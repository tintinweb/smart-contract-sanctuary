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
Pool

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IPool.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IStakingModule.sol";
import "./interfaces/IRewardModule.sol";
import "./interfaces/IEvents.sol";
import "./OwnerController.sol";

/**
 * @title Pool
 *
 * @notice this implements the GYSR core Pool contract. It supports generalized
 * incentive mechanisms through a modular architecture, where
 * staking and reward logic is contained in child contracts.
 */
contract Pool is IPool, IEvents, ReentrancyGuard, OwnerController {
    using SafeERC20 for IERC20;

    // constants
    uint256 public constant DECIMALS = 18;

    // modules
    IStakingModule private immutable _staking;
    IRewardModule private immutable _reward;

    // gysr fields
    IERC20 private immutable _gysr;
    IPoolFactory private immutable _factory;
    uint256 private _gysrVested;

    /**
     * @param staking_ the staking module address
     * @param reward_ the reward module address
     * @param gysr_ address for GYSR token
     * @param factory_ address for parent factory
     */
    constructor(
        address staking_,
        address reward_,
        address gysr_,
        address factory_
    ) {
        _staking = IStakingModule(staking_);
        _reward = IRewardModule(reward_);
        _gysr = IERC20(gysr_);
        _factory = IPoolFactory(factory_);
    }

    // -- IPool --------------------------------------------------------------

    /**
     * @inheritdoc IPool
     */
    function stakingTokens() external view override returns (address[] memory) {
        return _staking.tokens();
    }

    /**
     * @inheritdoc IPool
     */
    function rewardTokens() external view override returns (address[] memory) {
        return _reward.tokens();
    }

    /**
     * @inheritdoc IPool
     */
    function stakingBalances(address user)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _staking.balances(user);
    }

    /**
     * @inheritdoc IPool
     */
    function stakingTotals() external view override returns (uint256[] memory) {
        return _staking.totals();
    }

    /**
     * @inheritdoc IPool
     */
    function rewardBalances()
        external
        view
        override
        returns (uint256[] memory)
    {
        return _reward.balances();
    }

    /**
     * @inheritdoc IPool
     */
    function usage() external view override returns (uint256) {
        return _reward.usage();
    }

    /**
     * @inheritdoc IPool
     */
    function stakingModule() external view override returns (address) {
        return address(_staking);
    }

    /**
     * @inheritdoc IPool
     */
    function rewardModule() external view override returns (address) {
        return address(_reward);
    }

    /**
     * @inheritdoc IPool
     */
    function stake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        (address account, uint256 shares) =
            _staking.stake(msg.sender, amount, stakingdata);
        (uint256 spent, uint256 vested) =
            _reward.stake(account, msg.sender, shares, rewarddata);
        _processGysr(spent, vested);
    }

    /**
     * @inheritdoc IPool
     */
    function unstake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        (address account, uint256 shares) =
            _staking.unstake(msg.sender, amount, stakingdata);
        (uint256 spent, uint256 vested) =
            _reward.unstake(account, msg.sender, shares, rewarddata);
        _processGysr(spent, vested);
    }

    /**
     * @inheritdoc IPool
     */
    function claim(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        (address account, uint256 shares) =
            _staking.claim(msg.sender, amount, stakingdata);
        (uint256 spent, uint256 vested) =
            _reward.claim(account, msg.sender, shares, rewarddata);
        _processGysr(spent, vested);
    }

    /**
     * @inheritdoc IPool
     */
    function update() external override nonReentrant {
        _staking.update(msg.sender);
        _reward.update(msg.sender);
    }

    /**
     * @inheritdoc IPool
     */
    function clean() external override nonReentrant {
        requireController();
        _staking.clean();
        _reward.clean();
    }

    /**
     * @inheritdoc IPool
     */
    function gysrBalance() external view override returns (uint256) {
        return _gysrVested;
    }

    /**
     * @inheritdoc IPool
     */
    function withdraw(uint256 amount) external override {
        requireController();
        require(amount > 0, "p1");
        require(amount <= _gysrVested, "p2");

        // do transfer
        _gysr.safeTransfer(msg.sender, amount);

        _gysrVested = _gysrVested - amount;

        emit GysrWithdrawn(amount);
    }

    /**
     * @notice transfer control of the Pool and modules to another account
     * @param newController address of new controller
     */
    function transferControl(address newController) public override {
        super.transferControl(newController);
        _staking.transferControl(newController);
        _reward.transferControl(newController);
    }

    // -- Pool internal -----------------------------------------------------

    /**
     * @dev private method to process GYSR spending and vesting
     * @param spent number of tokens to unstake
     * @param vested data passed to staking module
     */
    function _processGysr(uint256 spent, uint256 vested) private {
        // spending
        if (spent > 0) {
            _gysr.safeTransferFrom(msg.sender, address(this), spent);
        }

        // vesting
        if (vested > 0) {
            uint256 fee = (vested * _factory.fee()) / 10**DECIMALS;
            if (fee > 0) {
                _gysr.safeTransfer(_factory.treasury(), fee);
            }
            _gysrVested = _gysrVested + vested - fee;
        }
    }
}

