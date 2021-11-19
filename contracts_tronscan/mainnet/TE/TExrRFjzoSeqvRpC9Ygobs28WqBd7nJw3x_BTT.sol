//SourceUnit: newbtt.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface TRC20Basic {
  function totalSupply() external view returns (uint);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BTT {
    
    uint32 public currentId = 2;
    address public owner;
    address public owner2;
    bool public lockStatus;
    trcToken public rewardId;
    uint public totalAmount;
    TRC20Basic public token;
    uint public adminFee = 16;
    uint public adminfee1 = 75;
    uint public adminfee2 = 25;
    
    struct userDetails {
        uint32 id;
        uint8 level;
        address referer;
        address[] firstLineRef;
        address[] secondLineRef;
        address[] thirdLineRef;
        address[] fourthLineRef;
        bool status;
        uint levelEarned;
        uint received;
        uint8 levelCount;
        uint8 cycle;
    }
    
    mapping(address => userDetails)public users;
    mapping(uint => address)public userList;
    mapping(uint => uint)public levelPrice;
    mapping(uint => uint)public NFTprice;
    mapping(uint => uint)public tokenPrice;
    
    event Join(address indexed from,address _ref,uint amount,uint time);
    event AdminCommission(address indexed user,address owner,address owner2,uint amount1,uint amount2);
    event TokenBalance(address indexed user,uint BTTamount,uint NFTamount,uint8 level,uint time);
    event Reinvest(address indexed from,uint8 level,uint cyclecount,uint time);
    
    
    constructor (uint256 _rewardId,address _owner,address _owner2,address _token) {
        rewardId = _rewardId;
        owner = _owner;
        owner2 = _owner2;
        token = TRC20Basic(_token);
        userList[1] = owner;
        users[owner].status = true;
        users[owner].id = 1;
        users[owner].level = 1;
        
        levelPrice[1] = 360e6;
        levelPrice[2] = 530e6;
        levelPrice[3] = 1065e6;
        levelPrice[4] = 1770e6;
        
        tokenPrice[1] = 100e6;
        tokenPrice[2] = 200e6;
        tokenPrice[3] = 400e6;
        tokenPrice[4] = 800e6;
        
        NFTprice[1] = 100000e6;
        NFTprice[2] = 200000e6;
        NFTprice[3] = 400000e6;
        NFTprice[4] = 800000e6;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
    /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, "BTT: Contract Locked");
        _;
    }
    
    /**
     * @dev Throws if called by other contract
     */
    modifier isContractCheck(address _user) {
        require(!isContract(_user), "BTT: Invalid address");
        _;
    }
    
   receive()external payable{} 
   
  function updateRewardPrice(uint[] memory _NFTprice,uint[] memory _tokenprice)public onlyOwner {
      require(_NFTprice.length == _tokenprice.length,"Invalid params");
      for(uint i=0;i<_NFTprice.length;i++){
      NFTprice[i+1] = _NFTprice[i];
      tokenPrice[i+1] = _tokenprice[i];
      }
  }
  
  function updateAdminFee(uint _adminPercent,uint _admin1,uint _admin2)public onlyOwner {
      adminFee = _adminPercent;
      adminfee1 = _admin1;
      adminfee2 = _admin2;
  }
    
   function join(uint32 _refID) public payable isLock isContractCheck(msg.sender){
       
    userDetails storage user = users[msg.sender];
    require(users[userList[_refID]].status == true,"User not exist");
    require(user.status == false,"User already register");
    require( msg.value == levelPrice[1],"Incorrect Deposit amount");
    if (users[userList[_refID]].firstLineRef.length >= 2) 
            _refID = users[findFreeReferrer(userList[_refID])].id;
    user.id = currentId;
    currentId++;
    user.referer = userList[_refID];
    user.status = true;
    user.level = 1;
    userList[user.id] = msg.sender;
    uint amt = msg.value*adminFee/100;
    require(payable(owner).send(amt*adminfee1/100));
    require(payable(owner2).send(amt*adminfee2/100));
    emit AdminCommission(msg.sender,owner,owner2,amt*adminfee1/100,amt*adminfee2/100);
    users[userList[_refID]].levelEarned += (msg.value - amt);
    totalAmount += msg.value;
    payable(msg.sender).transferToken(tokenPrice[1],rewardId);
    token.transfer(msg.sender,NFTprice[1]);
    emit TokenBalance(msg.sender,tokenPrice[1],NFTprice[1],1,block.timestamp);
    updateRef(msg.sender);
    payLevel(users[msg.sender].referer);
    emit Join(msg.sender,users[msg.sender].referer,msg.value,block.timestamp);
   }
   
   function updateRef(address _user) internal {
     address firstUpline = users[_user].referer;
     address secondUpline = users[firstUpline].referer;
     address thirdUpline = users[secondUpline].referer;
     address fourthUpline = users[thirdUpline].referer;
     
     if (firstUpline != address(0))
     users[firstUpline].firstLineRef.push(_user);
     if (secondUpline != address(0))
     users[secondUpline].secondLineRef.push(_user);
     if (thirdUpline != address(0))
     users[thirdUpline].thirdLineRef.push(_user);
     if (fourthUpline != address(0))
     users[fourthUpline].fourthLineRef.push(_user);
   }
   
   function payLevel(address _ref) internal {
        address firstUpline = _ref;
        address secondUpline = users[firstUpline].referer;
        address thirdUpline = users[secondUpline].referer;
        uint amount;
        address[10] memory referer;
        
        if (users[firstUpline].level == 1 && firstUpline != address(0)
        && users[firstUpline].firstLineRef.length == 2) {
        
            userDetails storage user = users[firstUpline]; 
            uint amt = levelPrice[2]*adminFee/100;
            require(payable(owner).send(amt*adminfee1/100));
            require(payable(owner2).send(amt*adminfee2/100));
            emit AdminCommission(msg.sender,owner,owner2,amt*adminfee1/100,amt*adminfee2/100);
            
            users[thirdUpline].levelEarned += (levelPrice[2]-amt);
            user.levelEarned -= levelPrice[2];
            amount = user.levelEarned;
            address receipent = firstUpline != address(0)? firstUpline:owner;
            require(payable(receipent).send(amount),"Level 2 upgration failed");
            
            users[receipent].received += amount;
            user.level = 2;
            user.levelEarned -= amount;
            payable(firstUpline).transferToken(tokenPrice[2],rewardId);
            token.transfer(firstUpline,NFTprice[2]);
            emit TokenBalance(firstUpline,tokenPrice[2],NFTprice[2],users[firstUpline].level,block.timestamp);
            
            if (thirdUpline != address(0)){
                users[thirdUpline].levelCount++;
            }
        }
        if(thirdUpline != address(0) && users[thirdUpline].levelCount == 4) {
            userDetails storage user = users[thirdUpline];
            referer[0] = user.referer;
            referer[1] = users[referer[0]].referer;
            referer[2] = users[referer[1]].referer;
            uint amt = levelPrice[3]*adminFee/100;
            require(payable(owner).send(amt*adminfee1/100));
            require(payable(owner2).send(amt*adminfee2/100));
            emit AdminCommission(msg.sender,owner,owner2,amt*adminfee1/100,amt*adminfee2/100);
            
            
            
            users[referer[2]].levelEarned += (levelPrice[3] - amt) ;
            user.levelEarned -= levelPrice[3];
            amount = user.levelEarned;
            address receipent = thirdUpline != address(0)? thirdUpline:owner;
            require(payable(receipent).send(amount),"Level 3 upgration failed");
            
            users[receipent].received += amount;
            user.level = 3;
            user.levelEarned -= amount;
            
            payable(thirdUpline).transferToken(tokenPrice[3],rewardId);
            token.transfer(thirdUpline,NFTprice[3]);
            emit TokenBalance(thirdUpline,tokenPrice[3],NFTprice[3],users[thirdUpline].level,block.timestamp);
            
            if (referer[2] != address(0)){
                users[referer[2]].levelCount++;
            }
        }
        
        
        if(referer[2] != address(0) && users[referer[2]].levelCount == 12) {
        
            userDetails storage user = users[referer[2]];
            referer[3] = user.referer;
            referer[4] = users[referer[3]].referer;
            referer[5] = users[referer[4]].referer;
            referer[6] = users[referer[5]].referer;
            
            uint amt = levelPrice[4]*adminFee/100;
            require(payable(owner).send(amt*adminfee1/100));
            require(payable(owner2).send(amt*adminfee2/100));
            emit AdminCommission(msg.sender,owner,owner2,amt*adminfee1/100,amt*adminfee2/100);
            
            users[referer[6]].levelEarned += (levelPrice[4] - amt);
            user.levelEarned -= levelPrice[4];
            amount = user.levelEarned;
            address receipent = referer[2] != address(0)? referer[2]:owner;
            require(payable(receipent).send(amount),"Level 4 upgration failed");
            
            users[receipent].received += amount;
            user.level = 4;
            user.levelEarned -= amount;
            
            payable(referer[2]).transferToken(tokenPrice[4],rewardId);
            token.transfer(referer[2],NFTprice[4]);
            emit TokenBalance(referer[2],tokenPrice[4],NFTprice[4],users[referer[2]].level,block.timestamp);
            
            if (referer[6] != address(0)){
                users[referer[6]].levelCount++;
            }
        }
        
        if(referer[6] != address(0) && users[referer[6]].levelCount == 28) {
            amount = users[referer[6]].levelEarned;
            address receipent = referer[6] != address(0)? referer[6]:owner;
            uint amt = levelPrice[1]*adminFee/100;
            require(payable(owner).send(amt*adminfee1/100));
            require(payable(owner2).send(amt*adminfee2/100));
            emit AdminCommission(receipent,owner,owner2,amt*adminfee1/100,amt*adminfee2/100);
            
            require(payable(receipent).send((amount - levelPrice[1])),"Final payment failed");
            userDetails storage user = users[receipent];
            user.received += (amount);
            user.levelEarned -= (amount);
            _reinvest(receipent);
            payLevel(users[receipent].referer);
        }
   }
   
   function _reinvest(address _user)internal {
       userDetails storage user = users[_user];
       user.firstLineRef = new address[](0);
       user.secondLineRef = new address[](0);
       user.thirdLineRef = new address[](0);
       user.fourthLineRef = new address[](0);
       user.level = 1;
       user.levelCount = 0;
       user.cycle++;
       emit Reinvest(_user,user.level,user.cycle,block.timestamp);
   }
   
   function viewRef(address _user)public view returns(address[]memory,address[] memory,address[] memory,address[] memory) {
       userDetails storage user = users[_user];
       return (user.firstLineRef,
               user.secondLineRef,
               user.thirdLineRef,
               user.fourthLineRef);
   }
  
   function findFreeReferrer(address _user) public view returns(address) {
        uint referLimit = 2;
        if (users[_user].firstLineRef.length < referLimit) {
            return _user;
        }
        address[] memory referrals = new address[](126);
        referrals[0] = users[_user].firstLineRef[0];
        referrals[1] = users[_user].firstLineRef[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 126; i++) { // Finding FreeReferrer
            if (users[referrals[i]].firstLineRef.length == referLimit) {
                if (i < 62) {
                    referrals[(i + 1) * 2] = users[referrals[i]].firstLineRef[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]].firstLineRef[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, "BTT: No Free Referrer");
        return freeReferrer;
    }
    
    function updateLevel(uint _level1,uint _level2,uint _level3,uint _level4)public onlyOwner {
        levelPrice[1] = _level1;
        levelPrice[2] = _level2;
        levelPrice[3] = _level3;
        levelPrice[4] = _level4;
    }
    
    function retrive(uint8 _type,address _toUser,uint amount)public onlyOwner returns(bool status){
           require(_toUser != address(0), "Invalid Address");
        if (_type == 1) {
           require(address(this).balance >= amount, "BTT: Insufficient balance");
            require(payable(_toUser).send(amount), "BTT: Transaction failed");
            return true;
        }
        else if (_type == 2) {
            require(payable(address(this)).tokenBalance(rewardId) >= amount);
            payable(_toUser).transferToken(amount,rewardId);
            return true;
        }
        else if (_type == 3) {
            require(token.balanceOf(address(this)) >= amount);
            token.transfer(_toUser,amount);
            return true;
        }
    }
    
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
    /**
     * @dev isContract: Returns true if account is a contract
     */
    function isContract(address _account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(_account)
        }
        if (size != 0)
            return true;
        return false;
    }
    
}