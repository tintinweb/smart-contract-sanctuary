// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


import {PermissionAdmin} from '@kyber.network/utils-sc/contracts/PermissionAdmin.sol';
import {PermissionOperators} from '@kyber.network/utils-sc/contracts/PermissionOperators.sol';
import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';
import {IPool} from '../../interfaces/liquidation/IPool.sol';
import {INoSwappingLiquidationStrategy} from '../../interfaces/liquidation/INoSwappingLiquidationStrategy.sol';

/// @dev The simplest liquidation strategy which requests funds from TreasuryPool and
/// 	transfer directly to treasury pool, no actual liquidation happens
contract NoSwappingLiquidationStrategy is PermissionAdmin, PermissionOperators,
	INoSwappingLiquidationStrategy {

  IPool private _treasuryPool;
  address payable private _rewardPool;

  constructor(
    address admin,
    address treasuryPoolAddress,
    address payable rewardPoolAddress
  ) PermissionAdmin(admin) {
    _setTreasuryPool(treasuryPoolAddress);
    _setRewardPool(rewardPoolAddress);
  }

  function updateTreasuryPool(address pool) external override onlyAdmin {
    _setTreasuryPool(pool);
  }

  function updateRewardPool(address payable pool) external override onlyAdmin {
    _setRewardPool(pool);
  }

  /** @dev Fast forward tokens from fee pool to treasury pool
  * @param sources list of source tokens to liquidate
  * @param amounts list of amounts corresponding to each source token
  */
  function liquidate(IERC20Ext[] calldata sources, uint256[] calldata amounts)
		external override
	{
		// check for sources and amounts length will be done in fee pool
		_treasuryPool.withdrawFunds(sources, amounts, _rewardPool);
		emit Liquidated(msg.sender, sources, amounts);
	}

  function treasuryPool() external override view returns (address) {
    return address(_treasuryPool);
  }

  function rewardPool() external override view returns (address) {
    return _rewardPool;
  }

  function _setTreasuryPool(address _pool) internal {
    require(_pool != address(0), 'invalid treasury pool');
    _treasuryPool = IPool(_pool);
    emit TreasuryPoolSet(_pool);
  }

  function _setRewardPool(address payable _pool) internal {
    require(_pool != address(0), 'invalid reward pool');
    _rewardPool = _pool;
    emit RewardPoolSet(_pool);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


abstract contract PermissionAdmin {
    address public admin;
    address public pendingAdmin;

    event AdminClaimed(address newAdmin, address previousAdmin);

    event TransferAdminPending(address pendingAdmin);

    constructor(address _admin) {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./PermissionAdmin.sol";


abstract contract PermissionOperators is PermissionAdmin {
    uint256 private constant MAX_GROUP_SIZE = 50;

    mapping(address => bool) internal operators;
    address[] internal operatorsGroup;

    event OperatorAdded(address newOperator, bool isAdd);

    modifier onlyOperator() {
        require(operators[msg.sender], "only operator");
        _;
    }

    function getOperators() external view returns (address[] memory) {
        return operatorsGroup;
    }

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator], "operator exists"); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE, "max operators");

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator(address operator) public onlyAdmin {
        require(operators[operator], "not operator");
        operators[operator] = false;

        for (uint256 i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.pop();
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev Interface extending ERC20 standard to include decimals() as
 *      it is optional in the OpenZeppelin IERC20 interface.
 */
interface IERC20Ext is IERC20 {
    /**
     * @dev This function is required as Kyber requires to interact
     *      with token.decimals() with many of its operations.
     */
    function decimals() external view returns (uint8 digits);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';

interface IPool {

  event AuthorizedStrategy(address indexed strategy);
  event UnauthorizedStrategy(address indexed strategy);
  event Paused(address indexed sender);
  event Unpaused(address indexed sender);
  event WithdrawToken(
    IERC20Ext indexed token,
    address indexed sender,
    address indexed recipient,
    uint256 amount
  );

  function pause() external;
  function unpause() external;
  function authorizeStrategies(address[] calldata strategies) external;
  function unauthorizeStrategies(address[] calldata strategies) external;
  function withdrawFunds(
    IERC20Ext[] calldata tokens,
    uint256[] calldata amounts,
    address payable recipient
  ) external;
  function isPaused() external view returns (bool);
  function isAuthorizedStrategy(address strategy) external view returns (bool);
  function getAuthorizedStrategiesLength() external view returns (uint256);
  function getAuthorizedStrategyAt(uint256 index) external view returns (address);
  function getAllAuthorizedStrategies()
    external view returns (address[] memory strategies);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';


interface INoSwappingLiquidationStrategy {
  event TreasuryPoolSet(address indexed treasuryPool);
  event RewardPoolSet(address indexed rewardPool);
  event Liquidated(address sender, IERC20Ext[] sources, uint256[] amounts);

  function updateTreasuryPool(address pool) external;
  function updateRewardPool(address payable pool) external;
  function liquidate(IERC20Ext[] calldata sources, uint256[] calldata amounts) external;
  function treasuryPool() external view returns (address);
  function rewardPool() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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
  "libraries": {}
}