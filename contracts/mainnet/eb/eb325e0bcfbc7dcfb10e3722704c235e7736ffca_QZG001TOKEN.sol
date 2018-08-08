pragma solidity ^0.4.8;
contract tokenRecipient { 
	//获得批准
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

contract QZG001TOKEN{
   
    string public standard = &#39;QZG001TOKEN 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

   
    mapping (address => uint256) public balanceOf;
  
    mapping (address => mapping (address => uint256)) public allowance;

    
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Burn(address indexed from, uint256 value);

    
    function QZG001TOKEN() public {
        balanceOf[msg.sender] = 1000000 * 1000000000000000000;             
        totalSupply =  1000000 * 1000000000000000000;                       
        name = "QZC001";                                   // Set the name 	for display purposes
        symbol = "QZGC";                               // Set the symbol for display 	purposes
        decimals = 18;                            // Amount of decimals for display 	purposes
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
       
         require (_to != 0x0);
         require(balanceOf[msg.sender] >= _value);
         require(balanceOf[_to] + _value > balanceOf[_to]);
    
        balanceOf[msg.sender] -= _value;                    
        balanceOf[_to] += _value;                           
        Transfer(msg.sender, _to, _value);            
    }

    /* Allow another contract to spend some tokens in your behalf  */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
     
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx  */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public 
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins  */
    function transferFrom(address _from, address _to, uint256 _value) public
    returns (bool success) {
       
    
        require (_to != 0x0);
         require(balanceOf[_from] >= _value);
         require(balanceOf[_to] + _value > balanceOf[_to]);
         require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
       
       require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;                      // Subtract from the sender
        totalSupply -= _value;                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
       
     
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;                          // Subtract from the sender
        totalSupply -= _value;                               // Updates totalSupply
        Burn(_from, _value);
        return true;
    }
}