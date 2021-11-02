// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract Mizudako is  ERC721URIStorage  {

    address public owner;
    uint nftid = 1;
    bool airdropon = true;
    
    string currentURI = "https://arweave.net/USaj3ThuHB8Z0h-0dWIY3mJUy4cO1lX23vLsXOs1ols";
    address airdropperaddress = 0x08Be0EB2345a54454FDD19ED5E01391914f721A1;

    event Mint();
    event SetTokenURI( uint256 , string );

    function setTokenURI( uint targetnftid ,string memory _uri ) public {
        require( _msgSender() == owner );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        _setTokenURI( targetnftid , _uri );
        emit SetTokenURI( targetnftid , _uri );
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

    function airdrop(address _userAddress) public {
        require( _msgSender() == airdropperaddress );
        require( airdropon );
        //require( nftid <= 150 );
        _safeMint( _userAddress , nftid);
        emit Mint();
        nftid++;
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == owner) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function airdropOff() public {
        require( _msgSender() == airdropperaddress );
        airdropon = false;        
    }

    function airdropOn() public {
        require( _msgSender() == airdropperaddress );
        airdropon = true;        
    }


    constructor() ERC721("Mizudako" , "Tako" ) {
        owner = airdropperaddress;
        
        }
    
}