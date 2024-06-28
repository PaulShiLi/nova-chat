from openai import OpenAI
import requests
import json
import time

def inference(text: str, endPoint: str = "http://127.0.0.1:7999"):
    with requests.post(
        f"{endPoint}/completion",
        headers={
            "Content-Type": "application/json"
        },
        json={
            "prompt": text,
            "n_predict": 128,
            "stream": True,
        },
        stream=True,
    ) as response:
        for line in response.iter_lines():
            if line:
                content = json.loads(line.decode('utf-8').replace("data: ", ""))["content"]
                print(content, end="")

def inferenceOpenAI(text: str, endPoint="http://127.0.0.1:7999"):
    client = OpenAI(base_url=f"{endPoint}/v1", api_key="sk-no-key-required")

    for resp in client.completions.create(
        model="",
        prompt=prompt,
        stream=True,
        max_tokens=128 # Token limit is bugged
    ):
        completion = resp.content
        print(completion, end="")        
    

prompt = "Write a Python function to calculate the factorial of a number (a non-negative integer). The function accepts the number as an argument."

start = time.time()
print("====================================")
inference(prompt)
end = time.time()

print(f"Time taken: {end - start} seconds")


start = time.time()
print("====================================")

inferenceOpenAI(prompt)

end = time.time()

print(f"Time taken: {end - start} seconds")

