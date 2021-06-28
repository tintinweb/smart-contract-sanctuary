// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "./Ownable.sol";
import "./Erc20.sol";
import "./Erc20Permit.sol";
import "./Erc20Recover.sol";
import "./SafeErc20.sol";

import "./IHToken.sol";
import "./IBalanceSheetV1.sol";

/// @notice Emitted when the bond did not mature.
error HToken__BondNotMatured(uint256 maturity);

/// @notice Emitted when burning hTokens and the caller is not the BalanceSheet contract.
error HToken__BurnNotAuthorized(address caller);

/// @notice Emitted when the maturity is in the past.
error HToken__MaturityPast(uint256 maturity);

/// @notice Emitted when minting hTokens and the caller is not the BalanceSheet contract.
error HToken__MintNotAuthorized(address caller);

/// @notice Emitted when redeeming more underlying that there is in the reserve.
error HToken__RedeemInsufficientLiquidity(uint256 underlyingAmount, uint256 totalUnderlyingReserve);

/// @notice Emitted when redeeming a zero amount of hTokens.
error HToken__RedeemZero();

/// @notice Emitted when supplying a zero amount of underlying.
error HToken__SupplyUnderlyingZero();

/// @notice Emitted when constructing the contract and the underlying has more than 18 decimals.
error HToken__UnderlyingDecimalsOverflow(uint256 decimals);

/// @notice Emitted when constructing the contract and the underlying has zero decimals.
error HToken__UnderlyingDecimalsZero();

/// @title HToken
/// @author Hifi
contract HToken is
    Ownable, // one dependency
    Erc20, // one dependency
    Erc20Permit, // four dependencies
    IHToken, // five dependencies
    Erc20Recover // five dependencies
{
    using SafeErc20 for IErc20;

    /// PUBLIC STORAGE ///

    /// @inheritdoc IHToken
    IBalanceSheetV1 public override balanceSheet;

    /// @inheritdoc IHToken
    uint256 public override maturity;

    /// @inheritdoc IHToken
    uint256 public override totalUnderlyingReserve;

    /// @inheritdoc IHToken
    IErc20 public override underlying;

    /// @inheritdoc IHToken
    uint256 public override underlyingPrecisionScalar;

    /// CONSTRUCTOR ///

    /// @notice The hToken always has 18 decimals.
    /// @param name_ Erc20 name of this token.
    /// @param symbol_ Erc20 symbol of this token.
    /// @param maturity_ Unix timestamp in seconds for when this token matures.
    /// @param balanceSheet_ The address of the BalanceSheet contract.
    /// @param underlying_ The contract address of the underlying asset.
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maturity_,
        IBalanceSheetV1 balanceSheet_,
        IErc20 underlying_
    ) Erc20Permit(name_, symbol_, 18) Ownable() {
        // Set the maturity.
        if (maturity_ <= block.timestamp) {
            revert HToken__MaturityPast(maturity_);
        }
        maturity = maturity_;

        // Set the BalanceSheet contract.
        balanceSheet = balanceSheet_;

        // Set the underlying contract and calculate the precision scalar.
        uint256 underlyingDecimals = underlying_.decimals();
        if (underlyingDecimals == 0) {
            revert HToken__UnderlyingDecimalsZero();
        }
        if (underlyingDecimals > 18) {
            revert HToken__UnderlyingDecimalsOverflow(underlyingDecimals);
        }
        underlyingPrecisionScalar = 10**(18 - underlyingDecimals);
        underlying = underlying_;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IHToken
    function isMatured() public view override returns (bool) {
        return block.timestamp >= maturity;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IHToken
    function burn(address holder, uint256 burnAmount) external override {
        // Checks: the caller is the BalanceSheet.
        if (msg.sender != address(balanceSheet)) {
            revert HToken__BurnNotAuthorized(msg.sender);
        }

        // Effects: burns the hTokens.
        burnInternal(holder, burnAmount);

        // Emit a Burn and a Transfer event.
        emit Burn(holder, burnAmount);
    }

    /// @inheritdoc IHToken
    function mint(address beneficiary, uint256 mintAmount) external override {
        // Checks: the caller is the BalanceSheet.
        if (msg.sender != address(balanceSheet)) {
            revert HToken__MintNotAuthorized(msg.sender);
        }

        // Effects: print the new hTokens into existence.
        mintInternal(beneficiary, mintAmount);

        // Emit a Mint event.
        emit Mint(beneficiary, mintAmount);
    }

    /// @inheritdoc IHToken
    function redeem(uint256 hTokenAmount) external override {
        // Checks: before maturation.
        if (!isMatured()) {
            revert HToken__BondNotMatured(maturity);
        }

        // Checks: the zero edge case.
        if (hTokenAmount == 0) {
            revert HToken__RedeemZero();
        }

        // Denormalize the hToken amount to the underlying decimals.
        uint256 underlyingAmount;
        if (underlyingPrecisionScalar != 1) {
            unchecked {
                underlyingAmount = hTokenAmount / underlyingPrecisionScalar;
            }
        } else {
            underlyingAmount = hTokenAmount;
        }

        // Checks: there is enough liquidity.
        if (underlyingAmount > totalUnderlyingReserve) {
            revert HToken__RedeemInsufficientLiquidity(underlyingAmount, totalUnderlyingReserve);
        }

        // Effects: decrease the remaining supply of underlying.
        totalUnderlyingReserve -= underlyingAmount;

        // Interactions: burn the hTokens.
        burnInternal(msg.sender, hTokenAmount);

        // Interactions: perform the Erc20 transfer.
        underlying.safeTransfer(msg.sender, underlyingAmount);

        emit Redeem(msg.sender, hTokenAmount, underlyingAmount);
    }

    /// @inheritdoc IHToken
    function supplyUnderlying(uint256 underlyingSupplyAmount) external override {
        // Checks: the zero edge case.
        if (underlyingSupplyAmount == 0) {
            revert HToken__SupplyUnderlyingZero();
        }

        // Effects: update storage.
        totalUnderlyingReserve += underlyingSupplyAmount;

        // Normalize the underlying amount to 18 decimals.
        uint256 hTokenAmount;
        if (underlyingPrecisionScalar != 1) {
            hTokenAmount = underlyingSupplyAmount * underlyingPrecisionScalar;
        } else {
            hTokenAmount = underlyingSupplyAmount;
        }

        // Effeects: mint the hTokens.
        mintInternal(msg.sender, hTokenAmount);

        // Interactions: perform the Erc20 transfer.
        underlying.safeTransferFrom(msg.sender, address(this), underlyingSupplyAmount);

        emit SupplyUnderlying(msg.sender, underlyingSupplyAmount, hTokenAmount);
    }

    /// @inheritdoc IHToken
    function _setBalanceSheet(IBalanceSheetV1 newBalanceSheet) external override onlyOwner {
        // Effects: update storage.
        IBalanceSheetV1 oldBalanceSheet = balanceSheet;
        balanceSheet = newBalanceSheet;

        emit SetBalanceSheet(owner, oldBalanceSheet, newBalanceSheet);
    }
}