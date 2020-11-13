
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
import "./MixinUniswapV2.sol";

contract MixinSushiswap is
    MixinAdapterAddresses
{
    using LibERC20TokenV06 for IERC20TokenV06;

    /// @dev Mainnet address of the `SushiswapRouter` contract.
    IUniswapV2Router02 private immutable SUSHISWAP_ROUTER;

    constructor(AdapterAddresses memory addresses)
        public
    {
        SUSHISWAP_ROUTER = IUniswapV2Router02(addresses.sushiswapRouter);
    }

    function _tradeSushiswap(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    )
        internal
        returns (uint256 boughtAmount)
    {
        // solhint-disable indent
        address[] memory path = abi.decode(bridgeData, (address[]));
        // solhint-enable indent

        require(path.length >= 2, "SushiswapBridge/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(
            path[path.length - 1] == address(buyToken),
            "SushiswapBridge/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN"
        );
        // Grant the Uniswap router an allowance to sell the first token.
        IERC20TokenV06(path[0]).approveIfBelow(
            address(SUSHISWAP_ROUTER),
            sellAmount
        );

        uint[] memory amounts = SUSHISWAP_ROUTER.swapExactTokensForTokens(
             // Sell all tokens we hold.
            sellAmount,
             // Minimum buy amount.
            1,
            // Convert to `buyToken` along this path.
            path,
            // Recipient is `this`.
            address(this),
            // Expires after this block.
            block.timestamp
        );
        return amounts[amounts.length-1];
    }
}
