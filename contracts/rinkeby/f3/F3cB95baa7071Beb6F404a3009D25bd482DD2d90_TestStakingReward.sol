// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./OwnableTokenAccessControl.sol";
import "./IStakingReward.sol";
import "./IERC20Mint.sol";

contract TestStakingReward is OwnableTokenAccessControl, IStakingReward {
    // TODO replace with constants in final contract
    address private STAKING_ADDRESS;
    address private TOKEN_ADDRESS;
    mapping(address => uint256) private _claims;

    uint256 public constant stakingRewardRate = 10 ether / uint256(1 days);
    uint256 public stakingRewardEndTimestamp = 1736152962; // TODO update in final contract


    /// @dev Emitted when `account` claims `amount` of reward.
    event Claim(address indexed account, uint256 indexed amount);


    constructor(address stakingContractAddress, address tokenContractAddress) {
        STAKING_ADDRESS = stakingContractAddress;
        TOKEN_ADDRESS = tokenContractAddress;
    }

    function setStakingRewardEndTimestamp(uint256 timestamp) external onlyOwner {
        require(stakingRewardEndTimestamp > block.timestamp, "Staking has already ended");
        require(timestamp > block.timestamp, "Must be a time in the future");

        stakingRewardEndTimestamp = timestamp;
    }


    modifier onlyStaking() {
        require(STAKING_ADDRESS == _msgSender(), "Not allowed");
        _;
    }

    function didStakeTokens(address account, uint16[] calldata tokenIds) external override onlyStaking {
        uint256 timestamp = block.timestamp;

        uint256 claim = _claims[account];
        uint256 unclaimedBalance = claim >> 48;
        uint256 stakedCount = claim & 0x3fff;
        if (stakedCount > 0) {
            unchecked {
                uint256 lastClaimTimestamp = (claim >> 14) & 0x3ffffffff;
                unclaimedBalance += _reward(lastClaimTimestamp, timestamp) * stakedCount;
            }
        }

        unchecked {
            _claims[account] = (unclaimedBalance << 48) | (timestamp << 14) | (stakedCount + tokenIds.length);
        }
    }

    function willUnstakeTokens(address account, uint16[] calldata tokenIds) external override onlyStaking {
        uint256 timestamp = block.timestamp;

        uint256 claim = _claims[account];
        uint256 unclaimedBalance = claim >> 48;
        uint256 stakedCount = claim & 0x3fff;
        if (stakedCount > 0) {
            unchecked {
                uint256 lastClaimTimestamp = (claim >> 14) & 0x3ffffffff;
                unclaimedBalance += _reward(lastClaimTimestamp, timestamp) * stakedCount;
            }
        }

        uint256 unstakeCount = tokenIds.length;
        if (unstakeCount < stakedCount) {
            unchecked {
                stakedCount -= unstakeCount;
            }
        }
        else {
            stakedCount = 0;
            if (unclaimedBalance == 0) {
                timestamp = 0; // set to 0 to clean up storage slot after all tokens have been unstaked
            }
        }

        unchecked {
            _claims[account] = (unclaimedBalance << 48) | (timestamp << 14) | stakedCount;
        }
    }

    function willBeReplacedByContract(address /*stakingRewardContract*/) external override onlyStaking {
        uint256 timestamp = block.timestamp;

        if (stakingRewardEndTimestamp > timestamp) {
            stakingRewardEndTimestamp = timestamp;
        }
    }

    function didReplaceContract(address stakingRewardContract) external override onlyStaking {

    }


    function _duration(uint256 timestampFrom, uint256 timestampTo) internal view returns (uint256) {
        if (timestampTo > stakingRewardEndTimestamp) {
            timestampTo = stakingRewardEndTimestamp;
        }
        if (timestampFrom > timestampTo) {
            return 0;
        }
        unchecked {
            return timestampTo - timestampFrom;
        }
    }

    function _reward(uint256 timestampFrom, uint256 timestampTo) internal view returns (uint256) {
        unchecked {
            return _duration(timestampFrom, timestampTo) * stakingRewardRate;
        }
    }

    function reward(uint256 timestampFrom, uint256 timestampTo) public view returns (uint256) {
        require(timestampTo > timestampFrom, "Invalid time");
        return _reward(timestampFrom, timestampTo);
    }

    function timestampUntilReward(uint256 targetRewardAmount, uint256 stakedCount, uint256 timestampFrom) public view returns (uint256) {
        uint256 totalTimeUnits = targetRewardAmount / stakingRewardRate;
        uint256 duration = totalTimeUnits / stakedCount;
        if (duration == 0) {
            duration = 1;
        }
        uint256 timestampTo = timestampFrom + duration;
        require(timestampTo <= stakingRewardEndTimestamp, "Cannot get reward amount before staking ends");
        return timestampTo;
    }


    function stakedTokensBalanceOf(address account) external view returns (uint256 stakedCount) {
        stakedCount = _claims[account] & 0x3fff;
    }

    function lastClaimTimestampOf(address account) external view returns (uint256 lastClaimTimestamp) {
        lastClaimTimestamp = (_claims[account] >> 14) & 0x3ffffffff;
    }

    function rawClaimDataOf(address account) external view returns (uint256) {
        return _claims[account];
    }


    function _claim(address account, uint256 amount) private {
        if (amount == 0) {
            return;
        }

        uint256 timestamp = block.timestamp;

        uint256 claim = _claims[account];
        uint256 unclaimedBalance = claim >> 48;
        uint256 stakedCount = claim & 0x3fff;
        if (stakedCount > 0) {
            unchecked {
                uint256 lastClaimTimestamp = (claim >> 14) & 0x3ffffffff;
                unclaimedBalance += _reward(lastClaimTimestamp, timestamp) * stakedCount;
            }
        }
        else {
            timestamp = 0; // set to 0 to clean up storage slot after all tokens have been unstaked
        }

        unchecked {
            require(unclaimedBalance >= amount, "Not enough rewards to claim");
            _claims[account] = ((unclaimedBalance - amount) << 48) | (timestamp << 14) | stakedCount;
            emit Claim(account, amount);
        }
    }


    function _transfer(address account, address to, uint256 amount) internal {
        _claim(account, amount);
        IERC20Mint(TOKEN_ADDRESS).mint(to, amount);
    }

    function claimRewardsAmount(uint256 amount) external {  
        address account = _msgSender();
        _transfer(account, account, amount);
    }

    function claimRewards() external {
        address account = _msgSender();

        uint256 timestamp = block.timestamp;

        uint256 claim = _claims[account];
        uint256 unclaimedBalance = claim >> 48;
        uint256 stakedCount = claim & 0x3fff;
        if (stakedCount > 0) {
            unchecked {
                uint256 lastClaimTimestamp = (claim >> 14) & 0x3ffffffff;
                unclaimedBalance += _reward(lastClaimTimestamp, timestamp) * stakedCount;
            }
        }
        else {
            timestamp = 0; // set to 0 to clean up storage slot after all tokens have been unstaked
        }

        require(unclaimedBalance > 0, "Nothing to claim");

        _claims[account] = (timestamp << 14) | stakedCount;
        emit Claim(account, unclaimedBalance);
        IERC20Mint(TOKEN_ADDRESS).mint(account, unclaimedBalance);
    }

    // ERC20 compatible functions

    function balanceOf(address account) public view returns (uint256) {
        uint256 claim = _claims[account];
        uint256 unclaimedBalance = claim >> 48;
        uint256 stakedCount = claim & 0x3fff;
        if (stakedCount > 0) {
            unchecked {
                uint256 lastClaimTimestamp = (claim >> 14) & 0x3ffffffff;
                unclaimedBalance += _reward(lastClaimTimestamp, block.timestamp) * stakedCount;
            }
        }

        return unclaimedBalance;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address account, address to, uint256 amount) public returns (bool) {
        require(_msgSender() == account || _hasAccess(Access.Transfer, _msgSender()), "Not Allowed");
        _transfer(account, to, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) public {
        require(_hasAccess(Access.Burn, _msgSender()), "Not Allowed");
        _claim(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title OwnableTokenAccessControl
/// @notice Basic access control for utility tokens 
/// @author ponky
contract OwnableTokenAccessControl is Ownable {
    /// @dev Keeps track of how many accounts have been granted each type of access
    uint96 private _accessCounts;

    mapping (address => uint256) private _accessFlags;

    /// @dev Access types
    enum Access { Mint, Burn, Transfer }

    /// @dev Emitted when `account` is granted `access`.
    event AccessGranted(bytes32 indexed access, address indexed account);

    /// @dev Emitted when `account` is revoked `access`.
    event AccessRevoked(bytes32 indexed access, address indexed account);

    /// @dev Helper constants for fitting each access index into _accessCounts
    uint constant private _AC_BASE          = 4;
    uint constant private _AC_MASK_BITSIZE  = 1 << _AC_BASE;
    uint constant private _AC_MASK          = (1 << _AC_MASK_BITSIZE) - 1;

    /// @dev Convert the string `access` to an uint
    function _accessToIndex(bytes32 access) internal pure virtual returns (uint index) {
        if (access == 'MINT')       {return uint(Access.Mint);}
        if (access == 'BURN')       {return uint(Access.Burn);}
        if (access == 'TRANSFER')   {return uint(Access.Transfer);}
        revert("Invalid Access");
    }

    function _hasAccess(Access access, address account) internal view returns (bool) {
        return (_accessFlags[account] & (1 << uint(access))) != 0;
    }

    function hasAccess(bytes32 access, address account) public view returns (bool) {
        uint flag = 1 << _accessToIndex(access);        
        return (_accessFlags[account] & flag) != 0;
    }

    function grantAccess(bytes32 access, address account) external onlyOwner {
        //require(isContract(account), "Can only grant access to a contract");

        uint index = _accessToIndex(access);
        uint256 flags = _accessFlags[account];
        uint256 newFlags = flags | (1 << index);
        require(flags != newFlags, "Account already has access");
        _accessFlags[account] = newFlags;

        uint shift = index << _AC_BASE;
        uint accessCount = (_accessCounts >> shift) & _AC_MASK;
        unchecked {
            require(accessCount < (_AC_MASK-1), "Access disabled or limit reached");
            _accessCounts += uint96(1 << shift);
        }

        emit AccessGranted(access, account);
    }

    function revokeAccess(bytes32 access, address account) external onlyOwner {
        uint index = _accessToIndex(access);
        uint256 flags = _accessFlags[account];
        uint newFlags = flags & ~(1 << index);
        require(flags != newFlags, "Account does not have access");
        _accessFlags[account] = newFlags;

        uint shift = index << _AC_BASE;
        unchecked {
            _accessCounts -= uint96(1 << shift);
        }

        emit AccessRevoked(access, account);
    }

    /// @dev Returns the number of accounts that have been granted `access`.
    function countOfAccess(bytes32 access) external view returns (uint) {
        uint index = _accessToIndex(access);

        uint shift = index << _AC_BASE;
        uint accessCount = (_accessCounts >> shift) & _AC_MASK;
        if (accessCount == _AC_MASK) {
            // access has been disabled
            accessCount = 0;
        }
        return accessCount;
    }

    function permanentlyDisableGrantingAccess(bytes32 access) external onlyOwner {
        uint index = _accessToIndex(access);
        
        uint shift = index << _AC_BASE;
        uint mask = _AC_MASK << shift;
        uint accessCount = _accessCounts & mask;
        require(accessCount != mask, "Granting access has already been disabled");
        require(accessCount == 0, "Revoke access from contracts first");
        _accessCounts |= uint96(mask);
    }

    function _permanentlyDisableGrantingAllAccess() internal {
        uint256 accessCounts = _accessCounts;
        uint shift = 0;
        do {
            uint mask = _AC_MASK << shift;
            uint accessCount = accessCounts & mask;
            require(accessCount == mask || accessCount == 0, "Revoke access from contracts first");
            unchecked {
                shift += _AC_MASK_BITSIZE;
            }
        } while (shift < 96);
        _accessCounts = type(uint96).max;
    }

    function renounceOwnership() public override onlyOwner {
        _permanentlyDisableGrantingAllAccess();

        _transferOwnership(address(0));
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IStakingReward {
    function didStakeTokens(address account, uint16[] calldata tokenIds) external;
    function willUnstakeTokens(address account, uint16[] calldata tokenIds) external;

    function willBeReplacedByContract(address stakingRewardContract) external;
    function didReplaceContract(address stakingRewardContract) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IERC20Mint is IERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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