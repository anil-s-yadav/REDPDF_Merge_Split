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
