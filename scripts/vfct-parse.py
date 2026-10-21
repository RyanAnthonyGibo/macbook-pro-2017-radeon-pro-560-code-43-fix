#!/usr/bin/env python3
"""
vfct-parse.py - Dump the header, ATOM BIOS object table (connectors, encoders, display paths)
and checksums of an ACPI VFCT table. Author: Ryan Anthony Gibo - MIT License.
Usage: python vfct-parse.py vfct.dat
"""
import struct,sys
d=bytearray(open(sys.argv[1],'rb').read())
u16=lambda b,o:struct.unpack_from('<H',b,o)[0]; u32=lambda b,o:struct.unpack_from('<I',b,o)[0]
print('sig',d[0:4],'len',u32(d,4),'rev',d[8],'cksum ok',sum(d)&0xff==0, 'oem',d[10:16],d[16:24])
vo=u32(d,52); print('vbios_off',vo,'lib1',u32(d,56))
bus,dev,fn,vid,did,ssvid,ssid,rev,ilen=struct.unpack_from('<IIIHHHHII',d,vo)
print('img hdr bus/dev/fn',bus,dev,fn,'%04x:%04x ss %04x:%04x'%(vid,did,ssvid,ssid),'len',ilen)
r=vo+28; rom=d[r:r+ilen]
print('rom sig',rom[0:2].hex(),'size',rom[2]*512,'cksum',sum(rom[:rom[2]*512])&0xff,'(0 = OK)')
rh=u16(rom,0x48); print('romhdr',hex(rh),rom[rh+4:rh+8])
mdt=u16(rom,rh+0x20); print('master data',hex(mdt))
tabs=[u16(rom,mdt+4+2*i) for i in range(34)]
oh=tabs[22]; print('ObjectHeader',hex(oh),'fmt/content rev',rom[oh+2],rom[oh+3])
dsup,conn,rout,enc,prot,path=struct.unpack_from('<HHHHHH',rom,oh+4)
print('devsupport %04x'%dsup)
def objtab(o,name):
  n=rom[o]; print(name,'count',n)
  for i in range(n):
    oid,src,rec,res=struct.unpack_from('<HHHH',rom,o+4+8*i); print('  obj %04x type %d id %02x'%(oid,(oid>>12)&7,oid&0xff),'src',hex(src),'rec',hex(rec))
objtab(oh+conn,'connectors'); objtab(oh+enc,'encoders')
p=oh+path; n=rom[p]; print('paths',n,'ver',rom[p+1]); q=p+4
for i in range(n):
  tag,sz,co,go=struct.unpack_from('<HHHH',rom,q); g=[u16(rom,q+8+2*k) for k in range((sz-8)//2)]
  print('  path tag %04x size %d conn %04x gpu %04x graph %s'%(tag,sz,co,go,[hex(x) for x in g])); q+=sz
