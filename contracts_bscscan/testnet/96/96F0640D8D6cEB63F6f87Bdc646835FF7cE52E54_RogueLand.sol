// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NewRegister {
  
  enum Status { NoRecord, Processing, Finished }
  
  struct Account {
    string name;
    string email;
    address wallet;
	uint punkId;
    uint[] balance;
  }

  struct UseInfo {
    uint kind;
    address player;
    uint id;
	uint amount;
    string metaData;
    Status status;
  }
  
  address public owner;
  string[] tokens;
  uint public useId;

  mapping (address => Account) public accountInfo;
  mapping (uint => address) public punkOwner;
  mapping (address => bool) public isAdmin;
  mapping (address => uint) public lastUse;
  mapping (uint => UseInfo) public useInfo;
  mapping (address => mapping (uint => uint)) public oldBalance;

  event RegisterSucceed(address indexed player, string name, string email, address wallet);
  event Award(address indexed player, uint indexed id, uint amount);
  event Use(uint indexed useId, uint indexed kind, address indexed player, uint id, uint amount);
  
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
  
  function register(string memory name_, string memory email_, address wallet_) public {
    accountInfo[msg.sender].name = name_;
    accountInfo[msg.sender].email = email_;
    accountInfo[msg.sender].wallet = wallet_;
    emit RegisterSucceed(msg.sender, name_, email_, wallet_);
  }

  function award(address player, uint id, uint amount) public {
    require(isAdmin[msg.sender], "You are not admin");
    for(uint i=accountInfo[player].balance.length; i<=id; i++) {
      accountInfo[player].balance.push(0);
    }
    accountInfo[player].balance[id] += amount;
    emit Award(player, id, amount);
  }

  function use(address player, uint id, uint amount, uint kind, string memory metaData) public {
    require(isAdmin[msg.sender] || msg.sender == player, "You cannot use other's token");
    require(accountInfo[player].balance[id] >= amount, "No enough balance");
    accountInfo[player].balance[id] -= amount;
    useId ++;
    useInfo[useId] = UseInfo(kind, player, id, amount, metaData, Status.Processing);
    lastUse[player] = useId;
    emit Use(useId, kind, player, id, amount);
  }

  function setFinish(uint id) public {
    require(isAdmin[msg.sender], "You are not admin");
    useInfo[id].status = Status.Finished;
  }

  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NewRegister.sol";

