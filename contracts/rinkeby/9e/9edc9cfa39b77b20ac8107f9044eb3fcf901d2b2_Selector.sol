/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "./IERC721.sol";

contract Selector {
    
    constructor() {} 
    function calculateSelector() public pure returns (bytes4) {
        
        return  bytes4(keccak256('balanceOf(address)')) ^ bytes4(keccak256('ownerOf(uint256)')) ^ bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^ bytes4(keccak256('transferFrom(address,address,uint256)')) ^ bytes4(keccak256('approve(address,uint256)')) ^ bytes4(keccak256('getApproved(uint256)')) ^ bytes4(keccak256('setApprovalForAll(address,bool)')) ^ bytes4(keccak256('isApprovedForAll(address,address)')) ^ bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'));
    
    }
}