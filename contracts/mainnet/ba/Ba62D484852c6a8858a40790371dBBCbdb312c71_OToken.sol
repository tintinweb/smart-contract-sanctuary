pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IStrategiesWhitelist.sol";
import "./interfaces/IAllocationStrategy.sol";
import "./Ownable.sol";
import "./OTokenStorage.sol";

/**
    @title oToken contract
    @author Overall Finance
    @notice Core oToken contract
*/
contract OToken is OTokenStorage, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // MAX fee on interest is 10%
    uint256 public constant MAX_FEE = 10**18 / 10;
    uint256 public constant INITIAL_EXCHANGE_RATE = 50 ether;

    event FeeChanged(address indexed owner, uint256 oldFee, uint256 newFee);
    event AllocationStrategyChanged(address indexed owner, address indexed oldAllocationStrategy, address indexed newAllocationStrategy);
    event Withdrawn(address indexed from, address indexed receiver, uint256 amount);
    event Deposited(address indexed from, address indexed receiver, uint256 amount);
    event AdminChanged(address newAdmin);
    event TreasuryChanged(address newTreasury);
    event WhitelistChanged(address newWhitelist);

    /**
        @notice Initializer
        @dev Replaces the constructor so it can be used together with a proxy contract
        @param _initialAllocationStrategy Address of the initial allocation strategy
        @param _name Token name
        @param _symbol Token symbol
        @param _decimals Amount of decimals the token has
        @param _underlying Address of the underlying token
        @param _admin Address of the OToken admin
        @param _treasury Address of the OToken treasury
        @param _strategiesWhitelist Address of the StrategiesWhitelist Contract
    */
    function init(
        address _initialAllocationStrategy,
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        address _underlying,
        address _admin,
        address _treasury,
        address _strategiesWhitelist
    ) public  {
        ots storage s = lots();
        require(!s.initialised, "Already initialised");
        s.initialised = true;
        s.allocationStrategy = IAllocationStrategy(_initialAllocationStrategy);
        s.name = _name;
        s.symbol = _symbol;
        s.underlying = IERC20(_underlying);
        s.decimals = uint8(_decimals);
        s.admin = _admin;
        s.treasury = _treasury;
        s.strategiesWhitelist = IStrategiesWhitelist(_strategiesWhitelist);
        _setOwner(msg.sender);
    }

    /**
        @notice Deposit Underlying token in return for oTokens
        @param _amount Amount of the underlying token
        @param _receiver Address receiving the oToken
    */

    function depositUnderlying(uint256 _amount, address _receiver) external nonReentrant {
        ots storage s = lots();
        handleFeesInternal();
        uint256 strategyUnderlyingBalanceBefore = s.allocationStrategy.balanceOfUnderlying();
        s.underlying.safeTransferFrom(msg.sender, address(s.allocationStrategy), _amount);
        uint256 amount = s.allocationStrategy.investUnderlying(_amount);
        _deposit(amount, _receiver, strategyUnderlyingBalanceBefore);
    }

    function _deposit(uint256 _amount, address _receiver, uint256 _strategyUnderlyingBalanceBefore) internal {
        ots storage s = lots();

        if(s.internalTotalSupply == 0) {
            uint256 internalToMint = _amount.mul(INITIAL_EXCHANGE_RATE).div(10**18);
            s.internalBalanceOf[_receiver] = internalToMint;
            s.internalTotalSupply = internalToMint;
            emit Transfer(address(0), _receiver, _amount);
            emit Deposited(msg.sender, _receiver, _amount);
            // Set last total underlying to keep track of interest
            s.lastTotalUnderlying = s.allocationStrategy.balanceOfUnderlying();
            return;
        } else {
            // Calculates proportional internal balance from deposit
            uint256 internalToMint = s.internalTotalSupply.mul(_amount).div(_strategyUnderlyingBalanceBefore);
            s.internalBalanceOf[_receiver] = s.internalBalanceOf[_receiver].add(internalToMint);
            s.internalTotalSupply = s.internalTotalSupply.add(internalToMint);
            emit Transfer(address(0), _receiver, _amount);
            emit Deposited(msg.sender, _receiver, _amount);
            // Set last total underlying to keep track of interest
            s.lastTotalUnderlying = s.allocationStrategy.balanceOfUnderlying();
            return;
        }
    }

    /**
        @notice Burns oTokens and returns the underlying asset
        @param _redeemAmount Amount of oTokens to burn
        @param _receiver Address receiving the underlying asset
    */
    function withdrawUnderlying(uint256 _redeemAmount, address _receiver) external nonReentrant {
        ots storage s = lots();
        handleFeesInternal();
        uint256 internalAmount = s.internalTotalSupply.mul(_redeemAmount).div(s.allocationStrategy.balanceOfUnderlying());
        s.internalBalanceOf[msg.sender] = s.internalBalanceOf[msg.sender].sub(internalAmount);
        s.internalTotalSupply = s.internalTotalSupply.sub(internalAmount);
        uint256 redeemedAmount = s.allocationStrategy.redeemUnderlying(_redeemAmount, _receiver);
        s.lastTotalUnderlying = s.allocationStrategy.balanceOfUnderlying();
        emit Transfer(msg.sender, address(0), redeemedAmount);
        emit Withdrawn(msg.sender, _receiver, redeemedAmount);
    }

    /**
        @notice Get the allowance
        @param _owner Address that set the allowance
        @param _spender Address allowed to spend
        @return Amount allowed to spend
    */
    function allowance(address _owner, address _spender) external view override returns (uint256) {
        ots storage s = lots();
        return s.internalAllowances[_owner][_spender];
    }

    /**
        @notice Approve an address to transfer tokens on your behalf
        @param _spender Address allowed to spend
        @param _amount Amount allowed to spend
        @return success
    */
    function approve(address _spender, uint256 _amount) external override returns (bool) {
        ots storage s = lots();
        s.internalAllowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
        @notice Get the balance of an address
        @dev Balance goes up when interest is earned
        @param _account Address to query balance of
        @return Balance of the account
    */
    function balanceOf(address _account) external view override returns (uint256) {
        // Returns proportional share of the underlying asset
        ots storage s = lots();
        if(s.internalTotalSupply == 0) {
            return 0;
        }
        return s.allocationStrategy.balanceOfUnderlyingView().mul(s.internalBalanceOf[_account]).div(s.internalTotalSupply.add(calcFeeMintAmount()));
    }

    /**
        @notice Get the total amount of tokens
        @return totalSupply
    */
    function totalSupply() external view override returns (uint256) {
        ots storage s = lots();
        return s.allocationStrategy.balanceOfUnderlyingView();
    }

    /**
        @notice Transfer tokens
        @param _to Address to send the tokens to
        @param _amount Amount of tokens to send
        @return success
    */
    function transfer(address _to, uint256 _amount) external override returns(bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
        @notice Transfer tokens from
        @param _from Address to transfer the tokens from
        @param _to Address to send the tokens to
        @param _amount Amount of tokens to transfer
        @return success
    */
    function transferFrom(address _from, address _to, uint256 _amount) external override returns(bool) {
        ots storage s = lots();
        require(
            msg.sender == _from ||
            s.internalAllowances[_from][_to] >= _amount,
            "OToken.transferFrom: Insufficient allowance"
        );

        // DO not update balance if it is set to max uint256
        if(s.internalAllowances[_from][msg.sender] != uint256(-1)) {
            s.internalAllowances[_from][msg.sender] = s.internalAllowances[_from][msg.sender].sub(_amount);
        }
        _transfer(_from, _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        ots storage s = lots();
        handleFeesInternal();

        // internal amount = internalTotalSupply * amount / underlying total balance
        uint256 internalAmount = s.internalTotalSupply.mul(_amount).div(s.allocationStrategy.balanceOfUnderlyingView());
        uint256 sanityAmount = internalAmount.mul(s.allocationStrategy.balanceOfUnderlyingView()).div(s.internalTotalSupply);

        // If there is a rounding issue add one wei
        if(_amount != sanityAmount) {
            internalAmount = internalAmount.add(1);
        }

        s.internalBalanceOf[_from] = s.internalBalanceOf[_from].sub(internalAmount);
        s.internalBalanceOf[_to] = s.internalBalanceOf[_to].add(internalAmount);
        emit Transfer(_from, _to, _amount);

        s.lastTotalUnderlying = s.allocationStrategy.balanceOfUnderlyingView();
    }

    /**
        @notice Pulls fees to owner
    */
    function handleFees() public {
        handleFeesInternal();
    }

    function handleFeesInternal() internal {
        ots storage s = lots();
        uint256 mintAmount = calcFeeMintAmount();
        if(mintAmount == 0) {
            return;
        }

        s.internalBalanceOf[s.treasury] = s.internalBalanceOf[s.treasury].add(mintAmount);
        s.internalTotalSupply = s.internalTotalSupply.add(mintAmount);

        s.lastTotalUnderlying = s.allocationStrategy.balanceOfUnderlyingView();
    }

    /**
        @notice Calculate internal balance to mint for fees
        @return Amount to mint
    */
    function calcFeeMintAmount() public view returns (uint256) {
        ots storage s = lots();
        // If interest is 0 or negative
        uint256 newUnderlyingAmount = s.allocationStrategy.balanceOfUnderlyingView();
        if(newUnderlyingAmount <= s.lastTotalUnderlying) {
            return 0;
        }
        uint256 interestEarned = newUnderlyingAmount.sub(s.lastTotalUnderlying);
        if(interestEarned == 0) {
            return 0;
        }
        uint256 feeAmount = interestEarned.mul(s.fee).div(10**18);

        return s.internalTotalSupply.mul(feeAmount).div(newUnderlyingAmount.sub(feeAmount));
    }

    /**
        @notice Set the fee, can only be called by the owner
        @param _newFee The new fee. 1e18 == 100%
    */
    function setFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= MAX_FEE, "OToken.setFee: Fee too high");
        ots storage s = lots();
        emit FeeChanged(msg.sender, s.fee, _newFee);
        s.fee = _newFee;
    }

    /**
        @notice Set the new admin
        @param _newAdmin address of the new admin
    */
    function setAdmin(address _newAdmin) external onlyOwner {
        ots storage s = lots();
        emit AdminChanged(_newAdmin);
        s.admin = _newAdmin;
    }

    /**
        @notice Set the new treasury
        @param _newTreasury address of the new treasury
    */
    function setTreasury(address _newTreasury) external onlyOwner {
        ots storage s = lots();
        emit TreasuryChanged(_newTreasury);
        s.treasury = _newTreasury;
    }

    /**
        @notice Set the new strategiesWhitelist
        @param _newStrategiesWhitelist address of the new whitelist
    */
    function setWhitelist(address _newStrategiesWhitelist) external onlyOwner {
        ots storage s = lots();
        emit WhitelistChanged(_newStrategiesWhitelist);
        s.strategiesWhitelist = IStrategiesWhitelist(_newStrategiesWhitelist);
    }

    /**
        @notice Change the allocation strategy. Can only be called by the owner
        @param _newAllocationStrategy Address of the allocation strategy
    */
    function changeAllocationStrategy(address _newAllocationStrategy) external {
        ots storage s = lots();
        require(msg.sender == s.admin, "OToken.changeAllocationStrategy: msg.sender not admin");
        require(s.strategiesWhitelist.isWhitelisted(_newAllocationStrategy) == 1, "OToken.changeAllocationStrategy: allocations strategy not whitelisted");

        emit AllocationStrategyChanged(msg.sender, address(s.allocationStrategy), _newAllocationStrategy);

        // redeem all from old allocation strategy
        s.allocationStrategy.redeemAll();

        // change allocation strategy
        s.allocationStrategy = IAllocationStrategy(_newAllocationStrategy);

        uint256 balance = s.underlying.balanceOf(address(this));

        // transfer underlying to new allocation strategy
        s.underlying.safeTransfer(_newAllocationStrategy, balance);
        // deposit in new allocation strategy
        s.allocationStrategy.investUnderlying(balance);
    }

    /**
        @notice Withdraw accidentally acquired tokens by OToken
        @param _token Address of the token to withdraw
    */
    function withdrawLockedERC20(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity 0.6.6;

interface IStrategiesWhitelist {
    function isWhitelisted(address _allocationStrategy) external returns (uint8 answer);
}

pragma solidity 0.6.6;

interface IAllocationStrategy {
    function balanceOfUnderlying() external returns (uint256);
    function balanceOfUnderlyingView() external view returns(uint256);
    function investUnderlying(uint256 _investAmount) external returns (uint256);
    function redeemUnderlying(uint256 _redeemAmount, address _receiver) external returns (uint256);
    function redeemAll() external;
}

pragma solidity 0.6.6;

// Copied from PieDAO smart pools repo. Which is audited

contract Ownable {

    bytes32 constant public oSlot = keccak256("Ownable.storage.location");

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    // Ownable struct
    struct os {
        address owner;
    }

    modifier onlyOwner(){
        require(msg.sender == los().owner, "Ownable.onlyOwner: msg.sender not owner");
        _;
    }

    /**
        @notice Get owner
        @return Address of the owner
    */
    function owner() public view returns(address) {
        return los().owner;
    }

    /**
        @notice Transfer ownership to a new address
        @param _newOwner Address of the new owner
    */
    function transferOwnership(address _newOwner) onlyOwner external {
        _setOwner(_newOwner);
    }

    /**
        @notice Internal method to set the owner
        @param _newOwner Address of the new owner
    */
    function _setOwner(address _newOwner) internal {
        emit OwnerChanged(los().owner, _newOwner);
        los().owner = _newOwner;
    }

    /**
        @notice Load ownable storage
        @return s Storage pointer to the Ownable storage struct
    */
    function los() internal pure returns (os storage s) {
        bytes32 loc = oSlot;
        assembly {
            s_slot := loc
        }
    }

}

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAllocationStrategy.sol";
import "./interfaces/IStrategiesWhitelist.sol";

contract OTokenStorage {

    // DO NOT CHANGE this slot when upgrading [email protected][email protected][email protected]
    bytes32 constant public otSlot = keccak256("OToken.storage.location");

    // O Token Storage ONLY APPEND TO THIS STRUCT WHEN UPGRADING [email protected][email protected][email protected]
    struct ots {
        IAllocationStrategy allocationStrategy;
        IERC20 underlying;
        uint256 fee;
        uint256 lastTotalUnderlying;
        string name;
        string symbol;
        uint8 decimals;
        mapping(address => mapping(address => uint256)) internalAllowances;
        mapping(address => uint256) internalBalanceOf;
        uint256 internalTotalSupply;
        bool initialised;
        address admin;
        address treasury;
        IStrategiesWhitelist strategiesWhitelist;
        // ONLY APPEND TO THIS STRUCT WHEN UPGRADING [email protected][email protected]
    }

    function allocationStrategy() external view returns(address) {
        return address(lots().allocationStrategy);
    }

    function admin() external view returns(address) {
        return lots().admin;
    }

    function treasury() external view returns(address) {
        return lots().treasury;
    }

    function strategiesWhitelist() external view returns(address) {
        return address(lots().strategiesWhitelist);
    }

    function underlying() external view returns(address) {
        return address(lots().underlying);
    }

    function fee() external view returns(uint256) {
        return lots().fee;
    }

    function lastTotalUnderlying() external view returns(uint256) {
        return lots().lastTotalUnderlying;
    }

    function name() external view returns(string memory) {
        return lots().name;
    }

    function symbol() external view returns(string memory) {
        return lots().symbol;
    }

    function decimals() external view returns(uint8) {
        return lots().decimals;
    }

    function internalBalanceOf(address _who) external view returns(uint256) {
        return lots().internalBalanceOf[_who];
    }

    function internalTotalSupply() external view returns(uint256) {
        return lots().internalTotalSupply;
    }

    function lots() internal pure returns(ots storage s) {
        bytes32 loc = otSlot;
        assembly {
            s_slot := loc
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

