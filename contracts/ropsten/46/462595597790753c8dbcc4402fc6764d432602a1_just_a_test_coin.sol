/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


contract just_a_test_coin {
    
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    uint256 token_total_supply;
    uint256 token_initial_supply;
    address token_creator;
    uint8 token_decimals = 0;
    string token_name = "Just a Test Coin";
    string token_symbol = "JTC";
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() {
        token_total_supply = 1e3;
        token_initial_supply = 1e3;
        token_creator = msg.sender;
        balances[token_creator] = token_initial_supply;
    }
    function creator() public view returns (address) {
        return token_creator;
    }
    function name() public view returns (string memory) {
        return token_name;
    }
    function symbol() public view returns (string memory) {
        return token_symbol;
    }
    function decimals() public view returns (uint8) {
        return token_decimals;
    }
    function totalSupply() public view returns (uint256) {
        return token_total_supply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    // Allows _spender to withdraw from your account multiple times, up to the _value amount. 
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    // Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    // Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
    // The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    // Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    // The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
    // This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 tmp_allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && tmp_allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (tmp_allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    function mint() public {
        require(token_total_supply < 1e3, "Limit reached");
        token_total_supply += 1e2;
        balances[msg.sender] += 1e2;
    }

}