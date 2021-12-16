/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

pragma solidity 0.6.7;

abstract contract Setter {
  function modifyParameters(bytes32, uint) external virtual;
  function modifyParameters(bytes32, address) external virtual;
  function addAuthorization(address) external virtual;
  function removeAuthorization(address) external virtual;
}

contract UpdateParams {

  function execute(bool) public {

    // GEB_ORACLE_RELAYER - adjusting redemption rate bounds to +- 100% over 5 months
    Setter(0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851).modifyParameters("redemptionRateLowerBound", 999999942696167270176085171);
    Setter(0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851).modifyParameters("redemptionRateUpperBound", 1000000057303836013553348526);

    // GEB_RRFM_SETTER - updateRateDelay to 12 hours
    Setter(0x7Acfc14dBF2decD1c9213Db32AE7784626daEb48).modifyParameters("updateRateDelay", 12 hours);

    // GEB_RRFM_SETTER_RELAYER - relayDelay to 12 hours
    Setter(0xD52Da90c20c4610fEf8faade2a1281FFa54eB6fB).modifyParameters("relayDelay", 12 hours);

    // MEDIANIZER_RAI_REWARDS_RELAYER - baseUpdateCallerReward increases 100% over 10800 seconds
    Setter(0xE8063b122Bef35d6723E33DBb3446092877C6855).modifyParameters("perSecondCallerRewardIncrease", 1000064182354095453705626271);

    //MEDIANIZER_ETH_REWARDS_RELAYER - baseUpdateCallerReward increases 100% over 10800 seconds
    Setter(0xdD2e7750ebF07BB8Be147e712D5f8deDEE052fde).modifyParameters("perSecondCallerRewardIncrease", 1000064182354095453705626271);

    //FSM_WRAPPER_ETH - baseUpdateCallerReward increases 100% over 10800 seconds
    Setter(0x105b857583346E250FBD04a57ce0E491EB204BA3).modifyParameters("perSecondCallerRewardIncrease", 1000064182354095453705626271);

    //GEB_SINGLE_CEILING_SETTER - baseUpdateCallerReward increases 100% over 10800 seconds
    Setter(0x54999Ee378b339f405a4a8a1c2f7722CD25960fa).modifyParameters("perSecondCallerRewardIncrease", 1000064182354095453705626271);

    //COLLATERAL_AUCTION_THROTTLER - baseUpdateCallerReward increases 100% over 10800 seconds
    Setter(0x59536C9Ad1a390fA0F60813b2a4e8B957903Efc7).modifyParameters("perSecondCallerRewardIncrease", 1000064182354095453705626271);

    //DEBT_POPPER_REWARDS - baseUpdateCallerReward increases 100% over 10800 seconds
    Setter(0xe1d5181F0DD039aA4f695d4939d682C4cF874086).modifyParameters("maxPerPeriodPops", 50);

    //GEB_AUTO_SURPLUS_BUFFER - baseUpdateCallerReward increases 100% over 10800 seconds
    Setter(0x1450f40E741F2450A95F9579Be93DD63b8407a25).modifyParameters("perSecondCallerRewardIncrease", 1000064182354095453705626271);

    //GEB_AUTO_SURPLUS_AUCTIONED - baseUpdateCallerReward increases 100% over 10800 seconds
    Setter(0xa43BFA2a04c355128F3f10788232feeB2f42FE98).modifyParameters("perSecondCallerRewardIncrease", 1000064182354095453705626271);
    //GEB_AUTO_SURPLUS_AUCTIONED - targetValue to 69,420 RAY
    Setter(0xa43BFA2a04c355128F3f10788232feeB2f42FE98).modifyParameters("targetValue", 69420 * 10 ** 27);

    //GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER - bidTargetValue to 69,420 WAD
    Setter(0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E).modifyParameters("bidTargetValue", 69420 * 10 ** 27);
    //GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER - baseUpdateCallerReward increases 100% over 10800 seconds
    Setter(0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E).modifyParameters("perSecondCallerRewardIncrease", 1000064182354095453705626271);
    //GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER - systemCoinOrcl to the latest RAI CL TWAP
    Setter(0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E).modifyParameters("systemCoinOrcl", 0x92dC9b16be52De059279916c1eF810877f85F960);

    //GEB_STAKING - maxConcurrentAuctions to 5
    Setter(0x69c6C08B91010c88c95775B6FD768E5b04EFc106).modifyParameters("maxConcurrentAuctions", 5);

    //GEB_STABILITY_FEE_TREASURY - surplusTransferDelay to 2419200 seconds (28 days)
    Setter(0x83533fdd3285f48204215E9CF38C785371258E76).modifyParameters("surplusTransferDelay", 2419200);

    //GEB_MINMAX_REWARDS_ADJUSTER - Replace old overlay (0x3C3f8d76d15Da0B380fC34e80079EF3667001094) with 0xB85a752fE055b9aDB2EE6C7D20239c94331c6883
    Setter(0xa937A6da2837Dcc91eB19657b051504C0D512a35).removeAuthorization(0x3C3f8d76d15Da0B380fC34e80079EF3667001094);
    Setter(0xa937A6da2837Dcc91eB19657b051504C0D512a35).addAuthorization(0xB85a752fE055b9aDB2EE6C7D20239c94331c6883);

    //GEB_FIXED_REWARDS_ADJUSTER - Replace old overlay (0x94ad9752FB73b8487f50551E68Ed6029aDEBbe2e) with 0x380F510FbC103A248C2a14FFbB70E2cff010ACA8
    Setter(0xfF5126b97f37DdB4743858b7e0d6c5aE8E5Db2ab).removeAuthorization(0x94ad9752FB73b8487f50551E68Ed6029aDEBbe2e);
    Setter(0xfF5126b97f37DdB4743858b7e0d6c5aE8E5Db2ab).addAuthorization(0x380F510FbC103A248C2a14FFbB70E2cff010ACA8);
  }
}