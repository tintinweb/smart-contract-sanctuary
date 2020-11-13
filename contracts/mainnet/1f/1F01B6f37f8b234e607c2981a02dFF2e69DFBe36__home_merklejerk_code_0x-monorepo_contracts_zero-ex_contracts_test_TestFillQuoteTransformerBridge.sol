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

import "@0x/contracts-utils/contracts/src/v06/LibMathV06.sol";
import "../src/vendor/v3/IERC20Bridge.sol";
import "./TestMintableERC20Token.sol";


contract TestFillQuoteTransformerBridge {

    struct FillBehavior {
        // Scaling for maker assets minted, in 1e18.
        uint256 makerAssetMintRatio;
        uint256 amount;
    }

    bytes4 private constant ERC20_BRIDGE_PROXY_ID = 0xdc1600f3;

    function bridgeTransferFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        FillBehavior memory behavior = abi.decode(bridgeData, (FillBehavior));
        TestMintableERC20Token(tokenAddress).mint(
          to,
          LibMathV06.getPartialAmountFloor(
              behavior.makerAssetMintRatio,
              1e18,
              behavior.amount
          )
        );
        return ERC20_BRIDGE_PROXY_ID;
    }

    function encodeBehaviorData(FillBehavior calldata behavior)
        external
        pure
        returns (bytes memory encoded)
    {
        return abi.encode(behavior);
    }
}
