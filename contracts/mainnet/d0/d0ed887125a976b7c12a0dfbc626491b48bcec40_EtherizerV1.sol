/**
 *Submitted for verification at Etherscan.io on 2020-06-05
*/

pragma solidity 0.6.7; // optimization runs: 200, evm version: istanbul


interface ERC1271Interface {
  function isValidSignature(
    bytes calldata data, bytes calldata signatures
  ) external view returns (bytes4 magicValue);
}


interface EtherizedInterface {
  function triggerCall(
    address target, uint256 value, bytes calldata data
  ) external returns (bool success, bytes memory returnData);
}


interface EtherizerV1Interface {
  event TriggeredCall(
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data,
    bytes returnData
  );
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function triggerCallFrom(
    EtherizedInterface from,
    address payable to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success, bytes memory returnData);
  function approve(
    address spender, uint256 value
  ) external returns (bool success);
  function increaseAllowance(
    address spender, uint256 addedValue
  ) external returns (bool success);
  function decreaseAllowance(
    address spender, uint256 subtractedValue
  ) external returns (bool success);
  function modifyAllowanceViaMetaTransaction(
    address owner,
    address spender,
    uint256 value,
    bool increase,
    uint256 expiration,
    bytes32 salt,
    bytes calldata signatures
  ) external returns (bool success);
  function cancelAllowanceModificationMetaTransaction(
    address owner,
    address spender,
    uint256 value,
    bool increase,
    uint256 expiration,
    bytes32 salt
  ) external returns (bool success);

  function getMetaTransactionMessageHash(
    bytes4 functionSelector,
    bytes calldata arguments,
    uint256 expiration,
    bytes32 salt
  ) external view returns (bytes32 digest, bool valid);
  function balanceOf(address account) external view returns (uint256 amount);
  function allowance(
    address owner, address spender
  ) external view returns (uint256 amount);
}


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }
}


/**
 * @title EtherizerV1
 * @author 0age
 * @notice Etherizer is a contract for enabling "approvals" for performing Ether
 * transfers from compliant accounts via either standard ERC20 methods or
 * meta-transactions. A "compliant" account must be a smart contract that
 * implements a `triggerCall` function that is only callable by this contract as
 * well as the `isValidSignature` function specified by ERC-1271 for enabling
 * meta-transaction functionality. Be warned that any approved spender can
 * initiate arbitrary calls from the owner's account, including ERC20 token
 * transfers, so be extremely cautious when granting approval to spenders.
 */
