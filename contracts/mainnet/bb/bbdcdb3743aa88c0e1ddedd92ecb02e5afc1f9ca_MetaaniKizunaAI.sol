// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;


import "./OpenzeppelinERC721.sol";

contract MetaaniKizunaAI is  ERC721URIStorage , ERC721Enumerable {

    address metaani = 0xeecE4544101f7C7198157c74A1cBfE12aa86718B;
    address kizunaai_metaani = 0xD56F0b3D880b3321692661a4b0AcC5Cd5039ECfb;
    string ipfs_base;
    address public owner;
    uint256 public nftid;
    event Mint();

    function mint(uint256 _qty) public {
        require( msg.sender == metaani );
        for (uint i = 1 ; i <= _qty ; i++){
        nftid++;
        require( nftid <= 200 );
        _safeMint( kizunaai_metaani , nftid);
        emit Mint();
        }
    }



    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burn(uint256 _id) public {
        require( _msgSender() == ownerOf(_id));
        _burn(_id);
    }

    function setbaseURI(string memory _ipfs_base) public {
        require(msg.sender == metaani );
        ipfs_base = _ipfs_base;
    }

    function _baseURI() internal view override returns (string memory) {
        return ipfs_base;
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    constructor() ERC721("MetaaniKizunaAI" , "MTANAI" ) {
        owner = _msgSender();
        ipfs_base = "ipfs://QmTYKXWWg8jQV21mcvvqTyd3qf8BreBG8iyffabLvvvo5q/";
    } 


}