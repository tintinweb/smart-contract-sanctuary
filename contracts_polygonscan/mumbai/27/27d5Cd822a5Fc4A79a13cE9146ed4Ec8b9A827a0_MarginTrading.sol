/**
 *Submitted for verification at polygonscan.com on 2022-01-22
*/

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
     * @dev Returns the decimal poimt of the token.
     */
    function decimals() external view returns (uint256);
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
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.7.6;

contract MarginTrading is Ownable{
    using SafeMath for uint256;

    struct Position {
        address asset;
        uint256 assetAmount;
        uint256 reverseAmount;
        address targetAsset;
        uint256 targetAmount;
        uint256 timestamp;
        bool status;
    }

    struct Deposit {
        uint256 assetAmount;
        uint256 leverage;
        uint256 loanAmount;
        uint256 interestAccumulated;
        uint256 timestamp;
        uint256 usedMargin;
    }

    // Starting position
    uint256 positionID = 1;
    // Interest per block
    uint256 interestPerBlock = 2E18;

    uint256 public reserveMargin;
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
         reserveMargin = 2;
    }

    receive() external payable{}

    function deposit(address tokenAddress, uint256 amount, uint256 leverage) external payable {
        Deposit storage depositInfo = deposits[msg.sender][tokenAddress];
        require(amount > 0 || msg.value > 0, "Deposit call : Null Amount");
        if(tokenAddress == address(0)) 
            amount = msg.value;
        else
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);  

        if(depositInfo.assetAmount > 0) {
            accureInterest(tokenAddress);
        } 

        depositInfo.assetAmount = depositInfo.assetAmount.add(amount);
        depositInfo.leverage = depositInfo.leverage.add(leverage);
        depositInfo.loanAmount = depositInfo.loanAmount.add((amount.mul(leverage)).sub(amount));
        depositInfo.timestamp = block.number;

        userbalances[msg.sender][tokenAddress] = userbalances[msg.sender][tokenAddress].add(amount);
        emit DepositEvent(msg.sender, tokenAddress, amount, block.timestamp);
    }

    function createPositionandTrade(address tokenAddress, address targetToken, uint256 amount) external {
        Deposit storage depositInfo = deposits[msg.sender][tokenAddress];
        uint256 allowedDeposit = depositInfo.assetAmount.add(depositInfo.loanAmount).sub(depositInfo.usedMargin);
        allowedDeposit = allowedDeposit.sub(allowedDeposit.mul(reserveMargin).div(100));
        require(allowedDeposit >= amount, "Create Position call : Insufficient Deposit");
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = targetToken;
        if(tokenAddress == address(0)) 
            path[0] = uniswapV2Router.WETH();

        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(path[0], path[1]);
        require(pair != address(0), "Create Position call :Invalid Pair");
        if(tokenAddress == address(0))
            require(address(this).balance >= amount, "Create position call : Insufficient payable Balance");
        else 
            require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "Create position call : Insufficient Token Balance");   

        uint256 _result = trade(amount, path);    

        positionIDs[msg.sender][positionID] = Position({
            asset: tokenAddress,
            assetAmount: amount,
            reverseAmount: 0,
            targetAsset: targetToken,
            targetAmount: _result,
            timestamp: block.number,
            status: true
        }); 
        userbalances[msg.sender][targetToken] = userbalances[msg.sender][targetToken].add(_result);
        depositInfo.usedMargin =  depositInfo.usedMargin.add(amount);
        usersPosition[msg.sender].push(positionID);
        positionID++;
    }

    function trade(uint256 loanAmount, address[] memory path) internal returns(uint256) {
        uint256[] memory result = new uint256[](2);
        uint deadline = block.timestamp + 100;
        if(path[0] == uniswapV2Router.WETH()) {
            // Trade and get asset out
            result = uniswapV2Router.swapExactETHForTokens{value: loanAmount}(0, path, address(this), deadline);
        }
        else if(path[1] == uniswapV2Router.WETH()){
            // Approve token in
            IERC20(path[0]).approve(address(uniswapV2Router), loanAmount); 
            // Trade and get asset out    
            result = uniswapV2Router.swapExactTokensForETH(loanAmount, 0, path, address(this), deadline);
        }
        else {
            // Approve token in
            IERC20(path[0]).approve(address(uniswapV2Router), loanAmount);
            // Trade and get asset out
            result = uniswapV2Router.swapExactTokensForTokens(loanAmount, 0, path, address(this), deadline);
        }
        return result[1];
    }

    function closePosition(uint256 _positionID) external payable {
        Position storage positionInfo = positionIDs[msg.sender][_positionID];
        Deposit storage depositInfo = deposits[msg.sender][positionInfo.asset];
        address[] memory path = new address[](2);
        path[1] = positionInfo.asset;
        path[0] = positionInfo.targetAsset;
        if(path[1] == address(0)) 
            path[1] = uniswapV2Router.WETH();
        uint256 _result = trade(positionInfo.targetAmount, path);

        positionInfo.reverseAmount = _result;

        userbalances[msg.sender][positionInfo.asset] =  userbalances[msg.sender][positionInfo.asset].add(_result);
        depositInfo.usedMargin =  depositInfo.usedMargin.sub(positionInfo.assetAmount);
        uint256 temp;
        if(positionInfo.assetAmount >= _result) { 
            temp = positionInfo.assetAmount.sub(_result);
            depositInfo.assetAmount = depositInfo.assetAmount.sub(temp);
        }
        else{ 
            temp = _result.sub(positionInfo.assetAmount);
            depositInfo.assetAmount = depositInfo.assetAmount.add(temp);
        }     

        
        userbalances[msg.sender][positionInfo.targetAsset] =  0;
        emit closeTrade(_positionID);
    }

    function withdraw(address tokenAddress, uint256 amount) external payable {
        Deposit storage depositInfo = deposits[msg.sender][tokenAddress];
        require(depositInfo.assetAmount >= 0, "Withdraw call : Insufficient Deposit");    
        uint256 withdrawAmount;
        accureInterest(tokenAddress);
        uint256 _interest = depositInfo.interestAccumulated;
        // require(userbalances[msg.sender][tokenAddress].sub(amount) > _interest, "Withdraw call : Cannot withdraw more than allowed");
        if(amount >= depositInfo.assetAmount) {
            depositInfo.interestAccumulated = 0;
            if(depositInfo.assetAmount < _interest) {
                uint256 amountTopay = _interest.sub(depositInfo.assetAmount);
                if(tokenAddress == address(0)) 
                    require(msg.value >= amountTopay, "Withdraw call : Insufficient Payable Interest pay");
                else
                    IERC20(tokenAddress).transferFrom(msg.sender, address(this), amountTopay);    
            }
            withdrawAmount = depositInfo.assetAmount.sub(_interest);
            userbalances[address(this)][tokenAddress] =  userbalances[address(this)][tokenAddress].add(_interest);
            depositInfo.assetAmount =  depositInfo.assetAmount.sub(_interest);
            depositInfo.loanAmount = 0;
            depositInfo.leverage = 0;
        }
        else {
            withdrawAmount = amount;
        }
        if(tokenAddress == address(0)) 
            msg.sender.transfer(withdrawAmount);
        else
            IERC20(tokenAddress).transfer(msg.sender, withdrawAmount);

        userbalances[msg.sender][tokenAddress] =  userbalances[msg.sender][tokenAddress].sub(withdrawAmount);
        depositInfo.assetAmount =  depositInfo.assetAmount.sub(withdrawAmount);
        depositInfo.timestamp = block.number;  
          
    }

    // function withdrawAfterTrade(uint256 _positionID) public payable {
    //     Position storage positionInfo = positionIDs[msg.sender][_positionID];
    //     Deposit storage depositInfo = deposits[msg.sender][positionInfo.asset];
    //     uint256 _interest = checkInterestAccumulated(msg.sender, positionInfo.asset);
    //     uint256 amount = positionInfo.assetAmount;
    //     uint256 targetWithdrawAmount; 
    //     // uint256 depositWithdrawAmount;
    //     if(amount >= depositInfo.assetAmount) {
    //         depositInfo.interestAccumulated = 0;
    //         if(depositInfo.assetAmount < _interest) {
    //             uint256 amountTopay = _interest.sub(depositInfo.assetAmount);
    //             if(positionInfo.targetAsset == uniswapV2Router.WETH()) 
    //                 require(msg.value >= amountTopay, "Withdraw call : Insufficient Payable Interest pay");
    //             else { 
    //                 if(IERC20(positionInfo.targetAsset).decimals() == 6) {
    //                     amountTopay = amountTopay.div(1E12);
    //                     _interest = _interest.div(1E12);
    //                 }
    //                 IERC20(positionInfo.targetAsset).transferFrom(msg.sender, address(this), amountTopay);  
    //             }  
    //         }
    //         targetWithdrawAmount = positionInfo.targetAmount.sub(_interest);
    //         userbalances[address(this)][positionInfo.targetAsset] = userbalances[address(this)][positionInfo.targetAsset].add(_interest);
    //         // if(positionInfo.asset == uniswapV2Router.WETH()) {
    //         //     depositWithdrawAmount = positionInfo.targetAmount.sub(_interest.mul(1E6));
    //         // }
    //         // else {
    //         //     if(IERC20(positionInfo.asset).decimals() == 6) 
    //         //         depositWithdrawAmount = positionInfo.targetAmount.sub(_interest.mul(1E12));
    //         //     else 
    //         //         depositWithdrawAmount = targetWithdrawAmount;
    //         // }
    //         depositInfo.assetAmount =  depositInfo.assetAmount.sub(_interest);
    //         depositInfo.loanAmount = 0;
    //         depositInfo.leverage = 0;
    //     }
    //     else {
    //         targetWithdrawAmount = positionInfo.targetAmount;
    //     }
    //     if(positionInfo.targetAsset == uniswapV2Router.WETH()) 
    //         msg.sender.transfer(targetWithdrawAmount);
    //     else
    //         IERC20(positionInfo.targetAsset).transfer(msg.sender, targetWithdrawAmount);

    //     userbalances[msg.sender][positionInfo.targetAsset] =  userbalances[msg.sender][positionInfo.targetAsset].sub(targetWithdrawAmount);
    //     depositInfo.assetAmount =  depositInfo.assetAmount.sub(positionInfo.assetAmount);
    //     depositInfo.usedMargin =  depositInfo.usedMargin.sub(positionInfo.assetAmount);
    //     depositInfo.timestamp = block.number; 
    //     positionInfo.status = false;
    // }

    function accureInterest(address tokenAddress) internal {
        Deposit storage depositInfo = deposits[msg.sender][tokenAddress];
        depositInfo.interestAccumulated = depositInfo.interestAccumulated.add(checkInterestAccumulated(msg.sender, tokenAddress));
    }

    function checkInterestAccumulated(address userAddress, address tokenAddress) public view returns(uint256) {
        Deposit memory depositInfo = deposits[userAddress][tokenAddress];
        uint256 loanAmount = depositInfo.loanAmount;
        uint256 interval = (block.number.sub(depositInfo.timestamp)).div(120);
        uint interest = depositInfo.interestAccumulated.add(loanAmount.mul(interval.mul(interestPerBlock).div(1000)).div(1E18));
        return interest;
    }

    function liquidateOpenPosition(uint256 _positionID) external onlyOwner {
        Position storage positionInfo = positionIDs[msg.sender][_positionID];
        Deposit storage depositInfo = deposits[msg.sender][positionInfo.asset];
        uint256 _interest = checkInterestAccumulated(msg.sender, positionInfo.asset);
        if(depositInfo.assetAmount <= _interest) {
            
        }
    }
}