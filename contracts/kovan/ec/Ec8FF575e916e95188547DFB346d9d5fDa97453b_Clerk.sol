/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/lender/adapters/mkr/clerk.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.6.12;

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

////// src/lender/adapters/mkr/clerk.sol
/* pragma solidity >=0.6.12; */

/* import "tinlake-auth/auth.sol"; */
/* import "tinlake-math/interest.sol"; */

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
    function drip(bytes32 ilk) external returns (uint rate);
    function base() external view returns(uint);
}

interface GemJoinLike {
    function ilk() external view returns(bytes32);
}

interface UrnLike {
    function gemJoin() external view returns(address);
}

interface AssessorLike_2 {
    function calcSeniorTokenPrice() external view returns(uint);
    function calcSeniorAssetValue(uint seniorDebt_, uint seniorBalance_) external view returns(uint);
    function changeSeniorAsset(uint seniorSupply, uint seniorRedeem) external;
    function seniorDebt() external view returns(uint);
    function seniorBalance() external view returns(uint);
    function getNAV() external view returns(uint);
    function totalBalance() external view returns(uint);
    function calcExpectedSeniorAsset(uint seniorRedeem, uint seniorSupply, uint seniorBalance_, uint seniorDebt_) external view returns(uint);
    function changeBorrowAmountEpoch(uint currencyAmount) external;
    function borrowAmountEpoch() external view returns(uint);
}

interface CoordinatorLike_1 {
    function validateRatioConstraints(uint assets, uint seniorAsset) external view returns(int);
    function calcSeniorAssetValue(uint seniorRedeem, uint seniorSupply, uint currSeniorAsset, uint reserve_, uint nav_) external returns(uint);
    function calcSeniorRatio(uint seniorAsset, uint NAV, uint reserve_) external returns(uint);
    function submissionPeriod() external view returns(bool);
}

interface ReserveLike_3 {
    function totalBalance() external returns(uint);
    function hardDeposit(uint daiAmount) external;
    function hardPayout(uint currencyAmount) external;
}

interface TrancheLike_1 {
    function mint(address usr, uint amount) external;
    function token() external returns(address);
}

interface ERC20Like_1 {
    function burn(address, uint) external;
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address usr, uint amount) external;
}

