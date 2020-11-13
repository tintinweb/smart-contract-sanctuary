// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "../HEZToken.sol";

contract HEZMock is HEZ {
    constructor(address initialHolder)
        public
        HEZ(initialHolder)
    {}

    function mint(address to, uint256 value) external {
        super._mint(to, value);
    }
}
