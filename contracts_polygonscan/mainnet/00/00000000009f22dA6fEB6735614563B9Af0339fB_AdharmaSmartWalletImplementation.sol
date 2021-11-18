/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

pragma solidity 0.5.11; // optimization runs: 200, evm version: petersburg


interface MinimalEscapeHatchRegistryInterface {
  function getEscapeHatch() external view returns (
    bool exists, address escapeHatch
  );
}


/**
 * @title AdharmaSmartWalletImplementation
 * @author 0age
 * @notice The Adharma smart wallet is an emergency implementation wallet that
 * can be immediately upgraded to by the Upgrade Beacon Controller Manager in
 * the event of a critical-severity exploit, or after a 90-day period of
 * inactivity by Dharma. It gives the user direct, sole custody and control over
 * their smart wallet until the Upgrade Beacon Controller Manager issues another
 * upgrade to the implementation contract. If the user has set an escape hatch
 * for the account, it will have authority over the smart wallet during the
 * contingency - otherwise, the user signing key in storage slot zero will have
 * that authority.
 */
contract AdharmaSmartWalletImplementation {
  // The key is still held in storage slot zero.
  address private _key;

  // The escape hatch registry address is hard-coded as a constant.
  MinimalEscapeHatchRegistryInterface private constant _ESCAPE_HATCH = (
    MinimalEscapeHatchRegistryInterface(
      0x00000000005280B515004B998a944630B6C663f8
    )
  );

  // The smart wallet can receive funds, though it is inadvisable.
  function () external payable {}

  // Keep the initializer function on the contract in case a smart wallet has
  // not yet been deployed but the account still contains funds.
  function initialize(address key) external {
    // Ensure that this function is only callable during contract construction.
    assembly { if extcodesize(address) { revert(0, 0) } }

    // Ensure that a key is set on this smart wallet.
    require(key != address(0), "No key provided.");

    // Set up the key.
    _key = key;
  }

  // The escape hatch account, or the key account if no escape hatch is set, has
  // sole authority to make calls from the smart wallet during the contingency.
  function performCall(
    address payable to, uint256 amount, bytes calldata data
  ) external payable returns (
    bool ok, bytes memory returnData
  ) {
    // Determine if an escape hatch is set on the registry for this account.
    (bool escapeHatchSet, address escapeHatch) = _ESCAPE_HATCH.getEscapeHatch();

    // Set escape hatch account as permitted caller, or user key if none is set.
    address authority = escapeHatchSet ? escapeHatch : _key;

    // Ensure that the call originates from the designated caller.
    require(msg.sender == authority, "Caller prohibited.");

    // Perform the call, forwarding all gas and supplying given value and data.
    (ok, returnData) = to.call.value(amount)(data);

    // Revert and pass along the revert reason if the call reverted.
    require(ok, string(returnData));
  }
}