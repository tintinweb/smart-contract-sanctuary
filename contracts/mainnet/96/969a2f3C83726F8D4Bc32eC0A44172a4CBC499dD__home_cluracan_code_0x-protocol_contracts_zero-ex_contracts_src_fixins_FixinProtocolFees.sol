/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../external/FeeCollector.sol";
import "../features/libs/LibTokenSpender.sol";

/// @dev Helpers for collecting protocol fees.
abstract contract FixinProtocolFees {
    bytes32 immutable feeCollectorCodeHash;

    constructor() internal {
        feeCollectorCodeHash = keccak256(type(FeeCollector).creationCode);
    }

    /// @dev   Collect the specified protocol fee in either WETH or ETH. If
    ///        msg.value is non-zero, the fee will be paid in ETH. Otherwise,
    ///        this function attempts to transfer the fee in WETH. Either way,
    ///        The fee is stored in a per-pool fee collector contract.
    /// @param poolId The pool ID for which a fee is being collected.
    /// @param amount The amount of ETH/WETH to be collected.
    /// @param weth The WETH token contract.
    function _collectProtocolFee(
        bytes32 poolId,
        uint256 amount,
        IERC20TokenV06 weth
    )
        internal
    {
        FeeCollector feeCollector = _getFeeCollector(poolId);

        if (msg.value == 0) {
            // WETH
            LibTokenSpender.spendERC20Tokens(weth, msg.sender, address(feeCollector), amount);
        } else {
            // ETH
            (bool success,) = address(feeCollector).call{value: amount}("");
            require(success, "FixinProtocolFees/ETHER_TRANSFER_FALIED");
        }
    }

    /// @dev Transfer fees for a given pool to the staking contract.
    /// @param poolId Identifies the pool whose fees are being paid.
    function _transferFeesForPool(
        bytes32 poolId,
        IStaking staking,
        IEtherTokenV06 weth
    )
        internal
    {
        FeeCollector feeCollector = _getFeeCollector(poolId);

        uint256 codeSize;
        assembly {
            codeSize := extcodesize(feeCollector)
        }

        if (codeSize == 0) {
            // Create and initialize the contract if necessary.
            new FeeCollector{salt: poolId}();
            feeCollector.initialize(weth, staking, poolId);
        }

        if (address(feeCollector).balance > 1) {
            feeCollector.convertToWeth(weth);
        }

        uint256 bal = weth.balanceOf(address(feeCollector));
        if (bal > 1) {
            // Leave 1 wei behind to avoid high SSTORE cost of zero-->non-zero.
            staking.payProtocolFee(
                address(feeCollector),
                address(feeCollector),
                bal - 1);
        }
    }

    /// @dev Compute the CREATE2 address for a fee collector.
    /// @param poolId The fee collector's pool ID.
    function _getFeeCollector(
        bytes32 poolId
    )
        internal
        view
        returns (FeeCollector)
    {
        // Compute the CREATE2 address for the fee collector.
        address payable addr = address(uint256(keccak256(abi.encodePacked(
            byte(0xff),
            address(this),
            poolId, // pool ID is salt
            feeCollectorCodeHash
        ))));
        return FeeCollector(addr);
    }
}
