/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity 0.6.7;

abstract contract Auth {
  function addAuthorization(address) public virtual;
  function removeAuthorization(address) public virtual;
}

abstract contract Setter is Auth {
  function modifyParameters(bytes32, address) public virtual;
  function addFundedFunction(address, bytes4, uint) public virtual;
  function removeFundedFunction(address, bytes4) public virtual;
  function addFundingReceiver(address, bytes4, uint, uint, uint, uint) public virtual;
  function addFundingReceiver(address, bytes4, uint, uint, uint) external virtual;
  function removeFundingReceiver(address, bytes4) public virtual;
  function toggleReimburser(address) public virtual;
  function modifyParameters(bytes32, uint256, uint256, bytes4, address) public virtual;
  function addRewardAdjuster(address) external virtual;
  function removeRewardAdjuster(address) external virtual;
}

contract Proposal {
  uint256 public constant updateDelay =  1 days;
  uint256 public constant gasAmountForExecution = 1000;
  uint256 public constant baseRewardMultiplier = 100;     // 1x
  uint256 public constant maxRewardMultiplier = 200;      // 2x
  uint256 public constant fixedRewardMultiplier = 130;    // 1.3x

    // contracts being replaced
  address public constant oldFixedRewardsAdjuster = 0xfF5126b97f37DdB4743858b7e0d6c5aE8E5Db2ab;         // GEB_FIXED_REWARDS_ADJUSTER
  address public constant oldMinmaxRewardsAdjuster = 0xa937A6da2837Dcc91eB19657b051504C0D512a35;        // GEB_MINMAX_REWARDS_ADJUSTER

  Setter public constant stabilityFeeTreasury = Setter(0x83533fdd3285f48204215E9CF38C785371258E76);     // GEB_STABILITY_FEE_TREASURY                           // GEB_STABILITY_FEE_TREASURY
  Setter public constant treasuryParamAdjuster = Setter(0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787);    // GEB_TREASURY_CORE_PARAM_ADJUSTER
  Setter public constant newMinmaxRewardsAdjuster = Setter(0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA);
  Setter public constant newFixedRewardsAdjuster = Setter(0xE64575f62d4802C432E2bD9c1b6692A8bACbDFB9);
  Setter public constant bundler = Setter(0x7F55e74C25647c100256D87629dee379D68bdCDe);                  // GEB_REWARD_ADJUSTER_BUNDLER

  address public constant newFixedAdjusterOverlay = 0xE7A341f5488BaFcC549950fF3E7301Cc9F017EEd;
  address public constant newMinmaxAdjusterOverlay = 0xA4037B0f5185C421518a2D63Ab12808DCcF8f19A;

  function execute(bool) public {
    address deployer = 0x3E0139cE3533a42A7D342841aEE69aB2BfEE1d51;

    // authing new setter, deauthing old
    stabilityFeeTreasury.addAuthorization(address(newMinmaxRewardsAdjuster));
    stabilityFeeTreasury.removeAuthorization(address(oldMinmaxRewardsAdjuster));
    stabilityFeeTreasury.addAuthorization(address(newFixedRewardsAdjuster));
    stabilityFeeTreasury.removeAuthorization(address(oldFixedRewardsAdjuster));

    treasuryParamAdjuster.addRewardAdjuster(address(newMinmaxRewardsAdjuster));
    treasuryParamAdjuster.removeRewardAdjuster(address(oldMinmaxRewardsAdjuster));
    treasuryParamAdjuster.addRewardAdjuster(address(newFixedRewardsAdjuster));
    treasuryParamAdjuster.removeRewardAdjuster(address(oldFixedRewardsAdjuster));

    bundler.modifyParameters("minMaxRewardAdjuster", address(newMinmaxRewardsAdjuster));
    bundler.modifyParameters("fixedRewardAdjuster", address(newFixedRewardsAdjuster));

    // adding funded functions (fixed)
    // DEBT_POPPER_REWARDS - getRewardForPop(uint256,address)
    newFixedRewardsAdjuster.addFundingReceiver(0xe1d5181F0DD039aA4f695d4939d682C4cF874086, bytes4(0xf00df8b8), updateDelay, gasAmountForExecution, 130);

    // adding funded functions (minmax)
    address payable[10] memory fundingReceivers = [
        0xD52Da90c20c4610fEf8faade2a1281FFa54eB6fB, // GEB_RRFM_SETTER_RELAYER
        0xE8063b122Bef35d6723E33DBb3446092877C6855, // MEDIANIZER_RAI_REWARDS_RELAYER
        0xdD2e7750ebF07BB8Be147e712D5f8deDEE052fde, // MEDIANIZER_ETH_REWARDS_RELAYER
        0x105b857583346E250FBD04a57ce0E491EB204BA3, // FSM_WRAPPER_ETH
        0x54999Ee378b339f405a4a8a1c2f7722CD25960fa, // GEB_SINGLE_CEILING_SETTER
        0x59536C9Ad1a390fA0F60813b2a4e8B957903Efc7, // COLLATERAL_AUCTION_THROTTLER
        0x0262Bd031B99c5fb99B47Dc4bEa691052f671447, // GEB_DEBT_FLOOR_ADJUSTER
        0x9fe16154582ecCe3414536FdE57A201c17398b2A, // GEB_AUTO_SURPLUS_BUFFER
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
        newMinmaxRewardsAdjuster.addFundingReceiver(fundingReceivers[i], fundedFunctions[i], updateDelay, gasAmountForExecution, baseRewardMultiplier, maxRewardMultiplier);
    }

    // Authing both reward adjusters in adjusted contracts
    // Auth - Minmax rewards adjuster
    for (uint256 i = 0; i < 10; i++) {
        Setter(fundingReceivers[i]).addAuthorization(address(newMinmaxRewardsAdjuster));
        Setter(fundingReceivers[i]).removeAuthorization(address(oldMinmaxRewardsAdjuster));
    }

    // Auth - Fixed rewards adjuster
    Setter(0xe1d5181F0DD039aA4f695d4939d682C4cF874086).addAuthorization(address(newFixedRewardsAdjuster));  // DEBT_POPPER_REWARDS
    Setter(0xe1d5181F0DD039aA4f695d4939d682C4cF874086).removeAuthorization(oldFixedRewardsAdjuster);        // DEBT_POPPER_REWARDS

    // remove deployer from new contracts
    newMinmaxRewardsAdjuster.removeAuthorization(deployer);
    newFixedRewardsAdjuster.removeAuthorization(deployer);
    Setter(newMinmaxAdjusterOverlay).removeAuthorization(deployer);
    Setter(newFixedAdjusterOverlay).removeAuthorization(deployer);

    // authing new overlays
    newMinmaxRewardsAdjuster.addAuthorization(newMinmaxAdjusterOverlay);
    newFixedRewardsAdjuster.addAuthorization(newFixedAdjusterOverlay);
  }
}