// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract LegendMaps is ERC721, ERC721Enumerable, Ownable {
  string private _baseURIextended;
  bool public saleActive = false;
  bool public whitelistActive = false;
  uint8 public activeWhiteListTier = 0;
  address payable public _owner;
  mapping(uint256 => bool) public sold;
  mapping(uint256 => uint256) public price;
  mapping(address => uint8) private _whitelist;
  mapping(address => uint8) private _whitelistTiers;
  mapping(uint256 => string) public mintedMaps;
  uint256 public constant MAX_SUPPLY = 9000;
  uint256 public constant MAX_PUBLIC_MINT = 5;
  uint256 public constant PRICE_PER_TOKEN = 0.03 ether;
  
  event Purchase(address owner, uint256 price, uint256 id, string uri);

  constructor() ERC721("Legend Maps", "LMNFT") {
  }

  function setWhiteListActive(bool _whitelististActive) external onlyOwner {
    whitelistActive = _whitelististActive;
  }

  function setWhiteList (address[] calldata addresses, uint8 numMintsAllowed, uint8 whitelistTier) external onlyOwner {
    for(uint256 i = 0; i < addresses.length; i++){
      _whitelist[addresses[i]] = numMintsAllowed;
      _whitelistTiers[addresses[i]] = whitelistTier;
    }
  }

  function getMintsRemaining(address addr) external view returns(uint8){
    if(_whitelistTiers[msg.sender] <= activeWhiteListTier){
      return _whitelist[addr];
    } else {
      return 0;
    }
  }

  function setSaleState(bool newState) public onlyOwner {
    saleActive = newState;
  }

  function setActiveWhiteList(uint8 newGroup) public onlyOwner{
    activeWhiteListTier = newGroup;
  }

  function getWhitelistGroup(address addr) external view returns(uint8){
    return _whitelistTiers[addr];
  }

  function mintAllowList(uint8 numTokens) external payable {
    uint256 ts = totalSupply();
    require(whitelistActive, "White list is not currently active");
    require(_whitelistTiers[msg.sender] <= activeWhiteListTier, "Whitelist group not active yet");
    require(numTokens <= _whitelist[msg.sender], "Exceeds max available for you to purchase");
    require(ts + numTokens <= MAX_SUPPLY, "Not enough supply remaining");
    require(PRICE_PER_TOKEN * numTokens <= msg.value, "Insufficient ether sent");

    _whitelist[msg.sender] -= numTokens;
    for(uint256 i = 0; i < numTokens; i++){
      _safeMint(msg.sender, ts + i);
    }
  }

  function openMint(uint numTokens) public payable {
    uint256 ts = totalSupply();
    require(saleActive, "Sale must be active to mint tokens");
    require(numTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
    require(ts + numTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(PRICE_PER_TOKEN * numTokens <= msg.value, "Ether value sent is not correct");

    for (uint256 i = 0; i < numTokens; i++) {
        _safeMint(msg.sender, ts + i);
    }
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function maxSupply() public pure returns (uint256){
    return MAX_SUPPLY;
  }

  function mintPrice() public pure returns(uint256){
    return PRICE_PER_TOKEN;
  }

  function setMintMapData(uint256[] calldata tokenIds, string[] calldata maps) external onlyOwner {
    for(uint256 i = 0; i < tokenIds.length; i++){
      mintedMaps[tokenIds[i]] = maps[i];
    }
  }

  function setBaseURI(string memory baseURI_) external onlyOwner() {
      _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseURIextended;
  }

  function getTokenURI(uint256 tokenId) public view returns (string memory) {
    return tokenURI(tokenId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
      return super.supportsInterface(interfaceId);
  }

}