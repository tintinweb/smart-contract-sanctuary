// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./Erc20.sol";
import "./Erc20Permit.sol";
import "./Erc20Recover.sol";
import "./SafeErc20.sol";

import "./IHToken.sol";
import "./IBalanceSheetV1.sol";

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
    uint256 public override expirationTime;

    /// @inheritdoc IHToken
    uint256 public override totalUnderlyingSupply;

    /// @inheritdoc IHToken
    IErc20 public override underlying;

    /// @inheritdoc IHToken
    uint256 public override underlyingPrecisionScalar;

    /// CONSTRUCTOR ///

    /// @notice The hToken always has 18 decimals.
    /// @param name_ Erc20 name of this token.
    /// @param symbol_ Erc20 symbol of this token.
    /// @param expirationTime_ Unix timestamp in seconds for when this token expires.
    /// @param balanceSheet_ The address of the BalanceSheet contract.
    /// @param underlying_ The contract address of the underlying asset.
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 expirationTime_,
        IBalanceSheetV1 balanceSheet_,
        IErc20 underlying_
    ) Erc20Permit(name_, symbol_, 18) Ownable() {
        // Set the unix expiration time.
        require(expirationTime_ > block.timestamp, "CONSTRUCTOR_EXPIRATION_TIME_PAST");
        expirationTime = expirationTime_;

        // Set the BalanceSheet contract.
        balanceSheet = balanceSheet_;

        // Set the underlying contract and calculate the decimal scalar offsets.
        uint256 underlyingDecimals = underlying_.decimals();
        require(underlyingDecimals > 0, "CONSTRUCTOR_UNDERLYING_DECIMALS_ZERO");
        require(underlyingDecimals <= 18, "CONSTRUCTOR_UNDERLYING_DECIMALS_OVERFLOW");
        underlyingPrecisionScalar = 10**(18 - underlyingDecimals);
        underlying = underlying_;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IHToken
    function isMatured() public view override returns (bool) {
        return block.timestamp >= expirationTime;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IHToken
    function burn(address holder, uint256 burnAmount) external override {
        // Checks: the caller is the BalanceSheet.
        require(msg.sender == address(balanceSheet), "BURN_NOT_AUTHORIZED");

        // Checks: the zero edge case.
        require(burnAmount > 0, "BURN_ZERO");

        // Effects: burns the hTokens.
        burnInternal(holder, burnAmount);

        // Emit a Burn and a Transfer event.
        emit Burn(holder, burnAmount);
    }

    /// @inheritdoc IHToken
    function mint(address beneficiary, uint256 mintAmount) external override {
        // Checks: the caller is the BalanceSheet.
        require(msg.sender == address(balanceSheet), "MINT_NOT_AUTHORIZED");

        // Checks: the zero edge case.
        require(mintAmount > 0, "MINT_ZERO");

        // Effects: print the new hTokens into existence.
        mintInternal(beneficiary, mintAmount);

        // Emit a Mint event.
        emit Mint(beneficiary, mintAmount);
    }

    /// @inheritdoc IHToken
    function redeem(uint256 hTokenAmount) external override {
        // Checks: before maturation.
        require(isMatured(), "BOND_NOT_MATURED");

        // Checks: the zero edge case.
        require(hTokenAmount > 0, "REDEEM_ZERO");

        // Denormalize the hToken amount to the underlying decimals.
        uint256 underlyingAmount;
        if (underlyingPrecisionScalar != 1) {
            unchecked { underlyingAmount = hTokenAmount / underlyingPrecisionScalar; }
        } else {
            underlyingAmount = hTokenAmount;
        }

        // Checks: there is enough liquidity.
        require(underlyingAmount <= totalUnderlyingSupply, "REDEEM_INSUFFICIENT_LIQUIDITY");

        // Effects: decrease the remaining supply of underlying.
        totalUnderlyingSupply -= underlyingAmount;

        // Interactions: burn the hTokens.
        burnInternal(msg.sender, hTokenAmount);

        // Interactions: perform the Erc20 transfer.
        underlying.safeTransfer(msg.sender, underlyingAmount);

        emit Redeem(msg.sender, hTokenAmount, underlyingAmount);
    }

    /// @inheritdoc IHToken
    function supplyUnderlying(uint256 underlyingSupplyAmount) external override {
        // Checks: the zero edge case.
        require(underlyingSupplyAmount > 0, "SUPPLY_UNDERLYING_ZERO");

        // Effects: update storage.
        totalUnderlyingSupply += underlyingSupplyAmount;

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