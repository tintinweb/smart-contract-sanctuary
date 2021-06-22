/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// File: localhost/mint/openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: localhost/mint/openzeppelin/contracts/proxy/Clones.sol

 

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// File: localhost/mint/interface/IMintLever.sol

 

pragma solidity 0.7.4;





/**
杠杆挖矿
 */
interface IMintLever {

    /**
    资产对
     */
    event Pair(address indexed tokenA, address indexed tokenB);

    /**
    设置清算费率
    
    clearingEarningRate:清算费率
     */
    event ClearingEarningRate(uint256 clearingEarningRate);

    /**
    设置最大风险率

    maxRiskRate:最大风险率
     */
    event MaxRiskRate(uint256 maxRiskRate);

    /**
    杠杆倍数
     */
    event LeverageRange(uint256 maxLeverage, uint256 minLeverage);

    /**
    挖矿合约
     */
    event Mint(address indexed exchange);

    /**
    变化后的仓位

    user:用户
    capitalToken:本金资产类型
    capitalAmount:本金资产数量
    borrowLoans:借贷合约
    borrowTokens:借贷资产类型
    borrowAmounts:借贷资产数量
    bondTokens:保证金资产类型
    bondAmounts:保证金资产数量
     */
    event Position(address indexed user, address indexed capitalToken, uint256 capitalAmount, address[] borrowLoans, address[] borrowTokens, uint256[] borrowAmounts, address[] bondTokens, uint256[] bondAmounts);

    /**
    直接清算平仓

    user:用户
     */
    event DirectClearingPosition(address indexed user);

    /**
    先还后清算平仓

    user:用户
     */
    event IndirectClearingPosition(address indexed user);

    /**
    初始化参数
    
    config
    maxLeverage
    minLeverage
    clearingEarningRate
    clearingPlatformEarningRate
    maxRiskRate
    liquidity
    capitalToken
     */
    function init(address owner, Config config, uint256 maxLeverage, uint256 minLeverage, uint256 clearingEarningRate, uint256 clearingPlatformEarningRate, uint256 maxRiskRate) external;

    function openPosition(uint256 amountA, uint256 amountB, uint256 leverage, IExchange exchange, address borrowToken, uint256 deadLine) external;

    function closePosition(uint256 percentage, uint256 deadLine) external;

    function repay(address token, uint256 amount) external;

    function directClearingPosition(address user, uint256 percentage) external;

    function indirectClearingPosition(address user, uint256 percentage) external;

    function setConfig(Config config) external;

    function setOpen(bool open) external;

    function setBlacklist(address user, bool state) external;

    function getPair() external view returns (address, address);

    function setClearingEarningRate(uint256 clearingEarningRate) external;
    
    function setClearingPlatformEarningRate(uint256 clearingPlatformEarningRate) external;

    function setMaxRiskRate(uint256 maxRiskRate) external;
    
    function harvest() external;

    function getEarning(address user) external view returns (address[] memory, uint256[] memory);

    function getRiskRate(address user) external view returns (uint256, uint8);

    function setLeverage(uint256 maxLeverage, uint256 minLeverage) external;

    function getDebt(address user) external view returns (address, uint256);
    
    function getBond(address user) external view returns (address[] memory, uint256[] memory);

    function getStake(address user) external view returns (address, uint256);

    function addBond(address token, uint256 amount) external;

    function removeBond(address token, uint256 amount) external;

}
// File: localhost/mint/interface/ILiquidity.sol

 

pragma solidity 0.7.4;

/**
流动性
 */
interface ILiquidity {
    
    /**
    初始化参数

    liquidity:流动性合约地址
     */
    function init(address liquidity) external;

    /**
    添加流动性
    
    tokenA:tokenA
    tokenB:tokenB
    amountA:tokenA的数量
    amountB:tokenB的数量
    liquidity:流动性数量
    amount:流动性数量
     */
    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external returns (uint256, uint256, address, uint256);
    
    /**
    移除流动性

    tokenA:tokenA
    tokenB:tokenB
    liquidity:流动性数量
     */
    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity) external;

}
// File: localhost/mint/interface/IMint.sol

 

pragma solidity 0.7.4;

/**
挖矿
 */
interface IMint {

    /**
    初始化参数

    mint:挖矿合约地址
     */
    function init(address mint) external;

