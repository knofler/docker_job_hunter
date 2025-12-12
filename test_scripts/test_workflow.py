#!/usr/bin/env python3
import requests
import json

# Test data for recruiter workflow
test_payload = {
    "job_description": "We are looking for a Senior Frontend Engineer with expertise in React, TypeScript, and modern web development. The ideal candidate will have 5+ years of experience building scalable web applications.",
    "resumes": [
        {
            "resume_id": "software-engineer-resume",
            "candidate_id": "candidate_1"
        },
        {
            "resume_id": "product-manager-resume",
            "candidate_id": "candidate_1"
        }
    ],
    "job_metadata": {
        "title": "Senior Frontend Engineer",
        "code": "REQ-001",
        "level": "Senior",
        "salary_band": "$130k - $150k AUD",
        "summary": "Senior Frontend Engineer role at Acme Corp"
    }
}

# Make the request
url = "http://localhost:8010/recruiter-workflow/generate"
headers = {"Content-Type": "application/json"}

print("Making request to recruiter workflow...")
response = requests.post(url, json=test_payload, headers=headers)

print(f"Status Code: {response.status_code}")
if response.status_code == 200:
    result = response.json()
    print("Success! Response received.")
    print("Keys in response:", list(result.keys()))
    # Check if engagement_plan exists and what type it is
    if "engagement_plan" in result:
        print(f"engagement_plan type: {type(result['engagement_plan'])}")
        print(f"engagement_plan value: {result['engagement_plan']}")
    if "fairness_guidance" in result:
        print(f"fairness_guidance type: {type(result['fairness_guidance'])}")
        print(f"fairness_guidance value: {result['fairness_guidance']}")
else:
    print(f"Error: {response.text}")