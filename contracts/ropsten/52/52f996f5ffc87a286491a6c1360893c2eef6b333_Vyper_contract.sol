l: constant(int128) = 5
m: constant(int128) = 5
data: int128[l]
idx: constant(int128) = 3
V: int128[l]

# Sum of an array
@internal
def sum(d: int128[l]) -> int128:
    a: int128 = 0
    for i in range(0, l):
        a += d[i]
    return a

# Return and entry of an array   
@internal
def get( id: int128, _data: int128[l]) -> int128:
    assert id <= l
    val: int128 = _data[id]
    return val

# Derive a calls corresponding to a CO2 level
@internal
def CO2_Class(Rs: int128, Cls: int128[4]) -> int128:

    c: int128 = 0
        
    if Rs > Cls[3]: 
        c = 5
    elif ( Rs <= Cls[3] ) and ( Rs > Cls[2]):
        c = 4
    elif ( Rs <= Cls[2]) and ( Rs > Cls[1]):
        c = 3
    elif ( Rs <= Cls[1]) and ( Rs > Cls[0]):
        c = 2
    else:
        c = 1

    return c



@external

def ASS(_data: int128[l], ids: int128[idx], Cls: int128[4]) -> int128:
    
    Vals: int128[l] = self.V
    for i in ids:
        _id: int128 = ids[i]
        val: int128 = self.get(_id, _data)
        Vals[i] = val    
    V_s: int128 = self.sum(Vals)
    D_s: int128 = self.sum(_data)
     
    f: int128 = (V_s/D_s)*100
    cls: int128 = self.CO2_Class(f, Cls)
    return cls
    
    

@external
@view
def ASS1(_data: int128[l], Cost: int128[l], C_0: int128, ids: int128[idx], Cls: int128[4]) -> (int128, int128):
    
    #Vals: int128[l] = empty(int128[l])    
    #for i in ids:
        #_id: int128 = ids[i]
        #val: int128 = _data[_id]
        #Vals[i] = val
    
    Va: int128[idx] = empty(int128[idx])
    for i in range(0,idx):
        p: int128 = ids[i]
        Va[i] = _data[p]
    
    b: int128 = 0
    for i in range(0, idx):
        b += Va[i]
    
    a: int128 = 0
    for i in range(0, l):
        a += _data[i]
  
    #V_s: int128 = self.sum(Vals)
    #D_s: int128 = self.sum(_data)
    
    a1: decimal =  convert(a, decimal)
    b1: decimal =  convert(b, decimal)
    
     
    Rs1: decimal = (b1/a1)*100.0
    
    Rs: int128 = ceil(Rs1)
    #cls: int128 = self.CO2_Class(f, Cls)
    
    c: int128 = 0
        
    if Rs > Cls[3]: 
        c = 5
    elif ( Rs <= Cls[3] ) and ( Rs > Cls[2]):
        c = 4
    elif ( Rs <= Cls[2]) and ( Rs > Cls[1]):
        c = 3
    elif ( Rs <= Cls[1]) and ( Rs > Cls[0]):
        c = 2
    else:
        c = 1
        
        
    # Credit value calculation
    x: int128[idx] = empty(int128[idx])
    y: int128[idx] = empty(int128[idx])
    
    l_n: int128 = 0
    m_n: int128 = 0
    for i in range(0,idx):
        p: int128 = ids[i]
        
        if Cost[p] < 0:
            x[i] = Cost[p]
            l_n += x[i]
        else:
            y[i] = Cost[p]
            m_n += y[i]
    
    x1: decimal[idx] = empty(decimal[idx])
    
    for i in range(0,idx):
        x1[i] = convert(x[i], decimal)
    
    l1: decimal =  convert(l_n, decimal)
    m1: decimal =  convert(m_n, decimal)
    
    C_s: decimal = 0.0
    for i in range(0,idx):
        C_s1: decimal = (x1[i]/l1)*x1[i]
        C_s += C_s1
    
    C: decimal = m1 - C_s
    
    # Cost gained for being in class
    
    # convert initial cost into decimal
    C_01: decimal = convert(C_0, decimal)
    
    # cost increasing factors per class
    alpha: decimal[m] = [0.1, 0.2, 0.3, 0.4, 0.5]
    
    # increase in initial credits 
    C_e: decimal = C_01 + C_01*alpha[c-1]
    
    
    Cs: int128 = ceil(C + C_e)
    
    
    return c, Cs
    
    
@external
@view

def CO(Rs: int128, Cls: int128[4]) -> int128:

    c: int128 = 0
        
    if Rs > Cls[3]: 
        c = 5
    elif ( Rs <= Cls[3] ) and ( Rs > Cls[2]):
        c = 4
    elif ( Rs <= Cls[2]) and ( Rs > Cls[1]):
        c = 3
    elif ( Rs <= Cls[1]) and ( Rs > Cls[0]):
        c = 2
    else:
        c = 1

    return c
    

     
@external
@view
def forLoop(a: int128[5], id: int128[3]) -> int128:
    
    x: int128[3] = empty(int128[3])
    y: int128[3] = empty(int128[3])
    
    l_n: int128 = 0
    m_n: int128 = 0
    for i in range(0,3):
        p: int128 = id[i]
        
        if a[p] < 0:
            x[i] = a[p]
            l_n += x[i]
        else:
            y[i] = a[p]
            m_n += y[i]
    
    x1: decimal[3] = empty(decimal[3])
    
    for i in range(0,3):
        x1[i] = convert(x[i], decimal)
    
    l1: decimal =  convert(l_n, decimal)
    m1: decimal =  convert(m_n, decimal)
    
    Rs: decimal = 0.0
    for i in range(0,3):
        Rs1: decimal = (x1[i]/l1)*x1[i]
        Rs += Rs1
    
    C: decimal = m1 - Rs
    
    Cs: int128 = ceil(C)
         
    return Cs