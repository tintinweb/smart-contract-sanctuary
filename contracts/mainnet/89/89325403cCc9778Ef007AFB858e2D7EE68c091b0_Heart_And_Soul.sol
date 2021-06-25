// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract Heart_And_Soul is  ERC721URIStorage , ERC721Enumerable {

    address public owner;

    event PermanentURI(string _value, uint256 indexed _id);

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



    constructor() ERC721("Heart and Soul" , "HS" ) {
        owner = 0x0Ca338955087E3Fe5D968116028638720473D241;
        _safeMint( owner , 1);
        _setTokenURI( 1 , "https://arweave.net/rzQDPi_IDovH7UMMk6E902kiTI5_iPrZ3wZbW0duSuo" );
        emit PermanentURI("https://arweave.net/rzQDPi_IDovH7UMMk6E902kiTI5_iPrZ3wZbW0duSuo", 1);
    } 


}