// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IStaking.sol";

contract YieldFarm {
    struct TokenDetails {
        address addr;
        uint8 decimals;
    }

    TokenDetails[] public poolTokens;
    uint8 maxDecimals;

    IERC20 public rewardToken;

    address public communityVault;
    IStaking public staking;

    uint256 public totalDistributedAmount;
    uint256 public numberOfEpochs;
    uint128 public epochsDelayedFromStakingContract;

    uint256 public _totalAmountPerEpoch;
    uint128 public lastInitializedEpoch;

    uint256[] public epochPoolSizeCache;
    mapping(address => uint128) public lastEpochIdHarvested;

    uint256 public epochDuration; // init from staking contract
    uint256 public epochStart; // init from staking contract

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);

    // constructor
    constructor(
        address[] memory poolTokenAddresses,
        address rewardTokenAddress,
        address stakingAddress,
        address communityVaultAddress,
        uint256 distributedAmount,
        uint256 noOfEpochs,
        uint128 epochsDelayed
    ) {
        for (uint256 i = 0; i < poolTokenAddresses.length; i++) {
            address addr = poolTokenAddresses[i];
            require(addr != address(0), "invalid pool token address");

            uint8 decimals = IERC20Metadata(addr).decimals();
            poolTokens.push(TokenDetails(addr, decimals));

            if (maxDecimals < decimals) {
                maxDecimals = decimals;
            }
        }

        rewardToken = IERC20(rewardTokenAddress);

        staking = IStaking(stakingAddress);
        communityVault = communityVaultAddress;

        totalDistributedAmount = distributedAmount;
        numberOfEpochs = noOfEpochs;
        epochPoolSizeCache = new uint256[](numberOfEpochs + 1);
        epochsDelayedFromStakingContract = epochsDelayed;

        epochDuration = staking.epochDuration();
        epochStart = staking.epoch1Start() + epochDuration * epochsDelayedFromStakingContract;

        _totalAmountPerEpoch = totalDistributedAmount / numberOfEpochs;
    }

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external returns (uint256){
        uint256 totalUserReward;
        uint256 epochId = _getEpochId() - 1;
        // fails in epoch 0
        // force max number of epochs
        if (epochId > numberOfEpochs) {
            epochId = numberOfEpochs;
        }

        uint128 userLastEpochHarvested = lastEpochIdHarvested[msg.sender];

        for (uint128 i = userLastEpochHarvested + 1; i <= epochId; i++) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalUserReward += _harvest(i);
        }

        emit MassHarvest(msg.sender, epochId - userLastEpochHarvested, totalUserReward);

        if (totalUserReward > 0) {
            rewardToken.transferFrom(communityVault, msg.sender, totalUserReward);
        }

        return totalUserReward;
    }

    function harvest(uint128 epochId) external returns (uint256){
        // checks for requested epoch
        require(_getEpochId() > epochId, "This epoch is in the future");
        require(epochId <= numberOfEpochs, "Maximum number of epochs is 25");
        require(lastEpochIdHarvested[msg.sender] + 1 == epochId, "Harvest in order");

        uint256 userReward = _harvest(epochId);
        if (userReward > 0) {
            rewardToken.transferFrom(communityVault, msg.sender, userReward);
        }

        emit Harvest(msg.sender, epochId, userReward);

        return userReward;
    }

    // views
    // calls to the staking smart contract to retrieve the epoch total pool size
    function getPoolSize(uint128 epochId) external view returns (uint256) {
        return _getPoolSize(epochId);
    }

    function getPoolSizeByToken(address token, uint128 epochId) external view returns (uint256) {
        uint128 stakingEpochId = _stakingEpochId(epochId);

        return staking.getEpochPoolSize(token, stakingEpochId);
    }

    function getCurrentEpoch() external view returns (uint256) {
        return _getEpochId();
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId) external view returns (uint256) {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function getEpochStakeByToken(address userAddress, address token, uint128 epochId) external view returns (uint256) {
        uint128 stakingEpochId = _stakingEpochId(epochId);

        return staking.getEpochUserBalance(userAddress, token, stakingEpochId);
    }

    function userLastEpochIdHarvested() external view returns (uint256){
        return lastEpochIdHarvested[msg.sender];
    }

    function getPoolTokens() external view returns (address[] memory tokens) {
        tokens = new address[](poolTokens.length);

        for (uint256 i = 0; i < poolTokens.length; i++) {
            tokens[i] = poolTokens[i].addr;
        }
    }

    // internal methods

    function _initEpoch(uint128 epochId) internal {
        require(lastInitializedEpoch + 1 == epochId, "Epoch can be init only in order");

        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch
        epochPoolSizeCache[epochId] = _getPoolSize(epochId);
    }

    function _harvest(uint128 epochId) internal returns (uint256) {
        // try to initialize an epoch. if it can't it fails
        // if it fails either user either a BarnBridge account will init not init epochs
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user last harvested epoch
        lastEpochIdHarvested[msg.sender] = epochId;
        // compute and return user total reward. For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)

        // exit if there is no stake on the epoch
        if (epochPoolSizeCache[epochId] == 0) {
            return 0;
        }

        return _totalAmountPerEpoch * _getUserBalancePerEpoch(msg.sender, epochId) / epochPoolSizeCache[epochId];
    }

    function _getPoolSize(uint128 epochId) internal view returns (uint256) {
        uint128 stakingEpochId = _stakingEpochId(epochId);

        uint256 totalPoolSize;

        for (uint256 i = 0; i < poolTokens.length; i++) {
            totalPoolSize = totalPoolSize + staking.getEpochPoolSize(poolTokens[i].addr, stakingEpochId) * 10 ** (maxDecimals - poolTokens[i].decimals);
        }

        return totalPoolSize;
    }


    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint256){
        uint128 stakingEpochId = _stakingEpochId(epochId);

        uint256 totalUserBalance;

        for (uint256 i = 0; i < poolTokens.length; i++) {
            totalUserBalance = totalUserBalance + staking.getEpochUserBalance(userAddress, poolTokens[i].addr, stakingEpochId) * 10 ** (maxDecimals - poolTokens[i].decimals);
        }

        return totalUserBalance;
    }

    // compute epoch id from block.timestamp and epochStart date
    function _getEpochId() internal view returns (uint128) {
        if (block.timestamp < epochStart) {
            return 0;
        }

        return uint128(
            (block.timestamp - epochStart) / epochDuration + 1
        );
    }

    // get the staking epoch
    function _stakingEpochId(uint128 epochId) internal view returns (uint128) {
        return epochId + epochsDelayedFromStakingContract;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IStaking {
    function getEpochId(uint256 timestamp) external view returns (uint256); // get epoch id
    function getEpochUserBalance(address user, address token, uint128 epoch) external view returns(uint256);
    function getEpochPoolSize(address token, uint128 epoch) external view returns (uint256);
    function epoch1Start() external view returns (uint256);
    function epochDuration() external view returns (uint256);
}