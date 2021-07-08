/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;


// Part: ERC20Interface

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint);
}

// Part: Goblin

interface Goblin {

    /// @dev Work on a (potentially new) position. Optionally send surplus token back to Bank.
    function work(uint256 id, address user, address borrowToken, uint256 borrow, uint256 debt, bytes calldata data) external payable;

    /// @dev Return the amount of ETH wei to get back if we are to liquidate the position.
    function health(uint256 id, address borrowToken) external view returns (uint256);

    /// @dev Liquidate the given position to token need. Send all ETH back to Bank.
    function liquidate(uint256 id, address user, address borrowToken) external;

    /// @dev Re-invest whatever the goblin is working on.
    function reinvest() external;
}

// File: contracts/interfaces/IMdexRouter.sol

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WBNB() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
    external
    returns (
        uint amountA,
        uint amountB,
        uint liquidity
    );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
    external
    payable
    returns (
        uint amountToken,
        uint amountETH,
        uint liquidity
    );

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path)
    external
    view
    returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path)
    external
    view
    returns (uint[] memory amounts);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

// File: contracts/interfaces/IMdexPair.sol

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// Part: Strategy
interface Strategy {
    function execute(address user, address borrowToken, uint256 borrow, uint256 debt, bytes calldata data) external payable;
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

contract BoardroomMDX {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accMDXPerShare;
        uint256 mdxAmount;
    }

    address public mdx;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    function deposit(uint256 _pid, uint256 _amount) public {}
    function withdraw(uint256 _pid, uint256 _amount) public {}
    function pending(uint256 _pid, address _user) external view returns (uint256) {}
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 val) internal {
        (bool success, ) = to.call{value:val}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}


// Part: Initializable

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || _isConstructor() || !_initialized,
            'Initializable: contract is already initialized'
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}
// Part: ReentrancyGuardUpgradeSafe

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
 */
contract ReentrancyGuardUpgradeSafe is Initializable {
    // counter to allow mutex lock with only one SSTORE operation
    uint private _guardCounter;

    function __ReentrancyGuardUpgradeSafe__init() internal initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, 'ReentrancyGuard: reentrant call');
    }

    uint[50] private ______gap;
}

// Part: Governable

contract Governable is Initializable {
    address public governor; // The current governor.
    address public pendingGovernor; // The address pending to become the governor once accepted.

    modifier onlyGov() {
        require(msg.sender == governor, 'not the governor');
        _;
    }

    /// @dev Initialize the bank smart contract, using msg.sender as the first governor.
    function __Governable__init() internal initializer {
        governor = msg.sender;
        pendingGovernor = address(0);
    }

    /// @dev Set the pending governor, which will be the governor once accepted.
    /// @param _pendingGovernor The address to become the pending governor.
    function setPendingGovernor(address _pendingGovernor) external onlyGov {
        pendingGovernor = _pendingGovernor;
    }

    /// @dev Accept to become the new governor. Must be called by the pending governor.
    function acceptGovernor() external {
        require(msg.sender == pendingGovernor, 'not the pending governor');
        pendingGovernor = address(0);
        governor = msg.sender;
    }
}

interface IDebtToken {
    function setOkHolders(address[] calldata _okHolders, bool _isOk) external;
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

interface IFairLaunch {
    function poolLength() external view returns (uint256);

    function addPool(
        uint256 _allocPoint,
        address _stakeToken,
        bool _withUpdate
    ) external;

    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function updatePool(uint256 _pid) external;

    function deposit(address _for, uint256 _pid, uint256 _amount) external;

    function withdraw(address _for, uint256 _pid, uint256 _amount) external;

    function withdrawAll(address _for, uint256 _pid) external;

    function harvest(uint256 _pid) external;
}



contract MdexWorkerGoblin is Governable,ReentrancyGuardUpgradeSafe, Goblin {
    /// @notice Libraries
    using SafeToken for address;
    using SafeMath for uint;

    /// @notice Events
    event Reinvest(address indexed caller, uint reward, uint bounty);
    event AddShare(uint indexed id, uint share);
    event RemoveShare(uint indexed id, uint share);
    event Liquidate(uint256 indexed id, address lpTokenAddress, uint256 lpAmount, address debtToken, uint256 liqAmount);

    BoardroomMDX public masterChef;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    IUniswapV2Pair public lpToken;

    address public wbnb;
    uint256 public pid;
    address public fairLaunchAddr;
    uint256 public fairLaunchPoolId;

    address public baseToken;
    address public farmingToken;

    address public debtToken;
    address public operator;

    /// @notice Mutable state variables
    mapping(uint => uint) public shares;
    mapping(address => bool) public okStrats;
    uint public totalShare;

    uint public feeBps;
    address public devAddr;

    Strategy public addStrat; // use StrategyAllBNBOnly strat (for reinvesting)
    Strategy public liqStrat;

    mapping(address => bool) public killWhitelist;

    address[] public path;
    uint256 public rewardBalance;

    /// @dev Require that the caller must be an EOA account to avoid flash loans.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, 'not eoa');
        _;
    }

