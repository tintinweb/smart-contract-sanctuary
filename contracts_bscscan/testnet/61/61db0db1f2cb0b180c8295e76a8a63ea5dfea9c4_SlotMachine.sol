/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

pragma solidity ^0.4.8;

contract SlotMachine {
    
    mapping (address => uint) public playerList; 
    uint256 public contractBalance;
    
    function SlotMachine() public {
    }
    
    function () payable public {
        start();
    }
    
    function start() public payable {
        
        uint256 userBalance = msg.value;
        require(userBalance > 0);
        uint randomValue = random();
        playerList[msg.sender] = randomValue;
        contractBalance = address(this).balance;
            
        if(randomValue > 50)
        {    
            uint256 winBalance = userBalance * 2;
            if(contractBalance < winBalance){
                winBalance = contractBalance;
            }
            msg.sender.transfer(winBalance); 
            contractBalance = address(this).balance;        
        }
    }
    
    function random() view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp)) % 100) + 1; // 1 ~ 100 (Only for testing.)
    }
}