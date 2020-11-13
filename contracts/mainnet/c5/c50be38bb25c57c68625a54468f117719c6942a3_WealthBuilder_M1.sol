pragma solidity 0.5.16;

interface ERC20Interface {
  function transfer(address to, uint value) external returns(bool success);
  function transferFrom(address _from, address _to, uint256 value)  external returns(bool success);
  function Exchange_Price() external view returns(uint256 actual_Price);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract WealthBuilder_M1 {
  struct User {
    bool isExist;
    uint ID;
    uint ReferrerID;
    uint SponsorID;
    uint SubscriptionTime;
    uint64 ReferralCount;
    uint64 LvL1Count;
    uint64 LvL2Count;
    uint64 LvL3Count;
    uint64 LvL4Count;
    address[] Referrals;
    address[] Line1Referrals;
    address[] Line2Referrals;
    address[] Line3Referrals;
    address[] Line4Referrals;
    mapping (uint8 => uint) LevelExpiresAt;
  }
  struct Token_Reward {
    uint Total;
    uint8[]   Rewardtype;
    address[] ReferralAddr;
    uint256[] Amount;
    uint256[] RewardedAt;
  }
  struct ETH_Reward {
    uint Total;
    uint8[]   Rewardtype;
    address[] ReferralAddr;
    uint256[] Amount;
    uint256[] RewardedAt;
  }
  struct Purchased_Upgrade {
    uint Total;
    uint[]    pDate;
    uint8[]   LvL;
    uint32[]  EduPkg;
  }

  address public WBC_Wallet;
  uint256 public adminCount;
  uint  public MAX_LEVEL = 9;
  uint public REFERRALS_LIMIT = 2;
  uint public LEVEL_EXPIRE_TIME = 30 days;
  uint256 public TOKEN_PRICE = 0.001 ether;
  uint64 public currUserID = 0;
  uint8 public Loyalty_TokenReward;
  address public TOKEN_SC;
  address public TOKEN_ATM;
  address public TOKEN_EXCHNG;
  address[] public adminListed;
  mapping(address => User) public USERS;
  mapping(uint256 => address) public USER_ADDRESS;
  mapping(uint8 => uint256) public UPGRADE_PRICE;
  mapping(uint8 => uint8) public SPONSOR_REWARD;
  mapping(address => Purchased_Upgrade) public UPGRADE_PURCHASED;
  mapping(address => Token_Reward) public LOYALTY_BONUS;
  mapping(address => ETH_Reward) public SPONSOR_BONUS;
  mapping(address => uint256) public TOKEN_DEPOSITS;

  modifier validLevelAmount(uint8 _level) {
    require(msg.value == UPGRADE_PRICE[_level], 'Invalid level amount sent');
    _;
  }

  modifier userRegistered() {
    require(USERS[msg.sender].ID != 0, 'User does not exist');
    require(USERS[msg.sender].isExist, 'User does not exist');
    _;
  }
  modifier validReferrerID(uint _referrerID) {
    require(_referrerID > 0 && _referrerID <= currUserID, 'Invalid referrer ID');
    _;
  }

  modifier userNotRegistered() {
    require(USERS[msg.sender].ID == 0, 'User is already registered');
    require(!USERS[msg.sender].isExist, 'User does not exist');
    _;
  }

  modifier validLevel(uint _level) {
    require(_level > 0 && _level <= MAX_LEVEL, 'Invalid level entered');
    _;
  }

  constructor() public {
    TOKEN_SC = 0x79C90021A36250BcE01f11CFd847Ba30E05488B1;
    TOKEN_ATM = 0x12e26F7eEfF0602232b03a086343e9eF20825ec3;
    TOKEN_EXCHNG = 0x12e26F7eEfF0602232b03a086343e9eF20825ec3;
    WBC_Wallet = msg.sender;
    adminListed.push(msg.sender);
    adminCount = 1;
    UPGRADE_PRICE[1] = 0.05 ether;
    UPGRADE_PRICE[2] = 0.1 ether;
    UPGRADE_PRICE[3] = 0.5 ether;
    UPGRADE_PRICE[4] = 1 ether;
    UPGRADE_PRICE[5] = 1.5 ether;
    UPGRADE_PRICE[6] = 3 ether;
    UPGRADE_PRICE[7] = 7 ether;
    UPGRADE_PRICE[8] = 16 ether;
    UPGRADE_PRICE[9] = 34 ether;

    Loyalty_TokenReward = 23;

    SPONSOR_REWARD[1] = 20;
    SPONSOR_REWARD[2] = 10;
    SPONSOR_REWARD[3] = 5;
    SPONSOR_REWARD[4] = 2;

    addUser(msg.sender,1,1);
    for (uint8 i = 1; i <= MAX_LEVEL; i++) {
    USERS[msg.sender].LevelExpiresAt[i] = 88888888888;
    }
   }

  function () external payable {
    uint8 level;
    if(msg.value == UPGRADE_PRICE[1]) level = 1;
    else if(msg.value == UPGRADE_PRICE[2]) level = 2;
    else if(msg.value == UPGRADE_PRICE[3]) level = 3;
    else if(msg.value == UPGRADE_PRICE[4]) level = 4;
    else if(msg.value == UPGRADE_PRICE[5]) level = 5;
    else if(msg.value == UPGRADE_PRICE[6]) level = 6;
    else if(msg.value == UPGRADE_PRICE[7]) level = 7;
    else if(msg.value == UPGRADE_PRICE[8]) level = 8;
    else if(msg.value == UPGRADE_PRICE[9]) level = 9;
    else revert('Incorrect Value send');
    if(USERS[msg.sender].isExist) buyLevel(level,level);
      else if(level == 1) {
        uint refId = 1;
        address referrer = bytesToAddress(msg.data);
        if(USERS[referrer].isExist) refId = USERS[referrer].ID;
            else revert('Incorrect referrer');
        regUser(refId,1);
        }
        else revert('Please buy first level for 0.05 ETH');
  }

  function regUser(uint _referrerID, uint32 EduPkg) public payable userNotRegistered() validReferrerID(_referrerID) validLevelAmount(1){
    uint sponsorUP1_ID = _referrerID;
    address sponsorUP1 = USER_ADDRESS[sponsorUP1_ID];
    address sponsorUP2 = USER_ADDRESS[USERS[sponsorUP1].SponsorID];
    address sponsorUP3 = USER_ADDRESS[USERS[sponsorUP2].SponsorID];
    address sponsorUP4 = USER_ADDRESS[USERS[sponsorUP3].SponsorID];

    if(USERS[sponsorUP1].Referrals.length >= REFERRALS_LIMIT) {
        _referrerID = USERS[findFreeReferrer(sponsorUP1)].ID;
    }
    addUser(msg.sender, sponsorUP1_ID, _referrerID);
    USERS[msg.sender].LevelExpiresAt[1] = block.timestamp+LEVEL_EXPIRE_TIME;
    USERS[USER_ADDRESS[_referrerID]].Referrals.push(msg.sender);

    USERS[sponsorUP1].Line1Referrals.push(msg.sender);
    USERS[sponsorUP2].Line2Referrals.push(msg.sender);
    USERS[sponsorUP3].Line3Referrals.push(msg.sender);
    USERS[sponsorUP4].Line4Referrals.push(msg.sender);

    USERS[sponsorUP1].LvL1Count = USERS[sponsorUP1].LvL1Count+1;
    USERS[sponsorUP2].LvL2Count = USERS[sponsorUP2].LvL2Count+1;
    USERS[sponsorUP3].LvL3Count = USERS[sponsorUP3].LvL3Count+1;
    USERS[sponsorUP4].LvL4Count = USERS[sponsorUP4].LvL4Count+1;

    payMembers(msg.sender,sponsorUP1,sponsorUP2,sponsorUP3,sponsorUP4,1,EduPkg);
    addReferrerCount(USER_ADDRESS[_referrerID]);
  }

  function addUser(address New_Member, uint256 SponsorID, uint256 ReferrerID ) internal {
    currUserID++;
    USERS[New_Member] = User({
      isExist: true,
      ID: currUserID,
      ReferrerID: ReferrerID,
      SponsorID: SponsorID,
      ReferralCount: 0,
      LvL1Count:0,
      LvL2Count:0,
      LvL3Count:0,
      LvL4Count:0,
      SubscriptionTime: block.timestamp,
      Referrals: new address[](0),
      Line1Referrals: new address[](0),
      Line2Referrals: new address[](0),
      Line3Referrals: new address[](0),
      Line4Referrals: new address[](0)
    });
    USER_ADDRESS[currUserID] = New_Member;
  }

  function addReferrerCount(address Referrer) internal {
    bool isFinished = false;
    uint ID;
    for(uint8 i = 1;i<=13;i++){
        if(!isFinished){
            USERS[Referrer].ReferralCount = USERS[Referrer].ReferralCount+1;
            ID = USERS[Referrer].ID;
            if(ID==1) {isFinished = true;}
                else {Referrer = USER_ADDRESS[USERS[Referrer].ReferrerID];}
            }
        }
    }

  function buyLevel(uint8 _level, uint32 EduPkg) public payable validLevelAmount(_level) {
    require(USERS[msg.sender].isExist, 'User not exist');
    require(_level > 0 && _level <= 10, 'Incorrect level');
    for(uint8 l = 1; l < _level ; l++) require(USERS[msg.sender].LevelExpiresAt[l] >= block.timestamp,'Buy the previous level');

    address sponsorUP1 = USER_ADDRESS[USERS[msg.sender].SponsorID];
    address sponsorUP2 = USER_ADDRESS[USERS[sponsorUP1].SponsorID];
    address sponsorUP3 = USER_ADDRESS[USERS[sponsorUP2].SponsorID];
    address sponsorUP4 = USER_ADDRESS[USERS[sponsorUP3].SponsorID];

    USERS[msg.sender].LevelExpiresAt[_level] = block.timestamp+LEVEL_EXPIRE_TIME;
    payMembers(msg.sender,sponsorUP1,sponsorUP2,sponsorUP3,sponsorUP4,_level,EduPkg);
  }

  function findFreeReferrer(address _user) public view returns (address) {
    require(USERS[_user].isExist, 'User not exist');
    if (USERS[_user].Referrals.length < REFERRALS_LIMIT) {
      return _user;
    }
    address[16382] memory referrals;
    referrals[0] = USERS[_user].Referrals[0];
    referrals[1] = USERS[_user].Referrals[1];
    address referrer;
    for (uint16 i = 0; i < 16382; i++) {
      if (USERS[referrals[i]].Referrals.length < REFERRALS_LIMIT) {
        referrer = referrals[i];
        break;
      }
      if (i >= 8190) {continue;}
      referrals[(i+1)*2] = USERS[referrals[i]].Referrals[0];
      referrals[(i+1)*2+1] = USERS[referrals[i]].Referrals[1];
    }
    require(referrer != address(0), 'Referrer not found');
    return referrer;
  }

  function Reward_Loyality_Bonus(uint8 _level, address _user) internal returns(uint256 RewardedLoyalityBonus){
    require(USERS[_user].isExist, 'User not exist');
    uint _referrerID;
    address _referrerAddr;
    uint8 _referrerLevel;
    address user = _user;
    uint _uplines = _level+4;
    uint _LevelReward = (UPGRADE_PRICE[_level]*Loyalty_TokenReward/100)/_uplines;
    uint256 _amountToken = _LevelReward*(10**18)/TOKEN_PRICE;
    uint256 rewardedUplines = 0;
    for (uint8 i = 1; i <= _uplines; i++) {
      _referrerID = USERS[user].ReferrerID;
      _referrerAddr = USER_ADDRESS[_referrerID];
      _referrerLevel = getUserLevel(_referrerAddr);
      if( _referrerLevel < _level ) {
        Write_Loyalty_Bonus(0, _referrerAddr, _user, _amountToken);
      } else {
        TOKEN_DEPOSITS[TOKEN_SC] = TOKEN_DEPOSITS[TOKEN_SC] - (_amountToken);
        ERC20Interface ERC20Token = ERC20Interface(TOKEN_SC);
        ERC20Token.transfer(_referrerAddr, _amountToken);
        Write_Loyalty_Bonus(i, _referrerAddr, _user, _amountToken);
        rewardedUplines += 1;
      }
    user = _referrerAddr;
    }
    RewardedLoyalityBonus = _LevelReward*rewardedUplines;
    if (rewardedUplines>0){
      bool send = false;
      (send, ) = address(uint160(TOKEN_ATM)).call.value(RewardedLoyalityBonus)("");
    }
    return RewardedLoyalityBonus;
  }

  function Write_Loyalty_Bonus(uint8 _type, address _user, address _referralAddr, uint256 _reward ) internal {
	  LOYALTY_BONUS[_user].Rewardtype.push(_type);
	  LOYALTY_BONUS[_user].ReferralAddr.push(_referralAddr);
	  LOYALTY_BONUS[_user].Amount.push(_reward);
	  LOYALTY_BONUS[_user].RewardedAt.push(block.timestamp);
  }

  function Write_Sponsor_Bonus(uint8 _type, address _user, address _referralAddr, uint256 _reward ) internal {
	  SPONSOR_BONUS[_user].Rewardtype.push(_type);
	  SPONSOR_BONUS[_user].ReferralAddr.push(_referralAddr);
	  SPONSOR_BONUS[_user].Amount.push(_reward);
	  SPONSOR_BONUS[_user].RewardedAt.push(block.timestamp);
  }

  function paySponsor(address _user, address Sponsor,uint8 _level, uint8 _line, uint256 _remValue) internal returns(uint256 RemValue) {
    uint256 _Price = UPGRADE_PRICE[_level];
    uint256 _UPLevelReward = _Price*SPONSOR_REWARD[_line]/100;
    bool send = false;
    RemValue = _remValue;
    if ( getUserLevel(Sponsor) >= _level ){
      (send, ) = address(uint160(Sponsor)).call.value(_UPLevelReward)("");
      Write_Sponsor_Bonus(_line,Sponsor,_user,_UPLevelReward);
      RemValue = _remValue-_UPLevelReward;
    } else {
      Write_Sponsor_Bonus(0, Sponsor,_user,_UPLevelReward);
	  }
  }

  function payMembers(address _user,address spUP1,address spUP2,address spUP3,address spUP4,uint8 _level,uint32 EduPkg) internal {
    uint256 _remValue = UPGRADE_PRICE[_level];
    _remValue = paySponsor(_user,spUP1,_level,1,_remValue);
    _remValue = paySponsor(_user,spUP2,_level,2,_remValue);
    _remValue = paySponsor(_user,spUP3,_level,3,_remValue);
    _remValue = paySponsor(_user,spUP4,_level,4,_remValue);
    _remValue = _remValue - Reward_Loyality_Bonus(_level, _user);
    UPGRADE_PURCHASED[_user].pDate.push(block.timestamp);
    UPGRADE_PURCHASED[_user].LvL.push(_level);
    UPGRADE_PURCHASED[_user].EduPkg.push(EduPkg);
    bool send = false;
    (send, ) = address(uint160(WBC_Wallet)).call.value(_remValue)("");
  }

    function isAdminListed(address _maker) public view returns (bool) {
        require(_maker != address(0));
        bool status = false;
        for(uint256 i=0;i<adminCount;i++){
            if(adminListed[i] == _maker) { status = true; }
        }
        return status;
    }

  function listAdmins() public view returns (address[] memory) {
    require(isAdminListed(msg.sender),'Only Admins');
    address[] memory _adminList = new address[](adminCount);
    for(uint i = 0; i<adminCount ; i++){
      _adminList[i] = adminListed[i];
    }
    return _adminList;
  }

      function addAdminList (address _adminUser) public {
        require(_adminUser != address(0));
        require(!isAdminListed(_adminUser));
        adminListed.push(_adminUser);
        adminCount++;
    }

    function removeAdminList (address _clearedAdmin) public {
        require(isAdminListed(msg.sender),'Only Admins');
        require(isAdminListed(_clearedAdmin) && _clearedAdmin != msg.sender);
        for(uint256 i = 0 ;i<adminCount;i++){
            if(adminListed[i] == _clearedAdmin) {
                adminListed[i] = adminListed[adminListed.length-1];
                delete adminListed[adminListed.length-1];
                adminCount--;
            }
        }
    }

  function getUserReferrals(address _User,uint _Pos) public view returns (address referral)
    { return(USERS[_User].Referrals[_Pos]); }

  function getLine1Ref(address _User, uint _Pos) public view returns (address referral)
    { return USERS[_User].Line1Referrals[_Pos]; }

  function getLine2Ref(address _User, uint _Pos) public view returns (address referral)
    { return USERS[_User].Line2Referrals[_Pos]; }

  function getLine3Ref(address _User, uint _Pos) public view returns (address referral)
    { return USERS[_User].Line3Referrals[_Pos]; }

  function getLine4Ref(address _User, uint _Pos) public view returns (address referral)
    { return USERS[_User].Line4Referrals[_Pos]; }

  function getUserLevelExpiresAt(address _user, uint8 _level) public view returns (uint)
    { return USERS[_user].LevelExpiresAt[_level];}

  function getUserLevel (address _user) public view returns (uint8) {
    if (getUserLevelExpiresAt(_user, 1) < block.timestamp) {return (0);}
    else if (getUserLevelExpiresAt(_user, 2) < block.timestamp) {return (1);}
    else if (getUserLevelExpiresAt(_user, 3) < block.timestamp) {return (2);}
    else if (getUserLevelExpiresAt(_user, 4) < block.timestamp) {return (3);}
    else if (getUserLevelExpiresAt(_user, 5) < block.timestamp) {return (4);}
    else if (getUserLevelExpiresAt(_user, 6) < block.timestamp) {return (5);}
    else if (getUserLevelExpiresAt(_user, 7) < block.timestamp) {return (6);}
    else if (getUserLevelExpiresAt(_user, 8) < block.timestamp) {return (7);}
    else if (getUserLevelExpiresAt(_user, 9) < block.timestamp) {return (8);}
    else  {return (9);}
    }

  function getPkgPurchased(address _User, uint _Pos)
    public view returns (uint8 LvL,uint pDate,uint32 EduPkg) {
    return (
      UPGRADE_PURCHASED[_User].LvL[_Pos],
      UPGRADE_PURCHASED[_User].pDate[_Pos],
      UPGRADE_PURCHASED[_User].EduPkg[_Pos]
  );}

  function getLOYALTY_BONUS(address _User, uint _Pos)
  public view returns(uint8 Rewardtype,uint256 Amount,uint256 RewardedAt,address ReferralAddr){
    return (
      LOYALTY_BONUS[_User].Rewardtype[_Pos],
      LOYALTY_BONUS[_User].Amount[_Pos],
      LOYALTY_BONUS[_User].RewardedAt[_Pos],
      LOYALTY_BONUS[_User].ReferralAddr[_Pos]
  );}

  function getSPONSOR_BONUS(address _User, uint _Pos)
  public view returns(uint8 Rewardtype,uint256 Amount,uint256 RewardedAt,address ReferralAddr){
    return (
      SPONSOR_BONUS[_User].Rewardtype[_Pos],
      SPONSOR_BONUS[_User].Amount[_Pos],
      SPONSOR_BONUS[_User].RewardedAt[_Pos],
      SPONSOR_BONUS[_User].ReferralAddr[_Pos]
  );}

  function set_TOKEN_SC_Address (address _tokenSCAddress) public {
      require(isAdminListed(msg.sender),'Only Admins');
      TOKEN_SC = _tokenSCAddress;}

  function set_TOKEN_ATM_Address (address _tokenATM_Address) public {
      require(isAdminListed(msg.sender),'Only Admins');
      TOKEN_ATM = _tokenATM_Address;}
      
  function set_TOKEN_EXCHNG_Address (address _exchngSCAddress) public { 
      require(isAdminListed(msg.sender),'Only Admins');
      TOKEN_EXCHNG  = _exchngSCAddress;}

  function set_Owner_Address (address _WBC_Address) public {
      require(isAdminListed(msg.sender),'Only Admins');
      WBC_Wallet = _WBC_Address;}

  function bytesToAddress(bytes memory bys) private pure returns (address addr) {assembly {addr := mload(add(bys,20))}}

  function set_Exchange_Price() public {
    ERC20Interface ERC20Exchng = ERC20Interface(TOKEN_EXCHNG);
    TOKEN_PRICE = ERC20Exchng.Exchange_Price();}

  function depositToken(uint256 _amount) public {
    ERC20Interface ERC20Token = ERC20Interface(TOKEN_SC);
    require(ERC20Token.transferFrom(msg.sender, address(this),_amount),'Token Transfer failed !');
    TOKEN_DEPOSITS[TOKEN_SC] = TOKEN_DEPOSITS[TOKEN_SC]+_amount;}

  function getUserID(address _user) public view returns(uint256 userID) {return userID = USERS[_user].ID;}
  function viewUserReferral(address _user) public view returns(address[] memory) {return USERS[_user].Referrals;}
  function getETHBalance() public view returns (uint256 _ETHBalance) {
      require(isAdminListed(msg.sender),'Only Admins');
      return address(this).balance;}
}