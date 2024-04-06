{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "RunScript",
            "type": "shell",
            "command": "python",
            "args": ["D:\\Azure Automation\\main.py"],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "reveal": "silent"
            },
            "problemMatcher": [],
            "schedule": {
                "interval": "1m",
                "mode": "interval"
            }
        }
    ]
}
