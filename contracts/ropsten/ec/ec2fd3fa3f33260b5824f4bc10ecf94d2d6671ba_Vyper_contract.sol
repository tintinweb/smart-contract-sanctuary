registry: HashMap[String[100], address]


# Number of Admins
k: constant(int128) = 5

# Admin addresses
Admins: constant(address[k]) = [0x365EF799914Bd6aCc4774f98b9D2aE6D1620860C, 0x264aF64f72B2F683E3c01B6732Ea6fE49e909176, 0x5fBFb8d95F659686c3059DF4A2A4cba8BD0159c7, 0xE6BC01234760EED06D7B99a4A740fF1Ac1f77CDC, 0xfD38413288240614109389Bdc562e3e899c81A85]


# Number of CO2 reductions
l: constant(int128) = 5

# Implemented action IDs
idx: constant(int128) = 3

# CO2 reduction data
Co2Data: constant(int128[l]) = [10,30,50,60,80]

# CO2 reduction cost
Co2Cost: constant(int128[l]) = [10,-20,50,-10,20]

# CO2 reduction class 
Class_limits: constant(int128[4]) = [20,40,60,80]


Cls:     public(int128)
ID:      public(int128[idx])
Crd:     public(int128)


event DataStore:
    setter  : indexed(address)
    data_co2: int128[l]
    cost_co2: int128[l]
    crd     : int128

event DataUpdate:
    tester: indexed(address)
    name  : address
    actios: int128[idx] 
    cls   : int128
    credts: int128  

@external
def __init__( _cls: int128, _crd: int128):

    assert _crd > 0

    self.Cls  = _cls
    self.Crd  = _crd
        
    count: int128 = 0
    admins: address[k] = Admins

    for i in range(k):
        
        if msg.sender == admins[i]:
            count +=1
            
    # Permission to deploy the Contract
    assert count > 0, "Unauthorized User"
    
    log DataStore( msg.sender, Co2Data, Co2Cost, _crd )


# Approval to register as a new client
@internal
def approval(_address:address) -> int128:
    
    count: int128 = 0
    admins: address[k] = Admins

    for i in range(k):
        
        if _address == admins[i]:
            count +=1
    
    return count 

# Update data storage
@external
def UpdateStore(_DataSetter: address, _data: int128[l], _cost: int128[l], _crd: int128): 
  
    approve: int128 = self.approval(_DataSetter) 
    assert approve > 0, "UNauthorized User"
  
    log DataStore(_DataSetter, Co2Data, Co2Cost, _crd )


# CO2 reduction class
@internal 
def CPFClass(_CO_Reduction: int128) -> int128:
    
    # CFP class
    c: int128 = 0
        
    if _CO_Reduction > Class_limits[3]: 
        c = 5
    elif ( _CO_Reduction <= Class_limits[3] ) and ( _CO_Reduction > Class_limits[2]):
        c = 4
    elif ( _CO_Reduction <= Class_limits[2]) and ( _CO_Reduction > Class_limits[1]):
        c = 3
    elif ( _CO_Reduction <= Class_limits[1]) and ( _CO_Reduction > Class_limits[0]):
        c = 2
    else:
        c = 1

    return c 
    
 # Update CO2 credits based on CO2 reduction actions     
@internal
def Credits(_id: int128[idx], _c: int128) -> int128:
    
    self.ID   = _id
    C_0: int128 = self.Crd
    
    A: int128[l] = Co2Cost
    
    # Total credits spent (x) or earned (y) 
    x: int128[idx] = empty(int128[idx])
    y: int128[idx] = empty(int128[idx])
    
    l_n: int128 = 0
    m_n: int128 = 0
    for i in range(0,idx):
        p: int128 = _id[i]
        
        if A[p] < 0:
            x[i] = A[p]
            l_n += x[i]
        else:
            y[i] = A[p]
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
    
    # Remaining credits based on implemented actions 
    C: decimal = m1 - C_s
    
    # Cost gained for being in class
    # convert initial cost into decimal
    C_01: decimal = convert(C_0, decimal)
    
    # cost increasing factors per class
    alpha: decimal[5] = [0.1, 0.2, 0.3, 0.4, 0.5]
    
    # increase in initial credits 
    C_e: decimal = C_01 + C_01*alpha[_c - 1]
    
    
    Cs: int128 = ceil(C + C_e)
    
    return Cs

