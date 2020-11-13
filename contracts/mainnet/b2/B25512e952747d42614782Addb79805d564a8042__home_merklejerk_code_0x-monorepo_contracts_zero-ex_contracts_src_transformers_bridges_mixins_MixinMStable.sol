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


interface IMStable {

    function swap(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        address recipient
    )
        external
        returns (uint256 boughtAmount);
}

contract MixinMStable is
    MixinAdapterAddresses
{
    using LibERC20TokenV06 for IERC20TokenV06;

    /// @dev Mainnet address of the mStable mUSD contract.
    IMStable private immutable MSTABLE;

    constructor(AdapterAddresses memory addresses)
        public
    {
        MSTABLE = IMStable(addresses.mStable);
    }

    function _tradeMStable(
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
        sellToken.approveIfBelow(address(MSTABLE), sellAmount);

        boughtAmount = MSTABLE.swap(
            sellToken,
            buyToken,
            sellAmount,
            address(this)
        );
    }
}
