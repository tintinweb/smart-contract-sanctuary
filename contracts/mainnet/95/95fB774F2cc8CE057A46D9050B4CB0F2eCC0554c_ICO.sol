// SPDX-License-Identifier: MIT;

pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

contract ICO is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    struct ICOStateSchema {
        uint256 currentIteration;
        uint256 currentPrice;
        uint256 ICOAllocatedTokensAmount;
        uint256 tokensLeft;
    }

    uint256 public oneIterationTokenAmount = 10 * 10 ** 6 * 10 ** 10;

    bool public icoCompleted;
    uint256 public icoStartTime;
    uint256 public icoEndTime;
    address public tokenAddress;
    uint256 public currentIterationOfICO;
    uint256 public current_allocatedTokens;
    uint256 public minLimit = 1 * 10 ** 10;
    uint256 public maxLimit = 1 * 10 ** 8 * 10 ** 10;
    uint256 private referralBonus = 20;
    uint256 private commission = 8 * 10 ** 15;
    uint256 private maxRoundICO = 200;

    AggregatorV3Interface private priceFeed;
    uint256 public usdPrice;
    uint256 private startPriceInUSD = 5; // since this value is 0.0005 . Multiplying it by 10000
    uint256 private stepPriceInUSD;

    mapping(address => bool) allowedInvestors;

    event Allocated(uint256 amount);
    event WithdrawedETH(address user, uint256 amount);
    event MinLimitUpdated(uint256 newLimit);
    event MaxLimitUpdated(uint256 newLimit);
    event Bought(address buyer, uint256 amount, uint256 usdPrice);

    modifier allowedInvestor {
        require(allowedInvestors[msg.sender], "Your address not allowed. Please contact with owner.");
        _;
    }

    modifier whenIcoStart {
        require(!icoCompleted, 'ICO completed');
        require(icoStartTime != 0, 'ICO has not started yet');
        _;
    }

    constructor(address _tokenAddress, address owner){
        require(_tokenAddress != address(0) && owner != address(0), "Incorrect addresses");
        tokenAddress = _tokenAddress;
        transferOwnership(owner);
        allowedInvestors[owner] = true;
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /// can be accessed only by owner
    function startICO() public onlyOwner {
        require(icoStartTime == 0, "ICO was started before");
        _allocate();
        icoStartTime = block.timestamp;
    }

    /// can be accessed only by owner
    function setMinLimit(uint256 newLimit) public onlyOwner {
        minLimit = newLimit;
        emit MinLimitUpdated(maxLimit);
    }

    /// can be accessed only by owner
    function setMaxLimit(uint256 newLimit) public onlyOwner {
        maxLimit = newLimit;
        emit MaxLimitUpdated(maxLimit);
    }

    /// can be accessed only by owner
    function setReferralBonus(uint256 _bonus) external onlyOwner {
        require(_bonus <= 100, 'Referral bonus should not be more than 100%');
        referralBonus = _bonus;
    }

    /// can be accessed only by owner
    function getReferralBonus() external view returns (uint256) {
        return referralBonus;
    }

    /// can be accessed only by owner
    function setCommission(uint256 _commission) external onlyOwner {
        commission = _commission;
    }

    /// read only
    /// returns uint256
    function getCommission() external view returns (uint256) {
        return commission;
    }

    /// can be accessed only by owner
    function addAddressToAllowed(address client) public onlyOwner {
        allowedInvestors[client] = true;
    }

    /// can be accessed only by owner
    function removeAddressFromAllowed(address client) public onlyOwner {
        allowedInvestors[client] = false;
    }

    function _allocate() private {
        require(currentIterationOfICO <= maxRoundICO, 'Funding cycle ended');
        if (icoStartTime == 0) {
            usdPrice = startPriceInUSD;
        } else if (currentIterationOfICO == 0) {
            oneIterationTokenAmount = 19 * 10 ** 5 * 10 ** 10;
            usdPrice = 10;
            // to have correct order over startPriceInUSD -> Multiplying 0.001 by 10000
            stepPriceInUSD = 1;
            currentIterationOfICO++;
        } else if (currentIterationOfICO > 0 && currentIterationOfICO < 100) {
            usdPrice = usdPrice.add(stepPriceInUSD);
            currentIterationOfICO++;
        } else if (currentIterationOfICO == 100) {
            oneIterationTokenAmount = 8 * 10 ** 6 * 10 ** 10;
            usdPrice = 110;
            // to have correct order over startPriceInUSD -> Multiplying 0.011 by 10000
            stepPriceInUSD = 10;
            currentIterationOfICO++;
        } else if (currentIterationOfICO > 100 && currentIterationOfICO <= maxRoundICO) {
            usdPrice = usdPrice.add(stepPriceInUSD);
            currentIterationOfICO++;
        }
        current_allocatedTokens = current_allocatedTokens.add(oneIterationTokenAmount);
        emit Allocated(current_allocatedTokens);
    }

    receive() external payable {
        buy();
    }

    function _getAmountForETH(uint amountETH) private view returns (uint256){
        (
        ,
        // rate is giving with precision to actual price * 10 ** 8
        int rate,
        ,
        ,
        ) = priceFeed.latestRoundData();
        // So here we have to divide final amount
        uint256 usdAmount = amountETH.mul(uint256(rate)).div(10 ** 8);
        // Since token price is less then 1 - we have to multiply the smallest value to 10 ** 4
        // So on every calculation of price it should be divided into 10 ** 4
        uint256 amountTokens = usdAmount.div(usdPrice).div(10 ** 14).mul(10 ** 10);
        if (amountTokens > current_allocatedTokens) {
            uint256 tokenPrice = usdPrice;
            uint256 current_allocated = current_allocatedTokens;
            uint256 icoRound = currentIterationOfICO;
            amountTokens = 0;
            while (usdAmount > 0) {
                uint256 amount = usdAmount.div(tokenPrice).div(10 ** 4);
                if (amount > current_allocated) {
                    amountTokens = amountTokens.add(current_allocated);
                    uint256 ethForAllocated = getCost(current_allocated);
                    uint256 usdForAllocated = ethForAllocated.mul(uint256(rate)).div(10 ** 8);
                    usdAmount = usdAmount.sub(usdForAllocated);
                    if (currentIterationOfICO < maxRoundICO) {
                        icoRound++;
                    }
                    (uint256 roundPrice, uint256 stepPrice) = getTokenPrice(icoRound);
                    tokenPrice = roundPrice.add(stepPrice);
                    amount = usdAmount.div(tokenPrice).div(10 ** 4);
                    current_allocated = getTokensPerIteration(icoRound);
                } else if (amount <= current_allocated) {
                    amountTokens = amountTokens.add(amount);
                    usdAmount = 0;
                }
            }
        }
        return amountTokens;
    }

    /// get cost is calculating price including switch to different price range
    /// read only
    /// returns uint256
    function getCost(uint amount) public view returns (uint256){
        uint256 usdCost;
        uint256 ethCost;
        int exchangeRate = getLatestPrice();
        if (amount <= current_allocatedTokens) {
            usdCost = amount.mul(usdPrice).div(10 ** 4);
            ethCost = getPriceInETH(usdCost, exchangeRate);
        } else {
            uint256 price = usdPrice;
            uint256 stepPrice;
            uint256 current_allocated = current_allocatedTokens;
            uint256 icoRound = currentIterationOfICO;
            uint256 iterationAmount;
            while (amount > 0) {
                if (current_allocated > 0) {
                    amount = amount.sub(current_allocated);
                    usdCost = current_allocated.div(10 ** 4).mul(price).add(usdCost);
                    current_allocated = 0;
                    icoRound++;
                    (price, stepPrice) = getTokenPrice(icoRound);
                    price = price.add(stepPrice);
                }
                // get amounts for the next round since it could be different
                iterationAmount = getTokensPerIteration(icoRound);
                if (amount > iterationAmount) {
                    amount = amount.sub(iterationAmount);
                    usdCost = iterationAmount.div(10 ** 4).mul(price).add(usdCost);
                    icoRound++;
                    (price, stepPrice) = getTokenPrice(icoRound);
                    price = price.add(stepPrice);
                }
                iterationAmount = getTokensPerIteration(icoRound);
                if (amount <= getTokensPerIteration(icoRound)) {
                    usdCost = amount.div(10 ** 4).mul(price).add(usdCost);
                    amount = 0;
                }
            }
            ethCost = getPriceInETH(usdCost, exchangeRate);
        }
        return ethCost;
    }

    function _changeCurrentAllocatedTokens(uint256 amount, uint256 ethForTokens) private {
        if (amount <= current_allocatedTokens) {
            current_allocatedTokens = current_allocatedTokens.sub(amount);
        } else {
            uint256 amountForLoop = amount;
            while (amountForLoop > 0) {
                if (amountForLoop > current_allocatedTokens) {
                    amountForLoop = amountForLoop.sub(current_allocatedTokens);
                    uint256 ethForStep = getCost(current_allocatedTokens);
                    ethForTokens = ethForTokens.sub(ethForStep);
                    current_allocatedTokens = 0;
                    _allocate();
                    amountForLoop = _getAmountForETH(ethForTokens);
                } else if (amountForLoop <= current_allocatedTokens) {
                    current_allocatedTokens = current_allocatedTokens.sub(amountForLoop);
                    amountForLoop = 0;
                }
            }
        }
    }

    function _completeICO() private {
        if (current_allocatedTokens < minLimit && currentIterationOfICO >= maxRoundICO) {
            icoEndTime = block.timestamp;
            icoCompleted = true;
        } else if (current_allocatedTokens == 0) {
            _allocate();
        }
    }

    function _sendTokens(address client, uint256 amountToken) private nonReentrant {
        IERC20(tokenAddress).transfer(client, amountToken);
        emit Bought(client, amountToken, usdPrice);
    }

    function withdrawReward() public nonReentrant onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, 'Not enough reward for withdraw');
        (bool success,) = address(msg.sender).call{value : amount}("");
        require(success, 'Transfer failed');
        emit WithdrawedETH(msg.sender, amount);
    }

    /// read only
    /// returns ICOStateSchema
    function getCurrentICOState() public view returns (ICOStateSchema memory currentState) {
        require(icoStartTime != 0, 'ICO was not started can not _allocate new tokens');
        currentState.currentIteration = currentIterationOfICO;
        currentState.currentPrice = usdPrice;
        currentState.ICOAllocatedTokensAmount = oneIterationTokenAmount;
        currentState.tokensLeft = current_allocatedTokens;
    }

    /// available only after start of ICO
    /// accessible only by allowed investors
    /// payable
    /// returns uint256
    function buy() public payable whenIcoStart allowedInvestor {
        require(msg.value > commission, 'Amount of ETH smaller than commission');
        uint256 ethForTokens = msg.value.sub(commission);
        uint256 amount = _getAmountForETH(ethForTokens);
        require(amount >= minLimit, 'Amount for one purchase is too low');
        require(amount <= maxLimit, 'Limit for one purchase is reached');
        _changeCurrentAllocatedTokens(amount, ethForTokens);
        _sendTokens(msg.sender, amount);
        _completeICO();
    }

    /// payable
    /// accessible only by allowed investors
    function buyWithReferral(address payable referral) external payable
    allowedInvestor whenIcoStart {
        require(referral != address(0), 'Referral address should not be empty');
        require(referral != msg.sender, 'Referral address should not be equal buyer address');
        require(msg.value > commission, 'Amount of ETH smaller than commission');
        uint256 bonusAmount = (msg.value.sub(commission)).mul(referralBonus).div(100);
        buy();
        (bool success,) = referral.call{value : bonusAmount}("");
        require(success);
    }

    /// available only after start of ICO
    /// payable
    /// can be accessed only by owner
    function buyFor(address buyer) public payable onlyOwner whenIcoStart {
        uint256 amount = _getAmountForETH(msg.value);
        require(amount >= minLimit, 'Amount for one purchase is too low');
        require(amount <= maxLimit, 'Limit for one purchase is reached');
        require(buyer != address(0), 'Buyer address should not be empty');
        _changeCurrentAllocatedTokens(amount, msg.value);
        IERC20(tokenAddress).transfer(buyer, amount);
        emit Bought(buyer, amount, usdPrice);
        _completeICO();
    }

    /// available only after start of ICO
    /// payable
    /// can be accessed only by owner
    function buyForWithReferral(address buyer, address payable referral) external payable
    onlyOwner whenIcoStart {
        require(referral != address(0), 'Referral address should not be empty');
        require(referral != msg.sender, 'Referral address should not be equal buyer address');
        require(referral != buyer, 'Referral address should not be equal buyer address');
        uint256 bonusAmount = (msg.value).mul(referralBonus).div(100);
        buyFor(buyer);
        (bool success,) = referral.call{value : bonusAmount}("");
        require(success);
    }

    /// read only
    /// returns int
    function getLatestPrice() public view returns (int) {
        (
        ,
        int price,
        ,
        ,
        ) = priceFeed.latestRoundData();
        return 1 ether / (price / (10 ** 8));
    }

    /// returns uint256
    function getPriceInETH(uint256 amount, int exchangeRate) public pure returns (uint256) {
        return amount.mul(uint256(exchangeRate)).div(10 ** 10);
    }

    /// read only
    /// returns uint256
    function getTokenPrice(uint256 icoIteration) public view returns (uint256, uint256) {
        require(icoIteration <= maxRoundICO, 'Incorrect ICO round');
        uint256 price;
        uint256 stepPrice;
        if (icoIteration == 0) {
            price = startPriceInUSD;
        } else if (icoIteration == 1) {
            price = 10;
            stepPrice = 0;
        } else if (icoIteration > 1 && icoIteration <= 100) {
            price = 10;
            stepPrice = icoIteration.sub(1);
        } else if (icoIteration == 101) {
            price = 110;
            stepPrice = 0;
        } else {
            price = 110;
            stepPrice = icoIteration.sub(101).mul(10);
        }
        return (price, stepPrice);
    }

    /// read only
    /// returns uint256
    function getTokensPerIteration(uint256 icoIteration) public view returns (uint256) {
        require(icoIteration <= maxRoundICO, 'Incorrect ICO round');
        uint256 amount;
        if (icoIteration == 0) {
            amount = 10 * 10 ** 6 * 10 ** 10;
        } else if (icoIteration > 0 && icoIteration <= 100) {
            amount = 19 * 10 ** 5 * 10 ** 10;
        } else {
            amount = 8 * 10 ** 6 * 10 ** 10;
        }
        return amount;
    }
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor () {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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