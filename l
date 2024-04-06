{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "RunScript",
            "type": "shell",
            "command": "python",
            "args": [
                "path_to_your_script.py"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "reveal": "silent"
            },
            "problemMatcher": [],
            "schedule": "*/1 * * * *"
        }
    ]
}
