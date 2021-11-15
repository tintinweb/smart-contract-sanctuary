pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "synthetix/contracts/interfaces/IFeePool.sol";
import "synthetix/contracts/interfaces/IRewardEscrow.sol";
import "synthetix/contracts/interfaces/ISynthetix.sol";
import "synthetix/contracts/interfaces/IStakingRewards.sol";

interface ISNX is ISynthetix {
    function balanceOf(address account) external view returns(uint);
}

contract StakingGetter {

    struct StakedTokenResult {
        address rewardContract;
        uint stakedBalance;
        uint earnedAmount;
    }
    struct RewardResult {
        uint susdFeesAvailable;
        uint snxRewardsAvailable;
        uint snxBalance;
        uint escrowBalance;
        uint collateral;
        uint transferableSynthetix;
        uint collateralizationRatio;
        StakedTokenResult[] stakedTokenResults;
    }

    IFeePool private constant FEE_POOL = IFeePool(0x013D16CB1Bd493bBB89D45b43254842FadC169C8);
    ISNX private constant SYNTHETIX = ISNX(0xf87A0587Fe48Ca05dd68a514Ce387C0d4d3AE31C);
    IRewardEscrow private constant REWARD_ESCROW = IRewardEscrow(0xb671F2210B1F6621A2607EA63E6B2DC3e2464d1F);

    constructor () public {}

    function getAllStakingRewards(address[] memory wallets, address[] memory rewards) public view returns (RewardResult[] memory results) {
        results = new RewardResult[](wallets.length);
        for (uint i = 0; i < wallets.length; i++) {
            results[i] = getRewardResult(wallets[i], rewards);
        }
        return results;
    }

    function getRewardResult(address wallet, address[] memory rewards) public view returns (RewardResult memory result) {
        (uint susdFeesAvailable, uint snxRewardsAvailable) = FEE_POOL.feesAvailable(wallet);
        uint snxBalance = SYNTHETIX.balanceOf(wallet);
        uint escrowBalance = REWARD_ESCROW.totalEscrowedAccountBalance(wallet);
        uint collateral = SYNTHETIX.collateral(wallet);
        uint transferableSynthetix = SYNTHETIX.transferableSynthetix(wallet);
        uint collateralizationRatio = SYNTHETIX.collateralisationRatio(wallet);
        StakedTokenResult[] memory stakedTokenResults = getStakedTokenResults(wallet, rewards);
        return RewardResult(
            susdFeesAvailable,
            snxRewardsAvailable,
            snxBalance,
            escrowBalance,
            collateral,
            transferableSynthetix,
            collateralizationRatio,
            stakedTokenResults
        );
    }

    function getStakedTokenResults(address wallet, address[] memory rewards) public view returns (StakedTokenResult[] memory stakedTokenResults) {
        stakedTokenResults = new StakedTokenResult[](rewards.length);
        for (uint i = 0; i < rewards.length; i++) {
            IStakingRewards rewardContract = IStakingRewards(rewards[i]);
            uint stakedBalance = rewardContract.balanceOf(wallet);
            uint earnedAmount = rewardContract.earned(wallet);
            stakedTokenResults[i] = StakedTokenResult(address(rewardContract), stakedBalance, earnedAmount);
        }
        return stakedTokenResults;
    }
}

pragma solidity >=0.4.24;


// https://docs.synthetix.io/contracts/source/interfaces/ifeepool
interface IFeePool {
    // Views

    // solhint-disable-next-line func-name-mixedcase
    function FEE_ADDRESS() external view returns (address);

    function feesAvailable(address account) external view returns (uint, uint);

    function feePeriodDuration() external view returns (uint);

    function isFeesClaimable(address account) external view returns (bool);

    function targetThreshold() external view returns (uint);

    function totalFeesAvailable() external view returns (uint);

    function totalRewardsAvailable() external view returns (uint);

    // Mutative Functions
    function claimFees() external returns (bool);

    function claimOnBehalf(address claimingForAddress) external returns (bool);

    function closeCurrentFeePeriod() external;

    // Restricted: used internally to Synthetix
    function appendAccountIssuanceRecord(
        address account,
        uint lockedAmount,
        uint debtEntryIndex
    ) external;

    function recordFeePaid(uint sUSDAmount) external;

    function setRewardsToDistribute(uint amount) external;
}

pragma solidity >=0.4.24;


// https://docs.synthetix.io/contracts/source/interfaces/irewardescrow
interface IRewardEscrow {
    // Views
    function balanceOf(address account) external view returns (uint);

    function numVestingEntries(address account) external view returns (uint);

    function totalEscrowedAccountBalance(address account) external view returns (uint);

    function totalVestedAccountBalance(address account) external view returns (uint);

    // Mutative functions
    function appendVestingEntry(address account, uint quantity) external;

    function vest() external;
}

pragma solidity >=0.4.24;


// https://docs.synthetix.io/contracts/source/interfaces/istakingrewards
interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

pragma solidity >=0.4.24;


// https://docs.synthetix.io/contracts/source/interfaces/isynth
interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Synthetix
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}

pragma solidity >=0.4.24;

import "./ISynth.sol";
import "./IVirtualSynth.sol";


// https://docs.synthetix.io/contracts/source/interfaces/isynthetix
interface ISynthetix {
    // Views
    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint);

    function availableSynths(uint index) external view returns (ISynth);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint);

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function maxIssuableSynths(address issuer) external view returns (uint maxIssuable);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint);

    function totalIssuedSynthsExcludeEtherCollateral(bytes32 currencyKey) external view returns (uint);

    function transferableSynthetix(address account) external view returns (uint transferable);

    // Mutative Functions
    function burnSynths(uint amount) external;

    function burnSynthsOnBehalf(address burnForAddress, uint amount) external;

    function burnSynthsToTarget() external;

    function burnSynthsToTargetOnBehalf(address burnForAddress) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithVirtual(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualSynth vSynth);

    function issueMaxSynths() external;

    function issueMaxSynthsOnBehalf(address issueForAddress) external;

    function issueSynths(uint amount) external;

    function issueSynthsOnBehalf(address issueForAddress, uint amount) external;

    function mint() external returns (bool);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    function liquidateDelinquentAccount(address account, uint susdAmount) external returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint amount) external;

    function mintSecondaryRewards(uint amount) external;

    function burnSecondary(address account, uint amount) external;
}

pragma solidity >=0.4.24;

import "./ISynth.sol";


interface IVirtualSynth {
    // Views
    function balanceOfUnderlying(address account) external view returns (uint);

    function rate() external view returns (uint);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function settled() external view returns (bool);

    function synth() external view returns (ISynth);

    // Mutative functions
    function settle(address account) external;
}

