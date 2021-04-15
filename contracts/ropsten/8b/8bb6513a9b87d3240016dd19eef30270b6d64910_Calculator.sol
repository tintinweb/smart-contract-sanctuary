/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity ^0.4.24;  
    contract Calculator {  
        
        
        uint public blockNumber;
        bytes32 public blockHashNow;
        bytes32 public blockHashPrevious;
        
        int private lastValue = 0;  
        function Add(int a, int b) public returns (int) {  
            lastValue = a + b;  
            return lastValue;  
        }  
        function Subtract(int a, int b) public returns (int) {  
            lastValue = a - b;  
            return lastValue;  
        }  
        function LastOperation() public constant returns (int) {  
            return lastValue;  
        }
        function setValues() {
        blockNumber = block.number;
        blockHashNow = blockhash(blockNumber);
        blockHashPrevious =blockhash(blockNumber - 1);
        }
        function leerblock() public constant returns (bytes32)
        {
           return blockhash(block.number);

        }
    }