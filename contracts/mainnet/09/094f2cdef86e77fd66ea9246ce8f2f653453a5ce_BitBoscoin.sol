//-------------------------------------------
// BitBoscoin Digital Asset Token "BOSS" 
// BitBoscoin fixed supply token contract
// Thirty Million Tokens Only
// BitBoscoin @ 2018 BitBoscoin.io  
//-------------------------------------------

pragma solidity ^0.4.24;

contract BitBoscoin {
    /* Public variables of the token */
    string public standard = &#39;BOSS Token&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function BitBoscoin() {

         initialSupply = 30000000000000000000000000;
         name ="BitBoscoin";
        decimals = 18;
         symbol = "BOSS";
        
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
                                   
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
      
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }
}