pragma solidity ^0.4.23;



contract OUTPUTS {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    mapping (address => uint256) public balances;
    string public name;   
    address public owner = msg.sender;
  
    constructor (
        string _tokenName
      
    ) public {
        name = _tokenName;                                 
    }
    
    function getOwner() public view returns (address xowner) {
    return owner;
  }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function returnBoolean(bool bo) public view returns (bool boo) {
            return bo;
    }

    function returnBooleanInverted(bool bo) public view returns (bool boo) {
            return !bo;
    }
    function returnUint8(uint8 val) public view returns (uint8 uinteger8) {
                return val;
    }
    function returnUint16(uint16 val) public view returns (uint16 uinteger16) {
                return val;
    }
    function returnUint32(uint32 val) public view returns (uint32 uinteger32) {
                return val;
    }
    function returnUint64(uint64 val) public view returns (uint64 uinteger64) {
                return val;
    }
    function returnUint128(uint128 val) public view returns (uint128 uinteger128) {
                return val;
    }
    function returnUint256(uint256 val) public view returns (uint256 uinteger256) {
                return val;
    }
    
    
    function returnInt8(int8 val) public view returns (int8 integer8) {
                return val;
    }
    function returnInt16(int16 val) public view returns (int16 integer16) {
                return val;
    }
    function returnInt32(int32 val) public view returns (int32 integer32) {
                return val;
    }
    function returnInt64(int64 val) public view returns (int64 integer64) {
                return val;
    }
    function returnInt128(int128 val) public view returns (int128 integer128) {
                return val;
    }
    function returnInt256(int256 val) public view returns (int256 integer256) {
                return val;
    }
    
    
    function returnString(string val) public view returns (string value) {
                return val;
    }

    function returnAddress(address val) public view returns (address value) {
                    return val;
    }
    
    function returnArrayBytes1(uint8 len) public view returns (bytes value) {
                     bytes memory b = new bytes(len);
                     for (uint8 i=0; i<b.length; i++) {
                             b[i] = 13;
                      }
                    return b;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    function returnBytes1(bytes arr) public view returns (bytes value) {
                     
                    return arr;
    }

}