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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../src/transformers/IERC20Transformer.sol";
import "../src/transformers/LibERC20Transformer.sol";


contract TestTransformerHost {

    using LibERC20Transformer for IERC20TokenV06;
    using LibRichErrorsV06 for bytes;

    function rawExecuteTransform(
        IERC20Transformer transformer,
        IERC20Transformer.TransformContext calldata context
    )
        external
    {
        (bool _success, bytes memory resultData) =
            address(transformer).delegatecall(abi.encodeWithSelector(
                transformer.transform.selector,
                context
            ));
        if (!_success) {
            resultData.rrevert();
        }
        require(
            abi.decode(resultData, (bytes4)) == LibERC20Transformer.TRANSFORMER_SUCCESS,
            "TestTransformerHost/INVALID_TRANSFORMER_RESULT"
        );
    }

    // solhint-disable
    receive() external payable {}
    // solhint-enable
}
