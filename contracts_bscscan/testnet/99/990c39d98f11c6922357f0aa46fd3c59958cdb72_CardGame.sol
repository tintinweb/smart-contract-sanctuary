/**
 *Submitted for verification at BscScan.com on 2021-08-20
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
    // function transferOwnershipPack(address seller, address to, uint256 tokenId, string calldata ownerId) external returns (bool);
}

// File: contracts/Blind.sol

pragma solidity 0.8.0;



contract CardGame {

using SafeMath for uint256;
  IERC20 ALIA;
  uint256 randomValue;
  address xanaliaDex;
  
  string[] test2;

  struct attributesInUri{
    string tokenUris;
    uint256 cost;
    uint256 attack;
    uint256 toughness;
    uint256 abilityCount;
    string element;
    string[] abilities;
    bool pureCheck;
  }

  struct rarity{
    mapping(uint256=>attributesInUri) attributes;
    uint256 count;
    }

  struct category{
    mapping(string=>rarity) rarityBasedUris;
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
  uint256 randomValueRarity;  
  string rarityValue;


  event CreateCategory(string name, string title,string description,string image, uint256 price, uint256 usdPrice, uint256 countNFT);
  event URIAddedToCat(string name, string rarity, string uri, uint256 count, uint256 cost, uint256 attack, uint256 toughness, string[] abilities, string element);
  event BuyBox(address buyer, string ownerId, string name, uint256 tokenIds, string tokenUri );
  event UpdateAllValueOfPack(string name, string title, string description, string image, uint256 price, uint256 usdPrice, uint256 count);

  // constructor(){
  //   ALIA = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
  //   xanaliaDex = 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1;
  //   LPAlia=IERC20(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
  //   LPBNB=IERC20(0xe230E414f3AC65854772cF24C061776A58893aC2);
  //   isInitialized1=true;
  // }

 function init1() public {
    require(!isInitialized1);
    // ALIA = IERC20(0xe1a4af407A124777A4dB6bB461b6F256c1f8E341);
    // xanaliaDex = 0xfE1a571eb3458d3aCf7d71bF0A78aC62DA537124;
    // LPAlia=IERC20(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
    // LPBNB=IERC20(0xe230E414f3AC65854772cF24C061776A58893aC2);
     ALIA = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
    xanaliaDex = 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1;
    LPAlia=IERC20(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
    LPBNB=IERC20(0xe230E414f3AC65854772cF24C061776A58893aC2);
    isInitialized1=true;
  }

  modifier adminAdd() {
      require(msg.sender == 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859);
      _;
  }

  function createCategory(string memory name, string memory title, string memory description, string memory image, uint256 price, uint256 usdPrice, uint256 countNFT) public adminAdd {
    require(price > 0 || usdPrice > 0, "Price or Price in usd should be greater than 0");
    require(countNFT > 0, "Count of NFTs should be greater then 0");
    require(Category[name].count == 0, "NFT name alreay present with token URIs");
    Category[name].title = title;
    Category[name].description = description;
    Category[name].image = image;
    Category[name].price = price;
    Category[name].usdPrice = usdPrice;
    Category[name].countNFT = countNFT;
    emit CreateCategory(name, Category[name].title, Category[name].description, Category[name].image, Category[name].price, Category[name].usdPrice, Category[name].countNFT);
  }

  function addUriToCategory(string memory name,string memory rarityInput, string memory uris, uint256 cost, uint256 attack, uint256 toughness, string[] memory abilities, string memory element) adminAdd public {
    require(Category[name].price > 0 || Category[name].usdPrice > 0, "Category not created");
    Category[name].rarityBasedUris[rarityInput].attributes[Category[name].count].tokenUris = uris;// test this
    Category[name].rarityBasedUris[rarityInput].attributes[Category[name].count].cost = cost;
    Category[name].rarityBasedUris[rarityInput].attributes[Category[name].count].attack = attack;
    Category[name].rarityBasedUris[rarityInput].attributes[Category[name].count].toughness = toughness;
    Category[name].rarityBasedUris[rarityInput].attributes[Category[name].count].abilities = abilities;
    Category[name].rarityBasedUris[rarityInput].attributes[Category[name].count].abilityCount = abilities.length;
    Category[name].rarityBasedUris[rarityInput].attributes[Category[name].count].element = element;
    Category[name].rarityBasedUris[rarityInput].attributes[Category[name].count].pureCheck = true;
    emit URIAddedToCat(name, rarityInput, uris,Category[name].rarityBasedUris[rarityInput].count, cost,attack,toughness, abilities, element);
    Category[name].rarityBasedUris[rarityInput].count++;
  }
  
  
  function updateAllValueOfPack(string memory name, string memory title,string memory description, string memory image, uint256 price, uint256 usdPrice, uint256 count ) public adminAdd {
    require(price > 0 || usdPrice > 0, "Price or Price in usd should be greater than 0");
    Category[name].title = title;
    Category[name].description = description;
    Category[name].image = image;
    Category[name].price = price;
    Category[name].usdPrice = usdPrice;
    Category[name].countNFT = count;
    emit UpdateAllValueOfPack(name, title, description, image, price, usdPrice, count);
  }
  

  function buyBox(address seller, string memory ownerId, string memory name) public {
    uint256 price = Category[name].price;
    if(price == 0){
      (uint112 _reserve0, uint112 _reserve1,) =LPBNB.getReserves();
           (uint112 reserve0, uint112 reserve1,) =LPAlia.getReserves();
           price = (Category[name].usdPrice * _reserve0 * reserve0) /(_reserve1 * reserve1);
    }
    IERC20(xanaliaDex).mintAliaForNonCrypto(price,msg.sender);
    uint256 tokenId;
    for(uint256 i =0; i<Category[name].countNFT; i++)
    {
    string memory returnedValue = weightGenerator(i+1);
    uint256 num = SafeMath.div(SafeMath.div(block.timestamp,block.number),i+2);
    randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, num))) % Category[name].rarityBasedUris[returnedValue].count;
    tokenId = IERC20(xanaliaDex).blindBox(seller, Category[name].rarityBasedUris[returnedValue].attributes[randomValue].tokenUris, true, msg.sender, ownerId);
    emit BuyBox(msg.sender, ownerId, name,tokenId,Category[name].rarityBasedUris[returnedValue].attributes[randomValue].tokenUris);
    }
    ALIA.transferFrom(msg.sender, 0x7712a69600587E48d73060Def272D3a37e078921 , price);
  }

  function getBoxDetail(string memory name) public view returns(string memory, string memory, uint256,uint256, uint256){
    return (Category[name].title, Category[name].description, Category[name].price,Category[name].usdPrice,Category[name].countNFT);
  }

function weightGenerator(uint256 Input) internal returns(string memory)  {
    uint256 num =SafeMath.div(SafeMath.div(block.timestamp,block.number),Input);
    randomValueRarity = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, num))) % 1000;
    if(randomValueRarity<=700) rarityValue = "common";
    else if(randomValueRarity>700 && randomValueRarity<=898) rarityValue = "unCommon"; 
    else if(randomValueRarity>898 && randomValueRarity<=944) rarityValue = "rare";
    else if(randomValueRarity>944 && randomValueRarity<=977) rarityValue = "doubleRare";
    else if(randomValueRarity>977 && randomValueRarity<=990) rarityValue = "trippleRare";
    else if(randomValueRarity>990 && randomValueRarity<=996) rarityValue = "superRare";
    else if(randomValueRarity>996 && randomValueRarity<=998) rarityValue = "hyperRare";
    else if(randomValueRarity==999) rarityValue = "ultraRare";
    return (rarityValue);
  }
 
}