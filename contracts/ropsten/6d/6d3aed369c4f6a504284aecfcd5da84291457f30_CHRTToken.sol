pragma solidity ^0.4.16;  
contract Token{  
    uint256 public totalSupply;  
  
    function balanceOf(address _owner) public constant returns (uint256 balance);  
    function transfer(address _to, uint256 _value) public returns (bool success);  
  
    event Transfer(address indexed _from, address indexed _to, uint256 _value);  
}  
  
contract CHRTToken is Token {  
  
    string public name;                   
    uint8 public decimals;               
    string public symbol;
    
    mapping (address => uint256) balances;  
    
    function CHRTToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {  
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);    
        balances[msg.sender] = totalSupply; 
  
        name = _tokenName;                     
        decimals = _decimalUnits;            
        symbol = _tokenSymbol;  
    }  

    // token的发送函数
    function _transferFunc(address _from, address _to, uint _value) internal {
        require(_to != 0x0);    
        require(balances[_from] >= _value);       
        require(balances[_to] + _value > balances[_to]);  

        uint previousBalances = balances[_from] + balances[_to]; 
        balances[_from] -= _value; 
        balances[_to] += _value;
        Transfer(_from, _to, _value);  
        assert(balances[_from] + balances[_to] == previousBalances);  
    }
  
    function transfer(address _to, uint256 _value) public  returns (bool success) {
        _transferFunc(msg.sender, _to, _value); 
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {  
        return balances[_owner];  
    }  
}