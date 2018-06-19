pragma solidity ^0.4.23;

contract Ownable {
  address public owner;

  event NewOwner (address indexed owner);

  constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner () {
    if (owner != msg.sender) revert();
    _;
  }

  function setOwner (address candidate) public onlyOwner {
    if (candidate == address(0)) revert();
    owner = candidate;
    emit NewOwner(owner);
  }
}

contract TokenAware is Ownable {
  function withdrawToken (address addressOfToken, uint256 amount) public onlyOwner returns (bool) {
    bytes4 hashOfTransfer = bytes4(keccak256(&#39;transfer(address,uint256)&#39;));

    return addressOfToken.call(hashOfTransfer, owner, amount);
  }
}

contract Destructible is TokenAware {
  function kill () public onlyOwner {
    selfdestruct(owner);
  }
}

contract Pausable is Destructible {
  bool public paused;

  event NewStatus (bool isPaused);

  modifier whenNotPaused () {
    if (paused) revert();
    _;
  }

  modifier whenPaused () {
    if (!paused) revert();
    _;
  }

  function setStatus (bool isPaused) public onlyOwner {
    paused = isPaused;
    emit NewStatus(isPaused);
  }
}

contract Operable is Pausable {
  address[] public operators;

  event NewOperator(address indexed operator);
  event RemoveOperator(address indexed operator);

  constructor (address[] newOperators) public {
    operators = newOperators;
  }

  modifier restricted () {
    if (owner != msg.sender &&
        !containsOperator(msg.sender)) revert();
    _;
  }

  modifier onlyOperator () {
    if (!containsOperator(msg.sender)) revert();
    _;
  }

  function containsOperator (address candidate) public constant returns (bool) {
    for (uint256 x = 0; x < operators.length; x++) {
      address operator = operators[x];
      if (candidate == operator) {
        return true;
      }
    }

    return false;
  }

  function indexOfOperator (address candidate) public constant returns (int256) {
    for (uint256 x = 0; x < operators.length; x++) {
      address operator = operators[x];
      if (candidate == operator) {
        return int256(x);
      }
    }

    return -1;
  }

  function addOperator (address candidate) public onlyOwner {
    if (candidate == address(0) || containsOperator(candidate)) revert();
    operators.push(candidate);
    emit NewOperator(candidate);
  }

  function removeOperator (address operator) public onlyOwner {
    int256 indexOf = indexOfOperator(operator);

    if (indexOf < 0) revert();

    // overwrite operator with last operator in the array
    if (uint256(indexOf) != operators.length - 1) {
      address lastOperator = operators[operators.length - 1];
      operators[uint256(indexOf)] = lastOperator;
    }

    // delete the last element
    delete operators[operators.length - 1];
    emit RemoveOperator(operator);
  }
}

contract EtherShuffleLite is Operable {

  uint256 public nextGameId = 1;
  uint256 public lowestGameWithoutQuorum = 1;

  uint256[5] public distributions = [300000000000000000, // 30%
    240000000000000000, // 20%
    220000000000000000, // 10%
    0, 
    0];

  uint8 public constant countOfParticipants = 5;
  uint256 public gamePrice = 15 finney;

  mapping (uint256 => Shuffle) public games;
  mapping (address => uint256[]) public gamesByPlayer;
  mapping (address => uint256) public balances;

  struct Shuffle {
    uint256 id;
    address[] players;
    bytes32 hash;
    uint8[5] result;
    bytes32 secret;
    uint256 value;
    uint256 price;
  }

  event NewGame (uint256 indexed gameId);
  event NewHash (uint256 indexed gameId);
  event NewReveal (uint256 indexed gameId);
  event NewPrice (uint256 price);
  event NewDistribution (uint256[5]);
  event Quorum (uint256 indexed gameId);

  constructor (address[] operators)
    Operable(operators) public {
  }

  modifier onlyExternalAccount () {
    uint size;
    address addr = msg.sender;
    assembly { size := extcodesize(addr) }
    if (size > 0) revert();
    _;
  }

  function newGame () public payable whenNotPaused onlyExternalAccount {
    if (msg.value != gamePrice) revert();

    uint256 gameId = nextGameId;
    nextGameId++;
    Shuffle storage game = games[gameId];

    // ensure this is a real uninitialized game
    if (game.id != 0) revert();

    game.id = gameId;
    game.price = gamePrice;

    emit NewGame(gameId);

    joinGameInternal(game, msg.sender, msg.value);
  }

  function joinGame (uint256 gameId) public payable whenNotPaused onlyExternalAccount {
    Shuffle storage game = games[gameId];
    joinGameInternal(game, msg.sender, msg.value);
  }

  function joinGameFromBalance (uint256 gameId) public whenNotPaused {
    uint256 balanceOf = balances[msg.sender];
    Shuffle storage game = games[gameId];

    if (balanceOf < game.price) revert();

    balances[msg.sender] -= game.price;
    joinGameInternal(game, msg.sender, game.price);
  }

  function joinGameInternal (Shuffle storage game, address player, uint256 value) private {
    if (game.id == 0) revert();

    if (game.players.length == countOfParticipants) revert();

    if (value != game.price) revert();
    game.value += gamePrice;
    if (game.value < gamePrice) revert();

    game.players.push(player);
    gamesByPlayer[player].push(game.id);

    if (game.players.length == countOfParticipants) {
      emit Quorum(game.id);
    }
  }

  /* Informational constant functions */

  function gamesOf (address player) public constant returns (uint256[]) {
    return gamesByPlayer[player];
  }

  function balanceOf (address player) public constant returns (uint256) {
    return balances[player];
  }

  function getPlayers (uint256 gameId) public constant returns (address[]) {
    Shuffle storage game = games[gameId];
    return game.players;
  }

  function hasHash (uint256 gameId) public constant returns (bool) {
    Shuffle storage game = games[gameId];
    return game.hash != bytes32(0);
  }

  function getHash (uint256 gameId) public constant returns (bytes32) {
    Shuffle storage game = games[gameId];
    return game.hash;
  }

  function getResult (uint256 gameId) public constant returns (uint8[5]) {
    Shuffle storage game = games[gameId];
    return game.result;
  }

  function hasSecret (uint256 gameId) public constant returns (bool) {
    Shuffle storage game = games[gameId];
    return game.secret != bytes32(0);
  }

  function getSecret (uint256 gameId) public constant returns (bytes32) {
    Shuffle storage game = games[gameId];
    return game.secret;
  }
    
  function getValue (uint256 gameId) public constant returns (uint256) {
    Shuffle storage game = games[gameId];
    return game.value;
  }

  /* For operators */

  function setHash (uint256 gameId, bytes32 hash) public whenNotPaused restricted {
    Shuffle storage game = games[gameId];

    if (game.hash != bytes32(0)) revert();

    game.hash = hash;
    emit NewHash(game.id);
  }

  function reveal (uint256 gameId, uint8[5] result, bytes32 secret) public whenNotPaused restricted {
    Shuffle storage game = games[gameId];
    if (game.players.length < uint256(countOfParticipants)) revert();
    if (game.secret != bytes32(0)) revert();

    bytes32 hash = keccak256(result, secret);
    if (game.hash != hash) revert();

    game.secret = secret;
    game.result = result;
    disburse(game);
    emit NewReveal(gameId);
  }

  function disburse (Shuffle storage game) private restricted {

    uint256 totalValue = game.value;

    for (uint8 x = 0; x < game.result.length; x++) {
      uint256 indexOfDistribution = game.result[x];
      address player = game.players[x];
      uint256 playerDistribution = distributions[indexOfDistribution];
      uint256 disbursement = totalValue * playerDistribution / (1 ether);
      uint256 playerBalance = balances[player];

      game.value -= disbursement;
      playerBalance += disbursement;
      if (playerBalance < disbursement) revert();
      balances[player] = playerBalance;
    }

    balances[owner] += game.value;
    game.value = 0;
  }

  /* For the owner */

  function setPrice (uint256 price) public onlyOwner {
    gamePrice = price;
    emit NewPrice(price);
  }

  function setDistribution (uint256[5] winnings) public onlyOwner {
    distributions = winnings;
    emit NewDistribution(winnings);
  }

  /* For players */

  // anyone can withdraw on behalf of someone (when the player lacks the gas, for instance)
  function withdrawToMany (address[] players) public {
    for (uint8 x = 0; x < players.length; x++) {
      address player = players[x];

      withdrawTo(player);
    }
  }

  function withdraw () public {
    withdrawTo(msg.sender);
  }

  function withdrawTo (address player) public {
    uint256 playerBalance = balances[player];

    if (playerBalance > 0) {
      balances[player] = 0;

      player.transfer(playerBalance);
    }
  }

  /* Utility */

  function contains (uint256 gameId, address candidate) public constant returns (bool) {
    Shuffle storage game = games[gameId];
    return contains(game, candidate);
  }

  function contains (Shuffle storage game, address candidate) private constant returns (bool) {
    for (uint256 x = 0; x < game.players.length; x++) {
      address player = game.players[x];
      if (candidate == player) {
        return true;
      }
    }

    return false;
  }

  function createHash (uint8[5] result, bytes32 secret) public pure returns (bytes32) {
    bytes32 hash = keccak256(result, secret);
    return hash;
  }

  function verify (bytes32 hash, uint8[5] result, bytes32 secret) public pure returns (bool) {
    return hash == createHash(result, secret);
  }

  function verifyGame (uint256 gameId) public constant returns (bool) {
    Shuffle storage game = games[gameId];
    return verify(game.hash, game.result, game.secret);
  }

  function getDistributions () public constant returns (uint256[5]) {
    return distributions;
  }
}