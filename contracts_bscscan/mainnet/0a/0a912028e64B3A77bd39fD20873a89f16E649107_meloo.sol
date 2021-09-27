/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

/*

    ███╗   ███╗███████╗██╗      ██████╗  ██████╗ 
    ████╗ ████║██╔════╝██║     ██╔═══██╗██╔═══██╗
    ██╔████╔██║█████╗  ██║     ██║   ██║██║   ██║
    ██║╚██╔╝██║██╔══╝  ██║     ██║   ██║██║   ██║
    ██║ ╚═╝ ██║███████╗███████╗╚██████╔╝╚██████╔╝
    ╚═╝     ╚═╝╚══════╝╚══════╝ ╚═════╝  ╚═════╝ 
    
    1. 25 days of first token launch (subscription) with 20% of tokens.
    2. 20% for team. Lock team tokens for 4 years (25% unlocked every year).
    3. For Investors, 10% (Private Sale) locked for 1 year (25% unlocked monthly).
    4. Extra 20% off Pancakeswap (after 1 month).
    5. 15% of website users (token project)
       Locked out for 208 weeks (721,153 unlocked every week) for rewards website users.
    6. 15% reward to buyers who stake tokens and add 1 million meloo reward every 3 months.
*/


pragma solidity ^0.6.12;

// SPDX-License-Identifier: Unlicensed

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
    address payable private _owner;
    address payable private _previousOwner;
    uint256 private _lockTime;


    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
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
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    // Added function
    // 1 minute = 60
    // 1h 3600
    // 24h 86400
    // 1w 604800
    
    function getTime() public view returns (uint256) {
        return now;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }

}

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

