/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

contract BulkDistribute {
    function batchClaim(address claim, bytes[] calldata data) external {
       for(uint i = 0 ; i < data.length ; i++) {
           claim.call(data[i]);
       }
    }
}