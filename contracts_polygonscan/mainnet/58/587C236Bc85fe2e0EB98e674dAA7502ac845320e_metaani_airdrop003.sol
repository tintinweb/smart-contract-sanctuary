// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract metaani_airdrop003 is  ERC721URIStorage , ERC721Enumerable {

    address public owner;
    uint nftid = 1;
    bool airdropon = true;
    
    string currentURI = "ipfs://QmVakKWS12uLfexfFmUM3Nqv42mLojv5PUnyciQBoCmgCh";
    address airdropperaddress = 0xE43B62a6817210C1b5A37780737f3e744A7f219d;

    event Mint();
    event SetTokenURI( uint256 , string );

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
        
        if ( keccak256(abi.encodePacked(super.tokenURI(tokenId))) != keccak256(abi.encodePacked(""))){
        return super.tokenURI(tokenId);
        } else {
        return currentURI;
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

    function airdrop(address _userAddress) public {
        require( _msgSender() == airdropperaddress );
        require( airdropon );
        _safeMint( _userAddress , nftid);
        emit Mint();
        nftid++;
    }

    function airdropToYourFriend(address _userAddress) public {
        require( airdropon );
        _safeMint( _userAddress , nftid);
        emit Mint();
        nftid++;
    }

    function startairdrop() public {
        require( _msgSender() == airdropperaddress );
        airdropon = true;
    }

    function stopairdrop() public {
        require( _msgSender() == airdropperaddress );
        airdropon = false;
    }


    constructor() ERC721("metaani_airdrop003" , "metaani_airdrop003" ) {
        owner = airdropperaddress;
        
        }
    
}