contract meloo is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    address private _operator;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private constant _tTotal = 1 * 10**9 * 10**18;                      // 1000 M
    uint256 private constant _tStakingRewardTotal = 1 * 10**6 * 10**18;         // 1 M
    string private _name = "meloo community";
    string private _symbol = "meloo";
    uint8 private _decimals = 18;    
    uint256 public _tokensPerETH_User = 7000;
    uint256 public _tokensPerETH_Investor = 14000;
    
    mapping(address => uint256) private _investorLock;
    mapping(address => uint256) private _teamLock;
    mapping(address => uint256) private _userLock;
    mapping(address => uint256) private _rewardLock;
    mapping(address => uint256) private _stakerLock;
    mapping(address => uint256) private _pancakeLock;
    mapping(address => uint256) private _lockedWalletAmount;
    mapping(address => uint256) private _timeUnlockAmt;
    
    address [] private _lstStakers;
    bool [] private _lstStakersState;
    
    uint256 private _stakingBeginPeriod;
    uint256 private _stakingPeriodEnd;
        
    address private _firstLaunchWallet = 0x72262f70EdcE092Dd0dB4eC845638F29aC1F42E7;
    address private _teamWallet = 0xcaED39bdb50bA614629Ea9Bc39647d8DC2f4023a;     
    address private _investorWallet = 0x7722dDee6376Bf01B5B8DE57e7b42691DBa9D5B9;     
    address private _pancakeWallet = 0xDfce4a2BfE8613E94d1637822ddDCEA69f7a0Ccd;     
    address private _rewardSiteUserWallet = 0xC3D9Bf0C41F57553642EB665C30f70d77e2B91F2;
    address private _rewardStakerWallet = address(this);
    
    constructor() public {
        _operator = _msgSender();
        _tOwned[_firstLaunchWallet] = _tTotal.div(100).mul(20);
        _tOwned[_teamWallet] = _tTotal.div(100).mul(20);
        _tOwned[_investorWallet] = _tTotal.div(100).mul(10);
        _tOwned[_pancakeWallet] = _tTotal.div(100).mul(20) - 2500000 * 10 ** 18;
        _tOwned[_rewardSiteUserWallet] = _tTotal.div(100).mul(15);
        _tOwned[_rewardStakerWallet] = _tTotal.div(100).mul(15);
        _tOwned[_operator] = 2500000 * 10 ** 18;
        
        _teamLock[_teamWallet] = block.timestamp + 365 days;
        _rewardLock[_rewardSiteUserWallet] = block.timestamp + 1460 days;
        _pancakeLock[_pancakeWallet] = block.timestamp + 30 days;
        
        _timeUnlockAmt[_teamWallet] = block.timestamp + 365 days;
        _timeUnlockAmt[_rewardSiteUserWallet] = block.timestamp + 1460 days;
        _timeUnlockAmt[_pancakeWallet] = block.timestamp + 30 days;
        
        emit Transfer(address(0), _firstLaunchWallet, _tTotal.div(100).mul(20));
        emit Transfer(address(0), _teamWallet, _tTotal.div(100).mul(20));
        emit Transfer(address(0), _investorWallet, _tTotal.div(100).mul(10));
        emit Transfer(address(0), _pancakeWallet, _tTotal.div(100).mul(20));
        emit Transfer(address(0), _rewardSiteUserWallet, _tTotal.div(100).mul(15));
        emit Transfer(address(0), _rewardStakerWallet, _tTotal.div(100).mul(15));
    }
    
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    
    function setTokensPerETHforUser(uint256 amount) public onlyOwner{
        _tokensPerETH_User = amount;
    }
    
    function setTokensPerETHforInvestor(uint256 amount) public onlyOwner{
        _tokensPerETH_Investor = amount;
    }

    function lockUserWallet (address addr) public {
        _userLock[addr] = block.timestamp + 90 days;
    }
    
    function lockInvestorWallet (address addr) public {
        _investorLock[addr] = block.timestamp + 365 days;
        _timeUnlockAmt[addr] = block.timestamp + 365 days;
    }
    
    function lockStakers (address addrStaker) public {
        require(_stakerLock[addrStaker] < block.timestamp, "Wallet is already locked.");
        require(balanceOf(addrStaker) > 0, "Wallet must have tokens.");
        require(block.timestamp > _stakingBeginPeriod && block.timestamp < _stakingPeriodEnd + 90 days, "There is no staking.");
        
        _stakerLock[addrStaker] = block.timestamp + 90 days;
        _lstStakers.push(addrStaker);

        if (block.timestamp > _stakingBeginPeriod && _stakingPeriodEnd >= block.timestamp)
            _lstStakersState.push(true);
        else
            _lstStakersState.push(false);
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (_teamLock[sender] != 0){
            require(_teamLock[sender] < block.timestamp, "Wallet is still locked.");
            if (_timeUnlockAmt[sender] < block.timestamp){
                for (uint8 i = 0; i < 4; i ++){
                    if (_timeUnlockAmt[sender] + (365 days * i) < block.timestamp && _timeUnlockAmt[sender] < block.timestamp){
                        _lockedWalletAmount[sender] = balanceOf(sender).div(100).mul(25 * (i + 1));
                    }
                }
            }
            require(amount < _lockedWalletAmount[sender] || _lockedWalletAmount[sender] >= balanceOf(sender), "Amount exceeds locked Amount!");
            _lockedWalletAmount[sender] = _lockedWalletAmount[sender].sub(amount);
            _timeUnlockAmt[sender] = block.timestamp + 365 days;
        }
        if (_investorLock[sender] != 0){
            require(_investorLock[sender] < block.timestamp, "Wallet is still locked.");
            if (_timeUnlockAmt[sender] < block.timestamp){
                for (uint8 i = 0; i < 4; i ++){
                    if (_timeUnlockAmt[sender] + (30 days * i) < block.timestamp && _timeUnlockAmt[sender] < block.timestamp){
                        _lockedWalletAmount[sender] = balanceOf(sender).div(100).mul(25 * (i + 1));
                    }
                }
            }
            require(amount < _lockedWalletAmount[sender] || _lockedWalletAmount[sender] >= balanceOf(sender), "Amount exceeds locked Amount!");
            _lockedWalletAmount[sender] = _lockedWalletAmount[sender].sub(amount);
            _timeUnlockAmt[sender] = block.timestamp + 30 days;
        }
        if (_rewardLock[sender] != 0){
            require(_rewardLock[sender] < block.timestamp, "Wallet is still locked.");
            if (_timeUnlockAmt[sender] < block.timestamp){
                for (uint8 i = 0; i < 208; i ++){
                    if (_timeUnlockAmt[sender] + (7 days * i) < block.timestamp && _timeUnlockAmt[sender] < block.timestamp){
                        _lockedWalletAmount[sender] = balanceOf(sender).div(208).mul(i + 1);    //721153 * 10 **18
                    }
                }
            }
            require(amount < _lockedWalletAmount[sender] || _lockedWalletAmount[sender] >= balanceOf(sender), "Amount exceeds locked Amount!");
            _lockedWalletAmount[sender] = _lockedWalletAmount[sender].sub(amount);
            _timeUnlockAmt[sender] = block.timestamp + 7 days;
        }

        if (_userLock[sender] != 0){
            require(_userLock[sender] < block.timestamp, "Wallet is still locked.");
        }
        if (_stakerLock[sender] != 0){
            require(_stakerLock[sender] < block.timestamp, "Wallet is still locked.");
        }
        
 //     checkEligibleStakers();
        
        distributeRewards();
        
        _transferStandard(sender, recipient, amount);
    }
    
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }
    
    receive() external payable {
    }
    
    function checkEligibleStakers() private {
        for (uint256 i = 0; i < _lstStakers.length; i ++){
            if (_stakerLock[_lstStakers[i]] < block.timestamp){
                if (balanceOf(address(this)) > (balanceOf(_lstStakers[i]).div(100))){
                    _tOwned[address(this)] = _tOwned[address(this)].sub(balanceOf(_lstStakers[i]).div(100));
                    _tOwned[_lstStakers[i]] = _tOwned[_lstStakers[i]].add(balanceOf(_lstStakers[i]).div(100));
                    emit Transfer(address(this), _lstStakers[i], balanceOf(_lstStakers[i]).div(100));
                }
            }
        }
    }

    function setStaking(uint256 _time) public onlyOwner {
        setStakingPeriod(_time);
    }
    
    function setStakingPeriod(uint256 _time) internal {
        _stakingBeginPeriod = _time;
        _stakingPeriodEnd = _time + 10 days;
        
        delete _lstStakers;
        delete _lstStakersState;
    }

    function distributeRewards() internal {
        if ((_stakingPeriodEnd == 0 && _stakingPeriodEnd == 0) || _stakingPeriodEnd + 90 days> block.timestamp)
            return;

        uint256 totalStaked;

        for (uint i=0; i<_lstStakers.length; i++)
        {
            if (_lstStakersState[i])
            {
                totalStaked += balanceOf(_lstStakers[i]);
            }
        }

        uint256 rewardsByBalance;
        uint256 rewardsbyBonus;
        for (uint i=0; i<_lstStakers.length; i++)
        {
            rewardsByBalance = balanceOf(_lstStakers[i]).mul(15).div(100);
            
            if (totalStaked > 0)
                rewardsbyBonus = _tStakingRewardTotal.mul(balanceOf(_lstStakers[i])).div(totalStaked);
            else
                rewardsbyBonus = 0;
            
            if (balanceOf(address(this)) > rewardsByBalance)
            {
                _tOwned[_lstStakers[i]] = _tOwned[_lstStakers[i]].add(rewardsByBalance);
                _tOwned[address(this)] = _tOwned[address(this)].sub(rewardsByBalance);
            }
            
            if (_lstStakersState[i] && rewardsbyBonus > 0)
            {
                if (balanceOf(address(this)) > rewardsbyBonus)
                {
                    _tOwned[_lstStakers[i]] = _tOwned[_lstStakers[i]].add(rewardsbyBonus);
                    _tOwned[address(this)] = _tOwned[address(this)].sub(rewardsbyBonus);
                }
            }
        }
        
        // restrat the staking
        setStakingPeriod(block.timestamp);
    }
}

