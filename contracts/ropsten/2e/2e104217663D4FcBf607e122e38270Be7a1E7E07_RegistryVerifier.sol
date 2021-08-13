// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import {Verifier} from "./Verifier.sol";

contract Registry {
    address superuser;

    // User `_u` is considered accredited for all Unix timestamps strictly
    // smaller than `expirations[_u]`.
    mapping(address => uint256) expirations;

    constructor() {
        superuser = msg.sender;
    }

    modifier onlySuperuser {
        require(msg.sender == superuser);
        _;
    }

    function setSuperuser(address _superuser) external onlySuperuser {
        superuser = _superuser;
    }

    function currentlyValid(address _who) external view returns (bool) {
        return block.timestamp < expirations[_who];
    }

    function expiration(address _who) external view returns (uint256) {
        return expirations[_who];
    }

    function setExpiration(address _who, uint256 _when) external onlySuperuser {
        expirations[_who] = _when;
    }

    function setExpirations(Expiration[] memory _data) external onlySuperuser {
        for (uint256 _i = 0; _i < _data.length; _i++) {
            expirations[_data[_i].who] = _data[_i].when;
        }
    }
}

struct Expiration {
    address who;
    uint256 when;
}

contract RegistryVerifier is Verifier {
    Registry registry;

    constructor(Registry _registry) {
        registry = _registry;
    }

    function mayReceive(address _who) external view override returns (bool) {
        return registry.currentlyValid(_who);
    }
}

contract PushoverVerifier is Verifier {
    function mayReceive(address _who) external pure override returns (bool) {
        _who;
        return true;
    }
}

contract NoTradingVerifier is Verifier {
    function mayReceive(address _who) external pure override returns (bool) {
        _who;
        return false;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

interface Verifier {
    // Checks whether an address is permitted to receive unrestricted stock.
    // For instance, this might verify that the address corresponds to an
    // accredited investor.
    function mayReceive(address _who) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}