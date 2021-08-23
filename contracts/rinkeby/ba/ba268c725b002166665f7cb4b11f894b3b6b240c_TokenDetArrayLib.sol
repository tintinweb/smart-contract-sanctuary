/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;


library TokenDetArrayLib{
    // Using for array of strcutres for storing mintable address and token id 
    using TokenDetArrayLib for TokenDets;

    struct  TokenDet {
        address NFTAddress;
        uint256 tokenID;
    }

    // custom type array TokenDets
    struct TokenDets {
        TokenDet[] array;
    }

    /**
     * @notice push an tokenDet to the array
     * @dev if the address already exists, it will not be added again
     * @param self Storage array containing tokenDet type variables
     */
    function addTokenDet(TokenDets storage self,address _mintableaddress,uint256 _tokenID) public {
        if(!self.exists(_mintableaddress, _tokenID)){
            self.array.push(TokenDet(_mintableaddress, _tokenID));
        }
    }

    /**
     * @notice get the tokenDet at a specific index from array
     * @dev revert if the index is out of bounds
     * @param self Storage array containing tokenDet type variables
     */
    function getIndexByTokenDet(TokenDets storage self, address _mintableaddress,uint256 _tokenID) internal view returns(uint256, bool) {
        uint256 index;
        bool exists = false;
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _mintableaddress &&
                self.array[i].tokenID == _tokenID
            ) {
                index =i;
                exists = true;
                break;
            }
        }
        return (index, exists);
    }    

    /**
     * @notice remove an tokenDet from the array
     * @dev finds the tokenDet, swaps it with the last tokenDet, and then deletes it;
     *      returns a boolean whether the tokenDet was found and deleted
     * @param self Storage array containing tokenDet type variables
     */
    function removeTokenDet(TokenDets storage self, address _mintableaddress,uint256 _tokenID) internal returns (bool) {
        
            (uint256 i, bool exists)  = self.getIndexByTokenDet(_mintableaddress,_tokenID);
            if (exists == true) {
                self.array[i] = self.array[self.array.length - 1];
                self.array.pop();
                return true;
            }
        return false;
    }
    
    /**
     * @notice check if an tokenDet exist in the array
     * @param self Storage array containing tokenDet type variables
    
     */
    function exists(TokenDets storage self, address _mintableaddress,uint256 _tokenID) internal view returns (bool) {
        for (uint i = 0; i < self.array.length; i++) {
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