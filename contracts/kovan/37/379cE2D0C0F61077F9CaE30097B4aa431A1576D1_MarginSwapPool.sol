/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// File: marginSwap/MSPError.sol

pragma solidity ^0.5.16;

contract MSPError {
    enum Error {
        NO_ERROR,
        BAD_INPUT
    }
}
// File: marginSwap/utils/tools.sol

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

contract Tools {
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }
}

// File: marginSwap/IMarginSwapInterface.sol

pragma solidity ^0.5.16;






contract MarginSwapStorage {
    //保证金结构
    struct supplyConfigSingle {
        string symbol;
        //保证金币种
        address supplyToken;
        //保证金数量
        uint256 supplyAmount;
        //兑换成pToken数量
        uint256 pTokenAmount;
    }

    struct BailConfig {
        mapping(address => supplyConfigSingle) bailCfgContainer;
        address[] accountBailAddresses; //[USDTAddr, BUSDAddr]
    }

    struct MarginSwapConfig {
        //所有建仓结构： 张三=>id=>配置
        mapping(address => mapping(string => marginSwapConfig)) accountMarginSwapRecords;
        mapping(address => string []) accountCurrentRecordIds;
    }

    struct marginSwapConfig {
        //持仓ID
        string id;
        //保证金结构
        supplyConfigSingle supplyInfo;
        uint256 leverage;
        //借款数量
        uint256 borrowAmount;
        //兑换目标Token
        EIP20Interface swapToken;
        //预估兑换数量
        // uint256 predictSwapAmount;
        //滑点
        uint256 slippageTolerance;
        //是否自动存入资金池
        bool isAutoSupply;
        //实际兑换资产数量
        uint256 acturallySwapAmount;
        //兑换资产存入资金池后获得pToken数量
        uint256 pTokenSwapAmount;
        //当前记录是否有效
        // bool isAlive;
        //当前记录是否存在
        bool isExist;
    }

    address public admin;

    //所有用户&所有保证金, 张三=>id=>保证金结构
    mapping(address => mapping(string => BailConfig)) bailConfigs;

    //所有用户&所有持仓结构
    MarginSwapConfig msConfig;

    //当前杠杆交易合约名字: MSP BUSD
    string public name;
    //pToken地址 : pBUSD
    address public pTokenUnderlying;
    //资产地址: BUSD
    address public assetUnderlying;
    //资产符号
    string assetUnderlyingSymbol;
    //预言机
    IAssetPrice public priceOracle;
    //配置管理
    ConfigManager public configManager;
    //dex管理
    address public dexSwapper;
}
pragma solidity ^0.5.16;



contract IMarginSwapInterface is MarginSwapStorage {
    //建仓
    function openPosition(
        uint256 _supplyAmount,
        uint256 _leverage,
        EIP20Interface _swapToken,
        uint256 _slippageTolerance
    ) public returns (uint256 id);

    event openPositionEvent(string _positionId, uint256 _leverage, uint256 _borrowAmount, address _swapToken, uint256 _acturallySwapAmount, uint256 _slippageTolerance);

    //加仓
    function morePosition(
        string memory _positionId,
        uint256 _supplyAmount,
        uint256 _leverage,
        EIP20Interface _swapToken,
        uint256 _slippageTolerance
    ) public;

    event morePositionEvent(string _positionId, uint256 _leverage, uint256 _borrowAmount, address _swapToken, uint256 _acturallySwapAmount, uint256 _slippageTolerance);

    //追加保证金
    function addMargin(
        string memory _positionId,
        uint256 _amount,
        address _bailToken
    ) public;

    event addMarginEvent(string _positionId, uint256 _amount, address _bailToken);

    //提取保证金
    function redeemMargin(
        string memory _positionId,
        uint256 _amount,
        address _tokenType
    ) public;

    event reduceMarginEvent(string _positionId, uint256 _amount, address _tokenType);

    //还款
    function repay(string memory _positionId, uint256 _repayAmount) public returns (uint256, uint256);

    event repayEvent(string _positionId, uint256 _amount, uint256);

    //平仓
    function closePosition(string memory _positionId) public returns (uint256);

    event closePositionEvent(string _positionId, uint256 _needToPay, uint256 _backToAccountAmt);

    function depositMarginsToPublicsInternal(string memory _positionId) internal returns (uint256);
    function depositSwapTokenToPublicsInternal(string memory _positionId) internal returns (uint256, uint256);

    //允许存款并转入
    function enabledAndDoDeposit(string memory _positionId) public returns (uint256, uint256);
    event enabledAndDoDepositEvent(string _positionId, uint256 _actualMintAmt);

    function withdrawMarginsFromPublicsInternal(string memory _positionId) internal returns (uint256);
    function withdrawSwapTokenFromPublicsInternal(string memory _positionId) internal returns (uint256, uint256);

    //禁止存入并转出
    function disabledAndDoWithdraw(string memory _positionId) public returns (uint256, uint256);
    event disabledAndDoWithdrawEvent(string _positionId);

    //获取风险率
    function getRisk(address _account, string memory _positionId) public returns (uint256);

    event getRiskEvent(string _positionId);

    //直接清算
    function liquidateBorrowedDirectly(address _account, string memory _positionId) public;

    event liquidateBorrowedDirectlyEvent(address _account, string _positionId);

    //偿还清算
    function liquidateBorrowedRepayFirst(address _account, string memory _positionId) public;

    event liquidateBorrowedRepayFirstEvent(address _account, string _positionId);

    //设置依赖的pToken合约
    function setUnderlyPTokenAddress(address _pTokenUnderlying) public;

    event setUnderlyPTokenAddressEvent(address _pTokenUnderlying);

    // //返回最佳询价
    function getSwapPrice(address _baseToken, address _swapToken) public returns (uint256);

    //获取持仓结构详情
    function getAccountConfigDetail(string memory _id)
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        );

    //获取保证金详情
    function getBailAddress(string memory _id) public view returns (address[] memory);

    function getBailConfigDetail(string memory _id, address _bailToken) public view returns ( string memory, uint256, uint256);

    //设置DexSwapper
    function setDexSwapper(address _newDexSwapper) external;

    event SetDexSwapperEvent(address oldDexSwapper, address _newDexSwapper);
}

// File: TestOnly/TestDex.sol

pragma solidity ^0.5.16;


// import "hardhat/console.sol";

