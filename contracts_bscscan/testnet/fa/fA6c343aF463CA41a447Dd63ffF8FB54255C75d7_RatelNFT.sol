// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RatelNFT is ERC721URIStorage, VRFConsumerBase, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20; 
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  // 事件
  event OnBabyMarketItemCreated (
    uint indexed itemId,
    uint indexed babyId,
    address seller,
    address owner,
    uint price,
    bool sold
  );
  event OnRatelBreed(
    address owner, 
    uint babyId, 
    uint maleTokenId, 
    uint femaleTokenId
  );
  event OnBabySold(
    address seller, 
    address owner, 
    uint babyId, 
    uint price
  );
  event OnCancelOrder(
    address seller, 
    uint babyId
  );
  event OnTakeGrownupRatel(
    address owner,
    uint babyId 
  );

  event OnDeposit(address indexed sender, uint value);

  Counters.Counter internal _itemIds; // will increment token ids when minting new tokens.
  Counters.Counter internal _itemsSold; 

  uint256 internal constant FATHER = 0;
  uint256 internal constant MOTHER = 1;
  uint256 internal constant MAX_BREED_COUNT = 5; //单张nft繁殖次数定量为5次
  uint256 internal constant FIVE_DAY_SECONDS = 300; //TODO，上线改为 432000; //幼兽成熟时间是5天

  // price for pre sale stage (0.2 BNB)
  uint256 internal preSalePrice =20 * 10**14; //TODO，上线改为  20 * 10**16;

  // price for publicsale stage (0.25 BNB)
  uint256 internal publicSalePrice = 25 * 10**14;  //TODO，上线改为 25 * 10**16;

  // fee for take grownup rate (0.01 BNB)
  uint256 internal takeGrownupFee = 1 * 10**16;

  // fee for breed , 游戏币 
  uint256 internal breedFee = 125000;

  // max airdrop  quota allowed
  uint256 internal maxAirdropCount = 1000;

  // max presale quota allowed
  uint256 internal maxPrivateSale = 3000;

  // max supply NFT 
  uint256 internal maxSupply = 10000;

  enum MintMode {AIRDROP, PRESALE, PUBLICSALE, BREED}

  uint256 internal chainlinkFee = 0.1 * 10**18; // 0.1 LINK token

  uint internal _totalAirdrop;     //空投总和
  uint internal _totalPrivateSale; //预售总和
  uint internal _totalPublicSale;  //公开销售总和
  uint internal _totalBreed;       //合约内所有幼兽总和
  uint internal _totalBreedFee;    //所有繁殖的手续费3%的总和，用于社区运营

  //预售及公开销售阶段，单个地址只允许10张, 空投及online之后不限制
  uint internal MAX_SALE_USER_AMOUNT = 10;

  // flag for pre sale
  bool internal preSale = false;

  // flag for publicsale
  bool internal publicSale = false;

  // flag for contract online status, admin only airdrop-able when offline
  bool internal isOnline = false;

  struct Baby {
        //父tokenId
        uint256 father_tokenId;
        //母tokenId
        uint256 mother_tokenId;
        //繁殖时的块高度
        uint256 blockNumber;
        //繁殖时的出块时间
        uint256 birthTime;
  }

  Baby[] private babies;

  // 用户拥有的幼兽信息映射： 幼兽id => 拥有者
  mapping (uint => address) private babyToOwner;
  // 地址拥有幼兽数量映射：拥有者 => 幼兽数量
  mapping (address => uint) private ownerBabyCount;
  // 用户是否为幼兽持有者映射：拥有者 => true/false
  mapping(address => bool) private babyOwner; 

  // 用户拥有的成年蜜獾映射：拥有者 => 数量
  mapping(address => uint) private ownerRatelCount; 

  // 用户是否为成年蜜獾持有者映射：拥有者 => true/false
  mapping(address => bool) private ratelOwner; 
 
  mapping(address => bool) private presaleAllowed;
  mapping(address => uint) private saleMintedLimits;
  mapping(uint => mapping(uint => uint)) private parents; //current tokenId => 0 => father tokenId
                                                          //current tokenId => 1 => mother tokenId
  mapping(uint => uint) private breedCounts; //current tokenId => 1-5

  uint256 internal maleTotal;
  uint256 internal femaleTotal;

  uint256 internal level2_rand;       //二级NFT随机数
  uint256 internal level3_rand;       //三级NFT随机数
  uint256 internal count_level_2 = 0;  //二级NFT比例 360-480
  uint256 internal count_level_3 = 0;  //三级NFT比例 480-600

  string  nftName = "Metaverse Ratel NFT";

  struct Character {
      uint256 strength; //力量
      uint256 dexterity; //敏捷
      uint256 luck; //幸运
      uint256 defense;  //防御
      uint256 wisdom; //智慧
      uint256 attack; //攻击
      uint256 gender; //性别
      string name;   //名称
     uint256 generation; //辈分，第几代
  }

  Character[] public characters;

  uint256 private randomResult;
  bytes32 requestId_;
  //tokenId与随机数的映射
  mapping(uint256 => uint256) internal tokenIdToSeed; 

  mapping(address => uint256) lastBlockNumberCalled;


  address _ratelGameTokenAddress = 0x72F20393273875BF4Ba237dF9eb91C6e1bcd1bbA;
  IERC20 internal ratelGameToken;//游戏代币合约

   address marketContractAddress = 0xEf2Da21F5bFDCb96AD6e4612F8007C0E0cC01326;

   string  internal _defaultURI = "https://meta-ratel.xyz/metadata/ratel.json";

   address _VRFCoordinator = 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C;
   address _LINKToken = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
   bytes32 keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
  
  //构造方法，先部署游戏代币合约及市场合约
  constructor()  VRFConsumerBase(_VRFCoordinator, _LINKToken) 
  ERC721("Metaverse Ratel NFT", "RATELNFT")
  {
    ratelGameToken = IERC20(_ratelGameTokenAddress);
  }

  /// @dev Receive function allows to deposit ether.
  receive() external payable {
    if (msg.value > 0)
            emit OnDeposit(msg.sender, msg.value);
  }

  fallback() external payable {

  }
  
  /***
    * @dev ensure contract is online
    */
  modifier online() {
      require(isOnline, "Contract must be online.");
      _;
  }

  /**
    * @dev ensure contract is offline
    */
  modifier offline() {
      require(!isOnline, "Contract must be offline.");
      _;
  }


  /**
    * @dev ensure caller is not contract 
    */
  modifier onlyNonContract() {
      _onlyNonContract();
      _;
  }

  function _onlyNonContract() internal view {
      require(tx.origin == msg.sender, "ONC");
  }

  /**
    * @dev ensure caller is not one block 
    */
  modifier oncePerBlock(address user) {
      _oncePerBlock(user);
      _;
  }

  function _oncePerBlock(address user) internal {
      require(lastBlockNumberCalled[user] < block.number, "OCB");
      lastBlockNumberCalled[user] = block.number;
  }

  /**
    * @dev ensure collector pays for breed an cub
    */
  modifier breedable(uint256 maleTokenId, uint256 femaleTokenId) {
      require(msg.sender == ownerOf(maleTokenId), "Male owner error.");
      require(msg.sender == ownerOf(femaleTokenId), "Female owner error.");
      _;
  }

 /**
  * @dev ensure collector pays for mint token
  */
  modifier mintable() {
      if(publicSale) {
          require(msg.value >= publicSalePrice, "Payment error.");
      }
      if(preSale) {
          require(msg.value >= preSalePrice, "Payment error.");
      }
      _;
  }

  function setDefaultURI(string memory defaultURI) public onlyOwner {
    _defaultURI = defaultURI;
  }

  /**
    * @dev change status from online to offline and vice versa
    * @notice only owner can call this method
    */
  function toggleActive() public onlyOwner returns (bool) {
      isOnline = !isOnline;
      return true;
  }

  /**
    * @dev change sale stage to private sale and PublicSale
    * @notice only owner can call this method
    */
  function togglePreAndPublicSale(uint256 flag) public onlyOwner returns (bool) {
      if (flag ==0) preSale = !preSale;
      if (flag ==1) publicSale = !publicSale;
      return true;
  }

  /**
    * @dev Set base URI for contract
    * @param _baseURI NFT Metadata base URI
    * @notice only owner can call this method
    */
  function setBaseURI(string memory _baseURI) public onlyOwner{
      setBaseURI(_baseURI);
  }

 //合约部署之后，需要调用一次
  function requestRandomNumber() public onlyOwner returns (bool) {
      require(
          LINK.balanceOf(address(this)) >= chainlinkFee,
          "Not enough LINK - fill contract with faucet"
      );
       //生成随机数,一次性
      require(randomResult==0, "only once call");
      requestRandomness(keyHash, chainlinkFee);
      return true;
  }

  /**
   * @dev mint a NFT for address: _to
   */
  function _mint(MintMode mode, address _to,  uint256 babyId) internal returns (bool) {
  
    require(randomResult>0, "randomResult error");

    uint256 tokenId = generateCharacters(mode, babyId);

    if (mode == MintMode.AIRDROP) {
      _totalAirdrop +=1;
    } else if (mode == MintMode.PRESALE) {
      _totalPrivateSale += 1;
      saleMintedLimits[_to] += 1;
    } else if (mode == MintMode.PUBLICSALE) {
      _totalPublicSale += 1;
      saleMintedLimits[_to] += 1;
    }
    
    if(ratelOwner[_to] == false) {
      ratelOwner[_to] = true;
    }
    ownerRatelCount[_to] += 1;

    //铸造一个新的NFT
    _safeMint(_to, tokenId);

    return true;
  }

  function generateCharacters(MintMode mode, uint256 babyId) internal returns(uint256){
    uint256 newId = characters.length;
    uint generation;
    uint256 base =20;
    if (mode == MintMode.BREED) {
      base = 45;
      //设置新的tokenId的父母
      parents[newId][FATHER] = babies[babyId].father_tokenId;
      parents[newId][MOTHER] = babies[babyId].mother_tokenId;

      uint generation_father = characters[babies[babyId].father_tokenId].generation;
      uint generation_mother = characters[babies[babyId].mother_tokenId].generation;
      generation = generation_father;
      if (generation_mother > generation_father) generation = generation_mother;

      randomResult = uint256(keccak256(abi.encode(tokenIdToSeed[babies[babyId].father_tokenId], tokenIdToSeed[babies[babyId].mother_tokenId])));
      
    } else {
      generation = 1; //第一代, 10000张都是
      randomResult = uint256(keccak256(abi.encode(block.timestamp, randomResult)));
    }

    uint256 strength = ((randomResult % 100) * base + 4000) / 100;// 力量
    uint256 dexterity = ((uint256(keccak256(abi.encode(randomResult, 1))) % 100) * base + 4000) / 100; //敏捷
    uint256 luck = ((uint256(keccak256(abi.encode(randomResult, 2))) % 100) * base  + 4000) / 100;     //运气
    uint256 defense = ((uint256(keccak256(abi.encode(randomResult, 3))) % 100) * base + 4000) / 100;  //防御
    uint256 wisdom = ((uint256(keccak256(abi.encode(randomResult, 4))) % 100) * base + 4000) / 100;   //智慧
    uint256 attack = ((uint256(keccak256(abi.encode(randomResult, 5))) % 100) * base + 4000) / 100;    //攻击
    if (level2_rand == 0) {
     level2_rand = uint256(keccak256(abi.encode(randomResult, 6))) % 3 + 8 ; //8-10
    }
    if (level3_rand == 0) {
     level3_rand = uint256(keccak256(abi.encode(randomResult, 7))) % 20 + 180; //180-199
    }

    //性别，0-雌性，1-雄性
    uint256 gender;
    if (maleTotal * 6 >= femaleTotal * 4 )  {
        gender = 0;
        femaleTotal++;
    } else {
        gender = 1;
        maleTotal++;
    }
    if ((newId+1) % level2_rand == 0 && count_level_2 < 950) {
          strength+=20;
          dexterity+=20;
          luck+=20;
          defense+=20;
          wisdom+=20;
          attack+=20;
          count_level_2 +=1;
          level2_rand = 0; //重新随机
    }

    if (( newId+1) % level3_rand == 0 && count_level_3 < 50 ) {
          strength+=40;
          dexterity+=40;
          luck+=40;
          defense+=40;
          wisdom+=40;
          attack+=40;
          count_level_3 +=1;
          level3_rand = 0; //重新随机
    }

    characters.push(  
          Character(
              strength,
              dexterity,
              luck,
              defense,
              wisdom,
              attack,
              gender,
              nftName,
              generation
          )
    );

    tokenIdToSeed[newId] = randomResult; 

    return newId;
  }

  //铸造方法，要根据预售或公开销售状态支付不同价格的BNB, 当游戏online之后，无法调用此方法
  function mint() 
    public 
    payable 
    offline 
    onlyNonContract  
    oncePerBlock(msg.sender) 
    mintable 
    returns (bool) {

    if (getMintMode() == MintMode.PRESALE) {
      require(presaleAllowed[_msgSender()], "Only whitelist addresses allowed.");
      require(saleMintedLimits[_msgSender()] + 1 <= MAX_SALE_USER_AMOUNT, "Max sale amount exceeded.");
      require(_totalPrivateSale + 1 <= maxPrivateSale, "Cannot oversell");
    }
    if (getMintMode() == MintMode.PUBLICSALE) {
      require(saleMintedLimits[_msgSender()] + 1 <= MAX_SALE_USER_AMOUNT, "Max sale amount exceeded.");
       require(_totalAirdrop + _totalPrivateSale + _totalPublicSale + 1 <= maxSupply, "Max publicsale amount exceeded.");
    }

    payable(address(this)).transfer(msg.value);
    
    return _mint(getMintMode(), _msgSender(), 0);
  }

  //空投, 只允许部署者调用
  function airdrop(address[] memory receivers, uint256[] memory counts)
    external
    offline
    onlyOwner
    returns (bool) {

    require(counts.length==receivers.length, "two array length is not equal");
    require(counts.length<=200, "length must less than 200");
    require(_totalAirdrop + 1 <= maxAirdropCount, "Max airdrop amount exceeded.");
          
    for(uint i = 0; i < receivers.length; i++) {
      for(uint j = 0; j < counts[i]; j++) {
        _mint(MintMode.AIRDROP, receivers[i], 0);
      }
    }
    return true;
  }

  function getMintMode() internal view returns(MintMode) {
    if (preSale) return MintMode.PRESALE;
    if (publicSale) return MintMode.PUBLICSALE;
    return MintMode.BREED;
  }

  //预售白名单录入
  function whitelist(address[] memory allowlist) 
  public 
  offline 
  onlyOwner returns(bool){
    for(uint i = 0; i < allowlist.length; i++) {
      presaleAllowed[allowlist[i]] = true;
    }
    return true;
  }

  //获取预售总数
  function totalPrivateSale() public view returns(uint) {
    return _totalPrivateSale;
  }

  //获取公开销售总数
  function totalPublicSale() public view returns(uint) {
    return _totalPublicSale;
  }

  //获取幼兽总数
  function totalBreed() public view returns(uint) {
    return _totalBreed;
  }

  //VRF的回调方法，重写
  function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override
  {
      requestId_ = requestId;
      randomResult = randomNumber;
  }

  /**
   * @dev Get tokenURI by tokenId
   * @notice  出块n个之后才能查询，否则返回default URI
   */
  function getTokenURI(uint256 tokenId) public view returns (string memory) {
      return tokenURI(tokenId);
  }

  //外部调用，在生成json文件之后调用
  function setTokenURI(uint256 tokenId, string memory _tokenURI) public nonReentrant {
      require(
          _isApprovedOrOwner(_msgSender(), tokenId),
          "ERC721: transfer caller is not owner nor approved"
      );
      _setTokenURI(tokenId, _tokenURI);

      setApprovalForAll(marketContractAddress, true);
  }

  //获取性别
  function getGender(uint256 tokenId) public view returns (uint256) {
      return characters[tokenId].gender;
  }

  //获取第几代
  function getGeneration(uint256 tokenId) public view returns (uint256) {
      return characters[tokenId].gender;
  }

  //获取所有成年蜜獾
  function getNumberOfCharacters() public view returns (uint256) {
      return characters.length;
  }

  //获取NFT概况，web开盲盒时从此接口获取到名称，综合值， 性别，第几代
  function getCharacterOverView(uint256 tokenId)
      public
      view
      returns (
          string memory,
          uint256,
          uint256,
          uint256,
          uint256
      )
  {
      return (
          characters[tokenId].name,
          characters[tokenId].strength + characters[tokenId].dexterity + characters[tokenId].luck + characters[tokenId].defense + characters[tokenId].wisdom + characters[tokenId].attack,
          getGender(tokenId),
          characters[tokenId].gender,
          characters[tokenId].generation
      );
  }

  //获取NFT属性状态
  function getCharacterStats(uint256 tokenId)
      public
      view
      returns (
          uint256,
          uint256,
          uint256,
          uint256,
          uint256,
          uint256,
          uint256
      )
  {
      return (
          characters[tokenId].strength,
          characters[tokenId].dexterity,
          characters[tokenId].luck,
          characters[tokenId].defense,
          characters[tokenId].wisdom,
          characters[tokenId].attack,
          characters[tokenId].gender
      );
  }

  //获取成年蜜獾的家族信息, 上一代父母，第几代
  function getRatelFamily(uint256 tokenId) public view returns(uint256, uint256, uint256) {
     return  (
       parents[tokenId][FATHER],
       parents[tokenId][MOTHER],
       characters[tokenId].generation
     );
  }

  //获取用户拥有的成年蜜獾总数
  function getRatelOwnCount(address addr) public view returns(uint256) {
    if (ratelOwner[addr] == false) return 0;
    return ownerRatelCount[addr];
  }

  // 获取用户拥有的成年蜜獾tokenId列表， 可用于游戏
  function getRatelListByOwner(address owner) public view returns (uint[] memory) {
      // 为了节省gas消耗 在内存中创建结果数组方法之后完后就会销毁
      uint[] memory result = new uint[](ownerRatelCount[owner]);
      uint counter = 0;
      for (uint i = 0; i < characters.length; i++) {
          if (ownerOf(i) == owner) {
              result[counter] = i;
              counter++;
          }
      }
      return result;
  }
  
  /*
  // 根据起始tokenId获取拥有者地址的列表，只能在合约外部调用
  function getOwnerListByTokenId(uint256 startTokenId, uint256 endTokenId) external view returns (address[] memory) {
    require(endTokenId < characters.length, "endTokenId must less than total");
    require(endTokenId > startTokenId, "startTokenId  must less than endTokenId");
    address[] memory result = new address[](endTokenId - startTokenId);
    uint counter = 0;
    for (uint i = startTokenId; i < endTokenId; i++) {
        result[counter] = ownerOf(i) ;
        counter++;
    }
    return result;
  }
  */

  //获取幼兽的信息, 父,母tokenid，第几代，出块高度，出生时间
  function getBabyInfo(uint babyId) 
    public
    view
  returns(uint256, uint256, uint256, uint256, uint256) {
    uint generation;
    uint generation_father = characters[babies[babyId].father_tokenId].generation;
    uint generation_mother = characters[babies[babyId].mother_tokenId].generation;
    generation = generation_father;
    if (generation_mother > generation_father) generation = generation_mother;
    return (
      babies[babyId].father_tokenId,
      babies[babyId].mother_tokenId,
      generation, //属于第几代
      babies[babyId].blockNumber,
      babies[babyId].birthTime
    );
  }

  //获取用户拥有的幼兽总数
  function getBabyOwnCount(address addr) public view returns(uint256) {
    if (babyOwner[addr] == false) return 0;
    return ownerBabyCount[addr];
  }

  // 获取用户所拥有的幼兽数组
  function getBabiesByOwner(address owner) public view returns (uint[] memory) {
      uint[] memory result = new uint[](ownerBabyCount[owner]);
      uint counter = 0;
      for (uint i = 0; i < babies.length; i++) {
          if (babyToOwner[i] == owner) {
              result[counter] = i;
              counter++;
          }
      }
      return result;
  }

  //获取繁殖需要的HRGT代币
  function getBreedFee(uint256 maleTokenId, uint256 femaleTokenId) public view returns(uint256){
    uint256 breedFee1 = breedFee.mul( breedCounts[maleTokenId].add(1));
    uint256 breedFee2 = breedFee.mul( breedCounts[femaleTokenId].add(1));
    return breedFee1.add(breedFee2);
  }

  //繁殖
  function breed(uint256 maleTokenId, uint256 femaleTokenId)
    public 
    online
    breedable(maleTokenId, femaleTokenId)
    nonReentrant
    returns(bool){
    // step 1, 检测雌雄性别
    require(characters[maleTokenId].gender == 1, "Father not male");
    require(characters[femaleTokenId].gender == 0, "Mother not female");

    // step 2, 检测雌雄的父母是否相同 
    //雄性的父亲
    uint256 father1 = parents[maleTokenId][FATHER];
    //雌性的父亲
    uint256 father2 = parents[femaleTokenId][FATHER]; 
    require(father1 != father2, "Same father error.");

    //雄性的母亲
    uint256 mother1 = parents[maleTokenId][MOTHER];
    //雌性的母亲
    uint256 mother2 = parents[femaleTokenId][MOTHER];
    require(mother1 != mother2, "Same mother error.");

    //父母与亲生后代不能繁殖
    require(maleTokenId != father2 , "Breed error.");
    require(femaleTokenId !=  mother1 , "Breed error.");

    // step 3，检测双方的繁殖次数是否达到5次
    require(breedCounts[maleTokenId] + 1 < MAX_BREED_COUNT, "Max breed error.");
    require(breedCounts[femaleTokenId] + 1 < MAX_BREED_COUNT, "Max breed error.");

    // step 4，检测是否拥有足够的游戏代币
    uint256 _fee = getBreedFee(maleTokenId, femaleTokenId);

    require(ratelGameToken.balanceOf(msg.sender) >= _fee, "Insufficient token for breed" );

    //HRGT转账到合约, 必须让用户调用游戏代币合约的approve
    ratelGameToken.safeTransferFrom(msg.sender, address(this), _fee);
    _totalBreedFee = _totalBreedFee.add(_fee.mul(97).div(100));
    ratelGameToken.safeTransferFrom(address(this), address(0), _fee.mul(97).div(100)); //销毁97%

    //累加繁殖次数
    breedCounts[maleTokenId]  += 1;
    breedCounts[femaleTokenId] += 1;

    //写入幼兽数组
    uint256 newBabyId = babies.length;
    babies.push(Baby(
      maleTokenId,
      femaleTokenId,
      block.number,
      block.timestamp
    ));

    //存放用户拥有的幼兽信息
    babyToOwner[newBabyId] = msg.sender;
    ownerBabyCount[msg.sender] += 1;

    if(babyOwner[msg.sender] == false) {
      babyOwner[msg.sender] = true;
    }
    
    _totalBreed++;

    emit OnRatelBreed(msg.sender, newBabyId, maleTokenId, femaleTokenId);
    return true; 
  }

  /**
    * @dev take the grownup ratel after 5 days
    * @notice 提取繁殖的NFT，需消耗0.01BNB手续费
    */
  function takeGrownupRatel(uint babyId) 
    public
    payable
    online
  returns(bool) {
    require(msg.value >= takeGrownupFee, "Payment take error.");
    require(babyOwner[msg.sender] == true, "Not owner error");
    require(babyToOwner[babyId] == msg.sender, "Not owner error");
    require(block.timestamp - babies[babyId].birthTime >= FIVE_DAY_SECONDS, "Less than 5 days" );

    babyToOwner[babyId] = address(0); // 设置为0地址
    ownerBabyCount[msg.sender] -= 1; //数量减一
    if (ownerBabyCount[msg.sender] == 0) {
      babyOwner[msg.sender] = false;
    }

    //手续费 
    payable(address(this)).transfer(msg.value);
    
    //减少幼兽数量
    _totalBreed--;

    //触发事件
    emit OnTakeGrownupRatel(msg.sender, babyId);
   
    return _mint(MintMode.BREED, _msgSender(), babyId);
  }

  /**
  * @dev withdraw ether to owner/admin wallet
  * @notice only owner can call this method
  */
  function withdraw() public onlyOwner returns(bool){
      payable(msg.sender).transfer(address(this).balance);
      return true; 
  }

  /**
  * @dev Withdraw ERC20 Token from this contract
  * @notice only owner can call this method
  */
  function withdrawToken() public onlyOwner returns(bool){
    uint256 balance = ratelGameToken.balanceOf(address(this));
    ratelGameToken.safeTransfer(msg.sender, balance);
    return true; 
  }

  struct MarketItem {
    uint itemId;
    uint babyId;
    address payable seller;
    address payable owner; 
    uint price;
    bool sold;
  }

  mapping(uint => MarketItem) private idToMarketItem;

  //卖家上架幼兽, 价格以BNB为单位, NFT在市场中交易，如果成交, 项目方会收取卖方3%手续费 
  function createBabyMarketItem(uint babyId, uint price) public nonReentrant returns(bool){
    require(price > 0, "price must be more than 0");
    require(babyToOwner[babyId] == msg.sender, "Not owner");

    _itemIds.increment();
    uint itemId = _itemIds.current();

    idToMarketItem[itemId] = MarketItem(
      itemId,
      babyId,
      payable(msg.sender), // seller
      payable(address(0)), // owner. Empty address because it still has no owner.
      price,
      false 
    );

    babyToOwner[babyId] = address(0); //将幼兽所有者设置为0x0地址
    ownerBabyCount[idToMarketItem[itemId].seller] -= 1;
    if (ownerBabyCount[idToMarketItem[itemId].seller] == 0) {
       babyOwner[idToMarketItem[itemId].seller] = false;
    }

    emit OnBabyMarketItemCreated(itemId, babyId, msg.sender, address(0), price, false);    
    return true;
  }

  //买家购买, 手续费3%由卖家承担
  function createBabyMarketSale(uint itemId) public payable nonReentrant returns(bool) {
    require(itemId <= _itemIds.current(), "item not exists" );
    uint price = idToMarketItem[itemId].price;
    uint babyId = idToMarketItem[itemId].babyId;

    require(msg.value >= price, "the price payed is incorrect");
    // console.log("price is: %s", msg.value);
    require(idToMarketItem[itemId].sold == false, "already sold");

    // transfer the price of the baby (sending money) from the buyer to the seller
    idToMarketItem[itemId].seller.transfer(msg.value.mul(97).div(100));

    //手续费转到合约  
    payable(address(this)).transfer(msg.value.mul(3).div(100));
    
    // change the owner infomation to the buyer
    babyToOwner[babyId] = msg.sender;
    ownerBabyCount[msg.sender] += 1;
    babyOwner[msg.sender] = true;

    //初始化繁殖时间
    babies[babyId].birthTime = block.timestamp;
      
    // set the local value for the owner.
    idToMarketItem[itemId].owner = payable(msg.sender);
    idToMarketItem[itemId].sold = true;

    // MarketItem memory item1 = idToMarketItem[itemId];
    // console.log("item.sold: %s", item1.sold);

    _itemsSold.increment();

    //触发幼兽售出事件
    emit OnBabySold(idToMarketItem[itemId].seller, payable(msg.sender), babyId, price);

    return true;
  }

  //撤单
  function cancelOrder(uint256 itemId) public nonReentrant returns (bool) {
      require(itemId <= _itemIds.current(), "item not exists" );
      MarketItem storage item = idToMarketItem[itemId];
      require(item.seller == msg.sender, "not the seller of this item");
      require(item.owner == address(0), "owner not address zero");
      require(item.sold == true, "already sold");

      babyToOwner[item.babyId] = msg.sender;
      ownerBabyCount[msg.sender] += 1;
      babyOwner[msg.sender] = true;
    
      item.owner = payable(msg.sender);
      item.sold = true;
      item.price = 0;

      //初始化繁殖时间
      babies[item.babyId].birthTime = block.timestamp;
      
      //触发幼兽撤单事件
      emit OnCancelOrder(idToMarketItem[itemId].seller, item.babyId);

      return true;
  }

  //获取未售出状态的幼兽
  function fetchBabyMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;
    MarketItem[] memory items = new MarketItem[](unsoldItemCount);

    for (uint256 index = 0; index < itemCount; index++) {
      if(idToMarketItem[index+1].owner == address(0)){
        uint currentId = idToMarketItem[index +1].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex +=1;
      }
    }

    return items;
  }

  //查询当前用户在市场上的所有幼兽列表
  function fetchMyBabiesMarket() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint256 index = 1; index < totalItemCount; index++) {
      if(idToMarketItem[index].owner == msg.sender){
        itemCount +=1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 index = 1; index < totalItemCount; index++) {
      if(idToMarketItem[index].owner == msg.sender){
        uint currentId = idToMarketItem[index].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex = currentIndex+1; 
      }
    }
    return items;
  }

  //获取市场上当前用户出售中的幼兽
  function fetchBabyItemsCreated() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint256 index = 1; index < totalItemCount; index++) {
      if(idToMarketItem[index].seller == msg.sender){
        itemCount +=1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 index = 1; index < totalItemCount; index++) {
      if(idToMarketItem[index].seller == msg.sender){
        uint currentId = idToMarketItem[index].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex = currentIndex+1; 
      }
    }
    return items;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}