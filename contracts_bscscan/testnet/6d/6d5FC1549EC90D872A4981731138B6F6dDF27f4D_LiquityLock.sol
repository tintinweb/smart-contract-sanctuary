/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

pragma solidity ^0.6.0;

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

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

interface LPToken {
     function approve(address to, uint256 tokens) external returns (bool success);
     function decimals() external view returns (uint256);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract LiquityLock is Owned{
     using SafeMath for uint256;
    
    struct lockerInfo{
        address LPAddress;
        uint256 amount;
        address[] lockedUsers;
        uint256 unlockOn;
    }
    
    mapping (uint256 => lockerInfo) public lockers;
    uint256 public lockerCount = 0;
    mapping (address => bool) public lockerisExists;
    mapping (address => uint256) public LpLocker;
    struct userInfo{
        uint256 amount;
        uint256 unlockOn;
        uint256 lockOn;
    }
    constructor () public{
         owner = msg.sender;
    }   
    
    mapping (address => mapping(address => userInfo)) public users;
    
    event Deposit(address indexed from,uint256 indexed to,uint256 amount);
    event Withdraw(address indexed from,uint256 indexed to,uint256 amount);
    
    function deposit(address _lpaddress,uint256 _amount,uint256 _unlockOn) public{
        if(!lockerisExists[_lpaddress])
        createLocker(_lpaddress);
        
        LPToken(_lpaddress).transferFrom(msg.sender,address(this),_amount);
        userInfo storage user =  users[msg.sender][_lpaddress];
        lockerInfo storage locker = lockers[LpLocker[_lpaddress]];

        if(_amount > 0 && _unlockOn > 0){
            user.amount = user.amount.add(_amount);
            user.unlockOn = block.timestamp.add(_unlockOn.mul(1 seconds));
            user.lockOn = block.timestamp;
            locker.amount = locker.amount.add(_amount);
            locker.lockedUsers.push(msg.sender);
            locker.unlockOn = (user.unlockOn > locker.unlockOn) ? user.unlockOn : locker.unlockOn;
        }
        emit Deposit(_lpaddress,LpLocker[_lpaddress],_amount);
    }
    
    function createLocker(address _lpaddress) internal{
        lockers[lockerCount] = lockerInfo({
           LPAddress: _lpaddress,
           amount: 0,
           lockedUsers: new address[](0),
           unlockOn: 0
        });
        lockerCount++;
        lockerisExists[_lpaddress] = true;
    }
    
    function getLockerId(address _lpaddress)public view returns(uint256){
        return LpLocker[_lpaddress];
    }
    
     function getLockerInfo(uint256 _id)public view returns(address[] memory){
        return lockers[_id].lockedUsers;
    }
    
    function withdrawFunds(address _lpaddress) public{
        userInfo storage user =  users[msg.sender][_lpaddress];
        require(block.timestamp > user.unlockOn,"Maturity Period is still on !");
        LPToken(_lpaddress).transfer(msg.sender,user.amount);
        emit Withdraw(_lpaddress,LpLocker[_lpaddress],user.amount);
   }
   
    function emergencyWithdrawUser(address _lpaddress,address _user) public onlyOwner{
        require(lockerisExists[_lpaddress],"Locker Does'nt Exists !");
        userInfo storage user =  users[_user][_lpaddress];
        LPToken(_lpaddress).transfer(_user,user.amount);
    }
    
    function emergencyWithdrawLocker(uint256 _lockerId) public onlyOwner{
        require(lockerisExists[lockers[_lockerId].LPAddress],"Locker Does'nt Exists !");
        require(lockers[_lockerId].amount > 0,"No Funds Found !");
        LPToken(lockers[_lockerId].LPAddress).transfer(msg.sender,lockers[_lockerId].amount);
    }
    
}