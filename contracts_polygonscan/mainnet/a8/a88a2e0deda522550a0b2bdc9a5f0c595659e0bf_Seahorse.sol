// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract Seahorse is  ERC721URIStorage , ERC721Enumerable {

    address public owner;

    bool public switchon = false;

    event Mint();

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
        if(switchon){
            return "https://arweave.net/GBUq1lATXeor4KN3X_v8N0Yaoj0jR9tuzKr4VAnUwj4";
        }else{
            return "https://arweave.net/NtaEnRKN58vhBn9kgluG7Du1MbfWHA5SvQ6qXR27St4";
        }
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function on() public {
        require(_msgSender() == this.ownerOf(1) );
        switchon = true;
    }

    function off() public {
        require(_msgSender() == this.ownerOf(1) );
        switchon = false;
    }

    constructor() ERC721("Seahorse" , "SH" ) {
        owner = _msgSender();
        _safeMint( _msgSender() , 1);
        emit Mint();
    } 


}