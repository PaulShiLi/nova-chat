from openai import OpenAI
import requests
import json
import time

client = OpenAI(base_url="https://0.0.0.0:8000/v1", api_key="")
client2 = OpenAI(base_url="https://127.0.0.1:7999/v1", api_key="")

def inference(text: str, endPoint: str = "http://localhost:8000"):
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

prompt = "Write a Python function to calculate the factorial of a number (a non-negative integer). The function accepts the number as an argument."

start = time.time()
print("====================================")
# inference(prompt)
end = time.time()

# print(f"Time taken: {end - start} seconds")


start = time.time()
print("====================================")
inference(prompt, "http://127.0.0.1:7999")
end = time.time()

print(f"Time taken: {end - start} seconds")



from transformers import AutoModelForCausalLM, AutoTokenizer, TextStreamer, GenerationConfig

from pathlib import Path
import os

device = "cpu"

root = Path(__file__).resolve().parent.parent
modelPath = os.path.join(root, "assets", "models", "text", "Storm-7B")

model = AutoModelForCausalLM.from_pretrained(modelPath).to(device)
tokenizer = AutoTokenizer.from_pretrained(modelPath)
model.eval().requires_grad_(False)

def generate_response(prompt):
    input_ids = tokenizer(prompt, return_tensors="pt").input_ids.to(device)
    streamer = TextStreamer(tokenizer=tokenizer, skip_prompt=True, skip_special_tokens=True)
    
    generation_params = {
        "eos_token_id": tokenizer.eos_token_id,
        "pad_token_id": tokenizer.eos_token_id,
        "do_sample": True,
        "temperature": 0.7,
        "top_p": 0.95,
        "top_k": 40,
        "max_new_tokens": 128,
        "repetition_penalty": 1.1
    }
    generation_config = GenerationConfig(**generation_params)

    start = time.time()
    outputs = model.generate(
        input_ids, 
        streamer=streamer,
        generation_config=generation_config,
        max_length=128
    )
    end = time.time()
    print(f"Time taken: {end - start} seconds")
    

prompt = "Write a Python function to calculate the factorial of a number (a non-negative integer). The function accepts the number as an argument."
input_prompt = f"GPT4 Correct User: {prompt}<|end_of_turn|>GPT4 Correct Assistant:"
# response_text = generate_response(input_prompt)
# print("Response:", response_text)

