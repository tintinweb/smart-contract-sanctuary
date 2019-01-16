pragma solidity ^0.4.0;
contract TheAclydProject {
    /* Public variables of the DuqueBrewingCompany */
    string public standard = &#39;The Aclyd Project Bahamas Reg. 123543639&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public corporateRegNumber;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function DuqueBrewingCompany() {

         corporateRegNumber = 123543639;
         name ="The Aclyd Project";
         decimals = 8;
         symbol = "ACLYD";
        
        balanceOf[msg.sender] = corporateRegNumber;              // Give the creator all initial tokens
        totalSupply = corporateRegNumber;                        // Update total supply
                                   
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