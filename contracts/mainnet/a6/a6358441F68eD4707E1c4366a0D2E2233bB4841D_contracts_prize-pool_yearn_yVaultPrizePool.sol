// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import "../../external/yearn/yVaultInterface.sol";
import "../PrizePool.sol";

/// @title Prize Pool for yEarn's yVaults
contract yVaultPrizePool is PrizePool {
  using SafeMath for uint256;

  event yVaultPrizePoolInitialized(address indexed vault);
  event ReserveRateMantissaSet(uint256 reserveRateMantissa);

  /// @notice Interface for the yEarn yVault
  yVaultInterface public vault;

  /// Amount that is never exposed to the prize
  uint256 public reserveRateMantissa;

  /// @notice Initializes the Prize Pool and Yield Service with the required contract connections
  /// @param _trustedForwarder Address of the Forwarding Contract for GSN Meta-Txs
  /// @param _controlledTokens Array of addresses for the Ticket and Sponsorship Tokens controlled by the Prize Pool
  /// @param _maxExitFeeMantissa The maximum exit fee size, relative to the withdrawal amount
  /// @param _maxTimelockDuration The maximum length of time the withdraw timelock could be
  /// @param _vault Address of the yEarn yVaultInterface
  function initialize (
    address _trustedForwarder,
    RegistryInterface _reserveRegistry,
    address[] memory _controlledTokens,
    uint256 _maxExitFeeMantissa,
    uint256 _maxTimelockDuration,
    yVaultInterface _vault,
    uint256 _reserveRateMantissa
  )
    public
    initializer
  {
    PrizePool.initialize(
      _trustedForwarder,
      _reserveRegistry,
      _controlledTokens,
      _maxExitFeeMantissa,
      _maxTimelockDuration
    );
    vault = _vault;
    _setReserveRateMantissa(_reserveRateMantissa);

    emit yVaultPrizePoolInitialized(address(vault));
  }

  function setReserveRateMantissa(uint256 _reserveRateMantissa) external onlyOwner {
    _setReserveRateMantissa(_reserveRateMantissa);
  }

  function _setReserveRateMantissa(uint256 _reserveRateMantissa) internal {
    require(_reserveRateMantissa < 1 ether, "yVaultPrizePool/reserve-rate-lt-one");
    reserveRateMantissa = _reserveRateMantissa;

    emit ReserveRateMantissaSet(reserveRateMantissa);
  }

  /// @dev Gets the balance of the underlying assets held by the Yield Service
  /// @return The underlying balance of asset tokens
  function _balance() internal override returns (uint256) {
    uint256 total = _sharesToToken(vault.balanceOf(address(this)));
    uint256 reserve = FixedPoint.multiplyUintByMantissa(total, reserveRateMantissa);
    return total.sub(reserve);
  }

  /// @dev Allows a user to supply asset tokens in exchange for yield-bearing tokens
  /// to be held in escrow by the Yield Service
  function _supply(uint256) internal override {
    IERC20 assetToken = _token();
    uint256 total = assetToken.balanceOf(address(this));
    assetToken.approve(address(vault), total);
    vault.deposit(total);
  }

  /// @dev Allows a user to supply asset tokens in exchange for yield-bearing tokens
  /// to be held in escrow by the Yield Service
  function _supplySpecific(uint256 amount) internal {
    _token().approve(address(vault), amount);
    vault.deposit(amount);
  }

  /// @dev The external token cannot be yDai or Dai
  /// @param _externalToken The address of the token to check
  /// @return True if the token may be awarded, false otherwise
  function _canAwardExternal(address _externalToken) internal override view returns (bool) {
    return _externalToken != address(vault) && _externalToken != vault.token();
  }

  /// @dev Allows a user to redeem yield-bearing tokens in exchange for the underlying
  /// asset tokens held in escrow by the Yield Service
  /// @param amount The amount of underlying tokens to be redeemed
  /// @return The actual amount of tokens transferred
  function _redeem(uint256 amount) internal override returns (uint256) {
    IERC20 token = _token();

    require(_balance() >= amount, "yVaultPrizePool/insuff-liquidity");

    // yVault will try to over-withdraw so that amount is always available
    // we want: amount = X - X*feeRate
    // amount = X(1 - feeRate)
    // amount / (1 - feeRate) = X
    // calculate possible fee
    uint256 withdrawal;
    if (reserveRateMantissa > 0) {
      withdrawal = FixedPoint.divideUintByMantissa(amount, uint256(1e18).sub(reserveRateMantissa));
    } else {
      withdrawal = amount;
    }

    uint256 sharesToWithdraw = _tokenToShares(withdrawal);
    uint256 preBalance = token.balanceOf(address(this));
    vault.withdraw(sharesToWithdraw);
    uint256 postBalance = token.balanceOf(address(this));

    uint256 amountWithdrawn = postBalance.sub(preBalance);
    uint256 amountRedeemable = (amountWithdrawn < amount) ? amountWithdrawn : amount;

    // Redeposit any asset funds that were removed premptively for fees
    if (postBalance > amountRedeemable) {
      _supplySpecific(postBalance.sub(amountRedeemable));
    }

    return amountRedeemable;
  }

  function _tokenToShares(uint256 tokens) internal view returns (uint256) {
    /**
      ex. rate = tokens / shares
      => shares = shares_total * (tokens / tokens total)
     */
    return vault.totalSupply().mul(tokens).div(vault.balance());
  }

  function _sharesToToken(uint256 shares) internal view returns (uint256) {
    uint256 ts = vault.totalSupply();
    if (ts == 0 || shares == 0) {
      return 0;
    }
    return (vault.balance().mul(shares)).div(ts);
  }

  /// @dev Gets the underlying asset token used by the Yield Service
  /// @return A reference to the interface of the underling asset token
  function _token() internal override view returns (IERC20) {
    return IERC20(vault.token());
  }
}
