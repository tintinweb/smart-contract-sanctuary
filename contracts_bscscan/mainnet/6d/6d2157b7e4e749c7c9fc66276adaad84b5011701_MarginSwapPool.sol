/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// File: marginSwap/interface/ICapitalInterface.sol

pragma solidity ^0.5.16;


contract ICapitalInterface {
    IStorageInterface mspstorage;

    function depositSpecToken(address _account, uint256 _id, address _modifyToken, uint256 _amount, address _caller) public returns (uint256, uint256);
    function redeemUnderlying(address _account, uint256 _id, address _modifyToken, uint256 _amount, address _caller) public returns (uint256, uint256, uint256);

    function doCreditLoanBorrowInternal(address payable _account, uint256 _borrowAmount, uint256 _id, address _caller) public returns (uint256);
    function doCreditLoanRepayInternal(address _payer, uint256 _repayAmount, uint256 _id, address _caller) public returns (uint256, uint256);

    function doTransferIn( address from, address erc20token, uint256 amount, address _caller) public returns (uint256);
    function doTransferOut(address payable to, address erc20token, uint256 amount, address _caller) public;

    function enabledAndDoDeposit(address _account, uint256 _id, address _caller) public returns (uint256);
    function disabledAndDoWithdraw(address _account, uint256 _id, address _caller) public returns (uint256);

    function depositMarginsToPublicsInternal(address _account, uint256 _id) internal returns (uint256);
    function withdrawMarginsFromPublicsInternal(address _account, uint256 _id) internal returns (uint256);

    function setStorage(IStorageInterface _newStorage) public;
    function getStorage() public view returns (IStorageInterface);
}
// File: TestOnly/MockDex.sol

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
        return _swapAmt;
    }

    function doTransferIn(address from, address erc20token, uint256 amount)
        internal
        returns (uint256)
    {
        EIP20Interface token = EIP20Interface(erc20token);
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
        EIP20Interface token = EIP20Interface(erc20token);
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

// File: LoanTypeBase.sol

pragma solidity ^0.5.16;

contract LoanTypeBase {
    enum LoanType {NORMAL, MARGIN_SWAP_PROTOCOL, MINNING_SWAP_PROTOCOL}
}

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





//import "hardhat/console.sol";

contract DexSwapper is Exponential {
    using SafeMath for uint256;
    uint256 MANTISSA18 = 1 ether;

    address public admin;
    address[] dexArray;

    PriceOracleAggregator public oracle; //临时模拟

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
        address _srcPToken,
        uint256 _srcAmt,
        address _dstPToken,
        uint256 _tolerance
    ) public returns (address, uint256) {
        //在这里确认兑换数量
        //使用ORACLE
        //TODO

        // uint256 busdPrice = 3* MANTISSA18; //债务币种价格上涨1倍，用户亏了
        // uint256 uniPrice =  MANTISSA18;

        //价格是有尾数的，而且不同资产的尾数不同，不可以直接使用除法来做倍数计算
        uint256 srcTokenPrice = oracle.getUnderlyingPrice(PTokenInterface(_srcPToken));
        uint256 dstTokenPrice = oracle.getUnderlyingPrice(PTokenInterface(_dstPToken));
        // console.log("srcTokenPrice:", srcTokenPrice);
        // console.log("dstTokenPrice:", dstTokenPrice);

        (MathError err, uint256 _times) = divScalarByExpTruncate(srcTokenPrice, Exp({mantissa: dstTokenPrice}));
        // console.log("swap::times: ", _times);

        uint256 swapAmt;
        //1. 遍历dex数组
        for (uint256 i = 0; i < dexArray.length; i++) {
            //2. 检查每一个dex的滑点
            //TODO

            //计算价格，兑换比例计算
            (MathError err, uint256 swapAmt1) = mulScalarTruncate(Exp({mantissa: _srcAmt}), _times);
            if (err != MathError.NO_ERROR) {
                // console.log("getCandiadate::err:", uint256(err));
                return (address(0), 0);
            }
            // console.log("getCandiadate::will swapAmt:", swapAmt1);
            swapAmt = swapAmt1;

            // swapAmt = _srcAmt.mul(_times); //这个_times参数要干掉，使用预言机
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

    function _setPriceOracle(PriceOracleAggregator newOracle) public returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return 0;
        }

        // Track the old oracle for the comptroller
        PriceOracleAggregator oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        // emit NewPriceOracle(oldOracle, newOracle);

        return 0;
    }
}

// File: IAssetPrice.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

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
// File: PriceOracle.sol

pragma solidity ^0.5.16;

// import "./PToken.sol";


contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
     * @notice Get the underlying price of a pToken asset
     * @param pToken The pToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(PTokenInterface pToken) external view returns (uint256);
}

// File: PriceOracleAggregator.sol

pragma solidity ^0.5.16;

// import "./PErc20.sol";




