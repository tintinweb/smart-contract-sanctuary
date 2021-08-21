// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract pnft is  ERC721URIStorage , ERC721Enumerable {

    address public owner;

    uint256 public nftid = 1;

    string currentURI = "";

    event Mint();
    event SetTokenURI( uint256 , string );
    event SetCurrentURI( string );


    bytes32 hashedpassword;


    function setCurrentURI( string memory _uri ) public {
        require( _msgSender() == owner  );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        currentURI = _uri;
        emit SetCurrentURI( _uri );
    }

    function setTokenURI( uint targetnftid ,string memory _uri ) public {
        require( _msgSender() == owner );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        _setTokenURI( targetnftid , _uri );
        emit SetTokenURI( targetnftid , _uri );
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




    function ZZZ(string memory _password) public view returns(string memory){
        if (hashedpassword != keccak256(abi.encodePacked(_password))){
            return "invalid password";
        }
        if (_msgSender() == ownerOf(1)){
            return "very good!(owner function with password)";
        }
        return "good! (password ok)";
    }


    constructor(string memory _password) ERC721("pnft" , "PNFT" ) {
        owner = _msgSender();
        hashedpassword =keccak256(abi.encodePacked( _password));
        _safeMint( _msgSender() , 1);
        _setTokenURI( 1 , "https://arweave.net/u3xTj2O16cykLhUcyKBt89pllKVLq89CDKD_xNSD6WI" );
        emit Mint();

    } 


}