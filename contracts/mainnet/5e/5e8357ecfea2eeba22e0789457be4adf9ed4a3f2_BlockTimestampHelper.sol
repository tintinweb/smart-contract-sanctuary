/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

pragma solidity ^0.6.12;

contract BlockTimestampHelper {
    function getBlockTimeStamp()  external view returns (uint256) {
        return block.timestamp;
    }
}