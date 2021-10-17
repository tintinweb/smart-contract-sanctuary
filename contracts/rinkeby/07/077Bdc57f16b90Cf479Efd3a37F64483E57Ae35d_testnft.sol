// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract testnft is  ERC721URIStorage , ERC721Enumerable {

    address public owner;

    uint256 public nftid = 1;

    event Mint();
    event SetTokenURI( uint256 , string );

    function mint(string memory _uri) public {
        _safeMint( msg.sender , nftid);
        _setTokenURI( nftid , _uri );
        emit Mint();
        emit SetTokenURI( nftid , _uri );
        nftid++;
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



    constructor() ERC721("testnft" , "TNFT" ) {
        owner = _msgSender();
    } 

}