# CO2 reduction class for implemented CO2 reduction actions 
@internal
def Co2Cls( _id: int128[idx]) -> int128:

    A: int128[l] = Co2Data
         
    # Total CO2 emission from all actions
    a: int128 = 0
    for i in range(0, l):
        a += A[i]
    
    # Total CO2 emission from selected actions     
    Va: int128[idx] = empty(int128[idx])
    b: int128 = 0
    for i in range(0,idx):
        p: int128 = _id[i]
        Va[i] = A[p]
        b += Va[i]
           
    a1: decimal =  convert(a, decimal)
    b1: decimal =  convert(b, decimal)
    
    # Total CO2 emission from selecteced actions as a percentage of total emission of all possible actions  
    Rs1: decimal = (b1/a1)*100.0
    Rs: int128   = ceil(Rs1)

    # Select the class farm belongs to
    c: int128 = self.CPFClass(Rs)
    
    return c

# Farming action validation
@internal
def DataSize(_id: int128[idx]) -> int128:
    a: int128[l] = empty(int128[l])
    for i in range(l):
        a[i] = i
    
    count: int128 = 0
    for i in range(idx):
        id_i: int128 = _id[i]
        for j in range(l):
            if id_i == a[j]:
                count += 1
    return count

# Register a new client or update an exisitng client
@external
def register(name: String[100], _address: address, _id: int128[idx]):
    
    # check a legitimate address
    approve_1: int128 = self.approval(_address) 
    assert approve_1 == 0, "Admin-level address"
    
    cls: int128 = 0
    crd: int128 = 0
    
    if self.registry[name] == ZERO_ADDRESS:
        self.registry[name] = _address
        crd = self.Crd
        cls = self.Cls
        
        log DataUpdate(_address, self.registry[name], _id, cls, crd)
    else:
        
        # validate Faming Actions 
    
        approve_2: int128 = self.DataSize(_id)
        assert approve_2 == 3, "Invalid Faming Actions"
        
        cls  = self.Co2Cls(_id)
        crd  = self.Credits(_id, cls)
        
        log DataUpdate(_address, self.registry[name], _id, cls, crd)
    
 
 
@external
def ASS1(name: String[100], _tester: address, _id: int128[idx]) -> (int128, int128):
    
    #self.ID  = _id
    #self.Crd = _crd

    A: int128[l] = Co2Data
         
    # Total CO2 emission from all actions
    a: int128 = 0
    for i in range(0, l):
        a += A[i]
    
    # Total CO2 emission from selected actions     
    Va: int128[idx] = empty(int128[idx])
    b: int128 = 0
    for i in range(0,idx):
        p: int128 = _id[i]
        Va[i] = A[p]
        b += Va[i]
           
    a1: decimal =  convert(a, decimal)
    b1: decimal =  convert(b, decimal)
    
    # Total CO2 emission from selecteced actions as a percentage of total emission of all possible actions  
    Rs1: decimal = (b1/a1)*100.0
    Rs: int128   = ceil(Rs1)

    # Select the class farm belongs to
    c: int128 = self.CPFClass(Rs)
    
    # Cost earned from CO2 reductions actions 
    Cs: int128 = self.Credits( _id, c)
    
    log DataUpdate(_tester, self.registry[name], _id, c, Cs)
    
    return c,Cs       
    

@view
@external
def lookup(name: String[100], _id: int128[idx]) -> (address):
    #cls: int128  = self.Co2Cls(_id)
    #crd: int128  = self.Credits(_id, cls)
    return self.registry[name]