pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) { return 0; }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Manageable {

  address public owner;
  address public manager;
  bool public contractLock;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event ContractLockChanged(address admin, bool state);

  constructor() public {
    owner = msg.sender;
    contractLock = false;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier isUnlocked() {
    require(!contractLock);
    _;
  }

  function transferOwner(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  function setContractLock(bool setting) public onlyOwner {
    contractLock = setting;
    emit ContractLockChanged(msg.sender, setting);
  }

  function _addrNotNull(address _to) internal pure returns (bool) {
    return(_to != address(0));
  }
}


contract InvitherC is Manageable {
/*********level A**********************************************/
  using SafeMath for uint256;

/********************************************** EVENTS **********************************************/
  event AddUser(address user_address,  uint256 user_id, uint256 parent_id);
  event Reward(address user_address, uint256 user_id, uint256 reward_amount);
  event Init();
/****************************************************************************************************/

/********************************************** STRUCTS *********************************************/
  struct User {
    address user_address;
    uint256 parent_id;
    uint256[5] childs;
    bool isFull;
  }

/*********************************************** VARS ***********************************************/

  mapping(uint256 => User) private usersMap;
  bool public initDone = false;
  uint256 public userCount = 0;
  uint256 public price = 1000000000000000000;
  address commissioner = 0xfe9313E171C441db91E3604F75cA58f13AA0Cb23;
/****************************************************************************************************/


  function init() public onlyOwner {
    require(!initDone);
    initDone = true;
    uint256 child = 0;
    usersMap[0] = User({user_address: owner, parent_id: 0, childs:[child, child, child, child, child], isFull: false});  // solhint-disable-line max-line-length
    userCount=1;
    emit Init();
  }
    
  function _addUser(address user_address) private returns (uint256) {
    for (uint256 i=0; i<userCount; i++){
      if (!usersMap[i].isFull){
        for (uint256 j=0; j<5; j++){
          if (usersMap[i].childs[j] == 0){
            usersMap[i].childs[j] = userCount;
            uint256 child = 0;
            usersMap[userCount] = User({user_address: user_address, parent_id:i, childs:[child, child, child, child, child], isFull: false});
            userCount++;
            if (j == 4) usersMap[i].isFull = true;
            return userCount-1;
          }
        }
      }
    }
    return 0;
  }

  function getRewarder(uint256 parent_id) private view returns (uint256) {
    uint256 i = 0;
    for (i = 0; i < 3; i++){
      parent_id = usersMap[parent_id].parent_id;
      if (parent_id == 0){
        return 0;
      }
    }
    return parent_id;
  }

  function getUserCount() public view returns (uint256 _usercount){
    _usercount = userCount;
  }

  function getUser(uint256 _user_id) public view returns (address user_address, uint256 parent_id, uint256[5] childs, bool isFull){
    User memory _user = usersMap[_user_id];
    user_address = _user.user_address;
    parent_id = _user.parent_id;
    childs = _user.childs;
    isFull = _user.isFull;
  }

  function addUser(uint256 parent_id) public payable isUnlocked{
    require(parent_id < userCount);  
    require(msg.value >= price);
    uint256 fee = msg.value.mul(4) / 100;
    uint256 reward_amount = msg.value - fee;
    if (!usersMap[parent_id].isFull) {
      for (uint256 i=0; i<5; i++){
        if (usersMap[parent_id].childs[i] == 0){
          usersMap[parent_id].childs[i] = userCount;
          uint256 child = 0;
          usersMap[userCount] = User({user_address: msg.sender, parent_id:parent_id, childs:[child, child, child, child, child], isFull: false});
          uint256 current_user_id = userCount;
          userCount++;
          if (i == 4) usersMap[parent_id].isFull = true;
          emit AddUser(msg.sender, current_user_id, parent_id);
          uint256 rewarder_id = getRewarder(parent_id);
          commissioner.transfer(fee);
          usersMap[rewarder_id].user_address.transfer(reward_amount);
          emit Reward(usersMap[rewarder_id].user_address, rewarder_id, reward_amount);
          break;
        }
      }
    } 
  }
  
  function addUserAuto() public payable isUnlocked{
    require(msg.value >= price);
    uint256 fee = msg.value.mul(4) / 100;
    uint256 reward_amount = msg.value - fee;
    uint256 user_id = _addUser(msg.sender);
    emit AddUser(msg.sender, user_id, usersMap[user_id].parent_id);
    uint256 rewarder = getRewarder(usersMap[user_id].parent_id);
    commissioner.transfer(fee);
    usersMap[rewarder].user_address.transfer(reward_amount);
    emit Reward(usersMap[rewarder].user_address, rewarder, reward_amount);
  }
}