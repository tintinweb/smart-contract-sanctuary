// SPDX-License-Identifier: MIT
/// @title GENERATIVE BURGER CLUB

/// ____________________________________________________________________________________________________
/// ____________________________________________________________________________________________________
/// ____________________________________________________________________________________________________
/// ____________________________________________________________________________________________________
/// _________________________________WWWWNNXXXKKK000000000KKKKKXXNNWWWWW________________________________
/// ___________________________WWWNXK00OOkkkxxxxxxxxxxxxxxxxxxxxkkkOO00KXNWWW___________________________
/// _______________________WWNXK0OkkxxxxxxxxxxxxxxxxxxxxxxxkkkkxxxxxxxxxxkO0KXNWW_______________________
/// _____________________WXKOkkxxxkkkkkxxxxxxxxxxxxxxxxxxk0KXXKkxxxxxxxxxxxxxkk0KXWW____________________
/// __________________WNKOkkxxxxxOKXXK0kxxxxxxxxxxxxxxxxxOKXXK0kxxxxxxxxxkkkkxxxkkOKNW__________________
/// ________________WX0kkxxxxxxxxk0XXXKOkxxxxxxxxxxxxxxxxkkkkkxxxxxxxxxxk0KXKOkxxxxxk0XW________________
/// ______________WN0kxxxxxxxxxxxxkkOOOkxxxxxxxxxkkkxxxxxxxxxxxxxxxxxxxxk0XXXKOkxxxxxxk0NW______________
/// _____________WXOxxxxxxkxxxxxxxxxxxxxxxxxxxxxOKKKOkxxxxxxxxxxxxxxxxxxxkOOOOkxxxxxxxxkOXW_____________
/// ____________WKOxxxxkOKK0kxxxxxxxxxxxxxxxxxxOKXXX0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkKW____________
/// ___________WXkxxxxk0XNXKOxxxxxxxxxxxxxxxxxxO0KK0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkXW___________
/// ___________NOxxxxxk0KK0OkxxxxxxxxxxxxxxxxxxxkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkOOOkxxxxxON___________
/// __________WXkxxxxxxkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk0KXX0kxxxxxkXW__________
/// __________WKkxxxxxxxxxxxxxxxxxxxxxkkkkkxxxxxxxxxxxxxxxxxxxxxkOOkxxxxxxxxxxxOKXXKOkxxxxxkKW__________
/// __________WKkxxxxxxxxxxxxxxxxxxxxk0KXK0OxxxxxxxxxxxxxxxxxxxkKXXK0kxxxxxxxxxkkOOkxxxxxxxkXW__________
/// ___________XOxxxxxxxxxxxxxxxxxxxxkOKXXX0kxxxxxxxxxxxxxxxxxxk0XXXKOxxxxxxxxxxxxxxxxxxxxxOX___________
/// ___________WXOxxxxxxxxxxxxxxxxxxxxxkkOOkxxxxxxxxxxxxxxxxxxxxkkOOOkxxxxxxxxxxxxxxxxxxxxOXW___________
/// ____________NOddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddON____________
/// ____________NkcclodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdolcckN____________
/// ____________WOc;;:clloddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddolcc:;;ckW____________
/// ___________WNOl:;;;;;:::cclllloooooooddddddddddddddddddddddddddoooooolllllcc::;;;;;;:lON____________
/// _________WNKkdolc:::;;;;;;;;;;;;;;::::::::::::::::::::::::::::::::;;;;;;;;;;;;;;;::clodOKNW_________
/// _________WKxdoooolllcc::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::ccclooooodkKW_________
/// _________WX0kxdoooooooollllccc::::::::;;;;;;;;;;;;;;;;;;;;;;;;;::::::cccccllloooooooodxO0NW_________
/// _________WNK0OOkxdxxxxxxxxdoooooollllllllllllllllccclcclllllllllllloooooddxxxxxxxxxxkO00XNW_________
/// __________WXkoodxkOO000000OxdoooooooooooooooooooooooooooooooooooooooooodkO000000OOkdollkXW__________
/// ___________Wk,..',:codkOO00OOxdoooodxxkkkxdoooooooooooooddxkkkxxddodddkO000Okxol:;'...,xNW__________
/// ___________W0:........';:codxkkkkkOO000000OOxdoooooooodxOO000000OOkkkkkxol:;,.........:0W___________
/// ___________N0l,.............';:lodkOO00000000OkxxxxxkkO00000000Okxdlc;,'.............'l0NW__________
/// __________WXkdl;.................',;:ldxOO00000000000000000Oxol:,'..................;lxkXW__________
/// __________WKkxxdc,.....................',:coxkO000000Okxol:,'.....................,cdxxkKW__________
/// __________WKkxxxxdl:,.......................',;coddoc:,'.......................,:ldxxxxkKW__________
/// __________WXOxxxxxxxdoc:,'................................................';:codxxxxxxxOXW__________
/// ___________WKkxxxxxxxxxxddolc:;,,''..............................'',,;:clodxxxxxxxxxxxx0N___________
/// ___________WN0kxxxxxxxxxxxxxxxxddooolllccc::::::::::::::::::cclloodddxxxxxxxxxxxxxxxxk0NW___________
/// _____________WKOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOKNW____________
/// ______________WNKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkOKNW______________
/// ________________WWXKOkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkO0XNW________________
/// ___________________WWNXK0OOkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkOO0KXNWW___________________
/// ________________________WWWNNXXK000OOOOOOkkkkkkkkkkkkkkkkkkOOOOOO00KKXXXNNWWWW______________________
/// _________________________________WWWWWWWWWNNNNNNNNNNNNNNNNNWWWWWWWW_________________________________
/// ____________________________________________________________________________________________________
/// ____________________________________________________________________________________________________
/// ____________________________________________________________________________________________________

