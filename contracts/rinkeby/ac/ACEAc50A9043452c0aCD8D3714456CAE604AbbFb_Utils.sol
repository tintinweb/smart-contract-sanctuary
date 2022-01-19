// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library Utils {

function exclame(string memory greeting) public pure returns(string memory) {
    return string(abi.encodePacked(greeting,"!"));
}

}