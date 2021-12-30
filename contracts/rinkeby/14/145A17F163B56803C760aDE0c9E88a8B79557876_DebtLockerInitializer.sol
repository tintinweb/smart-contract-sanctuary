// hevm: flattened sources of contracts/DebtLockerInitializer.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.8.7;

////// contracts/DebtLockerStorage.sol
/* pragma solidity 0.8.7; */

/// @title DebtLockerStorage maps the storage layout of a DebtLocker.
contract DebtLockerStorage {

    address internal _liquidator;
    address internal _loan;
    address internal _pool;

    bool internal _repossessed;

    uint256 internal _allowedSlippage;
    uint256 internal _amountRecovered;
    uint256 internal _fundsToCapture;
    uint256 internal _minRatio;
    uint256 internal _principalRemainingAtLastClaim;

}

////// contracts/interfaces/IDebtLockerInitializer.sol
/* pragma solidity 0.8.7; */

/// @title DebtLockerInitializer is intended to initialize the storage of a DebtLocker proxy.
interface IDebtLockerInitializer {

    function encodeArguments(address loan_, address pool_) external pure returns (bytes memory encodedArguments_);

    function decodeArguments(bytes calldata encodedArguments_) external pure returns (address loan_, address pool_);

}

////// contracts/interfaces/Interfaces.sol
/* pragma solidity 0.8.7; */

interface IERC20Like_1 {

    function decimals() external view returns (uint8 decimals_);

    function balanceOf(address account_) external view returns (uint256 balanceOf_);

}

interface ILiquidatorLike_1 {

    function auctioneer() external view returns (address auctioneer_);
}

interface IMapleGlobalsLike_1 {

   function defaultUniswapPath(address fromAsset_, address toAsset_) external view returns (address intermediateAsset_);

   function getLatestPrice(address asset_) external view returns (uint256 price_);

   function investorFee() external view returns (uint256 investorFee_);

   function isValidCollateralAsset(address asset_) external view returns (bool isValid_);

   function isValidLiquidityAsset(address asset_) external view returns (bool isValid_);

   function mapleTreasury() external view returns (address mapleTreasury_);

   function protocolPaused() external view returns (bool protocolPaused_);

   function treasuryFee() external view returns (uint256 treasuryFee_);

}

interface IMapleLoanLike {

    function acceptNewTerms(address refinancer_, bytes[] calldata calls_, uint256 amount_) external;

    function claimableFunds() external view returns (uint256 claimableFunds_);

    function collateralAsset() external view returns (address collateralAsset_);

    function fundsAsset() external view returns (address fundsAsset_);

    function lender() external view returns (address lender_);

    function principal() external view returns (uint256 principal_);

    function principalRequested() external view returns (uint256 principalRequested_);

    function claimFunds(uint256 amount_, address destination_) external;

    function repossess(address destination_) external returns (uint256 collateralAssetAmount_, uint256 fundsAssetAmount_);

}

interface IPoolLike {

    function poolDelegate() external view returns (address poolDelegate_);

    function superFactory() external view returns (address superFactory_);

}

interface IPoolFactoryLike {

    function globals() external pure returns (address globals_);

}

interface IUniswapRouterLike_1 {

    function swapExactTokensForTokens(
        uint amountIn_,
        uint amountOutMin_,
        address[] calldata path_,
        address to_,
        uint deadline_
    ) external returns (uint[] memory amounts_);

}

////// contracts/DebtLockerInitializer.sol
/* pragma solidity 0.8.7; */

/* import { IMapleGlobalsLike, IMapleLoanLike, IPoolFactoryLike, IPoolLike }  from "./interfaces/Interfaces.sol"; */

/* import { IDebtLockerInitializer } from "./interfaces/IDebtLockerInitializer.sol"; */

/* import { DebtLockerStorage } from "./DebtLockerStorage.sol"; */

/// @title DebtLockerInitializer is intended to initialize the storage of a DebtLocker proxy.
contract DebtLockerInitializer is IDebtLockerInitializer, DebtLockerStorage {

    function encodeArguments(address loan_, address pool_) external pure override returns (bytes memory encodedArguments_) {
        return abi.encode(loan_, pool_);
    }

    function decodeArguments(bytes calldata encodedArguments_) public pure override returns (address loan_, address pool_) {
        ( loan_, pool_ ) = abi.decode(encodedArguments_, (address, address));
    }

    fallback() external {
        ( address loan_, address pool_ ) = decodeArguments(msg.data);

        IMapleGlobalsLike_1 globals = IMapleGlobalsLike_1(IPoolFactoryLike(IPoolLike(pool_).superFactory()).globals());

        require(globals.isValidCollateralAsset(IMapleLoanLike(loan_).collateralAsset()), "DL:I:INVALID_COLLATERAL_ASSET");
        require(globals.isValidLiquidityAsset(IMapleLoanLike(loan_).fundsAsset()),       "DL:I:INVALID_FUNDS_ASSET");

        _loan = loan_;
        _pool = pool_;

        _principalRemainingAtLastClaim = IMapleLoanLike(loan_).principalRequested();
    }

}