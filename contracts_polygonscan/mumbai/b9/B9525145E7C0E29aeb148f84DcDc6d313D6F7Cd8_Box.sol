/**
 *Submitted for verification at polygonscan.com on 2021-10-10
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

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


// File contracts/BoxStorage.sol

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

contract BoxStorage is Initializable {
  //TODO: update byte32 to correct value
  bytes32 internal constant _VALUE_SLOT =
    0xf1a169aa0f736c2813818fdfbdc5755c31e0839c8f49831a16543496b28574ea;

  function initializeStore(
    uint256 _value
  ) public initializer {
    _setValue(_value);
  }

  function _setValue(uint256 _value) internal {
    setUint256(_VALUE_SLOT, _value);
  }
  function _value() internal view returns (uint256)  {
    return getUint256(_VALUE_SLOT);
  }

  function setAddress(bytes32 slot, address _address) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }


  function getAddress(bytes32 slot) private view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) private view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  uint256[50] private ______gap;
}


// File contracts/Box.sol

// contracts/Box.solpragma solidity ^0.8.0;


contract Box is BoxStorage {

    function initializeBox(
        uint256 value
    ) public initializer {
        BoxStorage.initializeStore(value);
    } 
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return _value();
    }
}