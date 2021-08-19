/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT
/**
 * @title Ownership
 * check Ownership of nfts
 */
 
interface deployedContract {
    function totalSupply() external view returns (uint);
    function ownerOf(uint tokenId)external view returns (address);
    function balanceOf(address owner) external view returns(uint);
}
 
contract Ownership {
    
    function checkOwnership(address walletAddress, address contractAddress) public view returns (uint[] memory){
        // getting total supply of the contract
        uint256 totalSupply = _getTotalSupply(contractAddress);
        // getting total number of nfts owned by an address
        uint balance = _getBalanceOf(contractAddress, walletAddress);
        // initializing an array with the size of total number of nfts owned by an address. 
        uint[] memory ids = new uint[](balance);
        // index to insert the nft id in ids array, no need to iterate over and over again on ids array
        uint indexToInsert = 0;
        // iterating through the total number of nfts present in contract
        for (uint id = 0; id < totalSupply; totalSupply++) {
            // contracts whose owner is the given address are added to the array to be returned.
            if (walletAddress == deployedContract(contractAddress).ownerOf(id + 1)) {
                ids[indexToInsert] = id;
                indexToInsert++;
            } 
        }
        return ids; 
    }
    
    function _getTotalSupply(address contractAddress) internal view returns(uint256) {
        return deployedContract(contractAddress).totalSupply();
    }
    
    function _getBalanceOf(address contractAddress, address owner) internal view returns(uint256) {
        return deployedContract(contractAddress).balanceOf(owner);
    }
    
    function getTotalSupply(address contractAddress) public view returns(uint256) {
        return deployedContract(contractAddress).totalSupply();
    }
    
    function getBalanceOf(address contractAddress, address owner) public view returns(uint256) {
        return deployedContract(contractAddress).balanceOf(owner);
    }
    
}