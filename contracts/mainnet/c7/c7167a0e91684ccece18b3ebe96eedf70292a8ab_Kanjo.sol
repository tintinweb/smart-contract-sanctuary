pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721.sol";


contract Kanjo is  ERC721URIStorage  {

    address public owner;

    string[5] ipfs_bases;

    uint256 public nftid = 1;

    //for debug
    //uint oneDay = 86;
    uint oneDay = 86400;

    uint onesetofartworks = 5;

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function mint() public {
        require( _msgSender() == owner );
        _safeMint( owner , nftid);
        nftid++;
    }

    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burn(uint256 _id) public {
        require( msg.sender == ownerOf(_id));
        _burn(_id);
    }

    function _baseURI() internal view override returns (string memory) {
        uint facesetnum = (block.timestamp / oneDay) % onesetofartworks;
        return ipfs_bases[facesetnum] ;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function timestamp() public view returns(uint){
        return block.timestamp;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {        
        return super.supportsInterface(interfaceId);
    }

    function set_ipfs_bases(uint _setnumber, string memory _ipfsuri) public {
        require( _msgSender() == owner);
        ipfs_bases[_setnumber] = _ipfsuri;        
    }



    constructor() ERC721("kanjo" , "KANJO" ) {
        owner = msg.sender;
        ipfs_bases[0] = "ipfs://QmdiPiWHd6xQDFKpZWo6iiEPjMc2LzF9xxQuW2XUM4k43M/";
        ipfs_bases[1] = "ipfs://QmW8RbtfoPXyK6qsBtx6RpfobjzggvvKu83GkoLMr2ACMk/";
        ipfs_bases[2] = "ipfs://QmYQ41bFsAze8RdUUWfktmVGGhuvP4VNbM8cpotzQPiLXZ/";
        ipfs_bases[3] = "ipfs://QmYdbjxAi5cQFtizHJjnCDMcMdw8cxGb4BtrJp19pkoxJy/";
        ipfs_bases[4] = "ipfs://QmRRHWJ2qCY2dZ69Wu61DZSgfhhofMWqCqcyvEw47iG8b1/";
        for(uint i = 1; i <= 10; i++ ){
            mint();
        }
    } 
}