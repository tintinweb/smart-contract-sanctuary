/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 value) external returns (bool);
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

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function blindBox(address seller, string calldata tokenURI, bool flag, address to, string calldata ownerId) external returns (uint256);
    function mintAliaForNonCrypto(uint256 price, address from) external returns (bool);
    function getRandomNumber() external returns (bytes32);
    function getRandomVal() external returns (uint256);
    // function transferOwnershipPack(address seller, address to, uint256 tokenId, string calldata ownerId) external returns (bool);
}

// File: contracts/blindBoxSingle.sol

pragma solidity 0.8.0;



contract BlindBoxSingle {

using SafeMath for uint256;
  IERC20 ALIA;
  uint256 randomValue;
  address xanaliaDex;

  struct category{
    mapping(uint256=>string) tokenUris;
    uint256 count;
    string title;
    string description;
    string image;
    uint256 price;
    uint256 usdPrice;
    uint256 countNFT;
  }
  mapping(string=>category) private Category;
   bool private isInitialized1;
  IERC20 LPAlia;
  IERC20 LPBNB;
using SafeMath for uint112;
  struct categoryDetail{  
    string hash;  
  } 
  mapping(string=>categoryDetail) private CategoryDetail;

  event CreateCategory(string name, string title,string description,string image, uint256 price, uint256 usdPrice, uint256 countNFT, string detailHash);
  event URIAdded(string name, string uri, uint256 count);
  event BuyBox(address buyer, string ownerId, string name, uint256 tokenIds );
  event UpdateAllValueOfPack(string name, string title, string description, string image, uint256 price, uint256 usdPrice, uint256 count, string detailHash);
  
  
  event CreateCategoryDuel(string name, string title,string description,string image, uint256 price, uint256 usdPrice, uint256 countNFT, uint256 amountBox, uint256 startTime, uint256 endTime); 
  event UpdateAllValueOfPackDuel(string name, string title, string description, string image, uint256 price, uint256 usdPrice, uint256 count, uint256 amountBox, uint256 startTime, uint256 endTime);

  event URIAddedToCatDuel(string name, string rarity, string uri, uint256 count, uint256 cost, uint256 attack, uint256 cardType, uint256 toughness, string[] abilities, string element);
  event UpdateURIAddedToCatDuel(string name, string rarity, string uri, uint256 count, uint256 cost, uint256 attack, uint256 cardType, uint256 toughness, string[] abilities, string element);
  event BuyBoxDuel(address buyer, string ownerId, string name, uint256 tokenIds, string tokenUri );
  

  constructor() public{
    ALIA = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
    xanaliaDex = 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1;
    LPAlia=IERC20(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
    LPBNB=IERC20(0xe230E414f3AC65854772cF24C061776A58893aC2);
    chainRan = IERC20(0xc891D750acdDA5F6f927315c46CFa1063Cd2bDf8);
    isInitialized1=true;
  }

 function init1() public {
    require(!isInitialized1);
    ALIA = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
    xanaliaDex = 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1;
    LPAlia=IERC20(0x8c77B810EaC25502EE7de2e447ffb80b316c4E6E);
    isInitialized1=true;
  }
  IERC20 chainRan;
  bool private isInitialized2;
  uint256 randomValueMain;
  string rarityValue;

  uint256 randomValueRarity;  
  struct attributesInUri{
        string tokenUris;
        uint256 cost;
        uint256 attack;
        uint256 cardType;
        uint256 toughness;
        uint256 abilityCount;
        string element;
        string[] abilities;
      }

      struct rarity{
        mapping(uint256=>attributesInUri) attributes;
        uint256 count;
        }

      struct pack{
        uint256 count;
        string description;
        string image;
        uint256 price;
        uint256 usdPrice;
        uint256 countNFT;
        uint256 amountBox;
        uint256 sold;
        uint256 startTime;
        uint256 endTime;
      }

      struct categoryDuel{
      mapping(string=>pack) packType;
      mapping(string=>rarity) rarityBasedUris;
      }

    mapping (string => categoryDuel) private CategoryDuel;

    uint256 public rarity1;
    uint256 public rarity2;
    uint256 public rarity3;
    uint256 public rarity4;
    uint256 public rarity5;
    uint256 public rarity6;
    uint256 public rarity7;
    uint256 public rarity8;

 struct tokenURI{
        uint256 cost;
        uint256 attack;
        uint256 cardType;
        uint256 toughness;
        uint256 abilityCount;
        string element;
        string[] abilities;
        bool pureCheck;
      }
    mapping(string=>tokenURI) public mapUri;

  function init2() public {
    require(!isInitialized2);
    isInitialized2=true;
    chainRan = IERC20(0xc891D750acdDA5F6f927315c46CFa1063Cd2bDf8);
  }

  modifier adminAdd() {
      require(msg.sender == 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859);
      _;
  }

  function createCategory(string memory name, string memory title, string memory description, string memory image, uint256 price, uint256 usdPrice, uint256 countNFT, string memory detailHash) public adminAdd {
    require(price > 0 || usdPrice > 0, "Price or Price in usd should be greater than 0");
    require(countNFT > 0, "Count of NFTs should be greater then 0");
    require(Category[name].count == 0, "NFT name alreay present with token URIs");
    Category[name].title = title;
    Category[name].description = description;
    Category[name].image = image;
    Category[name].price = price;
    Category[name].usdPrice = usdPrice;
    Category[name].countNFT = countNFT;
    CategoryDetail[name].hash = detailHash; 
    emit CreateCategory(name, title, description, image, price, usdPrice,countNFT, detailHash);
  }

function createCategoryDuel(string memory name, string memory title, string memory description, string memory image, uint256 price, uint256 usdPrice, uint256 countNFT, uint256 amountBox, uint256 startTime, uint256 endTime) public adminAdd {
    require(price > 0 || usdPrice > 0, "Price or Price in usd should be greater than 0");
    require(countNFT > 0, "Count of NFTs should be greater then 0");
    require(CategoryDuel[name].packType[title].count == 0, "NFT name alreay present with token URIs");
    require(CategoryDuel[name].packType[title].countNFT>0,"No box Exists");
    require((startTime>= block.timestamp) && (endTime > block.timestamp),"Start/End time must me greater than now");
    require(startTime < endTime,"No Correct Time");
    CategoryDuel[name].packType[title].description = description;
    CategoryDuel[name].packType[title].image = image;
    CategoryDuel[name].packType[title].price = price;
    CategoryDuel[name].packType[title].usdPrice = usdPrice;
    CategoryDuel[name].packType[title].countNFT = countNFT;
    CategoryDuel[name].packType[title].sold = 0;
    CategoryDuel[name].packType[title].amountBox = amountBox;
    CategoryDuel[name].packType[title].startTime = startTime;
    CategoryDuel[name].packType[title].endTime = endTime;
    emit CreateCategoryDuel(name, title, description, image, price, usdPrice, countNFT, amountBox, startTime, endTime);
  }

  function addUriToCategory(string memory name,string memory uris) adminAdd public {
    require(Category[name].price > 0 || Category[name].usdPrice > 0, "Category not created");
    Category[name].tokenUris[Category[name].count] = uris;
    emit URIAdded(name, uris,Category[name].count);
    Category[name].count++;
  }
    function addUriToCategoryDuel(string memory name,string memory title,string memory rarityInput, string memory uris, uint256 cost, uint256 attack, uint256 cardType, uint256 toughness, string[] memory abilities, string memory element) adminAdd public {
    require(CategoryDuel[name].packType[title].price > 0 || CategoryDuel[name].packType[title].usdPrice > 0, "CategoryDuel not created");

    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[CategoryDuel[name].rarityBasedUris[rarityInput].count].tokenUris = uris;   
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[CategoryDuel[name].rarityBasedUris[rarityInput].count].cost = cost;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[CategoryDuel[name].rarityBasedUris[rarityInput].count].attack = attack;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[CategoryDuel[name].rarityBasedUris[rarityInput].count].cardType = cardType;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[CategoryDuel[name].rarityBasedUris[rarityInput].count].toughness = toughness;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[CategoryDuel[name].rarityBasedUris[rarityInput].count].abilities = abilities;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[CategoryDuel[name].rarityBasedUris[rarityInput].count].abilityCount = abilities.length;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[CategoryDuel[name].rarityBasedUris[rarityInput].count].element = element;
    emit URIAddedToCatDuel(name, rarityInput, uris,CategoryDuel[name].rarityBasedUris[rarityInput].count, cost,attack,cardType,toughness, abilities, element);
    CategoryDuel[name].rarityBasedUris[rarityInput].count++;

    CategoryDuel[name].packType[title].count++;

    mapUri[uris].cost = cost;
    mapUri[uris].attack = attack;
    mapUri[uris].cardType = cardType;
    mapUri[uris].toughness = toughness;
    mapUri[uris].abilityCount = 1;
    mapUri[uris].element = element;
    mapUri[uris].abilities = abilities;
    mapUri[uris].pureCheck = true;

  }

function updateUriToCategoryDuel(string memory name,string memory title,string memory rarityInput, uint256 valueToUpdate, string memory uris, uint256 cost, uint256 attack, uint256 cardType, uint256 toughness, string[] memory abilities, string memory element) adminAdd public {
    require(CategoryDuel[name].packType[title].price > 0 || CategoryDuel[name].packType[title].usdPrice > 0, "CategoryDuel not created");

    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[valueToUpdate].tokenUris = uris;   
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[valueToUpdate].cost = cost;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[valueToUpdate].attack = attack;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[valueToUpdate].cardType = cardType;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[valueToUpdate].toughness = toughness;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[valueToUpdate].abilities = abilities;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[valueToUpdate].abilityCount = abilities.length;
    CategoryDuel[name].rarityBasedUris[rarityInput].attributes[valueToUpdate].element = element;
    emit UpdateURIAddedToCatDuel(name, rarityInput, uris, valueToUpdate, cost,attack,cardType,toughness, abilities, element);

    delete mapUri[CategoryDuel[name].rarityBasedUris[rarityInput].attributes[valueToUpdate].tokenUris];
    
    mapUri[uris].cost = cost;
    mapUri[uris].attack = attack;
    mapUri[uris].cardType = cardType;
    mapUri[uris].toughness = toughness;
    mapUri[uris].abilityCount = 1;
    mapUri[uris].element = element;
    mapUri[uris].abilities = abilities;
    mapUri[uris].pureCheck = true;

  }

  function updateAllValueOfPack(string memory name, string memory title,string memory description, string memory image, uint256 price, uint256 usdPrice, uint256 count, string memory detailHash)  public adminAdd {
    require(price > 0 || usdPrice > 0, "Price or Price in usd should be greater than 0");
    Category[name].title = title;
    Category[name].description = description;
    Category[name].image = image;
    Category[name].price = price;
    Category[name].usdPrice = usdPrice;
    Category[name].countNFT = count;
    CategoryDetail[name].hash = detailHash; 
    emit UpdateAllValueOfPack(name, title, description, image, price, usdPrice, count, detailHash);
  }

  function updateAllValueOfPackDuel(string memory name, string memory title,string memory description, string memory image, uint256 price, uint256 usdPrice, uint256 count, uint256 amountBox, uint256 startTime, uint256 endTime ) public adminAdd {
    require(price > 0 || usdPrice > 0, "Price or Price in usd should be greater than 0");
    CategoryDuel[name].packType[title].description = description;
    CategoryDuel[name].packType[title].image = image;
    CategoryDuel[name].packType[title].price = price;
    CategoryDuel[name].packType[title].usdPrice = usdPrice;
    CategoryDuel[name].packType[title].countNFT = count;
    CategoryDuel[name].packType[title].amountBox = amountBox;
    CategoryDuel[name].packType[title].startTime = startTime;
    CategoryDuel[name].packType[title].endTime = endTime;
    emit UpdateAllValueOfPackDuel(name, title, description, image, price, usdPrice, count, amountBox, startTime, endTime);
  }

  function buyBox(address seller, string memory ownerId, string memory name) public {
    uint256 price = Category[name].price;
    if(price == 0){
           (uint112 reserve0, uint112 reserve1,) =LPAlia.getReserves();
           price = (Category[name].usdPrice * reserve1) /(reserve0 * 1000000000000);
    }
    IERC20(xanaliaDex).mintAliaForNonCrypto(price,msg.sender);
    uint256 tokenId;
    chainRan.getRandomNumber();
    for(uint256 i =0; i<Category[name].countNFT; i++)
    {
    randomValueMain = chainRan.getRandomVal();
    tokenId = IERC20(xanaliaDex).blindBox(seller, Category[name].tokenUris[(uint256(keccak256(abi.encode(randomValueMain, i))) % Category[name].count)], true, msg.sender, ownerId);
    emit BuyBox(msg.sender, ownerId, name,tokenId);
    }
    ALIA.transferFrom(msg.sender, 0x17e42ABa1Aa9aA2D50Ada0e4b3E03837e8e57Cec, price);
  }

 function buyBoxDuel(address seller, string memory ownerId, string memory name, string memory title) public {
    require(CategoryDuel[name].packType[title].sold <= CategoryDuel[name].packType[title].amountBox, "Already sold maximum time");
    uint256 price = CategoryDuel[name].packType[title].price;
    if(price == 0){
      (uint112 _reserve0, uint112 _reserve1,) =LPBNB.getReserves();
           (uint112 reserve0, uint112 reserve1,) =LPAlia.getReserves();
           price = (CategoryDuel[name].packType[title].usdPrice * _reserve0 * reserve0) /(_reserve1 * reserve1);
    }
    IERC20(xanaliaDex).mintAliaForNonCrypto(price,msg.sender);
    uint256 tokenId;
    chainRan.getRandomNumber();
    for(uint256 i =0; i<CategoryDuel[name].packType[title].countNFT; i++)
    {
    randomValueMain = chainRan.getRandomVal();
    string memory returnedValue = weightGenerator(i+1);
    uint256 num = (uint256(keccak256(abi.encode(randomValueMain, i))) % CategoryDuel[name].rarityBasedUris[returnedValue].count);
    tokenId = IERC20(xanaliaDex).blindBox(seller, CategoryDuel[name].rarityBasedUris[returnedValue].attributes[num].tokenUris, true, msg.sender, ownerId);
    emit BuyBoxDuel(msg.sender, ownerId, name,tokenId,CategoryDuel[name].rarityBasedUris[returnedValue].attributes[num].tokenUris);
    }
    ALIA.transferFrom(msg.sender, 0x7712a69600587E48d73060Def272D3a37e078921 , price);
    CategoryDuel[name].packType[title].sold+1;
  }


  function getBoxDetail(string memory name) public view returns(string memory, string memory, uint256,uint256, uint256){
    return (Category[name].title, Category[name].description, Category[name].price,Category[name].usdPrice,Category[name].countNFT);
  }
 
 function weightGenerator(uint256 Input) internal returns(string memory)  {
    uint256 num =(uint256(keccak256(abi.encode(randomValueMain, Input))));
    randomValueRarity = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, num))) % 10000;
    if(randomValueRarity<=rarity1) rarityValue = "common";
    else if(randomValueRarity>rarity1 && randomValueRarity<=rarity2) rarityValue = "unCommon"; 
    else if(randomValueRarity>rarity2 && randomValueRarity<=rarity3) rarityValue = "rare";
    else if(randomValueRarity>rarity3 && randomValueRarity<=rarity4) rarityValue = "doubleRare";
    else if(randomValueRarity>rarity4 && randomValueRarity<=rarity5) rarityValue = "trippleRare";
    else if(randomValueRarity>rarity5 && randomValueRarity<=rarity6) rarityValue = "superRare";
    else if(randomValueRarity>rarity6 && randomValueRarity<=rarity7) rarityValue = "hyperRare";
    else if(randomValueRarity==rarity8) rarityValue = "ultraRare";
    return (rarityValue);
  }

 function setWeightage(uint256 input1,uint256 input2,uint256 input3,uint256 input4,uint256 input5,uint256 input6,uint256 input7,uint256 input8) public adminAdd{
   require(input1+input2+input3+input4+input5+input6+input7+input8 == 10000,"Sum should be 10000");
  rarity1 = input1;
  rarity2 = input2+input1;
  rarity3 = input3+input2+input1;
  rarity4 = input4+input3+input2+input1;
  rarity5 = input5+input4+input3+input2+input1;
  rarity6 = input6+input5+input4+input3+input2+input1;
  rarity7 = input7+input6+input5+input4+input3+input2+input1;
  rarity8 = input8+input7+input6+input5+input4+input3+input2+input1;
 }

}