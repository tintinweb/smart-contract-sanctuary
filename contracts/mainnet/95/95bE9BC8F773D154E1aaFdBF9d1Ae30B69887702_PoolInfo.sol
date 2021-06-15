/*
OwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Owner controller
 *
 * @notice this base contract implements an owner-controller access model.
 *
 * @dev the contract is an adapted version of the OpenZeppelin Ownable contract.
 * It allows the owner to designate an additional account as the controller to
 * perform restricted operations.
 *
 * Other changes include supporting role verification with a require method
 * in addition to the modifier option, and removing some unneeded functionality.
 *
 * Original contract here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
contract OwnerController {
    address private _owner;
    address private _controller;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    constructor() {
        _owner = msg.sender;
        _controller = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit ControlTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view returns (address) {
        return _controller;
    }

    /**
     * @dev Modifier that throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "oc1");
        _;
    }

    /**
     * @dev Modifier that throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_controller == msg.sender, "oc2");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOwner() internal view {
        require(_owner == msg.sender, "oc1");
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    function requireController() internal view {
        require(_controller == msg.sender, "oc2");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        requireOwner();
        require(newOwner != address(0), "oc3");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) public virtual {
        requireOwner();
        require(newController != address(0), "oc4");
        emit ControlTransferred(_controller, newController);
        _controller = newController;
    }
}

/*
PoolInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "../interfaces/IPool.sol";
import "../interfaces/IStakingModule.sol";
import "../interfaces/IRewardModule.sol";

/**
 * @title Pool info library
 *
 * @notice this implements the Pool info library, which provides read-only
 * convenience functions to query additional information and metadata
 * about the core Pool contract.
 */
library PoolInfo {
    /**
     * @notice get information about the underlying staking and reward modules
     * @param pool address of Pool contract
     * @return staking module address
     * @return reward module address
     * @return staking module type
     * @return reward module type
     */
    function modules(address pool)
        public
        view
        returns (
            address,
            address,
            address,
            address
        )
    {
        IPool p = IPool(pool);
        IStakingModule s = IStakingModule(p.stakingModule());
        IRewardModule r = IRewardModule(p.rewardModule());
        return (address(s), address(r), s.factory(), r.factory());
    }
}

/*
IEvents

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.4;

/**
 * @title GYSR event system
 *
 * @notice common interface to define GYSR event system
 */
