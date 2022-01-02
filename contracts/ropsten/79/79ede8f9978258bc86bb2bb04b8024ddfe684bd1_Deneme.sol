/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

contract Deneme{

    function amIOwner(address nftContractAddress, uint256 nftId) public returns(bool) {
        (bool success, bytes memory data) = nftContractAddress.call(abi.encodeWithSignature("ownerOf(uint256)", nftId));
        require(success, "Verification failed."); // cannot check
        return abi.decode(data, (address)) == msg.sender;
    }

}