contract MockDex {
    //0. 预先在dex中转入足量的from和to代币，这个swap函数会正向和反向兑换
    //1. 指定from和to的地址，根据比例自动计算出来
    //2. dex从MSP中划走from，同时转入to代币
    function swap(address payable _msp, address _fromToken, uint256  _fromAmt, address _toToken, uint256 _swapAmt) public returns (uint256) {
        // console.log("MockDex.swap called!");

        uint256 actualAmt = doTransferIn(_msp, _fromToken, _fromAmt);
        // console.log("MockDex::actual doTransferIn amount:", actualAmt);

        doTransferOut(_msp, _toToken, _swapAmt);
    }

    function doTransferIn(address from, address erc20token, uint256 amount)
        internal
        returns (uint256)
    {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(erc20token);
        uint256 balanceBefore =
            EIP20Interface(erc20token).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter =
            EIP20Interface(erc20token).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function doTransferOut(address payable to, address erc20token, uint256 amount) internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(erc20token);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }


}
// File: marginSwap/DexSwapper.sol

pragma solidity ^0.5.16;




contract DexSwapper {
    using SafeMath for uint256;

    address public admin;
    address[] dexArray;

    constructor() public {
        admin = msg.sender;
    }

    function setDexWhiteList(address[] memory _supportList) public {
        require(msg.sender == admin, "only admin can set white list");

        for (uint256 i = 0; i < _supportList.length; i++) {
            require(address(_supportList[i]) != address(0), "invalid address");
            dexArray.push(address(_supportList[i]));
        }
    }

    function getCandiadate(
        address _srcToken,
        uint256 _srcAmt,
        address _dstToken,
        uint256 _tolerance,
        uint256 _times
    ) public returns (address, uint256) {
        uint256 swapAmt;
        //1. 遍历dex数组
        for (uint256 i = 0; i < dexArray.length; i++) {
            //2. 检查每一个dex的滑点
            //TODO

            //计算价格，兑换比例计算
            swapAmt = _srcAmt.mul(_times); //这个_times参数要干掉，使用预言机
            // console.log("getCandiadate::will swapAmt:", swapAmt);
        }

        return (dexArray[0], swapAmt);
    }

    function swap(
        address _srcToken,
        uint256 _srcAmt,
        address _dstToken,
        address _candidate,
        uint256 _swapAmt
    ) public returns (uint256) {
        return MockDex(_candidate).swap(msg.sender, _srcToken, _srcAmt, _dstToken, _swapAmt);
    }
}

// File: marginSwap/ConfigManager.sol

pragma solidity ^0.5.16;



contract ConfigManager {
    //swapToken whitelist
    mapping(address => bool) public supplyTokenWhiteList; //标的资产白名单
    mapping(address => address) public assetToPTokenList; //BUSD => pBUSD, 兑换资产白名单，不为空说明允许
    mapping(address => bool) public bailTokenWhiteList; //保证金白名单

    address public admin;

    constructor() public {
        admin = msg.sender;
    }

    function setSupplyTokenWhiteList(EIP20Interface[] memory _supportList) public {
        require(msg.sender == admin, "only admin can set white list");
        for (uint256 i = 0; i < _supportList.length; i++) {
            require(address(_supportList[i]) != address(0), "invalid address");
            supplyTokenWhiteList[address(_supportList[i])] = true;
        }
    }

    function setAssetToPTokenList(EIP20Interface[] memory _erc20List, PTokenInterface[] memory _pList) public {
        require(msg.sender == admin, "only admin can set white list");
        for (uint256 i = 0; i < _erc20List.length; i++) {
            require(address(_erc20List[i]) != address(0), "invalid erc20 address");
            require(address(_pList[i]) != address(0), "invalid pToken address");
            assetToPTokenList[address(_erc20List[i])] = address(_pList[i]);
        }
    }

    function setBailTokenWhiteList(EIP20Interface[] memory _supportList) public {
        require(msg.sender == admin, "only admin can set white list");
        for (uint256 i = 0; i < _supportList.length; i++) {
            require(address(_supportList[i]) != address(0), "invalid address");
            bailTokenWhiteList[address(_supportList[i])] = true;
        }
    }
}

// File: IAssetPrice.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

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
// File: marginSwap/MarginSwapStorage.sol


// File: marginSwap/CapitalManager.sol


pragma solidity ^0.5.16;


contract LoanTypeBase {
    enum LoanType {NORMAL, MARGIN_SWAP_PROTOCOL, MINNING_SWAP_PROTOCOL}
}


// import "hardhat/console.sol";

contract CapitalManager is MarginSwapStorage, LoanTypeBase {
    /**
     *@notice 信用贷借款
     *@param _borrowAmount 借款数量
     *@return 错误码
     */
    function doCreditLoanBorrowInternal(uint256 _borrowAmount) public returns (uint256) {
        require(pTokenUnderlying != address(0), "pTokenUnderlying address should not be 0");
        uint256 error = ICreditLoan(pTokenUnderlying).doCreditLoanBorrow(msg.sender, _borrowAmount, LoanType.MARGIN_SWAP_PROTOCOL);
        //console.log("信用贷借款error:", error);
        return error;
    }

    /**
     *@notice 信用贷还款
     *@param _repayAmount 还款数量
     *@return 错误码，实际还款数量
     */
    function doCreditLoanRepayInternal(uint256 _repayAmount) public returns (uint256, uint256) {
        require(pTokenUnderlying != address(0), "pTokenUnderlying address should not be 0");

        bool f = EIP20Interface(assetUnderlying).approve(pTokenUnderlying, _repayAmount);
        require(f, "credit loan repay approve failed!");

        uint256 allowance = EIP20Interface(assetUnderlying).allowance(address(this), pTokenUnderlying);
        // console.log("busd msp allowance:", allowance);

        (uint256 error, uint256 acturallyRepayAmount) = ICreditLoan(pTokenUnderlying).doCreditLoanRepay(msg.sender, _repayAmount, LoanType.MARGIN_SWAP_PROTOCOL);
        return (error, acturallyRepayAmount);
    }
}

// File: ExponentialNoError.sol