interface IEvents {
    // staking
    event Staked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Unstaked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Claimed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );

    // rewards
    event RewardsDistributed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event RewardsFunded(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsUnlocked(address indexed token, uint256 shares);
    event RewardsExpired(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    // gysr
    event GysrSpent(address indexed user, uint256 amount);
    event GysrVested(address indexed user, uint256 amount);
    event GysrWithdrawn(uint256 amount);
}

/*
IPool

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Pool interface
 *
 * @notice this defines the core Pool contract interface
 */
interface IPool {
    /**
     * @return staking tokens for Pool
     */
    function stakingTokens() external view returns (address[] memory);

    /**
     * @return reward tokens for Pool
     */
    function rewardTokens() external view returns (address[] memory);

    /**
     * @return staking balances for user
     */
    function stakingBalances(address user)
        external
        view
        returns (uint256[] memory);

    /**
     * @return total staking balances for Pool
     */
    function stakingTotals() external view returns (uint256[] memory);

    /**
     * @return reward balances for Pool
     */
    function rewardBalances() external view returns (uint256[] memory);

    /**
     * @return GYSR usage ratio for Pool
     */
    function usage() external view returns (uint256);

    /**
     * @return address of staking module
     */
    function stakingModule() external view returns (address);

    /**
     * @return address of reward module
     */
    function rewardModule() external view returns (address);

    /**
     * @notice stake asset and begin earning rewards
     * @param amount number of tokens to unstake
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function stake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @notice unstake asset and claim rewards
     * @param amount number of tokens to unstake
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function unstake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @notice claim rewards without unstaking
     * @param amount number of tokens to claim against
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function claim(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @notice method called ad hoc to update user accounting
     */
    function update() external;

    /**
     * @notice method called ad hoc to clean up and perform additional accounting
     */
    function clean() external;

    /**
     * @return gysr balance available for withdrawal
     */
    function gysrBalance() external view returns (uint256);

    /**
     * @notice withdraw GYSR tokens applied during unstaking
     * @param amount number of GYSR to withdraw
     */
    function withdraw(uint256 amount) external;
}

/*
IRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";

import "../OwnerController.sol";

/**
 * @title Reward module interface
 *
 * @notice this contract defines the common interface that any reward module
 * must implement to be compatible with the modular Pool architecture.
 */
abstract contract IRewardModule is OwnerController, IEvents {
    // constants
    uint256 public constant DECIMALS = 18;

    /**
     * @return array of reward tokens
     */
    function tokens() external view virtual returns (address[] memory);

    /**
     * @return array of reward token balances
     */
    function balances() external view virtual returns (uint256[] memory);

    /**
     * @return GYSR usage ratio for reward module
     */
    function usage() external view virtual returns (uint256);

    /**
     * @return address of module factory
     */
    function factory() external view virtual returns (address);

    /**
     * @notice perform any necessary accounting for new stake
     * @param account address of staking account
     * @param user address of user
     * @param shares number of new shares minted
     * @param data addtional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function stake(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external virtual returns (uint256, uint256);

    /**
     * @notice reward user and perform any necessary accounting for unstake
     * @param account address of staking account
     * @param user address of user
     * @param shares number of shares burned
     * @param data additional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function unstake(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external virtual returns (uint256, uint256);

    /**
     * @notice reward user and perform and necessary accounting for existing stake
     * @param account address of staking account
     * @param user address of user
     * @param shares number of shares being claimed against
     * @param data addtional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function claim(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external virtual returns (uint256, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @param user address of user for update
     * @dev will only be called ad hoc and should not contain essential logic
     */
    function update(address user) external virtual;

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     */
    function clean() external virtual;
}

/*
IStakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";

import "../OwnerController.sol";

/**
 * @title Staking module interface
 *
 * @notice this contract defines the common interface that any staking module
 * must implement to be compatible with the modular Pool architecture.
 */
abstract contract IStakingModule is OwnerController, IEvents {
    // constants
    uint256 public constant DECIMALS = 18;

    /**
     * @return array of staking tokens
     */
    function tokens() external view virtual returns (address[] memory);

    /**
     * @notice get balance of user
     * @param user address of user
     * @return balances of each staking token
     */
    function balances(address user)
        external
        view
        virtual
        returns (uint256[] memory);

    /**
     * @return address of module factory
     */
    function factory() external view virtual returns (address);

    /**
     * @notice get total staked amount
     * @return totals for each staking token
     */
    function totals() external view virtual returns (uint256[] memory);

    /**
     * @notice stake an amount of tokens for user
     * @param user address of user
     * @param amount number of tokens to stake
     * @param data additional data
     * @return address of staking account
     * @return number of shares minted for stake
     */
    function stake(
        address user,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (address, uint256);

    /**
     * @notice unstake an amount of tokens for user
     * @param user address of user
     * @param amount number of tokens to unstake
     * @param data additional data
     * @return address of staking account
     * @return number of shares burned for unstake
     */
    function unstake(
        address user,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (address, uint256);

    /**
     * @notice quote the share value for an amount of tokens without unstaking
     * @param user address of user
     * @param amount number of tokens to claim with
     * @param data additional data
     * @return address of staking account
     * @return number of shares that the claim amount is worth
     */
    function claim(
        address user,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (address, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @param user address of user for update
     * @dev will only be called ad hoc and should not contain essential logic
     */
    function update(address user) external virtual;

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     */
    function clean() external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 10000
  },
  "evmVersion": "istanbul",
  "libraries": {},
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