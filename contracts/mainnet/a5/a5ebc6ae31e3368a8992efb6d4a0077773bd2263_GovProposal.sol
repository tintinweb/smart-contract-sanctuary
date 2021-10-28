/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.6.7;

abstract contract TreasuryParamAdjusterLike {
    function modifyParameters(address receiver, bytes4 targetFunction, bytes32 parameter, uint256 val) external virtual;
    function whitelistedFundedFunctions(address, bytes4) external virtual view returns (uint256, uint256);
}

abstract contract ChainlinkTWAPLike {
    function modifyParameters(bytes32, uint256) external virtual;
    function maxWindowSize() external virtual view returns (uint256);
}

abstract contract FusePoolLike {
    function _unsupportMarket(address) external virtual;
    function markets(address) external virtual view returns(bool, uint256);
}

contract GovProposal {
    ChainlinkTWAPLike public constant chainlinkTwap = ChainlinkTWAPLike(0x92dC9b16be52De059279916c1eF810877f85F960);
    uint256 public constant maxWindowSize = 345600;
    FusePoolLike public constant fusePool = FusePoolLike(0xd04010e5618d48625F6D9DfBc8E10E39c6349B77);

    TreasuryParamAdjusterLike public constant treasuryParamSetter = TreasuryParamAdjusterLike(0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787);


    function execute(bool) public {

        // mxWindowSize in latest CL TWAP to 345600
        chainlinkTwap.modifyParameters(
            "maxWindowSize",
            maxWindowSize
            );

        // Remove the CVX market from Fuse pool 64
        fusePool._unsupportMarket(0xa67f0C06fc1Ea0B24e83AE1518d824fF0a03a048);

        address payable[11] memory fundingReceivers = [
            0xe1d5181F0DD039aA4f695d4939d682C4cF874086, // DEBT_POPPER_REWARDS
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

        // Set latestExpectedCalls for every funded function
        bytes4[11] memory fundedFunctions = [
            bytes4(0xf00df8b8),                         // getRewardForPop(uint256,address)
            0x59426fad,                                 // relayRate(uint256,address)
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
        uint256[11] memory latestExpectedCalls = [
            uint256(700),
            2200,
            2200,
            2200,
            2200,
            365,
            26,
            26,
            26,
            52,
            26
        ];

        for (uint256 i = 0; i < 11; i++) {
            treasuryParamSetter.modifyParameters(
                fundingReceivers[i],
                fundedFunctions[i],
                "latestExpectedCalls",
                latestExpectedCalls[i]
                );
        }
    }
}