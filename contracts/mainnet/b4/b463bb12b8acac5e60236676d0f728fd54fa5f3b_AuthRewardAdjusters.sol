/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.6.7;

abstract contract AuthLike {
    function addAuthorization(address) external virtual;
    function removeAuthorization(address) external virtual;
    function authorizedAccounts(address) external view virtual returns (uint);
}

contract AuthRewardAdjusters {
    address public constant fixedRewardsAdjuster = 0xfF5126b97f37DdB4743858b7e0d6c5aE8E5Db2ab;  // GEB_FIXED_REWARDS_ADJUSTER
    address public constant minmaxRewardsAdjuster = 0xbe0D9016714c64a877ed28fd3F3C7c8fF513d807; // GEB_MINMAX_REWARDS_ADJUSTER

    function execute(bool) public {
        // Auth - Fixed rewards adjuster
        AuthLike(0xe1d5181F0DD039aA4f695d4939d682C4cF874086).addAuthorization(fixedRewardsAdjuster); // DEBT_POPPER_REWARDS

        // Auth - Minmax rewards adjuster
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

        for (uint256 i = 0; i < 10; i++) {
            AuthLike(fundingReceivers[i]).addAuthorization(minmaxRewardsAdjuster);
        }
    }
}