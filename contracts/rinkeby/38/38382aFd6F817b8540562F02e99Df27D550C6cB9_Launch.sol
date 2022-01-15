// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Launch {

    function launch(address myAddress) external pure returns (string memory) {
        require(myAddress == address(0x4046bC8A20B698Dd29d0a1b51cB2BFB75d2b3DBC), "This is not MY address");
        return "Visit https://promittoproject.io/congrats-ship-launched";
    }
}