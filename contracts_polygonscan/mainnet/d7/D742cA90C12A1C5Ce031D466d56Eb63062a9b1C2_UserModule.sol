pragma solidity ^0.8.0;


import "../common/variables.sol";
import "./events.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ERC20Interface is IERC20 {
    function decimals() external view returns (uint8);
    function mint(address to_, uint256 amount_) external;
    function burn(address _from, uint256 amount_) external;
}


contract Internals is Variables, Events {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    /**
    * @dev withdraws token and redeems itoken.
    * @param token_ address of token.
    * @param amount_ amount of token.
    * @param itokenAmount_ itoken amount of token.
    */
    function withdrawInternal(address token_, uint amount_, uint itokenAmount_) internal returns (uint supplyExchangePrice_) {
        ERC20Interface itokenContract = ERC20Interface(_itokens[token_]);
        uint userBal_ = itokenContract.balanceOf(msg.sender);
        require(itokenAmount_ <= userBal_, "not-enough-user-balance");
        itokenContract.burn(msg.sender, itokenAmount_);
        (,, supplyExchangePrice_,) = liquidity.withdraw(token_, amount_);
        IERC20(token_).safeTransfer(msg.sender, amount_);
    }

    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

}


contract UserModule is Internals {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
    * @dev calls updateExchangePrice, updateUserReward internally
    * @param token_ address of token.
    * @return supplyExchangePrice_ new supply exchange price.
    */
    function commonUpdates(address token_) internal returns(uint supplyExchangePrice_) {
        require(_tokenEnabled[token_], "M2::common-updates-failed");
        (supplyExchangePrice_,) = liquidity.updateInterest(token_);
        updateUserReward(msg.sender, token_);
    }

    /**
    * @dev updates reward for a particular token.
    * @param token_ address of token.
    * @return newRewardPrices_ array of new exchange prices.
    */
    function updateRewards(address token_) public returns (uint[] memory newRewardPrices_) {
        address[] memory rewardTokens_ = _rewardTokens[token_];
        newRewardPrices_ = new uint[](rewardTokens_.length);
        uint itokenTotalSupply_ = IERC20(_itokens[token_]).totalSupply();
        for (uint i = 0; i < rewardTokens_.length; i++) {
            uint rewardRate_ = _rewardRate[token_][rewardTokens_[i]];
            RewardPrice memory rewardPrice_ = _rewardPrice[token_][rewardTokens_[i]];
            if (rewardPrice_.lastUpdateTime != block.timestamp) {
                // multiplying with 1e27 to get decimal precision otherwise the number could get 0. To calculate users reward divide by 1e27 in the end.
                newRewardPrices_[i] = itokenTotalSupply_ == 0 ? rewardPrice_.rewardPrice :
                    rewardPrice_.rewardPrice.add(rewardRate_.mul(block.timestamp.sub(rewardPrice_.lastUpdateTime)).mul(1e27).div(itokenTotalSupply_));
                _rewardPrice[token_][rewardTokens_[i]] = RewardPrice(newRewardPrices_[i], block.timestamp);
            }
            emit updateRewardsLog(token_, rewardTokens_, newRewardPrices_);
        }
    }

    /**
    * @dev updates reward for user.
    * @param user_ address of user.
    * @param token_ address of token.
    * @return updatedRewards_ updated rewards for all the reward tokens for user.
    */
    function updateUserReward(address user_, address token_) public returns (uint[] memory updatedRewards_) {
        address[] memory rewardTokens_ = _rewardTokens[token_];
        updatedRewards_ = new uint[](rewardTokens_.length);
        uint[] memory newRewardPrices_ = updateRewards(token_);
        uint userItokenBal_ = IERC20(_itokens[token_]).balanceOf(user_);
        for (uint i = 0; i < rewardTokens_.length; i++) {
            UserReward memory userRewards_ = _userRewards[user_][token_][rewardTokens_[i]];
            if (newRewardPrices_[i] > userRewards_.lastRewardPrice) {
                // dividing by 1e27 to get proper reward as we multiplied it with 1e27 at the time of setting price
                updatedRewards_[i] = userRewards_.reward.add(newRewardPrices_[i].sub(userRewards_.lastRewardPrice).mul(userItokenBal_).div(1e27));
                _userRewards[user_][token_][rewardTokens_[i]] = UserReward(newRewardPrices_[i], updatedRewards_[i]);
            }
        }
        emit updateUserRewardLog(user_, token_, rewardTokens_, updatedRewards_);
    }

    /**
    * @dev supply token from user's address and mints itoken to user's address.
    * @param token_ address of token.
    * @param amount_ amount of token.
    * @return itokenAmount_ amount of itoken minted.
    */
    function supply(address token_, uint amount_) external nonReentrant returns (uint itokenAmount_) {
        IERC20 tokenContract_ = IERC20(token_);
        tokenContract_.safeTransferFrom(msg.sender, address(this), amount_);
        tokenContract_.safeApprove(address(liquidity), amount_);
        (,, uint supplyExchangePrice_,) = liquidity.supply(token_, amount_);
        // updateSupplyRate(token_, supplyRate_);
        // multiplying with 18 decimal as exchange price is in 18 decimals
        itokenAmount_ = amount_.mul(1e18).div(supplyExchangePrice_);
        ERC20Interface(_itokens[token_]).mint(msg.sender, itokenAmount_);

        emit supplyLog(token_, amount_, itokenAmount_);
    }

    /**
    * @dev withdraw token to user's address and redeems itoken from user's address.
    * @param token_ address of token.
    * @param amount_ amount of token.
    * @return itokenAmount_ amount of itoken redeemed.
    */
    function withdraw(address token_, uint amount_) external nonReentrant returns (uint itokenAmount_) {
        require(amount_ != 0, "amount-cannot-be-0");
        uint supplyExchangePrice_ = commonUpdates(token_);
        // multiplying with 18 decimal as exchange price is in 18 decimals
        itokenAmount_ = amount_.mul(1e18).div(supplyExchangePrice_);
        withdrawInternal(token_, amount_, itokenAmount_);

        emit withdrawLog(token_, amount_, itokenAmount_);
    }

    /**
    * @dev withdraw token to user's address and redeems itoken from user's address.
    * @param token_ address of token.
    * @param itokenAmount_ amount of itoken redeemed.
    * @return amount_ amount of token returned to user.
    */
    function withdrawItoken(address token_, uint itokenAmount_) external nonReentrant returns (uint amount_) {
        require(itokenAmount_ != 0, "itoken-amount-cannot-be-0");
        uint supplyExchangePrice_ = commonUpdates(token_);
        // dividing by 18 decimal as exchange price is in 18 decimals
        amount_ = itokenAmount_.mul(supplyExchangePrice_).div(1e18);
        withdrawInternal(token_, amount_, itokenAmount_);

        emit withdrawItokenLog(token_, amount_, itokenAmount_);
    }

    /**
    * @dev claim rewards.
    * @param user_ address of user.
    * @param token_ address of token.
    * @return updatedRewards_ amount of reward token sent to user.
    */
    function claim(address user_, address token_) external nonReentrant returns (uint[] memory updatedRewards_) {
        address[] memory rewardTokens_ = _rewardTokens[token_];
        updatedRewards_ = updateUserReward(user_, token_);
        for (uint i = 0; i < rewardTokens_.length; i++) {
            _userRewards[user_][token_][rewardTokens_[i]].reward = 0;
            IERC20(rewardTokens_[i]).safeTransfer(user_, updatedRewards_[i]);
        }

        emit claimLog(user_, token_, rewardTokens_, updatedRewards_);
    }

    /**
    * @dev updates rewards on itoken transfer. itoken contract can only call this function.
    * @param from_ address from which tokens are being transferred.
    * @param to_ address to which tokens are being transferred.
    */
    function updateRewardsOnTransfer(address from_, address to_) external {
        address token_ = _tokens[msg.sender];
        require(token_ != address(0), "not-itoken-contract"); // TODO: Need to update the address here
        uint[] memory fromUpdatedRewards_ = updateUserReward(from_, token_);
        uint[] memory toUpdatedRewards_ = updateUserReward(to_, token_);

        emit updateRewardsOnTransferLog(from_, to_, fromUpdatedRewards_, toUpdatedRewards_);
    }

}

