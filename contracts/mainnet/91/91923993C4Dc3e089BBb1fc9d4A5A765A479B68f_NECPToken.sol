pragma solidity ^0.4.11;

contract owned {
    address public owner;
    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
}

contract NECPToken is owned {
    /* Public variables of the token */
    string public constant standard = &#39;Token 0.1&#39;;
    string public constant name = "Neureal Early Contributor Points";
    string public constant symbol = "NECP";
    uint256 public constant decimals = 8;
    uint256 public constant MAXIMUM_SUPPLY = 3000000000000;
    
    uint256 public totalSupply;
    bool public frozen = false;

    /* This tracks all balances */
    mapping (address => uint256) public balanceOf;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function NECPToken() {
        balanceOf[msg.sender] = MAXIMUM_SUPPLY;              // Give the creator all initial tokens
        totalSupply = MAXIMUM_SUPPLY;                        // Update total supply
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (frozen) throw;                                   // Check if frozen
        if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    function freezeTransfers() onlyOwner  {
        frozen = true;
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;   // Prevents accidental sending of ether
    }
}