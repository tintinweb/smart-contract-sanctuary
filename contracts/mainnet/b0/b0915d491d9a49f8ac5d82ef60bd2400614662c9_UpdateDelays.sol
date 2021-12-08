/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function modifyParameters(address,bytes4,bytes32,uint256) external virtual;
    function modifyParameters(bytes32,uint256) external virtual;
    function addAuthorization(address) external virtual;
}

contract UpdateDelays {
    function execute(bool) public {
        bytes32 updateDelay = bytes32("updateDelay");

        // update delay (fixed rewards)
        Setter(0xfF5126b97f37DdB4743858b7e0d6c5aE8E5Db2ab).modifyParameters(      // GEB_FIXED_REWARDS_ADJUSTER
            0xe1d5181F0DD039aA4f695d4939d682C4cF874086,                           // DEBT_POPPER_REWARDS
            bytes4(0xf00df8b8),
            updateDelay,
            1 days
        );

        // update delay (increasing rewards)
        address payable[10] memory fundingReceivers = [
            0xD52Da90c20c4610fEf8faade2a1281FFa54eB6fB,                           // GEB_RRFM_SETTER_RELAYER
            0xE8063b122Bef35d6723E33DBb3446092877C6855,                           // MEDIANIZER_RAI_REWARDS_RELAYER
            0xdD2e7750ebF07BB8Be147e712D5f8deDEE052fde,                           // MEDIANIZER_ETH_REWARDS_RELAYER
            0x105b857583346E250FBD04a57ce0E491EB204BA3,                           // FSM_WRAPPER_ETH
            0x54999Ee378b339f405a4a8a1c2f7722CD25960fa,                           // GEB_SINGLE_CEILING_SETTER
            0x59536C9Ad1a390fA0F60813b2a4e8B957903Efc7,                           // COLLATERAL_AUCTION_THROTTLER
            0x0262Bd031B99c5fb99B47Dc4bEa691052f671447,                           // GEB_DEBT_FLOOR_ADJUSTER
            0x1450f40E741F2450A95F9579Be93DD63b8407a25,                           // GEB_AUTO_SURPLUS_BUFFER
            0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E,                           // GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER
            0xa43BFA2a04c355128F3f10788232feeB2f42FE98                            // GEB_AUTO_SURPLUS_AUCTIONED

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
            Setter(0xa937A6da2837Dcc91eB19657b051504C0D512a35).modifyParameters(  // GEB_MINMAX_REWARDS_ADJUSTER
                fundingReceivers[i],
                fundedFunctions[i],
                updateDelay,
                1 days
            );
        }

        // update delay (core param adjuster)
        Setter(0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787).modifyParameters(updateDelay, 1 days); // GEB_TREASURY_CORE_PARAM_ADJUSTER

        // Auth the debt floor adjuster overlay. GEB_DEBT_FLOOR_ADJUSTER, SINGLE_DEBT_FLOOR_ADJUSTER_OVERLAY
        Setter(0x0262Bd031B99c5fb99B47Dc4bEa691052f671447).addAuthorization(0x62AF4c0186d060EF7C30D31705aEaBE1FdA2E32B);
    }
}