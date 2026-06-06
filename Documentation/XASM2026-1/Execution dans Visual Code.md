Pour terminer donne moi tes conseils pour éditer et compiler dans Studio Code15 h 23

Oui. Pour travailler confortablement dans Visual Studio Code, je te conseille cette organisation simple.

Ouvre directement le dossier :

code "<archive>\\xasm2026-1"Installe l’extension VS Code C/C++ de Microsoft. Elle suffit pour la coloration, la navigation dans le code C et les diagnostics de base.

Commande de compilation depuis le terminal VS Code, dans le dossier xasm2026-1 :

gcc -std=c99 -Wall -Wextra -Wno-pointer-sign -Wno-sign-compare -o xasm2026-1.exe eval.c genop.c hash.c init.c mes.c misc.c modern.c mvopr.c opr.c var.c xasm.cPour assembler ensuite un exemple depuis Exemples\\VOGUE :

....\\xasm2026-1.exe VOGUE.S -O VOGUE.obj -L VOGUE.lst -I VOGUE.hex -M VOGUE.s19 -P VOGUE.map -D VOGUE.d -B VOGUE.uu -X VOGUE.txt -R -WMon conseil pratique : ajoute un fichier .vscode\\tasks.json avec deux tâches, une pour compiler XASM et une pour assembler VOGUE. Comme ça tu n’auras plus qu’à faire Terminal > Run Task.

{"version": "2.0.0","tasks": [{"label": "Compiler xasm2026-1","type": "shell","command": "gcc","args": ["-std=c99","-Wall","-Wextra","-Wno-pointer-sign","-Wno-sign-compare","-o","xasm2026-1.exe","eval.c","genop.c","hash.c","init.c","mes.c","misc.c","modern.c","mvopr.c","opr.c","var.c","xasm.c"],"group": "build","problemMatcher": "gcc" }, { "label": "Assembler VOGUE", "type": "shell", "command": "..\\..\\xasm2026-1.exe", "args": [ "VOGUE.S", "-O", "VOGUE.obj", "-L", "VOGUE.lst", "-I", "VOGUE.hex", "-M", "VOGUE.s19", "-P", "VOGUE.map", "-D", "VOGUE.d", "-B", "VOGUE.uu", "-X", "VOGUE.txt", "-R", "-W" ], "options": { "cwd":"{workspaceFolder}\\Exemples\\VOGUE"},"problemMatcher": []}]}Pour tes fichiers assembleur .ASM / .S, tu peux aussi associer l’extension au langage Assembly dans VS Code :

{"files.associations": {"*.ASM": "asm","*.asm": "asm","*.S": "asm","*.s": "asm","*.lst": "plaintext","*.map": "plaintext","\*.uu": "basic"}}À mettre dans .vscode\\settings.json.

Le plus agréable au quotidien : Ctrl+Shift+B pour compiler xasm2026-1.exe, puis Terminal > Run Task > Assembler VOGUE pour produire tous les fichiers de sortie.

 
