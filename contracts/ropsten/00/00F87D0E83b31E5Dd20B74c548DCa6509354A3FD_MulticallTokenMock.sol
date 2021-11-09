// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Mock.sol";
import "./Address.sol";

abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this),data[i]);
        }
        return results;
    }
}

contract MulticallTokenMock is ERC20Mock, Multicall {
    constructor(uint256 initialBalance) ERC20Mock(msg.sender, initialBalance) {}
}