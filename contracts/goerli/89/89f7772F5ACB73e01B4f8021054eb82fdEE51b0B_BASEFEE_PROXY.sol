// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract BASEFEE_PROXY {
    address public immutable logic;

    constructor(address _logic) public {
        logic = _logic;
    }

    function RETURN_BASEFEE() public returns (uint256 basefee) {
        (bool success, bytes memory basefee32) = logic.delegatecall(
            abi.encodeWithSignature("RETURN_BASEFEE()")
        );
        require(success, "Failed to get basefee");
        basefee = abi.decode(basefee32, (uint256));
        return basefee;
    }
}

