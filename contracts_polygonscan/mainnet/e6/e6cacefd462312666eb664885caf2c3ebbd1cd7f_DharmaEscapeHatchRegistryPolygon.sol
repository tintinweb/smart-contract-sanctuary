/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

pragma solidity 0.5.11; // optimization runs: 200, evm version: petersburg


interface DharmaEscapeHatchRegistryInterface {
  // Fire an event when an escape hatch is set or removed.
  event EscapeHatchModified(
    address indexed smartWallet, address oldEscapeHatch, address newEscapeHatch
  );

  // Fire an event when an escape hatch is permanently disabled.
  event EscapeHatchDisabled(address smartWallet);

  // Store the escape hatch account, as well as a flag indicating if the escape
  // hatch has been disabled, for each smart wallet that elects to set one.
  struct EscapeHatch {
    address escapeHatch;
    bool disabled;
  }

  function setEscapeHatch(address newEscapeHatch) external;

  function removeEscapeHatch() external;

  function permanentlyDisableEscapeHatch() external;

  function getEscapeHatch() external view returns (
    bool exists, address escapeHatch
  );

  function getEscapeHatchForSmartWallet(
    address smartWallet
  ) external view returns (bool exists, address escapeHatch);

  function hasDisabledEscapeHatchForSmartWallet(
    address smartWallet
  ) external view returns (bool disabled);
}


/**
 * @title DharmaEscapeHatchRegistryPolygon
 * @author 0age
 * @notice The Dharma Escape Hatch Registry is an autonomous contract to store
 * opt-in "escape hatch" accounts for Dharma Smart Wallets. A designated escape
 * hatch account can bypass all controls on the smart wallet and directly access
 * funds. Furthermore, the Adharma Smart Wallet implementation will give full
 * control to the escape hatch account, rather than the user's key ring, if one
 * is currently set on the registry. Smart wallets can register an escape hatch
 * account by calling `setEscapeHatch` on the registry from a given smart wallet
 * or remove a registered escape hatch account by calling `removeEscapeHatch`.
 * Smart wallets can also be permanently disable the escape hatch mechanism by
 * calling `permanentlyDisableEscapeHatch`. The escape hatch registry will emit
 * `EscapeHatchModified` events whenever an escape hatch has been altered, and
 * `EscapeHatchDisabled` whenever a smart wallet disables the escape hatch
 * mechanism.
 */
