l: constant(int128) = 3
data: decimal[l]
idx: constant(int128) = 2
V: decimal[l]



@internal
def get( id: int128) -> decimal:
    assert id < l
    val: decimal = self.data[id]
    return val

@internal
def sum(d: decimal[l]) -> decimal:
    a: decimal = 0.0
    for i in range(0, l):
        a += d[i]
    return a
 
 
@internal
def foo1() -> (decimal, decimal):
    return 2.0, 3.0   

@internal
def devision(a: decimal, b: decimal) -> decimal:
    return a/b   

@internal
def CO2_Class(Rs: decimal) -> int128:

    c: int128 = 0
        
    if Rs > 80.0: 
        c = 5
    elif ( Rs <= 80.0 ) and ( Rs > 60.0):
        c = 4
    elif ( Rs <= 60.0 ) and ( Rs > 40.0):
        c = 3
    elif ( Rs <= 40.0 ) and ( Rs > 20.0):
        c = 2
    else:
        c = 1

    return c
    
@external
def ASS(_data: decimal[l], ids: int128[idx]) -> int128:

    Vals: decimal[l] = self.V
    for i in ids:
        _id: int128 = ids[i]
        val: decimal = self.get(_id)
        Vals[i] = val    
    V_s: decimal = self.sum(Vals)
    D_s: decimal = self.sum(self.data)

    f: decimal = (V_s/ D_s)*100.0
    c: int128 = self.CO2_Class(f)
    return c
    
@external
@view
def foo2(a: int128[3]) -> int128:

    b: int128 = 0
    for i in range(0, l):
        b += a[i]
    return b