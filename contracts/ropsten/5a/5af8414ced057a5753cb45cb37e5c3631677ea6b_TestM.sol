pragma solidity ^0.4.23;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

}


contract Ownable {

  address public owner;
  address public manager;
  address public ownerWallet;

  constructor() public {
    owner = msg.sender;
    manager = msg.sender;
    ownerWallet = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

  modifier onlyOwnerOrManager() {
     require((msg.sender == owner)||(msg.sender == manager), "only for owner or manager");
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  function setManager(address _manager) public onlyOwnerOrManager {
      require(_manager != address(0));
      manager = _manager;
  }

  function setOwnerWallet(address _ownerWallet) public onlyOwner {
      require(_ownerWallet != address(0));
      ownerWallet = _ownerWallet;
  }

}

contract TestM is Ownable {

    event regLevelEvent(address indexed _user, address indexed _referrer,  uint _time);
    event buyLevelEvent(address indexed _user, uint _level, uint _time);
    event prolongateLevelEvent(address indexed _user, uint _level, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    //------------------------------

    mapping (uint => uint) public LEVEL_PRICE;
    uint REFERRER_1_LEVEL_LIMIT = 3;
    uint PERIOD_LENGTH = 1 days;


    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        mapping (uint => uint) levelExpired;
    }

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    uint public currUserID = 0;




    constructor() public {
        LEVEL_PRICE[1] = 0.05 ether;
        LEVEL_PRICE[2] = 0.15 ether;
        LEVEL_PRICE[3] = 0.45 ether;
        LEVEL_PRICE[4] = 1.35 ether;
        LEVEL_PRICE[5] = 4.05 ether;
        LEVEL_PRICE[6] = 12.15 ether;
        LEVEL_PRICE[7] = 36.45 ether;
        LEVEL_PRICE[8] = 109.35 ether;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : 0,
            referral : new address[](0)
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;

        users[ownerWallet].levelExpired[1] = 77777777777;
        users[ownerWallet].levelExpired[2] = 77777777777;
        users[ownerWallet].levelExpired[3] = 77777777777;
        users[ownerWallet].levelExpired[4] = 77777777777;
        users[ownerWallet].levelExpired[5] = 77777777777;
        users[ownerWallet].levelExpired[6] = 77777777777;
        users[ownerWallet].levelExpired[7] = 77777777777;
        users[ownerWallet].levelExpired[8] = 77777777777;
    }

    function () public payable  {
        
        uint level;

        if(msg.value == LEVEL_PRICE[1]){
            level = 1;
        }else if(msg.value == LEVEL_PRICE[2]){
            level = 2;
        }else if(msg.value == LEVEL_PRICE[3]){
            level = 3;
        }else if(msg.value == LEVEL_PRICE[4]){
            level = 4;
        }else if(msg.value == LEVEL_PRICE[5]){
            level = 5;
        }else if(msg.value == LEVEL_PRICE[6]){
            level = 6;
        }else if(msg.value == LEVEL_PRICE[7]){
            level = 7;
        }else if(msg.value == LEVEL_PRICE[8]){
            level = 8;
        }else {
            revert(&#39;Incorrect Value send&#39;);
        }
        
        if(users[msg.sender].isExist){
            buyLevel(level);    
        } else if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);
            
            if (users[referrer].isExist){
                refId = users[referrer].id;
            } else {
                refId = currUserID;
            }
            
            regUser(refId);
        } else {
            revert("Please buy first level for 0.05 ETH");
        }
    }

    function regUser(uint _referrerID) public payable {
        require(!users[msg.sender].isExist, &#39;User exist&#39;);

        require(_referrerID > 0 && _referrerID <= currUserID, &#39;Incorrect referrer Id&#39;);

        require(msg.value>=LEVEL_PRICE[1], &#39;Incorrect Value&#39;);

        require(users[userList[_referrerID]].referral.length < REFERRER_1_LEVEL_LIMIT, &#39;Referrer already has three referrals&#39;);

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : _referrerID,
            referral : new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;
        users[msg.sender].levelExpired[2] = 0;
        users[msg.sender].levelExpired[3] = 0;
        users[msg.sender].levelExpired[4] = 0;
        users[msg.sender].levelExpired[5] = 0;
        users[msg.sender].levelExpired[6] = 0;
        users[msg.sender].levelExpired[7] = 0;
        users[msg.sender].levelExpired[8] = 0;

        users[userList[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender);
        
        emit regLevelEvent(msg.sender, userList[_referrerID],  now);
    }

    function buyLevel(uint _level) public payable {
        require(users[msg.sender].isExist, &#39;User not exist&#39;);

        require( _level>0 && _level<=8, &#39;Incorrect level&#39;);

        if(_level == 1){
            require(msg.value>=LEVEL_PRICE[1], &#39;Incorrect Value&#39;);
            users[msg.sender].levelExpired[1] += PERIOD_LENGTH;
        } else {
         
            require(msg.value>=LEVEL_PRICE[_level], &#39;Incorrect Value&#39;);

            require(users[msg.sender].levelExpired[_level-1] >= now,  &#39;Buy the previous level&#39;);
            if(users[msg.sender].levelExpired[_level] == 0){
                users[msg.sender].levelExpired[_level] =  now + PERIOD_LENGTH;
            } else {
                users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
            }
        }

        payForLevel(_level, msg.sender);
        emit buyLevelEvent(msg.sender, _level, now);
    }

    function payForLevel(uint _level, address _user) internal  {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        if(_level == 1 || _level == 5){
            referer = userList[users[_user].referrerID];
        } else if(_level == 2 || _level == 6){
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        } else if(_level == 3 || _level == 7){
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        } else if(_level == 4 || _level == 8){
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];            
        }
        
        if(!users[referer].isExist){
            referer = userList[1];
        }

        if(users[referer].levelExpired[_level] >= now ){
            referer.transfer(LEVEL_PRICE[_level]);
            emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
        } else {
            emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);
            payForLevel(_level,referer);
        }
    }


    function viewUserReferral(address _user) public view returns(address[]) {
        return users[_user].referral;
    }   

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return users[_user].levelExpired[_level];
    } 

    function withdraw() public onlyOwnerOrManager {
        owner.transfer(address(this).balance);
    }
    
    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }    
}