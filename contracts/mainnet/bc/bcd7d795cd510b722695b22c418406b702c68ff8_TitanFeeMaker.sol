pragma solidity =0.6.12;


interface ITitanFeeMaker {
    function depositLp(address _lpToken,uint256 _amount) external;
    function withdrawLp(address _lpToken,uint256 _amount) external;
    
    function withdrawETH(address to) external;
    function withdrawUSDT(address to) external;
    function withdrawTitan(uint256 amount) external;
    
    function chargeTitan(uint256 amount) external;
    function adjustTitanBonus(uint256 _BONUS_MULTIPLIER) external;
}

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

interface ITitanSwapV1ERC20 {
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
}

interface ITitanSwapV1Factory {
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

interface ITitanSwapV1Pair {
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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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


contract TitanFeeMaker is Ownable,ITitanFeeMaker{
    using SafeMath for uint256;

    ITitanSwapV1Factory public factory;
    address public weth;
    address public titan;
    address public usdt;
    address public routerAddress;
    
    // Bonus muliplier for early sushi makers.
    uint256 public BONUS_MULTIPLIER = 100;
    // Bonus muliplier for early sushi makers.
    uint256 public constant BONUS_BASE_RATE = 100;
    // record need reward titan amount
    uint256 public titanRewardAmount = 0;
    // recod already transfer titan reward
    uint256 public titanRewardAmountAlready = 0;
    

    // Info of each lp pool
    struct PoolInfo {
        address lpToken;
        uint256 lastRewardBlock;
        uint256 accTitanPerShare;
    }

    // Info of each user;
    struct UserInfo {
        uint256 amount; // How many lp tokens the user has provided;
        uint256 rewardDebt; // Reward debt;
    }

    // info of lp pool
    mapping (address => PoolInfo) public poolInfo;
    mapping (address => mapping(address => UserInfo)) public userInfo;
    
    // add this function to receive eth
    receive() external payable {
        assert(msg.sender == weth); // only accept ETH via fallback from the WETH contract
    }

    constructor(ITitanSwapV1Factory _factory,address _routerAddress,address _titan,address _weth,address _usdt) public {
        factory = _factory;
        titan = _titan;
        weth = _weth;
        usdt = _usdt;
        routerAddress = _routerAddress;
    }
    
    event createPool(address indexed lpToken,uint256 blockNumber);
   

    // Update reward variables of the given pool;
    function updatePool(address _lpToken,uint256 _addLpAmount) private {
        PoolInfo storage pool =  poolInfo[_lpToken];
        // create pool
        if(pool.lastRewardBlock == 0) {
            poolInfo[_lpToken] = PoolInfo({
            lpToken: _lpToken,
            lastRewardBlock: block.number,
            accTitanPerShare: 0
            });
            pool = poolInfo[_lpToken];
            emit createPool(_lpToken,block.number);
        }
        
        if(block.number < pool.lastRewardBlock) {
            return;
        }
        
        pool.lastRewardBlock = block.number;
        uint256 feeLpBalance = ITitanSwapV1Pair(pool.lpToken).balanceOf(address(this));
        if(feeLpBalance == 0) {
           return;
        }
        uint256 titanFeeReward = convertLpToTitan(ITitanSwapV1Pair(pool.lpToken),feeLpBalance);
        if(titanFeeReward == 0) {
            return;
        }
        // maybe reward more
        titanFeeReward = titanFeeReward.mul(BONUS_MULTIPLIER).div(BONUS_BASE_RATE);
        titanRewardAmount = titanRewardAmount.add(titanFeeReward);
        uint256 lpSupply = ITitanSwapV1Pair(pool.lpToken).totalSupply().sub(_addLpAmount);
        pool.accTitanPerShare = pool.accTitanPerShare.add(titanFeeReward.mul(1e18).div(lpSupply));
    }

    // call when add Liquidity，
    function depositLp(address _lpToken,uint256 _amount) external override {
        if(_amount > 0) {
            require(msg.sender == routerAddress,'TitanSwapV1FeeMaker: must call by router');
        }
        updatePool(_lpToken,_amount);
        PoolInfo storage pool = poolInfo[_lpToken];
        UserInfo storage user = userInfo[_lpToken][tx.origin];
        if(user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTitanPerShare).div(1e18).sub(user.rewardDebt);
            if(pending > 0) {
                require(IERC20(titan).balanceOf(address(this)) >= pending,'TitanSwapV1FeeMaker: titan not enough');
                TransferHelper.safeTransfer(titan,tx.origin,pending);
                titanRewardAmountAlready = titanRewardAmountAlready.add(pending);
            }
        }
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accTitanPerShare).div(1e18);
    }
    // call when remove Liquidity
    function withdrawLp(address _lpToken,uint256 _amount) external override {
        if(_amount > 0) {
            require(msg.sender == routerAddress,'TitanSwapV1FeeMaker: must call by router');
        }
        updatePool(_lpToken,0);
        PoolInfo storage pool = poolInfo[_lpToken];
        UserInfo storage user = userInfo[_lpToken][tx.origin];
        require(user.amount >= _amount,'remove lp not good');
        uint256 pending = user.amount.mul(pool.accTitanPerShare).div(1e18).sub(user.rewardDebt);
        if(pending > 0) {
             require(IERC20(titan).balanceOf(address(this)) >= pending,'TitanSwapV1FeeMaker: titan not enough');
            TransferHelper.safeTransfer(titan,tx.origin,pending);
            titanRewardAmountAlready = titanRewardAmountAlready.add(pending);
        }
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accTitanPerShare).div(1e18);
    }


    
    function convertLpToTitan(ITitanSwapV1Pair _pair,uint256 _feeLpBalance) private returns(uint256){
       
        uint256 beforeTitan = IERC20(titan).balanceOf(address(this));
        uint256 beforeWeth = IERC20(weth).balanceOf(address(this));
        uint256 beforeUsdt = IERC20(usdt).balanceOf(address(this));
        
        _pair.transfer(address(_pair),_feeLpBalance);
        _pair.burn(address(this));
       
        address token0 = _pair.token0();
        address token1 = _pair.token1();
        
        if(token0 == weth || token1 == weth) {
           // convert token to weth
           _toWETH(token0);
           _toWETH(token1);
           uint256 wethAmount = IERC20(weth).balanceOf(address(this)).sub(beforeWeth);
           if(token0 == titan || token1 == titan) {
                ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(titan,weth));
                (uint reserve0, uint reserve1,) = pair.getReserves();
                address _token0 = pair.token0();
                (uint reserveIn, uint reserveOut) = _token0 == titan ? (reserve0, reserve1) : (reserve1, reserve0);
                uint titanAmount = IERC20(titan).balanceOf(address(this)).sub(beforeTitan);
                uint256 titanWethAmount = reserveOut.mul(titanAmount).div(reserveIn);
                wethAmount = wethAmount.add(titanWethAmount);
           }
           // convert to titan
           return _wethToTitan(wethAmount);
        }
        
        if(token0 == usdt || token1 == usdt) {
            // convert token to usdt
            _toUSDT(token0);
            _toUSDT(token1);
           uint256 usdtAmount = IERC20(usdt).balanceOf(address(this)).sub(beforeUsdt);
           if(token0 == titan || token1 == titan) {
                ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(titan,usdt));
                (uint reserve0, uint reserve1,) = pair.getReserves();
                address _token0 = pair.token0();
                (uint reserveIn, uint reserveOut) = _token0 == titan ? (reserve0, reserve1) : (reserve1, reserve0);
                uint titanAmount = IERC20(titan).balanceOf(address(this)).sub(beforeTitan);
                uint256 titanUsdtAmount = reserveOut.mul(titanAmount).div(reserveIn);
                usdtAmount = usdtAmount.add(titanUsdtAmount);
           }
            // convert to titan
           return _usdtToTitan(usdtAmount);
        }
        return 0;
    }
    
    function _toUSDT(address token) private returns (uint256) {
        if(token == usdt || token == titan) {
            return 0;
        }
        ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(token,usdt));
        if(address(pair) == address(0)) {
           return 0;
        }
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);
        
        return swapTokenForWethOrUsdt(token,token0,pair,reserveIn,reserveOut);
    }

    function _toWETH(address token) private returns (uint256) {
        if(token == weth || token == titan) {
            return 0;
        }
        ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(token,weth));
        if(address(pair) == address(0)) {
            return 0;
        }
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);

        return swapTokenForWethOrUsdt(token,token0,pair,reserveIn,reserveOut);
    }
    
    function swapTokenForWethOrUsdt(address token,address token0,ITitanSwapV1Pair pair,uint reserveIn,uint reserveOut) private returns (uint256) {
         // contract token balance
        uint amountIn = IERC20(token).balanceOf(address(this));
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == token ? (uint(0), amountOut) : (amountOut, uint(0));
        TransferHelper.safeTransfer(token,address(pair),amountIn);
        // swap token for eth
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
        return amountOut;
    }

    function _wethToTitan(uint256 amountIn) internal view returns (uint256) {
        ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(titan,weth));
        require(address(pair) != address(0),'TitanSwapV1FeeMaker: titan/eth not exist');
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == weth ? (reserve0, reserve1) : (reserve1, reserve0);
        return reserveOut.mul(amountIn).div(reserveIn);
    }
    
    function _usdtToTitan(uint256 amountIn) internal view returns (uint256) {
        ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(titan,usdt));
        require(address(pair) != address(0),'TitanSwapV1FeeMaker: titan/usdt not exist');
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == usdt ? (reserve0, reserve1) : (reserve1, reserve0);
        return reserveOut.mul(amountIn).div(reserveIn);
    }

    function withdrawETH(address to) external override onlyOwner{
        uint256 wethBalance = IERC20(weth).balanceOf(address(this));
        // require(wethBalance > 0,'TitanSwapV1FeeMaker: weth amount == 0');
        IWETH(weth).withdraw(wethBalance);
        TransferHelper.safeTransferETH(to,wethBalance);
        // TransferHelper.safeTransfer(weth,to,wethBalance);
    }
    
     function withdrawUSDT(address to) external override onlyOwner{
        uint256 usdtBalance = IERC20(usdt).balanceOf(address(this));
        require(usdtBalance > 0,'TitanSwapV1FeeMaker: usdt amount == 0');
        TransferHelper.safeTransfer(usdt,to,usdtBalance);
    }

    function chargeTitan(uint256 _amount) external override {
        TransferHelper.safeTransferFrom(titan,msg.sender,address(this),_amount);
    }

    function withdrawTitan(uint256 _amount) external override onlyOwner {
        uint256 balance = IERC20(titan).balanceOf(address(this));
        require(balance >= _amount,'balance not enough');
        TransferHelper.safeTransfer(titan,msg.sender,_amount);
    }
    
    function adjustTitanBonus(uint256 _BONUS_MULTIPLIER) external override onlyOwner {
        require(_BONUS_MULTIPLIER >= 100,'number must >= 100');
        BONUS_MULTIPLIER = _BONUS_MULTIPLIER;
    }
    
}


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

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

library TitanSwapV1Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TitanSwapV1Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TitanSwapV1Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        pair = ITitanSwapV1Factory(factory).getPair(tokenA,tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ITitanSwapV1Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'TitanSwapV1Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'TitanSwapV1Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'TitanSwapV1Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TitanSwapV1Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'TitanSwapV1Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TitanSwapV1Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TitanSwapV1Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TitanSwapV1Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}