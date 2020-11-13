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

import "../src/fixins/FixinProtocolFees.sol";

contract TestProtocolFees is FixinProtocolFees {
    function collectProtocolFee(
        bytes32 poolId,
        uint256 amount,
        IERC20TokenV06 weth
    )
        external
        payable
    {
        _collectProtocolFee(poolId, amount, weth);
    }

    function transferFeesForPool(
        bytes32 poolId,
        IStaking staking,
        IEtherTokenV06 weth
    )
        external
    {
        _transferFeesForPool(poolId, staking, weth);
    }

    function getFeeCollector(
        bytes32 poolId
    )
        external
        view
        returns (FeeCollector)
    {
        return _getFeeCollector(poolId);
    }
}