pragma solidity ^0.5.16;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Publics
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint256 constant expScale = 1e18;
    uint256 constant doubleScale = 1e36;
    uint256 constant halfExpScale = expScale / 2;
    uint256 constant mantissaOne = expScale;

    struct Exp {
        uint256 mantissa;
    }

    struct Double {
        uint256 mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (uint256) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (uint256) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) internal pure returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint256 n, string memory errorMessage) internal pure returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: add_(a.mantissa, b.mantissa) });
    }

    function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: add_(a.mantissa, b.mantissa) });
    }

    function add_(uint256 a, uint256 b) internal pure returns (uint256) {
        return add_(a, b, "addition overflow");
    }

    function add_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: sub_(a.mantissa, b.mantissa) });
    }

    function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: sub_(a.mantissa, b.mantissa) });
    }

    function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: mul_(a.mantissa, b.mantissa) / expScale });
    }

    function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({ mantissa: mul_(a.mantissa, b) });
    }

    function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: mul_(a.mantissa, b.mantissa) / doubleScale });
    }

    function mul_(Double memory a, uint256 b) internal pure returns (Double memory) {
        return Double({ mantissa: mul_(a.mantissa, b) });
    }

    function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: div_(mul_(a.mantissa, expScale), b.mantissa) });
    }

    function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({ mantissa: div_(a.mantissa, b) });
    }

    function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa) });
    }

    function div_(Double memory a, uint256 b) internal pure returns (Double memory) {
        return Double({ mantissa: div_(a.mantissa, b) });
    }

    function div_(uint256 a, Double memory b) internal pure returns (uint256) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint256 a, uint256 b) internal pure returns (uint256) {
        return div_(a, b, "divide by zero");
    }

    function div_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint256 a, uint256 b) internal pure returns (Double memory) {
        return Double({ mantissa: div_(mul_(a, doubleScale), b) });
    }
}

// File: CarefulMath.sol

pragma solidity ^0.5.16;

/**
 * @title Careful Math
 * @author Publics
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
    /**
     * @dev Possible error codes that we can return
     */
    enum MathError { NO_ERROR, DIVISION_BY_ZERO, INTEGER_OVERFLOW, INTEGER_UNDERFLOW }

    /**
     * @dev Multiplies two numbers, returns an error on overflow.
     */
    function mulUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint256 c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function divUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
     * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
     */
    function subUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
     * @dev Adds two numbers, returns an error on overflow.
     */
    function addUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        uint256 c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
     * @dev add a and b and then subtract c
     */
    function addThenSubUInt(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (MathError, uint256) {
        (MathError err0, uint256 sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// File: Exponential.sol

pragma solidity ^0.5.16;



/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Publics
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint256 num, uint256 denom) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        (MathError err1, uint256 rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        return (MathError.NO_ERROR, Exp({ mantissa: rational }));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint256 result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({ mantissa: result }));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint256 result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({ mantissa: result }));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        return (MathError.NO_ERROR, Exp({ mantissa: scaledMantissa }));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        return (MathError.NO_ERROR, Exp({ mantissa: descaledMantissa }));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint256 scalar, Exp memory divisor) internal pure returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint256 numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint256 scalar, Exp memory divisor) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint256 doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        (MathError err2, uint256 product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({ mantissa: product }));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint256 a, uint256 b) internal pure returns (MathError, Exp memory) {
        return mulExp(Exp({ mantissa: a }), Exp({ mantissa: b }));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(
        Exp memory a,
        Exp memory b,
        Exp memory c
    ) internal pure returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

// File: ErrorReporter.sol

pragma solidity ^0.5.16;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL, //清算报错3
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED, //9
        MARKET_ALREADY_LISTED, //10
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION, //14
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY //17
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS, //17
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint256 error, uint256 info, uint256 detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), 0);

        return uint256(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(
        Error err,
        FailureInfo info,
        uint256 opaqueError
    ) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), opaqueError);

        return uint256(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        COMPTROLLER_REJECTION, //清算报错, 3
        COMPTROLLER_CALCULATION_ERROR, //borrow时报错
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH, //14
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE, //9
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK, //17错误
        LIQUIDATE_COMPTROLLER_REJECTION, //清算报错 18
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION, //31
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION, //40
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint256 error, uint256 info, uint256 detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), 0);

        return uint256(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(
        Error err,
        FailureInfo info,
        uint256 opaqueError
    ) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), opaqueError);

        return uint256(err);
    }
}

// File: SafeMath.sol

pragma solidity ^0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
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

// File: ICreditLoan.sol

pragma solidity ^0.5.16;

contract ICreditLoan is LoanTypeBase {

    //设置白名单
    function setWhiteList(address _trust) public returns (uint256);

    /**
     *@notice 信用贷借款
     *@param _borrower:实际借款人的地址
     *@param _borrowAmount:实际借款数量(精度18)
     *@return (uint256): 错误码
     */
    function doCreditLoanBorrow(
        address payable _borrower,
        uint256 _borrowAmount,
        LoanType _loanType
    ) public returns (uint256);

    event NewCreditLoanBorrowEvent( address _trust, LoanType _loanType, address _borrower, uint256 _borrowAmount, uint256 _error);

    /**
     *@notice 信用贷还款
     *@param _payer:实际还款人的地址
     *@param _repayAmount:实际还款数量(精度18)
     *@return (uint256, uint256): 错误码, 实际还款数量
     */
    function doCreditLoanRepay(address _payer, uint256 _repayAmount, LoanType _loanType)
        public
        returns (uint256, uint256);

    event NewCreditLoanRepayEvent( address _trust, LoanType _loanType, address _payer, uint256 _repayAmount, uint256 _acturally, uint256 _error);
}
// File: PubMiningRateModel.sol

pragma solidity ^0.5.16;


contract PubMiningRateModel {
    /// @notice Indicator that this is an PubMiningRateModel contract (for inspection)
    bool public constant isPubMiningRateModel = true;

    address public PubMining;

    function getSupplySpeed(uint utilizationRate) external view returns (uint);

    function getBorrowSpeed(uint utilizationRate) external view returns (uint);
}

// File: EIP20NonStandardInterface.sol

pragma solidity ^0.5.16;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// File: InterestRateModel.sol

pragma solidity ^0.5.16;

/**
 * @title Publics' InterestRateModel Interface
 * @author Publics
 */
contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market (currently unused)
     * @return The utilization rate as a mantissa between [0, 1e18]
     */
    function utilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public pure returns (uint256);

    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

// File: ComptrollerInterface.sol

pragma solidity ^0.5.16;


contract ComptrollerInterface is LoanTypeBase {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;
    address public pubAddress;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata pTokens) external returns (uint256[] memory);

    function exitMarket(address pToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address pToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address pToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address pToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address pToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address pToken,
        address borrower,
        uint256 borrowAmount,
        LoanType _loanType
    ) external returns (uint256);

    function borrowVerify(
        address pToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address pToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address pToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address pToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/
    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);
}

// File: PTokenInterfaces.sol

pragma solidity ^0.5.16;






