/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity 0.8.3;

contract MockFarm {
    
    mapping (address => uint256) public deposits;
    
    function deposit() public payable {
        deposits[msg.sender] += msg.value;
    }
    
    function harvest() public payable {
        payable(msg.sender).transfer(deposits[msg.sender] / 10);
    }
    
    function withdrawAndHarvest() public payable {
        payable(msg.sender).transfer(deposits[msg.sender] + deposits[msg.sender] / 10);
    }
}