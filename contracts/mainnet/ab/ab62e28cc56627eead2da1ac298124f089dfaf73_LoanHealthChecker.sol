/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// hevm: flattened sources of src/LoanHealthChecker.sol
// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;

////// src/LoanHealthChecker.sol
/* pragma solidity 0.8.7; */

interface IERC20Like_2 {
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
}


contract LoanHealthChecker {

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
        IERC20Like_2     collateralAsset = IERC20Like_2(loan.collateralAsset());
        IERC20Like_2     fundsAsset      = IERC20Like_2(loan.fundsAsset());

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

        // Where (collateral / outstandingPrincipal) should be greater or equal to (collateralRequired / principalRequested).
        // NOTE: principalRequested_ cannot be 0, which is reasonable, since it means this was never a loan.
        uint256 currentCollateralRequired =
            principal_ <= drawableFunds_ ?
                uint256(0) :
                (collateralRequired_ * (principal_ - drawableFunds_)) / principalRequested_;

        collateralMaintained_ = collateral_ >= currentCollateralRequired;
    }

}