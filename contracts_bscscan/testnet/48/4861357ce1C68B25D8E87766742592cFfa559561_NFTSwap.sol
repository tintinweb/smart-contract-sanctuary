/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// File: NFTSwap.sol

contract NFTSwap  {

    function transfer(address from, address to, uint256 tokenId, address con_address) external{
    bytes memory payload = abi.encodeWithSignature("safeTransferFrom(address, address, unit256)", from, to, tokenId);
    (bool success, bytes memory returnData) = address(con_address).call(payload);
    require(success);
    }

    function donateGame() external  payable {
        require(!(msg.value<0.001 ether));

    }

    }