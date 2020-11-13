
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

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "./MixinAdapterAddresses.sol";

interface IShell {

    function originSwap(
        address from,
        address to,
        uint256 fromAmount,
        uint256 minTargetAmount,
        uint256 deadline
    )
        external
        returns (uint256 toAmount);
}

contract MixinShell is
    MixinAdapterAddresses
{
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeShell(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    )
        internal
        returns (uint256 boughtAmount)
    {
        (address fromTokenAddress, address pool) = abi.decode(bridgeData, (address, address));

        // Grant the Shell contract an allowance to sell the first token.
        IERC20TokenV06(fromTokenAddress).approveIfBelow(
            pool,
            sellAmount
        );

        boughtAmount = IShell(pool).originSwap(
            fromTokenAddress,
            address(buyToken),
             // Sell all tokens we hold.
            sellAmount,
             // Minimum buy amount.
            1,
            // deadline
            block.timestamp + 1
        );
        return boughtAmount;
    }
}
