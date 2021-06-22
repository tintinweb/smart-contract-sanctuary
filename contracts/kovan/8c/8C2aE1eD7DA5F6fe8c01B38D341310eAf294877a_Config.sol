/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// File: localhost/mint/openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

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