// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";

contract BatchTransfer {

    address private owner;
    constructor() {
        owner = msg.sender;
    }

    function batchTransferDirect(IERC20 _erc20Contract, address[] calldata _to, uint256 _value) external {
        require(msg.sender == owner, "not owner");
        for (uint i=0; i<_to.length; i++) {
            _erc20Contract.transfer(_to[i], _value);
        }
    }
}