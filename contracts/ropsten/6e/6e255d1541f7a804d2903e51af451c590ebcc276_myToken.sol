/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

//SPDX-License-Identifier: Apache2.0
pragma solidity ^0.8.7;
interface Erc20Interface{

    function totalSupply() external view returns(uint256);
    function balanceof(address account) external view  returns(uint256);
    function allownace(address owner,   address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function tansferfrom(address sender, address recipient, uint256 amount) external returns(bool); 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract myToken is Erc20Interface
{
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalsupply;
    address public tokenowner;
    mapping(address => uint) private _balance;
    mapping(address => mapping(address=> uint256)) private _allownaces;

    constructor() public {
        tokenowner = msg.sender;
        symbol = "CCC1.1";
        name="Dinesh Kanojiya fixed supply token";
        decimals = 18;
        _totalsupply=1000000 * 10**uint(decimals);
        _balance[tokenowner] = _totalsupply;
        
        emit Transfer(address(0), tokenowner, _totalsupply);
    }

    function totalSupply() public view override returns(uint256)
    {
        return _totalsupply;
    }

    function balanceof(address account)public view override returns(uint256)
    {
        return _balance[account];
    }

    function allownace(address owner, address spender) public view virtual override returns (uint256)
    {
        return _allownaces[owner][spender];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns(bool)
    {
        address sender = msg.sender;
        _balance[sender] = _balance[sender] - amount;
        _balance[recipient] = _balance[recipient] + amount;
         emit Transfer(sender, recipient, amount);
         return true;
     }  

    function approve(address spender, uint256 amount) public virtual override returns(bool)
    {
        address approver = msg.sender;
        _allownaces[approver][spender] = amount;
        emit Approval(approver, spender, amount);
        return true;
    }

    function tansferfrom(address sender, address recipient, uint256 amount) public virtual override returns(bool)
    {
        _balance[sender] =_balance[sender] - amount;
        _balance[recipient] = _balance[recipient] + amount;
        emit Transfer(sender, recipient, amount);

        _allownaces[sender][recipient]  = amount;
        emit Approval(sender, recipient, amount);
        return true;

    }
}