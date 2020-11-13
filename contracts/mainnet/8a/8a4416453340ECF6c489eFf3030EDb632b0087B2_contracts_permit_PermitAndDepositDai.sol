// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import "../external/maker/DaiInterface.sol";
import "../prize-pool/PrizePoolInterface.sol";

/// @title Allows users to approve and deposit dai into a prize pool in a single transaction.
contract PermitAndDepositDai is OwnableUpgradeSafe {
  using SafeERC20 for DaiInterface;

  /// @notice Permits this contract to spend on a users behalf, and deposits into the prize pool.
  /// @dev The Dai permit params match the Dai#permit function, but it expects the `spender` to be
  /// the address of this contract.
  /// @param holder The address spending the tokens
  /// @param nonce The nonce of the tx.  Should be retrieved from the Dai token
  /// @param expiry The timestamp at which the sig expires
  /// @param allowed If true, then the spender is approving holder the max allowance.  False makes the allowance zero.
  /// @param v The `v` portion of the signature.
  /// @param r The `r` portion of the signature.
  /// @param s The `s` portion of the signature.
  /// @param prizePool The prize pool to deposit into
  /// @param to The address that will receive the controlled tokens
  /// @param amount The amount to deposit
  /// @param controlledToken The type of token to be minted in exchange (i.e. tickets or sponsorship)
  /// @param referrer The address that referred the deposit
  function permitAndDepositTo(
    // --- Approve by signature ---
    address dai, address holder, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s,
    address prizePool, address to, uint256 amount, address controlledToken, address referrer
  ) external {
    require(msg.sender == holder, "PermitAndDepositDai/only-signer");
    DaiInterface(dai).permit(holder, address(this), nonce, expiry, allowed, v, r, s);
    _depositTo(dai, holder, prizePool, to, amount, controlledToken, referrer);
  }

  /// @notice Deposits into a Prize Pool from the sender.  Tokens will be transferred from the sender
  /// then deposited into the Pool on the sender's behalf.  This can be called after permitAndDepositTo is called,
  /// as this contract will have full approval for a user.
  /// @param prizePool The prize pool to deposit into
  /// @param to The address that will receive the controlled tokens
  /// @param amount The amount to deposit
  /// @param controlledToken The type of token to be minted in exchange (i.e. tickets or sponsorship)
  /// @param referrer The address that referred the deposit
  function depositTo(
    address dai,
    address prizePool,
    address to,
    uint256 amount,
    address controlledToken,
    address referrer
  ) external {
    _depositTo(dai, msg.sender, prizePool, to, amount, controlledToken, referrer);
  }

  function _depositTo(
    address dai,
    address holder,
    address prizePool,
    address to,
    uint256 amount,
    address controlledToken,
    address referrer
  ) internal {
    DaiInterface(dai).safeTransferFrom(holder, address(this), amount);
    DaiInterface(dai).approve(address(prizePool), amount);
    PrizePoolInterface(prizePool).depositTo(to, amount, controlledToken, referrer);
  }

}
