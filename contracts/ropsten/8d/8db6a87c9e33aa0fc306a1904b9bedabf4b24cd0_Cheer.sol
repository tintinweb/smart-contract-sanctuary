/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.4.22;

contract Cheer {
    uint256 num = 0;

    function random(
        uint256 x,
        uint256 y,
        uint256 z
    ) public returns (uint256) {
        if (x % 2 == 0) {
            num = 256;
            while (x != z) {
                num = x * z;
                if (x > z) {
                    z++;
                } else {
                    x++;
                }
            }
            if (y % 2 == 0) {
                num = uint256(
                    keccak256(abi.encodePacked(block.difficulty, now))
                );
            }
        } else {
            num = 3;
        }
        return num;
    }
}