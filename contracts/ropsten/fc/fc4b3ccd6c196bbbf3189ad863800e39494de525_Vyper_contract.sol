from vyper.interfaces import ERC20

implements: ERC20

l: constant(int128) = 5

idx: constant(int128) = 3
V: int128[l]

# Carbon emission reduction data
Co2Data: constant(int128[l]) = [10,30,50,60,80] # Initial data version
ActionData: HashMap[int128, int128[l]]

# Carbon emission reduction cost
Co2Cost: constant(int128[l]) = [10,-20,50,-10,20] # Costs of initial data version
ActionCost: HashMap[int128, int128[l]]

# Carbon reduction class limits 
Class_limits: constant(int128[4]) = [20,40,60,80]

# Registered clients
ClientRegistry: public(HashMap[String[100], address])

# Registered Admins
AdminRegistry: public(HashMap[String[100], address])

# Token balance of registered clients
Token_Balance: public(HashMap[String[100], uint256])

# User Class
User_Class:public( HashMap[String[100], int128])

# User Ids
User_IDs: public(HashMap[String[100], int128[idx]])

# Client Data Sharing Frequency
Client_Frequency: HashMap[String[100], int128]

# Activity Frequency
Activity_Statistics: HashMap[String[100], int128[l]]

# Overall Activity Frequency
All_Activity_Statistics: HashMap[int128, int128[l]]

# User Security number
ClientSecurityNum: HashMap[String[100], uint256[3]]
AdminSecurityNum: HashMap[String[100], uint256[3]]


event Transfer:
    sender: indexed(address)   
    receiver: indexed(address)
    value: uint256

# Transfer credits between two clients 
event TransferName:
    sender_name: String[100]
    sender: indexed(address)   
    Receiver_name: String[100]
    receiver: indexed(address)
    value: uint256

# Approve a credit transfer 
event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

# System data store
event DataStore:
    _name1   : String[100]
    _name2   : String[100]
    data_co2 : int128[l]
    data_cost: int128[l]
    _Version : int128

# Client data store
event DataUpdate:
    tester : indexed(address)
    _name  : address
    actios : int128[idx] 
    cls    : int128
    credts : uint256 

# initial class, ID =0 and credit value, system data version and client data sharing attempt      
Cls : int128
ID  : int128[idx]
Crd : int128
DataVersion : int128
SharingFrequency : int128

# Token namen symbol and decimals   
name    : public(String[64])
symbol  : public(String[32])
decimals: uint256

# token balance 
balanceOf  :public( HashMap[address, uint256])
allowance  : public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
minter     : address
creator    : constant(String[100]) = "AA"
allowanceName: public(HashMap[String[100], HashMap[String[100], uint256]])

#################################  // ########################################

########################### Constructor function  ###############################

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _credits: int128, _cls: int128, _dataVersion: int128):
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
    self.name                  = _name
    self.symbol                = _symbol
    self.decimals              = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.totalSupply           = init_supply
    self.minter                = msg.sender
    self.Cls                   = _cls
    self.Crd                   = _credits
    self.DataVersion           = _dataVersion
    self.SharingFrequency      = 0

    self.AdminRegistry[self.name] = msg.sender
    self.ActionData[_dataVersion] = Co2Data
    self.ActionCost[_dataVersion] = Co2Cost
    
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)
    log DataStore(self.name, self.name, Co2Data, Co2Cost, _dataVersion )
      
 
#################################  // ########################################

##############################################################################
#                Carbon reduction class and carbon credits                   #
############################## User Class ####################################

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
    elif ( _CO_Reduction <= Class_limits[3]) and ( _CO_Reduction > Class_limits[2]):
        c = 4
    elif ( _CO_Reduction <= Class_limits[2]) and ( _CO_Reduction > Class_limits[1]):
        c = 3
    elif ( _CO_Reduction <= Class_limits[1]) and ( _CO_Reduction > Class_limits[0]):
        c = 2
    else:
        c = 1

    return c 

########################## Carbon reduction class ############################

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
    A: int128[l] = self.ActionData[self.DataVersion]
         
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
    
