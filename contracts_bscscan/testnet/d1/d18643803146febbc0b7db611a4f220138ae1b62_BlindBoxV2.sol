/**
 *Submitted for verification at BscScan.com on 2021-08-24
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

    function blindBox(address seller, string calldata tokenURI, bool flag, address to, string calldata ownerId) external returns (uint256);
    function mintAliaForNonCrypto(uint256 price, address from) external returns (bool);
    function nonCryptoNFTVault() external returns(address);
    function mainPerecentage() external returns(uint256);
    function authorPercentage() external returns(uint256);
    function platformPerecentage() external returns(uint256);
    function updateAliaBalance(string calldata stringId, uint256 amount) external returns(bool);
    
    //Revenue share
    function addNonCryptoAuthor(string calldata artistId, uint256 tokenId, bool _isArtist) external returns(bool);
    function tranferAliaArtist(address buyer, uint256 price, address nftVaultAddress, uint256 tokenId ) external returns(bool);
    function checkArtistOwner(string calldata artistId, uint256 tokenId) external returns(bool);
    function checkTokenAuthorIsArtist(uint256 tokenId) external returns(bool);
    function getRandomNumber() external returns (bytes32);
    function getRandomVal() external returns (uint256);
}

// File: contracts/NFTInterface.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface NFTInterface {
    /**
     * @dev Returns the amount of tokens in existence.
     */

    function blindBox(address to, string calldata tokenURI,uint256 quantity, bool flag, string calldata ownerId) external returns (uint256);
    function mintAliaForNonCrypto(uint256 price, address from) external returns (bool);
    function nonCryptoNFTVault() external view returns(address);
    function mainPerecentage() external returns(uint256);
    function authorPercentage() external returns(uint256);
    function platformPerecentage() external returns(uint256);
    function updateAliaBalance(string calldata stringId, uint256 amount) external returns(bool);
}

// File: contracts/LPInterface.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface LPInterface {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

   
}

// File: contracts/BlindBoxLive.sol

pragma solidity ^0.8.0;




