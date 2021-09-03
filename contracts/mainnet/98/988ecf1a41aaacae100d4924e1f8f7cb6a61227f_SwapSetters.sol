/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.6.7;

abstract contract AuthLike {
    function addAuthorization(address) public virtual;
    function removeAuthorization(address) public virtual;
    function authorizedAccounts(address) public virtual returns (uint);
    // function authorities(address) public virtual returns (uint);
}

abstract contract StabilityFeeTreasuryLike {
    function setTotalAllowance(address, uint) external virtual;
    function setPerBlockAllowance(address, uint) external virtual;
    function getAllowance(address) virtual external view returns (uint256, uint256);
}

abstract contract MinimalIncreasingTreasuryReimbursementOverlayLike {
    function reimbursers(address) external virtual returns (uint);
    function toggleReimburser(address reimburser) external virtual;
}


contract SwapSetters {

    function execute(bool) public {
        address newAuctionedSurplusSetter      = 0xa43BFA2a04c355128F3f10788232feeB2f42FE98;
        address newDebtAuctionParamSetter      = 0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E;
        address oldAuctionedSurplusSetter      = 0xfCD7BcC44C3778880AEd0E025fd0aE5f7ce5Ba44;
        address oldDebtAuctionParamSetter      = 0x840E4e438711962DAc1a0c37B0588C08C92c29A5;

        address autoSurplusBufferSetter        = 0x1450f40E741F2450A95F9579Be93DD63b8407a25;

        address accountingEngine               = 0xcEe6Aa1aB47d0Fb0f24f51A3072EC16E20F90fcE;
        address stabilityFeeTreasury           = 0x83533fdd3285f48204215E9CF38C785371258E76;
        address increasingReimbursementOverlay = 0x1dCeE093a7C952260f591D9B8401318f2d2d72Ac;
        address debtAuctionParamSetterOverlay  = 0xd3aE3208b6Fc3ec3091923bD8570151a6a4a96a0;

        // updating auth on accountingEngine
        AuthLike(accountingEngine).addAuthorization(newAuctionedSurplusSetter);
        AuthLike(accountingEngine).addAuthorization(newDebtAuctionParamSetter);
        AuthLike(accountingEngine).removeAuthorization(oldAuctionedSurplusSetter);
        AuthLike(accountingEngine).removeAuthorization(oldDebtAuctionParamSetter);

        // authing overlays
        AuthLike(newAuctionedSurplusSetter).addAuthorization(increasingReimbursementOverlay);
        AuthLike(newDebtAuctionParamSetter).addAuthorization(increasingReimbursementOverlay);
        AuthLike(newDebtAuctionParamSetter).addAuthorization(debtAuctionParamSetterOverlay);

        // toggling new/old contracts on Increasing treasury reimbursement overlay
        MinimalIncreasingTreasuryReimbursementOverlayLike(increasingReimbursementOverlay).toggleReimburser(newAuctionedSurplusSetter);
        MinimalIncreasingTreasuryReimbursementOverlayLike(increasingReimbursementOverlay).toggleReimburser(newDebtAuctionParamSetter);
        MinimalIncreasingTreasuryReimbursementOverlayLike(increasingReimbursementOverlay).toggleReimburser(oldAuctionedSurplusSetter);
        MinimalIncreasingTreasuryReimbursementOverlayLike(increasingReimbursementOverlay).toggleReimburser(oldDebtAuctionParamSetter);

        // updating allowances (SF treasury)
        StabilityFeeTreasuryLike(stabilityFeeTreasury).setPerBlockAllowance(newAuctionedSurplusSetter, 10**43); // .01 RAD
        StabilityFeeTreasuryLike(stabilityFeeTreasury).setPerBlockAllowance(newDebtAuctionParamSetter, 10**43); // .01 RAD
        StabilityFeeTreasuryLike(stabilityFeeTreasury).setTotalAllowance(newAuctionedSurplusSetter, uint(-1));
        StabilityFeeTreasuryLike(stabilityFeeTreasury).setTotalAllowance(newDebtAuctionParamSetter, uint(-1));

        // removing allowances from old contracts - convert to RAD
        StabilityFeeTreasuryLike(stabilityFeeTreasury).setPerBlockAllowance(oldAuctionedSurplusSetter, 0);
        StabilityFeeTreasuryLike(stabilityFeeTreasury).setPerBlockAllowance(oldDebtAuctionParamSetter, 0);
        StabilityFeeTreasuryLike(stabilityFeeTreasury).setTotalAllowance(oldAuctionedSurplusSetter, 0);
        StabilityFeeTreasuryLike(stabilityFeeTreasury).setTotalAllowance(oldDebtAuctionParamSetter, 0);

        // setting allowance for GEB_AUTO_SURPLUS_BUFFER
        StabilityFeeTreasuryLike(stabilityFeeTreasury).setPerBlockAllowance(autoSurplusBufferSetter, 10**43); // .01 RAD
        StabilityFeeTreasuryLike(stabilityFeeTreasury).setTotalAllowance(autoSurplusBufferSetter, uint(-1));
    }
}