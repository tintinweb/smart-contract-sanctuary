pragma solidity ^0.4.24;

import "./Exponential.sol";
import "./LiquidationChecker.sol";

contract AlkemiRateModel is Exponential, LiquidationChecker {

    uint constant blocksPerYear = 2102400;

    address public owner;
    address public newOwner;
    
    string public contractName;

    modifier onlyOwner() {
        require(msg.sender == owner, "non-owner");
        _;
    }

    enum IRError {
        NO_ERROR,
        FAILED_TO_ADD_CASH_PLUS_BORROWS,
        FAILED_TO_GET_EXP,
        FAILED_TO_MUL_PRODUCT_TIMES_BORROW_RATE
    }

    event OwnerUpdate(address indexed owner, address indexed newOwner);
    event LiquidatorUpdate(address indexed owner, address indexed newLiquidator, address indexed oldLiquidator);
    
    Exp internal SpreadLow;
    Exp internal BreakPointLow;
    Exp internal ReserveLow;
    Exp internal ReserveMid;
    Exp internal SpreadMid;
    Exp internal BreakPointHigh;
    Exp internal ReserveHigh;
    ExpNegative internal SpreadHigh;
    
    Exp internal MinRateActual;
    Exp internal HealthyMinURActual;
    Exp internal HealthyMinRateActual;
    Exp internal MaxRateActual;
    Exp internal HealthyMaxURActual;
    Exp internal HealthyMaxRateActual;

    constructor(string memory _contractName,uint MinRate,uint HealthyMinUR,uint HealthyMinRate,uint HealthyMaxUR,uint HealthyMaxRate,uint MaxRate, address moneyMarket, address liquidator) LiquidationChecker(moneyMarket, liquidator) public {
        // Remember to enter percentage times 100. ex., if it is 2.50%, enter 250
        owner = msg.sender;
        contractName = _contractName;
        Exp memory  temp1;
        Exp memory temp2;
        Exp memory HunderedMantissa;
        Error err;
        
        (err,HunderedMantissa) = getExp(100,1);
        
        (err,MinRateActual) = getExp(MinRate,100);
        (err,HealthyMinURActual) = getExp(HealthyMinUR,100);
        (err,HealthyMinRateActual) = getExp(HealthyMinRate,100);
        (err,MaxRateActual) = getExp(MaxRate,100);
        (err,HealthyMaxURActual) = getExp(HealthyMaxUR,100);
        (err,HealthyMaxRateActual) = getExp(HealthyMaxRate,100);
        
        SpreadLow = MinRateActual;
        BreakPointLow = HealthyMinURActual;
        BreakPointHigh = HealthyMaxURActual;
        
        // ReserveLow = (HealthyMinRate-SpreadLow)/BreakPointLow;
        (err,temp1) = subExp(HealthyMinRateActual,SpreadLow);
        (err,ReserveLow) = divExp(temp1,BreakPointLow);
        
        // ReserveMid = (HealthyMaxRate-HealthyMinRate)/(HealthyMaxUR-HealthyMinUR);
        (err,temp1) = subExp(HealthyMaxRateActual,HealthyMinRateActual);
        (err,temp2) = subExp(HealthyMaxURActual,HealthyMinURActual);
        (err,ReserveMid) = divExp(temp1,temp2);
        
        // SpreadMid = HealthyMinRate - (ReserveMid * BreakPointLow);
        (err,temp1) = mulExp(ReserveMid,BreakPointLow);
        (err,SpreadMid) = subExp(HealthyMinRateActual,temp1);
        
        // ReserveHigh = (MaxRate - HealthyMaxRate) / (100 - HealthyMaxUR);
        (err,temp1) = subExp(MaxRateActual,HealthyMaxRateActual);
        (err,temp2) = subExp(HunderedMantissa,HealthyMaxURActual);
        (err,ReserveHigh) = divExp(temp1,temp2);
        
        // SpreadHigh = HealthyMaxRate - (ReserveHigh * BreakPointHigh);
        (err,temp2) = mulExp(ReserveHigh,BreakPointHigh);
        (err,SpreadHigh) = subExpNegative(HealthyMaxRateActual,temp2);
    }

    function changeRates(string memory _contractName,uint MinRate,uint HealthyMinUR,uint HealthyMinRate,uint HealthyMaxUR,uint HealthyMaxRate,uint MaxRate) public onlyOwner {
        // Remember to enter percentage times 100. ex., if it is 2.50%, enter 250
        contractName = _contractName;
        Exp memory  temp1;
        Exp memory temp2;
        Exp memory HunderedMantissa;
        Error err;
        
        (err,HunderedMantissa) = getExp(100,1);
        
        (err,MinRateActual) = getExp(MinRate,100);
        (err,HealthyMinURActual) = getExp(HealthyMinUR,100);
        (err,HealthyMinRateActual) = getExp(HealthyMinRate,100);
        (err,MaxRateActual) = getExp(MaxRate,100);
        (err,HealthyMaxURActual) = getExp(HealthyMaxUR,100);
        (err,HealthyMaxRateActual) = getExp(HealthyMaxRate,100);
        
        SpreadLow = MinRateActual;
        BreakPointLow = HealthyMinURActual;
        BreakPointHigh = HealthyMaxURActual;
        
        // ReserveLow = (HealthyMinRate-SpreadLow)/BreakPointLow;
        (err,temp1) = subExp(HealthyMinRateActual,SpreadLow);
        (err,ReserveLow) = divExp(temp1,BreakPointLow);
        
        // ReserveMid = (HealthyMaxRate-HealthyMinRate)/(HealthyMaxUR-HealthyMinUR);
        (err,temp1) = subExp(HealthyMaxRateActual,HealthyMinRateActual);
        (err,temp2) = subExp(HealthyMaxURActual,HealthyMinURActual);
        (err,ReserveMid) = divExp(temp1,temp2);
        
        // SpreadMid = HealthyMinRate - (ReserveMid * BreakPointLow);
        (err,temp1) = mulExp(ReserveMid,BreakPointLow);
        (err,SpreadMid) = subExp(HealthyMinRateActual,temp1);
        
        // ReserveHigh = (MaxRate - HealthyMaxRate) / (100 - HealthyMaxUR);
        (err,temp1) = subExp(MaxRateActual,HealthyMaxRateActual);
        (err,temp2) = subExp(HunderedMantissa,HealthyMaxURActual);
        (err,ReserveHigh) = divExp(temp1,temp2);
        
        // SpreadHigh = HealthyMaxRate - (ReserveHigh * BreakPointHigh);
        (err,temp2) = mulExp(ReserveHigh,BreakPointHigh);
        (err,SpreadHigh) = subExpNegative(HealthyMaxRateActual,temp2);
    }

    function transferOwnership(address newOwner_) external onlyOwner {
        require(newOwner_ != owner, "TransferOwnership: the same owner.");
        newOwner = newOwner_;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner, "AcceptOwnership: only new owner do this.");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

    function setLiquidator(address _liquidator) external onlyOwner {
        require(_liquidator != address(0), "setLiquidator: liquidator cannot be a zero address");
        require(liquidator != _liquidator, "setLiquidator: The old and new addresses cannot be the same");
        address oldLiquidator = liquidator;
        liquidator = _liquidator;
        emit LiquidatorUpdate(msg.sender, _liquidator, oldLiquidator);
    }

    /*
     * @dev Calculates the utilization rate (borrows / (cash + borrows)) as an Exp
     */
    function getUtilizationRate(uint cash, uint borrows) pure internal returns (IRError, Exp memory) {
        if (borrows == 0) {
            // Utilization rate is zero when there's no borrows
            return (IRError.NO_ERROR, Exp({mantissa: 0}));
        }

        (Error err0, uint cashPlusBorrows) = add(cash, borrows);
        if (err0 != Error.NO_ERROR) {
            return (IRError.FAILED_TO_ADD_CASH_PLUS_BORROWS, Exp({mantissa: 0}));
        }

        (Error err1, Exp memory utilizationRate) = getExp(borrows, cashPlusBorrows);
        if (err1 != Error.NO_ERROR) {
            return (IRError.FAILED_TO_GET_EXP, Exp({mantissa: 0}));
        }
        (err1,utilizationRate) = mulScalar(utilizationRate,100);

        return (IRError.NO_ERROR, utilizationRate);
    }
    
    /*
     * @dev Calculates the utilization and borrow rates for use by get{Supply,Borrow}Rate functions
     */
    function getUtilizationAndAnnualBorrowRate(uint cash, uint borrows) view internal returns (IRError, Exp memory, Exp memory) {
        (IRError err0, Exp memory utilizationRate) = getUtilizationRate(cash, borrows);
        if (err0 != IRError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}), Exp({mantissa: 0}));
        }

        /**
         *  Borrow Rate
         *  0 < UR < 20% :      SpreadLow + UR * ReserveLow
         *  20% <= UR <= 80% :  SpreadMid + UR * ReserveMid
         *  80% < UR :          SpreadHigh + UR * ReserveHigh
         */

        Error err;
        
        uint annualBorrowRateScaled;
        Exp memory tempScaled;
        Exp memory tempScaled2;
        
        if(utilizationRate.mantissa < BreakPointLow.mantissa) {
            (err, tempScaled) = mulExp(utilizationRate, ReserveLow);
            assert(err == Error.NO_ERROR);
            (err, tempScaled2) = addExp(tempScaled, SpreadLow);
            annualBorrowRateScaled = tempScaled2.mantissa;
            assert(err == Error.NO_ERROR);
        }
        else if (utilizationRate.mantissa > BreakPointHigh.mantissa) {
            (err, tempScaled) = mulExp(utilizationRate, ReserveHigh);
            assert(err == Error.NO_ERROR);
            (err, tempScaled2) = addExpNegative(tempScaled, SpreadHigh);
            annualBorrowRateScaled = tempScaled2.mantissa;
            assert(err == Error.NO_ERROR);
        }
        else if (utilizationRate.mantissa >= BreakPointLow.mantissa && utilizationRate.mantissa <= BreakPointHigh.mantissa) {
            (err, tempScaled) = mulExp(utilizationRate, ReserveMid);
            assert(err == Error.NO_ERROR);
            (err, tempScaled2) = addExp(tempScaled, SpreadMid);
            annualBorrowRateScaled = tempScaled2.mantissa;
            assert(err == Error.NO_ERROR);
        }

        return (IRError.NO_ERROR, utilizationRate, Exp({mantissa: annualBorrowRateScaled / 100}));
    }

    /**
      * @notice Gets the current supply interest rate based on the given asset, total cash and total borrows
      * @dev The return value should be scaled by 1e18, thus a return value of
      *      `(true, 1000000000000)` implies an interest rate of 0.000001 or 0.0001% *per block*.
      * @param _asset The asset to get the interest rate of
      * @param cash The total cash of the asset in the market
      * @param borrows The total borrows of the asset in the market
      * @return Success or failure and the supply interest rate per block scaled by 10e18
      */
    function getSupplyRate(address _asset, uint cash, uint borrows) public view returns (uint, uint) {
        _asset; // pragma ignore unused argument
        (IRError err0, Exp memory utilizationRate0, Exp memory annualBorrowRate) = getUtilizationAndAnnualBorrowRate(cash, borrows);
        if (err0 != IRError.NO_ERROR) {
            return (uint(err0), 0);
        }
         
         /**
         *  Supply Rate
         *  = BorrowRate * utilizationRate * (1 - SpreadLow)
         */
         Exp memory temp1;
         Error err1;
         Exp memory oneMinusSpreadBasisPoints;
         (err1,temp1) = getExp(100,1);
         assert(err1 == Error.NO_ERROR);
         (err1,oneMinusSpreadBasisPoints) = subExp(temp1,SpreadLow);

        // mulScalar only overflows when product is greater than or equal to 2^256.
        // utilization rate's mantissa is a number between [0e18,1e18]. That means that
        // utilizationRate1 is a value between [0e18,8.5e21]. This is strictly less than 2^256.
        assert(err1 == Error.NO_ERROR);

        // Next multiply this product times the borrow rate
        (err1, temp1) = mulExp(utilizationRate0, annualBorrowRate);
        // If the product of the mantissas for mulExp are both less than 2^256,
        // then this operation will never fail. TODO: Verify.
        // We know that borrow rate is in the interval [0, 2.25e17] from above.
        // We know that utilizationRate1 is in the interval [0, 9e21] from directly above.
        // As such, the multiplication is in the interval of [0, 2.025e39]. This is strictly
        // less than 2^256 (which is about 10e77).
        assert(err1 == Error.NO_ERROR);
        
        (err1, temp1) = mulExp(temp1, oneMinusSpreadBasisPoints);
        assert(err1 == Error.NO_ERROR);

        // And then divide down by the spread's denominator (basis points divisor)
        // as well as by blocks per year.
        (Error err4, Exp memory supplyRate) = divScalar(temp1, 10000 * blocksPerYear); // basis points * blocks per year
        // divScalar only fails when divisor is zero. This is clearly not the case.
        assert(err4 == Error.NO_ERROR);

        return (uint(IRError.NO_ERROR), supplyRate.mantissa);
    }

    /**
      * @notice Gets the current borrow interest rate based on the given asset, total cash and total borrows
      * @dev The return value should be scaled by 1e18, thus a return value of
      *      `(true, 1000000000000)` implies an interest rate of 0.000001 or 0.0001% *per block*.
      * @param asset The asset to get the interest rate of
      * @param cash The total cash of the asset in the market
      * @param borrows The total borrows of the asset in the market
      * @return Success or failure and the borrow interest rate per block scaled by 10e18
      */
    function getBorrowRate(address asset, uint cash, uint borrows) public view returns (uint, uint) {
        asset; // pragma ignore unused argument

        (IRError err0, , Exp memory annualBorrowRate) = getUtilizationAndAnnualBorrowRate(cash, borrows);
        if (err0 != IRError.NO_ERROR) {
            return (uint(err0), 0);
        }

        // And then divide down by blocks per year.
        (Error err1, Exp memory borrowRate) = divScalar(annualBorrowRate, blocksPerYear); // basis points * blocks per year
        // divScalar only fails when divisor is zero. This is clearly not the case.
        assert(err1 == Error.NO_ERROR);

        // Note: mantissa is the rate scaled 1e18, which matches the expected result
        return (uint(IRError.NO_ERROR), borrowRate.mantissa);
    }
}