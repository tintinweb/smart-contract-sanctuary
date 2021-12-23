/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


interface WalletFactoryInterface {
  event SmartWalletDeployed(address wallet, address seed);

  function newSmartWallet(address seed) external returns (address wallet);

  function getNextSmartWallet(address seed) external view returns (address wallet);
}


interface WalletInterface {
  event CallSuccess(
    bool rolledBack,
    address to,
    uint256 value,
    bytes data,
    bytes returnData
  );

  event CallFailure(
    address to,
    uint256 value,
    bytes data,
    string revertReason
  );

  // Use an array of Calls for executing generic batch calls.
  struct Call {
    address to;
    uint96 value;
    bytes data;
  }

  // Use an array of CallReturns for handling generic batch calls.
  struct CallReturn {
    bool ok;
    bytes returnData;
  }

  struct ValueReplacement {
    uint24 returnDataOffset;
    uint8 valueLength;
    uint16 callIndex;
  }

  struct DataReplacement {
    uint24 returnDataOffset;
    uint24 dataLength;
    uint16 callIndex;
    uint24 callDataOffset;
  }

  struct AdvancedCall {
    address to;
    uint96 value;
    bytes data;
    ValueReplacement[] replaceValue;
    DataReplacement[] replaceData;
  }

  struct AdvancedCallReturn {
    bool ok;
    bytes returnData;
    uint96 callValue;
    bytes callData;
  }

  receive() external payable;

  function claimOwnership(address owner) external;

  function execute(
    Call[] calldata calls
  ) external returns (bool[] memory ok, bytes[] memory returnData);

  function executeAdvanced(
    AdvancedCall[] calldata calls
  ) external returns (AdvancedCallReturn[] memory callResults);

  function simulate(
    Call[] calldata calls
  ) external /* view */ returns (bool[] memory ok, bytes[] memory returnData);

  function simulateAdvanced(
    AdvancedCall[] calldata calls
  ) external /* view */ returns (AdvancedCallReturn[] memory callResults);
}


interface WalletClaimerRegistryInterface {
  function getWalletClaimer() external view returns (address);
}


library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}


contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable#transferOwnership: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

  /**
   * @dev Cancel a transfer of ownership to a new account.
   * Can only be called by the current owner.
   */
  function cancelOwnershipTransfer() public onlyOwner {
    delete _newPotentialOwner;
  }

  /**
   * @dev Transfers ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable#acceptOwnership: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    _setOwner(msg.sender);
  }

  function _setOwner(address owner) internal {
    emit OwnershipTransferred(_owner, owner);

    _owner = owner;
  }
}


contract Wallet is WalletInterface, TwoStepOwnable {
  using Address for address;

  bytes4 _selfCallContext;

  address public immutable seed;
  WalletClaimerRegistryInterface public immutable claimerRegistry;

  constructor(address _seed) {
    seed = _seed;
    claimerRegistry = WalletClaimerRegistryInterface(msg.sender);
  }

  receive() external payable override {}

  function claimOwnership(address owner) external override {
    require(
      TwoStepOwnable.owner() == address(0),
      "Cannot claim ownership with an owner already set."
    );

    require(
      msg.sender == claimerRegistry.getWalletClaimer(),
      "Only claimer can call this function."
    );

    require(owner != address(0), "New owner cannot be the zero address.");

    _setOwner(owner);
  }

  function execute(
    Call[] calldata calls
  ) external override onlyOwner() returns (bool[] memory ok, bytes[] memory returnData) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Note: from this point on, there are no reverts (apart from out-of-gas or
    // call-depth-exceeded) originating from this contract. However, one of the
    // calls may revert, in which case the function will return `false`, along
    // with the revert reason encoded as bytes, and fire a CallFailure event.

    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Set self-call context to call _execute.
    _selfCallContext = this.execute.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool externalOk, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._execute.selector, calls
      )
    );

    // Ensure that self-call context has been cleared.
    if (!externalOk) {
      delete _selfCallContext;
    }

    // Parse data returned from self-call into each call result and store / log.
    CallReturn[] memory callResults = abi.decode(rawCallResults, (CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      Call memory currentCall = calls[i];

      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;

      // Emit CallSuccess or CallFailure event based on the outcome of the call.
      if (callResults[i].ok) {
        // Note: while the call succeeded, the action may still have "failed".
        emit CallSuccess(
          !externalOk, // If another call failed this will have been rolled back
          currentCall.to,
          uint256(currentCall.value),
          currentCall.data,
          callResults[i].returnData
        );
      } else {
        // Note: while the call failed, the nonce will still be incremented,
        // which will invalidate all supplied signatures.
        emit CallFailure(
          currentCall.to,
          uint256(currentCall.value),
          currentCall.data,
          _decodeRevertReason(callResults[i].returnData)
        );

        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  function _execute(
    Call[] calldata calls
  ) external returns (CallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.execute.selector);

    bool rollBack = false;
    callResults = new CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = calls[i].to.call{
        value: uint256(calls[i].value)
      }(calls[i].data);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        rollBack = true;
        break;
      }
    }

    if (rollBack) {
      // Wrap in length encoding and revert (provide bytes instead of a string).
      bytes memory callResultsBytes = abi.encode(callResults);
      assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
    }
  }

  function executeAdvanced(
    AdvancedCall[] calldata calls
  ) external override onlyOwner() returns (AdvancedCallReturn[] memory callResults) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Note: from this point on, there are no reverts (apart from out-of-gas or
    // call-depth-exceeded) originating from this contract. However, one of the
    // calls may revert, in which case the function will return `false`, along
    // with the revert reason encoded as bytes, and fire an CallFailure event.

    // Specify length of returned values in order to work with them in memory.
    callResults = new AdvancedCallReturn[](calls.length);

    // Set self-call context to call _executeAdvanced.
    _selfCallContext = this.executeAdvanced.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool externalOk, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._executeAdvanced.selector, calls
      )
    );

    // Note: there are more efficient ways to check for revert reasons.
    if (
      rawCallResults.length > 68 && // prefix (4) + position (32) + length (32)
      rawCallResults[0] == bytes1(0x08) &&
      rawCallResults[1] == bytes1(0xc3) &&
      rawCallResults[2] == bytes1(0x79) &&
      rawCallResults[3] == bytes1(0xa0)
    ) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Ensure that self-call context has been cleared.
    if (!externalOk) {
      delete _selfCallContext;
    }

    // Parse data returned from self-call into each call result and store / log.
    callResults = abi.decode(rawCallResults, (AdvancedCallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      AdvancedCall memory currentCall = calls[i];

      // Emit CallSuccess or CallFailure event based on the outcome of the call.
      if (callResults[i].ok) {
        // Note: while the call succeeded, the action may still have "failed".
        emit CallSuccess(
          !externalOk, // If another call failed this will have been rolled back
          currentCall.to,
          uint256(callResults[i].callValue),
          callResults[i].callData,
          callResults[i].returnData
        );
      } else {
        // Note: while the call failed, the nonce will still be incremented,
        // which will invalidate all supplied signatures.
        emit CallFailure(
          currentCall.to,
          uint256(callResults[i].callValue),
          callResults[i].callData,
          _decodeRevertReason(callResults[i].returnData)
        );

        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  function _executeAdvanced(
    AdvancedCall[] memory calls
  ) public returns (AdvancedCallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.executeAdvanced.selector);

    bool rollBack = false;
    callResults = new AdvancedCallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      AdvancedCall memory a = calls[i];
      uint256 callValue = uint256(a.value);
      bytes memory callData = a.data;
      uint256 callIndex;

      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = a.to.call{value: callValue}(callData);
      callResults[i] = AdvancedCallReturn({
          ok: ok,
          returnData: returnData,
          callValue: uint96(callValue),
          callData: callData
      });
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        rollBack = true;
        break;
      }

      for (uint256 j = 0; j < a.replaceValue.length; j++) {
        callIndex = uint256(a.replaceValue[j].callIndex);

        // Note: this check could be performed prior to execution.
        if (i >= callIndex) {
          revert("Cannot replace value using call that has not yet been performed.");
        }

        uint256 returnOffset = uint256(a.replaceValue[j].returnDataOffset);
        uint256 valueLength = uint256(a.replaceValue[j].valueLength);

        // Note: this check could be performed prior to execution.
        if (valueLength == 0 || valueLength > 32) {
          revert("bad valueLength");
        }

        if (returnData.length < returnOffset + valueLength) {
          revert("Return values are too short to give back a value at supplied index.");
        }

        AdvancedCall memory callTarget = calls[callIndex];
        uint256 valueOffset = 32 - valueLength;
        assembly {
          returndatacopy(
            add(add(callTarget, 32), valueOffset), returnOffset, valueLength
          )
        }
      }

      for (uint256 k = 0; k < a.replaceData.length; k++) {
        callIndex = uint256(a.replaceData[k].callIndex);

        // Note: this check could be performed prior to execution.
        if (i >= callIndex) {
          revert("Cannot replace data using call that has not yet been performed.");
        }

        uint256 callOffset = uint256(a.replaceData[k].callDataOffset);
        uint256 returnOffset = uint256(a.replaceData[k].returnDataOffset);
        uint256 dataLength = uint256(a.replaceData[k].dataLength);

        if (returnData.length < returnOffset + dataLength) {
          revert("Return values are too short to give back a value at supplied index.");
        }

        bytes memory callTargetData = calls[callIndex].data;

        // Note: this check could be performed prior to execution.
        if (callTargetData.length < callOffset + dataLength) {
          revert("Calldata too short to insert returndata at supplied offset.");
        }

        assembly {
          returndatacopy(
            add(callTargetData, add(32, callOffset)), returnOffset, dataLength
          )
        }
      }
    }

    if (rollBack) {
      // Wrap in length encoding and revert (provide bytes instead of a string).
      bytes memory callResultsBytes = abi.encode(callResults);
      assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
    }
  }

  function simulate(
    Call[] calldata calls
  ) external /* view */ override returns (bool[] memory ok, bytes[] memory returnData) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Set self-call context to call _simulateActionWithAtomicBatchCallsAtomic.
    _selfCallContext = this.simulate.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool mustBeFalse, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._simulate.selector, calls
      )
    );

    // Note: this should never be the case, but check just to be extra safe.
    if (mustBeFalse) {
      revert("Simulation code must revert!");
    }

    // Ensure that self-call context has been cleared.
    delete _selfCallContext;

    // Parse data returned from self-call into each call result and store / log.
    CallReturn[] memory callResults = abi.decode(rawCallResults, (CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;

      if (!callResults[i].ok) {
        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  function _simulate(
    Call[] calldata calls
  ) external returns (CallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.simulate.selector);

    callResults = new CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = calls[i].to.call{
        value: uint256(calls[i].value)
      }(calls[i].data);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        break;
      }
    }

    // Wrap in length encoding and revert (provide bytes instead of a string).
    bytes memory callResultsBytes = abi.encode(callResults);
    assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
  }

  function simulateAdvanced(
    AdvancedCall[] calldata calls
  ) external /* view */ override returns (AdvancedCallReturn[] memory callResults) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Specify length of returned values in order to work with them in memory.
    callResults = new AdvancedCallReturn[](calls.length);

    // Set self-call context to call _simulateActionWithAtomicBatchCallsAtomic.
    _selfCallContext = this.simulateAdvanced.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool mustBeFalse, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._simulateAdvanced.selector, calls
      )
    );

    // Note: this should never be the case, but check just to be extra safe.
    if (mustBeFalse) {
      revert("Simulation code must revert!");
    }

    // Note: there are more efficient ways to check for revert reasons.
    if (
      rawCallResults.length > 68 && // prefix (4) + position (32) + length (32)
      rawCallResults[0] == bytes1(0x08) &&
      rawCallResults[1] == bytes1(0xc3) &&
      rawCallResults[2] == bytes1(0x79) &&
      rawCallResults[3] == bytes1(0xa0)
    ) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Ensure that self-call context has been cleared.
    delete _selfCallContext;

    // Parse data returned from self-call into each call result and return.
    callResults = abi.decode(rawCallResults, (AdvancedCallReturn[]));
  }

  function _simulateAdvanced(
    AdvancedCall[] memory calls
  ) public returns (AdvancedCallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.simulateAdvanced.selector);

    callResults = new AdvancedCallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      AdvancedCall memory a = calls[i];
      uint256 callValue = uint256(a.value);
      bytes memory callData = a.data;
      uint256 callIndex;

      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = a.to.call{value: callValue}(callData);
      callResults[i] = AdvancedCallReturn({
          ok: ok,
          returnData: returnData,
          callValue: uint96(callValue),
          callData: callData
      });
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        break;
      }

      for (uint256 j = 0; j < a.replaceValue.length; j++) {
        callIndex = uint256(a.replaceValue[j].callIndex);

        // Note: this check could be performed prior to execution.
        if (i >= callIndex) {
          revert("Cannot replace value using call that has not yet been performed.");
        }

        uint256 returnOffset = uint256(a.replaceValue[j].returnDataOffset);
        uint256 valueLength = uint256(a.replaceValue[j].valueLength);

        // Note: this check could be performed prior to execution.
        if (valueLength == 0 || valueLength > 32) {
          revert("bad valueLength");
        }

        if (returnData.length < returnOffset + valueLength) {
          revert("Return values are too short to give back a value at supplied index.");
        }

        AdvancedCall memory callTarget = calls[callIndex];
        uint256 valueOffset = 32 - valueLength;
        assembly {
          returndatacopy(
            add(add(callTarget, 32), valueOffset), returnOffset, valueLength
          )
        }
      }

      for (uint256 k = 0; k < a.replaceData.length; k++) {
        callIndex = uint256(a.replaceData[k].callIndex);

        // Note: this check could be performed prior to execution.
        if (i >= callIndex) {
          revert("Cannot replace data using call that has not yet been performed.");
        }

        uint256 callOffset = uint256(a.replaceData[k].callDataOffset);
        uint256 returnOffset = uint256(a.replaceData[k].returnDataOffset);
        uint256 dataLength = uint256(a.replaceData[k].dataLength);

        if (returnData.length < returnOffset + dataLength) {
          revert("Return values are too short to give back a value at supplied index.");
        }

        bytes memory callTargetData = calls[callIndex].data;

        // Note: this check could be performed prior to execution.
        if (callTargetData.length < callOffset + dataLength) {
          revert("Calldata too short to insert returndata at supplied offset.");
        }

        assembly {
          returndatacopy(
            add(callTargetData, add(32, callOffset)), returnOffset, dataLength
          )
        }
      }
    }

    // Wrap in length encoding and revert (provide bytes instead of a string).
    bytes memory callResultsBytes = abi.encode(callResults);
    assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
  }

  function _enforceSelfCallFrom(bytes4 selfCallContext) internal {
    // Ensure caller is this contract and self-call context is correctly set.
    if (msg.sender != address(this) || _selfCallContext != selfCallContext) {
      revert("External accounts or unapproved internal functions cannot call this.");
    }

    // Clear the self-call context.
    delete _selfCallContext;
  }

  function _ensureValidGenericCallTarget(address to) internal view {
    if (!to.isContract()) {
      revert("Invalid `to` parameter - must supply a contract address containing code.");
    }

    if (to == address(this)) {
      revert("Invalid `to` parameter - cannot supply the address of this contract.");
    }
  }

  function _decodeRevertReason(
    bytes memory revertData
  ) internal pure returns (string memory revertReason) {
    // Solidity prefixes revert reason with 0x08c379a0 -> Error(string) selector
    if (
      revertData.length > 68 && // prefix (4) + position (32) + length (32)
      revertData[0] == bytes1(0x08) &&
      revertData[1] == bytes1(0xc3) &&
      revertData[2] == bytes1(0x79) &&
      revertData[3] == bytes1(0xa0)
    ) {
      // Get the revert reason without the prefix from the revert data.
      bytes memory revertReasonBytes = new bytes(revertData.length - 4);
      for (uint256 i = 4; i < revertData.length; i++) {
        revertReasonBytes[i - 4] = revertData[i];
      }

      // Decode the resultant revert reason as a string.
      revertReason = abi.decode(revertReasonBytes, (string));
    } else {
      // Simply return the default, with no revert reason.
      revertReason = "(no revert reason)";
    }
  }
}


