/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

 abstract contract  EIP20Interface {

    uint256 public totalSupply;

    
    function  balanceOf(address _owner) virtual public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) virtual
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) virtual public returns (bool success);

    function approve(address _spender, uint256 _value) virtual
        public 
        returns (bool success);
    function allowance(address _owner, address _spender) virtual
        public
        view
        returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract EIP20 is EIP20Interface {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    string public name; //fancy name: eg Simon Bucks
    uint8 public decimals; //How many decimals to show.
    string public symbol; //An identifier: eg SBX

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) {
        balances[msg.sender] = _initialAmount; // Give the creator all initial tokens
        totalSupply = _initialAmount; // Update total supply
        name = _tokenName; // Set the name for display purposes
        decimals = _decimalUnits; // Amount of decimals for display purposes
        symbol = _tokenSymbol; // Set the symbol for display purposes
    }

    /*
    * dddddddddddddddddddddddddddddddddd
    */
    function transfer(address _to, uint256 _value) override
        public
        returns (bool success)
    {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender]  - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) override public returns (bool success) {
        require(
            balances[_from] >= _value && allowed[_from][msg.sender] >= _value,
            "Insufficient authorization !"
        );
        balances[_to] = balances[_to]+_value;
        balances[_from] = balances[_from] - _value ;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function approve(address _spender, uint256 _value) override
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) override
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) override public view returns (uint256 balance) {
        return balances[_owner];
    }
}