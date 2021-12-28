/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT

/**
 * Revoluzion Token
 * Future ecosystem development would include swap/dex system with chart integration,
 * Portfolio viewer, dex buy/sell order and web base Play to Earn NFT game Apocalypse.
 *
 * Website : revoluzion.io
 * Whitepaper : whitepaper.revoluzion.io
 * Facebook :facebook.com/revoluziontoken/
 * Twitter : twitter.com/RevoluzionToken
 * Linkedin : linkedin.com/company/revoluzion-token/
 * GitHub : github.com/RevoluzionToken
 * Telegram : t.me/revoluziontoken
 */


pragma solidity ^0.8.7;



/** LIBRARIES **/


/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * CAUTION
 * This version of SafeMath should only be used with Solidity 0.8 or later,
 * because it relies on the compiler's built in overflow checks.
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


/**
 * @title Context
 * 
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
    
    /** FUNCTION **/

    /**
     * @dev Provide information of current sender.
     */
    function _msgSender() internal view virtual returns (address) {
        /**
         * @dev Returns msg.sender.
         */
        return msg.sender;
    }

    /**
     * @dev Provide information current data.
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        /**
         * @dev Returns msg.data.
         */
        return msg.data;
    }

    /**
     * @dev Provide information current value.
     */
    function _msgValue() internal view virtual returns (uint256) {
        /**
         * @dev Returns msg.value.
         */
        return msg.value;
    }

}




/** IERC20 STANDARD **/

interface IERC20Extended {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/** UNISWAP V2 INTERFACES **/

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}



/** DIAMOND HAND REWARDS DISTRIBUTOR **/

interface IDiamondDistributor {
    function setDiamondCriteria(uint256 _diamondCycle, uint256 _minTokenRequired) external;

    function setEligibility(address holder, bool eligible) external;

    function deposit() external payable;

    function process(uint256 gas) external;
}