/*
PoolFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./interfaces/IPoolFactory.sol";
import "./interfaces/IModuleFactory.sol";
import "./interfaces/IStakingModule.sol";
import "./interfaces/IRewardModule.sol";
import "./OwnerController.sol";
import "./Pool.sol";

/**
 * @title Pool factory
 *
 * @notice this implements the Pool factory contract which allows any user to
 * easily configure and deploy their own Pool
 *
 * @dev it relies on a system of sub-factories which are responsible for the
 * creation of underlying staking and reward modules. This primary factory
 * calls each module factory and assembles the overall Pool contract.
 *
 * this contract also manages various privileged platform settings including
 * treasury address, fee amount, and module factory whitelist.
 */
contract PoolFactory is IPoolFactory, OwnerController {
    // events
    event PoolCreated(address indexed user, address pool);
    event FeeUpdated(uint256 previous, uint256 updated);
    event TreasuryUpdated(address previous, address updated);
    event WhitelistUpdated(
        address indexed factory,
        uint256 previous,
        uint256 updated
    );

    // types
    enum ModuleFactoryType {Unknown, Staking, Reward}

    // constants
    uint256 public constant MAX_FEE = 20 * 10**16; // 20%

    // fields
    mapping(address => bool) public map;
    address[] public list;
    address private _gysr;
    address private _treasury;
    uint256 private _fee;
    mapping(address => ModuleFactoryType) public whitelist;

    /**
     * @param gysr_ address of GYSR token
     */
    constructor(address gysr_, address treasury_) {
        _gysr = gysr_;
        _treasury = treasury_;
        _fee = MAX_FEE;
    }

    /**
     * @notice create a new Pool
     * @param staking address of factory that will be used to create staking module
     * @param reward address of factory that will be used to create reward module
     * @param stakingdata construction data for staking module factory
     * @param rewarddata construction data for reward module factory
     * @return address of newly created Pool
     */
    function create(
        address staking,
        address reward,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external returns (address) {
        // validate
        require(whitelist[staking] == ModuleFactoryType.Staking, "f1");
        require(whitelist[reward] == ModuleFactoryType.Reward, "f2");

        // create modules
        address stakingModule =
            IModuleFactory(staking).createModule(stakingdata);
        address rewardModule = IModuleFactory(reward).createModule(rewarddata);

        // create pool
        Pool pool = new Pool(stakingModule, rewardModule, _gysr, address(this));

        // set access
        IStakingModule(stakingModule).transferOwnership(address(pool));
        IRewardModule(rewardModule).transferOwnership(address(pool));
        pool.transferControl(msg.sender); // this also sets controller for modules
        pool.transferOwnership(msg.sender);

        // bookkeeping
        map[address(pool)] = true;
        list.push(address(pool));

        // output
        emit PoolCreated(msg.sender, address(pool));
        return address(pool);
    }

    /**
     * @inheritdoc IPoolFactory
     */
    function treasury() external view override returns (address) {
        return _treasury;
    }

    /**
     * @inheritdoc IPoolFactory
     */
    function fee() external view override returns (uint256) {
        return _fee;
    }

    /**
     * @notice update the GYSR treasury address
     * @param treasury_ new value for treasury address
     */
    function setTreasury(address treasury_) external {
        requireController();
        emit TreasuryUpdated(_treasury, treasury_);
        _treasury = treasury_;
    }

    /**
     * @notice update the global GYSR spending fee
     * @param fee_ new value for GYSR spending fee
     */
    function setFee(uint256 fee_) external {
        requireController();
        require(fee_ <= MAX_FEE, "f3");
        emit FeeUpdated(_fee, fee_);
        _fee = fee_;
    }

    /**
     * @notice set the whitelist status of a module factory
     * @param factory_ address of module factory
     * @param type_ updated whitelist status for module
     */
    function setWhitelist(address factory_, uint256 type_) external {
        requireController();
        require(type_ <= uint256(ModuleFactoryType.Reward), "f4");
        require(factory_ != address(0), "f5");
        emit WhitelistUpdated(factory_, uint256(whitelist[factory_]), type_);
        whitelist[factory_] = ModuleFactoryType(type_);
    }

    /**
     * @return total number of Pools created by the factory
     */
    function count() public view returns (uint256) {
        return list.length;
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
IModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Module factory interface
 *
 * @notice this defines the common module factory interface used by the
 * main factory to create the staking and reward modules for a new Pool.
 */
interface IModuleFactory {
    // events
    event ModuleCreated(address indexed user, address module);

    /**
     * @notice create a new Pool module
     * @param data binary encoded construction parameters
     * @return address of newly created module
     */
    function createModule(bytes calldata data) external returns (address);
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
IPoolFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Pool factory interface
 *
 * @notice this defines the Pool factory interface, primarily intended for
 * the Pool contract to interact with
 */
interface IPoolFactory {
    /**
     * @return GYSR treasury address
     */
    function treasury() external view returns (address);

    /**
     * @return GYSR spending fee
     */
    function fee() external view returns (uint256);
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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