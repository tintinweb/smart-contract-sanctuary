contract BEXP {  
    /* This creates an array with all balances */  
    mapping (address => uint256) public balanceOf;  
      
    string public name;  
    string public symbol;  
    uint8 public decimals;  
      
    event Transfer(address indexed from, address indexed to, uint256 value);  
          
    /* Initializes contract with initial supply tokens to the creator of the contract */  
    function BEXP () public {  
        decimals = 8;       // Amount of decimals for display purposes  
        balanceOf[msg.sender] = 1000000000 * 10**decimals;             // Give the creator all initial tokens  
        name = "BitExpress";                                  // Set the name for display purposes  
        symbol = "BEXP";                               // Set the symbol for display purposes  
        
    }  
          
    function transfer(address _to, uint256 _value) public {  
        /* Check if sender has balance and for overflows */  
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);  
  
        /* Add and subtract new balances */  
        balanceOf[msg.sender] -= _value;  
        balanceOf[_to] += _value;  
          
        /* Notify anyone listening that this transfer took place */  
        Transfer(msg.sender, _to, _value);          
    }  
}