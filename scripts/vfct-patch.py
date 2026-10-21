#!/usr/bin/env python3
"""
vfct-patch.py - Remove the internal eDP panel (LCD1) from the AMD VBIOS copy stored in
the ACPI VFCT table of a MacBook Pro 15" 2017 (A1707, MacBookPro14,3) with Radeon Pro 560/555.
Fixes Windows "Code 43" (CM_PROB_FAILED_POST_START) when the internal display is broken/removed.

Author / discoverer: Ryan Anthony Gibo - MIT License.
USE AT YOUR OWN RISK. Validate the output with vfct-parse.py before using it.

Usage: python vfct-patch.py vfct.dat VFCT-noeDP.aml
       (vfct.dat = raw VFCT table dumped with ACPICA: acpidump -n VFCT -b)
"""
import struct, sys

src = sys.argv[1] if len(sys.argv) > 1 else 'vfct.dat'
dst = sys.argv[2] if len(sys.argv) > 2 else 'VFCT-noeDP.aml'
EDP_CONNECTOR, EDP_ENCODER, LCD1_TAG = 0x3114, 0x221E, 0x0002

d = bytearray(open(src, 'rb').read())
assert d[0:4] == b'VFCT', 'input is not a VFCT table'
vo = struct.unpack_from('<I', d, 52)[0]        # VBIOSImageOffset (76 on A1707)
r = vo + 28                                    # ROM starts after the 28-byte image header
u16 = lambda o: struct.unpack_from('<H', d, o)[0]
R = lambda x: r + x

rh = u16(R(0x48))                              # ATOM_ROM_HEADER
mdt = u16(R(rh + 0x20))                        # Master Data Table
oh = u16(R(mdt + 4 + 2 * 22))                  # data table #22 = Object Header
dsup, conn, rout, enc, prot, path = struct.unpack_from('<HHHHHH', d, R(oh + 4))

def rm_obj(tab, oid):
    b = R(oh + tab); n = d[b]
    ents = [bytes(d[b + 4 + 8 * i:b + 12 + 8 * i]) for i in range(n)]
    keep = [e for e in ents if struct.unpack_from('<H', e)[0] != oid]
    assert len(keep) == n - 1, 'object %04x not found - different VBIOS? aborting' % oid
    d[b] = n - 1
    d[b + 4:b + 4 + 8 * n] = b''.join(keep) + b'\0' * 8

rm_obj(conn, EDP_CONNECTOR)
rm_obj(enc, EDP_ENCODER)

p = R(oh + path); n = d[p]; q = p + 4; paths = []
for i in range(n):
    sz = u16(q + 2); paths.append(bytes(d[q:q + sz])); q += sz
keep = [x for x in paths if struct.unpack_from('<H', x)[0] != LCD1_TAG]
assert len(keep) == n - 1, 'LCD1 display path not found - aborting'
blob = b''.join(keep); tot = sum(map(len, paths))
d[p] = n - 1
d[p + 4:p + 4 + tot] = blob + b'\0' * (tot - len(blob))

struct.pack_into('<H', d, R(oh + 4), dsup & ~0x0002)   # clear ATOM_DEVICE_LCD1_SUPPORT
struct.pack_into('<HH', d, vo + 16, 0x106B, 0x0179)    # image header SSVID:SSID = Apple 106B:0179

size = d[R(2)] * 512                                    # ROM checksum (byte 0x21)
d[R(0x21)] = 0; d[R(0x21)] = (-sum(d[r:r + size])) & 0xff
d[16:24] = b'Apple00\x00'                               # OEM Table ID
d[9] = 0; d[9] = (-sum(d)) & 0xff                       # ACPI table checksum
open(dst, 'wb').write(d)
print('written', dst, len(d), 'bytes')
