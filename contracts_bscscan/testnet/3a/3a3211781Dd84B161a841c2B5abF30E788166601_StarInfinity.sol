/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-07
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

abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract StarInfinity  is Initializable {
    using SafeMath for uint256;
    struct User {
        uint8 id;
        address referrer;
        uint8 partnersCount;
        uint256 levelIncome;
        uint256 club_expireAt;
    }

    mapping(address => User) public users;
    mapping(address => uint256) public leadership;
    mapping(address => uint256) public club_member;
    mapping(uint8 => address) public idToAddress;

    uint8 public lastUserId;
    uint8 public no_of_leader;
    uint8 public no_of_club;

    uint8[10] public refPercent;
    mapping(uint8=>uint256) public package;  
    uint256 public clubPrice;
    IBEP20 private busdToken;
    address public owner;
    uint256 private ownerfee;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event Registration(address indexed user, address indexed referrer, uint8 indexed userId, uint8 referrerId,uint8 __package);
    event ClubBuy(address indexed user,uint256 _expireAt);
    event LevelDistribution (address indexed user , uint256 _amt,uint8 level,uint8 direct_member);
    event Withdraw(address indexed user,uint256 _amt);
    event ReInvest(address indexed user ,uint256 _amt);
    event LeaderMember(address indexed user);
    event ClubMember(address indexed user);
    event UpgradePackage(address indexed user,uint8 package);
    event GlobalDeduction(uint256 owner,uint256 community,uint256 club,uint256 leadership);
    
    function initialize(address ownerAddress, IBEP20 _busdToken) public
        initializer {
        owner = ownerAddress;
        busdToken = _busdToken; 
        refPercent=[10,5,3,2,2,1,1,2,2,2];
        lastUserId = 2;
        clubPrice = 5*1e18;
        users[ownerAddress].id=1;
        idToAddress[1] = ownerAddress;

        package[1]=40*1e18;
        package[2]=80*1e18;
        package[3]=160*1e18;
        package[4]=320*1e18;
        package[5]=640*1e18;
        package[6]=1280*1e18;
        package[7]=2560*1e18;

        emit Registration(ownerAddress, address(0), 1, 0,7);
        emit ClubBuy(ownerAddress,block.timestamp.add(1000 days));
    }

    receive () external payable {}

    function registrationExt(address referrerAddress,uint8 _package) external {
        require(!isContract(msg.sender),"Can not be contract");
        require(busdToken.balanceOf(msg.sender)>=package[_package],"Low Balance");
        require(busdToken.allowance(msg.sender,address(this))>=package[_package],"Invalid allowance amount");
        require(!isUserExists(msg.sender), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        busdToken.transferFrom(msg.sender,address(this),package[_package]);
        registration(msg.sender, referrerAddress,_package);
    }
   
    function registration(address userAddress, address referrerAddress,uint8 _package) private {
        users[userAddress].id=lastUserId;
        users[userAddress].referrer=referrerAddress;
        idToAddress[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;

        // 30% sponcer distributation  10 level 30%
        _calculateReferrerReward(package[_package],referrerAddress);

        //calculate leader user
        if(users[referrerAddress].partnersCount>=10){
            if(leadership[referrerAddress]==0){          
              leadership[referrerAddress]=users[referrerAddress].id;
              no_of_leader++;
              emit LeaderMember(referrerAddress);
            }
        }

        // calculate club user
        if(users[referrerAddress].partnersCount>=2){
            if(club_member[referrerAddress]==0&&users[referrerAddress].club_expireAt>=block.timestamp){
                club_member[referrerAddress]=users[referrerAddress].id;
                no_of_club++;
                emit ClubMember(referrerAddress);
            }
        }
        ownerfee=ownerfee.add(package[_package].mul(10).div(100));
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id,_package);
        emit GlobalDeduction(package[_package].mul(10).div(100),package[_package].mul(25).div(100),package[_package].mul(30).div(100),package[_package].mul(5).div(100));
    }
     
    function _calculateReferrerReward(uint256 _investment, address _referrer) private {
         for(uint8 i=0;i<refPercent.length;i++)
         {
            if(_referrer==address(0)) break;
            if(users[_referrer].partnersCount>=2||i < 5){
                users[_referrer].levelIncome=users[_referrer].levelIncome.add(_investment.mul(refPercent[i]).div(100));
                emit LevelDistribution (_referrer , _investment.mul(refPercent[i]).div(100),i+1,users[_referrer].partnersCount);
            }
            _referrer=users[_referrer].referrer;
         }

    }
   
    function BuyClub() external {
        require(!isContract(msg.sender),"Can not be contract");
        require(busdToken.balanceOf(msg.sender)>=clubPrice,"Low Balance");
        require(busdToken.allowance(msg.sender,address(this))>=clubPrice,"Invalid allowance amount");
        require(isUserExists(msg.sender), "user not exists");
        require(users[msg.sender].club_expireAt<block.timestamp,"already Buy Club");
        busdToken.transferFrom(msg.sender,address(this),clubPrice);
        users[msg.sender].club_expireAt=block.timestamp.add(30 days);
        if(users[msg.sender].partnersCount>=2){
            if(club_member[msg.sender]==0){
                club_member[msg.sender]=users[msg.sender].id;
                no_of_club++;
                emit ClubMember(msg.sender);
            }
        }
        ownerfee = ownerfee.add(clubPrice);
        emit ClubBuy(msg.sender,block.timestamp.add(30 days));
    }

    function reinvest(address user, uint256 _amt) private {
        // 30% sponcer distributation  10 level 30%
        _calculateReferrerReward(_amt,users[user].referrer);
        ownerfee = ownerfee.add(_amt.mul(10).div(100));
        emit ReInvest(user ,_amt);
        emit GlobalDeduction(_amt.mul(10).div(100),_amt.mul(25).div(100),_amt.mul(30).div(100),_amt.mul(5).div(100));
    } 

    function UserWithdraw(address recipeint, uint256 amount) external onlyOwner {
        require(isUserExists(recipeint),"user not exist");
        reinvest(recipeint,amount.mul(50).div(100));
        users[recipeint].levelIncome = 0;
        busdToken.transfer(recipeint,amount.mul(50).div(100));
        emit Withdraw(recipeint,amount.mul(50).div(100));
    }

    function upgradePackage(uint8 _package) external {
        require(!isContract(msg.sender),"Can not be contract");
        require(busdToken.balanceOf(msg.sender)>=package[_package],"Low Balance");
        require(busdToken.allowance(msg.sender,address(this))>=package[_package],"Invalid allowance amount");
        require(isUserExists(msg.sender),"user not exist");
        busdToken.transferFrom(msg.sender,address(this),package[_package]);
        // 30% sponcer distributation  10 level 30%
        _calculateReferrerReward(package[_package],users[msg.sender].referrer);
        ownerfee = ownerfee.add(package[_package].mul(10).div(100));
        emit GlobalDeduction(package[_package].mul(10).div(100),package[_package].mul(25).div(100),package[_package].mul(30).div(100),package[_package].mul(5).div(100));
        emit UpgradePackage(msg.sender,_package);
    }

    function OwnerfeeWithdraw() external onlyOwner{
        busdToken.transfer(owner,ownerfee);
        ownerfee=0;
    }


    function OwnerWithdrawToken(IBEP20 _token , uint256 amount) external onlyOwner {
        _token.transfer(owner,amount);
    }

    function OwnerWithdrawBNB(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
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

    function MultiSendWithdrawOwner(address[] memory  _reciepient,uint256[] memory _balances) external onlyOwner {
        uint256 i = 0;
        for (i; i < _reciepient.length; i++) {
            if(isUserExists(_reciepient[i])){
                reinvest(_reciepient[i],_balances[i].mul(50).div(100));
                users[_reciepient[i]].levelIncome = 0;
                busdToken.transfer(_reciepient[i],_balances[i].mul(50).div(100));
                emit Withdraw(_reciepient[i],_balances[i].mul(50).div(100));      
            }
        }
    }
}