############################## User carbon credits ############################  

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
        Credits value based on implemented actions.

    """
    
    self.ID     = _id
    C_0: int128 = self.Crd
    
    A: int128[l] = self.ActionCost[self.DataVersion]
    
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
    C_01: decimal = convert(C_0, decimal)
    
    # cost increasing factors per class
    alpha: decimal[5] = [0.1, 0.2, 0.3, 0.4, 0.5]
    
    # increase in initial credits 
    C_e: decimal = C_01 + C_01*alpha[_c - 1]    
    
    Cs: int128 = ceil(C + C_e)
    
    return Cs

##############################  Input data validation ########################

@internal
def DataSize(_id: int128[idx]) -> int128:
    """
    @dev validates implemented farming actions 

    Parameters
    ----------
    _id : int128[idx]
        actions implemented.

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

########################## User activity statistics ##########################

@internal
def Stat(_id: int128[idx])-> int128[l]:
    stat: int128[l] = empty(int128[l])
    for i in range(idx):
        kk: int128 = _id[i]
        for j in range(l):
            if kk == j:
                stat[j] += 1
    return stat
    
#################################  // ########################################

##############################################################################
#                   Create new users and update their status                 #
##############################################################################

################ Generate an address to add users into the system #############

@internal
def CreateAddres(_0xName: Bytes[100], _v: uint256, _r: uint256, _s:uint256)-> address: 
    """
    @dev Create address for a given name

    Parameters
    ----------
    _0xName : Bytes[100]
        user name 0x+Name.
    _v, _r, _s : uint256
        Aritrary numbers that user wants to use in creating an user address.
    Returns
    -------
    address
        Address of Name .

    """   
    _hash: bytes32 = sha256(_0xName)
    return ecrecover(_hash, _v, _r, _s) 

################ Add an admin level user to the system  ######################

@external
def Register_NewAdmin(_AdminName: String[100], _0xAdminName: Bytes[100], _int1: uint256, _int2: uint256, _int3:uint256):
    
    # validate legitimate admin
    assert _int1 > 20, "Wrong first registration digit "
    assert _int2 > 20, "Wrong second registration digit "
    assert _int3 > 20, "Wrong third registration digit "
    
    # store security number
    Num: uint256[3] = empty(uint256[3])
    Num[0] = _int1
    Num[1] = _int2
    Num[2] = _int3
    self.AdminSecurityNum[_AdminName] = Num
    
    _AdminAddress: address = self.CreateAddres(_0xAdminName, _int1, _int2, _int3)
    
    assert self.AdminRegistry[_AdminName] == ZERO_ADDRESS, "Already registered admin "
    self.AdminRegistry[_AdminName] = _AdminAddress

########################## Update data storage ###############################

@external
def UpdateDatabase(_AdminName1: String[100],_int11:uint256, _int12:uint256, _int13:uint256, _AdminName2: String[100],_int21:uint256, _int22:uint256, _int3:uint256, _data: int128[l], _cost: int128[l]): 
    """
     @dev Update data storage.
     @param _DataSetter is the address update data storage
     @param _data is the new CO2 reduction data 
     @param _cost is the cost on implementing Co2 reduction data
     @param _crd is the initial credits given to user when join the system
    """  
    # Check the validity of the Admin1    
    assert self.AdminRegistry[_AdminName1] != ZERO_ADDRESS,  "Unauthorized Activity"
    assert self.AdminRegistry[_AdminName2] != ZERO_ADDRESS,  "Unauthorized Activity"
    
    # Check the validity of the Admin1
    _Num1: uint256[3] = self.AdminSecurityNum[_AdminName1]
    
    assert _Num1[0] == _int11, "Wrong first digit"
    assert _Num1[1] == _int12, "Wrong second digit"
    assert _Num1[2] == _int13, "Wrong third digit"
    
    # Check the validity of the Admin2
    _Num2: uint256[3] = self.AdminSecurityNum[_AdminName2]
    
    assert _Num2[0] == _int11, "Wrong first digit"
    assert _Num2[1] == _int12, "Wrong second digit"
    assert _Num2[2] == _int13, "Wrong third digit"
    
    self.DataVersion += 1
    
    log DataStore(_AdminName1, _AdminName2, _data, _cost, self.DataVersion)
    
    self.ActionData[self.DataVersion] = _data
    self.ActionCost[self.DataVersion] = _cost

################################ Register New User ###########################

