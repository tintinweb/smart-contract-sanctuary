// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract Root
contract Root is Ownable {
    using SafeMath for uint;

    enum Group { PrivateRound, PublicSale, Marketing, Liquidity, Team, Advisor, Ecosystem }

    IERC20 public token;

    struct GroupInfo {
        uint256[] balances;
        uint256[] balancesBase;
        uint256[] percents;
        address[] addresses;
    }

    mapping(Group => GroupInfo) private groupToInfo;

    /// @notice Time when the contract was deployed
    uint256 public deployTime;

    constructor(address _token) {
        token = IERC20(_token);
        deployTime = block.timestamp;
    }

    /// @notice Load group data to contract.
    /// @return bool True if data successfully loaded
    function loadGroupInfo(GroupInfo memory _group, Group _groupNumber) external onlyOwner returns(bool) {
        require(groupToInfo[_groupNumber].addresses.length == 0, "[E-39] - Group already loaded.");
        require(_group.addresses.length > 0, "[E-40] - Empty address array in group.");
        require(_group.addresses.length == _group.balances.length, "[E-50] - Address and balance length should be equal.");

        _checkTotalPercentSumInGroup(_group);

        _setupBaseBalance(_group);

        _transferTokensOnLoad(_group);

        groupToInfo[_groupNumber] = _group;

        return true;
    }

    /// @notice Check that percent sum inside group equal to 1
    /// @param _group Group to upload
    function _checkTotalPercentSumInGroup(GroupInfo memory _group) private pure {
        uint256 _percentSum = 0;
        for (uint256 k = 0; k < _group.percents.length; k++) {
            _percentSum = _percentSum.add(_group.percents[k]);
        }
        require(_percentSum == getDecimal(), "[E-104] - Invalid percent sum in group.");
    }

    /// @notice Copy user balances to baseBalances
    /// @param _group Group to upload
    function _setupBaseBalance(GroupInfo memory _group) private pure {
        _group.balancesBase = new uint256[](_group.balances.length);

        for (uint256 k = 0; k < _group.balances.length; k++) {
            _group.balancesBase[k] = _group.balances[k];
        }
    }

    /// @notice Transfer tokens in groups where TGE is 100% and execute base input validation
    /// @param _group Group to upload
    function _transferTokensOnLoad(GroupInfo memory _group) private {
        if (_group.percents[0] == getDecimal()) {
            for (uint256 k = 0; k < _group.addresses.length; k++) {
                _group.balances[k] = 0;
                token.transfer(_group.addresses[k], _group.balancesBase[k]);
            }
        }
    }

    /// @notice Transfer amount from contract to `msg.sender`
    /// @param _group Group number
    /// @param _amount Withdrawal amount
    /// @return True if withdrawal success
    function withdraw(Group _group, uint256 _amount) external returns(bool) {
        GroupInfo memory _groupInfo = groupToInfo[_group];

        uint256 _senderIndex = _getSenderIndexInGroup(_groupInfo);

        uint256 _availableToWithdraw = _getAvailableToWithdraw(_groupInfo);

        uint256 _amountToWithdraw = _amount > _availableToWithdraw ? _availableToWithdraw : _amount;
        require(_amountToWithdraw != 0, "[E-51] - Amount to withdraw is zero.");

        groupToInfo[_group].balances[_senderIndex] = (_groupInfo.balances[_senderIndex]).sub(_amountToWithdraw);

        return token.transfer(msg.sender, _amountToWithdraw);
    }

    /// @notice Function for external call. See _getWithdrawPercent
    /// @param _group Group number
    function getWithdrawPercent(Group _group) external view returns(uint256) {
        GroupInfo memory _groupInfo = groupToInfo[_group];
        return _getWithdrawPercent(_groupInfo);
    }

    /// @notice Get total percent for group depending on the number of days elapsed after contract deploy.
    /// @notice For example, percent for first 30 days - 15%, all next 30 days - 5%, return 25% after 90 days.
    /// @param _groupInfo Structure with group info
    function _getWithdrawPercent(GroupInfo memory _groupInfo) private view returns(uint256) {
        uint256 _index = 0;
        uint256 _timePerIndex = 30 days;
        uint256 _deployTime = deployTime;

        while(_deployTime + _timePerIndex * (_index + 1) <= block.timestamp) {
            _index++;
        }

        // Return 1 if last month is passed
        if (_groupInfo.percents.length - 1 <= _index) return getDecimal();

        uint256 _monthWithdrawPercent = 0;
        for (uint256 i = 0; i <= _index; i++) {
            _monthWithdrawPercent = _monthWithdrawPercent.add(_groupInfo.percents[i]);
        }

        uint256 _daysFromDeploy = (block.timestamp).sub(_deployTime).div(24 * 3600).mod(30);
        uint256 _daysWithdrawPercent = (_groupInfo.percents[_index + 1]).mul(_daysFromDeploy).div(30);

        return _monthWithdrawPercent.add(_daysWithdrawPercent);
    }

    /// @notice Function for external call. See _getWithdrawPercent.
    /// @param _group Group number
    function getAvailableToWithdraw(Group _group) external view returns(uint256) {
        GroupInfo memory _groupInfo = groupToInfo[_group];
        return _getAvailableToWithdraw(_groupInfo);
    }

    /// @param _groupInfo Structure with group info
    /// @return Amount that user can withdraw.
    function _getAvailableToWithdraw(GroupInfo memory _groupInfo) private view returns(uint256) {
        uint256 _withdrawPercent = _getWithdrawPercent(_groupInfo);
        uint256 _senderIndex = _getSenderIndexInGroup(_groupInfo);

        uint256 _availableToWithdraw = _withdrawPercent.mul(_groupInfo.balancesBase[_senderIndex]).div(getDecimal());
        uint256 _alreadyWithdraw = (_groupInfo.balancesBase[_senderIndex]).sub(_groupInfo.balances[_senderIndex]);

        return _availableToWithdraw.sub(_alreadyWithdraw);
    }

    /// @param _groupInfo Structure with group info
    /// @return Sender index that corresponds to the user balance and user balanceBase
    function _getSenderIndexInGroup(GroupInfo memory _groupInfo) private view returns(uint256) {
        bool _isAddressExistInGroup = false;
        uint256 _senderIndex = 0;

        for (uint256 i = 0; i < _groupInfo.addresses.length; i++) {
            if (_groupInfo.addresses[i] == msg.sender) {
                _isAddressExistInGroup = true;
                _senderIndex = i;
                break;
            }
        }
        require(_isAddressExistInGroup, '[E-55] - Address not found in selected group.');

        return _senderIndex;
    }

    /// @notice Decimal for contract
    function getDecimal() private pure returns (uint256) {
        return 10 ** 27;
    }
}