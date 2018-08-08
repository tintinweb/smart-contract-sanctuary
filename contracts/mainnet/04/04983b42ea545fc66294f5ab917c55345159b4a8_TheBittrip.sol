pragma solidity ^0.4.24;

interface theBittripRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TheBittrip {
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
    function TheBittrip(
    ) public {
        totalSupply = 250000000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = "The Bittrip Token";                                   // Set the name for display purposes
        symbol = "BT";                               // Set the symbol for display purposes
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
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
        theBittripRecipient spender = theBittripRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

 
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value); 
        balanceOf[msg.sender] -= _value;           
        totalSupply -= _value;                    
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);               
        require(_value <= allowance[_from][msg.sender]);  
        balanceOf[_from] -= _value;                        
        allowance[_from][msg.sender] -= _value;      
        totalSupply -= _value;                            
        emit Burn(_from, _value);
        return true;
    }
}