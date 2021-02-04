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

/*
    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;

/**
 * @title Require
 * @author dYdX
 *
 * Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 constant ASCII_ZERO = 48; // '0'
    uint256 constant ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 constant ASCII_LOWER_EX = 120; // 'x'
    bytes2 constant COLON = 0x3a20; // ': '
    bytes2 constant COMMA = 0x2c20; // ', '
    bytes2 constant LPAREN = 0x203c; // ' <'
    byte constant RPAREN = 0x3e; // '>'
    uint256 constant FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason)
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solium-disable-next-line security/no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // take last decimal digit
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
    private
    pure
    returns (byte)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}

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

import "./external/Decimal.sol";

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PERIOD = 240; // 10 days with 1h per epoch
    uint256 private constant BOOTSTRAPPING_PRICE = 148e16; // 1.48 USDC

    /* Oracle */
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 U8D -> 100M U8DS

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant EPOCH_OFFSET = 0;
    uint256 private constant EPOCH_START = 1611360000; // 01/23/2021 @ 12:00am (UTC)
    uint256 private constant EPOCH_PERIOD = 1 hours;

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 24; // 24 epochs
    uint256 private constant GOVERNANCE_EXPIRATION = 16; // 16 + 1 epochs
    uint256 private constant GOVERNANCE_QUORUM = 20e16; // 20%
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 1e16; // 1%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 12; // 12 epochs

    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE_USD = 70e18; // 70 USD
    uint256 private constant ADVANCE_MAX_INCENTIVE = 200e18; // 200 U8D
    uint256 private constant DAO_EXIT_STREAM_PERIOD = 120 hours; // 5 days of DAO streaming

    uint256 private constant DAO_EXIT_MAX_BOOST = uint256(-1);  // infinity - without max boost
    uint256 private constant DAO_EXIT_BOOST_COEFFICIENT = 200e16; // 200% (x2) – DAO boosting coefficient for fast streaming
    uint256 private constant DAO_EXIT_BOOST_PENALTY = 25e16; // 25% – penalty for DAO stream boosting

    /* Pool */
    uint256 private constant POOL_LP_EXIT_STREAM_PERIOD = 72 hours; // 3 days of Pool LP streaming
    uint256 private constant POOL_REWARD_EXIT_STREAM_PERIOD = 72 hours; // 3 days of Pool Reward streaming

    uint256 private constant POOL_EXIT_MAX_BOOST = uint256(-1);  // infinity - without max boost
    uint256 private constant POOL_EXIT_BOOST_COEFFICIENT = 200e16; // 200% (x2) – Pool boosting coefficient for fast streaming
    uint256 private constant POOL_EXIT_BOOST_PENALTY = 25e16; // 25% – penalty for Pool stream boosting

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 720;
    uint256 private constant DEBT_RATIO_CAP = 20e16; // 20%

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_LIMIT = 3e16; // 3%
    uint256 private constant SUPPLY_CHANGE_DIVISOR = 48e18; // 48
    uint256 private constant COUPON_SUPPLY_CHANGE_LIMIT = 6e16; // 6%
    uint256 private constant NEGATIVE_SUPPLY_CHANGE_DIVISOR = 12e18; // 12
    uint256 private constant ORACLE_POOL_RATIO = 30; // 30%
    uint256 private constant TREASURY_RATIO = 0; // 0%

    /* Not used */
    address private constant TREASURY_ADDRESS = address(0); // no treasury address

    /**
     * Getters
     */

    function getUsdcAddress() internal pure returns (address) {
        return USDC;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: EPOCH_OFFSET,
            start: EPOCH_START,
            period: EPOCH_PERIOD
        });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceExpiration() internal pure returns (uint256) {
        return GOVERNANCE_EXPIRATION;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }

    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }

    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }

    function getAdvanceIncentiveUsd() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE_USD;
    }

    function getAdvanceMaxIncentive() internal pure returns (uint256) {
        return ADVANCE_MAX_INCENTIVE;
    }

    /* DAO */

    function getDAOExitStreamPeriod() internal pure returns (uint256) {
        return DAO_EXIT_STREAM_PERIOD;
    }

    function getDAOExitMaxBoost() internal pure returns (uint256) {
        return DAO_EXIT_MAX_BOOST;
    }

    function getDAOExitBoostCoefficient() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DAO_EXIT_BOOST_COEFFICIENT});
    }

    function getDAOExitBoostPenalty() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DAO_EXIT_BOOST_PENALTY});
    }

    /* Pool */

    function getPoolLpExitStreamPeriod() internal pure returns (uint256) {
        return POOL_LP_EXIT_STREAM_PERIOD;
    }

    function getPoolRewardExitStreamPeriod() internal pure returns (uint256) {
        return POOL_REWARD_EXIT_STREAM_PERIOD;
    }

    function getPoolExitMaxBoost() internal pure returns (uint256) {
        return POOL_EXIT_MAX_BOOST;
    }

    function getPoolExitBoostCoefficient() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: POOL_EXIT_BOOST_COEFFICIENT});
    }

    function getPoolExitBoostPenalty() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: POOL_EXIT_BOOST_PENALTY});
    }

    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getSupplyChangeDivisor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_DIVISOR});
    }

    function getCouponSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: COUPON_SUPPLY_CHANGE_LIMIT});
    }

    function getNegativeSupplyChangeDivisor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: NEGATIVE_SUPPLY_CHANGE_DIVISOR});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getTreasuryRatio() internal pure returns (uint256) {
        return TREASURY_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getTreasuryAddress() internal pure returns (address) {
        return TREASURY_ADDRESS;
    }
}

