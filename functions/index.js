const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

setGlobalOptions({maxInstances: 10});

admin.initializeApp();

const geminiApiKey = defineSecret("GEMINI_API_KEY");

const allowedCategories = new Set([
  "plastic",
  "glass",
  "metal",
  "paper",
  "fabric",
  "electronic_waste",
  "non_recyclable",
]);

exports.detectWaste = onCall(
  {
    secrets: [geminiApiKey],
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to use AI detection.",
      );
    }

    const imageBase64 = request.data && request.data.imageBase64;
    const mimeType = request.data && request.data.mimeType;

    if (!imageBase64 || typeof imageBase64 !== "string") {
      throw new HttpsError("invalid-argument", "Missing image data.");
    }

    if (!mimeType || typeof mimeType !== "string") {
      throw new HttpsError("invalid-argument", "Missing image MIME type.");
    }

    try {
      const result = await callGemini({imageBase64, mimeType});
      return normalizeDetectionResult(result);
    } catch (error) {
      logger.error("Gemini waste detection failed", error);
      throw new HttpsError(
        "internal",
        "Unable to detect the waste item. Please try again or fill manually.",
      );
    }
  },
);

exports.verifyUpcycledProduct = onCall(
  {
    secrets: [geminiApiKey],
    timeoutSeconds: 90,
    memory: "512MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to run AI verification.",
      );
    }

    const productId = request.data && request.data.productId;
    if (!productId || typeof productId !== "string") {
      throw new HttpsError("invalid-argument", "Missing product ID.");
    }

    try {
      const result = await verifyProductForUser({
        productId,
        userId: request.auth.uid,
      });
      return result;
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logger.error("Gemini upcycled product verification failed", error);
      throw new HttpsError(
        "internal",
        "Unable to run AI credibility assessment. Please try again later.",
      );
    }
  },
);

