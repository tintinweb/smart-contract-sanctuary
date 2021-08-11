/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Pool{
    address public admin;
    address public token;
    address public walletAddress;
    
    mapping(address => uint256) private _balances;
    
    constructor (address _token) {
        token = _token;
        admin = msg.sender;
        walletAddress = msg.sender;
    }
    
    function updateWalletAddress(address addr) public {
        require(msg.sender == admin, "Only Admin Can Use This Function");
        walletAddress = addr;
    }
    
    function deposit(uint256 amount) public {
        uint256 balance = IERC20(token).balanceOf(address(msg.sender));
        require(balance >= amount, "Pool: INSUFFICIENT_INPUT_AMOUNT");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _balances[admin] += amount;
    }
    
    function withdraw(uint256 amount) public {
        uint256 balance = _balances[admin];
        require(balance >= amount, "Pool: INSUFFICIENT_OUTPUT_AMOUNT");
         
        IERC20(token).transfer(walletAddress, amount);
        _balances[admin] -= amount;
    }
    
    function balanceOfPool(address user) public view returns (uint256 amount) {
        return _balances[user];
    }
    

}