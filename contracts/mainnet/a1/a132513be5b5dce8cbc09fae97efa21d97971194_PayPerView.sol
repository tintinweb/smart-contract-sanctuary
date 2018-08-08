pragma solidity ^0.4.18;

contract PayPerView {
    /* Public variables of the Pay Per View */
    string public standard = &#39;PayPerView 1.0&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function PayPerView () public {

         initialSupply = 120000000000000000;
         name ="Pay Per View";
         decimals = 8;
         symbol = "PPV";
        
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
                                   
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has revert()
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
    }


    /* This unnamed function is called whenever someone tries to send ether to it */
    function () public {
        revert();     // Prevents accidental sending of ether
    }
}