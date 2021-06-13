// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract sushi_top_shot_isl1 is  ERC721URIStorage , ERC721Enumerable {

    address public creator;
    address engineer = 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7;

    uint256 public nftid = 1;

    string currentURI = "";

    event Mint();
    event SetTokenURI( uint256 , string );
    event SetCurrentURI( string );

    function mint() public {
        require( creator == _msgSender() );
        _safeMint( creator , nftid);
        _setTokenURI( nftid , currentURI );
        emit Mint();
        emit SetTokenURI( nftid , currentURI );
        nftid++;
    }


    function setCurrentURI( string memory _uri ) public {
        require( _msgSender() == creator || _msgSender() == engineer );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        currentURI = _uri;
        emit SetCurrentURI( _uri );
    }

    function setTokenURI( string memory _uri ) public {
        require( _msgSender() == creator );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        _setTokenURI( nftid , currentURI );
        emit SetTokenURI( nftid , currentURI );
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


    function _baseURI() internal pure override returns (string memory) {
        return "";
    }
    

    constructor() ERC721("SUSHI TOP SHOT ISL1" , "STSISL1" ) {
        creator = _msgSender();
    } 


}