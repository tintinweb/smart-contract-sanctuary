/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/borrower/feed/navfeed.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.7.6;

////// lib/tinlake-auth/src/auth.sol
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
/* pragma solidity >=0.5.15; */

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

////// lib/tinlake-math/src/math.sol
// Copyright (C) 2018 Rain <[email protected]>
/* pragma solidity >=0.5.15; */

contract Math {
    uint256 constant ONE = 10 ** 27;

    function safeAdd(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }

    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    function safeDiv(uint x, uint y) public pure returns (uint z) {
        z = x / y;
    }

    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint x, uint y) public pure returns (uint z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }


}

////// src/borrower/feed/discounting.sol
/* pragma solidity >=0.7.6; */

/* import "tinlake-math/math.sol"; */

// contract without a state which defines the relevant formulars for the navfeed
contract Discounting is Math {

    function calcDiscount(uint discountRate, uint fv, uint normalizedBlockTimestamp, uint maturityDate_) public pure returns (uint result) {
        return rdiv(fv, rpow(discountRate, safeSub(maturityDate_, normalizedBlockTimestamp), ONE));
    }

    // calculate the future value based on the amount, maturityDate interestRate and recoveryRate
    function calcFutureValue(uint loanInterestRate, uint amount, uint maturityDate_, uint recoveryRatePD_) public view returns(uint) {
        uint nnow = uniqueDayTimestamp(block.timestamp);
        uint timeRemaining = 0;
        if (maturityDate_ > nnow) {
            timeRemaining = safeSub(maturityDate_, nnow);
        }

        return rmul(rmul(rpow(loanInterestRate, timeRemaining, ONE), amount), recoveryRatePD_);
    }
    function secureSub(uint x, uint y) public pure returns(uint) {
        if(y > x) {
            return 0;
        }
        return safeSub(x, y);
    }

    // normalizes a timestamp to round down to the nearest midnight (UTC)
    function uniqueDayTimestamp(uint timestamp) public pure returns (uint) {
        return (1 days) * (timestamp/(1 days));
    }

    function rpow(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                let xx := mul(x, x)
                if iszero(eq(div(xx, x), x)) { revert(0,0) }
                let xxRound := add(xx, half)
                if lt(xxRound, xx) { revert(0,0) }
                x := div(xxRound, base)
                if mod(n,2) {
                    let zx := mul(z, x)
                    if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                    let zxRound := add(zx, half)
                    if lt(zxRound, zx) { revert(0,0) }
                    z := div(zxRound, base)
                }
            }
            }
        }
    }
}

////// src/borrower/feed/navfeed.sol
/* pragma solidity >=0.7.6; */

/* import "tinlake-auth/auth.sol"; */
/* import { Discounting } from "./discounting.sol"; */

interface ShelfLike_1 {
    function shelf(uint loan) external view returns (address registry, uint tokenId);
    function nftlookup(bytes32 nftID) external returns (uint loan);
    function loanCount() external view returns (uint);
}

interface PileLike_1 {
    function setRate(uint loan, uint rate) external;
    function debt(uint loan) external view returns (uint);
    function pie(uint loan) external returns (uint);
    function changeRate(uint loan, uint newRate) external;
    function loanRates(uint loan) external view returns (uint);
    function file(bytes32, uint, uint) external;
    function rates(uint rate) external view returns (uint, uint, uint ,uint48, uint);
    function total() external view returns (uint);
    function rateDebt(uint rate) external view returns (uint);
}

