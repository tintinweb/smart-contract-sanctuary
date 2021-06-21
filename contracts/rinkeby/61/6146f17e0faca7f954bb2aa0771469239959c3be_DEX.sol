/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DEX {
    IERC20 public token;
    
    receive() external payable {}
    
    constructor (address _f) {
        token = IERC20(_f);
    }
    
    function buy() payable public {
        uint256 amountToBuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this));
        uint256 k = address(this).balance * dexBalance;
        
        uint256 newBalance = k / (amountToBuy + address(this).balance);
        
        uint256 toSend = dexBalance - newBalance;
        token.transfer(msg.sender, toSend);
    }
    
    function sell (uint256 amountToSell) public {
        require(amountToSell > 0, "You need to sell something");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amountToSell, "Check the token allowance");
        uint256 dexBalance = token.balanceOf(address(this));
        
        uint256 k = dexBalance * address(this).balance;
        
        uint256 newBalance = k / (amountToSell + dexBalance);
        
        uint256 toSend = address(this).balance - newBalance;
        token.transferFrom(msg.sender, address(this), amountToSell);
        payable(msg.sender).transfer(toSend);
    }
}