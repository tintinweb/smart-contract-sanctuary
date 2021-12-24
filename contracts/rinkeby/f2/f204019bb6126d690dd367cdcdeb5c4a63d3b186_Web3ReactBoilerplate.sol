// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Web3ReactBoilerplate is ERC721Enumerable, Ownable {
  uint256 public mintPrice = 0.2777 ether;
  uint256 public presalePrice = 0.1777 ether;

  string _baseTokenURI;

  bool public isActive = false;
  bool public isAllowListActive = false;

  uint256 public maximumMintSupply = 7777;
  uint256 public maximumAllowedTokensPerPurchase = 3;
  uint256 public maximumAllowedTokensPerWallet = 7;
  uint256 public allowListMaxMint = 3;

  mapping(address => bool) private _allowList;
  mapping(address => uint256) private _allowListClaimed;

  event AssetMinted(uint256 tokenId, address sender);
  event SaleActivation(bool isActive);

  constructor(string memory baseURI) ERC721("Web3 React Boilerplate", "WRB") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= maximumMintSupply, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  function setMaximumAllowedTokens(uint256 _count) public onlyAuthorized {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyAuthorized {
    maximumAllowedTokensPerWallet = _count;
  }

  function setActive(bool val) public onlyAuthorized {
    isActive = val;
    emit SaleActivation(val);
  }

  function setIsAllowListActive(bool _isAllowListActive) external onlyAuthorized {
    isAllowListActive = _isAllowListActive;
  }

  function setAllowListMaxMint(uint256 maxMint) external  onlyAuthorized {
    allowListMaxMint = maxMint;
  }

  function addToAllowList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _allowList[addresses[i]] = true;
      _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
    }
  }

  function checkIfOnAllowList(address addr) external view returns (bool) {
    return _allowList[addr];
  }

  function removeFromAllowList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _allowList[addresses[i]] = false;
    }
  }

  function setPrice(uint256 _price) public onlyAuthorized {
    mintPrice = _price;
  }

  function setPresalePrice(uint256 _price) public onlyAuthorized {
    presalePrice = _price;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
  }

  function getContractOwner() public view returns (address) {
    return owner();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }


  function mint(address _to, uint256 _count) public payable saleIsOpen {
    if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
    }

    if(_to != owner()) {
      require(balanceOf(_to) + _count <= maximumAllowedTokensPerWallet, "Max holding cap reached.");
    }

    require(totalSupply() + _count <= maximumMintSupply, "Total supply exceeded.");
    require(totalSupply() <= maximumMintSupply, "Total supply spent.");
    require(
      _count <= maximumAllowedTokensPerPurchase,
      "Exceeds maximum allowed tokens"
    );
    require(msg.value >= mintPrice * _count, "Insuffient ETH amount sent.");

    for (uint256 i = 0; i < _count; i++) {
      emit AssetMinted(totalSupply(), _to);
      _safeMint(_to, totalSupply());
    }
  }

  function preSaleMint(uint256 _count) public payable saleIsOpen {
    require(isAllowListActive, 'Allow List is not active');
    require(_allowList[msg.sender], 'You are not on the Allow List');
    require(totalSupply() < maximumMintSupply, 'All tokens have been minted');
    require(_count <= allowListMaxMint, 'Cannot purchase this many tokens');
    require(_allowListClaimed[msg.sender] + _count <= allowListMaxMint, 'Purchase exceeds max allowed');
    require(msg.value >= presalePrice * _count, 'Insuffient ETH amount sent.');

    for (uint256 i = 0; i < _count; i++) {
      _allowListClaimed[msg.sender] += 1;
      emit AssetMinted(totalSupply(), msg.sender);
      _safeMint(msg.sender, totalSupply());
    }
  }

}