contract PTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint256 internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-pToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Model which tells what the current pub mining rate should be
     */
    PubMiningRateModel public pubMiningRateModel;

    /**
     * @notice Initial exchange rate used when minting the first PTokens (used when totalSupply = 0)
     */
    uint256 internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint256 public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint256 public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping(address => uint256) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal; //最新操作后的总余额（含应计利息）
        uint256 interestIndex; //对应的索引
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows; //NORMAL
    mapping(address => BorrowSnapshot) internal accountBorrowsMarginSP; //MarginSwapPool
    mapping(address => BorrowSnapshot) internal accountBorrowsMiningSP; //MiningSwapPool

    //信用贷相关，杠杆交易，杠杆挖矿，其他...
    mapping(address => bool) public whiteList;
}


contract PTokenInterface is PTokenStorage, LoanTypeBase {
    /**
     * @notice Indicator that this is a PToken contract (for inspection)
     */
    bool public constant isPToken = true;

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);
    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows, LoanType loanType);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows, LoanType loanType);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint256 repayAmount, address pTokenCollateral, uint256 seizeTokens);

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when pubMiningRateModel is changed
     */
    event NewPubMiningRateModel(PubMiningRateModel oldPubMiningRateModel, PubMiningRateModel newPubMiningRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    /*** User Interface ***/

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account, LoanType loanType)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account, LoanType loanType) external returns (uint256);

    function borrowBalanceStored(address account, LoanType loanType) public view returns (uint256);

    function exchangeRateCurrent() public returns (uint256);

    function exchangeRateStored() public view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() public returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(ComptrollerInterface newComptroller) public returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint256);

    function _setPubMiningRateModel(PubMiningRateModel newPubMiningRateModel) public returns (uint256);

    function getSupplyPubSpeed() external view returns (uint256);

    function getBorrowPubSpeed() external view returns (uint256);

}

contract CErc20Storage {
    /**
     * @notice Underlying asset for this PToken
     */
    address public underlying;
}

contract PErc20Interface is CErc20Storage {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external returns (uint256, uint256);

    function redeem(uint256 redeemTokens) external returns (uint256, uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        PTokenInterface pTokenCollateral
    ) external returns (uint256);

    function sweepToken(EIP20NonStandardInterface token) external;

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);
}

contract CDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

contract PDelegatorInterface is CDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) public;
}

contract PDelegateInterface is CDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public;
}

// File: EIP20Interface.sol

pragma solidity ^0.5.16;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// File: marginSwap/MarginSwapPool.sol

pragma solidity ^0.5.16;

// import "hardhat/console.sol";