/*
    Copyright 2019 dYdX Trading Inc.
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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

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
import "./PoolState.sol";
import "./PoolGetters.sol";
import "../streaming/StreamingSetters.sol";

contract PoolSetters is PoolState, PoolGetters, StreamingSetters {
    using SafeMath for uint256;

    /**
     * Global
     */

    function pause() internal {
        _state.paused = true;
    }

    function setUpgradeTimestamp() internal {
        _upgradeTimestamp = blockTimestamp();
    }

    function incrementTotalRewardStreamable(uint256 amount) internal {
        _totalRewardStreamable = _totalRewardStreamable.add(amount);
    }

    function decrementTotalRewardStreamable(uint256 amount, string memory reason) internal {
        _totalRewardStreamable = _totalRewardStreamable.sub(amount, reason);
    }

    /**
     * Account
     */

    function incrementBalanceOfBonded(address account, uint256 amount) internal {
        _state.accounts[account].bonded = _state.accounts[account].bonded.add(amount);
        _state.balance.bonded = _state.balance.bonded.add(amount);
    }

    function decrementBalanceOfBonded(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].bonded = _state.accounts[account].bonded.sub(amount, reason);
        _state.balance.bonded = _state.balance.bonded.sub(amount, reason);
    }

    function incrementBalanceOfStaged(address account, uint256 amount) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.add(amount);
        _state.balance.staged = _state.balance.staged.add(amount);
    }

    function decrementBalanceOfStaged(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.sub(amount, reason);
        _state.balance.staged = _state.balance.staged.sub(amount, reason);
    }

    function incrementBalanceOfClaimable(address account, uint256 amount) internal {
        _state.accounts[account].claimable = _state.accounts[account].claimable.add(amount);
        _state.balance.claimable = _state.balance.claimable.add(amount);
    }

    function decrementBalanceOfClaimable(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].claimable = _state.accounts[account].claimable.sub(amount, reason);
        _state.balance.claimable = _state.balance.claimable.sub(amount, reason);
    }

    function incrementBalanceOfPhantom(address account, uint256 amount) internal {
        _state.accounts[account].phantom = _state.accounts[account].phantom.add(amount);
        _state.balance.phantom = _state.balance.phantom.add(amount);
    }

    function decrementBalanceOfPhantom(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].phantom = _state.accounts[account].phantom.sub(amount, reason);
        _state.balance.phantom = _state.balance.phantom.sub(amount, reason);
    }
}

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/IDollar.sol";
import "./IDAO.sol";
import "./IUSDC.sol";
import "../streaming/Stream.sol";

