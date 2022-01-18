// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ERC721URIStorage.sol";

contract TopNFT is ERC721URIStorage {
    uint public counter;
    address public owner; //合约所有人

    constructor() ERC721("PPNFT","PPN") {
        counter = 0;
        owner = msg.sender;
    }

    //铸币仅限合约所有人调用
    function mint(address to,string memory tokenURI) public returns (uint) {
        require(msg.sender == owner,"sorry,You are not the owner");
        uint tokenId = counter;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        counter++;
        return  tokenId;
    }
    
    // function createNFTs (string memory tokenURI) public returns (uint) {
    //     uint tokenId = counter;

    //     _safeMint(msg.sender, tokenId);
    //     _setTokenURI(tokenId,tokenURI);

    //     counter++;
    //     return  tokenId;
    // }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender,tokenId),"You are not the owner or apprroved!");
        super._burn(tokenId);
    }
}