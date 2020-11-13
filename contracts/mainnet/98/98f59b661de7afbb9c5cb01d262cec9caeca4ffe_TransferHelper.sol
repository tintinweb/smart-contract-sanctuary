// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.1;

// Copyright 2020 Uniswap team
// Based on: https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol
library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: could not transfer ERC20 tokens"
        );
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: could not transferFrom ERC20 tokens"
        );
    }
}
