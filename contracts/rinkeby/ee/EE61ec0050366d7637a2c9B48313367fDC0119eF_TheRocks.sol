// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ITheRocks.sol";
import "./ITheRocksMetadata.sol";

contract TheRocks is ERC721Enumerable, Ownable, ITheRocks, ITheRocksMetadata {
  using Strings for uint256;

  uint256 public constant GIFT_COUNT = 0;
  uint256 public constant PUBLIC_COUNT = 1000;
  uint256 public constant MAX_COUNT = GIFT_COUNT + PUBLIC_COUNT;
  uint256 public constant PURCHASE_LIMIT = 1000;
  uint256 public constant PRICE = 0.11 ether;

  bool public isActive = false;
  bool public isAllowListActive = false;
  string public proof;

  uint256 public allowListMaxMint = 10;

  /// @dev We will use these to be able to calculate remaining correctly.
  uint256 public totalGiftSupply;
  uint256 public totalPublicSupply;

  mapping(address => bool) private _allowList;
  mapping(address => uint256) private _allowListClaimed;

  address[] collaborators;
  mapping(address => uint256) private collaboratorPercentages;
  mapping(address => uint256) private collaboratorShares;
  bool private collaboratorsSet = false;

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  function addToAllowList(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");

      _allowList[addresses[i]] = true;
      /**
      * @dev We don't want to reset _allowListClaimed count
      * if we try to add someone more than once.
      */
      _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
    }
  }

  function onAllowList(address addr) external view override returns (bool) {
    return _allowList[addr];
  }

  function removeFromAllowList(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");

      /// @dev We don't want to reset possible _allowListClaimed numbers.
      _allowList[addresses[i]] = false;
    }
  }

  /**
  * @dev We want to be able to distinguish tokens bought during isAllowListActive
  * and tokens bought outside of isAllowListActive
  */
  function allowListClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address not on Allow List');

    return _allowListClaimed[owner];
  }

  function purchase(uint256 numberOfTokens) external override payable {
    require(isActive, 'Contract is not active');
    require(!isAllowListActive, 'Only allowing from Allow List');
    require(totalSupply() < MAX_COUNT, 'All tokens have been minted');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
    /**
    * @dev The last person to purchase might pay too much.
    * This way however they can't get sniped.
    * If this happens, we'll refund the Eth for the unavailable tokens.
    */
    require(totalPublicSupply < PUBLIC_COUNT, 'Purchase would exceed PUBLIC_COUNT');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      /**
      * @dev Since they can get here while exceeding the MAX_COUNT,
      * we have to make sure to not mint any additional tokens.
      */
      if (totalPublicSupply < PUBLIC_COUNT) {
        /**
        * @dev Public token numbering starts after GIFT_COUNT.
        * And we don't want our tokens to start at 0 but at 1.
        */
        uint256 tokenId = GIFT_COUNT + totalPublicSupply + 1;

        totalPublicSupply += 1;
        _safeMint(msg.sender, tokenId);
      }
    }

    splitFunds();
  }

  function splitFunds() internal virtual {
    for (uint i = 0; i < collaborators.length; i++) {
      uint256 collaboratorShare = (msg.value *
        collaboratorPercentages[collaborators[i]]) / 100;

      collaboratorShares[collaborators[i]] += collaboratorShare;
    }
  }

  function purchaseAllowList(uint256 numberOfTokens) external override payable {
    require(isActive, 'Contract is not active');
    require(isAllowListActive, 'Allow List is not active');
    require(_allowList[msg.sender], 'You are not on the Allow List');
    require(totalSupply() < MAX_COUNT, 'All tokens have been minted');
    require(numberOfTokens <= allowListMaxMint, 'Cannot purchase this many tokens');
    require(totalPublicSupply + numberOfTokens <= PUBLIC_COUNT, 'Purchase would exceed PUBLIC_COUNT');
    require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      /**
      * @dev Public token numbering starts after GIFT_COUNT.
      * We don't want our tokens to start at 0 but at 1.
      */
      uint256 tokenId = GIFT_COUNT + totalPublicSupply + 1;

      totalPublicSupply += 1;
      _allowListClaimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }
  }

  function gift(address[] calldata to) external override onlyOwner {
    require(totalSupply() < MAX_COUNT, 'All tokens have been minted');
    require(totalGiftSupply + to.length <= GIFT_COUNT, 'Not enough tokens left to gift');

    for(uint256 i = 0; i < to.length; i++) {
      /// @dev We don't want our tokens to start at 0 but at 1.
      uint256 tokenId = totalGiftSupply + 1;

      totalGiftSupply += 1;
      _safeMint(to[i], tokenId);
    }
  }

  function setIsActive(bool _isActive) external override onlyOwner {
    isActive = _isActive;
  }

  function setIsAllowListActive(bool _isAllowListActive) external override onlyOwner {
    isAllowListActive = _isAllowListActive;
  }

  function setAllowListMaxMint(uint256 maxMint) external override onlyOwner {
    allowListMaxMint = maxMint;
  }

  function setProof(string calldata proofString) external override onlyOwner {
    proof = proofString;
  }

  function withdraw() external override onlyOwner {}

  modifier onlyCollaborator() {
      require(
          collaboratorPercentages[_msgSender()] > 0,
          "Only collaborators can call this function"
      );
      _;
  }

  function getCollaboratorShares(address collaboratorAddress) public view returns(uint256) {
      return collaboratorShares[collaboratorAddress];
  }

  function getCollaboratorPercentage(address collaboratorAddress) public view returns(uint256) {
      return collaboratorPercentages[collaboratorAddress];
  }

  function withdrawCollaborator() public onlyCollaborator() {
      uint256 withdrawAmount = collaboratorShares[_msgSender()];

      collaboratorShares[_msgSender()] = 0;

      payable(_msgSender()).transfer(withdrawAmount);
  }

  function setCollaborators(
      address[] memory _collaborators,
      uint256[] memory _collaboratorPercentages
  ) public onlyOwner {
    require(!collaboratorsSet);

    collaborators = _collaborators;

    uint256 sharesPercentageTotal = 0;

    for (uint i = 0; i < collaborators.length; i++) {
        sharesPercentageTotal += _collaboratorPercentages[i];
        collaboratorPercentages[collaborators[i]] =
            _collaboratorPercentages[i];
    }

    require(sharesPercentageTotal == 100);

    collaboratorsSet = true;
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

  function contractURI() public view override returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    /// @dev Convert string to bytes so we can check if it's empty or not.
    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }
}