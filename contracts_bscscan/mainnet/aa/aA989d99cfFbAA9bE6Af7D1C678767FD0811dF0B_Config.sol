/**
 *Submitted for verification at BscScan.com on 2021-07-09
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
        // leeqiang
        // require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

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

// File: localhost/mint/tripartitePlatform/publics/ILoanTypeBase.sol

 

pragma solidity 0.7.4;

interface ILoanTypeBase {
    enum LoanType {NORMAL, MARGIN_SWAP_PROTOCOL, MINNING_SWAP_PROTOCOL}
}
// File: localhost/mint/tripartitePlatform/publics/ILoanPublics.sol

 

pragma solidity 0.7.4;


interface ILoanPublics {

    /**
     *@notice 获取依赖资产地址
     *@return (address): 地址
     */
    // function underlying() external view returns (address);

    /**
     *@notice 真实借款数量（本息)
     *@param _account:实际借款人地址
     *@param _loanType:借款类型
     *@return (uint256): 错误码(0表示正确)
     */
    function borrowBalanceCurrent(address _account, uint256 id, ILoanTypeBase.LoanType _loanType) external returns (uint256);

    /**
     *@notice 用户存款
     *@param _mintAmount: 存入金额
     *@return (uint256, uint256): 错误码(0表示正确), 获取pToken数量
     */
    function mint(uint256 _mintAmount) external returns (uint256, uint256);

    /**
     *@notice 用户指定pToken取款
     *@param _redeemTokens: pToken数量
     *@return (uint256, uint256): 错误码(0表示正确), 获取Token数量，对应pToken数量
     */
    function redeem(uint256 _redeemTokens) external returns (uint256, uint256, uint256);

    /**
     *@notice 用户指定Token取款
     *@param _redeemAmount: Token数量
     *@return (uint256, uint256, uint256): 错误码(0表示正确), 获取Token数量，对应pToken数量
     */
    function redeemUnderlying(uint256 _redeemAmount) external returns (uint256, uint256, uint256);

    /**
     *@notice 获取用户的资产快照信息
     *@param _account: 用户地址
     *@param _id: 仓位id
     *@param _loanType: 借款类型
     *@return (uint256, uint256, uint256, uint256): 错误码(0表示正确), pToken数量, 借款(快照)数量, 兑换率
     */
    function getAccountSnapshot(address _account, uint256 _id, ILoanTypeBase.LoanType _loanType) external view returns (uint256, uint256, uint256, uint256);

    /**
     *@notice 信用贷借款
     *@param _borrower:实际借款人的地址
     *@param _borrowAmount:实际借款数量
     *@param _id: 仓位id
     *@param _loanType:借款类型
     *@return (uint256): 错误码
     */
    function doCreditLoanBorrow(address _borrower, uint256 _borrowAmount, uint256 _id, ILoanTypeBase.LoanType _loanType) external returns (uint256);

    /**
     *@notice 信用贷还款
     *@param _payer:实际还款人的地址
     *@param _repayAmount:实际还款数量
     *@param _id: 仓位id
     *@param _loanType:借款类型
     *@return (uint256, uint256): 错误码, 实际还款数量
     */
    function doCreditLoanRepay(address _payer, uint256 _repayAmount, uint256 _id, ILoanTypeBase.LoanType _loanType) external returns (uint256, uint256);

}

// File: localhost/mint/openzeppelin/contracts/token/ERC20/IERC20.sol

 

pragma solidity >=0.6.0 <0.8.0;

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
    自行加入
     */
    function decimals() external view returns (uint8);

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

// File: localhost/mint/tripartitePlatform/publics/IPublics.sol

 

pragma solidity 0.7.4;


interface IPublics is IERC20 {

    function claimComp(address holder) external returns (uint256);
    
}
// File: localhost/mint/interface/IAssetPrice.sol

 

pragma solidity 0.7.4;

/**
资产价格
 */
interface IAssetPrice {
    
    /**
    查询资产价格
    
    quote:报价资产合约地址
    base:计价资产合约地址

    code:1
    price:价格
    decimal:精度
     */
    function getPriceV1(address quote, address base) external view returns (uint8, uint256, uint8);
    
