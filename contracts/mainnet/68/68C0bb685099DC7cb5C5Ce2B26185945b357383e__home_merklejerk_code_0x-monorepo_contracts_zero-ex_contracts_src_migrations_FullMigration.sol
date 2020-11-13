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

import "../ZeroEx.sol";
import "../features/IOwnableFeature.sol";
import "../features/TokenSpenderFeature.sol";
import "../features/TransformERC20Feature.sol";
import "../features/SignatureValidatorFeature.sol";
import "../features/MetaTransactionsFeature.sol";
import "../external/AllowanceTarget.sol";
import "./InitialMigration.sol";


/// @dev A contract for deploying and configuring the full ZeroEx contract.
contract FullMigration {

    // solhint-disable no-empty-blocks,indent

    /// @dev Features to add the the proxy contract.
    struct Features {
        SimpleFunctionRegistryFeature registry;
        OwnableFeature ownable;
        TokenSpenderFeature tokenSpender;
        TransformERC20Feature transformERC20;
        SignatureValidatorFeature signatureValidator;
        MetaTransactionsFeature metaTransactions;
    }

    /// @dev Parameters needed to initialize features.
    struct MigrateOpts {
        address transformerDeployer;
    }

    /// @dev The allowed caller of `initializeZeroEx()`.
    address public immutable initializeCaller;
    /// @dev The initial migration contract.
    InitialMigration private _initialMigration;

    /// @dev Instantiate this contract and set the allowed caller of `initializeZeroEx()`
    ///      to `initializeCaller`.
    /// @param initializeCaller_ The allowed caller of `initializeZeroEx()`.
    constructor(address payable initializeCaller_)
        public
    {
        initializeCaller = initializeCaller_;
        // Create an initial migration contract with this contract set to the
        // allowed `initializeCaller`.
        _initialMigration = new InitialMigration(address(this));
    }

    /// @dev Retrieve the bootstrapper address to use when constructing `ZeroEx`.
    /// @return bootstrapper The bootstrapper address.
    function getBootstrapper()
        external
        view
        returns (address bootstrapper)
    {
        return address(_initialMigration);
    }

    /// @dev Initialize the `ZeroEx` contract with the full feature set,
    ///      transfer ownership to `owner`, then self-destruct.
    /// @param owner The owner of the contract.
    /// @param zeroEx The instance of the ZeroEx contract. ZeroEx should
    ///        been constructed with this contract as the bootstrapper.
    /// @param features Features to add to the proxy.
    /// @return _zeroEx The configured ZeroEx contract. Same as the `zeroEx` parameter.
    /// @param migrateOpts Parameters needed to initialize features.
    function initializeZeroEx(
        address payable owner,
        ZeroEx zeroEx,
        Features memory features,
        MigrateOpts memory migrateOpts
    )
        public
        returns (ZeroEx _zeroEx)
    {
        require(msg.sender == initializeCaller, "FullMigration/INVALID_SENDER");

        // Perform the initial migration with the owner set to this contract.
        _initialMigration.initializeZeroEx(
            address(uint160(address(this))),
            zeroEx,
            InitialMigration.BootstrapFeatures({
                registry: features.registry,
                ownable: features.ownable
            })
        );

        // Add features.
        _addFeatures(zeroEx, owner, features, migrateOpts);

        // Transfer ownership to the real owner.
        IOwnableFeature(address(zeroEx)).transferOwnership(owner);

        // Self-destruct.
        this.die(owner);

        return zeroEx;
    }

    /// @dev Destroy this contract. Only callable from ourselves (from `initializeZeroEx()`).
    /// @param ethRecipient Receiver of any ETH in this contract.
    function die(address payable ethRecipient)
        external
        virtual
    {
        require(msg.sender == address(this), "FullMigration/INVALID_SENDER");
        // This contract should not hold any funds but we send
        // them to the ethRecipient just in case.
        selfdestruct(ethRecipient);
    }

    /// @dev Deploy and register features to the ZeroEx contract.
    /// @param zeroEx The bootstrapped ZeroEx contract.
    /// @param owner The ultimate owner of the ZeroEx contract.
    /// @param features Features to add to the proxy.
    /// @param migrateOpts Parameters needed to initialize features.
    function _addFeatures(
        ZeroEx zeroEx,
        address owner,
        Features memory features,
        MigrateOpts memory migrateOpts
    )
        private
    {
        IOwnableFeature ownable = IOwnableFeature(address(zeroEx));
        // TokenSpenderFeature
        {
            // Create the allowance target.
            AllowanceTarget allowanceTarget = new AllowanceTarget();
            // Let the ZeroEx contract use the allowance target.
            allowanceTarget.addAuthorizedAddress(address(zeroEx));
            // Transfer ownership of the allowance target to the (real) owner.
            allowanceTarget.transferOwnership(owner);
            // Register the feature.
            ownable.migrate(
                address(features.tokenSpender),
                abi.encodeWithSelector(
                    TokenSpenderFeature.migrate.selector,
                    allowanceTarget
                ),
                address(this)
            );
        }
        // TransformERC20Feature
        {
            // Register the feature.
            ownable.migrate(
                address(features.transformERC20),
                abi.encodeWithSelector(
                    TransformERC20Feature.migrate.selector,
                    migrateOpts.transformerDeployer
                ),
                address(this)
            );
        }
        // SignatureValidatorFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.signatureValidator),
                abi.encodeWithSelector(
                    SignatureValidatorFeature.migrate.selector
                ),
                address(this)
            );
        }
        // MetaTransactionsFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.metaTransactions),
                abi.encodeWithSelector(
                    MetaTransactionsFeature.migrate.selector
                ),
                address(this)
            );
        }
    }
}
