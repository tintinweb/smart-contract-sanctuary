/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity ^0.5.0;


library SafeMath {
  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
   * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;
  address public manager;

  constructor() public {
    manager = 0xD70Ec4976401b93E585015668dB66c2d32e260f4;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "must be owner");
    _;
  }

  modifier onlyManager() {
    require(msg.sender == manager, "must be manager");
    _;
  }

  modifier onlyOwnerOrManager() {
    require((msg.sender == owner) || (msg.sender == manager), "must be owner or manager");
    _;
  }

}

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}

contract BEP20 is IERC20,Ownable {
  using SafeMath for uint;
  event tradeEvent(
    address indexed buyer,
    address indexed seller,
    uint256 level,
    uint256 amount,
    uint256 income,
    uint256 time,
    address referrer
  );
  event changeLevelMaxEvent(uint256 new_value,uint256 old_value);
  event destroyEvent(address indexed _user,uint256 _refund);
  event changeFeeEvent(uint256 new_fee,uint256 _old_fee);

  address constant WBNB_ADDRESS = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  uint256 constant REFERRAL_LIMIT = 3;

  uint256 level_max = 4;
  uint256 init_price = 0.06 ether;
  uint256 seed_sum = 0;
  uint256 fee = 0.01 ether;
  mapping(uint256 => uint256) level_price;
  mapping(uint256 => uint256) level_sum;

  struct UserStruct {
    bool isExist;
    uint256 id;
    uint256 referrerID;
    uint256 level;
    uint256 income;
    address[] referral;
  }

  mapping(address => UserStruct) public users;
  mapping(uint256 => address) public userList;
  uint256 public currUserID = 0;
  uint256 public tradingTotal = 0;
  uint256 public bnbTotal = 0;
  uint256 public createTime = 0;

  string public name;
  string public symbol;
  uint256 public decimals = 0;
  uint256 public totalSupply = 10 ** 9;
  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  IERC20 wbnb;

  modifier allowTrade() {
    require(level_max == 0 || msg.sender == owner, "disabled trade");
    _;
  }

  constructor(
    address _owner,
    string memory _name,
    string memory _symbol,
    uint256 _level_max,
    uint256 _price,
    uint256 _seed_sum
  ) public {
    require(_level_max == 4 || _level_max == 8,"level_max invalid");
    owner = _owner;
    name = _name;
    symbol = _symbol;
    level_max = _level_max;
    init_price = _price.mul(REFERRAL_LIMIT);
    if (_seed_sum >= REFERRAL_LIMIT) {
      seed_sum = _seed_sum;
    }
    balanceOf[owner] = totalSupply;

    for (uint256 i = 1; i <= 8; i++) {
      level_price[i] = init_price * (REFERRAL_LIMIT ** (i-1));
      level_sum[i] = 0;
    }

    UserStruct memory userStruct;
    currUserID++;

    userStruct = UserStruct({
      isExist: true,
      id: currUserID,
      referrerID: 0,
      level:level_max,
      income:0,
      referral: new address[](0)
    });
    users[owner] = userStruct;
    userList[currUserID] = owner;
    level_sum[userStruct.level] = 1;

    if(seed_sum>=REFERRAL_LIMIT){
      for(uint256 j = 1; j <= seed_sum; j++){
        currUserID++;
        address empty = address(j);
        users[empty] = UserStruct({
          isExist: true,
          id: currUserID,
          referrerID: userStruct.id,
          level:0,
          income:0,
          referral: new address[](0)
        });
        users[owner].referral.push(empty);
        userList[currUserID] = empty;
      }
    }

    createTime = _now(0);
    wbnb = IERC20(WBNB_ADDRESS);
  }

  function() external payable {
    if(level_max > 0){
      buy(msg.sender);
    }
  }

  function _approve(address from, address spender, uint value) internal {
    allowance[from][spender] = value;
    emit Approval(from, spender, value);
  }

  function _transfer(address from, address to, uint value) internal {
    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    emit Transfer(from, to, value);
  }

  function _transferFrom(address spender, address from, address to, uint value) internal {
    if (allowance[from][spender] != uint(-1)) {
      allowance[from][spender] = allowance[from][spender].sub(value);
    }
    _transfer(from, to, value);
  }

  function approve(address spender, uint value) external allowTrade returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  function transfer(address to, uint value) external allowTrade returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint value) external allowTrade returns (bool) {
    _transferFrom(msg.sender, from, to, value);
    return true;
  }

  function _trade(address buyer,address seller,uint256 level,address referrer) internal {
    uint256 amount = REFERRAL_LIMIT ** (level<=4 ? level : (level-4));
    uint256 income = level_price[level];
    uint256 _fee = msg.value.sub(income);

    users[seller].income = users[seller].income.add(income);
    users[buyer].level = level;
    bnbTotal = bnbTotal.add(income);
    tradingTotal++;
    level_sum[level] += 1;
    if(level>1 && level_sum[level-1]>0){
      level_sum[level-1] -= 1;
    }

    if(seller!=owner){
      _transfer(owner,seller,amount-1);
    }
    _transfer(seller,buyer,amount);

    address(uint160(seller)).transfer(income);
    if(_fee>0){
      address(uint160(manager)).transfer(_fee);
    }
    emit tradeEvent(buyer,seller,level,amount,income,_now(0),referrer);
  }

  function buy(address _user) public payable{
    if(users[_user].isExist){
      uint256 level = getLevel(msg.value);
      require(level == users[_user].level + 1 && level <= level_max,"level invalid");
      address seller = _findSeller(level,_user);
      _trade(_user,seller,level,address(0));
    }else{
      _register(_user,bytesToAddress(msg.data));
    }
  }

  function _register(address _user,address _referrer) internal {
    require(!isContract(_user),"disabled contract address");
    require(!users[_user].isExist, "user exists");
    require(users[_referrer].isExist,"referrer invalid");
    uint256 level = getLevel(msg.value);
    require(level == 1,"level invalid");
    uint256 refid = users[findFreeReferrer(_referrer)].id;
    UserStruct memory userStruct;
    currUserID++;

    userStruct = UserStruct({
      isExist: true,
      id: currUserID,
      referrerID: refid,
      level:level,
      income:0,
      referral: new address[](0)
    });
    users[_user] = userStruct;
    userList[currUserID] = _user;
    users[userList[refid]].referral.push(_user);
    address seller = _findSeller(level,_user);
    _trade(_user,seller,level,userList[refid]);
  }

  function agent(address _target, address _referrer) public payable {
    require(users[msg.sender].isExist,"");
    if (users[_target].isExist) {
      buy(_target);
    } else {
      _register(_target,_referrer);
    }
  }

  function destroy() public{
    require(
      level_max>0 && users[msg.sender].level == 1 && users[msg.sender].income == 0 && users[msg.sender].referrerID<=seed_sum+1,
      "disabled destroy"
    );
    require(REFERRAL_LIMIT == balanceOf[msg.sender],"disabled destroy");
    if(wbnb.transferFrom(owner,msg.sender,init_price)){
      _transfer(msg.sender,owner,balanceOf[msg.sender]);
      users[msg.sender].level = 0;
      emit destroyEvent(msg.sender,init_price);
    }else{
      revert("destory failure");
    }
  }

  function changeLevelMax(uint256 value) public onlyOwner {
    require(level_max!=value && level_max!=0,"value invalid");
    require(value==0 || value==4 || value==8,"value invalid");
    if(level_max==8 && value==4){
      revert("cannot be downgraded");
    }
    if(value!=0){
      users[owner].level = value;
    }
    uint256 old_value = level_max;
    level_max = value;
    emit changeLevelMaxEvent(level_max,old_value);
  }

  function changeFee(uint256 value) public onlyManager {
    uint256 _fee = fee;
    fee = value;
    emit changeFeeEvent(fee,_fee);
  }

  function _findSeller(uint256 _level, address _user) internal returns (address) {
    address seller;
    address referer1;
    address referer2;
    address referer3;
    if (_level == 1 || _level == 5) {
      seller = userList[users[_user].referrerID];
    } else if (_level == 2 || _level == 6) {
      referer1 = userList[users[_user].referrerID];
      seller = userList[users[referer1].referrerID];
    } else if (_level == 3 || _level == 7) {
      referer1 = userList[users[_user].referrerID];
      referer2 = userList[users[referer1].referrerID];
      seller = userList[users[referer2].referrerID];
    } else if (_level == 4 || _level == 8) {
      referer1 = userList[users[_user].referrerID];
      referer2 = userList[users[referer1].referrerID];
      referer3 = userList[users[referer2].referrerID];
      seller = userList[users[referer3].referrerID];
    }
    if (!users[seller].isExist) {
      seller = userList[1];
    }
    if (users[seller].level >= _level && balanceOf[seller] >= 1) {
      return seller;
    } else {
      return _findSeller(_level, seller);
    }
  }

  function findFreeReferrer(address _user) public view returns (address) {
    uint256 limit = REFERRAL_LIMIT;
    if (_user == owner) {
      limit = seed_sum;
    }
    if (users[_user].referral.length < limit) {
      return _user;
    }
    uint256 sum = 1;
    for (uint256 i = 0; i <= REFERRAL_LIMIT; i++) {
      sum += limit * (REFERRAL_LIMIT**i);
    }

    uint256 total = sum * REFERRAL_LIMIT;
    address[] memory referrals = new address[](total);

    for (uint256 i = 0; i < limit; i++) {
      referrals[i] = users[_user].referral[i];
    }

    uint256 skip = limit - REFERRAL_LIMIT;

    address freeReferrer;
    bool noFreeReferrer = true;

    for (uint256 i = 0; i < total; i++) {
      if (users[referrals[i]].referral.length == REFERRAL_LIMIT) {
        if (i < sum - 1) {
          for (uint256 j = 0; j < REFERRAL_LIMIT; j++) {
            referrals[(i + 1) * REFERRAL_LIMIT + j + skip] = users[
              referrals[i]
            ]
              .referral[j];
          }
        }
      } else {
        noFreeReferrer = false;
        freeReferrer = referrals[i];
        break;
      }
    }
    require(!noFreeReferrer, "no free referrer");
    return freeReferrer;
  }

  function viewUser(address _user)
    public
    view
    returns (
      uint256 id,
      address user,
      address referrer,
      uint256 level,
      uint256 income,
      address[] memory referrals,
      uint256 balance
    )
  {
    id = users[_user].id;
    level = users[_user].level;
    income = users[_user].income;
    referrer = userList[users[_user].referrerID];
    balance = balanceOf[_user];
    if(_user != owner || seed_sum==0){
      referrals = users[_user].referral;
    }
    return (
      id,
      _user,
      referrer,
      level,
      income,
      referrals,
      balance
    );
  }

  function viewExists(address _user) public view returns (bool) {
    return users[_user].isExist;
  }

  function viewSummary()
    public
    view
    returns (
      address _owner,
      address _manager,
      uint256 _currUserID,
      uint256 _tradingTotal,
      uint256 _bnbTotal,
      uint256 _fee,
      uint256 _level_max,
      uint256 _init_price,
      uint256 _seed_sum,
      uint256 _createTime,
      uint256[8] memory _prices,
      uint256[8] memory _levels
    )
  {
    uint256[8] memory prices = [uint256(0), 0, 0, 0, 0, 0, 0, 0];
    uint256[8] memory levels = [uint256(0), 0, 0, 0, 0, 0, 0, 0];
    for (uint256 k = 1; k <= level_max; k++) {
      prices[k - 1] = level_price[k];
      levels[k - 1] = level_sum[k];
    }

    return (
      owner,
      manager,
      currUserID,
      tradingTotal,
      bnbTotal,
      fee,
      level_max,
      init_price,
      seed_sum,
      createTime,
      prices,
      levels
    );
  }

  function getLevel(uint256 value) internal view returns (uint256) {
    uint256 level = 0;
    for (uint256 i = 1; i <= level_max; i++) {
      if (level_price[i] == value.sub(fee)) {
        level = i;
        break;
      }
    }
    return level;
  }

  function _now(uint value) internal view returns (uint) {
    //solium-disable-next-line
    uint v = block.timestamp;
    if(value != 0){
      v = v.add(value);
    }
    return v;
  }
  function bytesToAddress(bytes memory bys)
    private
    pure
    returns (address addr)
  {
    //solium-disable-next-line
    assembly {addr := mload(add(bys, 20))}
  }
  function isContract(address account) private view returns (bool) {
    uint256 size;
    //solium-disable-next-line
    assembly {
        size := extcodesize(account)
    }
    return size > 0;
  }

}