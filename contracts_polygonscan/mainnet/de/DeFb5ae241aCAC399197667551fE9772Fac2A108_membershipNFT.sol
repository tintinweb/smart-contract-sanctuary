// SPDX-License-Identifier: NONE

pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721.sol";

contract membershipNFT is  ERC721URIStorage  {

    address public owner;
    uint nftid = 1;
    
    string currentURI = "https://arweave.net/4YeahVj6ga6dg6w2X223aRJL_7I995wXovyMprgoh6E";


    function setTokenURI( uint targetnftid ,string memory _uri ) public {
        require( _msgSender() == owner );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        _setTokenURI( targetnftid , _uri );
    }

    function setCurrentURI( string memory _uri ) public {
        require( _msgSender() == owner );
        currentURI = _uri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function burn(uint256 _id) public {
        require( _msgSender() == ownerOf(_id));
        _burn(_id);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
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
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function target_mint(address _userAddress) public {
        require( _msgSender() == owner );
        _safeMint( _userAddress , nftid);
        nftid++;
    }


    function target_multimint(address[] memory _userAddresses) public {
        require( _msgSender() == owner );
        for(uint i=0;i<_userAddresses.length;i++){
            _safeMint( _userAddresses[i] , nftid);
            nftid++;
        }
    }

    constructor() ERC721("membershipNFT" , "WATARI" ) {
        owner = _msgSender();        
        }
    
}