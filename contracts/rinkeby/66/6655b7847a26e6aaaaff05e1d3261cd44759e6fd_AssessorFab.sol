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

import {Assessor} from "./../assessor.sol";

interface AssessorFabLike {
    function newAssessor() external returns (address);
}

contract AssessorFab {
    function newAssessor() public returns (address) {
        Assessor assessor = new Assessor();
        assessor.rely(msg.sender);
        assessor.deny(address(this));
        return address(assessor);
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

import "./../fixed_point.sol";
import "../../lib/galaxy-auth/src/auth.sol";
import "../../lib/galaxy-math/src/interest.sol";

interface NAVFeedLike {
    function calcUpdateNAV() external returns (uint256);

    function approximatedNAV() external view returns (uint256);

    function currentNAV() external view returns (uint256);
}

interface TrancheLike {
    function tokenSupply() external view returns (uint256);
}

interface ReserveLike {
    function totalBalance() external view returns (uint256);

    function payoutTo(address to, uint256 currencyAmount) external;
}

contract Assessor is Auth, FixedPoint, Interest {
    // senior ratio from the last epoch executed
    Fixed27 public seniorRatio;

    // the seniorAsset value is stored in two variables
    // seniorDebt is the interest bearing amount for senior
    uint256 public seniorDebt_;
    // senior balance is the rest which is not used as interest
    // bearing amount
    uint256 public seniorBalance_;

    // interest rate per second for senior tranche
    Fixed27 public seniorInterestRate;

    // withdraw fee rate
    Fixed27         public withdrawFeeRatio;

    // last time the senior interest has been updated
    uint256 public lastUpdateSeniorInterest;

    Fixed27 public maxSeniorRatio;
    Fixed27 public minSeniorRatio;

    uint256 public maxReserve;

    TrancheLike public seniorTranche;
    TrancheLike public juniorTranche;
    NAVFeedLike public navFeed;
    ReserveLike public reserve;

    constructor() public {
        wards[msg.sender] = 1;
        seniorInterestRate.value = ONE;
        withdrawFeeRatio.value = ONE;
        lastUpdateSeniorInterest = block.timestamp;
        seniorRatio.value = 0;
    }

    function depend(bytes32 contractName, address addr) external auth {
        if (contractName == "navFeed") {
            navFeed = NAVFeedLike(addr);
        } else if (contractName == "seniorTranche") {
            seniorTranche = TrancheLike(addr);
        } else if (contractName == "juniorTranche") {
            juniorTranche = TrancheLike(addr);
        } else if (contractName == "reserve") {
            reserve = ReserveLike(addr);
        } else revert();
    }

    function file(bytes32 name, uint256 value) external auth {
        if (name == "seniorInterestRate") {
            seniorInterestRate = Fixed27(value);
        } else if (name == "maxReserve") {
            maxReserve = value;
        } else if (name == "maxSeniorRatio") {
            require(value > minSeniorRatio.value, "value-too-small");
            maxSeniorRatio = Fixed27(value);
        } else if (name == "minSeniorRatio") {
            require(value < maxSeniorRatio.value, "value-too-big");
            minSeniorRatio = Fixed27(value);
        }
        else if(name == "withdrawFeeRatio") {
            require(value <= ONE, "value-too-big");
            require(value >= 10**25, "value-too-small");
            withdrawFeeRatio = Fixed27(value);
        }
    }

    function reBalance(uint256 seniorAsset_, uint256 seniorRatio_) internal {
        // re-balancing according to new ratio
        // we use the approximated NAV here because during the submission period
        // new loans might have been repaid in the meanwhile which are not considered in the epochNAV
        seniorDebt_ = rmul(navFeed.approximatedNAV(), seniorRatio_);
        if (seniorDebt_ > seniorAsset_) {
            seniorDebt_ = seniorAsset_;
            seniorBalance_ = 0;
            return;
        }
        seniorBalance_ = safeSub(seniorAsset_, seniorDebt_);
    }

    function changeSeniorAsset(
        uint256 seniorRatio_,
        uint256 seniorSupply,
        uint256 seniorRedeem
    ) external auth {
        dripSeniorDebt();
        uint256 seniorAsset = safeSub(safeAdd(safeAdd(seniorDebt_, seniorBalance_), seniorSupply), seniorRedeem);
        reBalance(seniorAsset, seniorRatio_);
        seniorRatio = Fixed27(seniorRatio_);
    }

    function seniorRatioBounds() public view returns (uint256 minSeniorRatio_, uint256 maxSeniorRatio_) {
        return (minSeniorRatio.value, maxSeniorRatio.value);
    }

    function calcUpdateNAV() external returns (uint256) {
        return navFeed.calcUpdateNAV();
    }

    function calcSeniorTokenPrice() external view returns (uint256) {
        return calcSeniorTokenPrice(navFeed.currentNAV(), reserve.totalBalance());
    }

    function calcJuniorTokenPrice() external view returns (uint256) {
        return calcJuniorTokenPrice(navFeed.currentNAV(), reserve.totalBalance());
    }

    function calcTokenPrices() external view returns (uint256, uint256) {
        uint256 epochNAV = navFeed.currentNAV();
        uint256 epochReserve = reserve.totalBalance();
        return calcTokenPrices(epochNAV, epochReserve);
    }

    function calcTokenPrices(uint256 epochNAV, uint256 epochReserve) public view returns (uint256, uint256) {
        return (calcJuniorTokenPrice(epochNAV, epochReserve), calcSeniorTokenPrice(epochNAV, epochReserve));
    }

    function calcSeniorTokenPrice(uint256 epochNAV, uint256 epochReserve) public view returns (uint256) {
        if ((epochNAV == 0 && epochReserve == 0) || seniorTranche.tokenSupply() == 0) {
            // initial token price at start 1.00
            return ONE;
        }
        uint256 totalAssets = safeAdd(epochNAV, epochReserve);
        uint256 seniorAssetValue = calcSeniorAssetValue(seniorDebt(), seniorBalance_);

        if (totalAssets < seniorAssetValue) {
            seniorAssetValue = totalAssets;
        }
        return rdiv(seniorAssetValue, seniorTranche.tokenSupply());
    }

    function calcJuniorTokenPrice(uint256 epochNAV, uint256 epochReserve) public view returns (uint256) {
        if ((epochNAV == 0 && epochReserve == 0) || juniorTranche.tokenSupply() == 0) {
            // initial token price at start 1.00
            return ONE;
        }
        uint256 totalAssets = safeAdd(epochNAV, epochReserve);
        uint256 seniorAssetValue = calcSeniorAssetValue(seniorDebt(), seniorBalance_);

        if (totalAssets < seniorAssetValue) {
            return 0;
        }

        return rdiv(safeSub(totalAssets, seniorAssetValue), juniorTranche.tokenSupply());
    }

    /// repayment update keeps track of senior bookkeeping for repaid loans
    /// the seniorDebt needs to be decreased
    function repaymentUpdate(uint256 currencyAmount) external auth {
        dripSeniorDebt();

        uint256 decAmount = rmul(currencyAmount, seniorRatio.value);

        if (decAmount > seniorDebt_) {
            seniorBalance_ = calcSeniorAssetValue(seniorDebt_, seniorBalance_);
            seniorDebt_ = 0;
            return;
        }

        seniorBalance_ = safeAdd(seniorBalance_, decAmount);
        // seniorDebt needs to be decreased for loan repayments
        seniorDebt_ = safeSub(seniorDebt_, decAmount);
        lastUpdateSeniorInterest = block.timestamp;
    }

    /// borrow update keeps track of the senior bookkeeping for new borrowed loans
    /// the seniorDebt needs to be increased to accumulate interest
    function borrowUpdate(uint256 currencyAmount) external auth {
        dripSeniorDebt();

        // the current senior ratio defines
        // interest bearing amount (seniorDebt) increase
        uint256 incAmount = rmul(currencyAmount, seniorRatio.value);

        // this case should most likely never happen
        if (incAmount > seniorBalance_) {
            // all the currency of senior is used as interest bearing currencyAmount
            seniorDebt_ = calcSeniorAssetValue(seniorDebt_, seniorBalance_);
            seniorBalance_ = 0;
            return;
        }

        // seniorDebt needs to be increased for loan borrows
        seniorDebt_ = safeAdd(seniorDebt_, incAmount);
        seniorBalance_ = safeSub(seniorBalance_, incAmount);
        lastUpdateSeniorInterest = block.timestamp;
    }

    function calcSeniorAssetValue(uint256 _seniorDebt, uint256 _seniorBalance) public pure returns (uint256) {
        return safeAdd(_seniorDebt, _seniorBalance);
    }

    function dripSeniorDebt() public returns (uint256) {
        uint256 newSeniorDebt = seniorDebt();

        if (newSeniorDebt > seniorDebt_) {
            seniorDebt_ = newSeniorDebt;
            lastUpdateSeniorInterest = block.timestamp;
        }

        return seniorDebt_;
    }

    function seniorDebt() public view returns (uint256) {
        return chargeInterest(seniorDebt_, seniorInterestRate.value, lastUpdateSeniorInterest);
    }

    function seniorBalance() public view returns (uint256) {
        return seniorBalance_;
    }

    /// available withdraw fee
    function availableWithdrawFee() public view returns (uint) {
        return availableWithdrawFee(navFeed.currentNAV(), reserve.totalBalance());
    }

    /// available withdraw fee with epochNAV and epochReserve
    function availableWithdrawFee(uint epochNAV, uint epochReserve) public view returns (uint) {
        if (epochNAV == 0 && epochReserve == 0) {
            return 0;
        }
        uint totalAssets = safeAdd(epochNAV, epochReserve);
        uint seniorAssetValue = calcSeniorAssetValue(seniorDebt(), seniorBalance());

        if(totalAssets < seniorAssetValue) {
            return 0;
        }

        uint withdrawFeeAmount = rmul(safeSub(totalAssets, seniorAssetValue), withdrawFeeRatio.value);
        return withdrawFeeAmount;
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