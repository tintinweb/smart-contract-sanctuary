contract BEXP {  
    /* This creates an array with all balances */  
    mapping (address => uint256) public balanceOf;
      
    string public name = "BitExpress";  
    string public symbol = "BEXP";  
    uint8 public decimals = 8;  
    uint256 public totalSupply = 1000000000 * 10**8;
    address founder = address(0xe2ce6a2539efbdf0a211300aadb70a416d5d2bec);
      
    event Transfer(address indexed from, address indexed to, uint256 value);  
          
    /* Initializes contract with initial supply tokens to the creator of the contract */  
    function BEXP () public {  
        balanceOf[founder] = totalSupply ;             // Give the creator all initial tokens  
        Transfer(0, founder, totalSupply);
    }  
          
    function transfer(address _to, uint256 _value) public returns (bool success){  
        /* Check if sender has balance and for overflows */  
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);  
  
        /* Add and subtract new balances */  
        balanceOf[msg.sender] -= _value;  
        balanceOf[_to] += _value;  
          
        /* Notify anyone listening that this transfer took place */  
        Transfer(msg.sender, _to, _value);
        
        return true;
    }
}