/**
 *Submitted for verification at polygonscan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface DharmaSmartWalletInterface {
  enum ActionType {
    Cancel, SetUserSigningKey, Generic, GenericAtomicBatch, SAIWithdrawal,
    USDCWithdrawal, ETHWithdrawal, SetEscapeHatch, RemoveEscapeHatch,
    DisableEscapeHatch, DAIWithdrawal, _ELEVEN, _TWELVE, _THIRTEEN,
    _FOURTEEN, _FIFTEEN, _SIXTEEN, _SEVENTEEN, _EIGHTEEN, _NINETEEN, _TWENTY
  }
  function getVersion() external pure returns (uint256 version);
}


interface DharmaSmartWalletFactoryV3Interface {
  function newSmartWallet(
    address userSigningKey
  ) external returns (address wallet);

  function getNextSmartWallet(
    address userSigningKey
  ) external view returns (address wallet);
}

interface DharmaKeyRingFactoryV2Interface {
  function newKeyRing(
    address userSigningKey, address targetKeyRing
  ) external returns (address keyRing);

  function getNextKeyRing(
    address userSigningKey
  ) external view returns (address targetKeyRing);
}


interface DharmaKeyRegistryInterface {
  function getKeyForUser(address account) external view returns (address key);
}


contract DharmaDeploymentHelperV2Polygon {
  DharmaSmartWalletFactoryV3Interface internal immutable _WALLET_FACTORY;

  DharmaKeyRingFactoryV2Interface internal immutable _KEYRING_FACTORY;

  DharmaKeyRegistryInterface internal immutable _KEY_REGISTRY;

  address internal immutable _SMART_WALLET_UPGRADE_BEACON;

  constructor(
    address smartWalletFactory,
    address keyRingFactory,
    address keyRegistry,
    address smartWalletUpgradeBeacon
  ) {
    uint256 size;

    require(
      smartWalletFactory != address(0),
      "DharmaDeploymentHelperV2#constructor: No smartWalletFactory address supplied."
    );

    assembly { size := extcodesize(smartWalletFactory) }
    require(
      size != 0,
      "DharmaDeploymentHelperV2#constructor: No code contract deployed for smartWalletFactory."
    );

    require(
      keyRingFactory != address(0),
      "DharmaDeploymentHelperV2#constructor: No keyRingFactory address supplied."
    );

    assembly { size := extcodesize(keyRingFactory) }
    require(
      size != 0,
      "DharmaDeploymentHelperV2#constructor: No code contract deployed for keyRingFactory."
    );

    require(
      keyRegistry != address(0),
      "DharmaDeploymentHelperV2#constructor: No keyRegistry address supplied."
    );

    assembly { size := extcodesize(keyRegistry) }
    require(
      size != 0,
      "DharmaDeploymentHelperV2#constructor: No code contract deployed for keyRegistry."
    );

    require(
      smartWalletUpgradeBeacon != address(0),
      "DharmaDeploymentHelperV2#constructor: No smartWalletUpgradeBeacon address supplied."
    );

    assembly { size := extcodesize(smartWalletUpgradeBeacon) }
    require(
      size != 0,
      "DharmaDeploymentHelperV2#constructor: No code contract deployed for smartWalletUpgradeBeacon."
    );

    _WALLET_FACTORY = DharmaSmartWalletFactoryV3Interface(smartWalletFactory);

    _KEYRING_FACTORY = DharmaKeyRingFactoryV2Interface(keyRingFactory);

    _KEY_REGISTRY = DharmaKeyRegistryInterface(keyRegistry);

    _SMART_WALLET_UPGRADE_BEACON = smartWalletUpgradeBeacon;
  }

  // Deploy a smart wallet and call it with arbitrary data.
  function deployWalletAndCall(
    address userSigningKey, // the key ring
    address smartWallet,
    bytes calldata data
  ) external returns (bool ok, bytes memory returnData) {
    _deployNewSmartWalletIfNeeded(userSigningKey, smartWallet);
    (ok, returnData) = smartWallet.call(data);
  }

  // Deploy a key ring and a smart wallet, then call the smart wallet
  // with arbitrary data.
  function deployKeyRingAndWalletAndCall(
    address initialSigningKey, // the initial key on the keyring
    address keyRing,
    address smartWallet,
    bytes calldata data
  ) external returns (bool ok, bytes memory returnData) {
    _deployNewKeyRingIfNeeded(initialSigningKey, keyRing);
    _deployNewSmartWalletIfNeeded(keyRing, smartWallet);
    (ok, returnData) = smartWallet.call(data);
  }

  // Get an actionID for the first action on a smart wallet before it
  // has been deployed.
  // no argument: empty string - abi.encode();
  // one argument, like setUserSigningKey: abi.encode(argument)
  // withdrawals: abi.encode(amount, recipient)
  // generics: abi.encode(to, data)
  // generic batch: abi.encode(calls) -> array of {address to, bytes data}
  function getInitialActionID(
    address smartWallet,
    address initialUserSigningKey, // the key ring
    DharmaSmartWalletInterface.ActionType actionType,
    uint256 minimumActionGas,
    bytes calldata arguments
  ) external view returns (bytes32 actionID) {
    // Prevent replays across different chains.
    uint256 chainId;
    assembly {
        chainId := chainid()
    }

    actionID = keccak256(
      abi.encodePacked(
        smartWallet,
        chainId,
        _getVersion(),
        initialUserSigningKey,
        _KEY_REGISTRY.getKeyForUser(smartWallet),
        uint256(0), // nonce starts at 0
        minimumActionGas,
        actionType,
        arguments
      )
    );
  }

  function _deployNewKeyRingIfNeeded(
    address initialSigningKey, address expectedKeyRing
  ) internal returns (address keyRing) {
    // Only deploy if a smart wallet doesn't already exist at expected address.
    uint256 size;
    assembly { size := extcodesize(expectedKeyRing) }
    if (size == 0) {
      require(
        _KEYRING_FACTORY.getNextKeyRing(initialSigningKey) == expectedKeyRing,
        "Key ring to be deployed does not match expected key ring."
      );
      keyRing = _KEYRING_FACTORY.newKeyRing(initialSigningKey, expectedKeyRing);
    } else {
      // Note: the key ring at the expected address may have been modified so that
      // the supplied user signing key is no longer a valid key - therefore, treat
      // this helper as a way to protect against race conditions, not as a primary
      // mechanism for interacting with key ring contracts.
      keyRing = expectedKeyRing;
    }
  }

  function _deployNewSmartWalletIfNeeded(
    address userSigningKey, // the key ring
    address expectedSmartWallet
  ) internal returns (address smartWallet) {
    // Only deploy if a smart wallet doesn't already exist at expected address.
    bytes32 size;
    assembly { size := extcodesize(expectedSmartWallet) }
    if (size == 0) {
      require(
        _WALLET_FACTORY.getNextSmartWallet(userSigningKey) == expectedSmartWallet,
        "Smart wallet to be deployed does not match expected smart wallet."
      );
      smartWallet = _WALLET_FACTORY.newSmartWallet(userSigningKey);
    } else {
      // Note: the smart wallet at the expected address may have been modified
      // so that the supplied user signing key is no longer a valid key.
      // Therefore, treat this helper as a way to protect against race
      // conditions, not as a primary mechanism for interacting with smart
      // wallet contracts.
      smartWallet = expectedSmartWallet;
    }
  }

  function _getVersion() internal view returns (uint256 version) {
    (, bytes memory data) = _SMART_WALLET_UPGRADE_BEACON.staticcall("");
    address implementation = abi.decode(data, (address));
    version = DharmaSmartWalletInterface(implementation).getVersion();
  }
}