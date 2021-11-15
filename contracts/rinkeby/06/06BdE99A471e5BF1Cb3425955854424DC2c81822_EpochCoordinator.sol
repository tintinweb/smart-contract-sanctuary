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
pragma experimental ABIEncoderV2;

import "./../fixed_point.sol";
import "../../lib/galaxy-auth/src/auth.sol";
import "../../lib/galaxy-math/src/math.sol";

interface EpochTrancheLike {
    function epochUpdate(uint epochID, uint supplyFulfillment_,
        uint redeemFulfillment_, uint tokenPrice_, uint epochSupplyCurrency, uint epochRedeemCurrency) external;
    function closeEpoch() external returns(uint totalSupply, uint totalRedeem);
}

interface ReserveLike {
    function file(bytes32 what, uint currencyAmount) external;
    function totalBalance() external returns (uint);
}

contract AssessorLike is FixedPoint {
    function calcSeniorTokenPrice(uint NAV, uint reserve) external returns(Fixed27 memory tokenPrice);
    function calcJuniorTokenPrice(uint NAV, uint reserve) external returns(Fixed27 memory tokenPrice);
    function maxReserve() external view returns(uint);
    function calcUpdateNAV() external returns (uint);
    function seniorDebt() external returns(uint);
    function seniorBalance() external returns(uint);
    function seniorRatioBounds() external view returns(Fixed27 memory minSeniorRatio, Fixed27 memory maxSeniorRatio);
    function changeSeniorAsset(uint seniorRatio, uint seniorSupply, uint seniorRedeem) external;
}

