// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./register.sol";

contract RogueLand {
    
    enum ActionChoices { SitStill, GoLeft, GoRight, GoUp, GoDown, GoLeftUp, GoLeftDown, GoRightUp, GoRightDown }
	
    struct Event {
      uint movingPunk;
      uint monster;
    }

    struct Gold {
      uint amount;
      uint vaildTime;
      uint punkNumber;
    }

    struct StatusInfo {
      uint t;
      int x;
      int y;
    }

    struct MovingPunk {
      uint newNeighbor;
      ActionChoices action;
      int x;
      int y;
    }

    struct StillPunk {
      uint oldNeighbor;
      uint newNeighbor;
      int x;
      int y;
      uint showtime;
      uint gold;
    }

    address public owner;
    address public registerContractAddress;
    bool public startClaim;
    uint public startBlock; // 记录初始区块数
    uint public endRound; // 记录结束的回合
    uint private _randNonce;
    uint public mapSize = 5;
    uint public activeRound = 150;
    uint public blockPerRound = 500;
    uint public goldInterval = 500;
    uint public goldAmount = 10000;
    uint public validBlockToPutGold;
    uint public freePunk = 2;
    uint public lowbAmount;
    uint public umgAmount;
  
    // 储存玩家授权信息
    mapping (uint => address) public punkMaster;
    mapping (address => uint) public punkOf;
    mapping (address => bool) public isVIP;

    // 储存punk的时空信息
    mapping (uint => mapping (uint => MovingPunk)) public movingPunks;

    // 储存punk最后规划的信息
    mapping (uint => uint) public lastScheduleOf;

    // 储存punk最后的位置信息
    mapping (uint => StillPunk) public stillPunks;

    // 储存静止punk的空间信息
    mapping (int => mapping (int => uint)) public stillPunkOn;

    // 储存金矿的空间信息
    mapping (int => mapping (int => Gold)) public goldOn;
  
    // 储存时空信息
    mapping (uint => mapping (int => mapping (int => Event))) public events;

    event ActionCommitted(uint indexed punkId, uint indexed time, ActionChoices action);
    event GoldPicked(uint indexed punkId, uint indexed time, int x, int y, uint amount);
    event GoldPut(uint indexed punkId, int x, int y, uint amount, bool isPut);
  
    constructor(address registerContractAddress_) {
        owner = msg.sender;
        registerContractAddress = registerContractAddress_;
        validBlockToPutGold = block.number;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getEvents(int x1, int y1, int x2, int y2, uint t) public view returns (Event[] memory) {
        require(x2 >= x1 && y2 >= y1, "Invalid index");
        Event[] memory selectEvents = new Event[](uint((x2-x1+1)*(y2-y1+1)));
        uint i = 0;
        for (int x=x1; x<=x2; x++) {
          for (int y=y1; y<=y2; y++) {
            selectEvents[i] = events[t][x][y];
            if (events[t][x][y].movingPunk == 0 && stillPunks[stillPunkOn[x][y]].showtime <= t) {
              selectEvents[i].movingPunk = stillPunkOn[x][y];
            }
            if (goldOn[x][y].vaildTime == 0 || goldOn[x][y].vaildTime >= t) {
              selectEvents[i].monster = goldOn[x][y].amount;
            }
            i ++;
          }
        }
        return selectEvents;
    }

    // 玩家注册游戏
    function register() public {
        Register registerContract = Register(registerContractAddress);
        uint id = registerContract.punkOf(msg.sender);
        if (id == 0) {
          while (punkMaster[freePunk] != address(0)) {
            freePunk ++;
          }
          require(freePunk <= 667, "no more free punks");
          id = freePunk;
          freePunk ++;
        }
        else {
          isVIP[msg.sender] = true;
        }
        punkMaster[id] = msg.sender;
        punkOf[msg.sender] = id;
        if (lastScheduleOf[id] == 0) {
          uint t = getCurrentTime();
          lastScheduleOf[id] = t;
          _addStillPunk(id, 0, 0, t);
        }
    }

    function isValidToPutGold(int x, int y) public view returns (bool) {
      uint time = getCurrentTime();
      return stillPunkOn[x][y] == 0 && events[time][x][y].movingPunk == 0 && (goldOn[x][y].vaildTime == 0 || time > goldOn[x][y].vaildTime + activeRound);
    }

    // 兑换OKT
    function swapGold(address payable player_) public {
        require(player_ == msg.sender, "Please use your gold.");
        require(stillPunks[punkOf[player_]].gold >= 1000, "Lack gold.");
        stillPunks[punkOf[player_]].gold -= 1000;
        require(player_.send(1e16), "okt transfer failed");
    }

    // 设置游戏开始与结束时间
    function startGame(uint startBlock_, uint endRound_) public {
        require(msg.sender == owner, "Only admin can start the game.");
        startBlock = startBlock_;
        endRound = endRound_;
    }

    // 设置金币参数
    function setGold(uint goldInterval_, uint goldAmount_) public {
        require(msg.sender == owner, "Only admin can put gold.");
        goldInterval = goldInterval_;
        goldAmount = goldAmount_;
    }

    function _putGold(int x, int y) private returns (bool) {
      if (isValidToPutGold(x, y)) {
        goldOn[x][y].vaildTime = 0;
        goldOn[x][y].punkNumber = 0;
        goldOn[x][y].amount += goldAmount;
        emit GoldPut(punkOf[msg.sender], x, y, goldAmount, true);
        return true;
      }
      else {
        return false;
      }
    }

    // 放置金币
    function putGold() public {
        require(block.number >= validBlockToPutGold, "Wait, the gold need some time to mint...");
        _randNonce = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randNonce)));
        int x = int(_randNonce % (2*mapSize+1)) - int(mapSize);
        _randNonce = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randNonce)));
        int y = int(_randNonce % (2*mapSize+1)) - int(mapSize);
        bool put = _putGold(x, y) || _putGold(x, -y) || _putGold(-x, y) || _putGold(-x, -y);
        if (put) {
          validBlockToPutGold = validBlockToPutGold + goldInterval;
        }
        else {
          mapSize ++;
        }
        stillPunks[punkOf[msg.sender]].gold += 200;
    }

    // 获取金币
    function getGold(int x, int y) public {
        require(goldOn[x][y].punkNumber > 0 , "Nothing to do.");
        uint t = goldOn[x][y].vaildTime;
        require(getCurrentTime() >= t, "Wait, it is not the time.");
        uint id = stillPunkOn[x][y];
        uint amount = goldOn[x][y].amount / goldOn[x][y].punkNumber;
        while (id != 0) {
          stillPunks[id].gold += amount;
          id = stillPunks[id].newNeighbor;
          emit GoldPicked(id, t, x, y, amount);
        }
        id = events[t][x][y].movingPunk;
        while (id != 0) {
          stillPunks[id].gold += amount;
          id = movingPunks[id][t].newNeighbor;
          emit GoldPicked(id, t, x, y, amount);
        }
        goldOn[x][y].vaildTime = 0;
        goldOn[x][y].punkNumber = 0;
        goldOn[x][y].amount = 0;
    }

    function getEvent(uint id) public view returns (StatusInfo memory) {
      if (lastScheduleOf[id] == 0) {
        return StatusInfo(0, 0, 0);
      }
      uint time = getCurrentTime();
      uint start = time > 150? time-150: 1;
      uint end = time < lastScheduleOf[id]-1? time: lastScheduleOf[id]-1;
      for (uint t=start; t<=end; t++) {
        int x_ = movingPunks[id][t].x;
        int y_ = movingPunks[id][t].y;
        if (goldOn[x_][y_].vaildTime == t) {
          return StatusInfo(t, x_, y_);
        }
      }
      if (lastScheduleOf[id] <= time) {
        int x = stillPunks[id].x;
        int y = stillPunks[id].y;
        if (goldOn[x][y].vaildTime == lastScheduleOf[id]) {
          return StatusInfo(lastScheduleOf[id], x, y);
        }
      }
      return StatusInfo(0, 0, 0);
    }

    function _removeStillPunk(uint id, int x, int y) private {
        uint oldNeighbor = stillPunks[id].oldNeighbor;
        uint newNeighbor = stillPunks[id].newNeighbor;
        if (oldNeighbor > 0) {
          stillPunks[oldNeighbor].newNeighbor = newNeighbor;
        }
        else {
          stillPunkOn[x][y] = newNeighbor;
        }
        if (newNeighbor > 0) {
          stillPunks[newNeighbor].oldNeighbor = oldNeighbor;
        }
    }

    function _addStillPunk(uint id, int x, int y, uint t) private {
        uint latestNeighbor = stillPunkOn[x][y];
        stillPunkOn[x][y] = id;
        stillPunks[id].oldNeighbor = 0;
        stillPunks[id].newNeighbor = latestNeighbor;
        stillPunks[id].x = x;
        stillPunks[id].y = y;
        stillPunks[id].showtime = t;
        if (latestNeighbor > 0) {
          stillPunks[latestNeighbor].oldNeighbor = id;
        }
        // 自动拾取金币
        if (goldOn[x][y].amount > 0 && (goldOn[x][y].vaildTime == 0 || goldOn[x][y].vaildTime >= t)) {
          if (goldOn[x][y].vaildTime == t) {
            goldOn[x][y].punkNumber ++;
          }
          else {
            goldOn[x][y].punkNumber = 1;
          }
          goldOn[x][y].vaildTime = t;
        }
    }

    function _addMovingPunk(uint id, uint t, int x, int y, ActionChoices action) private {
        movingPunks[id][t].newNeighbor = events[t][x][y].movingPunk;
        events[t][x][y].movingPunk = id;
        movingPunks[id][t].action = action;
        movingPunks[id][t].x = x;
        movingPunks[id][t].y = y;
    }

    // 操作punk
    function scheduleAction(uint id, ActionChoices action) public {
        require(punkOf[msg.sender] == id, "Get authorized first!");
        uint currentTime = getCurrentTime();
        if (lastScheduleOf[id] < currentTime) {
          lastScheduleOf[id] = currentTime;
        }
        uint t = lastScheduleOf[id];
        int x = stillPunks[id].x;
        int y = stillPunks[id].y;
        // remove this punk from still punks in (x, y) 
        _removeStillPunk(id, x, y);
        _addMovingPunk(id, t, x, y, action);
        if (action == ActionChoices.GoLeft) {
          _addStillPunk(id, x-1, y, t+1);
        }
        if (action == ActionChoices.GoRight) {
          _addStillPunk(id, x+1, y, t+1);
        }
        if (action == ActionChoices.GoUp) {
          _addStillPunk(id, x, y+1, t+1);
        }
        if (action == ActionChoices.GoDown) {
          _addStillPunk(id, x, y-1, t+1);
        }
        if (action == ActionChoices.GoLeftUp) {
          _addStillPunk(id, x-1, y+1, t+1);
        }
        if (action == ActionChoices.GoLeftDown) {
          _addStillPunk(id, x-1, y-1, t+1);
        }
        if (action == ActionChoices.GoRightUp) {
          _addStillPunk(id, x+1, y+1, t+1);
        }
        if (action == ActionChoices.GoRightDown) {
          _addStillPunk(id, x+1, y-1, t+1);
        }
        lastScheduleOf[id] ++;
        emit ActionCommitted(id, lastScheduleOf[id], action);
    }

    function getCurrentTime() public view returns (uint) {
      if (startBlock == 0) {
        return 0;
      }
      uint time = (block.number - startBlock) / blockPerRound;
      if (time > endRound) {
        return endRound;
      }
      return time;
    }

    function getCurrentStatus(uint id) public view returns (StatusInfo memory) {
      uint time = getCurrentTime();
      if (lastScheduleOf[id] > time) {
        return StatusInfo(time, movingPunks[id][time].x, movingPunks[id][time].y);
      }
      else {
        return StatusInfo(time, stillPunks[id].x, stillPunks[id].y);
      }
      
    }

    function getScheduleInfo(uint id) public view returns (StatusInfo memory) {
      uint time = getCurrentTime();
      if (lastScheduleOf[id] > time) {
        time = lastScheduleOf[id];
      }
      return StatusInfo(time, stillPunks[id].x, stillPunks[id].y);
    }

    function getGoldsofAllPunk() public view returns (uint[667] memory) {
      uint[667] memory golds;
      for (uint i=0; i<667; i++) {
        golds[i] = stillPunks[i+1].gold;
      }
      return golds;
    }

    function totalGold() public view returns (uint) {
      uint totalGold_;
      for (uint i=0; i<667; i++) {
        if (isVIP[punkMaster[i+1]]) {
          totalGold_ += stillPunks[i+1].gold*2;
        }
        else {
          totalGold_ += stillPunks[i+1].gold;
        }
      }
      return totalGold_;
    }

    // 设置奖励参数
    function setTotalRewards(uint lowbAmount_, uint umgAmount_) public {
        require(msg.sender == owner, "Only admin can set rewards.");
        lowbAmount = lowbAmount_;
        umgAmount = umgAmount_;
        startClaim = true;
    }

    // 领取奖励
    function claimRewards() public {
        require(startClaim, "Not the time");
        uint punkId = punkOf[msg.sender];
        uint gold_ = isVIP[msg.sender] ? stillPunks[punkId+1].gold*2 : stillPunks[punkId+1].gold;
        uint totalGold_ = totalGold();
        uint lowbRewards = gold_ * lowbAmount / totalGold_;
        uint umgRewards = gold_ * umgAmount / totalGold_;
        Register registerContract = Register(registerContractAddress);
        registerContract.award(msg.sender, 0, lowbRewards);
        registerContract.award(msg.sender, 1, umgRewards);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Register {
  
  enum Status { NoRecord, Processing, Finished }
  
  struct Account {
    string name;
    string email;
	  uint punkId;
    uint[] balance;
  }
  
  address public owner;
  string[] tokens;
  uint public useId;

  mapping (address => Account) public accountInfo;
  mapping (uint => address) public punkOwner;
  mapping (address => bool) public isAdmin;
  mapping (address => uint) public lastUse;
  mapping (uint => Status) public useInfo;

  event RegisterSucceed(address indexed player, string name, string email);
  event Award(address indexed player, uint indexed id, uint amount);
  event Use(uint indexed useId, address indexed player, uint indexed id, uint amount);
  
  constructor() {
    owner = msg.sender;
  }

  function setAdmin(address candidate, bool b) public {
    require(msg.sender == owner, "You are not admin");
    isAdmin[candidate] = b;
  }

  function newToken(string memory tokenName) public {
    require(msg.sender == owner, "You are not admin");
    tokens.push(tokenName);
  }

  function grantPunk(uint punkId, address newOwner) public {
    require(msg.sender == owner, "You are not admin");
    address prevOwner = punkOwner[punkId];
    accountInfo[prevOwner].punkId = 0;
    accountInfo[newOwner].punkId = punkId;
    punkOwner[punkId] = newOwner;
  }

  function balanceOf(address user) public view returns (uint[] memory) {
    return accountInfo[user].balance;
  }

  function tokenInfo() public view returns (string[] memory) {
    return tokens;
  }

  function punkOf(address user) public view returns (uint) {
    return accountInfo[user].punkId;
  }
  
  function register(string memory name_, string memory email_) public {
    accountInfo[msg.sender].name = name_;
    accountInfo[msg.sender].email = email_;
    emit RegisterSucceed(msg.sender, name_, email_);
  }

  function award(address player, uint id, uint amount) public {
    require(isAdmin[msg.sender], "You are not admin");
    for(uint i=accountInfo[player].balance.length; i<=id; i++) {
      accountInfo[player].balance.push(0);
    }
    accountInfo[player].balance[id] += amount;
    emit Award(player, id, amount);
  }

  function use(uint id, uint amount) public {
    require(accountInfo[msg.sender].balance[id] >= amount, "No enough balance");
    accountInfo[msg.sender].balance[id] -= amount;
    useId ++;
    useInfo[useId] = Status.Processing;
    lastUse[msg.sender] = useId;
    emit Use(useId, msg.sender, id, amount);
  }

  function setFinish(uint id) public {
    require(msg.sender == owner, "You are not admin");
    useInfo[id] = Status.Finished;
  }

  
}

