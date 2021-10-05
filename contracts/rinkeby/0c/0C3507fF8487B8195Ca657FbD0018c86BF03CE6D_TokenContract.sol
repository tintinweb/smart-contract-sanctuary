// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";


contract TokenContract is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {

    constructor() ERC721("RoachFest", "ROACH") {}

    uint256 private token_id = 0;
    
    uint256 private tokenprice = 0; 
    
    uint16[] private tokenIds;
    
    string private baseURI;
    
    uint256 private tokenSold = 0;
    
    mapping(address => uint256[]) private tokenOwner;
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function setNFTRange(uint16 start, uint16 end) public onlyOwner(){
        for(uint16 i = start; i <= end; i++){
            tokenIds.push(i);
        }
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
    
    function mint(uint256 amount) public payable{
        require(!paused(), "Sale is paused");
        require(amount <= 20, "Roaches per transaction is 20");
        require(msg.value >= tokenprice * amount,"NFT price is 0.04 ETH");
        for(uint256 i = 0; i < amount; i++){
            tokenSold++;
            uint256 randNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
            randNumber = randNumber % (tokenIds.length);
            _safeMint(msg.sender, tokenIds[randNumber]);
            _setTokenURI(tokenIds[randNumber], string(abi.encodePacked(baseURI, Strings.toString(tokenIds[randNumber]))));
            tokenOwner[msg.sender].push(tokenIds[randNumber]);
            tokenIds[randNumber] = tokenIds[tokenIds.length - 1];
            delete tokenIds[tokenIds.length - 1];
            tokenIds.pop();
        }
    }
    
    function mint(address account, uint256 count) public payable onlyOwner{
        require(!paused(), "Sale is paused");
        require(count <= 20, "Roaches per transaction is 20");
        require(msg.value >= 0 || msg.value <= 1000, "Admin pay 0 ETH to 1000 ETH");
        for(uint256 i = 0; i < count; i++){
            tokenSold++;
            uint256 randNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
            randNumber = randNumber % (tokenIds.length);
            _safeMint(account, tokenIds[randNumber]);
            _setTokenURI(tokenIds[randNumber], string(abi.encodePacked(baseURI, Strings.toString(tokenIds[randNumber]))));
            tokenOwner[account].push(tokenIds[randNumber]);
            tokenIds[randNumber] = tokenIds[tokenIds.length - 1];
            delete tokenIds[tokenIds.length - 1];
            tokenIds.pop();
        }
    }
    
    function withdraw(address account, uint256 amount) public onlyOwner{
        require(address(this).balance > amount, "Not Enough Balance");
        payable(account).transfer(amount);
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
    
    function setTokenPrice(uint256 price) public onlyOwner {
        tokenprice = price;
    }
    
    function getTokenIds() public view returns(uint16[] memory){
        return tokenIds;
    }
    
    function ownerOfTokens(address account) public view returns(uint256[] memory){
        return tokenOwner[account];
    }
    
    function getTotalSoldTokens() public view returns(uint256){
        return tokenSold;
    }
    
}