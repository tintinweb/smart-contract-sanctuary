/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/borrower/feed/navfeed.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.6.12;
pragma experimental ABIEncoderV2;

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

////// lib/tinlake-math/src/interest.sol
// Copyright (C) 2018 Rain <[email protected]> and Centrifuge, referencing MakerDAO dss => https://github.com/makerdao/dss/blob/master/src/pot.sol
/* pragma solidity >=0.5.15; */

/* import "./math.sol"; */

contract Interest is Math {
    // @notice This function provides compounding in seconds
    // @param chi Accumulated interest rate over time
    // @param ratePerSecond Interest rate accumulation per second in RAD(10ˆ27)
    // @param lastUpdated When the interest rate was last updated
    // @param pie Total sum of all amounts accumulating under one interest rate, divided by that rate
    // @return The new accumulated rate, as well as the difference between the debt calculated with the old and new accumulated rates.
    function compounding(uint chi, uint ratePerSecond, uint lastUpdated, uint pie) public view returns (uint, uint) {
        require(block.timestamp >= lastUpdated, "tinlake-math/invalid-timestamp");
        require(chi != 0);
        // instead of a interestBearingAmount we use a accumulated interest rate index (chi)
        uint updatedChi = _chargeInterest(chi ,ratePerSecond, lastUpdated, block.timestamp);
        return (updatedChi, safeSub(rmul(updatedChi, pie), rmul(chi, pie)));
    }

    // @notice This function charge interest on a interestBearingAmount
    // @param interestBearingAmount is the interest bearing amount
    // @param ratePerSecond Interest rate accumulation per second in RAD(10ˆ27)
    // @param lastUpdated last time the interest has been charged
    // @return interestBearingAmount + interest
    function chargeInterest(uint interestBearingAmount, uint ratePerSecond, uint lastUpdated) public view returns (uint) {
        if (block.timestamp >= lastUpdated) {
            interestBearingAmount = _chargeInterest(interestBearingAmount, ratePerSecond, lastUpdated, block.timestamp);
        }
        return interestBearingAmount;
    }

    function _chargeInterest(uint interestBearingAmount, uint ratePerSecond, uint lastUpdated, uint current) internal pure returns (uint) {
        return rmul(rpow(ratePerSecond, current - lastUpdated, ONE), interestBearingAmount);
    }


    // convert pie to debt/savings amount
    function toAmount(uint chi, uint pie) public pure returns (uint) {
        return rmul(pie, chi);
    }

    // convert debt/savings amount to pie
    function toPie(uint chi, uint amount) public pure returns (uint) {
        return rdivup(amount, chi);
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

////// src/borrower/feed/buckets.sol
/* pragma solidity >=0.5.15; */

// the buckets contract stores values in a map using a timestamp as a key
// each value store a pointer the next value in a linked list
// to improve performance/gas efficiency while iterating over all values in a timespan
contract Buckets {
    // abstract contract
    constructor() internal {}

    struct Bucket {
        uint value;
        uint next;
    }

    // timestamp => bucket
    mapping (uint => Bucket) public buckets;

    // pointer to the first bucket and last bucket
    uint public firstBucket;
    uint public lastBucket;

    uint constant public NullDate = 1;

    function addBucket(uint timestamp, uint value) internal {
        buckets[timestamp].value = value;

        if (firstBucket == 0) {
            firstBucket = timestamp;
            buckets[timestamp].next = NullDate;
            lastBucket = firstBucket;
            return;
        }

        // new bucket before first one
        if (timestamp < firstBucket) {
            buckets[timestamp].next = firstBucket;
            firstBucket = timestamp;
            return;
        }

        // find predecessor bucket by going back in time
        // instead of iterating the linked list from the first bucket
        // assuming its more gas efficient to iterate over time instead of iterating the list from the beginning
        // not true if buckets are only sparsely populated over long periods of time
        uint prev = timestamp;
        while(buckets[prev].next == 0) {prev = prev - 1 days;}

        if (buckets[prev].next == NullDate) {
            lastBucket = timestamp;
        }
        buckets[timestamp].next = buckets[prev].next;
        buckets[prev].next = timestamp;
    }

    function removeBucket(uint timestamp) internal {
        buckets[timestamp].value = 0;
        _removeBucket(timestamp);
        buckets[timestamp].next = 0;
    }

    function _removeBucket(uint timestamp) internal {
        if(firstBucket == lastBucket) {
            lastBucket = 0;
            firstBucket = 0;
            return;
        }

        if (timestamp != firstBucket) {
            uint prev = timestamp - 1 days;
            // assuming its more gas efficient to iterate over time instead of iterating the list from the beginning
            // not true if buckets are only sparsely populated over long periods of time
            while(buckets[prev].next != timestamp) {prev = prev - 1 days;}
            buckets[prev].next = buckets[timestamp].next;
            if(timestamp == lastBucket) {
                lastBucket = prev;
            }
            return;
        }

        firstBucket = buckets[timestamp].next;
    }
}

////// src/borrower/feed/nftfeed.sol
/* pragma solidity >=0.6.12; */

/* import "tinlake-auth/auth.sol"; */
/* import "tinlake-math/math.sol"; */

interface ShelfLike_2 {
    function shelf(uint loan) external view returns (address registry, uint tokenId);
    function nftlookup(bytes32 nftID) external returns (uint loan);
}

interface PileLike_2 {
    function setRate(uint loan, uint rate) external;
    function debt(uint loan) external returns (uint);
    function pie(uint loan) external returns (uint);
    function changeRate(uint loan, uint newRate) external;
    function loanRates(uint loan) external returns (uint);
    function file(bytes32, uint, uint) external;
    function rates(uint rate) external view returns (uint, uint, uint ,uint48, uint);
    function total() external view returns (uint);
    function rateDebt(uint rate) external view returns (uint);
}

// The NFTFeed stores values and risk group of nfts that are used as collateral in tinlake. A risk group contains: thresholdRatio, ceilingRatio & interstRate.
// The risk groups for a tinlake deployment are defined on contract creation and can not be changed afterwards.
// Loan parameters like interstRate, max borrow amount and liquidation threshold are determined based on the value and risk group of the underlying collateral nft.
contract BaseNFTFeed is Auth, Math {

    // nftID => nftValues
    mapping (bytes32 => uint) public nftValues;
    // nftID => risk
    mapping (bytes32 => uint) public risk;

    // risk => thresholdRatio
    // thresholdRatio is used to determine the liquidation threshold of the loan. thresholdRatio * nftValue = liquidation threshold
    // When loan debt reaches the liquidation threshold, it can be seized and collected by a whitelisted keeper.
    mapping (uint => uint) public thresholdRatio;

    // risk => ceilingRatio
    // ceilingRatio is used to determine the ax borrow amount (ceiling) of a loan. ceilingRatio * nftValue = max borrow amount
    // When loan debt reaches the liquidation threshold, it can be seized and collected by a whitelisted keeper.
    mapping (uint => uint) public ceilingRatio;

    // loan => borrowed
    // stores the already borrowed amounts for each loan
    // required to track the borrowed currency amount without accrued interest
    mapping (uint => uint) public borrowed;

    PileLike_2 pile;
    ShelfLike_2 shelf;

    constructor () public {
        wards[msg.sender] = 1;
    }

     // part of Feed interface
    function file(bytes32 name, uint value) public virtual auth {}

    // sets the dependency to another contract
    function depend(bytes32 contractName, address addr) external auth {
        if (contractName == "pile") {pile = PileLike_2(addr);}
        else if (contractName == "shelf") { shelf = ShelfLike_2(addr); }
        else revert();
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

    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_) public virtual auth {
        if(name == "riskGroupNFT") {
            require(ceilingRatio[risk_] == 0, "risk-group-in-usage");
            thresholdRatio[risk_] = thresholdRatio_;
            ceilingRatio[risk_] = ceilingRatio_;
            // set interestRate for risk group
            pile.file("rate", risk_, rate_);
        } else {revert ("unkown name");}
    }

    //  -- Oracle Updates --

    // The nft value is to be updated by authenticated oracles
    function update(bytes32 nftID_,  uint value) public auth {
        // switch of collateral risk group results in new: ceiling, threshold for existing loan
        nftValues[nftID_] = value;
    }

     // The nft value & risk group is to be updated by authenticated oracles
    function update(bytes32 nftID_, uint value, uint risk_) public virtual auth {
        // the risk group has to exist
        require(thresholdRatio[risk_] != 0, "threshold for risk group not defined");

        // switch of collateral risk group results in new: ceiling, threshold and interest rate for existing loan
        // change to new rate interestRate immediately in pile if loan debt exists
        uint loan = shelf.nftlookup(nftID_);
        if (pile.pie(loan) != 0) {
            pile.changeRate(loan, risk_);
        }
        risk[nftID_] = risk_;
        nftValues[nftID_] = value;
    }

    // function checks if the borrow amount does not exceed the max allowed borrow amount (=ceiling)
    function borrow(uint loan, uint amount) external virtual auth returns (uint) {
        // increase borrowed amount -> note: max allowed borrow amount does not include accrued interest
        borrowed[loan] = safeAdd(borrowed[loan], amount);

        require(currentCeiling(loan) >= borrowed[loan], "borrow-amount-too-high");
        return amount;
    }

    // part of Feed interface
    function repay(uint, uint amount) external virtual auth returns (uint) {
        // note: borrowed amount is not decreased as the feed implements the principal and not credit line method
        return amount;
    }

    // borrowEvent is called by the shelf in the borrow method
    function borrowEvent(uint loan) public auth {
        uint risk_ = risk[nftID(loan)];

        // when issued every loan has per default interest rate of risk group 0.
        // correct interest rate has to be set on first borrow event
        if(pile.loanRates(loan) != risk_) {
            // set loan interest rate to the one of the correct risk group
            pile.setRate(loan, risk_);
        }
    }

    // part of Feed interface
    function unlockEvent(uint loan) public auth {}

    //  -- Getter methods --
    // returns the ceiling of a loan
    // the ceiling defines the maximum amount which can be borrowed
    function ceiling(uint loan) public view returns (uint) {
        if (borrowed[loan] > currentCeiling(loan)) {
            return 0;
        }
        return safeSub(currentCeiling(loan), borrowed[loan]);
    }

    function currentCeiling(uint loan) public view returns(uint) {
        bytes32 nftID_ = nftID(loan);
        return rmul(nftValues[nftID_], ceilingRatio[risk[nftID_]]);
    }

    // returns the threshold of a loan
    // if the loan debt is above the loan threshold the NFT can be seized
    function threshold(uint loan) public view returns (uint) {
        bytes32 nftID_ = nftID(loan);
        return rmul(nftValues[nftID_], thresholdRatio[risk[nftID_]]);
    }

    // implements feed interface and returns poolValue as the total debt of all loans
    function totalValue() public virtual view returns (uint) {
        return pile.total();
    }
}

////// src/fixed_point.sol
/* pragma solidity >=0.6.12; */

contract FixedPoint {
    struct Fixed27 {
        uint value;
    }
}

////// src/borrower/feed/navfeed.sol
/* pragma solidity >=0.6.12; */
/* pragma experimental ABIEncoderV2; */

/* import "tinlake-auth/auth.sol"; */
/* import "tinlake-math/interest.sol"; */
/* import "./nftfeed.sol"; */
/* import "./buckets.sol"; */
/* import "../../fixed_point.sol"; */

// The Nav Feed contract extends the functionality of the NFT Feed by the Net Asset Value (NAV) computation of a Tinlake pool.
// NAV is computed as the sum of all discounted future values (fv) of ongoing loans (debt > 0) in the pool.
// The applied discountRate is dependant on the maturity data of the underlying collateral. The discount decreases with the maturity date approaching.
// To optimize the NAV calculation the discounting of future values happens bucketwise. FVs from assets with the same maturity date are added to one bucket.
// This safes iterations & gas, as the same discountRates can be applied per bucket.
contract NAVFeed is BaseNFTFeed, Interest, Buckets, FixedPoint {

    // maturityDate is the expected date of repayment for an asset
    // nftID => maturityDate
    mapping (bytes32 => uint) public maturityDate;

    // recoveryRatePD is a combined rate that includes the probability of default for an asset of a certain risk group and its recovery rate
    // risk => recoveryRatePD
    mapping (uint => Fixed27) public recoveryRatePD;

    // futureValue of an asset based on the loan debt, interest rate, maturity date and recoveryRatePD
    // nftID => futureValue
    mapping (bytes32 => uint) public futureValue;

    WriteOff [5] public writeOffs;

    struct WriteOff {
        uint rateGroup;
        // denominated in (10^27)
        Fixed27 percentage;
    }

    // discount rate applied on every asset's fv depending on its maturityDate. The discount decreases with the maturityDate approaching.
    Fixed27 public discountRate;

    // approximatedNAV is calculated in case of borrows & repayments between epoch executions.
    // It decreases/increases the NAV by the repaid/borrowed amount without running the NAV calculation routine.
    // This is required for more accurate Senior & JuniorAssetValue estimations between epochs
    uint public approximatedNAV;

    // rate group for write-offs in pile contract
    uint constant public  WRITE_OFF_PHASE_A = 1000;
    uint constant public  WRITE_OFF_PHASE_B = 1001;
    uint constant public  WRITE_OFF_PHASE_C = 1002;
    uint constant public  WRITE_OFF_PHASE_D = 1003;
    uint constant public  WRITE_OFF_PHASE_E = 1004;

    constructor () public {
        wards[msg.sender] = 1;
    }

    function init() public {
        require(ceilingRatio[0] == 0, "already-initialized");

        // gas optimized initialization of writeOffs and risk groups
        // write off are hardcoded in the contract instead of init function params

        // risk groups are extended by the recoveryRatePD parameter compared with NFTFeed

        // The following score cards just examples that are mostly optimized for the system test cases

        // risk group: 0, APR: 10,00%, 90% advance rate
        file("riskGroup", 0, ONE, 90 * 10**25, uint(1000000003170979198376458650), 99.93 * 10**25);
        // risk group: 1, APR: 10,00%, 80% advance rate
        file("riskGroup", 1, ONE, 80 * 10**25, uint(1000000003170979198376458650), 99.93 * 10**25);
        // risk group: 2, APR: 10,00%, 70% advance rate
        file("riskGroup", 2, ONE, 70 * 10**25, uint(1000000003170979198376458650), 99.93 * 10**25);
        // risk group: 3, APR: 10,00%, 60% advance rate
        file("riskGroup", 3, ONE, 60 * 10**25, uint(1000000003170979198376458650), 99.93 * 10**25);
        // risk group: 4, APR: 10,00%, 50% advance rate
        file("riskGroup", 4, ONE, 50 * 10**25, uint(1000000003170979198376458650), 99.93 * 10**25);
                
        // write-off group: 0 - 0% write off - Grace period
        setWriteOff(0, WRITE_OFF_PHASE_A, uint(1000000003170979198376458650), ONE);
        // write-off group: 1 - 10% write off
        setWriteOff(1, WRITE_OFF_PHASE_B, uint(1000000003170979198376458650), 90 * 10**25);
        // write-off group: 2 - 50% write off
        setWriteOff(2, WRITE_OFF_PHASE_C, ONE, 50 * 10**25);
        // write-off group: 3 - 75% write off
        setWriteOff(3, WRITE_OFF_PHASE_D, ONE, 25 * 10**25);
        // write-off group: 4 - 100% write off
        setWriteOff(4, WRITE_OFF_PHASE_E, ONE, 0);
    }

    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) public auth  {
        if(name == "riskGroup") {
            file("riskGroupNFT", risk_, thresholdRatio_, ceilingRatio_, rate_);
            recoveryRatePD[risk_] = Fixed27(recoveryRatePD_);

        } else {revert ("unknown name");}
    }

    function setWriteOff(uint phase_, uint group_, uint rate_, uint writeOffPercentage_) internal {
        writeOffs[phase_] = WriteOff(group_, Fixed27(writeOffPercentage_));
        pile.file("rate", group_, rate_);
    }

    function uniqueDayTimestamp(uint timestamp) public pure returns (uint) {
        return (1 days) * (timestamp/(1 days));
    }

    // maturityDate is a unix timestamp
    function file(bytes32 name, bytes32 nftID_, uint maturityDate_) public auth {
        // maturity date only can be changed when there is no debt on the collateral -> futureValue == 0
        if (name == "maturityDate") {
            require((futureValue[nftID_] == 0), "can-not-change-maturityDate-outstanding-debt");
            maturityDate[nftID_] = uniqueDayTimestamp(maturityDate_);
        } else { revert("unknown config parameter");}
    }

    function file(bytes32 name, uint value) public override auth {
        if (name == "discountRate") {
            discountRate = Fixed27(value);
        } else { revert("unknown config parameter");}
    }

    // In case of successful borrow the approximatedNAV is increased by the borrowed amount
    function borrow(uint loan, uint amount) external override auth returns(uint navIncrease) {
        navIncrease = _borrow(loan, amount);
        approximatedNAV = safeAdd(approximatedNAV, navIncrease);
        return navIncrease;
    }

    // On borrow: the discounted future value of the asset is computed based on the loan amount and addeed to the bucket with the according maturity Date
    function _borrow(uint loan, uint amount) internal returns(uint navIncrease) {
        // ceiling check uses existing loan debt
        require(ceiling(loan) >= safeAdd(borrowed[loan], amount), "borrow-amount-too-high");

        bytes32 nftID_ = nftID(loan);
        uint maturityDate_ = maturityDate[nftID_];
        // maturity date has to be a value in the future
        require(maturityDate_ > block.timestamp, "maturity-date-is-not-in-the-future");

        // calculate amount including fixed fee if applicatable
        (, , , , uint fixedRate) = pile.rates(pile.loanRates(loan));
        uint amountIncludingFixed =  safeAdd(amount, rmul(amount, fixedRate));
        // calculate future value FV
        uint fv = calcFutureValue(loan, amountIncludingFixed, maturityDate_, recoveryRatePD[risk[nftID_]].value);
        futureValue[nftID_] = safeAdd(futureValue[nftID_], fv);

        // add future value to the bucket of assets with the same maturity date
        if (buckets[maturityDate_].value == 0) {
            addBucket(maturityDate_, fv);
        } else {
            buckets[maturityDate_].value = safeAdd(buckets[maturityDate_].value, fv);
        }

        // increase borrowed amount for future ceiling computations
        borrowed[loan] = safeAdd(borrowed[loan], amount);

        // return increase NAV amount
        return calcDiscount(fv, uniqueDayTimestamp(block.timestamp), maturityDate_);
    }

    // calculate the future value based on the amount, maturityDate interestRate and recoveryRate
    function calcFutureValue(uint loan, uint amount, uint maturityDate_, uint recoveryRatePD_) public returns(uint) {
        // retrieve interest rate from the pile
        (, ,uint loanInterestRate, ,) = pile.rates(pile.loanRates(loan));
        return rmul(rmul(rpow(loanInterestRate, safeSub(maturityDate_, uniqueDayTimestamp(block.timestamp)), ONE), amount), recoveryRatePD_);
    }

    // update the nft value and change the risk group
    function update(bytes32 nftID_, uint value, uint risk_) public override auth {
        nftValues[nftID_] = value;

        // no change in risk group
        if (risk_ == risk[nftID_]) {
            return;
        }

        // nfts can only be added to risk groups that are part of the score card
        require(thresholdRatio[risk_] != 0, "risk group not defined in contract");
        risk[nftID_] = risk_;

        // no currencyAmount borrowed yet
        if (futureValue[nftID_] == 0) {
            return;
        }

        uint loan = shelf.nftlookup(nftID_);
        uint maturityDate_ = maturityDate[nftID_];

        // Changing the risk group of an nft, might lead to a new interest rate for the dependant loan.
        // New interest rate leads to a future value.
        // recalculation required
        buckets[maturityDate_].value = safeSub(buckets[maturityDate_].value, futureValue[nftID_]);

        futureValue[nftID_] = calcFutureValue(loan, pile.debt(loan), maturityDate[nftID_], recoveryRatePD[risk[nftID_]].value);
        buckets[maturityDate_].value = safeAdd(buckets[maturityDate_].value, futureValue[nftID_]);
    }

    // In case of successful repayment the approximatedNAV is decreased by the repaid amount
    function repay(uint loan, uint amount) external override auth returns (uint navDecrease) {
        navDecrease = _repay(loan, amount);
        if (navDecrease > approximatedNAV) {
            approximatedNAV = 0;
        }

        if(navDecrease < approximatedNAV) {
            approximatedNAV = safeSub(approximatedNAV, navDecrease);
            return navDecrease;
        }

        approximatedNAV = 0;
        return navDecrease;
    }

    // On repayment: adjust future value bucket according to repayment amount
    function _repay(uint loan, uint amount) internal returns (uint navDecrease) {
        bytes32 nftID_ = nftID(loan);
        uint maturityDate_ = maturityDate[nftID_];


        // no fv decrease calculation needed if maturity date is in the past
        if (maturityDate_ < uniqueDayTimestamp(block.timestamp)) {
            // if a loan is overdue, the portfolio value is initially equal to the existing debt
            // it will be reduced by a write off factor once it is moved to a write off group
            return amount;
        }

        // remove future value for loan from bucket
        buckets[maturityDate_].value = safeSub(buckets[maturityDate_].value, futureValue[nftID_]);

        uint debt = pile.debt(loan);
        debt = safeSub(debt, amount);

        uint fv = 0;
        uint preFutureValue = futureValue[nftID_];

        // in case of partial repayment, compute the fv of the remaining debt and add to the according fv bucket
        if (debt != 0) {
            fv = calcFutureValue(loan, debt, maturityDate_, recoveryRatePD[risk[nftID_]].value);
            buckets[maturityDate_].value = safeAdd(buckets[maturityDate_].value, fv);
        }

        futureValue[nftID_] = fv;

        // remove buckets if no remaining assets
        if (buckets[maturityDate_].value == 0 && firstBucket != 0) {
            removeBucket(maturityDate_);
        }

        // return decrease NAV amount
        return calcDiscount(safeSub(preFutureValue, fv), uniqueDayTimestamp(block.timestamp), maturityDate_);
    }

    function calcDiscount(uint amount, uint normalizedBlockTimestamp, uint maturityDate_) public view returns (uint result) {
        return rdiv(amount, rpow(discountRate.value, safeSub(maturityDate_, normalizedBlockTimestamp), ONE));
    }


    // calculates the total discount of all buckets with a timestamp > block.timestamp
    function calcTotalDiscount() public view returns(uint) {
        uint normalizedBlockTimestamp = uniqueDayTimestamp(block.timestamp);
        uint sum = 0;

        uint currDate = normalizedBlockTimestamp;

        if (currDate > lastBucket) {
            return 0;
        }

        // only buckets after the block.timestamp are relevant for the discount
        // assuming its more gas efficient to iterate over time to find the first one instead of iterating the list from the beginning
        // not true if buckets are only sparsely populated over long periods of time
        while(buckets[currDate].next == 0) { currDate = currDate + 1 days; }

        while(currDate != NullDate)
        {
            sum = safeAdd(sum, calcDiscount(buckets[currDate].value, normalizedBlockTimestamp, currDate));
            currDate = buckets[currDate].next;
        }
        return sum;
    }

    // returns the NAV (net asset value) of the pool
    function currentNAV() public view returns(uint) {
        // calculates the NAV for ongoing loans with a maturityDate date in the future
        uint nav_ = calcTotalDiscount();
        // include ovedue assets to the current NAV calculation
        for (uint i = 0; i < writeOffs.length; i++) {
            // multiply writeOffGroupDebt with the writeOff rate
            nav_ = safeAdd(nav_, rmul(pile.rateDebt(writeOffs[i].rateGroup), writeOffs[i].percentage.value));
        }
        return nav_;
    }

    function calcUpdateNAV() public returns(uint) {
        // approximated NAV is updated and at this point in time 100% correct
        approximatedNAV = currentNAV();
        return approximatedNAV;
    }

    // workaround for transition phase between V2 & V3
    function totalValue() public override view returns(uint) {
        return currentNAV();
    }

    function dateBucket(uint timestamp) public view returns (uint) {
        return buckets[timestamp].value;
    }
}