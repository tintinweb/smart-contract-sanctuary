/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

pragma solidity ^0.5.16;

contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

contract Exponential is CarefulMath, ExponentialNoError {
    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
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
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CToken cToken) external view returns (uint);
}

contract ComptrollerInterface {
   
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;
    
    PriceOracle public oracle;
    
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
    
    function getAssetsIn(address account) external view returns (CToken[] memory);

}

contract Context {
    function _msgSender() internal view  returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view  returns (bytes memory) {
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
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
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
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CToken {
    
    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);
    
    function totalSupply() external view returns (uint256);
    
    function totalReserves() external view returns (uint256);
    
    function totalBorrows() external view returns (uint256);
    
    function borrowIndex() external view returns (uint256);

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint);

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint);
    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public view returns (uint);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view returns (uint);

}

contract PlanetDiscount is Exponential,Ownable{
    
    
    address public gGammaAddress = 0x015bB997BD548A411359681FFEA2964e070f66b0;
    address public comptroller = 0x068cc7e399CFc538aB9404EEC0c65A48751F5e9c;
    address public oracle = 0x919Ce01ca1B3568B092AC7d9deACD857d6cf8914;
    
    uint256 public level0Discount = 0;
    uint256 public level1Discount = 500;
    uint256 public level2Discount = 2000;
    uint256 public level3Discount = 5000;
   
    uint256 public level1Min = 100;
    uint256 public level2Min = 500;
    uint256 public level3Min = 1000;
    
    
    /**
     * @notice Total amount of underlying discount given
     */
    mapping(address => uint) public totalDiscountGiven;
    
    mapping(address => bool) public deprecatedMarket;
    
    mapping(address => bool) public isMarketListed;
    
    address[] public deprecatedMarketArr;
    
    /*
     * @notice Array of users which have some supply balnce in market
     */
    mapping(address => address[]) public usersWhoHaveSupply;
    
    
    /*
     * @notice Official record of each user whether the user is present in profitGetters or not
     */
    mapping(address => mapping(address => supplyDiscountSnapshot)) public supplyDiscountSnap;
    
    
    /*
     * @notice Official record of each user whether the user is present in discountGetters or not
     */
    mapping(address => mapping(address => BorrowDiscountSnapshot)) public borrowDiscountSnap;
    
    /**
     * @notice Container for Discount information
     * @member exist (whether user is present in Profit scheme)
     * @member index (user address index in array of usersWhoHaveBorrow)
     * @member lastExchangeRateAtSupply(the last exchange rate at which profit is given to user)
     * @member lastUpdated(timestamp at which it is updated last time)
     */
    struct supplyDiscountSnapshot {
        bool exist;
        uint index;
        uint lastExchangeRateAtSupply;
        uint lastUpdated;
    }
    
    struct ReturnBorrowDiscountLocalVars {
        uint marketTokenSupplied;
    }
    
    mapping(address => address[]) public usersWhoHaveBorrow;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }
    
    /**
     * @notice Container for Discount information
     * @member exist (whether user is present in Discount scheme)
     * @member index (user address index in array of usersWhoHaveBorrow)
     * @member lastRepayAmountDiscountGiven(the last repay amount at which discount is given to user)
     * @member accTotalDiscount(total discount accumulated to the user)
     * @member lastUpdated(timestamp at which it is updated last time)
     */
    struct BorrowDiscountSnapshot {
        bool exist;
        uint index;
        uint lastBorrowAmountDiscountGiven;
        uint accTotalDiscount;
        uint lastUpdated;
    }

    
   /**
    * @notice Event emitted when discount is changed for user
    */
    event SupplyDiscountAccrued(address market,address supplier,uint discountGiven,uint lastUpdated);
    
   /**
    * @notice Event emitted when discount is changed for user
    */
    event BorrowDiscountAccrued(address market,address borrower,uint discountGiven,uint lastUpdated);
     
    event gGammaAddressChange(address prevgGammaAddress,address newgGammaAddress);
    
    event comptrollerChange(address prevComptroller,address newComptroller);
    
    event oracleChanged(address prevOracle,address newOracle);
    
    function changeAddress(address _newgGammaAddress,address _newComptroller,address _newOracle) public onlyOwner {
        address _gGammaAddress = gGammaAddress;
        address _comptroller = comptroller;
        address _oracle = oracle;
        
        gGammaAddress = _newgGammaAddress;
        comptroller = _newComptroller;
        oracle = _newOracle;
        
        emit gGammaAddressChange(_gGammaAddress,_newgGammaAddress);
        emit comptrollerChange(_comptroller,_newComptroller);
        emit oracleChanged(_oracle,_newOracle);
    }
    
    
    function deprecateMarket(address market) public onlyOwner {
       require(!deprecatedMarket[market],"market already deprecated");
       deprecatedMarket[market] = true;
       deprecatedMarketArr.push(market);
    }
    
    function deprecateMarkets(address[] memory markets) public onlyOwner {
       for(uint i = 0 ; i < markets.length ; i++){
        address market = markets[i];
        require(!deprecatedMarket[market],"market already deprecated");
        deprecatedMarket[market] = true;
        deprecatedMarketArr.push(market);
       }
    }
    
    function listMarket(address market) public onlyOwner {
       require(!isMarketListed[market],"market already listed");
       isMarketListed[market] = true;
    }
    
    function listMarkets(address[] memory markets) public onlyOwner {
       for(uint i = 0 ; i < markets.length ; i++){
        address market = markets[i];
         require(!isMarketListed[market],"market already listed");
         isMarketListed[market] = true;
       }
    }
    
    
    function returnBorrowerStakedAsset(address borrower,address market) public view returns(uint256){
        
        address marketAddress = market;
        ReturnBorrowDiscountLocalVars memory vars;
        
        (,uint gTokenBalance,,uint exchangeRate) = CToken(marketAddress).getAccountSnapshot(borrower);
        
        if(gTokenBalance != 0){
            uint price = PriceOracle(oracle).getUnderlyingPrice(CToken(marketAddress));
        
            (, vars.marketTokenSupplied) = mulScalarTruncate(Exp({mantissa: gTokenBalance}), exchangeRate);
            (, uint256 marketTokenSuppliedInBnb) = mulScalarTruncate(Exp({mantissa: vars.marketTokenSupplied}), price);
        
            return (marketTokenSuppliedInBnb);
        }
        else{
            return 0;
        }
    }
   
    
    function returnDiscountPercentage(address borrower) public view returns(uint discount){
        
        //scaled upto 2 decimal like if 50% then output is 5000
       
        CToken[] memory userInMarkets = ComptrollerInterface(comptroller).getAssetsIn(borrower);
        
        uint256 gammaStaked = returnBorrowerStakedAsset(borrower,gGammaAddress);
        uint256 otherStaked = 0; 
        
        for(uint i = 0; i < userInMarkets.length ;i++){
            
            CToken _market = userInMarkets[i];
            
            if(_market != CToken(gGammaAddress) && !deprecatedMarket[address(_market)]){
                
                (,otherStaked) = addUInt(otherStaked,returnBorrowerStakedAsset(borrower,address(_market)));
            
            }
            
        }
        
        
        (, Exp memory _discount) = getExp(gammaStaked,otherStaked);
        (,_discount.mantissa) = mulUInt(_discount.mantissa,100);
        (, uint256 _scaledDiscount) = divUInt(_discount.mantissa,1e16);
        discount = _scaledDiscount;
        
        if(level1Min <= discount && discount <= level2Min){
            discount = level1Discount;
        }
        else if(level2Min < discount && discount <= level3Min){
            discount = level2Discount;
        }
        else if(discount > level3Min){
            discount = level3Discount;
        }
        else{
            discount = level0Discount;
        }
        
        
            
    }  
    
    struct MintLocalVars {
        uint exchangeRateMantissa;
        uint mintTokens;
        uint totalSupplyNew;
        uint accountTokensNew;
        uint actualMintAmount;
    }
    
    
    struct SupplyBorrowDiscountLocalVars {
        uint newProfit;
        uint supplyDifference;
    }
    
    struct BorrowLocalVars {
        MathError mathErr;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
    }

    struct BorrowDiscountLocalVars {
        uint newDiscount;
        uint borrowDifference;
    }
    
    function totalReservesAfterDiscount(address market) external view returns(uint res){
        (,res) = subUInt(CToken(market).totalReserves(),totalDiscountGiven[market]);
    }

    
    function changeUserSupplyDiscount(address minter) external returns(uint _totalSupply,uint _accountTokens){
        
        require(isMarketListed[msg.sender],"Market not listed");
        
        CToken market = CToken(msg.sender);
        
        MintLocalVars memory vars;
        
        SupplyBorrowDiscountLocalVars memory discountVars;
        
        supplyDiscountSnapshot storage _supplyDis = supplyDiscountSnap[msg.sender][minter];
        
        (vars.exchangeRateMantissa) = market.exchangeRateStored();
        
        uint discount = returnDiscountPercentage(minter); // 5% => 500,20% => 2000 ,50% => 5000
        (,discount) = divUInt(discount,2);
        
        (,uint accountTokens,,) = market.getAccountSnapshot(minter);
        (,uint exchangeRateDifference) = subUInt(vars.exchangeRateMantissa,_supplyDis.lastExchangeRateAtSupply);
        (,uint currentInterest) = mulScalarTruncate(Exp({mantissa: exchangeRateDifference}), accountTokens);
        
        if( discount > 0 && accountTokens > 0) {
            
            (,discountVars.newProfit) = mulUInt(discount,currentInterest);
            (,discountVars.newProfit) = divUInt(discountVars.newProfit,10000);
            (,discountVars.newProfit) = divScalarByExpTruncate(discountVars.newProfit, Exp({mantissa: vars.exchangeRateMantissa}));
        
            _supplyDis.lastExchangeRateAtSupply = vars.exchangeRateMantissa;
            
            (, vars.accountTokensNew) = addUInt(accountTokens, discountVars.newProfit);
            (, vars.totalSupplyNew)   = addUInt(market.totalSupply(), discountVars.newProfit);
            
            (,totalDiscountGiven[msg.sender]) = addUInt(totalDiscountGiven[msg.sender],discountVars.newProfit);

            _supplyDis.lastUpdated = block.timestamp; 
            
            emit SupplyDiscountAccrued(msg.sender,minter,discountVars.newProfit,_supplyDis.lastUpdated);
            return(vars.totalSupplyNew,vars.accountTokensNew);
        }
        else if( accountTokens == 0){
            
            if(_supplyDis.exist){
                
                address lastUser = usersWhoHaveSupply[msg.sender][usersWhoHaveSupply[msg.sender].length-1];
                supplyDiscountSnapshot storage lastUserInArr = supplyDiscountSnap[msg.sender][lastUser];
            
                usersWhoHaveSupply[msg.sender][_supplyDis.index] = usersWhoHaveSupply[msg.sender][usersWhoHaveSupply[msg.sender].length-1];
                lastUserInArr.index = _supplyDis.index;
                usersWhoHaveSupply[msg.sender].length--;
            
                delete supplyDiscountSnap[msg.sender][minter];
            }
            else{
                usersWhoHaveSupply[msg.sender].push(minter);
                _supplyDis.exist = true;
                _supplyDis.index = usersWhoHaveSupply[msg.sender].length - 1;
                _supplyDis.lastExchangeRateAtSupply = vars.exchangeRateMantissa;
                _supplyDis.lastUpdated = block.timestamp;
            }
        }
        return(market.totalSupply(),accountTokens);
    }
    
    function changeUserBorrowDiscount(address borrower) external returns(uint,uint,uint){
        
        require(isMarketListed[msg.sender],"Market not listed");
        
        CToken market = CToken(msg.sender);
        
        BorrowLocalVars memory vars;
        
        BorrowDiscountLocalVars memory discountVars;
        
        BorrowDiscountSnapshot storage _dis = borrowDiscountSnap[msg.sender][borrower];
        
        uint discount = returnDiscountPercentage(borrower); // 5% => 500,20% => 2000 ,50% => 5000
        (,discount) = divUInt(discount,2);
        
        (uint currentBorrowBal) = market.borrowBalanceStored(borrower);
        
        if( discount > 0 && currentBorrowBal > 0) {
            
            (,discountVars.borrowDifference) = subUInt(currentBorrowBal,_dis.lastBorrowAmountDiscountGiven);

        
            (,discountVars.newDiscount) = mulUInt(discount,discountVars.borrowDifference);
            (,discountVars.newDiscount) = divUInt(discountVars.newDiscount,10000);
        
            _dis.lastBorrowAmountDiscountGiven = currentBorrowBal;
            
            (, vars.accountBorrowsNew) = subUInt(currentBorrowBal, discountVars.newDiscount);
            (, vars.totalBorrowsNew)   = subUInt(market.totalBorrows(), discountVars.newDiscount);
            
            (,totalDiscountGiven[msg.sender]) = addUInt(totalDiscountGiven[msg.sender],discountVars.newDiscount);
         
            _dis.lastUpdated = block.timestamp; 
            
            emit BorrowDiscountAccrued(msg.sender,borrower,discountVars.newDiscount,_dis.lastUpdated);
            
            return(vars.accountBorrowsNew,market.borrowIndex(),vars.totalBorrowsNew);
        }
        else if( currentBorrowBal == 0){
            
            if(_dis.exist){
                address lastUser = usersWhoHaveBorrow[msg.sender][usersWhoHaveBorrow[msg.sender].length-1];
            BorrowDiscountSnapshot storage lastUserInArr = borrowDiscountSnap[msg.sender][lastUser];
            
            usersWhoHaveBorrow[msg.sender][_dis.index] = usersWhoHaveBorrow[msg.sender][usersWhoHaveBorrow[msg.sender].length-1];
            lastUserInArr.index = _dis.index;
            usersWhoHaveBorrow[msg.sender].length--;
            
            delete borrowDiscountSnap[msg.sender][borrower];
            }
            else{
            usersWhoHaveBorrow[msg.sender].push(borrower);
            _dis.exist = true;
            _dis.index = usersWhoHaveBorrow[msg.sender].length - 1;
            _dis.lastBorrowAmountDiscountGiven = currentBorrowBal;
            _dis.lastUpdated = block.timestamp;
            }
            
        }
        return(currentBorrowBal,market.borrowIndex(),market.totalBorrows());
    }
        
    function changeLastExchangeRateAtSupply(address minter,uint exchangeRate) external {
        
        require(isMarketListed[msg.sender],"Market not listed");
        
        supplyDiscountSnapshot storage _supplyDis = supplyDiscountSnap[msg.sender][minter];
        _supplyDis.lastExchangeRateAtSupply = exchangeRate;
        _supplyDis.lastUpdated = block.timestamp;
        
    }
    
    function changeLastBorrowAmountDiscountGiven(address borrower,uint borrowAmount) external {
        
        require(isMarketListed[msg.sender],"Market not listed");
        
        BorrowDiscountSnapshot storage _borrowDis = borrowDiscountSnap[msg.sender][borrower];
        (_borrowDis.lastBorrowAmountDiscountGiven) = borrowAmount;
        _borrowDis.lastUpdated = block.timestamp;
        
    }
    
    function returnSupplyUserArr(address market) external view returns(address [] memory){
        return usersWhoHaveSupply[market];
    }
    
    function returnBorrowUserArr(address market) external view returns(address [] memory){
        return usersWhoHaveBorrow[market];
    }
}