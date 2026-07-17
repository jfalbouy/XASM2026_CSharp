# Utiliser xasm2026-4 avec Visual Studio 2022 et VS Code Insiders

## 1. Prérequis

Installer :

- Visual Studio 2022 avec la charge de travail **Développement .NET Desktop** ou **Développement multiplateforme .NET**.
- Le SDK **.NET 8**.
- Pour VS Code Insiders : extension **C# Dev Kit** ou extension **C#** Microsoft.

Le projet principal est :

```text
C:\Codex\xasm2026-github-final\src\Xasm2026.Native.csproj
```

La solution Visual Studio est :

```text
C:\Codex\xasm2026-github-final\xasm2026-4.sln
```

Une solution au nouveau format existe aussi :

```text
C:\Codex\xasm2026-github-final\xasm2026-4.slnx
```

Pour Visual Studio 2022, utiliser de préférence le fichier `.sln` classique.

## 2. Ouvrir dans Visual Studio 2022

1. Lancer Visual Studio 2022.
2. Choisir **Ouvrir un projet ou une solution**.
3. Ouvrir :

```text
C:\Codex\xasm2026-github-final\xasm2026-4.sln
```

4. Définir `Xasm2026.Native` comme projet de démarrage si Visual Studio ne le fait pas automatiquement.
5. Vérifier que la configuration est `Debug` ou `Release`, selon le besoin.

## 3. Profils de lancement Visual Studio

Les profils sont dans :

```text
C:\Codex\xasm2026-github-final\src\Properties\launchSettings.json
```

Profils disponibles :

| Profil | Rôle |
|---|---|
| `xasm2026-4 - coverage_all toutes options` | Compile le banc de couverture avec toutes les sorties. |
| `xasm2026-4 - REGISTER` | Compile `REGISTER.ASM`. |
| `xasm2026-4 - VOGUE` | Compile `VOGUE.S`. |
| `xasm2026-4 - source personnel` | Profil simple à modifier pour un source utilisateur. |

Dans Visual Studio :

1. Sélectionner le profil dans la liste déroulante à côté du bouton **Démarrer**.
2. Appuyer sur **F5** pour lancer en debug.
3. Appuyer sur **Ctrl+F5** pour lancer sans debug.

## 4. Modifier un profil pour son propre source

Dans `launchSettings.json`, modifier :

```json
"commandLineArgs": "mon_programme.asm -O mon_programme.obj -L mon_programme.lst -E -B mon_programme.uu -V",
"workingDirectory": "C:\\chemin\\du\\dossier\\source"
```

Le `workingDirectory` est important : les fichiers `INCLUDE` et les sorties sont résolus depuis ce dossier.

## 5. Compiler depuis le terminal Visual Studio

Depuis un terminal ouvert dans `C:\Codex\xasm2026-github-final` :

```powershell
dotnet build .\xasm2026-4.sln -c Release
```

Ou seulement le projet natif :

```powershell
dotnet build .\src\Xasm2026.Native.csproj -c Release
```

L'exécutable généré est :

```text
C:\Codex\xasm2026-github-final\src\bin\Release\net8.0\xasm2026-4.exe
```

La copie pratique du projet est :

```text
C:\Codex\xasm2026-github-final\bin\xasm2026-4.exe
```

## 6. Exemple de ligne de commande complète

```powershell
cd C:\Codex\xasm2026-github-final\tests
..\bin\xasm2026-4.exe coverage_all.asm -O coverage_all.obj -L coverage_all.lst -E -S -TZ -C -W -H -I coverage_all.hex -M coverage_all.s19 -P coverage_all.map -D coverage_all.d -B coverage_all.uu -X coverage_all.txt -V -R
```

Sorties attendues :

```text
coverage_all.obj
coverage_all.lst
coverage_all.err
coverage_all.hex
coverage_all.s19
coverage_all.map
coverage_all.d
coverage_all.uu
coverage_all.txt
```

## 7. Utiliser VS Code Insiders

Ouvrir le dossier :

```text
C:\Codex\xasm2026-github-final
```

Les fichiers fournis sont :

| Fichier | Rôle |
|---|---|
| `.vscode\tasks.json` | Tâches de build et d'assemblage. |
| `.vscode\launch.json` | Profils de debug. |
| `.vscode\settings.json` | Associations de fichiers `.asm`, `.lst`, `.uu`, etc. |

Commandes utiles dans VS Code Insiders :

- **Terminal > Run Build Task** : lance `build xasm2026-4`.
- **Terminal > Run Task** puis `coverage_all toutes options`.
- **Run and Debug** puis `Debug coverage_all`.
- **Run and Debug** puis `Debug REGISTER`.

## 8. Points de debug utiles

Fichiers principaux :

| Fichier | Ce qu'il faut y déboguer |
|---|---|
| `src\Program.cs` | Parsing global, écriture des sorties, rapports d'erreur. |
| `src\CommandLineOptions.cs` | Options `-O`, `-L`, `-B`, `-T`, etc. |
| `src\Assembly\NativeAssembler.cs` | Directives, macros, labels, prébytes, encodage opcodes. |
| `src\Expressions\ExpressionEvaluator.cs` | Évaluation numérique et symboles. |
| `src\Outputs\BasicUuWriter.cs` | Génération `.uu`. |
| `src\Outputs\ObjectWriter.cs` | Formats objet. |

Breakpoints recommandés :

- `Program.Main`, au début du `try`.
- `NativeAssembler.Assemble`.
- `NativeAssembler.EmitPrebyte`.
- `NativeAssembler.EmitMove`, `EmitMoveWord`, `EmitMovePointer`, `EmitMoveLong`.
- `BasicUuWriter.Write`.

## 9. Vérification rapide après modification

Après une modification du code :

```powershell
dotnet build C:\Codex\xasm2026-github-final\src\Xasm2026.Native.csproj -c Release
```

Puis :

```powershell
cd C:\Codex\xasm2026-github-final\tests
..\src\bin\Release\net8.0\xasm2026-4.exe coverage_all.asm -O coverage_all.check.obj -L coverage_all.check.lst -E -S -TZ -C -W -H -I coverage_all.check.hex -M coverage_all.check.s19 -P coverage_all.check.map -D coverage_all.check.d -B coverage_all.check.uu -X coverage_all.check.txt -V -R
```

Le banc `coverage_all.asm` doit compiler sans erreur.

## 10. Notes importantes

- Les erreurs fatales sont écrites dans `.err` et `.lst` si `-E` et `-L` sont utilisés.
- Les formes invalides de prébyte doivent produire `Prebyte error`.
- Pour `PY`, respecter la table : `PY+n` et `BP+PY` ne sont pas des formes de premier opérande.
- Pour comparer les objets, utiliser `fc.exe /b`.

