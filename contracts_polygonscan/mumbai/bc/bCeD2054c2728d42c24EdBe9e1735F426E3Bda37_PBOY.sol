//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";
import "./ERC721.sol";

contract PBOY is ERC721, Ownable {
    string SYMBOL = "PBOY";
    string NAME = "Pascal Boyart";
    
    string ContractCID;
    mapping (uint256 => string) TokenCIDs;

    uint256 TokenID = 1;

    constructor() ERC721(NAME, SYMBOL) {}

    // Mint functions ****************************************************

    function mintPBOY(string memory CID)
    public onlyOwner {
        TokenCIDs[TokenID] = CID;
        _safeMint(msg.sender, TokenID++);
    }
    
    // Token URI functions ***********************************************

    function tokenURI(uint256 tokenId)
    public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked("ipfs://", TokenCIDs[tokenId]));
    }

    // Contract URI functions *********************************************
    
    function setContractCID(string memory CID)
    public onlyOwner {
        ContractCID = CID;
    }
    
    function contractURI()
    public view virtual returns (string memory) {
        return string(abi.encodePacked("ipfs://", ContractCID));
    }

    // ERC721 Spec functions **********************************************
    
    function _beforeTokenTransfer(address from, address to, uint tokenId)
    internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}