// The NAV Feed contract calculates the Net Asset Value of a Tinlake pool.
// NAV is computed as the sum of all discounted future values (fv) of ongoing loans (debt > 0) in the pool.
// The applied discountRate is dependant on the maturity data of the underlying collateral.
// The discount decreases with the maturity date approaching.
// To optimize the NAV calculation, the NAV is calculated as the change in discounted future values since the calculation.
// When loans are overdue, they are locked at their fv on the maturity date.
// They can then be written off, using the public writeoff method based on
// the default writeoff schedule, or using the override writeoff method.
contract NAVFeed is Auth, Discounting {
    PileLike_1    public pile;
    ShelfLike_1   public shelf;

    struct NFTDetails {
        uint128 nftValues;
        uint128 futureValue;
        uint128 maturityDate;
        uint128 risk;
    }

    struct RiskGroup {
        // denominated in (10^27)
        uint128 ceilingRatio;
        // denominated in (10^27)
        uint128 thresholdRatio;
        // denominated in (10^27)
        uint128 recoveryRatePD;
    }

    struct LoanDetails {
        uint128 borrowed;
        // only auth calls can move loan into different writeOff group
        bool authWriteOff;
    }

    struct WriteOffGroup {
        // denominated in (10^27)
        uint128 percentage;
        // amount of days after the maturity days that the writeoff group can be applied by default
        uint128 overdueDays;
    }

    // nft => details
    mapping (bytes32 => NFTDetails) public details;
    // risk => riskGroup
    mapping (uint => RiskGroup) public riskGroup;
    // loan => details
    mapping(uint => LoanDetails) public loanDetails;
    // timestamp => bucket
    mapping (uint => uint)      public buckets;


    WriteOffGroup[] public writeOffGroups;

    // Write-off groups will be added as rate groups to the pile with their index
    // in the writeOffGroups array + this number
    uint public constant WRITEOFF_RATE_GROUP_START = 1000;

    // Discount rate applied on every asset's fv depending on its maturityDate.
    // The discount decreases with the maturityDate approaching.
    // denominated in (10^27)
    uint public discountRate;

    // latestNAV is calculated in case of borrows & repayments between epoch executions.
    // It decreases/increases the NAV by the repaid/borrowed amount without running the NAV calculation routine.
    // This is required for more accurate Senior & JuniorAssetValue estimations between epochs
    uint public latestNAV;
    uint public latestDiscount;
    uint public lastNAVUpdate;

    // overdue loans are loans which passed the maturity date but are not written-off
    uint public overdueLoans;

    // events
    event Depend(bytes32 indexed name, address addr);
    event File(bytes32 indexed name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_);
    event Update(bytes32 indexed nftID, uint value);
    event Update(bytes32 indexed nftID, uint value, uint risk);
    event File(bytes32 indexed name, uint risk_, uint thresholdRatio_, uint ceilingRatio_,
        uint rate_, uint recoveryRatePD_);
    event File(bytes32 indexed name, bytes32 nftID_, uint maturityDate_);
    event File(bytes32 indexed name, uint value);
    event File(bytes32 indexed name, uint rate_, uint writeOffPercentage_, uint overdueDays_);
    event WriteOff(uint indexed loan, uint indexed writeOffGroupsIndex, bool override_);

    // getter functions
    function maturityDate(bytes32 nft_)     public view returns(uint){ return uint(details[nft_].maturityDate);}
    function risk(bytes32 nft_)             public view returns(uint){ return uint(details[nft_].risk);}
    function nftValues(bytes32 nft_)        public view returns(uint){ return uint(details[nft_].nftValues);}
    function futureValue(bytes32 nft_)      public view returns(uint){ return uint(details[nft_].futureValue);}
    function ceilingRatio(uint riskID)      public view returns(uint){ return uint(riskGroup[riskID].ceilingRatio);}
    function thresholdRatio(uint riskID)    public view returns(uint){ return uint(riskGroup[riskID].thresholdRatio);}
    function recoveryRatePD(uint riskID)    public view returns(uint){ return uint(riskGroup[riskID].recoveryRatePD);}
    function borrowed(uint loan)            public view returns(uint) {return uint(loanDetails[loan].borrowed);}

    constructor () {
        wards[msg.sender] = 1;
        lastNAVUpdate = uniqueDayTimestamp(block.timestamp);
        emit Rely(msg.sender);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }
    
    // returns the ceiling of a loan
    // the ceiling defines the maximum amount which can be borrowed
    function ceiling(uint loan) public virtual view returns (uint) {
        bytes32 nftID_ = nftID(loan);
        uint initialCeiling = rmul(nftValues(nftID_), ceilingRatio(risk(nftID_)));

        if (borrowed(loan) > initialCeiling) {
            return 0;
        }

        return safeSub(initialCeiling, borrowed(loan));
    }

    // --- Administration ---
    function depend(bytes32 contractName, address addr) external auth {
        if (contractName == "pile") {pile = PileLike_1(addr);}
        else if (contractName == "shelf") { shelf = ShelfLike_1(addr); }
        else revert();
        emit Depend(contractName, addr);
    }

    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) public auth  {
        if(name == "riskGroup") {
            file("riskGroupNFT", risk_, thresholdRatio_, ceilingRatio_, rate_);
            riskGroup[risk_].recoveryRatePD= toUint128(recoveryRatePD_);
            emit File(name, risk_, thresholdRatio_, ceilingRatio_, rate_, recoveryRatePD_);

        } else { revert ("unknown name");}
    }

    function file(bytes32 name, bytes32 nftID_, uint maturityDate_) public auth {
        // maturity date only can be changed when there is no debt on the collateral -> futureValue == 0
        if (name == "maturityDate") {
            require((futureValue(nftID_) == 0), "can-not-change-maturityDate-outstanding-debt");
            details[nftID_].maturityDate = toUint128(uniqueDayTimestamp(maturityDate_));
            emit File(name, nftID_, maturityDate_);

        } else { revert("unknown config parameter");}
    }

    function file(bytes32 name, uint value) public auth {
        if (name == "discountRate") {
            uint oldDiscountRate = discountRate;
            discountRate = value;
            // the nav needs to be re-calculated based on the new discount rate
            // no need to recalculate it if initialized the first time
            if(oldDiscountRate != 0) {
                reCalcNAV();
            }
            emit File(name, value);

        } else { revert("unknown config parameter");}
    }

    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_) public auth {
        if(name == "riskGroupNFT") {
            require(ceilingRatio(risk_) == 0, "risk-group-in-usage");
            riskGroup[risk_].thresholdRatio = toUint128(thresholdRatio_);
            riskGroup[risk_].ceilingRatio = toUint128(ceilingRatio_);

            // set interestRate for risk group
            pile.file("rate", risk_, rate_);
            emit File(name, risk_, thresholdRatio_, ceilingRatio_, rate_);

        } else { revert ("unknown name");}
    }

    function file(bytes32 name, uint rate_, uint writeOffPercentage_, uint overdueDays_) public auth {
        if(name == "writeOffGroup") {
            uint index = writeOffGroups.length;
            writeOffGroups.push(WriteOffGroup(toUint128(writeOffPercentage_), toUint128(overdueDays_)));
            pile.file("rate", safeAdd(WRITEOFF_RATE_GROUP_START, index), rate_);
            emit File(name, rate_, writeOffPercentage_, overdueDays_);
        } else { revert ("unknown name");}
    }

    // --- Actions ---
    function borrow(uint loan, uint amount) external virtual auth returns(uint navIncrease) {
        uint nnow = uniqueDayTimestamp(block.timestamp);
        bytes32 nftID_ = nftID(loan);
        uint maturityDate_ = maturityDate(nftID_);

        require(ceiling(loan) >= amount, "borrow-amount-too-high");
        require(maturityDate_ > nnow, "maturity-date-is-not-in-the-future");

        if(nnow > lastNAVUpdate) {
            calcUpdateNAV();
        }

        // calculate amount including fixed fee if applicatable
        (, , uint loanInterestRate, , uint fixedRate) = pile.rates(pile.loanRates(loan));
        uint amountIncludingFixed = safeAdd(amount, rmul(amount, fixedRate));

        // calculate future value FV
        uint fv = calcFutureValue(loanInterestRate, amountIncludingFixed, maturityDate_, recoveryRatePD(risk(nftID_)));
        details[nftID_].futureValue = toUint128(safeAdd(futureValue(nftID_), fv));

        // add future value to the bucket of assets with the same maturity date
        buckets[maturityDate_] = safeAdd(buckets[maturityDate_], fv);

        // increase borrowed amount for future ceiling computations
        loanDetails[loan].borrowed = toUint128(safeAdd(borrowed(loan), amount));

        // return increase NAV amount
        navIncrease = calcDiscount(discountRate, fv, nnow, maturityDate_);

        latestDiscount = safeAdd(latestDiscount, navIncrease);
        latestNAV = safeAdd(latestNAV, navIncrease);
        return navIncrease;
    }

    function repay(uint loan, uint amount) external virtual auth {
        uint nnow = uniqueDayTimestamp(block.timestamp);
        if (nnow > lastNAVUpdate) {
            calcUpdateNAV();
        }

        // In case of successful repayment the latestNAV is decreased by the repaid amount
        bytes32 nftID_ = nftID(loan);
        uint maturityDate_ = maturityDate(nftID_);

        // case 1: repayment of a written-off loan
        if (isLoanWrittenOff(loan)) {
            // update nav with write-off decrease
            latestNAV = secureSub(latestNAV, rmul(amount,
                toUint128(writeOffGroups[pile.loanRates(loan)-WRITEOFF_RATE_GROUP_START].percentage)));
            return;
        }

        uint debt = safeSub(pile.debt(loan), amount);
        uint preFV = futureValue(nftID_);
        // in case of partial repayment, compute the fv of the remaining debt and add to the according fv bucket
        uint fv = 0;
        uint fvDecrease = preFV;
        if (debt != 0) {
            (, ,uint loanInterestRate, ,) = pile.rates(pile.loanRates(loan));
            fv = calcFutureValue(loanInterestRate, debt, maturityDate_, recoveryRatePD(risk(nftID_)));
            if (preFV >= fv) {
                fvDecrease = safeSub(preFV, fv);
            } else {
                fvDecrease = 0;
            }
        }

        details[nftID_].futureValue = toUint128(fv);
        // case 2: repayment of a loan before or on maturity date
        if (maturityDate_ >= nnow) {
            // remove future value decrease from bucket
            buckets[maturityDate_] = safeSub(buckets[maturityDate_], fvDecrease);
            uint discountDecrease = calcDiscount(discountRate, fvDecrease, nnow, maturityDate_);
            latestDiscount = secureSub(latestDiscount, discountDecrease);
            latestNAV = secureSub(latestNAV, discountDecrease);
        } else {
            // case 3: repayment of an overdue loan
            overdueLoans = safeSub(overdueLoans, fvDecrease);
            latestNAV = secureSub(latestNAV, fvDecrease);
        }
    }

    function borrowEvent(uint loan, uint) public virtual auth {
        uint risk_ = risk(nftID(loan));

        // when issued every loan has per default interest rate of risk group 0.
        // correct interest rate has to be set on first borrow event
        if (pile.loanRates(loan) != risk_) {
            // set loan interest rate to the one of the correct risk group
            pile.setRate(loan, risk_);
        }
    }

    function repayEvent(uint loan, uint amount) public virtual auth {}
    function lockEvent(uint loan) public virtual auth {}
    function unlockEvent(uint loan) public virtual auth {}

    function writeOff(uint loan) public {
        require(!loanDetails[loan].authWriteOff, "only-auth-write-off");

        bytes32 nftID_ = nftID(loan);
        uint maturityDate_ = maturityDate(nftID_);
        require(maturityDate_ > 0 && loan < shelf.loanCount(), "loan-does-not-exist");

        // can not write-off healthy loans
        uint nnow = uniqueDayTimestamp(block.timestamp);
        require(maturityDate_ < nnow, "maturity-date-in-the-future");
        // check the writeoff group based on the amount of days overdue
        uint writeOffGroupIndex_ = currentValidWriteOffGroup(loan);

        if (writeOffGroupIndex_ < type(uint128).max && pile.loanRates(loan) != WRITEOFF_RATE_GROUP_START + writeOffGroupIndex_) {
            _writeOff(loan, writeOffGroupIndex_, nftID_, maturityDate_);
            emit WriteOff(loan, writeOffGroupIndex_, false);
        }
    }

    function overrideWriteOff(uint loan, uint writeOffGroupIndex_) public auth {
        // can not write-off healthy loans
        bytes32 nftID_ = nftID(loan);
        uint maturityDate_ = maturityDate(nftID_);
        uint nnow = uniqueDayTimestamp(block.timestamp);
        require(maturityDate_ < nnow, "maturity-date-in-the-future");

        if (loanDetails[loan].authWriteOff == false) {
            loanDetails[loan].authWriteOff = true;
        }
        _writeOff(loan, writeOffGroupIndex_, nftID_, maturityDate_);
        emit WriteOff(loan, writeOffGroupIndex_, true);
    }

    function _writeOff(uint loan, uint writeOffGroupIndex_, bytes32 nftID_, uint maturityDate_) internal {
        uint nnow = uniqueDayTimestamp(block.timestamp);
        // Ensure we have an up to date NAV
        if(nnow > lastNAVUpdate) {
            calcUpdateNAV();
        }
        
        uint latestNAV_ = latestNAV;

        // first time written-off
        if (isLoanWrittenOff(loan) == false) {
            uint fv = futureValue(nftID_);
            if (uniqueDayTimestamp(lastNAVUpdate) > maturityDate_) {
                // write off after the maturity date
                overdueLoans = secureSub(overdueLoans, fv);
                latestNAV_ = secureSub(latestNAV_, fv);

            } else {
                // write off before or on the maturity date
                buckets[maturityDate_] = safeSub(buckets[maturityDate_], fv);
                uint pv = rmul(fv, rpow(discountRate, safeSub(uniqueDayTimestamp(maturityDate_), nnow), ONE));
                latestDiscount = secureSub(latestDiscount, pv);
                latestNAV_ = secureSub(latestNAV_, pv);
            }
        }

        pile.changeRate(loan, WRITEOFF_RATE_GROUP_START + writeOffGroupIndex_);
        latestNAV = safeAdd(latestNAV_, rmul(pile.debt(loan), writeOffGroups[writeOffGroupIndex_].percentage));
    }

    function isLoanWrittenOff(uint loan) public view returns(bool) {
        return pile.loanRates(loan) >= WRITEOFF_RATE_GROUP_START;
    }

    // --- NAV calculation ---
    function currentNAV() public view returns(uint) {
        (uint totalDiscount, uint overdue, uint writeOffs) = currentPVs();
        return safeAdd(totalDiscount, safeAdd(overdue, writeOffs));
    }

    function currentPVs() public view returns(uint totalDiscount, uint overdue, uint writeOffs) {
        if (latestDiscount == 0) {
            // all loans are overdue or writtenOff
            return (0, overdueLoans, currentWriteOffs());
        }

        uint errPV = 0;
        uint nnow = uniqueDayTimestamp(block.timestamp);

        // find all new overdue loans since the last update
        // calculate the discount of the overdue loans which is needed
        // for the total discount calculation
        for(uint i = lastNAVUpdate; i < nnow; i = i + 1 days) {
            uint b = buckets[i];
            if (b != 0) {
                errPV = safeAdd(errPV, rmul(b, rpow(discountRate, safeSub(nnow, i), ONE)));
                overdue = safeAdd(overdue, b);
            }
        }

        return
        (
            // calculate current totalDiscount based on the previous totalDiscount (optimized calculation)
            // the overdue loans are incorrectly in this new result with their current PV and need to be removed
            secureSub(rmul(latestDiscount, rpow(discountRate, safeSub(nnow, lastNAVUpdate), ONE)), errPV),
            // current overdue loans not written off
            safeAdd(overdueLoans, overdue),
            // current write-offs loans
            currentWriteOffs()
        );
    }

    function currentWriteOffs() public view returns(uint) {
        uint sum = 0;
        for (uint i = 0; i < writeOffGroups.length; i++) {
            // multiply writeOffGroupDebt with the writeOff rate
            sum = safeAdd(sum, rmul(pile.rateDebt(WRITEOFF_RATE_GROUP_START + i), uint(writeOffGroups[i].percentage)));
        }
        return sum;
    }

    function calcUpdateNAV() public returns(uint) {
        (uint totalDiscount, uint overdue, uint writeOffs) = currentPVs();

        overdueLoans = overdue;
        latestDiscount = totalDiscount;

        latestNAV = safeAdd(safeAdd(totalDiscount, overdue), writeOffs);
        lastNAVUpdate = uniqueDayTimestamp(block.timestamp);
        return latestNAV;
    }


    // re-calculates the nav in a non-optimized way
    // the method is not updating the NAV to latest block.timestamp
    function reCalcNAV() public returns (uint) {
        uint latestDiscount_ = reCalcTotalDiscount();

        latestNAV = safeAdd(latestDiscount_, safeSub(latestNAV, latestDiscount));
        latestDiscount = latestDiscount_;
        return latestNAV;
    }

    // re-calculates the totalDiscount in a non-optimized way based on lastNAVUpdate
    function reCalcTotalDiscount() public view returns(uint) {
        uint latestDiscount_ = 0;

        for (uint loanID = 1; loanID < shelf.loanCount(); loanID++) {
            bytes32 nftID_ = nftID(loanID);
            uint maturityDate_ = maturityDate(nftID_);

            if (maturityDate_ < lastNAVUpdate) {
                continue;
            }

            latestDiscount_= safeAdd(latestDiscount_, calcDiscount(discountRate,
                futureValue(nftID_), lastNAVUpdate, maturityDate_));
        }
        return latestDiscount_;
    }

    function update(bytes32 nftID_,  uint value) public auth {
        // switch of collateral risk group results in new: ceiling, threshold for existing loan
        details[nftID_].nftValues = toUint128(value);
        emit Update(nftID_, value);
    }

    function update(bytes32 nftID_, uint value, uint risk_) public auth {
        uint nnow = uniqueDayTimestamp(block.timestamp);
        details[nftID_].nftValues  = toUint128(value);

        // no change in risk group
        if (risk_ == risk(nftID_)) {
            return;
        }

        // nfts can only be added to risk groups that are part of the score card
        require(thresholdRatio(risk_) != 0, "risk group not defined in contract");
        details[nftID_].risk = toUint128(risk_);

        // update nav -> latestNAVUpdate = now
        if(nnow > lastNAVUpdate) {
            calcUpdateNAV();
        }

        // switch of collateral risk group results in new: ceiling, threshold and interest rate for existing loan
        // change to new rate interestRate immediately in pile if loan debt exists
        uint loan = shelf.nftlookup(nftID_);
        if (pile.pie(loan) != 0) {
            pile.changeRate(loan, risk_);
        }

        // no currencyAmount borrowed yet
        if (futureValue(nftID_) == 0) {
            return;
        }


        uint maturityDate_ = maturityDate(nftID_);

        // Changing the risk group of an nft, might lead to a new interest rate for the dependant loan.
        // New interest rate leads to a future value.
        // recalculation required
        uint fvDecrease = futureValue(nftID_);
        uint navDecrease = calcDiscount(discountRate, fvDecrease, nnow, maturityDate_);
        buckets[maturityDate_] = safeSub(buckets[maturityDate_], fvDecrease);
        latestDiscount = safeSub(latestDiscount, navDecrease);
        latestNAV = safeSub(latestNAV, navDecrease);

        // update latest NAV
        // update latest Discount
        (, ,uint loanInterestRate, ,) = pile.rates(pile.loanRates(loan));
        details[nftID_].futureValue = toUint128(calcFutureValue(loanInterestRate, pile.debt(loan),
            maturityDate(nftID_), recoveryRatePD(risk(nftID_))));
        
        uint fvIncrease =  futureValue(nftID_);
        uint navIncrease = calcDiscount(discountRate, fvIncrease, nnow, maturityDate_);
        buckets[maturityDate_] = safeAdd(buckets[maturityDate_], fvIncrease);
        latestDiscount = safeAdd(latestDiscount, navIncrease);
        latestNAV = safeAdd(latestNAV, navIncrease);
        emit Update(nftID_, value, risk_);
    }

    // --- Utilities ---
    // returns the threshold of a loan
    // if the loan debt is above the loan threshold the NFT can be seized
    function threshold(uint loan) public view returns (uint) {
        bytes32 nftID_ = nftID(loan);
        return rmul(nftValues(nftID_), thresholdRatio(risk(nftID_)));
    }

    // returns a unique id based on the nft registry and tokenId
    // the nftID is used to set the risk group and value for nfts
    function nftID(address registry, uint tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(registry, tokenId));
    }

    // returns the nftID for the underlying collateral nft
    function nftID(uint loan) public view returns (bytes32) {
        (address registry, uint tokenId) = shelf.shelf(loan);
        return nftID(registry, tokenId);
    }

    // returns true if the present value of a loan is zero
    // true if all debt is repaid or debt is 100% written-off
    function zeroPV(uint loan) public view returns (bool) {
        if (pile.debt(loan) == 0) {
            return true;
        }

        uint rate = pile.loanRates(loan);

        if(rate < WRITEOFF_RATE_GROUP_START) {
            return false;
        }

        return writeOffGroups[safeSub(rate, WRITEOFF_RATE_GROUP_START)].percentage == 0;
    }

    function currentValidWriteOffGroup(uint loan) public view returns (uint) {
        bytes32 nftID_ = nftID(loan);
        uint maturityDate_ = maturityDate(nftID_);
        uint nnow = uniqueDayTimestamp(block.timestamp);

        uint128 lastValidWriteOff = type(uint128).max;
        uint128 highestOverdueDays = 0;
        // it is not guaranteed that writeOff groups are sorted by overdue days
        for (uint128 i = 0; i < writeOffGroups.length; i++) {
            uint128 overdueDays = writeOffGroups[i].overdueDays;
            if (overdueDays >= highestOverdueDays && nnow >= maturityDate_ + overdueDays * 1 days) {
                lastValidWriteOff = i;
                highestOverdueDays = overdueDays;
            }
        }

        // returns type(uint128).max if no write-off group is valid for this loan
        return lastValidWriteOff;
    }
}