/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
// author: mel0n

pragma solidity >=0.7.0 <0.9.0;

contract ERC20 {
    string public constant NAME = "ALTINSOFT";
    string public constant SYMBOL = "ALT";

    uint256 public immutable totalSupply = 20000;
    address payable public owner;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => bool)) accessToWithdraw;
    mapping(address => mapping(address => uint256)) setAllowance;

    event Transfer(address _from, address _to, uint256 _value);
    event Approval(address _owner, address _spender, uint256 _value);

    constructor() payable {
        owner = payable(msg.sender);
        balances[owner] = totalSupply;
    }

    modifier checkAccessToWithdraw(address _from) {
        // the caller has to be _from themselves or the caller has to be given access by _from
        require(
            _from == msg.sender || accessToWithdraw[_from][msg.sender] == true,
            "caller doesn't have access to the account he's trying to withdraw balance from"
        );
        _;
    }

    modifier checkAllowance(address _from, uint256 _value) {
        // the spender has to have sufficient allowance given by the owner to spend
        require(
            setAllowance[_from][msg.sender] >= _value,
            "allowance not enough to transfer money"
        );
        _;
    }

    modifier senderNotEqualToReceiver(address _from, address _to) {
        require(_from != _to, "can't send any tokens to yourself");
        _;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address payable _to, uint256 amount)
        public
        senderNotEqualToReceiver(msg.sender, _to)
        returns (bool)
    {
        if (balances[msg.sender] >= amount) {
            balances[msg.sender] -= amount;
            balances[_to] += amount;
            // emitting  the transfer event
            emit Transfer(msg.sender, _to, amount);
            return true;
        } else
            revert(
                "Caller doesn't have enough balance to send given amount of token"
            );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        senderNotEqualToReceiver(_from, _to)
        checkAccessToWithdraw(_from)
        checkAllowance(_from, _value)
        returns (bool)
    {
        setAllowance[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        // emitting the transfer event
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public {
        if (balances[msg.sender] < _value) {
            revert("not enough balance to approve the given amount of token");
        }
        accessToWithdraw[msg.sender][_spender] = true;
        setAllowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        require(
            accessToWithdraw[_owner][_spender] == true,
            "there is no allowance given by owner to the spender"
        );

        return setAllowance[_owner][_spender];
    }
}