pragma solidity ^0.8.0;


import "../../common/ILiquidity.sol";

contract Variables {

    // status for re-entrancy. 1 = allow/non-entered, 2 = disallow/entered
    uint256 internal _status;

    ILiquidity constant internal liquidity = ILiquidity(address(0xb5C272b5D0D0E3Bd3f20f32d3836e7Ce4e9Cfbdf)); // TODO: add the core liquidity address

    // tokens enabled to supply in
    mapping (address => bool) internal _tokenEnabled;

    // array of all the tokens enabled
    address[] internal _markets;

    // token to itoken mapping (itoken are similar to ctokens)
    mapping (address => address) internal _itokens;

    // itoken to token mapping (itoken are similar to ctokens)
    mapping (address => address) internal _tokens;

    struct RewardPrice {
        uint256 rewardPrice; // rewards per itoken from start. Keeping it 256 bit as we're multiplying with 1e27 for proper decimal calculation
        uint256 lastUpdateTime; // in sec
    }

    struct UserReward {
        uint256 lastRewardPrice; // last updated reward price for this user. Keeping it 256 bit as we're multiplying with 1e27 for proper decimal calculation
        uint256 reward; // rewards available for claiming for user
    }

    // token => reward tokens. One token can have multiple rewards going on.
    mapping (address => address[]) internal _rewardTokens;

    // token => reward token => reward rate per sec
    mapping (address => mapping (address => uint)) internal _rewardRate;

    // rewards per itoken current. _rewardPrice = _rewardPrice + (_rewardRate * timeElapsed) / total itoken
    // multiplying with 1e27 to get decimal precision otherwise the number could get 0. To calculate users reward divide by 1e27 in the end.
    // token => reward token => reward price
    mapping (address => mapping (address => RewardPrice)) internal _rewardPrice; // starts from 0 & increase overtime.

    // last reward price stored for a user. Multiplying (current - last) * user_itoken will give users new rewards earned
    // user => token => reward token => reward amount
    mapping (address => mapping (address => mapping (address => UserReward))) internal _userRewards;

}

