/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

pragma solidity 0.8.9;

// SPDX-License-Identifier: CC0

interface ERC721 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract ERC721Scanner {
    
    
    function scan(address _contract, uint min, uint max) external view returns (uint[] memory) {
        ERC721 token = ERC721(_contract);
        require(token.supportsInterface(0x80ac58cd), 'not erc721');
     
        uint[] memory availableTokens = new uint[](max - min + 1);
        uint count = 0;

        for(uint i = 0; i < (max - min + 1); i++) {
            uint tokenId = i + min;
            try token.ownerOf(tokenId) returns (address addr) {
                if (addr == address(0)) {
                    availableTokens[count++] = tokenId;
                }
            } catch {
                availableTokens[count++] = tokenId;
            }
        }

        return availableTokens;
    }
}