contract PriceOracleAggregator is PriceOracle {
    address public admin;
    address public priceOracle;

    event PricePosted(address oldPriceFeed, address newPriceFeed);

    constructor() public {
        admin = msg.sender;
    }

    function setPriceOracle(address newPriceOracle) public {
        require(msg.sender == admin, "only admin can set price oracle");

        address oldPriceOracle = priceOracle;
        priceOracle = newPriceOracle;

        emit PricePosted(oldPriceOracle, newPriceOracle);
    }

    function getUnderlyingPrice(PTokenInterface pToken) public view returns (uint256) {
        address asset = address(IPublicsLoanInterface(address(pToken)).underlying());
        (uint256 code, uint256 price,) = IAssetPrice(priceOracle).getPriceUSDV1(asset);
        require(code == 1, "price is invalid!");

        return price;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// File: marginSwap/interface/IControllerInterface.sol

pragma solidity ^0.5.16;






contract ControllerStorage {
    //支持的资产
    mapping(address => bool) public supplyTokenWhiteList; //TODO
    //swapToken whitelist
    mapping(address => bool) public swapTokenWhiteList;
    //token=>pToken
    mapping(address => address) assetToPTokenList;
    //保证金白名单
    mapping(address => bool) public bailTokenWhiteList;

    //清算相关
    mapping(address => uint256) public collateralFactorMantissaContainer; //token质押率 0.8
    uint256 public closeFactorMantissa; //清算比例 100%
    uint256 public liquidationIncentiveMantissa; //清算收益1.08

    uint256 internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9 //抵押物质量，0 - 0.9之间
    uint256 internal constant closeFactorMinMantissa = 0.05e18; // 0.05
    uint256 internal constant closeFactorMaxMantissa = 0.9e18; // 0.9 //清算因子，表示清算比例，publics现在是0.5

    //预言机
    PriceOracleAggregator public oracle;
    //dexSwapper
    DexSwapper public dexSwapper;
    address public admin;
    //所有msp集合
    IMSPInterface[] public allMspMarkets;
    //暂停市场
    address public pauseGuardian;
    mapping(address => bool) public openGuardianPaused;
}

contract IControllerInterface {
    event MSPListed(address newAddress, bool isCollateral);
    event NewSwapToken(address token, bool flag);
    event NewBailToken(address token, bool flag);
    event NewAssetToPToken(address token, address pToken);
    event NewDexSwapper(address oldDexSwapper, address newDexSwapper);

    event NewPriceOracle(PriceOracleAggregator oldPriceOracle, PriceOracleAggregator newPriceOracle);
    event NewCloseFactor(uint256 oldCloseFactorMantissa, uint256 newCloseFactorMantissa);
    event NewCollateralFactor(PTokenInterface pToken, uint256 oldCollateralFactorMantissa, uint256 newCollateralFactorMantissa);
    event NewLiquidationIncentive(uint256 oldLiquidationIncentiveMantissa, uint256 newLiquidationIncentiveMantissa);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);
    /// @notice Emitted when an action is paused globally
    event ActionPausedGlobal(string action, bool pauseState);
    /// @notice Emitted when an action is paused on a market
    event ActionPaused(IMSPInterface msp, string action, bool pauseState);

    function _supportMspMarket(IMSPInterface _msp, bool _isCollateral) external returns (uint256);

    function setSwapTokenWhiteList(address _token, bool _flag) public;

    function setAssetToPTokenList(EIP20Interface _token, PTokenInterface _pToken) public;

    function setBailTokenWhiteList(EIP20Interface _token, bool _flag) public;
    
    function setDexSwapper(address _newDexSwapper) external;

    function _setPriceOracle(PriceOracleAggregator newOracle) public returns (uint256);

    function _setCloseFactor(uint256 newCloseFactorMantissa) external returns (uint256);

    function _setCollateralFactor(PTokenInterface pToken, uint256 newCollateralFactorMantissa) external returns (uint256);

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external returns (uint256);

    function getAccountLiquidity( address _account, IMSPInterface _msp, uint256 _id) public view returns ( uint256, uint256, uint256, uint256);

    function liquidateBorrowAllowed(
        address msp,
        address pTokenBorrowed, //pToken
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 _id
    ) public returns (uint256);

    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint256 actualRepayAmount,
        bool isAutoSupply
    ) external view returns (uint256, uint256);

    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);
    
    function getOracle() public view returns (PriceOracleAggregator);

    function getDexSwapper() public view returns (DexSwapper);

    function getAllMspMarkets() public view returns (IMSPInterface[] memory);
    
    function openPositionAllowed(address _msp) external returns (uint256);

    function getPToken(address _token) public view returns(address);

    function isBailTokenAllowed(address _token) public returns(bool);

    function isSwapTokenAllowed(address _token) public returns(bool);

    function redeemAllowed(address _redeemer, IMSPInterface _msp, uint256 _id, address _modifyToken, uint256 _redeemTokens) public view returns (uint256);
}

// File: marginSwap/MSPStruct.sol

pragma solidity ^0.5.16;


contract MSPStruct {
    /*************** 保证金相关 ****************/
    //保证金结构
    struct supplyConfig {
        string symbol;
        //保证金币种
        address supplyToken;
        //保证金数量
        uint256 supplyAmount;
        //兑换成pToken数量
        uint256 pTokenAmount;
    }

    struct BailConfig {
        mapping(address => supplyConfig) bailCfgContainer;
        address[] accountBailAddresses; //[USDTAddr, BUSDAddr]
    }

    /*************** 持仓结构相关 ****************/
    struct MSPConfig {
        //持仓ID
        uint256 id;
        //本金数量
        uint256 supplyAmount;
        //杠杆倍数
        uint256 leverage;
        //借款数量
        uint256 borrowAmount;
        //兑换目标Token
        EIP20Interface swapToken; //存入保证金结构时，变成supplyToken
        //预估兑换数量
        // uint256 predictSwapAmount;
        //滑点
        uint256 slippageTolerance;
        //是否自动存入资金池
        bool isAutoSupply;
        //当前记录是否存在
        bool isExist;
    }

    struct MarginSwapConfig {
        //所有建仓结构： 张三=>id=>配置
        mapping(address => mapping(uint256 => MSPConfig)) accountMspRecords;
        mapping(address => uint256[]) accountCurrentRecordIds;
    }
}
// File: marginSwap/interface/IStorageInterface.sol

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


// import "hardhat/console.sol";

