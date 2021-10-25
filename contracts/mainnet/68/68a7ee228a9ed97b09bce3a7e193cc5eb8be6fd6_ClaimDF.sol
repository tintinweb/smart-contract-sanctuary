/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {_setPendingOwner} and {_acceptOwner}.
 */
contract Ownable {
    /**
     * @dev Returns the address of the current owner.
     */
    address public owner;

    /**
     * @dev Returns the address of the current pending owner.
     */
    address public pendingOwner;

    event NewOwner(address indexed previousOwner, address indexed newOwner);
    event NewPendingOwner(
        address indexed oldPendingOwner,
        address indexed newPendingOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     * @param _owner owner address.
     */
    function __Ownable_init(address _owner) internal {
        owner = _owner;
        emit NewOwner(address(0), _owner);
    }

    /**
     * @notice Base on the inputing parameter `_newPendingOwner` to check the exact error reason.
     * @dev Transfer contract control to a new owner. The _newPendingOwner must call `_acceptOwner` to finish the transfer.
     * @param _newPendingOwner New pending owner.
     */
    function _setPendingOwner(address _newPendingOwner)
        external
        onlyOwner
    {
        require(
            _newPendingOwner != address(0) && _newPendingOwner != pendingOwner,
            "_setPendingOwner: New owenr can not be zero address and owner has been set!"
        );

        // Gets current owner.
        address _oldPendingOwner = pendingOwner;

        // Sets new pending owner.
        pendingOwner = _newPendingOwner;

        emit NewPendingOwner(_oldPendingOwner, _newPendingOwner);
    }

    /**
     * @dev Accepts the admin rights, but only for pendingOwenr.
     */
    function _acceptOwner() external {
        require(
            msg.sender == pendingOwner,
            "_acceptOwner: Only for pending owner!"
        );

        // Gets current values for events.
        address _oldOwner = owner;
        address _oldPendingOwner = pendingOwner;

        // Set the new contract owner.
        owner = pendingOwner;

        // Clear the pendingOwner.
        pendingOwner = address(0);

        emit NewOwner(_oldOwner, owner);
        emit NewPendingOwner(_oldPendingOwner, pendingOwner);
    }
}

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

contract ClaimDF is Ownable {
    using SafeMath for uint256;

    /// @notice Token address to be allocated
    IERC20 public token;

    /// @notice Unlocked amount per stage
    uint256 public stageAmount;

    /// @notice Unlocked stage index
    uint256 public unlockedStageIndex;

    /// @notice Fix the unlock time of each stage
    uint256[] public unlockStage = [
        1624982400, // 2021-06-30
        1632931200, // 2021-09-30
        1640880000, // 2021-12-31
        1648569600, // 2022-03-30
        1656518400, // 2022-06-30
        1664467200, // 2022-09-30
        1672416000, // 2022-12-31
        1680105600 // 2023-03-30
    ];

    /// @dev Emitted when `token` is changed.
    event ClaimToken(IERC20 token);

    /// @dev Emitted when `stageAmount` is changed.
    event ClaimStageAmount(uint256 stageAmount);

    /// @dev Emitted when `unlockedStageIndex` is changed.
    event ClaimUnlockedStageIndex(uint256 oldUnlockedStageIndex, uint256 unlockedStageIndex);

    /// @param _token token address to be allocated
    /// @param _owner owner address
    /// @param _stageAmount unlocked amount per stage
    constructor(IERC20 _token, address _owner, uint256 _stageAmount) public {
        __Ownable_init(_owner);

        token = _token;
        emit ClaimToken(_token);

        stageAmount = _stageAmount;
        emit ClaimStageAmount(_stageAmount);
    }

    /**
     * @notice Get amount and stage index.
     * @dev Calculation unlocked amount and stage index by timestamp.
     * @param _timestamp Greenwich timestamp.
     * @return Unlocked amount; Unlocked stage index.
     */
    function _getClaimAmount(uint256 _timestamp) internal view returns (uint256, uint256) {

        uint256[] memory _unlockStage = unlockStage;
        uint256 _unlockedStageNum = unlockedStageIndex;
        while (_unlockedStageNum < _unlockStage.length && _timestamp > _unlockStage[_unlockedStageNum])
            _unlockedStageNum++;

        return (_unlockedStageNum.sub(unlockedStageIndex).mul(stageAmount), _unlockedStageNum);
    }

    /**
     * @notice Receive unlocked token.
     * @dev It must be the owner address to call.
     */
    function claim() external onlyOwner {
        (uint256 _amount, uint256 _unlockedStageIndex) = _getClaimAmount(block.timestamp);
        require(_unlockedStageIndex > unlockedStageIndex, "Not unlocked!");

        uint256 _oldUnlockedStageIndex = unlockedStageIndex;
        unlockedStageIndex = _unlockedStageIndex;
        emit ClaimUnlockedStageIndex(_oldUnlockedStageIndex, _unlockedStageIndex);

        token.transfer(owner, _amount);
    }

    /**
     * @notice Get claim info.
     * @dev Get unlocked amount and information for the next unlocking stage by timestamp.
     * @param _timestamp Greenwich timestamp.
     * @return  _amount : unlocked amount,
     *          _unlockedStageIndex : unlocking stage index,
     *          _stageTimestamp : unlocking stage timestamp.
     */
    function getClaimInfo(uint256 _timestamp) public view returns (uint256 _amount, uint256 _unlockedStageIndex, uint256 _stageTimestamp) {
        (_amount, _unlockedStageIndex) = _getClaimAmount(_timestamp);
        _stageTimestamp = _unlockedStageIndex == unlockStage.length ? unlockStage[_unlockedStageIndex - 1] : unlockStage[_unlockedStageIndex];
    }

    /**
     * @notice Get current claim info.
     * @dev Get unlocked amount and information for the next unlocking stage by block timestamp.
     * @return unlocked amount; unlocking stage index; unlocking stage timestamp.
     */
    function getClaimInfo() external view returns (uint256, uint256, uint256) {
        return getClaimInfo(block.timestamp);
    }

    /**
     * @dev Get the token balance of the contract
     * @return  Contract token balance.
     */
    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}