    /// @dev Require that the caller must be the operator (the bank).
    modifier onlyOperator() {
        require(msg.sender == operator, "not operator");
        _;
    }

    function initialize(
        address _operator,
        IUniswapV2Router02 _router,
        uint _pid,
        Strategy _addStrat,
        Strategy _liqStrat,
        uint _feeBps,
        address _devAddr,
        address _fairLaunchAddr,
        address _baseToken,
        address[] calldata _path,
        BoardroomMDX _masterChef

    ) external initializer {
        __Governable__init();
        __ReentrancyGuardUpgradeSafe__init();


        operator = _operator;
        wbnb = _router.WBNB();
        router = _router;
        factory = IUniswapV2Factory(_router.factory());
        masterChef = _masterChef;
        feeBps = _feeBps;
        devAddr = _devAddr;
        fairLaunchAddr = _fairLaunchAddr;

        // Get lpToken and fToken from MasterChef pool
        pid = _pid;
        (IERC20 _farmingToken, , , , ) = masterChef.poolInfo(_pid);

        baseToken = _baseToken;
        farmingToken = address(_farmingToken);

        addStrat = _addStrat;
        liqStrat = _liqStrat;

        okStrats[address(addStrat)] = true;
        okStrats[address(liqStrat)] = true;

        path = _path;
    }

    /// @dev Work on the given position. Must be called by the operator.
    /// @param id The position ID to work on.
    /// @param user The original user that is interacting with the operator.
    /// @param borrowToken The token user borrow from bank.
    /// @param borrow The amount user borrow form bank.
    /// @param debt The user's debt amount.
    /// @param data The encoded data, consisting of strategy address and bytes to strategy.
    function work(uint256 id, address user, address borrowToken, uint256 borrow, uint256 debt, bytes calldata data)
    override
    external
    payable
    onlyOperator
    nonReentrant
    {
        require(borrowToken == baseToken || borrowToken == address(0), "borrowToken not token0 and token1");

        // 1. Convert this position back to LP tokens.
        _removeShare(id,user);
        // 2. Perform the worker strategy; sending LP tokens + borrowToken; expecting LP tokens.
        (address strategy, bytes memory ext) = abi.decode(data, (address, bytes));
        require(okStrats[strategy], "unapproved work strategy");

        farmingToken.safeTransfer(strategy,actualFarmingTokenBalance());
        // transfer the borrow token.
        if (borrow > 0 && borrowToken != address(0)) {
            borrowToken.safeTransferFrom(msg.sender, address(this), borrow);
            borrowToken.safeApprove(address(strategy), 0);
            borrowToken.safeApprove(address(strategy), uint256(-1));
        }
        Strategy(strategy).execute{value:msg.value}(user, borrowToken, borrow, debt, ext);

        // 3. Add token back to the farming pool.
        _addShare(id,user);

        if (borrowToken == address(0)) {
            SafeToken.safeTransferETH(msg.sender, address(this).balance);
        } else {
            uint256 borrowTokenAmount = borrowToken.myBalance();
            if(borrowTokenAmount > 0){
                SafeToken.safeTransfer(borrowToken, msg.sender, borrowTokenAmount);
            }
        }
    }

    /// @dev Liquidate the given position by converting it to debtToken and return back to caller.
    /// @param id The position ID to perform liquidation.
    /// @param borrowToken The token user borrow from bank.
    function liquidate(uint256 id, address user, address borrowToken)
    override
    external
    onlyOperator
    nonReentrant
    {
        bool isBorrowBNB = borrowToken == address(0);
        // 1. Convert the position back to LP tokens and use liquidate strategy.
        _removeShare(id,user);
        farmingToken.safeTransfer(address(liqStrat), actualFarmingTokenBalance());
        liqStrat.execute(address(0), borrowToken, uint256(0), uint256(0), abi.encode(uint256(0)));

        // 2. transfer borrowToken and user want back to goblin.
        uint256 tokenLiquidate;
        if (isBorrowBNB){
            tokenLiquidate = address(this).balance;
            SafeToken.safeTransferETH(msg.sender, tokenLiquidate);
        } else {
            tokenLiquidate = borrowToken.myBalance();
            borrowToken.safeTransfer(msg.sender, tokenLiquidate);
        }
        emit Liquidate(id, farmingToken, actualFarmingTokenBalance(), borrowToken, tokenLiquidate);
    }


