/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

pragma solidity ^0.8.7;

contract MyFirstSmartContract {
    
    uint256 number;
    
    constructor(uint256 _num){
        number = _num;
    }
    
    function changeNumber(uint256 _num) public {
        number = _num;
    }
    
    function getNumber() public view returns (uint256) {
        return number;
    }
}