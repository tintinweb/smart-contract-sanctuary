/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.5.16;


contract TestEncode {
    function encodePacked(address[] calldata x, uint256[] calldata y) external pure returns(bytes memory) {
        return abi.encodePacked(x,y);
    }
    
    function encodeNonPacked(address[] calldata x, uint256[] calldata y) external pure returns(bytes memory) {
        return abi.encode(x,y);
    }    
}