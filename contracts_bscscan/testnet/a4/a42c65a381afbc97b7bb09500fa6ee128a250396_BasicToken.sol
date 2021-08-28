// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";

contract BasicToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) allowed;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    /**
    * Constructor function
    *
    * Initializes contract with initial supply tokens to the creator of the contract
    */
    constructor (
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol,
        address _owner
    ) {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[_owner] = totalSupply;                     // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
    * Internal transfer, only can be called by this contract
    *
    * Send `_value` tokens to `_to` from `_from`
    *
    * @param _from Address of the sender
    * @param _to Address of the recipient
    * @param _value the amount to send
    */
    function _transfer(address _from, address _to, uint _value) internal {
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);

        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        // Subtract from the sender
        balanceOf[_from] -= _value;

        // Add the same to the recipient
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
    * Transfer tokens
    *
    * Send `_value` tokens to `_to` from your account
    *
    * @param _to The address of the recipient
    * @param _value the amount to send
    */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function getBalance(address _from) public view returns(uint balance) {
      return balanceOf[_from];
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }


    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }


    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balanceOf[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balanceOf[owner] = SafeMath.sub(balanceOf[owner], numTokens);
        allowed[owner][msg.sender] = SafeMath.sub(allowed[owner][msg.sender], numTokens);
        balanceOf[buyer] = SafeMath.add(balanceOf[buyer], numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}