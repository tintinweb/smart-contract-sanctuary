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

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ERC20 {
    /* Public variables of the token */
    string public standard = &#39;RIALTO 1.0&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public supply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ERC20(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balances[msg.sender] = initialSupply;              // Give the creator all initial tokens
        supply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }


    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);


    /* Send coins */
    function transfer(address _to, uint256 _value) returns (bool success);

 /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);


    /* Get the amount of remaining tokens to spend */
        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
                return allowance[_owner][_spender];
        }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }   
    }   
    
       /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }   
}   
contract Rialto is owned, ERC20 {

    uint256 public lockPercentage = 15;

    uint256 public expiration = block.timestamp + 180 days;


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Rialto(
        uint256 initialSupply, // 100000000000000000
        string tokenName, //RIALTO
        uint8 decimalUnits, //9
        string tokenSymbol // XRL
    ) ERC20 (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

        /* Get balance of specific address */
        function balanceOf(address _owner) constant returns (uint256 balance) {
                return balances[_owner];
        }

        /* Get total supply of issued coins */
        function totalSupply() constant returns (uint256 totalSupply) {
                return supply;
        }

    function transferOwnership(address newOwner) onlyOwner {
        if(!transfer(newOwner, balances[msg.sender])) throw;
        owner = newOwner;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) returns (bool success){


        if (balances[msg.sender] < _value) throw;           // Check if the sender has enough

        if (balances[_to] + _value < balances[_to]) throw; // Check for overflows

        if (msg.sender == owner && block.timestamp < expiration && (balances[msg.sender]-_value) < lockPercentage * supply / 100 ) throw;  // Locked funds

        balances[msg.sender] -= _value;                     // Subtract from the sender
        balances[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {


        if (balances[_from] < _value) throw;                 // Check if the sender has enough
        if (balances[_to] + _value < balances[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        if (_from == owner && block.timestamp < expiration && (balances[_from]-_value) < lockPercentage * supply / 100) throw; //Locked funds

        balances[_from] -= _value;                          // Subtract from the sender
        balances[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }



  }