// The EpochCoordinator keeps track of the epochs and execute epochs them.
// An epoch execution happens with the maximum amount of redeem and supply which still satisfies
// all constraints or at least improve certain pool constraints.
// In most cases all orders can be fulfilled with order maximum without violating any constraints.
// If it is not possible to satisfy all orders at maximum the coordinators opens a submission period.
// The problem of finding the maximum amount of supply and redeem orders which still satisfies all constraints
// can be seen as a linear programming (linear optimization problem).
// The optimal solution can be calculated off-chain
contract EpochCoordinator is Auth, Math, FixedPoint  {
    struct OrderSummary {
        // all variables are stored in currency
        uint  seniorRedeem;
        uint  juniorRedeem;
        uint  juniorSupply;
        uint  seniorSupply;
    }

    modifier minimumEpochTimePassed {
        require(safeSub(block.timestamp, lastEpochClosed) >= minimumEpochTime);
        _;
    }
                        // timestamp last epoch closed
    uint                public lastEpochClosed;
                        // default minimum length of an epoch
    uint                public minimumEpochTime = 1 days;

    EpochTrancheLike    public juniorTranche;
    EpochTrancheLike    public seniorTranche;

    ReserveLike         public reserve;
    AssessorLike        public assessor;

    uint                public lastEpochExecuted;
    uint                public currentEpoch;
                        // current best solution submission for an epoch which satisfies all constraints
    OrderSummary        public bestSubmission;
                        // current best score of the best solution
    uint                public bestSubScore;
                        // flag which tracks if an submission period received a valid solution
    bool                public gotFullValidSolution;
                        // snapshot from the the orders in the tranches at epoch close
    OrderSummary        public order;
                        // snapshot from the senior token price at epoch close
    Fixed27             public epochSeniorTokenPrice;
                        // snapshot from the junior token price at epoch close
    Fixed27             public epochJuniorTokenPrice;

                        // snapshot from NAV (net asset value of the loans) at epoch close
    uint                public epochNAV;
                        // snapshot from the senior asset value at epoch close
    uint                public epochSeniorAsset;
                        // snapshot from reserve balance at epoch close
    uint                public epochReserve;
                        // flag which indicates if the coordinator is currently in a submission period
    bool                public submissionPeriod;

                        // weights of the scoring function
                        // highest priority senior redeem and junior redeem before junior and senior supply
    uint                public weightSeniorRedeem  = 1000000;
    uint                public weightJuniorRedeem  =  100000;
    uint                public weightJuniorSupply =   10000;
    uint                public weightSeniorSupply =    1000;

                        // challenge period end timestamp
    uint                public minChallengePeriodEnd;
                        // after a first valid solution is received others can submit better solutions
                        // until challenge time is over
    uint                public challengeTime;
                        // if the current state is not healthy improvement submissions are allowed
                        // ratio and reserve improvements receive score points
                        // keeping track of the best improvements scores
    uint                public bestRatioImprovement;
    uint                public bestReserveImprovement;

                        // flag for closing the pool (no new supplies allowed only redeem)
    bool                public poolClosing = false;

                        // constants
    int                 public constant SUCCESS = 0;
    int                 public constant NEW_BEST = 0;
    int                 public constant ERR_CURRENCY_AVAILABLE = -1;
    int                 public constant ERR_MAX_ORDER = -2;
    int                 public constant ERR_MAX_RESERVE = - 3;
    int                 public constant ERR_MIN_SENIOR_RATIO = -4;
    int                 public constant ERR_MAX_SENIOR_RATIO = -5;
    int                 public constant ERR_NOT_NEW_BEST = -6;
    int                 public constant ERR_POOL_CLOSING = -7;
    uint                public constant BIG_NUMBER = ONE * ONE;

    uint                public constant IMPROVEMENT_WEIGHT =  10000;


    constructor(uint challengeTime_) public {
        wards[msg.sender] = 1;
        challengeTime = challengeTime_;

        lastEpochClosed = block.timestamp;
        currentEpoch = 1;
    }

    function file(bytes32 name, uint value) public auth {
        if(name == "challengeTime") {
            challengeTime = value;
        } else if (name == "minimumEpochTime") {
            minimumEpochTime = value;
        } else if (name == "weightSeniorRedeem") { weightSeniorRedeem = value;}
          else if (name == "weightJuniorRedeem") { weightJuniorRedeem = value;}
          else if (name == "weightJuniorSupply") { weightJuniorSupply = value;}
          else if (name == "weightSeniorSupply") { weightSeniorSupply = value;}
          else { revert("unkown-name");}
     }

    /// sets the dependency to another contract
    function depend (bytes32 contractName, address addr) public auth {
        if (contractName == "juniorTranche") { juniorTranche = EpochTrancheLike(addr); }
        else if (contractName == "seniorTranche") { seniorTranche = EpochTrancheLike(addr); }
        else if (contractName == "reserve") { reserve = ReserveLike(addr); }
        else if (contractName == "assessor") { assessor = AssessorLike(addr); }
        else revert();
    }

    /// an epoch can be closed after a minimum epoch time has passed
    /// closeEpoch creates a snapshot of the current lender state
    /// if all orders can be fulfilled epoch is executed otherwise
    /// submission period starts
    function closeEpoch() external minimumEpochTimePassed {
        require(submissionPeriod == false);
        lastEpochClosed = block.timestamp;
        currentEpoch = currentEpoch + 1;

        reserve.file("currencyAvailable", 0);

        (uint orderJuniorSupply, uint orderJuniorRedeem) = juniorTranche.closeEpoch();
        (uint orderSeniorSupply, uint orderSeniorRedeem) = seniorTranche.closeEpoch();

        //  if no orders exist epoch can be executed without validation
        if (orderSeniorRedeem == 0 && orderJuniorRedeem == 0 &&
        orderSeniorSupply == 0 && orderJuniorSupply == 0) {

            juniorTranche.epochUpdate(currentEpoch, 0, 0, 0, orderJuniorSupply, orderJuniorRedeem);
            seniorTranche.epochUpdate(currentEpoch, 0, 0, 0, orderSeniorSupply, orderSeniorRedeem);
            lastEpochExecuted = safeAdd(lastEpochExecuted, 1);
            return;
        }

        // create a snapshot of the current lender state
        epochNAV = assessor.calcUpdateNAV();
        epochReserve = reserve.totalBalance();

        // calculate current token prices which are used for the execute
        epochSeniorTokenPrice = assessor.calcSeniorTokenPrice(epochNAV, epochReserve);
        epochJuniorTokenPrice = assessor.calcJuniorTokenPrice(epochNAV, epochReserve);

        // start closing the pool if juniorTranche lost everything
        // the flag will change the behaviour of the validate function for not allowing new supplies
        if(epochJuniorTokenPrice.value == 0) {
            poolClosing = true;
        }

        epochSeniorAsset = safeAdd(assessor.seniorDebt(), assessor.seniorBalance());

        // convert redeem orders in token into currency
        order.seniorRedeem = rmul(orderSeniorRedeem, epochSeniorTokenPrice.value);
        order.juniorRedeem = rmul(orderJuniorRedeem, epochJuniorTokenPrice.value);
        order.juniorSupply = orderJuniorSupply;
        order.seniorSupply = orderSeniorSupply;

        // epoch is executed if orders can be fulfilled to 100% without constraint violation
        if (validate(order.seniorRedeem , order.juniorRedeem,
            order.seniorSupply, order.juniorSupply) == SUCCESS) {
            _executeEpoch(order.seniorRedeem, order.juniorRedeem,
                orderSeniorSupply, orderJuniorSupply);
            return;
        }
        // if 100% order fulfillment is not possible submission period starts
        // challenge period time starts after first valid submission is received
        submissionPeriod = true;
    }


    //// internal method to save new optimum
    //// orders are expressed as currency
    //// all parameter are 10^18
    function _saveNewOptimum(uint seniorRedeem, uint juniorRedeem, uint juniorSupply,
        uint seniorSupply, uint score) internal {

        bestSubmission.seniorRedeem = seniorRedeem;
        bestSubmission.juniorRedeem = juniorRedeem;
        bestSubmission.juniorSupply = juniorSupply;
        bestSubmission.seniorSupply = seniorSupply;

        bestSubScore = score;
    }


    /// method to submit a solution for submission period
    /// anybody can submit a solution for the current execution epoch
    /// if solution satisfies all constraints (or at least improves an unhealthy state)
    /// and has the highest score
    function submitSolution(uint seniorRedeem, uint juniorRedeem,
        uint juniorSupply, uint seniorSupply) public returns(int) {
        require(submissionPeriod == true, "submission-period-not-active");

        int valid = _submitSolution(seniorRedeem, juniorRedeem, juniorSupply, seniorSupply);

        // if solution is the first valid for this epoch the challenge period starts
        if(valid == SUCCESS && minChallengePeriodEnd == 0) {
            minChallengePeriodEnd = safeAdd(block.timestamp, challengeTime);
        }
        return valid;
    }

    // internal method for submit solution
    function _submitSolution(uint seniorRedeem, uint juniorRedeem,
        uint juniorSupply, uint seniorSupply) internal returns(int) {

        int valid = validate(seniorRedeem, juniorRedeem, seniorSupply, juniorSupply);

        // every solution needs to satisfy all core constraints
        // there is no exception
        if(valid  == ERR_CURRENCY_AVAILABLE || valid == ERR_MAX_ORDER) {
            // core constraint violated
            return valid;
        }

        // all core constraints and all pool constraints are satisfied
        if(valid == SUCCESS) {
            uint score = scoreSolution(seniorRedeem, juniorRedeem, seniorSupply, juniorSupply);

            if(gotFullValidSolution == false) {
                gotFullValidSolution = true;
                _saveNewOptimum(seniorRedeem, juniorRedeem, juniorSupply, seniorSupply, score);
                // solution is new best => 0
                return SUCCESS;
            }

            if (score < bestSubScore) {
                // solution is not the best => -6
                return ERR_NOT_NEW_BEST;
            }

            _saveNewOptimum(seniorRedeem, juniorRedeem, juniorSupply, seniorSupply, score);

            // solution is new best => 0
            return SUCCESS;
        }

        // proposed solution does not satisfy all pool constraints
        // if we never received a solution which satisfies all constraints for this epoch
        // we might accept it as an improvement
        if (gotFullValidSolution == false) {
            return _improveScore(seniorRedeem, juniorRedeem, juniorSupply, seniorSupply);
        }

        // proposed solution doesn't satisfy the pool constraints but a previous submission did
        return ERR_NOT_NEW_BEST;
    }

    function absDistance(uint x, uint y) public pure returns(uint delta) {
        if (x == y) {
            // gas optimization: for avoiding an additional edge case of 0 distance
            // distance is set to the smallest value possible
            return 1;
        }
        if(x > y) {
            return safeSub(x, y);
        }
        return safeSub(y, x);
    }

    function checkRatioInRange(Fixed27 memory ratio, Fixed27 memory minRatio,
        Fixed27 memory maxRatio) public pure returns (bool) {
        if (ratio.value >= minRatio.value && ratio.value <= maxRatio.value ) {
            return true;
        }
        return false;
    }

    /// calculates the improvement score of a solution
    function _improveScore(uint seniorRedeem, uint juniorRedeem,
        uint juniorSupply, uint seniorSupply) internal returns(int) {
        Fixed27 memory currSeniorRatio = Fixed27(calcSeniorRatio(epochSeniorAsset,
            epochNAV, epochReserve));

        int err = 0;
        uint impScoreRatio = 0;
        uint impScoreReserve = 0;

        if (bestRatioImprovement == 0) {
            // define no orders (current status) score as benchmark if no previous submission exists
            // if the current state satisfies all pool constraints it has the highest score
            (err, impScoreRatio, impScoreReserve) = scoreImprovement(currSeniorRatio, epochReserve);
            saveNewImprovement(impScoreRatio, impScoreReserve);
        }

        uint newReserve = calcNewReserve(seniorRedeem, juniorRedeem, seniorSupply, juniorSupply);

        Fixed27 memory newSeniorRatio = Fixed27(calcSeniorRatio(calcSeniorAssetValue(seniorRedeem, seniorSupply,
            epochSeniorAsset, newReserve, epochNAV), epochNAV, newReserve));

        (err, impScoreRatio, impScoreReserve) = scoreImprovement(newSeniorRatio, newReserve);

        if (err  == ERR_NOT_NEW_BEST) {
            // solution is not the best => -1
            return err;
        }

        saveNewImprovement(impScoreRatio, impScoreReserve);

        // solution doesn't satisfy all pool constraints but improves the current violation
        // improvement only gets 0 points only solutions in the feasible region receive more
        _saveNewOptimum(seniorRedeem, juniorRedeem, juniorSupply, seniorSupply, 0);
        return NEW_BEST;
    }

    // the score improvement reserve uses the normalized distance to maxReserve/2 as score
    // as smaller the distance as higher is the score
    // highest possible score if solution is not violating the reserve
    function scoreReserveImprovement(uint newReserve_) public view returns (uint score) {
        if (newReserve_ <= assessor.maxReserve()) {
            // highest possible score
            return BIG_NUMBER;
        }
        // normalize reserve by defining maxReserve as ONE
        Fixed27 memory normalizedNewReserve = Fixed27(rdiv(newReserve_, assessor.maxReserve()));

        return rmul(IMPROVEMENT_WEIGHT, rdiv(ONE,  absDistance(safeDiv(ONE, 2), normalizedNewReserve.value)));
    }

    // the score improvement ratio uses the normalized distance to (minRatio+maxRatio)/2 as score
    // as smaller the distance as higher is the score
    // highest possible score if solution is not violating the ratio
    function scoreRatioImprovement(Fixed27 memory newSeniorRatio) public view returns (uint) {
        (Fixed27 memory minSeniorRatio, Fixed27 memory maxSeniorRatio) = assessor.seniorRatioBounds();
        if (checkRatioInRange(newSeniorRatio, minSeniorRatio, maxSeniorRatio) == true) {

            // highest possible score
            return BIG_NUMBER;
        }
        // absDistance of ratio can never be zero
        return rmul(IMPROVEMENT_WEIGHT, rdiv(ONE, absDistance(newSeniorRatio.value,
                safeDiv(safeAdd(minSeniorRatio.value, maxSeniorRatio.value), 2))));
    }

    // internal method to save new improvement score
    function saveNewImprovement(uint impScoreRatio, uint impScoreReserve) internal {
        bestRatioImprovement = impScoreRatio;
        bestReserveImprovement = impScoreReserve;
    }

    /// calculates improvement score for reserve and ratio pool constraints
    function scoreImprovement(Fixed27 memory newSeniorRatio_, uint newReserve_) public view returns(int, uint, uint) {
        uint impScoreRatio = scoreRatioImprovement(newSeniorRatio_);
        uint impScoreReserve = scoreReserveImprovement(newReserve_);

        // the highest priority has fixing the currentSeniorRatio
        // if the ratio is improved, we can ignore reserve
        if (impScoreRatio > bestRatioImprovement) {
            // we found a new best
            return (NEW_BEST, impScoreRatio, impScoreReserve);
        }

        // only if the submitted solution ratio score equals the current best ratio
        // we determine if the submitted solution improves the reserve
        if (impScoreRatio == bestRatioImprovement) {
              if (impScoreReserve >= bestReserveImprovement) {
                  return (NEW_BEST, impScoreRatio, impScoreReserve);
              }
        }
        return (ERR_NOT_NEW_BEST, impScoreRatio, impScoreReserve);
    }

    /// scores a solution in the submission period
    /// the scoring function is a linear function with high weights as coefficient to determine
    /// the priorities. (non-preemptive goal programming)
    function scoreSolution(uint seniorRedeem, uint juniorRedeem,
        uint juniorSupply, uint seniorSupply) public view returns(uint) {
        // the default priority order
        // 1. senior redeem
        // 2. junior redeem
        // 3. junior supply
        // 4. senior supply
        return safeAdd(safeAdd(safeMul(seniorRedeem, weightSeniorRedeem), safeMul(juniorRedeem, weightJuniorRedeem)),
            safeAdd(safeMul(juniorSupply, weightJuniorSupply), safeMul(seniorSupply, weightSeniorSupply)));
    }

    /// validates if a solution satisfy the core constraints
    /// returns: first constraint which is not satisfied or success
    function validateCoreConstraints(uint currencyAvailable, uint currencyOut, uint seniorRedeem, uint juniorRedeem,
        uint seniorSupply, uint juniorSupply) public view returns (int err) {
        // constraint 1: currency available
        if (currencyOut > currencyAvailable) {
            // currencyAvailableConstraint => -1
            return ERR_CURRENCY_AVAILABLE;
        }

        // constraint 2: max order
        if (seniorSupply > order.seniorSupply ||
        juniorSupply > order.juniorSupply ||
        seniorRedeem > order.seniorRedeem ||
            juniorRedeem > order.juniorRedeem) {
            // maxOrderConstraint => -2
            return ERR_MAX_ORDER;
        }

        // successful => 0
        return SUCCESS;
    }


    /// validates if a solution satisfies the pool constraints
    /// returns: first constraint which is not satisfied or success
    function validatePoolConstraints(uint reserve_, uint seniorAsset, uint nav_) public view returns (int err) {
        // constraint 3: max reserve
        if (reserve_ > assessor.maxReserve()) {
            // maxReserveConstraint => -3
            return ERR_MAX_RESERVE;
        }

        uint assets = safeAdd(nav_, reserve_);

        (Fixed27 memory minSeniorRatio, Fixed27 memory maxSeniorRatio) = assessor.seniorRatioBounds();

        // constraint 4: min senior ratio constraint
        if (seniorAsset < rmul(assets, minSeniorRatio.value)) {
            // minSeniorRatioConstraint => -4
            return ERR_MIN_SENIOR_RATIO;
        }
        // constraint 5: max senior ratio constraint
        if (seniorAsset > rmul(assets, maxSeniorRatio.value)) {
            // maxSeniorRatioConstraint => -5
            return ERR_MAX_SENIOR_RATIO;
        }
        // successful => 0
        return SUCCESS;
    }

    /// validates if a solution satisfies core and pool constraints
    /// returns: first constraint which is not satisfied or success
    function validate(uint seniorRedeem, uint juniorRedeem,
        uint seniorSupply, uint juniorSupply) public view returns (int) {

        uint currencyAvailable = safeAdd(safeAdd(epochReserve, seniorSupply), juniorSupply);
        uint currencyOut = safeAdd(seniorRedeem, juniorRedeem);

        int err = validateCoreConstraints(currencyAvailable, currencyOut, seniorRedeem,
            juniorRedeem, seniorSupply, juniorSupply);

        if(err != SUCCESS) {
            return err;
        }

        uint newReserve = safeSub(currencyAvailable, currencyOut);
        if(poolClosing == true) {
            if(seniorSupply == 0 && juniorSupply == 0) {
                return SUCCESS;
            }
            return ERR_POOL_CLOSING;

        }
        return validatePoolConstraints(newReserve, calcSeniorAssetValue(seniorRedeem, seniorSupply,
            epochSeniorAsset, newReserve, epochNAV), epochNAV);
    }

    /// public method to execute an epoch which required a submission period and the challenge period is over
    function executeEpoch() public {
        require(block.timestamp >= minChallengePeriodEnd && minChallengePeriodEnd != 0);

        _executeEpoch(bestSubmission.seniorRedeem ,bestSubmission.juniorRedeem,
            bestSubmission.seniorSupply, bestSubmission.juniorSupply);
    }

    /// calculates a new senior asset value based on senior redeem and senior supply
    function calcSeniorAssetValue(uint seniorRedeem, uint seniorSupply,
        uint currSeniorAsset, uint reserve_, uint nav_) public pure returns (uint seniorAsset) {

        seniorAsset =  safeSub(safeAdd(currSeniorAsset, seniorSupply), seniorRedeem);
        uint assets = calcAssets(nav_, reserve_);
        if(seniorAsset > assets) {
            seniorAsset = assets;
        }

        return seniorAsset;
    }

    /// calculates the net wealth in the system
    /// NAV for ongoing loans and currency in reserve
    function calcAssets(uint NAV, uint reserve_) public pure returns(uint) {
        return safeAdd(NAV, reserve_);
    }


    /// calculates the senior ratio
    function calcSeniorRatio(uint seniorAsset, uint NAV, uint reserve_) public pure returns(uint) {
        // note: NAV + reserve == seniorAsset + juniorAsset (loop invariant: always true)
        uint assets = calcAssets(NAV, reserve_);
        if(assets == 0) {
            return 0;
        }
        return rdiv(seniorAsset, assets);
    }

    /// calculates the percentage of an order type which can be fulfilled for an epoch
    function calcFulfillment(uint amount, uint totalOrder) public pure returns(Fixed27 memory percent) {
        if(amount == 0 || totalOrder == 0) {
            return Fixed27(0);
        }
        return Fixed27(rdiv(amount, totalOrder));
    }

    /// calculates the new reserve after a solution would be executed
    function calcNewReserve(uint seniorRedeem, uint juniorRedeem,
        uint seniorSupply, uint juniorSupply) public view returns(uint) {

        return safeSub(safeAdd(safeAdd(epochReserve, seniorSupply), juniorSupply),
            safeAdd(seniorRedeem, juniorRedeem));
    }

    /// internal execute epoch communicates the order fulfillment of the best solution to the tranches
    function _executeEpoch(uint seniorRedeem, uint juniorRedeem,
        uint seniorSupply, uint juniorSupply) internal {

        uint epochID = safeAdd(lastEpochExecuted, 1);

        seniorTranche.epochUpdate(epochID, calcFulfillment(seniorSupply, order.seniorSupply).value,
            calcFulfillment(seniorRedeem, order.seniorRedeem).value,
            epochSeniorTokenPrice.value,order.seniorSupply, order.seniorRedeem);

        juniorTranche.epochUpdate(epochID, calcFulfillment(juniorSupply, order.juniorSupply).value,
            calcFulfillment(juniorRedeem, order.juniorRedeem).value,
            epochJuniorTokenPrice.value, order.juniorSupply, order.juniorRedeem);

        uint newReserve = calcNewReserve(seniorRedeem, juniorRedeem
        , seniorSupply, juniorSupply);

        uint seniorAsset = calcSeniorAssetValue(seniorRedeem, seniorSupply,
           epochSeniorAsset, newReserve, epochNAV);

        uint newSeniorRatio = calcSeniorRatio(seniorAsset, epochNAV, newReserve);

        // assessor performs senior debt reBalancing according to new ratio
        assessor.changeSeniorAsset(newSeniorRatio, seniorSupply, seniorRedeem);
        // the new reserve after this epoch can be used for new loans
        reserve.file("currencyAvailable", newReserve);
        // reset state for next epochs
        lastEpochExecuted = epochID;
        submissionPeriod = false;
        minChallengePeriodEnd = 0;
        bestSubScore = 0;
        gotFullValidSolution = false;
        bestRatioImprovement = 0;
        bestReserveImprovement = 0;
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

pragma solidity >=0.5.15 <0.6.0;

contract FixedPoint {
    struct Fixed27 {
        uint value;
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

pragma solidity >=0.5.15 <0.6.0;

import "../../ds-note/src/note.sol";

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
pragma solidity >=0.5.15;

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

