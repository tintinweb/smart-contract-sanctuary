// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract AngryApesUnited is ERC721Enumerable, Ownable {
  using ECDSA for bytes32;

  uint256 public mintPrice = 0.065 ether;

  uint256 private reserveAtATime = 45;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 225;

  address private signerAddress = 0x2187D614e851758e7218c43ACFe2690693A15dE4;

  string _baseTokenURI;

  bool public isActive = false;
  bool public isAllowListActive = false;

  uint256 public maximumMintSupply = 8888;
  uint256 public maximumAllowedTokensPerPurchase = 20;
  uint256 public allowListMaxMint = 5;

  mapping(address => uint256) private _allowListClaimed;

  event AssetMinted(uint256 tokenId, address sender);
  event SaleActivation(bool isActive);

  constructor(string memory baseURI) ERC721("Angry Apes United", "AAU") {
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

  function setActive(bool val) public onlyAuthorized {
    isActive = val;
    emit SaleActivation(val);
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyAuthorized {
    maximumMintSupply = maxMintSupply;
  }

  function setIsAllowListActive(bool _isAllowListActive) external onlyAuthorized {
    isAllowListActive = _isAllowListActive;
  }

  function setAllowListMaxMint(uint256 maxMint) external  onlyAuthorized {
    allowListMaxMint = maxMint;
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

  function setSignerAddress(address addr) external onlyAuthorized {
    signerAddress = addr;
  }

  function getMaximumAllowedTokens() public view onlyAuthorized returns (uint256) {
    return maximumAllowedTokensPerPurchase;
  }

  function getPrice() external view returns (uint256) {
    return mintPrice;
  }

  function getReserveAtATime() external view returns (uint256) {
    return reserveAtATime;
  }

  function getTotalSupply() external view returns (uint256) {
    return totalSupply();
  }

  function getContractOwner() public view returns (address) {
    return owner();
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

  function mint(address _to, uint256 _count) public payable saleIsOpen {
    if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
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

  function batchReserveToMultipleAddresses(uint256 _count, address[] calldata addresses) external onlyAuthorized {
      uint256 supply = totalSupply();

      require(supply + _count <= maximumMintSupply, "Total supply exceeded.");
      require(supply <= maximumMintSupply, "Total supply spent.");

      for (uint256 i = 0; i < addresses.length; i++) {
        require(addresses[i] != address(0), "Can't add a null address");
        
        for(uint256 j = 0; j < _count; j++) {
           emit AssetMinted(totalSupply(), addresses[i]);
          _safeMint(addresses[i], totalSupply());
        }
      }
  }

  function isValidAccessMessage(bytes memory _signature) internal view returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sender));
    return signerAddress == hash.toEthSignedMessageHash().recover(_signature);
  }

  function preSaleMint(bytes memory _signature, uint256 _count) public payable saleIsOpen {
    require(isAllowListActive, 'Allow List is not active');
    require(isValidAccessMessage(_signature), "Invalid access message");
    require(totalSupply() < maximumMintSupply, 'All tokens have been minted');
    require(_count <= allowListMaxMint, 'Cannot purchase this many tokens');
    require(_allowListClaimed[msg.sender] + _count <= allowListMaxMint, 'Purchase exceeds max allowed');
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
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}