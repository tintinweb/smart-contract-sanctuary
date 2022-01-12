/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

pragma solidity 0.7.6;

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

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

// File: contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

pragma solidity 0.7.6;

contract MarginTrading {
    using SafeMath for uint256;

    struct Position {
        address asset;
        uint256 assetAmount;
        uint256 loanAmount;
        address targetAsset;
        uint256 targetAmount;
        uint256 interestAfterClose;
        uint256 timestamp;
    }

    struct Deposit {
        address asset;
        uint256 assetAmount;
        uint256 leverage;
        uint256 interestAccumulated;
        uint256 timestamp;
    }

    // Starting position
    uint256 positionID = 1;
    // Interest per block
    uint256 interestPerBlock = 2E18;
    // handles trade position
    mapping(address => mapping(uint256 => Position)) public positionIDs;
    // Handles users deposits
    mapping(address => mapping(address => Deposit)) public deposits;
    // Handles array of position id
    mapping(address => uint256[]) public usersPosition;
    // User balance
    mapping(address => mapping(address => uint256)) public userbalances;
    // Event for deposit
    event DepositEvent(address User, address Token, uint256 Amount, uint256 Timestamp);
    // Event to close position 
    event closeTrade(uint256 positionID);

    IUniswapV2Router02 public uniswapV2Router;
    
    constructor () {
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x8954AfA98594b838bda56FE4C12a09D7739D179b);
         uniswapV2Router = _uniswapV2Router;
    }

    receive() external payable{}

    function deposit(address tokenAddress, uint256 amount, uint256 leverage) external payable {
        require(amount > 0 || msg.value > 0, "Deposit call : Null Amount");
        if(tokenAddress == address(0)) 
            amount = msg.value;
        else
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);    
        deposits[msg.sender][tokenAddress] = Deposit({
            asset: tokenAddress,
            assetAmount: amount,
            leverage: leverage,
            interestAccumulated: 0,
            timestamp: block.number
        });
        userbalances[msg.sender][tokenAddress] = userbalances[msg.sender][tokenAddress].add(amount);
        emit DepositEvent(msg.sender, tokenAddress, amount, block.timestamp);
    }

    function createPositionandTrade(address tokenAddress, address targetToken, uint256 amount) external {
        require(deposits[msg.sender][tokenAddress].assetAmount >= amount, "Create Position call : Insufficient Deposit");
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = targetToken;
        if(tokenAddress == address(0)) 
            path[0] = uniswapV2Router.WETH();

        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(path[0], path[1]);
        require(pair != address(0), "Create Position call :Invalid Pair");
        uint256 allotedAmount = amount.mul(deposits[msg.sender][tokenAddress].leverage);
        if(tokenAddress == address(0))
            require(address(this).balance >= allotedAmount.sub(amount), "Create position call : Insufficient payable Balance");
        else 
            require(IERC20(tokenAddress).balanceOf(address(this)) >= allotedAmount.sub(amount), "Create position call : Insufficient Token Balance");   

        uint256 _result = trade(allotedAmount, path);    

        positionIDs[msg.sender][positionID] = Position({
            asset: tokenAddress,
            assetAmount: amount,
            loanAmount: allotedAmount.sub(amount),
            targetAsset: targetToken,
            targetAmount: _result,
            timestamp: block.number,
            interestAfterClose: 0
        }); 
        userbalances[msg.sender][targetToken] = userbalances[msg.sender][targetToken].add(_result);
        userbalances[msg.sender][tokenAddress] = userbalances[msg.sender][tokenAddress].sub(amount);
        deposits[msg.sender][tokenAddress].assetAmount =  deposits[msg.sender][tokenAddress].assetAmount.sub(amount);
        usersPosition[msg.sender].push(positionID);
        positionID++;
    }

    function trade(uint256 allotedAmount, address[] memory path) internal returns(uint256) {
        uint256[] memory result = new uint256[](2);
        uint deadline = block.timestamp + 100;
        if(path[0] == uniswapV2Router.WETH()) {
            // Trade and get asset out
            result = uniswapV2Router.swapExactETHForTokens{value: allotedAmount}(0, path, address(this), deadline);
        }
        else if(path[1] == uniswapV2Router.WETH()){
            // Approve token in
            IERC20(path[0]).approve(address(uniswapV2Router), allotedAmount); 
            // Trade and get asset out    
            result = uniswapV2Router.swapExactTokensForETH(allotedAmount, 0, path, address(this), deadline);
        }
        else {
            // Approve token in
            IERC20(path[0]).approve(address(uniswapV2Router), allotedAmount);
            // Trade and get asset out
            result = uniswapV2Router.swapExactTokensForTokens(allotedAmount, 0, path, address(this), deadline);
        }
        return result[1];
    }

    function closePosition(uint256 _positionID) external payable{
        Position storage positionInfo = positionIDs[msg.sender][_positionID];
        uint256 held = block.number.sub(positionInfo.timestamp); 
        uint interest = positionInfo.loanAmount.mul(held.mul(interestPerBlock).div(100)).div(1E18);
        positionInfo.interestAfterClose = interest;
        if(positionInfo.asset == address(0)) 
            require(msg.value >= interest);
        else
            IERC20(positionInfo.asset).transferFrom(msg.sender, address(this), interest);
        if(positionInfo.targetAsset == uniswapV2Router.WETH())
            msg.sender.transfer(positionInfo.targetAmount);
        else    
            IERC20(positionInfo.targetAsset).transfer(msg.sender, positionInfo.targetAmount);
        
        userbalances[msg.sender][positionInfo.targetAsset] = userbalances[msg.sender][positionInfo.targetAsset].add(positionInfo.targetAmount);        
        emit closeTrade(_positionID);
    }

    function withdraw(address tokenAddress, uint256 amount) external payable {
        uint256 withdrawAmount = amount;
        require(deposits[msg.sender][tokenAddress].assetAmount >= amount, "Withdraw call : Insufficient Deposit");
        if(tokenAddress == address(0)) {
            uint256 interest = checkInterestAccumulated(address(0));
            if(interest>0) {
                if(withdrawAmount>interest) {
                    withdrawAmount = withdrawAmount - interest;
                }
                else {
                    require(msg.value + withdrawAmount >= interest,"You have to pay more");  
                    withdrawAmount = withdrawAmount + msg.value - interest;
                }
            }
            if(withdrawAmount>0)
            msg.sender.transfer(withdrawAmount);
        }
        else { 
            uint256 interest = checkInterestAccumulated(tokenAddress);
            if(interest>0) {
                if(withdrawAmount>interest) {
                    withdrawAmount = withdrawAmount - interest;  
                }
                else {
                    uint256 extraAmount = interest - withdrawAmount;
                    require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), extraAmount),"You have to pay more");    
                    withdrawAmount = extraAmount + withdrawAmount - interest;
                }
            }
            if(withdrawAmount>0)
            IERC20(tokenAddress).transfer(msg.sender, withdrawAmount);
        }
        userbalances[msg.sender][tokenAddress] =  userbalances[msg.sender][tokenAddress].sub(amount);
        deposits[msg.sender][tokenAddress].assetAmount =  deposits[msg.sender][tokenAddress].assetAmount.sub(amount);
    }

    function checkInterestAccumulated(address tokenAddress) public view returns(uint256) {
        uint256 depositAmount = deposits[msg.sender][tokenAddress].assetAmount;
        require(depositAmount > 0, "Create Position call : Insufficient Deposit");
        uint256 interval = block.number.sub(deposits[msg.sender][tokenAddress].timestamp);
        uint interest = depositAmount.mul(interval.mul(interestPerBlock).div(100)).div(1E18);
        return interest;
    }
}