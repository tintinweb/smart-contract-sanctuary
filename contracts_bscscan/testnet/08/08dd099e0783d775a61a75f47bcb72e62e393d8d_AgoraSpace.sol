// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./token/IAgoraToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A contract for staking tokens
contract AgoraSpace is Ownable {
    // Tokens managed by the contract
    address public immutable token;
    address public immutable stakeToken;

    // For emergencies
    bool public frozen;

    // For timelock
    mapping(address => LockedItem[]) internal timelocks;

    struct LockedItem {
        uint256 expires;
        uint256 amount;
        uint256 rankId;
    }

    // For ranking
    uint256 public numOfRanks;

    struct Rank {
        uint256 minDuration;
        uint256 goalAmount;
    }

    // For storing balances
    struct Balance {
        uint256 locked;
        uint256 unlocked;
    }

    // Bigger id equals higher rank
    mapping(uint256 => Rank) public ranks;

    mapping(uint256 => mapping(address => Balance)) public rankBalances;

    event Deposit(address indexed wallet, uint256 amount);
    event Withdraw(address indexed wallet, uint256 amount);
    event NewRank(uint256 minDuration, uint256 goalAmount, uint256 id);
    event ModifyRank(uint256 minDuration, uint256 goalAmount, uint256 id);
    event SpaceFrozenState(bool frozen);
    event EmergencyWithdraw(address indexed wallet, uint256 amount);

    error InsufficientBalance(uint256 rankId, uint256 available, uint256 required);
    error TooManyRanks();
    error NoRanks();
    error InvalidRank();
    error NewDurationTooShort(uint256 value, uint256 minValue);
    error NewDurationTooLong(uint256 value, uint256 maxValue);
    error NewGoalTooSmall(uint256 value, uint256 minValue);
    error NewGoalTooBig(uint256 value, uint256 maxValue);
    error TooManyDeposits();
    error NonPositiveAmount();
    error SpaceIsFrozen();
    error SpaceIsNotFrozen();

    modifier notFrozen() {
        if (frozen) revert SpaceIsFrozen();
        _;
    }

    /// @param _tokenAddress The address of the token to be staked, that the contract accepts
    /// @param _stakeTokenAddress The address of the token that's given in return
    constructor(address _tokenAddress, address _stakeTokenAddress) {
        token = _tokenAddress;
        stakeToken = _stakeTokenAddress;
    }

    /// @notice Creates a new rank
    /// @dev Only the new highest rank can be added
    /// @dev The goal amount and the lock time can't be lower than in the previous rank
    /// @param _minDuration The duration of the lock
    /// @param _goalAmount The amount of tokens needed to reach the rank
    function addRank(uint256 _minDuration, uint256 _goalAmount) external onlyOwner {
        if (numOfRanks >= 255) revert TooManyRanks();
        if (numOfRanks >= 1) {
            if (ranks[numOfRanks - 1].goalAmount > _goalAmount)
                revert NewGoalTooSmall({value: _goalAmount, minValue: ranks[numOfRanks - 1].goalAmount});
            if (ranks[numOfRanks - 1].minDuration > _minDuration)
                revert NewDurationTooShort({value: _minDuration, minValue: ranks[numOfRanks - 1].minDuration});
        }
        ranks[numOfRanks] = (Rank(_minDuration, _goalAmount));
        emit NewRank(_minDuration, _goalAmount, numOfRanks);
        numOfRanks++;
    }

    /// @notice Modifies a rank
    /// @dev Values must be between the previous and the next ranks'
    /// @param _minDuration New duration of the lock
    /// @param _goalAmount New amount of tokens needed to reach the rank
    /// @param _id The id of the rank to be modified
    function modifyRank(
        uint256 _minDuration,
        uint256 _goalAmount,
        uint256 _id
    ) external onlyOwner {
        if (numOfRanks < 1) revert NoRanks();
        if (_id >= numOfRanks) revert InvalidRank();
        if (_id > 0) {
            if (ranks[_id - 1].goalAmount > _goalAmount)
                revert NewGoalTooSmall({value: _goalAmount, minValue: ranks[numOfRanks - 1].goalAmount});
            if (ranks[numOfRanks - 1].minDuration > _minDuration)
                revert NewDurationTooShort({value: _minDuration, minValue: ranks[numOfRanks - 1].minDuration});
        }
        if (_id < numOfRanks - 1) {
            if (ranks[_id + 1].goalAmount < _goalAmount)
                revert NewGoalTooBig({value: _goalAmount, maxValue: ranks[_id + 1].goalAmount});
            if (ranks[_id + 1].minDuration < _minDuration)
                revert NewDurationTooLong({value: _minDuration, maxValue: ranks[_id + 1].minDuration});
        }
        ranks[_id] = Rank(_minDuration, _goalAmount);
        emit ModifyRank(_minDuration, _goalAmount, _id);
    }

    /// @notice Accepts tokens, locks them and gives different tokens in return
    /// @dev The depositor should approve the contract to manage stakingTokens
    /// @dev For minting stakeTokens, this contract should be the owner of them
    /// @param _amount The amount to be deposited in the smallest unit of the token
    /// @param _rankId The id of the rank to be deposited to
    /// @param _consolidate Calls the consolidate function if true
    function deposit(
        uint256 _amount,
        uint256 _rankId,
        bool _consolidate
    ) external notFrozen {
        if (_amount < 1) revert NonPositiveAmount();
        if (timelocks[msg.sender].length >= 64) revert TooManyDeposits();
        if (numOfRanks < 1) revert NoRanks();
        if (_rankId >= numOfRanks) revert InvalidRank();
        if (
            rankBalances[_rankId][msg.sender].unlocked + rankBalances[_rankId][msg.sender].locked + _amount >=
            ranks[_rankId].goalAmount
        ) {
            unlockBelow(_rankId, msg.sender);
        } else if (_consolidate && _rankId > 0) {
            consolidate(_amount, _rankId, msg.sender);
        }
        LockedItem memory timelockData;
        timelockData.expires = block.timestamp + ranks[_rankId].minDuration * 1 minutes;
        timelockData.amount = _amount;
        timelockData.rankId = _rankId;
        timelocks[msg.sender].push(timelockData);
        rankBalances[_rankId][msg.sender].locked += _amount;
        IAgoraToken(stakeToken).mint(msg.sender, _amount);
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    /// @notice If the timelock is expired, gives back the staked tokens in return for the tokens obtained while depositing
    /// @dev This contract should have sufficient allowance to be able to burn stakeTokens from the user
    /// @dev For burning stakeTokens, this contract should be the owner of them
    /// @param _amount The amount to be withdrawn in the smallest unit of the token
    /// @param _rankId The id of the rank to be withdrawn from
    function withdraw(uint256 _amount, uint256 _rankId) external notFrozen {
        if (_amount < 1) revert NonPositiveAmount();
        uint256 expired = viewExpired(msg.sender, _rankId);
        if (rankBalances[_rankId][msg.sender].unlocked + expired < _amount)
            revert InsufficientBalance({
                rankId: _rankId,
                available: rankBalances[_rankId][msg.sender].unlocked + expired,
                required: _amount
            });
        unlockExpired(msg.sender);
        rankBalances[_rankId][msg.sender].unlocked -= _amount;
        IAgoraToken(stakeToken).burn(msg.sender, _amount);
        IERC20(token).transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /// @notice Checks the locked tokens for an account and unlocks them if they're expired
    /// @param _investor The address whose tokens should be checked
    function unlockExpired(address _investor) internal {
        uint256[] memory expired = new uint256[](numOfRanks);
        LockedItem[] storage usersLocked = timelocks[_investor];
        int256 usersLockedLength = int256(usersLocked.length);
        for (int256 i = 0; i < usersLockedLength; i++) {
            if (usersLocked[uint256(i)].expires <= block.timestamp) {
                // Collect expired amounts per ranks
                expired[usersLocked[uint256(i)].rankId] += usersLocked[uint256(i)].amount;
                // Remove expired locks
                usersLocked[uint256(i)] = usersLocked[uint256(usersLockedLength) - 1];
                usersLocked.pop();
                usersLockedLength--;
                i--;
            }
        }
        // Move expired amounts from locked to unlocked
        for (uint256 i = 0; i < numOfRanks; i++) {
            if (expired[i] > 0) {
                rankBalances[i][_investor].locked -= expired[i];
                rankBalances[i][_investor].unlocked += expired[i];
            }
        }
    }

    /// @notice Unlocks every deposit below a certain rank
    /// @dev Should be called, when the minimum of a rank is reached
    /// @param _investor The address whose tokens should be checked
    /// @param _rankId The id of the rank to be checked
    function unlockBelow(uint256 _rankId, address _investor) internal {
        LockedItem[] storage usersLocked = timelocks[_investor];
        int256 usersLockedLength = int256(usersLocked.length);
        uint256[] memory unlocked = new uint256[](numOfRanks);
        for (int256 i = 0; i < usersLockedLength; i++) {
            if (usersLocked[uint256(i)].rankId < _rankId) {
                // Collect the amount to be unlocked per rank
                unlocked[usersLocked[uint256(i)].rankId] += usersLocked[uint256(i)].amount;
                // Remove expired locks
                usersLocked[uint256(i)] = usersLocked[uint256(usersLockedLength) - 1];
                usersLocked.pop();
                usersLockedLength--;
                i--;
            }
        }
        // Move unlocked amounts from locked to unlocked
        for (uint256 i = 0; i < numOfRanks; i++) {
            if (unlocked[i] > 0) {
                rankBalances[i][_investor].locked -= unlocked[i];
                rankBalances[i][_investor].unlocked += unlocked[i];
            }
        }
    }

    /// @notice Collects the investments up to a certain rank if it's needed to reach the minimum
    /// @dev There must be more than 1 rank
    /// @dev The minimum should not be reached with the new deposit
    /// @dev The deposited amount must be locked after the function call
    /// @param _amount The amount to be deposited
    /// @param _rankId The id of the rank to be deposited to
    /// @param _investor The address which made the deposit
    function consolidate(
        uint256 _amount,
        uint256 _rankId,
        address _investor
    ) internal {
        uint256 consolidateAmount = ranks[_rankId].goalAmount -
            rankBalances[_rankId][_investor].unlocked -
            rankBalances[_rankId][_investor].locked -
            _amount;
        uint256 totalBalanceBelow;
        uint256 lockedBalance;
        uint256 unlockedBalance;

        LockedItem[] storage usersLocked = timelocks[_investor];
        int256 usersLockedLength = int256(usersLocked.length);

        for (uint256 i = 0; i < _rankId; i++) {
            lockedBalance = rankBalances[i][_investor].locked;
            unlockedBalance = rankBalances[i][_investor].unlocked;

            if (lockedBalance > 0) {
                totalBalanceBelow += lockedBalance;
                rankBalances[i][_investor].locked = 0;
            }

            if (unlockedBalance > 0) {
                totalBalanceBelow += unlockedBalance;
                rankBalances[i][_investor].unlocked = 0;
            }
        }

        if (totalBalanceBelow > 0) {
            LockedItem memory timelockData;
            // Iterate over the locked list and unlock everything below the rank
            for (int256 i = 0; i < usersLockedLength; i++) {
                if (usersLocked[uint256(i)].rankId < _rankId) {
                    usersLocked[uint256(i)] = usersLocked[uint256(usersLockedLength) - 1];
                    usersLocked.pop();
                    usersLockedLength--;
                    i--;
                }
            }
            // Create a new locked item and lock it for the rank's duration
            timelockData.expires = block.timestamp + ranks[_rankId].minDuration * 1 minutes;
            timelockData.rankId = _rankId;

            if (totalBalanceBelow > consolidateAmount) {
                // Set consolidateAmount as the locked amount
                timelockData.amount = consolidateAmount;
                rankBalances[_rankId][_investor].locked += consolidateAmount;
                rankBalances[_rankId][_investor].unlocked += totalBalanceBelow - consolidateAmount;
            } else {
                // Set totalBalanceBelow as the locked amount
                timelockData.amount = totalBalanceBelow;
                rankBalances[_rankId][_investor].locked += totalBalanceBelow;
            }
            timelocks[_investor].push(timelockData);
        }
    }

    /// @notice Disables the deposit and withdraw functions and enables emergencyWithdraw if input is true
    /// @notice Enables the deposit and withdraw functions and disables emergencyWithdraw if input is false
    /// @dev function call must change the state of the contract
    /// @param _frozen The new state of the contract
    function freezeSpace(bool _frozen) external onlyOwner {
        if (!frozen && !_frozen) revert SpaceIsNotFrozen();
        if (frozen && _frozen) revert SpaceIsFrozen();
        frozen = _frozen;
        emit SpaceFrozenState(frozen);
    }

    /// @notice Gives back all the staked tokens in exchange for the tokens obtained, regardless of timelock
    /// @dev Can only be called when the contract is frozen
    function emergencyWithdraw() external {
        if (!frozen) revert SpaceIsNotFrozen();

        uint256 totalBalance;
        uint256 lockedBalance;
        uint256 unlockedBalance;

        for (uint256 i = 0; i < numOfRanks; i++) {
            lockedBalance = rankBalances[i][msg.sender].locked;
            unlockedBalance = rankBalances[i][msg.sender].unlocked;

            if (lockedBalance > 0) {
                totalBalance += lockedBalance;
                rankBalances[i][msg.sender].locked = 0;
            }

            if (unlockedBalance > 0) {
                totalBalance += unlockedBalance;
                rankBalances[i][msg.sender].unlocked = 0;
            }
        }
        if (totalBalance < 1) revert NonPositiveAmount();

        delete timelocks[msg.sender];
        IAgoraToken(stakeToken).burn(msg.sender, totalBalance);
        IERC20(token).transfer(msg.sender, totalBalance);
        emit EmergencyWithdraw(msg.sender, totalBalance);
    }

    /// @notice Returns all the timelocks a user has in an array
    /// @param _wallet The address of the user
    /// @return An array containing structs with fields "expires", "amount" and "rankId"
    function getTimelocks(address _wallet) external view returns (LockedItem[] memory) {
        return timelocks[_wallet];
    }

    /// @notice Sums the locked tokens for an account by ranks if they were expired
    /// @param _investor The address whose tokens should be checked
    /// @param _rankId The id of the rank to be checked
    /// @return The total amount of expired, but not unlocked tokens in the rank
    function viewExpired(address _investor, uint256 _rankId) public view returns (uint256) {
        uint256 expiredAmount;
        LockedItem[] memory usersLocked = timelocks[_investor];
        uint256 usersLockedLength = usersLocked.length;
        for (uint256 i = 0; i < usersLockedLength; i++) {
            if (usersLocked[i].rankId == _rankId && usersLocked[i].expires <= block.timestamp) {
                expiredAmount += usersLocked[i].amount;
            }
        }
        return expiredAmount;
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