contract IStorageInterface {
    // 唯一修改人(所属MSP合约)
    address public admin;
    // 资产地址: BUSD
    address public assetUnderlying;
    // pToken地址 : pBUSD
    address public pTokenUnderlying;
    // 资产符号
    string public assetUnderlyingSymbol;
    // 当前杠杆交易合约名字: MSP BUSD
    string public name;
    // 配置管理
    IControllerInterface public controller;
    
    /*************** 保证金相关 ****************/
    //获取保证金详情
    function getBailAddress(address _account, uint256 _id) public view returns (address[] memory);
    function setBailAddress(address _account, uint256 _id, address _address) public;
    function deleteBailAddress(address _account, uint256 _id, address _remove) public returns (bool);

    function getSupplyConfig(address _account, uint256 _id, address _supplyToken) public view returns (MSPStruct.supplyConfig memory);
    function setSupplyConfig(address _account, uint256 _id, address _supplyToken, MSPStruct.supplyConfig memory _newScs) public;

    //所有用户&所有保证金, 张三=>id=>保证金结构
    mapping(address => mapping(uint256 => MSPStruct.BailConfig)) bailConfigs;

    /*************** 持仓结构相关 ****************/
    function getAccountRecordIds(address _account) public view returns(uint256[] memory);
    function setAccountRecordIds(address _account, uint256 _id) public;
    function deleteClosedAccountRecord(address _account, uint256 _id) public returns (bool);

    function getAccountMspConfig(address _account, uint256 _id) public view returns(MSPStruct.MSPConfig memory);
    function setAccountMspConfig(address _account, uint256 _id, MSPStruct.MSPConfig memory _newConfig) public;
    
    //所有用户&所有持仓结构
    MSPStruct.MarginSwapConfig msConfig;
    //持仓id
    uint public lastId;
    function updateID() public;

    mapping(address => mapping(string =>bool)) accountRecordExist;
    function getAccountRecordExistFlag(address _account, string memory _unique) public returns(bool);
    function setAccountRecordExistFlag(address _account, string memory _unique, bool _flag) public;

    /*************** MSP基础信息 ****************/
    function setAdmain(address _admin) public;

    //资金使用白名单
    mapping (address=>bool) superList;
    function setSuperList(address _address, bool _flag) public;
    function mustInSuperList(address _address) public;

    function setController(IControllerInterface _newController) public;
    function getController() public returns (IControllerInterface);
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

// File: marginSwap/interface/IMSPInterface.sol

pragma solidity ^0.5.16;





contract IMSPInterface {
    uint256 BASE10 = 10;
    bool _notEntered = true;

    IStorageInterface public mspstorage;
    IControllerInterface public controller;
    ICapitalInterface public capital;

    address public assetUnderlying;
    address public pTokenUnderlying;
    string public assetUnderlyingSymbol;

    //建仓
    function openPosition(
        uint256 _supplyAmount,
        uint256 _leverage,
        EIP20Interface _swapToken,
        uint256 _slippageTolerance
    ) public returns (uint256);

    event OpenPositionEvent(uint256 _id, uint256 _supplyAmount, uint256 _leverage, uint256 _borrowAmount, address _swapToken, uint256 _acturallySwapAmount, uint256 _slippageTolerance);

    //加仓
    function morePosition(
        uint256 _id,
        uint256 _supplyAmount,
        uint256 _leverage,
        EIP20Interface _swapToken,
        uint256 _slippageTolerance
    ) public returns(uint256);
    event MorePositionEvent(uint256 _id, uint256 _supplyAmount, uint256 _leverage, uint256 _borrowAmount, address _swapToken, uint256 _acturallySwapAmount, uint256 _slippageTolerance);

    // 平仓
    function closePosition(uint256 _id) public returns (uint256);
    event ClosePositionEvent(uint256 _id, uint256 _needToPay, uint256 _backToAccountAmt);

    //追加保证金
    function addMargin(
        uint256 _id,
        uint256 _amount,
        address _bailToken
    ) public;
    event AddMarginEvent(uint256 _id, uint256 _amount, address _bailToken);

    //提取保证金
    function redeemMargin(
        uint256 _id,
        uint256 _amount,
        address _modifyToken
    ) public;
    event ReedeemMarginEvent(uint256 _id, uint256 _amount, address _modifyToken);

    //还款
    function repay(uint256 _id, uint256 _repayAmount) public returns (uint256, uint256);
    event RepayEvent(uint256 _id, uint256 _amount, uint256);

    function repayFromMargin(uint256 _id, address _bailToken, uint256 _amount, uint256 _slippageTolerance) public returns (uint256, uint256);
    event RepayFromMarginEvent(uint256 id, address bailToken, uint256 amount);

    // 允许存款并转入
    function enabledAndDoDeposit(uint256 _id) public returns (uint256);
    event EnabledAndDoDepositEvent(uint256 _id);

    // 禁止存入并转出
    function disabledAndDoWithdraw(uint256 _id) public returns (uint256);
    event DisabledAndDoWithdrawEvent(uint256 _id);

    // //返回最佳询价
    function getSwapPrice(address _baseToken, address _swapToken) public view returns (uint256);

    //获取风险值
    function getRisk(address _account, uint256 _id) public view returns (uint256);

    // function getIdRiskArrayPair(address _account) public view returns ([]uint256, []uint256);

    function getAccountCurrRecordIds(address _account) public view returns (uint256[] memory);

    function getAccountConfigDetail(address _account, uint256 _id)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            bool
        );
    function getBailAddress(address _account, uint256 _id) public view returns (address[] memory);

    function getBailConfigDetail(
        address _account,
        uint256 _id,
        address _bailToken
    )
        public
        view
        returns (
            string memory,
            uint256,
            uint256
        );
        
    // function setCapital(ICap)
}

// File: marginSwap/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        return msg.data;
    }
}

// File: marginSwap/utils/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;


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
    constructor() public {
        _setOwner(_msgSender());
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
    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: marginSwap/utils/ErrorReporter.sol

pragma solidity ^0.5.16;

contract ControllerErrorReporter {
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

contract ErrorReporter {
    enum Error1 {
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
    enum FailureInfo1 {
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
    function fail(Error1 err, FailureInfo1 info) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), 0);

        return uint256(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(
        Error1 err,
        FailureInfo1 info,
        uint256 opaqueError
    ) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), opaqueError);

        return uint256(err);
    }
}

// File: marginSwap/utils/tools.sol

pragma solidity ^0.5.16;


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
    uint256 public initialExchangeRateMantissa;

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
    mapping(address => mapping(uint256 =>BorrowSnapshot)) internal accountBorrowsMarginSP; //MarginSwapPool
    mapping(address => mapping(uint256 =>BorrowSnapshot)) internal accountBorrowsMiningSP; //MiningSwapPool

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

    function getAccountSnapshot(address account, uint256 id, LoanType loanType)
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

    function borrowBalanceCurrent(address account, uint256 id, LoanType loanType) external returns (uint256);

    function borrowBalanceStored(address account, uint256 id, LoanType loanType) public view returns (uint256);

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

    function redeem(uint256 redeemTokens) external returns (uint256, uint256, uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256, uint256, uint256);

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

// File: CarefulMath.sol

// File: Exponential.sol

pragma solidity ^0.5.16;



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

// File: ExponentialNoError.sol

pragma solidity ^0.5.16;


// File: IPublicsLoanInterface.sol

pragma solidity ^0.5.16;


