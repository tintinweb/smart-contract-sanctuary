// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// Contract account to simulate another user
contract User {
    function execute(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public payable returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(success, "!user-execute");

        return returnData;
    }
}
