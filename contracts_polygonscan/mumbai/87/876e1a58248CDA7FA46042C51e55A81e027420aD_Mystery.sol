//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Mystery{
    event Transfer(bool success, bytes data);

    function transferItem(address _contract, address from, uint256 id) public payable returns (bool) {
        (bool success, bytes memory data) = _contract.call(
            abi.encodeWithSignature("safeTransferFrom(address, address, uint256, uint256, bytes)", from, msg.sender, id, 1, "")
        );
        emit Transfer(success, data);
        return success;
    }
}