    /**
    查询质押数量
     */
    function getStake(address user) external returns (uint256 amount);

    /**
    查询收益
     */
    function getEarning(address user) external view returns (address[] memory tokens, uint256[] memory earnings);

    /**
    质押

    user:用户    
    lp:流动性凭证
    amount:数量
     */
    function stake(address user, address lp, uint256 amount) external;
    
    /**
    质押
    
    user:用户
    lp:流动性凭证
    amount:数量
     */
    function unStake(address user, address lp, uint256 amount) external;

    /**
    领取收益

    user:用户
     */
    function harvest(address user) external;

}
// File: localhost/mint/openzeppelin/contracts/utils/Context.sol

 

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: localhost/mint/openzeppelin/contracts/access/Ownable.sol

 

pragma solidity >=0.6.0 <0.8.0;

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
    //constructor () internal {
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

// File: localhost/mint/tripartitePlatform/publics/IPublics.sol

 

pragma solidity 0.7.4;

interface IPublics {

    function claimComp(address holder) external returns (uint256);
    
}
// File: localhost/mint/tripartitePlatform/publics/ILoanTypeBase.sol

 

pragma solidity 0.7.4;

interface ILoanTypeBase {
    enum LoanType {NORMAL, MARGIN_SWAP_PROTOCOL, MINNING_SWAP_PROTOCOL}
}
// File: localhost/mint/tripartitePlatform/publics/ILoanPublics.sol

 

pragma solidity 0.7.4;


interface ILoanPublics {
    
    //授权
    function mint(uint256 mintAmount) external returns (uint256, uint256);//存款
    
    function redeem(uint256 redeemTokens) external returns (uint256, uint256);//取款
    
    function borrowBalanceCurrent(address account, ILoanTypeBase.LoanType loanType) external view returns (uint256);//待还
    
    /**
     *@notice 信用贷借款
     *@param _borrower:实际借款人的地址
     *@param _borrowAmount:实际借款数量(精度18)
     *@return (uint256): 错误码
     */
    function doCreditLoanBorrow(address _borrower, uint256 _borrowAmount, ILoanTypeBase.LoanType _loanType) external returns (uint256);


    /**
     *@notice 信用贷还款
     *@param _payer:实际还款人的地址
     *@param _repayAmount:实际还款数量(精度18)
     *@return (uint256, uint256): 错误码, 实际还款数量
     */
    function doCreditLoanRepay(address _payer, uint256 _repayAmount, ILoanTypeBase.LoanType _loanType) external returns (uint256, uint256);

}



// File: localhost/mint/interface/IExchange.sol

 

pragma solidity 0.7.4;

/**
兑换
 */
interface IExchange {

    /**
    初始化参数

    exchange:兑换合约地址
     */
    function init(address exchange) external;

    /**
    兑换

    tokenIn:输入token
    tokenOut:输出token
    amountIn:输入数量
    amountOut:输出数量
     */
    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut);
    
    /**
    兑换预估

    tokenIn:输入token
    tokenOut:输出token
    amountIn:输入数量
    amountOut:预估输出数量    
     */
    function swapEstimate(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256 amountOut);

}
// File: localhost/mint/interface/ILoan.sol

 

pragma solidity 0.7.4;

/**
借贷
 */
interface ILoan {
    
    /**
    初始化参数

    loan:借贷合约地址
     */
    // function init(address loan) external;
    
    /**
    借款

    user:借款人
    token:资产合约地址
    amount:借款数量
     */
    function borrow(address user, address token, uint256 amount) external returns (bool);

    /**
    全额还款
    
    user:借款人
    token:资产合约地址
     */
    function fullRepayment(address user, address token) external;
    
    /**
    部分还款
    
    user:借款人
    token:资产合约地址
    amount:还款数量
     */
    function partialRepayment(address user, address token, uint256 amount) external;
    
    function deposit(address token, uint256 amount) external;

    function withdraw(address token, uint256 amount) external;

    /**
    查询年利率

    token:资产合约地址
     */
    function getInterestRate(address token) external view returns (uint256);

    /**
    查询利息数量

    user:借款人
    token:资产合约地址
     */
    function getInterest(address user, address token) external view returns (uint256);

