/////////////////////////////////////////////////////////////////////////////////////
//
//  SPDX-License-Identifier: MIT
//
//  ███    ███  ██████  ███    ██ ███████ ██    ██ ██████  ██ ██████  ███████
//  ████  ████ ██    ██ ████   ██ ██       ██  ██  ██   ██ ██ ██   ██ ██     
//  ██ ████ ██ ██    ██ ██ ██  ██ █████     ████   ██████  ██ ██████  █████  
//  ██  ██  ██ ██    ██ ██  ██ ██ ██         ██    ██      ██ ██      ██     
//  ██      ██  ██████  ██   ████ ███████    ██    ██      ██ ██      ███████
//
//  ██████  ██    ██ ███████ ███████ ███████ ██████  
//  ██   ██ ██    ██ ██      ██      ██      ██   ██ 
//  ██████  ██    ██ █████   █████   █████   ██████  
//  ██   ██ ██    ██ ██      ██      ██      ██   ██ 
//  ██████   ██████  ██      ██      ███████ ██   ██ 
//
//  https://moneypipe.xyz
//
/////////////////////////////////////////////////////////////////////////////////////
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
contract Buffer is Initializable {
  mapping (address => uint) public withdrawn;
  bytes32 public root;
  uint public totalReceived;
  function initialize(bytes32 _root) initializer public {
    root = _root;
  }
  receive () external payable {
    totalReceived += msg.value;
  }
  function withdraw(address account, uint256 amount, bytes32[] calldata proof) external payable {
    // 1. verify proof
    bytes32 hash = keccak256(abi.encodePacked(account, amount));
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];
      if (hash <= proofElement) {
        hash = _hash(hash, proofElement);
      } else {
        hash = _hash(proofElement, hash);
      }
    }
    require(hash == root, "1");
    // 2. calculate amount to withdraw based on "amount" (out of 1,000,000,000,000)
    uint payment = totalReceived * amount / 10**12 - withdrawn[account];
    withdrawn[account] += payment;
    _transfer(account, payment);
  }
  // memory optimization from: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3039
  function _hash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
  // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
  error TransferFailed();
  function _transfer(address to, uint256 amount) internal {
    bool callStatus;
    assembly {
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!callStatus) revert TransferFailed();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}