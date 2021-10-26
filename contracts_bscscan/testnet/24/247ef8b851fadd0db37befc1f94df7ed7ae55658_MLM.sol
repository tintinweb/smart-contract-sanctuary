/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    
    uint256 c = a / b;
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

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }
    
    function getOwner() public view returns(address){
        return owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


interface IBEP20 {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}


contract MLM is Owned {
    using SafeMath for uint256;
      struct UserStruct {
        bool isExist;
        address referrer;
        uint256 directCount;
        address[] referral;
        uint256 amount;
        uint256 earned;
        uint256 signedTime;
    }
    
    address public REWARD = 0xB93BB7Bd900E7567cdD868374288F05feE8B7dEd;
    
    mapping (address => UserStruct) public users;
    mapping (address => address) public _parent;
    
    event Rewards(address indexed _from, address indexed _referrer, uint256 amount);
    event Claim(address indexed _to,uint256 amount);
    
    uint256 public userCount = 0;
    uint256 public totalEarned = 0;
   
    
    uint256[] public rewardLevel;
    
    constructor() public{
        rewardLevel.push(400);
        rewardLevel.push(200);
        rewardLevel.push(100);
        rewardLevel.push(100);
        rewardLevel.push(100);
        rewardLevel.push(50);
        rewardLevel.push(50);
         users[msg.sender] = UserStruct({
            isExist : true,
            referrer : address(0),
            directCount: 0,
            referral: new address[](0),
            amount: 0,
            earned: 0,
            signedTime: block.timestamp
        });
        _parent[msg.sender] = address(0);
    }
    
    function signupUser(address _referrer,uint256 amount) public{
        require(!users[msg.sender].isExist,"User already Exists !");
        _referrer = users[_referrer].isExist ? _referrer : getOwner();
         users[msg.sender] = UserStruct({
            isExist : true,
            referrer : _referrer,
            directCount: 0,
            referral: new address[](0),
            amount: 0,
            earned: 0,
            signedTime: block.timestamp
        });
        _parent[msg.sender] = _referrer;
        users[_referrer].referral.push(msg.sender);
        users[_referrer].directCount = users[_referrer].directCount.add(1);
        userCount++;
       rewardDistribution(msg.sender,amount);
    }
    
    function rewardDistribution(address _user,uint256 _amount)internal{
        for(uint256 i=0; i < rewardLevel.length;i++){
            _user = users[_parent[_user]].isExist ? _parent[_user] : getOwner();
            uint256 toTransfer = _amount.mul(rewardLevel[i]).div(10000);
            users[_user].amount = users[_user].amount.add(toTransfer);
            emit Rewards(address(this),_user,toTransfer);
        }
        
    }
    
    function getLevels() public view returns (uint256[] memory){
        return rewardLevel;
    }
    
    function getReferalperUser(address _user) public view returns (address[] memory){
        return users[_user].referral;
    }
    
   function claimRewards() public{
        uint256 toTransfer = users[msg.sender].amount;
        IBEP20(REWARD).transfer(msg.sender,toTransfer);
        users[msg.sender].amount = 0;
        users[msg.sender].earned = users[msg.sender].earned.add(toTransfer);
        totalEarned = totalEarned.add(toTransfer);
        emit Claim(msg.sender,toTransfer);  
    }
   
      
}