contract PoolAccount {
    struct State {
        uint256 staged;
        uint256 claimable;
        uint256 bonded;
        uint256 phantom;
        Stream.Stream lpStream;
        Stream.Stream rewardStream;
    }
}

contract PoolStorage {
    struct Provider {
        IDAO dao;
        IDollar dollar;
        IERC20 univ2;
    }
    
    struct Balance {
        uint256 staged;
        uint256 claimable;
        uint256 bonded;
        uint256 phantom;
    }

    struct State {
        Balance balance;
        Provider provider;

        bool paused;
        bool isInitialized;

        mapping(address => PoolAccount.State) accounts;
    }
}

contract PoolState {
    PoolStorage.State _state;

    uint256 _totalRewardStreamable;
    uint256 _upgradeTimestamp;
}

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IDollar is IERC20 {
    function burn(uint256 amount) public;
    function burnFrom(address account, uint256 amount) public;
    function mint(address account, uint256 amount) public returns (bool);
}

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

contract IDAO {
    function distributePenalty(uint256 penalty) external;
    function epoch() external view returns (uint256);
}

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

contract IUSDC {
    function isBlacklisted(address _account) external view returns (bool);
}

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

contract Stream {
    struct Stream {
        uint256 reserved;
        uint256 released;
        uint64 timestampFrom;
        uint64 timestampTo;
        uint64 boostCounter;
    }
}

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
import "./PoolState.sol";
import "../Constants.sol";
import "../streaming/StreamingGetters.sol";

