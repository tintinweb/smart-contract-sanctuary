// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

interface metaaniGEN {
    function ownerOf(uint256 tokenID) external view returns(address);
}


contract TitleFirstPenguin is  ERC721URIStorage {

    address public owner;

    string ipfs_base;

    bool mint_started = false;


    mapping(uint => bool) public minted;


    address metawallet = 0x60a89BB4C35A62DE53e4E1852E2d4037a008aC5b;
    address metaanigenaddress = 0xa467AB9447AfA5Db0c70325348D810d2058DDe18;
    mapping(address  => uint) priceCandidates;


    function checkMetaaniGEN(uint256 _nftid) public view returns(address){
        return metaaniGEN(metaanigenaddress).ownerOf(_nftid);
    }


    function claim(uint256 _nftid) public {
        require( mint_started );
        require( _nftid <= 10000);
        require( metaaniGEN(metaanigenaddress).ownerOf(_nftid) == msg.sender);
        _safeMint( msg.sender , _nftid);
        minted[_nftid] = true;
    }


    function mintStart() public {
        require(msg.sender == owner );
        mint_started = true;
    }


    function mintStop() public {
        require(msg.sender == metawallet);
        mint_started = false;
    }

    function withdraw() public {
        require(msg.sender == metawallet);
        uint balance = address(this).balance;
        payable(metawallet).transfer(balance);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }



    function burn(uint256 _id) public {
        require( msg.sender == ownerOf(_id));
        _burn(_id);
    }

    function _baseURI() internal view override returns (string memory) {
        return ipfs_base;
    }

    function setbaseURI(string memory _ipfs_base) public {
        require(msg.sender == metawallet );
        ipfs_base = _ipfs_base;
    }



    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getTitle(uint256 tokenId) public pure returns (string memory) {
        tokenId;
        return "First Penguin";
    }

    constructor() ERC721("FirstPenguin" , "TITLE" ) {
        owner = msg.sender;

        //title_first_penguin
        ipfs_base = "ipfs://QmTmrvQJMBtaEVzpnuzNimgdSQnrSi9tRcvYCdsi6oJR7U/";

    } 

}