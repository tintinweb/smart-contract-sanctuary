// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./SafeMath.sol";

contract TokenContract is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    
    using SafeMath for uint256;

    constructor() ERC721("RoachFest NFT", "ROACHFEST") {}

    uint256 private token_id = 0;
    
    uint256 private tokenprice = 70000000000000000; //0.07 ETH
    
    uint256[] private tokenIds;
    
    string private baseURI;
    
    address private team1 = 0x1a00eC621B514F82916Fd411494Cc0DADc8C6A56;
    
    address private team2 = 0xf9971Bed975Cc7679870a0C2dcA057939aC9D283;
     
    address private team3 = 0x1a00eC621B514F82916Fd411494Cc0DADc8C6A56;

    mapping(address => uint256) private mintPerAddress;
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(string memory metadata) public onlyOwner {
        token_id++;
        tokenIds.push(token_id);
        _safeMint(msg.sender, token_id);
        _setTokenURI(token_id, metadata);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)internal whenNotPaused override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId)public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function getToken(uint256 tokenId) public view virtual returns (address, string memory) {
        address owner = ownerOf(tokenId);
        string memory ipfs =  tokenURI(tokenId);
        return (owner, ipfs);
    }
    
    function buyToken() public payable{
        require(!paused(), "Sale is paused");
        require(mintPerAddress[msg.sender] <= 20, "You reached your limit");
        require(msg.value >= tokenprice,"NFT price is 0.07 ETH");
        uint256 randNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        randNumber = randNumber % (tokenIds.length);
        _transfer(ownerOf(tokenIds[randNumber]), msg.sender, tokenIds[randNumber]);
        mintPerAddress[msg.sender] += 1;
        tokenIds[randNumber] = tokenIds[tokenIds.length - 1];
        delete tokenIds[tokenIds.length - 1];
        tokenIds.pop();
    }
    
    function withdraw() public onlyOwner{
        payable(team1).transfer((address(this).balance).mul(45).div(100));
        payable(team2).transfer((address(this).balance).mul(45).div(100));
        payable(team3).transfer((address(this).balance).mul(10).div(100));
    }
    
    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }
    
    function setBaseTokenURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function getTokenPrice() public view returns(uint256){
        return tokenprice;
    }
}