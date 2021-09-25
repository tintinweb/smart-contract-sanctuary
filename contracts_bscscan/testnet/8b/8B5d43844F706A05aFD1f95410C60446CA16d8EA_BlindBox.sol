/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/IERC20.sol

pragma solidity ^0.5.0;

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
    function mint(address recipient, uint256 amount) external returns(bool);
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
    function registerAddressBlindbox(address _address, string calldata name) external;
    function blindBox(address seller, string calldata tokenURI, bool flag, address to, string calldata ownerId, string calldata boxName) external returns (uint256);
    function mintAliaForNonCrypto(uint256 price, address from) external returns (bool);
    // Revenue share
    function getRandomNumber() external returns (bytes32);
    function getRandomVal() external returns (uint256);
    
}

// File: contracts/BlindBoxLiveV2.sol

pragma solidity 0.5.0;



contract BlindBox {

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
  struct categoryDetail{  
    string hash;  
  } 
  mapping(string=>categoryDetail) private CategoryDetail;
  using SafeMath for uint112;
  IERC20 chainRan;
  bool private isInitialized2;
  uint256 randomValueMain;
  uint256 deployTime;
  // string tempUri;
  bool private isInitialized3;
  struct soldDetails{
    uint256 count;
    bool isSold;
  }
  struct BoxDetails {
    uint256 initialize;
    uint256 dailiyLimit;
    mapping (uint256=>soldDetails) usedCountByday;
    mapping (string => uint256) tokenUriUsedCount;
    mapping (uint256 => mapping(uint256 => bool)) luckyBox;
    mapping (uint256=> uint256) dailyUsersCount;
  }
  mapping (string=> BoxDetails) boxDetails;

  event CreateCategory(string name, string title,string description,string image, uint256 price, uint256 usdPrice, uint256 countNFT, string detailHash, address revenueAddress);
  event URIAdded(string name, string uri, uint256 count);
  event BuyBox(address buyer, string ownerId, string name, uint256 tokenIds );
  event UpdateAllValueOfPack(string name, string title, string description, string image, uint256 price, uint256 usdPrice, uint256 count, string detailHash);
  event AddAgent(uint256 index,string agentId, address _agentAddress, string artistId, uint256 _percentage,uint256 _artistPercentage);
  event EditAgent(uint256 index,string agentId, address _agentAddress, string artistId, uint256 _percentage,uint256 _artistPercentage);
  event RemoveAgent(uint256 index, string artistId);
  event UpdateCompanyPercentage(uint256 _artistPercentage, uint256 _companyPercentage, string artistId);
  event TokenUriUsed(string name, string tokenUri, uint256 index);
  constructor() public{
    ALIA = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
    // xanaliaDex = 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1;
    LPAlia=IERC20(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
    LPBNB=IERC20(0xe230E414f3AC65854772cF24C061776A58893aC2);
    isInitialized1=true;
    isInitialized2=true;
    chainRan = IERC20(0x343AC8e237f9588b06568f8adA361b9F8a475A26);
  }
 
  function init1() public {
    require(!isInitialized1);
    ALIA = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
    // xanaliaDex = 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1;
    LPAlia=IERC20(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
    LPBNB=IERC20(0xe230E414f3AC65854772cF24C061776A58893aC2);
    isInitialized1=true;
  }
  function init2() public {
    require(!isInitialized2);
    isInitialized2=true;
    chainRan = IERC20(0x343AC8e237f9588b06568f8adA361b9F8a475A26);
  }

  function init3() public  adminAdd{
    require(isInitialized2 && !isInitialized3, "already initialized");
    isInitialized3=true;
    deployTime = now;
    chainRan.getRandomNumber();
  }


  modifier adminAdd() {
      require(msg.sender == 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859);
      _;
  }

  function createCategory(string memory name, string memory title, string memory description, string memory image, uint256 price, uint256 usdPrice, uint256 countNFT, string memory detailHash, address _address) public adminAdd {
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
    IERC20(xanaliaDex).registerAddressBlindbox(_address, name);
    emit CreateCategory(name, title, description, image, price, usdPrice,countNFT, detailHash, _address);
  }

  function addUriToCategory(string memory name,string memory uris) adminAdd public {
    require(Category[name].price > 0 || Category[name].usdPrice > 0, "Category not created");
    Category[name].tokenUris[Category[name].count] = uris;
    emit URIAdded(name, uris,Category[name].count);
    Category[name].count++;
  }
  function updateAllValueOfPack(string memory name, string memory title,string memory description, string memory image, uint256 price, uint256 usdPrice, uint256 count, string memory detailHash) public adminAdd {
    require(price > 0 || usdPrice > 0, "Price or Price in usd should be greater than 0");
    Category[name].title = title;
    Category[name].description = description;
    Category[name].image = image;
    Category[name].price = price;
    Category[name].usdPrice = usdPrice;
    Category[name].countNFT = count;
    CategoryDetail[name].hash = detailHash; 
    // IERC20(xanaliaDex).registerAddressBlindbox(_address, name);
    emit UpdateAllValueOfPack(name, title, description, image, price, usdPrice, count, detailHash);
  }
  function removeTokenUri (string memory name, uint256 index) adminAdd public {
    require(index >= 0 && index < Category[name].count,"Invalid index");
    emit TokenUriUsed(name, Category[name].tokenUris[index], index);
     Category[name].tokenUris[index] = Category[name].tokenUris[Category[name].count];
     delete Category[name].tokenUris[Category[name].count];
     Category[name].count--;
  }
  function initializeBox(string memory name,uint256 _time) adminAdd public {
    if(boxDetails[name].initialize == 0){
      uint256 counter;
      for(uint256 i = 0; i < 3; i++){
       for (uint256 j = 0; j < 10 || (i ==2 && j < 11); j++) {
          randomValueMain = chainRan.getRandomVal();
          uint256 randNumber =  (uint256(keccak256(abi.encode(randomValueMain, (block.timestamp + counter++ )))) % (i ==2 ? 110 : 100));
          boxDetails[name].luckyBox[i][randNumber] = true;
        }
      }
    }
    boxDetails[name].initialize = _time;
    boxDetails[name].dailiyLimit = 10;
  }

  function buyBox(address seller, string memory ownerId, string memory name, uint256 selectedTime, bool isPaid) public {
    uint256 dayCount = ((selectedTime > 0 ? selectedTime : block.timestamp ) - boxDetails[name].initialize)/(60 * 30);
    require(Category[name].count > 0, "No NFT");
    require(!boxDetails[name].usedCountByday[dayCount].isSold,"Box soldout");
    require(boxDetails[name].initialize < block.timestamp, "Box not available");
    require(dayCount < Category[name].count / boxDetails[name].dailiyLimit, "Box expired");
    if(boxDetails[name].usedCountByday[dayCount].count == 0) {
      boxDetails[name].usedCountByday[dayCount].count = dayCount == ((Category[name].count / boxDetails[name].dailiyLimit) -1) ? (boxDetails[name].dailiyLimit + Category[name].count % boxDetails[name].dailiyLimit) : boxDetails[name].dailiyLimit;
    }
    uint256 price = Category[name].price;
    if(price == 0){
      (uint112 _reserve0, uint112 _reserve1,) =LPBNB.getReserves();
      (uint112 reserve0, uint112 reserve1,) =LPAlia.getReserves();
      price = (Category[name].usdPrice * reserve0 * _reserve0) /(reserve1 * _reserve1);
    }
    bool isLucky = boxDetails[name].luckyBox[dayCount][boxDetails[name].dailyUsersCount[dayCount]];
    require(isLucky || (!isLucky && isPaid), "BuyBox error");
    boxDetails[name].dailyUsersCount[dayCount]++;
    !isLucky && IERC20(xanaliaDex).mintAliaForNonCrypto(price,msg.sender);
    uint256 tokenId = 0;
     timeTester();
    for(uint256 i =0; i<Category[name].countNFT; i++)
    {
     randomValueMain = chainRan.getRandomVal();
     uint256 randNumber = (boxDetails[name].dailiyLimit * dayCount) + (uint256(keccak256(abi.encode(randomValueMain, (block.timestamp +i)))) % boxDetails[name].usedCountByday[dayCount].count);
     tokenId = IERC20(xanaliaDex).blindBox(seller, Category[name].tokenUris[randNumber], true, msg.sender, ownerId, name);
     boxDetails[name].tokenUriUsedCount[Category[name].tokenUris[randNumber]]++;
     if(boxDetails[name].tokenUriUsedCount[Category[name].tokenUris[randNumber]] == 5){
      
      emit TokenUriUsed(name, Category[name].tokenUris[randNumber], randNumber);
      Category[name].tokenUris[randNumber] = Category[name].tokenUris[boxDetails[name].usedCountByday[dayCount].count];
      boxDetails[name].usedCountByday[dayCount].count--;
      if(boxDetails[name].usedCountByday[dayCount].count == 1){
        boxDetails[name].usedCountByday[dayCount].isSold = true;
        boxDetails[name].usedCountByday[dayCount].count = 0;
      }
     }
     emit BuyBox(msg.sender, ownerId, name,tokenId);
    }
    !isLucky && ALIA.transferFrom(msg.sender, 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859, price);
  }
  function timeTester() internal {
    if(deployTime+ 24 hours <= block.timestamp)
    {
      deployTime = block.timestamp;
      chainRan.getRandomNumber();
    }
  }

  function getBoxDetail(string memory name, uint256 selectedTime) public view returns(uint256, uint256, uint256,uint256, uint256, bool, uint256){
    return (Category[name].count, boxDetails[name].dailiyLimit, Category[name].price,Category[name].usdPrice,Category[name].countNFT, isBoxSold(selectedTime, name), boxDetails[name].initialize);
  }

  function getCountByTime(uint256 selectedTime, string memory name) public view returns(uint256, uint256) {
    uint256 dayCount = ((selectedTime > 0 ? selectedTime : block.timestamp ) - boxDetails[name].initialize)/(60 * 30);
    return (boxDetails[name].usedCountByday[dayCount].count, dayCount);
  }
  function isBoxSold(uint256 selectedTime, string memory name) public view returns(bool) {
    uint256 dayCount = ((selectedTime > 0 ? selectedTime : block.timestamp ) - boxDetails[name].initialize)/(60 * 30);
    return Category[name].count == 0 || boxDetails[name].usedCountByday[dayCount].isSold || boxDetails[name].initialize >= block.timestamp || !(boxDetails[name].dailiyLimit > 0 && dayCount < Category[name].count / boxDetails[name].dailiyLimit) ;
  }
  function isExpire(uint256 selectedTime, string memory name) public view returns(bool) {
    uint256 dayCount = ((selectedTime > 0 ? selectedTime : block.timestamp ) - boxDetails[name].initialize)/(60 * 30);
    return dayCount >= Category[name].count / boxDetails[name].dailiyLimit;
  }
  function isOnSell(uint256 selectedTime, string memory name) public view returns(bool) {
    return boxDetails[name].initialize >= ( selectedTime > 0 ? selectedTime : block.timestamp);
    
  }
  function getBoxDetailsNonCrypto(string memory name, uint256 selectedTime) adminAdd public view returns(bool) {
    uint256 dayCount = ((selectedTime > 0 ? selectedTime : block.timestamp ) - boxDetails[name].initialize)/(60 * 30);
    return  boxDetails[name].luckyBox[dayCount][boxDetails[name].dailyUsersCount[dayCount]];    
  }

}