    /**
    查询资产价格
    
    quote:报价资产合约地址
    base:计价资产合约地址
    decimal:精度
    
    code:1
    price:价格
     */
    function getPriceV2(address quote, address base, uint8 decimal) external view returns (uint8, uint256);

    /**
    查询资产对USD价格
    
    token:报价资产合约地址
    
    code:1
    price:价格
    decimal:精度
     */
    function getPriceUSDV1(address token) external view returns (uint8, uint256, uint8);
    
    /**
    查询资产对USD价格
    
    token:报价资产合约地址
    decimal:精度
    
    code:1
    price:价格
     */
    function getPriceUSDV2(address token, uint8 decimal) external view returns (uint8, uint256);

    /**
    查询资产价值

    token:报价资产合约地址
    amount:数量
    
    code:1
    usd:USD
    decimal:精度
     */
    function getUSDV1(address token, uint256 amount) external view returns (uint8, uint256, uint8);
    
    /**
    查询资产价值

    token:报价资产合约地址
    amount:数量
    decimal:精度

    code:1
    usd:USD
     */
    function getUSDV2(address token, uint256 amount, uint8 decimal) external view returns (uint8, uint256);
    
}
// File: localhost/mint/interface/IExchange.sol

 

pragma solidity 0.7.4;

interface IExchange {
    
    /**
     * 兑换
     * 
     * from:from
     * to:to
     * amount:amount
     * deadLine:deadLine
     * 
     * return:兑换数量
     */
    function swap(address from, address to, uint256 amount, uint256 deadLine) external returns (uint256);
    
    
    /**
     * 预估兑换
     * 
     * from:from
     * to:to
     * amount:amount
     * 
     * return:预估兑换数量
     */
    function swapEstimate(address from, address to, uint256 amount) external view returns (uint256);

}
// File: localhost/mint/interface/IMintLeverRouter.sol

 

pragma solidity 0.7.4;

interface IMintLeverRouter {
    
    function canClearing(address mintLever, address user) external view returns (bool);
    
    function getBondUSD(address mintLever, address user, uint8 decimal) external view returns (uint256);
    
    function getDebtUSD(address mintLever, address user, uint8 decimal) external view returns (uint256);
    
    function getBond(address mintLever, address user) external view returns (address[] memory, uint256[] memory);

}
// File: localhost/mint/interface/IBorrowProxy.sol

 

pragma solidity 0.7.4;

interface IBorrowProxy {
    
    function setBorrowAccess(address spender, bool state) external;
    
    function borrow(address owner, uint256 id, address tokenA, uint256 amountA, address tokenB, uint256 amountB, address borrowToken, uint256 leverage, uint256 deadLine) external returns(uint256, uint256, uint256);

}
// File: localhost/mint/interface/IApproveProxy.sol

 

pragma solidity 0.7.4;

interface IApproveProxy {
    
    function setClaimAccess(address spender, bool state) external;
    
    function claim(address token, address owner, address spender, uint256 amount) external;
        
}
// File: localhost/mint/interface/IConfig.sol

 

pragma solidity 0.7.4;









interface IConfig {
    
    function getOracleDecimal(address quote, address base) external view returns (uint8, uint8);
    
    function getOracleSources(address quote, address base) external view returns (uint8, address[] memory, uint8[] memory, address[] memory);
    
    function getApproveProxy() external view returns (IApproveProxy);
    
    function getBorrowProxy() external view returns (IBorrowProxy);
    
    function getRouter() external view returns (IMintLeverRouter);

    function getAssetPrice() external view returns (IAssetPrice);
    
    function getLoanPublics(address token) external view returns (ILoanPublics);

    function tryGetLoanPublics(address token) external view returns (ILoanPublics);
    
    function isBond(address token) external view returns (bool);

    function isLoan(address token) external view returns (bool);
    
    function getUsdt() external view returns (address);
    
    function getExchange() external view returns (IExchange);

    function getPublics() external view returns (IPublics);
    
    function getPlatformFee() external view returns (address);
    
    function getSlippage() external view returns (uint256);

    function isBlacklist(address user) external view returns (bool);
    
    function isOpen(address mintLever) external view returns (bool);
    
    function isDirectClearing(address mintLever) external view returns (bool);

    function getLeverage(address mintLever) external view returns (uint256, uint256);

