// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';

import './INightWorld.sol';
import './INightWorldMetadata.sol';

contract NightWorld is ERC721Enumerable, Ownable, INightWorld, INightWorldMetadata {
  using Strings for uint256;

  uint256 public constant NWT_GIFT = 94;
  uint256 public constant NWT_BENEFIT = 1_800;
  uint256 public constant NWT_PUBLIC = 9_000;
  uint256 public constant NWT_MAX = NWT_GIFT + NWT_BENEFIT + NWT_PUBLIC;
  uint256 public constant PURCHASE_LIMIT = 10;
  uint256 public constant PRICE = 0.088 ether;
  uint256 public constant ALLOW_PRICE = 0.08 ether;
  uint256 public constant TWICE_PRICE = 0.01 ether;
  
  bool public isActive = false;
  bool public isAllowListActive = false;
  bool public isTwiceActive = false;
  bool public isBenefitActive = false;

  uint256 public allowListMaxMint = 3;

  uint256 public totalGiftSupply;
  uint256 public totalPublicSupply;
  uint256 public totalBenefitSupply;

  mapping(address => bool) private _allowList;
  mapping(address => uint256) private _allowListClaimed;

  mapping(uint256 => bool) private _twiceList;      // tokenId -> twice flag
  mapping(uint256 => bool) private _benefitList; // monkey tokenId -> swap flag
  address public monkeyContract;                    // the address of monkey contract.

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';
  string private _tokenTwiceRevealedBaseURI = '';

  // index: 0(1-500), 1(501-1000), 2, 3
  mapping(uint256 => string) private _revealedBaseURIList;
  uint256 public splitFactor = 500;  

  constructor(string memory name, string memory symbol, string memory newBaseURI) ERC721(name, symbol) {
    _tokenBaseURI = newBaseURI;
  }

  function addToAllowList(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");

      _allowList[addresses[i]] = true;

      _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
    }
  }

  function onAllowList(address addr) external view override returns (bool) {
    return _allowList[addr];
  }

  function onTwiceList(uint256 tokenId) external view override returns (bool) {
    return _twiceList[tokenId];
  }

  function onBenefitList(uint256 tokenId) external view override returns (bool) {
    return _benefitList[tokenId];
  }

  function removeFromAllowList(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");

      _allowList[addresses[i]] = false;
    }
  }

  function allowListClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address not on Allow List');

    return _allowListClaimed[owner];
  }

  function purchase(uint256 numberOfTokens) external override payable {
    require(isActive, 'Contract is not active');
    require(!isAllowListActive, 'Only allowing from Allow List');
    require(totalSupply() < NWT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');

    require(totalPublicSupply < NWT_PUBLIC, 'Purchase would exceed NWT_PUBLIC');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      if (totalPublicSupply < NWT_PUBLIC) {
        uint256 tokenId = NWT_GIFT + NWT_BENEFIT + totalPublicSupply + 1;

        totalPublicSupply += 1;
        _safeMint(msg.sender, tokenId);
      }
    }
  }

  function purchaseTwice(uint256 tokenId) external override payable {
    require(isActive, 'Contract is not active');
    require(isTwiceActive, 'Twice opt is not active');
    require(_exists(tokenId), 'Token does not exist');
    require(!_twiceList[tokenId], 'Already execute twice opt');
    require(TWICE_PRICE <= msg.value, 'ETH amount is not sufficient');
    require(ownerOf(tokenId) == msg.sender, "TokenId not belong the msg.sender");

    _twiceList[tokenId] = true;
    emit Twice(msg.sender, tokenId);
  }

  function purchaseAllowList(uint256 numberOfTokens) external override payable {
    require(isActive, 'Contract is not active');
    require(isAllowListActive, 'Allow List is not active');
    require(_allowList[msg.sender], 'You are not on the Allow List');
    require(totalSupply() < NWT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= allowListMaxMint, 'Cannot purchase this many tokens');
    require(totalPublicSupply + numberOfTokens <= NWT_PUBLIC, 'Purchase would exceed NWT_PUBLIC');
    require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'Purchase exceeds max allowed');
    require(ALLOW_PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 tokenId = NWT_GIFT + NWT_BENEFIT + totalPublicSupply + 1;

      totalPublicSupply += 1;
      _allowListClaimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }
  }

  function gift(address[] calldata to) external override onlyOwner {
    require(totalSupply() < NWT_MAX, 'All tokens have been minted');
    require(totalGiftSupply + to.length <= NWT_GIFT, 'Not enough tokens left to gift');

    for(uint256 i = 0; i < to.length; i++) {
      uint256 tokenId = totalGiftSupply + 1;

      totalGiftSupply += 1;
      _safeMint(to[i], tokenId);
    }
  }

  function benefit(uint256 _tokenId) external override {
    require(isActive, 'Contract is not active');
    require(isBenefitActive, 'Benefit is not active');
    require(totalSupply() < NWT_MAX, 'All tokens have been minted');
    require(!_benefitList[_tokenId], 'tokenId already benefit');
    require(totalBenefitSupply + 1 <= NWT_BENEFIT, 'Not left to benefit');
    
    IERC721 token = IERC721(monkeyContract);
    require(token.ownerOf(_tokenId) == msg.sender, "Not owner for tokenId");
    
    // calc tokenId
    _benefitList[_tokenId] = true;
    
    uint256 tokenId = NWT_GIFT + totalBenefitSupply + 1;
    totalBenefitSupply += 1;
    _safeMint(msg.sender, tokenId);
  }

  function mintReserved(uint256 numberOfTokens) external override onlyOwner {
    require(totalSupply() < NWT_MAX, 'All tokens have been minted');
    require(totalPublicSupply + numberOfTokens < NWT_PUBLIC, 'Purchase would exceed NWT_PUBLIC');

    for(uint256 i = 0; i < numberOfTokens; i++) {
      if (totalPublicSupply < NWT_PUBLIC) {
        uint256 tokenId = NWT_GIFT + NWT_BENEFIT + totalPublicSupply + 1;

        totalPublicSupply += 1;
        _safeMint(msg.sender, tokenId);
      }
    }
  }

  function setIsActive(bool _isActive) external override onlyOwner {
    isActive = _isActive;
  }

  function setIsTwiceActive(bool _isTwiceActive) external override onlyOwner {
    isTwiceActive = _isTwiceActive;
  }

  function setIsAllowListActive(bool _isAllowListActive) external override onlyOwner {
    isAllowListActive = _isAllowListActive;
  }

  function setAllowListMaxMint(uint256 maxMint) external override onlyOwner {
    allowListMaxMint = maxMint;
  }

  function setIsBenefitActive(bool _isBenefitActive, address _contractAddr) external override onlyOwner {
    isBenefitActive = _isBenefitActive;
    monkeyContract = _contractAddr;
  }

  function withdraw() external override onlyOwner {
    uint256 balance = address(this).balance;

    payable(msg.sender).transfer(balance);
  }

  function setContractURI(string calldata URI) external override onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external override onlyOwner {
    _tokenBaseURI = URI;
  }

  function setRevealedBaseURI(string calldata revealedBaseURI) external override onlyOwner {
    _tokenRevealedBaseURI = revealedBaseURI;
  }

  function setTwiceRevealedBaseURI(string calldata twiceRevealedBaseURI) external override onlyOwner {
    _tokenTwiceRevealedBaseURI = twiceRevealedBaseURI;
  }

  function setIntervalRevealedBaseURI(uint256 index, string calldata revealedBaseURI) external override onlyOwner {
    _revealedBaseURIList[index] = revealedBaseURI;
  }

  function contractURI() public view override returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    // Calculate the corresponding interval for tokenId
    uint256 _index = 0;
    if(tokenId > 0) {
        _index = (tokenId-1) / splitFactor;
    }

    string memory revealedBaseURI = _revealedBaseURIList[_index];
    //string memory revealedBaseURI = _tokenRevealedBaseURI;
    
    if(bytes(revealedBaseURI).length > 0 && _twiceList[tokenId]){
      string memory twiceRevealedBaseURI = _tokenTwiceRevealedBaseURI;

      return bytes(twiceRevealedBaseURI).length > 0 ?
        string(abi.encodePacked(twiceRevealedBaseURI, tokenId.toString())) :
        string(abi.encodePacked(revealedBaseURI, tokenId.toString()));
    }

    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }
}