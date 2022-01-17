//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IAddressRegistry.sol';

contract AddressRegistry is IAddressRegistry {
    uint256 public nextId = 1;

    mapping(uint256 => address) private idToAddress;
    mapping(address => uint256) private addressToId;

    event AddressRegistered(address indexed addr, uint256 id);

    error InvalidLength();

    function getId(address addr) public returns (uint256 id) {
        id = addressToId[addr];
        
        if (id == 0) {
            id = nextId;
            nextId += 1;

            idToAddress[id] = addr;
            addressToId[addr] = id;

            emit AddressRegistered(addr, id);
        }
    }

    function peekId(address addr) external view returns (uint256 id) {
        id = addressToId[addr];
    }

    function getAddress(uint256 id) external view returns (address addr) {
        return idToAddress[id];
    }

    function getMinBytes() external view returns (uint256) {
        uint256 _nextId = nextId;

        for (uint256 _bytes = 8; _bytes < 256; _bytes += 8) {
            uint maxValue = 1 << _bytes;
            if (maxValue >= _nextId) {
                return _bytes;
            }
        }
        return 256;
    }

    function getSafeMinBytes() external view returns (uint256) {
        uint256 _nextId = nextId + 5000;

        for (uint256 _bytes = 8; _bytes < 256; _bytes += 8) {
            uint maxValue = 1 << _bytes;
            if (maxValue >= _nextId) {
                return _bytes;
            }
        }
        return 256;
    }

    fallback() external {
        if (msg.data.length % 20 != 0) {
            revert InvalidLength();
        }

        uint256 numAddresses = msg.data.length / 20;
        for (uint256 i = 0; i < numAddresses; i += 1) {
            uint256 offset = i * 20;
            address addr = address(bytes20(msg.data[offset:offset + 20]));
            this.getId(addr);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressRegistry {
    function nextId() external view returns (uint256);

    function getId(address addr) external returns (uint256 id);

    function peekId(address addr) external view returns (uint256 id);

    function getAddress(uint256 id) external view returns (address addr);
}