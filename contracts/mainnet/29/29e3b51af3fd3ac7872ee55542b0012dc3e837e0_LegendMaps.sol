// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/*
################################################################       
___       _______   _______    _______  _____  ___   ________   
|"  |     /"     "| /" _   "|  /"     "|(\"   \|"  \ |"      "\  
||  |    (: ______)(: ( \___) (: ______)|.\\   \    |(.  ___  :) 
|:  |     \/    |   \/ \       \/    |  |: \.   \\  ||: \   ) || 
 \  |___  // ___)_  //  \ ___  // ___)_ |.  \    \. |(| (___\ || 
( \_|:  \(:      "|(:   _(  _|(:      "||    \    \ ||:       :) 
 \_______)\_______) \_______)  \_______) \___|\____\)(________/                                                           
 ___      ___       __         _______    ________               
|"  \    /"  |     /""\       |   __ "\  /"       )              
 \   \  //   |    /    \      (. |__) :)(:   \___/               
 /\\  \/.    |   /' /\  \     |:  ____/  \___  \                 
|: \.        |  //  __'  \    (|  /       __/  \\                
|.  \    /:  | /   /  \\  \  /|__/ \     /" \   :)               
|___|\__/|___|(___/    \___)(_______)   (_______/         
       
################################################################    
*/
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract LegendMaps is ERC721, ERC721Enumerable, Ownable {
  using Strings for uint256;
  address payable public _owner;
  string private _baseURIextended;
  string public _baseExtension = "";
  bool public saleActive = false;
  bool public whitelistActive = false;
  uint8 public activeWhiteListTier = 0;
  mapping(uint256 => bool) public sold;
  mapping(uint256 => uint256) public price;
  mapping(address => uint8) private _whitelist;
  mapping(address => uint8) private _whitelistTiers;
  mapping(uint256 => string) private _tokenURIs;
  uint256 public constant MAX_SUPPLY = 5757;
  uint256 public constant MAX_PUBLIC_MINT = 5;
  uint256 public constant PRICE_PER_TOKEN = 0.042 ether;

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

  function setAllWhiteLists (address[] calldata addresses, uint256 epicStart, uint256 rareStart, uint256 uncommonStart, uint8 numLegendaryMints, uint8 numEpicMints, uint8 numRareMints, uint8 numUncommonMints) external onlyOwner {
    for(uint256 i = 0; i < epicStart; i++){
      _whitelist[addresses[i]] = numLegendaryMints;
      _whitelistTiers[addresses[i]] = 0;
    }
    for(uint256 j = epicStart; j < rareStart; j++){
      _whitelist[addresses[j]] = numEpicMints;
      _whitelistTiers[addresses[j]] = 1;
    }
    for(uint256 k = rareStart; k < uncommonStart; k++){
      _whitelist[addresses[k]] = numRareMints;
      _whitelistTiers[addresses[k]] = 2;
    }
    for(uint256 l = uncommonStart; l < addresses.length; l++){
      _whitelist[addresses[l]] = numUncommonMints;
      _whitelistTiers[addresses[l]] = 3;
    }
  }

  function getMintsRemaining(address addr) external view returns(uint8){
    if(_whitelistTiers[addr] <= activeWhiteListTier){
      return _whitelist[addr];
    } else {
      return 0;
    }
  }

  function setSaleState(bool newState) public onlyOwner {
    if(newState == false){
      whitelistActive = false;
    }
    saleActive = newState;
  }

  function setActiveWhiteList(uint8 newGroup) public onlyOwner{
    activeWhiteListTier = newGroup;
  }

  function getWhitelistGroup(address addr) external view returns(uint8){
    return _whitelistTiers[addr];
  }

  function mintWhiteList(uint8 numTokens) external payable {
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

  function setBaseURI(string memory baseURI_) external onlyOwner {
      _baseURIextended = baseURI_;
  }

  function setBaseExtension(string memory baseExtension) external onlyOwner {
    _baseExtension = baseExtension;
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

  function contractURI() public pure returns (string memory) {
    return "https://legendmaps.io/legendmaps-metadata.json";
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
    _setTokenURI(tokenId, _tokenURI);
  }

  function reserve(uint256 count) public onlyOwner {
    uint supply = totalSupply();
    for(uint i = 0; i < count; i++){
      _safeMint(msg.sender, supply + i);
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

      string memory _tokenURI = _tokenURIs[tokenId];
      string memory base = _baseURI();

      if (bytes(base).length == 0) {
          return _tokenURI;
      }
      if (bytes(_tokenURI).length > 0) {
          return string(abi.encodePacked(base, _tokenURI));
      }

      string memory baseURI = _baseURI();
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), _baseExtension)) : "";
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
      require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
      _tokenURIs[tokenId] = _tokenURI;
  }

  function _burn(uint256 tokenId) internal virtual override {
      super._burn(tokenId);

      if (bytes(_tokenURIs[tokenId]).length != 0) {
          delete _tokenURIs[tokenId];
      }
  }
}