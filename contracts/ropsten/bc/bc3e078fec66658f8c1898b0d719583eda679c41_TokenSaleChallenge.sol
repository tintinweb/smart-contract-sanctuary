/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.4.21;

contract TokenSaleChallenge{
    mapping(address => uint256) public balanceOf;
    uint256 constant PRICE_TOKEN=1 finney;
    
    constructor(address _player) public payable{
        require(msg.value == 1 ether);
        balanceOf[_player] += 10;
    }
    
    function buy(uint256 numTokens) public payable{
        require(msg.value == numTokens*PRICE_TOKEN);
        balanceOf[msg.sender] += numTokens;
    }
    
    function sell(uint256 numTokens) public {
        require(balanceOf[msg.sender] >= numTokens);
        balanceOf[msg.sender] -= numTokens;
        msg.sender.transfer(numTokens*PRICE_TOKEN);
    }
    
    function withdraw() public {
        msg.sender.transfer(address(this).balance/2);
    } 
    
    function withdraw2() external{
        msg.sender.transfer(address(this).balance);
    }
    
}