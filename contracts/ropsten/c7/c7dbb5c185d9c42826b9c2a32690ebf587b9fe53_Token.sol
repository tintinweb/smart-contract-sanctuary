/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

contract Token{

    string public _tokenName;
    string public _symbol;
    mapping (address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;
    uint256 public constant tokenPrice = 10 ** 9; // 1 token for 10^9 wei
    uint256 private _supply;
    
    event Approval(address from, address to, uint256 value);
    event Transfer(address sender, address recipient, uint256 amount);
    
    constructor(uint256 supply, string memory tokenName, string memory symbol) {
        _supply = supply;
        balances[msg.sender] = _supply;
       _tokenName = tokenName;
       _symbol = symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _supply;    
    }
    
    function balanceOf(address account) public view returns (uint256 coins){
        coins = balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool result){
        result = transferFrom(msg.sender, recipient, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool result){
        require(balances[sender] >= amount);
        require(amount <= allowed[sender][msg.sender]);
        
        allowed[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        result = true;
    }
    
    
    function allowance(address owner, address spender) public view returns (uint256 _all) {
        _all = allowed[owner][spender];
    }
    
    
    function approve(address spender, uint256 amount) public returns (bool){
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

}