/*
    Copyright 2021 Universal Dollar Devs, based on the works of the Empty Set Squad

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../external/Require.sol";
import "../Constants.sol";
import "./PoolSetters.sol";
import "./Liquidity.sol";
import "./PoolUpgradable.sol";

contract Pool is PoolSetters, Liquidity, PoolUpgradable {
    using SafeMath for uint256;

    function initialize(address dao, address dollar, address univ2) public {
        require(!_state.isInitialized, "Pool: already initialized");
        _state.isInitialized = true;

        _state.provider.dao = IDAO(dao);
        _state.provider.dollar = IDollar(dollar);
        _state.provider.univ2 = IERC20(univ2);
    }

    bytes32 private constant FILE = "Pool";

    event Deposit(address indexed account, uint256 value);
    event ReleaseLp(address indexed account, uint256 value);
    event ReleaseReward(address indexed account, uint256 value);
    event Bond(address indexed account, uint256 value);
    event Unbond(address indexed account, uint256 value, uint256 newClaimable);
    event Provide(address indexed account, uint256 value, uint256 lessUsdc, uint256 newUniv2);

    // Streaming LP
    event StreamStartLp(address indexed account, uint256 value, uint256 streamedUntil);
    event StreamCancelLp(address indexed account, uint256 valueToStaged);
    event StreamBoostLp(address indexed account, uint256 penalty);
    event UnstreamToStagedLp(address indexed account, uint256 value);

    // Streaming Reward
    event StreamStartReward(address indexed account, uint256 value, uint256 streamedUntil);
    event StreamCancelReward(address indexed account, uint256 valueToStaged);
    event StreamBoostReward(address indexed account, uint256 penalty);

    function deposit(uint256 value) public notPaused {
        univ2().transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(msg.sender, value);

        balanceCheck();

        emit Deposit(msg.sender, value);
    }

    // ** NEW LOGIC **

    function depositAndBond(uint256 value) external {
        deposit(value);
        bond(value);
    }

    function release() external {
        releaseLp();
        releaseReward();
    }

    /**
     * Streaming LP
     */

    function startLpStream(uint256 value) external {
        require(value > 0, "Pool: must stream non-zero amount");

        cancelLpStream();
        decrementBalanceOfStaged(msg.sender, value, "Pool: insufficient staged balance");
        setStream(streamLp(msg.sender), value, Constants.getPoolLpExitStreamPeriod());

        balanceCheck();

        emit StreamStartLp(msg.sender, value, streamedLpUntil(msg.sender));
    }

    function cancelLpStream() public {
        // already canceled or not exist
        if (streamLpReserved(msg.sender) == 0) {
            return;
        }

        releaseLp();
        uint256 amountToStaged = unreleasedLpAmount(msg.sender);
        incrementBalanceOfStaged(msg.sender, amountToStaged);
        resetStream(streamLp(msg.sender));

        balanceCheck();

        emit StreamCancelLp(msg.sender, amountToStaged);
    }

    function boostLpStream() external returns (uint256) {
        require(streamLpBoosted(msg.sender) < Constants.getPoolExitMaxBoost(), "Pool: max boost reached");

        releaseLp();

        uint256 unreleasedLp = unreleasedLpAmount(msg.sender);
        uint256 penaltyLp = Decimal.from(unreleasedLp)
                                    .mul(Constants.getPoolExitBoostPenalty())
                                    .asUint256();
        uint256 timeleft = Decimal.from(streamedLpUntil(msg.sender).sub(blockTimestamp()))
                                    .div(Constants.getPoolExitBoostCoefficient())
                                    .asUint256();

        setStream(
            streamLp(msg.sender),
            unreleasedLp.sub(penaltyLp),
            timeleft
        );
        incrementBoostCounter(streamLp(msg.sender));

        uint256 penalty = convertLpToDollar(penaltyLp); // remove liquidity and swap to dollar
        dollar().burn(penalty);

        // distribute penalty if more than one dollar
        dao().distributePenalty(penalty);

        balanceCheck();

        emit StreamBoostLp(msg.sender, penaltyLp);

        return penaltyLp;
    }

    function releaseLp() public {
        uint256 unreleasedLp = releasableLpAmount(msg.sender);

        if (unreleasedLp == 0) {
            return;
        }

        incrementReleased(streamLp(msg.sender), unreleasedLp);
        univ2().transfer(msg.sender, unreleasedLp);

        balanceCheck();

        emit ReleaseLp(msg.sender, unreleasedLp);
    }

    /**
     * Streaming Reward
     */

    function startRewardStream(uint256 value) external {
        require(value > 0, "Pool: must stream non-zero amount");

        cancelRewardStream();

        decrementBalanceOfClaimable(msg.sender, value, "Pool: insufficient claimable balance");
        incrementTotalRewardStreamable(value);

        setStream(streamReward(msg.sender), value, Constants.getPoolRewardExitStreamPeriod());

        balanceCheck();

        emit StreamStartReward(msg.sender, value, streamedRewardUntil(msg.sender));
    }

    function cancelRewardStream() public {
        // already canceled or not exist
        if (streamRewardReserved(msg.sender) == 0) {
            return;
        }

        releaseReward();

        uint256 amountToClaimable = unreleasedRewardAmount(msg.sender);

        // UIP-3 fix
        if (streamedRewardFrom(msg.sender) >= upgradeTimestamp()) {
            decrementTotalRewardStreamable(amountToClaimable, "Pool: insufficient total streamable reward");
        }

        incrementBalanceOfClaimable(msg.sender, amountToClaimable);
        resetStream(streamReward(msg.sender));

        balanceCheck();

        emit StreamCancelReward(msg.sender, amountToClaimable);
    }

    function boostRewardStream() external returns (uint256) {
        require(streamRewardBoosted(msg.sender) < Constants.getPoolExitMaxBoost(), "Pool: max boost reached");

        releaseReward();

        uint256 unreleased = unreleasedRewardAmount(msg.sender);
        uint256 penalty = Decimal.from(unreleased)
                                    .mul(Constants.getPoolExitBoostPenalty())
                                    .asUint256();
        uint256 timeleft = Decimal.from(streamedRewardUntil(msg.sender).sub(blockTimestamp()))
                                    .div(Constants.getPoolExitBoostCoefficient())
                                    .asUint256();

        // UIP-3 fix
        if (streamedRewardFrom(msg.sender) >= upgradeTimestamp()) {
            decrementTotalRewardStreamable(penalty, "Pool: insufficient total streamable reward");
        } else {
            incrementTotalRewardStreamable(unreleased.sub(penalty));
        }

        setStream(
            streamReward(msg.sender),
            unreleased.sub(penalty),
            timeleft
        );
        incrementBoostCounter(streamReward(msg.sender));

        dollar().burn(penalty);

        // distribute penalty if more than one dollar
        dao().distributePenalty(penalty);

        balanceCheck();

        emit StreamBoostReward(msg.sender, penalty);

        return penalty;
    }

    function releaseReward() public {
        uint256 unreleasedReward = releasableRewardAmount(msg.sender);

        if (unreleasedReward == 0) {
            return;
        }

        // UIP-3 fix
        if (streamedRewardFrom(msg.sender) >= upgradeTimestamp()) {
            decrementTotalRewardStreamable(unreleasedReward, "Pool: insufficient total streamable reward");
        }

        incrementReleased(streamReward(msg.sender), unreleasedReward);
        dollar().transfer(msg.sender, unreleasedReward);

        balanceCheck();

        emit ReleaseReward(msg.sender, unreleasedReward);
    }

    // ** END NEW LOGIC **

    function bond(uint256 value) public notPaused {
        // partially unstream LP and bond
        uint256 staged = balanceOfStaged(msg.sender);
        if (value > staged) {
            releaseLp();

            uint256 amountToUnstream = value.sub(staged);
            uint256 newLpReserved = unreleasedLpAmount(msg.sender).sub(amountToUnstream, "Pool: insufficient balance");
            if (newLpReserved > 0) {
                setStream(
                    streamLp(msg.sender),
                    newLpReserved,
                    streamLpTimeleft(msg.sender)
                );
                incrementBalanceOfStaged(msg.sender, amountToUnstream);

                emit UnstreamToStagedLp(msg.sender, amountToUnstream);
            }
        }

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom());
        uint256 newPhantom = totalBonded() == 0 ?
            totalRewarded() == 0 ? Constants.getInitialStakeMultiple().mul(value) : 0 :
            totalRewardedWithPhantom.mul(value).div(totalBonded());

        incrementBalanceOfBonded(msg.sender, value);
        incrementBalanceOfPhantom(msg.sender, newPhantom);
        decrementBalanceOfStaged(msg.sender, value, "Pool: insufficient staged balance");

        balanceCheck();

        emit Bond(msg.sender, value);
    }

    function unbond(uint256 value) external {
        uint256 balanceOfBonded = balanceOfBonded(msg.sender);
        Require.that(
            balanceOfBonded > 0,
            FILE,
            "insufficient bonded balance"
        );

        uint256 newClaimable = balanceOfRewarded(msg.sender).mul(value).div(balanceOfBonded);
        uint256 lessPhantom = balanceOfPhantom(msg.sender).mul(value).div(balanceOfBonded);

        incrementBalanceOfStaged(msg.sender, value);
        incrementBalanceOfClaimable(msg.sender, newClaimable);
        decrementBalanceOfBonded(msg.sender, value, "Pool: insufficient bonded balance");
        decrementBalanceOfPhantom(msg.sender, lessPhantom, "Pool: insufficient phantom balance");

        balanceCheck();

        emit Unbond(msg.sender, value, newClaimable);
    }

    function provide(uint256 value) external notPaused {
        Require.that(
            totalBonded() > 0,
            FILE,
            "insufficient total bonded"
        );

        Require.that(
            totalRewarded() > 0,
            FILE,
            "insufficient total rewarded"
        );

        Require.that(
            balanceOfRewarded(msg.sender) >= value,
            FILE,
            "insufficient rewarded balance"
        );

        (uint256 lessUsdc, uint256 newUniv2) = addLiquidity(value);

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom()).add(value);
        uint256 newPhantomFromBonded = totalRewardedWithPhantom.mul(newUniv2).div(totalBonded());

        incrementBalanceOfBonded(msg.sender, newUniv2);
        incrementBalanceOfPhantom(msg.sender, value.add(newPhantomFromBonded));


        balanceCheck();

        emit Provide(msg.sender, value, lessUsdc, newUniv2);
    }

    function emergencyWithdraw(address token, uint256 value) external onlyDao {
        IERC20(token).transfer(address(dao()), value);
    }

    function emergencyPause() external onlyDao {
        pause();
    }

    function upgrade(address newPoolImplementation) external onlyDao {
        upgradeTo(newPoolImplementation);
    }

    function balanceCheck() private {
        Require.that(
            univ2().balanceOf(address(this)) >= totalStaged().add(totalBonded()),
            FILE,
            "Inconsistent UNI-V2 balances"
        );
    }

    modifier onlyDao() {
        Require.that(
            msg.sender == address(dao()),
            FILE,
            "Not dao"
        );

        _;
    }

    modifier notPaused() {
        Require.that(
            !paused(),
            FILE,
            "Paused"
        );

        _;
    }
}