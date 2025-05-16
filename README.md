# -Serverless-Form-Submission-App-on-AWS

his project is a serverless web application designed to collect and store user data — such as name, age, profession, and years of experience — through a simple form hosted on an S3 static website.

The backend is fully serverless and uses AWS Lambda, API Gateway, and DynamoDB to process and store submissions. An SNS notification is triggered on each new entry, providing real-time alerts.

📌 Use Case / Business Context
This solution can help small to mid-sized businesses or internal teams collect structured data from users or clients, without managing infrastructure. Use cases include:

Talent acquisition forms
Customer intake for services
Internal employee surveys
It enables easy scaling, minimal cost, and quick deployment.

🧱 Architecture Overview
link : https://github.com/wilems-cloud/-Serverless-Form-Submission-App-on-AWS/blob/main/Architecture%20Diagram.jpg

⚙️ Tech Stack
S3 – Static website hosting for the frontend
API Gateway – Routes GET and POST HTTP requests
AWS Lambda – Handles business logic for reading and writing
DynamoDB – NoSQL database to store form data
SNS – Sends notification upon each new entry (POST)

🧪 Features
Submit user data through a clean web form
View existing entries (optional: via API or logs)
Real-time alerts on new submissions (SMS or email via SNS)
Fully serverless and event-driven

Feel fre to clone and try it..
let me know your feedback please.
