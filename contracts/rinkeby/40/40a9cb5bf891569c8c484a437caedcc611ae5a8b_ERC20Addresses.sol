/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

pragma solidity ^0.5.17;

// library for erc20address array 
library ERC20Addresses {
    using ERC20Addresses for erc20Addresses;

    struct erc20Addresses {
        address[] array;
    }

    function addERC20Tokens(erc20Addresses storage self, address erc20address)
        external
    {
        self.array.push(erc20address);
    }

    function getIndexByERC20Token(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool exists;

        for (uint256 i = 0; i < self.array.length; i++) {
            if (self.array[i] == _ercTokenAddress) {
                index = i;
                exists = true;

                break;
            }
        }
        return (index, exists);
    }

    function removeERC20Token(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal {
        if (self.array.length > 1){
            for (uint256 i = 0; i < self.array.length; i++) {
                    if (
                        self.array[i] == _ercTokenAddress 
                    ) {
                        delete self.array[i];
                    }
                }
        }
        else{
            self.array.length = 0;
        }
    }
    function exists(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _ercTokenAddress 
            ) {
                return true;
            }
        }
        return false;
    }
}