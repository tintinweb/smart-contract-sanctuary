/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;
 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract HUSKYToken is IERC20 {
    string public constant symbol = "HUSKY Token";
    string public constant name = "HSK";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 100000000000000*10**18;
 
    // Owner of this contract
    address public owner;
     mapping(address => mapping (address => uint256)) allowed;
    // Balances for each account
    mapping(address => uint256) balances;
 
 
 
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
 
 
 
 
 
 
 
    // Constructor
    constructor () public{
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
 
    function totalSupply() view  public  override returns (uint256 supply) {
        return _totalSupply;
    }
 
 
    function balanceOf(address _owner) view public  override returns (uint256 balance) {
        return balances[_owner];
    }
 
    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) public   override returns (bool success) {
 
 
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit  Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
 
 
 
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) override   public   returns (bool success) {
 
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
           emit  Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)public  override returns  (bool success) {
        allowed[msg.sender][_spender] = _amount;
       emit  Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function  allowance(address _owner, address _spender)   public   view override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}