// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library CodeHelper {
    function getCode(address addressToGetCodeFrom) public view returns (bytes memory code) {
        code = addressToGetCodeFrom.code;
    }
    
    function hasCode(address addressToGetCodeFrom) public view returns (bool addressHasCode) {
        addressHasCode = addressToGetCodeFrom.code.length != 0;
    }
}