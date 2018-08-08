pragma solidity ^0.4.18;


/** A token in which owner can do whatever they want.

This is to demonstrate a smart contract without auditing could be completely useless and a joke.

This contract is published on [ETH(Ropsten.io testnet)](https://ropsten.etherscan.io/token/0x75e80d242730deb9f18064ea96f0e880a5aa4a0e)
Updated
 - 2018-07-01 15:25 PT: After a second review, I realize there is a bug in function "issueOwnerMore", in that
 it doesn&#39;t do `balanceOf[owner]+= _value;`
 Therefore it was not Pure Air Token.

*/
contract PureAirToken {
    /* Public variables of the token */
    string public standard = "Token 0.1";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function PureAirToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) public {
        balanceOf[msg.sender] = initialSupply;
        owner = msg.sender;

        // Give the creator all initial tokens
        totalSupply = initialSupply;
        // Update total supply
        name = tokenName;
        // Set the name for display purposes
        symbol = tokenSymbol;
        // Set the symbol for display purposes
        decimals = decimalUnits;
        // Amount of decimals for display purposes
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // TODO not safe for overflow
        // Check for overflows
        balanceOf[msg.sender] -= _value;
        // Subtract from the sender
        balanceOf[_to] += _value;
        // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);
        // Notify anyone listening that this transfer took place
    }

    function changeName(string newName) public {
        require (msg.sender == owner);
        name = newName;
    }

    function changeSymbol(string newSymbol) public {
        require (msg.sender == owner);
        symbol = newSymbol;
    }

    function issueOwnerMore(uint256 _value) public {
        require (msg.sender == owner);
        require (totalSupply + _value > totalSupply); // TODO not safe for overflow
        require (balanceOf[msg.sender] + _value > balanceOf[msg.sender]); // TODO not safe for overflow
        totalSupply += _value;
        balanceOf[owner]+= _value;
    }
}