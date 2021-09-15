/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title Vesting
 * Version of The Colony Network Vesting contract modified to include a
 * deployer defined refund recipient.
 * Further modified by Curvegrid to include method to add token grant batches
 * and rebased to use IBEP20 and Safe Math as dependancies.
 * @author Val Mack - <[email protected]>
 * https://github.com/JoinColony/colonyToken/blob/master/contracts/Vesting.sol
 *
 * See original GNU GPL license from The Colony Network below:
 *
 * > This file is part of The Colony Network.
 *
 * > The Colony Network is free software: you can redistribute it and/or modify
 * > it under the terms of the GNU General Public License as published by
 * > the Free Software Foundation, either version 3 of the License, or
 * > (at your option) any later version.
 *
 * > The Colony Network is distributed in the hope that it will be useful,
 * > but WITHOUT ANY WARRANTY; without even the implied warranty of
 * > MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * > GNU General Public License for more details.
 *
 * > You should have received a copy of the GNU General Public License
 * > along with The Colony Network. If not, see <http://www.gnu.org/licenses/>.
 *
 */
contract Vesting {
    using SafeMath for uint256;

    IBEP20 public token;
    address public owner;
    address public refundRecipient;

    uint constant internal SECONDS_PER_DAY = 86400;

    event GrantAdded(address recipient, uint256 startTime, uint128 amount, uint16 vestingDuration, uint16 vestingCliff);
    event GrantRemoved(address recipient, uint128 amountVested, uint128 amountNotVested);
    event GrantTokensClaimed(address recipient, uint128 amountClaimed);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RefundRecipientRoleTransferred(address indexed previousRefundRecipient, address indexed newRefundRecipient);

    struct Grant {
        uint startTime;
        uint128 amount;
        uint16 vestingDuration;
        uint16 vestingCliff;
        uint16 daysClaimed;
        uint128 totalClaimed;
    }
    mapping (address => Grant) public tokenGrants;

    modifier onlyOwner {
        require(msg.sender == owner, "vesting-unauthorized");
        _;
    }

    modifier onlyRefundRecipient {
        require(msg.sender == refundRecipient, "vesting-unauthorized");
        _;
    }

    modifier nonZeroAddress(address x) {
        require(x != address(0), "vesting-zero-address");
        _;
    }

    modifier noGrantExistsForUser(address _user) {
        require(tokenGrants[_user].startTime == 0, "vesting-user-grant-already-exists");
        _;
    }

    constructor(address _token, address _owner, address _refundRecipient) public
    nonZeroAddress(_token)
    nonZeroAddress(_owner)
    nonZeroAddress(_refundRecipient)
    {
        token = IBEP20(_token);
        owner = _owner;
        refundRecipient = _refundRecipient;
    }

    /// @notice Add a new token grant for user `_recipient`. Only one grant per user is allowed
    /// The amount of tokens here need to be preapproved for transfer by this `Vesting` contract before this call
    /// Secured to the Owner only
    /// @param _recipient Address of the token grant recipient entitled to claim the grant funds
    /// @param _startTime Grant start time as seconds since unix epoch
    /// Allows backdating grants by passing time in the past. If `0` is passed here current blocktime is used.
    /// @param _amount Total number of tokens in grant
    /// @param _vestingDuration Number of days of the grant's duration
    /// @param _vestingCliff Number of days of the grant's vesting cliff
    function addTokenGrant(address _recipient, uint256 _startTime, uint128 _amount, uint16 _vestingDuration, uint16 _vestingCliff) external
    onlyOwner
    noGrantExistsForUser(_recipient)
    {
        require(_vestingCliff > 0, "vesting-zero-cliff");
        require(_vestingDuration > _vestingCliff, "vesting-cliff-longer-than-duration");
        uint amountVestedPerDay = uint(_amount).div(_vestingDuration);
        require(amountVestedPerDay > 0, "vesting-zero-amount-per-day");

        // Transfer the grant tokens under the control of the vesting contract
        token.transferFrom(owner, address(this), _amount);

        Grant memory grant = Grant({
            startTime: _startTime == 0 ? now : _startTime,
            amount: _amount,
            vestingDuration: _vestingDuration,
            vestingCliff: _vestingCliff,
            daysClaimed: 0,
            totalClaimed: 0
        });

        tokenGrants[_recipient] = grant;
        emit GrantAdded(_recipient, grant.startTime, _amount, _vestingDuration, _vestingCliff);
    }

    /// @notice Add a new token grant for each user of `_recipients`. Only one grant per user is allowed
    /// The amount of tokens here need to be preapproved for transfer by this `Vesting` contract before this call
    /// Secured to the Owner only
    /// @param _recipients Array of addresses of the token grant recipients entitled to claim the grant funds
    /// @param _startTime Grant start time as seconds since unix epoch
    /// Allows backdating grants by passing time in the past. If `0` is passed here current blocktime is used.
    /// @param _amounts Array of token amounts to be granted for the user of the same index
    /// @param _vestingDuration Number of days of the grant's duration
    /// @param _vestingCliff Number of days of the grant's vesting cliff
    function addTokenGrantBatch(address[] calldata _recipients, uint256 _startTime, uint128[] calldata _amounts, uint16 _vestingDuration, uint16 _vestingCliff) external
    onlyOwner
    {
        require(_recipients.length > 0, "vesting-batch-length-zero");
        require(_recipients.length == _amounts.length, "vesting-batch-length-mismatch");
        require(_vestingCliff > 0, "vesting-zero-cliff");
        require(_vestingDuration > _vestingCliff, "vesting-cliff-longer-than-duration");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount = totalAmount.add(_amounts[i]);
        }

        // Transfer control of the summed grant amount to the vesting contract
        token.transferFrom(owner, address(this), totalAmount);

        for (uint256 i = 0; i < _recipients.length; i++) {
            uint amountVestedPerDay = uint(_amounts[i]).div(_vestingDuration);
            require(amountVestedPerDay > 0, "vesting-zero-amount-per-day");
            require(tokenGrants[_recipients[i]].startTime == 0, "vesting-user-grant-already-exists");

            Grant memory grant = Grant({
                startTime: _startTime == 0 ? now : _startTime,
                amount: _amounts[i],
                vestingDuration: _vestingDuration,
                vestingCliff: _vestingCliff,
                daysClaimed: 0,
                totalClaimed: 0
            });

            tokenGrants[_recipients[i]] = grant;
            emit GrantAdded(_recipients[i], grant.startTime, _amounts[i], _vestingDuration, _vestingCliff);
        }
    }

    /// @notice Terminate token grant transferring all vested tokens to the `_recipient`
    /// and returning all non-vested tokens to the Refund Recipient
    /// Secured to the Refund Recipient only
    /// @param _recipient Address of the token grant recipient
    function removeTokenGrant(address _recipient) external
    onlyRefundRecipient
    {
        Grant storage tokenGrant = tokenGrants[_recipient];
        uint128 amountVested;
        (, amountVested) = calculateGrantClaim(_recipient);
        uint128 amountNotVested = uint128(uint(tokenGrant.amount).sub(tokenGrant.totalClaimed).sub(amountVested));

        tokenGrant.startTime = 0;
        tokenGrant.amount = 0;
        tokenGrant.vestingDuration = 0;
        tokenGrant.vestingCliff = 0;
        tokenGrant.daysClaimed = 0;
        tokenGrant.totalClaimed = 0;

        require(token.transfer(_recipient, amountVested), "vesting-recipient-transfer-failed");
        require(token.transfer(refundRecipient, amountNotVested), "vesting-refund-recipient-transfer-failed");

        emit GrantRemoved(_recipient, amountVested, amountNotVested);
    }

    /// @notice Allows a grant recipient to claim their vested tokens. Errors if no tokens have vested
    /// It is advised recipients check they are entitled to claim via `calculateGrantClaim` before calling this
    function claimVestedTokens() external {
        uint16 daysVested;
        uint128 amountVested;
        (daysVested, amountVested) = calculateGrantClaim(msg.sender);
        require(amountVested > 0, "vesting-zero-amount-vested");

        Grant storage tokenGrant = tokenGrants[msg.sender];
        tokenGrant.daysClaimed = uint16(uint(tokenGrant.daysClaimed).add(daysVested));
        tokenGrant.totalClaimed = uint128(uint(tokenGrant.totalClaimed).add(amountVested));

        require(token.transfer(msg.sender, amountVested), "vesting-sender-transfer-failed");
        emit GrantTokensClaimed(msg.sender, amountVested);
    }

    /// @notice Calculate the vested and unclaimed days and tokens available for `_recepient` to claim
    /// Due to rounding errors once grant duration is reached, returns the entire left grant amount
    /// Returns (0, 0) if cliff has not been reached
    function calculateGrantClaim(address _recipient) public view returns (uint16, uint128) {
        Grant storage tokenGrant = tokenGrants[_recipient];

        // For grants created with a future start date, that hasn't been reached, return 0, 0
        if (now < tokenGrant.startTime) {
            return (0, 0);
        }

        // Check cliff was reached
        uint elapsedTime = now.sub(tokenGrant.startTime);
        uint elapsedDays = elapsedTime.div(SECONDS_PER_DAY);

        if (elapsedDays < tokenGrant.vestingCliff) {
            return (0, 0);
        }

        // If over vesting duration, all tokens vested
        if (elapsedDays >= tokenGrant.vestingDuration) {
            uint16 daysVested = uint16(uint(tokenGrant.vestingDuration).sub(tokenGrant.daysClaimed));
            uint128 remainingGrant = uint128(uint(tokenGrant.amount).sub(tokenGrant.totalClaimed));
            return (daysVested, remainingGrant);
        } else {
            uint16 daysVested = uint16(elapsedDays.sub(tokenGrant.daysClaimed));
            uint amountVestedPerDay = uint(tokenGrant.amount).div(tokenGrant.vestingDuration);
            uint128 amountVested = uint128(uint(daysVested).mul(amountVestedPerDay));
            return (daysVested, amountVested);
        }
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Transfers refund recipient of the contract to a new account (`newRefundRecipient`).
     * Can only be called by the current owner.
     */
    function transferRefundRecipientRole(address newRefundRecipient) public onlyOwner {
        require(
            newRefundRecipient != address(0),
            "new refund recipient is the zero address"
        );
        emit RefundRecipientRoleTransferred(refundRecipient, newRefundRecipient);
        refundRecipient = newRefundRecipient;
    }
}