/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface usdt {
    function balanceOf(address addr) external view returns (uint256);
    function transfer(address to,uint256 amount) external;
} 

contract Test {
    
    address owner;
    usdt  usd;
    
    
    constructor() {
        owner=msg.sender;
        usd=usdt(0x337610d27c682E347C9cD60BD4b3b107C9d34dDd);
    }
    function test() public view returns (uint256){
        return owner.balance;
    }
    
     function test4() public view returns (uint256){
        return usd.balanceOf(owner);
    }
    
    function test2() public view returns (uint256){
        return address(this).balance;
    }
    
    function test6() public view returns (uint256){
        return usd.balanceOf(address(this));
    }
    
    receive () external payable{
        
    }
    
    function test3(uint256 money) public {
        assert(money>=address(this).balance);
        payable(owner).transfer(money);
    }
    
    function test5(uint256 money) public{
        assert(money>=usd.balanceOf(address(this)));
        usd.transfer(address(this),money);
    }
    
}