// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IDispatcher Interface
/// @author Enzyme Council <[email protected]>
interface IDispatcher {
    function cancelMigration(address _vaultProxy, bool _bypassFailure) external;

    function claimOwnership() external;

    function deployVaultProxy(
        address _vaultLib,
        address _owner,
        address _vaultAccessor,
        string calldata _fundName
    ) external returns (address vaultProxy_);

    function executeMigration(address _vaultProxy, bool _bypassFailure) external;

    function getCurrentFundDeployer() external view returns (address currentFundDeployer_);

    function getFundDeployerForVaultProxy(address _vaultProxy)
        external
        view
        returns (address fundDeployer_);

    function getMigrationRequestDetailsForVaultProxy(address _vaultProxy)
        external
        view
        returns (
            address nextFundDeployer_,
            address nextVaultAccessor_,
            address nextVaultLib_,
            uint256 executableTimestamp_
        );

    function getMigrationTimelock() external view returns (uint256 migrationTimelock_);

    function getNominatedOwner() external view returns (address nominatedOwner_);

    function getOwner() external view returns (address owner_);

    function getSharesTokenSymbol() external view returns (string memory sharesTokenSymbol_);

    function getTimelockRemainingForMigrationRequest(address _vaultProxy)
        external
        view
        returns (uint256 secondsRemaining_);

    function hasExecutableMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasExecutableRequest_);

    function hasMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasMigrationRequest_);

    function removeNominatedOwner() external;

    function setCurrentFundDeployer(address _nextFundDeployer) external;

    function setMigrationTimelock(uint256 _nextTimelock) external;

    function setNominatedOwner(address _nextNominatedOwner) external;

    function setSharesTokenSymbol(string calldata _nextSymbol) external;

    function signalMigration(
        address _vaultProxy,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../dispatcher/IDispatcher.sol";
import "./IFundValueCalculator.sol";

/// @title FundValueCalculatorRouter Contract
/// @author Enzyme Council <[email protected]>
/// @notice A peripheral contract for routing value calculation requests
/// to the correct FundValueCalculator instance for a particular release
/// @dev These values should generally only be consumed from off-chain,
/// unless you understand how each release interprets each calculation
contract FundValueCalculatorRouter {
    event FundValueCalculatorUpdated(address indexed fundDeployer, address fundValueCalculator);

    address private immutable DISPATCHER;

    mapping(address => address) private fundDeployerToFundValueCalculator;

    constructor(address _dispatcher) public {
        DISPATCHER = _dispatcher;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Calculates the GAV for a given fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return denominationAsset_ The denomination asset of the fund
    /// @return gav_ The GAV quoted in the denomination asset
    function calcGav(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 gav_)
    {
        return getFundValueCalculatorForVault(_vaultProxy).calcGav(_vaultProxy);
    }

    /// @notice Calculates the gross value of one shares unit (10 ** 18) for a given fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return denominationAsset_ The denomination asset of the fund
    /// @return grossShareValue_ The gross share value quoted in the denomination asset
    function calcGrossShareValue(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 grossShareValue_)
    {
        return getFundValueCalculatorForVault(_vaultProxy).calcGrossShareValue(_vaultProxy);
    }

    /// @notice Calculates the NAV for a given fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return denominationAsset_ The denomination asset of the fund
    /// @return nav_ The NAV quoted in the denomination asset
    function calcNav(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 nav_)
    {
        return getFundValueCalculatorForVault(_vaultProxy).calcNav(_vaultProxy);
    }

    /// @notice Calculates the net value of one shares unit (10 ** 18) for a given fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return denominationAsset_ The denomination asset of the fund
    /// @return netShareValue_ The net share value quoted in the denomination asset
    function calcNetShareValue(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 netShareValue_)
    {
        return getFundValueCalculatorForVault(_vaultProxy).calcNetShareValue(_vaultProxy);
    }

    /// @notice Calculates the net value of all shares held by a specified account
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _sharesHolder The account holding shares
    /// @return denominationAsset_ The denomination asset of the fund
    /// @return netValue_ The net value of all shares held by _sharesHolder
    function calcNetValueForSharesHolder(address _vaultProxy, address _sharesHolder)
        external
        returns (address denominationAsset_, uint256 netValue_)
    {
        return
            getFundValueCalculatorForVault(_vaultProxy).calcNetValueForSharesHolder(
                _vaultProxy,
                _sharesHolder
            );
    }

    /// @notice Sets FundValueCalculator instances for a list of FundDeployer instances
    /// @param _fundDeployers The FundDeployer instances
    /// @param _fundValueCalculators The FundValueCalculator instances corresponding
    /// to each instance in _fundDeployers
    function setFundValueCalculators(
        address[] memory _fundDeployers,
        address[] memory _fundValueCalculators
    ) external {
        require(
            msg.sender == IDispatcher(getDispatcher()).getOwner(),
            "Only the Dispatcher owner can call this function"
        );
        require(
            _fundDeployers.length == _fundValueCalculators.length,
            "setFundValueCalculators: Unequal array lengths"
        );

        for (uint256 i; i < _fundDeployers.length; i++) {
            fundDeployerToFundValueCalculator[_fundDeployers[i]] = _fundValueCalculators[i];

            emit FundValueCalculatorUpdated(_fundDeployers[i], _fundValueCalculators[i]);
        }
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the FundValueCalculator instance to use for a given fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return fundValueCalculatorContract_ The FundValueCalculator instance
    function getFundValueCalculatorForVault(address _vaultProxy)
        public
        view
        returns (IFundValueCalculator fundValueCalculatorContract_)
    {
        address fundDeployer = IDispatcher(DISPATCHER).getFundDeployerForVaultProxy(_vaultProxy);
        require(fundDeployer != address(0), "getFundValueCalculatorForVault: Invalid _vaultProxy");

        address fundValueCalculator = getFundValueCalculatorForFundDeployer(fundDeployer);
        require(
            fundValueCalculator != address(0),
            "getFundValueCalculatorForVault: No FundValueCalculator set"
        );

        return IFundValueCalculator(fundValueCalculator);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `DISPATCHER` variable
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return DISPATCHER;
    }

    /// @notice Gets the FundValueCalculator address for a given FundDeployer
    /// @param _fundDeployer The FundDeployer for which to get the FundValueCalculator address
    /// @return fundValueCalculator_ The FundValueCalculator address
    function getFundValueCalculatorForFundDeployer(address _fundDeployer)
        public
        view
        returns (address fundValueCalculator_)
    {
        return fundDeployerToFundValueCalculator[_fundDeployer];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IFundValueCalculator interface
/// @author Enzyme Council <[email protected]>
interface IFundValueCalculator {
    function calcGav(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 gav_);

    function calcGrossShareValue(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 grossShareValue_);

    function calcNav(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 nav_);

    function calcNetShareValue(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 netShareValue_);

    function calcNetValueForSharesHolder(address _vaultProxy, address _sharesHolder)
        external
        returns (address denominationAsset_, uint256 netValue_);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "details": {
      "constantOptimizer": true,
      "cse": true,
      "deduplicate": true,
      "jumpdestRemover": true,
      "orderLiterals": true,
      "peephole": true,
      "yul": false
    },
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}