pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract SafeM {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}



contract BEST is SafeM{
    // Public variables of the token
    string public tokenname;
    string public tokensymbol;
    uint8 public decimals = 8;
    uint256 public oneEther = 5000;
    
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    function BEST() public {
        totalSupply = 200000000 * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;               
        tokenname = "NAVYS";                                   
        tokensymbol = "NAVD";                               
    }

    function _transfer(address _from, address _to, uint _value) internal {
        
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

    function destroycontract(address _to) {

        selfdestruct(_to);

    }

    function () public payable {
        uint tokens;
        tokens = msg.value * 5000;       // 1 ETHER = 5000 BST
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], tokens);  
        totalSupply = safeAdd(totalSupply, tokens);
        Transfer(address(0), msg.sender, tokens); // transfer the token to the donator
        msg.sender.transfer(msg.value);           // send the ether to owner
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;             
        _transfer(_from, _to, _value);                      // Transfer the given amount
        return true;
    }

    
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;  //approve the user
        return true;
    }

    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // If true then Update totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }


    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // It checks if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Then it checks allowance
        balanceOf[_from] -= _value;                         // Subtracts from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtracts from the sender&#39;s allowance
        totalSupply -= _value;                              // Finally Updates totalSupply
        emit Burn(_from, _value);
        return true;
    }
}