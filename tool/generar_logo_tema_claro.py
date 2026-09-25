#!/usr/bin/env python3
"""
Genera assets/logo/VacunApp2_claro.png a partir de VacunApp2.png.

=== Análisis del PNG original (633×768, paleta + alpha, sRGB) ===

1) El bitmap mezcla tres tipos de píxeles: transparentes (~43 % del lienzo),
   un cluster «oscuro» (~78k px) y un cluster «claro» (~75k px).

2) El cluster oscuro, ponderado por frecuencia, coincide con el trazo ya visible
   en papel oscuro: RGB ≈ (0, 86, 97) → #005661 (SisVacuMarca.vercelestePrimario).
   Ese trazo NO se modifica: ya tiene buen contraste en tema claro.

3) El cluster claro son blancos y grises muy claros (índices de paleta tipo
   245–255) + su anti-alias. Sobre surface clara (#F7F7F7 típica de la app)
   desaparecen.

=== Criterio del segundo color (no duplicar #005661) ===

- Objetivo: mantener **dos tonos** como en la intención gráfica original, no
  aplanar todo a un solo petróleo.

- Opciones evaluadas frente a fondo ~#F7F7F7 (contraste relativo aproximado):
  · #005661 primario → ~7.8:1  (excelente pero ya usado en el otro trazo)
  · #009CAF cuaternario → ~3.1:1  (legible en marca / trazos gruesos a este tamaño)
  · #00B0C7 verceleste → ~2.4:1  (más débil)
  · #00D1ED terciario → ~1.7:1  (insuficiente para uso general en claro)
  · #004B8E azul Formosa → ~8.2:1  (muy seguro pero **otro matiz**; rompe la
    familia cian–verde del logotipo)

- Elección: **SisVacuMarca.vercelesteCuaternario (#009CAF)**. Es el escalón
  claro de la misma rampa de marca (enfoque de sistemas de color 2024–2026:
  tonal ramps accesibles en lugar de un solo primario o blanco puro).

Solo se recolorean píxeles claros (RGB ≥ umbral); el resto se copia igual.

Ejecutar desde la raíz del repo:
  python3 tool/generar_logo_tema_claro.py
"""
from __future__ import annotations

import pathlib
import struct
import zlib

# Trazo que ya venía oscuro en el PNG (~#005661): no lo tocamos en código.
# Píxeles que eran blancos / casi blancos → segundo tono de marca:
# SisVacuMarca.vercelesteCuaternario 0xff009CAF
SEGUNDO_TONO_R, SEGUNDO_TONO_G, SEGUNDO_TONO_B = 0, 156, 175

UMBRAL_CLARO = 238


def _read_png_rgba(path: pathlib.Path) -> tuple[int, int, list[bytes]]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit("No es PNG")
    pos = 8
    width = height = 0
    bit_depth = color_type = 0
    palette = b""
    trns = b""
    idat = b""
    while pos < len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        ctype = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + length]
        pos += 8 + length + 4
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, _, _, _ = struct.unpack(
                ">IIBBBBB", chunk
            )
        elif ctype == b"PLTE":
            palette = chunk
        elif ctype == b"tRNS":
            trns = chunk
        elif ctype == b"IDAT":
            idat += chunk
        elif ctype == b"IEND":
            break
    raw = zlib.decompress(idat)
    if color_type != 3 or bit_depth != 8:
        raise SystemExit(f"Solo soportado PNG indexado 8-bit; tipo={color_type}")
    bpp = 1
    stride = width
    rows: list[bytearray] = []
    i = 0
    prev = bytearray(stride)
    for _y in range(height):
        filt = raw[i]
        i += 1
        scan = bytearray(raw[i : i + stride])
        i += stride
        if filt == 1:
            for x in range(stride):
                left = scan[x - bpp] if x >= bpp else 0
                scan[x] = (scan[x] + left) & 0xFF
        elif filt == 2:
            for x in range(stride):
                scan[x] = (scan[x] + prev[x]) & 0xFF
        elif filt == 3:
            for x in range(stride):
                left = scan[x - bpp] if x >= bpp else 0
                up = prev[x]
                scan[x] = (scan[x] + ((left + up) // 2)) & 0xFF
        elif filt == 4:

            def paeth(a: int, b: int, c: int) -> int:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                if pa <= pb and pa <= pc:
                    return a
                if pb <= pc:
                    return b
                return c

            for x in range(stride):
                a = scan[x - bpp] if x >= bpp else 0
                b = prev[x]
                c = prev[x - bpp] if x >= bpp else 0
                scan[x] = (scan[x] + paeth(a, b, c)) & 0xFF
        prev = scan
        rows.append(scan)
    n = len(palette) // 3
    alpha_plte = [255] * n
    for j, a in enumerate(trns):
        if j < n:
            alpha_plte[j] = a
    rgba_rows: list[bytes] = []
    for scan in rows:
        buf = bytearray(width * 4)
        for x, idx in enumerate(scan):
            ir = 3 * idx
            r, g, b = palette[ir], palette[ir + 1], palette[ir + 2]
            a = alpha_plte[idx] if idx < n else 255
            buf[4 * x : 4 * x + 4] = bytes((r, g, b, a))
        rgba_rows.append(bytes(buf))
    return width, height, rgba_rows


def _write_png_rgba_rgba8(path: pathlib.Path, width: int, height: int, rgba: bytes) -> None:
    def chunk(tag: bytes, cdata: bytes) -> bytes:
        crc = zlib.crc32(tag + cdata) & 0xFFFFFFFF
        return struct.pack(">I", len(cdata)) + tag + cdata + struct.pack(">I", crc)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        raw.extend(rgba[y * width * 4 : (y + 1) * width * 4])
    compressed = zlib.compress(bytes(raw), 9)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", compressed)
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def main() -> None:
    raiz = pathlib.Path(__file__).resolve().parents[1]
    origen = raiz / "assets" / "logo" / "VacunApp2.png"
    destino = raiz / "assets" / "logo" / "VacunApp2_claro.png"
    if not origen.is_file():
        raise SystemExit(f"No existe {origen}")

    w, h, rows = _read_png_rgba(origen)
    out = bytearray(w * h * 4)
    for y in range(h):
        row = rows[y]
        for x in range(w):
            i = 4 * (y * w + x)
            r, g, b, a = row[4 * x : 4 * x + 4]
            if a > 0 and r >= UMBRAL_CLARO and g >= UMBRAL_CLARO and b >= UMBRAL_CLARO:
                r, g, b = SEGUNDO_TONO_R, SEGUNDO_TONO_G, SEGUNDO_TONO_B
            out[i : i + 4] = bytes((r, g, b, a))

    _write_png_rgba_rgba8(destino, w, h, bytes(out))
    print(
        f"Escrito {destino} ({w}x{h}): trazo oscuro intacto (~#005661); "
        f"antiguos claros → #"
        f"{SEGUNDO_TONO_R:02X}{SEGUNDO_TONO_G:02X}{SEGUNDO_TONO_B:02X} "
        f"(vercelesteCuaternario)"
    )


if __name__ == "__main__":
    main()