contract DiamondDistributor is IDiamondDistributor, Context {


    /* LIBRARY */
    using SafeMath for uint256;


    /* DATA */
    IERC20Extended public rewardToken;
    IUniswapV2Router02 public router;
    address public _token;
    address public _owner;

    struct Diamond {
        bool eligible;
        uint256 eligibleTime;
        uint256 totalRealised;
    }

    bool public initialized;
    uint256 public currentIndex;
    uint256 public diamondCycle;
    uint256 public diamondCycleStart;
    uint256 public diamondCycleEnd;
    uint256 public previousCycleEnd;
    uint256 public minTokenRequired;
    address[] public holders;

    mapping(address => uint256) public holderIndexes;
    mapping(address => uint256) public holderClaims;
    mapping(address => Diamond) public diamonds;
    
    uint256 public totalDiamonds; 
    uint256 public totalDistributed;
    uint256 public diamondsPerHolder;
    uint256 public prevDiamondsPerHolder;
    uint256 public diamondsPerHolderAccuracyFactor;


    /* MODIFIER */
    modifier initializer() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(_msgSender() == _token);
        _;
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner);
        _;
    }

    modifier onlyTokenAndOwner() {
        require(_msgSender() == _token || _msgSender() == _owner);
        _;
    }


    /* CONSTRUCTOR */
    constructor(address rewardToken_, address router_) {
        _token = _msgSender();
        _owner = _msgSender();
        rewardToken = IERC20Extended(rewardToken_);
        router = IUniswapV2Router02(router_);

        diamondsPerHolderAccuracyFactor = 10**36;
        diamondCycle = 6 hours;
        diamondCycleStart = block.timestamp;
        diamondCycleEnd = diamondCycleStart + diamondCycle;
        previousCycleEnd = block.timestamp - 1;
        minTokenRequired = 1000000000000000000;
    }


    /* FUNCTION */

    receive() external payable {}

    function unInitialized(bool initialization) external onlyToken {
        initialized = initialization;
    }

    function resetCycle() external onlyOwner {
        diamondCycleStart = block.timestamp;
        diamondCycleEnd = diamondCycleStart + diamondCycle;
        previousCycleEnd = block.timestamp - 1;
    }

    function setRewardToken(address rewardToken_) external onlyOwner {
        rewardToken = IERC20Extended(rewardToken_);
    }

    function setRouter(address router_) external onlyOwner {
        router = IUniswapV2Router02(router_);
    }

    function setTokenAddress(address token_) external initializer onlyToken {
        _token = token_;
    }

    function setDiamondCriteria(uint256 _diamondCycle, uint256 _minTokenRequired) external override onlyToken {
        diamondCycle = _diamondCycle;
        minTokenRequired = _minTokenRequired;
    }

    function totalDiamondHolders() public view returns (uint256) {
        return holders.length;
    }

    function checkCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Set the address eligibility.
     */
    function setEligibility(address holder, bool eligible) external override onlyToken {
        if (diamonds[holder].eligible == true && diamonds[holder].eligibleTime + diamondCycle <= previousCycleEnd) {
            distributeDiamond(holder);
        }

        if (eligible == true && diamonds[holder].eligible == false) {
            addHolder(holder);
        } else if (eligible == false && diamonds[holder].eligible == true) {
            removeHolder(holder);
        }

        diamonds[holder].eligible = eligible;
    } 

    function process(uint256 gas) external override onlyTokenAndOwner {
        uint256 holderCount = holders.length;

        if (holderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < holderCount) {
            if (currentIndex >= holderCount) {
                currentIndex = 0;
            }

            if (IERC20Extended(_token).balanceOf(holders[currentIndex]) >= minTokenRequired && shouldDistribute(holders[currentIndex])) {
                distributeDiamond(holders[currentIndex]);
            } else if (IERC20Extended(_token).balanceOf(holders[currentIndex]) < minTokenRequired) {
                removeHolder(holders[currentIndex]);
                diamonds[holders[currentIndex]].eligible = false;

                uint256 current = rewardToken.balanceOf(address(this));
                diamondsPerHolder = diamondsPerHolderAccuracyFactor.mul(current).div(holders.length);
            }

            if (block.timestamp > diamondCycleEnd) {
                
                diamondCycleStart = diamondCycleEnd;
                diamondCycleEnd = diamondCycleEnd + diamondCycle;
                previousCycleEnd = diamondCycleStart - 1;

                uint256 current = rewardToken.balanceOf(address(this));
                prevDiamondsPerHolder = diamondsPerHolder;
                diamondsPerHolder = diamondsPerHolderAccuracyFactor.mul(current).div(holders.length);

            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address holder) internal view returns (bool) {
        return 
            holderClaims[holder] < (previousCycleEnd + 1) && 
            diamonds[holder].eligible == true && 
            diamonds[holder].eligibleTime + diamondCycle <= previousCycleEnd;
    }

    function deposit() external payable override onlyTokenAndOwner {
        uint256 balanceBefore = rewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens {
            value: _msgValue()
        } (0, path, address(this), block.timestamp);

        uint256 current = rewardToken.balanceOf(address(this));
        uint256 amount = current.sub(balanceBefore);

        totalDiamonds = totalDiamonds.add(amount);
        diamondsPerHolder = diamondsPerHolderAccuracyFactor.mul(current).div(holders.length);
    }

    /**
     * @dev Distribute diamond to the holders and update diamond information.
     */
    function distributeDiamond(address holder) internal {
        if (diamonds[holder].eligible == false) {
            return;
        }

        uint256 amount = getUnpaidEarnings(holder);

        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            rewardToken.transfer(holder, amount);
            holderClaims[holder] = block.timestamp;
            diamonds[holder].eligibleTime = previousCycleEnd;
            diamonds[holder].totalRealised = diamonds[holder].totalRealised.add(amount);
        }
    }
    
    /**
     * @dev Get the cumulative diamond for the given share.
     */
    function getCumulativeDiamonds() internal returns (uint256) {

        if (block.timestamp > diamondCycleEnd) {
            
            diamondCycleStart = diamondCycleEnd;
            diamondCycleEnd = diamondCycleEnd + diamondCycle;
            previousCycleEnd = diamondCycleStart - 1;

            uint256 current = rewardToken.balanceOf(address(this));
            prevDiamondsPerHolder = diamondsPerHolder;
            diamondsPerHolder = diamondsPerHolderAccuracyFactor.mul(current).div(holders.length);

            return prevDiamondsPerHolder.div(diamondsPerHolderAccuracyFactor);

        } else if (block.timestamp > previousCycleEnd) {
            return prevDiamondsPerHolder.div(diamondsPerHolderAccuracyFactor);
        }

        return diamondsPerHolder.div(diamondsPerHolderAccuracyFactor);
    }
    
    
    /**
     * @dev Get unpaid diamond that needed to be distributed for the given address.
     */
    function getUnpaidEarnings(address holder) internal returns (uint256) {
        if (diamonds[holder].eligible == false) {
            return 0;
        }

        return getCumulativeDiamonds();
    }


    /**
     * @dev Add the address to the array of holders.
     */
    function addHolder(address holder) internal {
        holderIndexes[holder] = holders.length;
        holders.push(holder);
        diamonds[holder].eligibleTime = block.timestamp;
    }

    /**
     * @dev Remove the address from the array of holders.
     */
    function removeHolder(address holder) internal {
        holders[holderIndexes[holder]] = holders[holders.length - 1];
        holderIndexes[holders[holders.length - 1]] = holderIndexes[holder];
        holders.pop();
        diamonds[holder].eligibleTime = block.timestamp;
    }

}