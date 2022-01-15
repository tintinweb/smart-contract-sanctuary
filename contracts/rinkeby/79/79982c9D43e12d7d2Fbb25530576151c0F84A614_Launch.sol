// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Launch {

    function launch(address myAddress) external pure returns (string memory) {
        require(myAddress == address(0xF04BDc6B9a481A804fAe576345CdBD6f6387AF7B), "This is not MY address");
        return "Visit https://promittoproject.io/congrats-ship-launched";
    }
}