// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LoserLand.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Building {
  
  struct LandInfo {
    uint oldBuilding;
    uint newBuilding;
    uint oldHP;
    uint newHP;
    uint builtTime;
    bool used;
    address owner;
  }
  
  address public owner;
  address public squidAddress;
  address public landAddress;
  address public gameAddress;
  int outerBound = 625;

  mapping (int => mapping (int => LandInfo)) public landInfo;

  constructor(address landAddress_, address squidAddress_) {
    owner = msg.sender;
    landAddress = landAddress_;
    squidAddress = squidAddress_;
  }

  function getLandInfo(int x1, int y1, int x2, int y2) public view returns (uint[] memory) {
    require(x2 >= x1 && y2 >= y1, "Invalid index");
    uint[] memory selectLands = new uint[](uint((x2-x1+1)*(y2-y1+1)));
    uint i = 0;
    for (int x=x1; x<=x2; x++) {
      for (int y=y1; y<=y2; y++) {
        LandInfo memory land = landInfo[x][y];
        selectLands[i] = land.builtTime > block.number? land.oldBuilding : land.newBuilding;
        i ++;
      }
    }
    return selectLands;
  }

  function landOf(int x, int y) public view returns (LandInfo memory) {
    LoserLand loserLand = LoserLand(landAddress);
    LandInfo memory land = landInfo[x][y];
    land.owner = loserLand.landOwner(x, y);
    return land;
  }

  function playerLand(address player) public view returns (int, int) {
    LoserLand land = LoserLand(landAddress);
    if (land.balanceOf(player) == 0) {
      return (0, 0);
    }
    else {
      uint landId = land.tokenOfOwnerByIndex(player, 0);
      return land.positionOf(landId);
    }
  }

  function buildingType(int x, int y) public view returns (uint) {
    LandInfo memory land = landInfo[x][y];
    uint kind = land.builtTime > block.number? land.oldBuilding : land.newBuilding;
    return kind;
  }

  function setOuterBound(int n) public {
    require(msg.sender == owner, "You are not admin");
    outerBound = n;
  }

  function setGameAddress(address addr) public {
    require(msg.sender == owner, "You are not admin");
    gameAddress = addr;
  }

  function _payFee(address player, uint amount) private {
    IERC20 squid = IERC20(squidAddress);
    require(squid.transferFrom(player, address(this), amount), 'Failed to transfer the squid token');
  }

  function payFee(address player, uint amount) public {
    require(msg.sender == gameAddress, "not allowed");
    _payFee(player, amount);
  }

  
  function getProductivity(int x, int y) public view returns (uint) {
    uint kind = buildingType(x, y);
    if (kind/3 == 1) {
      return kind%3 + 1;
    }
    else {
      return 0;
    }
  }

  // 矿场挖矿
  function mine(int x, int y, uint gold) public returns (uint) {
    require(msg.sender == gameAddress, "not allowed");
    if (landInfo[x][y].builtTime > block.number) {
      if (gold >= landInfo[x][y].oldHP) {
        landInfo[x][y].oldBuilding = 0;
        return landInfo[x][y].oldHP;
      }
      else {
        landInfo[x][y].oldHP -= gold;
        return gold;
      }
    }
    else {
      if (gold >= landInfo[x][y].newHP) {
        landInfo[x][y].newBuilding = 0;
        return landInfo[x][y].newHP;
      }
      else {
        landInfo[x][y].newHP -= gold;
        return gold;
      }
    }
    
  }

  // 渔场捕鱼
  function fish(int x, int y) public {
    require(msg.sender == gameAddress, "not allowed");
    if (landInfo[x][y].builtTime > block.number) {
      if (landInfo[x][y].oldHP <= 1) {
        landInfo[x][y].oldBuilding = 0;
      }
      else {
        landInfo[x][y].oldHP -= 1;
      }
    }
    else {
      if (landInfo[x][y].newHP <= 1) {
        landInfo[x][y].newBuilding = 0;
      }
      else {
        landInfo[x][y].newHP -= 1;
      }
    }
  }

  // 房屋收租
  //function charge(int x, int y, uint t) public returns (bool) {
  //  require(msg.sender == gameAddress, "not allowed");
  //  return true;
  //}

  function award(address player, uint amount) public {
    require(msg.sender == gameAddress, "not allowed");
    IERC20 squid = IERC20(squidAddress);
    uint balance = squid.balanceOf(address(this));
    if (balance <= amount) {
      squid.transfer(player, balance);
    }
    else {
      squid.transfer(player, amount);
    }
  }

  function setUsed(int x, int y) public {
    require(msg.sender == gameAddress, "not allowed");
    landInfo[x][y].used = true;
  }

  function mint(int x, int y) public {
    require(x**2 > 100  ||  y**2 > 100, "not open");
    require(x**2 < outerBound &&  y**2 < outerBound, "not open");
    _payFee(msg.sender, 2e18);
    LoserLand land = LoserLand(landAddress);
    land.awardLand(msg.sender, x, y);
    landInfo[x][y].newBuilding = 3;
    landInfo[x][y].newHP = 400;
    landInfo[x][y].builtTime = block.number;
  }

  function _build(int x, int y, uint kind) private {
    if (landInfo[x][y].builtTime <= block.number) {
      landInfo[x][y].oldBuilding = landInfo[x][y].newBuilding;
      landInfo[x][y].oldHP = landInfo[x][y].newHP;
    }
    landInfo[x][y].builtTime = block.number + (kind%3+1)*10000;
    landInfo[x][y].newBuilding = kind;
    if (kind/3 == 1) { //矿场
      landInfo[x][y].newHP = 400;
    }
    else if (kind/3 == 2) { //渔场
      landInfo[x][y].newHP = 20;
    }
    else if (kind/3 == 3) { //房屋
      landInfo[x][y].newHP = 10;
    }
  }

  function build(int x, int y, uint kind) public {
    LoserLand land = LoserLand(landAddress);
    require(land.landOwner(x, y) == msg.sender && kind > 2 && kind < 12, 'not allowed');
    _payFee(msg.sender, (kind%3+1)*1e18);
    _build(x, y, kind);
  }
}

// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LoserLand is ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Position {
      int x;
      int y;
    }

    string baseTokenURI = "https://www.losernft.org/loserland/";

    address public owner;

    // 返回土地拥有者
    mapping (int => mapping (int => uint)) public landOf;
    mapping (uint => Position) public positionOf;
    mapping (address => bool) public isAdmin;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) { owner = msg.sender; }

    function awardLand(address player, int x, int y) public returns (uint256)
    {
        require(isAdmin[msg.sender], "You are not admin");
        require(landOwner(x, y) == address(0), "already mint");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        positionOf[newItemId] = Position(x, y);
        landOf[x][y] = newItemId;
        return newItemId;
    }

    function setAdmin(address candidate, bool b) public {
        require(msg.sender == owner, "You are not admin");
        isAdmin[candidate] = b;
    }

    function landOwner(int x, int y) public view returns (address) {
        uint id = landOf[x][y];
        if (id == 0) {
            return address(0);
        }
        else {
            return ownerOf(id);
        }
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId), ".json"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Building.sol";

contract RogueLand {
    
    enum ActionChoices { SitStill, GoLeft, GoRight, GoUp, GoDown, GoLeftUp, GoLeftDown, GoRightUp, GoRightDown }
	
    struct MovingPunk {
      uint punkId;
      uint punkNonce;
    }

    struct KillEvent {
      uint A;
      uint B;
      uint t;
      int x;
      int y;
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
      uint oldNeighbor;
      uint newNeighbor;
      int x;
      int y;
      uint showtime;
      uint gold;
      uint enemy;
      uint hp;
      uint nonce; // 代表死亡时间
      uint evil; // 记录人头数
    }
    
    struct PunkInfo {      
      uint oldNeighbor;
      uint newNeighbor;
      int x;
      int y;
      bool isMoving;
      uint totalGold;
      uint hp;
      uint evil;
      uint seed;
      address player;
      string name;
      uint blockNumber;
    }

    struct GameInfo {
      uint total;
      uint dead;
      uint pool;
      uint squidBalance;
      uint squidApproved;
      uint hepBalance;
      uint hepApproved;
    }

    uint public constant AC = 9; // 防御力
    uint public constant BAREHAND = 5; // 徒手攻击
    
    address public owner;
    address public hepAddress;
    address public squidAddress;
    address public buildingAddress;
    uint public startBlock; // 记录初始区块数
    uint private _randNonce;
    uint public blockPerRound = 500;
    uint public rewardsPerRound = 5e15;
    //bool public gameOver;
    uint public totalPunk; // 记录报名信息
    address[] public deadPunk; // 记录死亡信息

  
    // 储存玩家授权信息
    mapping (uint => address) public punkMaster;
    mapping (address => uint) public punkOf;
    mapping (address => string) public nickNameOf;

    // 储存punk的时空信息
    mapping (uint => mapping (uint => Position)) public movingPunks;

    // 储存punk最后规划的信息
    mapping (uint => uint) public lastScheduleOf;

    // 储存随机种子，用于战斗
    //mapping (uint => uint) private _randseedOfRound;
    mapping (uint => uint) private _randseedOfPunk;

    // 储存punk最后的位置信息
    mapping (uint => StillPunk) public stillPunks;

    // 储存punk最后的死亡信息
    mapping (address => KillEvent) public lastKilled;

    // 储存punk的行动信息
    mapping (address => mapping (uint => bool)) public takeAction;

    // 储存静止punk的空间信息
    mapping (int => mapping (int => uint)) public stillPunkOn;
  
    // 储存时空信息
    mapping (uint => mapping (int => mapping (int => MovingPunk))) public movingPunksOn;


    event ActionCommitted(uint indexed punkId, uint indexed time, ActionChoices action);
    event UseHEP(uint indexed id, uint restore);
    event Attacked(uint indexed punkA, uint indexed punkB, uint damage);
    event Killed(uint indexed punkA, uint indexed punkB);
    event Fishing(uint indexed id, int x, int y, uint gold);
  
    constructor(address buildingAddress_, address hepAddress_, address squidAddress_) {
        owner = msg.sender;
        buildingAddress = buildingAddress_;
        hepAddress = hepAddress_;
        squidAddress = squidAddress_;
        _randNonce = uint(keccak256(abi.encode(block.timestamp, msg.sender)));
        //_randseedOfRound[0] = _randNonce;
    }

    // 增加下一回合信息
    function getEvents(int x1, int y1, int x2, int y2, uint t) public view returns (uint[] memory) {
        require(x2 >= x1 && y2 >= y1, "Invalid index");
        uint[] memory selectEvents = new uint[](uint((x2-x1+1)*(y2-y1+1)));
        uint i = 0;
        for (int x=x1; x<=x2; x++) {
          for (int y=y1; y<=y2; y++) {
            selectEvents[i] = getPunkOn(t, x, y);
            i ++;
          }
        }
        return selectEvents;
    }

    function getDeadPunk() public view returns (KillEvent[] memory) {
        KillEvent[] memory _deadPunks = new KillEvent[](deadPunk.length);
        for (uint i=0; i<deadPunk.length; i++) {
          _deadPunks[i] = lastKilled[deadPunk[i]];
        }
        return _deadPunks;
    }

    function _resetPunk(uint id, int x, int y) private {
      uint t = getCurrentTime();
      lastScheduleOf[id] = t;
      stillPunks[id].hp = 15; // 初始生命值为15
      stillPunks[id].nonce = t;
      stillPunks[id].evil = 0;
      stillPunks[id].gold = 0;
      stillPunks[id].showtime = t;
      _addStillPunk(id, x, y, t);
    }

    // 玩家设置昵称
    function setNickName(string memory name) public {
        nickNameOf[msg.sender] = name;
    }

    function freePunk() public view returns (uint) {
      uint id;
      for (id=2; id<=667; id++) {
        if (punkMaster[id] == address(0)) {
          break;
        }
      }
      return id;
    }

    function gameInfo(address player) public view returns (GameInfo memory) {
        uint total = totalPunk;
        uint dead = deadPunk.length;
        IERC20 squid = IERC20(squidAddress);
        uint pool = squid.balanceOf(buildingAddress);
        uint squidBalance = squid.balanceOf(player);
        uint squidApproved = squid.allowance(player, buildingAddress);
        IERC20 hep = IERC20(hepAddress);
        uint hepBalance = hep.balanceOf(player);
        uint hepApproved = hep.allowance(player, address(this));
        return GameInfo(total, dead, pool, squidBalance, squidApproved, hepBalance, hepApproved);
    }

    function register(uint id) public {
        if (id == 0) {
          id = freePunk();
        }
        require(id >= 2 && id <= 667, 'invalid');
        require(punkMaster[id] == address(0), 'not free punk');
        require(punkOf[msg.sender] == 0, "registered!");
        Building building = Building(buildingAddress);
        (int x, int y) = building.playerLand(msg.sender);
        require(x != 0 || y != 0, "you don't have land");
        (,,,,,bool used,) = building.landInfo(x, y);
        if (used) {
          building.payFee(msg.sender, 1e18);
        }
        else {
          building.setUsed(x, y);
        }
        punkMaster[id] = msg.sender;
        punkOf[msg.sender] = id;
        _randseedOfPunk[id] = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randNonce)));
        _resetPunk(id, x, y);
        totalPunk ++;
    }

    // 设置游戏开始与结束时间
    function startGame(uint startBlock_) public {
        require(msg.sender == owner, "Only admin can start the game.");
        startBlock = startBlock_;
    }

    function setRewards(uint rewards) public {
        require(msg.sender == owner, "Only admin can start the game.");
        rewardsPerRound = rewards;
    }


    // punkA击杀了punkB
    function _kill(uint A, uint B, uint t, int x, int y) private {
      // 阻止B后续的移动
      _removeStillPunk(B);
      // 失去连接
      lastKilled[punkMaster[B]] = KillEvent(A, B, t, x, y);
      deadPunk.push(punkMaster[B]);
      punkOf[punkMaster[B]] = 0;
      punkMaster[B] = address(0);
      // A获得了B的所有金币
      stillPunks[A].gold += (stillPunks[B].gold);
      stillPunks[B].gold = 0;
      stillPunks[A].enemy = 0;
      stillPunks[B].enemy = 0;
      // A变得更邪恶了
      stillPunks[A].evil ++;
      Building building = Building(buildingAddress);
      building.award(msg.sender, 2e17);
      
	    emit Killed(A, B);
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
		    emit Attacked(A, B, dice%5+1);
      }
	    else {
		    emit Attacked(A, B, 0);
	    }
    }

    // punkA向punkB进攻
    function attack(uint A, uint B) public {
      require(punkOf[msg.sender] == A, "Get authorized first!");
      require(A > 0 && B > 0, "Punk not exit!");
      require(punkMaster[B] != address(0), "You attack a dead punk!");
      require(!takeAction[msg.sender][block.number/10], "cooldown");
      takeAction[msg.sender][block.number/10] = true;
      uint t = getCurrentTime();
      Position memory posA = getPostion(A, t);
      Position memory posB = getPostion(B, t);
	    //require(stillPunks[A].showtime <= t, "punk A is moving");
      //require(t > stillPunks[B].nonce, "punk B is just born!");
      //require(posA.x**2 < 625 && posA.y**2 < 625 && posB.x**2 < 625 && posB.y**2 < 625, "cannot attack punks outside the game area");
      require((posA.x-posB.x)**2 <=1  &&  (posA.y-posB.y)**2 <=1, "can only attack neighbors");
      Building building = Building(buildingAddress);
      require(building.buildingType(posB.x, posB.y)/3 != 3, "cannot attack punk in the house");

      if (stillPunks[A].enemy != B) {
        stillPunks[A].enemy = B;
      }

      _attack(A, B);
      if (stillPunks[B].hp == 0) {
        _kill(A, B, t, posB.x, posB.y);
      }
      else {
        // punkB自动反击
        _attack(B, A);
        if (stillPunks[A].hp == 0) {
          _kill(B, A, t, posA.x, posA.y);
        }
      }
    }

    // 只能在非战状态下时使用HEP
    function useHEP(uint id) public {
      IERC20 hep = IERC20(hepAddress);
      require(hep.transferFrom(msg.sender, address(this), 1), 'Failed to use hep');

      require(!takeAction[msg.sender][block.number/10], "cooldown");
      takeAction[msg.sender][block.number/10] = true;

      // 之后加入该机制
      //if (stillPunks[id].enemy != 0) {
      //  leaveBattle(id);
      //}

      stillPunks[id].hp += 10;
      if (stillPunks[id].hp > 15) {
        emit UseHEP(id, 25-stillPunks[id].hp);
        stillPunks[id].hp = 15;
      }
      else {
        emit UseHEP(id, 10);
      }
    }

    function _removeStillPunk(uint id) private {
        uint oldNeighbor = stillPunks[id].oldNeighbor;
        uint newNeighbor = stillPunks[id].newNeighbor;
        int x = stillPunks[id].x;
        int y = stillPunks[id].y;
        if (oldNeighbor > 0) {
          stillPunks[oldNeighbor].newNeighbor = newNeighbor;
        }
        else {
          stillPunkOn[x][y] = newNeighbor;
        }
        if (newNeighbor > 0) {
          stillPunks[newNeighbor].oldNeighbor = oldNeighbor;
        }

        // 自动进行挖矿操作
        uint gold = pendingGold(id);
        if (gold > 0) {
          Building building = Building(buildingAddress);
          stillPunks[id].gold += building.mine(x, y, gold);
        }
    }

    function _addStillPunk(uint id, int x, int y, uint t) private {
        Building building = Building(buildingAddress);
        LoserLand loserLand = LoserLand(building.landAddress());
        address landOwner = loserLand.landOwner(x, y);
        if (building.buildingType(x, y)/3 == 3 && msg.sender != landOwner) {
          building.payFee(msg.sender, (building.buildingType(x, y)%3+1) * 5e16);
          building.award(landOwner, (building.buildingType(x, y)%3+1) * 5e16);
        }
        require (getPunkOn(t, x, y) == 0 || building.buildingType(x, y)/3 == 3, 'other punk already on it!');
        require (building.buildingType(x, y)/3 != 2, 'cannot swimming');
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
    }

    function _addMovingPunk(uint id, uint t, int x, int y) private {
        movingPunksOn[t][x][y].punkId = id;
        movingPunksOn[t][x][y].punkNonce = stillPunks[id].nonce;
        movingPunks[id][t].x = x;
        movingPunks[id][t].y = y;
    }



    // 操作punk
    function scheduleAction(uint id, ActionChoices action) public {
        require(punkOf[msg.sender] == id, "Get authorized first!");
        require(id > 0, "Punk not exit!");
        require(action != ActionChoices.SitStill, "Not allowed!");
        uint currentTime = getCurrentTime();
        if (lastScheduleOf[id] < currentTime) {
          lastScheduleOf[id] = currentTime;
        }
        uint t = lastScheduleOf[id];
        int x = stillPunks[id].x;
        int y = stillPunks[id].y;
        // remove this punk from still punks in (x, y) 
        _removeStillPunk(id);
        _addMovingPunk(id, t, x, y);
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
      if (startBlock == 0 || startBlock > block.number) {
        return 0;
      }
      uint time = (block.number - startBlock) / blockPerRound + 1;
      return time;
    }

    function getPunkInfo(uint id) public view returns (PunkInfo memory) {
      uint t = getCurrentTime();
      Position memory pos = getPostion(id, t);
      address player = punkMaster[id];
      uint totalGold = stillPunks[id].gold + pendingGold(id);
      bool isMoving = (t == stillPunks[id].nonce) || (stillPunks[id].showtime > t);
      return PunkInfo(stillPunks[id].oldNeighbor, stillPunks[id].newNeighbor, pos.x, pos.y, isMoving, totalGold, stillPunks[id].hp, stillPunks[id].evil, _randseedOfPunk[id], player, nickNameOf[player], block.number);
    }

    function getPunkOn(uint t, int x, int y) public view returns (uint) {
      if (stillPunkOn[x][y] != 0  && stillPunks[stillPunkOn[x][y]].showtime <= t) {
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
        golds[i] = punkMaster[i+1] == address(0) ? 0 : stillPunks[i+1].gold;
      }
      return golds;
    }

    function pendingGold(uint id) public view returns (uint) {
      uint time = getCurrentTime();
      if (stillPunks[id].showtime < time) {
        Building building = Building(buildingAddress);
        uint productivity = building.getProductivity(stillPunks[id].x, stillPunks[id].y);
        return (time - stillPunks[id].showtime) * productivity * rewardsPerRound;
      }
      else {
        return 0;
      }
    }

    function fish(int x, int y) public {
      uint id = punkOf[msg.sender];
      require(id > 0, "Punk not exit!");
      uint t = getCurrentTime();
      Position memory pos = getPostion(id, t);
      require((pos.x-x)**2 <=1  &&  (pos.y-y)**2 <=1, "can only fish neighbors");
      Building building = Building(buildingAddress);
      require (building.buildingType(x, y)/3 == 2, 'cannot swimming');
      require (t >= stillPunks[id].showtime, "you are moving");
      _randNonce = uint(keccak256(abi.encode(_randNonce, block.timestamp, msg.sender)));
      if (_randNonce % 40 < t - stillPunks[id].showtime) {
        uint _gold = building.buildingType(x, y) % 3 + 1; 
        building.fish(x, y);
        stillPunks[id].gold += _gold * 20 * rewardsPerRound;
        emit Fishing(id, x, y, _gold);
      }
      else {
        emit Fishing(id, x, y, 0);
      }
      stillPunks[id].showtime = t;
    }

    function charge(uint A, uint B, bool getOut) public {
      require(punkOf[msg.sender] == A, "Get authorized first!");
      require(A > 0 && B > 0, "Punk not exit!");
      require(punkMaster[B] != address(0), "You are charging a dead punk!");
      uint t = getCurrentTime();
      Position memory posA = getPostion(A, t);
      Position memory posB = getPostion(B, t);
      require((posA.x-posB.x)**2 <=1  &&  (posA.y-posB.y)**2 <=1, "can only charge neighbors");
      Building building = Building(buildingAddress);
      require(building.buildingType(posB.x, posB.y)/3 == 3, "not in house");
      LoserLand loserLand = LoserLand(building.landAddress());
      address landOwner = loserLand.landOwner(posA.x, posA.y);
      require(landOwner == msg.sender, "not owner");
      require(stillPunks[A].showtime <= t, "punk A is moving");
      require(t - stillPunks[B].showtime > 5, "invalid");
      if (getOut) {
        _removeStillPunk(B);
        _removeStillPunk(A);
        _addStillPunk(A, posB.x, posB.y, t);
        _addStillPunk(B, posA.x, posA.y, t);
      }
      else {
        uint gold = (building.buildingType(posB.x, posB.y)%3+1) * (t-stillPunks[B].showtime) * 1e16;
        building.payFee(msg.sender, gold);
        building.award(landOwner, gold);
        stillPunks[B].showtime = t;
      }
    }

    // 领取奖励
    function claimRewards() public {
      uint id = punkOf[msg.sender];
      require(id > 0, "Punk not exit!");
      uint t = getCurrentTime();
      Position memory pos = getPostion(id, t);
      Building building = Building(buildingAddress);
      require(building.buildingType(pos.x, pos.y)/3 == 3, 'go to house to claim your reward');
      building.award(msg.sender, stillPunks[id].gold);
      stillPunks[id].gold = 0;
      // 自杀
      //_removeStillPunk(id);
      //punkOf[punkMaster[id]] = 0;
      //punkMaster[id] = address(0);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}