### Common bugs
If you are unable to load a docker image, delete the Docker config file and try again:
Mac:
```bash
rm  ~/.docker/config.json
```

To run llama.cpp server after running build.sh:
```
./pkg/llama.cpp/llama-server -m ./assets/models/text/mistral-7b/mistral-7b-v0.1.Q2_K.gguf --port 7999 --keep -1 -ngl 0
```