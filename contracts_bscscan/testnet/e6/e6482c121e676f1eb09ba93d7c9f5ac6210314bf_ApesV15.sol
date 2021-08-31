// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./SafeMath.sol";
import "./IAGold.sol";
import "./IPancakeRouter.sol";
 
contract ApesV15 is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable {
  using SafeMath for uint256;
  // Enums
  enum Level { Baby, TeenNormal, TeenFarmer, TeenWarrior, AdultNormal, AdultFarmer, AdultWarrior }
  // Structs
  struct Monkey {
    uint256 idx;
    uint256 id;
    Level level;
    uint256 age; // stone, iron, future, etc
    string edition; //normal, christmas, etc
    uint256 bornAt;
    bool onSale;
    uint256 price;
    address owner;
  }
  // Maps
  mapping(uint256 => uint256) public tokenIdToLeftHand;
  mapping(uint256 => uint256) public tokenIdToRightHand;
  mapping(uint256 => uint256) public tokenIdToArmor;
  mapping(uint256 => string) public tokenIdToName;
  // Events
  event NftBought(address _seller, address _buyer, uint256 _price);
 
  // Private Args TODO private
  uint256 public mintPrice;
  uint256 public growPrice;
  uint256 public evolvePrice;
  uint256 public nextGrow;
  address public bnbAddr;
  address public aGoldAddr;
  address public aBananaAddr;
  address public aPapyrusAddr;
  address public fightAddr;
  address public pancakeAddr;
  address public liquidityWallet;
  address public devWallet;
  address public marketingWallet;
  address public deployerWallet;
  address public rewardsWallet;
  // Public Args
  Monkey[] public monkeys;
 
  // Initiatialize
  function initialize() public initializer {
    nextGrow = 0;
    mintPrice = 1000; //aGold
    growPrice = 10; //aBanana
    evolvePrice = 1; //aPapyrus
    deployerWallet = address(msg.sender);
  }
  function setBNBAddr(address a) public {
    require(msg.sender == deployerWallet);
    bnbAddr = a;
  }
  function setAGoldAddr(address a) public {
    require(msg.sender == deployerWallet);
    aGoldAddr = a;
  }
  function setABananaAddr(address a) public {
    require(msg.sender == deployerWallet);
    aBananaAddr = a;
  }
  function setAPapyrusAddr(address a) public {
    require(msg.sender == deployerWallet);
    aPapyrusAddr = a;
  }
  function setFightAddr(address a) public {
    require(msg.sender == deployerWallet);
    fightAddr = a;
  }
  function setPancakeAddr(address a) public {
    require(msg.sender == deployerWallet);
    pancakeAddr = a;
  }
  function setLiquidityWallet(address a) public {
    require(msg.sender == deployerWallet);
    liquidityWallet = a;
  }
  function setDevWallet(address a) public {
    require(msg.sender == deployerWallet);
    devWallet = a;
  }
  function setMarketingWallet(address a) public {
    require(msg.sender == deployerWallet);
    marketingWallet = a;
  }
  function setRewardsWallet(address a) public {
    require(msg.sender == deployerWallet);
    rewardsWallet = a;
  }
 
  // Functions
  function getLevel(uint256 seed) private pure returns(Level) {
    uint256 spinResult = SafeMath.mod(seed, 10);
    if (spinResult == 9) {
      return Level.TeenWarrior;
    } else if (spinResult == 8 || spinResult == 7 || spinResult == 6) {
      return Level.TeenFarmer;
    } else {
      return Level.TeenNormal;
    }
  }
  function intToLevel(uint256 num) private pure returns(Level) {
    if (num == 1) {
      return Level.TeenNormal;
    } else if (num == 2) {
      return Level.TeenFarmer;
    } else if (num == 3) {
      return Level.TeenWarrior;
    } else if (num == 4) {
      return Level.AdultNormal;
    } else if (num == 5) {
      return Level.AdultFarmer;
    } else if (num == 6) {
      return Level.AdultWarrior;
    } else {
      return Level.Baby;
    }
  }
  function manualMint(
      string memory _name,
      string memory _tokenURI,
      uint256 _level,
      uint256 _age,
      string memory _edition,
      address _owner
    ) public {
    require(address(msg.sender) == devWallet); //only developers
    uint256 idx = monkeys.length;
    uint256 id = idx.add(1);
    Level level = intToLevel(_level);
    Monkey memory _toCreate = Monkey(idx, id, level, _age, _edition, block.timestamp, false, 0, _owner);
    monkeys.push(_toCreate);
    tokenIdToName[id] = _name;
    _mint(_owner, id);
    _setTokenURI(id, _tokenURI);
  }
  function mintWithFee(string memory _name, string memory _tokenURI) public {
    address deadWallet = 0x000000000000000000000000000000000000dEaD;
    IAGold aGold = IAGold(aGoldAddr);
 
    address senderAddr = address(msg.sender);
    address apesAddr = address(this);
    uint256 senderBalance = aGold.balanceOf(senderAddr);
    uint256 allowance = aGold.allowance(senderAddr, apesAddr);
    require(senderBalance >= mintPrice);
    require(allowance >= mintPrice);
 
    uint256 half = mintPrice.div(2);
    uint256 otherHalf = mintPrice.sub(half);
    uint256 onePercent = mintPrice.div(100);
    uint256 restOtherHalf = otherHalf.sub(onePercent);
    // // send one percent to burn
    aGold.transferFrom(senderAddr, deadWallet, onePercent); // <= Hasta aca OK!
    // // send 49% to rewards wallet
    aGold.transferFrom(senderAddr, rewardsWallet, restOtherHalf); // <=
    // // send 50% to liquidity
    aGold.transferFrom(senderAddr, liquidityWallet, half);
 
    // Metadatos
    uint256 idx = monkeys.length;
    uint256 id = idx.add(1);
    Monkey memory _toCreate = Monkey(
      idx, id,
      Level.Baby, 0, 'normal',
      block.timestamp, false,
      0, msg.sender
    );
    tokenIdToName[id] = _name;
    monkeys.push(_toCreate);
    _mint(msg.sender, id);
    _setTokenURI(id, _tokenURI);
  }
  function grow(uint256 _tokenIdx) public {
    address deadWallet = address(0x000000000000000000000000000000000000dEaD);
    IAGold aBanana = IAGold(aBananaAddr);
    address apesAddr = address(this);
    address senderAddr = address(msg.sender);
    uint256 tokenId = _tokenIdx.add(1);
    uint256 senderBalance = aBanana.balanceOf(senderAddr);
    uint256 allowance = aBanana.allowance(senderAddr, apesAddr);
 
    require(senderAddr == ownerOf(tokenId)); // only owner
    require(senderBalance >= growPrice);
    require(allowance >= growPrice);
 
    Monkey memory current = monkeys[_tokenIdx];
    require(current.level == Level.Baby);
    require(senderAddr == current.owner);
 
    current.level = getLevel(block.timestamp);
    monkeys[_tokenIdx] = current;
 
    aBanana.transferFrom(senderAddr, deadWallet, growPrice); // TODO reward => dead
  }
  function getOwned() public view returns (uint[] memory) {
    uint256 cantOwned = balanceOf(msg.sender);
    uint256[] memory result = new uint256[](cantOwned); 
    for (uint256 index = 0; index < cantOwned; index++) {
      uint256 tokenId = tokenOfOwnerByIndex(msg.sender, index);
      result[index] = tokenId;
    }
    return result;
  }
  function listToSell(uint256 _idx, uint256 _price) public {
    Monkey memory current = monkeys[_idx];
    address blockChainOwner = ownerOf(current.id);
    require(current.onSale == false); // already on sale
    require(msg.sender == current.owner); // only owner
    require(msg.sender == blockChainOwner); // only owner
    require(_price > 0);
 
    current.onSale = true;
    current.price = _price;
    monkeys[_idx] = current;
  }
  function buy(uint256 _tokenId) public {
    IAGold aGold = IAGold(aGoldAddr);
    address buyerAddr = address(msg.sender);
    address apesAddr = address(this);
    uint256 buyerBalance = aGold.balanceOf(buyerAddr);
    uint256 allowance = aGold.allowance(buyerAddr, apesAddr);
    uint256 _idx = _tokenId.sub(1);
    Monkey memory current = monkeys[_idx];
    uint256 price = current.price;
    require(current.onSale == true); // check onSale
    require(buyerBalance >= price);
    require(allowance >= price);
    address initialOwner = ownerOf(_tokenId);
 
    // remove it from sales list
    current.onSale = false;
    current.owner = buyerAddr;
    current.price = 0;
    monkeys[_idx] = current;
 
    _transfer(initialOwner, buyerAddr, _tokenId);
 
    aGold.transferFrom(buyerAddr, initialOwner, price);
  }
 
  // overrides to use ERC721Enumerable and ERC721URIStorage
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
  function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
    super._burn(tokenId);
  }
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }
  // utils
  function compareStrings(string memory a, string memory b) private pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }
}