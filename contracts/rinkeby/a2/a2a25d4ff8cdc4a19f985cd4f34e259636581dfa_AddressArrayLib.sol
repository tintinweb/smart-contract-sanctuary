/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// library for address array 
library AddressArrayLib {
    using AddressArrayLib for addresses;

    struct addresses {
        address[] array;
    }

    function add(addresses storage self, address _address)
        external
    {
        if(! exists(self, _address)){
            self.array.push(_address);
        }
    }

    function getIndexByAddress(
        addresses storage self,
        address _address
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool exists_;

        for (uint256 i = 0; i < self.array.length; i++) {
            if (self.array[i] == _address) {
                index = i;
                exists_ = true;
                break;
            }
        }
        return (index, exists_);
    }

    function remove(
        addresses storage self,
        address _address
    ) internal {
       for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                delete self.array[i];
            }
        }
    }


    function exists(
        addresses storage self,
        address _address
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                return true;
            }
        }
        return false;
    }
}