contract DharmaEscapeHatchRegistryPolygon is DharmaEscapeHatchRegistryInterface {
  // Track escape hatches for each account.
  mapping(address => EscapeHatch) private _escapeHatches;

  /**
   * @notice Enable a fallback that will return the escape hatch address for the
   * caller in instances where improved efficiency is desired. The null address
   * will be returned in the event that no escape hatch is set for the caller,
   * and so the caller must appropriately handle this outcome if they elect to
   * use the fallback in place of the `getEscapeHatch` view function.
   * @return The address of the escape hatch or the null address if none is set.
   */
  function () external {
    // Get the caller's escape hatch account or the null address if none is set.
    address escapeHatch = _escapeHatches[msg.sender].escapeHatch;

    // Solidity does not natively support returning values from the fallback.
    assembly {
      // Store the escape hatch address in the first word of scratch space.
      mstore(0, escapeHatch)

      // Return the first word of scratch space containing escape hatch account.
      return(0, 32)
    }
  }

  /**
   * @notice Register an account as the designated escape hatch for the caller.
   * The attempt will revert if escape hatch functionality has been disabled. An
   * `EscapeHatchModified` event will be emitted if the escape hatch account was
   * modified.
   * @param escapeHatch address The account to set as the escape hatch.
   */
  function setEscapeHatch(address escapeHatch) external {
    // Ensure that an escape hatch address has been supplied.
    require(escapeHatch != address(0), "Must supply an escape hatch address.");

    // Store the escape hatch (do not disable it) and emit an event if modified.
    _modifyEscapeHatch(escapeHatch, false);
  }

  /**
   * @notice Remove the caller's escape hatch account if one is currently set.
   * This call will revert if escape hatch functionality has been disabled, but
   * in that case the account will already have no escape hatch assigned. An
   * `EscapeHatchModified` event will be emitted if an escape hatch account was
   * currently assigned.
   */
  function removeEscapeHatch() external {
    // Remove escape hatch (do not disable it) and emit an event if modified.
    _modifyEscapeHatch(address(0), false);
  }

  /**
   * @notice Remove the caller's escape hatch account if one is currently set
   * and irrevocably opt them out of the escape hatch mechanism. This call will
   * revert if escape hatch functionality has already been disabled, which also
   * means that no escape hatch is currently assigned. An `EscapeHatchDisabled`
   * event will be emitted, as well as an `EscapeHatchModified` event if an
   * escape hatch account was currently assigned.
   */
  function permanentlyDisableEscapeHatch() external {
    // Remove the escape hatch and disable it, emitting corresponding events.
    _modifyEscapeHatch(address(0), true);
  }

   /**
   * @notice View function to determine whether a caller has an escape hatch
   * account set, and if so to get the address of the escape hatch in question.
   * @return A boolean signifying whether the caller has an escape hatch set, as
   * well as the address of the escape hatch if one exists.
   */
  function getEscapeHatch() external view returns (
    bool exists, address escapeHatch
  ) {
    escapeHatch = _escapeHatches[msg.sender].escapeHatch;
    exists = escapeHatch != address(0);
  }

   /**
   * @notice View function to determine whether a particular smart wallet has an
   * escape hatch account set, and if so to get the address of the escape hatch
   * in question.
   * @param smartWallet address The smart wallet to check for an escape hatch.
   * @return A boolean signifying whether the designated smart wallet has an
   * escape hatch set, as well as the address of the escape hatch if one exists.
   */
  function getEscapeHatchForSmartWallet(
    address smartWallet
  ) external view returns (bool exists, address escapeHatch) {
    // Ensure that a smart wallet address has been supplied.
    require(smartWallet != address(0), "Must supply a smart wallet address.");

    escapeHatch = _escapeHatches[smartWallet].escapeHatch;
    exists = escapeHatch != address(0);
  }

   /**
   * @notice View function to determine whether a particular smart wallet has
   * permanently opted out of the escape hatch mechanism.
   * @param smartWallet address The smart wallet to check for escape hatch
   * mechanism disablement.
   * @return A boolean signifying whether the designated smart wallet has
   * disabled the escape hatch mechanism or not.
   */
  function hasDisabledEscapeHatchForSmartWallet(
    address smartWallet
  ) external view returns (bool disabled) {
    // Ensure that a smart wallet address has been supplied.
    require(smartWallet != address(0), "Must supply a smart wallet address.");

    disabled = _escapeHatches[smartWallet].disabled;
  }

  /**
   * @notice Internal function to update an escape hatch and/or disable it, and
   * to emit corresponding events.
   * @param escapeHatch address The account to set as the escape hatch.
   * @param disable bool A flag indicating whether the escape hatch will be
   * permanently disabled.
   */
  function _modifyEscapeHatch(address escapeHatch, bool disable) internal {
    // Retrieve the storage region of the escape hatch in question.
    EscapeHatch storage escape = _escapeHatches[msg.sender];

    // Ensure that the escape hatch mechanism has not been disabled.
    require(!escape.disabled, "Escape hatch has been disabled by this account.");

    // Emit an event if the escape hatch account has been modified.
    if (escape.escapeHatch != escapeHatch) {
      // Include calling smart wallet, old escape hatch, and new escape hatch.
      emit EscapeHatchModified(msg.sender, escape.escapeHatch, escapeHatch);
    }

    // Emit an event if the escape hatch mechanism has been disabled.
    if (disable) {
      // Include the calling smart wallet account.
      emit EscapeHatchDisabled(msg.sender);
    }

    // Update the storage region for the escape hatch with the new information.
    escape.escapeHatch = escapeHatch;
    escape.disabled = disable;
  }
}