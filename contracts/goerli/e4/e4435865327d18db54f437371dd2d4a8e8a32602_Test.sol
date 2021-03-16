/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity =0.6.6;


contract Test {
    
    
    function getNow() view public returns (uint256,uint256,uint256){
        return (block.number,block.timestamp,now);
    }   
    
    function getOneDay() pure public returns (uint){
        return  1 days;
    }    
}