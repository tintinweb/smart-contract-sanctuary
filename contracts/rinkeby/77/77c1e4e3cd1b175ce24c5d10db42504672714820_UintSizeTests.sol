/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.7.6;

contract UintSizeTests {
    function testUint256() public {
        uint256 j = 0;
        for (uint256 i = 0; i < 100; i++) {
            j = i;
        }
    }
    
    
    function testUint32() public {
        uint32 j = 0;
        for (uint32 i = 0; i < 100; i++) {
            j = i;
        }
    }
}