@external
def Register_NewClient(_Name: String[100], _0xName: Bytes[100], _int1: uint256, _int2: uint256, _int3:uint256):
    """
    @dev allows new user to register and old users to update their credits 

    Parameters
    ----------
    name : String[100]
        User name.
    _0xName : Bytes[100]
        Input nane as Bytes[100]; 0x+name.
    _id : int128[idx]
        Implemented action IDs.
    _int1, _int2, _int2 : uint256
        arbitrary numbers that user wish to use create an address for the user

    Returns
    -------
    None.

    """
    # checks the validity of client registration numbers 
    assert _int1 < 20, "Wrong first  registration digit "
    assert _int2 < 20, "Wrong second registration digit"
    assert _int3 < 20, "Wrong third  registration digit "
    
    # create and address for the given name
    _address: address = self.CreateAddres(_0xName, _int1, _int2, _int3)
    
    # check the client is not an Admin 
    assert self.AdminRegistry[_Name] ==  ZERO_ADDRESS, "Admin-level address"
    
    # check the client is not before registered in the client registry 
    assert self.ClientRegistry[_Name] == ZERO_ADDRESS, "Already used address "
    
    # Add the client into the ClientRegistry 
    self.ClientRegistry[_Name] = _address
    
    crd: int128 = self.Crd
    cls: int128 = self.Cls
    
    _value: uint256 = convert(crd, uint256) * 10 ** self.decimals
    self.balanceOf[_address] += _value
    
    _id: int128[idx] = empty(int128[idx])
    
    log DataUpdate(_address, self.ClientRegistry[_Name], _id, cls, _value)
    
    self.Token_Balance[_Name] = _value
    self.User_Class[_Name] = cls
    self.User_IDs[_Name] = _id
    
    # Data sharing frequency
    self.Client_Frequency[_Name] = 0#self.SharingFrequency 
    
    # Carbon reduction activity frequency 
    self.Activity_Statistics[_Name] = empty(int128[l])

    # store security number
    Num: uint256[3] = empty(uint256[3])
    Num[0] = _int1
    Num[1] = _int2
    Num[2] = _int3
    self.ClientSecurityNum[_Name] = Num
########################  Update an exisitng client ##########################

@external
def Check_UserStatus(_Name: String[100], _id: int128[idx], _int1: uint256, _int2:uint256, _int3: uint256):
    """
    @dev Allows users to check their status (tokens) 

    Parameters
    ----------
    name : String[100]
        User name.
    _id : int128[idx]
        Implemented action IDs.

    Returns
    -------
    None.

    """
    
    # Retieve the address of name from the registry
    _address: address = self.ClientRegistry[_Name]
    
    assert self.AdminRegistry[_Name] ==  ZERO_ADDRESS, "Admin-level address"
    
    # Check the name is in the user registry
    assert self.ClientRegistry[_Name] != ZERO_ADDRESS, "Unknown User Name"
    
    # Check the validity of the client
    _Num: uint256[3] = self.ClientSecurityNum[_Name]
    
    assert _Num[0] == _int1, "Wrong first digit"
    assert _Num[1] == _int2, "Wrong second digit"
    assert _Num[2] == _int3, "Wrong third digit"
    
    #cls: int128 = 0
    #crd: int128 = 0
    
    # Validate user inputs 
    approve_2: int128 = self.DataSize(_id)
    assert approve_2 == 3, "Invalid Action IDs"
    
    cls:int128  = self.Co2Cls(_id)
    crd: int128  = self.Credits(_id, cls)
    
    _value: uint256 = convert(crd, uint256) * 10 ** self.decimals
    self.balanceOf[_address] += _value
            
    log DataUpdate(_address, self.ClientRegistry[_Name], _id, cls, _value)
    
    self.Token_Balance[_Name] = _value
    self.User_Class[_Name]    = cls
    self.User_IDs[_Name]      = _id
    
    self.Client_Frequency[_Name] += 1
    
    # Carbon reduction activity frequency 
    _priorFre: int128[l] = self.Activity_Statistics[_Name]
    _currntFre: int128[l] = self.Stat(_id)
    _updateFre: int128[l] = empty(int128[l])
    
    for j in range(l):
       _updateFre[j] =  _priorFre[j] + _currntFre[j]
       
    self.Activity_Statistics[_Name] = _updateFre
    
    # Count total data sharing attempts
    _priorFre1: int128[l] = self.All_Activity_Statistics[self.SharingFrequency] 
    
    self.SharingFrequency += 1
    
    _updateFre1: int128[l] = empty(int128[l])
    for j in range(l):
       _updateFre1[j] =  _priorFre1[j] + _updateFre[j]
       
    self.All_Activity_Statistics[self.SharingFrequency] = _updateFre1

