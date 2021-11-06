/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev LEEDO NFT Ownership Proxy
 *
 *  _              ______      
 * | |             |  _  \     
 * | |     ___  ___| | | |___  
 * | |    / _ \/ _ \ | | / _ \ 
 * | |___|  __/  __/ |/ / (_) |
 * \_____/\___|\___|___/ \___/ 
 * LEEDO Project
 */

interface INft {

    function ownerOf(uint tokenId) external view returns (address owner);
    function tokensOf(address account) external view returns (uint[] memory);
    function balanceOf(address account) external view returns (uint256); 
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    
}

contract NftOwner {
    
    address public nftAddr;
    address public nftVaultAddr;
    

    constructor(address _nftAddr, address _nftVaultAddr) {
        nftAddr = _nftAddr;
        nftVaultAddr = _nftVaultAddr;
    }
    
    function ownerOf(uint _tokenId) external view returns (address) {
        INft NFT = INft(nftAddr);
        if (NFT.ownerOf(_tokenId) == nftVaultAddr) {
            INft Vault = INft(nftVaultAddr);
            return Vault.ownerOf(_tokenId);
        } else {
            return NFT.ownerOf(_tokenId);
        }
    }

    function tokensOf(address _account, bool staked) external view returns (uint[] memory) {
        if(staked) {
            return INft(nftVaultAddr).tokensOf(_account);
        } else {
            INft nft = INft(nftAddr);
            uint count = nft.balanceOf(_account);
            uint[] memory tokenIds = new uint256[] (count);
            for(uint i=0; i < count; i++) {
                tokenIds[i] = nft.tokenOfOwnerByIndex(_account, i);
            }
            return tokenIds;
        }
    }
}