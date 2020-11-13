// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library AddrArrayLib {
    using AddrArrayLib for Addresses;

    struct Addresses {
      address[]  _items;
    }
    function pushAddress(Addresses storage self, address element) internal {
      if (!exists(self, element)) {
        self._items.push(element);
      }
    }
    function removeAddress(Addresses storage self, address element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }
    function getAddressAtIndex(Addresses storage self, uint256 index) internal view returns (address) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }
    function size(Addresses storage self) internal view returns (uint256) {
      return self._items.length;
    }
    function exists(Addresses storage self, address element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }
    function getAllAddresses(Addresses storage self) internal view returns(address[] memory) {
        return self._items;
    }
}

interface Minter {
    // Mint new tokens
    function mint(address to, uint256 amount) external returns (bool);
    function changeOwner(address to) external;
    function changeMinter(address to) external;
}

contract Manager {
    using AddrArrayLib for AddrArrayLib.Addresses;
    AddrArrayLib.Addresses managers;
    
    event addManager(address manager);
    event delManager(address manager);

    constructor (address owner) public {
        managers.pushAddress(owner);
        emit addManager(owner);
    }

    modifier ownerOnly() {
        require(managers.exists(msg.sender));
        _;
    }

    function createManager(address manager) public ownerOnly {
        managers.pushAddress(manager);
        emit addManager(manager);
    }

    function rmManager(address manager) public ownerOnly {
        managers.removeAddress(manager);
        emit delManager(manager);
    }

    function mint(address token, address to, uint256 amount) public ownerOnly returns(bool) {
        Minter(token).mint(to, amount);
        return true;
    }

    function migrate(address token, address to, bool minter) public ownerOnly {
        if (minter) {
            Minter(token).changeMinter(to);
        } else {
            Minter(token).changeOwner(to);
        }
    }

    function listManagers() public view returns(address[] memory) {
        return managers.getAllAddresses();
    }
}