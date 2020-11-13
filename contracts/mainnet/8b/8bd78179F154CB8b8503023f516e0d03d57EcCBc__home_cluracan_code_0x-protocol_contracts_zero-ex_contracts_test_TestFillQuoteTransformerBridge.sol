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

    function sellTokenForToken(
        address takerToken,
        address makerToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    )
        external
        returns (uint256 boughtAmount)
    {
        FillBehavior memory behavior = abi.decode(auxiliaryData, (FillBehavior));
        boughtAmount = LibMathV06.getPartialAmountFloor(
            behavior.makerAssetMintRatio,
            1e18,
            behavior.amount
        );
        TestMintableERC20Token(makerToken).mint(
          recipient,
          boughtAmount
        );
    }

    function encodeBehaviorData(FillBehavior calldata behavior)
        external
        pure
        returns (bytes memory encoded)
    {
        return abi.encode(behavior);
    }
}
