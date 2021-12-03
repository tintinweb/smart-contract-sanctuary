/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier:UNLICENCED
pragma solidity ^0.8.0;

contract StructExample{
    struct NFT{
        uint256 id;
        string name;
        string symbol;
    }
    NFT[] allNFTs;

    function addNFT(NFT memory newNFT) public virtual{
        allNFTs.push(newNFT);
    }
    
    function listNFT() public virtual view returns(NFT[] memory){
        return allNFTs;
    }
}