pragma solidity ^ 0.8.4;

import "./IBankEth.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router.sol";

contract BankEthStaking is Ownable, ReentrancyGuard {
    uint256 constant REWARD_MAG = 10000;

    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    event BankEthStaked(address staker, uint256 amount, uint256 duration);

    event ReflectionsClaimed(address staker, uint256 amount);
    event StakingReleased(address staker, uint256 amount);

    struct Stake {
        uint256 nonce;
        address staker;
        address pool;
        uint256 contribution;
        uint256 bonus;
        uint256 end;
        bool released;
    }

    struct Tier {
        uint256 daysToStake;
        uint256 rewardRate;
        bool active;
    }

    uint256 constant internal magnitude = 2 ** 128;
    uint256 internal magnifiedDividendPerShare;
    mapping(address => int256)internal magnifiedDividendCorrections;
    mapping(address => uint256)internal withdrawnDividends;
    uint256 public totalDividendsDistributed;
    uint256 public totalDividendBalance;
    mapping(address => uint256) private dividendBalances;

    uint256 stakeNonce = 1;

    mapping(address => uint256[]) userStakes;
    mapping(uint256 => Stake) stakes;

    uint256[] tiers;
    mapping(uint256 => Tier) rewardRates;

    IBankEth public bankEth;
    IUniswapV2Router02 public uniswapV2Router;

    constructor() {
        bankEth = IBankEth(0xBE0C826f17680d8Da620855bE89DD6544C034cA1);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
    }

    function addStakingTokens(uint256 tokenAmount) external onlyOwner {
        require(bankEth.balanceOf(msg.sender) >= tokenAmount, "BankEthStaking: Insufficient BankEth Balance");
        bankEth.transferFrom(msg.sender, address(this), tokenAmount);
        incrementBalance(owner(), tokenAmount);
    }

    function removeStakingTokens(uint256 tokenAmount) external onlyOwner {
        require(dividendBalanceOf(msg.sender) >= tokenAmount, "BankEthStaking: Insufficient BankEth Balance");
        bankEth.transfer(msg.sender, tokenAmount);
        decrementBalance(msg.sender, tokenAmount);
    }

    function addTier(uint256 daysToStake, uint256 rate) external onlyOwner {
        require(!rewardRates[daysToStake].active, "BankEthStaking: Tier is already populated");
        Tier memory tier = Tier(daysToStake, rate, true);
        tiers.push(daysToStake);
        rewardRates[daysToStake] = tier;
    }

    function removeTier(uint256 daysToStake) external onlyOwner {
        require(rewardRates[daysToStake].active, "BankEthStaking: Tier is not populated");
        rewardRates[daysToStake].active = false;

        for (uint256 i = 0; i < tiers.length; i++) {
            if (tiers[i] == daysToStake) {
                tiers[i] = tiers[tiers.length - 1];
                tiers.pop();
                break;
            }
        }
    }

    function getTiers() external view returns(Tier[] memory _tiers) {
        _tiers = new Tier[](tiers.length);
        for (uint256 i = 0; i < tiers.length; i++) {
            _tiers[i] = rewardRates[tiers[i]];
        }
    }

    function stakeForEth(uint256 tokenAmount, uint256 _days) public {
        require(bankEth.balanceOf(msg.sender) >= tokenAmount, "BankEthStaking: Insufficient BankEth Balance");
        require(rewardRates[_days].active, "BankEthStaking: Tier is not populated");
        bankEth.transferFrom(msg.sender, address(this), tokenAmount);

        uint256 bonus = calculateBonus(tokenAmount, _days);
        uint256 totalStake = tokenAmount.add(bonus);
        uint256 releaseTime = block.timestamp.add(_days.mul(1 days));

        Stake memory newStake = Stake(
            stakeNonce,
            msg.sender,
            address(0),
            tokenAmount,
            bonus,
            releaseTime,
            false
        );

        userStakes[msg.sender].push(stakeNonce);
        stakes[stakeNonce] = newStake;
        incrementBalance(msg.sender, totalStake);
        decrementBalance(owner(), bonus);
        stakeNonce = stakeNonce.add(1);
    }

    function releaseEthStake(uint256 _stakeNonce) public nonReentrant {
        Stake memory stakeInfo = stakes[_stakeNonce];
        require(stakeInfo.staker == msg.sender, "BankEthStaking: Caller is not the staker");
        require(block.timestamp > stakeInfo.end, "BankEthStaking: Stake is not releasable");
        require(!stakeInfo.released, "BankEthStaking: Staking is already released");
        receiveRewards();

        uint256 totalStake = stakeInfo.bonus.add(stakeInfo.contribution);
        decrementBalance(msg.sender, totalStake);
        incrementBalance(owner(), stakeInfo.bonus);
        bankEth.transfer(msg.sender, stakeInfo.contribution);
        stakeInfo.released = true;
    }

    function userStakingInfo(address account)public view returns(Stake[] memory _stakes) {
        uint256[] storage userStakeNonces = userStakes[account];
        _stakes = new Stake[](userStakeNonces.length);
        for (uint i = 0; i < userStakeNonces.length; i ++) {
            uint256 _stakeNonce = userStakeNonces[i];
            Stake storage stake = stakes[_stakeNonce];
            _stakes[i] = stake;
        }
        return _stakes;
    }

    function calculateBonus(uint256 tokenAmount, uint256 _days) public view returns(uint256) {
        uint256 rate = rewardRates[_days].rewardRate;
        return tokenAmount.mul(rate).div(REWARD_MAG);
    }

    function distributeDividends()public payable {
        require(totalDividendBalance > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalDividendBalance);
            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }
    
    function withdrawDividend(bool reinvest, uint256 minTokens) external {
        _withdrawDividend(msg.sender, reinvest, minTokens);
    }

    function _withdrawDividend(address account, bool reinvest, uint256 minTokens) internal {
        receiveRewards();

        if (reinvest) {
            withdrawTokens(account, minTokens);
        } else {
            withdrawEth(account);
        }
    }

    function withdrawEth(address account) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if (_withdrawableDividend > 0) {

            withdrawnDividends[account] = withdrawnDividends[account].add(_withdrawableDividend);
            //   emit DividendWithdrawn(user, _withdrawableDividend, to);
            (bool success,) = account.call{value: _withdrawableDividend}("");
            if(!success) {
                withdrawnDividends[account] = withdrawnDividends[account].sub(_withdrawableDividend);
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function withdrawTokens(address account, uint256 minTokens) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if (_withdrawableDividend > 0) {
            swapEthForTokens(_withdrawableDividend, minTokens, account);
            return _withdrawableDividend;
        }
        return 0;
    }

    function swapEthForTokens(uint256 ethAmount, uint256 minTokens, address account) internal returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(bankEth);
        
        uint256 balanceBefore = bankEth.balanceOf(account);
        
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            minTokens,
            path,
            account,
            block.timestamp
        );
        
        uint256 tokenAmount = bankEth.balanceOf(account).sub(balanceBefore);
        return tokenAmount;
    }
    
    function dividendOf(address _owner) public view returns(uint256) {
        return withdrawableDividendOf(_owner);
    }
    
    function withdrawableDividendOf(address _owner) public view returns(uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view returns(uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns(uint256) {
        return magnifiedDividendPerShare.mul(dividendBalanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    function dividendBalanceOf(address account) public view virtual returns (uint256) {
        return dividendBalances[account];
    }

    function incrementBalance(address staker, uint256 tokenAmount) internal {
        totalDividendBalance = totalDividendBalance.add(tokenAmount);
        dividendBalances[staker] = dividendBalances[staker].add(tokenAmount);
        magnifiedDividendCorrections[staker] = magnifiedDividendCorrections[staker]
        .sub( (magnifiedDividendPerShare.mul(tokenAmount)).toInt256Safe() );
    }

    function decrementBalance(address staker, uint256 tokenAmount) internal {
        dividendBalances[staker] = dividendBalances[staker].sub(tokenAmount);
        totalDividendBalance = totalDividendBalance.sub(tokenAmount);
        magnifiedDividendCorrections[staker] = magnifiedDividendCorrections[staker]
        .add((magnifiedDividendPerShare.mul(tokenAmount)).toInt256Safe() );
    }

    function receiveRewards() internal {
        if (bankEth.withdrawableDividendOf(address(this)) > 0) {
            bankEth.claim(false, 0);
        }
    }

    function userInfo(address account) public view returns(uint256 withdrawableDividend, uint256 withdrawnDividend, uint256 currentStake) {
        withdrawableDividend = withdrawableDividendOf(account);
        withdrawnDividend = withdrawnDividendOf(account);
        currentStake = dividendBalanceOf(account);
    }

    function pendingDividends(address account) public view returns(uint256) {
        uint256 withdrawable = bankEth.withdrawableDividendOf(address(this));
        uint256 _magnifiedDividendPerShare = magnifiedDividendPerShare;

        if (withdrawable > 0) {
            _magnifiedDividendPerShare = _magnifiedDividendPerShare.add((withdrawable).mul(magnitude) / totalDividendBalance);
        } 
        
        uint256 accumulate = _magnifiedDividendPerShare.mul(dividendBalanceOf(account)).toInt256Safe()
        .add(magnifiedDividendCorrections[account]).toUint256Safe() / magnitude;

        return accumulate.sub(withdrawnDividends[account]);
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner nonReentrant {
        address prevOwner = owner();
        super.transferOwnership(newOwner);
        receiveRewards();
        withdrawEth(prevOwner);
        uint256 tokenAmount = dividendBalanceOf(prevOwner);
        decrementBalance(prevOwner, tokenAmount);
        incrementBalance(newOwner, tokenAmount);
    }

    receive()external payable {
        distributeDividends();
    }
}

import "./IERC20.sol";

interface IBankEth is IERC20 {

    function dividendTracker() external returns(address);
  	
    function uniswapV2Pair() external returns(address);

  	function setTradingStartTime(uint256 newStartTime) external;
  	
    function updateDividendTracker(address newAddress) external;

    function updateUniswapV2Router(address newAddress) external;

    function excludeFromFees(address account, bool excluded) external;

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external;

    function setAutomatedMarketMakerPair(address pair, bool value) external;
    
    function excludeFromDailyLimit(address account, bool excluded) external;

    function allowPreTrading(address account, bool allowed) external;

    function setMaxPurchaseEnabled(bool enabled) external;

    function setMaxPurchaseAmount(uint256 newAmount) external;

    function updateDevAddress(address payable newAddress) external;

    function getTotalDividendsDistributed() external view returns (uint256);

    function isExcludedFromFees(address account) external view returns(bool);

    function withdrawableDividendOf(address account) external view returns(uint256);

	function dividendTokenBalanceOf(address account) external view returns (uint256);

    function reinvestInactive(address payable account) external;

    function claim(bool reinvest, uint256 minTokens) external;
        
    function getNumberOfDividendTokenHolders() external view returns(uint256);
    
    function getAccount(address _account) external view returns (
        uint256 withdrawableDividends,
        uint256 withdrawnDividends,
        uint256 balance
    );
    
    function assignAntiBot(address _address) external;
    
    function toggleAntiBot() external;
}

pragma solidity ^ 0.8.4;

// SPDX-License-Identifier: MIT License

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
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

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.4;

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

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.4;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

// SPDX-License-Identifier: MIT

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^ 0.8.4;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

pragma solidity ^0.8.4;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.4;

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

pragma solidity ^ 0.8.4;

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