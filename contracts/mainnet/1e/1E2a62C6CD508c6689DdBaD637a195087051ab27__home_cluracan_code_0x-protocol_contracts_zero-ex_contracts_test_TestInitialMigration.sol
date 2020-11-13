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

import "../src/ZeroEx.sol";
import "../src/features/IBootstrapFeature.sol";
import "../src/migrations/InitialMigration.sol";
import "../src/features/SimpleFunctionRegistryFeature.sol";


contract TestInitialMigration is
    InitialMigration
{
    address public bootstrapFeature;
    address public dieRecipient;

    // solhint-disable-next-line no-empty-blocks
    constructor(address deployer) public InitialMigration(deployer) {}

    function callBootstrap(ZeroEx zeroEx) external {
        IBootstrapFeature(address(zeroEx)).bootstrap(address(this), new bytes(0));
    }

    function bootstrap(address owner, BootstrapFeatures memory features)
        public
        override
        returns (bytes4 success)
    {
        success = InitialMigration.bootstrap(owner, features);
        // Snoop the bootstrap feature contract.
        bootstrapFeature =
            SimpleFunctionRegistryFeature(address(uint160(address(this))))
            .getFunctionImplementation(IBootstrapFeature.bootstrap.selector);
    }

    function die(address payable ethRecipient) public override {
        dieRecipient = ethRecipient;
    }
}
