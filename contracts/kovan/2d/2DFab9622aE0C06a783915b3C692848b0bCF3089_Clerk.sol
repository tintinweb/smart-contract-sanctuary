/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

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

pragma solidity >=0.5.15 <0.6.0;

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

pragma solidity >=0.5.15 <0.6.0;

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

pragma solidity >=0.4.23;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
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

contract Auth is DSNote {
    mapping (address => uint) public wards;
    function rely(address usr) public auth note { wards[usr] = 1; }
    function deny(address usr) public auth note { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }
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

pragma solidity >=0.5.15 <0.6.0;

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

interface ManagerLike {
    // put collateral into cdp
    function join(uint amountDROP) external;
    // draw DAi from cdp
    function draw(uint amountDAI) external;
    // repay cdp debt
    function wipe(uint amountDAI) external;
    // remove collateral from cdp
    function exit(uint amountDROP) external;
    // collateral ID
    function ilk() external view returns(bytes32);
    // indicates if soft-liquidation was activated
    function safe() external view returns(bool);
    // indicates if hard-liquidation was activated
    function glad() external view returns(bool);
    // indicates if global settlement was triggered
    function live() external view returns(bool);
    // auth functions
    function file(bytes32 what, address data) external;

    function urn() external view returns(address);
}

// MKR contract
interface VatLike {
    function urns(bytes32, address) external view returns (uint,uint);
    function ilks(bytes32) external view returns(uint, uint, uint, uint, uint);
}
// MKR contract
interface SpotterLike {
    function ilks(bytes32) external view returns(address, uint256);
}
// MKR contract
interface JugLike {
    function ilks(bytes32) external view returns(uint, uint);
}

interface GemJoinLike {
    function ilk() external view returns(bytes32);
}

interface UrnLike {
    function gemJoin() external view returns(address);
}

interface AssessorLike {
    function calcSeniorTokenPrice() external view returns(uint);
    function calcSeniorAssetValue(uint seniorDebt, uint seniorBalance) external view returns(uint);
    function changeSeniorAsset(uint seniorSupply, uint seniorRedeem) external;
    function seniorDebt() external returns(uint);
    function seniorBalance() external returns(uint);
    function getNAV() external view returns(uint);
    function totalBalance() external returns(uint);
    function calcExpectedSeniorAsset(uint seniorRedeem, uint seniorSupply, uint seniorBalance_, uint seniorDebt_) external view returns(uint);
    function changeBorrowAmountEpoch(uint currencyAmount) external;
    function borrowAmountEpoch() external view returns(uint);
}

interface CoordinatorLike {
    function validateRatioConstraints(uint assets, uint seniorAsset) external returns(int);
    function calcSeniorAssetValue(uint seniorRedeem, uint seniorSupply, uint currSeniorAsset, uint reserve_, uint nav_) external returns(uint);
    function calcSeniorRatio(uint seniorAsset, uint NAV, uint reserve_) external returns(uint);
    function submissionPeriod() external view returns(bool);
}

interface ReserveLike {
    function totalBalance() external returns(uint);
    function hardDeposit(uint daiAmount) external;
    function hardPayout(uint currencyAmount) external;
}

interface TrancheLike {
    function mint(address usr, uint amount) external;
    function token() external returns(address);
}

interface ERC20Like {
    function burn(address, uint) external;
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address usr, uint amount) external;
}