pragma solidity ^0.8.6;

import { PaymentSplitter, ERC721, Ownable, ProxyRegistry } from './OpenZeppelinDependencies.sol';

contract GBC is ERC721, PaymentSplitter, Ownable {

  uint public constant MAX_BURGERER_SUPPLY = 1_234;

  uint public constant MAX_MINT_AMOUNT = 5;

  uint public constant MAX_OWNER_MINTS = 14;

  uint public constant SPECIAL_START_ID = 10_000;

  uint public lastSaleId = 40 + MAX_OWNER_MINTS;

  uint public totalSupplySpecials;

  uint public totalSupplyBurgerers;

  uint public priceMint = 0.2 ether;

  uint public priceBuy = 0.2 ether;

  uint public allowListRatio = 5;

  uint public mintPhase;

  uint public constant decimals = 0;

  string private _contractURI = "ipfs://QmZRvHgwSiPYp69h7n4soVWzteG3k9fxia9rxz56seuZG1";

  string public baseURI = "https://api.genburger.club/";

  address public immutable proxyRegistryAddress;

  mapping (address => uint256) public allowListAmounts;

  constructor(
    address _proxyRegistryAddress,
    address[] memory addresses,
    uint256[] memory amounts
  ) ERC721("Generative Burger Club", "BURGERER")
    PaymentSplitter(addresses, amounts) {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /// @notice Override isApprovedForAll to allow user's OpenSea proxy accounts to enable gas-less listings.
  function isApprovedForAll(address owner, address operator) public view override(ERC721) returns (bool) {
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

      /// @notice allow OpenSea proxy contract for easy trading.
      if (proxyRegistry.proxies(owner) == operator) {
          return true;
      }
      return super.isApprovedForAll(owner, operator);
  }

  function ownerOf(uint256 tokenId) public view override returns (address) {
    return _isValidVirtualToken(tokenId, true) ? owner() : super.ownerOf(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (_isValidVirtualToken(tokenId, true)){
      string memory baseURI_ = _baseURI();
      return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, _toString(tokenId))) : "";
    } else {
      return super.tokenURI(tokenId);
    }
  }

  function totalSupply() public view returns (uint){
    return totalSupplyBurgerers + totalSupplySpecials;
  }

  function transferFrom(
      address from,
      address to,
      uint256 tokenId
  ) public override {
      if (!_exists(tokenId)){
        /// @dev already checked existence above; save gas!
        require(_isValidVirtualToken(tokenId, false), 'GBC: nonexistent token');
        address _owner = owner();
        require(_owner == msg.sender || isApprovedForAll(_owner, msg.sender), 'GBC: transfer caller is not owner nor approved');
        _transferVirtual(_owner, to, tokenId);
        if (to != _owner && tokenId <= lastSaleId) allowListAmounts[to] += allowListRatio;
      } else {
        super.transferFrom(from, to, tokenId);
      }
  }

  /// @notice Check if token has been virtually minted
  function _isValidVirtualToken(uint256 tokenId, bool checkExists) internal view returns (bool){
    if (checkExists) {
      if (_exists(tokenId)) return false;
    }
    if (tokenId <= lastSaleId && tokenId <= totalSupplyBurgerers) return true;
    if (tokenId > SPECIAL_START_ID && tokenId <= SPECIAL_START_ID+totalSupplySpecials) return true;
    return false;
  }

  /// @notice Reserved for owner to mint
  function ownerSaleMint(uint amount, bool virtual_) public {
    address _owner = owner();

    require(msg.sender == _owner, 'GBC: caller is not the owner');

    uint currentBurgererSupply = totalSupplyBurgerers;

    require(currentBurgererSupply+amount <= lastSaleId, 'GBC: No more sale mints');

    totalSupplyBurgerers = currentBurgererSupply + amount;

    for (uint i=1; i<=amount; i++){
      if (virtual_) {
        _mintVirtual(_owner, currentBurgererSupply+i);
      } else {
        _mint(_owner, currentBurgererSupply+i);
      }
    }
  }

  /// @notice Reserved for owner to mint
  function ownerMintSpecials(address[] calldata addresses) public onlyOwner {
    uint amount = addresses.length;

    uint currentSpecialSupply = totalSupplySpecials;

    totalSupplySpecials = currentSpecialSupply + amount;

    for (uint i=0; i<amount; i++){
      /// @notice perform all offsets so Special Token starts at 10,000 onwards
      uint tokenId = SPECIAL_START_ID+currentSpecialSupply+1+i;
      _mint(addresses[i], tokenId);
    }
  }

  /// @notice Buy specific ids if available
  function buy(uint[] calldata tokenIds) public payable {
    uint amount = tokenIds.length;

    /// @notice This will overflow if amount > MAX_MINT_AMOUNT
    MAX_MINT_AMOUNT - amount;

    require(amount * priceBuy <= msg.value, "GBC: Not enough value sent");

    address _owner = owner();

    allowListAmounts[msg.sender] += amount * allowListRatio;

    for(uint i=0; i<amount; i++){
      uint tokenId = tokenIds[i];
      require(tokenId > MAX_OWNER_MINTS, 'GBC: not for sale');
      require(tokenId <= lastSaleId, 'GBC: not for sale');
      require(!_exists(tokenId), 'GBC: not for sale');
      _transferVirtual(_owner, msg.sender, tokenId);
    }

  }

  /// @notice Public mints
  function mint(uint amount) public payable {
    require(mintPhase > 0, 'GBC: Not open');

    if (mintPhase == 1){
      /// @notice Allowlist users can mint based on their previous history
      /// @dev Will overflow and revert if amount is above maximum
      allowListAmounts[msg.sender] -= amount;
    }

    if (mintPhase > 1) {
      /// @notice Public can mint a maximum quantity at a time.
      /// @dev Will overflow and revert if amount is above maximum
      MAX_MINT_AMOUNT - amount;
    }

    uint currentBurgererSupply = totalSupplyBurgerers;

    /// @notice Cannot exceed maximum supply minus the special supply
    require(currentBurgererSupply+amount <= MAX_BURGERER_SUPPLY, "GBC: Not enough mints remaining");

    /// @notice public must send in correct funds
    require(amount * priceMint <= msg.value, "GBC: Not enough value sent");

    totalSupplyBurgerers = currentBurgererSupply + amount;

    for (uint i=1; i<=amount; i++){
      ///@notice  perform all offsets so special mint does not interfere with sequential regular ids
      uint256 tokenId = currentBurgererSupply+i;
      _mint(msg.sender, tokenId);
    }

  }

  function setMintPhase(uint newPhase) external onlyOwner {
    require(totalSupplyBurgerers >= lastSaleId, 'GBC: sale mints remaining');
    mintPhase = newPhase;
  }

  function increaseSaleMints(uint amount) public onlyOwner{
    require(mintPhase == 0, 'GBC: Doors already open');
    uint currentSaleId = lastSaleId;
    require(currentSaleId+amount <= MAX_BURGERER_SUPPLY, 'GBC: Max supply reached');
    lastSaleId = currentSaleId + amount;
  }

  /// @notice priced in finney where 1 finny = 0.001 ether
  function setPriceMint(uint newPriceInFinney) public onlyOwner {
    priceMint = newPriceInFinney * 1e15;
  }
  /// @notice priced in finney where 1 finny = 0.001 ether
  function setPriceBuy(uint newPriceInFinney) public onlyOwner {
    priceBuy = newPriceInFinney * 1e15;
  }

  function setAllowListRatio(uint newAllowListRatio) public onlyOwner {
    allowListRatio = newAllowListRatio;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function _baseURI() internal override view returns (string memory){
    return baseURI;
  }

  function setContractURI(string memory newContractURI) external onlyOwner {
    _contractURI = newContractURI;
  }

  function contractURI() external view returns (string memory){
    return _contractURI;
  }

  /// @notice From @openzeppelin/contracts/utils/[email protected]
  /// @dev Converts a `uint256` to its ASCII `string` decimal representation.
  function _toString(uint256 value) internal pure returns (string memory) {
      if (value == 0) {
          return "0";
      }
      uint256 temp = value;
      uint256 digits;
      while (temp != 0) {
          digits++;
          temp /= 10;
      }
      bytes memory buffer = new bytes(digits);
      while (value != 0) {
          digits -= 1;
          buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
          value /= 10;
      }
      return string(buffer);
  }

  /// @notice PaymentSplitter introduces a `receive()` function that we do not need.
  receive() external payable override {
    revert();
  }
}