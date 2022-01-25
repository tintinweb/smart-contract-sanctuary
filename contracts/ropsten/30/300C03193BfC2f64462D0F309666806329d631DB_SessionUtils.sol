// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./commons/GapNonceUtils.sol";
import "./commons/NonceResetUtils.sol";

import "../commons/ModuleERC165.sol";
import "../commons/interfaces/IModuleAuthUpgradable.sol";


contract SessionUtils is GapNonceUtils, NonceResetUtils {
  //                       SESSION_SPACE = bytes32(uint256(uint160(bytes20(keccak256("org.sequence.sessions.space")))));
  //                                     = 0x96f7fef04d2478e2b011c3aca79dc5a83b5d37ef
  uint256 private constant SESSION_SPACE = 861879107978547650890364157709704413515112855535;

  /**
   * @notice Enforces the order of execution for pre-signed session transactions.
   * @dev It uses gap nonce instead of regular nonces, so the order is guaranteed but transactions can be skipped.
   * @param _nonce The gap nonce of the transaction.
   */
  function requireSessionNonce(uint256 _nonce) external {
    // Require gap nonce
    _requireGapNonce(SESSION_SPACE, _nonce);

    // Reset regular nonce
    _resetNonce(SESSION_SPACE);
  
    // Should support AuthModuleUpgradable
    // otherwise the wallet wasn't upgraded
    require(
      ModuleERC165(address(this)).supportsInterface(type(IModuleAuthUpgradable).interfaceId),
      "SessionUtils#requireSessionNonce: WALLET_NOT_UPGRADED"
    );
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../../commons/ModuleStorage.sol";


contract GapNonceUtils {
  event GapNonceChange(uint256 _space, uint256 _oldNonce, uint256 _newNonce);

  //                       GAP_NONCE_KEY = keccak256("org.sequence.module.gapnonce.nonce");
  bytes32 internal constant GAP_NONCE_KEY = bytes32(keccak256("org.sequence.module.gapnonce.nonce"));

  /**
   * @notice Returns the current nonce for a given gap space
   * @param _space Nonce space, each space keeps an independent nonce count
   * @return The current nonce
   */
  function _readGapNonce(uint256 _space) internal view returns (uint256) {
    return uint256(ModuleStorage.readBytes32Map(GAP_NONCE_KEY, bytes32(_space)));
  }

  /**
   * @notice Changes the gap nonce of the given space
   * @param _space Nonce space, each space keeps an independent nonce count
   * @param _nonce Nonce to write to the space
   */
  function _writeGapNonce(uint256 _space, uint256 _nonce) internal {
    ModuleStorage.writeBytes32Map(GAP_NONCE_KEY, bytes32(_space), bytes32(_nonce));
  }

  /**
   * @notice Requires current nonce to be below the value provided, updates the current nonce
   * @dev Throws if the current nonce is not below the value provided
   * @param _space Nonce space, each space keeps an independent nonce count
   * @param _nonce Nonce to check against the current nonce
   */
  function _requireGapNonce(uint256 _space, uint256 _nonce) internal {
    // Read the current nonce
    uint256 currentNonce = _readGapNonce(_space);

    // Verify that the provided nonce
    // is above the current nonce
    require(
      _nonce > currentNonce,
      "GapNonceUtils#_requireGapNonce: INVALID_NONCE"
    );

    // Store new nonce value
    _writeGapNonce(_space, _nonce);

    // Emit event
    emit GapNonceChange(_space, currentNonce, _nonce);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../../commons/ModuleStorage.sol";


contract NonceResetUtils {
  //                       NONCE_KEY = keccak256("org.arcadeum.module.calls.nonce");
  bytes32 internal constant NONCE_KEY = bytes32(0x8d0bf1fd623d628c741362c1289948e57b3e2905218c676d3e69abee36d6ae2e);

  event ResetNonce(uint256 _space);

  /**
   * @notice Changes the current nonce of the given nonce space
   * @param _space Nonce space, each space keeps an independent nonce count
   * @param _nonce Nonce to write to the space
   */
  function _writeNonce(uint256 _space, uint256 _nonce) internal {
    ModuleStorage.writeBytes32Map(NONCE_KEY, bytes32(_space), bytes32(_nonce));
  }

  /**
   * @notice Resets the current nonce of the given nonce space back to 0
   * @param _space Nonce space, each space keeps an independent nonce count
   */
  function _resetNonce(uint256 _space) internal {
    // Set nonce back to 0
    _writeNonce(_space, 0);

    // Emit event
    emit ResetNonce(_space);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;


abstract contract ModuleERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @dev Adding new hooks will not lead to them being reported by this function
   *      without upgrading the wallet. In addition, developpers must ensure that 
   *      all inherited contracts by the mainmodule don't conflict and are accounted
   *      to be supported by the supportsInterface method.
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) virtual public pure returns (bool) {
    return _interfaceID == this.supportsInterface.selector;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


interface IModuleAuthUpgradable {
  /**
   * @notice Updates the signers configuration of the wallet
   * @param _imageHash New required image hash of the signature
   */
  function updateImageHash(bytes32 _imageHash) external;

  /**
   * @notice Returns the current image hash of the wallet
   */
  function imageHash() external view returns (bytes32);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


library ModuleStorage {
  function writeBytes32(bytes32 _key, bytes32 _val) internal {
    assembly { sstore(_key, _val) }
  }

  function readBytes32(bytes32 _key) internal view returns (bytes32 val) {
    assembly { val := sload(_key) }
  }

  function writeBytes32Map(bytes32 _key, bytes32 _subKey, bytes32 _val) internal {
    bytes32 key = keccak256(abi.encode(_key, _subKey));
    assembly { sstore(key, _val) }
  }

  function readBytes32Map(bytes32 _key, bytes32 _subKey) internal view returns (bytes32 val) {
    bytes32 key = keccak256(abi.encode(_key, _subKey));
    assembly { val := sload(key) }
  }
}