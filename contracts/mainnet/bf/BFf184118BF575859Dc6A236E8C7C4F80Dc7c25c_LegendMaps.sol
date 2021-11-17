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
import "./MerkleProof.sol";

contract LegendMaps is ERC721, ERC721Enumerable, Ownable {
  using Strings for uint256;
  string private _baseURIextended;
  string public _baseExtension = "";
  bool public saleActive = false;
  bool public whitelistActive = false;
  uint8 public activeWhiteListTier = 0;
  bytes32 public legendaryRoot;
  bytes32 public epicRoot;
  bytes32 public rareRoot;
  bytes32 public uncommonRoot;

  mapping(uint256 => bool) public sold;
  mapping(uint256 => uint256) public price;
  mapping(uint256 => string) private _tokenURIs;
  uint256 public constant MAX_SUPPLY = 5757;
  uint256 public constant MAX_PUBLIC_MINT = 5;
  uint256 public constant PRICE_PER_TOKEN = 0.042 ether;
  uint public constant LEGENDARY_MINTS = 5;
  uint public constant EPIC_MINTS = 4;
  uint public constant RARE_MINTS = 3;
  uint public constant UNCOMMON_MINTS = 2;

  event Purchase(address owner, uint256 price, uint256 id, string uri);

  constructor() ERC721("Legend Maps", "LMNFT") {
  }

  function setWhiteListActive(bool _whitelististActive) external onlyOwner {
    whitelistActive = _whitelististActive;
  }

  function setRoot (uint8 group, bytes32 merkleroot) external onlyOwner {
    if(group == 0){
      legendaryRoot = merkleroot;
    } else if(group == 1){
      epicRoot = merkleroot;
    } else if(group == 2){
      rareRoot = merkleroot;
    } else if(group == 3){
      uncommonRoot = merkleroot;
    }
  }

  function getMintsRemaining(address addr, uint8 group) external view returns(uint){
    uint senderBalance = balanceOf(addr);
    return mintsRemaining(senderBalance, group);
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

  // function getWhitelistGroup(address addr) external view returns(uint8){
  //   return _whitelistTiers[addr];
  // }

  function _leaf(address account, uint256 addressId)
  internal pure returns (bytes32)
  {
      return keccak256(abi.encodePacked(addressId, account));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof, uint8 whitelistGroup)
  internal view returns (bool)
  {
      if(whitelistGroup == 0){
        return MerkleProof.verify(proof, legendaryRoot, leaf);
      }
      if(whitelistGroup == 1){
        return MerkleProof.verify(proof, epicRoot, leaf);
      }
      if(whitelistGroup == 2){
        return MerkleProof.verify(proof, rareRoot, leaf);
      }
      if(whitelistGroup == 3){
        return MerkleProof.verify(proof, uncommonRoot, leaf);
      }
      return false;
  }

  function mintsRemaining(uint senderBalance, uint8 whitelistGroup) internal pure returns (uint){
    if(whitelistGroup == 0){
      return LEGENDARY_MINTS - senderBalance;
    }
    if(whitelistGroup == 1){
      return EPIC_MINTS - senderBalance;
    }
    if(whitelistGroup == 2){
      return RARE_MINTS - senderBalance;
    }
    if(whitelistGroup == 3){
      return UNCOMMON_MINTS - senderBalance;
    }
    return 0;
  }

  function mintWhiteList(uint8 numTokens, uint256 addressId, uint8 whitelistGroup, bytes32[] calldata proof) external payable {
    uint256 ts = totalSupply();
    uint senderBalance = balanceOf(msg.sender);
    uint remainingMints = mintsRemaining(senderBalance, whitelistGroup);
    require(whitelistActive, "White list is not currently active");
    require(whitelistGroup <= activeWhiteListTier, "Whitelist group not active yet");
    require(_verify(_leaf(msg.sender, addressId), proof, whitelistGroup), "Invalid merkle proof");
    require(ts + numTokens <= MAX_SUPPLY, "Not enough supply remaining");
    require(PRICE_PER_TOKEN * numTokens <= msg.value, "Insufficient ether sent");
    require(numTokens <= remainingMints, "Cannot mint more than allotment");
    require(remainingMints > 0, "No mints remaining");
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