#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jul  5 23:49:11 2021

@author: tssg
"""

from vyper.interfaces import ERC20

implements: ERC20

# Number of Admins
k: constant(int128) = 5

# Admin addresses
#Admins: constant(address[k]) = [0x365EF799914Bd6aCc4774f98b9D2aE6D1620860C, 0x264aF64f72B2F683E3c01B6732Ea6fE49e909176, 0x5fBFb8d95F659686c3059DF4A2A4cba8BD0159c7, 0xE6BC01234760EED06D7B99a4A740fF1Ac1f77CDC, 0xfD38413288240614109389Bdc562e3e899c81A85]

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

event Transfer:
    sender: indexed(address)   
    receiver: indexed(address)
    value: uint256

event TransferName:
    sender_name: String[100]
    sender: indexed(address)   
    Receiver_name: String[100]
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event DataStore:
    _name   : String[100]
    data_co2: int128[l]
    cost_co2: int128[l]
    _Version: int128

event DataUpdate:
    tester: indexed(address)
    _name  : address
    actios: int128[idx] 
    cls   : int128
    credts: uint256 

# initial class, ID =0 and credit value      
Cls:     int128
ID:      int128[idx]
Crd:     int128
DataVersion: int128

# Token namen symbol and decimals   
name    : public(String[64])
symbol  : public(String[32])
decimals: uint256

# token balance 
balanceOf:public( HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
minter: address
creator: constant(String[100]) = "AA"

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
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.totalSupply = init_supply
    self.minter = msg.sender
    
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)
    
    
    self.AdminRegistry[creator] = msg.sender
    
    self.Cls  = _cls
    self.Crd  = _credits
    log DataStore(creator, Co2Data, Co2Cost, _dataVersion )
    
    self.DataVersion = _dataVersion
    
    self.ActionData[_dataVersion] = Co2Data
    self.ActionCost[_dataVersion] = Co2Cost
    
 
#################################  // ########################################

########################## Update data storage ###############################

@external
def UpdateDatabase(_name: String[100], _data: int128[l], _cost: int128[l], _crd: int128): 
    """
     @dev Update data storage.
     @param _DataSetter is the address update data storage
     @param _data is the new CO2 reduction data 
     @param _cost is the cost on implementing Co2 reduction data
     @param _crd is the initial credits given to user when join the system
    """  
    
    assert self.AdminRegistry[_name] != ZERO_ADDRESS,  "Unauthorized Activity"
    self.DataVersion += 1
    
    log DataStore(_name, _data, _cost, self.DataVersion)
    
    self.ActionData[self.DataVersion] = _data
    self.ActionCost[self.DataVersion] = _cost
    
#################################  // ########################################

########################## User Class ########################################

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
 
#################################  // ########################################

########################## Compute User credits ##############################   
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
    # convert initial cost into decimal
    C_01: decimal = convert(C_0, decimal)
    
    # cost increasing factors per class
    alpha: decimal[5] = [0.1, 0.2, 0.3, 0.4, 0.5]
    
    # increase in initial credits 
    C_e: decimal = C_01 + C_01*alpha[_c - 1]
    
    
    Cs: int128 = ceil(C + C_e)
    
    return Cs
#################################  // ########################################

########################## Compute User class ################################

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
#################################  // ########################################

########################## User input data validation #######################
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
#################################  // ########################################

################ Generate an address for a given user name ###################

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
#################################  // ########################################

################ Add an admin level user to the system  ######################
@external
def Register_NewAdmin(_AdminName: String[100], _0xAdminName: Bytes[100], _int1: uint256, _int2: uint256, _int3:uint256):
    # validate legitimate admin
    assert _int1 > 20, "Wrong first registration digit "
    assert _int2 > 20, "Wrong second registration digit "
    assert _int3 > 20, "Wrong third registration digit "
    
    _AdminAddress: address = self.CreateAddres(_0xAdminName, _int1, _int2, _int3)
    
    assert self.AdminRegistry[_AdminName] == ZERO_ADDRESS, "Already registered admin "
    self.AdminRegistry[_AdminName] = _AdminAddress

#################################  // ########################################

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
    # validates a legitimate client
    assert _int1 < 20, "Wrong first registration digit "
    assert _int2 < 20, "Wrong second registration digit "
    assert _int3 < 20, "Wrong third registration digit "
    
    # check a legitimate address
    _address: address = self.CreateAddres(_0xName, _int1, _int2, _int3)
    
    assert self.AdminRegistry[_Name] ==  ZERO_ADDRESS, "Admin-level address"
    
    assert self.ClientRegistry[_Name] == ZERO_ADDRESS, "Already used address "
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

#################################  // ########################################

##############  Register a new client or update an exisitng client ###########
@external
def Check_UserStatus(_Name: String[100], _id: int128[idx]):
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

#################################  // ########################################

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

#################################  // ########################################

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

#################################  // ########################################

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

#################################  // ########################################

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

#################################  // ########################################

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

#################################  // ########################################

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

#################################  // ########################################

################## Get the address of an existing Admin ########################

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

#################################  // ########################################

################## Get the information of an existing user # #################

@view
@external
def UserInformation(_ClientName:String[100]) -> (address, int128[idx], int128, uint256):
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

#################################  // ########################################

################################ View Database ################################

@view
@external
def SystemDataBase(_AdminName: String[100], _version: int128) -> (int128[l], int128[l]):
    
    assert self.AdminRegistry[_AdminName] != ZERO_ADDRESS, "Unauthorized Access"

    return self.ActionData[_version], self.ActionCost[_version]

#################################  // ########################################
# Perform Transaction between clients by using their names from the registry
################################ Transfer token to a clients #################

@external
def TransferToClient(_toName : String[100], _value : uint256) -> bool:
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
    
    _to: address = self.ClientRegistry[_toName]
    
    # Check _toName is an Admin 
    assert self.AdminRegistry[_toName] != _to, "Invalid transaction"
    
    #_AdminName: String[100] = self.AdminRegistry[creator]
    
    self.Token_Balance[creator] -= _value
    self.Token_Balance[_toName] += _value
    
    log TransferName(self.name, msg.sender, _toName, _to, _value)
    
    return True

#################################  // ########################################

################################ Transfer token between clients ###############
   
@external
def TransferClient1toClient2(_fromName : String[100], _toName : String[100], _value : uint256) -> bool:
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
    
    # Check  admins are not involved in  the trasaction
    assert self.AdminRegistry[_fromName] == ZERO_ADDRESS,  "Unauthorized client"
    assert self.AdminRegistry[_toName] == ZERO_ADDRESS, "Unauthorized client"
    
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
def AssignTokenToName( _adminName: String[100],  _toName: String[100], _value: uint256):
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
    
    assert self.ClientRegistry[_toName] != ZERO_ADDRESS, "Unknown user"
    
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    self.totalSupply += _value
    self.Token_Balance[_toName] += _value
    log TransferName(self.name, ZERO_ADDRESS, _toName, _to, _value)