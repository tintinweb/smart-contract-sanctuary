/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract querytoBlockchain{
        address public senderAddress;
        uint public blockNumber;
        uint public time;
        uint public value;
        uint public difficulty;
        uint public num=0;
        uint public sum=0;
        
        function query() public payable{
            senderAddress = msg.sender;
            blockNumber = block.number;
            time = block.timestamp;
            value = msg.value;
            difficulty = block.difficulty;
        }
        function plus(uint n) public {
            num=n;
            for(uint i=1;i<n;i++){
                sum+=i;
            }
        }
        function mul(uint n) public {
            num=n;
            for(uint i=1;i<n;i++){
                sum*=i;
            }
        }
        function SumToZero() public {
            sum=0;
        }
        
        
}