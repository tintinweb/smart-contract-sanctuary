// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract PerilousPetz is ERC721Enumerable, Ownable {
  uint256 public mintPrice = 0.1 ether;

  uint256 private reserveAtATime = 46;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 276;

  string _baseTokenURI;

  bool public isActive = false;
  bool public isPresaleActive = false;

  uint256 public MAX_SUPPLY = 7777;
  
  uint256 public maximumAllowedTokensPerPurchase = 10;
  uint256 public maximumAllowedTokensPerWallet = 13;

  uint256 public presaleMaximumAllowedTokensPerPurchase = 3;
  uint256 public presaleMaximumAllowedTokensPerWallet = 3;

  address private GSDAddress1 = 0x1551AD0a4f658D3F66a55F1B6bAbac3300A81351;
  address private GSDAddress2 = 0x8Fa461074FC99D7B874569869b2559Addd00d9AD;
  address private GSDAddress3 = 0x947394C9478530DEbfD2Aa9023153dD939d9b0B8;

  mapping(address => bool) private _allowList;
  mapping(address => uint256) private _allowListClaimed;

  event AssetMinted(uint256 tokenId, address sender);
  event SaleActivation(bool isActive);

  constructor(string memory baseURI) ERC721("Perilous Petz", "PP") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  function setMaximumAllowedTokensPerPurchase(uint256 _count) public onlyAuthorized {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setPresaleMaximumAllowedTokensPerPurchase(uint256 _count) public onlyAuthorized {
    presaleMaximumAllowedTokensPerPurchase = _count;
  }

    function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyAuthorized {
    maximumAllowedTokensPerWallet = _count;
  }


  function setActive(bool val) public onlyAuthorized {
    isActive = val;
    emit SaleActivation(val);
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyAuthorized {
    MAX_SUPPLY = maxMintSupply;
  }

  function setisPresaleActive(bool _isPresaleActive) external onlyAuthorized {
    isPresaleActive = _isPresaleActive;
  }

  function setPresaleAllowedTokensPerWallet(uint256 maxMint) external  onlyAuthorized {
    presaleMaximumAllowedTokensPerWallet = maxMint;
  }

  function addToWhiteList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _allowList[addresses[i]] = true;
      _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
    }
  }

  function checkIfOnWhiteList(address addr) external view returns (bool) {
    return _allowList[addr];
  }

  function removeFromWhiteList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _allowList[addresses[i]] = false;
    }
  }

  function allowListClaimedBy(address owner) external view returns (uint256){
    require(owner != address(0), 'Zero address not on Allow List');
    return _allowListClaimed[owner];
  }

  function setReserveAtATime(uint256 val) public onlyAuthorized {
    reserveAtATime = val;
  }

  function setMaxReserve(uint256 val) public onlyAuthorized {
    maxReserveCount = val;
  }

  function setPrice(uint256 _price) public onlyAuthorized {
    mintPrice = _price;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
  }


  function getReserveAtATime() external view returns (uint256) {
    return reserveAtATime;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function reserveNft() public onlyAuthorized {
    require(reservedCount <= maxReserveCount, "Max Reserves taken already!");
    uint256 supply = totalSupply();
    uint256 i;

    for (i = 0; i < reserveAtATime; i++) {
      emit AssetMinted(supply + i, msg.sender);
      _safeMint(msg.sender, supply + i);
      reservedCount++;
    }
  }

  function reserveToCustomWallet(address _walletAddress, uint256 _count) public onlyAuthorized {
    for (uint256 i = 0; i < _count; i++) {
      emit AssetMinted(totalSupply(), _walletAddress);
      _safeMint(_walletAddress, totalSupply());
    }
  }

  function mint(uint256 _count) public payable saleIsOpen {
    if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
      require(balanceOf(msg.sender) + _count <= maximumAllowedTokensPerWallet, "Max holding cap reached.");
    }


    require(totalSupply() + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(totalSupply() <= MAX_SUPPLY, "Total supply spent.");
    require(
      _count <= maximumAllowedTokensPerPurchase,
      "Exceeds maximum allowed tokens"
    );

    require(msg.value >= mintPrice * _count, "Insuffient ETH amount sent.");

    for (uint256 i = 0; i < _count; i++) {
      emit AssetMinted(totalSupply( ), msg.sender);
      _safeMint(msg.sender, totalSupply());
    }
  }

  function batchReserveToMultipleAddresses(uint256 _count, address[] calldata addresses) external onlyAuthorized {
    uint256 supply = totalSupply();

    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");

    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");

      for(uint256 j = 0; j < _count; j++) {
        emit AssetMinted(totalSupply(), addresses[i]);
        _safeMint(addresses[i], totalSupply());
      }
    }
  }

  function preSaleMint(uint256 _count) public payable saleIsOpen {
    require(isPresaleActive, 'Allow List is not active');
    require(_allowList[msg.sender], 'You are not on the Allow List');
    require(totalSupply() < MAX_SUPPLY, 'All tokens have been minted');
    
    require(_count <= presaleMaximumAllowedTokensPerPurchase, 'Cannot purchase this many tokens');
    
    require(_allowListClaimed[msg.sender] + _count <= presaleMaximumAllowedTokensPerWallet, 'Purchase exceeds max allowed');
    
    require(msg.value >= mintPrice * _count, 'Insuffient ETH amount sent.');

    for (uint256 i = 0; i < _count; i++) {
      _allowListClaimed[msg.sender] += 1;
      emit AssetMinted(totalSupply(), msg.sender);
      _safeMint(msg.sender, totalSupply());
    }
  }

  function walletOfOwner(address _owner) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for(uint i = 0; i < tokenCount; i++){
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function withdraw() external onlyAuthorized {

    payable(GSDAddress1).transfer(address(this).balance * 2500 / 10000);
    payable(GSDAddress2).transfer(address(this).balance * 2500 / 10000);
    payable(GSDAddress3).transfer(address(this).balance * 2500 / 10000);
    
    payable(owner()).transfer(address(this).balance);

  }
}