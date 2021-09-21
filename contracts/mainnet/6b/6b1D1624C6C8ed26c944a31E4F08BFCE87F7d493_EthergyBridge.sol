/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);
}

interface IXDaiBridge {
    function relayTokens(address _receiver, uint256 _amount) external returns (bool);
}

contract EthergyBridge{
    
    address public xdaiBridge = 0x4aa42145Aa6Ebf72e164C9bBC74fbD3788045016;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public dao;
    
    event DAIBridge(address target, uint amount);
    event DAIBridge1(uint amount);
    
    constructor(address _dao) public
    {
        dao = _dao;
    }


    function bridge() external {
        uint256 balance = IERC20(dai).balanceOf(address(this));
        require(balance > 0, "No sufficent DAI on the smart contract");
        IERC20(dai).approve(xdaiBridge, balance);
        IXDaiBridge(xdaiBridge).relayTokens(dao, balance);
        
        emit DAIBridge(dao, balance);
    }
    
    
    function bridge1() external {
        uint256 balance = IERC20(dai).balanceOf(address(this));
        require(balance > 0, "No sufficent DAI on the smart contract");
        
        emit DAIBridge(dao, balance);
    }
    

    function bridge2() external {
        uint256 balance = IERC20(dai).balanceOf(address(this));
        require(balance > 0, "No sufficent DAI on the smart contract");
        IERC20(dai).approve(xdaiBridge, balance);
        
        emit DAIBridge(dao, balance);
    }
    
}