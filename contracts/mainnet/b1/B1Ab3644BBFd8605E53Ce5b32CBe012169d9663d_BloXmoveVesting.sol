//SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title bloXmove Cliffing and Vesting Contract.
 */
contract BloXmoveVesting is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;

    // The ERC20 bloXmove token
    IERC20 public immutable bloXmoveToken;
    // The allowed total amount of all grants (currently estimated 49000000 tokens).
    uint256 public immutable totalAmountOfGrants;
    // The current total amount of added grants.
    uint256 public storedAddedAmount = 0;

    struct Grant {
        address beneficiary;
        uint16 vestingDuration; // in days
        uint16 daysClaimed;
        uint256 vestingStartTime;
        uint256 amount;
        uint256 totalClaimed;
    }

    // The start time of all Grants.
    // starttime + cliffing time of Grant = starttime of vesting
    uint256 public immutable startTime;

    mapping(address => Grant) private tokenGrants;

    event GrantAdded(address indexed beneficiary);

    event GrantTokensClaimed(
        address indexed beneficiary,
        uint256 amountClaimed
    );

    /**
     * @dev Constructor to set the address of the token contract
     * and the start time (timestamp in seconds).
     */
    constructor(
        address _bloXmoveToken,
        address _grantManagerAddr,
        uint256 _totalAmountOfGrants,
        uint256 _startTime
    ) {
        transferOwnership(_grantManagerAddr);
        bloXmoveToken = IERC20(_bloXmoveToken);
        totalAmountOfGrants = _totalAmountOfGrants;
        startTime = _startTime;
    }

    /**
     * @dev Not supported receive function.
     */
    receive() external payable {
        revert("Not supported receive function");
    }

    /**
     * @dev Not supported fallback function.
     */
    fallback() external payable {
        revert("Not supported fallback function");
    }

    /**
     * @dev Add Token Grant for the beneficiary.
     * @param _beneficiary the address of the account receiving the grant
     * @param _amount the amount (in 1/18 token) of the grant
     * @param _vestingDurationInDays the vesting period of the grant in days
     * @param _vestingCliffInDays the cliff period of the grant in days
     *
     * Emits a {GrantAdded} event indicating the beneficiary address.
     *
     * Requirements:
     *
     * - The msg.sender is the owner of the contract.
     * - The beneficiary has no other Grants.
     * - The given grant amount + other added grants is smaller or equal to the totalAmountOfGrants
     * - The amount vested per day (amount/vestingDurationInDays) is bigger than 0.
     * - The requirement described in function {calculateGrantClaim} for msg.sender.
     * - The contract can transfer token on behalf of the owner of the contract.
     */
    function addTokenGrant(
        address _beneficiary,
        uint256 _amount,
        uint16 _vestingDurationInDays,
        uint16 _vestingCliffInDays
    ) external onlyOwner {
        require(tokenGrants[_beneficiary].amount == 0, "Grant already exists!");
        storedAddedAmount = storedAddedAmount.add(_amount);
        require(
            storedAddedAmount <= totalAmountOfGrants,
            "Amount exceeds grants balance!"
        );
        uint256 amountVestedPerDay = _amount.div(_vestingDurationInDays);
        require(amountVestedPerDay > 0, "amountVestedPerDay is 0");
        require(
            bloXmoveToken.transferFrom(owner(), address(this), _amount),
            "transferFrom Error"
        );

        Grant memory grant = Grant({
            vestingStartTime: startTime + _vestingCliffInDays * 1 days,
            amount: _amount,
            vestingDuration: _vestingDurationInDays,
            daysClaimed: 0,
            totalClaimed: 0,
            beneficiary: _beneficiary
        });
        tokenGrants[_beneficiary] = grant;
        emit GrantAdded(_beneficiary);
    }

    /**
     * @dev Claim the available vested tokens.
     *
     * This function is called by the beneficiaries to claim their vested tokens.
     *
     * Emits a {GrantTokensClaimed} event indicating the beneficiary address and
     * the claimed amount.
     *
     * Requirements:
     *
     * - The vested amount to claim is bigger than 0
     * - The requirement described in function {calculateGrantClaim} for msg.sender
     * - The contract can transfer tokens to the beneficiary
     */
    function claimVestedTokens() external {
        uint16 daysVested;
        uint256 amountVested;
        (daysVested, amountVested) = calculateGrantClaim(_msgSender());
        require(amountVested > 0, "Vested is 0");
        Grant storage tokenGrant = tokenGrants[_msgSender()];
        tokenGrant.daysClaimed = uint16(tokenGrant.daysClaimed.add(daysVested));
        tokenGrant.totalClaimed = uint256(
            tokenGrant.totalClaimed.add(amountVested)
        );
        require(
            bloXmoveToken.transfer(tokenGrant.beneficiary, amountVested),
            "no tokens"
        );
        emit GrantTokensClaimed(tokenGrant.beneficiary, amountVested);
    }

    /**
     * @dev calculate the days and the amount vested for a particular claim.
     *
     * Requirements:
     *
     * - The Grant ist not fully claimed
     * - The current time is bigger than the starttime.
     *
     * @return a tuple of days vested and amount of vested tokens.
     */
    function calculateGrantClaim(address _beneficiary)
        private
        view
        returns (uint16, uint256)
    {
        Grant storage tokenGrant = tokenGrants[_beneficiary];
        require(tokenGrant.amount > 0, "no Grant");
        require(
            tokenGrant.totalClaimed < tokenGrant.amount,
            "Grant fully claimed"
        );
        // Check cliffing duration
        if (currentTime() < tokenGrant.vestingStartTime) {
            return (0, 0);
        }

        uint256 elapsedDays = currentTime()
            .sub(tokenGrant.vestingStartTime - 1 days)
            .div(1 days);

        // If over vesting duration, all tokens vested
        if (elapsedDays >= tokenGrant.vestingDuration) {
            // solve the uneven vest issue that could accure
            uint256 remainingGrant = tokenGrant.amount.sub(
                tokenGrant.totalClaimed
            );
            return (tokenGrant.vestingDuration, remainingGrant);
        } else {
            uint16 daysVested = uint16(elapsedDays.sub(tokenGrant.daysClaimed));
            uint256 amountVestedPerDay = tokenGrant.amount.div(
                uint256(tokenGrant.vestingDuration)
            );
            uint256 amountVested = uint256(daysVested.mul(amountVestedPerDay));
            return (daysVested, amountVested);
        }
    }

    /**
     * @dev Get the amount of tokens that are currently available to claim for a given beneficiary.
     * Reverts if there is no grant for the beneficiary.
     *
     * @return the amount of tokens that are currently available to claim, 0 if fully claimed.
     */
    function getCurrentAmountToClaim(address _beneficiary)
        public
        view
        returns (uint256)
    {
        Grant storage tokenGrant = tokenGrants[_beneficiary];
        require(tokenGrant.amount > 0, "no Grant");
        if (tokenGrant.totalClaimed == tokenGrant.amount) {
            return 0;
        }
        uint256 amountVested;
        (, amountVested) = calculateGrantClaim(_beneficiary);
        return amountVested;
    }

    /**
     * @dev Get the remaining grant amount for a given beneficiary.
     * @return the remaining grant amount.
     */
    function getRemainingGrant(address _beneficiary)
        public
        view
        returns (uint256)
    {
        Grant storage tokenGrant = tokenGrants[_beneficiary];
        return tokenGrant.amount.sub(tokenGrant.totalClaimed);
    }

    /**
     * @dev Get the vesting start time for a given beneficiary.
     * @return the start time.
     */
    function getVestingStartTime(address _beneficiary)
        public
        view
        returns (uint256)
    {
        Grant storage tokenGrant = tokenGrants[_beneficiary];
        return tokenGrant.vestingStartTime;
    }

    /**
     * @dev Get the grant amount for a given beneficiary.
     * @return the grant amount.
     */
    function getGrantAmount(address _beneficiary)
        public
        view
        returns (uint256)
    {
        Grant storage tokenGrant = tokenGrants[_beneficiary];
        return tokenGrant.amount;
    }

    /**
     * @dev Get the timestamp from the block set by the miners.
     * @return the current timestamp of the block.
     */
    function currentTime() private view returns (uint256) {
        return block.timestamp; // solhint-disable-line
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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