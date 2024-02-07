import json

x = open("meta-data.json")
contents = json.load(x)
x.close()

for entry in contents:
    entry["language"] = "c"
    entry["src"] = {
        "root_abspath": "/experiment/vulnloc/{subject}/{bug_id}/src".format(
            subject=entry["subject"], bug_id=entry["bug_id"]
        ),
        "entrypoint": {
            "file": entry["binary_path"] + ".c",
            "function": "main",
        },
    }
    entry["output_dir_abspath"] = "/output"
    entry["stack_trace"] = []
    for i,x in enumerate(entry["crash_stack_trace"]):
        entry["stack_trace"].append({
            "depth":i,
            "function":x[0],
            "source_file":x[1],
            "line":x[2]
        })
        
y = open("meta-data.candidate.json", "w")
json.dump(contents, y)
y.close()
