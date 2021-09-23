// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {LendingPoolInterface, AaveServicesInterface} from "./interface.sol";
import {Events} from "./events.sol";
import {Helpers} from "./helpers.sol";

abstract contract GAaveProtectionResolver is Events, Helpers {
    /// @dev Function for submitting a protection task
    /// @param _wantedHealthFactor targeted health after protection.
    /// @param _minimumHealthFactor trigger protection when current health
    /// factor is below _minimumHealthFactor.
    /// @param _isPermanent boolean to set a protection as permanent
    function submitProtection(
        uint256 _wantedHealthFactor,
        uint256 _minimumHealthFactor,
        bool _isPermanent
    ) external payable {
        _submitProtection(
            _wantedHealthFactor,
            _minimumHealthFactor,
            _isPermanent
        );
        emit LogSubmitProtection(
            address(this),
            _protectionAction,
            _wantedHealthFactor,
            _minimumHealthFactor,
            _isPermanent
        );
    }

    /// @dev Function for modifying a protection task
    /// @param _wantedHealthFactor targeted health after protection.
    /// @param _minimumHealthFactor trigger protection when current health
    /// factor is below _minimumHealthFactor.
    /// @param _isPermanent boolean to set a protection as permanent
    function updateProtection(
        uint256 _wantedHealthFactor,
        uint256 _minimumHealthFactor,
        bool _isPermanent
    ) external payable {
        _updateProtection(
            _wantedHealthFactor,
            _minimumHealthFactor,
            _isPermanent
        );
        emit LogUpdateProtection(
            address(this),
            _protectionAction,
            _wantedHealthFactor,
            _minimumHealthFactor,
            _isPermanent
        );
    }

    /// @dev Function for cancelling a protection task
    function cancelProtection() external payable {
        _cancelProtection();
        emit LogCancelProtection(address(this), _protectionAction);
    }

    /// @dev Function for cancelling and removing allowance
    /// of aToken to _protectionAction
    function cancelAndRevoke() external payable {
        if (_dsaHasProtection()) _cancelProtection();
        _revokeAllowance();
        emit LogCancelAndRevoke(address(this), _protectionAction);
    }
}

contract GAaveProtectionMainnetConnector is GAaveProtectionResolver {
    // solhint-disable-next-line const-name-snakecase
    string public constant name = "GAaveProtectionMainnetConnector-v1";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
}

struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
}

interface LendingPoolInterface {
    function getReservesList() external view returns (address[] memory);

    function getReserveData(address asset)
        external
        view
        returns (ReserveData memory);
}

interface AaveServicesInterface {
    function submitTask(
        address _action,
        bytes memory _taskData,
        bool _isPermanent
    ) external;

    function cancelTask(address _action) external;

    function updateTask(
        address _action,
        bytes memory _data,
        bool _isPermanent
    ) external;

    function taskByUsersAction(address _user, address _action)
        external
        view
        returns (bytes32);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Events {
    event LogSubmitProtection(
        address indexed dsa,
        address indexed action,
        uint256 wantedHealthFactor,
        uint256 minimumHealthFactor,
        bool isPermanent
    );
    event LogUpdateProtection(
        address indexed dsa,
        address indexed action,
        uint256 wantedHealthFactor,
        uint256 minimumHealthFactor,
        bool isPermanent
    );
    event LogCancelProtection(address indexed dsa, address indexed action);
    event LogCancelAndRevoke(address indexed dsa, address indexed action);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {
    LendingPoolInterface,
    AaveServicesInterface,
    IERC20
} from "./interface.sol";

abstract contract Helpers {
    // solhint-disable-next-line const-name-snakecase
    LendingPoolInterface internal constant _lendingPool =
        LendingPoolInterface(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    // solhint-disable-next-line const-name-snakecase
    AaveServicesInterface internal constant _aaveServices =
        AaveServicesInterface(0xE3d373c78803C1d22cE96bdC43d47542835bBF42);

    // solhint-disable-next-line const-name-snakecase
    address internal constant _protectionAction =
        0xD2579361F3C402938841774ECc1acdd51d3a4345;

    function _submitProtection(
        uint256 _wantedHealthFactor,
        uint256 _minimumHealthFactor,
        bool _isPermanent
    ) internal {
        _giveAllowance();

        _aaveServices.submitTask(
            _protectionAction,
            abi.encode(
                _wantedHealthFactor,
                _minimumHealthFactor,
                address(this)
            ),
            _isPermanent
        );
    }

    function _updateProtection(
        uint256 _wantedHealthFactor,
        uint256 _minimumHealthFactor,
        bool _isPermanent
    ) internal {
        _giveAllowance();

        _aaveServices.updateTask(
            _protectionAction,
            abi.encode(
                _wantedHealthFactor,
                _minimumHealthFactor,
                address(this)
            ),
            _isPermanent
        );
    }

    function _cancelProtection() internal {
        _aaveServices.cancelTask(_protectionAction);
    }

    function _giveAllowance() internal {
        address[] memory aTokenList = _getATokenList();
        for (uint256 i = 0; i < aTokenList.length; i++) {
            if (
                !(IERC20(aTokenList[i]).allowance(
                    address(this),
                    _protectionAction
                ) == type(uint256).max)
            ) {
                IERC20(aTokenList[i]).approve(
                    _protectionAction,
                    type(uint256).max
                );
            }
        }
    }

    function _revokeAllowance() internal {
        address[] memory aTokenList = _getATokenList();
        for (uint256 i = 0; i < aTokenList.length; i++) {
            if (
                !(IERC20(aTokenList[i]).allowance(
                    address(this),
                    _protectionAction
                ) == 0)
            ) {
                IERC20(aTokenList[i]).approve(_protectionAction, 0);
            }
        }
    }

    function _getATokenList()
        internal
        view
        returns (address[] memory aTokenList)
    {
        address[] memory underlyingsList = _lendingPool.getReservesList();
        aTokenList = new address[](underlyingsList.length);
        for (uint256 i = 0; i < underlyingsList.length; i++) {
            aTokenList[i] = (_lendingPool.getReserveData(underlyingsList[i]))
                .aTokenAddress;
        }
    }

    function _dsaHasProtection() internal view returns (bool) {
        return
            _aaveServices.taskByUsersAction(address(this), _protectionAction) !=
            bytes32(0);
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}