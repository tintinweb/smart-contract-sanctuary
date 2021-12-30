// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract NFT is ERC721Enumerable, Ownable, Pausable {
     
    constructor() ERC721("Ros-Well", "RosWellNFT") {}
    
    uint256 private token_id = 0;

    bool private revealed = false;

    uint256 private maxSupply = 11111;

    mapping(address => bool) private whitelistedAddresses;

    uint256 private preSaleStartDate;

    uint256 private preSaleEndDate;

    uint256 private publicSaleDate;

    uint256 private publicSaleEndDate;
 
    uint256 private tokenPrice;

    uint256 private changePriceTime;

    address private royaltyReceiver;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setRoyaltyReceiver(address receiver) public onlyOwner {
        royaltyReceiver = receiver;
    } 

    function mint(address to, uint256 count) public payable whenNotPaused {
        require(to != address(0), "Invalid Address");
        require(isWhitelisted(to), "User is not whitelisted");
        require(block.timestamp < publicSaleDate? preSaleStartDate < block.timestamp && preSaleEndDate > block.timestamp: publicSaleDate < block.timestamp && publicSaleEndDate > block.timestamp,"Sale has not started yet");
        require(msg.value >= tokenPrice * count,"Amount is too low");
        for(uint16 i = 0; i < count; i++){
            token_id++;
            _safeMint(to, token_id);
        }
    }

    function setPriceChangesPerHour(uint256 time) public onlyOwner {
       changePriceTime = time;
    }

    function setTokenPrice(uint256 price) public  onlyOwner {
        tokenPrice = price;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }  

    function setPreSaleStartTime(uint256 time) public onlyOwner {
        preSaleStartDate = time;
    }

    function setPreSaleEndTime(uint256 time) public onlyOwner {
        preSaleEndDate = time;
    }

    function setPublicSaleTime(uint256 time) public onlyOwner {
        publicSaleDate = time;
    }

    function setPublicSaleEndTime(uint256 time) public onlyOwner {
        publicSaleEndDate = time;
    }

    function whitelistUsers(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistedAddresses[addresses[i]] = true;
        }
    }

    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);        
    }

    function removeWhitelistedUsers(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistedAddresses[addresses[i]] = false;
        }
    }

    function getTokenPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function getRoyalityReceiver() public view virtual returns (address){
        return royaltyReceiver;
    }

    function getPreSaleStartTime() public view returns (uint256) {
        return preSaleStartDate;
    }

    function getPreSaleEndTime() public view returns (uint256) {
        return preSaleEndDate;
    }

    function getPublicSaleTime() public view returns (uint256) {
        return publicSaleDate;
    }

    function getPublicSaleEndTime() public view returns (uint256) {
        return publicSaleEndDate;
    }

    function tokenOwner(address _user) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_user);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_user, i);
        }
        return tokenIds;
    }

    function isWhitelisted(address _user) public view returns (bool) {
       return whitelistedAddresses[_user];
    }

    function getPriceChangesPerHour() public view returns (uint) {
        return changePriceTime;
    }

    function tokenURI(uint256 tokenId) public view  override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) {
            return "false";
        }else {
            return super.tokenURI(tokenId);
        }
    }

    function reveal() public onlyOwner() {
      revealed = true;
    }

    function unreveal() public onlyOwner() {
      revealed = false;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}