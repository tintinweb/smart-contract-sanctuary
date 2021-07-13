// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./YERC20.sol";

contract Test {
    
    address owner;
    
    constructor() {
        owner=msg.sender;
    }
    
    function addressOfYuki() public view returns (address){
        return address(owner);
    }
    
    function balanceOfYuki() public view returns (uint256){
        return owner.balance;
    }
    
     function balanceOfYukiToken(address token) public view returns (uint256){
        YERC20 yerc20=YERC20(token);
        return yerc20.balanceOf(owner);
    }
    
    function balanceOfWallet() public view returns (uint256){
        return address(this).balance;
    }
    
    function balanceOfWalletToken(address token) public view returns (uint256){
        YERC20 yerc20=YERC20(token);
        return yerc20.balanceOf(address(this));
    }
    
    receive () external payable{
        
    }
    
    function transferBalanceToYuki(uint256 money) public {
        require(money>=address(this).balance);
        payable(owner).transfer(money);
    }
    
    function transferTokenToYuki(address token,uint256 money) public{
        YERC20 yerc20=YERC20(token);
        require(money>=yerc20.balanceOf(address(this)));
        yerc20.transfer(address(this),money);
    }
    
    function nameOfToken(address token) public view returns(string memory) {
        YERC20 yerc20=YERC20(token);
        return yerc20.name();
    }
    
    function symbolOfToken(address token) public view returns(string memory) {
        YERC20 yerc20=YERC20(token);
        return yerc20.symbol();
    }
    
}