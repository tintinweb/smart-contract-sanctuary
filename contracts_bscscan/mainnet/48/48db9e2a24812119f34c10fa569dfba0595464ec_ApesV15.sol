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
    string name;
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
  // TODO: quit events for test, and implemet as getters that only deployer can excecute
  event MessageI(uint256 msg);
  event MessageB(bool msg);
  event MessageA(address msg);
  
  // Initiatialize
  function initialize() public initializer {
    nextGrow = 0;
    mintPrice = 1000; //aGold
    growPrice = 10; //aBanana
    evolvePrice = 1; //aPapyrus
  }
  function setBNBAddr(address a) public {
    bnbAddr = a;
  }
  function setAGoldAddr(address a) public {
    aGoldAddr = a;
  }
  function setABananaAddr(address a) public {
    aBananaAddr = a;
  }
  function setAPapyrusAddr(address a) public {
    aPapyrusAddr = a;
  }
  function setFightAddr(address a) public {
    fightAddr = a;
  }
  function setPancakeAddr(address a) public {
    pancakeAddr = a;
  }
  function setLiquidityWallet(address a) public {
    liquidityWallet = a;
  }
  function setDevWallet(address a) public {
    devWallet = a;
  }
  function setMarketingWallet(address a) public {
    marketingWallet = a;
  }
  function setDeployerWallet(address a) public {
    deployerWallet = a;
  }
  function setRewardsWallet(address a) public {
    rewardsWallet = a;
  }

  // function swapAndLiquify(uint256 tokens) private {
  //   IPancakeRouter pancake = IPancakeRouter(pancakeAddr);
  //   // split the contract balance into halves
  //   uint256 half = tokens.div(2);
  //   uint256 otherHalf = tokens.sub(half);

  //   // capture the contract's current ETH balance.
  //   // this is so that we can capture exactly the amount of ETH that the
  //   // swap creates, and not make the liquidity event include any ETH that
  //   // has been manually sent to the contract
  //   uint256 initialBalance = address(this).balance;

  //   // swap tokens for ETH
  //   swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

  //   // how much ETH did we just swap into?
  //   uint256 newBalance = address(this).balance.sub(initialBalance);

  //   // add liquidity to uniswap
  //   addLiquidity(otherHalf, newBalance);

  //   emit SwapAndLiquify(half, newBalance, otherHalf);
  // }

  // Functions
  function getLevel(uint256 num) private pure returns(Level) {
    if (num == 9) {
      return Level.TeenWarrior;
    } else if (num == 8 || num == 7 || num == 6) {
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
    require(address(msg.sender) == devWallet, "no devwallet"); //only developers
    uint256 idx = monkeys.length;
    uint256 id = idx.add(1);
    Level level = intToLevel(_level);
    Monkey memory _toCreate = Monkey(_name, idx, id, level, _age, _edition, block.timestamp, false, 0, _owner);
    monkeys.push(_toCreate);
    _mint(_owner, id);
    _setTokenURI(id, _tokenURI);
  }
  function mintWithFee(string memory _name, string memory _tokenURI) public {
    
    address deadWallet = 0x000000000000000000000000000000000000dEaD;
    IAGold aGold = IAGold(aGoldAddr);
    IPancakeRouter pancake = IPancakeRouter(pancakeAddr);
    
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](3);
    path[0] = address(this);
    path[1] = aGoldAddr;
    path[2] = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); //BNB;

    address senderAddr = address(msg.sender);
    address apesAddr = address(this);
    uint256 senderBalance = aGold.balanceOf(senderAddr);
    uint256 allowance = aGold.allowance(senderAddr, apesAddr);
    
    // emit MessageI(allowance); => 1000 OK!
    require(senderBalance >= mintPrice);
    require(allowance >= mintPrice);
    // emit MessageI(senderBalance); => 100.000 OK!  

    uint256 half = mintPrice.div(2);
    uint256 otherHalf = mintPrice.sub(half);
    uint256 onePercent = mintPrice.div(100);
    uint256 restOtherHalf = otherHalf.sub(onePercent);
    // emit MessageI(onePercent); => 10 OK!
    // emit MessageI(restOtherHalf); => 495 OK!
    // send one percent to burn
    aGold.transferFrom(senderAddr, deadWallet, onePercent); // <= Hasta aca OK!
    // send 49% to rewards wallet
    aGold.transferFrom(senderAddr, rewardsWallet, restOtherHalf); // <= Hasta aca OK!
    // get balance on bnb before buy
    uint256 bnbBalanceBeforeSwap = apesAddr.balance;
    // send half of the other half to bnb
    uint256 quarterPart = half.div(2);
    
    aGold.approve(pancakeAddr, quarterPart); // <= Approve aGold for swapping in pancake
    pancake.swapExactTokensForTokensSupportingFeeOnTransferTokens(quarterPart, 0, path, address(this), block.timestamp); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
    // get balance on bnb after buy
    uint256 bnbBalanceAfterSwap = apesAddr.balance;
    uint256 amountBNBGiven = bnbBalanceAfterSwap.sub(bnbBalanceBeforeSwap);
    pancake.addLiquidity(bnbAddr, aGoldAddr, amountBNBGiven, quarterPart, 0, 0, devWallet, block.timestamp);
    // emit SwapAndLiquify(half, newBalance, otherHalf); <= It was on swapAndLiquify, is it neccessary?
    
    // Metadatos
    //uint256 idx = monkeys.length;
    //uint256 id = idx.add(1);
    //Monkey memory _toCreate = Monkey(
    //_name, idx, id,
    //Level.Baby, 0, 'normal',
    //block.timestamp, false,
    //0, msg.sender
    //);
    //monkeys.push(_toCreate);
    //_mint(msg.sender, id);
    //_setTokenURI(id, _tokenURI);
  }
  function grow(uint256 _tokenIdx) public {
    // address aBananaAddr = address(0x70BBAc8a3a2232B512923C2997439FeAB5f6B56B);
    // IABanana aBanana = IABanana(aBananaAddr);
    // require(aBanana.allowance(address(msg.sender), address(this)) >= growPrice);
    // require(growPrice <= aBanana.balanceOf(address(msg.sender)));
    Monkey memory current = monkeys[_tokenIdx];
    require(current.level == Level.Baby);
    require(msg.sender == current.owner);
    // require(msg.value > 0); // TODO compare against growPrice

    current.level = getLevel(nextGrow);
    // nextGrow = (nextGrow + 1) % 10;
    nextGrow = SafeMath.mod((nextGrow.add(1)), 10);
    monkeys[_tokenIdx] = current;

    // bool sent = aBanana.transferFrom(
    //   address(msg.sender),
    //   address(aBananaAddr),
    //   growPrice
    // );
    // require(sent);
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
    require(msg.sender == current.owner); // only owner
    require(msg.sender == blockChainOwner); // only owner
    require(_price > 0);

    current.onSale = true;
    current.price = _price;
    monkeys[_idx] = current;
  }
  function buy(uint256 _tokenId/*, uint256 _price*/) public { // TODO: payable?
    uint256 _idx = _tokenId.sub(1);
    address actualOwner = ownerOf(_tokenId);
    Monkey memory current = monkeys[_idx];

    require(current.onSale == true); // check onSale
    // TODO require(current.price == _price);

    // remove it from sales list
    current.onSale = false;
    current.owner = msg.sender;
    current.price = 0;
    monkeys[_idx] = current;

    _transfer(actualOwner, msg.sender, _tokenId);
    // TODO: transfer aGold to seller
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