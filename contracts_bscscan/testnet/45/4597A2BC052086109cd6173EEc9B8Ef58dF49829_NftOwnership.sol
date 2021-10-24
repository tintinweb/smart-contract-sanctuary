pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT
/**
 * @title Ownership
 * Check Ownership of nfts
 * Developed for the RugZombie platform but compatible with all BEP721's
 */


interface Nft {
    function totalSupply() external view returns (uint);
    function ownerOf(uint tokenId)external view returns (address);
    function balanceOf(address owner) external view returns(uint);
}

contract NftOwnership {

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
        for (uint id = 0; id < totalSupply; id++) {
            // contracts whose owner is the given address are added to the array to be returned.
            // incrementing id by one because nft ids start from 1
            if (walletAddress == Nft(contractAddress).ownerOf(id + 1)) {
                ids[indexToInsert] = id + 1;
                indexToInsert++;
            }
        }
        return ids;
    }

    function massCheckOwnership(address walletAddress, address[] memory contractAddresses) public view returns (uint[][] memory) {
        // initializing 2d array of owned ids
        uint[][] memory ids = new uint[][](contractAddresses.length);
        // calling and storing the result of checkOwnership called on each nft contract
        for(uint x = 0;  x < contractAddresses.length; x++) {
            ids[x] = checkOwnership(walletAddress, contractAddresses[x]);
        }
        return ids;
    }

    function _getTotalSupply(address contractAddress) internal view returns(uint256) {
        return Nft(contractAddress).totalSupply();
    }

    function _getBalanceOf(address contractAddress, address owner) internal view returns(uint256) {
        return Nft(contractAddress).balanceOf(owner);
    }

}