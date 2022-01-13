// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.7;

interface IMapleGlobalsLike {

   function isValidCollateralAsset(address asset_) external view returns (bool isValid_);

   function isValidLiquidityAsset(address asset_) external view returns (bool isValid_);

}

interface IMapleLoanLike {

    function collateralAsset() external view returns (address collateralAsset_);

    function fundsAsset() external view returns (address fundsAsset_);

    function principalRequested() external view returns (uint256 principalRequested_);

}

interface IPoolFactoryLike {

    function globals() external pure returns (address globals_);

}

interface IPoolLike {

    function superFactory() external view returns (address superFactory_);

}

/// @title DebtLockerInitializer is intended to initialize the storage of a DebtLocker proxy.
interface IDebtLockerInitializer {

    function encodeArguments(address loan_, address pool_) external pure returns (bytes memory encodedArguments_);

    function decodeArguments(bytes calldata encodedArguments_) external pure returns (address loan_, address pool_);

}

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

        IMapleGlobalsLike globals = IMapleGlobalsLike(IPoolFactoryLike(IPoolLike(pool_).superFactory()).globals());

        require(globals.isValidCollateralAsset(IMapleLoanLike(loan_).collateralAsset()), "DL:I:INVALID_COLLATERAL_ASSET");
        require(globals.isValidLiquidityAsset(IMapleLoanLike(loan_).fundsAsset()),       "DL:I:INVALID_FUNDS_ASSET");

        _loan = loan_;
        _pool = pool_;

        _principalRemainingAtLastClaim = IMapleLoanLike(loan_).principalRequested();
    }

}