    function isLeverage(address mintLever, uint256 leverage) external view returns (bool);
    
    function getPlatformTakeRate(address mintLever) external view returns (uint256);
    
    function getClearingEarningRate(address mintLever) external view returns (uint256);
    
    function getClearingPlatformEarningRate(address mintLever) external view returns (uint256);
    
    function getMaxRiskRate(address mintLever) external view returns (uint256);

}
// File: localhost/mint/implement/AddressCheck.sol

 

pragma solidity 0.7.4;

abstract contract AddressCheck {
    
    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "publics:parameter_is_zero");
        _;
    }
    
}
// File: localhost/mint/implement/Config.sol

 

pragma solidity 0.7.4;





contract Config is Ownable, IConfig, AddressCheck {
    
    using SafeMath for uint256;
    
    /**
    修改价格数据源

    quote:报价资产合约地址
    base:计价资产合约地址
    oracle:预言机合约地址
    ratio:价格占比权重，A/(A+B+C+D)
    extend:扩展
    decimal:精度
     */
    event UpdateOracleSource(address indexed quote, address indexed base, address indexed oracle, uint8 ratio, address extend, uint8 decimal);
    
    event ApproveProxy(address indexed approveProxy);

    event BorrowProxy(address indexed borrowProxy);

    event Router(address indexed router);
    
    /**
    设置资产标记价格地址

    assetPrice:资产标记价格地址
     */
    event AssetPrice(address indexed assetPrice);
    
    /**
    设置借贷地址
    
    name:名称
    token:资产地址
    loanPublics:借贷地址
     */
    event LoanPublics(string name, address indexed token, address indexed loanPublics);
    
    /**
    设置保证金白名单

    name:名称
    bond:保证金资产地址    
    state:true(开启)，false(关闭)
     */
    event Bond(string name, address indexed bond, bool state);
    
    /**
    设置可贷资产白名单
    
    loanToken:可贷资产地址
    state:true(开启)，false(关闭)
     */
    event LoanToken(string name, address indexed loanToken, bool state);
        
    /**
    设置USDT地址

    usdt:USDT地址
     */
    event Usdt(address indexed usdt);
    
    /**
    设置USDC地址

    usdc:USDC地址
     */
    event Usdc(address indexed usdd);
    
    /**
    设置默认兑换地址

     */
    event Exchange(address indexed exchange);
    
    /**
    设置平台币地址

    publics:平台币地址
     */
    event Publics(address indexed publics);

    /**
    设置杠杆挖矿平台手续地址

    platformFee:收取手续费地址
     */
    event PlatformFee(address indexed platformFee);

    event Slippage(uint256 slippage);

    event Blacklist(address indexed user, bool state);

    event Open(address indexed mintLever, bool state);

    event Visible(address indexed mintLever, bool state);
    
    event DirectClearing(address indexed mintLever, bool state);
    
    event LeverageRange(address indexed mintLever, uint256 maxLeverage, uint256 minLeverage);

    event PlatformTakeRate(address indexed mintLever, uint256 platformTakeRate);
    
    event ClearingEarningRate(address indexed mintLever, uint256 clearingEarningRate);

    event ClearingPlatformEarningRate(address indexed mintLever, uint256 clearingPlatformEarningRate);

    event MaxRiskRate(address indexed mintLever, uint256 maxRiskRate);
    
    mapping(address => mapping(address => uint8)) public decimals;
    mapping(address => mapping(address => mapping(address => bool))) public oracleSourcesV1;
    mapping(address => mapping(address => OracleSource[])) public oracleSourcesV2;
    
    IApproveProxy private approveProxy;
    IBorrowProxy private borrowProxy;
    IMintLeverRouter private router;//router
    IAssetPrice private assetPrice;//资产标记价格地址
    mapping(address => ILoanPublics) private loanPublics;//借贷平台
    mapping(address => string) public loanPublicsNames;//借贷地址
    mapping(address => bool) public bonds;//保证金资产白名单
    mapping(address => string) public bondNames;//保证金资产白名单
    mapping(address => bool) public loanTokens;//可借贷资产白名单
    mapping(address => string) public loanTokenNames;//可借贷资产白名单
    address private usdt;//USDT地址
    address public usdc;//USDC地址
    IExchange private exchange;//默认兑换地址
    IPublics private publics;//平台币地址
    address private platformFee;//收取手续费地址
    uint256 private slippage = 300;//滑点,3%:300,(0,10000)
    mapping(address => bool) public blacklist;//黑名单
    mapping(address => bool) public openlist;//是否开启
    mapping(address => bool) public visiblelist;//是否显示
    mapping(address => bool) public directClearings;//直接清算
    mapping(address => uint256) private maxLeverages;//[minLeverage->]
    mapping(address => uint256) private minLeverages;//[10->maxLeverage]
    mapping(address => uint256) private platformTakeRates;//[0->9999]
    mapping(address => bool) public platformTakeRatesV2;
    mapping(address => uint256) private clearingEarningRates;//[0->9999]
    mapping(address => bool) public clearingEarningRatesV2;
    mapping(address => uint256) private clearingPlatformEarningRates;//[0->9999]
    mapping(address => bool) public clearingPlatformEarningRatesV2;
    mapping(address => uint256) private maxRiskRates;//[1->9999]

    struct OracleSource {
        address oracle;//预言机合约地址
        uint8 ratio;//价格占比权重，A/(A+B+C+D)
        address extend;//扩展
    }
    
    function copy() external {
        // leeqiang
        approveProxy = IApproveProxy(0x02c3a4F454C133d10D919F2CA6A0c38D7BBb294A);
        borrowProxy = IBorrowProxy(0x1F943a814d3AD5B750dF17Af2D1676ab52948Da8);
        router = IMintLeverRouter(0x5715BE9BEa8A6350A3Ee1bD66284ecb9D5f4e0F4);
        assetPrice = IAssetPrice(0xD3b95Db3FB6D0Fc08A30CEF25239E00Ee921fED9);
        loanPublics[0x55d398326f99059fF775485246999027B3197955] = ILoanPublics(0x4f4a4F56EBc9289F7Fb96C401C85c23B3d40ae24);
        loanPublicsNames[0x55d398326f99059fF775485246999027B3197955] = "usdt";
        bonds[0x55d398326f99059fF775485246999027B3197955] = true;
        bondNames[0x55d398326f99059fF775485246999027B3197955] = "usdt";
        loanTokens[0x55d398326f99059fF775485246999027B3197955] = true;
        loanTokenNames[0x55d398326f99059fF775485246999027B3197955] = "usdt";
        usdt = 0x55d398326f99059fF775485246999027B3197955;
        exchange = IExchange(0x51e47D8D571cA10d9E61f9434fa96EEb87200661);
        platformFee = 0xa1468d01e62Da56EEE5f89fDF27F5AC2449645Ae;
        
        // test uni
        this.updateOracleSource(0x18888960b66606A16FC92f842c1621D548c3B43F, 0x0000000000000000000000000000000000000001, 0x872dE36D882cbEbf2aC4139b9c028e2DC2Dd5FF5, 50, 0xb57f259E7C24e56a1dA00F66b55A5640d9f9E7e4, 18);
        // test busd
        this.updateOracleSource(0x90753D53f56BF62d51b4bCD97bD3430eD9Fb19c1, 0x0000000000000000000000000000000000000001, 0x872dE36D882cbEbf2aC4139b9c028e2DC2Dd5FF5, 50, 0xcBb98864Ef56E9042e7d2efef76141f15731B82f, 18);
        // uni
        this.updateOracleSource(0xBf5140A22578168FD562DCcF235E5D43A02ce9B1, 0x0000000000000000000000000000000000000001, 0x872dE36D882cbEbf2aC4139b9c028e2DC2Dd5FF5, 50, 0xb57f259E7C24e56a1dA00F66b55A5640d9f9E7e4, 18);
        // busd
        this.updateOracleSource(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, 0x0000000000000000000000000000000000000001, 0x872dE36D882cbEbf2aC4139b9c028e2DC2Dd5FF5, 50, 0xcBb98864Ef56E9042e7d2efef76141f15731B82f, 18);
        // usdt
        this.updateOracleSource(0x55d398326f99059fF775485246999027B3197955, 0x0000000000000000000000000000000000000001, 0x872dE36D882cbEbf2aC4139b9c028e2DC2Dd5FF5, 50, 0xB97Ad0E74fa7d920791E90258A6E2085088b4320, 18);
    }

    function updateOracleSource(address quote, address base, address oracle, uint8 ratio, address extend, uint8 decimal) external onlyOwner {
        decimals[quote][base] = decimal;
        OracleSource[] storage oracleSources = oracleSourcesV2[quote][base];
        uint256 count = oracleSources.length;
        if (oracleSourcesV1[quote][base][address(oracle)]) {
            if (0 == ratio) {
                for (uint256 i = 0; i < count; i++) {
                    if (oracleSources[i].oracle == oracle) {
                        oracleSources[i] = oracleSources[count.sub(1)];
                        break;
                    }
                }
                oracleSources.pop();
                oracleSourcesV1[quote][base][address(oracle)] = false;
            }else {
                for (uint256 i = 0; i < count; i++) {
                    if (oracleSources[i].oracle == oracle) {
                        oracleSources[i].ratio = ratio;
                        oracleSources[i].extend = extend;
                        break;
                    }
                }
            }
            emit UpdateOracleSource(quote, base, address(oracle), ratio, extend ,decimal);
        }else {
            if (0 < ratio) {
                oracleSources.push(OracleSource({oracle:oracle, ratio:ratio, extend:extend}));
                oracleSourcesV1[quote][base][address(oracle)] = true;
                emit UpdateOracleSource(quote, base, address(oracle), ratio, extend, decimal);
            }
        }
    }
    
    function getOracleDecimal(address quote, address base) override external view returns (uint8, uint8) {
        return (1, decimals[quote][base]);
    }
    
    function getOracleSources(address quote, address base) override external view returns (uint8, address[] memory, uint8[] memory, address[] memory) {
        OracleSource[] memory oracleSources = oracleSourcesV2[quote][base];
        address[] memory oracles = new address[](oracleSources.length);
        uint8[] memory ratios = new uint8[](oracleSources.length);
        address[] memory extends = new address[](oracleSources.length);
        OracleSource memory oracleSource;
        for (uint256 i = 0; i < oracleSources.length; i++) {
            oracleSource = oracleSources[i];
            oracles[i] = oracleSource.oracle;
            ratios[i] = oracleSource.ratio;
            extends[i] = oracleSource.extend;
        }
        return (1, oracles, ratios, extends);
    }
    
    function setApproveProxy(IApproveProxy _approveProxy) external onlyOwner {
        require(address(0) != address(_approveProxy), "publics:approve_proxy_is_zero");
        approveProxy = _approveProxy;
        emit ApproveProxy(address(_approveProxy));
    }
    
    function getApproveProxy() override external view returns (IApproveProxy) {
        require(address(0) != address(approveProxy), "publics:approve_proxy_is_zero");
        return approveProxy;
    }
    
    function setBorrowProxy(IBorrowProxy _borrowProxy) external onlyOwner {
        require(address(0) != address(_borrowProxy), "publics:borrow_proxy_is_zero");
        borrowProxy = _borrowProxy;
        emit BorrowProxy(address(_borrowProxy));
    }
    
    function getBorrowProxy() override external view returns (IBorrowProxy) {
        require(address(0) != address(borrowProxy), "publics:borrow_proxy_is_zero");
        return borrowProxy;
    }
    
    function setRouter(IMintLeverRouter _router) external onlyOwner {
        require(address(0) != address(_router), "publics:router_is_zero");
        router = _router;
        emit Router(address(_router));
    }
    
    function getRouter() override external view returns (IMintLeverRouter) {
        require(address(0) != address(router), "publics:router_is_zero");
        return router;
    }
    
    function setAssetPrice(IAssetPrice _assetPrice) external onlyOwner {
        require(address(0) != address(_assetPrice), "publics:asset_price_is_zero");
        assetPrice = _assetPrice;
        emit AssetPrice(address(_assetPrice));
    }
    
    function getAssetPrice() override external view returns (IAssetPrice) {
        require(address(0) != address(assetPrice), "publics:asset_price_is_zero");
        return assetPrice;
    }
    
    function setLoanPublics(string memory name, address token, ILoanPublics _loanPublics) external onlyOwner {
        require(address(0) != token, "publics:token_is_zero");
        require(address(0) != address(_loanPublics), "publics:loan_publics_is_zero");
        loanPublics[token] = _loanPublics;
        loanPublicsNames[token] = name;
        emit LoanPublics(name, token, address(_loanPublics));
    }
    
    function getLoanPublics(address token) override external view returns (ILoanPublics) {
        ILoanPublics _loanPublics = loanPublics[token];
        require(address(0) != address(_loanPublics), "publics:loan_publics_is_zero");
        return _loanPublics;
    }
    
    function tryGetLoanPublics(address token) override external view returns (ILoanPublics) {
        return loanPublics[token];
    }

    function setBond(string memory name, address bond, bool state) external onlyOwner {
        require(address(0) != bond, "publics:bond_is_zero");
        bonds[bond] = state;
        bondNames[bond] = name;
        emit Bond(name, bond, state);
    }
    
    function isBond(address token) override external view returns (bool) {
        bool state = bonds[token];
        require(state, "publics:bond_invalid");
        return state;
    }

    function setLoanToken(string memory name, address loanToken, bool state) external onlyOwner {
        require(address(0) != loanToken, "publics:loan_token_is_zero");
        loanTokens[loanToken] = state;
        loanTokenNames[loanToken] = name;
        emit LoanToken(name, loanToken, state);
    }
    
    function isLoan(address token) override external view returns (bool) {
        bool state = loanTokens[token];
        require(state, "publics:loan_invalid");
        return state;
    }

    function setUsdt(address _usdt) external onlyOwner {
        require(address(0) != _usdt, "publics:usdt_is_zero");
        usdt = _usdt;
        emit Usdt(_usdt);
    }
    
    function getUsdt() override external view returns (address) {
        require(address(0) != usdt, "publics:usdt_is_zero");
        return usdt;
    }

    function setUsdc(address _usdc) external onlyOwner {
        require(address(0) != _usdc, "publics:usdc_is_zero");
        usdc = _usdc;
        emit Usdc(_usdc);
    }
    
    function setExchange(IExchange _exchange) external onlyOwner {
        require(address(0) != address(_exchange), "publics:exchange_is_zero");
        exchange = _exchange;
        emit Exchange(address(_exchange));
    }
    
    function getExchange() override external view returns (IExchange) {
        require(address(0) != address(exchange), "publics:exchange_is_zero");
        return exchange;
    }
    
    function setPublics(IPublics _publics) external onlyOwner {
        require(address(0) != address(_publics), "publics:publics_is_zero");
        publics = _publics;
        emit Publics(address(_publics));
    }
    
    function getPublics() override external view returns (IPublics) {
        require(address(0) != address(publics), "publics:publics_is_zero");
        return publics;
    }

    function setPlatformFee(address _platformFee) external onlyOwner {
        require(address(0) != _platformFee, "publics:platform_fee_is_zero");
        platformFee = _platformFee;
        emit PlatformFee(platformFee);
    }
    
    function getPlatformFee() override external view returns (address) {
        require(address(0) != platformFee, "publics:platform_fee_is_zero");
        return platformFee;
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        require(0 < _slippage && _slippage < 10000, "publics:slippage_overflow");
        slippage = _slippage;
        emit Slippage(_slippage);
    }

    function getSlippage() override external view returns (uint256) {
        return slippage;
    }
    
    function setBlacklist(address user, bool state) external {
        blacklist[user] = state;
        emit Blacklist(user, state);
    }
    
    function isBlacklist(address user) override external view returns (bool) {
        bool state = blacklist[user];
        require(!state, "publics:user_in_blacklist");
        return state;
    }
    
    function setOpen(address mintLever, bool state) external onlyOwner {
        openlist[mintLever] = state;
        emit Open(mintLever, state);
    }
    
    function isOpen(address mintLever) override external view returns (bool) {
        // leeqiang
        // bool state = openlist[mintLever];
        // require(state, "publics:pool_closed");
        // return state;
        return true;
    }
    
    function setVisible(address mintLever, bool state) external onlyOwner {
        visiblelist[mintLever] = state;
        emit Visible(mintLever, state);
    }

    function setDirectClearing(address mintLever, bool state) external onlyOwner {
        directClearings[mintLever] = state;
        emit DirectClearing(mintLever, state);
    }
    
    function isDirectClearing(address mintLever) override external view returns (bool) {
        // leeqiang
        // bool state = directClearings[mintLever];
        // require(state, "publics:direct_clearing_close");
        // return state;
        return true;
    }

    function setLeverage(address mintLever, uint256 maxLeverage, uint256 minLeverage) external onlyOwner nonZeroAddress(mintLever) {
        require(10 <= minLeverage && minLeverage <= maxLeverage, "publics:leverage_overflow");
        maxLeverages[mintLever] = maxLeverage;
        minLeverages[mintLever] = minLeverage;
        emit LeverageRange(mintLever, maxLeverage, minLeverage);
    }
    
    function getLeverage(address mintLever) override external view returns (uint256, uint256) {
        uint256 maxLeverage = maxLeverages[mintLever];
        uint256 minLeverage = minLeverages[mintLever];
        require(10 <= minLeverage && minLeverage <= maxLeverage, "publics:leverage_overflow");
        return (maxLeverage, minLeverage);
    }
    
    function isLeverage(address mintLever, uint256 leverage) override external view returns (bool) {
        // leeqiang
        // (uint256 maxLeverage, uint256 minLeverage) = this.getLeverage(mintLever);
        // require(minLeverage <= leverage && leverage <= maxLeverage, "publics:leverage_overflow");
        return true;
    }
    
    function setPlatformTakeRate(address mintLever, uint256 platformTakeRate) external onlyOwner nonZeroAddress(mintLever) {
        require(0 <= platformTakeRate && platformTakeRate < 10000, "publics:platform_take_rate_overflow");
        platformTakeRates[mintLever] = platformTakeRate;
        platformTakeRatesV2[mintLever] = true;
        emit PlatformTakeRate(mintLever, platformTakeRate);
    }
    
    function getPlatformTakeRate(address mintLever) override external view returns (uint256) {
        // leeqiang
        // require(platformTakeRatesV2[mintLever], "publics:platform_take_rate_overflow");
        // return platformTakeRates[mintLever];
        return 1000;
    }
    
    function setClearingEarningRate(address mintLever, uint256 clearingEarningRate) external onlyOwner nonZeroAddress(mintLever) {
        require(0 <= clearingEarningRate && clearingEarningRate < 10000, "publics:clearing_earning_rate_overflow");
        clearingEarningRates[mintLever] = clearingEarningRate;
        clearingEarningRatesV2[mintLever] = true;
        emit ClearingEarningRate(mintLever, clearingEarningRate);
    }

    function getClearingEarningRate(address mintLever) override external view returns (uint256) {
        // leeqiang
        // require(clearingEarningRatesV2[mintLever], "publics:clearing_earning_rate_overflow");
        // return clearingEarningRates[mintLever];
        return 800;
    }
    
    function setClearingPlatformEarningRate(address mintLever, uint256 clearingPlatformEarningRate) external onlyOwner nonZeroAddress(mintLever) {
        require(0 <= clearingPlatformEarningRate && clearingPlatformEarningRate < 10000, "publics:clearing_platform_earning_rate_overflow");
        clearingPlatformEarningRates[mintLever] = clearingPlatformEarningRate;
        clearingPlatformEarningRatesV2[mintLever] = true;
        emit ClearingPlatformEarningRate(mintLever, clearingPlatformEarningRate);
    }
    
    function getClearingPlatformEarningRate(address mintLever) override external view returns (uint256) {
        // leeqiang
        // require(clearingPlatformEarningRatesV2[mintLever], "publics:clearing_platform_earning_rate_overflow");
        // return clearingPlatformEarningRates[mintLever];
        return 6000;
    }
    
    function setMaxRiskRate(address mintLever, uint256 maxRiskRate) external onlyOwner nonZeroAddress(mintLever) {
        require(0 < maxRiskRate && maxRiskRate < 10000, "publics:max_risk_rate_overflow");
        maxRiskRates[mintLever] = maxRiskRate;
        emit MaxRiskRate(mintLever, maxRiskRate);
    }
    
    function getMaxRiskRate(address mintLever) override external view returns (uint256) {
        // leeqiang
        // uint256 maxRiskRate = maxRiskRates[mintLever];
        // require(0 < maxRiskRate, "publics:max_risk_rate_overflow");
        // return maxRiskRate;
        return 8000;
    }

    
}