// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract NFT is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;

    constructor(address _wallet1, address _wallet2) ERC721("NFT", "RNFT") {
        beneficiaryWallet1 = _wallet1;
        beneficiaryWallet2 = _wallet2;
    }

    struct Reveal{
        address owner;
        uint256 buyTime;
    }
    
    mapping (uint256 => Reveal) private tokenDetails;

    uint256 private preSaleStartDate;

    uint256 private preSaleEndDate;

    uint256 private publicSaleDate;

    uint256 private publicSaleEndDate;

    uint256 private presalePrice = 120000000000000000; 

    uint256 private publicSalePrice = 300000000000000000;

    uint256 private revealTime = 48 hours;

    address private beneficiaryWallet1;  

    address private beneficiaryWallet2;

    mapping(address => bool) private whitelistUsers;

    event PresaleMint(address user, uint256 count, uint256 amount, uint256 time);

    event PublicsaleMint(address user, uint256 count, uint256 amount, uint256 time);

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function preSaleMint(address _to ,uint256 _mintAmount) public payable whenNotPaused{
        require(preSaleStartDate <= block.timestamp && preSaleEndDate > block.timestamp, "Presale ended or not started yet");
        require(isWhitelisted(_to), "User is not whitelisted");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "No amount to mint");              
        require(msg.value >= presalePrice * _mintAmount, "Wrong price!");        
        for (uint256 i = 1; i <= _mintAmount; i++) {
            Reveal memory revealInfo;
            revealInfo = Reveal({
                owner :  _to,
                buyTime : block.timestamp
            }); 
            tokenDetails[supply + i] = revealInfo;
            _safeMint(_to, supply + i);
        }
        uint256 amount = (address(this).balance).mul(80).div(100);
        payable(beneficiaryWallet1).transfer(amount.mul(70).div(100));
        payable(beneficiaryWallet2).transfer(amount.mul(30).div(100));
        emit PresaleMint(_to, _mintAmount, msg.value, block.timestamp);
    }

    function publicSaleMint(address _to ,uint256 _mintAmount) public payable whenNotPaused{
        require(publicSaleDate <= block.timestamp && publicSaleEndDate > block.timestamp, "Presale ended or not started yet");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "No amount to mint");           
        require(msg.value >= publicSalePrice * _mintAmount, "Wrong price!");       
        for (uint256 i = 1; i <= _mintAmount; i++) {
            Reveal memory revealInfo;
            revealInfo = Reveal({
                owner :  _to,
                buyTime : block.timestamp
            }); 
            tokenDetails[supply + i] = revealInfo;
            _safeMint(_to, supply + i);
        }
        payable(owner()).transfer(address(this).balance);
        emit PublicsaleMint(_to, _mintAmount, msg.value, block.timestamp);
    }
   
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }  

    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    function setPublicSalePrice(uint256 _newPrice) public onlyOwner {
        publicSalePrice = _newPrice;
    }
  
    function setPresaleStartTime(uint256 time) public onlyOwner {
        preSaleStartDate = time;
    }

    function setPresaleEndTime(uint256 time) public onlyOwner {
        preSaleEndDate = time;
    }

    function setPublicSaleTime(uint256 time) public onlyOwner {
        publicSaleDate = time;
    }

    function setPublicSaleEndTime(uint256 time) public onlyOwner {
        publicSaleEndDate = time;
    }

    function whitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistUsers[addresses[i]] = true;
        }
    }

    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);        
    }

    function removeWhitelistedUsers(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistUsers[addresses[i]] = false;
        }
    }

    function getPreSalePrice() public view returns (uint256) {
        return presalePrice;
    }

    function getPublicSalePrice() public view returns (uint256) {
        return publicSalePrice;
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
       return whitelistUsers[_user];
    }

    function tokenURI(uint256 tokenId) public view  override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(block.timestamp < tokenDetails[tokenId].buyTime + revealTime){
            return "null";
        }else {
            return super.tokenURI(tokenId);
        }
    }

    function getTokenDetails(uint256 tokenId) public view returns (address, uint256){
        Reveal memory revealInf = tokenDetails[tokenId];  
        return (revealInf.owner, revealInf.buyTime);
    }
}