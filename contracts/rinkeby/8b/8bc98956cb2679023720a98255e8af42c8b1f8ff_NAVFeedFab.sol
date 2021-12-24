// Copyright (C) 2020 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.15;

import {NAVFeed} from "./../feed/navfeed.sol";

contract NAVFeedFab {
    function newFeed() public returns (address) {
        NAVFeed feed = new NAVFeed();
        feed.rely(msg.sender);
        feed.deny(address(this));
        return address(feed);
    }
}

// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity 0.5.15;
pragma experimental ABIEncoderV2;

import "../../../lib/ds-note/src/note.sol";
import "../../../lib/galaxy-auth/src/auth.sol";
import "../../../lib/galaxy-math/src/interest.sol";
import "./nftfeed.sol";
import "./buckets.sol";
import "../../fixed_point.sol";

// The Nav Feed contract extends the functionality of the NFT Feed by the Net Asset Value (NAV) computation of a Galaxy pool.
// NAV is computed as the sum of all discounted future values (fv) of ongoing loans (debt > 0) in the pool.
// The applied discountRate is dependant on the maturity data of the underlying collateral. The discount decreases with the maturity date approaching.
// To optimize the NAV calculation the discounting of future values happens bucketwise. FVs from assets with the same maturity date are added to one bucket.
// This safes iterations & gas, as the same discountRates can be applied per bucket.
contract NAVFeed is BaseNFTFeed, Interest, Buckets, FixedPoint {
    // maturityDate is the expected date of repayment for an asset
    // nftID => maturityDate
    mapping(bytes32 => uint256) public maturityDate;

    // recoveryRatePD is a combined rate that includes the probability of default for an asset of a certain risk group and its recovery rate
    // risk => recoveryRatePD
    mapping(uint256 => Fixed27) public recoveryRatePD;

    // futureValue of an asset based on the loan debt, interest rate, maturity date and recoveryRatePD
    // nftID => futureValue
    mapping(bytes32 => uint256) public futureValue;

    WriteOff[2] public writeOffs;

    struct WriteOff {
        uint256 rateGroup;
        // denominated in (10^27)
        Fixed27 percentage;
    }

    // discount rate applied on every asset's fv depending on its maturityDate. The discount decreases with the maturityDate approaching.
    Fixed27 public discountRate;

    // approximatedNAV is calculated in case of borrows & repayments between epoch executions.
    // It decreases/increases the NAV by the repaid/borrowed amount without running the NAV calculation routine.
    // This is required for more accurate Senior & JuniorAssetValue estimations between epochs
    uint256 public approximatedNAV;

    // rate group for write-offs in pile contract
    uint256 public constant WRITE_OFF_PHASE_A = 1001;
    uint256 public constant WRITE_OFF_PHASE_B = 1002;

    constructor() public {
        wards[msg.sender] = 1;
    }

    function init() external {
        require(ceilingRatio[0] == 0, "already-initialized");

        // gas optimized initialization of writeOffs and risk groups
        // write off are hardcoded in the contract instead of init function params

        // risk groups are extended by the recoveryRatePD parameter compared with NFTFeed

        // The following score cards just examples that are mostly optimized for the system test cases

        // risk group: 0 Galaxy
        file(
            "riskGroup",
            0, // riskGroup:       0
            105**26, // thresholdRatio   105%
            ONE, // ceilingRatio     100%
            uint256(1000000001547125870000000000), // interestRate     5% per year
            ONE // recoveryRatePD:  1.0
        );

        /// Overdue loans (= loans that were not repaid by the maturityDate) are moved to write Offs
        // 6% interest rate & 60% write off
        setWriteOff(0, WRITE_OFF_PHASE_A, uint256(1000000674400000000000000000), 6 * 10**26);
        // 6% interest rate & 80% write off
        setWriteOff(1, WRITE_OFF_PHASE_B, uint256(1000000674400000000000000000), 8 * 10**26);
    }

    function file(
        bytes32 name,
        uint256 risk_,
        uint256 thresholdRatio_,
        uint256 ceilingRatio_,
        uint256 rate_,
        uint256 recoveryRatePD_
    ) public auth {
        if (name == "riskGroup") {
            file("riskGroupNFT", risk_, thresholdRatio_, ceilingRatio_, rate_);
            recoveryRatePD[risk_] = Fixed27(recoveryRatePD_);
        } else {
            revert("unknown name");
        }
    }

    function setWriteOff(
        uint256 phase_,
        uint256 group_,
        uint256 rate_,
        uint256 writeOffPercentage_
    ) internal {
        writeOffs[phase_] = WriteOff(group_, Fixed27(writeOffPercentage_));
        pile.file("rate", group_, rate_);
    }

    function uniqueDayTimestamp(uint256 timestamp) public pure returns (uint256) {
        return (1 days) * (timestamp / (1 days));
    }

    /// maturityDate is a unix timestamp
    function file(
        bytes32 name,
        bytes32 nftID_,
        uint256 maturityDate_
    ) external auth {
        // maturity date only can be changed when there is no debt on the collateral -> futureValue == 0
        if (name == "maturityDate") {
            require((futureValue[nftID_] == 0), "can-not-change-maturityDate-outstanding-debt");
            maturityDate[nftID_] = uniqueDayTimestamp(maturityDate_);
        } else {
            revert("unknown config parameter");
        }
    }

    function file(bytes32 name, uint256 value) public auth {
        if (name == "discountRate") {
            discountRate = Fixed27(value);
        } else {
            revert("unknown config parameter");
        }
    }

    // In case of successful borrow the approximatedNAV is increased by the borrowed amount
    function borrow(uint256 loan, uint256 amount) external auth returns (uint256 navIncrease) {
        navIncrease = _borrow(loan, amount);
        approximatedNAV = safeAdd(approximatedNAV, navIncrease);
        return navIncrease;
    }

    // On borrow: the discounted future value of the asset is computed based on the loan amount and addeed to the bucket with the according maturity Date
    function _borrow(uint256 loan, uint256 amount) internal returns (uint256 navIncrease) {
        // ceiling check uses existing loan debt
        require(ceiling(loan) >= safeAdd(borrowed[loan], amount), "borrow-amount-too-high");

        bytes32 nftID_ = nftID(loan);
        uint256 maturityDate_ = maturityDate[nftID_];
        // maturity date has to be a value in the future
        require(maturityDate_ > block.timestamp, "maturity-date-is-not-in-the-future");

        // calculate amount including fixed fee if applicatable
        (, , , , uint256 fixedRate) = pile.rates(pile.loanRates(loan));
        uint256 amountIncludingFixed = safeAdd(amount, rmul(amount, fixedRate));
        // calculate future value FV
        uint256 fv = calcFutureValue(loan, amountIncludingFixed, maturityDate_, recoveryRatePD[risk[nftID_]].value);
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
    function calcFutureValue(
        uint256 loan,
        uint256 amount,
        uint256 maturityDate_,
        uint256 recoveryRatePD_
    ) public returns (uint256) {
        // retrieve interest rate from the pile
        (, , uint256 loanInterestRate, , ) = pile.rates(pile.loanRates(loan));
        return rmul(rmul(rpow(loanInterestRate, safeSub(maturityDate_, uniqueDayTimestamp(now)), ONE), amount), recoveryRatePD_);
    }

    /// update the nft value and change the risk group
    function update(
        bytes32 nftID_,
        uint256 value,
        uint256 risk_
    ) public auth {
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

        uint256 loan = shelf.nftlookup(nftID_);
        uint256 maturityDate_ = maturityDate[nftID_];

        // Changing the risk group of an nft, might lead to a new interest rate for the dependant loan.
        // New interest rate leads to a future value.
        // recalculation required
        buckets[maturityDate_].value = safeSub(buckets[maturityDate_].value, futureValue[nftID_]);

        futureValue[nftID_] = calcFutureValue(loan, pile.debt(loan), maturityDate[nftID_], recoveryRatePD[risk[nftID_]].value);
        buckets[maturityDate_].value = safeAdd(buckets[maturityDate_].value, futureValue[nftID_]);
    }

    // In case of successful repayment the approximatedNAV is decreased by the repaid amount
    function repay(uint256 loan, uint256 amount) external auth returns (uint256 navDecrease) {
        navDecrease = _repay(loan, amount);
        if (navDecrease > approximatedNAV) {
            approximatedNAV = 0;
        }

        if (navDecrease < approximatedNAV) {
            approximatedNAV = safeSub(approximatedNAV, navDecrease);
            return navDecrease;
        }

        approximatedNAV = 0;
        return navDecrease;
    }

    // On repayment: adjust future value bucket according to repayment amount
    function _repay(uint256 loan, uint256 amount) internal returns (uint256 navDecrease) {
        bytes32 nftID_ = nftID(loan);
        uint256 maturityDate_ = maturityDate[nftID_];

        // no fv decrease calculation needed if maturaity date is in the past
        if (maturityDate_ < block.timestamp) {
            return amount;
        }

        // remove future value for loan from bucket
        buckets[maturityDate_].value = safeSub(buckets[maturityDate_].value, futureValue[nftID_]);

        uint256 debt = pile.debt(loan);
        debt = safeSub(debt, amount);

        uint256 fv = 0;
        uint256 preFutureValue = futureValue[nftID_];

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
        if (block.timestamp < maturityDate_) {
            return calcDiscount(safeSub(preFutureValue, fv), uniqueDayTimestamp(block.timestamp), maturityDate_);
        }

        // if a loan is overdue the portfolio value is equal to the existing debt multiplied with a write off factor
        return amount;
    }

    function calcDiscount(
        uint256 amount,
        uint256 normalizedBlockTimestamp,
        uint256 maturityDate_
    ) public view returns (uint256 result) {
        return rdiv(amount, rpow(discountRate.value, safeSub(maturityDate_, normalizedBlockTimestamp), ONE));
    }

    /// calculates the total discount of all buckets with a timestamp > block.timestamp
    function calcTotalDiscount() public view returns (uint256) {
        uint256 normalizedBlockTimestamp = uniqueDayTimestamp(block.timestamp);
        uint256 sum = 0;

        uint256 currDate = normalizedBlockTimestamp;

        if (currDate > lastBucket) {
            return 0;
        }

        // only buckets after the block.timestamp are relevant for the discount
        // assuming its more gas efficient to iterate over time to find the first one instead of iterating the list from the beginning
        // not true if buckets are only sparsely populated over long periods of time
        while (buckets[currDate].next == 0) {
            currDate = currDate + 1 days;
        }

        while (currDate != NullDate) {
            sum = safeAdd(sum, calcDiscount(buckets[currDate].value, normalizedBlockTimestamp, currDate));
            currDate = buckets[currDate].next;
        }
        return sum;
    }

    /// returns the NAV (net asset value) of the pool
    function currentNAV() public view returns (uint256) {
        // calculates the NAV for ongoing loans with a maturityDate date in the future
        uint256 nav_ = calcTotalDiscount();
        // include ovedue assets to the current NAV calculation
        for (uint256 i = 0; i < writeOffs.length; i++) {
            // multiply writeOffGroupDebt with the writeOff rate
            nav_ = safeAdd(nav_, rmul(pile.rateDebt(writeOffs[i].rateGroup), writeOffs[i].percentage.value));
        }
        return nav_;
    }

    function calcUpdateNAV() external returns (uint256) {
        // approximated NAV is updated and at this point in time 100% correct
        approximatedNAV = currentNAV();
        return approximatedNAV;
    }

    /// workaround for transition phase between V2 & V3
    function totalValue() public view returns (uint256) {
        return currentNAV();
    }

    function dateBucket(uint256 timestamp) public view returns (uint256) {
        return buckets[timestamp].value;
    }
}

/// note.sol -- the `note' modifier, for logging calls as events

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity 0.5.15;

contract DSNote {
    event LogNote(bytes4 indexed sig, address indexed guy, bytes32 indexed foo, bytes32 indexed bar, uint256 wad, bytes fax) anonymous;

    modifier note() {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.15;

import "../../ds-note/src/note.sol";

contract Auth is DSNote {
    mapping(address => uint256) public wards;

    function rely(address usr) public auth note {
        wards[usr] = 1;
    }

    function deny(address usr) public auth note {
        wards[usr] = 0;
    }

    modifier auth() {
        require(wards[msg.sender] == 1);
        _;
    }
}

// Copyright (C) 2018 Rain <[email protected]> and Centrifuge, referencing MakerDAO dss => https://github.com/makerdao/dss/blob/master/src/pot.sol
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.15;

import "./math.sol";

contract Interest is Math {
    // @notice This function provides compounding in seconds
    // @param chi Accumulated interest rate over time
    // @param ratePerSecond Interest rate accumulation per second in RAD(10ˆ27)
    // @param lastUpdated When the interest rate was last updated
    // @param pie Total sum of all amounts accumulating under one interest rate, divided by that rate
    // @return The new accumulated rate, as well as the difference between the debt calculated with the old and new accumulated rates.
    function compounding(
        uint256 chi,
        uint256 ratePerSecond,
        uint256 lastUpdated,
        uint256 pie
    ) public view returns (uint256, uint256) {
        require(block.timestamp >= lastUpdated, "galaxy-math/invalid-timestamp");
        require(chi != 0);
        // instead of a interestBearingAmount we use a accumulated interest rate index (chi)
        uint256 updatedChi = _chargeInterest(chi, ratePerSecond, lastUpdated, block.timestamp);
        return (updatedChi, safeSub(rmul(updatedChi, pie), rmul(chi, pie)));
    }

    // @notice This function charge interest on a interestBearingAmount
    // @param interestBearingAmount is the interest bearing amount
    // @param ratePerSecond Interest rate accumulation per second in RAD(10ˆ27)
    // @param lastUpdated last time the interest has been charged
    // @return interestBearingAmount + interest
    function chargeInterest(
        uint256 interestBearingAmount,
        uint256 ratePerSecond,
        uint256 lastUpdated
    ) public view returns (uint256) {
        if (block.timestamp >= lastUpdated) {
            interestBearingAmount = _chargeInterest(interestBearingAmount, ratePerSecond, lastUpdated, block.timestamp);
        }
        return interestBearingAmount;
    }

    function _chargeInterest(
        uint256 interestBearingAmount,
        uint256 ratePerSecond,
        uint256 lastUpdated,
        uint256 current
    ) internal pure returns (uint256) {
        return rmul(rpow(ratePerSecond, current - lastUpdated, ONE), interestBearingAmount);
    }

    // convert pie to debt/savings amount
    function toAmount(uint256 chi, uint256 pie) public pure returns (uint256) {
        return rmul(pie, chi);
    }

    // convert debt/savings amount to pie
    function toPie(uint256 chi, uint256 amount) public pure returns (uint256) {
        return rdivup(amount, chi);
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 base
    ) public pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := base
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := base
                }
                default {
                    z := x
                }
                let half := div(base, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, base)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

// Copyright (C) 2020 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.15;

import "../../../lib/ds-note/src/note.sol";
import "../../../lib/galaxy-auth/src/auth.sol";
import "../../../lib/galaxy-math/src/math.sol";

contract ShelfLike {
    function shelf(uint256 loan) public view returns (address registry, uint256 tokenId);

    function nftlookup(bytes32 nftID) public returns (uint256 loan);
}

contract PileLike {
    function setRate(uint256 loan, uint256 rate) public;

    function debt(uint256 loan) public returns (uint256);

    function pie(uint256 loan) public returns (uint256);

    function changeRate(uint256 loan, uint256 newRate) public;

    function loanRates(uint256 loan) public returns (uint256);

    function file(
        bytes32,
        uint256,
        uint256
    ) public;

    function rates(uint256 rate)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint48,
            uint256
        );

    function total() public view returns (uint256);

    function rateDebt(uint256 rate) public view returns (uint256);
}

// The NFTFeed stores values and risk group of nfts that are used as collateral in galaxy. A risk group contains: thresholdRatio, ceilingRatio & interstRate.
// The risk groups for a galaxy deployment are defined on contract creation and can not be changed afterwards.
// Loan parameters like interstRate, max borrow amount and liquidation threshold are determined based on the value and risk group of the underlying collateral nft.
contract BaseNFTFeed is DSNote, Auth, Math {
    // nftID => nftValues
    mapping(bytes32 => uint256) public nftValues;
    // nftID => risk
    mapping(bytes32 => uint256) public risk;

    // risk => thresholdRatio
    // thresholdRatio is used to determine the liquidation threshold of the loan. thresholdRatio * nftValue = liquidation threshold
    // When loan debt reaches the liquidation threshold, it can be seized and collected by a whitelisted keeper.
    mapping(uint256 => uint256) public thresholdRatio;

    // risk => ceilingRatio
    // ceilingRatio is used to determine the ax borrow amount (ceiling) of a loan. ceilingRatio * nftValue = max borrow amount
    // When loan debt reaches the liquidation threshold, it can be seized and collected by a whitelisted keeper.
    mapping(uint256 => uint256) public ceilingRatio;

    // loan => borrowed
    // stores the already borrowed amounts for each loan
    // required to track the borrowed currency amount without accrued interest
    mapping(uint256 => uint256) public borrowed;

    PileLike pile;
    ShelfLike shelf;

    constructor() public {
        wards[msg.sender] = 1;
    }

    // part of Feed interface
    function file(bytes32 name, uint256 value) external auth {}

    /// sets the dependency to another contract
    function depend(bytes32 contractName, address addr) external auth {
        if (contractName == "pile") {
            pile = PileLike(addr);
        } else if (contractName == "shelf") {
            shelf = ShelfLike(addr);
        } else revert();
    }

    // returns a unique id based on the nft registry and tokenId
    // the nftID is used to set the risk group and value for nfts
    function nftID(address registry, uint256 tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(registry, tokenId));
    }

    // returns the nftID for the underlying collateral nft
    function nftID(uint256 loan) public view returns (bytes32) {
        (address registry, uint256 tokenId) = shelf.shelf(loan);
        return nftID(registry, tokenId);
    }

    function file(
        bytes32 name,
        uint256 risk_,
        uint256 thresholdRatio_,
        uint256 ceilingRatio_,
        uint256 rate_
    ) public auth {
        if (name == "riskGroupNFT") {
            require(ceilingRatio[risk_] == 0, "risk-group-in-usage");
            require(thresholdRatio_ > ceilingRatio_, "thresholdRatio_ must be greater than ceilingRatio_");
            thresholdRatio[risk_] = thresholdRatio_;
            ceilingRatio[risk_] = ceilingRatio_;
            // set interestRate for risk group
            pile.file("rate", risk_, rate_);
        } else {
            revert("unkown name");
        }
    }

    ///  -- Oracle Updates --

    // The nft value is to be updated by authenticated oracles
    function update(bytes32 nftID_, uint256 value) external auth {
        // switch of collateral risk group results in new: ceiling, threshold for existing loan
        nftValues[nftID_] = value;
    }

    // The nft value & risk group is to be updated by authenticated oracles
    function update(
        bytes32 nftID_,
        uint256 value,
        uint256 risk_
    ) external auth {
        // the risk group has to exist
        require(thresholdRatio[risk_] != 0, "threshold for risk group not defined");

        // switch of collateral risk group results in new: ceiling, threshold and interest rate for existing loan
        // change to new rate interestRate immediately in pile if loan debt exists
        uint256 loan = shelf.nftlookup(nftID_);
        if (pile.pie(loan) != 0) {
            pile.changeRate(loan, risk_);
        }
        risk[nftID_] = risk_;
        nftValues[nftID_] = value;
    }

    // function checks if the borrow amount does not exceed the max allowed borrow amount (=ceiling)
    function borrow(uint256 loan, uint256 amount) external auth returns (uint256) {
        // increase borrowed amount -> note: max allowed borrow amount does not include accrued interest
        borrowed[loan] = safeAdd(borrowed[loan], amount);

        require(currentCeiling(loan) >= borrowed[loan], "borrow-amount-too-high");
        return amount;
    }

    // part of Feed interface
    function repay(uint256, uint256 amount) external auth returns (uint256) {
        // note: borrowed amount is not decreased as the feed implements the principal and not credit line method
        return amount;
    }

    // borrowEvent is called by the shelf in the borrow method
    function borrowEvent(uint256 loan) external auth {
        uint256 risk_ = risk[nftID(loan)];

        // when issued every loan has per default interest rate of risk group 0.
        // correct interest rate has to be set on first borrow event
        if (pile.loanRates(loan) != risk_) {
            // set loan interest rate to the one of the correct risk group
            pile.setRate(loan, risk_);
        }
    }

    // part of Feed interface
    function unlockEvent(uint256 loan) external auth {}

    ///  -- Getter methods --
    // returns the ceiling of a loan
    // the ceiling defines the maximum amount which can be borrowed
    function ceiling(uint256 loan) public view returns (uint256) {
        if (borrowed[loan] > currentCeiling(loan)) {
            return 0;
        }
        return safeSub(currentCeiling(loan), borrowed[loan]);
    }

    function currentCeiling(uint256 loan) public view returns (uint256) {
        bytes32 nftID_ = nftID(loan);
        return rmul(nftValues[nftID_], ceilingRatio[risk[nftID_]]);
    }

    // returns the threshold of a loan
    // if the loan debt is above the loan threshold the NFT can be seized
    function threshold(uint256 loan) public view returns (uint256) {
        bytes32 nftID_ = nftID(loan);
        return rmul(nftValues[nftID_], thresholdRatio[risk[nftID_]]);
    }

    /// implements feed interface and returns poolValue as the total debt of all loans
    function totalValue() public view returns (uint256) {
        return pile.total();
    }
}

// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity 0.5.15;

// the buckets contract stores values in a map using a timestamp as a key
// each value store a pointer the next value in a linked list
// to improve performance/gas efficiency while iterating over all values in a timespan
contract Buckets {
    // abstract contract
    constructor() internal {}

    struct Bucket {
        uint256 value;
        uint256 next;
    }

    // timestamp => bucket
    mapping(uint256 => Bucket) public buckets;

    // pointer to the first bucket and last bucket
    uint256 public firstBucket;
    uint256 public lastBucket;

    uint256 public constant NullDate = 1;

    function addBucket(uint256 timestamp, uint256 value) internal {
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
        uint256 prev = timestamp;
        while (buckets[prev].next == 0) {
            prev = prev - 1 days;
        }

        if (buckets[prev].next == NullDate) {
            lastBucket = timestamp;
        }
        buckets[timestamp].next = buckets[prev].next;
        buckets[prev].next = timestamp;
    }

    function removeBucket(uint256 timestamp) internal {
        buckets[timestamp].value = 0;
        _removeBucket(timestamp);
        buckets[timestamp].next = 0;
    }

    function _removeBucket(uint256 timestamp) internal {
        if (firstBucket == lastBucket) {
            lastBucket = 0;
            firstBucket = 0;
            return;
        }

        if (timestamp != firstBucket) {
            uint256 prev = timestamp - 1 days;
            // assuming its more gas efficient to iterate over time instead of iterating the list from the beginning
            // not true if buckets are only sparsely populated over long periods of time
            while (buckets[prev].next != timestamp) {
                prev = prev - 1 days;
            }
            buckets[prev].next = buckets[timestamp].next;
            if (timestamp == lastBucket) {
                lastBucket = prev;
            }
            return;
        }

        firstBucket = buckets[timestamp].next;
    }
}

// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.15;

contract FixedPoint {
    struct Fixed27 {
        uint256 value;
    }
}

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.15;

contract Math {
    uint256 constant ONE = 10**27;

    function safeAdd(uint256 x, uint256 y) public pure returns (uint256 z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint256 x, uint256 y) public pure returns (uint256 z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }

    function safeMul(uint256 x, uint256 y) public pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    function safeDiv(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = x / y;
    }

    function rmul(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint256 x, uint256 y) public pure returns (uint256 z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }
}