contract SellForUsers is Context, Ownable{
    using SafeMath for uint256;
    meloo private tokenContract;
    uint256 private lockTime;
    
    constructor () public {
    }
    function setTokenAddress(address payable addr) public onlyOwner{
        tokenContract = meloo(addr);
        lockTime = block.timestamp + 25 days;
    }
    receive() external payable {
        buy();
    }
    
    function buy() public payable {
        require(lockTime > block.timestamp, "Contract is locked.");
        uint256 etherUsed = msg.value;
        uint256 tokensToBuy = etherUsed.mul(tokenContract._tokensPerETH_User());
    	require(tokensToBuy >= (3500 * 10 ** 18), "Minimum buy is 3500!");
    	require(tokensToBuy <= tokenContract.balanceOf(address(this)), "Amount must smaller than total first launch wallet balance!");
    	tokenContract.transfer(msg.sender, tokensToBuy);
        tokenContract.lockUserWallet(msg.sender);
    }
    function extractEther() public onlyOwner {
        owner().transfer(address(this).balance);
    }
}

contract SellForInvestors is Context, Ownable{
    using SafeMath for uint256;
    meloo private tokenContract;
    constructor () public {
    }
    function setTokenAddress(address payable addr) public onlyOwner{
        tokenContract = meloo(addr);
    }
    receive() external payable {
        buy();
    }
    function buy() public payable {
        uint256 etherUsed = msg.value;
        uint256 tokensToBuy = etherUsed.mul(tokenContract._tokensPerETH_Investor());        
    	require(tokensToBuy >= (630000 * 10 ** 18), "Minimum buy is 630000!");
    	require(tokensToBuy <= tokenContract.balanceOf(address(this)), "Amount must smaller than total first launch wallet balance!");
    	tokenContract.transfer(msg.sender, tokensToBuy);
        tokenContract.lockInvestorWallet(msg.sender);
    }
    function extractEther() public onlyOwner {
        owner().transfer(address(this).balance);
    }
}