async function verifyProductForUser({productId, userId}) {
  const firestore = admin.firestore();
  const productRef = firestore.collection("completed_products").doc(productId);
  const productSnapshot = await productRef.get();

  if (!productSnapshot.exists) {
    throw new HttpsError("not-found", "Completed product not found.");
  }

  const product = productSnapshot.data();
  if (!product || product.user_id !== userId) {
    throw new HttpsError(
      "permission-denied",
      "You can only verify your own completed products.",
    );
  }

  if (product.is_published_to_hub === true) {
    throw new HttpsError(
      "failed-precondition",
      "Published reports cannot be changed by AI assessment in this prototype.",
    );
  }

  if (!stringValue(product.after_image_url, "")) {
    throw new HttpsError("failed-precondition", "After photo is required.");
  }

  const guideSnapshot = stringValue(product.guide_id, "")
    ? await firestore.collection("diy_guides").doc(product.guide_id).get()
    : null;
  const guide = guideSnapshot && guideSnapshot.exists ?
    guideSnapshot.data() :
    {};

  const afterImage = await fetchImageInlineData(product.after_image_url);
  const beforeImageUrl = stringValue(product.before_image_url, "");
  const beforeImage = beforeImageUrl ?
    await fetchImageInlineData(beforeImageUrl) :
    null;

  const aiResult = await callGeminiVerification({
    product,
    guide,
    beforeImage,
    afterImage,
  });
  const normalized = normalizeVerificationResult(aiResult, product);
  const batch = firestore.batch();

  batch.update(productRef, {
    assessment_method: "ai_assisted",
    material_match_score: normalized.materialMatchScore,
    diy_output_match_score: normalized.diyOutputMatchScore,
    transformation_plausibility_score: normalized.transformationPlausibilityScore,
    image_quality_score: normalized.imageQualityScore,
    final_verification_score: normalized.finalVerificationScore,
    verification_badge: normalized.verificationBadge,
    verification_status: normalized.verificationStatus,
    ai_explanation: normalized.aiExplanation,
    report_summary: normalized.reportSummary,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    verified_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  const sessionId = stringValue(product.project_session_id, "");
  if (sessionId) {
    batch.update(firestore.collection("project_sessions").doc(sessionId), {
      status: normalized.verificationStatus,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      verified_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  return normalized;
}

async function fetchImageInlineData(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Image fetch failed ${response.status}`);
  }

  const contentType = response.headers.get("content-type") || "image/jpeg";
  const buffer = Buffer.from(await response.arrayBuffer());
  return {
    mimeType: contentType.split(";")[0],
    data: buffer.toString("base64"),
  };
}

async function callGeminiVerification({product, guide, beforeImage, afterImage}) {
  const endpoint =
    "https://generativelanguage.googleapis.com/v1beta/models/" +
    "gemini-3.5-flash:generateContent?key=" +
    geminiApiKey.value();

  const productContext = {
    product_name: stringValue(product.product_name, ""),
    materials_used: stringValue(product.materials_used, ""),
    reused_materials: Array.isArray(product.reused_materials) ?
      product.reused_materials :
      [],
    product_purpose: stringValue(product.product_purpose, ""),
    condition: stringValue(product.condition, ""),
    safety_note: stringValue(product.safety_note, ""),
    dimensions: stringValue(product.dimensions, ""),
    time_taken: stringValue(product.time_taken, ""),
    estimated_cost: stringValue(product.estimated_cost, ""),
    evidence_completeness_score: numberValue(
      product.evidence_completeness_score,
      0,
    ),
    has_before_photo: beforeImage !== null,
  };
  const guideContext = {
    title: stringValue(guide.title, ""),
    description: stringValue(guide.description, ""),
    material_tags: Array.isArray(guide.material_tags) ? guide.material_tags : [],
    materials_needed: Array.isArray(guide.materials_needed) ?
      guide.materials_needed :
      [],
    steps: Array.isArray(guide.steps) ? guide.steps : [],
    difficulty_level: stringValue(guide.difficulty_level, ""),
    estimated_time: stringValue(guide.estimated_time, ""),
  };

  const prompt = [
    "You are performing an AI-assisted credibility assessment for an upcycling app.",
    "Do not claim legal proof, certification, or guaranteed authenticity.",
    "Assess whether the submitted evidence appears plausible and complete.",
    "If the before photo is missing, material match and transformation plausibility must be limited.",
    "Return ONLY valid JSON with no markdown and no extra text.",
    "Use integer scores from 0 to 100.",
    "JSON schema:",
    "{",
    "\"material_match_score\": integer,",
    "\"diy_output_match_score\": integer,",
    "\"transformation_plausibility_score\": integer,",
    "\"image_quality_score\": integer,",
    "\"ai_explanation\": string",
    "}",
    "Product context:",
    JSON.stringify(productContext),
    "DIY guide context:",
    JSON.stringify(guideContext),
  ].join("\n");

  const parts = [{text: prompt}];
  if (beforeImage) {
    parts.push({text: "Before photo:"});
    parts.push({inlineData: beforeImage});
  }
  parts.push({text: "After photo:"});
  parts.push({inlineData: afterImage});

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      contents: [{role: "user", parts}],
      generationConfig: {
        temperature: 0.1,
        responseMimeType: "application/json",
      },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Gemini API error ${response.status}: ${errorText}`);
  }

  const payload = await response.json();
  const text = payload
    .candidates?.[0]
    ?.content
    ?.parts
    ?.map((part) => part.text || "")
    ?.join("");

  if (!text) {
    throw new Error("Gemini returned an empty verification response.");
  }

  return JSON.parse(stripJsonFence(text));
}

function normalizeVerificationResult(result, product) {
  const materialMatchScore = scoreValue(result.material_match_score);
  const diyOutputMatchScore = scoreValue(result.diy_output_match_score);
  const transformationPlausibilityScore = scoreValue(
    result.transformation_plausibility_score,
  );
  const imageQualityScore = scoreValue(result.image_quality_score);
  const evidenceCompletenessScore = scoreValue(
    product.evidence_completeness_score,
  );
  const finalVerificationScore = Math.round(
    materialMatchScore * 0.25 +
    diyOutputMatchScore * 0.30 +
    transformationPlausibilityScore * 0.20 +
    evidenceCompletenessScore * 0.15 +
    imageQualityScore * 0.10,
  );
  const verificationStatus = finalVerificationScore >= 60 ?
    "verified" :
    "need_more_evidence";
  const verificationBadge = finalVerificationScore >= 80 ?
    "AI-Assisted Verified" :
    finalVerificationScore >= 60 ?
      "Partially Verified" :
      "More Evidence Required";
  const aiExplanation = stringValue(
    result.ai_explanation,
    "AI assessment completed, but no explanation was returned.",
  );
  const reportSummary = buildAiReportSummary({
    product,
    finalVerificationScore,
    verificationBadge,
    aiExplanation,
  });

  return {
    assessmentMethod: "ai_assisted",
    materialMatchScore,
    diyOutputMatchScore,
    transformationPlausibilityScore,
    imageQualityScore,
    evidenceCompletenessScore,
    finalVerificationScore,
    verificationStatus,
    verificationBadge,
    aiExplanation,
    reportSummary,
  };
}

function buildAiReportSummary({
  product,
  finalVerificationScore,
  verificationBadge,
  aiExplanation,
}) {
  const productName = stringValue(product.product_name, "This product");
  const materials = stringValue(product.materials_used, "the submitted materials");
  const purpose = stringValue(product.product_purpose, "the stated purpose");
  return [
    `${productName} received a ${finalVerificationScore}/100 AI-assisted`,
    `credibility score with the status "${verificationBadge}".`,
    `The report considered the claimed reused materials (${materials}),`,
    `the product purpose (${purpose}), the selected DIY guide, and the`,
    "submitted visual evidence. This assessment is a plausibility and",
    "evidence-quality check, not a guarantee of authenticity.",
    `AI explanation: ${aiExplanation}`,
  ].join(" ");
}

async function callGemini({imageBase64, mimeType}) {
  const endpoint =
    "https://generativelanguage.googleapis.com/v1beta/models/" +
    "gemini-3.5-flash:generateContent?key=" +
    geminiApiKey.value();

  const prompt = [
    "You are helping classify household waste for a recycling/upcycling app.",
    "Analyze the image and identify the most likely waste item.",
    "Return ONLY valid JSON with no markdown and no explanation outside JSON.",
    "JSON schema:",
    "{",
    "\"object\": string,",
    "\"material\": string,",
    "\"category\": string,",
    "\"confidence\": number,",
    "\"reason\": string",
    "}",
    "Allowed category values only:",
    "plastic, glass, metal, paper, fabric, electronic_waste, non_recyclable.",
    "Use practical material names such as PET plastic, cardboard, aluminium,",
    "glass, fabric, electronic parts, mixed waste.",
    "If uncertain, choose the closest category and use lower confidence.",
  ].join("\n");

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      contents: [
        {
          role: "user",
          parts: [
            {text: prompt},
            {
              inlineData: {
                mimeType,
                data: imageBase64,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.1,
        responseMimeType: "application/json",
      },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Gemini API error ${response.status}: ${errorText}`);
  }

  const payload = await response.json();
  const text = payload
    .candidates?.[0]
    ?.content
    ?.parts
    ?.map((part) => part.text || "")
    ?.join("");

  if (!text) {
    throw new Error("Gemini returned an empty response.");
  }

  return JSON.parse(stripJsonFence(text));
}

function stripJsonFence(text) {
  return text
    .trim()
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/\s*```$/i, "");
}

function normalizeDetectionResult(result) {
  const object = stringValue(result.object, "Unknown item");
  const material = stringValue(result.material, "Unknown material");
  let category = stringValue(result.category, "non_recyclable").toLowerCase();
  const reason = stringValue(result.reason, "");
  let confidence = Number(result.confidence);

  if (!allowedCategories.has(category)) {
    category = "non_recyclable";
  }

  if (!Number.isFinite(confidence)) {
    confidence = 0.5;
  }

  if (confidence > 1) {
    confidence = confidence / 100;
  }

  confidence = Math.min(Math.max(confidence, 0), 1);

  return {
    object,
    material,
    category,
    confidence,
    reason,
  };
}

function stringValue(value, fallback) {
  if (typeof value === "string" && value.trim()) {
    return value.trim();
  }
  return fallback;
}

function numberValue(value, fallback) {
  const number = Number(value);
  if (Number.isFinite(number)) {
    return number;
  }
  return fallback;
}

function scoreValue(value) {
  const number = numberValue(value, 0);
  return Math.round(Math.min(Math.max(number, 0), 100));
}
