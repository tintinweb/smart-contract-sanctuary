pragma solidity ^0.4.24;

interface ERC721 /* is ERC165 */ {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owner {

  address public owner;

  /**
   * @dev set the owner of contract
   */
  constructor() public {
      owner = msg.sender;
  }

  /**
   * @dev only the owner
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

/**
 * @title GreedyCoin
 */
contract GreedyCoin is Owner,ERC721 {

  using SafeMath for uint256;

  // total supply
  uint16  constant ISSUE_MAX = 2100;

  // init price
  uint256 constant START_PRICE = 0.1 ether;

  // min price
  uint256 constant PRICE_MIN = 0.000000000000000001 ether;

  // max price
  uint256 constant PRICE_LIMIT = 100000000 ether;

  // percent of fee
  uint256 constant PROCEDURE_FEE_PERCENT = 10;

  // GreedyCoin token
  struct TokenGDC{
    bytes32 token_hash;
    uint256 last_deal_time;
    uint256 buying_price;
    uint256 price;
  }

  /**
   * @dev token structure
  */
  TokenGDC[] stTokens;

  /**
   * @dev owner of tokens ( index => address )
  */
  mapping (uint256 => address) stTokenIndexToOwner;

  /**
   * @dev GreedyCoin count of one address
  */
  mapping (address => uint256) stOwnerTokenCount;

  /**
   * @dev set transfer token permission
  */
  mapping (uint256 => address) stTokenApprovals;

  /**
  * @dev set approved address
  */
  mapping (address => mapping (address => bool) ) stApprovalForAll;


  /*
   * @dev (ERC721)
   */
  function balanceOf(address owner) external view returns (uint256 balance){
    balance = stOwnerTokenCount[owner];
  }
  
  /**
   * @dev query the owner of one GreedyCoin
   */
  function ownerOf(uint256 token_id) external view returns (address owner){
    owner = stTokenIndexToOwner[token_id];
  }

  /**
   * @dev transfer from
   */
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
    require(msg.sender == _from);
    require(_to != address(0));
    require(_tokenId >= 0 && _tokenId < ISSUE_MAX - 1);
    _transfer(_from, _to, _tokenId);
  }

  /**
   * @dev approve before transfer
   */
  function approve(address to, uint256 token_id) external payable {
    require(msg.sender == stTokenIndexToOwner[token_id]);
    stTokenApprovals[token_id] = to;
    emit Approval(msg.sender, to, token_id);
  }

  /**
   * @dev get approve
   */
  function getApproved(uint256 _tokenId) external view returns (address){
    return stTokenApprovals[_tokenId];
  }