pragma solidity ^0.8.0;


contract Events {

    event updateRewardsLog(address indexed token_, address[] rewardTokens_, uint[] newRewardPrices_);

    event updateUserRewardLog(address indexed user_, address indexed token_, address[] rewardTokens_, uint[] updatedRewards_);

    event supplyLog(address indexed token_, uint amount_, uint itokenAmount_);

    event withdrawLog(address indexed token_, uint amount_, uint itokenAmount_);

    event withdrawItokenLog(address indexed token_, uint amount_, uint itokenAmount_);

    event claimLog(address indexed user_, address indexed token_, address[] rewardTokens_, uint[] rewards_);

    event updateRewardsOnTransferLog(address indexed from_, address indexed to_, uint[] fromRewards_, uint[] toRewards_);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.0;


interface ILiquidity {

    function supply(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function withdraw(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function borrow(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function payback(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function updateInterest(
        address token_
    ) external view returns (
        uint newSupplyExchangePrice,
        uint newBorrowExchangePrice
    );

    function isProtocol(address protocol_) external view returns (bool);

    function protocolSupplyLimit(address protocol_, address token_) external view returns (uint256);

    function protocolBorrowLimit(address protocol_, address token_) external view returns (uint256);

    function rawSupply(address token_) external view returns (uint256);

    function rawBorrow(address token_) external view returns (uint256);

    function protocolRawSupply(address protocol_, address token_) external view returns (uint256);

    function protocolRawBorrow(address protocol_, address token_) external view returns (uint256);

    struct Rates {
        uint96 lastSupplyExchangePrice; // last stored exchange price. Increases overtime.
        uint96 lastBorrowExchangePrice; // last stored exchange price. Increases overtime.
        uint48 lastUpdateTime; // in sec
        uint16 utilization; // utilization. 10000 = 100%
    }

    function rate(address token_) external view returns (Rates memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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