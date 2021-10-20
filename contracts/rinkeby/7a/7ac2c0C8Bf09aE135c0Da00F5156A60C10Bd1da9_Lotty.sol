/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Lotty {

    address public owner_;
    string public name = "Lotty";
    string public symbol = "LTY";
    uint256 public totalSupply = 50 * 10 ** 18; // Tokens can only be minted to lottery winners
    uint256 public decmials = 18;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //check balance of an account
    mapping(address => uint256) public balances;
    // who can spend what on whos behalf
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        owner_ = msg.sender;
        balances[owner_] = totalSupply;
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    //transfers token from function caller 
    function transfer(address _to, uint256 _value) public returns(bool success) {
        require(
            balances[msg.sender] >= _value,
            "insufficient funds"
        );
    //state is modified after function call as a re entrancy gaurd
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        public returns(bool success)
    {
        require(
            balances[_from] >= _value,
            "insufficient funds"
        );
        require(
            allowance[_from][msg.sender] >= _value,
            "allowance is too low"
        );
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address _spender, 
        uint256 _value
    ) 
        public returns (bool success) 
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}