contract Clerk is Auth, Math {

    // max amount of DAI that can be brawn from MKR
    uint public creditline;

    // tinlake contracts
    CoordinatorLike public coordinator;
    AssessorLike public assessor;
    ReserveLike public reserve;
    TrancheLike public tranche;

    // MKR contracts
    ManagerLike public mgr;
    VatLike public vat;
    SpotterLike public spotter;
    JugLike public jug;

    ERC20Like public dai;
    ERC20Like public collateral;

    // buffer to add on top of mat to avoid cdp liquidation => default 1%
    uint matBuffer = 0.01 * 10**27;

    // adapter functions can only be active if the tinlake pool is currently not in epoch closing/submissions/execution state
    modifier active() { require(activated(), "epoch-closing"); _; }

    function activated() public view returns(bool) {
        return coordinator.submissionPeriod() == false && mkrActive();
    }

    function mkrActive() public view returns (bool) {
        return mgr.safe() && mgr.glad() && mgr.live();
    }

    constructor(address dai_, address collateral_) public {
        wards[msg.sender] = 1;
        dai =  ERC20Like(dai_);
        collateral =  ERC20Like(collateral_);
    }

    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "mgr") {
            mgr =  ManagerLike(addr);
        } else if (contractName == "coordinator") {
            coordinator = CoordinatorLike(addr);
        } else if (contractName == "assessor") {
            assessor = AssessorLike(addr);
        } else if (contractName == "reserve") {
            reserve = ReserveLike(addr);
        } else if (contractName == "tranche") {
            tranche = TrancheLike(addr);
        } else if (contractName == "collateral") {
            collateral = ERC20Like(addr);
        } else if (contractName == "spotter") {
            spotter = SpotterLike(addr);
        } else if (contractName == "vat") {
            vat = VatLike(addr);
        } else if (contractName == "jug") {
            jug = JugLike(addr);
        } else revert();
    }

    function file(bytes32 what, uint value) public auth {
        if (what == "buffer") {
            matBuffer = value;
        }
    }

    function remainingCredit() public returns (uint) {
        if (creditline <= (cdptab()) || mkrActive() == false) {
            return 0;
        }
        return safeSub(creditline, cdptab());
    }

    function collatDeficit() public returns (uint) {
        uint lockedCollateralDAI = rmul(cdpink(), assessor.calcSeniorTokenPrice());
        uint requiredCollateralDAI = calcOvercollAmount(cdptab());
        if (requiredCollateralDAI > lockedCollateralDAI) {
            return safeSub(requiredCollateralDAI, lockedCollateralDAI);
        }
        return 0;
    }

    function remainingOvercollCredit() public returns (uint) {
        return calcOvercollAmount(remainingCredit());
    }


    // junior stake in the cdpink -> value of drop used for cdptab protection
    function juniorStake() public view returns (uint) {
        // junior looses stake in case vault is in soft/hard liquidation mode
        uint collateralValue = rmul(cdpink(), assessor.calcSeniorTokenPrice());
        uint mkrDebt = cdptab();
        if (mkrActive() == false || collateralValue < mkrDebt) {
            return 0;
        }
        return safeSub(collateralValue, mkrDebt);
    }

    // increase MKR credit line
    function raise(uint amountDAI) public auth active {
        // creditline amount including required overcollateralization => amount by that the seniorAssetValue should be increased
        uint overcollAmountDAI =  calcOvercollAmount(amountDAI);
        // protection value for the creditline increase coming from the junior tranche => amount by that the juniorAssetValue should be decreased
        uint protectionDAI = safeSub(overcollAmountDAI, amountDAI);
        // check if the new creditline would break the pool constraints
        require((validate(0, protectionDAI, overcollAmountDAI, 0) == 0), "supply not possible, pool constraints violated");
        // increase MKR crediline by amount
        creditline = safeAdd(creditline, amountDAI);
        // make increase in creditline available to new loans
        assessor.changeBorrowAmountEpoch(safeAdd(assessor.borrowAmountEpoch(), amountDAI));
    }

    // mint DROP, join DROP into cdp, draw DAI and send to reserve
    function draw(uint amountDAI) public auth active {
        //make sure there is no collateral deficit before drawing out new DAI
        require(collatDeficit() == 0, "please heal cdp first"); // tbd
        require(amountDAI <= remainingCredit(), "not enough credit left");
        // collateral value that needs to be locked in vault to draw amountDAI
        uint collateralDAI = calcOvercollAmount(amountDAI);
        uint collateralDROP = rdiv(collateralDAI, assessor.calcSeniorTokenPrice());
        // mint required DROP
        tranche.mint(address(this), collateralDROP);
        // join collateral into the cdp
        collateral.approve(address(mgr), collateralDROP);
        mgr.join(collateralDROP);
        // draw dai from cdp
        mgr.draw(amountDAI);
        // move dai to reserve
        dai.approve(address(reserve), amountDAI);
        reserve.hardDeposit(amountDAI);
        // increase seniorAsset by amountDAI
        updateSeniorAsset(0, collateralDAI);
    }

    // transfer DAI from reserve, wipe cdp debt, exit DROP from cdp, burn DROP, harvest junior profit
    function wipe(uint amountDAI) public auth active {
        require((cdptab() > 0), "cdp debt already repaid");

        // repayment amount should not exceed cdp debt
        if (amountDAI > cdptab()) {
            amountDAI = cdptab();
        }
        // get DAI from reserve
        reserve.hardPayout(amountDAI);
        // repay cdp debt
        dai.approve(address(mgr), amountDAI);
        mgr.wipe(amountDAI);

        // harvest junior interest & burn surplus drop
        harvest();
    }

    // harvest junior profit
    function harvest() public active {
        require((cdpink() > 0), "nothing profit to harvest");
        uint dropPrice = assessor.calcSeniorTokenPrice();
        uint lockedCollateralDAI = rmul(cdpink(), dropPrice);
        // profit => diff between the DAI value of the locked collateral in the cdp & the actual cdp debt including protection buffer
        uint requiredLocked = calcOvercollAmount(cdptab());
        if(lockedCollateralDAI < requiredLocked) {
            // nothing to harvest, currently under-collateralized
            return;
        }
        uint profitDAI = safeSub(lockedCollateralDAI, requiredLocked);
        uint profitDROP = rdiv(profitDAI, dropPrice);
        // remove profitDROP from the vault & brun them
        mgr.exit(profitDROP);
        collateral.burn(address(this), profitDROP);
        // decrease the seniorAssetValue by profitDAI -> DROP price stays constant
        updateSeniorAsset(profitDAI, 0);
    }

    // decrease MKR creditline
    function sink(uint amountDAI) public auth active {
        require(remainingCredit() >= amountDAI, "decrease amount too high");

        // creditline amount including required overcollateralization => amount by that the seniorAssetValue should be decreased
        uint overcollAmountDAI = calcOvercollAmount(amountDAI);
        // protection value for the creditline decrease going to the junior tranche => amount by that the juniorAssetValue should be increased
        uint protectionDAI = safeSub(overcollAmountDAI, amountDAI);
        // check if the new creditline would break the pool constraints
        require((validate(protectionDAI, 0, 0, overcollAmountDAI) == 0), "pool constraints violated");

        // increase MKR crediline by amount
        creditline = safeSub(creditline, amountDAI);
        // decrease in creditline impacts amount available for new loans
        assessor.changeBorrowAmountEpoch(safeSub(assessor.borrowAmountEpoch(), amountDAI));
    }

    function heal(uint amountDAI) public auth active {
        uint collatDeficitDAI = collatDeficit();
        require(collatDeficitDAI > 0, "no healing required");

        // heal max up to the required missing collateral amount
        if (collatDeficitDAI < amountDAI) {
            amountDAI = collatDeficitDAI;
        }

        require((validate(0, amountDAI, 0, 0) == 0), "supply not possible, pool constraints violated");
        //    mint drop and move into vault
        uint priceDROP = assessor.calcSeniorTokenPrice();
        uint collateralDROP = rdiv(amountDAI, priceDROP);
        tranche.mint(address(this), collateralDROP);
        collateral.approve(address(mgr), collateralDROP);
        mgr.join(collateralDROP);
        // increase seniorAsset by amountDAI
        updateSeniorAsset(0, amountDAI);
    }

    // heal the cdp and put in more drop in case the collateral value has fallen below the bufferedmat ratio
    function heal() public auth active{
        uint collatDeficitDAI = collatDeficit();
        if (collatDeficitDAI > 0) {
            heal(collatDeficitDAI);
        }
    }

    // checks if the Maker credit line increase could violate the pool constraints // -> make function pure and call with current pool values approxNav
    function validate(uint juniorSupplyDAI, uint juniorRedeemDAI, uint seniorSupplyDAI, uint seniorRedeemDAI) internal returns(int) {
        uint newAssets = safeSub(safeSub(safeAdd(safeAdd(safeAdd(assessor.totalBalance(), assessor.getNAV()), seniorSupplyDAI),
            juniorSupplyDAI), juniorRedeemDAI), seniorRedeemDAI);
        uint expectedSeniorAsset = assessor.calcExpectedSeniorAsset(seniorRedeemDAI, seniorSupplyDAI,
            assessor.seniorBalance(), assessor.seniorDebt());
        return coordinator.validateRatioConstraints(newAssets, expectedSeniorAsset);
    }

    function updateSeniorAsset(uint decreaseDAI, uint increaseDAI) internal  {
        assessor.changeSeniorAsset(increaseDAI, decreaseDAI);
    }

    // returns the debt towards mkr
    function cdptab() public view returns (uint) {
        (, uint art) = vat.urns(ilk(), mgr.urn());
        return rmul(art, stabilityFeeIndex());
    }

    // returns the collateral amount in the cdp
    function cdpink() public view returns (uint) {
        uint ink = collateral.balanceOf(address(mgr));
        return ink;
    }

    // returns the required security margin for the DROP tokens
    function mat() public view returns (uint) {
        (, uint256 mat) = spotter.ilks(ilk());
        return safeAdd(mat, matBuffer); //  e.g 150% denominated in RAY
    }

    // helper function that returns the overcollateralized DAI amount considering the current mat value
    function calcOvercollAmount(uint amountDAI) public returns (uint) {
        return rmul(amountDAI, mat());
    }

    // In case contract received DAI as a leftover from the cdp liquidation return back to reserve
    function returnDAI() public auth {
        uint amountDAI = dai.balanceOf(address(this));
        dai.approve(address(reserve), amountDAI);
        reserve.hardDeposit(amountDAI);
    }

    function changeOwnerMgr(address usr) public auth {
        mgr.file("owner", usr);
    }

    function debt() public view returns(uint) {
        return cdptab();
    }

    function stabilityFeeIndex() public view returns(uint) {
        (, uint rate, , ,) = vat.ilks(ilk());
        return rate;
    }

    function stabilityFee() public view returns(uint) {
        // mkr.duty is the stability fee in the mkr system
        (uint duty, ) =  jug.ilks(ilk());
        return duty;
    }

    function ilk() public view returns (bytes32) {
        return GemJoinLike(UrnLike(mgr.urn()).gemJoin()).ilk();
    }
}