contract Clerk is Auth, Interest {

    // max amount of DAI that can be brawn from MKR
    uint public creditline;

    // tinlake contracts
    CoordinatorLike_1 public coordinator;
    AssessorLike_2 public assessor;
    ReserveLike_3 public reserve;
    TrancheLike_1 public tranche;

    // MKR contracts
    ManagerLike public mgr;
    VatLike public vat;
    SpotterLike public spotter;
    JugLike public jug;

    ERC20Like_1 public immutable dai;
    ERC20Like_1 public collateral;

    uint public constant WAD = 10*18;

    // buffer to add on top of mat to avoid cdp liquidation => default 1%
    uint public matBuffer = 0.01 * 10**27;

    // collateral tolerance accepted because of potential rounding problems
    uint public collateralTolerance = 10;

    // the debt is only repaid if amount is higher than the threshold
    // repaying a lower amount would cause more cost in gas fees than the debt reduction
    uint public wipeThreshold = 1 * WAD;

    // adapter functions can only be active if the tinlake pool is currently not in epoch closing/submissions/execution state
    modifier active() { require(activated(), "epoch-closing"); _; }

    function activated() public view returns(bool) {
        return coordinator.submissionPeriod() == false && mkrActive();
    }

    function mkrActive() public view returns (bool) {
        return mgr.safe() && mgr.glad() && mgr.live();
    }

    event Depend(bytes32 indexed contractName, address addr);
    event File(bytes32 indexed what, uint value);

    constructor(address dai_, address collateral_) {
        dai = ERC20Like_1(dai_);
        collateral =  ERC20Like_1(collateral_);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "mgr") {
            mgr =  ManagerLike(addr);
        } else if (contractName == "coordinator") {
            coordinator = CoordinatorLike_1(addr);
        } else if (contractName == "assessor") {
            assessor = AssessorLike_2(addr);
        } else if (contractName == "reserve") {
            reserve = ReserveLike_3(addr);
        } else if (contractName == "tranche") {
            tranche = TrancheLike_1(addr);
        } else if (contractName == "collateral") {
            collateral = ERC20Like_1(addr);
        } else if (contractName == "spotter") {
            spotter = SpotterLike(addr);
        } else if (contractName == "vat") {
            vat = VatLike(addr);
        } else if (contractName == "jug") {
            jug = JugLike(addr);
        } else revert();
        emit Depend(contractName, addr);
    }

    function file(bytes32 what, uint value) public auth {
        if (what == "buffer") {
            matBuffer = value;
        } else if (what == "tolerance") {
            collateralTolerance = value;
        } else if (what == "wipeThreshold") {
            wipeThreshold = value;
        } else { revert(); }
        emit File(what, value);
    }

    function remainingCredit() public view returns (uint) {
        uint debt_ = debt();
        if (creditline <= debt_ || mkrActive() == false) {
            return 0;
        }
        return safeSub(creditline, debt_);
    }

    function collatDeficit() public view returns (uint) {
        uint lockedCollateralDAI = rmul(cdpink(), assessor.calcSeniorTokenPrice());
        uint requiredCollateralDAI = calcOvercollAmount(debt());

        if(requiredCollateralDAI > collateralTolerance){
            requiredCollateralDAI = safeSub(requiredCollateralDAI, collateralTolerance);
        }

        if (requiredCollateralDAI > lockedCollateralDAI) {
            return safeSub(requiredCollateralDAI, lockedCollateralDAI);
        }
        return 0;
    }

    function remainingOvercollCredit() public view returns (uint) {
        return calcOvercollAmount(remainingCredit());
    }

    // junior stake in the cdpink -> value of drop used for debt protection
    function juniorStake() public view returns (uint) {
        // junior looses stake in case vault is in soft/hard liquidation mode
        uint collateralValue = rmul(cdpink(), assessor.calcSeniorTokenPrice());
        uint mkrDebt = debt();
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
        require((validate(0, protectionDAI, overcollAmountDAI, 0) == 0), "violates-constraints");
        // increase MKR crediline by amount
        creditline = safeAdd(creditline, amountDAI);
        // make increase in creditline available to new loans
        assessor.changeBorrowAmountEpoch(safeAdd(assessor.borrowAmountEpoch(), amountDAI));
    }

    // mint DROP, join DROP into cdp, draw DAI and send to reserve
    function draw(uint amountDAI) public auth active {
        //make sure there is no collateral deficit before drawing out new DAI
        require(collatDeficit() == 0, "please-heal-cdp-first"); 
        require(amountDAI <= remainingCredit(), "not-enough-credit-left");
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
        // if amountDAI is too low, required transaction fees of wipe would be higher
        // only continue with wipe if amountDAI is higher than wipeThreshold;
        if(amountDAI < wipeThreshold) {
            return;
        }

        uint debt_ = debt();
        require((debt_ > 0), "cdp-debt-already-repaid");

        // repayment amount should not exceed cdp debt
        if (amountDAI > debt_) {
            amountDAI = debt_;
        }

        uint dropPrice = assessor.calcSeniorTokenPrice();
        // get DAI from reserve
        reserve.hardPayout(amountDAI);
        // repay cdp debt
        dai.approve(address(mgr), amountDAI);
        mgr.wipe(amountDAI);
        // harvest junior interest & burn surplus drop
        _harvest(dropPrice);
    }

    // harvest junior profit
    function harvest() public active {
        _harvest(assessor.calcSeniorTokenPrice());
    }

    function _harvest(uint dropPrice) internal {
        require((cdpink() > 0), "no-profit-to-harvest");

        uint lockedCollateralDAI = rmul(cdpink(), dropPrice);
        // profit => diff between the DAI value of the locked collateral in the cdp & the actual cdp debt including protection buffer
        uint requiredLocked = calcOvercollAmount(debt());

        if(lockedCollateralDAI < requiredLocked) {
            // nothing to harvest, currently under-collateralized;
            return;
        }
        uint profitDAI = safeSub(lockedCollateralDAI, requiredLocked);
        uint profitDROP = safeDiv(safeMul(profitDAI, ONE), dropPrice);
        // remove profitDROP from the vault & brun them
        mgr.exit(profitDROP);
        collateral.burn(address(this), profitDROP);
        // decrease the seniorAssetValue by profitDAI -> DROP price stays constant
        updateSeniorAsset(profitDAI, 0);
    }

    // decrease MKR creditline
    function sink(uint amountDAI) public auth active {
        require(remainingCredit() >= amountDAI, "decrease-amount-too-high");

        // creditline amount including required overcollateralization => amount by that the seniorAssetValue should be decreased
        uint overcollAmountDAI = calcOvercollAmount(amountDAI);
        // protection value for the creditline decrease going to the junior tranche => amount by that the juniorAssetValue should be increased
        uint protectionDAI = safeSub(overcollAmountDAI, amountDAI);
        // check if the new creditline would break the pool constraints
        require((validate(protectionDAI, 0, 0, overcollAmountDAI) == 0), "pool-constraints-violated");

        // increase MKR crediline by amount
        creditline = safeSub(creditline, amountDAI);
        // decrease in creditline impacts amount available for new loans

        uint borrowAmountEpoch = assessor.borrowAmountEpoch();

        if(borrowAmountEpoch <= amountDAI) {
            assessor.changeBorrowAmountEpoch(0);
            return;
        }

        assessor.changeBorrowAmountEpoch(safeSub(borrowAmountEpoch, amountDAI));
    }

    function heal(uint amountDAI) public auth active {
        uint collatDeficitDAI = collatDeficit();
        require(collatDeficitDAI > 0, "no-healing-required");

        // heal max up to the required missing collateral amount
        if (collatDeficitDAI < amountDAI) {
            amountDAI = collatDeficitDAI;
        }

        require((validate(0, amountDAI, 0, 0) == 0), "violates-constraints");
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
    function validate(uint juniorSupplyDAI, uint juniorRedeemDAI, uint seniorSupplyDAI, uint seniorRedeemDAI) public view returns(int) {
        uint newAssets = safeSub(safeSub(safeAdd(safeAdd(safeAdd(assessor.totalBalance(), assessor.getNAV()), seniorSupplyDAI),
            juniorSupplyDAI), juniorRedeemDAI), seniorRedeemDAI);
        uint expectedSeniorAsset = assessor.calcExpectedSeniorAsset(seniorRedeemDAI, seniorSupplyDAI,
            assessor.seniorBalance(), assessor.seniorDebt());
        return coordinator.validateRatioConstraints(newAssets, expectedSeniorAsset);
    }

    function updateSeniorAsset(uint decreaseDAI, uint increaseDAI) internal  {
        assessor.changeSeniorAsset(increaseDAI, decreaseDAI);
    }

    // returns the collateral amount in the cdp
    function cdpink() public view returns (uint) {
        uint ink = collateral.balanceOf(address(mgr));
        return ink;
    }

    // returns the required security margin for the DROP tokens
    function mat() public view returns (uint) {
        (, uint256 mat_) = spotter.ilks(ilk());
        return safeAdd(mat_, matBuffer); //  e.g 150% denominated in RAY
    }

    // helper function that returns the overcollateralized DAI amount considering the current mat value
    function calcOvercollAmount(uint amountDAI) public view returns (uint) {
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

    // returns the current debt from the Maker vault
    function debt() public view returns(uint) {
        bytes32 ilk_ = ilk();
        // get debt index
        (, uint art) = vat.urns(ilk_, mgr.urn());

        // get accumulated interest rate index
        (, uint rateIdx,,,) = vat.ilks(ilk_);

        // get interest rate per second and last interest rate update timestamp
        (uint duty, uint rho) = jug.ilks(ilk_);

        // interest accumulation up to date
        if (block.timestamp == rho) {
            return rmul(art, rateIdx);
        }

        // calculate current debt (see jug.drip function in MakerDAO)
        return rmul(art, rmul(rpow(safeAdd(jug.base(), duty), safeSub(block.timestamp, rho), ONE), rateIdx));
    }
    function stabilityFeeIndex() public view returns(uint) {
        (, uint rate, , ,) = vat.ilks(ilk());
        return rate;
    }

    function stabilityFee() public view returns(uint) {
        // mkr.duty is the stability fee in the mkr system
        (uint duty, ) =  jug.ilks(ilk());
        return safeAdd(jug.base(), duty);
    }

    function ilk() public view returns (bytes32) {
        return GemJoinLike(UrnLike(mgr.urn()).gemJoin()).ilk();
    }
}