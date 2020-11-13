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

import "../src/transformers/IERC20Transformer.sol";
import "./TestMintableERC20Token.sol";
import "./TestTransformerHost.sol";


contract TestFillQuoteTransformerHost is
    TestTransformerHost
{
    function executeTransform(
        IERC20Transformer transformer,
        TestMintableERC20Token inputToken,
        uint256 inputTokenAmount,
        address payable sender,
        address payable taker,
        bytes calldata data
    )
        external
        payable
    {
        if (inputTokenAmount != 0) {
            inputToken.mint(address(this), inputTokenAmount);
        }
        // Have to make this call externally because transformers aren't payable.
        this.rawExecuteTransform(
            transformer,
            IERC20Transformer.TransformContext({
                callDataHash: bytes32(0),
                sender: sender,
                taker: taker,
                data: data
            })
        );
    }
}
