/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20{

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Owned {
    address public owner;
    address public newOwner;
 
    event OwnershipTransferred(address indexed _from, address indexed _to);
 
    constructor() {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
 
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract RaysToken is IERC20, Owned {
    using SafeMath for uint;

    uint totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    
    constructor() {
        name = "Ray Dev Token";
        symbol = "RDTK";
        decimals = 6;
        totalSupply = 200000000 * 10**uint(decimals);
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    fallback () external { // when not exist method called
        revert();
    }

    receive() external payable{ // when coin incoming
        handleReceiveCoin();
    }
 
    function handleReceiveCoin() public payable {
        revert();
    }




    function balanceOf(address account) external view returns (uint){
        return balances[account];
    }

    function transfer(address reciever, uint amount) external returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[reciever] = balances[reciever].add(amount);
        emit Transfer(msg.sender, reciever, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint){
        return allowed[owner][spender];
    }

    function approve(address spender, uint amount) external returns (bool){
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address reciever,
        uint amount
    ) external returns (bool){
        balances[sender] = balances[sender].sub(amount);
        allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);
        balances[reciever] = balances[reciever].add(amount);
        return true;
    }

}