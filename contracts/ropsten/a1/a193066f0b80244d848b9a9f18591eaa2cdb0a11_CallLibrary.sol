// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CallLibrary {
    constructor() {}
    
    function callLibrary(address lib) external {
        bytes memory libCall = abi.encodeWithSignature("add(uint256, uint256)", 2, 2);
        (bool success,) = address(lib).call(libCall);
        require(success);
    }

}

