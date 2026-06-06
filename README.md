# XASM2026 C#

Version C# autonome de XASM2026 pour CPU SC62015 / SHARP PC-E500S.

## Contenu

- `src/` : code source C# natif
- `bin/` : executable final pret a tester sous Windows
- `Documentation/` : documentation historique et notes utiles
- `Exemples/` : sources assembleur de reference
- `Reference/` : sources de reference conservees pour comparaison
- `tests/` : elements de verification
- `PORTAGE.md` : journal du portage et validations

## Utilisation rapide

Pour un projet avec des fichiers inclus comme `VOGUE.S`, se placer dans son dossier :

```powershell
cd .\Exemples\VOGUE
..\..\bin\xasm2026-3.exe VOGUE.S -O vogue.obj -L vogue.lst -B vogue.uu
```

Pour reconstruire depuis les sources :

```powershell
dotnet build .\src\Xasm2026.Native.csproj -c Release
```

## Validation finale

La version finalisee a ete verifiee sur `vogue.s` contre les sorties DOSBox / UUSELFX de reference :

- `vogue.obj` : identique
- `vogue.lst` : identique
- `vogue.uu` : identique
