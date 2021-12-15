/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)external returns (bool);
  function transferFrom(address from, address to, uint256 value)external returns (bool);
  function burn(uint256 value)external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}


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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract StarInfinity  {
    using SafeMath for uint256;

    struct User {
        uint id;
        uint256 amount;
        address referrer;
        uint partnersCount;
        uint256 levelIncome;
        uint8 currentPackage;
        Pool join_time_pool;
        TimeHistory history;
        uint256 totalWithdraw;
    }

    struct Pool {
        uint256 communityIncome;
        uint256 leadershipIncome;
        uint256 clubIncome;
    }

    struct TimeHistory {
        uint256 last_withdrawal;
        uint256 buy_club;
        uint256 join_time;
    }

    mapping(address => User) public users;
    mapping(address => uint256) public leadership;
    mapping(address => uint256) public club_member;
    mapping(uint8 => address) public idToAddress;

    uint8 public lastUserId = 2;
    uint8 public no_of_leader;
    uint8 public no_of_club;

    uint8[10] public refPercent=[10,5,3,2,2,1,1,2,2,2];
    mapping(uint8=>uint256) public package;  
    Pool public global_Pool;
    IBEP20 private busdToken;
    address public owner;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);

    constructor(address ownerAddress, IBEP20 _busdToken) {
        owner = ownerAddress;
        busdToken = _busdToken; 

        users[ownerAddress].id=1;
        users[ownerAddress].currentPackage=7;
        users[ownerAddress].join_time_pool=global_Pool;
        users[ownerAddress].history.join_time=block.timestamp;
        idToAddress[1] = ownerAddress;

        package[1]=40*1e18;
        package[2]=80*1e18;
        package[3]=160*1e18;
        package[4]=320*1e18;
        package[5]=640*1e18;
        package[6]=1280*1e18;
        package[7]=2560*1e18;

    }

    receive () external payable {}

    function registrationExt(address referrerAddress) external payable {
        require(!isContract(msg.sender),"Can not be contract");
        require(busdToken.balanceOf(msg.sender)>=package[1],"Low Balance");
        require(busdToken.allowance(msg.sender,address(this))>=package[1],"Invalid allowance amount");
        busdToken.transferFrom(msg.sender,address(this),package[1]);
        registration(msg.sender, referrerAddress);
    }
   
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        users[userAddress].id=lastUserId;
        users[userAddress].referrer=referrerAddress;
        users[userAddress].currentPackage=1;
        users[userAddress].join_time_pool=global_Pool;
        idToAddress[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;

        //calculate leader user
        if(users[referrerAddress].partnersCount>=10){
            if(leadership[referrerAddress]==0){          
              leadership[referrerAddress]=users[referrerAddress].id;
              no_of_leader++;
            }
        }

        // calculate club user
        if(users[referrerAddress].partnersCount>=2){
        if(club_member[referrerAddress]==0&&users[referrerAddress].history.buy_club.add(30 days)>=block.timestamp){
            no_of_club++;
        }
        }

        //10% admin deduction   
        
        // 25% globle Community
        global_Pool.communityIncome=global_Pool.communityIncome.add(package[1].mul(25).div(100));

        // 30% globle Club Pool
        global_Pool.clubIncome=global_Pool.clubIncome.add(package[1].mul(30).div(100));
        
        // 5% leadership Pool
        global_Pool.leadershipIncome=global_Pool.leadershipIncome.add(package[1].mul(5).div(100));

        // 30% sponcer distributation  10 level 30%
        _calculateReferrerReward(package[1],userAddress);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
     
    function _calculateReferrerReward(uint256 _investment, address _referrer) private {
         for(uint8 i=0;i<refPercent.length;i++)
         {
            if(_referrer==address(0)) break;
            if(users[_referrer].partnersCount>=2||i > 5){
             if(users[_referrer].totalWithdraw < (package[users[_referrer].currentPackage]*10))
                users[_referrer].levelIncome=users[_referrer].levelIncome+(_investment.mul(refPercent[i]).div(100));
            }
            _referrer=users[_referrer].referrer;
         }

    }

    function totalIncome(address _user) public view returns (uint256 communityIncome,uint256 clubIncome,uint256 leadershipIncome) {
        User memory user = users[_user];
        if(user.totalWithdraw< package[user.currentPackage]){
          communityIncome = (global_Pool.communityIncome-user.join_time_pool.communityIncome).div(lastUserId - 1);
          leadershipIncome = user.partnersCount>=10?(global_Pool.leadershipIncome-user.join_time_pool.leadershipIncome).div(no_of_leader):0;
          clubIncome = user.partnersCount>=2 && user.history.buy_club.add(30 days)>=block.timestamp?(global_Pool.clubIncome-user.join_time_pool.clubIncome).div(no_of_club):0;
        }else {
            return (0,0,0);
        }
    } 

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function isContract(address _address) public view returns (bool _isContract) {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }      

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

}