contract BlindBoxV2 {

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
  mapping (uint256 => string) _nonCryptoAuthor;
  mapping (string => bool) isArtist;
  struct agent {
    string id;
    address _address;
    uint256 percentage;
  }
  struct percentages {
    uint256  artistPercentage;
    uint256  companyPercentage;
    uint256 count;
    mapping(uint256 => agent) _agents;
  }
  
  mapping (string => percentages) _artistDetails;
  address companyAddress;
  
  event CreateCategory(string name, string title,string description,string image, uint256 price, uint256 usdPrice, uint256 countNFT, string detailHash);
  event URIAdded(string name, string uri, uint256 count);
  event BuyBox(address buyer, string ownerId, string name, uint256 tokenIds );
  event UpdateAllValueOfPack(string name, string title, string description, string image, uint256 price, uint256 usdPrice, uint256 count, string detailHash);
  event AddAgent(uint256 index,string agentId, address _agentAddress, string artistId, uint256 _percentage,uint256 _companyPercentage, uint256 _artistPercentage);
  event EditAgent(uint256 index,string agentId, address _agentAddress, string artistId, uint256 _percentage,uint256 _companyPercentage, uint256 _artistPercentage);
  event RemoveAgent(uint256 index, string artistId);
  event UpdateCompanyPercentage(uint256 _artistPercentage, uint256 _companyPercentage, string artistId);
  constructor() public{
    // ALIA = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
    // xanaliaDex = 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1;
    // LPAlia=IERC20(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
    // LPBNB=IERC20(0xe230E414f3AC65854772cF24C061776A58893aC2);
    // isInitialized1=true;
  }

 function init1() public {
    require(!isInitialized1);
      ALIA = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
    xanaliaDex = 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1;
    LPAlia=IERC20(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
    LPBNB=IERC20(0xe230E414f3AC65854772cF24C061776A58893aC2);
    isInitialized1=true;
  }
  function init2() public {
    companyAddress = 0xa6b714Fc6984649Ca0EED016F0b55d1b87f2CdBc;
  }
  IERC20 chainRan;
  bool private isInitialized3;
  uint256 randomValueMain;
  function init3() public {
    require(!isInitialized3);
    isInitialized3=true;
    chainRan = IERC20(0x343AC8e237f9588b06568f8adA361b9F8a475A26);
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
    emit UpdateAllValueOfPack(name, title, description, image, price, usdPrice, count, detailHash);
  }
  

  function buyBox(address seller, string memory ownerId, string memory name) public {
    uint256 price = Category[name].price;
    if(price == 0){
      (uint112 _reserve0, uint112 _reserve1,) =LPBNB.getReserves();
           (uint112 reserve0, uint112 reserve1,) =LPAlia.getReserves();
           price = (Category[name].usdPrice * reserve0 * _reserve0) /(reserve1 * _reserve1);
           //SafeMath.div(SafeMath.mul(Category[name].usdPrice,reserve1),SafeMath.mul(reserve0,1000000000000));
           //(Category[name].usdPrice * reserve0) /(reserve1);
    }
    IERC20(xanaliaDex).mintAliaForNonCrypto(price,msg.sender);
    uint256 tokenId;
    chainRan.getRandomNumber();
    for(uint256 i =0; i<Category[name].countNFT; i++)
    {
    //uint256 num = SafeMath.div(SafeMath.div(block.timestamp,block.number),i+1);
    // randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, num))) % Category[name].count;
    randomValueMain = chainRan.getRandomVal();
    tokenId = IERC20(xanaliaDex).blindBox(seller, Category[name].tokenUris[(uint256(keccak256(abi.encode(randomValueMain, i))) % Category[name].count)], true, msg.sender, ownerId);
    emit BuyBox(msg.sender, ownerId, name,tokenId);
    }
    ALIA.transferFrom(msg.sender, 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859, price);
  }

  function getBoxDetail(string memory name) public view returns(string memory, string memory, uint256,uint256, uint256){
    return (Category[name].title, Category[name].description, Category[name].price,Category[name].usdPrice,Category[name].countNFT);
  }

  function addAgent(string memory agentId, address _agentAddress, string memory artistId, uint256 _percentage, uint256 _companyPercentage, uint256 _artistPercentage) adminAdd public {
    require(_artistDetails[artistId].count < 5, "limit reached");
    _artistDetails[artistId].count++;
    uint256 index = _artistDetails[artistId].count;
    _artistDetails[artistId]._agents[ index] = agent(agentId, _agentAddress, _percentage);
    if(_agentAddress == address(0x0)){
      _artistDetails[artistId]._agents[ index]._address = NFTInterface(xanaliaDex).nonCryptoNFTVault();
    }
    _artistDetails[artistId].artistPercentage = _artistPercentage;
    _artistDetails[artistId].companyPercentage = _companyPercentage;
    if(!isArtist[artistId]){
      isArtist[artistId]=true;
    }
    emit AddAgent(index, agentId, _agentAddress, artistId, _percentage, _companyPercentage, _artistPercentage);
  }
  function editAgent(uint256 index,string memory agentId, address _agentAddress, string memory artistId, uint256 _percentage, uint256 _companyPercentage, uint256 _artistPercentage) adminAdd public {
    require(_artistDetails[artistId].count >= index && index > 0, "not valid index");
    _artistDetails[artistId]._agents[index] = agent(agentId, _agentAddress, _percentage);
    if(_agentAddress == address(0x0)){
      _artistDetails[artistId]._agents[ index]._address = NFTInterface(xanaliaDex).nonCryptoNFTVault();
    }
    _artistDetails[artistId].artistPercentage = _artistPercentage;
    _artistDetails[artistId].companyPercentage = _companyPercentage;
    emit EditAgent(index,agentId, _agentAddress, artistId, _percentage, _companyPercentage, _artistPercentage);
  }
  function removeAgent(uint256 index, string memory artistId) adminAdd public {
    _artistDetails[artistId].artistPercentage = _artistDetails[artistId].artistPercentage + _artistDetails[artistId]._agents[index].percentage;
    for(uint256 i = index; i < _artistDetails[artistId].count; i++ ){
      _artistDetails[artistId]._agents[i] = _artistDetails[artistId]._agents[i+1];
    }
    delete _artistDetails[artistId]._agents[_artistDetails[artistId].count];
    _artistDetails[artistId].count--;
    emit RemoveAgent(index, artistId);
  }

  function getAgent(uint256 index, string memory artistId) view public returns (string memory, address, uint256) {
    agent storage temp = _artistDetails[artistId]._agents[index];
    return (temp.id, temp._address, temp.percentage);
  }
  function getPercentagesAndCount(string memory artistId) view public returns(uint256,uint256,uint256) {
    percentages storage temp = _artistDetails[artistId];
    return (temp.artistPercentage,temp.companyPercentage,temp.count );
  }

  function addNonCryptoAuthor(string calldata artistId, uint256 tokenId, bool _isArtist) external returns(bool) {
    require(msg.sender == xanaliaDex);
      _nonCryptoAuthor[tokenId] = artistId; 
      isArtist[artistId]= _isArtist;
      if(_isArtist && _artistDetails[artistId].artistPercentage == 0){
      _artistDetails[artistId].artistPercentage = 975;
      }
    return true;
  }

  function tranferAliaArtist(address buyer, uint256 price, address nftVaultAddress, uint256 tokenId ) external returns(bool) {
    require(msg.sender == xanaliaDex, "not nft address");
    // string storage artistId = _nonCryptoAuthor[tokenId];
    ALIA.transferFrom(buyer, nftVaultAddress, (price * _artistDetails[_nonCryptoAuthor[tokenId]].artistPercentage)/1000);
    NFTInterface(xanaliaDex).updateAliaBalance(_nonCryptoAuthor[tokenId], (price * _artistDetails[_nonCryptoAuthor[tokenId]].artistPercentage)/1000);
      ALIA.transferFrom(buyer, companyAddress, (price * _artistDetails[_nonCryptoAuthor[tokenId]].companyPercentage)/1000);
      for(uint256 i =1; i <= _artistDetails[_nonCryptoAuthor[tokenId]].count; i++){
        ALIA.transferFrom(buyer, _artistDetails[_nonCryptoAuthor[tokenId]]._agents[i]._address, (price * _artistDetails[_nonCryptoAuthor[tokenId]]._agents[i].percentage)/1000);
        if(_artistDetails[_nonCryptoAuthor[tokenId]]._agents[i]._address == nftVaultAddress){
          NFTInterface(xanaliaDex).updateAliaBalance(_artistDetails[_nonCryptoAuthor[tokenId]]._agents[i].id,(price * _artistDetails[_nonCryptoAuthor[tokenId]]._agents[i].percentage)/1000);
        }
      }
    return true;
  }


  function getNonCryptoAuthor(uint256 tokenId) public view returns(string memory) {
    return _nonCryptoAuthor[tokenId];
  }

  function checkTokenAuthorIsArtist(uint256 tokenId) public view returns(bool) {
    return  isArtist[_nonCryptoAuthor[tokenId]];
  }
  function checkArtistOwner(string memory artistId, uint256 tokenId) public view returns(bool) {
    return  keccak256(abi.encodePacked((_nonCryptoAuthor[tokenId]))) == keccak256(abi.encodePacked((artistId)));
  }
  function updateCompanyPercentage(uint256 _artistPercentage, uint256 _companyPercentage, string memory artistId) public {
    _artistDetails[artistId].artistPercentage = _artistPercentage;
    _artistDetails[artistId].companyPercentage = _companyPercentage;
    if(!isArtist[artistId]){
      isArtist[artistId]=true;
    }
    emit UpdateCompanyPercentage(_artistPercentage, _companyPercentage, artistId);
  }
  function allArtistAgentPercentages(string memory artistId)public view returns(uint256) {
    uint256 agentPercentagesSum = 0;
    for(uint256 i = 1; i <= _artistDetails[artistId].count; i++){
      agentPercentagesSum += _artistDetails[artistId]._agents[i].percentage;
    }
    return agentPercentagesSum;
  }

  function addExistingNonCryptoAuthors(string[] memory ownerId, uint256[] memory tokenId) public adminAdd {
    for (uint256 i =0; i< tokenId.length; i++){
      _nonCryptoAuthor[tokenId[i]] = ownerId[i];
    }
  }
}