    /**
    查询本金、利息数量

    user:借款人
    token:资产合约地址
     */
    function getPrincipalInterest(address user, address token) external view returns (uint256);

}
// File: localhost/mint/interface/IAssetPrice.sol

 

pragma solidity 0.7.4;

/**
资产价格
 */
interface IAssetPrice {
    
    /**
    查询资产价格
    
    tokenQuote:报价资产合约地址
    tokenBase:计价资产合约地址
    price:报价
    decimal:精度
     */
    function getPrice(address tokenQuote, address tokenBase) external view returns (uint256, uint8);

    /**
    查询资产对USD价格
    
    token:报价资产合约地址
    price:报价
    decimal:精度
     */
    function getPriceUSD(address token) external view returns (uint256, uint8);

    /**
    查询价格精度
    tokenQuote:报价资产合约地址
    tokenBase:计价资产合约地址
     */
    function decimal(address tokenQuote, address tokenBase) external view returns (uint8);

}
// File: localhost/mint/implement/Config.sol

 

pragma solidity 0.7.4;







contract Config is Ownable {
    
    /**
    设置资产标记价格合约地址
     */
    event AssetPrice(address indexed assetPrice);
    
    /**
    设置借贷白名单

    name:名称
    loan:借贷合约地址
    state:状态，true:开启，false:关闭
     */
    event Loan(string name, address indexed loan, bool state);
    
    /**
    设置兑换白名单
    
    name:名称
    exchange:兑换合约地址
    state:状态，true:开启，false:关闭
     */
    event Exchange(string name, address indexed exchange, bool state);
    
    /**
    设置保证金白名单

    bond:保证金资产合约地址    
    state:状态，true:开启，false:关闭
     */
    event Bond(string name, address indexed bond, bool state);
    
    /**
    设置可贷资产白名单
    
    loanToken:可贷资产合约地址
    state:状态，true:开启，false:关闭
     */
    event LoanToken(string name, address indexed loanToken, bool state);
        
    /**
    设置USDT合约地址

    usdt:USDT合约地址
     */
    event Usdt(address indexed usdt);
    
    /**
    设置USDC合约地址

    usdc:USDC合约地址
     */
    event Usdc(address indexed usdd);
    
    event Exchange(address indexed exchange);
    
    /**
    设置loanPublics合约地址
    
    token:
    loanPublics:loanPublics合约地址
     */
    event LoanPublics(address indexed token, address indexed loanPublics);
    
    /**
    设置publics合约地址

    publics:publics合约地址
     */
    event Publics(address indexed publics);

    /**
    设置杠杆挖矿平台手续地址

    mintPlatformFee:收取手续费地址
     */
    event MintPlatformFee(address indexed mintPlatformFee);

    IAssetPrice public assetPrice;//资产标记价格合约地址
    mapping(address => bool) public loans;//借贷合约地址
    mapping(address => string) public loanNames;//借贷合约地址
    mapping(address => bool) public exchanges;//主流资产兑换合约地址
    mapping(address => string) public exchangeNames;//主流资产兑换合约地址
    mapping(address => bool) public bonds;//保证金资产白名单
    mapping(address => string) public bondNames;//保证金资产白名单
    mapping(address => bool) public loanTokens;//可借贷资产白名单
    mapping(address => string) public loanTokenNames;//可借贷资产白名单
    address public usdt;//USDT合约地址
    address public usdc;//USDC合约地址
    IExchange public exchange;//
    mapping(address => ILoanPublics) public loanPublics;//借贷平台
    IPublics public publics;//平台币合约地址
    address public mintPlatformFee;//收取杠杆挖矿平台手续地址
        
    /**
    设置资产标记价格合约地址
     */
    function setAssetPrice(IAssetPrice _assetPrice) external onlyOwner {
        require(address(0) != address(_assetPrice), "publics:assetPrice_error");
        assetPrice = _assetPrice;
        emit AssetPrice(address(_assetPrice));
    }
    
    /**
    设置配资合约地址
     */
    function setLoan(string memory name, address loan, bool state) external onlyOwner {
        require(address(0) != loan, "publics:loan_error");
        loans[loan] = state;
        loanNames[loan] = name;
        emit Loan(name, loan, state);
    }
    
    /**
    设置资产兑换合约地址
     */
    function setExchange(string memory name, address _exchange, bool state) external onlyOwner {
        require(address(0) != _exchange, "publics:exchange_error");
        exchanges[_exchange] = state;
        exchangeNames[_exchange] = name;
        emit Exchange(name, _exchange, state);
    }

    /**
    设置保证金资产白名单
     */
    function setBond(string memory name, address bond, bool state) external onlyOwner {
        require(address(0) != bond, "publics:bond_error");
        bonds[bond] = state;
        bondNames[bond] = name;
        emit Bond(name, bond, state);
    }

    /**
    设置可借贷资产白名单
     */
    function setLoanToken(string memory name, address loanToken, bool state) external onlyOwner {
        require(address(0) != loanToken, "publics:loanToken_error");
        loanTokens[loanToken] = state;
        loanTokenNames[loanToken] = name;
        emit LoanToken(name, loanToken, state);
    }

    /**
    USDT合约地址
     */
    function setUsdt(address _usdt) external onlyOwner {
        require(address(0) != _usdt, "publics:usdt_error");
        usdt = _usdt;
        emit Usdt(_usdt);
    }

    /**
    USDC合约地址
     */
    function setUsdc(address _usdc) external onlyOwner {
        require(address(0) != _usdc, "publics:usdc_error");
        usdc = _usdc;
        emit Usdc(_usdc);
    }
    
    function setExchange(IExchange _exchange) external onlyOwner {
        require(address(0) != address(_exchange), "publics:exchange_error");
        exchange = _exchange;
        emit Exchange(address(_exchange));
    }

    /**
    设置借贷平台
     */
    function setLoanPublics(address token, ILoanPublics _loanPublics) external onlyOwner {
        require(address(0) != token, "publics:token_error");
        require(address(0) != address(_loanPublics), "publics:loanPublics_error");
        loanPublics[token] = _loanPublics;
        emit LoanPublics(token, address(_loanPublics));
    }
    
    /**
    设置平台币合约地址
     */
    function setPublics(IPublics _publics) external onlyOwner {
        require(address(0) != address(_publics), "publics:publics_error");
        publics = _publics;
        emit Publics(address(_publics));
    }
    
    /**
    设置收取杠杆挖矿平台手续地址
     */
    function setMintPlatformFee(address _mintPlatformFee) external onlyOwner {
        require(address(0) != address(_mintPlatformFee), "publics:mintPlatformFee_error");
        mintPlatformFee = _mintPlatformFee;
        emit MintPlatformFee(mintPlatformFee);
    }

}
// File: localhost/mint/implement/ConfigBase.sol

 

