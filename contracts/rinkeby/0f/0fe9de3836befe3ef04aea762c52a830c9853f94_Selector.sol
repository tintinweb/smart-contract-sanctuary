// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

contract Selector {
    
    constructor() {}
    function calculateSelector() public pure returns (bytes4) {
        IERC165 i;
        return i.supportsInterface.selector;
    }
}