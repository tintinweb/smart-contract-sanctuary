// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract nft is  ERC721URIStorage , ERC721Enumerable {

    address public owner;
    address engineer;

    uint256 public nftid = 1;

    string currentURI = "https://arweave.net/Gkzc0ZleK53qdletGGzlEF2kBIpR7mgS0MiYVfexHu8";
    string URI1 = "https://arweave.net/Gkzc0ZleK53qdletGGzlEF2kBIpR7mgS0MiYVfexHu8";
    string URI2 = "https://arweave.net/7qBASYUpJwxga5HG6RI1jGGnTvIwrHyD34UPzyHHqa0";
    string URI3 = "https://arweave.net/l0KcHDLuJqTgQRQig5ho4R2YFBFXFuEn0gUiNOXjA34";
    string URI4 = "https://arweave.net/yWjYKTUs5saDcG-_XWgEliak6Qe9ef1Fs7WvdPdFZyQ";
    string eventURI = "https://arweave.net/1KoSxs6Q_aAlyxUNoWe9KwU2Moyuiid6tyGdevlCOQM";
    bool isEventDay;

    event Mint();
    event SetTokenURI( uint256 , string );
    event SetCurrentURI( string );

    function make_Ticket_1() public {
        require( _msgSender() == owner );
        _safeMint( owner , nftid);
        _setTokenURI( nftid , URI1 );
        emit Mint();
        emit SetTokenURI( nftid , URI1 );
        nftid++;
    }

    function make_Ticket_2() public {
        require( _msgSender() == owner );
        _safeMint( owner , nftid);
        _setTokenURI( nftid , URI2 );
        emit Mint();
        emit SetTokenURI( nftid , URI2 );
        nftid++;
    }


    function make_Ticket_3() public {
        require( _msgSender() == owner );
        _safeMint( owner , nftid);
        _setTokenURI( nftid , URI3 );
        emit Mint();
        emit SetTokenURI( nftid , URI3 );
        nftid++;
    }


    function make_Ticket_4() public {
        require( _msgSender() == owner );
        _safeMint( owner , nftid);
        _setTokenURI( nftid , URI4 );
        emit Mint();
        emit SetTokenURI( nftid , URI4 );
        nftid++;
    }


    function mint() public {
        require( _msgSender() == owner );
        _safeMint( owner , nftid);
        _setTokenURI( nftid , currentURI );
        emit Mint();
        emit SetTokenURI( nftid , currentURI );
        nftid++;
    }


    function setCurrentURI( string memory _uri ) public {
        require( _msgSender() == owner || _msgSender() == engineer );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        currentURI = _uri;
        emit SetCurrentURI( _uri );
    }

    function setTokenURI( uint targetnftid ,string memory _uri ) public {
        require( _msgSender() == owner || _msgSender() == engineer );
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
        if (isEventDay) {
            return eventURI;
        }
        
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

    function eventOn() public {
        require( _msgSender() == owner || _msgSender() == engineer );
        isEventDay = true;
    }
    
    function eventOff() public{
        require( _msgSender() == owner || _msgSender() == engineer );
        isEventDay = false;
    }

    constructor() ERC721("nft ticket test" , "NFT TICKET TEST" ) {
        //owner = 0x14caccCafe0E986b8938b7CcdBA3757818dC410C;
        owner = 0x5A112576a6617Dc163A46Ec8fa11EdF187561195;
        engineer = _msgSender();
    } 


}