contract IPublicsLoanInterface is LoanTypeBase {
    /**
     *@notice 获取依赖资产地址
     *@return (address): 地址
     */
    function underlying() public view returns (address);

    /**
     *@notice 真实借款数量（本息)
     *@param _account:实际借款人地址
     *@param _loanType:借款类型
     *@return (uint256): 错误码(0表示正确)
     */
    function borrowBalanceCurrent(address _account, uint256 id, LoanType _loanType) external returns (uint256);

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
     *@return (uint256, uint256, uint256,uint256): 错误码(0表示正确), pToken数量, 借款(快照)数量, 兑换率
     */
    function getAccountSnapshot(address _account, uint256 _id, LoanType _loanType) external view returns (uint256, uint256, uint256,uint256);

    /**
     *@notice 信用贷借款
     *@param _borrower:实际借款人的地址
     *@param _borrowAmount:实际借款数量
     *@param _id: 仓位id
     *@param _loanType:借款类型
     *@return (uint256): 错误码
     */
    function doCreditLoanBorrow( address payable _borrower, uint256 _borrowAmount, uint256 _id, LoanType _loanType) public returns (uint256);

    /**
     *@notice 信用贷还款
     *@param _payer:实际还款人的地址
     *@param _repayAmount:实际还款数量
     *@param _id: 仓位id
     *@param _loanType:借款类型
     *@return (uint256, uint256): 错误码, 实际还款数量
     */
    function doCreditLoanRepay(address _payer, uint256 _repayAmount, uint256 _id, LoanType _loanType) public returns (uint256, uint256);
}

// File: marginSwap/MarginSwapPool.sol

pragma solidity ^0.5.16;


// import "hardhat/console.sol";















