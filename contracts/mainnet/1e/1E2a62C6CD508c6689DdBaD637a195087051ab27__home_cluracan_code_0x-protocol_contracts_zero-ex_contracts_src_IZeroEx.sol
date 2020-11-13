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

import "./features/IOwnableFeature.sol";
import "./features/ISimpleFunctionRegistryFeature.sol";
import "./features/ITokenSpenderFeature.sol";
import "./features/ISignatureValidatorFeature.sol";
import "./features/ITransformERC20Feature.sol";
import "./features/IMetaTransactionsFeature.sol";
import "./features/IUniswapFeature.sol";
import "./features/ILiquidityProviderFeature.sol";


/// @dev Interface for a fully featured Exchange Proxy.
interface IZeroEx is
    IOwnableFeature,
    ISimpleFunctionRegistryFeature,
    ITokenSpenderFeature,
    ISignatureValidatorFeature,
    ITransformERC20Feature,
    IMetaTransactionsFeature,
    IUniswapFeature,
    ILiquidityProviderFeature
{
    // solhint-disable state-visibility

    /// @dev Fallback for just receiving ether.
    receive() external payable;
}