contract MarginSwapPool is IMarginSwapInterface, Tools, Exponential, CapitalManager, MSPError {
    using SafeMath for uint256;
    uint256 MANTISSA18 = 1 ether;

    constructor(
        string memory _name,
        ConfigManager _config,
        address _dexSwapper
    ) public {
        name = _name;
        configManager = _config;
        dexSwapper = _dexSwapper;
        admin = msg.sender;
    }

    struct posLocalVars {
        string currentId;
        uint256 borrowAmount;
        uint256 borrowError;
        uint256 acturallySwapAmount;
        MathError err0;
        bool isAlreadyExist;
    }

    struct closeLocalVars {
        uint256 needToPayback; 
        uint256 backToAccountAmt;
        uint256 aboutToSwapAmnt;
    }

    struct TestPrcieLocal {
        uint256 busdPrice;
        uint256 uniPrice;
        uint256 times;
    }

    //开仓
    function openPosition(
        uint256 _supplyAmount,
        uint256 _leverage,
        EIP20Interface _swapToken,
        uint256 _slippageTolerance
    ) public returns (uint256) {
        require(_leverage >= MANTISSA18 && _leverage <= 3 * MANTISSA18 && _leverage.mod(MANTISSA18.div(10)) == 0, "1 <= leverage <= 3, step 0.1 only!");
        require(configManager.assetToPTokenList(address(_swapToken)) != address(0), "swap token is not in white list");
        require(address(_swapToken) != address(assetUnderlying), "swap token is not supported");

        posLocalVars memory vars;

        //借款数量:
        (vars.err0, _leverage) = subUInt(_leverage, MANTISSA18);
        require(vars.err0 == MathError.NO_ERROR, "leverage invalid!");

        (vars.err0, vars.borrowAmount) = mulScalarTruncate(Exp({mantissa: _supplyAmount}), _leverage);

        // console.log("vars.borrowAmount:", vars.borrowAmount);
        require(vars.err0 == MathError.NO_ERROR, "borrowAmountCalc error!");
        require(vars.borrowAmount <= (PTokenInterface(pTokenUnderlying)).getCash(), "money insufficient!");

        string memory swapTokenSymbol = EIP20Interface(_swapToken).symbol();
        //TODO
        vars.currentId = Tools.strConcat(assetUnderlyingSymbol, swapTokenSymbol);

        vars.isAlreadyExist = msConfig.accountMarginSwapRecords[msg.sender][vars.currentId].isExist;
        // console.log("vars.isAlreadyExist", vars.isAlreadyExist, vars.currentId);

        if (vars.isAlreadyExist) {
            //加仓
            // morePosition(vars.currentId, _supplyAmount, _leverage, _swapToken, _predictSwapAmount, _slippageTolerance);
        } else {
            //用户提供保证金信息，后续追加时单独存储一个新结构
            supplyConfigSingle memory scs = supplyConfigSingle({symbol: assetUnderlyingSymbol, supplyToken: assetUnderlying, supplyAmount: _supplyAmount, pTokenAmount: 0});

            //1. save config
            marginSwapConfig memory config =
                marginSwapConfig({
                    id: vars.currentId,
                    supplyInfo: scs,
                    leverage: _leverage,
                    borrowAmount: vars.borrowAmount,
                    swapToken: _swapToken,
                    // predictSwapAmount: _predictSwapAmount,
                    slippageTolerance: _slippageTolerance,
                    isAutoSupply: false,
                    acturallySwapAmount: 0,
                    pTokenSwapAmount: 0, // isAlive: true,
                    isExist: true
                });

            //2. get supply money
            // 需用户先授权
            // EIP20Interface(assetUnderlying).transferFrom(msg.sender, address(this), _supplyAmount);
            doTransferIn(msg.sender, assetUnderlying, _supplyAmount);

            //3. get credit loan
            vars.borrowError = doCreditLoanBorrowInternal(vars.borrowAmount);
            require(vars.borrowError == 0, "doCreditLoanBorrow failed!");

            // ******* 测试模拟dex ********* /
            uint256 aboutToSwapAmnt = _supplyAmount.add(vars.borrowAmount);
            // console.log("aboutToSwapAmnt:", aboutToSwapAmnt);

            TestPrcieLocal memory vars1;

            vars1.busdPrice = MANTISSA18;
            vars1.uniPrice = MANTISSA18;
            vars1.times = vars1.busdPrice.div(vars1.uniPrice);
            // console.log("busdPrice.div(uniPrice):", vars1.times);

            //查找最佳dex //TODO
            // getCandiadate(address _srcToken, uint256 _srcAmt, address _dstToken, uint256 _tolerance, uint256 _times)
            (address dexCandidate, uint256 willSwapAmt) = DexSwapper(dexSwapper).getCandiadate(assetUnderlying, aboutToSwapAmnt, address(_swapToken), _slippageTolerance, vars1.times);
            // console.log("dexCandidate", dexCandidate, "willSwapAmt", willSwapAmt);

            EIP20Interface(assetUnderlying).approve(dexCandidate, aboutToSwapAmnt);
            // console.log("allowance:", EIP20Interface(assetUnderlying).allowance(address(this), dexCandidate));

            // function swap(address _srcToken, uint256 _srcAmt, address _dstToken, address _candidate, uint256 _swapAmt) public returns (uint256) {
            DexSwapper(dexSwapper).swap(assetUnderlying, aboutToSwapAmnt, address(_swapToken), dexCandidate, willSwapAmt);
            vars.acturallySwapAmount = willSwapAmt;

            emit openPositionEvent(vars.currentId, _leverage, vars.borrowAmount, address(_swapToken), vars.acturallySwapAmount, _slippageTolerance);

            //更新建仓结构
            config.acturallySwapAmount = vars.acturallySwapAmount;
            msConfig.accountMarginSwapRecords[msg.sender][config.id] = config;
            msConfig.accountCurrentRecordIds[msg.sender].push(vars.currentId);
        }
    }

    //加仓
    function morePosition(
        string memory _positionId,
        uint256 _supplyAmount,
        uint256 _leverage,
        EIP20Interface _swapToken,
        uint256 _slippageTolerance
    ) public {
        require(_leverage >= MANTISSA18 && _leverage <= 3 * MANTISSA18 && _leverage.mod(MANTISSA18.div(10)) == 0, "1 <= leverage <= 3, step 0.1 only!");
        require(configManager.assetToPTokenList(address(_swapToken)) != address(0), "swap token is not in white list");
        require(address(_swapToken) != address(assetUnderlying), "swap token is not supported");

        //1. 根据id找到记录
        marginSwapConfig storage config = msConfig.accountMarginSwapRecords[msg.sender][_positionId];
        require(config.isExist, "moreposition record id is not exist!");

        posLocalVars memory vars;

        //借款数量:
        (vars.err0, _leverage) = subUInt(_leverage, MANTISSA18); //1e18
        (vars.err0, vars.borrowAmount) = mulScalarTruncate(Exp({mantissa: _supplyAmount}), _leverage);

        // console.log("vars.borrowAmount:", vars.borrowAmount);
        require(vars.err0 == MathError.NO_ERROR, "borrowAmountCalc error!");
        require(vars.borrowAmount <= (PTokenInterface(pTokenUnderlying)).getCash(), "money insufficient!");

        //2. get supply money 需用户先授权
        doTransferIn(msg.sender, assetUnderlying, _supplyAmount);

        //3. get credit loan
        vars.borrowError = doCreditLoanBorrowInternal(vars.borrowAmount);
        require(vars.borrowError == 0, "doCreditLoanBorrow failed!");

        //授权dex
        uint256 aboutToSwapAmnt = _supplyAmount.add(vars.borrowAmount);
        // console.log("morePosition::aboutToSwapAmnt:", aboutToSwapAmnt);

        //查找最佳dex
        // getCandiadate(address _srcToken, uint256 _srcAmt, address _dstToken, uint256 _tolerance, uint256 _times)
        (address dexCandidate, uint256 willSwapAmt) = DexSwapper(dexSwapper).getCandiadate(assetUnderlying, aboutToSwapAmnt, address(_swapToken), _slippageTolerance, 1);
        // console.log("dexCandidate", dexCandidate, "willSwapAmt", willSwapAmt);

        EIP20Interface(assetUnderlying).approve(dexCandidate, aboutToSwapAmnt);
        // console.log("allowance:", EIP20Interface(assetUnderlying).allowance(address(this), dexCandidate));

        uint256 holdBalance = EIP20Interface(_swapToken).balanceOf(address(this));
        // console.log("morePosition::holdBalance前:", holdBalance);

        // function swap(address _srcToken, uint256 _srcAmt, address _dstToken, address _candidate, uint256 _swapAmt) public returns (uint256) {
        DexSwapper(dexSwapper).swap(assetUnderlying, aboutToSwapAmnt, address(_swapToken), dexCandidate, willSwapAmt);
        vars.acturallySwapAmount = willSwapAmt;

         holdBalance = EIP20Interface(_swapToken).balanceOf(address(this));
        // console.log("morePosition::holdBalance后:", holdBalance);

        //2. 将传入的数据更新到记录中
        // console.log("config.supplyInfo.supplyAmount：", config.supplyInfo.supplyAmount, _supplyAmount);
        config.supplyInfo.supplyAmount = config.supplyInfo.supplyAmount.add(_supplyAmount); //这个变量需要维护吗？ //TODO
        config.borrowAmount = config.borrowAmount.add(vars.borrowAmount); //还是要维护的，用于记录平仓时该还多少
        config.acturallySwapAmount = config.acturallySwapAmount.add(vars.acturallySwapAmount);

        //如果打开自动存储，则转换为pToken
        if (config.isAutoSupply) {
            (uint256 error,) = depositSwapTokenToPublicsInternal(_positionId);
            require(error == 0, "depositSwapTokenToPublicsInternal error!");
        }

        emit morePositionEvent(_positionId, _leverage, vars.borrowAmount, address(_swapToken), vars.acturallySwapAmount, _slippageTolerance);
    }

    function addMargin(
        string memory _positionId,
        uint256 _amount,
        address _bailToken
    ) public {
        //开仓和加仓时，直接操作scs结构
        //追加保证金的时候，即使是本金资产，统一放在结构中，这样对于本金就有两个scs结构来维护了，在处理清算，取款时要分别处理，不要忘记
        marginSwapConfig storage config = msConfig.accountMarginSwapRecords[msg.sender][_positionId];
        require(config.isExist, "record id is not exist!");
        require(configManager.bailTokenWhiteList(_bailToken), "bail token not in white list!");

        // 1. 转入资金到MSP
        doTransferIn(msg.sender, _bailToken, _amount);

        // 2. 更新到保证金结构中
        BailConfig storage bailConfig = bailConfigs[msg.sender][_positionId];
        supplyConfigSingle storage scs = bailConfig.bailCfgContainer[_bailToken];

        //无论存在与否都累计amount
        scs.supplyAmount = scs.supplyAmount.add(_amount);

        if (scs.supplyToken == address(0)) {
            scs.symbol = EIP20Interface(_bailToken).symbol();
            scs.supplyToken = _bailToken; //重要
            scs.pTokenAmount = 0;

            //更新保证金数组
            bailConfig.accountBailAddresses.push(_bailToken);
        }

        // 3. 如果已经enable，则调用自动进行存款函数
        if (config.isAutoSupply) {
            uint256 error = depositMarginsToPublicsInternal(_positionId);
            require(error == 0, "add::depositMarginsToPublicsInternal error!");
        }

        emit addMarginEvent(_positionId, _amount, _bailToken);
    }

    //提取保证金
    function redeemMargin(
        string memory _positionId,
        uint256 _amount,
        address _tokenType
    ) public {
        //TODO 全部取回的时候，删除保证金币种，平仓也要删除
        emit reduceMarginEvent(_positionId, _amount, _tokenType);
    }

    //还款，还信用贷的借款
    function repay(string memory _positionId, uint256 _repayAmount) public returns (uint256, uint256) {
        marginSwapConfig storage config = msConfig.accountMarginSwapRecords[msg.sender][_positionId];
        require(config.isExist, "record id is not exist!");

        uint256 currDebt = PTokenInterface(pTokenUnderlying).borrowBalanceCurrent(msg.sender, LoanType.MARGIN_SWAP_PROTOCOL);
        require(currDebt != 0, "borrow amount is 0, no need to repay");

        //1. 先还款
        //1. 从用户钱包扣款到MSP
        doTransferIn(msg.sender, assetUnderlying, _repayAmount);

        //1.b 如果输入小于余额但是大于债务，更新还款数字为债务值(还款合约内部处理了)
        (uint256 err, uint256 actualAmt) = doCreditLoanRepayInternal(_repayAmount);
        // console.log("callerBalance:", callerBalance, "actualAmt:", actualAmt);
        if (Error(err) != Error.NO_ERROR) {
            return (err, 0);
        }

        doTransferOut(msg.sender, assetUnderlying, _repayAmount.sub(actualAmt));
        
        //2. 更新结构
        //config中的数据只是用户借的，偿还的时候有可能包含了利息
        config.borrowAmount = currDebt.sub(actualAmt);

        emit repayEvent(_positionId, _repayAmount,  uint256(Error.BAD_INPUT));
        return (uint256(Error.NO_ERROR), actualAmt);
    }

    //平仓
    function closePosition(string memory _positionId) public returns (uint256) {
        marginSwapConfig storage config = msConfig.accountMarginSwapRecords[msg.sender][_positionId];
        require(config.isExist, "record id is not exist!");

        // 1. 如果发现ETH已经存入资金池（持有pToken），则先赎回：disableWithDraw方法
        if (config.isAutoSupply) {
            (uint256 error, ) = disabledAndDoWithdraw(_positionId);
            require(error == 0, "disabledAndDoWithdraw error!");
        }

        posLocalVars memory vars;
        closeLocalVars memory closeVars;

        // 2. 然后将UNI卖掉，得到BUSD
        //与DEX交互,需要先授权dex//TODO
        //授权dex
        closeVars.aboutToSwapAmnt = config.acturallySwapAmount;
        // console.log("colse aboutToSwapAmnt:", aboutToSwapAmnt); //UNI

        //查找最佳dex
        // getCandiadate(address _srcToken, uint256 _srcAmt, address _dstToken, uint256 _tolerance, uint256 _times)
        (address dexCandidate, uint256 willSwapAmt) = DexSwapper(dexSwapper).getCandiadate(address(config.swapToken), closeVars.aboutToSwapAmnt, assetUnderlying, config.slippageTolerance, 1);
        // console.log("dexCandidate", dexCandidate, "willSwapAmt", willSwapAmt);

        EIP20Interface(config.swapToken).approve(dexCandidate, closeVars.aboutToSwapAmnt);
        // console.log("allowance:", EIP20Interface(config.swapToken).allowance(address(this),dexCandidate));

        // function swap(address _srcToken, uint256 _srcAmt, address _dstToken, address _candidate, uint256 _swapAmt) public returns (uint256) {
        DexSwapper(dexSwapper).swap(address(config.swapToken), closeVars.aboutToSwapAmnt, assetUnderlying, dexCandidate, willSwapAmt);
        vars.acturallySwapAmount = willSwapAmt;

        // 3. 用户偿还BUSD，得到剩余的BUSD（本金）,
        //a. 先偿还借款(有利息), 该偿还多少呢？
        closeVars.needToPayback = PTokenInterface(pTokenUnderlying).borrowBalanceCurrent(msg.sender, LoanType.MARGIN_SWAP_PROTOCOL);
        // console.log("needToPayback:", closeVars.needToPayback, "uint256(-1):", uint256(-1));

        //抵押品价值大于债务，剩余的差值直接转给用户
        if (closeVars.needToPayback <= vars.acturallySwapAmount) {
            if (closeVars.needToPayback != 0) {
                //a. 偿还信用贷
                (uint256 err, uint256 actualAmt) = doCreditLoanRepayInternal(uint256(-1));
                // console.log("needToPayback:", closeVars.needToPayback, "actualAmt:", actualAmt);

                if (err != 0) {
                    return uint256(err);
                }

                //b. 把剩余的转给用户
                closeVars.backToAccountAmt = vars.acturallySwapAmount.sub(actualAmt);
                // console.log("backToAccountAmt:", closeVars.backToAccountAmt);
                // require(backToAccountAmt > 0, "backToAccountAmt should gt 0");
                doTransferOut(msg.sender, assetUnderlying, closeVars.backToAccountAmt);
            }

            // 4. 将其他各种保证金转给用户
            BailConfig storage bailConfig = bailConfigs[msg.sender][_positionId]; 
            address[] memory bailAssests = bailConfig.accountBailAddresses;

            for (uint256 i = 0; i < bailAssests.length; i++) {
                address currAsset = bailAssests[i];
                supplyConfigSingle storage scs = bailConfig.bailCfgContainer[currAsset];

                if (scs.supplyAmount == 0) {
                    continue;
                }

                //转给用户
                doTransferOut(msg.sender, currAsset, scs.supplyAmount);

                //维护保证金列表，删除 //TODO
                // deleteAccountBailAddress(_positionId, currAsset);
            }
        } else {
            //如果抵押品不足债务，则需要使用保证金来偿还
            //TODO
        }

        // 5. 更新结构
        config.isExist = false;

        // 6. 维护当前持仓的ID列表
        deleteClosedAccountRecord(_positionId);
        emit closePositionEvent(_positionId, closeVars.needToPayback, closeVars.backToAccountAmt);
    }

    function depositMarginsToPublicsInternal(string memory _positionId) internal returns (uint256){
        //1.a. 用户追加的保证金，多种，需要遍历
        BailConfig storage bailConfig = bailConfigs[msg.sender][_positionId];

        address[] memory bailAssests = bailConfig.accountBailAddresses;

        for (uint256 i = 0; i < bailAssests.length; i++) {
            address currAsset = bailAssests[i];
            supplyConfigSingle storage scs = bailConfig.bailCfgContainer[currAsset];

            //已经存储到池子了
            if (scs.supplyAmount == 0) {
                continue;
            }

            address pTokenCurrAsset = configManager.assetToPTokenList(address(currAsset));
            require(pTokenCurrAsset != address(0), "pToken for swapToken address is address(0)");
            EIP20Interface(currAsset).approve(pTokenCurrAsset, scs.supplyAmount);

            (uint256 error, uint256 actualMintAmt) = PErc20Interface(pTokenCurrAsset).mint(scs.supplyAmount);
            if (error != 0) {
                return error;
            }

            //存入之后，更新结构
            scs.supplyAmount = 0;
            scs.pTokenAmount = actualMintAmt;

            // console.log("depositMarginsToPublicsInternal::currAsset:", scs.symbol, "mint ptoken amount:", actualMintAmt);
        }

        return 0;
    }

    function depositSwapTokenToPublicsInternal(string memory _positionId) internal returns (uint256, uint256){
        marginSwapConfig storage config = msConfig.accountMarginSwapRecords[msg.sender][_positionId];

        //用户兑换回来的资产，例如：UNI
        uint256 swapTokenAmnt = config.acturallySwapAmount;
        // console.log("swapTokenAmnt:", swapTokenAmnt);

        //之前已经存储到池子中
        if (swapTokenAmnt == 0) {
            // console.log("no need to mint");
            return (0, 0);
        }

        //2. 存入池子中，调用pToken的mint函数，所以要先approve，注意是swapToken，不是underlying
        address swapTokenPToken = configManager.assetToPTokenList(address(config.swapToken));
        require(swapTokenPToken != address(0), "pToken for swapToken address is address(0)");

        //MSP合约授权pUNI合约可以划走自己的UNI
        EIP20Interface(config.swapToken).approve(swapTokenPToken, swapTokenAmnt);
        // console.log("allowance:", config.swapToken.allowance(address(this), swapTokenPToken));

        uint256 beforeMintAmt = PTokenInterface(swapTokenPToken).balanceOf(address(this));
        // console.log("beforeMintAmt:", beforeMintAmt);

        uint256 holdBalance = EIP20Interface(config.swapToken).balanceOf(address(this));
        // console.log("curr swap token balance:", holdBalance);

        (uint256 error, uint256 actualMintAmt) = PErc20Interface(swapTokenPToken).mint(swapTokenAmnt);
        if (error != 0) {
            return (error, 0);
        }

        uint256 afterMintAmt = PTokenInterface(swapTokenPToken).balanceOf(address(this));
        // console.log("afterMintAmt:", afterMintAmt); //1850000000000,正确37*5 = 185
        // console.log("actualMintAmt:", actualMintAmt); //370000000000000000000

        //3. 更新结构
        uint256 mintAmtCalc = afterMintAmt.sub(beforeMintAmt);
        require(actualMintAmt == mintAmtCalc, "actualMintAmt == mintAmtCalc");

        config.pTokenSwapAmount = config.pTokenSwapAmount.add(actualMintAmt);
        config.acturallySwapAmount = 0;
        config.isAutoSupply = true;

        return (0, actualMintAmt);
    }

    //允许存款并转入
    function enabledAndDoDeposit(string memory _positionId) public returns (uint256, uint256) {
        marginSwapConfig memory config = msConfig.accountMarginSwapRecords[msg.sender][_positionId];

        require(config.isExist, "record id is not exist!");
        require(!config.isAutoSupply, "auto supply already enabled!");

        // console.log("config.pTokenSwapAmount", config.pTokenSwapAmount);
        // console.log("config.acturallySwapAmount", config.acturallySwapAmount);
        // console.log("config.isAutoSupply", config.isAutoSupply);

        uint256 error = depositMarginsToPublicsInternal(_positionId);
        if (error != 0) {
            return (error, 0);
        }

        (uint256 error1, uint256 actualMintAmt) = depositSwapTokenToPublicsInternal(_positionId);
        if (error1 != 0) {
            return (error1, 0);
        }

        emit enabledAndDoDepositEvent(_positionId, actualMintAmt);
        return (0, actualMintAmt);
    }

    function withdrawMarginsFromPublicsInternal(string memory _positionId) internal returns (uint256) {
        //将所有的保证金取回，遍历
        BailConfig storage bailConfig = bailConfigs[msg.sender][_positionId];
        address[] memory bailAssests = bailConfig.accountBailAddresses;

        for (uint256 i = 0; i < bailAssests.length; i++) {
            address currAsset = bailAssests[i];
            supplyConfigSingle storage scs = bailConfig.bailCfgContainer[currAsset];

            if (scs.pTokenAmount == 0) {
                //理论上不会为0, double check
                continue;
            }

            //1. 找到pToken
            address pTokenCurrAsset = configManager.assetToPTokenList(address(currAsset));
            require(pTokenCurrAsset != address(0), "pToken for swapToken address is address(0)");

            //2. 调用redeem函数
            (uint256 error, uint256 actualRedeemAmt) = PErc20Interface(pTokenCurrAsset).redeem(scs.pTokenAmount);
            if (error != 0) {
                return error;
            }

            //3. 取出之后更新结构
            scs.supplyAmount = actualRedeemAmt;
            scs.pTokenAmount = 0;

            // console.log("withdrawMarginsFromPublicsInternal::currAsset:", scs.symbol, "redeem asset amount:", actualRedeemAmt);
        }

        return 0;
    }

    function withdrawSwapTokenFromPublicsInternal(string memory _positionId) internal returns (uint256, uint256) {
        marginSwapConfig storage config = msConfig.accountMarginSwapRecords[msg.sender][_positionId];

        // 1. 查看UNI的pToken，去赎回，调用redeem，输入指定金额
        uint256 pTokenSwapAmount = config.pTokenSwapAmount;
        require(pTokenSwapAmount > 0, "pTokenSwapAmount should gt 0");

        // 2. 找到pToken合约
        address pToken = configManager.assetToPTokenList(address(config.swapToken));
        require(pToken != address(0), "pToken for swapToken address is address(0)");

        uint256 beforeRedeemAmt = EIP20Interface(config.swapToken).balanceOf(address(this));
        // console.log("beforeRedeemAmt:", beforeRedeemAmt);

        // 3. msp得到UNI，更新结构：用户数量，置位false
        (uint256 error, uint256 actualRedeemAmt) = PErc20Interface(pToken).redeem(pTokenSwapAmount);
        if (error != 0) {
            return (error, 0);
        }

        uint256 afterRedeemAmt = EIP20Interface(config.swapToken).balanceOf(address(this));
        // console.log("afterRedeemAmt:", afterRedeemAmt);
        // console.log("actualRedeemAmt:", actualRedeemAmt);

        // 4. 更新结构
        uint256 redeemAmtCalc = afterRedeemAmt.sub(beforeRedeemAmt);
        require(actualRedeemAmt == redeemAmtCalc, "actualRedeemAmt == redeemAmtCalc");

        config.acturallySwapAmount = config.acturallySwapAmount.add(actualRedeemAmt);
        config.pTokenSwapAmount = 0;
        config.isAutoSupply = false;

        return (0, actualRedeemAmt);
    }

    //禁止存入并转出
    function disabledAndDoWithdraw(string memory _positionId) public returns (uint256, uint256) {
        marginSwapConfig memory config = msConfig.accountMarginSwapRecords[msg.sender][_positionId];
        require(config.isExist, "record id is not exist!");
        require(config.isAutoSupply, "auto supply already disabled!");

        uint256 error =  withdrawMarginsFromPublicsInternal(_positionId);
        if (error != 0) {
            return (error, 0);
        }

        (uint256 error1, uint256 actualRedeemAmt) = withdrawSwapTokenFromPublicsInternal(_positionId);
        if (error1 != 0) {
            return (error1, 0);
        }

        emit disabledAndDoWithdrawEvent(_positionId);
        return (0, actualRedeemAmt);
    }

    //获取风险率
    function getRisk(address _account, string memory _positionId) public returns (uint256) {
        emit getRiskEvent(_positionId);
        return 0;
    }

    //直接清算
    function liquidateBorrowedDirectly(address _account, string memory _positionId) public {
        emit liquidateBorrowedDirectlyEvent(_account, _positionId);
    }

    //偿还清算
    function liquidateBorrowedRepayFirst(address _account, string memory _positionId) public {
        emit liquidateBorrowedRepayFirstEvent(_account, _positionId);
    }

    function setUnderlyPTokenAddress(address _pTokenUnderlyingInit) public {
        require(_pTokenUnderlyingInit != address(0), "pTokenUnderlying address should not be 0");
        pTokenUnderlying = _pTokenUnderlyingInit;

        assetUnderlying = address(PErc20Interface(pTokenUnderlying).underlying());
        assetUnderlyingSymbol = EIP20Interface(assetUnderlying).symbol();
    }

    //获取资产数量
    function getAssetUnderlyingBalance(address _owner) public view returns (uint256) {
        return EIP20Interface(assetUnderlying).balanceOf(_owner);
    }

    function getSwapPrice(address _baseToken, address _swapToken) public returns (uint256) {
        return 0;
    }

    function getAccountCurrRecordIds() public view returns (string[] memory) {
        string[] memory ids = msConfig.accountCurrentRecordIds[msg.sender];
        return ids;
    }

    function getAccountConfigDetail(string memory _id)
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        marginSwapConfig memory msc = msConfig.accountMarginSwapRecords[msg.sender][_id];
        require(msc.isExist, "record id is not exist!");

        return (msc.id, msc.supplyInfo.supplyAmount, msc.borrowAmount, msc.supplyInfo.pTokenAmount, msc.isAutoSupply, msc.acturallySwapAmount, msc.pTokenSwapAmount);
    }

    function getBailAddress(string memory _id) public view returns (address[] memory) {
        marginSwapConfig memory msc = msConfig.accountMarginSwapRecords[msg.sender][_id];
        require(msc.isExist, "record id is not exist!");

        return bailConfigs[msg.sender][_id].accountBailAddresses;
    }

    function getBailConfigDetail(string memory _id, address _bailToken) public view returns ( string memory, uint256, uint256){
        supplyConfigSingle memory scs = bailConfigs[msg.sender][_id].bailCfgContainer[_bailToken];
        return (scs.symbol, scs.supplyAmount, scs.pTokenAmount);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function deleteClosedAccountRecord(string memory index) public returns (bool) {
        string[] storage myArray = msConfig.accountCurrentRecordIds[msg.sender];

        bool f = false;
        uint256 pos;

        for (uint256 i = 0; i <= myArray.length - 1; i++) {
            if (compareStrings(myArray[i], index)) {
                pos = i;
                f = true;
                break;
            }
        }

        // console.log(f, pos);
        if (f) {
            myArray[pos] = myArray[myArray.length - 1];
            myArray.length--;
        }

        return f;
    }

    function deleteAccountBailAddress(string memory _id, address _target) public returns (bool) {
        address[] storage myArray = bailConfigs[msg.sender][_id].accountBailAddresses;

        bool f = false;
        uint256 pos;

        for (uint256 i = 0; i <= myArray.length - 1; i++) {
            if (myArray[i] == _target) {
                pos = i;
                f = true;
                break;
            }
        }

        // console.log(f, pos);
        if (f) {
            myArray[pos] = myArray[myArray.length - 1];
            myArray.length--;
        }

        return f;
    }

    function doTransferIn(
        address from,
        address erc20token,
        uint256 amount
    ) internal returns (uint256) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(erc20token);
        uint256 balanceBefore = EIP20Interface(erc20token).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = EIP20Interface(erc20token).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function doTransferOut(
        address payable to,
        address erc20token,
        uint256 amount
    ) internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(erc20token);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }

    // modifier positionIdExist(string message _id) {
    //     require(_notEntered, "re-entered");
    //     _notEntered = false;
    //     _;
    //     _notEntered = true; // get a gas-refund post-Istanbul
    // }

    //设置DexSwapper
    function setDexSwapper(address _newDexSwapper) external {
        require(msg.sender == admin, "only the owner may call this function.");
        require(_newDexSwapper != address(0), "invalid dex sapper address!");

        address oldDexSwapper = dexSwapper;
        dexSwapper = _newDexSwapper;

        emit SetDexSwapperEvent(oldDexSwapper, _newDexSwapper);
    }
}