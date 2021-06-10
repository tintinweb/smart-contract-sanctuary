/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.6.0;// SPDX-License-Identifier: MIT



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

pragma experimental ABIEncoderV2;



contract TokenTimelock {
    using SafeMath for uint256;

    IERC20 public token;
    /**
     * @dev maxWithdrawDeposits limits the number of deposits a user can withdraw at once.
     * Prevents releaseMultipleDeposits() to revert with "out of gas".
     */
    uint256 public maxWithdrawDeposits;

    mapping(address => Deposit[]) public beneficiaries;

    struct Deposit {
        uint256 amount;
        uint256 releaseTime;
        bool isClaimed;
    }

    event DepositIssued(
        address beneficiary,
        uint256 amount,
        uint256 releaseTime,
        uint256 index
    );

    event DepositReleased(address beneficiary, uint256 amount, uint256 index);
    event MultipleDepositsReleased(
        address beneficiary,
        uint256 amount,
        uint256 startIndex,
        uint256 endIndex
    );

    constructor(IERC20 _token, uint256 _maxWithdrawDeposits) public {
        require(_maxWithdrawDeposits > 0);
        token = _token;
        maxWithdrawDeposits = _maxWithdrawDeposits;
    }

    function getAllBeneficiaryDeposits(address _beneficiary)
        public
        view
        returns (Deposit[] memory)
    {
        return beneficiaries[_beneficiary];
    }

    function getBeneficiaryDeposit(address _beneficiary, uint256 _depositId)
        public
        view
        returns (Deposit memory)
    {
        return beneficiaries[_beneficiary][_depositId];
    }

    function getBeneficiaryDepositsCount(address _beneficiary)
        public
        view
        returns (uint256)
    {
        return beneficiaries[_beneficiary].length;
    }

    function getTimestampAfterNDays(uint256 _days)
        public
        view
        returns (uint256)
    {
        return block.timestamp + _days * 1 days;
    }

    /**
     * @param _releaseTime should be the timestamp of the release date in seconds since unix epoch.
     */
    function createDeposit(
        address _beneficiary,
        uint256 _amount,
        uint256 _releaseTime
    ) public {
        token.transferFrom(msg.sender, address(this), _amount);
        addBeneficiary(_beneficiary, _amount, _releaseTime);
    }

    /**
     * The three input arrays must be with equal length and with maximum of a 100 entities.
     */
    function createMultipleDeposits(
        address[] memory _beneficiaries,
        uint256[] memory _amounts,
        uint256[] memory _releaseTimes
    ) public {
        require(
            _beneficiaries.length == _amounts.length &&
                _amounts.length == _releaseTimes.length,
            "Mismatch in array lengths"
        );

        uint256 totalTokensDeposited;

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            addBeneficiary(_beneficiaries[i], _amounts[i], _releaseTimes[i]);
            totalTokensDeposited = totalTokensDeposited.add(_amounts[i]);
        }

        token.transferFrom(msg.sender, address(this), totalTokensDeposited);
    }

    function releaseDeposit(uint256 _depositId) public {
        require(
            beneficiaries[msg.sender].length > _depositId,
            "Non existing deposit id"
        );
        require(
            block.timestamp >=
                beneficiaries[msg.sender][_depositId].releaseTime,
            "TokenTimelock: current time is before release time"
        );
        require(
            !beneficiaries[msg.sender][_depositId].isClaimed,
            "The deposit is already claimed"
        );

        beneficiaries[msg.sender][_depositId].isClaimed = true;

        uint256 amount = beneficiaries[msg.sender][_depositId].amount;
        token.transfer(msg.sender, amount);

        emit DepositReleased(msg.sender, amount, _depositId);
    }

    function releaseMultipleDeposits(uint256 _startIndex, uint256 _endIndex)
        public
    {
        require(_endIndex > _startIndex, "End index is before start index");
        require(
            _endIndex.sub(_startIndex) <= maxWithdrawDeposits,
            "Max withdrawal count exceeded"
        );

        require(
            beneficiaries[msg.sender].length > _endIndex,
            "End Index out of range"
        );

        uint256 totalTokensDeposited;

        for (uint256 i = _startIndex; i <= _endIndex; i++) {
            if (beneficiaries[msg.sender][i].isClaimed) {
                continue;
            }
            if (block.timestamp < beneficiaries[msg.sender][i].releaseTime) {
                continue;
            }
            totalTokensDeposited = totalTokensDeposited.add(
                beneficiaries[msg.sender][i].amount
            );
            beneficiaries[msg.sender][i].isClaimed = true;
        }

        token.transfer(msg.sender, totalTokensDeposited);
        emit MultipleDepositsReleased(
            msg.sender,
            totalTokensDeposited,
            _startIndex,
            _endIndex
        );
    }

    function addBeneficiary(
        address _beneficiary,
        uint256 _amount,
        uint256 _releaseTime
    ) internal {
        require(
            _beneficiary != address(0),
            "Beneficiary address cannot be zero address"
        );

        require(_amount > 0, "Amount cannot be 0");

        require(
            _releaseTime > block.timestamp,
            "TokenTimelock: release time is after current time"
        );
        beneficiaries[_beneficiary].push(
            Deposit({
                amount: _amount,
                releaseTime: _releaseTime,
                isClaimed: false
            })
        );
        emit DepositIssued(
            _beneficiary,
            _amount,
            _releaseTime,
            beneficiaries[_beneficiary].length - 1
        );
    }
}