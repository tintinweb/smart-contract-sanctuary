/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File contracts/library/IterableAddressSet.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library IterableAddressSet {

    struct Set {
        address[] keys;
        mapping(address => uint256) ids;
    }

    function inside(Set storage self, address x) public view returns (bool) {
        return self.ids[x] != 0;
    }

    function add(Set storage self, address x) public {
        if (!inside(self, x)) {
            self.keys.push(x);
            self.ids[x] = self.keys.length;
        }
    }

    function remove(Set storage self, address x) public {
        if (inside(self, x)) {
            uint256 id = self.ids[x] - 1;
            uint256 last = self.keys.length - 1;
            if (id != last) {
                self.ids[self.keys[last]] = id + 1;
                (
                    self.keys[last],
                    self.keys[id]
                ) = (
                    self.keys[id],
                    self.keys[self.keys.length - 1]
                );
            }
            delete self.ids[x];
            self.keys.pop();
        }
    }
}