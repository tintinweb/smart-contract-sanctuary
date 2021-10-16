/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

pragma solidity ^0.6.7;

abstract contract AuthLike {
    function addAuthorization(address) external virtual;
    function removeAuthorization(address) external virtual;
    function authorizedAccounts(address) external view virtual returns (uint);
}

abstract contract TreasuryParamAdjusterLike is AuthLike {
    function addRewardAdjuster(address) external virtual;
    function addFundedFunction(address, bytes4, uint256) external virtual;
    function rewardAdjusters(address) external virtual view returns (uint256);
    function whitelistedFundedFunctions(address, bytes4) external virtual view returns (uint256, uint256);
}

abstract contract FixedRewardsAdjusterLike is AuthLike {
    function addFundingReceiver(address, bytes4, uint256, uint256, uint256) external virtual;
    function fundingReceivers(address, bytes4) external virtual view returns (uint256, uint256, uint256, uint256);
}

abstract contract MinMaxRewardsAdjusterLike is AuthLike {
    function addFundingReceiver(address, bytes4, uint256, uint256, uint256, uint256) external virtual;
    function fundingReceivers(address, bytes4) external virtual view returns (uint256, uint256, uint256, uint256, uint256);
}

contract SetupRewardAdjusters {
    uint256 public constant updateDelay =  1209600;       // 14 days
    uint256 public constant gasAmountForExecution = 1000;
    uint256 public constant fixedRewardMultiplier = 130;  // 1.3x
    uint256 public constant baseRewardMultiplier = 100;   // 1x
    uint256 public constant maxRewardMultiplier = 200;    // 2x
    uint256 public constant latestExpectedCalls = 1;

    function execute(bool) public {
        AuthLike stabilityFeeTreasury = AuthLike(0x83533fdd3285f48204215E9CF38C785371258E76);                                    // GEB_STABILITY_FEE_TREASURY
        TreasuryParamAdjusterLike treasuryParamAdjuster = TreasuryParamAdjusterLike(0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787); // GEB_TREASURY_CORE_PARAM_ADJUSTER
        FixedRewardsAdjusterLike fixedRewardsAdjuster = FixedRewardsAdjusterLike(0xfF5126b97f37DdB4743858b7e0d6c5aE8E5Db2ab);    // GEB_FIXED_REWARDS_ADJUSTER
        MinMaxRewardsAdjusterLike minmaxRewardsAdjuster = MinMaxRewardsAdjusterLike(0xbe0D9016714c64a877ed28fd3F3C7c8fF513d807); // GEB_MINMAX_REWARDS_ADJUSTER

        // Auth
        stabilityFeeTreasury.addAuthorization(address(treasuryParamAdjuster));
        stabilityFeeTreasury.addAuthorization(address(fixedRewardsAdjuster));
        stabilityFeeTreasury.addAuthorization(address(minmaxRewardsAdjuster));

        // Add reward adjusters to treasury core param setter
        treasuryParamAdjuster.addRewardAdjuster(address(fixedRewardsAdjuster));
        treasuryParamAdjuster.addRewardAdjuster(address(minmaxRewardsAdjuster));

        // Adding functions - Fixed rewards adjuster
        // DEBT_POPPER_REWARDS - getRewardForPop(uint256,address)
        fixedRewardsAdjuster.addFundingReceiver(0xe1d5181F0DD039aA4f695d4939d682C4cF874086, bytes4(0xf00df8b8), updateDelay, gasAmountForExecution, fixedRewardMultiplier);
        treasuryParamAdjuster.addFundedFunction(0xe1d5181F0DD039aA4f695d4939d682C4cF874086, bytes4(0xf00df8b8), latestExpectedCalls);

        // Adding functions - Minmax rewards adjuster
        address payable[10] memory fundingReceivers = [
            0xD52Da90c20c4610fEf8faade2a1281FFa54eB6fB, // GEB_RRFM_SETTER_RELAYER
            0xE8063b122Bef35d6723E33DBb3446092877C6855, // MEDIANIZER_RAI_REWARDS_RELAYER
            0xdD2e7750ebF07BB8Be147e712D5f8deDEE052fde, // MEDIANIZER_ETH_REWARDS_RELAYER
            0x105b857583346E250FBD04a57ce0E491EB204BA3, // FSM_WRAPPER_ETH
            0x54999Ee378b339f405a4a8a1c2f7722CD25960fa, // GEB_SINGLE_CEILING_SETTER
            0x59536C9Ad1a390fA0F60813b2a4e8B957903Efc7, // COLLATERAL_AUCTION_THROTTLER
            0x0262Bd031B99c5fb99B47Dc4bEa691052f671447, // GEB_DEBT_FLOOR_ADJUSTER
            0x1450f40E741F2450A95F9579Be93DD63b8407a25, // GEB_AUTO_SURPLUS_BUFFER
            0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E, // GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER
            0xa43BFA2a04c355128F3f10788232feeB2f42FE98  // GEB_AUTO_SURPLUS_AUCTIONED

        ];
        bytes4[10] memory fundedFunctions = [
            bytes4(0x59426fad),                         // relayRate(uint256,address)
            0x8d7fb67a,                                 // reimburseCaller(address)
            0x8d7fb67a,                                 // reimburseCaller(address)
            0x2761f27b,                                 // renumerateCaller(address)
            0xcb5ec87a,                                 // autoUpdateCeiling(address)
            0x36b8b425,                                 // recomputeOnAuctionSystemCoinLimit(address)
            0x341369c1,                                 // recomputeCollateralDebtFloor(address)
            0xbf1ad0db,                                 // adjustSurplusBuffer(address)
            0xbbaf0133,                                 // setDebtAuctionInitialParameters(address)
            0xa8e2044e                                  // recomputeSurplusAmountAuctioned(address)
        ];

        for (uint256 i = 0; i < 10; i++) {
            minmaxRewardsAdjuster.addFundingReceiver(fundingReceivers[i], fundedFunctions[i], updateDelay, gasAmountForExecution, baseRewardMultiplier, maxRewardMultiplier);
            treasuryParamAdjuster.addFundedFunction(fundingReceivers[i], fundedFunctions[i], latestExpectedCalls);
        }

        // Deauthing deployer
        treasuryParamAdjuster.removeAuthorization(0x3E0139cE3533a42A7D342841aEE69aB2BfEE1d51);
        fixedRewardsAdjuster.removeAuthorization(0x3E0139cE3533a42A7D342841aEE69aB2BfEE1d51);
        minmaxRewardsAdjuster.removeAuthorization(0x3E0139cE3533a42A7D342841aEE69aB2BfEE1d51);
    }
}