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


contract MNCenter is Manageable {

/********************************************** EVENTS **********************************************/
  event Saled(uint256 _sale_id, string _user_email, string sale_coin, string sale_amount, uint256 sale_masternode_id);
  event Rewarded(uint256 _reward_id, string reward_user_email, string reward_coin, string reward_amount, uint256 reward_masternode_id);
/****************************************************************************************************/

  function AddSale(uint256 _sale_id, string _user_email, string _sale_coin, string _sale_amount, uint256 _sale_masternode_id) public onlyOwner {
      emit Saled(_sale_id, _user_email, _sale_coin, _sale_amount, _sale_masternode_id);
  }
  
  function AddReward(uint256 _reward_id, string _reward_user_email, string _reward_coin, string _rewarded_amount, uint256 _rewareded_masternode_id) public onlyOwner {
      emit Rewarded(_reward_id, _reward_user_email, _reward_coin, _rewarded_amount, _rewareded_masternode_id);
  }
}