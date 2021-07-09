/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Test {
    
    function getSigner(uint256 tokenID, uint8 v, bytes32 r, bytes32 s) external pure returns(address) {
        address ret = ecrecover(keccak256(abi.encodePacked(tokenID)), v, r, s);
        return ret;
    }
}