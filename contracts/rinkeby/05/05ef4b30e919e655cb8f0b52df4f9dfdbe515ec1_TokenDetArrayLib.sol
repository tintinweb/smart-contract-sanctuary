/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity ^0.5.17;

// librray for TokenDets
library TokenDetArrayLib {
    // Using for array of strcutres for storing mintable address and token id
    using TokenDetArrayLib for TokenDets;

    struct TokenDet {
        address NFTAddress;
        uint256 tokenID;
    }

    // custom type array TokenDets
    struct TokenDets {
        TokenDet[] array;
    }

    function addTokenDet(
        TokenDets storage self,
        address _mintableaddress,
        uint256 _tokenID
    ) public {
        if (!self.exists(_mintableaddress, _tokenID)) {
            self.array.push(TokenDet(_mintableaddress, _tokenID));
        }
    }

    function getIndexByTokenDet(
        TokenDets storage self,
        address _mintableaddress,
        uint256 _tokenID
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool tokenExists = false;
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _mintableaddress &&
                self.array[i].tokenID == _tokenID
            ) {
                index = i;
                tokenExists = true;
                break;
            }
        }
        return (index, tokenExists);
    }

    function removeTokenDet(
        TokenDets storage self,
        address _mintableaddress,
        uint256 _tokenID
    ) internal returns (bool) {
        (uint256 i, bool tokenExists) = self.getIndexByTokenDet(
            _mintableaddress,
            _tokenID
        );
        if (tokenExists == true) {
            self.array[i] = self.array[self.array.length - 1];
            self.array.pop();
            return true;
        }
        return false;
    }

    function exists(
        TokenDets storage self,
        address _mintableaddress,
        uint256 _tokenID
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _mintableaddress &&
                self.array[i].tokenID == _tokenID
            ) {
                return true;
            }
        }
        return false;
    }
}