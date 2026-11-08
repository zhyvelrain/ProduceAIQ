# ProduceAIQ — System Gaps Checklist

Honest audit of what's real/working vs. what's missing, stubbed, or
needs a decision. Organized by how much it matters, not by file.

---

## 🔴 CRITICAL — blocks a real end-to-end test or defense

- [ ] **Run a real device/emulator test, start to finish.** Nothing in
      this project has been run on an actual phone yet (only
      `flutter analyze`, which checks syntax, not behavior). Do the
      full loop once: scan → confidence screen → result (with
      freshness badge) → recipe screen → submit-for-review → confirm
      it shows up correctly in the admin panel, photo included.
- [ ] **Confirm `firestore.rules` is actually deployed.** The rules
      file exists and is correct, but until you run
      `firebase deploy --only firestore:rules` (or paste it into
      Console → Firestore → Rules → Publish), the *database* may
      still be running on old/open rules — only the admin panel's
      *UI* gate is currently guaranteed to be active.
- [ ] **CNN species classifier — freshness/ripeness is NOT one.**
      The produce *identification* model (MobileNetV2, `.tflite`) is
      a real trained CNN — that part is genuinely AI. The
      Fresh/Ripe/Overripe grade is a color/blemish heuristic, not a
      trained model of any kind, because no labeled freshness dataset
      exists. If your thesis committee expects "AI-based freshness
      detection," this is the gap to be upfront about. Real fix
      requires: (1) collecting/labeling a Fresh/Ripe/Overripe dataset
      per species, (2) training a second classifier or a multi-head
      model, (3) exporting and wiring it in the same way as the
      species model. This is a data problem first, an engineering
      problem second — no amount of code alone fixes it.

## 🟠 IMPORTANT — should resolve before relying on this for a defense

- [ ] **Finish or abandon the Google account transfer.** You added a
      second account as Owner via IAM; the transfer isn't complete
      until you've verified full access under the new account AND
      removed Owner from the old one. Right now both likely still
      have full access — fine temporarily, but decide and finish.
- [ ] **Swap the USDA `DEMO_KEY` for a real key.** `DEMO_KEY` is
      rate-limited (~30 requests/hour/IP) — fine for a demo, will
      break under any real testing load. Get a free key:
      fdc.nal.usda.gov/api-key-signup, replace in
      `produceaiq-admin-panel/index.html`.
- [ ] **Host the admin panel properly, not via `file://`.** Firebase
      Auth can behave inconsistently from a raw local file path
      (unauthorized-domain issues). Deploy via
      `firebase deploy --only hosting` or at minimum test through
      `firebase serve` before treating it as final.
- [ ] **No way to approve a second admin from inside the panel.**
      Approving the *first* admin requires the Firebase Console by
      hand (unavoidable without a backend) — but approving any admin
      *after* that still requires the Console too, since no
      "approve pending admins" UI was built. Low effort to add if
      you want it.
- [ ] **Photo thumbnails are new and untested.** Just switched from
      Firebase Storage (blocked — requires paid Blaze plan) to
      compressed Base64 thumbnails stored directly in Firestore. Code
      is written but never run against a real photo yet — verify a
      real submission actually populates `imageThumbnailBase64` and
      that the admin panel renders it.

## 🟡 KNOWN, DISCLOSED, LIKELY PERMANENT — not casually fixable

- [ ] **FAO INFOODS has no public API.** Confirmed via search, not
      assumed. The admin panel links out for manual lookup instead of
      faking an automated cross-reference. This isn't fixable without
      FAO publishing an API that doesn't currently exist.
- [ ] **"Show Me the Difference" is text, not photos.** Shows written
      visual-ID cues (shape/color/texture) pulled from your own
      catalog data, not actual side-by-side reference images of
      look-alike produce — no curated image set for that exists.
- [ ] **No original full-resolution photos are archived anywhere**,
      now that Storage is off the table without paid billing. Only
      compressed thumbnails exist. Acceptable for visual ID review;
      not acceptable if you ever need forensic-quality originals.

## 🟢 POLISH / FUTURE WORK — not blocking anything today

- [ ] No automated tests exist for any of the new logic (freshness
      heuristic, disambiguation flow, admin approval gate, USDA
      lookup).
- [ ] `produce_model.tflite` is from one training run (Aug 6) — worth
      retraining if you've added dataset photos since, or want higher
      accuracy.
- [ ] No rate-limiting/abuse protection on admin registration beyond
      Firebase's own defaults — fine for a thesis-scale audience, not
      hardened for public traffic.
- [ ] AI-driven recipe suggestions are still a static, hand-curated
      list per item (matches your thesis's "local knowledge base"
      description — not actually a gap, just noting it's not
      generative).

---

## What's actually solid right now (for balance — not everything is a gap)

- ✅ Real trained CNN (MobileNetV2 → TFLite) doing on-device produce
  identification — no placeholder, no mock data.
- ✅ Firebase Authentication + Firestore-backed admin approval system,
  enforced both client-side and (once deployed) server-side via rules.
- ✅ Live USDA FoodData Central integration (verified against the real
  API, not guessed).
- ✅ `flutter analyze` returns 0 issues as of the last pass.
- ✅ Project cleaned from ~1.85GB of committed bloat down to ~63MB.