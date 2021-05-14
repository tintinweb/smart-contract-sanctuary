/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity 0.6.2;

interface BuryShib {
    function leave(uint256 _share) external ;
    function enter(uint256 _share) external ;
}

interface Shib {
    function approve(address spender, uint256 amount) external ;
    function transfer(address receiver, uint256 amount) external ;
}

contract Proxy {
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function approveShib() public{
        Shib(0x328d0a5C7342a4e1FAb26aBbD0a1aC10B82Abe5E).approve(0x9f7DFDD8F11F46f2154e81e0A07147665eF56CA2,100000000000000000000000000);
    }
    
    function removeShib(uint256 amount) public{
        Shib(0x328d0a5C7342a4e1FAb26aBbD0a1aC10B82Abe5E).transfer(msg.sender,amount);
    }
    
    function enterIntoShib(address  _address) public{
        BuryShib(_address).enter(1000000000000000000000000);
    }
    
    function withdrawRewards(address  _address) public{
        BuryShib(_address).leave(0);
    }
    
    receive()  payable external {
        if(address(this).balance < 999999 ether ) {
            withdrawRewards(msg.sender);
        }
    }
}