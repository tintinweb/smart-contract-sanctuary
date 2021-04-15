/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity ^0.4.24;  
    contract Calculator {  
        
        
       
        function leerblock() public constant returns (bytes32)
        {
           return blockhash(block.number-1);

        }
    }