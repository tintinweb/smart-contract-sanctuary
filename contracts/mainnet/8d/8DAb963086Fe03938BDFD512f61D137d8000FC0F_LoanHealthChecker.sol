/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IERC20Like {
    function balanceOf(address account_) external view returns (uint256 balance_);
}

interface IMapleLoanLike {
    function claimableFunds() external view returns (uint256 claimableFunds_);
    function collateral() external view returns (uint256 collateral_);
    function collateralAsset() external view returns (address collateralAsset_);
    function collateralRequired() external view returns (uint256 collateralRequired_);
    function drawableFunds() external view returns (uint256 drawableFunds_);
    function fundsAsset() external view returns (address fundsAsset_);
    function principal() external view returns (uint256 principal_);
    function principalRequested() external view returns (uint256 principalRequested_);
    function paymentInterval() external view returns (uint256 paymentInterval_);
    function paymentsRemaining() external view returns (uint256 paymentsRemaining_);
}

interface IMapleGlobalsLike {
    function investorFee() external view returns (uint256 investorFee_);
    function treasuryFee() external view returns (uint256 treasuryFee_);
}


contract LoanHealthChecker {

    address public globals;

    constructor(address globals_) {
        globals = globals_;
    }

    function checkLoanAccounting(address loan_)
        external view
        returns (
            uint256 collateralAssetBalance_,
            uint256 fundsAssetBalance_,
            uint256 collateral_,
            uint256 claimableFunds_,
            uint256 drawableFunds_,
            bool    collateralAssetSafe_,
            bool    fundsAssetSafe_
        )
    {
        IMapleLoanLike loan            = IMapleLoanLike(loan_);
        IERC20Like     collateralAsset = IERC20Like(loan.collateralAsset());
        IERC20Like     fundsAsset      = IERC20Like(loan.fundsAsset());

        collateralAssetBalance_ = collateralAsset.balanceOf(loan_);
        fundsAssetBalance_      = fundsAsset.balanceOf(loan_);

        collateral_     = loan.collateral();
        claimableFunds_ = loan.claimableFunds();
        drawableFunds_  = loan.drawableFunds();

        if (address(collateralAsset) != address(fundsAsset)) {
            collateralAssetSafe_ = collateralAssetBalance_ >= collateral_;
            fundsAssetSafe_      = fundsAssetBalance_      >= (claimableFunds_ + drawableFunds_);
        } else {
            collateralAssetSafe_ = fundsAssetSafe_ = fundsAssetBalance_ >= (collateral_ + claimableFunds_ + drawableFunds_);
        }
    }

    function isCollateralMaintained(address loan_)
        external view
        returns (
            uint256 collateral_,
            uint256 principal_,
            uint256 drawableFunds_,
            uint256 principalRequested_,
            uint256 collateralRequired_,
            bool    collateralMaintained_
        )
    {
        IMapleLoanLike loan = IMapleLoanLike(loan_);

        collateral_         = loan.collateral();
        principal_          = loan.principal();
        drawableFunds_      = loan.drawableFunds();
        principalRequested_ = loan.principalRequested();
        collateralRequired_ = loan.collateralRequired();

        uint256 paymentInterval   = loan.paymentInterval();
        uint256 paymentsRemaining = loan.paymentsRemaining();

        // Transfer the annualized treasury fee, if any, to the Maple treasury, and decrement drawable funds.
        uint256 treasuryFee = (principalRequested_ * IMapleGlobalsLike(globals).treasuryFee() * paymentInterval * paymentsRemaining) / uint256(365 days * 10_000);

        // Transfer delegate fee, if any, to the pool delegate, and decrement drawable funds.
        uint256 delegateFee = (principalRequested_ * IMapleGlobalsLike(globals).investorFee() * paymentInterval * paymentsRemaining) / uint256(365 days * 10_000);

        // Where (collateral / outstandingPrincipal) should be greater or equal to (collateralRequired / principalRequested).
        // NOTE: principalRequested_ cannot be 0, which is reasonable, since it means this was never a loan.
        if(principal_ == drawableFunds_ + treasuryFee + delegateFee) {
            collateralMaintained_ = true;
        } else {
            uint256 currentCollateralRequired =
                principal_ <= drawableFunds_ ?
                    uint256(0) :
                    (collateralRequired_ * (principal_ - drawableFunds_)) / principalRequested_;

            collateralMaintained_ = collateral_ >= currentCollateralRequired;
        }
    }

}