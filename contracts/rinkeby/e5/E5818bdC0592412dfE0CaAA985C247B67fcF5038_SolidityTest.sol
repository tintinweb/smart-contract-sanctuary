/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

pragma solidity ^0.5.0;
contract SolidityTest {
    constructor() public{
    }
    function getResults() public pure returns(uint){
        uint a = 1;
        uint b = 2;
        uint result = a + b;
        return result;
    }
}