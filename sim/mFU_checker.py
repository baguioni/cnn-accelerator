import os
import time
from typing import *

class Int(int):
    def __new__(cls, value, width=8):
        if width <= 1:
            raise ValueError("Width must be greater than 1 to split into hi and lo.")
        if value >= (1 << width) or value < -(1 << (width - 1)):
            raise ValueError(f"Value '{value}' cannot be contained in width '{width}'")
                
        obj = super().__new__(cls, value & ((1<<width)-1))
        obj.width = width
        return obj

    @property
    def hi(self):
        if self.width <= 1:
            raise AttributeError("No hi part for width 1.")
        hi_width = self.width // 2
        return Int(self >> hi_width, hi_width)
    
    @property
    def lo(self):
        if self.width <= 1:
            raise AttributeError("No lo part for width 1.")
        lo_width = self.width // 2
        mask = (1 << lo_width) - 1
        return Int(self & mask, lo_width)
    
    def signed(self):
        if self & (1<<(self.width-1)):
            return int(self) - (1<<self.width)
        return int(self)
        
    def __mul__(self, value):
        if not hasattr(value, 'width'):
            raise TypeError(f"Invalid multiplication. Operands must be of the same type (Int)")
        if self.width != value.width:
            raise ValueError(f"Invalid multiplication. Operands must have the same width")
        
        return Int(self.signed()*value.signed(), self.width*2)
    
    def __add__(self, value):
        if not hasattr(value, 'width'):
            raise TypeError(f"Invalid addition. Operands must be of the same type (Int)")
        if self.width != value.width:
            raise ValueError(f"Invalid addition. Operands must have the same width")

        return Int(self.signed()+value.signed(), self.width+1)
    
    def __repr__(self):
        return f"Int({self.signed()}, width={self.width})"

    def __format__(self, format_spec):
        if format_spec == 'b':
            return f"0b{int(self):0{self.width}b}"
        elif format_spec == 'x':
            return f"0x{int(self):0{(self.width + 3) // 4}x}"
        elif format_spec == 'd':
            return f"{int(self)}"
        else:
            return super().__format__(format_spec)

def timer(func: Callable):
    def temp(*args, **kwargs):
        s = time.perf_counter()
        func(*args, **kwargs)
        e = time.perf_counter()
        print(f"{func.__name__} took {e-s}s")
    return temp

def mFU(a: Int, b: Int, mode, debug=False) -> Int:
    # 8-bit
    if mode==0:
        p = a*b
        if debug:
            print(f'{a:08b} x {b:08b} = {p:016b}')
        return Int(p.signed(),16)
    # 4-bit
    if mode==1:
        p1 = a.hi*b.hi
        p3 = a.lo*b.lo
        if debug:
            print(f'{a.hi:04b} x {b.hi:04b} = {p1:08b}')
            print(f'{a.lo:04b} x {b.lo:04b} = {p3:08b}')
        return Int((p1+p3).signed(),16)
    # 2-bit
    if mode==2:
        p1_hh = a.hi.hi*b.hi.hi
        p1_ll = a.hi.lo*b.hi.lo
        p3_hh = a.lo.hi*b.lo.hi
        p3_ll = a.lo.lo*b.lo.lo
        if debug:
            print(f'{a.hi.hi:02b} x {b.hi.hi:02b} = {p1_hh:04b}')
            print(f'{a.hi.lo:02b} x {b.hi.lo:02b} = {p1_ll:04b}')
            print(f'{a.lo.hi:02b} x {b.lo.hi:02b} = {p3_hh:04b}')
            print(f'{a.lo.lo:02b} x {b.lo.lo:02b} = {p3_ll:04b}')
        return Int(((p1_hh+p1_ll)+(p3_hh+p3_ll)).signed(),16)

@timer
def run_mfu_checker(lim: int = 2**8) -> None:
    with open('./scripts/input.txt' ,'w') as ip, \
         open('./scripts/output.txt','w') as op:
        
        for m in range(3):
            for a in range(lim):
                for b in range(lim):
                    aa = Int(a)
                    bb = Int(b)
                    out = mFU(aa,bb,m)
                    ip.write(f'{m},' )
                    ip.write(f'{aa.signed() },' )
                    ip.write(f'{bb.signed() }\n')
                    op.write(f'{out.signed()}\n')

    os.system("iverilog -g2012 -o dsn -f filelist.txt")
    os.system("vvp dsn")

    with open('./scripts/input.txt' ,'r') as ip, \
         open('./scripts/output.txt','r') as op, \
         open('./scripts/test.txt'  ,'r') as te:
        
        while True:
            i=ip.readline()[:-1]
            o=op.readline()[:-1]
            t=te.readline()[:-1]
            
            # Stop loop: all cases are already checked
            if not (i and o and t):
                break
            
            # Check correctness
            if o != t:
                m,a,b = i.split(',')
                print(f"Test Failed: mode={m} {a} x {b} expected {o} got {t}")

@timer
def run_specific(testcases: List[Tuple[int]]):
    with open('./scripts/input.txt' ,'w') as ip, \
         open('./scripts/output.txt','w') as op:
        
        for m,a,b in testcases:
            aa = Int(a)
            bb = Int(b)
            out = mFU(aa,bb,m)
            ip.write(f'{m},' )
            ip.write(f'{aa.signed() },' )
            ip.write(f'{bb.signed() }\n')
            op.write(f'{out.signed()}\n')

    os.system("iverilog -g2012 -o dsn -f filelist.txt")
    os.system("vvp dsn")

    with open('./scripts/input.txt' ,'r') as ip, \
         open('./scripts/output.txt','r') as op, \
         open('./scripts/test.txt'  ,'r') as te:
        
        while True:
            i=ip.readline()[:-1]
            o=op.readline()[:-1]
            t=te.readline()[:-1]
            
            # Stop loop: all cases are already checked
            if not (i and o and t):
                break
            
            # Check correctness
            if o != t:
                m,a,b = i.split(',')
                print(f"Test Failed: mode={m} {a} x {b} expected {o} got {t}")

def main():
    run_mfu_checker()
    # run_specific([(0,12,7),(0,13,7),(0,12,3),(0,15,3)])

if __name__ == "__main__":
    main()