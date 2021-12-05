/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract HtdfFaucet {
    
    uint256 public onceAmount;
    address public owner ;
    
    event SendHtdf(address indexed toAddress, uint256 indexed amount);
    event Deposit(address indexed fromAddress, uint256 indexed amount);
    event SetOnceAmount(address indexed fromAddress, uint256 indexed amount);
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
        emit SetOnceAmount(msg.sender, amount);
    }
    
    function getOneHtdf() public {
        require( sendRecords[msg.sender] == 0 || 
            (sendRecords[msg.sender] > 0 &&  block.timestamp - sendRecords[msg.sender] > 1 minutes ));
            
        require(address(this).balance >= onceAmount);
        
        // NOTE: THIS IS UNSAFE
        msg.sender.call{value:onceAmount};
        sendRecords[msg.sender] = block.timestamp; // NOTE: probobaly be re-entrancy attacked
        emit SendHtdf(msg.sender, onceAmount);
    }
    
    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    // function() public payable{
        
    // }
    
}