//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract demo {
    string message;

    function storageMessage(string memory _message) external {
        message = _message;
    }

    function getMessage() external view returns (string memory){
        return message;
    }
}