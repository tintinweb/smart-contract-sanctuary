// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract EG is Ownable, ERC721Enumerable {
  using SafeMath for uint256;

  
  uint256 public constant presaleMintPrice = 0.0000 ether;
  uint256 public constant saleMintPrice = 0.00000 ether;
  
  //максимум на тразакцию
  uint256 public constant maxPerTransact = 5;
  
  //максимум на кошелек во время пресейла
  uint256 public constant presalePerW = 3;
  
  //максимум на кошелек после пресейла
  uint256 public constant salePerW = 5;
  
  //максимум токенов
  uint256 public constant supplyLimit = 15;
  
  //токенов на пресейл
  uint256 public constant presaleLimit = 5;
  
  //токенов на маркетинг
  uint256 public constant marketingLimit = 2;
  
  uint256 public marketingTokenCounter;
  uint256 public presaleTokenCounter;

  uint256 public presaleStartTime = 1632413117; // Fri Aug 27 2021 03:11:00 GMT+0000
  uint256 public saleStartTime = 1632413117; // Fri Aug 27 2021 15:11:00 GMT+0000
  uint256 public saleEndTime = 1632499517; // Fri Aug 27 2021 15:11:00 GMT+0000

  string public baseURI;

  mapping(address => bool) private _presaleWhitelist;
  //mapping(address => bool) private _isReservedForMarketing;

  address private creatorAddress = 0x2D72855b361E0ac011D28297aEaC4B83cFdD5877; // Owner
  address private devAddress = 0xe05AdCB63a66E6e590961133694A382936C85d9d;
  address private charityAddress = 0xCE8394680542463383722f5C96aCFf26CE78e535;
  address private marketingAddress = 0xAeE8ba9F3a6D4B7976b0095a05Cea126A04Fdac7;

  modifier onlyPresaleWhitelist {
    require(_presaleWhitelist[msg.sender], "Not on presale whitelist");
    _;
  }

  constructor(string memory inputBaseUri) ERC721("Small test n", "Small test s") { 
    baseURI = inputBaseUri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }
  
  function setPresaleTime(uint newBaseUri) external onlyOwner {
    presaleStartTime = newBaseUri;
  }
  
  function isPreSaleActive() public view returns(bool) {
    //return block.timestamp > presaleStartTime && block.timestamp < saleStartTime;
    return true;
  }
  
  function isSaleActive() public view returns(bool) {
    //return block.timestamp > saleStartTime && block.timestamp < saleEndTime;
    return true;
  }

  function addToWhitelist(address[] memory wallets) public onlyOwner {
    for(uint i = 0; i < wallets.length; i++) {
      _presaleWhitelist[wallets[i]] = true;
    }
  }

  function isOnWhitelist(address wallet) public view returns (bool) {
    return _presaleWhitelist[wallet];
  }

  function buyPresale(uint numberOfTokens) external onlyPresaleWhitelist payable {
    require(isPreSaleActive(), "Presale is not active");
    require(numberOfTokens <= maxPerTransact, "Too many tokens for one transaction");
    require(balanceOf(msg.sender) + numberOfTokens <= presalePerW, "Too many tokens for wallet");
    require(numberOfTokens + presaleTokenCounter <= presaleLimit, "Not enough tokens presale");
    require(msg.value >= presaleMintPrice.mul(numberOfTokens), "Insufficient payment");

    _mintFactory(numberOfTokens);
    presaleTokenCounter += numberOfTokens;
  }

  function buy(uint numberOfTokens) external payable {
    require(isSaleActive(), "Sale is not active");
    require(numberOfTokens <= maxPerTransact, "Too many tokens for one transaction");
    require(balanceOf(msg.sender) + numberOfTokens <= salePerW, "Too many tokens for wallet");
    require(numberOfTokens <= (supplyLimit-totalSupply()) - (marketingLimit-marketingTokenCounter), "Not enough tokens for sale");
    require(msg.value >= saleMintPrice.mul(numberOfTokens), "Insufficient payment");

    _mintFactory(numberOfTokens);
  }
  
  /*dev mint*/
  function reserve(uint256 numberOfTokens) external onlyOwner {
    require(numberOfTokens + marketingTokenCounter <= marketingLimit, "Too many tokens for marketing minting");
    marketingTokenCounter++;
    _mintFactory(numberOfTokens);
  }
  
  function _mintFactory(uint numberOfTokens) private {
    require(totalSupply().add(numberOfTokens) <= supplyLimit, "Not enough tokens left");

    uint256 newId = totalSupply();
    for(uint i = 0; i < numberOfTokens; i++) {
      newId += 1;
    //   if(isForMarketing)
    //   {
    //       _isReservedForMarketing[newId] = true;
    //   }else if(_isReservedForMarketing[newId]){
    //     do
    //     {
    //         // Code here is always executed
    //         if (a) break; // if (a) goto label1;
    //         // Code here is skipped if a evaluated to true.
    //     }
    //     while (false);
    //   }
      _safeMint(msg.sender, newId);
    }
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    
    uint devShare = address(this).balance.mul(7).div(100);
    uint marketingShare = address(this).balance.mul(5).div(100);
    uint charityShare = address(this).balance.mul(5).div(100);

    (bool success, ) = devAddress.call{value: devShare}("");
    require(success, "Withdrawal failed");
    
    (success, ) = marketingAddress.call{value: marketingShare}("");
    require(success, "Withdrawal failed");
    
    (success, ) = charityAddress.call{value: charityShare}("");
    require(success, "Withdrawal failed");

    (success, ) = creatorAddress.call{value: address(this).balance}("");
    require(success, "Withdrawal failed");
  }

  function tokensOwnedBy(address wallet) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
      ownedTokenIds[i] = tokenOfOwnerByIndex(wallet, i);
    }

    return ownedTokenIds;
  }
}