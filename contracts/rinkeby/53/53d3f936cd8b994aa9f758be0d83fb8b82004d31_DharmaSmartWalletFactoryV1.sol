/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity 0.5.11; // optimization runs: 200, evm version: petersburg


interface DharmaSmartWalletFactoryV1Interface {
  // Fires an event when a new smart wallet is deployed and initialized.
  event SmartWalletDeployed(address wallet, address userSigningKey);

  function newSmartWallet(
    address userSigningKey
  ) external returns (address wallet);
  
  function getNextSmartWallet(
    address userSigningKey
  ) external view returns (address wallet);
}


interface DharmaSmartWalletInitializer {
  function initialize(address userSigningKey) external;
}


/**
 * @title UpgradeBeaconProxyV1
 * @author 0age
 * @notice This contract delegates all logic, including initialization, to an
 * implementation contract specified by a hard-coded "upgrade beacon" contract.
 * Note that this implementation can be reduced in size by stripping out the
 * metadata hash, or even more significantly by using a minimal upgrade beacon
 * proxy implemented using raw EVM opcodes.
 */
contract UpgradeBeaconProxyV1 {
  // Set upgrade beacon address as a constant (i.e. not in contract storage).
  address private constant _UPGRADE_BEACON = address(
    0x2b95782fcA7bBF2FE3DC77D6a963b35771846B43
  );

  /**
   * @notice In the constructor, perform initialization via delegatecall to the
   * implementation set on the upgrade beacon, supplying initialization calldata
   * as a constructor argument. The deployment will revert and pass along the
   * revert reason in the event that this initialization delegatecall reverts.
   * @param initializationCalldata Calldata to supply when performing the
   * initialization delegatecall.
   */
  constructor(bytes memory initializationCalldata) public payable {
    // Delegatecall into the implementation, supplying initialization calldata.
    (bool ok, ) = _implementation().delegatecall(initializationCalldata);
    
    // Revert and include revert data if delegatecall to implementation reverts.
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }

  /**
   * @notice In the fallback, delegate execution to the implementation set on
   * the upgrade beacon.
   */
  function () external payable {
    // Delegate execution to implementation contract provided by upgrade beacon.
    _delegate(_implementation());
  }

  /**
   * @notice Private view function to get the current implementation from the
   * upgrade beacon. This is accomplished via a staticcall to the beacon with no
   * data, and the beacon will return an abi-encoded implementation address.
   * @return implementation Address of the implementation.
   */
  function _implementation() private view returns (address implementation) {
    // Get the current implementation address from the upgrade beacon.
    (bool ok, bytes memory returnData) = _UPGRADE_BEACON.staticcall("");
    
    // Revert and pass along revert message if call to upgrade beacon reverts.
    require(ok, string(returnData));

    // Set the implementation to the address returned from the upgrade beacon.
    implementation = abi.decode(returnData, (address));
  }

  /**
   * @notice Private function that delegates execution to an implementation
   * contract. This is a low level function that doesn't return to its internal
   * call site. It will return whatever is returned by the implementation to the
   * external caller, reverting and returning the revert data if implementation
   * reverts.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) private {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize)

      // Delegatecall to the implementation, supplying calldata and gas.
      // Out and outsize are set to zero - instead, use the return buffer.
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      // Copy the returned data from the return buffer.
      returndatacopy(0, 0, returndatasize)

      switch result
      // Delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }
}


/**
 * @title DharmaSmartWalletFactoryV1
 * @author 0age
 * @notice This contract deploys new Dharma Smart Wallet instances as "Upgrade
 * Beacon" proxies that reference a shared implementation contract specified by
 * the Dharma Upgrade Beacon contract.
 */
contract DharmaSmartWalletFactoryV1 is DharmaSmartWalletFactoryV1Interface {
  // Use Dharma Smart Wallet initializer to construct initialization calldata.
  DharmaSmartWalletInitializer private _INITIALIZER;

  /**
   * @notice Deploy a new smart wallet address using the provided user signing
   * key.
   * @param userSigningKey address The user signing key, supplied as a
   * constructor argument.
   * @return The address of the new smart wallet.
   */
  function newSmartWallet(
    address userSigningKey
  ) external returns (address wallet) {
    // Get initialization calldata from initialize selector & user signing key.
    bytes memory initializationCalldata = abi.encodeWithSelector(
      _INITIALIZER.initialize.selector,
      userSigningKey
    );
    
    // Initialize and deploy new user smart wallet as an Upgrade Beacon proxy.
    wallet = _deployUpgradeBeaconProxyInstance(initializationCalldata);

    // Emit an event to signal the creation of the new smart wallet.
    emit SmartWalletDeployed(wallet, userSigningKey);
  }

  /**
   * @notice View function to find the address of the next smart wallet address
   * that will be deployed for a given user signing key. Note that a new value
   * will be returned if a particular user signing key has been used before.
   * @param userSigningKey address The user signing key, supplied as a
   * constructor argument.
   * @return The future address of the next smart wallet.
   */
  function getNextSmartWallet(
    address userSigningKey
  ) external view returns (address wallet) {
    // Get initialization calldata from initialize selector & user signing key.
    bytes memory initializationCalldata = abi.encodeWithSelector(
      _INITIALIZER.initialize.selector,
      userSigningKey
    );
    
    // Determine the user's smart wallet address based on the user signing key.
    wallet = _computeNextAddress(initializationCalldata);
  }

  /**
   * @notice Private function to deploy an upgrade beacon proxy via `CREATE2`.
   * @param initializationCalldata bytes The calldata that will be supplied to
   * the `DELEGATECALL` from the deployed contract to the implementation set on
   * the upgrade beacon during contract creation.
   * @return The address of the newly-deployed upgrade beacon proxy.
   */
  function _deployUpgradeBeaconProxyInstance(
    bytes memory initializationCalldata
  ) private returns (address upgradeBeaconProxyInstance) {
    // Place creation code and constructor args of new proxy instance in memory.
    bytes memory initCode = abi.encodePacked(
      type(UpgradeBeaconProxyV1).creationCode,
      abi.encode(initializationCalldata)
    );

    // Get salt to use during deployment using the supplied initialization code.
    (uint256 salt, ) = _getSaltAndTarget(initCode);

    // Deploy the new upgrade beacon proxy contract using `CREATE2`.
    assembly {
      let encoded_data := add(0x20, initCode) // load initialization code.
      let encoded_size := mload(initCode)     // load the init code's length.
      upgradeBeaconProxyInstance := create2(  // call `CREATE2` w/ 4 arguments.
        callvalue,                            // forward any supplied endowment.
        encoded_data,                         // pass in initialization code.
        encoded_size,                         // pass in init code's length.
        salt                                  // pass in the salt value.
      )

      // Pass along failure message and revert if contract deployment fails.
      if iszero(upgradeBeaconProxyInstance) {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }

  /**
   * @notice Private view function for finding the address of the next upgrade
   * beacon proxy that will be deployed, given a particular initialization
   * calldata payload.
   * @param initializationCalldata bytes The calldata that will be supplied to
   * the `DELEGATECALL` from the deployed contract to the implementation set on
   * the upgrade beacon during contract creation.
   * @return The address of the next upgrade beacon proxy contract with the
   * given initialization calldata.
   */
  function _computeNextAddress(
    bytes memory initializationCalldata
  ) private view returns (address target) {
    // Place creation code and constructor args of the proxy instance in memory.
    bytes memory initCode = abi.encodePacked(
      type(UpgradeBeaconProxyV1).creationCode,
      abi.encode(initializationCalldata)
    );

    // Get target address using the constructed initialization code.
    (, target) = _getSaltAndTarget(initCode);
  }

  /**
   * @notice Private function for determining the salt and the target deployment
   * address for the next deployed contract (using `CREATE2`) based on the
   * contract creation code.
   */
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
                nonce,              // pass in the salt from above.
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