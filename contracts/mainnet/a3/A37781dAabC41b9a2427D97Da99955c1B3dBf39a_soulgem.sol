// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract soulgem is  ERC721URIStorage , ERC721Enumerable {

    address public owner;
    address engineer;

    uint256 public soulgeneratetime;

    //need to set metadata here
    string soul1 = "soul1";
    string soul2 = "soul2";
    string soul3 = "soul3";
    string soul4 = "soul4";
    string soul5 = "soul5";
    
    event Mint();

    function setSoul1( string memory _uri ) public {
        require( _msgSender() == owner || _msgSender() == engineer);
        //ipfs://Qm....... or https://arweave.net/......  etc.
        soul1 = _uri;
    }

    function setSoul2( string memory _uri ) public {
        require( _msgSender() == owner || _msgSender() == engineer);
        //ipfs://Qm....... or https://arweave.net/......  etc.
        soul2 = _uri;
    }

    function setSoul3( string memory _uri ) public {
        require( _msgSender() == owner || _msgSender() == engineer);
        //ipfs://Qm....... or https://arweave.net/......  etc.
        soul3 = _uri;
    }

    function setSoul4( string memory _uri ) public {
        require( _msgSender() == owner || _msgSender() == engineer);
        //ipfs://Qm....... or https://arweave.net/......  etc.
        soul4 = _uri;
    }

    function setSoul5( string memory _uri ) public {
        require( _msgSender() == owner || _msgSender() == engineer);
        //ipfs://Qm....... or https://arweave.net/......  etc.
        soul5 = _uri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        soulgeneratetime = block.timestamp;
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
        if (secondsSinceSoulGenerate() > 5270400 ){
            return soul5;
        } else if (secondsSinceSoulGenerate() > 3024000  ) {
            return soul4;            
        } else if (secondsSinceSoulGenerate() > 1296000 ) {
            return soul3;
        } else if (secondsSinceSoulGenerate() > 432000 ) {
            return soul2;
        } else {
            return soul1;
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


    function secondsSinceSoulGenerate() public view returns (uint){
        return block.timestamp - soulgeneratetime;
    }

    constructor() ERC721("-Soul gem-" , "GEM") {
        owner = 0x7bA019379E2A54689922d8A3519B32994dbe667e;
        engineer = _msgSender();
        soulgeneratetime = block.timestamp;
        _safeMint( owner , 1);
        emit Mint();
    } 
}