/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract querytoBlockchain{
        address public senderAddress;
        uint public blockNumber;
        uint public time;
        uint public value;
        uint public difficulty;
        uint public sum=0;
        string public text; 
        
        function query() public payable{
            senderAddress = msg.sender;
            blockNumber = block.number;
            time = block.timestamp;
            value = msg.value;
            difficulty = block.difficulty;
           
        }
        function plus(uint n) public {
            sum=0;
            for(uint i=1;i<n+1;i++){
                sum+=i;
            }
        }
        function mul(uint n) public {
            sum=1;
            for(uint i=1;i<n+1;i++){
                sum*=i;
            }
        }
       
        
        
}