pragma solidity ^0.4.23;






// @title iNovaStaking
// @dev The interface for cross-contract calls to the Nova Staking contract
// @author Dragon Foundry (https://www.nvt.gg)
// (c) 2018 Dragon Foundry LLC. All Rights Reserved. This code is not open source.
contract iNovaStaking {

  function balanceOf(address _owner) public view returns (uint256);
}



// @title iNovaGame
// @dev The interface for cross-contract calls to the Nova Game contract
// @author Dragon Foundry (https://www.nvt.gg)
// (c) 2018 Dragon Foundry LLC. All Rights Reserved. This code is not open source.
contract iNovaGame {
  function isAdminForGame(uint _game, address account) external view returns(bool);

  // List of all games tracked by the Nova Game contract
  uint[] public games;
}



// @title SafeMath
// @dev Math operations with safety checks that throw on error
library SafeMath {

  // @dev Multiplies two numbers, throws on overflow.
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b, "mul failed");
    return c;
  }

  // @dev Integer division of two numbers, truncating the quotient.
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  // @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub fail");
    return a - b;
  }

  // @dev Adds two numbers, throws on overflow.
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "add fail");
    return c;
  }
}


// @title Nova Game Access (Nova Token Game Access Control)
// @dev NovaGame contract for controlling access to games, and allowing managers to add and remove operator accounts
// @author Dragon Foundry (https://www.nvt.gg)
// (c) 2018 Dragon Foundry LLC. All Rights Reserved. This code is not open source.
contract NovaGameAccess is iNovaGame {
  using SafeMath for uint256;

  event AdminPrivilegesChanged(uint indexed game, address indexed account, bool isAdmin);
  event OperatorPrivilegesChanged(uint indexed game, address indexed account, bool isAdmin);

  // Admin addresses are stored both by gameId and address
  mapping(uint => address[]) public adminAddressesByGameId; 
  mapping(address => uint[]) public gameIdsByAdminAddress;

  // Stores admin status (as a boolean) by gameId and account
  mapping(uint => mapping(address => bool)) public gameAdmins;

  // Reference to the Nova Staking contract
  iNovaStaking public stakingContract;

  // @dev Access control modifier to limit access to game admin accounts
  modifier onlyGameAdmin(uint _game) {
    require(gameAdmins[_game][msg.sender]);
    _;
  }

  constructor(address _stakingContract)
    public
  {
    stakingContract = iNovaStaking(_stakingContract);
  }

  // @dev gets the admin status for a game & account
  // @param _game - the gameId of the game
  // @param _account - the address of the user
  // @returns bool - the admin status of the requested account for the requested game
  function isAdminForGame(uint _game, address _account)
    external
    view
  returns(bool) {
    return gameAdmins[_game][_account];
  }

  // @dev gets the list of admins for a game
  // @param _game - the gameId of the game
  // @returns address[] - the list of admin addresses for the requested game
  function getAdminsForGame(uint _game) 
    external
    view
  returns(address[]) {
    return adminAddressesByGameId[_game];
  }

  // @dev gets the list of games that the requested account is the admin of
  // @param _account - the address of the user
  // @returns uint[] - the list of game Ids for the requested account
  function getGamesForAdmin(address _account) 
    external
    view
  returns(uint[]) {
    return gameIdsByAdminAddress[_account];
  }

  // @dev Adds an address as an admin for a game
  // @notice Can only be called by an admin of the game
  // @param _game - the gameId of the game
  // @param _account - the address of the user
  function addAdminAccount(uint _game, address _account)
    external
    onlyGameAdmin(_game)
  {
    require(_account != msg.sender);
    require(_account != address(0));
    require(!gameAdmins[_game][_account]);
    _addAdminAccount(_game, _account);
  }

  // @dev Removes an address from an admin for a game
  // @notice Can only be called by an admin of the game.
  // @notice Can&#39;t remove your own account&#39;s admin privileges.
  // @param _game - the gameId of the game
  // @param _account - the address of the user to remove admin privileges.
  function removeAdminAccount(uint _game, address _account)
    external
    onlyGameAdmin(_game)
  {
    require(_account != msg.sender);
    require(gameAdmins[_game][_account]);
    
    address[] storage opsAddresses = adminAddressesByGameId[_game];
    uint startingLength = opsAddresses.length;
    // Yes, "i < startingLength" is right. 0 - 1 == uint.maxvalue, not -1.
    for (uint i = opsAddresses.length - 1; i < startingLength; i--) {
      if (opsAddresses[i] == _account) {
        uint newLength = opsAddresses.length.sub(1);
        opsAddresses[i] = opsAddresses[newLength];
        delete opsAddresses[newLength];
        opsAddresses.length = newLength;
      }
    }

    uint[] storage gamesByAdmin = gameIdsByAdminAddress[_account];
    startingLength = gamesByAdmin.length;
    for (i = gamesByAdmin.length - 1; i < startingLength; i--) {
      if (gamesByAdmin[i] == _game) {
        newLength = gamesByAdmin.length.sub(1);
        gamesByAdmin[i] = gamesByAdmin[newLength];
        delete gamesByAdmin[newLength];
        gamesByAdmin.length = newLength;
      }
    }

    gameAdmins[_game][_account] = false;
    emit AdminPrivilegesChanged(_game, _account, false);
  }

  // @dev Adds an address as an admin for a game
  // @notice Can only be called by an admin of the game
  // @notice Operator privileges are managed on the layer 2 network
  // @param _game - the gameId of the game
  // @param _account - the address of the user to
  // @param _isOperator - "true" to grant operator privileges, "false" to remove them
  function setOperatorPrivileges(uint _game, address _account, bool _isOperator)
    external
    onlyGameAdmin(_game)
  {
    emit OperatorPrivilegesChanged(_game, _account, _isOperator);
  }

  // @dev Internal function to add an address as an admin for a game
  // @param _game - the gameId of the game
  // @param _account - the address of the user
  function _addAdminAccount(uint _game, address _account)
    internal
  {
    address[] storage opsAddresses = adminAddressesByGameId[_game];
    require(opsAddresses.length < 256, "a game can only have 256 admins");
    for (uint i = opsAddresses.length; i < opsAddresses.length; i--) {
      require(opsAddresses[i] != _account);
    }

    uint[] storage gamesByAdmin = gameIdsByAdminAddress[_account];
    require(gamesByAdmin.length < 256, "you can only own 256 games");
    for (i = gamesByAdmin.length; i < gamesByAdmin.length; i--) {
      require(gamesByAdmin[i] != _game, "you can&#39;t become an operator twice");
    }
    gamesByAdmin.push(_game);

    opsAddresses.push(_account);
    gameAdmins[_game][_account] = true;
    emit AdminPrivilegesChanged(_game, _account, true);
  }
}


