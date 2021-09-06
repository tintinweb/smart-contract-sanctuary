/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract loop {
    function looping(uint256 a,uint256 b, uint256 c, uint256 d, uint256 e, uint256 f, uint256 g, uint256 h) public pure returns (uint256) {
        uint sum;
        for(uint i = 0;i<a;i++){
            sum = (b*(h*c-d))/(e*f-g); 
        }
        return sum;
    }
}