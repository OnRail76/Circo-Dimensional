#!/usr/bin/env python3
"""Reproducción independiente de Circo Dimensional v1.1 a partir del TAP oficial v1.0.
MIT © 2026 Tony C. Ware. Las imágenes integradas tienen derechos separados.
"""
from pathlib import Path
import argparse,hashlib,struct,zlib,base64
OLD='69f2cc4d4682eca9160595107886c0b9449b6cc745c4e2468e324b5db10f41f1'
NEW='9105d9679319aae0f4de445142276c1bfe7c65df36993e6f86ad87ddfa03dac1'
TITLE='eNoNzLux2loYBtAPH1+z37/89nZw1AFIuR+ZUtEIAjIHxzM0wKuC24EAVUAFEnRACTsk8MxnF7BWAtOI6RXTE9Nrpv+Y3jCNKYqZ4kRxqlgoloq14kxxrtAoLBSWCiuFjXraqvtOPe9V3qpfR/U4qXGn1r3KB3W5qjwpimamOdGcahaapWatOdOcazQaC42lxkpjo5+2+r7TP/Y6P+hxq1+OOp00Or3utQz6ctVy03+SphhmhhPDqWFhWBrWhjPDuUFjsDBYGqwMNma0Nfed+bE3zweD1vw+mnQyOBvpzLo3GAyuBjeDZCiWmeXEcmpZWJaWteXMcm7RWCwslhYri40dbW3a2W97+3ywaO33o00ni7Mdd3bdWwwWV4ubRbIUx8xx4jh1LBxLx9px5jh3aBwWDkuHlcPGjbYu7dzL3uUHh9b9PLr7yeHsxp1b9w6Dw9Xh5pAcxTPznHhOPQvP0rP2nHnOPRqPhcfSj1b+sfHY+rTzL3ufH/y99T+P/n7yX85eOr/uPQaPq8fNI3lKYBY4CZwGFoFlYB04C5yHcRMui5Avw3gTsA2PXfi1D/kh/GlDfgz3U8jP4f8urPuAIeAacAtIgSLMhBPhVFgIS2EtnAnn8tTIZSH5UmQj2MpjJ4+9SCv5US4nyTtZ94JBcBXcBOnfk7HImL1l8ZbZOxbvmL1n8Z7ZBxYfmH1k8ZHZJxafmH1m8ZnpCyQii5hETCOKiDKijphFzGPVxGoVq02strE6xKqN1TlWXaz6WA2xusUq/bNfUXzFX235El0='
CHANGES={66:105,67:224,452:131,453:224,504:22,511:26,518:30,525:36,532:44,640:124,641:224}
EXTENSION=bytes.fromhex('00cd5380473a68e0fefa30063c3268e0afc978c9af3268e0c38382e5c5210b8f06057eb720052310f91807060a0e20cd288ac1e1c33782')
def checksum(buf):
 x=0
 for b in buf:x^=b
 return buf+bytes([x])
def blocks(tap):
 i=0;r=[]
 while i<len(tap):
  size=struct.unpack_from('<H',tap,i)[0];i+=2
  assert 2<=size and i+size<=len(tap)
  block=tap[i:i+size];i+=size
  assert checksum(block[:-1])==block
  r.append(block)
 assert i==len(tap) and len(r)==6
 return r
def rebuild(data):
 assert hashlib.sha256(data).hexdigest()==OLD,'El origen no es el TAP oficial v1.0'
 b=blocks(data)
 title=bytearray(b[3][1:-1])
 assert len(title)==6912
 diff=zlib.decompress(base64.b64decode(TITLE))
 assert len(diff)==792
 for i in range(0,len(diff),3):
  addr,value=struct.unpack_from('<HB',diff,i)
  title[addr]=value
 code=bytearray(b[5][1:-1])
 assert len(code)==24680 and code[0x0f24:0x0f24+6912]==b[3][1:-1]
 code[0x0f24:0x0f24+6912]=title
 for offset,value in CHANGES.items():code[offset]=value
 code.extend(EXTENSION)
 assert len(code)==24735
 header=bytearray(b[4][:-1])
 assert len(header)==18
 header[12:14]=struct.pack('<H',len(code))
 b[3]=checksum(bytes([255])+title)
 b[4]=checksum(header)
 b[5]=checksum(bytes([255])+code)
 output=b''.join(struct.pack('<H',len(x))+x for x in b)
 assert hashlib.sha256(output).hexdigest()==NEW,'El resultado NO coincide con la v1.1 aprobada'
 assert blocks(output)==b
 return output
if __name__=='__main__':
 ap=argparse.ArgumentParser()
 ap.add_argument('input',type=Path)
 ap.add_argument('output',type=Path)
 args=ap.parse_args()
 result=rebuild(args.input.read_bytes())
 args.output.parent.mkdir(parents=True,exist_ok=True)
 args.output.write_bytes(result)
 print('OK — TAP aprobado v1.1, SHA256',NEW)
