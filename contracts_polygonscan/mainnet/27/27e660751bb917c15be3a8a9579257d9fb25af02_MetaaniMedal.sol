// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract MetaaniMedal is  ERC721URIStorage , ERC721Enumerable {

    address public owner;

    uint256 public nftid = 1;

    string currentURI = "ipfs://QmQxJogDXoXSgMub6QrWcgqmP5xg6qFmFbWNqWNLGQ7Uip";

    event Mint();
    event SetTokenURI( uint256 , string );
    event SetCurrentURI( string );


    address mekezzo = 0xcc344De89bB3CB8F6c6134dDb338847cE58f64cA;
    address misoshita = 0xd9a126b386455925E7a464eAC06Ab603c5043b2f;
    address nandemotoken = 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7;
    address metawallet = 0x60a89BB4C35A62DE53e4E1852E2d4037a008aC5b;


    function mint() public {
        require( _msgSender() == owner || _msgSender() == mekezzo || _msgSender() == misoshita || _msgSender() == nandemotoken ||  _msgSender() == metawallet );
        _safeMint( owner , nftid);
        _setTokenURI( nftid , currentURI );
        emit Mint();
        emit SetTokenURI( nftid , currentURI );
        nftid++;
    }


    function setCurrentURI( string memory _uri ) public {
        require( _msgSender() == owner || _msgSender() == mekezzo || _msgSender() == misoshita || _msgSender() == nandemotoken ||  _msgSender() == metawallet );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        currentURI = _uri;
        emit SetCurrentURI( _uri );
    }

    function setTokenURI( uint targetnftid ,string memory _uri ) public {
        require( _msgSender() == owner || _msgSender() == mekezzo || _msgSender() == misoshita || _msgSender() == nandemotoken ||  _msgSender() == metawallet );
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



    constructor() ERC721("metaani_medal" , "MEDAL" ) {
        owner = _msgSender();
    } 


}