pragma solidity 0.7.4;


contract ConfigBase is Ownable {
    
    event Config_(address indexed config);
    
    Config public config;
    
    constructor (Config _config) {
        require(address(0) != address(_config), "publics:config_error");
        config = _config;
        emit Config_(address(_config));
    }
    
    function setConfig(Config _config) external onlyOwner {
        require(address(0) != address(_config), "publics:config_error");
        config = _config;
        emit Config_(address(_config));
    }
    
}
// File: localhost/mint/implement/MintLeverFactory.sol

 

pragma solidity 0.7.4;







contract MintLeverFactory is ConfigBase {
    
    using SafeMath for uint256;
        
    /**
    创建杠杆挖矿标的

    mintLever:挖矿合约地址
     */
    event CreateMintLever(uint256 index, address indexed mintLever);

    address[] public mints;
    
    constructor (Config _config) ConfigBase(_config) {
    }

    function getMints() external view returns (address[] memory) {
        return mints;
    }

    function getMintCount() external view returns (uint256) {
        return mints.length;
    }

    function clone(address template, uint256 maxLeverage, uint256 minLeverage, uint256 clearingEarningRate, uint256 clearingPlatformEarningRate, uint256 maxRiskRate) external onlyOwner {
        require(address(0) != template, "publics:template_is_zero");
        address mintLever = Clones.clone(template);
        require(address(0) != mintLever, "publics:clone_error");
        mints.push(mintLever);
        IMintLever(mintLever).init(msg.sender, config, maxLeverage, minLeverage, clearingEarningRate, clearingPlatformEarningRate, maxRiskRate);
        emit CreateMintLever(mints.length.sub(1), mintLever);
    }
}