    /// @dev Re-invest whatever this worker has earned back to staked LP tokens.
    function reinvest() override public onlyEOA nonReentrant {
        require(killWhitelist[msg.sender],"Not Whitelist");
        // 1. Approve tokens
        farmingToken.safeApprove(address(masterChef), uint256(-1));

        // 2. reset all reward balance since all rewards will be reinvested
        rewardBalance = 0;

        // 3. Withdraw all the rewards.
        masterChef.withdraw(pid,0);
        uint256 reward = farmingToken.myBalance();
        if (reward == 0) return;

        // 4. Send the reward bounty to the caller.
        uint fee = reward.mul(feeBps) / 10000;
        farmingToken.safeTransfer(devAddr,fee);

        // 5. re stake the farming token to get more rewards
        masterChef.deposit(pid,reward.sub(fee));

        // 6. Reset approval
        farmingToken.safeApprove(address(masterChef), 0);
        emit Reinvest(msg.sender, reward, 0);
    }

    /// @dev Return the amount of debt token to receive if we are to liquidate the given position.
    /// @param id The position ID to perform health check.
    function health(uint256 id, address /* borrowToken */) override external view returns (uint256) {
        IUniswapV2Pair currentLP;
        uint256[] memory amount;
        address[] memory reversedPath = getReversedPath();
        amount = new uint256[](reversedPath.length);
        amount[0] = shareToBalance(shares[id]);

        for(uint256 i = 1; i < reversedPath.length; i++) {
            /// 1. Get the current LP based on the specified paths.
            currentLP = IUniswapV2Pair(factory.getPair(reversedPath[i-1], reversedPath[i]));
            /// 2. Get the pool's total supply of the token of path i-1 and the token of path i.
            (uint256 r0, uint256 r1,) = currentLP.getReserves();
            (uint256 rOut, uint256 rIn) = currentLP.token0() == reversedPath[i] ? (r0, r1) : (r1, r0);
            /// 3. Convert all amount on the token of path i-1 to the token of path i.
            amount[i] = getMktSellAmount(
                amount[i-1], rIn, rOut
            );
        }
        /// @notice return the last amount, since the last amount is the amount that we shall get in baseToken if we sell the farmingToken at the market price
        return amount[amount.length - 1];
    }

    /// @dev Return the entitied LP token balance for the given shares.
    /// @param share The number of shares to be converted to LP balance.
    function shareToBalance(uint share) public view returns (uint) {
        if (totalShare == 0) return share; // When there's no share, 1 share = 1 balance.
        (uint totalBalance, ) = masterChef.userInfo(pid, address(this));
        return share.mul(totalBalance).div(totalShare);
    }

    /// @dev Return the number of shares to receive if staking the given LP tokens.
    /// @param balance the number of LP tokens to be converted to shares.
    function balanceToShare(uint balance) public view returns (uint) {
        if (totalShare == 0) return balance; // When there's no share, 1 share = 1 balance.
        (uint totalBalance, ) = masterChef.userInfo(pid, address(this));
        return balance.mul(totalShare).div(totalBalance);
    }

    /// @notice since reward gaining from the masterchef is the same token with farmingToken,
    /// thus the rewardBalance exists to differentiate an actual farming token balance without taking reward balance into account
    function actualFarmingTokenBalance() internal view returns (uint256) {
        return farmingToken.myBalance().sub(rewardBalance);
    }

    /// @dev Internal function to stake all outstanding LP tokens to the given position ID.
    function _addShare(uint id,address user) internal {
        uint256 shareBalance = actualFarmingTokenBalance();
        if (shareBalance > 0) {
            // 1. Approve token to be spend by masterChef
            address(farmingToken).safeApprove(address(masterChef), uint256(-1));
            // 2. Convert balance to share
            uint256 share = balanceToShare(shareBalance);
            // 3. Update shares
            shares[id] = shares[id].add(share);
            totalShare = totalShare.add(share);
            rewardBalance = rewardBalance.add(masterChef.pending(pid, address(this)));
            // 4. Deposit balance to PancakeMasterChef
            masterChef.deposit(pid,shareBalance);
            // 5. Deposit DebtToken to Rabbit FairLaunch
            // _fairLaunchDeposit(user,share);
            // 6. Reset approve token
            address(farmingToken).safeApprove(address(masterChef), 0);
            emit AddShare(id, share);
        }
    }

    /// @dev Internal function to remove shares of the ID and convert to outstanding LP tokens.
    function _removeShare(uint id,address user) internal {
        uint share = shares[id];
        if (share > 0) {
            uint balance = shareToBalance(share);
            totalShare = totalShare.sub(share);
            shares[id] = 0;

            rewardBalance = rewardBalance.add(masterChef.pending(pid, address(this)));
            masterChef.withdraw(pid,balance);
            //   _fairLaunchWithdraw(user,share);

            emit RemoveShare(id, share);
        }
    }

