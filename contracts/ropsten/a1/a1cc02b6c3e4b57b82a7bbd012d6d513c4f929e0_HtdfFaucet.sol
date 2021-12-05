/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract HtdfFaucet {
    
    uint256 public onceAmount;
    address public owner;
    
    mapping (address => uint256) sendRecords;
    
    constructor(){
        onceAmount = 100000000;
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function setOnceAmount(uint256 amount) public onlyOwner {
        onceAmount = amount;
    }

    //可以调用这个方法重置实验
    function clearRecords() public {
        sendRecords[msg.sender] = 0;
    }

    
    function getOneHtdf() public {
        require(sendRecords[msg.sender] == 0);

        // NOTE: THIS IS UNSAFE
        msg.sender.call{value:1};
        onceAmount--;
        sendRecords[msg.sender] = block.timestamp; // NOTE: probobaly be re-entrancy attacked
    }
    

    // function() public payable{
        
    // }
    
}