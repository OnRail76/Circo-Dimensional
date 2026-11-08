"""Patch only the O/P keyboard handling in the definitive Circo Dimensional TAP.
Keeps all existing Z80 code, title, pictures, and resources byte-identical;
replaces the first 3 bytes of the old keyboard function with a JP to an
appended routine that detects fresh O/P keypresses rather than key repeats.
"""
from pathlib import Path
import struct

SOURCE_TAP = Path(__file__).resolve().parent.parent/'CIRCO_DIMENSIONAL_NAVIDAD85_V10.tap'
OUTPUT_TAP = Path(__file__).parent/'CIRCO_DIMENSIONAL_48K_DEFINITIVO_CONTROL_TOQUES.tap'
OUTPUT_BIN = Path(__file__).parent/'CIRCO_DIMENSIONAL_CONTROL_TOQUES.bin'

ORG = 0x8000
KEYBOARD = 0x80EC
KEY_FIRE = 0x8133
PLAYER = 0x8ED8
MOVE_CD = 0x8EDB
PLAYER_MOVED_FRAME = 0x8F07
EXPECTED_CODE_BYTES = 24612

class PatchAssembler:
    def __init__(self, address):
        self.address = address
        self.code = bytearray()
        self.labels = {}
        self.relative = []
    def label(self, name):
        self.labels[name] = self.address + len(self.code)
    def op(self, hexdump):
        self.code.extend(bytes.fromhex(hexdump))
    def ld_a_ptr(self, address):
        self.code.extend((0x3a, address&255, address>>8))
    def ld_ptr_a(self, address):
        self.code.extend((0x32, address&255, address>>8))
    def jr(self, opc, label):
        self.code.extend((opc,0));self.relative.append((len(self.code)-1,label))
    def compiled(self):
        for at,name in self.relative:
            relative = self.labels[name] - (self.address + at + 1)
            assert -128 <= relative <= 127, (name,relative)
            self.code[at] = relative & 0xff
        return bytes(self.code)

def make_routine(base_address):
    a = PatchAssembler(base_address)
    a.label('keyboard_by_press')
    a.op('c5')                 # PUSH BC, preserve caller's registers
    a.op('3edf dbfe e603 ee03 47') # LD A,$DF / IN A,($FE) / AND 3 / XOR 3 / LD B,A
    a.ld_a_ptr(MOVE_CD)        # last frame pressed-key mask (0 = neither)
    a.op('ee03 a0 4f')         # XOR 3 / AND B / LD C,A; C = fresh press bits
    a.op('78')                 # LD A,B
    a.ld_ptr_a(MOVE_CD)        # save CURRENT mask regardless of movement
    a.op('79 e602')           # LD A,C / AND 2 -> O newly down?
    a.jr(0x28,'try_p')        # JR Z,try_p
    a.ld_a_ptr(PLAYER)
    a.op('b7')                 # OR A
    a.jr(0x28,'finish')       # JR Z,finish (left edge reached)
    a.op('3d')                 # DEC A
    a.ld_ptr_a(PLAYER)
    a.op('3e01')               # LD A,1
    a.ld_ptr_a(PLAYER_MOVED_FRAME)
    a.jr(0x18,'finish')       # JR finish
    a.label('try_p')
    a.op('79 e601')           # LD A,C / AND 1 -> P newly down?
    a.jr(0x28,'finish')
    a.ld_a_ptr(PLAYER)
    a.op('fe04')               # CP 4
    a.jr(0x28,'finish')
    a.op('3c')                 # INC A
    a.ld_ptr_a(PLAYER)
    a.op('3e01')               # LD A,1
    a.ld_ptr_a(PLAYER_MOVED_FRAME)
    a.label('finish')
    a.op('c1')                 # POP BC
    a.op('c3'+struct.pack('<H',KEY_FIRE).hex()) # JP old key_fire: space behavior unchanged
    return a.compiled()

def split_blocks(tap):
    pos = 0;out=[]
    while pos < len(tap):
        length = int.from_bytes(tap[pos:pos+2],'little')
        if not (2 <= length <= 65535) or pos+2+length>len(tap):
            raise ValueError('Bad TAP block length')
        block = tap[pos+2:pos+2+length]
        if __import__('functools').reduce(lambda z,n:z^n,block,0):
            raise ValueError('Bad checksum')
        out.append(block)
        pos += 2 + length
    assert pos==len(tap)
    return out

def with_checksum(original):
    x=0
    for ch in original:x^=ch
    return original + bytes([x])

def assemble_tap(blocks):
    return b''.join(struct.pack('<H',len(b))+b for b in blocks)

def build(input_tap=SOURCE_TAP,output_tap=OUTPUT_TAP):
    blocks=split_blocks(Path(input_tap).read_bytes())
    assert len(blocks)==6 and blocks[4][0:2]==b'\x00\x03' and blocks[-1][0]==255
    assert blocks[-1][1:-1] and blocks[4][2:12].rstrip()==b'CIRCO Z80'
    program = bytearray(blocks[-1][1:-1])
    assert len(program)==EXPECTED_CODE_BYTES
    assert program[KEYBOARD-ORG:KEYBOARD-ORG+5]==bytes.fromhex('3adb8e b7 28')
    patch_address = ORG + len(program)
    patch=make_routine(patch_address)
    assert patch_address+len(patch)<0xff00
    program[KEYBOARD-ORG:KEYBOARD-ORG+3]=b'\xc3'+struct.pack('<H',patch_address)
    program.extend(patch)
    # Update only the CODE block size and payload; every other tape block stays identical.
    blocks[4]=with_checksum(blocks[4][:-1][:12]+struct.pack('<H',len(program))+blocks[4][:-1][14:])
    blocks[5]=with_checksum(bytes([255])+program)
    output=assemble_tap(blocks)
    assert split_blocks(output)==blocks
    assert all(split_blocks(Path(input_tap).read_bytes())[i]==blocks[i] for i in range(4))
    Path(output_tap).write_bytes(output)
    OUTPUT_BIN.write_bytes(program)
    return bytes(program),patch

if __name__=='__main__':
    code,patch=build()
    print('Original machine code:',EXPECTED_CODE_BYTES,'bytes')
    print('Patched code:',len(code),'bytes')
    print('Patch routine:',len(patch),'bytes at',hex(ORG+EXPECTED_CODE_BYTES))
    print('Output:',OUTPUT_TAP)
