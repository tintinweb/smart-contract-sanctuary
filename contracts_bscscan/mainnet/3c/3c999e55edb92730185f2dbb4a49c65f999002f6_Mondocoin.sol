/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT
contract Mondocoin{
    mapping(address => uint) balances;
    address public _owner;
    mapping (address => mapping(address=>uint)) public allowance;
    uint public decimals = 2;
    uint public totalSupply = 2*10**(uint(decimals)); // total supply = 200
    string public name = "MONDOCOIN";
    string public sybmol = "USDMD";
    event Approval (address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        balances[msg.sender] = totalSupply;
    }
    function balanceOf(address account) public view returns (uint){
        return balances[account];
        
    }
    function approve (address spender, uint value) public returns(bool){
        allowance [msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }
    function tansferFrom (address from, address rcvr, uint value) public returns (bool){
        require(balanceOf(from) <=value, "balance is too low to send");
        require(allowance[from][rcvr] <= value, "allowance is too low");
        balances[from] -= value;
        balances[rcvr] += value;
        emit Transfer(from, rcvr, value);
        return true;
    }
    function transferToken (address to, uint value) public returns (bool){
        require(balanceOf(msg.sender) <= value, "balance is too to transfer");
        balances[to] += value;
        balances[msg.sender] -=value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function mint(address account, uint amount) public returns (bool) {
        require(account != address(0));
        balances[account]+= amount;
        totalSupply += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }
    function burn(address account, uint amount) public returns (bool) {
        require (balanceOf(account) >= amount, "Balance is short to destroy the coins");
        balances[account]-= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}