contract MarginSwapPool is IMSPInterface, Tools, Ownable, Exponential, ErrorReporter {
    using SafeMath for uint256;

    constructor(ICapitalInterface _capital) public {
        capital = _capital;
        mspstorage = _capital.getStorage();
        controller = mspstorage.controller();
        assetUnderlying = mspstorage.assetUnderlying();
        pTokenUnderlying = mspstorage.pTokenUnderlying();
        assetUnderlyingSymbol = mspstorage.assetUnderlyingSymbol();
    }

    modifier nonReentrant() { 
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    struct posLocalVars {
        uint256 currentId;
        string uniqueName;
        uint256 borrowAmount;
        uint256 acturallySwapAmount;
        uint256 err0;
        bool isAlreadyExist;
    }

    struct closeLocalVars {
        uint256 totalAsset;
        address currAsset;
        uint256 acturallySwapAmount;
        uint256 needToPayback;
        uint256 backToAccountAmt;
    }

    //开仓
    function openPosition(
        uint256 _supplyAmount,
        uint256 _leverage,
        EIP20Interface _swapToken,
        uint256 _slippageTolerance
    ) public nonReentrant returns (uint256) {
        require(_leverage >= BASE10 && _leverage <= 3 * BASE10 , "10 <= leverage <= 30, step 1 only!");
        require(controller.isSwapTokenAllowed(address(_swapToken)), "swap token is not in white list");
        require(address(_swapToken) != address(mspstorage.assetUnderlying()), "swap token is not supported");

        posLocalVars memory vars;
        vars.borrowAmount = _supplyAmount.div(BASE10).mul(_leverage - BASE10);
        require(vars.borrowAmount <= PTokenInterface(pTokenUnderlying).getCash(), "money insufficient!");

        string memory swapTokenSymbol = EIP20Interface(_swapToken).symbol();
        vars.uniqueName = Tools.strConcat(mspstorage.assetUnderlyingSymbol(), swapTokenSymbol);
        // console.log("1. vars.uniqueName:", vars.uniqueName);
        vars.isAlreadyExist = mspstorage.getAccountRecordExistFlag(msg.sender, vars.uniqueName);

        if (vars.isAlreadyExist) {
            // console.log("已经存在，进入morePosition逻辑");
            return morePosition(mspstorage.lastId(), _supplyAmount, _leverage, _swapToken, _slippageTolerance);
        } 

        mspstorage.updateID();
        vars.currentId = mspstorage.lastId();
        vars.err0 = controller.openPositionAllowed(address(this));
        require(vars.err0 == 0, "this msp is paused!");

        //1. save mspconfig
        MSPStruct.MSPConfig memory mspconfig =
            MSPStruct.MSPConfig({
                id: vars.currentId,
                supplyAmount: _supplyAmount,
                leverage: _leverage,
                borrowAmount: vars.borrowAmount,
                swapToken: _swapToken,
                slippageTolerance: _slippageTolerance,
                isAutoSupply: false,
                isExist: true
            });

        vars.acturallySwapAmount = borrowAndSwapInternal(_supplyAmount, vars.borrowAmount, _swapToken, vars.currentId, _slippageTolerance);
        emit OpenPositionEvent(vars.currentId, _supplyAmount, _leverage, vars.borrowAmount, address(_swapToken), vars.acturallySwapAmount, _slippageTolerance);

        //1. 更新建仓结构
        mspstorage.setAccountMspConfig(msg.sender, mspconfig.id, mspconfig);
        mspstorage.setAccountRecordIds(msg.sender, mspconfig.id);

        //2. 更新到保证金结构中
        //将兑换回来的token直接添加到保证金中，统一管理
        MSPStruct.supplyConfig memory scs = makeSupplyConfigInternal(EIP20Interface(_swapToken).symbol(), address(_swapToken), vars.acturallySwapAmount);
        mspstorage.setSupplyConfig(msg.sender, mspconfig.id, address(_swapToken), scs);
        mspstorage.setBailAddress(msg.sender, mspconfig.id, address(_swapToken));
        
        //增加债务空结构，用于清算使用 //TODO
        scs = makeSupplyConfigInternal(EIP20Interface(assetUnderlying).symbol(), address(assetUnderlying), 0);
        mspstorage.setSupplyConfig(msg.sender, mspconfig.id, address(assetUnderlying), scs);
        mspstorage.setBailAddress(msg.sender, mspconfig.id, address(assetUnderlying));

        // console.log("2. vars.uniqueName:", vars.uniqueName);
        mspstorage.setAccountRecordExistFlag(msg.sender, vars.uniqueName, true);
        return vars.currentId;
    }

    //加仓
    function morePosition(
        uint256 _id,
        uint256 _supplyAmount,
        uint256 _leverage,
        EIP20Interface _swapToken,
        uint256 _slippageTolerance
    ) public returns (uint256){
        require(_leverage >= BASE10 && _leverage <= 3 * BASE10 , "10 <= leverage <= 30, step 1 only!");
        require(controller.isSwapTokenAllowed(address(_swapToken)), "swap token is not in white list");
        require(address(_swapToken) != address(mspstorage.assetUnderlying()), "swap token is not supported");

        //2. 借款数量:
        uint256 borrowAmount = _supplyAmount.div(BASE10).mul(_leverage - BASE10);
        // console.log("vars.borrowAmount:", vars.borrowAmount);
        require(borrowAmount <= (PTokenInterface(pTokenUnderlying)).getCash(), "money insufficient!");

        //3. 转账并swap目标token
        uint256 acturallySwapAmount = borrowAndSwapInternal(_supplyAmount, borrowAmount, _swapToken, _id, _slippageTolerance);

        //4. 是否存入到借贷池
        MSPStruct.MSPConfig memory mspconfig = mspstorage.getAccountMspConfig(msg.sender, _id);
        depositAndUpdateInternal(msg.sender, _id,  acturallySwapAmount, address(_swapToken), mspconfig.isAutoSupply);

        //5. 数据更新到记录
        uint256 currDebt = PTokenInterface(pTokenUnderlying).borrowBalanceCurrent(msg.sender, _id, LoanTypeBase.LoanType.MARGIN_SWAP_PROTOCOL);
        // console.log("currDebt:", currDebt, "_repayAmount:", _repayAmount);

        mspconfig.supplyAmount = mspconfig.supplyAmount.add(_supplyAmount);
        mspconfig.borrowAmount = currDebt.add(borrowAmount); 
        mspstorage.setAccountMspConfig(msg.sender, _id, mspconfig);

        emit MorePositionEvent(_id, _supplyAmount, _leverage, borrowAmount, address(_swapToken), acturallySwapAmount, _slippageTolerance);
        return _id;
    }

    function borrowAndSwapInternal(uint256 _supplyAmount, uint256 _borrowAmount, EIP20Interface _swapToken, uint256 _id, uint256 _slippageTolerance) internal returns (uint256) {
        require(_supplyAmount != 0, "invalid supply amount input!");
        //2. get supply money
        capital.doTransferIn(msg.sender, assetUnderlying, _supplyAmount, address(this));

        //3. get credit loan
        uint256 borrowError = capital.doCreditLoanBorrowInternal(msg.sender, _borrowAmount, _id, address(this));
        require(borrowError == 0, "doCreditLoanBorrow failed!");

        // ******* 测试模拟dex ********* /
        uint256 supplyAmount = _supplyAmount.add(_borrowAmount);
        // console.log("aboutToSwapAmnt:", aboutToSwapAmnt);

        return swapAndDepositBack(assetUnderlying, supplyAmount, address(_swapToken), _slippageTolerance);
    }

    function swapAndDepositBack(address _fromToken, uint256 _supplyAmount, address _swapToken, uint256 _slippageTolerance) internal returns (uint256){
        //模拟的时候需要传递pToken
        (address dexCandidate, uint256 willSwapAmt) =
            controller.getDexSwapper().getCandiadate(controller.getPToken(_fromToken), _supplyAmount, controller.getPToken(address(_swapToken)), _slippageTolerance);
        // console.log("dexCandidate", dexCandidate, "willSwapAmt", willSwapAmt);
        
        address payable wallet = address(uint160(address(this)));
        capital.doTransferOut(wallet, _fromToken, _supplyAmount, address(this));

        EIP20Interface(_fromToken).approve(dexCandidate, _supplyAmount);
        uint256 acturallySwapAmt = controller.getDexSwapper().swap(_fromToken, _supplyAmount, address(_swapToken), dexCandidate, willSwapAmt);
        
        EIP20Interface(_swapToken).approve(address(capital), acturallySwapAmt);
        capital.doTransferIn(address(this), address(_swapToken), acturallySwapAmt, address(this));

        return acturallySwapAmt;
    }
    
    function addMargin(uint256 _id, uint256 _amount, address _supplyToken) public nonReentrant {
        require(controller.isBailTokenAllowed(_supplyToken), "bail token not in white list!");
        require(_amount != 0, "invalid supply amount input!");

        capital.doTransferIn(msg.sender, _supplyToken, _amount, address(this));

        MSPStruct.MSPConfig memory mspconfig = mspstorage.getAccountMspConfig(msg.sender, _id);
        depositAndUpdateInternal(msg.sender, _id,  _amount, _supplyToken, mspconfig.isAutoSupply);

        emit AddMarginEvent(_id, _amount, _supplyToken);
    }

    function depositAndUpdateInternal(address _account, uint256 _id, uint256 _amount, address _supplyToken, bool _isAutoSupply) internal {
        MSPStruct.supplyConfig memory scs = mspstorage.getSupplyConfig(_account, _id, _supplyToken);

        if (_isAutoSupply) {
            (uint256 error, uint256 mintPToken) = capital.depositSpecToken(_account, _id, _supplyToken, _amount, address(this));
            require(error == 0, "capital.depositSpecToken error!");

            scs.pTokenAmount = scs.pTokenAmount.add(mintPToken);
        } else {
            scs.supplyAmount = scs.supplyAmount.add(_amount);
        }

        if (scs.supplyToken == address(0)) {
            scs.supplyToken = _supplyToken;
            scs.symbol = EIP20Interface(_supplyToken).symbol();

            mspstorage.setBailAddress(_account, _id, _supplyToken);
        }

        mspstorage.setSupplyConfig(_account, _id, _supplyToken, scs);
    }

    //提取保证金，指定币种提取
    function redeemMargin(
        uint256 _id,
        uint256 _amount,
        address _modifyToken
    ) public nonReentrant {
        require(_amount != 0, "invalid supply amount input!");

        // 2. 提取前提是不可以触发清算，否则失败退出
        uint256 allowed = controller.redeemAllowed(msg.sender, this, _id, _modifyToken, _amount);
        // console.log("allowed:", allowed);
        require(allowed == 0, "redeem amount will cause liquidation, denied!");

        (uint256 error, uint256 actualAmt, uint256 actualPToken) = capital.redeemUnderlying(msg.sender, _id, _modifyToken, _amount, address(this));
        require(error == 0, "capital.redeemUnderlying error!");
        // console.log("actualAmt:", actualAmt, "redeemUnderlying:", actualPToken);

        capital.doTransferOut(msg.sender, _modifyToken, actualAmt, address(this));
        MSPStruct.supplyConfig memory scs = mspstorage.getSupplyConfig(msg.sender, _id, _modifyToken);

        // 1. 如果已经存入借贷市场，需要先取出来，失败退出
        MSPStruct.MSPConfig memory mspconfig = mspstorage.getAccountMspConfig(msg.sender, _id);

        //3. 按照用户输入数量，直接去取款，先判断是否存入
        if (mspconfig.isAutoSupply) {
            // console.log("scs.supplyAmount :", scs.supplyAmount, "actualAmt:", actualAmt);
            scs.pTokenAmount = scs.pTokenAmount.sub(actualPToken);
        } else {
            // console.log("scs.pTokenAmount :", scs.pTokenAmount, "actualPToken:", actualPToken);
            scs.supplyAmount = scs.supplyAmount.sub(actualAmt);
        }

        //如果全部取出，则删除记录
        if (scs.supplyAmount == 0 && scs.pTokenAmount == 0) {
            mspstorage.deleteBailAddress(msg.sender, _id, _modifyToken);
        }

        // 4. 更新保证金结构
        mspstorage.setSupplyConfig(msg.sender, _id, _modifyToken, scs);
        emit ReedeemMarginEvent(_id, _amount, _modifyToken);
    }

    //还款1: 还信用贷的借款，从钱包扣除
    function repay(uint256 _id, uint256 _repayAmount) public returns (uint256, uint256) {
        MSPStruct.MSPConfig memory mspconfig = mspstorage.getAccountMspConfig(msg.sender, _id);

        uint256 currDebt = PTokenInterface(pTokenUnderlying).borrowBalanceCurrent(msg.sender, _id, LoanTypeBase.LoanType.MARGIN_SWAP_PROTOCOL);
        // console.log("currDebt:", currDebt, "_repayAmount:", _repayAmount);
        require(currDebt != 0, "borrow amount is 0, no need to repay");

        //1. 先还款
        //1. 从用户钱包扣款到MSP
        capital.doTransferIn(msg.sender, assetUnderlying, _repayAmount, address(this));

        //1.b 如果输入小于余额但是大于债务，更新还款数字为债务值(还款合约内部处理了)
        (uint256 err, uint256 actualAmt) = capital.doCreditLoanRepayInternal(msg.sender, _repayAmount, _id, address(this));
        // console.log("callerBalance:", callerBalance, "actualAmt:", actualAmt);
        require(err == 0, "repay failed!");

        uint256 left = _repayAmount.sub(actualAmt);
        if (left > 0) {
            capital.doTransferOut(msg.sender, assetUnderlying, left, address(this));
        }

        //2. 更新结构
        //config中的数据只是用户借的，偿还的时候有可能包含了利息
        mspconfig.borrowAmount = currDebt.sub(actualAmt);
        mspstorage.setAccountMspConfig(msg.sender, _id, mspconfig);

        emit RepayEvent(_id, _repayAmount, uint256(Error1.BAD_INPUT));
        return (uint256(Error1.NO_ERROR), actualAmt);
    }

    struct RepayVars {
        uint256 id;
        uint256 oraclePriceMantissa;
        uint256 exchangeRateMantissa;
        address bailToken;
        uint256 borrowBalance;
        uint256 holdAmount;
        uint256 acturallySwapAmt;
        uint256 oErr;
        uint256 amount;
        Exp oraclePrice;
        Exp exchangeRate;
        
        uint256 actualAmt;
        uint256 actualPToken;
    }

    //废弃，保留 //TODO
    /*
    {
        // 2. x 计算当前的总债务价值：债务数量*价格
        vars.oraclePriceMantissa = controller.getOracle().getUnderlyingPrice(scs.supplyToken);
        if (vars.oraclePriceMantissa == 0) {
            return (Error.PRICE_ERROR, 0);
        }

        vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});
        uint256 sumBorrow = mul_ScalarTruncate(vars.oraclePrice, vars.borrowBalance);
        // console.log("债务价格:", vars.oraclePriceMantissa, "总债务:", sumBorrow);

        // 3. y 计算准备偿还的总价值：计算输入token数量*价格
        vars.oraclePriceMantissa = controller.getOracle().getUnderlyingPrice(_bailToken);
        if (vars.oraclePriceMantissa == 0) {
            return (Error.PRICE_ERROR, 0);
        }

        vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});
        uint256 sumBail = mul_ScalarTruncate(vars.oraclePrice, _amount);
        // console.log("保证金价格:", vars.oraclePriceMantissa, "总repay价值:", sumBail);
    }
    */

    /**
     *@notice 还款2: 从用户指定保证金还款，常规平仓(多余的会返回)
     *@param _id: 持仓id
     *@param _bailToken: 保证金
     *@param _amount: 保证金数量
     *@return (uint256, uint256): 错误码(0表示正确), 获取Token数量，实际还款数量
        /* 实现思路:
        1. 校验参数
        2. x 计算当前的总债务价值：债务数量*价格
        3. y 计算准备偿还的总价值：计算输入token数量*价格
        4. 如果x >= y，直接还y，swap
        5. 如果x < y，偿还债务实际价值，将多余的还给用户
        */
    function repayFromMargin(uint256 _id, address _bailToken, uint256 _amount, uint256 _slippageTolerance) public returns (uint256, uint256){
        RepayVars memory vars;
        vars.id = _id;
        vars.bailToken = _bailToken;
        vars.amount = _amount;
        
        // 1. 校验参数
        MSPStruct.supplyConfig memory scs = mspstorage.getSupplyConfig(msg.sender, vars.id, vars.bailToken);
        require(scs.supplyToken != address(0), "invalid address input!");

        uint256 error1 = PTokenInterface(pTokenUnderlying).accrueInterest();
        if (error1 != uint256(Error1.NO_ERROR)) {
            return (fail(Error1(error1), FailureInfo1.LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED), 0);
        }

        //确保计算用户输入的数量是否小于等于实际持有的数量
        (vars.oErr, , vars.borrowBalance, vars.exchangeRateMantissa) = PTokenInterface(pTokenUnderlying).getAccountSnapshot(msg.sender, vars.id, LoanTypeBase.LoanType.MARGIN_SWAP_PROTOCOL);
        if (vars.oErr != 0) {
            return (0, 0);
        }

        MSPStruct.MSPConfig memory mspconfig = mspstorage.getAccountMspConfig(msg.sender, vars.id);

        if (mspconfig.isAutoSupply) {
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa}); //转成结构体
            vars.holdAmount = mul_ScalarTruncate(vars.exchangeRate, scs.pTokenAmount);
        }

        //确保数量充足
        require(scs.supplyAmount >= vars.amount || vars.holdAmount >= vars.amount, "not enough amount to repay!");

        //1. 将保证金兑换为债务资产
        //先将取出来
        if (mspconfig.isAutoSupply) {
            (vars.oErr, vars.actualAmt, vars.actualPToken) = capital.redeemUnderlying(msg.sender, vars.id, _bailToken, vars.amount, address(this));
            require(vars.oErr == 0, "capital.redeemUnderlying error!");
            require(vars.actualAmt == vars.amount, "redeemUnderlying error!");

            // console.log("actualAmt:", vars.actualAmt, "amount:", vars.amount);
        }

        //我们就是按照用户输入的数量进行兑换的: A->B
        vars.acturallySwapAmt = swapAndDepositBack(_bailToken, vars.amount, assetUnderlying, _slippageTolerance);
        // console.log("vars.acturallySwapAmt:", vars.acturallySwapAmt);
        //2. 偿还债务 借了20个，可能兑换：10个或30个
        //债务大于还款，全部还掉
        uint256 repayAmnt = vars.borrowBalance >= vars.acturallySwapAmt? vars.acturallySwapAmt: vars.borrowBalance;
        // console.log("vars.borrowBalance:", vars.borrowBalance);
        // console.log("vars.acturallySwapAmt:", vars.acturallySwapAmt);
        // console.log("repayAmnt:", repayAmnt);

        (uint256 err, uint256 actualRepay) = capital.doCreditLoanRepayInternal(msg.sender, repayAmnt, vars.id, address(this));
        // console.log("credit repay:", actualRepay);
        require(err == 0, "repayFromMargin::credit loan repay failed!");

        //更新结构MSP结构
        // mspconfig.borrowAmount = mspconfig.borrowAmount.sub(reapyAmnt); //可以删掉这个字段，不去维护//TODO
        // mspstorage.setAccountMspConfig(msg.sender, _id, mspconfig);

        //更新swapToken结构
        uint256 left = vars.acturallySwapAmt.sub(actualRepay);
        // console.log("left:", left);
        if (left > 0) {
            //如果还多了，直接作为保证金了
            depositAndUpdateInternal(msg.sender, vars.id, left, address(assetUnderlying), mspconfig.isAutoSupply);
        }

        //更新_bailToken结构
        if (mspconfig.isAutoSupply) {
            scs.pTokenAmount = scs.pTokenAmount.sub(vars.actualPToken);
            // console.log("scs.pTokenAmount:", scs.pTokenAmount);
        } else {
            scs.supplyAmount = scs.supplyAmount.sub(vars.amount);
            // console.log("scs.supplyAmount:", scs.supplyAmount);
        }
        mspstorage.setSupplyConfig(msg.sender, vars.id, vars.bailToken, scs);

        //如果全部取出，则删除记录
        if (scs.supplyAmount == 0 && scs.pTokenAmount == 0) {
            mspstorage.deleteBailAddress(msg.sender, vars.id, vars.bailToken);
        }

        emit RepayFromMarginEvent(vars.id, vars.bailToken, vars.amount);
    }

    // 这个是一键平仓：平仓， 全部兑换成债务资产，然后换掉(前端不展示)
    function closePosition(uint256 _id) public nonReentrant returns (uint256) {
        /*
        MSPStruct.MSPConfig memory mspconfig = mspstorage.getAccountMspConfig(msg.sender, _id);

        // 1. 如果发现ETH已经存入资金池（持有pToken），则先赎回：disableWithDraw方法
        if (mspconfig.isAutoSupply) {
            uint256 error = capital.disabledAndDoWithdraw(msg.sender, _id, address(this));
            require(error == 0, "disabledAndDoWithdraw error!");
        }

        posLocalVars memory vars;
        closeLocalVars memory closeVars;

        address[] memory bailAssests = mspstorage.getBailAddress(msg.sender, _id);

        //1. 遍历所有的保证金(包括兑换回来的UNI，空的BUSD，以及后续追加资产)
        for (uint256 i = 0; i < bailAssests.length; i++) {
            closeVars.currAsset = bailAssests[i];
            // console.log("currAsset:", closeVars.currAsset);
            MSPStruct.supplyConfig memory scs = mspstorage.getSupplyConfig(msg.sender, _id, closeVars.currAsset);

            if (scs.supplyAmount == 0) {
                // console.log("supplyAmount = 0");
                continue;
            }

            //2. 将所有的资产兑换为债务资产
            if (closeVars.currAsset == assetUnderlying) {
                closeVars.totalAsset = closeVars.totalAsset.add(scs.supplyAmount);
                mspstorage.setSupplyConfig(msg.sender, _id, closeVars.currAsset, scs);
                // console.log("自身，不用兑换，直接累加资产!");
                continue;
            }

            //查找最佳dex
            (address dexCandidate, uint256 willSwapAmt) =
                controller.getDexSwapper().getCandiadate(
                    controller.getPToken(address(closeVars.currAsset)),
                    scs.supplyAmount,
                    controller.getPToken(assetUnderlying),
                    mspconfig.slippageTolerance
                );

            // console.log("willSwapAmt:", willSwapAmt, " closeVars.currAsset:",  closeVars.currAsset);
            require(dexCandidate != address(0), "dexCandidate != address(0)");
            
            address payable wallet = address(uint160(address(this)));
            capital.doTransferOut(wallet, closeVars.currAsset, scs.supplyAmount, address(this));
            // console.log("到账:", EIP20Interface(closeVars.currAsset).balanceOf(address(this)));
            // console.log("scs.supplyAmount:", scs.supplyAmount);
            EIP20Interface(closeVars.currAsset).approve(dexCandidate, scs.supplyAmount);

            closeVars.acturallySwapAmount = controller.getDexSwapper().swap(address(closeVars.currAsset), scs.supplyAmount, assetUnderlying, dexCandidate, willSwapAmt);
            // console.log("scs.supplyAmount:",scs.supplyAmount);
            // console.log("closeVars.acturallySwapAmount:", closeVars.acturallySwapAmount);

            closeVars.totalAsset = closeVars.totalAsset.add(closeVars.acturallySwapAmount);
            // console.log("closeVars.totalAsset:", closeVars.totalAsset);

            //维护保证金列表，删除，这个可以删除 //TODO
            mspstorage.deleteBailAddress(msg.sender, _id, closeVars.currAsset);
        }

        //把兑换的资金转给captial
        EIP20Interface(assetUnderlying).approve(address(capital), closeVars.totalAsset);
        capital.doTransferIn(address(this), assetUnderlying, closeVars.totalAsset, address(this));

        // 3. 偿还BUSD，得到剩余的BUSD（本金）,
        closeVars.needToPayback = PTokenInterface(pTokenUnderlying).borrowBalanceCurrent(msg.sender, _id, LoanTypeBase.LoanType.MARGIN_SWAP_PROTOCOL);
        require(closeVars.totalAsset >= closeVars.needToPayback, "money insufficient, should be liquidated!");
        // console.log("final totalAsset:", closeVars.totalAsset);
        // console.log("needToPayback:", closeVars.needToPayback);

        (uint256 err, uint256 actualAmt) = capital.doCreditLoanRepayInternal(msg.sender, closeVars.needToPayback, _id, address(this));
        // console.log("actualAmt:", actualAmt);
        require(err == 0, "closePosition::credit loan repay failed!");

        //4. 剩余的资产还给用户
        closeVars.backToAccountAmt = closeVars.totalAsset.sub(actualAmt);
        // console.log("backToAccountAmt:", closeVars.backToAccountAmt);
        // require(backToAccountAmt > 0, "backToAccountAmt should gt 0");

        if (closeVars.backToAccountAmt > 0) {
            capital.doTransferOut(msg.sender, assetUnderlying, closeVars.backToAccountAmt, address(this));
        }

        // 5. 更新结构
        mspconfig.isExist = false;
        mspstorage.setAccountMspConfig(msg.sender, _id, mspconfig);

        string memory swapTokenSymbol = EIP20Interface(mspconfig.swapToken).symbol();
        vars.uniqueName = Tools.strConcat(assetUnderlyingSymbol, swapTokenSymbol);
        // console.log("3. vars.uniqueName:", vars.uniqueName);
        mspstorage.setAccountRecordExistFlag(msg.sender, vars.uniqueName, false);

        // 6. 维护当前持仓的ID列表
        mspstorage.deleteClosedAccountRecord(msg.sender, _id);
        emit ClosePositionEvent(_id, closeVars.needToPayback, closeVars.backToAccountAmt);
        */
    }
    
    // 允许存款并转入
    function enabledAndDoDeposit(uint256 _id) public returns (uint256) {
        uint256 err = capital.enabledAndDoDeposit(msg.sender, _id, address(this));

        emit EnabledAndDoDepositEvent(_id);
        return err;
    }

    // 禁止存入并转出
    function disabledAndDoWithdraw(uint256 _id) public returns (uint256) {
        uint256 err = capital.disabledAndDoWithdraw(msg.sender, _id, address(this));

        emit DisabledAndDoWithdrawEvent(_id);
        return err;
    }

    function getSwapPrice(address _baseToken, address _swapToken) public view returns (uint256) {
        return 0;
    }

    //获取风险率
    function getRisk(address _account, uint256 _id) public view returns (uint256) {
        // 总抵押 * 0.8 - 总借款（本金+借款）<= 0时，触发清算条件。
        (uint256 err, ,uint256 risk,) = controller.getAccountLiquidity(_account, this, _id);
        // console.log("shortfall: ", shortfall);

        if (err != uint256(Error1.NO_ERROR)) {
            return uint256(err);
        }

        return risk;
    }

    // function getIdRiskArrayPair(uint256 []_ids) public view returns ([]uint256, []uint256) {
    //     for (uint256 i = 0; i < _ids.length; i++) {
    //         uint256 risk = getRisk(_account, ids[i]);
    //     }
    // }


    function getAccountCurrRecordIds(address _account) public view returns (uint256[] memory) {
        return mspstorage.getAccountRecordIds(_account);
    }

    function getAccountConfigDetail(address _account,uint256 _id)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            bool
        )
    {
        MSPStruct.MSPConfig memory msc = mspstorage.getAccountMspConfig(_account, _id);

        (,,uint256 borrowBalance,) = PTokenInterface(pTokenUnderlying).getAccountSnapshot(_account, _id, LoanTypeBase.LoanType.MARGIN_SWAP_PROTOCOL);
        return (msc.id, msc.supplyAmount, msc.leverage, borrowBalance, address(msc.swapToken), msc.slippageTolerance, msc.isAutoSupply);
    }

    function getBailAddress(address _account,uint256 _id) public view returns (address[] memory) {
        return mspstorage.getBailAddress(_account, _id);
    }

    function getBailConfigDetail(
        address _account,
        uint256 _id,
        address _bailToken
    )
        public
        view
        returns (
            string memory,
            uint256,
            uint256
        )
    {
        MSPStruct.supplyConfig memory scs = mspstorage.getSupplyConfig(_account, _id, _bailToken);
        return (scs.symbol, scs.supplyAmount, scs.pTokenAmount);
    }

    function getPTokenUnderlying() public view returns (address) {
        return address(pTokenUnderlying);
    }
    
    function makeSupplyConfigInternal(string memory _symbol, address _supplyToken, uint256 _supplyAmount) internal view returns (MSPStruct.supplyConfig memory) {
        return MSPStruct.supplyConfig({symbol: _symbol, supplyToken: _supplyToken, supplyAmount: _supplyAmount, pTokenAmount: 0});
    }

    //获取资产数量
    function getAssetUnderlyingBalance(address _owner) public view returns (uint256) {
        return EIP20Interface(assetUnderlying).balanceOf(_owner);
    }
}