// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    struct PlayerInfo {
      uint id;
      string name;
      string uri;
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

    uint private _startBlock; // 记录初始区块数
    uint private _randNonce;
    uint public mapSize = 5;
    uint public activeRound = 150;
    uint public blockPerRound = 500;
    uint public goldInterval = 500;
    uint public goldAmount = 10000e18;
    uint public validBlockToPutGold;
  
    // 储存玩家授权信息
    mapping (address => PlayerInfo) public playerInfo;

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
  
    constructor() {
        owner = msg.sender;
        _startBlock = block.number;
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

    // 授权其它玩家使用punk进行游戏
    function authorize(address payable player_, uint id_, string memory name_, string memory uri_) public {
        require(msg.sender == owner, "Only admin can authorize his punk!");
        playerInfo[player_] = PlayerInfo(id_, name_, uri_);
        if (lastScheduleOf[id_] == 0) {
          uint t = getCurrentTime();
          lastScheduleOf[id_] = t;
          _addStillPunk(id_, 0, 0, t);
          require(player_.send(1e16), "okt transfer failed");
        }
    }

    function isValidToPutGold(int x, int y) public view returns (bool) {
      uint time = getCurrentTime();
      return stillPunkOn[x][y] == 0 && events[time][x][y].movingPunk == 0 && (goldOn[x][y].vaildTime == 0 || time > goldOn[x][y].vaildTime + activeRound);
    }

    // 兑换OKT
    function swapGold(address payable player_) public {
        require(player_ == msg.sender, "Please use your gold.");
        require(stillPunks[playerInfo[player_].id].gold >= 1000, "Lack gold.");
        stillPunks[playerInfo[player_].id].gold -= 1000;
        require(player_.send(1e16), "okt transfer failed");
    }

    // 设置金币参数
    function setGold(uint goldInterval_, uint goldAmount_) public {
        require(msg.sender == owner, "Only admin can put gold.");
        goldInterval = goldInterval_;
        goldAmount = goldAmount_;
    }

    // 放置金币
    function putGold() public {
        require(validBlockToPutGold >= block.number, "Wait, the gold need some time to mint...");
        _randNonce = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randNonce)));
        int x = int(_randNonce % (2*mapSize+1)) - int(mapSize);
        _randNonce = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randNonce)));
        int y = int(_randNonce % (2*mapSize+1)) - int(mapSize);
        if (isValidToPutGold(x, y)) {
          goldOn[x][y].vaildTime = 0;
          goldOn[x][y].punkNumber = 0;
          goldOn[x][y].amount += goldAmount;
          validBlockToPutGold += goldInterval;
        }
        else {
          mapSize ++;
        }
        stillPunks[playerInfo[msg.sender].id].gold += 100;
    }

    // 获取金币
    function getGold(int x, int y) public {
        require(goldOn[x][y].punkNumber > 0 , "Nothing to do.");
        uint t = goldOn[x][y].vaildTime;
        require(getCurrentTime() >= t, "Wait, it's not the time.");
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
      int x = stillPunks[id].x;
      int y = stillPunks[id].y;
      if (goldOn[x][y].vaildTime == lastScheduleOf[id]) {
        return StatusInfo(lastScheduleOf[id], x, y);
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
        require(playerInfo[msg.sender].id == id, "Get authorized first!");
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
      uint time = (block.number - _startBlock) / blockPerRound;
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

    function getPlayerInfo(address player_) public view returns (PlayerInfo memory) {
      return playerInfo[player_];
    }

    function getGoldsofAllPunk() public view returns (uint[667] memory) {
      uint[667] memory golds;
      for (uint i=0; i<667; i++) {
        golds[i] = stillPunks[i+1].gold;
      }
      return golds;
    }

}

