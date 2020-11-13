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

contract MixinAdapterAddresses
{

    struct AdapterAddresses {
        // Bridges
        address balancerBridge;
        address curveBridge;
        address kyberBridge;
        address mooniswapBridge;
        address mStableBridge;
        address oasisBridge;
        address uniswapBridge;
        address uniswapV2Bridge;
        // Exchanges
        address kyberNetworkProxy;
        address oasis;
        address uniswapV2Router;
        address uniswapExchangeFactory;
        address mStable;
        // Other
        address weth;
    }
}
