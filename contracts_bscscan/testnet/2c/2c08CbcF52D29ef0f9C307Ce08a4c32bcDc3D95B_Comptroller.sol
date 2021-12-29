pragma solidity ^0.5.16;

    contract XAIControllerInterface {
        function getXAIAddress() public view returns (address);
        function getMintableXAI(address minter) public view returns (uint, uint);
        function mintXAI(address minter, uint mintXAIAmount) external returns (uint);
        function repayXAI(address repayer, uint repayXAIAmount) external returns (uint);
        function _initializeAnnexXAIState(uint blockNumber) external returns (uint);
        function updateAnnexXAIMintIndex() external returns (uint);
        function calcDistributeXAIMinterAnnex(address xaiMinter) external returns(uint, uint, uint, uint);
    }

    contract ATokenStorage {
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

        uint internal constant borrowRateMaxMantissa = 0.0005e16;

        /**
        * @notice Maximum fraction of interest that can be set aside for reserves
        */
        uint internal constant reserveFactorMaxMantissa = 1e18;

        /**
        * @notice Administrator for this contract
        */
        address payable public admin;

        /**
        * @notice Pending administrator for this contract
        */
        address payable public pendingAdmin;

        /**
        * @notice Contract which oversees inter-aToken operations
        */
        ComptrollerInterface public comptroller;

        /**
        * @notice Model which tells what the current interest rate should be
        */
        InterestRateModel public interestRateModel;

        /**
        * @notice Initial exchange rate used when minting the first ATokens (used when totalSupply = 0)
        */
        uint internal initialExchangeRateMantissa;

        /**
        * @notice Fraction of interest currently set aside for reserves
        */
        uint public reserveFactorMantissa;

        /**
        * @notice Block number that interest was last accrued at
        */
        uint public accrualBlockNumber;

        /**
        * @notice Accumulator of the total earned interest rate since the opening of the market
        */
        uint public borrowIndex;

        /**
        * @notice Total amount of outstanding borrows of the underlying in this market
        */
        uint public totalBorrows;

        /**
        * @notice Total amount of reserves of the underlying held in this market
        */
        uint public totalReserves;

        /**
        * @notice Total number of tokens in circulation
        */
        uint public totalSupply;

        /**
        * @notice Official record of token balances for each account
        */
        mapping (address => uint) internal accountTokens;

        /**
        * @notice Approved token transfer amounts on behalf of others
        */
        mapping (address => mapping (address => uint)) internal transferAllowances;

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
        * @notice Mapping of account addresses to outstanding borrow balances
        */
        mapping(address => BorrowSnapshot) internal accountBorrows;
    }

    contract ATokenInterface is ATokenStorage {
        /**
        * @notice Indicator that this is a AToken contract (for inspection)
        */
        bool public constant isAToken = true;


        /*** Market Events ***/

        /**
        * @notice Event emitted when interest is accrued
        */
        event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

        /**
        * @notice Event emitted when tokens are minted
        */
        event Mint(address minter, uint mintAmount, uint mintTokens);

        /**
        * @notice Event emitted when tokens are redeemed
        */
        event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

        /**
        * @notice Event emitted when tokens are redeemed and fee are transferred
        */
        event RedeemFee(address redeemer, uint feeAmount, uint redeemTokens);

        /**
        * @notice Event emitted when underlying is borrowed
        */
        event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

        /**
        * @notice Event emitted when a borrow is repaid
        */
        event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

        /**
        * @notice Event emitted when a borrow is liquidated
        */
        event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address aTokenCollateral, uint seizeTokens);


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
        * @notice Event emitted when the reserve factor is changed
        */
        event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

        /**
        * @notice Event emitted when the reserves are added
        */
        event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

        /**
        * @notice Event emitted when the reserves are reduced
        */
        event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

        /**
        * @notice EIP20 Transfer event
        */
        event Transfer(address indexed from, address indexed to, uint amount);

        /**
        * @notice EIP20 Approval event
        */
        event Approval(address indexed owner, address indexed spender, uint amount);

        /**
        * @notice Failure event
        */
        event Failure(uint error, uint info, uint detail);


        /*** User Interface ***/

        function transfer(address dst, uint amount) external returns (bool);
        function transferFrom(address src, address dst, uint amount) external returns (bool);
        function approve(address spender, uint amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint);
        function balanceOf(address owner) external view returns (uint);
        function balanceOfUnderlying(address owner) external returns (uint);
        function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
        function borrowRatePerBlock() external view returns (uint);
        function supplyRatePerBlock() external view returns (uint);
        function totalBorrowsCurrent() external returns (uint);
        function borrowBalanceCurrent(address account) external returns (uint);
        function borrowBalanceStored(address account) public view returns (uint);
        function exchangeRateCurrent() public returns (uint);
        function exchangeRateStored() public view returns (uint);
        function getCash() external view returns (uint);
        function accrueInterest() public returns (uint);
        function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);


        /*** Admin Functions ***/

        function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);
        function _acceptAdmin() external returns (uint);
        function _setComptroller(ComptrollerInterface newComptroller) public returns (uint);
        function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
        function _reduceReserves(uint reduceAmount) external returns (uint);
        function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint);
    }

    contract ABep20Storage {
        /**
        * @notice Underlying asset for this AToken
        */
        address public underlying;
    }

    contract ABep20Interface is ABep20Storage {

        /*** User Interface ***/

        function mint(uint mintAmount) external returns (uint);
        function redeem(uint redeemTokens) external returns (uint);
        function redeemUnderlying(uint redeemAmount) external returns (uint);
        function borrow(uint borrowAmount) external returns (uint);
        function repayBorrow(uint repayAmount) external returns (uint);
        function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
        function liquidateBorrow(address borrower, uint repayAmount, ATokenInterface aTokenCollateral) external returns (uint);


        /*** Admin Functions ***/

        function _addReserves(uint addAmount) external returns (uint);
    }

    contract ADelegationStorage {
        /**
        * @notice Implementation address for this contract
        */
        address public implementation;
    }

    contract ADelegatorInterface is ADelegationStorage {
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
        function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public;
    }

    contract ADelegateInterface is ADelegationStorage {
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






    /**
    * @title Careful Math
    * @author Annex
    * @notice Derived from OpenZeppelin's SafeMath library
    *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
    */
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


    /**
    * @title Exponential module for storing fixed-precision decimals
    * @author Compound
    * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
    *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
    *         `Exp({mantissa: 5100000000000000000})`.
    */
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


    /**
    * @title Exponential module for storing fixed-precision decimals
    * @author Annex
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
        function getExp(uint num, uint denom) internal pure returns (MathError, Exp memory) {
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
        function addExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
            (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

            return (error, Exp({mantissa: result}));
        }

        /**
        * @dev Subtracts two exponentials, returning a new exponential.
        */
        function subExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
            (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

            return (error, Exp({mantissa: result}));
        }

        /**
        * @dev Multiply an Exp by a scalar, returning a new Exp.
        */
        function mulScalar(Exp memory a, uint scalar) internal pure returns (MathError, Exp memory) {
            (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
            if (err0 != MathError.NO_ERROR) {
                return (err0, Exp({mantissa: 0}));
            }

            return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
        }

        /**
        * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
        */
        function mulScalarTruncate(Exp memory a, uint scalar) internal pure returns (MathError, uint) {
            (MathError err, Exp memory product) = mulScalar(a, scalar);
            if (err != MathError.NO_ERROR) {
                return (err, 0);
            }

            return (MathError.NO_ERROR, truncate(product));
        }

        /**
        * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
        */
        function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) internal pure returns (MathError, uint) {
            (MathError err, Exp memory product) = mulScalar(a, scalar);
            if (err != MathError.NO_ERROR) {
                return (err, 0);
            }

            return addUInt(truncate(product), addend);
        }

        /**
        * @dev Divide an Exp by a scalar, returning a new Exp.
        */
        function divScalar(Exp memory a, uint scalar) internal pure returns (MathError, Exp memory) {
            (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
            if (err0 != MathError.NO_ERROR) {
                return (err0, Exp({mantissa: 0}));
            }

            return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
        }

        /**
        * @dev Divide a scalar by an Exp, returning a new Exp.
        */
        function divScalarByExp(uint scalar, Exp memory divisor) internal pure returns (MathError, Exp memory) {
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
        function divScalarByExpTruncate(uint scalar, Exp memory divisor) internal pure returns (MathError, uint) {
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
        function mulExp(uint a, uint b) internal pure returns (MathError, Exp memory) {
            return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
        }

        /**
        * @dev Multiplies three exponentials, returning a new exponential.
        */
        function mulExp3(Exp memory a, Exp memory b, Exp memory c) internal pure returns (MathError, Exp memory) {
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





    /**
    * @title Annex's InterestRateModel Interface
    * @author Annex
    */
    contract InterestRateModel {
        /// @notice Indicator that this is an InterestRateModel contract (for inspection)
        bool public constant isInterestRateModel = true;

        /**
        * @notice Calculates the current borrow interest rate per block
        * @param cash The total amount of cash the market has
        * @param borrows The total amount of borrows the market has outstanding
        * @param reserves The total amnount of reserves the market has
        * @return The borrow rate per block (as a percentage, and scaled by 1e18)
        */
        function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

        /**
        * @notice Calculates the current supply interest rate per block
        * @param cash The total amount of cash the market has
        * @param borrows The total amount of borrows the market has outstanding
        * @param reserves The total amnount of reserves the market has
        * @param reserveFactorMantissa The current reserve factor the market has
        * @return The supply rate per block (as a percentage, and scaled by 1e18)
        */
        function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

    }


    contract TokenErrorReporter {
        enum Error {
            NO_ERROR,
            UNAUTHORIZED,
            BAD_INPUT,
            COMPTROLLER_REJECTION,
            COMPTROLLER_CALCULATION_ERROR,
            INTEREST_RATE_MODEL_ERROR,
            INVALID_ACCOUNT_PAIR,
            INVALID_CLOSE_AMOUNT_REQUESTED,
            INVALID_COLLATERAL_FACTOR,
            MATH_ERROR,
            MARKET_NOT_FRESH,
            MARKET_NOT_LISTED,
            TOKEN_INSUFFICIENT_ALLOWANCE,
            TOKEN_INSUFFICIENT_BALANCE,
            TOKEN_INSUFFICIENT_CASH,
            TOKEN_TRANSFER_IN_FAILED,
            TOKEN_TRANSFER_OUT_FAILED,
            TOKEN_PRICE_ERROR
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
            BORROW_CASH_NOT_AVAILABLE,
            BORROW_FRESHNESS_CHECK,
            BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
            BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
            BORROW_MARKET_NOT_LISTED,
            BORROW_COMPTROLLER_REJECTION,
            LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
            LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
            LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
            LIQUIDATE_COMPTROLLER_REJECTION,
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
            MINT_COMPTROLLER_REJECTION,
            MINT_EXCHANGE_CALCULATION_FAILED,
            MINT_EXCHANGE_RATE_READ_FAILED,
            MINT_FRESHNESS_CHECK,
            MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
            MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
            MINT_TRANSFER_IN_FAILED,
            MINT_TRANSFER_IN_NOT_POSSIBLE,
            REDEEM_ACCRUE_INTEREST_FAILED,
            REDEEM_COMPTROLLER_REJECTION,
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
            ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE,
            TOKEN_GET_UNDERLYING_PRICE_ERROR,
            REPAY_XAI_COMPTROLLER_REJECTION,
            REPAY_XAI_FRESHNESS_CHECK,
            XAI_MINT_EXCHANGE_CALCULATION_FAILED,
            SFT_MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
            REDEEM_FEE_CALCULATION_FAILED
        }

        /**
        * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
        * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
        **/
        event Failure(uint error, uint info, uint detail);

        /**
        * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
        */
        function fail(Error err, FailureInfo info) internal returns (uint) {
            emit Failure(uint(err), uint(info), 0);

            return uint(err);
        }

        /**
        * @dev use this when reporting an opaque error from an upgradeable collaborator contract
        */
        function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
            emit Failure(uint(err), uint(info), opaqueError);

            return uint(err);
        }
    }
    /**
    * @title Annex's AToken Contract
    * @notice Abstract base for ATokens
    * @author Annex
    */
    contract AToken is ATokenInterface, Exponential, TokenErrorReporter {
        /**
        * @notice Initialize the money market
        * @param comptroller_ The address of the Comptroller
        * @param interestRateModel_ The address of the interest rate model
        * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
        * @param name_ EIP-20 name of this token
        * @param symbol_ EIP-20 symbol of this token
        * @param decimals_ EIP-20 decimal precision of this token
        */
        function initialize(ComptrollerInterface comptroller_,
                            InterestRateModel interestRateModel_,
                            uint initialExchangeRateMantissa_,
                            string memory name_,
                            string memory symbol_,
                            uint8 decimals_) public {
            require(msg.sender == admin, "only admin may initialize the market");
            require(accrualBlockNumber == 0 && borrowIndex == 0, "market may only be initialized once");

            // Set initial exchange rate
            initialExchangeRateMantissa = initialExchangeRateMantissa_;
            require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

            // Set the comptroller
            uint err = _setComptroller(comptroller_);
            require(err == uint(Error.NO_ERROR), "setting comptroller failed");

            // Initialize block number and borrow index (block number mocks depend on comptroller being set)
            accrualBlockNumber = getBlockNumber();
            borrowIndex = mantissaOne;

            // Set the interest rate model (depends on block number / borrow index)
            err = _setInterestRateModelFresh(interestRateModel_);
            require(err == uint(Error.NO_ERROR), "setting interest rate model failed");

            name = name_;
            symbol = symbol_;
            decimals = decimals_;

            // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
            _notEntered = true;
        }

        /**
        * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
        * @dev Called by both `transfer` and `transferFrom` internally
        * @param spender The address of the account performing the transfer
        * @param src The address of the source account
        * @param dst The address of the destination account
        * @param tokens The number of tokens to transfer
        * @return Whether or not the transfer succeeded
        */
        function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
            /* Fail if transfer not allowed */
            uint allowed = comptroller.transferAllowed(address(this), src, dst, tokens);
            if (allowed != 0) {
                return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.TRANSFER_COMPTROLLER_REJECTION, allowed);
            }

            /* Do not allow self-transfers */
            if (src == dst) {
                return fail(Error.BAD_INPUT, FailureInfo.TRANSFER_NOT_ALLOWED);
            }

            /* Get the allowance, infinite for the account owner */
            uint startingAllowance = 0;
            if (spender == src) {
                startingAllowance = uint(-1);
            } else {
                startingAllowance = transferAllowances[src][spender];
            }

            /* Do the calculations, checking for {under,over}flow */
            MathError mathErr;
            uint allowanceNew;
            uint sraTokensNew;
            uint dstTokensNew;

            (mathErr, allowanceNew) = subUInt(startingAllowance, tokens);
            if (mathErr != MathError.NO_ERROR) {
                return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ALLOWED);
            }

            (mathErr, sraTokensNew) = subUInt(accountTokens[src], tokens);
            if (mathErr != MathError.NO_ERROR) {
                return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ENOUGH);
            }

            (mathErr, dstTokensNew) = addUInt(accountTokens[dst], tokens);
            if (mathErr != MathError.NO_ERROR) {
                return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_TOO_MUCH);
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            accountTokens[src] = sraTokensNew;
            accountTokens[dst] = dstTokensNew;

            /* Eat some of the allowance (if necessary) */
            if (startingAllowance != uint(-1)) {
                transferAllowances[src][spender] = allowanceNew;
            }

            /* We emit a Transfer event */
            emit Transfer(src, dst, tokens);

            comptroller.transferVerify(address(this), src, dst, tokens);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice Transfer `amount` tokens from `msg.sender` to `dst`
        * @param dst The address of the destination account
        * @param amount The number of tokens to transfer
        * @return Whether or not the transfer succeeded
        */
        function transfer(address dst, uint256 amount) external nonReentrant returns (bool) {
            return transferTokens(msg.sender, msg.sender, dst, amount) == uint(Error.NO_ERROR);
        }

        /**
        * @notice Transfer `amount` tokens from `src` to `dst`
        * @param src The address of the source account
        * @param dst The address of the destination account
        * @param amount The number of tokens to transfer
        * @return Whether or not the transfer succeeded
        */
        function transferFrom(address src, address dst, uint256 amount) external nonReentrant returns (bool) {
            return transferTokens(msg.sender, src, dst, amount) == uint(Error.NO_ERROR);
        }

        /**
        * @notice Approve `spender` to transfer up to `amount` from `src`
        * @dev This will overwrite the approval amount for `spender`
        *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
        * @param spender The address of the account which may transfer tokens
        * @param amount The number of tokens that are approved (-1 means infinite)
        * @return Whether or not the approval succeeded
        */
        function approve(address spender, uint256 amount) external returns (bool) {
            address src = msg.sender;
            transferAllowances[src][spender] = amount;
            emit Approval(src, spender, amount);
            return true;
        }

        /**
        * @notice Get the current allowance from `owner` for `spender`
        * @param owner The address of the account which owns the tokens to be spent
        * @param spender The address of the account which may transfer tokens
        * @return The number of tokens allowed to be spent (-1 means infinite)
        */
        function allowance(address owner, address spender) external view returns (uint256) {
            return transferAllowances[owner][spender];
        }

        /**
        * @notice Get the token balance of the `owner`
        * @param owner The address of the account to query
        * @return The number of tokens owned by `owner`
        */
        function balanceOf(address owner) external view returns (uint256) {
            return accountTokens[owner];
        }

        /**
        * @notice Get the underlying balance of the `owner`
        * @dev This also accrues interest in a transaction
        * @param owner The address of the account to query
        * @return The amount of underlying owned by `owner`
        */
        function balanceOfUnderlying(address owner) external returns (uint) {
            Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
            (MathError mErr, uint balance) = mulScalarTruncate(exchangeRate, accountTokens[owner]);
            require(mErr == MathError.NO_ERROR, "balance could not be calculated");
            return balance;
        }

    //cont...
        /**
        * @notice Get a snapshot of the account's balances, and the cached exchange rate
        * @dev This is used by comptroller to more efficiently perform liquidity checks.
        * @param account Address of the account to snapshot
        * @return (possible error, token balance, borrow balance, exchange rate mantissa)
        */
        function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint) {
            uint aTokenBalance = accountTokens[account];
            uint borrowBalance;
            uint exchangeRateMantissa;

            MathError mErr;

            (mErr, borrowBalance) = borrowBalanceStoredInternal(account);
            if (mErr != MathError.NO_ERROR) {
                return (uint(Error.MATH_ERROR), 0, 0, 0);
            }

            (mErr, exchangeRateMantissa) = exchangeRateStoredInternal();
            if (mErr != MathError.NO_ERROR) {
                return (uint(Error.MATH_ERROR), 0, 0, 0);
            }

            return (uint(Error.NO_ERROR), aTokenBalance, borrowBalance, exchangeRateMantissa);
        }

        /**
        * @dev Function to simply retrieve block number
        *  This exists mainly for inheriting test contracts to stub this result.
        */
        function getBlockNumber() internal view returns (uint) {
            return block.number;
        }

        /**
        * @notice Returns the current per-block borrow interest rate for this aToken
        * @return The borrow interest rate per block, scaled by 1e18
        */
        function borrowRatePerBlock() external view returns (uint) {
            return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
        }

        /**
        * @notice Returns the current per-block supply interest rate for this aToken
        * @return The supply interest rate per block, scaled by 1e18
        */
        function supplyRatePerBlock() external view returns (uint) {
            return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
        }

        /**
        * @notice Returns the current total borrows plus accrued interest
        * @return The total borrows with interest
        */
        function totalBorrowsCurrent() external nonReentrant returns (uint) {
            require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
            return totalBorrows;
        }

        /**
        * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
        * @param account The address whose balance should be calculated after updating borrowIndex
        * @return The calculated balance
        */
        function borrowBalanceCurrent(address account) external nonReentrant returns (uint) {
            require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
            return borrowBalanceStored(account);
        }

        /**
        * @notice Return the borrow balance of account based on stored data
        * @param account The address whose balance should be calculated
        * @return The calculated balance
        */
        function borrowBalanceStored(address account) public view returns (uint) {
            (MathError err, uint result) = borrowBalanceStoredInternal(account);
            require(err == MathError.NO_ERROR, "borrowBalanceStored: borrowBalanceStoredInternal failed");
            return result;
        }

        /**
        * @notice Return the borrow balance of account based on stored data
        * @param account The address whose balance should be calculated
        * @return (error code, the calculated balance or 0 if error code is non-zero)
        */
        function borrowBalanceStoredInternal(address account) internal view returns (MathError, uint) {
            /* Note: we do not assert that the market is up to date */
            MathError mathErr;
            uint principalTimesIndex;
            uint result;

            /* Get borrowBalance and borrowIndex */
            BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

            /* If borrowBalance = 0 then borrowIndex is likely also 0.
            * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
            */
            if (borrowSnapshot.principal == 0) {
                return (MathError.NO_ERROR, 0);
            }

            /* Calculate new borrow balance using the interest index:
            *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
            */
            (mathErr, principalTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            (mathErr, result) = divUInt(principalTimesIndex, borrowSnapshot.interestIndex);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            return (MathError.NO_ERROR, result);
        }

        /**
        * @notice Accrue interest then return the up-to-date exchange rate
        * @return Calculated exchange rate scaled by 1e18
        */
        function exchangeRateCurrent() public nonReentrant returns (uint) {
            require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
            return exchangeRateStored();
        }

        /**
        * @notice Calculates the exchange rate from the underlying to the AToken
        * @dev This function does not accrue interest before calculating the exchange rate
        * @return Calculated exchange rate scaled by 1e18
        */
        function exchangeRateStored() public view returns (uint) {
            (MathError err, uint result) = exchangeRateStoredInternal();
            require(err == MathError.NO_ERROR, "exchangeRateStored: exchangeRateStoredInternal failed");
            return result;
        }

        /**
        * @notice Calculates the exchange rate from the underlying to the AToken
        * @dev This function does not accrue interest before calculating the exchange rate
        * @return (error code, calculated exchange rate scaled by 1e18)
        */
        function exchangeRateStoredInternal() internal view returns (MathError, uint) {
            uint _totalSupply = totalSupply;
            if (_totalSupply == 0) {
                /*
                * If there are no tokens minted:
                *  exchangeRate = initialExchangeRate
                */
                return (MathError.NO_ERROR, initialExchangeRateMantissa);
            } else {
                /*
                * Otherwise:
                *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
                */
                uint totalCash = getCashPrior();
                uint cashPlusBorrowsMinusReserves;
                Exp memory exchangeRate;
                MathError mathErr;

                (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
                if (mathErr != MathError.NO_ERROR) {
                    return (mathErr, 0);
                }

                (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
                if (mathErr != MathError.NO_ERROR) {
                    return (mathErr, 0);
                }

                return (MathError.NO_ERROR, exchangeRate.mantissa);
            }
        }

        /**
        * @notice Get cash balance of this aToken in the underlying asset
        * @return The quantity of underlying asset owned by this contract
        */
        function getCash() external view returns (uint) {
            return getCashPrior();
        }

        /**
        * @notice Applies accrued interest to total borrows and reserves
        * @dev This calculates interest accrued from the last checkpointed block
        *   up to the current block and writes new checkpoint to storage.
        */
        function accrueInterest() public returns (uint) {
            /* Remember the initial block number */
            uint currentBlockNumber = getBlockNumber();
            uint accrualBlockNumberPrior = accrualBlockNumber;

            /* Short-circuit accumulating 0 interest */
            if (accrualBlockNumberPrior == currentBlockNumber) {
                return uint(Error.NO_ERROR);
            }

            /* Read the previous values out of storage */
            uint cashPrior = getCashPrior();
            uint borrowsPrior = totalBorrows;
            uint reservesPrior = totalReserves;
            uint borrowIndexPrior = borrowIndex;

            /* Calculate the current borrow interest rate */
            uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
            require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

            /* Calculate the number of blocks elapsed since the last accrual */
            (MathError mathErr, uint blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
            require(mathErr == MathError.NO_ERROR, "could not calculate block delta");

            /*
            * Calculate the interest accumulated into borrows and reserves and the new index:
            *  simpleInterestFactor = borrowRate * blockDelta
            *  interestAccumulated = simpleInterestFactor * totalBorrows
            *  totalBorrowsNew = interestAccumulated + totalBorrows
            *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
            *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
            */

            Exp memory simpleInterestFactor;
            uint interestAccumulated;
            uint totalBorrowsNew;
            uint totalReservesNew;
            uint borrowIndexNew;

            (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa: borrowRateMantissa}), blockDelta);
            if (mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED, uint(mathErr));
            }

            (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
            if (mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED, uint(mathErr));
            }

            (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
            if (mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED, uint(mathErr));
            }

            (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
            if (mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED, uint(mathErr));
            }

            (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
            if (mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED, uint(mathErr));
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            /* We write the previously calculated values into storage */
            accrualBlockNumber = currentBlockNumber;
            borrowIndex = borrowIndexNew;
            totalBorrows = totalBorrowsNew;
            totalReserves = totalReservesNew;

            /* We emit an AccrueInterest event */
            emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice Sender supplies assets into the market and receives aTokens in exchange
        * @dev Accrues interest whether or not the operation succeeds, unless reverted
        * @param mintAmount The amount of the underlying asset to supply
        * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
        */
        function mintInternal(uint mintAmount) internal nonReentrant returns (uint, uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
                return (fail(Error(error), FailureInfo.MINT_ACCRUE_INTEREST_FAILED), 0);
            }
            // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
            return mintFresh(msg.sender, mintAmount);
        }

        struct MintLocalVars {
            Error err;
            MathError mathErr;
            uint exchangeRateMantissa;
            uint mintTokens;
            uint totalSupplyNew;
            uint accountTokensNew;
            uint actualMintAmount;
        }

        /**
        * @notice User supplies assets into the market and receives aTokens in exchange
        * @dev Assumes interest has already been accrued up to the current block
        * @param minter The address of the account which is supplying the assets
        * @param mintAmount The amount of the underlying asset to supply
        * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
        */
        function mintFresh(address minter, uint mintAmount) internal returns (uint, uint) {
            /* Fail if mint not allowed */
            uint allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
            if (allowed != 0) {
                return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.MINT_COMPTROLLER_REJECTION, allowed), 0);
            }

            /* Verify market's block number equals current block number */
            if (accrualBlockNumber != getBlockNumber()) {
                return (fail(Error.MARKET_NOT_FRESH, FailureInfo.MINT_FRESHNESS_CHECK), 0);
            }

            MintLocalVars memory vars;

            (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
            if (vars.mathErr != MathError.NO_ERROR) {
                return (failOpaque(Error.MATH_ERROR, FailureInfo.MINT_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr)), 0);
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            /*
            *  We call `doTransferIn` for the minter and the mintAmount.
            *  Note: The aToken must handle variations between BEP-20 and BNB underlying.
            *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
            *  side-effects occurred. The function returns the amount actually transferred,
            *  in case of a fee. On success, the aToken holds an additional `actualMintAmount`
            *  of cash.
            */
            vars.actualMintAmount = doTransferIn(minter, mintAmount);

            /*
            * We get the current exchange rate and calculate the number of aTokens to be minted:
            *  mintTokens = actualMintAmount / exchangeRate
            */

            (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(vars.actualMintAmount, Exp({mantissa: vars.exchangeRateMantissa}));
            require(vars.mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_CALCULATION_FAILED");

            /*
            * We calculate the new total supply of aTokens and minter token balance, checking for overflow:
            *  totalSupplyNew = totalSupply + mintTokens
            *  accountTokensNew = accountTokens[minter] + mintTokens
            */
            (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
            require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");

            (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[minter], vars.mintTokens);
            require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");

            /* We write previously calculated values into storage */
            totalSupply = vars.totalSupplyNew;
            accountTokens[minter] = vars.accountTokensNew;

            /* We emit a Mint event, and a Transfer event */
            emit Mint(minter, vars.actualMintAmount, vars.mintTokens);
            emit Transfer(address(this), minter, vars.mintTokens);

            /* We call the defense hook */
            comptroller.mintVerify(address(this), minter, vars.actualMintAmount, vars.mintTokens);

            return (uint(Error.NO_ERROR), vars.actualMintAmount);
        }

        /**
        * @notice Sender redeems aTokens in exchange for the underlying asset
        * @dev Accrues interest whether or not the operation succeeds, unless reverted
        * @param redeemTokens The number of aTokens to redeem into underlying
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function redeemInternal(uint redeemTokens) internal nonReentrant returns (uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
                return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
            }
            // redeemFresh emits redeem-specific logs on errors, so we don't need to
            return redeemFresh(msg.sender, redeemTokens, 0);
        }

        /**
        * @notice Sender redeems aTokens in exchange for a specified amount of underlying asset
        * @dev Accrues interest whether or not the operation succeeds, unless reverted
        * @param redeemAmount The amount of underlying to receive from redeeming aTokens
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function redeemUnderlyingInternal(uint redeemAmount) internal nonReentrant returns (uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
                return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
            }
            // redeemFresh emits redeem-specific logs on errors, so we don't need to
            return redeemFresh(msg.sender, 0, redeemAmount);
        }

        struct RedeemLocalVars {
            Error err;
            MathError mathErr;
            uint exchangeRateMantissa;
            uint redeemTokens;
            uint redeemAmount;
            uint totalSupplyNew;
            uint accountTokensNew;
        }

        /**
        * @notice User redeems aTokens in exchange for the underlying asset
        * @dev Assumes interest has already been accrued up to the current block
        * @param redeemer The address of the account which is redeeming the tokens
        * @param redeemTokensIn The number of aTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
        * @param redeemAmountIn The number of underlying tokens to receive from redeeming aTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function redeemFresh(address payable redeemer, uint redeemTokensIn, uint redeemAmountIn) internal returns (uint) {
            require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

            RedeemLocalVars memory vars;

            /* exchangeRate = invoke Exchange Rate Stored() */
            (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr));
            }

            /* If redeemTokensIn > 0: */
            if (redeemTokensIn > 0) {
                /*
                * We calculate the exchange rate and the amount of underlying to be redeemed:
                *  redeemTokens = redeemTokensIn
                *  redeemAmount = redeemTokensIn x exchangeRateCurrent
                */
                vars.redeemTokens = redeemTokensIn;

                (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), redeemTokensIn);
                if (vars.mathErr != MathError.NO_ERROR) {
                    return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint(vars.mathErr));
                }
            } else {
                /*
                * We get the current exchange rate and calculate the amount to be redeemed:
                *  redeemTokens = redeemAmountIn / exchangeRate
                *  redeemAmount = redeemAmountIn
                */

                (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(redeemAmountIn, Exp({mantissa: vars.exchangeRateMantissa}));
                if (vars.mathErr != MathError.NO_ERROR) {
                    return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED, uint(vars.mathErr));
                }

                vars.redeemAmount = redeemAmountIn;
            }

            /* Fail if redeem not allowed */
            uint allowed = comptroller.redeemAllowed(address(this), redeemer, vars.redeemTokens);
            if (allowed != 0) {
                return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.REDEEM_COMPTROLLER_REJECTION, allowed);
            }

            /* Verify market's block number equals current block number */
            if (accrualBlockNumber != getBlockNumber()) {
                return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDEEM_FRESHNESS_CHECK);
            }

            /*
            * We calculate the new total supply and redeemer balance, checking for underflow:
            *  totalSupplyNew = totalSupply - redeemTokens
            *  accountTokensNew = accountTokens[redeemer] - redeemTokens
            */
            (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply, vars.redeemTokens);
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint(vars.mathErr));
            }

            (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[redeemer], vars.redeemTokens);
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
            }

            /* Fail gracefully if protocol has insufficient cash */
            if (getCashPrior() < vars.redeemAmount) {
                return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            /*
            * We invoke doTransferOut for the redeemer and the redeemAmount.
            *  Note: The aToken must handle variations between BEP-20 and BNB underlying.
            *  On success, the aToken has redeemAmount less of cash.
            *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
            */

            uint feeAmount;
            uint remainedAmount;
            if (IComptroller(address(comptroller)).treasuryPercent() != 0) {
                (vars.mathErr, feeAmount) = mulUInt(vars.redeemAmount, IComptroller(address(comptroller)).treasuryPercent());
                if (vars.mathErr != MathError.NO_ERROR) {
                    return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_FEE_CALCULATION_FAILED, uint(vars.mathErr));
                }

                (vars.mathErr, feeAmount) = divUInt(feeAmount, 1e18);
                if (vars.mathErr != MathError.NO_ERROR) {
                    return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_FEE_CALCULATION_FAILED, uint(vars.mathErr));
                }

                (vars.mathErr, remainedAmount) = subUInt(vars.redeemAmount, feeAmount);
                if (vars.mathErr != MathError.NO_ERROR) {
                    return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_FEE_CALCULATION_FAILED, uint(vars.mathErr));
                }

                doTransferOut(address(uint160(IComptroller(address(comptroller)).treasuryAddress())), feeAmount);

                emit RedeemFee(redeemer, feeAmount, vars.redeemTokens);
            } else {
                remainedAmount = vars.redeemAmount;
            }

            doTransferOut(redeemer, remainedAmount);

            /* We write previously calculated values into storage */
            totalSupply = vars.totalSupplyNew;
            accountTokens[redeemer] = vars.accountTokensNew;

            /* We emit a Transfer event, and a Redeem event */
            emit Transfer(redeemer, address(this), vars.redeemTokens);
            emit Redeem(redeemer, remainedAmount, vars.redeemTokens);

            /* We call the defense hook */
            comptroller.redeemVerify(address(this), redeemer, vars.redeemAmount, vars.redeemTokens);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice Sender borrows assets from the protocol to their own address
        * @param borrowAmount The amount of the underlying asset to borrow
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function borrowInternal(uint borrowAmount) internal nonReentrant returns (uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
                return fail(Error(error), FailureInfo.BORROW_ACCRUE_INTEREST_FAILED);
            }
            // borrowFresh emits borrow-specific logs on errors, so we don't need to
            return borrowFresh(msg.sender, borrowAmount);
        }

        struct BorrowLocalVars {
            MathError mathErr;
            uint accountBorrows;
            uint accountBorrowsNew;
            uint totalBorrowsNew;
        }

        /**
        * @notice Users borrow assets from the protocol to their own address
        * @param borrowAmount The amount of the underlying asset to borrow
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function borrowFresh(address payable borrower, uint borrowAmount) internal returns (uint) {
            /* Fail if borrow not allowed */
            uint allowed = comptroller.borrowAllowed(address(this), borrower, borrowAmount);
            if (allowed != 0) {
                return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.BORROW_COMPTROLLER_REJECTION, allowed);
            }

            /* Verify market's block number equals current block number */
            if (accrualBlockNumber != getBlockNumber()) {
                return fail(Error.MARKET_NOT_FRESH, FailureInfo.BORROW_FRESHNESS_CHECK);
            }

            /* Fail gracefully if protocol has insufficient underlying cash */
            if (getCashPrior() < borrowAmount) {
                return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.BORROW_CASH_NOT_AVAILABLE);
            }

            BorrowLocalVars memory vars;

            /*
            * We calculate the new borrower and total borrow balances, failing on overflow:
            *  accountBorrowsNew = accountBorrows + borrowAmount
            *  totalBorrowsNew = totalBorrows + borrowAmount
            */
            (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
            }

            (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, borrowAmount);
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
            }

            (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows, borrowAmount);
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            /*
            * We invoke doTransferOut for the borrower and the borrowAmount.
            *  Note: The aToken must handle variations between BEP-20 and BNB underlying.
            *  On success, the aToken borrowAmount less of cash.
            *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
            */
            doTransferOut(borrower, borrowAmount);

            /* We write the previously calculated values into storage */
            accountBorrows[borrower].principal = vars.accountBorrowsNew;
            accountBorrows[borrower].interestIndex = borrowIndex;
            totalBorrows = vars.totalBorrowsNew;

            /* We emit a Borrow event */
            emit Borrow(borrower, borrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

            /* We call the defense hook */
            comptroller.borrowVerify(address(this), borrower, borrowAmount);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice Sender repays their own borrow
        * @param repayAmount The amount to repay
        * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
        */
        function repayBorrowInternal(uint repayAmount) internal nonReentrant returns (uint, uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
                return (fail(Error(error), FailureInfo.REPAY_BORROW_ACCRUE_INTEREST_FAILED), 0);
            }
            // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
            return repayBorrowFresh(msg.sender, msg.sender, repayAmount);
        }

        /**
        * @notice Sender repays a borrow belonging to borrower
        * @param borrower the account with the debt being payed off
        * @param repayAmount The amount to repay
        * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
        */
        function repayBorrowBehalfInternal(address borrower, uint repayAmount) internal nonReentrant returns (uint, uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
                return (fail(Error(error), FailureInfo.REPAY_BEHALF_ACCRUE_INTEREST_FAILED), 0);
            }
            // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
            return repayBorrowFresh(msg.sender, borrower, repayAmount);
        }

        struct RepayBorrowLocalVars {
            Error err;
            MathError mathErr;
            uint repayAmount;
            uint borrowerIndex;
            uint accountBorrows;
            uint accountBorrowsNew;
            uint totalBorrowsNew;
            uint actualRepayAmount;
        }

        /**
        * @notice Borrows are repaid by another user (possibly the borrower).
        * @param payer the account paying off the borrow
        * @param borrower the account with the debt being payed off
        * @param repayAmount the amount of undelrying tokens being returned
        * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
        */
        function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint, uint) {
            /* Fail if repayBorrow not allowed */
            uint allowed = comptroller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
            if (allowed != 0) {
                return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.REPAY_BORROW_COMPTROLLER_REJECTION, allowed), 0);
            }

            /* Verify market's block number equals current block number */
            if (accrualBlockNumber != getBlockNumber()) {
                return (fail(Error.MARKET_NOT_FRESH, FailureInfo.REPAY_BORROW_FRESHNESS_CHECK), 0);
            }

            RepayBorrowLocalVars memory vars;

            /* We remember the original borrowerIndex for verification purposes */
            vars.borrowerIndex = accountBorrows[borrower].interestIndex;

            /* We fetch the amount the borrower owes, with accumulated interest */
            (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
            if (vars.mathErr != MathError.NO_ERROR) {
                return (failOpaque(Error.MATH_ERROR, FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
            }

            /* If repayAmount == -1, repayAmount = accountBorrows */
            if (repayAmount == uint(-1)) {
                vars.repayAmount = vars.accountBorrows;
            } else {
                vars.repayAmount = repayAmount;
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            /*
            * We call doTransferIn for the payer and the repayAmount
            *  Note: The aToken must handle variations between BEP-20 and BNB underlying.
            *  On success, the aToken holds an additional repayAmount of cash.
            *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
            *   it returns the amount actually transferred, in case of a fee.
            */
            vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);

            /*
            * We calculate the new borrower and total borrow balances, failing on underflow:
            *  accountBorrowsNew = accountBorrows - actualRepayAmount
            *  totalBorrowsNew = totalBorrows - actualRepayAmount
            */
            (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, vars.actualRepayAmount);
            require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED");

            (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, vars.actualRepayAmount);
            require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED");

            /* We write the previously calculated values into storage */
            accountBorrows[borrower].principal = vars.accountBorrowsNew;
            accountBorrows[borrower].interestIndex = borrowIndex;
            totalBorrows = vars.totalBorrowsNew;

            /* We emit a RepayBorrow event */
            emit RepayBorrow(payer, borrower, vars.actualRepayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

            /* We call the defense hook */
            comptroller.repayBorrowVerify(address(this), payer, borrower, vars.actualRepayAmount, vars.borrowerIndex);

            return (uint(Error.NO_ERROR), vars.actualRepayAmount);
        }

        /**
        * @notice The sender liquidates the borrowers collateral.
        *  The collateral seized is transferred to the liquidator.
        * @param borrower The borrower of this aToken to be liquidated
        * @param aTokenCollateral The market in which to seize collateral from the borrower
        * @param repayAmount The amount of the underlying borrowed asset to repay
        * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
        */
        function liquidateBorrowInternal(address borrower, uint repayAmount, ATokenInterface aTokenCollateral) internal nonReentrant returns (uint, uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
                return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED), 0);
            }

            error = aTokenCollateral.accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
                return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED), 0);
            }

            // liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
            return liquidateBorrowFresh(msg.sender, borrower, repayAmount, aTokenCollateral);
        }

        /**
        * @notice The liquidator liquidates the borrowers collateral.
        *  The collateral seized is transferred to the liquidator.
        * @param borrower The borrower of this aToken to be liquidated
        * @param liquidator The address repaying the borrow and seizing collateral
        * @param aTokenCollateral The market in which to seize collateral from the borrower
        * @param repayAmount The amount of the underlying borrowed asset to repay
        * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
        */
        function liquidateBorrowFresh(address liquidator, address borrower, uint repayAmount, ATokenInterface aTokenCollateral) internal returns (uint, uint) {
            /* Fail if liquidate not allowed */
            uint allowed = comptroller.liquidateBorrowAllowed(address(this), address(aTokenCollateral), liquidator, borrower, repayAmount);
            if (allowed != 0) {
                return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.LIQUIDATE_COMPTROLLER_REJECTION, allowed), 0);
            }

            /* Verify market's block number equals current block number */
            if (accrualBlockNumber != getBlockNumber()) {
                return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_FRESHNESS_CHECK), 0);
            }

            /* Verify aTokenCollateral market's block number equals current block number */
            if (aTokenCollateral.accrualBlockNumber() != getBlockNumber()) {
                return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_COLLATERAL_FRESHNESS_CHECK), 0);
            }

            /* Fail if borrower = liquidator */
            if (borrower == liquidator) {
                return (fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER), 0);
            }

            /* Fail if repayAmount = 0 */
            if (repayAmount == 0) {
                return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_ZERO), 0);
            }

            /* Fail if repayAmount = -1 */
            if (repayAmount == uint(-1)) {
                return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX), 0);
            }


            /* Fail if repayBorrow fails */
            (uint repayBorrowError, uint actualRepayAmount) = repayBorrowFresh(liquidator, borrower, repayAmount);
            if (repayBorrowError != uint(Error.NO_ERROR)) {
                return (fail(Error(repayBorrowError), FailureInfo.LIQUIDATE_REPAY_BORROW_FRESH_FAILED), 0);
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            /* We calculate the number of collateral tokens that will be seized */
            (uint amountSeizeError, uint seizeTokens) = comptroller.liquidateCalculateSeizeTokens(address(this), address(aTokenCollateral), actualRepayAmount);
            require(amountSeizeError == uint(Error.NO_ERROR), "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

            /* Revert if borrower collateral token balance < seizeTokens */
            require(aTokenCollateral.balanceOf(borrower) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");

            // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
            uint seizeError;
            if (address(aTokenCollateral) == address(this)) {
                seizeError = seizeInternal(address(this), liquidator, borrower, seizeTokens);
            } else {
                seizeError = aTokenCollateral.seize(liquidator, borrower, seizeTokens);
            }

            /* Revert if seize tokens fails (since we cannot be sure of side effects) */
            require(seizeError == uint(Error.NO_ERROR), "token seizure failed");

            /* We emit a LiquidateBorrow event */
            emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(aTokenCollateral), seizeTokens);

            /* We call the defense hook */
            comptroller.liquidateBorrowVerify(address(this), address(aTokenCollateral), liquidator, borrower, actualRepayAmount, seizeTokens);

            return (uint(Error.NO_ERROR), actualRepayAmount);
        }

        /**
        * @notice Transfers collateral tokens (this market) to the liquidator.
        * @dev Will fail unless called by another aToken during the process of liquidation.
        *  Its absolutely critical to use msg.sender as the borrowed aToken and not a parameter.
        * @param liquidator The account receiving seized collateral
        * @param borrower The account having collateral seized
        * @param seizeTokens The number of aTokens to seize
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function seize(address liquidator, address borrower, uint seizeTokens) external nonReentrant returns (uint) {
            return seizeInternal(msg.sender, liquidator, borrower, seizeTokens);
        }

        /**
        * @notice Transfers collateral tokens (this market) to the liquidator.
        * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another AToken.
        *  Its absolutely critical to use msg.sender as the seizer aToken and not a parameter.
        * @param seizerToken The contract seizing the collateral (i.e. borrowed aToken)
        * @param liquidator The account receiving seized collateral
        * @param borrower The account having collateral seized
        * @param seizeTokens The number of aTokens to seize
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function seizeInternal(address seizerToken, address liquidator, address borrower, uint seizeTokens) internal returns (uint) {
            /* Fail if seize not allowed */
            uint allowed = comptroller.seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);
            if (allowed != 0) {
                return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.LIQUIDATE_SEIZE_COMPTROLLER_REJECTION, allowed);
            }

            /* Fail if borrower = liquidator */
            if (borrower == liquidator) {
                return fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER);
            }

            MathError mathErr;
            uint borrowerTokensNew;
            uint liquidatorTokensNew;

            /*
            * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
            *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
            *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
            */
            (mathErr, borrowerTokensNew) = subUInt(accountTokens[borrower], seizeTokens);
            if (mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED, uint(mathErr));
            }

            (mathErr, liquidatorTokensNew) = addUInt(accountTokens[liquidator], seizeTokens);
            if (mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED, uint(mathErr));
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            /* We write the previously calculated values into storage */
            accountTokens[borrower] = borrowerTokensNew;
            accountTokens[liquidator] = liquidatorTokensNew;

            /* Emit a Transfer event */
            emit Transfer(borrower, liquidator, seizeTokens);

            /* We call the defense hook */
            comptroller.seizeVerify(address(this), seizerToken, liquidator, borrower, seizeTokens);

            return uint(Error.NO_ERROR);
        }


        /*** Admin Functions ***/

        /**
        * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
        * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
        * @param newPendingAdmin New pending admin.
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _setPendingAdmin(address payable newPendingAdmin) external returns (uint) {
            // Check caller = admin
            if (msg.sender != admin) {
                return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
            }

            // Save current value, if any, for inclusion in log
            address oldPendingAdmin = pendingAdmin;

            // Store pendingAdmin with value newPendingAdmin
            pendingAdmin = newPendingAdmin;

            // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
            emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
        * @dev Admin function for pending admin to accept role and update admin
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _acceptAdmin() external returns (uint) {
            // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
            if (msg.sender != pendingAdmin || msg.sender == address(0)) {
                return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
            }

            // Save current values for inclusion in log
            address oldAdmin = admin;
            address oldPendingAdmin = pendingAdmin;

            // Store admin with value pendingAdmin
            admin = pendingAdmin;

            // Clear the pending value
            pendingAdmin = address(0);

            emit NewAdmin(oldAdmin, admin);
            emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice Sets a new comptroller for the market
        * @dev Admin function to set a new comptroller
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _setComptroller(ComptrollerInterface newComptroller) public returns (uint) {
            // Check caller is admin
            if (msg.sender != admin) {
                return fail(Error.UNAUTHORIZED, FailureInfo.SET_COMPTROLLER_OWNER_CHECK);
            }

            ComptrollerInterface oldComptroller = comptroller;
            // Ensure invoke comptroller.isComptroller() returns true
            require(newComptroller.isComptroller(), "marker method returned false");

            // Set market's comptroller to newComptroller
            comptroller = newComptroller;

            // Emit NewComptroller(oldComptroller, newComptroller)
            emit NewComptroller(oldComptroller, newComptroller);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
        * @dev Admin function to accrue interest and set a new reserve factor
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _setReserveFactor(uint newReserveFactorMantissa) external nonReentrant returns (uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reserve factor change failed.
                return fail(Error(error), FailureInfo.SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED);
            }
            // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
            return _setReserveFactorFresh(newReserveFactorMantissa);
        }

        /**
        * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
        * @dev Admin function to set a new reserve factor
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _setReserveFactorFresh(uint newReserveFactorMantissa) internal returns (uint) {
            // Check caller is admin
            if (msg.sender != admin) {
                return fail(Error.UNAUTHORIZED, FailureInfo.SET_RESERVE_FACTOR_ADMIN_CHECK);
            }

            // Verify market's block number equals current block number
            if (accrualBlockNumber != getBlockNumber()) {
                return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_RESERVE_FACTOR_FRESH_CHECK);
            }

            // Check newReserveFactor ≤ maxReserveFactor
            if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_RESERVE_FACTOR_BOUNDS_CHECK);
            }

            uint oldReserveFactorMantissa = reserveFactorMantissa;
            reserveFactorMantissa = newReserveFactorMantissa;

            emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice Accrues interest and reduces reserves by transferring from msg.sender
        * @param addAmount Amount of addition to reserves
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _addReservesInternal(uint addAmount) internal nonReentrant returns (uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
                return fail(Error(error), FailureInfo.ADD_RESERVES_ACCRUE_INTEREST_FAILED);
            }

            // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
            (error, ) = _addReservesFresh(addAmount);
            return error;
        }

        /**
        * @notice Add reserves by transferring from caller
        * @dev Requires fresh interest accrual
        * @param addAmount Amount of addition to reserves
        * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
        */
        function _addReservesFresh(uint addAmount) internal returns (uint, uint) {
            // totalReserves + actualAddAmount
            uint totalReservesNew;
            uint actualAddAmount;

            // We fail gracefully unless market's block number equals current block number
            if (accrualBlockNumber != getBlockNumber()) {
                return (fail(Error.MARKET_NOT_FRESH, FailureInfo.ADD_RESERVES_FRESH_CHECK), actualAddAmount);
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            /*
            * We call doTransferIn for the caller and the addAmount
            *  Note: The aToken must handle variations between BEP-20 and BNB underlying.
            *  On success, the aToken holds an additional addAmount of cash.
            *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
            *  it returns the amount actually transferred, in case of a fee.
            */

            actualAddAmount = doTransferIn(msg.sender, addAmount);

            totalReservesNew = totalReserves + actualAddAmount;

            /* Revert on overflow */
            require(totalReservesNew >= totalReserves, "add reserves unexpected overflow");

            // Store reserves[n+1] = reserves[n] + actualAddAmount
            totalReserves = totalReservesNew;

            /* Emit NewReserves(admin, actualAddAmount, reserves[n+1]) */
            emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

            /* Return (NO_ERROR, actualAddAmount) */
            return (uint(Error.NO_ERROR), actualAddAmount);
        }


        /**
        * @notice Accrues interest and reduces reserves by transferring to admin
        * @param reduceAmount Amount of reduction to reserves
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _reduceReserves(uint reduceAmount) external nonReentrant returns (uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
                return fail(Error(error), FailureInfo.REDUCE_RESERVES_ACCRUE_INTEREST_FAILED);
            }
            // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
            return _reduceReservesFresh(reduceAmount);
        }

        /**
        * @notice Reduces reserves by transferring to admin
        * @dev Requires fresh interest accrual
        * @param reduceAmount Amount of reduction to reserves
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _reduceReservesFresh(uint reduceAmount) internal returns (uint) {
            // totalReserves - reduceAmount
            uint totalReservesNew;

            // Check caller is admin
            if (msg.sender != admin) {
                return fail(Error.UNAUTHORIZED, FailureInfo.REDUCE_RESERVES_ADMIN_CHECK);
            }

            // We fail gracefully unless market's block number equals current block number
            if (accrualBlockNumber != getBlockNumber()) {
                return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDUCE_RESERVES_FRESH_CHECK);
            }

            // Fail gracefully if protocol has insufficient underlying cash
            if (getCashPrior() < reduceAmount) {
                return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDUCE_RESERVES_CASH_NOT_AVAILABLE);
            }

            // Check reduceAmount ≤ reserves[n] (totalReserves)
            if (reduceAmount > totalReserves) {
                return fail(Error.BAD_INPUT, FailureInfo.REDUCE_RESERVES_VALIDATION);
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            totalReservesNew = totalReserves - reduceAmount;
            // We checked reduceAmount <= totalReserves above, so this should never revert.
            require(totalReservesNew <= totalReserves, "reduce reserves unexpected underflow");

            // Store reserves[n+1] = reserves[n] - reduceAmount
            totalReserves = totalReservesNew;

            // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
            doTransferOut(admin, reduceAmount);

            emit ReservesReduced(admin, reduceAmount, totalReservesNew);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
        * @dev Admin function to accrue interest and update the interest rate model
        * @param newInterestRateModel the new interest rate model to use
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint) {
            uint error = accrueInterest();
            if (error != uint(Error.NO_ERROR)) {
                // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted change of interest rate model failed
                return fail(Error(error), FailureInfo.SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED);
            }
            // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
            return _setInterestRateModelFresh(newInterestRateModel);
        }

        /**
        * @notice updates the interest rate model (*requires fresh interest accrual)
        * @dev Admin function to update the interest rate model
        * @param newInterestRateModel the new interest rate model to use
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint) {

            // Used to store old model for use in the event that is emitted on success
            InterestRateModel oldInterestRateModel;

            // Check caller is admin
            if (msg.sender != admin) {
                return fail(Error.UNAUTHORIZED, FailureInfo.SET_INTEREST_RATE_MODEL_OWNER_CHECK);
            }

            // We fail gracefully unless market's block number equals current block number
            if (accrualBlockNumber != getBlockNumber()) {
                return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_INTEREST_RATE_MODEL_FRESH_CHECK);
            }

            // Track the market's current interest rate model
            oldInterestRateModel = interestRateModel;

            // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
            require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

            // Set the interest rate model to newInterestRateModel
            interestRateModel = newInterestRateModel;

            // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
            emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

            return uint(Error.NO_ERROR);
        }

        /*** Safe Token ***/

        /**
        * @notice Gets balance of this contract in terms of the underlying
        * @dev This excludes the value of the current message, if any
        * @return The quantity of underlying owned by this contract
        */
        function getCashPrior() internal view returns (uint);

        /**
        * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
        *  This may revert due to insufficient balance or insufficient allowance.
        */
        function doTransferIn(address from, uint amount) internal returns (uint);

        /**
        * @dev Performs a transfer out, ideally returning an explanatory error code upon failure tather than reverting.
        *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
        *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
        */
        function doTransferOut(address payable to, uint amount) internal;


        /*** Reentrancy Guard ***/

        /**
        * @dev Prevents a contract from calling itself, directly or indirectly.
        */
        modifier nonReentrant() {
            require(_notEntered, "re-entered");
            _notEntered = false;
            _;
            _notEntered = true; // get a gas-refund post-Istanbul
        }
    }



    contract ComptrollerErrorReporter {
        enum Error {
            NO_ERROR,
            UNAUTHORIZED,
            COMPTROLLER_MISMATCH,
            INSUFFICIENT_SHORTFALL,
            INSUFFICIENT_LIQUIDITY,
            INVALID_CLOSE_FACTOR,
            INVALID_COLLATERAL_FACTOR,
            INVALID_LIQUIDATION_INCENTIVE,
            MARKET_NOT_ENTERED, // no longer possible
            MARKET_NOT_LISTED,
            MARKET_ALREADY_LISTED,
            MATH_ERROR,
            NONZERO_BORROW_BALANCE,
            PRICE_ERROR,
            REJECTION,
            SNAPSHOT_ERROR,
            TOO_MANY_ASSETS,
            TOO_MUCH_REPAY,
            INSUFFICIENT_BALANCE_FOR_XAI
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
            SUPPORT_MARKET_EXISTS,
            SUPPORT_MARKET_OWNER_CHECK,
            SET_PAUSE_GUARDIAN_OWNER_CHECK,
            SET_XAI_MINT_RATE_CHECK,
            SET_XAICONTROLLER_OWNER_CHECK,
            SET_MINTED_XAI_REJECTION,
            SET_TREASURY_OWNER_CHECK
        }

        /**
        * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
        * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
        **/
        event Failure(uint error, uint info, uint detail);

        /**
        * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
        */
        function fail(Error err, FailureInfo info) internal returns (uint) {
            emit Failure(uint(err), uint(info), 0);

            return uint(err);
        }

        /**
        * @dev use this when reporting an opaque error from an upgradeable collaborator contract
        */
        function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
            emit Failure(uint(err), uint(info), opaqueError);

            return uint(err);
        }
    }


    contract XAIControllerErrorReporter {
        enum Error {
            NO_ERROR,
            UNAUTHORIZED,
            REJECTION,
            SNAPSHOT_ERROR,
            PRICE_ERROR,
            MATH_ERROR,
            INSUFFICIENT_BALANCE_FOR_XAI
        }

        enum FailureInfo {
            SET_PENDING_ADMIN_OWNER_CHECK,
            SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
            SET_COMPTROLLER_OWNER_CHECK,
            ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
            ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
            XAI_MINT_REJECTION,
            XAI_BURN_REJECTION,
            XAI_LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
            XAI_LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
            XAI_LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
            XAI_LIQUIDATE_COMPTROLLER_REJECTION,
            XAI_LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
            XAI_LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
            XAI_LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
            XAI_LIQUIDATE_FRESHNESS_CHECK,
            XAI_LIQUIDATE_LIQUIDATOR_IS_BORROWER,
            XAI_LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
            XAI_LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
            XAI_LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
            XAI_LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
            XAI_LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
            XAI_LIQUIDATE_SEIZE_TOO_MUCH,
            MINT_FEE_CALCULATION_FAILED,
            SET_TREASURY_OWNER_CHECK
        }

        /**
        * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
        * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
        **/
        event Failure(uint error, uint info, uint detail);

        /**
        * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
        */
        function fail(Error err, FailureInfo info) internal returns (uint) {
            emit Failure(uint(err), uint(info), 0);

            return uint(err);
        }

        /**
        * @dev use this when reporting an opaque error from an upgradeable collaborator contract
        */
        function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
            emit Failure(uint(err), uint(info), opaqueError);

            return uint(err);
        }
    }




    contract PriceOracle {
        /// @notice Indicator that this is a PriceOracle contract (for inspection)
        bool public constant isPriceOracle = true;

        /**
        * @notice Get the underlying price of a aToken asset
        * @param aToken The aToken to get the underlying price of
        * @return The underlying asset price mantissa (scaled by 1e18).
        *  Zero means the price is unavailable.
        */
        function getUnderlyingPrice(AToken aToken) external view returns (uint);
    }



    contract ComptrollerInterfaceG1 {
        /// @notice Indicator that this is a Comptroller contract (for inspection)
        bool public constant isComptroller = true;

        /*** Assets You Are In ***/

        function enterMarkets(address[] calldata aTokens) external returns (uint[] memory);
        function exitMarket(address aToken) external returns (uint);

        /*** Policy Hooks ***/

        function mintAllowed(address aToken, address minter, uint mintAmount) external returns (uint);
        function mintVerify(address aToken, address minter, uint mintAmount, uint mintTokens) external;

        function redeemAllowed(address aToken, address redeemer, uint redeemTokens) external returns (uint);
        function redeemVerify(address aToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

        function borrowAllowed(address aToken, address borrower, uint borrowAmount) external returns (uint);
        function borrowVerify(address aToken, address borrower, uint borrowAmount) external;

        function repayBorrowAllowed(
            address aToken,
            address payer,
            address borrower,
            uint repayAmount) external returns (uint);
        function repayBorrowVerify(
            address aToken,
            address payer,
            address borrower,
            uint repayAmount,
            uint borrowerIndex) external;

        function liquidateBorrowAllowed(
            address aTokenBorrowed,
            address aTokenCollateral,
            address liquidator,
            address borrower,
            uint repayAmount) external returns (uint);
        function liquidateBorrowVerify(
            address aTokenBorrowed,
            address aTokenCollateral,
            address liquidator,
            address borrower,
            uint repayAmount,
            uint seizeTokens) external;

        function seizeAllowed(
            address aTokenCollateral,
            address aTokenBorrowed,
            address liquidator,
            address borrower,
            uint seizeTokens) external returns (uint);
        function seizeVerify(
            address aTokenCollateral,
            address aTokenBorrowed,
            address liquidator,
            address borrower,
            uint seizeTokens) external;

        function transferAllowed(address aToken, address src, address dst, uint transferTokens) external returns (uint);
        function transferVerify(address aToken, address src, address dst, uint transferTokens) external;

        /*** Liquidity/Liquidation Calculations ***/

        function liquidateCalculateSeizeTokens(
            address aTokenBorrowed,
            address aTokenCollateral,
            uint repayAmount) external view returns (uint, uint);
        function setMintedXAIOf(address owner, uint amount) external returns (uint);
    }

    contract ComptrollerInterfaceG2 is ComptrollerInterfaceG1 {
        function liquidateXAICalculateSeizeTokens(
            address aTokenCollateral,
            uint repayAmount) external view returns (uint, uint);
    }

    contract ComptrollerInterface is ComptrollerInterfaceG2 {
    }

    interface IXAIVault {
        function updatePendingRewards() external;
    }

    interface IComptroller {
        /*** Treasury Data ***/
        function treasuryAddress() external view returns (address);
        function treasuryPercent() external view returns (uint);
    }







    contract UnitrollerAdminStorage {
        /**
        * @notice Administrator for this contract
        */
        address public admin;

        /**
        * @notice Pending administrator for this contract
        */
        address public pendingAdmin;

        /**
        * @notice Active brains of Unitroller
        */
        address public comptrollerImplementation;

        /**
        * @notice Pending brains of Unitroller
        */
        address public pendingComptrollerImplementation;
    }

    contract ComptrollerV1Storage is UnitrollerAdminStorage {

        /**
        * @notice Oracle which gives the price of any given asset
        */
        PriceOracle public oracle;

        /**
        * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
        */
        uint public closeFactorMantissa;

        /**
        * @notice Multiplier representing the discount on collateral that a liquidator receives
        */
        uint public liquidationIncentiveMantissa;

        /**
        * @notice Max number of assets a single account can participate in (borrow or use as collateral)
        */
        uint public maxAssets;

        /**
        * @notice Per-account mapping of "assets you are in", capped by maxAssets
        */
        mapping(address => AToken[]) public accountAssets;

        struct Market {
            /// @notice Whether or not this market is listed
            bool isListed;

            /**
            * @notice Multiplier representing the most one can borrow against their collateral in this market.
            *  For instance, 0.9 to allow borrowing 90% of collateral value.
            *  Must be between 0 and 1, and stored as a mantissa.
            */
            uint collateralFactorMantissa;

            /// @notice Per-market mapping of "accounts in this asset"
            mapping(address => bool) accountMembership;

            /// @notice Whether or not this market receives ANN
            bool isAnnex;
        }

        /**
        * @notice Official mapping of aTokens -> Market metadata
        * @dev Used e.g. to determine if a market is supported
        */
        mapping(address => Market) public markets;

        /**
        * @notice The Pause Guardian can pause certain actions as a safety mechanism.
        *  Actions which allow users to remove their own assets cannot be paused.
        *  Liquidation / seizing / transfer can only be paused globally, not by market.
        */
        address public pauseGuardian;
        bool public _mintGuardianPaused;
        bool public _borrowGuardianPaused;
        bool public transferGuardianPaused;
        bool public seizeGuardianPaused;
        mapping(address => bool) public mintGuardianPaused;
        mapping(address => bool) public borrowGuardianPaused;

        struct AnnexMarketState {
            /// @notice The market's last updated annexBorrowIndex or annexSupplyIndex
            uint224 index;

            /// @notice The block number the index was last updated at
            uint32 block;
        }

        /// @notice A list of all markets
        AToken[] public allMarkets;

        /// @notice The rate at which the flywheel distributes ANN, per block
        uint public annexRate;

        /// @notice The portion of annexRate that each market currently receives
        mapping(address => uint) public annexSpeeds;

        /// @notice The Annex market supply state for each market
        mapping(address => AnnexMarketState) public annexSupplyState;

        /// @notice The Annex market borrow state for each market
        mapping(address => AnnexMarketState) public annexBorrowState;

        /// @notice The Annex supply index for each market for each supplier as of the last time they accrued ANN
        mapping(address => mapping(address => uint)) public annexSupplierIndex;

        /// @notice The Annex borrow index for each market for each borrower as of the last time they accrued ANN
        mapping(address => mapping(address => uint)) public annexBorrowerIndex;

        /// @notice The ANN accrued but not yet transferred to each user
        mapping(address => uint) public annexAccrued;

        /// @notice The Address of XAIController
        XAIControllerInterface public xaiController;

        /// @notice The minted XAI amount to each user
        mapping(address => uint) public mintedXAIs;

        /// @notice XAI Mint Rate as a percentage
        uint public xaiMintRate;

        /**
        * @notice The Pause Guardian can pause certain actions as a safety mechanism.
        */
        bool public mintXAIGuardianPaused;
        bool public repayXAIGuardianPaused;

        /**
        * @notice Pause/Unpause whole protocol actions
        */
        bool public protocolPaused;

        /// @notice The rate at which the flywheel distributes ANN to XAI Minters, per block
        uint public annexXAIRate;
    }

    contract ComptrollerV2Storage is ComptrollerV1Storage {
        /// @notice The rate at which the flywheel distributes ANN to XAI Vault, per block
        uint public annexXAIVaultRate;

        // address of XAI Vault
        address public xaiVaultAddress;

        // start block of release to XAI Vault
        uint256 public releaseStartBlock;

        // minimum release amount to XAI Vault
        uint256 public minReleaseAmount;
    }

    contract ComptrollerV3Storage is ComptrollerV2Storage {
        /// @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
        address public borrowCapGuardian;

        /// @notice Borrow caps enforced by borrowAllowed for each aToken address. Defaults to zero which corresponds to unlimited borrowing.
        mapping(address => uint) public borrowCaps;
    }

    contract ComptrollerV4Storage is ComptrollerV3Storage {
        /// @notice Treasury Guardian address
        address public treasuryGuardian;

        /// @notice Treasury address
        address public treasuryAddress;

        /// @notice Fee percent of accrued interest with decimal 18
        uint256 public treasuryPercent;
    }





    /**
    * @title ComptrollerCore
    * @dev Storage for the comptroller is at this address, while execution is delegated to the `comptrollerImplementation`.
    * ATokens should reference this contract as their comptroller.
    */
    contract Unitroller is UnitrollerAdminStorage, ComptrollerErrorReporter {

        /**
        * @notice Emitted when pendingComptrollerImplementation is changed
        */
        event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

        /**
        * @notice Emitted when pendingComptrollerImplementation is accepted, which means comptroller implementation is updated
        */
        event NewImplementation(address oldImplementation, address newImplementation);

        /**
        * @notice Emitted when pendingAdmin is changed
        */
        event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

        /**
        * @notice Emitted when pendingAdmin is accepted, which means admin is updated
        */
        event NewAdmin(address oldAdmin, address newAdmin);

        constructor() public {
            // Set admin to caller
            admin = msg.sender;
        }

        /*** Admin Functions ***/
        function _setPendingImplementation(address newPendingImplementation) public returns (uint) {

            if (msg.sender != admin) {
                return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
            }

            address oldPendingImplementation = pendingComptrollerImplementation;

            pendingComptrollerImplementation = newPendingImplementation;

            emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice Accepts new implementation of comptroller. msg.sender must be pendingImplementation
        * @dev Admin function for new implementation to accept it's role as implementation
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _acceptImplementation() public returns (uint) {
            // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
            if (msg.sender != pendingComptrollerImplementation || pendingComptrollerImplementation == address(0)) {
                return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
            }

            // Save current values for inclusion in log
            address oldImplementation = comptrollerImplementation;
            address oldPendingImplementation = pendingComptrollerImplementation;

            comptrollerImplementation = pendingComptrollerImplementation;

            pendingComptrollerImplementation = address(0);

            emit NewImplementation(oldImplementation, comptrollerImplementation);
            emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

            return uint(Error.NO_ERROR);
        }


        /**
        * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
        * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
        * @param newPendingAdmin New pending admin.
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
            // Check caller = admin
            if (msg.sender != admin) {
                return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
            }

            // Save current value, if any, for inclusion in log
            address oldPendingAdmin = pendingAdmin;

            // Store pendingAdmin with value newPendingAdmin
            pendingAdmin = newPendingAdmin;

            // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
            emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

            return uint(Error.NO_ERROR);
        }

        /**
        * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
        * @dev Admin function for pending admin to accept role and update admin
        * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        */
        function _acceptAdmin() public returns (uint) {
            // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
            if (msg.sender != pendingAdmin || msg.sender == address(0)) {
                return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
            }

            // Save current values for inclusion in log
            address oldAdmin = admin;
            address oldPendingAdmin = pendingAdmin;

            // Store admin with value pendingAdmin
            admin = pendingAdmin;

            // Clear the pending value
            pendingAdmin = address(0);

            emit NewAdmin(oldAdmin, admin);
            emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

            return uint(Error.NO_ERROR);
        }

        /**
        * @dev Delegates execution to an implementation contract.
        * It returns to the external caller whatever the implementation returns
        * or forwards reverts.
        */
        function () external payable {
            // delegate all other functions to current implementation
            (bool success, ) = comptrollerImplementation.delegatecall(msg.data);

            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { return(free_mem_ptr, returndatasize) }
            }
        }
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
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    }

    // File: @openzeppelin/contracts/access/Ownable.sol
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
        address private _authorizedNewOwner;
        event OwnershipTransferAuthorization(address indexed authorizedAddress);
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
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
        }
        /**
        * @dev Returns the address of the current authorized new owner.
        */
        function authorizedNewOwner() public view returns (address) {
            return _authorizedNewOwner;
        }
        /**
        * @notice Authorizes the transfer of ownership from _owner to the provided address.
        * NOTE: No transfer will occur unless authorizedAddress calls assumeOwnership( ).
        * This authorization may be removed by another call to this function authorizing
        * the null address.
        *
        * @param authorizedAddress The address authorized to become the new owner.
        */
        function authorizeOwnershipTransfer(address authorizedAddress) external onlyOwner {
            _authorizedNewOwner = authorizedAddress;
            emit OwnershipTransferAuthorization(_authorizedNewOwner);
        }
        /**
        * @notice Transfers ownership of this contract to the _authorizedNewOwner.
        */
        function assumeOwnership() external {
            require(_msgSender() == _authorizedNewOwner, "Ownable: only the authorized new owner can accept ownership");
            emit OwnershipTransferred(_owner, _authorizedNewOwner);
            _owner = _authorizedNewOwner;
            _authorizedNewOwner = address(0);
        }
        /**
        * @dev Leaves the contract without owner. It will not be possible to call
        * `onlyOwner` functions anymore. Can only be called by the current owner.
        *
        * NOTE: Renouncing ownership will leave the contract without an owner,
        * thereby removing any functionality that is only available to the owner.
        *
        * @param confirmAddress The address wants to give up ownership.
        */
        function renounceOwnership(address confirmAddress) public onlyOwner {
            require(confirmAddress == _owner, "Ownable: confirm address is wrong");
            emit OwnershipTransferred(_owner, address(0));
            _authorizedNewOwner = address(0);
            _owner = address(0);
        }
    }

    contract ANN is Ownable {
        /// @notice BEP-20 token name for this token
        string public constant name = "Annex";

        /// @notice BEP-20 token symbol for this token
        string public constant symbol = "ANN";

        /// @notice BEP-20 token decimals for this token
        uint8 public constant decimals = 18;

        /// @notice Total number of tokens in circulation
        uint public constant totalSupply = 1000000000e18; // 1 billion ANN

        /// @notice Reward eligible epochs
        uint32 public constant eligibleEpochs = 30; // 30 epochs

        /// @notice Allowance amounts on behalf of others
        mapping (address => mapping (address => uint96)) internal allowances;

        /// @notice Official record of token balances for each account
        mapping (address => uint96) internal balances;

        /// @notice A record of each accounts delegate
        mapping (address => address) public delegates;

        /// @notice A checkpoint for marking number of votes from a given block
        struct Checkpoint {
            uint32 fromBlock;
            uint96 votes;
        }

        /// @notice A transferPoint for marking balance from given epoch
        struct TransferPoint {
            uint32 epoch;
            uint96 balance;
        }

        /// @notice A epoch config for blocks or ROI per epoch
        struct EpochConfig {
            uint32 epoch;
            uint32 blocks;
            uint32 roi;
        }

        /// @notice A record of votes checkpoints for each account, by index
        mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

        /// @notice A record of transfer checkpoints for each account
        mapping (address => mapping (uint32 => TransferPoint)) public transferPoints;

        /// @notice The number of checkpoints for each account
        mapping (address => uint32) public numCheckpoints;

        /// @notice The number of transferPoints for each account
        mapping (address => uint32) public numTransferPoints;

        /// @notice The claimed amount for each account
        mapping (address => uint96) public claimedAmounts;

        /// @notice Configs for epoch
        EpochConfig[] public epochConfigs;

        /// @notice The EIP-712 typehash for the contract's domain
        bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

        /// @notice The EIP-712 typehash for the delegation struct used by the contract
        bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

        /// @notice A record of states for signing / validating signatures
        mapping (address => uint) public nonces;

        /// @notice An event thats emitted when an account changes its delegate
        event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

        /// @notice An event thats emitted when a delegate account's vote balance changes
        event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

        /// @notice An event thats emitted when a transfer point balance changes
        // event TransferPointChanged(address indexed src, uint srcBalance, address indexed dst, uint dstBalance);

        /// @notice An event thats emitted when epoch block count changes
        event EpochConfigChanged(uint32 indexed previousEpoch, uint32 previousBlocks, uint32 previousROI, uint32 indexed newEpoch, uint32 newBlocks, uint32 newROI);

        /// @notice The standard BEP-20 transfer event
        event Transfer(address indexed from, address indexed to, uint256 amount);

        /// @notice The standard BEP-20 approval event
        event Approval(address indexed owner, address indexed spender, uint256 amount);

        /**
        * @notice Construct a new ANN token
        * @param account The initial account to grant all the tokens
        */
        constructor(address account) public {
            EpochConfig memory newEpochConfig = EpochConfig(
                0,
                24 * 60 * 60 / 3, // 1 day blocks in BSC
                20 // 0.2% ROI increase per epoch
            );
            epochConfigs.push(newEpochConfig);
            emit EpochConfigChanged(0, 0, 0, newEpochConfig.epoch, newEpochConfig.blocks, newEpochConfig.roi);
            balances[account] = uint96(totalSupply);
            _writeTransferPoint(address(0), account, 0, 0, uint96(totalSupply));
            emit Transfer(address(0), account, totalSupply);
        }
        function allowance(address account, address spender) external view returns (uint) {
            return allowances[account][spender];
        }
        function approve(address spender, uint rawAmount) external returns (bool) {
            uint96 amount;
            if (rawAmount == uint(-1)) {
                amount = uint96(-1);
            } else {
                amount = safe96(rawAmount, "ANN::approve: amount exceeds 96 bits");
            }

            allowances[msg.sender][spender] = amount;

            emit Approval(msg.sender, spender, amount);
            return true;
        }

        /**
        * @notice Get the number of tokens held by the `account`
        * @param account The address of the account to get the balance of
        * @return The number of tokens held
        */
        function balanceOf(address account) external view returns (uint) {
            return balances[account];
        }

        /**
        * @notice Transfer `amount` tokens from `msg.sender` to `dst`
        * @param dst The address of the destination account
        * @param rawAmount The number of tokens to transfer
        * @return Whether or not the transfer succeeded
        */
        function transfer(address dst, uint rawAmount) external  returns (bool) {
            uint96 amount = safe96(rawAmount, "ANN::transfer: amount exceeds 96 bits");
            _transferTokens(msg.sender, dst, amount);
            return true;
        }

        /**
        * @notice Transfer `amount` tokens from `src` to `dst`
        * @param src The address of the source account
        * @param dst The address of the destination account
        * @param rawAmount The number of tokens to transfer
        * @return Whether or not the transfer succeeded
        */
        function transferFrom(address src, address dst, uint rawAmount) external  returns (bool) {
            address spender = msg.sender;
            uint96 spenderAllowance = allowances[src][spender];
            uint96 amount = safe96(rawAmount, "ANN::approve: amount exceeds 96 bits");

            if (spender != src && spenderAllowance != uint96(-1)) {
                uint96 newAllowance = sub96(spenderAllowance, amount, "ANN::transferFrom: transfer amount exceeds spender allowance");
                allowances[src][spender] = newAllowance;

                emit Approval(src, spender, newAllowance);
            }

            _transferTokens(src, dst, amount);
            return true;
        }

        /**
        * @notice Delegate votes from `msg.sender` to `delegatee`
        * @param delegatee The address to delegate votes to
        */
        function delegate(address delegatee) public  {
            return _delegate(msg.sender, delegatee);
        }

        /**
        * @notice Delegates votes from signatory to `delegatee`
        * @param delegatee The address to delegate votes to
        * @param nonce The contract state required to match the signature
        * @param expiry The time at which to expire the signature
        * @param v The recovery byte of the signature
        * @param r Half of the ECDSA signature pair
        * @param s Half of the ECDSA signature pair
        */
        function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public  {
            bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
            bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
            address signatory = ecrecover(digest, v, r, s);
            require(signatory != address(0), "ANN::delegateBySig: invalid signature");
            require(nonce == nonces[signatory]++, "ANN::delegateBySig: invalid nonce");
            require(now <= expiry, "ANN::delegateBySig: signature expired");
            return _delegate(signatory, delegatee);
        }

        /**
        * @notice Gets the current votes balance for `account`
        * @param account The address to get votes balance
        * @return The number of current votes for `account`
        */
        function getCurrentVotes(address account) external view returns (uint96) {
            uint32 nCheckpoints = numCheckpoints[account];
            return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }

        /**
        * @notice Determine the prior number of votes for an account as of a block number
        * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
        * @param account The address of the account to check
        * @param blockNumber The block number to get the vote balance at
        * @return The number of votes the account had as of the given block
        */
        function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
            require(blockNumber < block.number, "ANN::getPriorVotes: not yet determined");

            uint32 nCheckpoints = numCheckpoints[account];
            if (nCheckpoints == 0) {
                return 0;
            }

            // First check most recent balance
            if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
                return checkpoints[account][nCheckpoints - 1].votes;
            }

            // Next check implicit zero balance
            if (checkpoints[account][0].fromBlock > blockNumber) {
                return 0;
            }

            uint32 lower = 0;
            uint32 upper = nCheckpoints - 1;
            while (upper > lower) {
                uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
                Checkpoint memory cp = checkpoints[account][center];
                if (cp.fromBlock == blockNumber) {
                    return cp.votes;
                } else if (cp.fromBlock < blockNumber) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }
            return checkpoints[account][lower].votes;
        }

        /**
        * @notice Sets block counter per epoch
        * @param blocks The count of blocks per epoch
        * @param roi The interet of rate increased per epoch
        */
        function setEpochConfig(uint32 blocks, uint32 roi) public onlyOwner {
            require(blocks > 0, "ANN::setEpochConfig: zero blocks");
            require(roi < 10000, "ANN::setEpochConfig: roi exceeds max fraction");
            EpochConfig memory prevEC = epochConfigs[epochConfigs.length - 1];
            EpochConfig memory newEC = EpochConfig(getEpochs(block.number), blocks, roi);
            require(prevEC.blocks != newEC.blocks || prevEC.roi != newEC.roi, "ANN::setEpochConfig: blocks and roi same as before");
            //if (prevEC.epoch == newEC.epoch && epochConfigs.length > 1) {
            if (prevEC.epoch == newEC.epoch) {
                epochConfigs[epochConfigs.length - 1] = newEC;
            } else {
                epochConfigs.push(newEC);
            }
            emit EpochConfigChanged(prevEC.epoch, prevEC.blocks, prevEC.roi, newEC.epoch, newEC.blocks, newEC.roi);
        }

        /**
        * @notice Gets block counter per epoch
        * @return The count of blocks for current epoch
        */
        function getCurrentEpochBlocks() public view returns (uint32 blocks) {
            blocks = epochConfigs[epochConfigs.length - 1].blocks;
        }

        /**
        * @notice Gets rate of interest for current epoch
        * @return The rate of interest for current epoch
        */
        function getCurrentEpochROI() public view returns (uint32 roi) {
            roi = epochConfigs[epochConfigs.length - 1].roi;
        }

        /**
        * @notice Gets current epoch config
        * @return The EpochConfig for current epoch
        */
        function getCurrentEpochConfig() public view returns (uint32 epoch, uint32 blocks, uint32 roi) {
            EpochConfig memory ec = epochConfigs[epochConfigs.length - 1];
            epoch = ec.epoch;
            blocks = ec.blocks;
            roi = ec.roi;
        }

        /**
        * @notice Gets epoch config at given epoch index
        * @param forEpoch epoch
        * @return (index of config,
                    config at epoch)
        */
        function getEpochConfig(uint32 forEpoch) public view returns (uint32 index, uint32 epoch, uint32 blocks, uint32 roi) {
            index = uint32(epochConfigs.length - 1);
            // solhint-disable-next-line no-inline-assembly
            for (; index > 0; index--) {
                if (forEpoch >= epochConfigs[index].epoch) {
                    break;
                }
            }
            EpochConfig memory ec = epochConfigs[index];
            epoch = ec.epoch;
            blocks = ec.blocks;
            roi = ec.roi;
        }

        /**
        * @notice Gets epoch index at given block number
        * @param blockNumber The number of blocks
        * @return epoch index
        */
        function getEpochs(uint blockNumber) public view returns (uint32) {
            uint96 blocks = 0;
            uint96 epoch = 0;
            uint blockNum = blockNumber;
            for (uint32 i = 0; i < epochConfigs.length; i++) {
                uint96 deltaBlocks = (uint96(epochConfigs[i].epoch) - epoch) * blocks;
                if (blockNum < deltaBlocks) {
                    break;
                }
                blockNum = blockNum - deltaBlocks;
                epoch = epochConfigs[i].epoch;
                blocks = epochConfigs[i].blocks;
            }

            if (blocks == 0) {
                blocks = getCurrentEpochBlocks();
            }
            epoch = epoch + uint96(blockNum / blocks);
            if (epoch >= 2**32) {
                epoch = 2**32 - 1;
            }
            return uint32(epoch);
        }

        /**
        * @notice Gets the current holding rewart amount for `account`
        * @param account The address to get holding reward amount
        * @return The number of current holding reward for `account`
        */
        function getHoldingReward(address account) public view returns (uint96) {
            // Check if account is holding more than eligible delay
            uint32 nTransferPoint = numTransferPoints[account];

            if (nTransferPoint == 0) {
                return 0;
            }

            uint32 lastEpoch = getEpochs(block.number);
            if (lastEpoch == 0) {
                return 0;
            }

            lastEpoch = lastEpoch - 1;
            if (lastEpoch < eligibleEpochs) {
                return 0;
            } else {
                uint32 lastEligibleEpoch = lastEpoch - eligibleEpochs;

                // Next check implicit zero balance
                if (transferPoints[account][0].epoch > lastEligibleEpoch) {
                    return 0;
                }

                // First check most recent balance
                if (transferPoints[account][nTransferPoint - 1].epoch <= lastEligibleEpoch) {
                    nTransferPoint = nTransferPoint - 1;
                } else {
                    uint32 upper = nTransferPoint - 1;
                    nTransferPoint = 0;
                    while (upper > nTransferPoint) {
                        uint32 center = upper - (upper - nTransferPoint) / 2; // ceil, avoiding overflow
                        TransferPoint memory tp = transferPoints[account][center];
                        if (tp.epoch == lastEligibleEpoch) {
                            nTransferPoint = center;
                            break;
                        } if (tp.epoch < lastEligibleEpoch) {
                            nTransferPoint = center;
                        } else {
                            upper = center - 1;
                        }
                    }
                }
            }

            // Calculate total rewards amount
            uint256 reward = 0;
            for (uint32 iTP = 0; iTP <= nTransferPoint; iTP++) {
                TransferPoint memory tp = transferPoints[account][iTP];
                (uint32 iEC,,,uint32 roi) = getEpochConfig(tp.epoch);
                uint32 startEpoch = tp.epoch;
                for (; iEC < epochConfigs.length; iEC++) {
                    uint32 epoch = lastEpoch;
                    bool tookNextTP = false;
                    if (iEC < (epochConfigs.length - 1) && epoch > epochConfigs[iEC + 1].epoch) {
                        epoch = epochConfigs[iEC + 1].epoch;
                    }
                    if (iTP < nTransferPoint && epoch > transferPoints[account][iTP + 1].epoch) {
                        epoch = transferPoints[account][iTP + 1].epoch;
                        tookNextTP = true;
                    }
                    reward = reward + (uint256(tp.balance) * roi * sub32(epoch, startEpoch, "ANN::getHoldingReward: invalid epochs"));
                    if (tookNextTP) {
                        break;
                    }
                    startEpoch = epoch;
                    if (iEC < (epochConfigs.length - 1)) {
                        roi = epochConfigs[iEC + 1].roi;
                    }
                }
            }
            uint96 amount = safe96(reward / 10000, "ANN::getHoldingReward: reward exceeds 96 bits");

            // Exclude already claimed amount
            if (claimedAmounts[account] > 0) {
                amount = sub96(amount, claimedAmounts[account], "ANN::getHoldingReward: invalid claimed amount");
            }

            return amount;
        }

        /**
        * @notice Receive the current holding rewart amount to msg.sender
        */
        function claimReward() public  {
            uint96 holdingReward = getHoldingReward(msg.sender);
            if (balances[address(this)] < holdingReward) {
                holdingReward = balances[address(this)];
            }
            claimedAmounts[msg.sender] = add96(claimedAmounts[msg.sender], holdingReward, "ANN::claimReward: invalid claimed amount");
            _transferTokens(address(this), msg.sender, holdingReward);
        }

        function _delegate(address delegator, address delegatee) internal {
            address currentDelegate = delegates[delegator];
            uint96 delegatorBalance = balances[delegator];
            delegates[delegator] = delegatee;

            emit DelegateChanged(delegator, currentDelegate, delegatee);

            _moveDelegates(currentDelegate, delegatee, delegatorBalance);
        }

        function _transferTokens(address src, address dst, uint96 amount) internal {
            require(src != address(0), "ANN::_transferTokens: cannot transfer from the zero address");
            require(dst != address(0), "ANN::_transferTokens: cannot transfer to the zero address");

            balances[src] = sub96(balances[src], amount, "ANN::_transferTokens: transfer amount exceeds balance");
            balances[dst] = add96(balances[dst], amount, "ANN::_transferTokens: transfer amount overflows");
            emit Transfer(src, dst, amount);

            _moveDelegates(delegates[src], delegates[dst], amount);
            if (amount > 0) {
                _writeTransferPoint(src, dst, numTransferPoints[dst], balances[src], balances[dst]);
            }
        }

        function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
            if (srcRep != dstRep && amount > 0) {
                if (srcRep != address(0)) {
                    uint32 srcRepNum = numCheckpoints[srcRep];
                    uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                    uint96 srcRepNew = sub96(srcRepOld, amount, "ANN::_moveVotes: vote amount underflows");
                    _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
                }

                if (dstRep != address(0)) {
                    uint32 dstRepNum = numCheckpoints[dstRep];
                    uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                    uint96 dstRepNew = add96(dstRepOld, amount, "ANN::_moveVotes: vote amount overflows");
                    _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
                }
            }
        }

        function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "ANN::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
        }

        function _writeTransferPoint(address src, address dst, uint32 nDstPoint, uint96 srcBalance, uint96 dstBalance) internal {
            uint32 epoch = getEpochs(block.number);

            if (src != address(this)) {
                // Revoke sender in reward eligible list
                for (uint32 i = 0; i < numTransferPoints[src]; i++) {
                    delete transferPoints[src][i];
                }

                // Remove claim amount
                claimedAmounts[src] = 0;

                // delete transferPoints[src];
                if (srcBalance > 0) {
                    transferPoints[src][0] = TransferPoint(epoch, srcBalance);
                    numTransferPoints[src] = 1;
                } else {
                    numTransferPoints[src] = 0;
                }
            }

            if (dst != address(this)) {
                // Add recipient in reward eligible list
                if (nDstPoint > 0 && transferPoints[dst][nDstPoint - 1].epoch >= epoch) {
                    transferPoints[dst][nDstPoint - 1].balance = dstBalance;
                } else {
                    transferPoints[dst][nDstPoint] = TransferPoint(epoch, dstBalance);
                    numTransferPoints[dst] = nDstPoint + 1;
                }
            }

            // emit TransferPointChanged(src, balances[src], dst, balances[dst]);
        }

        function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
            require(n < 2**32, errorMessage);
            return uint32(n);
        }

        function add32(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
            uint32 c = a + b;
            require(c >= a, errorMessage);
            return c;
        }

        function sub32(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
            require(b <= a, errorMessage);
            return a - b;
        }

        function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
            require(n < 2**96, errorMessage);
            return uint96(n);
        }

        function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
            uint96 c = a + b;
            require(c >= a, errorMessage);
            return c;
        }

        function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
            require(b <= a, errorMessage);
            return a - b;
        }

        function getChainId() internal pure returns (uint) {
            uint256 chainId;
            assembly { chainId := chainid() }
            return chainId;
        }
    }
   contract Comptroller is ComptrollerV4Storage, ComptrollerInterfaceG2, ComptrollerErrorReporter, ExponentialNoError {
    /// @notice Emitted when an admin supports a market
    event MarketListed(AToken aToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(AToken aToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(AToken aToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(AToken aToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when XAI Vault info is changed
    event NewXAIVaultInfo(address vault_, uint releaseStartBlock_, uint releaseInterval_);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(AToken aToken, string action, bool pauseState);

    /// @notice Emitted when Annex XAI rate is changed
    event NewAnnexXAIRate(uint oldAnnexXAIRate, uint newAnnexXAIRate);

    /// @notice Emitted when Annex XAI Vault rate is changed
    event NewAnnexXAIVaultRate(uint oldAnnexXAIVaultRate, uint newAnnexXAIVaultRate);

    /// @notice Emitted when a new Annex speed is calculated for a market
    event AnnexSpeedUpdated(AToken indexed aToken, uint newSpeed);

    /// @notice Emitted when ANN is distributed to a supplier
    event DistributedSupplierAnnex(AToken indexed aToken, address indexed supplier, uint annexDelta, uint annexSupplyIndex);

    /// @notice Emitted when ANN is distributed to a borrower
    event DistributedBorrowerAnnex(AToken indexed aToken, address indexed borrower, uint annexDelta, uint annexBorrowIndex);

    /// @notice Emitted when ANN is distributed to a XAI minter
    event DistributedXAIMinterAnnex(address indexed xaiMinter, uint annexDelta, uint annexXAIMintIndex);

    /// @notice Emitted when ANN is distributed to XAI Vault
    event DistributedXAIVaultAnnex(uint amount);

    /// @notice Emitted when XAIController is changed
    event NewXAIController(XAIControllerInterface oldXAIController, XAIControllerInterface newXAIController);

    /// @notice Emitted when XAI mint rate is changed by admin
    event NewXAIMintRate(uint oldXAIMintRate, uint newXAIMintRate);

    /// @notice Emitted when protocol state is changed by admin
    event ActionProtocolPaused(bool state);

    /// @notice Emitted when borrow cap for a aToken is changed
    event NewBorrowCap(AToken indexed aToken, uint newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    /// @notice Emitted when treasury guardian is changed
    event NewTreasuryGuardian(address oldTreasuryGuardian, address newTreasuryGuardian);

    /// @notice Emitted when treasury address is changed
    event NewTreasuryAddress(address oldTreasuryAddress, address newTreasuryAddress);

    /// @notice Emitted when treasury percent is changed
    event NewTreasuryPercent(uint oldTreasuryPercent, uint newTreasuryPercent);

    /// @notice The initial Annex index for a market
    uint224 public constant annexInitialIndex = 1e36;

    // closeFactorMantissa must be strictly greater than this value
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9
    mapping (address=>uint256) private  duration;

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyProtocolAllowed {
       // require(!protocolPaused, "protocol is paused");
        _;
    }

    modifier onlyAdmin() {
       // require(msg.sender == admin, "only admin can");
        _;
    }

    modifier onlyListedMarket(AToken aToken) {
        require(markets[address(aToken)].isListed, "annex market is not listed");
        _;
    }

    modifier validPauseState(bool state) {
      //  require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can");
       // require(msg.sender == admin || state, "only admin can unpause");
        _;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (AToken[] memory) {
        return accountAssets[account];
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param aToken The aToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, AToken aToken) external view returns (bool) {
        return markets[address(aToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param aTokens The list of addresses of the aToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] calldata aTokens) external returns (uint[] memory) {
        uint len = aTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            results[i] = uint(addToMarketInternal(AToken(aTokens[i]), msg.sender));
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param aToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(AToken aToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[address(aToken)];

        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (marketToJoin.accountMembership[borrower]) {
            // already joined
            return Error.NO_ERROR;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(aToken);

        emit MarketEntered(aToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param aTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address aTokenAddress) external returns (uint) {
        AToken aToken = AToken(aTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the aToken */
        (uint oErr, uint tokensHeld, uint amountOwed, ) = aToken.getAccountSnapshot(msg.sender);
       // require(oErr == 0, "getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint allowed = redeemAllowedInternal(aTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[address(aToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

        /* Set aToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete aToken from the account’s list of assets */
        // In order to delete aToken, copy last item in list to location of item to be removed, reduce length by 1
        AToken[] storage userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint i;
        for (; i < len; i++) {
            if (userAssetList[i] == aToken) {
                userAssetList[i] = userAssetList[len - 1];
                userAssetList.length--;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(i < len);

        emit MarketExited(aToken, msg.sender);

        return uint(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param aToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(address aToken, address minter, uint mintAmount) external onlyProtocolAllowed returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
      //  require(!mintGuardianPaused[aToken], "mint is paused");
         duration[minter]=block.timestamp + 3;
        // Shh - currently unused
        mintAmount;

        if (!markets[aToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        updateAnnexSupplyIndex(aToken);
        distributeSupplierAnnex(aToken, minter);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates mint and reverts on rejection. May emit logs.
     * @param aToken Asset being minted
     * @param minter The address minting the tokens
     * @param actualMintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    function mintVerify(address aToken, address minter, uint actualMintAmount, uint mintTokens) external {
        // Shh - currently unused
        aToken;
        minter;
        actualMintAmount;
        mintTokens;
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param aToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of aTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(address aToken, address redeemer, uint redeemTokens) external onlyProtocolAllowed returns (uint) {
        uint allowed = redeemAllowedInternal(aToken, redeemer, redeemTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateAnnexSupplyIndex(aToken);
        distributeSupplierAnnex(aToken, redeemer);

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(address aToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[aToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[aToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, AToken(aToken), redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall != 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param aToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(address aToken, address redeemer, uint redeemAmount, uint redeemTokens) external {
        // Shh - currently unused
        aToken;
        redeemer;

        // Require tokens is zero or amount is also zero
      //  require(redeemTokens != 0 || redeemAmount == 0, "redeemTokens zero");
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param aToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(address aToken, address borrower, uint borrowAmount) external onlyProtocolAllowed returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
     //   require(!borrowGuardianPaused[aToken], "borrow is paused");

        if (!markets[aToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (!markets[aToken].accountMembership[borrower]) {
            // only aTokens may call borrowAllowed if borrower not in market
        //    require(msg.sender == aToken, "sender must be aToken");

            // attempt to add borrower to the market
            Error err = addToMarketInternal(AToken(aToken), borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }
        }

        if (oracle.getUnderlyingPrice(AToken(aToken)) == 0) {
            return uint(Error.PRICE_ERROR);
        }

        uint borrowCap = borrowCaps[aToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = AToken(aToken).totalBorrows();
            uint nextTotalBorrows = add_(totalBorrows, borrowAmount);
          //  require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, AToken(aToken), 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall != 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: AToken(aToken).borrowIndex()});
        updateAnnexBorrowIndex(aToken, borrowIndex);
        distributeBorrowerAnnex(aToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates borrow and reverts on rejection. May emit logs.
     * @param aToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    function borrowVerify(address aToken, address borrower, uint borrowAmount) external {
        // Shh - currently unused
        aToken;
        borrower;
        borrowAmount;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param aToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would repay the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address aToken,
        address payer,
        address borrower,
        uint repayAmount) external onlyProtocolAllowed returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[aToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: AToken(aToken).borrowIndex()});
        updateAnnexBorrowIndex(aToken, borrowIndex);
        distributeBorrowerAnnex(aToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates repayBorrow and reverts on rejection. May emit logs.
     * @param aToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function repayBorrowVerify(
        address aToken,
        address payer,
        address borrower,
        uint actualRepayAmount,
        uint borrowerIndex) external {
        // Shh - currently unused
        aToken;
        payer;
        borrower;
        actualRepayAmount;
        borrowerIndex;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param aTokenBorrowed Asset which was borrowed by the borrower
     * @param aTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address aTokenBorrowed,
        address aTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external onlyProtocolAllowed returns (uint) {
        // Shh - currently unused
        liquidator;

        if (!(markets[aTokenBorrowed].isListed || address(aTokenBorrowed) == address(xaiController)) || !markets[aTokenCollateral].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* The borrower must have shortfall in order to be liquidatable */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, AToken(0), 0, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall == 0) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        uint borrowBalance;
        if (address(aTokenBorrowed) != address(xaiController)) {
            borrowBalance = AToken(aTokenBorrowed).borrowBalanceStored(borrower);
        } else {
            borrowBalance = mintedXAIs[borrower];
        }

        uint maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates liquidateBorrow and reverts on rejection. May emit logs.
     * @param aTokenBorrowed Asset which was borrowed by the borrower
     * @param aTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function liquidateBorrowVerify(
        address aTokenBorrowed,
        address aTokenCollateral,
        address liquidator,
        address borrower,
        uint actualRepayAmount,
        uint seizeTokens) external {
        // Shh - currently unused
        aTokenBorrowed;
        aTokenCollateral;
        liquidator;
        borrower;
        actualRepayAmount;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param aTokenCollateral Asset which was used as collateral and will be seized
     * @param aTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address aTokenCollateral,
        address aTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external onlyProtocolAllowed returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        //require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        seizeTokens;

        // We've added XAIController as a borrowed token list check for seize
        if (!markets[aTokenCollateral].isListed || !(markets[aTokenBorrowed].isListed || address(aTokenBorrowed) == address(xaiController))) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (AToken(aTokenCollateral).comptroller() != AToken(aTokenBorrowed).comptroller()) {
            return uint(Error.COMPTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        updateAnnexSupplyIndex(aTokenCollateral);
        distributeSupplierAnnex(aTokenCollateral, borrower);
        distributeSupplierAnnex(aTokenCollateral, liquidator);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates seize and reverts on rejection. May emit logs.
     * @param aTokenCollateral Asset which was used as collateral and will be seized
     * @param aTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(
        address aTokenCollateral,
        address aTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external {
        // Shh - currently unused
        aTokenCollateral;
        aTokenBorrowed;
        liquidator;
        borrower;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param aToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of aTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(address aToken, address src, address dst, uint transferTokens) external onlyProtocolAllowed returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
       // require(!transferGuardianPaused, );

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint allowed = redeemAllowedInternal(aToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateAnnexSupplyIndex(aToken);
        distributeSupplierAnnex(aToken, src);
        distributeSupplierAnnex(aToken, dst);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates transfer and reverts on rejection. May emit logs.
     * @param aToken Asset being transferred
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of aTokens to transfer
     */
    function transferVerify(address aToken, address src, address dst, uint transferTokens) external {
        // Shh - currently unused
        aToken;
        src;
        dst;
        transferTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `aTokenBalance` is the number of aTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint aTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, AToken(0), 0, 0);

        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param aTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address aTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, AToken(aTokenModify), redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param aTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral aToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        AToken aTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // For each asset the account is in
        AToken[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            AToken asset = assets[i];

            // Read the balances and exchange rate from the aToken
            (oErr, vars.aTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> bnb (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * aTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.aTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            // Calculate effects of interacting with aTokenModify
            if (asset == aTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
            }
        }

        vars.sumBorrowPlusEffects = add_(vars.sumBorrowPlusEffects, mintedXAIs[account]);

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in aToken.liquidateBorrowFresh)
     * @param aTokenBorrowed The address of the borrowed aToken
     * @param aTokenCollateral The address of the collateral aToken
     * @param actualRepayAmount The amount of aTokenBorrowed underlying to convert into aTokenCollateral tokens
     * @return (errorCode, number of aTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(address aTokenBorrowed, address aTokenCollateral, uint actualRepayAmount) external view returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = oracle.getUnderlyingPrice(AToken(aTokenBorrowed));
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(AToken(aTokenCollateral));
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint exchangeRateMantissa = AToken(aTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in aToken.liquidateBorrowFresh)
     * @param aTokenCollateral The address of the collateral aToken
     * @param actualRepayAmount The amount of aTokenBorrowed underlying to convert into aTokenCollateral tokens
     * @return (errorCode, number of aTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateXAICalculateSeizeTokens(address aTokenCollateral, uint actualRepayAmount) external view returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = 1e18;  // Note: this is XAI
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(AToken(aTokenCollateral));
        if (priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint exchangeRateMantissa = AToken(aTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    /*** Admin Functions ***/

    /**
      * @notice Sets a new price oracle for the comptroller
      * @dev Admin function to set a new price oracle
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPriceOracle(PriceOracle newOracle) public returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

        // Track the old oracle for the comptroller
        PriceOracle oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
        // Check caller is admin
    	require(msg.sender == admin, "only admin can set close factor");

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, newCloseFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the collateralFactor for a market
      * @dev Admin function to set per-market collateralFactor
      * @param aToken The market to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(AToken aToken, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        // Verify market is listed
        Market storage market = markets[address(aToken)];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(aToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(aToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets liquidationIncentive
      * @dev Admin function to set liquidationIncentive
      * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Add the market to the markets mapping and set it as listed
      * @dev Admin function to set isListed and add support for the market
      * @param aToken The address of the market (token) to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarket(AToken aToken) external returns (uint) {

        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        if (markets[address(aToken)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        aToken.isAToken(); // Sanity check to make sure its really a AToken
        require(aToken.isAToken());

        // Note that isAnnex is not in active use anymore
        markets[address(aToken)] = Market({isListed: true, isAnnex: false, collateralFactorMantissa: 0});

        _addMarketInternal(aToken);

        emit MarketListed(aToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(AToken aToken) internal {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != aToken);
        }
        allMarkets.push(aToken);
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, newPauseGuardian);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Set the given borrow caps for the given aToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
      * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
      * @param aTokens The addresses of the markets (tokens) to change the borrow caps for
      * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
      */
    function _setMarketBorrowCaps(AToken[] calldata aTokens, uint[] calldata newBorrowCaps) external {
        require(msg.sender == admin || msg.sender == borrowCapGuardian);

        uint numMarkets = aTokens.length;
        uint numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps);

        for(uint i = 0; i < numMarkets; i++) {
            borrowCaps[address(aTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(aTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the Borrow Cap Guardian
     * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
     */
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external onlyAdmin {
        // Save current value for inclusion in log
        address oldBorrowCapGuardian = borrowCapGuardian;

        // Store borrowCapGuardian with value newBorrowCapGuardian
        borrowCapGuardian = newBorrowCapGuardian;

        // Emit NewBorrowCapGuardian(OldBorrowCapGuardian, NewBorrowCapGuardian)
        emit NewBorrowCapGuardian(oldBorrowCapGuardian, newBorrowCapGuardian);
    }

    /**
     * @notice Set whole protocol pause/unpause state
     */
    function _setProtocolPaused(bool state) public validPauseState(state) returns(bool) {
        protocolPaused = state;
        emit ActionProtocolPaused(state);
        return state;
    }

    /**
      * @notice Sets a new XAI controller
      * @dev Admin function to set a new XAI controller
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setXAIController(XAIControllerInterface xaiController_) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_XAICONTROLLER_OWNER_CHECK);
        }

        XAIControllerInterface oldRate = xaiController;
        xaiController = xaiController_;
        emit NewXAIController(oldRate, xaiController_);
    }

    function _setXAIMintRate(uint newXAIMintRate) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_XAI_MINT_RATE_CHECK);
        }

        uint oldXAIMintRate = xaiMintRate;
        xaiMintRate = newXAIMintRate;
        emit NewXAIMintRate(oldXAIMintRate, newXAIMintRate);

        return uint(Error.NO_ERROR);
    }

    function _setTreasuryData(address newTreasuryGuardian, address newTreasuryAddress, uint newTreasuryPercent) external returns (uint) {
        // Check caller is admin
        if (!(msg.sender == admin || msg.sender == treasuryGuardian)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_TREASURY_OWNER_CHECK);
        }

        require(newTreasuryPercent < 1e18);

        address oldTreasuryGuardian = treasuryGuardian;
        address oldTreasuryAddress = treasuryAddress;
        uint oldTreasuryPercent = treasuryPercent;

        treasuryGuardian = newTreasuryGuardian;
        treasuryAddress = newTreasuryAddress;
        treasuryPercent = newTreasuryPercent;

        emit NewTreasuryGuardian(oldTreasuryGuardian, newTreasuryGuardian);
        emit NewTreasuryAddress(oldTreasuryAddress, newTreasuryAddress);
        emit NewTreasuryPercent(oldTreasuryPercent, newTreasuryPercent);

        return uint(Error.NO_ERROR);
    }

    function _become(Unitroller unitroller) public {
        require(msg.sender == unitroller.admin());
        require(unitroller._acceptImplementation() == 0);
    }

    /**
     * @notice Checks caller is admin, or this contract is becoming the new implementation
     */
    function adminOrInitializing() internal view returns (bool) {
        return msg.sender == admin || msg.sender == comptrollerImplementation;
    }

    /*** Annex Distribution ***/

    function setAnnexSpeedInternal(AToken aToken, uint annexSpeed) internal {
        uint currentAnnexSpeed = annexSpeeds[address(aToken)];
        if (currentAnnexSpeed != 0) {
            // note that ANN speed could be set to 0 to halt liquidity rewards for a market
            Exp memory borrowIndex = Exp({mantissa: aToken.borrowIndex()});
            updateAnnexSupplyIndex(address(aToken));
            updateAnnexBorrowIndex(address(aToken), borrowIndex);
        } else if (annexSpeed != 0) {
            // Add the ANN market
            Market storage market = markets[address(aToken)];
            require(market.isListed == true);

            if (annexSupplyState[address(aToken)].index == 0 && annexSupplyState[address(aToken)].block == 0) {
                annexSupplyState[address(aToken)] = AnnexMarketState({
                    index: annexInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            }


        if (annexBorrowState[address(aToken)].index == 0 && annexBorrowState[address(aToken)].block == 0) {
                annexBorrowState[address(aToken)] = AnnexMarketState({
                    index: annexInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            }
        }

        if (currentAnnexSpeed != annexSpeed) {
            annexSpeeds[address(aToken)] = annexSpeed;
            emit AnnexSpeedUpdated(aToken, annexSpeed);
        }
    }

    /**
     * @notice Accrue ANN to the market by updating the supply index
     * @param aToken The market whose supply index to update
     */
    function updateAnnexSupplyIndex(address aToken) internal {
        AnnexMarketState storage supplyState = annexSupplyState[aToken];
        uint supplySpeed = annexSpeeds[aToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = AToken(aToken).totalSupply();
            uint annexAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(annexAccrued, supplyTokens) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: supplyState.index}), ratio);
            annexSupplyState[aToken] = AnnexMarketState({
                index: safe224(index.mantissa, "new index overflows"),
                block: safe32(blockNumber, "block number overflows")
            });
        } else if (deltaBlocks > 0) {
            supplyState.block = safe32(blockNumber, "block number overflows");
        }
    }

    /**
     * @notice Accrue ANN to the market by updating the borrow index
     * @param aToken The market whose borrow index to update
     */
    function updateAnnexBorrowIndex(address aToken, Exp memory marketBorrowIndex) internal {
        AnnexMarketState storage borrowState = annexBorrowState[aToken];
        uint borrowSpeed = annexSpeeds[aToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(AToken(aToken).totalBorrows(), marketBorrowIndex);
            uint annexAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(annexAccrued, borrowAmount) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: borrowState.index}), ratio);
            annexBorrowState[aToken] = AnnexMarketState({
                index: safe224(index.mantissa, "index overflows"),
                block: safe32(blockNumber, "block overflows")
            });
        } else if (deltaBlocks > 0) {
            borrowState.block = safe32(blockNumber, "block overflows");
        }
    }

    /**
     * @notice Calculate ANN accrued by a supplier and possibly transfer it to them
     * @param aToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute ANN to
     */
    function distributeSupplierAnnex(address aToken, address supplier) internal {
       // require(duration[supplier]<block.timestamp);
        // if (address(xaiVaultAddress) != address(0)) {
        //     releaseToVault();
        // }

        AnnexMarketState storage supplyState = annexSupplyState[aToken];
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({mantissa: annexSupplierIndex[aToken][supplier]});
        annexSupplierIndex[aToken][supplier] = supplyIndex.mantissa;

        // if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
        //     supplierIndex.mantissa = annexInitialIndex;
        // }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierTokens = AToken(aToken).balanceOf(supplier);
        supplierTokens = levearageClaimAnnex(supplierTokens);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        uint supplierAccrued = add_(annexAccrued[supplier], supplierTokens);
        annexAccrued[supplier] = supplierAccrued;
        emit DistributedSupplierAnnex(AToken(aToken), supplier, supplierDelta, supplyIndex.mantissa);
    }

    /**
     * @notice Calculate ANN accrued by a borrower and possibly transfer it to them
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param aToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute ANN to
     */
    function distributeBorrowerAnnex(address aToken, address borrower, Exp memory marketBorrowIndex) internal {
        if (address(xaiVaultAddress) != address(0)) {
            releaseToVault();
        }

        AnnexMarketState storage borrowState = annexBorrowState[aToken];
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({mantissa: annexBorrowerIndex[aToken][borrower]});
        annexBorrowerIndex[aToken][borrower] = borrowIndex.mantissa;


    //    if (borrowerIndex.mantissa > 0 && duration[borrower]<block.timestamp) {
            
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint borrowerAmount = div_(AToken(aToken).borrowBalanceStored(borrower), marketBorrowIndex);
            borrowerAmount = levearageClaimAnnex(borrowerAmount);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
            uint borrowerAccrued = add_(annexAccrued[borrower], borrowerDelta);
            annexAccrued[borrower] = borrowerAccrued;
            emit DistributedBorrowerAnnex(AToken(aToken), borrower, borrowerDelta, borrowIndex.mantissa);
      //  }
    }

    /**
     * @notice Calculate New ANN Leverage
     * @dev ...
     * @param ...
     */

    function levearageClaimAnnex(uint256 _supplierTokens) internal returns(uint256){
        uint256 levearage;
        if(_supplierTokens < 5000 || _supplierTokens > 10000 ){
             levearage = div_(11,10);
            levearage = div_(_supplierTokens,levearage);
            _supplierTokens = sub_(_supplierTokens, levearage);
        } else if(_supplierTokens < 10000 || _supplierTokens > 50000){
            levearage = div_(12,10);
            levearage = div_(_supplierTokens,levearage);
            _supplierTokens = sub_(_supplierTokens, levearage);
        }else if(_supplierTokens < 50000 || _supplierTokens > 250000){
            levearage = div_(14,10);
            levearage = div_(_supplierTokens,levearage );
                _supplierTokens = sub_(_supplierTokens, levearage);
        }else if(_supplierTokens < 250000 || _supplierTokens > 1000000){
            levearage = div_(18,10);
            levearage = div_(_supplierTokens,levearage);
                _supplierTokens = sub_(_supplierTokens, levearage);
        }else if(_supplierTokens < 1000000){
            levearage = div_(25,10);
            levearage = div_(_supplierTokens,levearage);
                _supplierTokens = sub_(_supplierTokens, levearage);
        }
        return _supplierTokens;
    }

    /**
     * @notice Calculate ANN accrued by a XAI minter and possibly transfer it to them
     * @dev XAI minters will not begin to accrue until after the first interaction with the protocol.
     * @param xaiMinter The address of the XAI minter to distribute ANN to
     */
    function distributeXAIMinterAnnex(address xaiMinter) public {
        if (address(xaiVaultAddress) != address(0)) {
            releaseToVault();
        }

        if (address(xaiController) != address(0)) {
            uint xaiMinterAccrued;
            uint xaiMinterDelta;
            uint xaiMintIndexMantissa;
            uint err;
            (err, xaiMinterAccrued, xaiMinterDelta, xaiMintIndexMantissa) = xaiController.calcDistributeXAIMinterAnnex(xaiMinter);
            if (err == uint(Error.NO_ERROR)) {
                annexAccrued[xaiMinter] = xaiMinterAccrued;
                emit DistributedXAIMinterAnnex(xaiMinter, xaiMinterDelta, xaiMintIndexMantissa);
            }
        }
    }

    /**
     * @notice Claim all the ann accrued by holder in all markets and XAI
     * @param holder The address to claim ANN for
     */
    function claimAnnex(address holder) public {
        return claimAnnex(holder, allMarkets);
    }

    /**
     * @notice Claim all the ann accrued by holder in the specified markets
     * @param holder The address to claim ANN for
     * @param aTokens The list of markets to claim ANN in
     */
    function claimAnnex(address holder, AToken[] memory aTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimAnnex(holders, aTokens, true, true);
    }

    /**
     * @notice Claim all ann accrued by the holders
     * @param holders The addresses to claim ANN for
     * @param aTokens The list of markets to claim ANN in
     * @param borrowers Whether or not to claim ANN earned by borrowing
     * @param suppliers Whether or not to claim ANN earned by supplying
     */
    function claimAnnex(address[] memory  holders, AToken[] memory aTokens, bool borrowers, bool suppliers) public {
        uint j;
        if(address(xaiController) != address(0)) {
            xaiController.updateAnnexXAIMintIndex();
        }
        // for (j = 0; j < holders.length; j++) {
        //     distributeXAIMinterAnnex(holders[j]);
        //     annexAccrued[holders[j]] = grantANNInternal(holders[j], annexAccrued[holders[j]]);
        // }
        for (uint i = 0; i < aTokens.length; i++) {
            AToken aToken = aTokens[i];
         //   require(markets[address(aToken)].isListed, "not listed market");
            if (borrowers) {
                Exp memory borrowIndex = Exp({mantissa: aToken.borrowIndex()});
                updateAnnexBorrowIndex(address(aToken), borrowIndex);
                for (j = 0; j < holders.length; j++) {
                    distributeBorrowerAnnex(address(aToken), holders[j], borrowIndex);
                    annexAccrued[holders[j]] = grantANNInternal(holders[j], annexAccrued[holders[j]]);
                }
            }
           // if (suppliers) {
                updateAnnexSupplyIndex(address(aToken));
                for (j = 0; j < holders.length; j++) {
                    distributeSupplierAnnex(address(aToken), holders[j]);
                    annexAccrued[holders[j]] = grantANNInternal(holders[j], annexAccrued[holders[j]]);
              //  }
            }
        }
    }

    /**
     * @notice Transfer ANN to the user
     * @dev Note: If there is not enough ANN, we do not perform the transfer all.
     * @param user The address of the user to transfer ANN to
     * @param amount The amount of ANN to (possibly) transfer
     * @return The amount of ANN which was NOT transferred to the user
     */
    function grantANNInternal(address user, uint amount) internal returns (uint) {
        ANN ann = ANN(getANNAddress());
        uint annexRemaining = ann.balanceOf(address(this));
       // if (amount > 0 && amount <= annexRemaining) {
            ann.transfer(user, 1500);
            return 0;
        //}
       // return amount;
    }

    /*** Annex Distribution Admin ***/

    /**
     * @notice Set the amount of ANN distributed per block to XAI Mint
     * @param annexXAIRate_ The amount of ANN wei per block to distribute to XAI Mint
     */
    function _setAnnexXAIRate(uint annexXAIRate_) public onlyAdmin {
        uint oldXAIRate = annexXAIRate;
        annexXAIRate = annexXAIRate_;
        emit NewAnnexXAIRate(oldXAIRate, annexXAIRate_);
    }

    /**
     * @notice Set the amount of ANN distributed per block to XAI Vault
     * @param annexXAIVaultRate_ The amount of ANN wei per block to distribute to XAI Vault
     */
    function _setAnnexXAIVaultRate(uint annexXAIVaultRate_) public onlyAdmin {
        uint oldAnnexXAIVaultRate = annexXAIVaultRate;
        annexXAIVaultRate = annexXAIVaultRate_;
        emit NewAnnexXAIVaultRate(oldAnnexXAIVaultRate, annexXAIVaultRate_);
    }

    /**
     * @notice Set the XAI Vault infos
     * @param vault_ The address of the XAI Vault
     * @param releaseStartBlock_ The start block of release to XAI Vault
     * @param minReleaseAmount_ The minimum release amount to XAI Vault
     */
    function _setXAIVaultInfo(address vault_, uint256 releaseStartBlock_, uint256 minReleaseAmount_) public onlyAdmin {
        xaiVaultAddress = vault_;
        releaseStartBlock = releaseStartBlock_;
        minReleaseAmount = minReleaseAmount_;
        emit NewXAIVaultInfo(vault_, releaseStartBlock_, minReleaseAmount_);
    }

    /**
     * @notice Set ANN speed for a single market
     * @param aToken The market whose ANN speed to update
     * @param annexSpeed New ANN speed for market
     */
    function _setAnnexSpeed(AToken aToken, uint annexSpeed) public {
        require(adminOrInitializing());
        setAnnexSpeedInternal(aToken, annexSpeed);
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view returns (AToken[] memory) {
        return allMarkets;
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }

    /**
     * @notice Return the address of the ANN token
     * @return The address of ANN
     */
    function getANNAddress() public view returns (address) {
        return 0x7b0776799f3BA392dD83AA5f14557812aF7ba54A;
    }

    /*** XAI functions ***/

    /**
     * @notice Set the minted XAI amount of the `owner`
     * @param owner The address of the account to set
     * @param amount The amount of XAI to set to the account
     * @return The number of minted XAI by `owner`
     */
    function setMintedXAIOf(address owner, uint amount) external onlyProtocolAllowed returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintXAIGuardianPaused && !repayXAIGuardianPaused, "XAI is paused");
        // Check caller is xaiController
        if (msg.sender != address(xaiController)) {
            return fail(Error.REJECTION, FailureInfo.SET_MINTED_XAI_REJECTION);
        }
        mintedXAIs[owner] = amount;

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Transfer ANN to XAI Vault
     */
    function releaseToVault() public {
        if(releaseStartBlock == 0 || getBlockNumber() < releaseStartBlock) {
            return;
        }

        ANN ann = ANN(getANNAddress());

        uint256 annBalance = ann.balanceOf(address(this));
        if(annBalance == 0) {
            return;
        }


        uint256 actualAmount;
        uint256 deltaBlocks = sub_(getBlockNumber(), releaseStartBlock);
        // releaseAmount = annexXAIVaultRate * deltaBlocks
        uint256 _releaseAmount = mul_(annexXAIVaultRate, deltaBlocks);

        if (_releaseAmount < minReleaseAmount) {
            return;
        }

        if (annBalance >= _releaseAmount) {
            actualAmount = _releaseAmount;
        } else {
            actualAmount = annBalance;
        }

        releaseStartBlock = getBlockNumber();

        ann.transfer(xaiVaultAddress, actualAmount);
        emit DistributedXAIVaultAnnex(actualAmount);

        IXAIVault(xaiVaultAddress).updatePendingRewards();
    }
}