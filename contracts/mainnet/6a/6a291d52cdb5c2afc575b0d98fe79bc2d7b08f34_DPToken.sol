pragma solidity ^0.4.19;

interface tokenRecipients3dp{ function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract DPToken{
  string public name = "3DP-Token";
  string public symbol = "3DP";
  uint8 public  decimals = 2;
  uint256 public totalSupply=30000000000;
  
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed from, uint256 value);
    function DPToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = 30000000000;  
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;                   
        symbol = tokenSymbol;               
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipients3dp spender = tokenRecipients3dp(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);              
        require(_value <= allowance[_from][msg.sender]);  
        balanceOf[_from] -= _value;                       
        allowance[_from][msg.sender] -= _value;           
        totalSupply -= _value;                            
        Burn(_from, _value);
        return true;
    }
}