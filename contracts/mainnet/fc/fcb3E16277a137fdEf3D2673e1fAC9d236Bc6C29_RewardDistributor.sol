pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Ferrum Staking interface for adding reward
 */
interface IFestakeRewardManager {
    /**
     * @dev legacy add reward. To be used by contract support time limitted rewards.
     */
    function addReward(uint256 rewardAmount) external returns (bool);

    /**
     * @dev withdraw rewards for the user.
     * The only option is to withdraw all rewards is one go.
     */
    function withdrawRewards() external returns (uint256);

    /**
     * @dev marginal rewards is to be used by contracts supporting ongoing rewards.
     * Send the reward to the contract address first.
     */
    function addMarginalReward() external returns (bool);

    function rewardToken() external view returns (IERC20);

    function rewardsTotal() external view returns (uint256);

    /**
     * @dev returns current rewards for an address
     */
    function rewardOf(address addr) external view returns (uint256);
}

pragma solidity >=0.6.0 <0.8.0;

import "./IFestakeRewardManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRewardDistributor {
    function rollAndGetDistributionAddress(address addressForRandom) external view returns(address);
    function updateRewards(address target) external returns(bool);
}

contract RewardDistributor is Ownable, IRewardDistributor {
    struct RewardPools {
        bytes pools;
    }
    RewardPools rewardPools;
    address[] rewardReceivers;

    function addNewPool(address pool)
    onlyOwner()
    external returns(bool) {
        require(pool != address(0), "RewardD: Zero address");
        require(rewardReceivers.length < 30, "RewardD: Max no of pools reached");
        IFestakeRewardManager manager = IFestakeRewardManager(pool);
        require(address(manager.rewardToken()) != address(0), "RewardD: No reward address was provided");
        rewardReceivers.push(pool);
        IFestakeRewardManager firstManager = IFestakeRewardManager(rewardReceivers[0]);
        require(firstManager.rewardToken() == manager.rewardToken(),
            "RewardD: Reward token inconsistent with current pools");
        return true;
    }

    /**
     * poolRatio is used for a gas efficient round-robbin distribution of rewards.
     * Pack a number of uint8s in poolRatios. Maximum number of pools is 14.
     * Sum of ratios must add to 100.
     */
    function updateRewardDistributionForPools(bytes calldata poolRatios)
    onlyOwner()
    external returns (bool) {
        uint sum = 0;
        uint len = rewardReceivers.length;
        for (uint i = 0; i < len; i++) {
            sum = toUint8(poolRatios, i) + sum;
        }
        require(sum == 100, "ReardD: ratios must add to 100");
        rewardPools.pools = poolRatios;
        return true;
    }

    /**
     * @dev be carefull. Randomly chooses a pool using round robbin.
     * Assuming the transaction sizes are randomly distributed, each pool gets
     * the right share of rewards in aggregate.
     * Sacrificing accuracy for reduction in gas for each transaction.
     */
    function rollAndGetDistributionAddress(address addressForRandom)
    external override view returns(address) {
        require(addressForRandom != address(0) , "RewardD: address cannot be 0");
        uint256 rand = block.timestamp * (block.difficulty == 0 ? 1 : block.difficulty) *
             (uint256(addressForRandom) >> 128) * 31 % 100;
        uint sum = 0;
        bytes memory poolRatios = rewardPools.pools;
        uint256 len = rewardReceivers.length;
        for (uint i = 0; i < len && i < poolRatios.length; i++) {
            uint poolRatio = toUint8(poolRatios, i);
            sum += poolRatio;
            if (sum >= rand && poolRatio != 0 ) {
                return rewardReceivers[i];
            }
        }
        return address(0);
    }

    function updateRewards(address target) external override returns(bool) {
        IFestakeRewardManager manager = IFestakeRewardManager(target);
        return manager.addMarginalReward();
    }

    function bytes32ToBytes(bytes32 _bytes32) private pure returns (bytes memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return bytesArray;
    }

    function toByte32(bytes memory _bytes)
    private pure returns (bytes32) {
        bytes32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), 0))
        }

        return tempUint;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
    private pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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