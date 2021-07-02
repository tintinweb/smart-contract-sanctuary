from vyper.interfaces import ERC20

implements: ERC20

registry: HashMap[String[100], address]

# Number of Admins
k: constant(int128) = 5

# Admin addresses
Admins: constant(address[k]) = [0x365EF799914Bd6aCc4774f98b9D2aE6D1620860C, 0x264aF64f72B2F683E3c01B6732Ea6fE49e909176, 0x5fBFb8d95F659686c3059DF4A2A4cba8BD0159c7, 0xE6BC01234760EED06D7B99a4A740fF1Ac1f77CDC, 0xfD38413288240614109389Bdc562e3e899c81A85]


l: constant(int128) = 5

idx: constant(int128) = 3
V: int128[l]

# CO2 reduction data
Co2Data: constant(int128[l]) = [10,30,50,60,80]

# CO2 reduction cost
Co2Cost: constant(int128[l]) = [10,-20,50,-10,20]

# CO2 reduction class 
Class_limits: constant(int128[4]) = [20,40,60,80]

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256
    #Data: int128[l]
    #ids: int128[idx]
    #CO2_Class: int128

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

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
    
Cls:     public(int128)
ID:      public(int128[idx])
Crd:     public(int128)
    
name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
minter: address



@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _credits: int128, _cls: int128):
    """
    @dev initialize parameters

    Parameters
    ----------
    _name : String[64]
        token name.
    _symbol : String[32]
        token symbol.
    _decimals : uint256
        decimals.
    _credits : int128
        initial credits offered to user at the joining  the system.

    Returns
    -------
    None.

    """ 
    init_supply: uint256 = convert(_credits, uint256) * 10 ** _decimals
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.totalSupply = init_supply
    self.minter = msg.sender
    
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)
    
    self.Cls  = _cls
    self.Crd  = _credits
    log DataStore( msg.sender, Co2Data, Co2Cost, _credits )
    
    
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
    """
     @dev Update data storage.
     @param _DataSetter is the address update data storage
     @param _data is the new CO2 reduction data 
     @param _cost is the cost on implementing Co2 reduction data
     @param _crd is the initial credits given to user when join the system
    """  
    approve: int128 = self.approval(_DataSetter) 
    assert approve > 0, "UNauthorized User"
  
    log DataStore(_DataSetter, Co2Data, Co2Cost, _crd )


# CO2 reduction class
@internal 
def CPFClass(_CO_Reduction: int128) -> int128:
    """
    @dev compute the Co2 reduction class 

    Parameters
    ----------
    _CO_Reduction : int128
        the total CO2 reduction

    Returns
    -------
    int128
        Co2 reduction class.

    """
    
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
    """
    @dev compute the credits hols by a user

    Parameters
    ----------
    _id : int128[idx]
        farming action IDs implemented.
    _c : int128
        Co2 reduction class.

    Returns
    -------
    int128
        Credits value based on implemented actions .

    """
    
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
    """
    @dev compute the CO2 reduction class

    Parameters
    ----------
    _id : int128[idx]
        implemented farming actions .

    Returns
    -------
    int128
        Co2 reduction class.

    """

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
    """
    @dev validates implemented farming actions 

    Parameters
    ----------
    _id : int128[idx]
        actions implemented .

    Returns
    -------
    int128
       Implemented action IDs matche with the stored action IDs.

    """
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
    """
    @dev allows new user to register and old users to update their credits 

    Parameters
    ----------
    name : String[100]
        user name.
    _address : address
        address.
    _id : int128[idx]
        actions implemented.

    Returns
    -------
    None.

    """
    
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
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    
    log Transfer(msg.sender, _to, _value)
    
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    
    self.balanceOf[_from] -= _value
    self.balanceOf[_to]   += _value
    
    # NOTE: vyper does not allow underflows
    #      so the following subtraction would revert on insufficient allowance
   
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
         This encapsulates the modification of balances such that the
         proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)


@internal
def _burn(_to: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    assert _to != ZERO_ADDRESS
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender.
    @param _value The amount that will be burned.
    """
    self._burn(msg.sender, _value)


@external
def burnFrom(_to: address, _value: uint256):
    """
    @dev Burn an amount of the token from a given account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    self.allowance[_to][msg.sender] -= _value
    self._burn(_to, _value)