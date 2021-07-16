//SourceUnit: Matrix.sol

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

contract Matrix {

  using SafeMath for uint256;

  struct User {
    uint256 id;
    address referrer;
    uint256 referralsCount;

    mapping(uint8 => bool) activeMatrixLevels;

    mapping(uint8 => MatrixStruct) matrix;

    bool autoReinvest;
    bool autoReinvestGoldMatrix;
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

  mapping(address => MatrixStruct) public goldMatrix;
  uint256 GOLD_MATRIX_PRICE = 10 trx; 

  uint8 public constant LAST_LEVEL = 12; 

  uint256 PASSIVE_INCOME_DAILY_PERCENT = 1; 
  uint256 PASSIVE_INCOME_MAX_PROFIT_PERCENT = 120; 
  
  mapping(address => User) public users;
  mapping(uint256 => address) public idToAddress;
  mapping(address => uint256) public balances; 

  uint256 public lastUserId = 2;
  address public owner;
  
  mapping(uint8 => uint256) public levelPrice;
  
  event Registration(address indexed user, address indexed referrer, uint256 indexed userId, uint256 referrerId);
  event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 level);
  event Upgrade(address indexed user, address indexed referrer, uint8 level);
  event NewUserPlace(address indexed user, address indexed referrer, address indexed usersReferrer, uint8 level, uint8 place);
  event MissedTRXReceive(address indexed receiver, address indexed from, uint8 level);
  event SentTRXDividends(address indexed from, address indexed receiver, uint8 level, uint256 amount);
  event SentExtraTRXDividends(address indexed from, address indexed receiver, uint8 level);
  event AutoReinvestFlagSwitch(address indexed user, bool flag);
  event AutoReinvestGoldMatrixFlagSwitch(address indexed user, bool flag);
  event PassiveIncomeWithdrawn(address indexed receiver, uint8 level, uint256 amount);
  
  constructor() public {
    levelPrice[1] = 1 trx;
    for (uint8 i = 2; i <= LAST_LEVEL; i++) {
      levelPrice[i] = levelPrice[i-1] * 2;
    }
    
    owner = msg.sender;
    
    User memory user = User({
      id: 1,
      referrer: address(0),
      referralsCount: uint256(0),
      autoReinvest: true,
      autoReinvestGoldMatrix: true
    });
    
    users[owner] = user;
    idToAddress[1] = owner;
    
    for (uint8 i = 1; i <= LAST_LEVEL; i++) {
      users[owner].activeMatrixLevels[i] = true;
      users[owner].matrix[i].time = now;
    }

    goldMatrix[owner].time = now;
    goldMatrix[owner].firstLevelReferrals.push(owner);
    goldMatrix[owner].firstLevelReferrals.push(owner);
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner, "not owner");
    _;
  }

  function registration(address referrerAddress) external payable {
    registration(msg.sender, referrerAddress);
  }

  function withdrawContractBalance() external onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function registration(address userAddress, address referrerAddress) private {
    require(msg.value == 1 trx, "registration cost 1 TRX");
    require(!isUserExists(userAddress), "user exists");
    require(isUserExists(referrerAddress), "referrer not exists");
    
    uint32 size;
    assembly {
      size := extcodesize(userAddress)
    }
    require(size == 0, "cannot be a contract");
    
    User memory user = User({
      id: lastUserId,
      referrer: referrerAddress,
      referralsCount: 0,
      autoReinvest: true,
      autoReinvestGoldMatrix: true
    });
    
    users[userAddress] = user;
    idToAddress[lastUserId] = userAddress;

    users[userAddress].activeMatrixLevels[1] = true;
    users[userAddress].matrix[1].time = now;
    
    lastUserId++;
    
    users[referrerAddress].referralsCount++;

    updateMatrixReferrer(userAddress, findFreeMatrixReferrer(userAddress, 1), 1);
    
    emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
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
    
    emit Upgrade(msg.sender, freeMatrixReferrer, level);
  }

  function updateMatrixReferrer(address userAddress, address referrerAddress, uint8 level) private {
    require(users[referrerAddress].activeMatrixLevels[level], "Referrer level is inactive");
    
    if (users[referrerAddress].matrix[level].firstLevelReferrals.length < 2) {
      users[referrerAddress].matrix[level].firstLevelReferrals.push(userAddress);
      emit NewUserPlace(userAddress, referrerAddress, users[userAddress].referrer, level, uint8(users[referrerAddress].matrix[level].firstLevelReferrals.length));
      
      
      users[userAddress].matrix[level].currentReferrer = referrerAddress;

      if (referrerAddress == owner) {
        return sendTRXDividends(referrerAddress, userAddress, level, 0);
      }
      
      address ref = users[referrerAddress].matrix[level].currentReferrer;      
      users[ref].matrix[level].secondLevelReferrals.push(userAddress); 
      
      uint256 len = users[ref].matrix[level].firstLevelReferrals.length;
      
      if ((len == 2) && 
        (users[ref].matrix[level].firstLevelReferrals[0] == referrerAddress) &&
        (users[ref].matrix[level].firstLevelReferrals[1] == referrerAddress)) {
        if (users[referrerAddress].matrix[level].firstLevelReferrals.length == 1) {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, level, 5);
        } else {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, level, 6);
        }
      }  else if ((len == 1 || len == 2) &&
          users[ref].matrix[level].firstLevelReferrals[0] == referrerAddress) {
        if (users[referrerAddress].matrix[level].firstLevelReferrals.length == 1) {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, level, 3);
        } else {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, level, 4);
        }
      } else if (len == 2 && users[ref].matrix[level].firstLevelReferrals[1] == referrerAddress) {
        if (users[referrerAddress].matrix[level].firstLevelReferrals.length == 1) {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, level, 5);
        } else {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, level, 6);
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
      emit NewUserPlace(userAddress, users[referrerAddress].matrix[level].firstLevelReferrals[0], users[userAddress].referrer, level, uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].matrix[level].firstLevelReferrals.length));
      emit NewUserPlace(userAddress, referrerAddress, users[userAddress].referrer, level, 2 + uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].matrix[level].firstLevelReferrals.length));
      
      users[userAddress].matrix[level].currentReferrer = users[referrerAddress].matrix[level].firstLevelReferrals[0];
    } else {
      users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.push(userAddress);
      emit NewUserPlace(userAddress, users[referrerAddress].matrix[level].firstLevelReferrals[1], users[userAddress].referrer, level, uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.length));
      emit NewUserPlace(userAddress, referrerAddress, users[userAddress].referrer, level, 4 + uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.length));
      
      users[userAddress].matrix[level].currentReferrer = users[referrerAddress].matrix[level].firstLevelReferrals[1];
    }
  }
  
  function updateMatrixReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
    if (users[referrerAddress].matrix[level].secondLevelReferrals.length < 4) {
      
      return;
    }

    uint256 passiveIncome = 0;
    if (users[referrerAddress].matrix[level].reinvestCount == 0) {
      passiveIncome = withdrawPassiveIncome(referrerAddress);
    }

    if (!users[referrerAddress].autoReinvest || level == LAST_LEVEL) {
      sendTRXDividends(referrerAddress, userAddress, level, passiveIncome);
    } else if (users[referrerAddress].activeMatrixLevels[level + 1]) {
      sendTRXDividends(referrerAddress, userAddress, level + 1, passiveIncome);
    } else { 
      require(level < LAST_LEVEL, "Reinvest: invalid level");
      require(!users[referrerAddress].activeMatrixLevels[level + 1], "Reinvest: level already activated"); 

      if (users[referrerAddress].matrix[level].blocked) {
        users[referrerAddress].matrix[level].blocked = false;
      }

      address freeMatrixReferrer = findFreeMatrixReferrer(referrerAddress, level + 1);
      
      
      users[referrerAddress].activeMatrixLevels[level + 1] = true;
      users[referrerAddress].matrix[level + 1].time = now;
      updateMatrixReferrer(referrerAddress, freeMatrixReferrer, level + 1);
      
      emit Upgrade(referrerAddress, freeMatrixReferrer, level + 1);
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
    
    if (referrerAddress != owner) {
      address freeReferrerAddress = findFreeMatrixReferrer(referrerAddress, level);

      emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, level);
      updateMatrixReferrer(referrerAddress, freeReferrerAddress, level);
    } else {
      emit Reinvest(owner, address(0), userAddress, level);
      sendTRXDividends(owner, userAddress, level, 0);
    }
  }
  
  function findFreeMatrixReferrer(address userAddress, uint8 level) public view returns(address) {
    while (true) { 
      if (users[users[userAddress].referrer].activeMatrixLevels[level]) {
        return users[userAddress].referrer;
      }
      
      userAddress = users[userAddress].referrer;
    }
  }

  function buyGoldMatrix() external payable {
    require(isUserExists(msg.sender), "user is not exists. Register first.");
    require(msg.value == GOLD_MATRIX_PRICE, "invalid price");

    require(goldMatrix[msg.sender].time == 0, "gold matrix already activated"); 

    address freeMatrixReferrer = findFreeGoldMatrixReferrer(msg.sender);
    
    goldMatrix[msg.sender].time = now;
    updateGoldMatrixReferrer(msg.sender, freeMatrixReferrer);
    
    emit Upgrade(msg.sender, freeMatrixReferrer, 0); 
  }

  function updateGoldMatrixReferrer(address userAddress, address referrerAddress) private {
    require(goldMatrix[referrerAddress].time > 0, "Referrer Gold Matrix is inactive");
    
    if (goldMatrix[referrerAddress].firstLevelReferrals.length < 2) {
      goldMatrix[referrerAddress].firstLevelReferrals.push(userAddress);
      emit NewUserPlace(userAddress, referrerAddress, users[userAddress].referrer, 0, uint8(goldMatrix[referrerAddress].firstLevelReferrals.length));
      
      
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
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, 0, 5);
        } else {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, 0, 6);
        }
      }  else if ((len == 1 || len == 2) &&
          goldMatrix[ref].firstLevelReferrals[0] == referrerAddress) {
        if (goldMatrix[referrerAddress].firstLevelReferrals.length == 1) {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, 0, 3);
        } else {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, 0, 4);
        }
      } else if (len == 2 && goldMatrix[ref].firstLevelReferrals[1] == referrerAddress) {
        if (goldMatrix[referrerAddress].firstLevelReferrals.length == 1) {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, 0, 5);
        } else {
          emit NewUserPlace(userAddress, ref, users[userAddress].referrer, 0, 6);
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
      emit NewUserPlace(userAddress, goldMatrix[referrerAddress].firstLevelReferrals[0], users[userAddress].referrer, 0, uint8(goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[0]].firstLevelReferrals.length));
      emit NewUserPlace(userAddress, referrerAddress, users[userAddress].referrer, 0, 2 + uint8(goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[0]].firstLevelReferrals.length));
      
      goldMatrix[userAddress].currentReferrer = goldMatrix[referrerAddress].firstLevelReferrals[0];
    } else {
      goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[1]].firstLevelReferrals.push(userAddress);
      emit NewUserPlace(userAddress, goldMatrix[referrerAddress].firstLevelReferrals[1], users[userAddress].referrer, 0, uint8(goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[1]].firstLevelReferrals.length));
      emit NewUserPlace(userAddress, referrerAddress, users[userAddress].referrer, 0, 4 + uint8(goldMatrix[goldMatrix[referrerAddress].firstLevelReferrals[1]].firstLevelReferrals.length));
      
      goldMatrix[userAddress].currentReferrer = goldMatrix[referrerAddress].firstLevelReferrals[1];
    }
  }
  
  function updateGoldMatrixReferrerSecondLevel(address userAddress, address referrerAddress) private {
    if (goldMatrix[referrerAddress].secondLevelReferrals.length < 4) {
      return sendGoldMatrixTRXDividends(referrerAddress, userAddress);
    }

    if (!users[referrerAddress].autoReinvestGoldMatrix) {
      sendGoldMatrixTRXDividends(referrerAddress, userAddress);

      goldMatrix[referrerAddress].firstLevelReferrals = new address[](0);
      goldMatrix[referrerAddress].secondLevelReferrals = new address[](0);
      goldMatrix[referrerAddress].time = 0;

      return; 
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

    goldMatrix[referrerAddress].blocked = true; 

    goldMatrix[referrerAddress].reinvestCount++;
    
    if (referrerAddress != owner) {
      address freeReferrerAddress = findFreeGoldMatrixReferrer(referrerAddress);

      emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 0);
      updateGoldMatrixReferrer(referrerAddress, freeReferrerAddress);
    } else {
      emit Reinvest(owner, address(0), userAddress, 0);
      sendGoldMatrixTRXDividends(owner, userAddress);
    }
  }

  function findFreeGoldMatrixReferrer(address userAddress) public view returns(address) {
    while (true) { 
      if (goldMatrix[users[userAddress].referrer].time > 0) {
        return users[userAddress].referrer;
      }
      
      userAddress = users[userAddress].referrer;
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
        emit MissedTRXReceive(receiver, _from, level);
        isExtraDividends = true;
        receiver = users[receiver].matrix[level].currentReferrer;
      } else {
        return (receiver, isExtraDividends);
      }
    }
  }

  function sendTRXDividends(address userAddress, address _from, uint8 level, uint256 passiveIncome) private {
    (address receiver, bool isExtraDividends) = findTRXReceiver(userAddress, _from, level);

    uint256 amount = levelPrice[level];
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
    emit SentTRXDividends(_from, receiver, level, amount);
    
    if (isExtraDividends) {
      emit SentExtraTRXDividends(_from, receiver, level);
    }
  }

  function findGoldMatrixTRXReceiver(address userAddress, address _from) private returns(address, bool) {
    address receiver = userAddress;
    bool isExtraDividends;
    while (true) { 
      if (goldMatrix[receiver].blocked) {
        emit MissedTRXReceive(receiver, _from, 0);
        isExtraDividends = true;
        receiver = goldMatrix[receiver].currentReferrer;
      } else {
        return (receiver, isExtraDividends);
      }
    }
  }

  function sendGoldMatrixTRXDividends(address userAddress, address _from) private {
    (address receiver, bool isExtraDividends) = findGoldMatrixTRXReceiver(userAddress, _from);

    if (!address(uint160(receiver)).send(GOLD_MATRIX_PRICE)) {
      revert("Insufficient funds on the contract balance");
    }
    emit SentTRXDividends(_from, receiver, 0, GOLD_MATRIX_PRICE);
    
    if (isExtraDividends) {
      emit SentExtraTRXDividends(_from, receiver, 0);
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

  
  function setAutoReinvestGoldMatrix(bool _flag) public returns (bool) {
    if (users[msg.sender].autoReinvestGoldMatrix != _flag) {
      users[msg.sender].autoReinvestGoldMatrix = _flag;

      emit AutoReinvestGoldMatrixFlagSwitch(msg.sender, _flag);

      return true;
    }

    return false;
  }

  function getPassiveIncome(address userAddress) public view returns (uint256, uint8) {
    uint256 income = 0;
    uint8 level = LAST_LEVEL;

    for (; level >= 1; level--) {
      if (users[userAddress].activeMatrixLevels[level]) {
        if (users[userAddress].matrix[level].reinvestCount == 0) {
          if (users[userAddress].matrix[level].time == 0) {
            break;
          }

          income = levelPrice[level]
            .mul(
              now.sub(users[userAddress].matrix[level].time)
            )
            .mul(PASSIVE_INCOME_DAILY_PERCENT)
            .div(100)
            .div(1 days);

          uint256 incomeLimit = (levelPrice[level].mul(PASSIVE_INCOME_MAX_PROFIT_PERCENT).div(100))
            .sub(users[userAddress].matrix[level].passiveIncomeReceived);
          if (income > incomeLimit) {
            income = incomeLimit;
          }
        }

        break;
      }
    }

    return (income, level);
  }

  function withdrawPassiveIncome(address userAddress) private returns (uint256) {
    (uint256 income, uint8 level) = getPassiveIncome(userAddress);

    if (income > 0) {
      if (address(uint160(userAddress)).send(income)) {
        users[userAddress].matrix[level].time = now;
        users[userAddress].matrix[level].passiveIncomeReceived = users[userAddress].matrix[level].passiveIncomeReceived.add(income);
      }
    }

    if (users[userAddress].matrix[level].time == 0) {
      users[userAddress].matrix[level].time = now;
    }

    emit PassiveIncomeWithdrawn(userAddress, level, income);

    return income;
  }

  function withdrawPassiveIncome() public returns (uint256) {
    return withdrawPassiveIncome(msg.sender);
  }

}