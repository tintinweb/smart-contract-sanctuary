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

interface IOasis {

    /// @dev Sell `sellAmount` of `sellToken` token and receive `buyToken` token.
    /// @param sellToken The token being sold.
    /// @param sellAmount The amount of `sellToken` token being sold.
    /// @param buyToken The token being bought.
    /// @param minBoughtAmount Minimum amount of `buyToken` token to buy.
    /// @return boughtAmount Amount of `buyToken` bought.
    function sellAllAmount(
        IERC20TokenV06 sellToken,
        uint256 sellAmount,
        IERC20TokenV06 buyToken,
        uint256 minBoughtAmount
    )
        external
        returns (uint256 boughtAmount);
}

contract MixinOasis is
    MixinAdapterAddresses
{
    using LibERC20TokenV06 for IERC20TokenV06;

    /// @dev Mainnet address of the Oasis `MatchingMarket` contract.
    IOasis private immutable OASIS;

    constructor(AdapterAddresses memory addresses)
        public
    {
        OASIS = IOasis(addresses.oasis);
    }

    function _tradeOasis(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    )
        internal
        returns (uint256 boughtAmount)
    {
        // Decode the bridge data to get the `sellToken`.
        (IERC20TokenV06 sellToken) = abi.decode(bridgeData, (IERC20TokenV06));
        // Grant an allowance to the exchange to spend `sellToken` token.
        sellToken.approveIfBelow(
            address(OASIS),
            sellAmount
        );
        // Try to sell all of this contract's `sellToken` token balance.
        boughtAmount = OASIS.sellAllAmount(
            sellToken,
            sellAmount,
            buyToken,
            // min fill amount
            1
        );
        return boughtAmount;
    }
}
