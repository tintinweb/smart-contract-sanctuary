// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Account.sol";

contract AccountFactory {
    event Claimed(address from, address to);

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function claim(bytes memory code, uint256 salt, address payable to) public {
        require(msg.sender == owner);

        Account acc;
        assembly {
            acc := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(acc)) {
                revert(0, 0)
            }
        }
        acc.destroy(to);

        emit Claimed(address(acc), to);
    }
}