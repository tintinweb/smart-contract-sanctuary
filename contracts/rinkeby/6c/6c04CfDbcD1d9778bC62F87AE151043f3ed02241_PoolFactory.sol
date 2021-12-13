// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IPoolMaster.sol";
import "./interfaces/IFlashGovernor.sol";
import "./interfaces/IMembershipStaking.sol";
import "./libraries/Decimal.sol";

contract PoolFactory is OwnableUpgradeable {
    using ClonesUpgradeable for address;
    using Decimal for uint256;

    /// @notice CPOOL token contract
    IERC20Upgradeable public cpool;

    /// @notice MembershipStaking contract
    IMembershipStaking public staking;

    /// @notice FlashGovernor contract
    IFlashGovernor public flashGovernor;

    /// @notice Pool master contract
    address public poolMaster;

    /// @notice Interest Rate Model contract address
    address public interestRateModel;

    /// @notice Address of the auction contract
    address public auction;

    /// @notice Address of the treasury
    address public treasury;

    /// @notice Reserve factor as 10-digit decimal
    uint256 public reserveFactor;

    /// @notice Insurance factor as 10-digit decimal
    uint256 public insuranceFactor;

    /// @notice Pool utilization that leads to warning state (as 10-digit decimal)
    uint256 public warningUtilization;

    /// @notice Grace period for warning state before pool goes to default (in seconds)
    uint256 public warningGracePeriod;

    /// @notice Max period for which pool can stay not active before it can be closed by governor (in seconds)
    uint256 public maxInactivePeriod;

    /// @notice Debt auction duration (in seconds)
    uint256 public auctionDuration;

    /// @notice Allowance of different currencies in protocol
    mapping(address => bool) public currencyAllowed;

    struct PoolInfo {
        address currency;
        address pool;
        uint256 proposalId;
        bytes32 managerInfo;
        string managerSymbol;
        address staker;
        uint256 stakedAmount;
    }

    /// @notice Mapping of manager addresses to their pool info
    mapping(address => PoolInfo) public poolInfo;

    /// @notice Mapping of manager symbols to flags if they are already used
    mapping(string => bool) public usedManagerSymbols;

    // EVENTS

    /// @notice Event emitted when new pool is proposed
    event PoolProposed(address indexed manager, address indexed currency);

    /// @notice Event emitted when proposed pool is cancelled
    event PoolCancelled(address indexed manager, address indexed currency);

    /// @notice Event emitted when new pool is created
    event PoolCreated(
        address indexed pool,
        address indexed manager,
        address indexed currency
    );

    /// @notice Event emitted when pool is closed
    event PoolClosed(
        address indexed pool,
        address indexed manager,
        address indexed currency
    );

    // CONSTRUCTOR

    /**
     * @notice Upgradeable contract constructor
     * @param cpool_ The address of the CPOOL contract
     * @param staking_ The address of the Staking contract
     * @param flashGovernor_ The address of the FlashGovernor contract
     * @param poolMaster_ The address of the PoolMaster contract
     * @param interestRateModel_ The address of the InterestRateModel contract
     * @param auction_ The address of the Auction contract
     */
    function initialize(
        IERC20Upgradeable cpool_,
        IMembershipStaking staking_,
        IFlashGovernor flashGovernor_,
        address poolMaster_,
        address interestRateModel_,
        address auction_
    ) public initializer {
        __Ownable_init();

        cpool = cpool_;
        staking = staking_;
        flashGovernor = flashGovernor_;
        poolMaster = poolMaster_;
        interestRateModel = interestRateModel_;
        auction = auction_;
    }

    /* PUBLIC FUNCTIONS */

    /**
     * @notice Function used to propose new pool for the first time (with manager's info)
     * @param currency Address of the ERC20 token that would act as currnecy in the pool
     * @param managerInfo IPFS hash of the manager's info
     * @param managerSymbol Manager's symbol
     */
    function proposePoolInitial(
        address currency,
        bytes32 managerInfo,
        string memory managerSymbol
    ) external {
        _setManager(msg.sender, managerInfo, managerSymbol);
        _proposePool(currency);
    }

    /**
     * @notice Function used to propose new pool (when manager's info already exist)
     * @param currency Address of the ERC20 token that would act as currnecy in the pool
     */
    function proposePool(address currency) external {
        require(poolInfo[msg.sender].managerInfo != bytes32(0), "MHI");

        _proposePool(currency);
    }

    /**
     * @notice Function used to create proposed and approved pool
     */
    function createPool() external {
        PoolInfo storage info = poolInfo[msg.sender];
        flashGovernor.execute(info.proposalId);
        IPoolMaster pool = IPoolMaster(poolMaster.clone());
        pool.initialize(msg.sender, info.currency);
        info.pool = address(pool);

        emit PoolCreated(address(pool), msg.sender, info.currency);
    }

    /**
     * @notice Function used to cancel proposed but not yet created pool
     */
    function cancelPool() external {
        PoolInfo storage info = poolInfo[msg.sender];
        require(info.proposalId != 0 && info.pool == address(0), "NPP");

        emit PoolCancelled(msg.sender, info.currency);

        info.currency = address(0);
        info.proposalId = 0;
        staking.unlockStake(info.staker, info.stakedAmount);
    }

    // RESTRICTED FUNCTIONS

    /**
     * @notice Function used to immedeately create new pool for some manager for the first time
     * @notice Skips approval, restricted to owner
     * @param manager Manager to create pool for
     * @param currency Address of the ERC20 token that would act as currnecy in the pool
     * @param managerInfo IPFS hash of the manager's info
     * @param managerSymbol Manager's symbol
     */
    function forceCreatePoolInitial(
        address manager,
        address currency,
        bytes32 managerInfo,
        string memory managerSymbol
    ) external onlyOwner {
        _setManager(manager, managerInfo, managerSymbol);

        _forceCreatePool(manager, currency);
    }

    /**
     * @notice Function used to immedeately create new pool for some manager (when info already exist)
     * @notice Skips approval, restricted to owner
     * @param manager Manager to create pool for
     * @param currency Address of the ERC20 token that would act as currnecy in the pool
     */
    function forceCreatePool(address manager, address currency)
        external
        onlyOwner
    {
        require(poolInfo[manager].managerInfo != bytes32(0), "MHI");

        _forceCreatePool(manager, currency);
    }

    /**
     * @notice Function is called by contract owner to update currency allowance in the protocol
     * @param currency Address of the ERC20 token
     * @param allowed Should currency be allowed or forbidden
     */
    function setCurrency(address currency, bool allowed) external onlyOwner {
        currencyAllowed[currency] = allowed;
    }

    /**
     * @notice Function is called by contract owner to set new PoolMaster
     * @param poolMaster_ Address of the new PoolMaster contract
     */
    function setPoolMaster(address poolMaster_) external onlyOwner {
        require(poolMaster_ != address(0), "AIZ");
        poolMaster = poolMaster_;
    }

    /**
     * @notice Function is called by contract owner to set new InterestRateModel
     * @param interestRateModel_ Address of the new InterestRateModel contract
     */
    function setInterestRateModel(address interestRateModel_)
        external
        onlyOwner
    {
        require(interestRateModel_ != address(0), "AIZ");
        interestRateModel = interestRateModel_;
    }

    /**
     * @notice Function is called by contract owner to set new treasury
     * @param treasury_ Address of the new treasury
     */
    function setTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0), "AIZ");
        treasury = treasury_;
    }

    /**
     * @notice Function is called by contract owner to set new reserve factor
     * @param reserveFactor_ New reserve factor as 10-digit decimal
     */
    function setReserveFactor(uint256 reserveFactor_) external onlyOwner {
        require(reserveFactor_ <= Decimal.ONE, "GTO");
        reserveFactor = reserveFactor_;
    }

    /**
     * @notice Function is called by contract owner to set new insurance factor
     * @param insuranceFactor_ New reserve factor as 10-digit decimal
     */
    function setInsuranceFactor(uint256 insuranceFactor_) external onlyOwner {
        require(insuranceFactor_ <= Decimal.ONE, "GTO");
        insuranceFactor = insuranceFactor_;
    }

    /**
     * @notice Function is called by contract owner to set new warning utilization
     * @param warningUtilization_ New warning utilization as 10-digit decimal
     */
    function setWarningUtilization(uint256 warningUtilization_)
        external
        onlyOwner
    {
        require(warningUtilization_ <= Decimal.ONE, "GTO");
        warningUtilization = warningUtilization_;
    }

    /**
     * @notice Function is called by contract owner to set new warning grace period
     * @param warningGracePeriod_ New warning grace period in seconds
     */
    function setWarningGracePeriod(uint256 warningGracePeriod_)
        external
        onlyOwner
    {
        warningGracePeriod = warningGracePeriod_;
    }

    /**
     * @notice Function is called by contract owner to set new max inactive period
     * @param maxInactivePeriod_ New max inactive period in seconds
     */
    function setMaxInactivePeriod(uint256 maxInactivePeriod_)
        external
        onlyOwner
    {
        maxInactivePeriod = maxInactivePeriod_;
    }

    /**
     * @notice Function is called by contract owner to set new auction duration
     * @param auctionDuration_ New auction duration
     */
    function setAuctionDuration(uint256 auctionDuration_) external onlyOwner {
        auctionDuration = auctionDuration_;
    }

    /**
     * @notice Function is called by contract owner to set new CPOOl reward per block speed in some pool
     * @param pool Pool where to set reward
     * @param rewardPerBlock Reward per block value
     */
    function setPoolRewardPerBlock(address pool, uint256 rewardPerBlock)
        external
        onlyOwner
    {
        IPoolMaster(pool).setRewardPerBlock(rewardPerBlock);
    }

    /**
     * @notice Function is called through pool at closing to unlock manager's stake
     */
    function closePool() external {
        address manager = getPoolManager(msg.sender);
        PoolInfo storage info = poolInfo[manager];

        emit PoolClosed(msg.sender, manager, info.currency);
        info.currency = address(0);
        info.pool = address(0);
        staking.unlockStake(info.staker, info.stakedAmount);
    }

    function transferStake(address receiver) external {
        PoolInfo storage info = poolInfo[getPoolManager(msg.sender)];
        staking.transferStake(info.staker, info.stakedAmount, receiver);
        info.staker = address(0);
        info.stakedAmount = 0;
    }

    /**
     * @notice Function is used to withdraw CPOOL rewards from multiple pools
     * @param pools List of pools to withdrawm from
     */
    function withdrawReward(address[] memory pools) external {
        uint256 totalReward;
        for (uint256 i = 0; i < pools.length; i++) {
            require(isPool(pools[i]), "NPA");
            totalReward += IPoolMaster(pools[i]).withdrawReward(msg.sender);
        }

        if (totalReward > 0) {
            cpool.transfer(msg.sender, totalReward);
        }
    }

    // VIEW FUNCTIONS

    /**
     * @notice Function returns symbol for new pool based on currency and manager
     * @param currency Pool's currency address
     * @param manager Manager's address
     * @return Pool symbol
     */
    function getPoolSymbol(address currency, address manager)
        external
        view
        returns (string memory)
    {
        return
            string(
                bytes.concat(
                    bytes("cp"),
                    bytes(poolInfo[manager].managerSymbol),
                    bytes("-"),
                    bytes(IERC20MetadataUpgradeable(currency).symbol())
                )
            );
    }

    /**
     * @notice Function checks if some address is actual pool
     * @return True if address is pool, false otherwise
     */
    function isPool(address pool) public view returns (bool) {
        address manager = IPoolMaster(pool).manager();
        return pool == poolInfo[manager].pool;
    }

    function getPoolManager(address pool)
        internal
        view
        returns (address manager)
    {
        manager = IPoolMaster(pool).manager();
        require(msg.sender == poolInfo[manager].pool, "SNP");
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Internal function that proposes pool
     * @param currency Currency of the pool
     */
    function _proposePool(address currency) private {
        require(currencyAllowed[currency], "CNA");
        PoolInfo storage info = poolInfo[msg.sender];
        require(info.currency == address(0), "AHP");

        info.proposalId = flashGovernor.propose();
        info.currency = currency;
        info.staker = msg.sender;
        info.stakedAmount = staking.lockStake(msg.sender);

        emit PoolProposed(msg.sender, currency);
    }

    /**
     * @notice Internal function that immedeately creates pool
     * @param manager Manager of the pool
     * @param currency Currency of the pool
     */
    function _forceCreatePool(address manager, address currency) private {
        require(currencyAllowed[currency], "CNA");
        PoolInfo storage info = poolInfo[manager];
        require(info.currency == address(0), "AHP");

        IPoolMaster pool = IPoolMaster(poolMaster.clone());
        pool.initialize(manager, currency);

        info.pool = address(pool);
        info.currency = currency;
        info.staker = msg.sender;
        info.stakedAmount = staking.lockStake(msg.sender);

        emit PoolCreated(address(pool), manager, currency);
    }

    /**
     * @notice Internal function that sets manager's info
     * @param manager Manager to set info for
     * @param info Manager's info IPFS hash
     * @param symbol Manager's symbol
     */
    function _setManager(
        address manager,
        bytes32 info,
        string memory symbol
    ) private {
        require(poolInfo[manager].managerInfo == bytes32(0), "AHI");
        require(info != bytes32(0), "CEI");
        require(!usedManagerSymbols[symbol], "SAU");

        poolInfo[manager].managerInfo = info;
        poolInfo[manager].managerSymbol = symbol;
        usedManagerSymbols[symbol] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoolMaster {
    function manager() external view returns (address);

    function currency() external view returns (address);

    function borrows() external view returns (uint256);

    function getBorrowRate() external view returns (uint256);

    function getSupplyRate() external view returns (uint256);

    function getInterest() external view returns (uint256);

    enum State {
        Active,
        Warning,
        Default,
        Closed
    }

    function state() external view returns (State);

    function initialize(address manager_, address currency_) external;

    function setRewardPerBlock(uint256 rewardPerBlock_) external;

    function withdrawReward(address account) external returns (uint256);

    function transferReserves() external;

    function processDebtClaim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFlashGovernor {
    function proposalEndBlock(uint256 proposalId)
        external
        view
        returns (uint256);

    function propose() external returns (uint256);

    function execute(uint256 proposalId) external;

    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Executed
    }

    function state(uint256 proposalId) external view returns (ProposalState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMembershipStaking {
    function getManagerSymbol(address account)
        external
        view
        returns (string memory);

    function managerMinimalStake() external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);

    function lockStake(address account) external returns (uint256);

    function unlockStake(address account, uint256 amount) external;

    function transferStake(
        address account,
        uint256 amount,
        address receiver
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Decimal {
    /// @notice Number one as 10-digit decimal
    uint256 internal constant ONE = 10_000_000_000;

    /**
     * @notice Internal function for 10-digits decimal division
     * @param number Integer number
     * @param decimal Decimal number
     * @return Returns multiplied numbers
     */
    function mulDecimal(uint256 number, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        return (number * decimal) / ONE;
    }

    /**
     * @notice Internal function for 10-digits decimal multiplication
     * @param number Integer number
     * @param decimal Decimal number
     * @return Returns integer number divided by second
     */
    function divDecimal(uint256 number, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        return (number * ONE) / decimal;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}