contract RogueLand {
    
    enum ActionChoices { SitStill, GoLeft, GoRight, GoUp, GoDown, GoLeftUp, GoLeftDown, GoRightUp, GoRightDown }
	
    struct MovingPunk {
      uint punkId;
      uint punkNonce;
    }

    struct MapInfo {
      uint punk;
      uint gold;
    }

    struct TimeSpace {
      uint t;
      int x;
      int y;
    }

    struct Position {
      int x;
      int y;
    }

    struct StillPunk {      
      int x;
      int y;
      uint showtime;
      uint gold;
      uint hep;
      uint enemy;
      uint hp;
      uint nonce; // 代表死亡次数
    }

    struct PunkInfo {      
      int x;
      int y;
      uint gold;
      uint hep;
      uint hp;
      address player;
      string name;
    }

    uint public constant AC = 9; // 防御力
    uint public constant BAREHAND = 5; // 徒手攻击
    
    address public owner;
    address public registerContractAddress;
    uint public startBlock; // 记录初始区块数
    uint public endRound; // 记录结束的回合
    uint private _randNonce;
    //uint public mapSize = 5;
    //uint public activeRound = 50;
    uint public blockPerRound = 500;
    uint public rewardsPerRound = 100;
    uint public freePunk = 2;
    uint public lowbAmount;
    uint public umgAmount;
  
    // 储存玩家授权信息
    mapping (uint => address) public punkMaster;
    mapping (address => uint) public punkOf;
    mapping (address => bool) public isVIP;

    // 储存punk的时空信息
    mapping (uint => mapping (uint => Position)) public movingPunks;

    // 储存punk最后规划的信息
    mapping (uint => uint) public lastScheduleOf;

    // 储存随机种子，用于战斗
    mapping (uint => uint) private _randseedOfRound;
    mapping (uint => uint) private _randseedOfPunk;

    // 储存punk最后的位置信息
    mapping (uint => StillPunk) public stillPunks;

    // 储存静止punk的空间信息
    mapping (int => mapping (int => uint)) public stillPunkOn;

    // 储存药水合成信息
    mapping (uint => mapping (uint => bool)) public cooked;
  
    // 储存时空信息
    mapping (uint => mapping (int => mapping (int => MovingPunk))) public movingPunksOn;

    // 储存奖励信息
    mapping (address => bool) public claimed;

    event ActionCommitted(uint indexed punkId, uint indexed time, ActionChoices action);
    event GoldPicked(uint indexed punkId, uint indexed time, int x, int y, uint amount);
    event GoldPut(uint indexed punkId, int x, int y, uint amount, bool isPut);
  
    constructor(address registerContractAddress_) {
        owner = msg.sender;
        registerContractAddress = registerContractAddress_;
        _randNonce = uint(keccak256(abi.encode(block.timestamp, msg.sender)));
        _randseedOfRound[0] = _randNonce;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getEvents(int x1, int y1, int x2, int y2, uint t) public view returns (uint[] memory) {
        require(x2 >= x1 && y2 >= y1, "Invalid index");
        uint[] memory selectEvents = new uint[](uint((x2-x1+1)*(y2-y1+1)));
        uint i = 0;
        for (int x=x1; x<=x2; x++) {
          for (int y=y1; y<=y2; y++) {
            //selectEvents[i] = events[t][x][y];
            if (movingPunksOn[t][x][y].punkNonce == stillPunks[movingPunksOn[t][x][y].punkId].nonce) {
              selectEvents[i] = movingPunksOn[t][x][y].punkId;
            }
            if (stillPunkOn[x][y] != 0 && stillPunks[stillPunkOn[x][y]].showtime <= t) {
              selectEvents[i] = stillPunkOn[x][y];
            }
            i ++;
          }
        }
        return selectEvents;
    }

    function _resetPunk(uint id) private {
      uint t = getCurrentTime();
      lastScheduleOf[id] = t;
      stillPunks[id].hp = 15; // 初始生命值为15
      stillPunks[id].nonce ++;

      int n = int(id%100) / 2 - 24; // punk将根据序号分为4组排布在外城边界上
      if (id % 4 == 0) {
        _moveStillPunk(id, n, 25, t);
      }
      else if (id % 4 == 1) {
        _moveStillPunk(id, -n, -25, t);
      }
      else if (id % 4 == 2) {
        _moveStillPunk(id, 25, -n, t);
      }
      else if (id % 4 == 3) {
        _moveStillPunk(id, -25, n, t);
      }
      
    }
    
    // 玩家注册游戏
    function register() public {
        require(punkOf[msg.sender] == 0, "registered!");
        NewRegister registerContract = NewRegister(registerContractAddress);
        uint id = registerContract.punkOf(msg.sender);
        if (id == 0) {
          while (punkMaster[freePunk] != address(0) || registerContract.punkOwner(id) != address(0)) {
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
        _randseedOfPunk[id] = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randNonce)));
        _resetPunk(id);
    }

    // 兑换OKT
    function swapHEP() public {
        uint t = getCurrentTime();
        uint id = punkOf[msg.sender];
        require(id > 0 && !cooked[id][t], "You have cooked the potion this round.");
        require(stillPunks[id].gold >= 200, "Lack gold.");
        require(t != endRound, "The game is end now...");
        stillPunks[id].gold -= 200;
        stillPunks[id].hep ++;
        cooked[id][t] = true;
    }

    // 兑换OKT
    function swapOKT(address payable player_) public {
        require(player_ == msg.sender, "Please use your gold.");
        require(stillPunks[punkOf[player_]].gold >= 1000, "Lack gold.");
        require(getCurrentTime() != endRound, "The game is end now...");
        stillPunks[punkOf[player_]].gold -= 1000;
        require(player_.send(1e16), "okt transfer failed");
    }

    // 设置游戏开始与结束时间
    function startGame(uint startBlock_, uint endRound_) public {
        require(msg.sender == owner, "Only admin can start the game.");
        startBlock = startBlock_;
        endRound = endRound_;
    }


    // punkA击杀了punkB
    function _kill(uint A, uint B) private {
      // 阻止B后续的移动，将B送回原点，并恢复生命值
      _resetPunk(B);
      // A获得了B的所有金币
      stillPunks[A].gold += stillPunks[B].gold;
      stillPunks[B].gold = 0;
      stillPunks[A].enemy = 0;
      stillPunks[B].enemy = 0;
    }
    
    // punkA向punkB进攻
    function _attack(uint A, uint B) private {
      // 命中检定1d20，徒手攻击1d5
      _randseedOfPunk[B] = uint(keccak256(abi.encode(A, _randseedOfPunk[B])));
      uint dice = _randseedOfPunk[B] % 100;
      // 骰点小于 10+被攻击者AC 时攻击命中
      if (dice/5+1 < 10+AC) {
        // 徒手攻击，伤害值1d5
        stillPunks[B].hp = (stillPunks[B].hp < (dice%5+1)? 0 : stillPunks[B].hp-(dice%5+1));
      }
    }

    // punkA向punkB进攻
    function attack(uint A, uint B) public {
      require(punkOf[msg.sender] == A, "Get authorized first!");
      uint t = getCurrentTime();
      Position memory posA = getPostion(A, t);
      Position memory posB = getPostion(B, t);
      require((posA.x-posB.x)**2 <=1  &&  (posA.y-posB.y)**2 <=1, "can only attack neighbors");

      if (stillPunks[A].enemy != B) {
        stillPunks[A].enemy = B;
      }

      _attack(A, B);
      if (stillPunks[B].hp == 0) {
        _kill(A, B);
      }
      else {
        // punkB自动反击
        _attack(B, A);
        if (stillPunks[A].hp == 0) {
          _kill(B, A);
        }
      }
    }

    // 离开战斗，会受到一次攻击
    function leaveBattle(uint id) public {
      require(punkOf[msg.sender] == id, "Get authorized first!");
      require(stillPunks[id].enemy != 0, "no enemy");
      stillPunks[id].enemy = 0;
      _attack(stillPunks[id].enemy, id);
      if (stillPunks[id].hp == 0) {
        _kill(stillPunks[id].enemy, id);
      }
    }

    // 只能在非战状态下时使用HEP
    function useHEP(uint id) public {
      require(punkOf[msg.sender] == id, "Get authorized first!");
      require(stillPunks[id].hep >= 0, "Lack potion.");
      if (stillPunks[id].enemy != 0) {
        leaveBattle(id);
      }
      stillPunks[id].hep --;
      stillPunks[id].hp += 10;
      if (stillPunks[id].hp > 15) {
        stillPunks[id].hp = 15;
      }
    }

    function _moveStillPunk(uint id, int x, int y, uint t) private {
        require(getPunkOn(t, x, y) == 0 || x**2 == 625 || y**2 == 625, "other punk was already on it");
        int x_ = stillPunks[id].x;
        int y_ = stillPunks[id].y;
        stillPunkOn[x_][y_] = 0;
        stillPunkOn[x][y] = id;
        stillPunks[id].x = x;
        stillPunks[id].y = y;
        stillPunks[id].showtime = t;
        
    }

    function _addMovingPunk(uint id, uint t, int x, int y) private {
        movingPunksOn[t][x][y].punkId = id;
        movingPunksOn[t][x][y].punkNonce = stillPunks[id].nonce;
        movingPunks[id][t].x = x;
        movingPunks[id][t].y = y;
        // 自动进行挖矿操作
        uint gold = pendingGold(id);
        if (gold > 0) {
          stillPunks[id].gold += gold;
        }
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
        _addMovingPunk(id, t, x, y);
        if (action == ActionChoices.GoLeft) {
          _moveStillPunk(id, x-1, y, t+1);
        }
        if (action == ActionChoices.GoRight) {
          _moveStillPunk(id, x+1, y, t+1);
        }
        if (action == ActionChoices.GoUp) {
          _moveStillPunk(id, x, y+1, t+1);
        }
        if (action == ActionChoices.GoDown) {
          _moveStillPunk(id, x, y-1, t+1);
        }
        if (action == ActionChoices.GoLeftUp) {
          _moveStillPunk(id, x-1, y+1, t+1);
        }
        if (action == ActionChoices.GoLeftDown) {
          _moveStillPunk(id, x-1, y-1, t+1);
        }
        if (action == ActionChoices.GoRightUp) {
          _moveStillPunk(id, x+1, y+1, t+1);
        }
        if (action == ActionChoices.GoRightDown) {
          _moveStillPunk(id, x+1, y-1, t+1);
        }
        lastScheduleOf[id] ++;
        emit ActionCommitted(id, lastScheduleOf[id], action);
    }

    function getCurrentTime() public view returns (uint) {
      if (startBlock == 0 || startBlock > block.number) {
        return 0;
      }
      uint time = (block.number - startBlock) / blockPerRound + 1;
      if (time > endRound) {
        return endRound;
      }
      return time;
    }

    function getPunkInfo(uint id) public view returns (PunkInfo memory) {
      uint t = getCurrentTime();
      Position memory pos = getPostion(id, t);
      address player = punkMaster[id];
      NewRegister registerContract = NewRegister(registerContractAddress);
      (string memory name, , ,) = registerContract.accountInfo(player);
      return PunkInfo(pos.x, pos.y, stillPunks[id].gold, stillPunks[id].hep, stillPunks[id].hp, player, name);
    }

    function getPunkOn(uint t, int x, int y) public view returns (uint) {
      if (stillPunkOn[x][y] != 0) {
        return stillPunkOn[x][y];
      }
      else {
        uint id = movingPunksOn[t][x][y].punkId;
        if (movingPunksOn[t][x][y].punkNonce == stillPunks[id].nonce) {
          return id;
        }
      }
      return 0;
    }

    function getPostion(uint id, uint t) public view returns (Position memory) {
      if (lastScheduleOf[id] > t) {
        return Position(movingPunks[id][t].x, movingPunks[id][t].y);
      }
      else {
        return Position(stillPunks[id].x, stillPunks[id].y);
      }
    }

    function getCurrentStatus(uint id) public view returns (TimeSpace memory) {
      uint time = getCurrentTime();
      Position memory pos = getPostion(id, time);
      return TimeSpace(time, pos.x, pos.y);
    }

    function getScheduleInfo(uint id) public view returns (TimeSpace memory) {
      uint time = getCurrentTime();
      if (lastScheduleOf[id] > time) {
        time = lastScheduleOf[id];
      }
      return TimeSpace(time, stillPunks[id].x, stillPunks[id].y);
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

    function getProductivity(int x, int y) public pure returns (uint) {
      if (x == 0 && y == 0) {
        return 100;
      }
      else if (x**2 <= 1  &&  y**2 <= 1) {
        return 25;
      }
      else if (x**2 <= 9  &&  y**2 <= 9) {
        return 10;
      }
      else if (x**2 <= 36  &&  y**2 <= 36) {
        return 5;
      }
      else if (x**2 <= 100  &&  y**2 <= 100) {
        return 3;
      }
      else if (x**2 <= 225  &&  y**2 <= 225) {
        return 2;
      }
      else if (x**2 <= 576  &&  y**2 <= 576) {
        return 1;
      }
      else {
        return 0;
      }
    }

    function pendingGold(uint id) public view returns (uint) {
      uint time = getCurrentTime();
      if (stillPunks[id].showtime < time) {
        uint productivity = getProductivity(stillPunks[id].x, stillPunks[id].y);
        return (time - stillPunks[id].showtime) * productivity * rewardsPerRound;
      }
      else {
        return 0;
      }
    }

    // 设置奖励参数
    function setTotalRewards(uint lowbAmount_, uint umgAmount_) public {
        require(msg.sender == owner, "Only admin can set rewards.");
        lowbAmount = lowbAmount_;
        umgAmount = umgAmount_;
    }

    function pendingRewards(address player) public view returns (uint[2] memory) {
        uint punkId = punkOf[player];
        uint gold_ = isVIP[player] ? stillPunks[punkId].gold*2 : stillPunks[punkId].gold;
        if (punkId == 0) {
          gold_ = 0;
        }
        if (gold_ == 0) {
          return [gold_, gold_];
        }
        uint totalGold_ = totalGold();
        uint lowbRewards = gold_ * lowbAmount / totalGold_;
        uint umgRewards = gold_ * umgAmount / totalGold_;
        return [lowbRewards, umgRewards];
    }

    // 领取奖励
    function claimRewards() public {
        require(endRound != 0 && getCurrentTime() == endRound, "Not the time");
        require(!claimed[msg.sender], "Claimed");
        uint[2] memory pendingRewards_ = pendingRewards(msg.sender);
        claimed[msg.sender] = true;
        NewRegister registerContract = NewRegister(registerContractAddress);
        registerContract.award(msg.sender, 0, pendingRewards_[0]);
        registerContract.award(msg.sender, 1, pendingRewards_[1]);
    }

}