# stitch

A new Flutter project.

remove zip aproch there is nothing like zip file.
Add a screen to seldct pdf for split and give button to select file to split and give these info:
Very common use cases:
Extract chapter from ebook
Extract invoice from large document
Extract certificate page

Split Features You Should Add in Your App
For your RedPdf ecosystem, add these 4 options:
1️⃣ Extract Pages
→ select pages (1,3,5 or 2-6)
2️⃣ Split Every Page
→ create multiple PDFs
3️⃣ Split by Range
→ 1-5, 6-10 etc
4️⃣ Delete Pages
→ remove unwanted pages then save new PDF
Best Design for Your App
Separate the tools clearly.
1️⃣ Split PDF
Creates new files from selected pages
Example:
Select PDF
Select pages: 3–5
Result:
document_3-5.pdf
2️⃣ Remove Pages

Creates new PDF without those pages

Example:

Select PDF
Remove pages: 3–5
Result:
document_without_3-5.pdf
📱 Recommended Tools in Your App

Your Merge & Split app should have:

Merge PDF
Split PDF
Extract Pages
Remove Pages
Reorder Pages

workflow:
Select PDF
↓
Choose Split Option
↓
Select Pages / Mode
↓
Split PDF
↓
Save / Share

features after sellect pdf for spliting:
Visual Page Preview (Drag & Select)- Visual Page Preview (Drag & Select)
Smart Auto Naming- Output:
invoice_march_pages_1-3.pdf
invoice_march_pages_4-6.pdf
For split every page
invoice_march_page_1.pdf
invoice_march_page_2.pdf


---

## 📦 Key PDF & File Packages Architecture

| Package | What it does | Why it's needed |
| :--- | :--- | :--- |
| **`pdf_manipulator`** | ⚙️ Core Engine (Native) | Does the actual merging, splitting, and deleting of PDF files in the background using native code. Cannot be touched. |
| **`open_filex`** | 🚀 System App Launcher | Has no PDF code. It only tells Android: "Open this file with Google Drive / Adobe Acrobat". Tiny (< 100 KB) and allowed us to delete the heavy in-app viewer. |
| **`pdfx`** | 🖼️ Thumbnail & Image Renderer | `pdf_manipulator` cannot draw images or show previews. `pdfx` converts PDF pages into images for the 1st page preview on the Success screen and the pages grid on the Split screen. |
| **`syncfusion_flutter_pdf`** | 📄 Dart PDF Editor | Currently used in only one place: in `pdf_service.dart` when a user rearranges/reorders custom pages during Split. |


The Real Problem: "Remove Ads" Alone Doesn't Sell

You correctly noticed the catch: if "Remove Ads" is the only feature in Pro, users have very little motivation to pay ₹99 or ₹399 because:

Banner ads are quiet and non-intrusive anyway.
If they really care, they can just turn off Wi-Fi.

To get real paying customers, Pro must offer actual utility features, not just "No Ads".

3. How Top PDF Apps Solve This (Without Blocking Offline Use)

IMPORTANT

Never block offline use. You are 100% right: forcing internet connection for a local PDF tool will lead to 1-star reviews and uninstalls. Keep basic merge and split 100% offline and free.

Instead, monetize using Feature & Volume Limits:

Strategy A: Batch / Quantity Limits (Most Effective)
Free: Merge up to 3 files at a time.
Pro: Unlimited files at once (merge 10, 20, 50 documents).
Why it works: Casual users who merge 2 files stay happy and leave 5-star reviews. Office workers and students who need to merge 15 chapters or invoices happily pay for Pro.
Strategy B: Advanced Tools (Roadmap)

Your pdf_manipulator package already contains built-in capabilities that you haven't exposed in the UI yet! You can make these Pro-only features:

🔒 Encrypt / Password Protect PDF (Pro)
🔓 Decrypt / Remove Password from PDF (Pro)
🗜️ PDF Compressor (reduce large PDF file sizes) (Pro)
💧 Add Watermark / Stamp (Pro)
Strategy C: "Remove Ads" as a Bonus, Not the Main Pitch

On your Pro purchase screen, position it like this:

⚡ Unlimited Batch Merging (10+ files at once)
🔒 Password Protection & Encryption
⚡ Priority Processing Speed
✨ 100% Ad-Free Experience

======================================================

This 4-plan strategy works very well.

It creates a seamless psychological pricing ladder where every type of user finds a home:

1 Month (₹29): The "Impulse" buy. Anyone with a one-time college/job task pays instantly without thinking.
6 Months (₹99): The "Student / Project" buy. Under ₹100 is a huge psychological sweet spot for UPI payments.
1 Year (₹189): The "Smart Deal". For just ₹90 more than 6 months, they get a whole year (Badge: MOST POPULAR).
Lifetime (₹999): The "One-Time" buy (Badge: BEST VALUE).