  /**
   * @dev setApprovalForAll
   */
  function setApprovalForAll(address _operator, bool _approved) external {
    stApprovalForAll[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @dev isApprovedForAll
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return stApprovalForAll[_owner][_operator] == true;
  }

  /**
   * @dev _transfer
   */
  function _transfer(address from, address to, uint256 token_id) private {
    require(stTokenApprovals[token_id] == to || stApprovalForAll[from][to]);
    stOwnerTokenCount[to] = stOwnerTokenCount[to].add(1);
    stOwnerTokenCount[msg.sender] = stOwnerTokenCount[msg.sender].sub(1);
    stTokenIndexToOwner[token_id] = to;
    emit Transfer(from, to, token_id);
  }

  /**
   * @dev query detail of one GreedyCoin
   */
  function queryToken(uint256 _tokenId) external view returns ( uint256 price, uint256 last_deal_time ) {
    TokenGDC memory token = stTokens[_tokenId];
    price = token.price;
    last_deal_time = token.last_deal_time;
  }


  /**
   * @dev get all GreedyCoins of msg.sender
   */
  function getMyTokens() external view returns ( uint256[] arr_token_id, uint256[] arr_last_deal_time, uint256[] buying_price_arr, uint256[] price_arr ){

    TokenGDC memory token;

    uint256 count = stOwnerTokenCount[msg.sender];
    arr_last_deal_time = new uint256[](count);
    buying_price_arr = new uint256[](count);
    price_arr = new uint256[](count);
    arr_token_id = new uint256[](count);

    uint256 index = 0;
    for ( uint i = 0; i < stTokens.length; i++ ){
      if ( stTokenIndexToOwner[i] == msg.sender ) {
        token = stTokens[i];
        arr_last_deal_time[index] = token.last_deal_time;
        buying_price_arr[index] = token.buying_price;
        price_arr[index] = token.price;
        arr_token_id[index] = i;
        index = index + 1;
      }
    }
  }
}

contract Market is GreedyCoin {

  using SafeMath for uint256;

  event Bought (address indexed purchaser,uint256 indexed token_price, uint256 indexed next_price);
  event HitFunds (address indexed purchaser,uint256 indexed funds, uint256 indexed hit_time);
  event Recommended (address indexed recommender, uint256 indexed agency_fee);

  // buy (only accept normal address)
  function buy(uint256 next_price, bool is_recommend, uint256 recommend_token_id) external payable mustCommonAddress {

    require (next_price >= PRICE_MIN && next_price <= PRICE_LIMIT);

    _checkRecommend(is_recommend,recommend_token_id);
    if (stTokens.length < ISSUE_MAX ){
      _buyAndCreateToken(next_price,is_recommend,recommend_token_id);
    } else {
      _buyFromMarket(next_price,is_recommend,recommend_token_id);
    }
  }

  // query current blance of fees
  function queryCurrentContractFunds() external view returns (uint256) {
    return (address)(this).balance;
  }

  // query the lowest price
  function queryCurrentTradablePrice() external view returns (uint256 token_id,uint256 price) {
    if (stTokens.length < ISSUE_MAX){
      token_id = stTokens.length;
      price = START_PRICE;
    } else {
      token_id = _getCurrentTradableToken();
      price = stTokens[token_id].price;
    }
  }

  // get the cheapest GreedyCoin
  function _getCurrentTradableToken() private view returns(uint256 token_id) {
    uint256 token_count = stTokens.length;
    uint256 min_price = stTokens[0].price;
    token_id = 0;
    for ( uint i = 0; i < token_count; i++ ){
      // token = stTokens[i];
      uint256 price = stTokens[i].price;
      if (price < min_price) {
        // token = stTokens[i];
        min_price = price;
        token_id = i;
      }
    }
  }

  // create GreedyCoin
  function _buyAndCreateToken(uint256 next_price, bool is_recommend, uint256 recommend_token_id ) private {

    require( msg.value >= START_PRICE );

    // create
    uint256 now_time = now;
    uint256 token_id = stTokens.length;
    TokenGDC memory token;
    token = TokenGDC({
      token_hash: keccak256(abi.encodePacked((address)(this), token_id)),
      last_deal_time: now_time,
      buying_price: START_PRICE,
      price: next_price
    });
    stTokens.push(token);

    stTokenIndexToOwner[token_id] = msg.sender;
    stOwnerTokenCount[msg.sender] = stOwnerTokenCount[msg.sender].add(1);

    // 10% fee
    uint256 current_fund = START_PRICE.div(100 / PROCEDURE_FEE_PERCENT);

    // hash of GreedyCoin
    bytes32 current_token_hash = token.token_hash;

    owner.transfer( START_PRICE - current_fund );

    // if get all fees
    _gambling(current_fund, current_token_hash, now_time);

    // recommendation
    _awardForRecommender(is_recommend, recommend_token_id, current_fund);

    _refund(msg.value - START_PRICE);

    // emit event
    emit Bought(msg.sender, START_PRICE, next_price);

  }

// buy GreedyCoin from each other,after all GreedyCoins has been created
  function _buyFromMarket(uint256 next_price, bool is_recommend, uint256 recommend_token_id ) private {

    uint256 current_tradable_token_id = _getCurrentTradableToken();
    TokenGDC storage token = stTokens[current_tradable_token_id];

    uint256 current_token_price = token.price;

    bytes32 current_token_hash = token.token_hash;

    uint256 last_deal_time = token.last_deal_time;

    require( msg.value >= current_token_price );

    uint256 refund_amount = msg.value - current_token_price;

    token.price = next_price;

    token.buying_price = current_token_price;

    token.last_deal_time = now;

    address origin_owner = stTokenIndexToOwner[current_tradable_token_id];

    stOwnerTokenCount[origin_owner] =  stOwnerTokenCount[origin_owner].sub(1);

    stOwnerTokenCount[msg.sender] = stOwnerTokenCount[msg.sender].add(1);

    stTokenIndexToOwner[current_tradable_token_id] = msg.sender;

    uint256 current_fund = current_token_price.div(100 / PROCEDURE_FEE_PERCENT);

    origin_owner.transfer( current_token_price - current_fund );

    _gambling(current_fund, current_token_hash, last_deal_time);

    _awardForRecommender(is_recommend, recommend_token_id, current_fund);

    _refund(refund_amount);

    emit Bought(msg.sender, current_token_price, next_price);
  }

  function _awardForRecommender(bool is_recommend, uint256 recommend_token_id, uint256 current_fund) private {

    if ( is_recommend && stTokens.length >= recommend_token_id) {

      address recommender = stTokenIndexToOwner[recommend_token_id];

      // 50% of fee
      uint256 agency_fee = current_fund.div(2);

      recommender.transfer(agency_fee);

      emit Recommended(recommender,agency_fee);
    }
  }

  function _refund(uint256 refund_amount) private {
    if ( refund_amount > 0 ) {
      msg.sender.transfer(refund_amount);
    }
  }

  // 10% change of getting all blance of fees
  function _gambling(uint256 current_fund, bytes32 current_token_hash, uint256 last_deal_time) private {

    // random 0 - 99
    uint256 random_number = _createRandomNumber(current_token_hash,last_deal_time);

    if ( random_number < 10 ) {

      // contract address
      address contract_address = (address)(this);

      uint256 hit_funds = contract_address.balance.sub(current_fund);

      msg.sender.transfer(hit_funds);

      emit HitFunds(msg.sender, hit_funds, now);
    }
  }

  function _createRandomNumber(bytes32 current_token_hash, uint256 last_deal_time) private pure returns (uint256) {
    return (uint256)(keccak256(abi.encodePacked(current_token_hash, last_deal_time))) % 100;
  }

  function _checkRecommend(bool is_recommend, uint256 recommend_token_id) private view {
    if ( is_recommend ) {
      if ( stTokens.length > 0 ) {
        require(recommend_token_id >= 0 && recommend_token_id < stTokens.length);
      } 
    }
  }

  modifier aboveMinNextPrice(uint next_price) { 
    require (next_price >= PRICE_MIN && next_price <= PRICE_LIMIT);
    _;
  }

  // must be a normal address
  modifier mustCommonAddress() { 
    require (_isContract(msg.sender) == false);
    _; 
  }

  // check if it is the address of contract
  function _isContract(address addr) private view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}