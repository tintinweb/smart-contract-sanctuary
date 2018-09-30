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
  bool public contractLock;
  uint256 price = 1000000000000000000;
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


contract InvitherB is Manageable {
  using SafeMath for uint256;
  using SafeMath for int256;

/********************************************** EVENTS **********************************************/
  event AddUser(address user_address,  int256 user_id);
  event Reward(address user_address, int256 user_id, uint256 reward_amount);
/****************************************************************************************************/

/********************************************** STRUCTS *********************************************/
  struct User {
    address user_address;
    int256 parent_id;
    int256[5] childs;
    bool isFull;
  }

/*********************************************** VARS ***********************************************/

  mapping(int256 => User) private usersMap;
  bool initDone = false;
  int256 userCount = 0;

  address commissioner = 0xfe9313E171C441db91E3604F75cA58f13AA0Cb23;
/****************************************************************************************************/


  function init() public onlyOwner {
    int256 child = -1;
    usersMap[0] = User({user_address: owner, parent_id:child, childs:[child, child, child, child, child], isFull: false});  // solhint-disable-line max-line-length
    userCount=1;
  }

  function _addUser(address user_address) private returns (int256) {
    for (int256 i=0; i<userCount; i++){
      if (!usersMap[i].isFull){
        for (uint256 j=0; j<5; j++){
          if (usersMap[i].childs[j] == -1){
            usersMap[i].childs[j] == userCount;
            int256 child = -1;
            usersMap[userCount] = User({user_address: user_address, parent_id:i, childs:[child, child, child, child, child], isFull: false});
            userCount++;
            if (j == 4) usersMap[i].isFull = true;
            return userCount-1;
          }
        }
      }
    }
    return -1;
  }

  function getRewarder(int256 parent_id) private view returns (int256) {
    int256 i = 0;
    for (i = 0; i < 4; i++){
      parent_id = usersMap[parent_id].parent_id;
      if (parent_id == -1){
        return -1;
      }
    }
    return parent_id;
  }

  function getUserCount() public view returns (int256 _usercount){
    _usercount = userCount;
  }
  
  function getUser(int256 _user_id) public view returns (address user_address, int256 parent_id, int256[5] childs, bool isFull){
    User memory _user = usersMap[_user_id];
    user_address = _user.user_address;
    parent_id = _user.parent_id;
    childs = _user.childs;
    isFull = _user.isFull;    
  }
  
  function addUser(int256 parent_id) public payable isUnlocked{
    require(parent_id < userCount);
    require(msg.value >= price);
    uint256 i = 0;
    if (!usersMap[parent_id].isFull){
      for (i=0; i<5; i++){
        if (usersMap[parent_id].childs[i] == -1){
          usersMap[parent_id].childs[i] = userCount;
          int256 child = -1;
          usersMap[userCount] = User({user_address: msg.sender, parent_id:parent_id, childs:[child, child, child, child, child], isFull: false});
          userCount++;
          if (i == 4) usersMap[parent_id].isFull = true;
          emit AddUser(msg.sender, userCount-1);
          break;
        }
      }
    } 
  }
}