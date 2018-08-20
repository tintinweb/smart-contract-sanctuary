pragma solidity ^0.4.24;

// SafeMath library
library SafeMath {
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
		uint256 c = _a + _b;
		assert(c >= _a);
		return c;
	}

	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		assert(_a >= _b);
		return _a - _b;
	}

	function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
     return 0;
    }
		uint256 c = _a * _b;
		assert(c / _a == _b);
		return c;
	}

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return _a / _b;
	}
}

// Contract must have an owner
contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "onlyOwner wrong");
    _;
  }

  function setOwner(address _owner) onlyOwner public {
    owner = _owner;
  }
}

interface ERC20Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _addr) external view returns (uint256);
  function decimals() external view returns (uint8);
}

// the WTA Gamebook that records games, players and admins
contract WTAGameBook is Ownable{
  using SafeMath for uint256;

  string public name = "WTAGameBook V0.5";
  string public version = "0.5";

  // admins info
  address[] public admins;
  mapping (address => uint256) public adminId;

  // games info
  address[] public games;
  mapping (address => uint256) public gameId;

  //players info
  struct PlayerInfo {
    uint256 pid;
    address paddr;
    uint256 referrer;
  }

  uint256 public playerNum = 0;
  mapping (uint256 => PlayerInfo) public player;
  mapping (address => uint256) public playerId;

  event AdminAdded(address indexed _addr, uint256 _id, address indexed _adder);
  event AdminRemoved(address indexed _addr, uint256 _id, address indexed _remover);
  event GameAdded(address indexed _addr, uint256 _id, address indexed _adder);
  event GameRemoved(address indexed _addr, uint256 _id, address indexed _remover);
  event PlayerAdded(uint256 _pid, address indexed _paddr, uint256 _ref, address indexed _adder);

  event WrongTokenEmptied(address indexed _token, address indexed _addr, uint256 _amount);
  event WrongEtherEmptied(address indexed _addr, uint256 _amount);

  // check the address is human or contract
  function isHuman(address _addr) public view returns (bool) {
    uint256 _codeLength;
    assembly {_codeLength := extcodesize(_addr)}
    return (_codeLength == 0);
  }

  // address not zero
  modifier validAddress(address _addr) {
		require(_addr != 0x0, "validAddress wrong");
		_;
	}

  modifier onlyAdmin() {
    require(adminId[msg.sender] != 0, "onlyAdmin wrong");
    _;
  }

  modifier onlyAdminOrGame() {
    require((adminId[msg.sender] != 0) || (gameId[msg.sender] != 0), "onlyAdminOrGame wrong");
    _;
  }

  // create new GameBook contract, no need arguments
  constructor() public {
    // initialization
    // empty admin with id 0
    adminId[address(0x0)] = 0;
    admins.length++;
    admins[0] = address(0x0);

    // empty game with id 0
    gameId[address(0x0)] = 0;
    games.length++;
    games[0] = address(0x0);

    // first admin is owner
    addAdmin(owner);
  }

  // owner may add or remove admins
  function addAdmin(address _admin) onlyOwner validAddress(_admin) public {
    require(isHuman(_admin), "addAdmin human only");

    uint256 id = adminId[_admin];
    if (id == 0) {
      adminId[_admin] = admins.length;
      id = admins.length++;
    }
    admins[id] = _admin;
    emit AdminAdded(_admin, id, msg.sender);
  }

  function removeAdmin(address _admin) onlyOwner validAddress(_admin) public {
    require(adminId[_admin] != 0, "removeAdmin wrong");

    uint256 aid = adminId[_admin];
    adminId[_admin] = 0;
    for (uint256 i = aid; i<admins.length-1; i++){
        admins[i] = admins[i+1];
        adminId[admins[i]] = i;
    }
    delete admins[admins.length-1];
    admins.length--;
    emit AdminRemoved(_admin, aid, msg.sender);
  }

  // admins may add or remove games
  function addGame(address _game) onlyAdmin validAddress(_game) public {
    require(!isHuman(_game), "addGame inhuman only");

    uint256 id = gameId[_game];
    if (id == 0) {
      gameId[_game] = games.length;
      id = games.length++;
    }
    games[id] = _game;
    emit GameAdded(_game, id, msg.sender);
  }

  function removeGame(address _game) onlyAdmin validAddress(_game) public {
    require(gameId[_game] != 0, "removeGame wrong");

    uint256 gid = gameId[_game];
    gameId[_game] = 0;
    for (uint256 i = gid; i<games.length-1; i++){
        games[i] = games[i+1];
        gameId[games[i]] = i;
    }
    delete games[games.length-1];
    games.length--;
    emit GameRemoved(_game, gid, msg.sender);
  }

  // admins and games may add players, and players cannot be removed
  function addPlayer(address _addr, uint256 _ref) onlyAdminOrGame validAddress(_addr) public returns (uint256) {
    require(isHuman(_addr), "addPlayer human only");
    require((_ref < playerNum.add(1)) && (playerId[_addr] == 0), "addPlayer parameter wrong");
    playerId[_addr] = playerNum.add(1);
    player[playerNum.add(1)] = PlayerInfo({pid: playerNum.add(1), paddr: _addr, referrer: _ref});
    playerNum++;
    emit PlayerAdded(playerNum, _addr, _ref, msg.sender);
    return playerNum;
  }

  // interface methods
  function getPlayerIdByAddress(address _addr) validAddress(_addr) public view returns (uint256) {
    return playerId[_addr];
  }

  function getPlayerAddressById(uint256 _id) public view returns (address) {
    require(_id <= playerNum && _id > 0, "getPlayerAddressById wrong");
    return player[_id].paddr;
  }

  function getPlayerRefById(uint256 _id) public view returns (uint256) {
    require(_id <= playerNum && _id > 0, "getPlayerRefById wrong");
    return player[_id].referrer;
  }

  function getGameIdByAddress(address _addr) validAddress(_addr) public view returns (uint256) {
    return gameId[_addr];
  }

  function getGameAddressById(uint256 _id) public view returns (address) {
    require(_id < games.length && _id > 0, "getGameAddressById wrong");
    return games[_id];
  }

  function isAdmin(address _addr) validAddress(_addr) public view returns (bool) {
    return (adminId[_addr] > 0);
  }

  // Safety measures
  function () public payable {
    revert();
  }

  function emptyWrongToken(address _addr) onlyAdmin public {
    ERC20Token wrongToken = ERC20Token(_addr);
    uint256 amount = wrongToken.balanceOf(address(this));
    require(amount > 0, "emptyToken need more balance");
    require(wrongToken.transfer(msg.sender, amount), "empty Token transfer wrong");

    emit WrongTokenEmptied(_addr, msg.sender, amount);
  }

  // shouldn&#39;t happen, just in case
  function emptyWrongEther() onlyAdmin public {
    uint256 amount = address(this).balance;
    require(amount > 0, "emptyEther need more balance");
    msg.sender.transfer(amount);

    emit WrongEtherEmptied(msg.sender, amount);
  }

}