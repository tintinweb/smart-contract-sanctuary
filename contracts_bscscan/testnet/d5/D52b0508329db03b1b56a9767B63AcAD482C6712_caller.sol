/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

pragma solidity 0.8.0;

contract caller {
    
    uint num = 0;
    
    function execute() public returns (uint){
        num++;
        return num;
    }
}