contract WalletFactory is WalletFactoryInterface, TwoStepOwnable {
  address private _claimer;

  constructor() {
    _setOwner(msg.sender);
  }

  function setWalletClaimer(address claimer) external onlyOwner() {
    require(claimer != address(0), "No claimer supplied.");

    _claimer = claimer;
  }

  function getWalletClaimer() external view returns (address claimer) {
    claimer = _claimer;

    require(claimer != address(0), "No claimer set.");
  }

  function newSmartWallet(
    address seed
  ) external override returns (address wallet) {
    bytes memory constructorArguments = abi.encode(seed);

    wallet = _deployInstance(constructorArguments);

    emit SmartWalletDeployed(wallet, seed);
  }

  function getNextSmartWallet(
    address seed
  ) external view override returns (address wallet) {
    bytes memory constructorArguments = abi.encode(seed);

    wallet = _computeNextAddress(constructorArguments);
  }

  function _deployInstance(
    bytes memory constructorArguments
  ) private returns (address instance) {
    // Place creation code and constructor args of new instance in memory.
    bytes memory initCode = abi.encodePacked(
      type(Wallet).creationCode,
      constructorArguments
    );

    // Get salt to use during deployment using the supplied initialization code.
    (uint256 salt, ) = _getSaltAndTarget(initCode);

    // Deploy the new contract instance using `CREATE2`.
    assembly {
      let encoded_data := add(0x20, initCode) // load initialization code.
      let encoded_size := mload(initCode)     // load the init code's length.
      instance := create2(                    // call `CREATE2` w/ 4 arguments.
        callvalue(),                            // forward any supplied endowment.
        encoded_data,                         // pass in initialization code.
        encoded_size,                         // pass in init code's length.
        salt                                  // pass in the salt value.
      )

      // Pass along failure message and revert if contract deployment fails.
      if iszero(instance) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  function _computeNextAddress(
    bytes memory constructorArguments
  ) private view returns (address target) {
    bytes memory initCode = abi.encodePacked(
      type(Wallet).creationCode,
      constructorArguments
    );

    (, target) = _getSaltAndTarget(initCode);
  }

  function _getSaltAndTarget(
    bytes memory initCode
  ) private view returns (uint256 nonce, address target) {
    // Get the keccak256 hash of the init code for address derivation.
    bytes32 initCodeHash = keccak256(initCode);

    // Set the initial nonce to be provided when constructing the salt.
    nonce = 0;

    // Declare variable for code size of derived address.
    uint256 codeSize;

    // Loop until an contract deployment address with no code has been found.
    while (true) {
      target = address(            // derive the target deployment address.
        uint160(                   // downcast to match the address type.
          uint256(                 // cast to uint to truncate upper digits.
            keccak256(             // compute CREATE2 hash using 4 inputs.
              abi.encodePacked(    // pack all inputs to the hash together.
                bytes1(0xff),      // pass in the control character.
                address(this),     // pass in the address of this contract.
                nonce,             // pass in the salt from above.
                initCodeHash       // pass in hash of contract creation code.
              )
            )
          )
        )
      );

      // Determine if a contract is already deployed to the target address.
      assembly { codeSize := extcodesize(target) }

      // Exit the loop if no contract is deployed to the target address.
      if (codeSize == 0) {
        break;
      }

      // Otherwise, increment the nonce and derive a new salt.
      nonce++;
    }
  }
}