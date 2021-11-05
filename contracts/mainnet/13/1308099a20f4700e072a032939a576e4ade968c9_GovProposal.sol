/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

pragma solidity 0.6.7;

abstract contract SetterLike {
    function modifyParameters(bytes32, address) external virtual;
    function modifyParameters(bytes32, uint256, uint256, address) external virtual;
    function addAuthorization(address) external virtual;
}

contract GovProposal {
    // New contracts
    address public constant chainlinkTWAP = 0x92dC9b16be52De059279916c1eF810877f85F960;
    address public constant stakingOverlay = 0x374eA6547802136FFD20Aacb2c16de0b69b9bCE6;
    address public constant treasuryParamAdjusterOverlay = 0x17DACA422F564133f94674bF493C818D8B58E4E2;
    address public constant fixedRewardsAdjusterOverlay = 0x94ad9752FB73b8487f50551E68Ed6029aDEBbe2e;
    address public constant minMaxRewardsAdjusterOverlay = 0x3C3f8d76d15Da0B380fC34e80079EF3667001094;

    // Existing contracts
    SetterLike public constant staking = SetterLike(0x69c6C08B91010c88c95775B6FD768E5b04EFc106);               // GEB_STAKING
    SetterLike public constant treasuryParamAdjuster = SetterLike(0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787); // GEB_TREASURY_CORE_PARAM_ADJUSTER
    SetterLike public constant fixedRewardsAdjuster = SetterLike(0xfF5126b97f37DdB4743858b7e0d6c5aE8E5Db2ab);  // GEB_FIXED_REWARDS_ADJUSTER
    SetterLike public constant minmaxRewardsAdjuster = SetterLike(0xbe0D9016714c64a877ed28fd3F3C7c8fF513d807); // GEB_MINMAX_REWARDS_ADJUSTER
    SetterLike public constant rateSetter = SetterLike(0x7Acfc14dBF2decD1c9213Db32AE7784626daEb48);            // GEB_RRFM_SETTER
    SetterLike public constant twapRewardsRelayer = SetterLike(0xE8063b122Bef35d6723E33DBb3446092877C6855);    // MEDIANIZER_RAI_REWARDS_RELAYER
    SetterLike public constant taxCollector = SetterLike(0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB);          // GEB_TAX_COLLECTOR

    function execute(bool) public {

        // Connect new chainlink twap to rate setter / rewards contract
        rateSetter.modifyParameters("orcl", chainlinkTWAP);
        twapRewardsRelayer.modifyParameters("refundRequestor", chainlinkTWAP);

        // Attach new overlays
        staking.addAuthorization(stakingOverlay);
        treasuryParamAdjuster.addAuthorization(treasuryParamAdjusterOverlay);
        fixedRewardsAdjuster.addAuthorization(fixedRewardsAdjusterOverlay);
        minmaxRewardsAdjuster.addAuthorization(minMaxRewardsAdjusterOverlay);

        // Remove the recycling trigger contract from the TaxCollector
        taxCollector.modifyParameters("ETH-A", 2, 0, 0xaE09AFE44fCeA8e93338bdC492A6B038F4092818);
    }
}