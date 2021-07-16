//SourceUnit: MeridianFinance.sol

pragma solidity >=0.5.10;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MeridianFinance {

  using SafeMath for uint256;

  struct User {
    uint256 id;
    address referrer;
    uint256 referralsCount;

    mapping(uint8 => bool) activeMatrixLevels;

    mapping(uint8 => MatrixStruct) matrix;

    bool autoReinvest;
  }

  struct MatrixStruct {
    address currentReferrer;
    address[] firstLevelReferrals;
    address[] secondLevelReferrals;
    bool blocked;
    uint256 reinvestCount;
    uint256 time;
    uint256 passiveIncomeReceived;

    address closedPart;
  }

  address private constant DEFAULT_ADDRESS_1 = address(0x415bae3217b8816bafbc07edf017bedee26a3b0f36); 
  address private constant DEFAULT_ADDRESS_2 = address(0x411a3fc5651735a5aea413426904e9ad6370413aae); 
  address private constant DEFAULT_ADDRESS_3 = address(0x4116a29b82883593080f095d2b4351cd3dab54f5ea); 

  mapping(address => MatrixStruct) public goldMatrix;
  uint256 public constant GOLD_MATRIX_PRICE = 50000 trx;

  uint8 public constant LAST_LEVEL = 12;

  uint256 public constant PASSIVE_INCOME_DAILY_PERCENT = 100; 
  uint256 public constant PASSIVE_INCOME_DAILY_PERCENT_ONE_REFERRAL = 75; 
  uint256 public constant PASSIVE_INCOME_DAILY_PERCENT_NO_REFERRALS = 50; 
  uint256 public constant PASSIVE_INCOME_MAX_PROFIT_PERCENT = 120; 

  mapping(address => User) public users;
  mapping(uint256 => address) public idToAddress;

  uint256 public lastUserId = 1;
  address public owner;
  bool private contractDeployed = false;

  mapping(uint8 => uint256) public levelPrice;
  mapping(uint8 => uint256) private commulativePrice;
  mapping(address => mapping(uint8 => uint256)) public matrixReferralsCount;

  uint256 uniqueIndex = 0;

  event Registration(address indexed user, address indexed referrer, uint256 indexed userId, uint256 referrerId, uint256 index);
  event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 level, uint256 index);
  event Upgrade(address indexed user, address indexed referrer, uint8 level, uint256 index);
  event NewUserPlace(address indexed user, address indexed referrer, address indexed usersReferrer, uint8 level, uint8 place, uint256 index);
  event MissedTRXReceive(address indexed receiver, address indexed from, uint8 level, uint256 index);
  event SentTRXDividends(address indexed from, address indexed receiver, uint8 level, uint256 amount, uint256 index);
  event SentExtraTRXDividends(address indexed from, address indexed receiver, uint8 level, uint256 index);
  event AutoReinvestFlagSwitch(address indexed user, bool flag);
  event PassiveIncomeWithdrawn(address indexed receiver, uint8 level, uint256 amount, uint256 index);
  event MatrixClosed(address indexed referrer, uint8 level, uint256 reinvestCount, uint256 index);

  event TreeRootReached(string indexed method, address indexed address1, address indexed address2, uint8 level);

  constructor() public {
    levelPrice[1] = 250 trx;
    commulativePrice[1] = levelPrice[1];
    for (uint8 i = 2; i <= LAST_LEVEL; i++) {
      levelPrice[i] = levelPrice[i-1] * 2;
      commulativePrice[i] = commulativePrice[i-1].add(levelPrice[i]);
    }

    owner = DEFAULT_ADDRESS_1;

    initUser(DEFAULT_ADDRESS_1, address(0x0), LAST_LEVEL, true);
  }

  function init() external {
    require(msg.sender == owner, "Only owner can call this method");
    require(!contractDeployed, "Contract is already initialized");

    initUser(DEFAULT_ADDRESS_2, DEFAULT_ADDRESS_1, LAST_LEVEL, true);
    initUser(DEFAULT_ADDRESS_3, DEFAULT_ADDRESS_2, LAST_LEVEL, true);

    contractDeployed = true;
  }

  function initUser(address userAddress, address referrerAddress, uint256 levelTo, bool openGoldMatrix) private {
    User memory user = User({
      id: lastUserId,
      referrer: referrerAddress,
      referralsCount: 0,
      autoReinvest: true
    });

    users[userAddress] = user;
    idToAddress[lastUserId] = userAddress;

    for (uint8 i = 1; i <= levelTo; i++) {
      users[userAddress].activeMatrixLevels[i] = true;
      users[userAddress].matrix[i].time = now;

      if (referrerAddress != address(0x0)) {
        updateMatrixReferrer(userAddress, referrerAddress, i);
      }
    }

    lastUserId++;

    if (referrerAddress != address(0x0)) {
      users[referrerAddress].referralsCount++;
    }

    emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, uniqueIndex++);

    
    if (openGoldMatrix) {
      address freeMatrixReferrer = referrerAddress;
      if (referrerAddress != address(0x0)) {
        freeMatrixReferrer = findFreeGoldMatrixReferrer(userAddress);
        updateGoldMatrixReferrer(userAddress, freeMatrixReferrer);
      }

      users[userAddress].activeMatrixLevels[0] = true;

      emit Upgrade(userAddress, freeMatrixReferrer, 0, uniqueIndex++);
    }
  }

  function autoRegistration(address userAddress, address referrerAddress, uint8 levelTo, bool openGoldMatrix) external payable {
    require(msg.sender == DEFAULT_ADDRESS_1, "Only owner can call this method");

    require(!isUserExists(userAddress), "User is already exists");
    require(isUserExists(referrerAddress), "Referrer is not registered");

    uint256 price = commulativePrice[levelTo];
    if (openGoldMatrix) {
      price = price.add(GOLD_MATRIX_PRICE);
    }
    require(msg.value == price, "Invalid auto-qualification TRX amount");

    initUser(userAddress, referrerAddress, levelTo, openGoldMatrix);
  }

  function registration(address referrerAddress) external payable {
    registration(msg.sender, referrerAddress);
  }

  function registration(address userAddress, address referrerAddress) private {
    require(msg.value == 250 trx, "registration cost 250 TRX");
    require(!isUserExists(userAddress), "user exists");
    if (referrerAddress == address(0x0) || referrerAddress == userAddress || !isUserExists(referrerAddress)) {
      referrerAddress = DEFAULT_ADDRESS_3;
    }

    uint32 size;
    assembly {
      size := extcodesize(userAddress)
    }
    require(size == 0, "cannot be a contract");

    User memory user = User({
      id: lastUserId,
      referrer: referrerAddress,
      referralsCount: 0,
      autoReinvest: true
    });

    users[userAddress] = user;
    idToAddress[lastUserId] = userAddress;

    users[userAddress].activeMatrixLevels[1] = true;
    users[userAddress].matrix[1].time = now;

    lastUserId++;

    users[referrerAddress].referralsCount++;

    updateMatrixReferrer(userAddress, findFreeMatrixReferrer(userAddress, 1), 1);

    emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, uniqueIndex++);
  }

  function newUserPlace(address user, address referrer, address usersReferrer, uint8 level, uint8 place) private {
    if (referrer == usersReferrer) {
      matrixReferralsCount[referrer][level]++;
    }

    emit NewUserPlace(user, referrer, usersReferrer, level, place, uniqueIndex++);
  }

  function buyNewLevel(uint8 level) external payable {
    require(isUserExists(msg.sender), "user is not exists. Register first.");
    require(msg.value == levelPrice[level], "invalid price");
    require(level > 1 && level <= LAST_LEVEL, "invalid level"); 

    require(!users[msg.sender].activeMatrixLevels[level], "level already activated"); 

    if (users[msg.sender].matrix[level-1].blocked) {
      users[msg.sender].matrix[level-1].blocked = false;
    }

    address freeMatrixReferrer = findFreeMatrixReferrer(msg.sender, level);

    users[msg.sender].activeMatrixLevels[level] = true;
    users[msg.sender].matrix[level].time = now;
    updateMatrixReferrer(msg.sender, freeMatrixReferrer, level);

    emit Upgrade(msg.sender, freeMatrixReferrer, level, uniqueIndex++);
  }

  function updateMatrixReferrer(address userAddress, address referrerAddress, uint8 level) private {
    require(users[referrerAddress].activeMatrixLevels[level], "Referrer level is inactive");

    if (users[referrerAddress].matrix[level].firstLevelReferrals.length < 2) {
      users[referrerAddress].matrix[level].firstLevelReferrals.push(userAddress);
      newUserPlace(userAddress, referrerAddress, users[userAddress].referrer, level, uint8(users[referrerAddress].matrix[level].firstLevelReferrals.length));

      
      users[userAddress].matrix[level].currentReferrer = referrerAddress;

      if (referrerAddress == owner) {
        return sendTRXDividends(referrerAddress, userAddress, level, 0, false);
      }

      address ref = users[referrerAddress].matrix[level].currentReferrer;      
      users[ref].matrix[level].secondLevelReferrals.push(userAddress); 

      uint256 len = users[ref].matrix[level].firstLevelReferrals.length;

      if ((len == 2) && 
        (users[ref].matrix[level].firstLevelReferrals[0] == referrerAddress) &&
        (users[ref].matrix[level].firstLevelReferrals[1] == referrerAddress)) {
        if (users[referrerAddress].matrix[level].firstLevelReferrals.length == 1) {
          newUserPlace(userAddress, ref, users[userAddress].referrer, level, 5);
        } else {
          newUserPlace(userAddress, ref, users[userAddress].referrer, level, 6);
        }
      }  else if ((len == 1 || len == 2) &&
          users[ref].matrix[level].firstLevelReferrals[0] == referrerAddress) {
        if (users[referrerAddress].matrix[level].firstLevelReferrals.length == 1) {
          newUserPlace(userAddress, ref, users[userAddress].referrer, level, 3);
        } else {
          newUserPlace(userAddress, ref, users[userAddress].referrer, level, 4);
        }
      } else if (len == 2 && users[ref].matrix[level].firstLevelReferrals[1] == referrerAddress) {
        if (users[referrerAddress].matrix[level].firstLevelReferrals.length == 1) {
          newUserPlace(userAddress, ref, users[userAddress].referrer, level, 5);
        } else {
          newUserPlace(userAddress, ref, users[userAddress].referrer, level, 6);
        }
      }

      return updateMatrixReferrerSecondLevel(userAddress, ref, level);
    }

    users[referrerAddress].matrix[level].secondLevelReferrals.push(userAddress);

    if (users[referrerAddress].matrix[level].closedPart != address(0)) {
      if ((users[referrerAddress].matrix[level].firstLevelReferrals[0] == 
        users[referrerAddress].matrix[level].firstLevelReferrals[1]) &&
        (users[referrerAddress].matrix[level].firstLevelReferrals[0] ==
        users[referrerAddress].matrix[level].closedPart)) {

        updateMatrix(userAddress, referrerAddress, level, true);
        return updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
      } else if (users[referrerAddress].matrix[level].firstLevelReferrals[0] == 
        users[referrerAddress].matrix[level].closedPart) {
        updateMatrix(userAddress, referrerAddress, level, true);
        return updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
      } else {
        updateMatrix(userAddress, referrerAddress, level, false);
        return updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
      }
    }

    if (users[referrerAddress].matrix[level].firstLevelReferrals[1] == userAddress) {
      updateMatrix(userAddress, referrerAddress, level, false);
      return updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
    } else if (users[referrerAddress].matrix[level].firstLevelReferrals[0] == userAddress) {
      updateMatrix(userAddress, referrerAddress, level, true);
      return updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    if (users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].matrix[level].firstLevelReferrals.length <= 
      users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.length) {
      updateMatrix(userAddress, referrerAddress, level, false);
    } else {
      updateMatrix(userAddress, referrerAddress, level, true);
    }

    updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
  }

  function updateMatrix(address userAddress, address referrerAddress, uint8 level, bool x2) private {
    if (!x2) {
      users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].matrix[level].firstLevelReferrals.push(userAddress);
      newUserPlace(userAddress, users[referrerAddress].matrix[level].firstLevelReferrals[0], users[userAddress].referrer, level, uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].matrix[level].firstLevelReferrals.length));
      newUserPlace(userAddress, referrerAddress, users[userAddress].referrer, level, 2 + uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].matrix[level].firstLevelReferrals.length));
      
      users[userAddress].matrix[level].currentReferrer = users[referrerAddress].matrix[level].firstLevelReferrals[0];
    } else {
      users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.push(userAddress);
      newUserPlace(userAddress, users[referrerAddress].matrix[level].firstLevelReferrals[1], users[userAddress].referrer, level, uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.length));
      newUserPlace(userAddress, referrerAddress, users[userAddress].referrer, level, 4 + uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.length));
      
      users[userAddress].matrix[level].currentReferrer = users[referrerAddress].matrix[level].firstLevelReferrals[1];
    }
  }

  function updateMatrixReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
    if (users[referrerAddress].matrix[level].secondLevelReferrals.length < 4) {
      
      return;
    }

    uint256 passiveIncomeReceived = 0;
    if (users[referrerAddress].matrix[level].reinvestCount == 0) {
      withdrawPassiveIncome(referrerAddress, level);
      passiveIncomeReceived = users[referrerAddress].matrix[level].passiveIncomeReceived;
    }

    if (!users[referrerAddress].autoReinvest || level == LAST_LEVEL) {
      users[referrerAddress].matrix[level].blocked = false;
      sendTRXDividends(referrerAddress, userAddress, level, passiveIncomeReceived, true);
    } else if (users[referrerAddress].activeMatrixLevels[level + 1]) {
      users[referrerAddress].matrix[level].blocked = false;
      sendTRXDividends(referrerAddress, userAddress, level, passiveIncomeReceived, true);
    } else { 
      
      
      if (level < LAST_LEVEL 
       && !users[referrerAddress].activeMatrixLevels[level + 1] 
       && passiveIncomeReceived == 0) { 
        if (users[referrerAddress].matrix[level].blocked) {
          users[referrerAddress].matrix[level].blocked = false;
        }

        address freeMatrixReferrer = findFreeMatrixReferrer(referrerAddress, level + 1);
        
        
        users[referrerAddress].activeMatrixLevels[level + 1] = true;
        users[referrerAddress].matrix[level + 1].time = now;
        updateMatrixReferrer(referrerAddress, freeMatrixReferrer, level + 1);

        emit Upgrade(referrerAddress, freeMatrixReferrer, level + 1, uniqueIndex++);
      } else {
        sendTRXDividends(referrerAddress, userAddress, level, passiveIncomeReceived, true);
      }
    }

    address[] memory x6 = users[users[referrerAddress].matrix[level].currentReferrer].matrix[level].firstLevelReferrals;

    if (x6.length == 2) {
      if (x6[0] == referrerAddress ||
        x6[1] == referrerAddress) {
        users[users[referrerAddress].matrix[level].currentReferrer].matrix[level].closedPart = referrerAddress;
      } else if (x6.length == 1) {
        if (x6[0] == referrerAddress) {
          users[users[referrerAddress].matrix[level].currentReferrer].matrix[level].closedPart = referrerAddress;
        }
      }
    }

    users[referrerAddress].matrix[level].firstLevelReferrals = new address[](0);
    users[referrerAddress].matrix[level].secondLevelReferrals = new address[](0);
    users[referrerAddress].matrix[level].closedPart = address(0);

    if (!users[referrerAddress].activeMatrixLevels[level+1] && level != LAST_LEVEL) {
      users[referrerAddress].matrix[level].blocked = true;
    }

    users[referrerAddress].matrix[level].reinvestCount++;
    emit MatrixClosed(referrerAddress, level, users[referrerAddress].matrix[level].reinvestCount, uniqueIndex++);
    
    if (referrerAddress != owner) {
      address freeReferrerAddress = findFreeMatrixReferrer(referrerAddress, level);

      emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, level, uniqueIndex++);
      updateMatrixReferrer(referrerAddress, freeReferrerAddress, level);
    } else {
      emit Reinvest(owner, address(0), userAddress, level, uniqueIndex++);
      sendTRXDividends(owner, userAddress, level, 0, false);
    }
  }
  
  function findFreeMatrixReferrer(address userAddress, uint8 level) public returns(address) {
    while (true) { 
      if (users[users[userAddress].referrer].activeMatrixLevels[level]) {
        return users[userAddress].referrer;
      }

      userAddress = users[userAddress].referrer;

      if (userAddress == address(0x0)) {
        emit TreeRootReached("findFreeMatrixReferrer", userAddress, address(0x0), level);

        return DEFAULT_ADDRESS_3;
      }
    }
  }

  function buyGoldMatrix() external payable {
    require(isUserExists(msg.sender), "user is not exists. Register first.");
    require(msg.value == GOLD_MATRIX_PRICE, "invalid price");

    require(users[msg.sender].activeMatrixLevels[0] == false, "gold matrix already activated"); 

    address freeMatrixReferrer = findFreeGoldMatrixReferrer(msg.sender);

    updateGoldMatrixReferrer(msg.sender, freeMatrixReferrer);

    users[msg.sender].activeMatrixLevels[0] = true;

    emit Upgrade(msg.sender, freeMatrixReferrer, 0, uniqueIndex++); 
  }

  function updateGoldMatrixReferrer(address userAddress, address referrerAddress) private {
    require(users[referrerAddress].activeMatrixLevels[0], "Referrer Gold Matrix is inactive");

    if (goldMatrix[referrerAddress].firstLevelReferrals.length < 2) {
      goldMatrix[referrerAddress].firstLevelReferrals.push(userAddress);
      newUserPlace(userAddress, referrerAddress, users[userAddress].referrer, 0, uint8(goldMatrix[referrerAddress].firstLevelReferrals.length));

      
      goldMatrix[userAddress].currentReferrer = referrerAddress;

      if (referrerAddress == owner) {
        return sendGoldMatrixTRXDividends(referrerAddress, userAddress);
      }

      address ref = goldMatrix[referrerAddress].currentReferrer;      
      goldMatrix[ref].secondLevelReferrals.push(userAddress); 

      uint256 len = goldMatrix[ref].firstLevelReferrals.length;

      if ((len == 2) && 
        (goldMatrix[ref].firstLevelReferrals[0] == referrerAddress) &&
        (goldMatrix[ref].firstLevelReferrals[1] == referrerAddress)) {
        if (goldMatrix[referrerAddress].firstLevelReferrals.length == 1) {
          newUserPlace(userAddress, ref, users[userAddress].referrer, 0, 5);
        } else {
          newUserPlace(userAddress, ref, users[userAddress].referrer, 0, 6);
        }
      }  else if ((len == 1 || len == 2) &&
          goldMatrix[ref].firstLevelReferrals[0] == referrerAddress) {
        if (goldMatrix[referrerAddress].firstLevelReferrals.length == 1) {
          newUserPlace(userAddress, ref, users[userAddress].referrer, 0, 3);
        } else {
          newUserPlace(userAddress, ref, users[userAddress].referrer, 0, 4);
        }
      } else if (len == 2 && goldMatrix[ref].firstLevelReferrals[1] == referrerAddress) {
        if (goldMatrix[referrerAddress].firstLevelReferrals.length == 1) {
          newUserPlace(userAddress, ref, users[userAddress].referrer, 0, 5);
        } else {
          newUserPlace(userAddress, ref, users[userAddress].referrer, 0, 6);
        }
      }

      return updateGoldMatrixReferrerSecondLevel(userAddress, ref);
    }

    goldMatrix[referrerAddress].secondLevelReferrals.push(userAddress);

    if (goldMatrix[referrerAddress].closedPart != address(0)) {
      if ((goldMatrix[referrerAddress].firstLevelReferrals[0] == 
        goldMatrix[referrerAddress].firstLevelReferrals[1]) &&
        (goldMatrix[referrerAddress].firstLevelReferrals[0] ==
        goldMatrix[referrerAddress].closedPart)) {

        updateGoldMatrix(userAddress, referrerAddress, true);
        return updateGoldMatrixReferrerSecondLevel(userAddress, referrerAddress);
      } else if (goldMatrix[referrerAddress].firstLevelReferrals[0] == 
        goldMatrix[referrerAddress].closedPart) {
        updateGoldMatrix(userAddress, referrerAddress, true);
        return updateGoldMatrixReferrerSecondLevel(userAddress, referrerAddress);
      } else {
        updateGoldMatrix(userAddress, referrerAddress, false);
        return updateGoldMatrixReferrerSecondLevel(userAddress, referrerAddress);
      }
    }

    if (goldMatrix[referrerAddress].firstLevelReferrals[1] == userAddress) {
      updateGoldMatrix(userAddress, referrerAddress, false);
      return updateGoldMatrixReferrerSecondLevel(userAddress, referrerAddress);
    } else if (goldMatrix[referrerAddress].firstLevelReferrals[0] == userAddress) {
      updateGoldMatrix(userAddress, referrerAddress, true);
      return updateGoldMatrixReferrerSecondLevel(userAddress, referrerAddress);
    }

    if (goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[0]].firstLevelReferrals.length <= 
      goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[1]].firstLevelReferrals.length) {
      updateGoldMatrix(userAddress, referrerAddress, false);
    } else {
      updateGoldMatrix(userAddress, referrerAddress, true);
    }

    updateGoldMatrixReferrerSecondLevel(userAddress, referrerAddress);
  }

  function updateGoldMatrix(address userAddress, address referrerAddress, bool x2) private {
    if (!x2) {
      goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[0]].firstLevelReferrals.push(userAddress);
      newUserPlace(userAddress, goldMatrix[referrerAddress].firstLevelReferrals[0], users[userAddress].referrer, 0, uint8(goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[0]].firstLevelReferrals.length));
      newUserPlace(userAddress, referrerAddress, users[userAddress].referrer, 0, 2 + uint8(goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[0]].firstLevelReferrals.length));
      
      goldMatrix[userAddress].currentReferrer = goldMatrix[referrerAddress].firstLevelReferrals[0];
    } else {
      goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[1]].firstLevelReferrals.push(userAddress);
      newUserPlace(userAddress, goldMatrix[referrerAddress].firstLevelReferrals[1], users[userAddress].referrer, 0, uint8(goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[1]].firstLevelReferrals.length));
      newUserPlace(userAddress, referrerAddress, users[userAddress].referrer, 0, 4 + uint8(goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[1]].firstLevelReferrals.length));
      
      goldMatrix[userAddress].currentReferrer = goldMatrix[referrerAddress].firstLevelReferrals[1];
    }
  }

  function updateGoldMatrixReferrerSecondLevel(address userAddress, address referrerAddress) private {
    if (goldMatrix[referrerAddress].secondLevelReferrals.length < 4) {
      return sendGoldMatrixTRXDividends(referrerAddress, userAddress);
    }

    address[] memory x6 = goldMatrix[goldMatrix[referrerAddress].currentReferrer].firstLevelReferrals;

    if (x6.length == 2) {
      if (x6[0] == referrerAddress ||
        x6[1] == referrerAddress) {
        goldMatrix[goldMatrix[referrerAddress].currentReferrer].closedPart = referrerAddress;
      } else if (x6.length == 1) {
        if (x6[0] == referrerAddress) {
          goldMatrix[goldMatrix[referrerAddress].currentReferrer].closedPart = referrerAddress;
        }
      }
    }

    goldMatrix[referrerAddress].firstLevelReferrals = new address[](0);
    goldMatrix[referrerAddress].secondLevelReferrals = new address[](0);
    goldMatrix[referrerAddress].closedPart = address(0);

    goldMatrix[referrerAddress].reinvestCount++;
    emit MatrixClosed(referrerAddress, 0, goldMatrix[referrerAddress].reinvestCount, uniqueIndex++);

    if (referrerAddress != owner) {
      address freeReferrerAddress = findFreeGoldMatrixReferrer(referrerAddress);

      emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 0, uniqueIndex++);
      updateGoldMatrixReferrer(referrerAddress, freeReferrerAddress);
    } else {
      emit Reinvest(owner, address(0), userAddress, 0, uniqueIndex++);
      sendGoldMatrixTRXDividends(owner, userAddress);
    }
  }

  function findFreeGoldMatrixReferrer(address userAddress) public returns(address) {
    while (true) { 
      if (users[users[userAddress].referrer].activeMatrixLevels[0]) {
        return users[userAddress].referrer;
      }

      userAddress = users[userAddress].referrer;

      if (userAddress == address(0x0)) {
        emit TreeRootReached("findFreeGoldMatrixReferrer", userAddress, address(0x0), 0);

        return DEFAULT_ADDRESS_3;
      }
    }
  }

  function usersActiveMatrixLevels(address userAddress, uint8 level) public view returns(bool) {
    return users[userAddress].activeMatrixLevels[level];
  }

  function usersMatrix(address userAddress, uint8 level) public view
    returns(
      address, address[] memory, address[] memory, bool, address, bool
    )
  {
    return (
      users[userAddress].matrix[level].currentReferrer,
      users[userAddress].matrix[level].firstLevelReferrals,
      users[userAddress].matrix[level].secondLevelReferrals,
      users[userAddress].matrix[level].blocked,
      users[userAddress].matrix[level].closedPart,
      users[userAddress].activeMatrixLevels[level]
    );
  }

  function getMatrixDetails(address userAddress, uint8 level) public view
    returns(
      uint256
    )
  {
    return (
      users[userAddress].matrix[level].reinvestCount
    );
  }

  function getMatrixesStatus(address userAddress) public view 
    returns(
      bool[13] memory status
    )
  {
    for (uint8 i = 0; i < 13; i++){
      status[i] = users[userAddress].activeMatrixLevels[i];
    }
  }

  function goldMatrixData(address userAddress) public view
    returns(
      address, address[] memory, address[] memory, bool, address, uint256
    )
  {
    return (
      goldMatrix[userAddress].currentReferrer,
      goldMatrix[userAddress].firstLevelReferrals,
      goldMatrix[userAddress].secondLevelReferrals,
      goldMatrix[userAddress].blocked,
      goldMatrix[userAddress].closedPart,
      goldMatrix[userAddress].time
    );
  }

  function isUserExists(address user) public view returns (bool) {
    return (users[user].id != 0);
  }

  function findTRXReceiver(address userAddress, address _from, uint8 level) private returns(address, bool) {
    address receiver = userAddress;
    bool isExtraDividends;
    while (true) { 
      if (users[receiver].matrix[level].blocked) {
        emit MissedTRXReceive(receiver, _from, level, uniqueIndex++);
        isExtraDividends = true;
        receiver = users[receiver].matrix[level].currentReferrer;

        if (receiver == address(0x0)) {
          emit TreeRootReached("findTRXReceiver", userAddress, _from, level);
          
          return (DEFAULT_ADDRESS_3, isExtraDividends);
        }
      } else {
        return (receiver, isExtraDividends);
      }
    }
  }

  function sendTRXDividends(address userAddress, address _from, uint8 level, uint256 passiveIncome, bool isNextLevel) private {
    if (!contractDeployed) {
      return;
    }

    (address receiver, bool isExtraDividends) = findTRXReceiver(userAddress, _from, level);

    uint256 amount = levelPrice[level];
    if (isNextLevel) {
      amount = amount.mul(2);
    }
    if (passiveIncome > 0) {
      if (amount > passiveIncome) {
        amount = amount.sub(passiveIncome);
      } else {
        amount = 0;
      }
    }

    if (amount > 0) {
      if (!address(uint160(receiver)).send(amount)) {
        revert("Insufficient funds on the contract balance");
      }
    }
    emit SentTRXDividends(_from, receiver, level, amount, uniqueIndex++);
    
    if (isExtraDividends) {
      emit SentExtraTRXDividends(_from, receiver, level, uniqueIndex++);
    }
  }

  function findGoldMatrixTRXReceiver(address userAddress, address _from) private returns(address, bool) {
    address receiver = userAddress;
    bool isExtraDividends;
    while (true) { 
      if (goldMatrix[receiver].blocked) {
        emit MissedTRXReceive(receiver, _from, 0, uniqueIndex++);
        isExtraDividends = true;
        receiver = goldMatrix[receiver].currentReferrer;

        if (receiver == address(0x0)) {
          emit TreeRootReached("findGoldMatrixTRXReceiver", userAddress, _from, 0);
          
          return (DEFAULT_ADDRESS_3, isExtraDividends);
        }
      } else {
        return (receiver, isExtraDividends);
      }
    }
  }

  function sendGoldMatrixTRXDividends(address userAddress, address _from) private {
    if (!contractDeployed) {
      return;
    }

    (address receiver, bool isExtraDividends) = findGoldMatrixTRXReceiver(userAddress, _from);

    if (!address(uint160(receiver)).send(GOLD_MATRIX_PRICE)) {
      revert("Insufficient funds on the contract balance");
    }
    emit SentTRXDividends(_from, receiver, 0, GOLD_MATRIX_PRICE, uniqueIndex++);
    
    if (isExtraDividends) {
      emit SentExtraTRXDividends(_from, receiver, 0, uniqueIndex++);
    }
  }

  
  function setAutoReinvest(bool _flag) public returns (bool) {
    if (users[msg.sender].autoReinvest != _flag) {
      users[msg.sender].autoReinvest = _flag;

      emit AutoReinvestFlagSwitch(msg.sender, _flag);

      return true;
    }

    return false;
  }

  function getPassiveIncome(address userAddress, uint8 level) public view returns (uint256) {
    User storage user = users[userAddress];

    if (!user.activeMatrixLevels[level]) {
      return 0;
    }

    if (user.matrix[level].reinvestCount > 0) {
      return 0;
    }

    if (user.matrix[level].time == 0) {
      return 0;
    }

    uint256 income = levelPrice[level]
      .mul(
        now.sub(user.matrix[level].time)
      )
      .mul(passiveIncomeDailyPercent(userAddress, level))
      .div(10000)
      .div(1 days);

    uint256 incomeLimit = (levelPrice[level].mul(PASSIVE_INCOME_MAX_PROFIT_PERCENT).div(100))
      .sub(user.matrix[level].passiveIncomeReceived);
    if (income > incomeLimit) {
      income = incomeLimit;
    }

    return income;
  }

  function getPassiveIncomes(address userAddress) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
    User storage user = users[userAddress];

    uint256[] memory incomes = new uint256[](13);
    uint256[] memory incomesReceived = new uint256[](13);
    uint256[] memory dailyPercents = new uint256[](13);

    for (uint8 level = 1; level <= LAST_LEVEL; level++) {
      dailyPercents[level] = passiveIncomeDailyPercent(userAddress, level);
      incomesReceived[level] = user.matrix[level].passiveIncomeReceived;

      if (!user.activeMatrixLevels[level]) {
        continue;
      }

      if (user.matrix[level].reinvestCount == 0) {
        if (user.matrix[level].time == 0) {
          continue;
        }

        incomes[level] = levelPrice[level]
          .mul(
            now.sub(user.matrix[level].time)
          )
          .mul(passiveIncomeDailyPercent(userAddress, level))
          .div(10000)
          .div(1 days);

        uint256 incomeLimit = (levelPrice[level].mul(PASSIVE_INCOME_MAX_PROFIT_PERCENT).div(100))
          .sub(incomesReceived[level]);
        if (incomes[level] > incomeLimit) {
          incomes[level] = incomeLimit;
        }
      }
    }

    return (incomes, incomesReceived, dailyPercents);
  }

  function withdrawPassiveIncome(address userAddress) private returns (uint256, uint256[] memory) {
    uint256[] memory incomes;
    uint256 income = 0;

    (incomes, ,) = getPassiveIncomes(userAddress);

    for (uint8 level = 1; level <= LAST_LEVEL; level++) {
      if (incomes[level] > 0) {
        users[userAddress].matrix[level].time = now;
        users[userAddress].matrix[level].passiveIncomeReceived = users[userAddress].matrix[level].passiveIncomeReceived.add(incomes[level]);

        emit PassiveIncomeWithdrawn(userAddress, level, incomes[level], uniqueIndex++);

        income = income.add(incomes[level]);
      }

      if (users[userAddress].matrix[level].time == 0) {
        users[userAddress].matrix[level].time = now;
      }
    }

    address(uint160(userAddress)).transfer(income);

    return (income, incomes);
  }

  function withdrawPassiveIncome(address userAddress, uint8 level) private returns (uint256) {
    uint256 income = getPassiveIncome(userAddress, level);

    if (users[userAddress].matrix[level].time == 0) {
      users[userAddress].matrix[level].time = now;
    }

    if (income == 0) {
      return 0;
    }

    users[userAddress].matrix[level].time = now;
    users[userAddress].matrix[level].passiveIncomeReceived = users[userAddress].matrix[level].passiveIncomeReceived.add(income);

    address(uint160(userAddress)).transfer(income);
    emit PassiveIncomeWithdrawn(userAddress, level, income, uniqueIndex++);

    return income;
  }

  function withdrawPassiveIncome() public returns (uint256, uint256[] memory) {
    return withdrawPassiveIncome(msg.sender);
  }

  function passiveIncomeDailyPercent(address userAddress, uint8 matrixLevel) private view returns (uint256) {
    if (matrixReferralsCount[userAddress][matrixLevel] > 1) {
      return PASSIVE_INCOME_DAILY_PERCENT;
    } else if (matrixReferralsCount[userAddress][matrixLevel] == 1) {
      return PASSIVE_INCOME_DAILY_PERCENT_ONE_REFERRAL;
    }

    return PASSIVE_INCOME_DAILY_PERCENT_NO_REFERRALS;
  }

  function turn() external {
    
  }

}