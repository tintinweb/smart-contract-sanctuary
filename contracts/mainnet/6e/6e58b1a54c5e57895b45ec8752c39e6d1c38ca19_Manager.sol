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
    function totalSupply() external view returns (uint256);
    function changeOwner(address to) external;
    function changeMinter(address to) external;
}

contract Manager {
    using AddrArrayLib for AddrArrayLib.Addresses;
    AddrArrayLib.Addresses managers;
    
    event addManager(address manager);
    event delManager(address manager);
    
    // Set total supply cap
    mapping (address=>uint256) clap;

    constructor (address owner, address token, uint256 supply) public {
        managers.pushAddress(owner);
        clap[token] = supply;
        emit addManager(owner);
    }

    modifier ownerOnly() {
        require(managers.exists(msg.sender));
        _;
    }

    function createManager(address manager) external ownerOnly {
        managers.pushAddress(manager);
        emit addManager(manager);
    }

    function rmManager(address manager) external ownerOnly {
        managers.removeAddress(manager);
        emit delManager(manager);
    }

    function mint(address token, address to, uint256 amount) external ownerOnly returns(bool) {
        if (clap[token]>0) {
            require(clap[token]>Minter(token).totalSupply());
        }
        Minter(token).mint(to, amount);
        return true;
    }

    function migrate(address token, address to, bool minter) external ownerOnly {
        if (minter) {
            Minter(token).changeMinter(to);
        } else {
            Minter(token).changeOwner(to);
        }
    }
    
    function addClap(address token, uint256 supply) external ownerOnly {
        clap[token] = supply;
    }

    function listManagers() public view returns(address[] memory) {
        return managers.getAllAddresses();
    }
}