    /// @dev Return maximum output given the input amount and the status of Uniswap reserves.
    /// @param aIn The amount of asset to market sell.
    /// @param rIn the amount of asset in reserve for input.
    /// @param rOut The amount of asset in reserve for output.
    function getMktSellAmount(uint256 aIn, uint256 rIn, uint256 rOut) public pure returns (uint256) {
        if (aIn == 0) return 0;
        require(rIn > 0 && rOut > 0, "bad reserve values");
        uint256 aInWithFee = aIn.mul(997);
        uint256 numerator = aInWithFee.mul(rOut);
        uint256 denominator = rIn.mul(1000).add(aInWithFee);
        return numerator / denominator;
    }

    /// @dev Return the path that the worker is working on.
    function getPath() external view returns (address[] memory) {
        return path;
    }

    /// @dev Return the inverse path.
    function getReversedPath() public view returns (address[] memory) {
        address tmp;
        address[] memory reversedPath = path;
        for (uint i = 0; i < reversedPath.length / 2; i++) {
            tmp = reversedPath[i];
            reversedPath[i] = reversedPath[reversedPath.length - i - 1];
            reversedPath[reversedPath.length - i - 1] = tmp;
        }
        return reversedPath;
    }

    /// @dev Mint & deposit debtToken on behalf of farmers
    /// @param amount The amount of debt that the position holds
    function _fairLaunchDeposit(address user, uint256 amount) internal {
        if (amount > 0) {
            IDebtToken(debtToken).mint(address(this), amount);
            IFairLaunch(fairLaunchAddr).deposit(user, fairLaunchPoolId, amount);
        }
    }

    /// @dev Withdraw & burn debtToken on behalf of farmers
    function _fairLaunchWithdraw(address user, uint256 amount) internal {
        // if cannot withdraw from FairLaunch somehow. 0xb5c5f672 is a signature of withdraw(address,uint256,uint256)
        (bool success, ) = fairLaunchAddr.call(abi.encodeWithSelector(0xb5c5f672, user, fairLaunchPoolId, amount));
        if(success) IDebtToken(debtToken).burn(address(this), amount);
    }

    /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
    /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
    /// @param to The address to send the tokens to.
    /// @param value The number of tokens to transfer to `to`.
    function recover(
        address token,
        address to,
        uint value
    ) external onlyGov nonReentrant {
        token.safeTransfer(to, value);
    }

    function setFeeBps(uint _feeBps) external onlyGov{
        feeBps = _feeBps;
    }

    function setDevAddr(address _addr) external onlyGov{
        devAddr = _addr;
    }

    /// @dev Set the given strategies' approval status.
    /// @param strats The strategy addresses.
    /// @param isOk Whether to approve or unapprove the given strategies.
    function setStrategyOk(address[] calldata strats, bool isOk) external onlyGov {
        uint len = strats.length;
        for (uint idx = 0; idx < len; idx++) {
            okStrats[strats[idx]] = isOk;
        }
    }

    /// @dev Set a new path. In case that the liquidity of the given path is changed.
    /// @param _path The new path.
    function setPath(address[] calldata _path) external onlyGov {
        require(_path.length >= 2, "CakeMaxiWorker::setPath:: path length must be >= 2");
        require(_path[0] == baseToken && _path[_path.length-1] == farmingToken, "CakeMaxiWorker::setPath:: path must start with base token and end with farming token");
        path = _path;
    }

    /// @dev Update critical strategy smart contracts. EMERGENCY ONLY. Bad strategies can steal funds.
    /// @param _addStrat The new add strategy contract.
    /// @param _liqStrat The new liquidate strategy contract.
    function setCriticalStrategies(Strategy _addStrat, Strategy _liqStrat) external onlyGov {
        addStrat = _addStrat;
        liqStrat = _liqStrat;
    }

    /// @dev Update debtToken to a new address. Must only be called by owner.
    function updateDebtToken(address _debtToken, uint256 _newPid) external onlyGov {
        address[] memory okHolders = new address[](2);
        okHolders[0] = address(this);
        okHolders[1] = fairLaunchAddr;
        IDebtToken(_debtToken).setOkHolders(okHolders, true);
        debtToken = _debtToken;
        fairLaunchPoolId = _newPid;
        SafeToken.safeApprove(debtToken, fairLaunchAddr, uint256(-1));
    }

    function setFairLaunchPoolId(uint256 _poolId) external onlyGov {
        SafeToken.safeApprove(debtToken, fairLaunchAddr, uint256(-1));
        fairLaunchPoolId = _poolId;
    }

    function transferOperator(address _newOperator) external onlyGov{
        operator = _newOperator;
    }

    function createkillWhitelist(address addr,bool status) external onlyGov {
        killWhitelist[addr] = status;
    }

    receive() external payable {}
}