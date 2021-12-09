/**
 *Submitted for verification at Etherscan.io on 2021-12-09
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

interface ILeedoERC20 {
    function claims(uint _season, uint _tokenId) external view returns (bool);
    function claimBlocksRequired() external view returns (uint);
    function season() external view returns (uint);
}

interface ILeedoNftVault {
    function ownerOf(uint tokenId) external view returns (address owner);
    function lastBlocks(address addr) external view returns (uint black);
    function tokensOf(address _account) external view returns (uint[] memory);
}


contract NftOwner {
    
    address public nftAddr;
    address public nftVaultAddr;
    address public erc20Addr;
    

    constructor(address _nftAddr, address _nftVaultAddr, address _erc20Addr) {
        nftAddr = _nftAddr;
        nftVaultAddr = _nftVaultAddr;
        erc20Addr = _erc20Addr;
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

    function getUnclaims(address _addr) external view returns (uint[] memory) {
        ILeedoNftVault vault = ILeedoNftVault(nftVaultAddr);
        ILeedoERC20 erc20 = ILeedoERC20(erc20Addr);
        //require(vault.lastBlocks(_addr) + erc20.claimBlocksRequired() < block.number, 'ERC20: does not meet claimBlockRequired');
        uint[] memory sTokens = vault.tokensOf(_addr);
        for(uint i=0; i<sTokens.length; i++) {
            if (erc20.claims(erc20.season(), sTokens[i])) {
                delete sTokens[i];
            }
        }
        return sTokens;
    }
}