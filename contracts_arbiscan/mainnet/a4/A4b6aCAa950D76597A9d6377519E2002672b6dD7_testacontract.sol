/**
 *Submitted for verification at arbiscan.io on 2021-12-21
*/

pragma solidity ^0.7.0;

contract testacontract {

    function gimmeastring(uint256 a) public pure returns (string memory) {
        if(a == 1) {
            return "baabaablacksheep";
        } else {
            return "marry had a wittle lamb";
        }
    }

}