// @title Nova Game (Nova Token Game Data)
// @dev NovaGame contract for managing all game data
// @author Dragon Foundry (https://www.nvt.gg)
// (c) 2018 Dragon Foundry LLC. All Rights Reserved. This code is not open source.
contract NovaGame is NovaGameAccess {

  struct GameData {
    string json;
    uint tradeLockSeconds;
    bytes32[] metadata;
  }

  event GameCreated(uint indexed game, address indexed owner, string json, bytes32[] metadata);

  event GameMetadataUpdated(
    uint indexed game, 
    string json,
    uint tradeLockSeconds, 
    bytes32[] metadata
  );

  mapping(uint => GameData) internal gameData;

  constructor(address _stakingContract) 
    public 
    NovaGameAccess(_stakingContract)
  {
    games.push(2**32);
  }

  // @dev Create a new game by setting its data. 
  //   Created games are initially owned and managed by the game&#39;s creator
  // @notice - there&#39;s a maximum of 2^32 games (4.29 billion games)
  // @param _json - a json encoded string containing the game&#39;s name, uri, logo, description, etc
  // @param _tradeLockSeconds - the number of seconds a card remains locked to a purchaser&#39;s account
  // @param _metadata - game-specific metadata, in bytes32 format. 
  function createGame(string _json, uint _tradeLockSeconds, bytes32[] _metadata) 
    external
  returns(uint _game) {
    // Create the game
    _game = games.length;
    require(_game < games[0], "too many games created");
    games.push(_game);

    // Log the game as created
    emit GameCreated(_game, msg.sender, _json, _metadata);

    // Add the creator as the first game admin
    _addAdminAccount(_game, msg.sender);

    // Store the game&#39;s metadata
    updateGameMetadata(_game, _json, _tradeLockSeconds, _metadata);
  }

  // @dev Gets the number of games in the system
  // @returns the number of games stored in the system
  function numberOfGames() 
    external
    view
  returns(uint) {
    return games.length;
  }

  // @dev Get all game data for one given game
  // @param _game - the # of the game
  // @returns game - the game ID of the requested game
  // @returns json - the json data of the game
  // @returns tradeLockSeconds - the number of card sets
  // @returns balance - the Nova Token balance 
  // @returns metadata - a bytes32 array of metadata used by the game
  function getGameData(uint _game)
    external
    view
  returns(uint game,
    string json,
    uint tradeLockSeconds,
    uint256 balance,
    bytes32[] metadata) 
  {
    GameData storage data = gameData[_game];
    game = _game;
    json = data.json;
    tradeLockSeconds = data.tradeLockSeconds;
    balance = stakingContract.balanceOf(address(_game));
    metadata = data.metadata;
  }

  // @dev Update the json, trade lock, and metadata for a single game
  // @param _game - the # of the game
  // @param _json - a json encoded string containing the game&#39;s name, uri, logo, description, etc
  // @param _tradeLockSeconds - the number of seconds a card remains locked to a purchaser&#39;s account
  // @param _metadata - game-specific metadata, in bytes32 format. 
  function updateGameMetadata(uint _game, string _json, uint _tradeLockSeconds, bytes32[] _metadata)
    public
    onlyGameAdmin(_game)
  {
    gameData[_game].tradeLockSeconds = _tradeLockSeconds;
    gameData[_game].json = _json;

    bytes32[] storage data = gameData[_game].metadata;
    if (_metadata.length > data.length) { data.length = _metadata.length; }
    for (uint k = 0; k < _metadata.length; k++) { data[k] = _metadata[k]; }
    for (k; k < data.length; k++) { delete data[k]; }
    if (_metadata.length < data.length) { data.length = _metadata.length; }

    emit GameMetadataUpdated(_game, _json, _tradeLockSeconds, _metadata);
  }
}