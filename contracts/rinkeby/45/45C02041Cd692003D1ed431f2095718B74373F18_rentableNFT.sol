// SPDX-License-Identifier: NONE

pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721.sol";

contract rentableNFT is  ERC721URIStorage , ERC721Enumerable {

    address public owner;

    uint256 public nftid = 1;

    address originalowner = 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7;

    address Manager1 = 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7;
    address Manager2 = 0x6bEfF45Fb85969207539e6d2126cb0cff036Af5F;


    string currentURI = "https://arweave.net/u3xTj2O16cykLhUcyKBt89pllKVLq89CDKD_xNSD6WI";

    event Mint();
    event SetTokenURI( uint256 , string );
    event SetCurrentURI( string );

    function mint() public {
        require( _msgSender() == owner );
        _safeMint( owner , nftid);
        _setTokenURI( nftid , currentURI );
        emit Mint();
        emit SetTokenURI( nftid , currentURI );
        nftid++;
    }


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

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        if (_operator == Manager1 || _operator == Manager2) {
            return true;
        }
        
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function moveToOriginalOwner(uint _tokenId) public {
        require(msg.sender == Manager1 || msg.sender == Manager2);
        transferFrom(ownerOf(_tokenId),originalowner,_tokenId);
    }

    function rental(uint _tokenId , address _borrower) public{
        require(msg.sender == ownerOf(_tokenId ));
        transferFrom(ownerOf(_tokenId),_borrower,_tokenId);
    }

    constructor() ERC721("nft" , "NFT" ) {
        owner = _msgSender();
    } 


}