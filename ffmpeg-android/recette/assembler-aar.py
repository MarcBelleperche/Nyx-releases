"""Assemble une archive zip reproductible (classes.jar, AAR) : entrées triées, date et
droits fixes. Deux constructions des mêmes fichiers donnent les mêmes octets.

Usage : python3 -I assembler-aar.py <archive> <dossier>
"""
import os
import sys
import zipfile

# La date que met AGP dans ses AAR.
DATE = (1981, 1, 1, 1, 1, 2)


def assemble(archive, racine):
    fichiers = []
    for dossier, _, noms in os.walk(racine):
        for nom in noms:
            fichiers.append(os.path.relpath(os.path.join(dossier, nom), racine).replace(os.sep, "/"))
    fichiers.sort()
    with zipfile.ZipFile(archive, "w") as zf:
        for relatif in fichiers:
            entree = zipfile.ZipInfo(relatif, DATE)
            entree.compress_type = zipfile.ZIP_DEFLATED
            entree.external_attr = 0o644 << 16
            with open(os.path.join(racine, relatif), "rb") as f:
                zf.writestr(entree, f.read(), compresslevel=9)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    assemble(sys.argv[1], sys.argv[2])
