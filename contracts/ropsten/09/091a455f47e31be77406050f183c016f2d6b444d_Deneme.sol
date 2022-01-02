/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

contract Deneme{

    mapping(address => bool) public hasRight;
    
    function getRight(address nftContractAddress, uint256 nftId) public {
        require(_amIOwner(nftContractAddress, nftId), "You cannot have a right!");
        hasRight[msg.sender] = true;
    }

    function _amIOwner(address nftContractAddress, uint256 nftId) internal returns(bool) {
        (bool success, bytes memory data) = nftContractAddress.call(abi.encodeWithSignature("ownerOf(uint256)", nftId));
        require(success, "Verification failed."); // cannot check
        return abi.decode(data, (address)) == msg.sender;
    }

    function getHasRight(address queriedAddress) public view returns(bool) {
        return hasRight[queriedAddress];
    }



}