/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

pragma solidity >=0.7.0 <0.9.0;


contract Storagenum {

    uint256 number;

    function store(uint256 num1, uint256 num2) public {
        number = num1 + num2;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}