contract PoolGetters is PoolState, StreamingGetters {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    /**
     * Global
     */

    function usdc() public view returns (address) {
        return Constants.getUsdcAddress();
    }

    function dao() public view returns (IDAO) {
        return _state.provider.dao;
    }

    function dollar() public view returns (IDollar) {
        return _state.provider.dollar;
    }

    function univ2() public view returns (IERC20) {
        return _state.provider.univ2;
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalClaimable() public view returns (uint256) {
        return _state.balance.claimable;
    }

    function totalPhantom() public view returns (uint256) {
        return _state.balance.phantom;
    }

    function totalRewardStreamable() public view returns (uint256) {
        return _totalRewardStreamable;
    }

    function totalRewarded() public view returns (uint256) {
        return dollar().balanceOf(address(this)).sub(totalClaimable()).sub(totalRewardStreamable());
    }

    function paused() public view returns (bool) {
        return _state.paused;
    }

    // internal getter
    function upgradeTimestamp() internal view returns (uint256) {
        return _upgradeTimestamp;
    }

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfClaimable(address account) public view returns (uint256) {
        return _state.accounts[account].claimable;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        return _state.accounts[account].bonded;
    }

    function balanceOfPhantom(address account) public view returns (uint256) {
        return _state.accounts[account].phantom;
    }

    function balanceOfRewarded(address account) public view returns (uint256) {
        uint256 totalBonded = totalBonded();
        if (totalBonded == 0) {
            return 0;
        }

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom());
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom
            .mul(balanceOfBonded(account))
            .div(totalBonded);

        uint256 balanceOfPhantom = balanceOfPhantom(account);
        if (balanceOfRewardedWithPhantom > balanceOfPhantom) {
            return balanceOfRewardedWithPhantom.sub(balanceOfPhantom);
        }
        return 0;
    }

    /**
     * Streaming LP
     */

    // internal getter
    function streamLp(address account) internal view returns (Stream storage) {
        return _state.accounts[account].lpStream;
    }

    function streamedLpFrom(address account) public view returns (uint256) {
        return streamedFrom(streamLp(account));
    }

    function streamedLpUntil(address account) public view returns (uint256) {
        return streamedUntil(streamLp(account));
    }

    function streamLpDuration(address account) public view returns (uint256) {
        return streamDuration(streamLp(account));
    }

    function streamLpTimeleft(address account) public view returns (uint256) {
        return streamTimeleft(streamLp(account));
    }

    function streamLpReserved(address account) public view returns (uint256) {
        return streamReserved(streamLp(account));
    }

    function streamLpReleased(address account) public view returns (uint256) {
        return streamReleased(streamLp(account));
    }

    function streamLpBoosted(address account) public view returns (uint256) {
        return streamBoosted(streamLp(account));
    }

    function releasableLpAmount(address account) public view returns (uint256) {
        return releasableAmount(streamLp(account));
    }

    function unreleasedLpAmount(address account) public view returns (uint256) {
        return unreleasedAmount(streamLp(account));
    }

    /**
     * Streaming Reward
     */

    // internal getter
    function streamReward(address account) internal view returns (Stream storage) {
        return _state.accounts[account].rewardStream;
    }

    function streamedRewardFrom(address account) public view returns (uint256) {
        return streamedFrom(streamReward(account));
    }

    function streamedRewardUntil(address account) public view returns (uint256) {
        return streamedUntil(streamReward(account));
    }

    function streamRewardDuration(address account) public view returns (uint256) {
        return streamDuration(streamReward(account));
    }

    function streamRewardTimeleft(address account) public view returns (uint256) {
        return streamTimeleft(streamReward(account));
    }

    function streamRewardReserved(address account) public view returns (uint256) {
        return streamReserved(streamReward(account));
    }

    function streamRewardReleased(address account) public view returns (uint256) {
        return streamReleased(streamReward(account));
    }

    function streamRewardBoosted(address account) public view returns (uint256) {
        return streamBoosted(streamReward(account));
    }

    function releasableRewardAmount(address account) public view returns (uint256) {
        return releasableAmount(streamReward(account));
    }

    function unreleasedRewardAmount(address account) public view returns (uint256) {
        return unreleasedAmount(streamReward(account));
    }

    /**
     * Epoch
     */

    function epoch() internal view returns (uint256) {
        return dao().epoch();
    }

    function blockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }
}

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
import "./Stream.sol";

contract StreamingGetters is Stream {
    using SafeMath for uint256;

    function streamedFrom(Stream memory currentStream) internal pure returns (uint256) {
        return currentStream.timestampFrom;
    }

    function streamedUntil(Stream memory currentStream) internal pure returns (uint256) {
        return currentStream.timestampTo;
    }

    function streamDuration(Stream memory currentStream) internal pure returns (uint256) {
        return streamedUntil(currentStream).sub(streamedFrom(currentStream));
    }

    function streamTimeleft(Stream memory currentStream) internal view returns (uint256) {
        uint256 curTime = blockTimestamp();
        uint256 untilTime = streamedUntil(currentStream);

        if (curTime >= untilTime) {
            return 0;
        }

        return untilTime.sub(curTime);
    }

    function streamReserved(Stream memory currentStream) internal pure returns (uint256) {
        return currentStream.reserved;
    }

    function streamReleased(Stream memory currentStream) internal pure returns (uint256) {
        return currentStream.released;
    }

    function streamBoosted(Stream memory currentStream) internal pure returns (uint256) {
        return currentStream.boostCounter;
    }

    function releasableAmount(Stream memory currentStream) internal view returns (uint256) {
        uint256 curTime = blockTimestamp();
        uint256 untilTime = streamedUntil(currentStream);

        uint256 releasedAmount;
        if (untilTime == 0) {
            return 0;
        } else if (curTime >= untilTime) {
            releasedAmount = streamReserved(currentStream);
        } else {
            releasedAmount = streamReserved(currentStream)
                                .mul(curTime.sub(streamedFrom(currentStream)))
                                .div(streamDuration(currentStream));
        }

        return releasedAmount.sub(streamReleased(currentStream));
    }

    function unreleasedAmount(Stream memory currentStream) internal pure returns (uint256) {
        return streamReserved(currentStream).sub(streamReleased(currentStream));
    }

    function blockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }
}

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
import "./Stream.sol";
import "./StreamingGetters.sol";

