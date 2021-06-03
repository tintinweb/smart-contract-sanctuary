// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Registry.sol";

contract BlockedUserRegistry is Registry {
    constructor(address owner_) Registry(owner_) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract Registry {
    event AddressAdded(address account);
    event AddressRemoved(address account);

    address private _owner;
    mapping(address => bool) internal _registry;

    modifier onlyOwner {
        require(_owner == msg.sender);
        _;
    }

    /**
     * @dev Sets {owner}.
     */
    constructor(address owner_) {
        _owner = owner_;
    }

    /**
     * @dev Gets `addr_` value from the registry.
     */
    function get(address _addr) public view returns (bool) {
        return _registry[_addr];
    }

    /**
     * @dev Adds `addr_` to the registry.
     */
    function add(address addr_) onlyOwner public {
        _registry[addr_] = true;
        emit AddressAdded(addr_);
    }

    /**
     * @dev Removes `addr_` from the registry.
     */
    function remove(address addr_) onlyOwner public {
        delete _registry[addr_];
        emit AddressRemoved(addr_);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}