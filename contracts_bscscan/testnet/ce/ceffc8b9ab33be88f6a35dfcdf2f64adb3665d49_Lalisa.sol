// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "./Lalisa_dep.sol";
contract Lalisa is ERC721Enumerable, Ownable {
  using Strings for uint256;
  uint256 public cost = 20000000000000000;
  uint256 public discountPercent = 30;
  uint256 public changeCost = 5000000000000000;
  uint256 public descriptionCost = 20000000000000000;
  uint256 public maxWalletLength = 26;
  uint256 public maxDescriptionLength = 500;
  uint256 public maxWalletAddressLength = 300;
  uint256 public totalNameChanges = 0;
  uint256 public totalAddressChanges = 0;
  uint256 public taxPercent = 5;
  bool public paused = false;
  mapping(string => string) public name2address;
  mapping(string => string) public address2name;
  mapping(uint256 => string) public token2address;
  mapping(string => uint256) public address2token;
  mapping(uint256 => string) public token2name;
  mapping(string => uint256) public name2token;
  mapping(uint256 => uint256) public tokenCreated;
  mapping(uint256 => uint256) public tokenEdited;
  mapping(uint256 => bool) public tokenApproved;
  mapping(uint256 => string) public tokenDescription;
  mapping(uint256 => uint256) public tokenSalePrice;
  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {
  }
  // public
  function mint(string memory walletAddress, string memory walletName, address destinationAddress) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(!isWalletNameExists(walletName), "Wallet name exists.");
    require(!isWalletAddressExists(walletAddress), "Wallet address exists.");
    sanitizationNameCheck(walletName);
    sanitizationAddressCheck(walletAddress);
    if (msg.sender != owner()) {
        require(msg.value >= cost);
    }

    name2address[walletName] = walletAddress;
    address2name[walletAddress] = walletName;
    token2address[supply + 1] = walletAddress;
    address2token[walletAddress] = supply + 1;
    token2name[supply + 1] = walletName;
    name2token[walletName] = supply + 1;
    tokenCreated[supply+1] = block.timestamp* 1000;
     _safeMint(destinationAddress, supply + 1);
  }

  function bulkMint(string[] memory walletAddress, string[] memory walletName, address[] memory destinationAddress, uint256 quantity ) public payable {
    require(destinationAddress.length  == quantity && walletName.length == quantity && walletAddress.length == quantity && quantity >= 2);
    if (msg.sender != owner()) {
        require(msg.value >= ((cost * quantity) - (cost * quantity * discountPercent / 100)));
    }
    for (uint256 i; i < quantity; i++) {
        mint(walletAddress[i], walletName[i], destinationAddress[i]);
    }
  }
  function setTokenSalePrice(uint256 tokenId, uint256 salePrice) public payable {
    address ownerOfToken = ownerOf(tokenId);
    require(msg.sender == ownerOfToken);
    tokenSalePrice[tokenId] = salePrice;
  }
  function buyToken(uint256 tokenId) public payable {
    require(msg.sender.balance > msg.value && msg.value >= tokenSalePrice[tokenId] && tokenSalePrice[tokenId] > 0 );
    address ownerOfToken = ownerOf(tokenId);
    uint256 tax = (msg.value - 1) * taxPercent /100;
    require(payable(ownerOfToken).send(msg.value-tax));
    require(payable(owner()).send(tax));
    _transfer(ownerOfToken, msg.sender, tokenId);
    tokenSalePrice[tokenId] = 0;
  }
  function sanitizationNameCheck(string memory walletName) public view {
    uint256 length = StringUtils.length(walletName);
    require(length <= maxWalletLength && length >= 3);
  }
  function sanitizationAddressCheck(string memory walletAddress) public view {
    uint256 length = StringUtils.length(walletAddress);
    require(length <= maxWalletAddressLength && length >= 10);
  }
  
  function changeWalletName(uint256 tokenId, string memory newWalletName) public payable{
    address ownerOfToken = ownerOf(tokenId);
    require(msg.sender == ownerOfToken || msg.sender == owner());
    require(!isWalletNameExists(newWalletName));
    sanitizationNameCheck(newWalletName);
    if (msg.sender != owner()) 
        require(msg.value >= changeCost);
        
    string memory walletAddress = token2address[tokenId];
    name2address[token2name[tokenId]] = "";
    name2address[newWalletName] = walletAddress;
    
    name2token[token2name[tokenId]] = 0;
    name2token[newWalletName] = tokenId;
    
    address2name[walletAddress] = newWalletName;
    token2name[tokenId] = newWalletName;
    tokenEdited[tokenId] = block.timestamp * 1000;
    totalNameChanges = totalNameChanges + 1;
  }
  
  function changeWalletAddress(uint256 tokenId, string memory newWalletAddress) public payable{
    address ownerOfToken = ownerOf(tokenId);
    require(msg.sender == ownerOfToken || msg.sender == owner());
    require(!isWalletAddressExists(newWalletAddress));
    sanitizationAddressCheck(newWalletAddress);
    if (msg.sender != owner()) 
        require(msg.value >= changeCost);
    
    string memory walletName = token2name[tokenId];
    
    address2name[token2address[tokenId]] = "";
    address2name[newWalletAddress] = walletName; 
    
    address2token[token2address[tokenId]] = 0;
    address2token[newWalletAddress] = tokenId;
    
    name2address[walletName] = newWalletAddress;
    token2address[tokenId] = newWalletAddress;
    tokenEdited[tokenId] = block.timestamp * 1000;
    totalAddressChanges = totalAddressChanges + 1;
  }
  
  function isWalletNameExists(string memory walletName) public view returns (bool) {
    return name2token[walletName] != 0;
  }
  
  function isWalletAddressExists(string memory walletAddress) public view returns (bool) {
    return address2token[walletAddress] != 0;
  }
  
  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
  
  function setDiscountPercent(uint256 _discountPercent) public onlyOwner {
    require(_discountPercent<= 100);
    discountPercent = _discountPercent;
  }
    //only owner
  function setChangeCost(uint256 _newCost) public onlyOwner {
    changeCost = _newCost;
  }
  function setVerifyCost(uint256 _newCost) public onlyOwner {
    descriptionCost = _newCost;
  }
  function setTaxPercent(uint256 _newCost) public onlyOwner {
    taxPercent = _newCost;
  }

  function setWalletLength(uint256 _strLength) public onlyOwner {
    maxWalletLength = _strLength;
  }
  function setWalletAddressLength(uint256 _strLength) public onlyOwner {
    maxWalletAddressLength = _strLength;
  }
  
  function setTokenDescription(uint256 tokenId, string memory description) public payable{
    require(tokenApproved[tokenId]);
    uint256 length = StringUtils.length(description);
    require(length <= maxDescriptionLength && length >= 1);
    if (msg.sender != owner()) 
      require(msg.value >= descriptionCost);
      
    tokenDescription[tokenId] = description;
  }
  function setTokenApproval(uint256 tokenId, bool verify) public onlyOwner{
    tokenApproved[tokenId] = verify;
  }
  function getMaxWalletLength() public view returns (uint256) {
    return maxWalletLength;
  }
  
  function pause(bool _state) public onlyOwner { paused = _state; }

  function getTokensOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}