contract EtherizerV1 is EtherizerV1Interface {
  using SafeMath for uint256;

  // Maintain a mapping of Ether allowances.
  mapping (address => mapping (address => uint256)) private _allowances;

  // Maintain a mapping of invalid meta-transaction message hashes.
  mapping (bytes32 => bool) private _invalidMetaTxHashes;

  /**
   * @notice Trigger a call from `owner` to `recipient` with `amount` Ether and
   * `data` calldata as long as `msg.sender` has sufficient allowance.
   * @param owner address The account to perform the call from.
   * @param recipient address The account to call.
   * @param amount uint256 The amount of Ether to transfer.
   * @param data bytes The data to include with the call.
   * @return success A boolean indicating whether the call was successful.
   * @return returnData The data returned from the call, if any.
   */
  function triggerCallFrom(
    EtherizedInterface owner,
    address payable recipient,
    uint256 amount,
    bytes calldata data
  ) external override returns (bool success, bytes memory returnData) {
    // Get the current allowance granted by the owner to the caller.
    uint256 callerAllowance = _allowances[address(owner)][msg.sender];

    // Block attempts to trigger calls when no allowance has been set.
    require(callerAllowance != 0, "No allowance set for caller.");

    // Reduce the allowance if it is not set to full allowance.
    if (callerAllowance != uint256(-1)) {
      require(callerAllowance >= amount, "Insufficient allowance.");
      _approve(
          address(owner), msg.sender, callerAllowance - amount
      ); // overflow safe (condition has already been checked).
    }

    // Trigger the call from the owner and revert if success is not returned.
    (success, returnData) = owner.triggerCall(recipient, amount, data);
    require(success, "Triggered call did not return successfully.");

    // Emit an event with information regarding the triggered call.
    emit TriggeredCall(address(owner), recipient, amount, data, returnData);
  }

  /**
   * @notice Approve `spender` to transfer up to `value` Ether on behalf of
   * `msg.sender`.
   * @param spender address The account to grant the allowance.
   * @param value uint256 The size of the allowance to grant.
   * @return success A boolean indicating whether the approval was successful.
   */
  function approve(
    address spender, uint256 value
  ) external override returns (bool success) {
    _approve(msg.sender, spender, value);
    success = true;
  }

  /**
   * @notice Increase the current allowance of `spender` by `value` Ether.
   * @param spender address The account to grant the additional allowance.
   * @param addedValue uint256 The amount to increase the allowance by.
   * @return success A boolean indicating whether the modification was
   * successful.
   */
  function increaseAllowance(
    address spender, uint256 addedValue
  ) external override returns (bool success) {
    _approve(
      msg.sender, spender, _allowances[msg.sender][spender].add(addedValue)
    );
    success = true;
  }

  /**
   * @notice Decrease the current allowance of `spender` by `value` Ether.
   * @param spender address The account to decrease the allowance for.
   * @param subtractedValue uint256 The amount to subtract from the allowance.
   * @return success A boolean indicating whether the modification was
   * successful.
   */
  function decreaseAllowance(
    address spender, uint256 subtractedValue
  ) external override returns (bool success) {
    _approve(
      msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue)
    );
    success = true;
  }

  /**
   * @notice Modify the current allowance of `spender` for `owner` by `value`
   * Ether, increasing it if `increase` is true, otherwise decreasing it, via a
   * meta-transaction that expires at `expiration` (or does not expire if the
   * value is zero) and uses `salt` as an additional input, validated using
   * `signatures`.
   * @param owner address The account granting the modified allowance.
   * @param spender address The account to modify the allowance for.
   * @param value uint256 The amount to modify the allowance by.
   * @param increase bool A flag that indicates whether the allowance will be
   * increased by the specified value (if true) or decreased by it (if false).
   * @param expiration uint256 A timestamp indicating how long the modification
   * meta-transaction is valid for - a value of zero will signify no expiration.
   * @param salt bytes32 An arbitrary salt to be provided as an additional input
   * to the hash digest used to validate the signatures.
   * @param signatures bytes A signature, or collection of signatures, that the
   * owner must provide in order to authorize the meta-transaction. If the
   * account of the owner does not have any runtime code deployed to it, the
   * signature will be verified using ecrecover; otherwise, it will be supplied
   * to the owner along with the message digest and context via ERC-1271 for
   * validation.
   * @return success A boolean indicating whether the modification was
   * successful.
   */
  function modifyAllowanceViaMetaTransaction(
    address owner,
    address spender,
    uint256 value,
    bool increase,
    uint256 expiration,
    bytes32 salt,
    bytes calldata signatures
  ) external override returns (bool success) {
    require(expiration == 0 || now <= expiration, "Meta-transaction expired.");

    // Construct the meta-transaction's "context" information and validate it.
    bytes memory context = abi.encodePacked(
      address(this),
      this.modifyAllowanceViaMetaTransaction.selector,
      expiration,
      salt,
      abi.encode(owner, spender, value, increase)
    );
    _validateMetaTransaction(owner, context, signatures);

    // Calculate new allowance by applying modification to current allowance.
    uint256 currentAllowance = _allowances[owner][spender];
    uint256 newAllowance = (
      increase ? currentAllowance.add(value) : currentAllowance.sub(value)
    );

    // Modify the allowance.
    _approve(owner, spender, newAllowance);
    success = true;
  }

  /**
   * @notice Cancel a specific meta-transaction for modifying an allowance. The
   * designated owner or spender can both cancel the given meta-transaction.
   * @param owner address The account granting the modified allowance.
   * @param spender address The account to modify the allowance for.
   * @param value uint256 The amount to modify the allowance by.
   * @param increase bool A flag that indicates whether the allowance will be
   * increased by the specified value (if true) or decreased by it (if false).
   * @param expiration uint256 A timestamp indicating how long the modification
   * meta-transaction is valid for - a value of zero will signify no expiration.
   * @param salt bytes32 An arbitrary salt to be provided as an additional input
   * to the hash digest used to validate the signatures.
   * @return success A boolean indicating whether the cancellation was
   * successful.
   */
  function cancelAllowanceModificationMetaTransaction(
    address owner,
    address spender,
    uint256 value,
    bool increase,
    uint256 expiration,
    bytes32 salt
  ) external override returns (bool success) {
    require(expiration == 0 || now <= expiration, "Meta-transaction expired.");
    require(
      msg.sender == owner || msg.sender == spender,
      "Only owner or spender may cancel a given meta-transaction."
    );

    // Construct the meta-transaction's "context" information.
    bytes memory context = abi.encodePacked(
      address(this),
      this.modifyAllowanceViaMetaTransaction.selector,
      expiration,
      salt,
      abi.encode(owner, spender, value, increase)
    );

    // Construct the message hash using the provided context.
    bytes32 messageHash = keccak256(context);

    // Ensure message hash has not been used or cancelled and invalidate it.
    require(
      !_invalidMetaTxHashes[messageHash], "Meta-transaction already invalid."
    );
    _invalidMetaTxHashes[messageHash] = true;

    success = true;
  }

  /**
   * @notice View function to determine a meta-transaction message hash, and to
   * determine if it is still valid (i.e. it has not yet been used and is not
   * expired). The returned message hash will need to be prefixed using EIP-191
   * 0x45 and hashed again in order to generate a final digest for the required
   * signature - in other words, the same procedure utilized by `eth_Sign`.
   * @param functionSelector bytes4 The function selector for the given
   * meta-transaction. There is only one function selector available for V1:
   * `0x2d657fa5` (the selector for `modifyAllowanceViaMetaTransaction`).
   * @param arguments bytes The abi-encoded function arguments (aside from the
   * `expiration`, `salt`, and `signatures` arguments) that should be supplied
   * to the given function.
   * @param expiration uint256 A timestamp indicating how long the given
   * meta-transaction is valid for - a value of zero will signify no expiration.
   * @param salt bytes32 An arbitrary salt to be provided as an additional input
   * to the hash digest used to validate the signatures.
   * @return messageHash The message hash corresponding to the meta-transaction.
   */
  function getMetaTransactionMessageHash(
    bytes4 functionSelector,
    bytes calldata arguments,
    uint256 expiration,
    bytes32 salt
  ) external view override returns (bytes32 messageHash, bool valid) {
    // Construct the meta-transaction's message hash based on relevant context.
    messageHash = keccak256(
      abi.encodePacked(
        address(this), functionSelector, expiration, salt, arguments
      )
    );

    // The meta-transaction is valid if it has not been used and is not expired.
    valid = (
      !_invalidMetaTxHashes[messageHash] && (
        expiration == 0 || now <= expiration
      )
    );
  }

  /**
   * @notice View function to get the total Ether balance of an account.
   * @param account address The account to check the Ether balance for.
   * @return amount The Ether balance of the given account.
   */
  function balanceOf(
    address account
  ) external view override returns (uint256 amount) {
    amount = account.balance;
  }

  /**
   * @notice View function to get the total allowance that `spender` has to
   * transfer Ether from the `owner` account using `triggerCallFrom`.
   * @param owner address The account that is granting the allowance.
   * @param spender address The account that has been granted the allowance.
   * @return etherAllowance The allowance of the given spender for the given
   * owner.
   */
  function allowance(
    address owner, address spender
  ) external view override returns (uint256 etherAllowance) {
    etherAllowance = _allowances[owner][spender];
  }

  /**
   * @notice Private function to set the allowance for `spender` to transfer up
   * to `value` tokens on behalf of `owner`.
   * @param owner address The account that has granted the allowance.
   * @param spender address The account to grant the allowance.
   * @param value uint256 The size of the allowance to grant.
   */
  function _approve(address owner, address spender, uint256 value) private {
    require(owner != address(0), "ERC20: approve for the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
   * @notice Private function to enforce that a given Meta-transaction has not
   * been used before and that the signature is valid according to the owner
   * (determined using ERC-1271).
   * @param owner address The account originating the meta-transaction.
   * @param context bytes Information about the meta-transaction.
   * @param signatures bytes Signature or signatures used to validate
   * the meta-transaction.
   */
  function _validateMetaTransaction(
    address owner, bytes memory context, bytes memory signatures
  ) private {
    // Construct the message hash using the provided context.
    bytes32 messageHash = keccak256(context);

    // Ensure message hash has not been used or cancelled and invalidate it.
    require(
      !_invalidMetaTxHashes[messageHash], "Meta-transaction no longer valid."
    );
    _invalidMetaTxHashes[messageHash] = true;

    // Construct the digest to compare signatures against using EIP-191 0x45.
    bytes32 digest = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    // Validate via ERC-1271 against the owner account.
    bytes memory data = abi.encode(digest, context);
    bytes4 magic = ERC1271Interface(owner).isValidSignature(data, signatures);
    require(magic == bytes4(0x20c13b0b), "Invalid signatures.");
  }
}