#################################  // ########################################

##############################################################################
#                   Token transactions between accounts                      #
##############################################################################

##################Transfer tokens to an existing user ########################

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token to a specified address

    Parameters
    ----------
    _to : address
        The address to transfer to.
    _value : uint256
        The amount to be transferred.

    Returns
    -------
    bool
        True if trasaction is approved.

    """
    
    self.balanceOf[msg.sender] -= _value
    #_to: address = self.registry[_toName]
    self.balanceOf[_to] += _value
    
    log Transfer(msg.sender, _to, _value)
    
    return True

################## Transfer tokens between two existing users #################

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
    @dev Transfer tokens from one address to another.

    Parameters
    ----------
    _from : address
        address The address which you want to send tokens from.
    _to : address
        address The address which you want to transfer to.
    _value : uint256
        the amount of tokens to be transferred.

    Returns
    -------
    bool
        True if trasaction is approved.

    """

    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    
    self.balanceOf[_from] -= _value
    self.balanceOf[_to]   += _value
    
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    
    return True

################## Set up toek spending limit of an existing user ############

@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on 
         behalf of msg.sender.

    Parameters
    ----------
    _spender : address
        The address which will spend the funds.
    _value : uint256
        The amount of tokens to be spent.

    Returns
    -------
    bool
        True if trasaction is approved.

    """

    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

################## Assign tokens to an existing user #########################

@external
def mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.

    Parameters
    ----------
    _to : address
        The account that will receive the created tokens.
    _value : uint256
        The amount that will be created.

    Returns
    -------
    None.

    """    
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)

################## Delete tokens of an existing user ########################

