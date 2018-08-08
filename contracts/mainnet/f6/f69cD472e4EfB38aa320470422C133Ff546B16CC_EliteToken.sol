pragma solidity ^0.4.11;

contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

contract EliteToken { 
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    address owner;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function EliteToken() {
        /* Unless you add other functions these variables will never change */
        balanceOf[this] = 100;
        name = "EliteToken";     
        symbol = "ELT";
        owner = msg.sender;
        
        /* If you want a divisible token then add the amount of decimals the base unit has  */
        decimals = 0;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        /* if the sender doenst have enough balance then stop */
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        
        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        /* Notifiy anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);
    }
    
    /* Buy coins */
    function() payable {
        if (msg.value == 0) { return; }
        owner.transfer(msg.value);
        uint256 amount = msg.value / 1000000000000000000;  // calculates the amount
        if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                   // adds the amount to buyer&#39;s balance
        balanceOf[this] -= amount;                         // subtracts amount from seller&#39;s balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    }
    
    /* Withdraw foreign*/
    function WithdrawForeign(address _tokenContract) returns (bool) {
        if (msg.sender != owner) { throw; }

        ForeignToken token = ForeignToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}