contract StreamingSetters is Stream, StreamingGetters {
    using SafeMath for uint256;

    function setStream(Stream storage currentStream, uint256 amount, uint256 streamPeriod) internal {
        currentStream.reserved = amount;
        currentStream.released = 0;
        currentStream.timestampFrom = uint64(blockTimestamp());
        currentStream.timestampTo = uint64(blockTimestamp().add(streamPeriod)); // safe
    }

    function resetStream(Stream storage currentStream) internal {
        currentStream.reserved = 0;
        currentStream.released = 0;
        currentStream.timestampFrom = 0;
        currentStream.timestampTo = 0;
        currentStream.boostCounter = 0;
    }

    function incrementBoostCounter(Stream storage currentStream) internal {        
        currentStream.boostCounter++; // safe
    }

    function incrementReleased(Stream storage currentStream, uint256 amount) internal {
        currentStream.released = currentStream.released.add(amount);
    }
}

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '../external/UniswapV2Library.sol';
import "../Constants.sol";
import "./PoolGetters.sol";

contract Liquidity is PoolGetters {
    address private constant UNISWAP_FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    function addLiquidity(uint256 dollarAmount) internal returns (uint256, uint256) {
        (address dollar, address usdc) = (address(dollar()), usdc());
        (uint reserveA, uint reserveB) = getReserves(dollar, usdc);

        uint256 usdcAmount = (reserveA == 0 && reserveB == 0) ?
             dollarAmount :
             UniswapV2Library.quote(dollarAmount, reserveA, reserveB);

        address pair = address(univ2());
        IERC20(dollar).transfer(pair, dollarAmount);
        IERC20(usdc).transferFrom(msg.sender, pair, usdcAmount);
        return (usdcAmount, IUniswapV2Pair(pair).mint(address(this)));
    }

    function convertLpToDollar(uint256 liquidity) internal returns (uint256) {
        (uint256 dollarAmount, uint256 usdcAmount) = removeLiquidity(liquidity);
        return dollarAmount.add(swap(usdcAmount, usdc(), address(dollar())));
    }

    function removeLiquidity(uint256 liquidity) internal returns (uint256 dollarAmount, uint256 usdcAmount) {
        address pair = address(univ2());

        univ2().transfer(pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(address(this));

        (address dollar, address usdc) = (address(dollar()), usdc());
        (address token0,) = UniswapV2Library.sortTokens(dollar, usdc);
        (dollarAmount, usdcAmount) = dollar == token0 ? (amount0, amount1) : (amount1, amount0);
    }

    function swap(uint256 amountIn, address tokenIn, address tokenOut) internal returns (uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = getReserves(tokenIn, tokenOut);
        amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);

        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        (uint amount0Out, uint amount1Out) = tokenIn == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

        address pair = UniswapV2Library.pairFor(UNISWAP_FACTORY, tokenIn, tokenOut);
        IERC20(tokenIn).transfer(pair, amountIn);
        IUniswapV2Pair(pair).swap(
            amount0Out, amount1Out, address(this), new bytes(0)
        );
    }

    // overridable for testing
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(UniswapV2Library.pairFor(UNISWAP_FACTORY, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

/*
    Copyright 2018-2019 zOS Global Limited
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

import "@openzeppelin/upgrades/contracts/utils/Address.sol";
import "./PoolState.sol";

/**
 * Based off of, and designed to interface with, openzeppelin/upgrades package
 */
contract PoolUpgradable is PoolState {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    function initialize() public {
        require(!_state.isInitialized, "already initialized");
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function upgradeTo(address newImplementation) internal {
        setImplementation(newImplementation);

        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param newImplementation Address of the new implementation.
     */
    function setImplementation(address newImplementation) private {
        require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.5.0;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}