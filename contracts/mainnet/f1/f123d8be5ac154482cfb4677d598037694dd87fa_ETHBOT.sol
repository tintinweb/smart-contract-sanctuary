pragma solidity 0.4.25;

contract Auth {

  address internal mainAdmin;
  address internal backupAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(
    address _mainAdmin,
    address _backupAdmin
  ) internal {
    mainAdmin = _mainAdmin;
    backupAdmin = _backupAdmin;
  }

  modifier onlyMainAdmin() {
    require(isMainAdmin(), "onlyMainAdmin");
    _;
  }

  modifier onlyBackupAdmin() {
    require(isBackupAdmin(), "onlyBackupAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyBackupAdmin internal {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }

  function isBackupAdmin() public view returns (bool) {
    return msg.sender == backupAdmin;
  }
}

contract ETHBOT is Auth {

  struct User {
    bool isExist;
    uint id;
    uint referrerID;
    address[] referral;
    mapping(uint => uint) levelExpired;
    uint level;
  }

  uint REFERRER_1_LEVEL_LIMIT = 2;
  uint PERIOD_LENGTH = 100 days;
  uint public totalUser = 1;

  mapping(uint => uint) public LEVEL_PRICE;

  mapping (address => User) public users;
  mapping (uint => address) public userLists;
  uint public userIdCounter = 0;
  address cAccount;

  event Registered(address indexed user, address indexed inviter, uint id, uint time);
  event LevelBought(address indexed user, uint indexed id, uint level, uint time);
  event MoneyReceived(address indexed user, uint indexed id, address indexed from, uint level, uint amount, uint time);
  event MoneyMissed(address indexed user, uint indexed id, address indexed from, uint level, uint amount, uint time);

  constructor(
    address _rootAccount,
    address _cAccount,
    address _backupAdmin
  )
  public
  Auth(msg.sender, _backupAdmin)
  {
    LEVEL_PRICE[1] = 0.05 ether;
    LEVEL_PRICE[2] = 0.08 ether;
    LEVEL_PRICE[3] = 0.2 ether;
    LEVEL_PRICE[4] = 1 ether;
    LEVEL_PRICE[5] = 3 ether;
    LEVEL_PRICE[6] = 8 ether;
    LEVEL_PRICE[7] = 16 ether;
    LEVEL_PRICE[8] = 31 ether;
    LEVEL_PRICE[9] = 60 ether;
    LEVEL_PRICE[10] = 120 ether;

    User memory user;

    user = User({
      isExist: true,
      id: userIdCounter,
      referrerID: 0,
      referral: new address[](0),
      level: 1
    });
    users[_rootAccount] = user;
    userLists[userIdCounter] = _rootAccount;
    cAccount = _cAccount;
  }

  function updateMainAdmin(address _admin) public {
    transferOwnership(_admin);
  }

  function updateCAccount(address _cAccount) onlyMainAdmin public {
    cAccount = _cAccount;
  }

  function () external payable {
    uint level;

    if(msg.value == LEVEL_PRICE[1]) level = 1;
    else if(msg.value == LEVEL_PRICE[2]) level = 2;
    else if(msg.value == LEVEL_PRICE[3]) level = 3;
    else if(msg.value == LEVEL_PRICE[4]) level = 4;
    else if(msg.value == LEVEL_PRICE[5]) level = 5;
    else if(msg.value == LEVEL_PRICE[6]) level = 6;
    else if(msg.value == LEVEL_PRICE[7]) level = 7;
    else if(msg.value == LEVEL_PRICE[8]) level = 8;
    else if(msg.value == LEVEL_PRICE[9]) level = 9;
    else if(msg.value == LEVEL_PRICE[10]) level = 10;
    else revert('Incorrect Value send');

    if(users[msg.sender].isExist) buyLevel(level);
    else if(level == 1) {
      uint refId = 0;
      address referrer = bytesToAddress(msg.data);

      if(users[referrer].isExist) refId = users[referrer].id;
      else revert('Incorrect referrer');

      regUser(refId);
    }
    else revert('Please buy first level for 0.05 ETH');
  }

  function regUser(uint _referrerID) public payable {
    require(!users[msg.sender].isExist, 'User exist');
    require(_referrerID >= 0 && _referrerID <= userIdCounter, 'Incorrect referrer Id');
    require(msg.value == LEVEL_PRICE[1], 'Incorrect Value');

    if(users[userLists[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT) _referrerID = users[findFreeReferrer(userLists[_referrerID])].id;

    User memory user;
    userIdCounter++;

    user = User({
      isExist: true,
      id: userIdCounter,
      referrerID: _referrerID,
      referral: new address[](0),
      level: 1
    });

    users[msg.sender] = user;
    userLists[userIdCounter] = msg.sender;

    users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;

    users[userLists[_referrerID]].referral.push(msg.sender);
    totalUser += 1;
    emit Registered(msg.sender, userLists[_referrerID], userIdCounter, now);

    payForLevel(1, msg.sender);
  }

  function buyLevel(uint _level) public payable {
    require(users[msg.sender].isExist, 'User not exist');
    require(_level > 0 && _level <= 10, 'Incorrect level');

    if(_level == 1) {
      require(msg.value == LEVEL_PRICE[1], 'Incorrect Value');
      users[msg.sender].levelExpired[1] += PERIOD_LENGTH;
    }
    else {
      require(msg.value == LEVEL_PRICE[_level], 'Incorrect Value');

      for(uint l =_level - 1; l > 0; l--) require(users[msg.sender].levelExpired[l] >= now, 'Buy the previous level');

      if(users[msg.sender].levelExpired[_level] == 0 || users[msg.sender].levelExpired[_level] < now) {
        users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
      } else {
        users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
      }
    }
    users[msg.sender].level = _level;
    emit LevelBought(msg.sender, users[msg.sender].id, _level, now);

    payForLevel(_level, msg.sender);
  }

  function payForLevel(uint _level, address _user) internal {
    address referer;
    address referer1;
    address referer2;
    address referer3;
    address referer4;

    if(_level == 1 || _level == 6) {
      referer = userLists[users[_user].referrerID];
    }
    else if(_level == 2 || _level == 7) {
      referer1 = userLists[users[_user].referrerID];
      referer = userLists[users[referer1].referrerID];
    }
    else if(_level == 3 || _level == 8) {
      referer1 = userLists[users[_user].referrerID];
      referer2 = userLists[users[referer1].referrerID];
      referer = userLists[users[referer2].referrerID];
    }
    else if(_level == 4 || _level == 9) {
      referer1 = userLists[users[_user].referrerID];
      referer2 = userLists[users[referer1].referrerID];
      referer3 = userLists[users[referer2].referrerID];
      referer = userLists[users[referer3].referrerID];
    }
    else if(_level == 5 || _level == 10) {
      referer1 = userLists[users[_user].referrerID];
      referer2 = userLists[users[referer1].referrerID];
      referer3 = userLists[users[referer2].referrerID];
      referer4 = userLists[users[referer3].referrerID];
      referer = userLists[users[referer4].referrerID];
    }

    if(users[referer].isExist && users[referer].id > 0) {
      bool sent = false;
      if(users[referer].levelExpired[_level] >= now && users[referer].level == _level) {
        sent = address(uint160(referer)).send(LEVEL_PRICE[_level]);

        if (sent) {
          emit MoneyReceived(referer, users[referer].id, msg.sender, _level, LEVEL_PRICE[_level], now);
        }
      }
      if(!sent) {
        emit MoneyMissed(referer, users[referer].id, msg.sender, _level, LEVEL_PRICE[_level], now);

        payForLevel(_level, referer);
      }
    } else {
      cAccount.transfer(LEVEL_PRICE[_level]);
    }
  }

  function findFreeReferrer(address _user) public view returns(address) {
    if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) return _user;

    address[] memory referrals = new address[](126);
    referrals[0] = users[_user].referral[0];
    referrals[1] = users[_user].referral[1];

    address freeReferrer;
    bool noFreeReferrer = true;

    for(uint i = 0; i < 126; i++) {
      if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
        if(i < 62) {
          referrals[(i+1)*2] = users[referrals[i]].referral[0];
          referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
        }
      }
      else {
        noFreeReferrer = false;
        freeReferrer = referrals[i];
        break;
      }
    }

    require(!noFreeReferrer, 'No Free Referrer');

    return freeReferrer;
  }

  function viewUserReferral(address _user) public view returns(address[] memory) {
    return users[_user].referral;
  }

  function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
    return users[_user].levelExpired[_level];
  }

  function showMe() public view returns (bool, uint, uint) {
    User storage user = users[msg.sender];
    return (user.isExist, user.id, user.level);
  }

  function levelData() public view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
    return (
      users[msg.sender].levelExpired[1],
      users[msg.sender].levelExpired[2],
      users[msg.sender].levelExpired[3],
      users[msg.sender].levelExpired[4],
      users[msg.sender].levelExpired[5],
      users[msg.sender].levelExpired[6],
      users[msg.sender].levelExpired[7],
      users[msg.sender].levelExpired[8],
      users[msg.sender].levelExpired[9],
      users[msg.sender].levelExpired[10]
    );
  }

  function bytesToAddress(bytes memory bys) private pure returns (address addr) {
    assembly {
      addr := mload(add(bys, 20))
    }
  }
}