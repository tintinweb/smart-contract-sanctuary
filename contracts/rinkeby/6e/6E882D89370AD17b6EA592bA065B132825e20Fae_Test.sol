/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity 0.7.0;

contract Test {
    uint public a;

    constructor(){
        a = 10;
    }

    function getA() public view returns (uint){
        return a;
    }
}