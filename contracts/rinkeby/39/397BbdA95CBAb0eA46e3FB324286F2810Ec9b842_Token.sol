/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Token
 */
 
library Balances {
    function move(mapping(address => uint256) storage balances, address from, address to, uint amount) internal {
        require(balances[from] >= amount);
        require(balances[to] + amount >= balances[to]);
        balances[from] -= amount;
        balances[to] += amount;
    }
}
 
contract Token {
    using Balances for *;
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint private tsupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Payment(address payer, uint256 value);
    
    constructor (string memory _name, string memory _symbol, uint8 _decimals, uint _supply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        tsupply = _supply * 10**uint(decimals);
        owner = msg.sender;
        balances[owner] = tsupply;
        emit Transfer(address(0), owner, tsupply);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Prohibited");
        _;
    }
    
    function totalSupply() public view returns (uint sup) {
        sup = tsupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint bal) {
        bal = balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        remaining = allowed[tokenOwner][spender];
    }
    
    function transfer(address _to, uint tokens) public returns (bool success) {
        balances.move(msg.sender, _to, tokens);
        emit Transfer(msg.sender, _to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        require(allowed[msg.sender][spender] == 0, "");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint tokens) public returns (bool success) {
        require(allowed[_from][msg.sender] >= tokens);
        allowed[_from][msg.sender] -= tokens;
        balances.move(_from, _to, tokens);
        emit Transfer(_from, _to, tokens);
        return true;
    }
    
    receive() external payable {
        emit Payment(msg.sender, msg.value);
    }
    
    function withdrawal() public onlyOwner {
        address payable to = payable(owner);
        uint256 amount = address(this).balance;
        to.transfer(amount);
    }

}