// Sources flattened with buidler v1.4.3 https://buidler.dev

// File @openzeppelin/contracts/GSN/Context.sol@v3.1.0

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


// File @openzeppelin/contracts/math/SafeMath.sol@v3.1.0

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v3.1.0

pragma solidity ^0.6.0;

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


// File @openzeppelin/contracts/utils/Pausable.sol@v3.1.0

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @animoca/f1dt-ethereum-contracts/contracts/game/TimeTrialEliteLeague.sol@v0.4.0

pragma solidity 0.6.8;





/// Minimal transfers-only ERC20 interface
interface IERC20Transfers {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

struct ParticipantData {
        uint256 timestamp;
        uint256 amount;
    }

/**
 * @title TimeTrialEliteLeague.
 * Contract which manages the participation status of players to the elite tiers.
 * Entering a tier requires the participant to escrow some ERC20 gaming token, which
 * is given back to the participant when they leave the tier.
 */
contract TimeTrialEliteLeague is Context, Pausable, Ownable {
    using SafeMath for uint256;
    /**
     * Event emitted when a player's particiation in a tier is updated.
     * @param participant The address of the participant.
     * @param tierId The tier identifier.
     * @param deposit Amount escrowed in tier. 0 means non participant.
     */
    event ParticipationUpdated(address participant, bytes32 tierId, uint256 deposit);

    IERC20Transfers public immutable gamingToken;
    uint256 public immutable lockingPeriod;
    mapping(bytes32 => uint256) public tiers; // tierId => minimumAmountToEscrow
    mapping(address => mapping(bytes32 => ParticipantData)) public participants; // participant => tierId => ParticipantData
    /**
     * @dev Reverts if `gamingToken_` is the zero address.
     * @dev Reverts if `lockingPeriod` is zero.
     * @dev Reverts if `tierIds` and `amounts` have different lengths.
     * @dev Reverts if any element of `amounts` is zero.
     * @param gamingToken_ An ERC20-compliant contract address.
     * @param lockingPeriod_ The period that a participant needs to wait for leaving a tier after entering it.
     * @param tierIds The identifiers of each supported tier.
     * @param amounts The amounts of gaming token to escrow for participation, for each one of the `tierIds`.
     */
    constructor(
        IERC20Transfers gamingToken_,
        uint256 lockingPeriod_,
        bytes32[] memory tierIds,
        uint256[] memory amounts
    ) public {
        require(gamingToken_ != IERC20Transfers(0), "Leagues: zero address");
        require(lockingPeriod_ != 0, "Leagues: zero lock");
        gamingToken = gamingToken_;
        lockingPeriod = lockingPeriod_;

        uint256 length = tierIds.length;
        require(length == amounts.length, "Leagues: inconsistent arrays");
        for (uint256 i = 0; i < length; ++i) {
            uint256 amount = amounts[i];
            require(amount != 0, "Leagues: zero amount");
            tiers[tierIds[i]] = amount;
        }
    }

    /**
     * Updates amount staked for participant in tier
     * @dev Reverts if `tierId` does not exist.  
     * @dev Reverts if user is not in tier.     
     * @dev Emits a ParticipationUpdated event.
     * @dev An amount of ERC20 `gamingToken` is transferred from the sender to this contract.
     * @param tierId The identifier of the tier to increase the deposit for.
     * @param amount The amount to deposit.
     */
    function increaseDeposit(bytes32 tierId, uint256 amount) whenNotPaused public {
        address sender = _msgSender();
        require(tiers[tierId] != 0, "Leagues: tier not found");
        ParticipantData memory pd = participants[sender][tierId];
        require(pd.timestamp != 0, "Leagues: non participant");
        uint256 newAmount = amount.add(pd.amount);
        participants[sender][tierId] = ParticipantData(block.timestamp,newAmount);
        require(
            gamingToken.transferFrom(sender, address(this), amount),
            "Leagues: transfer in failed"
        );
        emit ParticipationUpdated(sender, tierId, newAmount);
    }

    /**
     * Enables the participation of a player in a tier. Requires the escrowing of an amount of gaming token.
     * @dev Reverts if `tierId` does not exist.
     * @dev Reverts if 'deposit' is less than minimumAmountToEscrow
     * @dev Reverts if the sender is already participant in the tier.
     * @dev Emits a ParticipationUpdated event.
     * @dev An amount of ERC20 `gamingToken` is transferred from the sender to this contract.
     * @param tierId The identifier of the tier to enter.
     * @param deposit The amount to deposit.
     */
    function enterTier(bytes32 tierId, uint256 deposit) whenNotPaused public {
        address sender = _msgSender();
        uint256 minDeposit = tiers[tierId];
        require(minDeposit != 0, "Leagues: tier not found");
        require(minDeposit <= deposit, "Leagues: insufficient amount");
        require(participants[sender][tierId].timestamp == 0, "Leagues: already participant");
        participants[sender][tierId] = ParticipantData(block.timestamp,deposit);
        require(
            gamingToken.transferFrom(sender, address(this), deposit),
            "Leagues: transfer in failed"
        );
        emit ParticipationUpdated(sender, tierId, deposit);
    }

    /**
     * Disables the participation of a player in a tier. Releases the amount of gaming token escrowed for this tier.
     * @dev Reverts if the sender is not a participant in the tier.
     * @dev Reverts if the tier participation of the sender is still time-locked.
     * @dev Emits a ParticipationUpdated event.
     * @dev An amount of ERC20 `gamingToken` is transferred from this contract to the sender.
     * @param tierId The identifier of the tier to exit.
     */
    function exitTier(bytes32 tierId) public {
        address sender = _msgSender();
        ParticipantData memory pd = participants[sender][tierId];
        require(pd.timestamp != 0, "Leagues: non-participant");
        
        require(block.timestamp - pd.timestamp > lockingPeriod, "Leagues: time-locked");
        participants[sender][tierId] = ParticipantData(0,0);
        emit ParticipationUpdated(sender, tierId, 0);
        require(
            gamingToken.transfer(sender, pd.amount),
            "Leagues: transfer out failed"
        );
    }

    /**
     * Gets the partricipation status of several tiers for a participant.
     * @param participant The participant to check the status of.
     * @param tierIds The tier identifiers to check.
     * @return timestamps The enter timestamp for each of the the `tierIds`. Zero values mean non-participant.
     */
    function participantStatus(address participant, bytes32[] calldata tierIds)
        external
        view
        returns (uint256[] memory timestamps)
    {
        uint256 length = tierIds.length;
        timestamps = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            timestamps[i] = participants[participant][tierIds[i]].timestamp;
        }
    }

     /**
     * Pauses the deposit operations.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if the contract is paused already.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpauses the deposit operations.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if the contract is not paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

}