@internal
def _burn(_to: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.

    Parameters
    ----------
    _to : address
        The account whose tokens will be burned.
    _value : uint256
        The amount that will be burned.

    Returns
    -------
    None.

    """

    assert _to != ZERO_ADDRESS
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender. 
    
    Parameters
    ----------
    _value : uint256
        The amount that will be burned.

    Returns
    -------
    None.

    """    
    self._burn(msg.sender, _value)

################## Delete tokens of an existing user ########################

@external
def burnFrom(_to: address, _value: uint256):
    """
    Parameters
    ----------
    _to : address
        The account whose tokens will be burned.
    _value : uint256
        The amount that will be burned.

    Returns
    -------
    None.

    """    
    
    self.allowance[_to][msg.sender] -= _value
    self._burn(_to, _value)

#################################  // ########################################

##############################################################################
#                   Featurs Accessible to Users                              #
##############################################################################
                       
############################ View an existing Admin ##########################

@view
@external
def AdminAddress(_AdminName: String[100]) -> (address):
    """
    @dev Registered address in the registry

    Parameters
    ----------
    name : String[100]
        User Name.

    Returns
    -------
    (address)
        Address corresponding to the user name.

    """
    assert self.AdminRegistry[_AdminName] != ZERO_ADDRESS, "Unauthorized user"

    return self.AdminRegistry[_AdminName]


################################ View Database ################################

@view
@external
def SystemDataBase(_AdminName: String[100], _version: int128) -> (int128[l], int128[l]):
    
    assert self.AdminRegistry[_AdminName] != ZERO_ADDRESS, "Unauthorized Access"

    return self.ActionData[_version], self.ActionCost[_version]

#################### Overall Activity statistics  ############################

@view
@external
def OverallActivityStats() -> (int128, int128[l], int128[l]):
    """
    @ dev Displya overall activity stats

    Parameters
    ----------
    _AdminName : String[100]
        Admin user name.

    Returns
    -------
    (int128, int128[l], int128[l])
        number of data shares, activity Ids and  activity Id frequency.

    """
    #assert self.AdminRegistry[_AdminName] != ZERO_ADDRESS, "Unauthorized user"

    _id:int128[l] = empty(int128[l])
    for i in range(l):
        _id[i] = i
    return self.SharingFrequency,_id, self.All_Activity_Statistics[self.SharingFrequency]

################## Get the address of an existing user ########################

@view
@external
def ClientAddress(_ClientName: String[100]) -> (address):
    """
    @dev Registered address in the registry

    Parameters
    ----------
    name : String[100]
        User Name.

    Returns
    -------
    (address)
        Address corresponding to the user name.

    """

    return self.ClientRegistry[_ClientName]

################## Get the information of an existing user # #################

@view
@external
def ClientInformation(_ClientName:String[100]) -> (address, int128[idx], int128, uint256):
    """
    @dev Registered address in the registry

    Parameters
    ----------
    name : String[100]
        User Name.

    Returns
    -------
    (address)
        Name, Action Ids, User Class, and Balance corresponding to the _address.

    """

    return self.ClientRegistry[_ClientName], self.User_IDs[_ClientName], self.User_Class[_ClientName], self.Token_Balance[_ClientName]


################################ User Activity statistics  ################################

@view
@external
def ClientActivityStats(_Name: String[100]) -> (int128,int128[l], int128[l]):
    
    # Check user validity
    assert self.ClientRegistry[_Name] != ZERO_ADDRESS, "Unauthorized user"
    
    _id:int128[l] = empty(int128[l])
    for i in range(l):
        _id[i] = i
    return self.Client_Frequency[_Name], _id,  self.Activity_Statistics[_Name]


#################################  // ########################################
# Perform Transaction between clients by using their names from the registry
#################### Transfer token to a clients #############################

@external
def TransferToClient(_toName : String[100], _value : uint256, _int1: uint256, _int2: uint256, _int3: uint256) -> bool:
    """
    @dev Transfer token for a specified address

    Parameters
    ----------
    _to : address
        The address to transfer to.
    _value : uint256
        The amount to be transferred.

    Returns
    -------
    bool
        True if trasaction is approved.

    """
    # Check _toName is a resistered user
    assert self.ClientRegistry[_toName] != ZERO_ADDRESS, "Unknown user"
    
    # Check the validity of the client
    _Num: uint256[3] = self.ClientSecurityNum[_toName]
    
    assert _Num[0] == _int1, "Wrong first digit"
    assert _Num[1] == _int2, "Wrong second digit"
    assert _Num[2] == _int3, "Wrong third digit"
    
    _to: address = self.ClientRegistry[_toName]
    
    # Check _toName is an Admin 
    assert self.AdminRegistry[_toName] == ZERO_ADDRESS, "Invalid transaction"
    
    # Check whether client has shared data with the system at least once
    assert self.Client_Frequency[_toName] != 0, "Client must share data at least once"
    
    self.Token_Balance[self.name] -= _value
    self.Token_Balance[_toName] += _value
    
    log TransferName(self.name, msg.sender, _toName, _to, _value)
    
    return True

#################################  // ########################################

################################ Transfer token between clients ###############
   
@external
def TransferClient1toClient2(_fromName : String[100],  _int11: uint256, _int12: uint256, _int13: uint256, _toName : String[100],  _int21: uint256, _int22: uint256, _int23: uint256, _value : uint256) -> bool:
    """
    @dev Transfer tokens from one address to another.

    Parameters
    ----------
    _from : address
        address The address which you want to send tokens from.
    _to : address
        address The address which you want to transfer to.
    _value : uint256
        the amount of tokens to be transferred.

    Returns
    -------
    bool
        True if trasaction is approved.

    """

    # following subtraction would revert on insufficient balance
    
    # Check validity of clients 
    assert self.ClientRegistry[_fromName] != ZERO_ADDRESS,  "Unknown client"
    assert self.ClientRegistry[_toName] != ZERO_ADDRESS, "Unknown Client"
    
    # Check the validity of the client
    _Num1: uint256[3] = self.ClientSecurityNum[_toName]
    
    assert _Num1[0] == _int11, "Wrong first digit"
    assert _Num1[1] == _int12, "Wrong second digit"
    assert _Num1[2] == _int13, "Wrong third digit"
    
    # Check the validity of the client
    _Num2: uint256[3] = self.ClientSecurityNum[_toName]
    
    assert _Num2[0] == _int21, "Wrong first digit"
    assert _Num2[1] == _int22, "Wrong second digit"
    assert _Num2[2] == _int23, "Wrong third digit"
    
    # Check  admins are not involved in  the trasaction
    assert self.AdminRegistry[_fromName] == ZERO_ADDRESS,  "Unauthorized client"
    assert self.AdminRegistry[_toName] == ZERO_ADDRESS, "Unauthorized client"
    
    # Check whether client has shared data with the system at least once
    assert self.Client_Frequency[_fromName] != 0, "Client must share data at least once"
    assert self.Client_Frequency[_toName] != 0,   "Client must share data at least once"
    
    _from: address = self.ClientRegistry[_fromName]
    
    self.Token_Balance[_fromName] -= _value
    
    _to: address = self.ClientRegistry[_toName]
    
    # Check _toName is an Admin 
    assert self.AdminRegistry[_toName] != _to, "Invalid transaction"
    
    self.Token_Balance[_toName]   += _value
    
   
    #self.allowance[_from][msg.sender] -= _value
    log TransferName(_fromName, _from, _toName, _to, _value)
    
    return True

#################################  // ########################################

################################ Assign tokens to a client ###############

@external
def AssignTokenToName( _adminName: String[100], _int11: uint256, _int12: uint256, _int13: uint256,  _toName: String[100], _int21: uint256, _int22: uint256, _int23: uint256, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.

    Parameters
    ----------
    _to : address
        The account that will receive the created tokens.
    _value : uint256
        The amount that will be created.

    Returns
    -------
    None.

    """
    # Check _adminName is a valid Admin 
    assert self.AdminRegistry[_adminName] != ZERO_ADDRESS, "Unauthorized user"
    
    _to: address = self.ClientRegistry[_toName]
    
    # Check _toName is in the client registry 
    assert self.ClientRegistry[_toName] != ZERO_ADDRESS, "Unknown user"
    
    # Check whether client has shared data with the system at least once
    assert self.Client_Frequency[_toName] != 0, "Client must share data at least once"
    
    # Check the validity of the client
    _Num1: uint256[3] = self.ClientSecurityNum[_toName]
    
    assert _Num1[0] == _int11, "Wrong first digit"
    assert _Num1[1] == _int12, "Wrong second digit"
    assert _Num1[2] == _int13, "Wrong third digit"
    
    # Check the validity of the client
    _Num2: uint256[3] = self.ClientSecurityNum[_toName]
    
    assert _Num2[0] == _int21, "Wrong first digit"
    assert _Num2[1] == _int22, "Wrong second digit"
    assert _Num2[2] == _int23, "Wrong third digit"
    
    
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    self.totalSupply += _value
    self.Token_Balance[_toName] += _value
    
    log TransferName(_adminName, self.AdminRegistry[_adminName], _toName, _to, _value)

#################################  // ########################################

################## Delete tokens of an existing user ########################

@internal
def _burnName(_toName: String[100], _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.

    Parameters
    ----------
    _to : address
        The account whose tokens will be burned.
    _value : uint256
        The amount that will be burned.

    Returns
    -------
    None.

    """

    assert self.ClientRegistry[_toName] != ZERO_ADDRESS
    self.totalSupply -= _value
    
    _to: address = self.ClientRegistry[_toName]
    
    self.Token_Balance[_toName] -= _value
    log TransferName(_toName, _to, self.name,  ZERO_ADDRESS, _value)


@external
def DeleteTokens(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender. 
    
    Parameters
    ----------
    _value : uint256
        The amount that will be burned.

    Returns
    -------
    None.

    """    
    self._burnName(self.name, _value)

#################################  // ########################################

################## Delete tokens of an existing user ########################

@external
def DeleteTokensFrom(_toName: String[100], _int1: uint256, _int2: uint256, _int3: uint256, _value: uint256):
    """
    Parameters
    ----------
    _to : address
        The account whose tokens will be burned.
    _value : uint256
        The amount that will be burned.

    Returns
    -------
    None.

    """  
    assert self.ClientRegistry[_toName] != ZERO_ADDRESS  
    
    # Check the validity of the client
    _Num: uint256[3] = self.ClientSecurityNum[_toName]
    
    assert _Num[0] == _int1, "Wrong first digit"
    assert _Num[1] == _int2, "Wrong second digit"
    assert _Num[2] == _int3, "Wrong third digit"
    
    _to: address = self.ClientRegistry[_toName]
    
    
    self.allowanceName[_toName][self.name] -= _value
    self._burnName(_toName, _value)