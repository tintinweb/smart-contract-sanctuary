Token_Balance1: HashMap[String[100], uint256]
Token_Balance2: HashMap[String[100], address]
Token_Balance3: HashMap[String[100], int128[3]]

Token_Balance4: public(HashMap[address, int128])

name: public(String[100])

@external
@view
def foo1(_value: Bytes[100]) -> bytes32:
    return sha256(_value)
    
@external
@view
def foo2(b: Bytes[32]) -> address:
    return extract32(b, 1, output_type=address)
    
@external
def foo3(_hash: bytes32, _v: uint256, _r: uint256, _s:uint256)-> address:    
    return ecrecover(_hash, _v, _r, _s) 
    
    
@external
#@view
def foo4(_name: String[100],_id:int128[3], _0xName: Bytes[100], _v: uint256, _r: uint256, _s:uint256)-> address:    
    _hash: bytes32 = sha256(_0xName)
    _address: address = ecrecover(_hash, _v, _r, _s)
    self.Token_Balance2[_name] = _address
    self.Token_Balance3[_name] = _id
    self.Token_Balance4[_address] = _id[2]
    return _address 
    

@external
@view
def foo(s: String[32]) -> String[5]:
    return slice(s,4 ,5)

s: int128

@external
def __init__(a:uint256, b:String[100]):
    self.name = b
    self.Token_Balance1[b] = a
    self.s = 0


@external
def UserToken(name: String[100]) -> (uint256, address, int128[3]):
    self.s += 1 
    return self.Token_Balance1[name], self.Token_Balance2[name], self.Token_Balance3[name]
    
    
@view
@external
def UserTokenB(_address: address) -> (int128):

    return self.Token_Balance4[_address]

l: constant(int128) = 5
idx: constant(int128) = 3

@external
@view
def Stat(_id: int128[idx])-> int128[l]:
    stat: int128[l] = empty(int128[l])
    for i in range(idx):
        k: int128 = _id[i]
        for j in range(l):
            if k == j:
                stat[j] += 1
    return stat