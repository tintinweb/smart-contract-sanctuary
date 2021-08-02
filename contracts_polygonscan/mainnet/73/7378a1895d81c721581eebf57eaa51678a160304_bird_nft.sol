// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract bird_nft is  ERC721URIStorage , ERC721Enumerable {

    address public owner;

    string uri_with_bird = "https://arweave.net/X5eewf5bU0HWqpyndS6C7uISIHrhFKdMAkT3E_t70wU";
    string uri_without_bird = "https://arweave.net/qeSAoPyKo3PjAG1KgSLDAxm29j3nylGygLUF9FrSMsk";
    bool magicon=false;

    mapping( address => bool ) magicianMAP;

    event Mint();
    event SetTokenURI( uint256 , string );
    event SetCurrentURI( string );

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
        if(magicon){
        return uri_without_bird;
        }else{
        return uri_with_bird;
        }
    }

    function magicstart() public {
        require( magicianMAP[_msgSender()] );
        magicon = true;
    }

    function magicstop() public {
        require( magicianMAP[_msgSender()]);
        magicon = false;
    }

    function addmagician( address _newmagician ) public{
        require( magicianMAP[_msgSender()]);
        magicianMAP[_msgSender()] = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }



    constructor() ERC721("bird magic" , "BIRD_MAGIC" ) {
        owner = _msgSender();
        magicianMAP[_msgSender()] = true;
        _safeMint( owner , 1);
        emit Mint();
    } 
}