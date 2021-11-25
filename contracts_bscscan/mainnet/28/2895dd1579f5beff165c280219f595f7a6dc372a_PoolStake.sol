/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

//"SPDX-License-Identifier: MIT"

pragma solidity ^0.6.6;

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

interface IPancakeFactory {
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

interface IPancakePair {
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

interface IPancakeRouter {
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

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
                ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

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
}

contract Owned {
    
    //address of contract owner
    address public owner;

    //event for transfer of ownership
    event OwnershipTransferred(address indexed _from, address indexed _to);

    /**
     * @dev Initializes the contract setting the _owner as the initial owner.
     */
    constructor(address _owner) public {
        owner = _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, 'only owner allowed');
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

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

    constructor() public {
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


interface Multiplier {
    function updateLockupPeriod(address _user, uint _lockup) external returns(bool);
    function getMultiplierCeiling() external pure returns (uint);
    function balance(address user) external view returns (uint);
    function approvedContract(address _user) external view returns(address);
    function lockupPeriod(address user) external view returns (uint);
}

/* 
 * @dev PoolStakes contract for locking up liquidity to earn bonus rewards.
 */
contract PoolStake is Owned, ReentrancyGuard {
    //instantiate SafeMath library
    using SafeMath for uint;
    
    IERC20 internal weth;                       //represents weth.
    IERC20 internal token;                      //represents the project's token which should have a weth pair on uniswap
    IERC20 internal lpToken;                    //lpToken for liquidity provisioning
    
    address internal uToken1;                   //utility token
    address internal uToken2;                   //utility token for migration 
    address internal platformWallet;            //fee receiver
    uint internal scalar = 10 ** 36;            //unit for scaling
    uint internal cap;                          //ETH limit that can be provided
    bool internal migratedToLQDY;
    
    Multiplier internal multiplier1;                        //Interface of Multiplier contract
    Multiplier internal multiplier2;                        //Interface of Multiplier contract
    IPancakeRouter internal pancakeRouter;                //Interface of Pancakeswap router
    IPancakeFactory internal iPancakeFactory;
    
    //user struct
    struct User {
        uint start;                 //starting period
        uint release;               //release period
        uint tokenBonus;            //user token bonus
        uint wethBonus;             //user weth bonus
        uint tokenWithdrawn;        //amount of token bonus withdrawn
        uint wethWithdrawn;         //amount of weth bonus withdrawn
        uint liquidity;             //user liquidity gotten from uniswap
        uint period;                //identifies users' current term period
        bool migrated;              //if migrated to uniswap V3
        uint lastAction;            //timestamp for user's last action
        uint lastTokenProvided;     //last provided token
        uint lastWethProvided;      //last provided eth
        uint lastTerm;              //last term joined
        uint lastPercentToken;      //last percentage for rewards token
        uint lastPercentWeth;       //last percentage for rewards eth
        bool multiplier;            //if last action included multiplier
    }
    
    mapping(address => User) internal _users;
    
    //term periods
    uint32 internal period1;
    uint32 internal period2;
    uint32 internal period3;
    uint32 internal period4;
    
    //mapping periods(in series of 1 - 4) to number of providers. 
    mapping(uint => uint) internal _providers;
    
    //return percentages for ETH and token                          1000 = 1% 
    uint internal period1RPWeth; 
    uint internal period2RPWeth;
    uint internal period3RPWeth;
    uint internal period4RPWeth;
    uint internal period1RPToken; 
    uint internal period2RPToken;
    uint internal period3RPToken;
    uint internal period4RPToken;
    
    //available bonuses rto be claimed
    uint internal _pendingBonusesWeth;
    uint internal _pendingBonusesToken;
    
    //data for analytics
    uint internal totalETHProvided;
    uint internal totalTokenProvided;
    uint internal totalProviders;
    
    //migration contract for Uniswap V3
    address public migrationContract;
    
    //events
    event BonusAdded(address indexed sender, uint ethAmount, uint tokenAmount);
    event BonusRemoved(address indexed sender, uint amount);
    event CapUpdated(address indexed sender, uint amount);
    event LPWithdrawn(address indexed sender, uint amount);
    event LiquidityAdded(address indexed sender, uint liquidity, uint amountETH, uint amountToken);
    event LiquidityWithdrawn(address indexed sender, uint liquidity, uint amountETH, uint amountToken);
    event MigratedToLQDY(address indexed sender, address uToken, address multiplier);
    event FeeReceiverUpdated(address oldFeeReceiver, address newFeeReceiver);
    event NewUToken(address indexed sender, address uToken2, address multiplier);
    event UserTokenBonusWithdrawn(address indexed sender, uint amount, uint fee);
    event UserETHBonusWithdrawn(address indexed sender, uint amount, uint fee);
    event VersionMigrated(address indexed sender, uint256 time, address to);
    event LiquidityMigrated(address indexed sender, uint amount, address to);
    event StakeEnded(address indexed sender, uint lostETHBonus, uint lostTokenBonus);
    
    /* 
     * @dev initiates a new PoolStake.
     * --------------------------------------------------------
     * @param _token    --> token offered for staking liquidity.
     * @param _Owner    --> address for the initial contract owner.
     */ 
    constructor(address _token, address _Owner) public Owned(_Owner) {
            
        require(_token != address(0), "can not deploy a zero address");
        token = IERC20(_token);
        
        pancakeRouter = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);  
        iPancakeFactory = IPancakeFactory(pancakeRouter.factory());
        weth = IERC20(pancakeRouter.WETH()); 
        address _lpToken = iPancakeFactory.getPair(address(token), pancakeRouter.WETH());
        require(_lpToken != address(0), "Pair must first be created on pancakeswap");
        lpToken = IERC20(_lpToken);
        
        uToken1 = 0xd185C16756873B907dF064bD7b4815839de4e6b9;
        platformWallet = 0x538f14c190ba4B81A6f3CfBfD8dE470e5293ba3A;
        multiplier1 = Multiplier(0x53CD43a2d816e99f9F863d3c60228155481E96aB);
    }
    
    modifier onlyPlatformWallet() {
        
        require(msg.sender == platformWallet, "only wallet can call");
        _;
    }
    
    modifier uTokenVet(uint _id) {
        
        if(uToken2 == address(0)) require(_id == 1, "currently accepts only uToken1");
        if(migratedToLQDY) require(_id != 1, "currently accepts only uToken2");
        _;
    }

    function newUToken(address _uToken2, address _multiplier2) external onlyPlatformWallet returns(bool) {
        
        require(uToken2 == address(0) && address(multiplier2) == address(0), "already migrated to LQDY");
        require(_uToken2 != address(0x0) && _multiplier2 != address(0x0), "cannot set the zero address");
        require(Address.isContract(_multiplier2), "multiplier must be a smart contract address");
        
        uToken2 = _uToken2;
        multiplier2 = Multiplier(_multiplier2);
        
        emit NewUToken(msg.sender, _uToken2, _multiplier2);
        return true;
    }
    
    function completeUTokenMerge() external onlyPlatformWallet returns(bool) {
        
        require(!migratedToLQDY, "already migrated to LQDY");
        
        migratedToLQDY = true;
        uToken1 = uToken2;
        
        address _multiplier2 = address(multiplier2);
        multiplier1 = Multiplier(_multiplier2);
        
        emit MigratedToLQDY(msg.sender, uToken2, address(multiplier2));
        return true;
    }
    
    function changeFeeReceiver(address _feeReceiver) external onlyPlatformWallet returns(bool) {
        
        platformWallet = _feeReceiver;
        
        emit FeeReceiverUpdated(msg.sender, _feeReceiver);
        return true;
    }
    
    /* 
     * @dev change the return percentage for locking up liquidity for ETH and Token (only Owner).
     * ------------------------------------------------------------------------------------
     * @param _period1RPETH - _period4RPToken --> the new return percentages.
     * ----------------------------------------------
     * returns whether successfully changed or not.
     */ 
    function changeReturnPercentages(
        uint _period1RPETH, uint _period2RPETH, uint _period3RPETH, uint _period4RPETH, 
        uint _period1RPToken, uint _period2RPToken, uint _period3RPToken, uint _period4RPToken
    ) external onlyOwner returns(bool) {
        
        period1RPWeth = _period1RPETH;
        period2RPWeth = _period2RPETH;
        period3RPWeth = _period3RPETH;
        period4RPWeth = _period4RPETH;
        
        period1RPToken = _period1RPToken;
        period2RPToken = _period2RPToken;
        period3RPToken = _period3RPToken;
        period4RPToken = _period4RPToken;
        
        return true;
    }
    
    /* 
     * @dev change the lockup periods (only Owner).
     * ------------------------------------------------------------------------------------
     * @param _firstTerm - _fourthTerm --> the new term periods.
     * ----------------------------------------------
     * returns whether successfully changed or not.
     */ 
    function changeTermPeriods(
        uint32 _firstTerm, uint32 _secondTerm, 
        uint32 _thirdTerm, uint32 _fourthTerm
    ) external onlyOwner returns(bool) {
        
        period1 = _firstTerm;
        period2 = _secondTerm;
        period3 = _thirdTerm;
        period4 = _fourthTerm;
        
        return true;
    }
    
    /* 
     * @dev change the maximum ETH that a user can enter with (only Owner).
     * ------------------------------------------------------------------------------------
     * @param _cap      --> the new cap value.
     * ----------------------------------------------
     * returns whether successfully changed or not.
     */ 
    function changeCap(uint _cap) external onlyOwner returns(bool) {
        
        cap = _cap;
        
        emit CapUpdated(msg.sender, _cap);
        return true;
    }
    
    /* 
     * @dev makes migration possible for uniswap V3 (only Owner).
     * ----------------------------------------------------------
     * @param _unistakeMigrationContract      --> the migration contract address.
     * -------------------------------------------------------------------------
     * returns whether successfully migrated or not.
     */ 
    function allowMigration(address _unistakeMigrationContract) external onlyOwner returns (bool) {
        
        require(_unistakeMigrationContract != address(0x0), "cannot migrate to a null address");
        migrationContract = _unistakeMigrationContract;
        
        emit VersionMigrated(msg.sender, now, migrationContract);
        return true;
    }
    
    /* 
     * @dev initiates migration for a user (only when migration is allowed).
     * -------------------------------------------------------------------
     * @param _unistakeMigrationContract      --> the migration contract address.
     * -------------------------------------------------------------------------
     * returns whether successfully migrated or not.
     */ 
    function startMigration(address _unistakeMigrationContract) external returns (bool) {
        
        require(_unistakeMigrationContract != address(0x0), "cannot migrate to a null address");
        require(migrationContract == _unistakeMigrationContract, "must confirm endpoint");
        require(!getUserMigration(msg.sender), "must not be migrated already");
        
        _users[msg.sender].migrated = true;
        
        uint256 liquidity = _users[msg.sender].liquidity;
        lpToken.transfer(migrationContract, liquidity);
        
        emit LiquidityMigrated(msg.sender, liquidity, migrationContract);
        return true;
    }
    
    /* 
     * @dev add more staking bonuses to the pool.
     * ----------------------------------------
     * @param              --> input value along with call to add ETH
     * @param _tokenAmount --> the amount of token to be added.
     * --------------------------------------------------------
     * returns whether successfully added or not.
     */ 
    function addBonus(uint _tokenAmount) external payable returns(bool) {
        
        require(_tokenAmount > 0 || msg.value > 0, "must send value");
        if (_tokenAmount > 0)
        require(token.transferFrom(msg.sender, address(this), _tokenAmount), "must approve smart contract");
        
        emit BonusAdded(msg.sender, msg.value, _tokenAmount);
        return true;
    }
    
    /* 
     * @dev remove staking bonuses to the pool. (only owner)
     * must have enough asset to be removed
     * ----------------------------------------
     * @param _amountETH   --> eth amount to be removed
     * @param _amountToken --> token amount to be removed.
     * --------------------------------------------------------
     * returns whether successfully added or not.
     */ 
    function removeETHAndTokenBouses(uint _amountETH, uint _amountToken) external onlyOwner returns (bool success) {
       
        require(_amountETH > 0 || _amountToken > 0, "amount must be larger than zero");
    
        if (_amountETH > 0) {
            require(_checkForSufficientStakingBonusesForETH(_amountETH), 'cannot withdraw above current ETH bonus balance');
            msg.sender.transfer(_amountETH);
            emit BonusRemoved(msg.sender, _amountETH);
        }
        
        if (_amountToken > 0) {
            require(_checkForSufficientStakingBonusesForToken(_amountToken), 'cannot withdraw above current token bonus balance');
            require(token.transfer(msg.sender, _amountToken), "error: token transfer failed");
            emit BonusRemoved(msg.sender, _amountToken);
        }
        
        return true;
    }
    
    /* 
     * @dev add unwrapped liquidity to staking pool.
     * --------------------------------------------
     * @param _tokenAmount  --> must input token amount along with call
     * @param _term         --> the lockup term.
     * @param _multiplier   --> whether multiplier should be used or not
     *                        1 means you want to use the multiplier. !1 means no multiplier
     * -------------------------------------------------------------------------------------
     */
    function addLiquidity(uint _term, uint _multiplier, uint _id) external uTokenVet(_id) payable {
        
        require(!getUserMigration(msg.sender), "must not be migrated already");
        require(now >= _users[msg.sender].release, "cannot override current term");
        
        (bool isValid, uint period) = _isValidTerm(_term);
        require(isValid, "must select a valid term");
        require(msg.value > 0, "must send ETH along with transaction");
        if (cap != 0) require(msg.value <= cap, "cannot provide more than the cap");
        
        uint rate = _proportion(msg.value, address(weth), address(token));
        require(token.transferFrom(msg.sender, address(this), rate), "must approve smart contract");
        
        (uint ETH_bonus, uint token_bonus) = getUserBonusPending(msg.sender);
        require(ETH_bonus == 0 && token_bonus == 0, "must first withdraw available bonus");
        
        uint oneTenthOfRate = (rate.mul(10)).div(100);
        token.approve(address(pancakeRouter), rate);

        (uint amountToken, uint amountETH, uint liquidity) = 
        pancakeRouter.addLiquidityETH{value: msg.value}(
            address(token), 
            rate.add(oneTenthOfRate),
            0, 
            0, 
            address(this), 
            now);
        
        uint term = _term;
        uint mul = _multiplier;
        uint __id = _id;
        
        _users[msg.sender].start = now;
        _users[msg.sender].release = now.add(term);
        
        totalETHProvided = totalETHProvided.add(amountETH);
        totalTokenProvided = totalTokenProvided.add(amountToken);
        totalProviders++;
        
        uint currentPeriod = _users[msg.sender].period;
        if (currentPeriod != period) {
            _providers[currentPeriod]--;
            _providers[period]++;
            _users[msg.sender].period = period;
        }
        
        uint previousLiquidity = _users[msg.sender].liquidity; 
        _users[msg.sender].liquidity = previousLiquidity.add(liquidity);  
        
        uint wethRP = _calculateReturnPercentage(weth, term);
        uint tokenRP = _calculateReturnPercentage(token, term);
               
        (uint provided_ETH, uint provided_token) = getUserLiquidity(msg.sender);
        
        if (mul == 1) 
        _withMultiplier(term, provided_ETH, provided_token, wethRP, tokenRP, __id);
        else _withoutMultiplier(provided_ETH, provided_token, wethRP, tokenRP);
        
        _updateLastProvision(now, term, provided_token, provided_ETH, mul);
        
        emit LiquidityAdded(msg.sender, liquidity, amountETH, amountToken);
    }
    
    /* 
     * @dev relocks liquidity already provided
     * --------------------------------------------
     * @param _term       --> the lockup term.
     * @param _multiplier --> whether multiplier should be used or not
     *                        1 means you want to use the multiplier. !1 means no multiplier
     * --------------------------------------------------------------
     * returns whether successfully relocked or not.
     */
    function relockLiquidity(uint _term, uint _multiplier, uint _id) external uTokenVet(_id) returns(bool) {
        
        require(!getUserMigration(msg.sender), "must not be migrated already");
        require(_users[msg.sender].liquidity > 0, "do not have any liquidity to lock");
        require(now >= _users[msg.sender].release, "cannot override current term");
        (bool isValid, uint period) = _isValidTerm(_term);
        require(isValid, "must select a valid term");
        
        (uint ETH_bonus, uint token_bonus) = getUserBonusPending(msg.sender);
        require (ETH_bonus == 0 && token_bonus == 0, 'must withdraw available bonuses first');
        
        (uint provided_ETH, uint provided_token) = getUserLiquidity(msg.sender);
        if (cap != 0) require(provided_ETH <= cap, "cannot provide more than the cap");
        
        uint wethRP = _calculateReturnPercentage(weth, _term);
        uint tokenRP = _calculateReturnPercentage(token, _term);
        
        totalProviders++;
        
        uint currentPeriod = _users[msg.sender].period;
        if (currentPeriod != period) {
            _providers[currentPeriod]--;
            _providers[period]++;
            _users[msg.sender].period = period;
        }
        
        _users[msg.sender].start = now;
        _users[msg.sender].release = now.add(_term);
        
        uint __id = _id;
        uint term = _term;
        uint mul = _multiplier;
        
        if (mul == 1) 
        _withMultiplier(term, provided_ETH, provided_token, wethRP, tokenRP, __id);
        else _withoutMultiplier(provided_ETH, provided_token, wethRP, tokenRP); 
        
        _updateLastProvision(now, term, provided_token, provided_ETH, mul);
        
        return true;
    }
    
    /* 
     * @dev withdraw unwrapped liquidity by user if released.
     * -------------------------------------------------------
     * @param _lpAmount --> takes the amount of user's lp token to be withdrawn.
     * -------------------------------------------------------------------------
     * returns whether successfully withdrawn or not.
     */
    function withdrawLiquidity(uint _lpAmount) external returns(bool) {
        
        require(!getUserMigration(msg.sender), "must not be migrated already");
        
        uint liquidity = _users[msg.sender].liquidity;
        require(_lpAmount > 0 && _lpAmount <= liquidity, "do not have any liquidity");
        require(now >= _users[msg.sender].release, "cannot override current term");
        
        _users[msg.sender].liquidity = liquidity.sub(_lpAmount); 
        
        lpToken.approve(address(pancakeRouter), _lpAmount);                                         
        
        (uint amountToken, uint amountETH) = 
            pancakeRouter.removeLiquidityETH(
                address(token),
                _lpAmount,
                1,
                1,
                msg.sender,
                now);
        
        uint period = _users[msg.sender].period;
        if (_users[msg.sender].liquidity == 0) {
            _users[msg.sender].period = 0;
            _providers[period]--;
            
            _updateLastProvision(0, 0, 0, 0, 0);
            _users[msg.sender].lastPercentWeth = 0;
            _users[msg.sender].lastPercentToken = 0;
        }
        
        emit LiquidityWithdrawn(msg.sender, _lpAmount, amountETH, amountToken);
        return true;
    }
    
    /* 
     * @dev withdraw LP token by user if released.
     * -------------------------------------------------------
     * returns whether successfully withdrawn or not.
     */
    function withdrawUserLP() external returns(bool) {
        
        require(!getUserMigration(msg.sender), "must not be migrated already");
        
        uint liquidity = _users[msg.sender].liquidity;
        require(liquidity > 0, "do not have any liquidity");
        require(now >= _users[msg.sender].release, "cannot override current term");
        
        uint period = _users[msg.sender].period;
        _users[msg.sender].liquidity = 0; 
        _users[msg.sender].period = 0;
        _providers[period]--;
        
        _updateLastProvision(0, 0, 0, 0, 0);
        _users[msg.sender].lastPercentWeth = 0;
        _users[msg.sender].lastPercentToken = 0;
        
        lpToken.transfer(msg.sender, liquidity);                                         
        
        emit LPWithdrawn(msg.sender, liquidity);
        return true;
    }
    
    function endStake(uint _id) external nonReentrant uTokenVet(_id) returns(bool) {
        
        require(_users[msg.sender].release > now, "no current lockup");
        
        _withdrawUserBonus(_id);
        
        (uint ethBonus, uint tokenBonus) = getUserBonusPending(msg.sender);
        _zeroBalances();
        
        if (ethBonus > 0 && tokenBonus > 0) {
            
            _pendingBonusesWeth = _pendingBonusesWeth.sub(ethBonus);
            _pendingBonusesToken = _pendingBonusesToken.sub(tokenBonus);
            
        } else if (ethBonus > 0 && tokenBonus == 0) 
            _pendingBonusesWeth = _pendingBonusesWeth.sub(ethBonus);
        
        else if (ethBonus == 0 && tokenBonus > 0)
            _pendingBonusesToken = _pendingBonusesToken.sub(tokenBonus);
        
        _users[msg.sender].release = 0;
        
        emit StakeEnded(msg.sender, ethBonus, tokenBonus);
        return true;
    }
    
    /* 
     * @dev withdraw available staking bonuses earned from locking up liquidity. 
     * --------------------------------------------------------------
     * returns whether successfully withdrawn or not.
     */  
    function withdrawUserBonus(uint _id) external uTokenVet(_id) returns(bool) {
        
        (uint ETH_bonus, uint token_bonus) = getUserBonusAvailable(msg.sender);
        require(ETH_bonus > 0 || token_bonus > 0, "you do not have any bonus available");
        
        _withdrawUserBonus(_id);
        
        if (_users[msg.sender].release <= now) {
            _zeroBalances();
        }
        return true;
    }
    
    /* 
     * @dev get the timestamp of when the user balance will be released from locked term. 
     * ---------------------------------------------------------------------------------
     * @param _user --> the address of the user.
     * ---------------------------------------
     * returns the timestamp for the release.
     */     
    function getUserRelease(address _user) external view returns(uint release_time) {
        
        uint release = _users[_user].release;
        if (release > now) {
            
            return (release.sub(now));
       
        } else {
            
            return 0;
        }
        
    }
    
    /* 
     * @dev get the amount of bonuses rewarded from staking to a user.   
     * --------------------------------------------------------------
     * @param _user --> the address of the user.
     * ---------------------------------------
     * returns the amount of staking bonuses.
     */  
    function getUserBonusPending(address _user) public view returns(uint ETH_bonus, uint token_bonus) {
        
        uint takenWeth = _users[_user].wethWithdrawn;
        uint takenToken = _users[_user].tokenWithdrawn;
        
        return (_users[_user].wethBonus.sub(takenWeth), _users[_user].tokenBonus.sub(takenToken));
    }
    
    /* 
     * @dev get the amount of released bonuses rewarded from staking to a user.   
     * --------------------------------------------------------------
     * @param _user --> the address of the user.
     * ---------------------------------------
     * returns the amount of released staking bonuses.
     */  
    function getUserBonusAvailable(address _user) public view returns(uint ETH_Released, uint token_Released) {
        
        uint ETHValue = _calculateETHReleasedAmount(_user);
        uint tokenValue = _calculateTokenReleasedAmount(_user);
        
        return (ETHValue, tokenValue);
    }   
    
    /* 
     * @dev get the amount of liquidity pool tokens staked/locked by user.   
     * ------------------------------------------------------------------
     * @param _user --> the address of the user.
     * ---------------------------------------
     * returns the amount of locked liquidity.
     */   
    function getUserLPTokens(address _user) external view returns(uint user_LP) {

        return _users[_user].liquidity;
    }
    
    /* 
     * @dev get the lp token address for the pair.  
     * -----------------------------------------------------------
     * returns the lp address for eth/token pair.
     */ 
    function getLPAddress() external view returns(address) {
        
        return address(lpToken);
    }
    
    /* 
     * @dev get the total amount of LP tokens in the Poolstake contract
     * ----------------------------------------------------------------
     * returns the amount of LP tokens in the Poolstake contract
     */ 
    function getTotalLPTokens() external view returns(uint) {
        
        return lpToken.balanceOf(address(this));
    }
    
    /* 
     * @dev get the amount of staking bonuses available in the pool.  
     * -----------------------------------------------------------
     * returns the amount of staking bounses available for ETH and Token.
     */ 
    function getAvailableBonus() external view returns(uint available_ETH, uint available_token) {
        
        available_ETH = (address(this).balance).sub(_pendingBonusesWeth);
        available_token = (token.balanceOf(address(this))).sub(_pendingBonusesToken);
        
        return (available_ETH, available_token);
    }
    
    /* 
     * @dev get the maximum amount of ETH allowed for provisioning.  
     * -----------------------------------------------------------
     * returns the maximum ETH allowed
     */ 
    function getCap() external view returns(uint maxETH) {
        
        return cap;
    }
    
    /* 
     * @dev get the amount ETH and Token liquidity provided by the user.   
     * ------------------------------------------------------------------
     * @param _user --> the address of the user.
     * ---------------------------------------
     * returns the amount of ETH and Token liquidity provided.
     */   
    function getUserLiquidity(address _user) public view returns(uint provided_ETH, uint provided_token) {
        
        uint total = lpToken.totalSupply();
        uint ratio = ((_users[_user].liquidity).mul(scalar)).div(total);
        uint tokenHeld = token.balanceOf(address(lpToken));
        uint wethHeld = weth.balanceOf(address(lpToken));
        
        return ((ratio.mul(wethHeld)).div(scalar), (ratio.mul(tokenHeld)).div(scalar));
    }
    
    /* 
     * @dev check whether the inputted user address has been migrated.  
     * ----------------------------------------------------------------------
     * @param _user --> ddress of the user
     * ---------------------------------------
     * returns whether true or not.
     */  
    function getUserMigration(address _user) public view returns (bool) {
        
        return _users[_user].migrated;
    }
    
    /* 
     * @dev checks the term period and return percentages 
     * --------------------------------------------------
     * returns term period and return percentages 
     */
    function getTermPeriodAndReturnPercentages() external view returns(
        uint Term_Period_1, uint Term_Period_2, uint Term_Period_3, uint Term_Period_4,
        uint Period_1_Return_Percentage_Token, uint Period_2_Return_Percentage_Token,
        uint Period_3_Return_Percentage_Token, uint Period_4_Return_Percentage_Token,
        uint Period_1_Return_Percentage_ETH, uint Period_2_Return_Percentage_ETH,
        uint Period_3_Return_Percentage_ETH, uint Period_4_Return_Percentage_ETH
    ) {
        
        return (
            period1, period2, period3, period4, period1RPToken, period2RPToken, period3RPToken, 
            period4RPToken,period1RPWeth, period2RPWeth, period3RPWeth, period4RPWeth);
    }
    
    function analytics() external view returns(uint Total_ETH_Provided, 
        uint Total_Tokens_Provided, uint Total_Providers,
        uint Current_Term_1, uint Current_Term_2, 
        uint Current_Term_3, uint Current_Term_4
    ) {
        
        return(
            totalETHProvided, totalTokenProvided, totalProviders, 
            _providers[1], _providers[2], _providers[3], _providers[4]);
    }
    
    /* 
     * @dev get the address of the multiplier contract
     * -----------------------------------------------
     * returns the multiplier contract address
     */ 
    function multiplierContract() external view returns(address Token1, address Token2) {
        
        return (address(multiplier1), address(multiplier2));
    }
    
    /* 
     * @dev get the address of the fee token
     * -------------------------------------
     * returns the fee token address
     */ 
    function feeToken() external view returns(address _uToken1, address _uToken2) {
        
        return (uToken1, uToken2);
    }
    
    /* 
     * @dev get the address of the fee receiver
     * ----------------------------------------
     * returns the fee receiver address
     */ 
    function feeReceiver() external view returns(address) {
        
        return platformWallet;
    }
    
    function lastProvision(address _user) external view returns(
        uint timestamp, uint term, uint token_provided, 
        uint eth_provided, bool multiplier, 
        uint percentageGottenToken, uint percentageGottenWeth
    ) {
        
        timestamp = _users[_user].lastAction;
        term = _users[_user].lastTerm;
        token_provided = _users[_user].lastTokenProvided;
        eth_provided = _users[_user].lastWethProvided;
        multiplier = _users[_user].multiplier;
        percentageGottenToken = _users[_user].lastPercentToken;
        percentageGottenWeth = _users[_user].lastPercentWeth;
        
    }
    
    /* 
     * @dev uses the Multiplier contract for double rewarding
     * ------------------------------------------------------
     * @param _term       --> the lockup term.
     * @param amountETH   --> ETH amount provided in liquidity
     * @param amountToken --> token amount provided in liquidity
     * @param wethRP      --> return percentge for ETH based on term period
     * @param tokenRP     --> return percentge for token based on term period
     * --------------------------------------------------------------------
     */
    function _withMultiplier(
        uint _term, uint amountETH, uint amountToken, uint wethRP, uint tokenRP, uint _id
    ) internal {
        
        if(_id == 1) 
        _resolveMultiplier(_term, amountETH, amountToken, wethRP, tokenRP, multiplier1);
        else _resolveMultiplier(_term, amountETH, amountToken, wethRP, tokenRP, multiplier2);
    }
    
    /* 
     * @dev distributes bonus without considering Multiplier
     * ------------------------------------------------------
     * @param amountETH   --> ETH amount provided in liquidity
     * @param amountToken --> token amount provided in liquidity
     * @param wethRP      --> return percentge for ETH based on term period
     * @param tokenRP     --> return percentge for token based on term period
     * --------------------------------------------------------------------
     */
    function _withoutMultiplier(
        uint amountETH, uint amountToken, uint wethRP, uint tokenRP
    ) internal {
            
        uint addedBonusWeth;
        uint addedBonusToken;
        
        if (_offersBonus(weth) && _offersBonus(token)) {
            
            addedBonusWeth = _calculateBonus(amountETH, wethRP);
            addedBonusToken = _calculateBonus(amountToken, tokenRP);
                
            require(_checkForSufficientStakingBonusesForETH(addedBonusWeth)
            && _checkForSufficientStakingBonusesForToken(addedBonusToken),
            "must be sufficient staking bonuses available in pool");
            
            _users[msg.sender].wethBonus = _users[msg.sender].wethBonus.add(addedBonusWeth);
            _users[msg.sender].tokenBonus = _users[msg.sender].tokenBonus.add(addedBonusToken);
            _users[msg.sender].lastPercentWeth = wethRP;
            _users[msg.sender].lastPercentToken = tokenRP;
            _pendingBonusesWeth = _pendingBonusesWeth.add(addedBonusWeth);
            _pendingBonusesToken = _pendingBonusesToken.add(addedBonusToken);
                
        } else if (_offersBonus(weth) && !_offersBonus(token)) {
                
            addedBonusWeth = _calculateBonus(amountETH, wethRP);
                
            require(_checkForSufficientStakingBonusesForETH(addedBonusWeth), 
            "must be sufficient staking bonuses available in pool");
                
            _users[msg.sender].wethBonus = _users[msg.sender].wethBonus.add(addedBonusWeth);
            _users[msg.sender].lastPercentWeth = wethRP;
            _pendingBonusesWeth = _pendingBonusesWeth.add(addedBonusWeth);
                
        } else if (!_offersBonus(weth) && _offersBonus(token)) {
                
            addedBonusToken = _calculateBonus(amountToken, tokenRP);
                
            require(_checkForSufficientStakingBonusesForToken(addedBonusToken),
            "must be sufficient staking bonuses available in pool");
                
            _users[msg.sender].tokenBonus = _users[msg.sender].tokenBonus.add(addedBonusToken);
            _users[msg.sender].lastPercentToken = tokenRP;
            _pendingBonusesToken = _pendingBonusesToken.add(addedBonusToken);
        }
    }
    
    function _resolveMultiplier(
        uint _term, uint amountETH, uint amountToken, uint wethRP, uint tokenRP, Multiplier _multiplier
    ) internal {
        
        uint addedBonusWeth;
        uint addedBonusToken;
        
        require(_multiplier.balance(msg.sender) > 0, "No Multiplier balance to use");
        if (_term > _multiplier.lockupPeriod(msg.sender)) _multiplier.updateLockupPeriod(msg.sender, _term);
            
        uint multipliedETH = _proportion(_multiplier.balance(msg.sender), uToken1, address(weth));
        uint multipliedToken = _proportion(multipliedETH, address(weth), address(token));
            
        if (_offersBonus(weth) && _offersBonus(token)) {
                        
            if (multipliedETH > amountETH) {
                multipliedETH = (_calculateBonus((amountETH.mul(_multiplier.getMultiplierCeiling())), wethRP));
                addedBonusWeth = multipliedETH;
            } else {
                addedBonusWeth = (_calculateBonus((amountETH.add(multipliedETH)), wethRP));
            }
                
            if (multipliedToken > amountToken) {
                multipliedToken = (_calculateBonus((amountToken.mul(_multiplier.getMultiplierCeiling())), tokenRP));
                addedBonusToken = multipliedToken;
            } else {
                addedBonusToken = (_calculateBonus((amountToken.add(multipliedToken)), tokenRP));
            }
                    
            require(_checkForSufficientStakingBonusesForETH(addedBonusWeth)
            && _checkForSufficientStakingBonusesForToken(addedBonusToken),
            "must be sufficient staking bonuses available in pool");
                                
            _users[msg.sender].wethBonus = _users[msg.sender].wethBonus.add(addedBonusWeth);
            _users[msg.sender].tokenBonus = _users[msg.sender].tokenBonus.add(addedBonusToken);
            _users[msg.sender].lastPercentWeth = wethRP.mul(2);
            _users[msg.sender].lastPercentToken = tokenRP.mul(2);
            _pendingBonusesWeth = _pendingBonusesWeth.add(addedBonusWeth);
            _pendingBonusesToken = _pendingBonusesToken.add(addedBonusToken);
                    
        } else if (_offersBonus(weth) && !_offersBonus(token)) {
                    
            if (multipliedETH > amountETH) {
                multipliedETH = (_calculateBonus((amountETH.mul(_multiplier.getMultiplierCeiling())), wethRP));
                addedBonusWeth = multipliedETH;
            } else {
                addedBonusWeth = (_calculateBonus((amountETH.add(multipliedETH)), wethRP));
            }
                        
            require(_checkForSufficientStakingBonusesForETH(addedBonusWeth), 
            "must be sufficient staking bonuses available in pool");
                    
            _users[msg.sender].wethBonus = _users[msg.sender].wethBonus.add(addedBonusWeth);
            _users[msg.sender].lastPercentWeth = wethRP.mul(2);
            _pendingBonusesWeth = _pendingBonusesWeth.add(addedBonusWeth);
                        
        } else if (!_offersBonus(weth) && _offersBonus(token)) {
            
            if (multipliedToken > amountToken) {
                multipliedToken = (_calculateBonus((amountToken.mul(_multiplier.getMultiplierCeiling())), tokenRP));
                addedBonusToken = multipliedToken;
            } else {
                addedBonusToken = (_calculateBonus((amountToken.add(multipliedToken)), tokenRP));
            }
            
            require(_checkForSufficientStakingBonusesForToken(addedBonusToken),
            "must be sufficient staking bonuses available in pool");
         
            _users[msg.sender].tokenBonus = _users[msg.sender].tokenBonus.add(addedBonusToken);
            _users[msg.sender].lastPercentToken = tokenRP.mul(2);
            _pendingBonusesToken = _pendingBonusesToken.add(addedBonusToken);
        }
    }    
    
    function _updateLastProvision(
        uint timestamp, uint term, uint tokenProvided, 
        uint ethProvided, uint _multiplier
    ) internal {
        
        _users[msg.sender].lastAction = timestamp;
        _users[msg.sender].lastTerm = term;
        _users[msg.sender].lastTokenProvided = tokenProvided;
        _users[msg.sender].lastWethProvided = ethProvided;
        _users[msg.sender].multiplier = _multiplier == 1 ? true : false;
    }
    
    function _zeroBalances() internal {
        
        _users[msg.sender].wethWithdrawn = 0;
        _users[msg.sender].tokenWithdrawn = 0;
        _users[msg.sender].wethBonus = 0;
        _users[msg.sender].tokenBonus = 0;
    }
    
    function _withdrawUserBonus(uint _id) internal {
        
        uint releasedToken = _calculateTokenReleasedAmount(msg.sender);
        uint releasedETH = _calculateETHReleasedAmount(msg.sender);
        
        if (releasedToken > 0 && releasedETH > 0) {
            
            _withdrawUserTokenBonus(msg.sender, releasedToken, _id);
            _withdrawUserETHBonus(msg.sender, releasedETH, _id);
            
        } else if (releasedETH > 0 && releasedToken == 0) 
            _withdrawUserETHBonus(msg.sender, releasedETH, _id);
        
        else if (releasedETH == 0 && releasedToken > 0)
            _withdrawUserTokenBonus(msg.sender, releasedToken, _id);
    }
    
    /* 
     * @dev withdraw ETH bonus earned from locking up liquidity
     * --------------------------------------------------------------
     * @param _user          --> address of the user making withdrawal
     * @param releasedAmount --> released ETH to be withdrawn
     * ------------------------------------------------------------------
     * returns whether successfully withdrawn or not.
     */
    function _withdrawUserETHBonus(address payable _user, uint releasedAmount, uint _id) internal returns(bool) {
     
        _users[_user].wethWithdrawn = _users[_user].wethWithdrawn.add(releasedAmount);
        _pendingBonusesWeth = _pendingBonusesWeth.sub(releasedAmount);
        
        (uint fee, uint feeInETH) = _calculateETHFee(releasedAmount);
        
        if(_id == 1) require(IERC20(uToken1).transferFrom(_user, platformWallet, fee), "must approve fee");
        else require(IERC20(uToken2).transferFrom(_user, platformWallet, fee), "must approve fee");
        
        _user.transfer(releasedAmount);
        
        emit UserETHBonusWithdrawn(_user, releasedAmount, feeInETH);
        return true;
    }
    
    /* 
     * @dev withdraw token bonus earned from locking up liquidity
     * --------------------------------------------------------------
     * @param _user          --> address of the user making withdrawal
     * @param releasedAmount --> released token to be withdrawn
     * ------------------------------------------------------------------
     * returns whether successfully withdrawn or not.
     */
    function _withdrawUserTokenBonus(address _user, uint releasedAmount, uint _id) internal returns(bool) {
        
        _users[_user].tokenWithdrawn = _users[_user].tokenWithdrawn.add(releasedAmount);
        _pendingBonusesToken = _pendingBonusesToken.sub(releasedAmount);
        
        (uint fee, uint feeInToken) = _calculateTokenFee(releasedAmount);
        if(_id == 1) require(IERC20(uToken1).transferFrom(_user, platformWallet, fee), "must approve fee");
        else require(IERC20(uToken2).transferFrom(_user, platformWallet, fee), "must approve fee");
        
        token.transfer(_user, releasedAmount);
    
        emit UserTokenBonusWithdrawn(_user, releasedAmount, feeInToken);
        return true;
    }
    
    /* 
     * @dev gets an asset's amount in proportion of a pair asset
     * ---------------------------------------------------------
     * param _amount --> the amount of first asset
     * param _tokenA --> the address of the first asset
     * param _tokenB --> the address of the second asset
     * -------------------------------------------------
     * returns the propotion of the _tokenB
     */ 
    function _proportion(uint _amount, address _tokenA, address _tokenB) internal view returns(uint tokenBAmount) {
        
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(address(iPancakeFactory), _tokenA, _tokenB);
        
        return PancakeLibrary.quote(_amount, reserveA, reserveB);
    }
    
    /* 
     * @dev gets the released Token value
     * --------------------------------
     * param _user --> the address of the user
     * ------------------------------------------------------
     * returns the released amount in Token
     */ 
    function _calculateTokenReleasedAmount(address _user) internal view returns(uint) {

        uint release = _users[_user].release;
        uint start = _users[_user].start;
        uint taken = _users[_user].tokenWithdrawn;
        uint tokenBonus = _users[_user].tokenBonus;
        uint releasedPct;
        
        if (now >= release) releasedPct = 100;
        else releasedPct = ((now.sub(start)).mul(100000)).div((release.sub(start)).mul(1000));
        
        uint released = (((tokenBonus).mul(releasedPct)).div(100));
        return released.sub(taken);
    }
    
    /* 
     * @dev gets the released ETH value
     * --------------------------------
     * param _user --> the address of the user
     * ------------------------------------------------------
     * returns the released amount in ETH
     */ 
    function _calculateETHReleasedAmount(address _user) internal view returns(uint) {
        
        uint release = _users[_user].release;
        uint start = _users[_user].start;
        uint taken = _users[_user].wethWithdrawn;
        uint wethBonus = _users[_user].wethBonus;
        uint releasedPct;
        
        if (now >= release) releasedPct = 100;
        else releasedPct = ((now.sub(start)).mul(10000)).div((release.sub(start)).mul(100));
        
        uint released = (((wethBonus).mul(releasedPct)).div(100));
        return released.sub(taken);
    }
    
    /* 
     * @dev get the required fee for the released token bonus in the utility token
     * -------------------------------------------------------------------------------
     * param _user --> the address of the user
     * ----------------------------------------------------------
     * returns the fee amount in the utility token and Token
     */ 
    function _calculateTokenFee(uint _amount) internal view returns(uint uTokenFee, uint tokenFee) {
        
        uint fee = (_amount.mul(10)).div(100);
        uint feeInETH = _proportion(fee, address(token), address(weth));
        uint feeInUtoken = _proportion(feeInETH, address(weth), uToken1); 
        
        return (feeInUtoken, fee);
    }
    
    /* 
     * @dev get the required fee for the released ETH bonus in the utility token
     * -------------------------------------------------------------------------------
     * param _user --> the address of the user
     * ----------------------------------------------------------
     * returns the fee amount in the utility token and ETH
     */ 
    function _calculateETHFee(uint _amount) internal view returns(uint uTokenFee, uint ethFee) {
        
        uint fee = (_amount.mul(10)).div(100);
        uint feeInUtoken = _proportion(fee, address(weth), uToken1); 
        
        return (feeInUtoken, fee);
    }
    
    /* 
     * @dev get the required fee for the released ETH bonus   
     * -------------------------------------------------------------------------------
     * param _user --> the address of the user
     * ----------------------------------------------------------
     * returns the fee amount.
     */ 
    function calculateETHBonusFee(address _user) external view returns(uint ETH_Fee) {
        
        uint wethReleased = _calculateETHReleasedAmount(_user);
        
        if (wethReleased > 0) {
            
            (uint feeForWethInUtoken,) = _calculateETHFee(wethReleased);
            
            return feeForWethInUtoken;
            
        } else return 0;
    }
    
    /* 
     * @dev get the required fee for the released token bonus   
     * -------------------------------------------------------------------------------
     * param _user --> the address of the user
     * ----------------------------------------------------------
     * returns the fee amount.
     */ 
    function calculateTokenBonusFee(address _user) external view returns(uint token_Fee) {
        
        uint tokenReleased = _calculateTokenReleasedAmount(_user);
        
        if (tokenReleased > 0) {
            
            (uint feeForTokenInUtoken,) = _calculateTokenFee(tokenReleased);
            
            return feeForTokenInUtoken;
            
        } else return 0;
    }
    
    /* 
     * @dev get the bonus based on the return percentage for a particular locking term.   
     * -------------------------------------------------------------------------------
     * param _amount           --> the amount to calculate bonus from.
     * param _returnPercentage --> the returnPercentage of the term.
     * ----------------------------------------------------------
     * returns the bonus amount.
     */ 
    function _calculateBonus(uint _amount, uint _returnPercentage) internal pure returns(uint) {
        
        return ((_amount.mul(_returnPercentage)).div(100000)) / 2;                                  //  1% = 1000
    }
    
    /* 
     * @dev get the correct return percentage based on locked term.   
     * -----------------------------------------------------------
     * @param _token --> associated asset.
     * @param _term --> the locking term.
     * ----------------------------------------------------------
     * returns the return percentage.
     */   
    function _calculateReturnPercentage(IERC20 _token, uint _term) internal view returns(uint) {
        
        if (_token == weth) {
            if (_term == period1) return period1RPWeth;
            else if (_term == period2) return period2RPWeth;
            else if (_term == period3) return period3RPWeth;
            else if (_term == period4) return period4RPWeth;
            else return 0;
            
        } else if (_token == token) {
            if (_term == period1) return period1RPToken;
            else if (_term == period2) return period2RPToken;
            else if (_term == period3) return period3RPToken;
            else if (_term == period4) return period4RPToken;
            else return 0;
        }
    }
    
    /* 
     * @dev check whether the input locking term is one of the supported terms.  
     * ----------------------------------------------------------------------
     * @param _term --> the locking term.
     * --------------------------------------------------
     * returns whether true or not and the period's index
     */   
    function _isValidTerm(uint _term) internal view returns(bool isValid, uint Period) {
        
        if (_term == period1) return (true, 1);
        else if (_term == period2) return (true, 2);
        else if (_term == period3) return (true, 3);
        else if (_term == period4) return (true, 4);
        else return (false, 0);
    }
    
    /* 
     * @dev check whether the inputted user token has currently offers bonus  
     * ----------------------------------------------------------------------
     * @param _token --> associated token
     * ---------------------------------------
     * returns whether true or not.
     */  
    function _offersBonus(IERC20 _token) internal view returns (bool) {
        
        if (_token == weth) {
            uint wethRPTotal = period1RPWeth.add(period2RPWeth).add(period3RPWeth).add(period4RPWeth);
            if (wethRPTotal > 0) return true; 
            else return false;
            
        } else if (_token == token) {
            uint tokenRPTotal = period1RPToken.add(period2RPToken).add(period3RPToken).add(period4RPToken);
            if (tokenRPTotal > 0) return true;
            else return false;
        }
    }
    
    /* 
     * @dev check whether the pool has sufficient amount of bonuses available for new deposits/stakes.   
     * ----------------------------------------------------------------------------------------------
     * @param amount --> the _amount to be evaluated against.
     * ---------------------------------------------------
     * returns whether true or not.
     */ 
    function _checkForSufficientStakingBonusesForETH(uint _amount) internal view returns(bool) {
        
        if ((address(this).balance).sub(_pendingBonusesWeth) >= _amount) {
            return true;
        } else {
            return false;
        }
    }
    
    /* 
     * @dev check whether the pool has sufficient amount of bonuses available for new deposits/stakes.   
     * ----------------------------------------------------------------------------------------------
     * @param amount --> the _amount to be evaluated against.
     * ---------------------------------------------------
     * returns whether true or not.
     */ 
    function _checkForSufficientStakingBonusesForToken(uint _amount) internal view returns(bool) {
       
        if ((token.balanceOf(address(this)).sub(_pendingBonusesToken)) >= _amount) {
            
            return true;
            
        } else {
            
            return false;
        }
    }
    
}