// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './MerkleProof.sol';

contract FyatLux is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public totalPublicSupply;
  uint256 public totalGiftSupply;
  uint256 public PURCHASE_LIMIT = 2;
  uint256 public PRICE = 0.125 ether;
  uint256 public constant FL_GIFT = 50;
  uint256 public constant FL_PUBLIC = 8030;
  uint256 public constant MAX_SUPPLY = FL_PUBLIC + FL_GIFT;

  bool public _isAllowListRequired = true;
  bool public isActive = false;

  mapping(address => uint256) private _allowListClaimed;

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';
  bytes32 private _allowedRoot;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  function getRoot() external onlyOwner view returns (bytes32) {
    return _allowedRoot;
  }

  function setRoot(bytes32 newRoot) external onlyOwner {
    _allowedRoot = newRoot;
  }

  function isAllowListRequired() external onlyOwner view returns (bool){
    return _isAllowListRequired;
  }

  function setAllowListRequired(bool isRequired) external onlyOwner {
    _isAllowListRequired = isRequired;
  }

  function setPurchaseLimit(uint256 limit) external onlyOwner {
    require(limit > 0, 'Limit must be larger than 0');
    PURCHASE_LIMIT = limit;
  }

  function setTokenPrice(uint256 newPrice) external onlyOwner {
    PRICE = newPrice;
  }

  function purchase(uint256 numberOfTokens, bytes32[] calldata proof) external payable {
    require(numberOfTokens > 0, 'Minted tokens must be larger than 0');
    require(isActive, 'Contract is not active');
    require(totalSupply()  < MAX_SUPPLY, 'All tokens have been minted');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
    require(_allowListClaimed[msg.sender] + numberOfTokens <= PURCHASE_LIMIT, 'Would surpass number of allocations.');

    if(_isAllowListRequired){
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(proof, _allowedRoot, leaf), 'Invalid proof.');
    }

    require(totalPublicSupply < FL_PUBLIC, 'Purchase would exceed Public Supply.');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      if (totalPublicSupply < FL_PUBLIC) {
        uint256 tId = FL_GIFT + totalPublicSupply + 1;
        totalPublicSupply += 1;
        _allowListClaimed[msg.sender] += 1;
        _safeMint(msg.sender, tId);
      }
    }

  }

  function gift(address[] calldata to) external onlyOwner {
    require(totalSupply() < MAX_SUPPLY, 'All tokens have been minted');
    require(totalGiftSupply + to.length <= FL_GIFT, 'Not enough tokens left to gift');

    for(uint256 i = 0; i < to.length; i++) {

      uint256 tokenId = totalGiftSupply + 1;

      totalGiftSupply += 1;
      _safeMint(to[i], tokenId);
    }
  }

  function setIsActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setContractURI(string calldata URI) external onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external onlyOwner {
    _tokenBaseURI = URI;
  }

  function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
    _tokenRevealedBaseURI = revealedBaseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function isWhitelisted(bytes32[] calldata proof) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    return MerkleProof.verify(proof, _allowedRoot, leaf);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
    string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }
}