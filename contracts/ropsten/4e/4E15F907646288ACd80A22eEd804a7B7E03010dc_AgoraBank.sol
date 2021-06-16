// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./token/IAgoraToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title The central contract of agora.space, keeping track of the community member limits and distributing rewards.
contract AgoraBank is Ownable {
    uint256 public rewardPerBlock = 100000000000000000; // 0.1 AGO by default
    uint256 public lockInterval = 586868; // by default around 90 days with 13.25s block time
    uint256 public totalStakes;

    struct StakeItem {
        uint256 amount;
        uint128 lockExpires;
        uint128 countRewardsFrom;
    }
    mapping(uint256 => mapping(address => StakeItem)) public stakes; // communityId -> user -> stake

    event Deposit(uint256 indexed communityId, address indexed wallet, uint256 amount);
    event Withdraw(uint256 indexed communityId, address indexed wallet, uint256 amount);
    event RewardClaimed(uint256[] communityIds, address indexed wallet);
    event RewardChanged(uint256 newRewardPerBlock);

    /// @notice Stakes AGO token and registers it.
    function deposit(uint256 _communityId, uint256 _amount) external {
        // Claim rewards in the community
        uint256[] memory communityArray = new uint256[](1);
        communityArray[0] = _communityId;
        claimReward(communityArray);
        // Register the stake details
        stakes[_communityId][msg.sender].amount += _amount;
        stakes[_communityId][msg.sender].lockExpires = uint128(block.number + lockInterval);
        totalStakes += _amount;
        // Actually get the tokens
        IAgoraToken(agoAddress()).transferFrom(msg.sender, address(this), _amount);
        emit Deposit(_communityId, msg.sender, _amount);
    }

    /// @notice Withdraws a certain amount of staked tokens if the timelock expired.
    function withdraw(uint256 _communityId, uint256 _amount) external {
        StakeItem storage stakeData = stakes[_communityId][msg.sender];
        // Test timelock
        require(stakeData.lockExpires < block.number, "Stake still locked");
        // Claim rewards in the community
        uint256[] memory communityArray = new uint256[](1);
        communityArray[0] = _communityId;
        claimReward(communityArray);
        // Modify tne stake details
        stakeData.amount -= _amount; // Will revert if the user tries to withdraw more than staked
        totalStakes -= _amount;
        // // Actually send the withdraw amount
        IAgoraToken(agoAddress()).transfer(msg.sender, _amount);
        emit Withdraw(_communityId, msg.sender, _amount);
    }

    /// @notice Mints the reward for the sender based on the stakes in an array of communities.
    /// @dev The rewards will be calculated from the current block in these communities on the next call.
    function claimReward(uint256[] memory _communityIds) public {
        uint256 userStakes;
        uint256 elapsedBlocks;
        for (uint256 i = 0; i < _communityIds.length; i++) {
            uint256 stakeInCommunity = stakes[_communityIds[i]][msg.sender].amount;
            if (stakeInCommunity > 0) {
                userStakes += stakeInCommunity;
                elapsedBlocks += block.number - stakes[_communityIds[i]][msg.sender].countRewardsFrom;
            }
            stakes[_communityIds[i]][msg.sender].countRewardsFrom = uint128(block.number);
        }
        if (userStakes > 0)
            IAgoraToken(agoAddress()).mint(msg.sender, (elapsedBlocks * rewardPerBlock * userStakes) / totalStakes);
        emit RewardClaimed(_communityIds, msg.sender);
    }

    /// @notice Changes the amount of AGO to be minted per block as a reward.
    function changeRewardPerBlock(uint256 _rewardAmount) external onlyOwner {
        rewardPerBlock = _rewardAmount;
        emit RewardChanged(_rewardAmount);
    }

    /// @notice Changes the number of blocks the stakes will be locked for.
    function changeTimelockInterval(uint256 _blocks) external onlyOwner {
        lockInterval = _blocks;
    }

    /// @notice Calculates the reward for the sender based on the stakes in an array of communities.
    /// @dev The same logic as in claimReward.
    function getReward(uint256[] calldata _communityIds) external view returns (uint256) {
        uint256 userStakes;
        uint256 elapsedBlocks;
        for (uint256 i = 0; i < _communityIds.length; i++) {
            uint256 stakeInCommunity = stakes[_communityIds[i]][msg.sender].amount;
            if (stakeInCommunity > 0) {
                userStakes += stakeInCommunity;
                elapsedBlocks += block.number - stakes[_communityIds[i]][msg.sender].countRewardsFrom;
            }
        }
        return (elapsedBlocks * rewardPerBlock * userStakes) / totalStakes;
    }

    /// @notice The address of the token minted for staking.
    /// @dev Change before deploying. Also, this contract has to be able to mint it.
    function agoAddress() public pure returns (address) {
        return 0x02c2545aa78d0FA4f3099331F64761F9c730f071;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAgoraToken is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

{
  "metadata": {
    "useLiteralContent": true
  },
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