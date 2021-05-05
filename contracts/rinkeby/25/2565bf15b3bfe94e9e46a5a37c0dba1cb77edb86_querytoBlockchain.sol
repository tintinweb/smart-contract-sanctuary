/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.7.6;
contract querytoBlockchain{
        address public senderAddress;
        uint public value;
        uint public sum=0;
        string public Message;
        
       
        
        function query() public payable{
            senderAddress = msg.sender;
            value = msg.value;
           
        }
        
         function myDataPush (string memory x) public {
            Message = x;
        } 
        
        function plus(uint n) public payable{
            require(msg.value>1000) ;
            senderAddress = msg.sender;
            value = msg.value;
            sum=0;
            for(uint i=1;i<n+1;i++){
                sum+=i;
            }
        }
        function mul(uint n) public payable{
            require(msg.value>1000) ;
            senderAddress = msg.sender;
            value = msg.value;
            sum=1;
            for(uint i=1;i<n+1;i++){
                sum*=i;
            }
        }
       
        
        
}