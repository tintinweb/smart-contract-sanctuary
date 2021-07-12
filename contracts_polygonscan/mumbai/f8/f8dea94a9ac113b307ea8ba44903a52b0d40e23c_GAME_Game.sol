/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.7.0;
// SPDX-License-Identifier: UNLICENSED





/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {

  function _msgSender()
    internal
    virtual
    view
    returns (address payable sender)
  {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
            mload(add(array, index)),
            0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


abstract contract EIP712Base {
  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
  }

  bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(
    bytes(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    )
  );
  bytes32 internal domainSeperator;

  constructor(
      string memory name,
      string memory version
  ) {
    domainSeperator = encodeDomainSeperator(name, version);
  }

  function getChainId() public pure returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  function getDomainSeperator() public view returns (bytes32) {
    return domainSeperator;
  }

  function encodeDomainSeperator(string memory name, string memory version) public view returns (bytes32) {
    uint chainId = getChainId();
    require(chainId != 0, "chain ID must not be zero");
    return keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        chainId,
        address(this)
      )
    );
  }

  /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
  function toTypedMessageHash(bytes32 messageHash)
    internal
    view
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
      );
  }
}



// @title iGAME_ERC721
// @dev The interface for the main Token Manager contract
//  Only methods required for calling by sibling contracts are required here
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract iGAME_ERC721 {

  function auctionTransfer(address _from, address _to, uint _tokenId) virtual external;

  function inGameOwnerOf(uint _tokenId) virtual external view returns (bytes32 _owner);

  function revokeToken(uint _game, uint _tokenId, bytes32 _purchaseId)
    virtual external returns (bool _isRevoked);

  function transferNewToken(bytes32 _recipient, uint _tokenId, uint _tradeLockTime)
    virtual external;

  function getCryptoAccount(uint _game, bytes32 _inGameAccount)
    virtual public view returns(address cryptoAccount);

  function getValidCryptoAccount(uint _game, bytes32 _inGameAccount)
    virtual public view returns(address cryptoAccount);

  function getInGameAccount(uint _game, address _cryptoAccount)
    virtual public view returns(bytes32 inGameAccount);

  function getValidInGameAccount(uint _game, address _cryptoAccount)
    virtual public view returns(bytes32 inGameAccount);

  function getOrCreateInGameAccount(uint _game, address _cryptoAccount)
    virtual external returns(bytes32 inGameAccount);

  function linkContracts(address _gameContract, address _erc20Contract) virtual external;

  function generateCollectible(uint tokenId, uint xp, uint xpPerHour, uint creationTime) virtual external;
}



// @title iGAME_ERC20
// @dev The interface for the Auction & ERC-20 contract
//  Only methods required for calling by sibling contracts are required here
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract iGAME_ERC20 {

  function cancelAuctionByManager(uint _tokenId) virtual external;

  function transferByContract(address _from, address _to, uint256 _value) virtual external;

  function linkContracts(address _gameContract, address _erc721Contract) virtual external;

  function getGameBalance(uint _game) virtual public view returns(uint balance);

  function getLoyaltyPointsGranted(uint _game, address _account) virtual public view returns(uint currentPoints);

  function getLoyaltyPointSpends(uint _game, address _account) virtual public view returns(uint currentPoints);

  function getLoyaltyPointsTotal(uint _game, address _account) virtual public view returns(uint currentPoints);

  function thirdPartySpendLoyaltyPoints(uint _game, address _account, uint _pointsToSpend) virtual external;
}



// @title iGAME_Master
// @dev The interface for the Master contract
//  Only methods required for calling by sibling contracts are required here
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract iGAME_Master {
  function isOwner(address _owner) virtual external view returns (bool);
  function isCFO(address _cfo) virtual external view returns (bool);
  function isCOO(address _coo) virtual external view returns (bool);
  function isWorker(address _account) virtual external view returns (bool);
  function isWorkerOrMinion(address _account) virtual external view returns (bool);
  function makeFundedCall(address _account) virtual external returns (bool);

  function isMaster()
    external
    pure
  returns(bool) {
    return true;
  }
}



// @title iGAME_Game
// @dev The interface for the GAME Credits Game Data contract
//  Only methods required for calling by sibling contracts are required here
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract iGAME_Game {
  mapping(uint => mapping(address => bool)) public gameAdmins;
  mapping(uint => mapping(address => bool)) public gameOperators;

  function getCardPrice(uint _game, uint _set, uint _card) virtual external view returns(uint256);
  function getCardLoyaltyPrice(uint _game, uint _set, uint _card) virtual external view returns(uint256);
  function isGameAdmin(uint _game, address _admin) virtual external view returns(bool);
  function linkContracts(address _erc721Contract, address _erc20Contract) virtual external;
  function isOperatorOrMinion(uint _game, address _sender) virtual external returns(bool);
  function isValidCaller(address account_, bool isMinion_, uint game_) virtual external view returns(bool isValid);
  function burnToken(uint _tokenId) virtual external;
  function createTokenFromCard(uint game_, uint set_, uint card_) virtual external returns(uint tokenId, uint tradeLockTime);
}



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    *
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    *
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    *
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    *
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts with custom message when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}




abstract contract NetworkAgnostic is EIP712Base, Context {
  using SafeMath for uint256;
  bytes32 internal constant META_TRANSACTION_TYPEHASH = keccak256(
    bytes(
      "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
    )
  );
  event MetaTransactionExecuted(
    address userAddress,
    address payable relayerAddress,
    bytes functionSignature
  );
  mapping(address => uint256) nonces;

  /*
    * Meta transaction structure.
    * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
    * He should call the desired function directly in that case.
    */
  struct MetaTransaction {
    uint256 nonce;
    address from;
    bytes functionSignature;
  }

  constructor(
    string memory name,
    string memory version
  ) EIP712Base(name, version) {}

  function executeMetaTransaction(
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public payable returns (bytes memory) {
    MetaTransaction memory metaTx = MetaTransaction({
      nonce: nonces[userAddress],
      from: userAddress,
      functionSignature: functionSignature
    });

    require(
      verify(userAddress, metaTx, sigR, sigS, sigV),
      "Signer and signature do not match"
    );

    // increase nonce for user (to avoid re-use)
    nonces[userAddress] = nonces[userAddress].add(1);

    emit MetaTransactionExecuted(
      userAddress,
      msg.sender,
      functionSignature
    );

    // Append userAddress and relayer address at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(
      abi.encodePacked(functionSignature, userAddress)
    );
    require(success, "Function call not successful");

    return returnData;
  }

  function hashMetaTransaction(MetaTransaction memory metaTx)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          META_TRANSACTION_TYPEHASH,
          metaTx.nonce,
          metaTx.from,
          keccak256(metaTx.functionSignature)
        )
      );
  }

  function getNonce(address user) public view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  function verify(
    address signer,
    MetaTransaction memory metaTx,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) internal view returns (bool) {
    return
      signer != address(0) && signer ==
      ecrecover(
        toTypedMessageHash(hashMetaTransaction(metaTx)),
        sigV,
        sigR,
        sigS
      );
  }
}




// @title iLocalContract
// @dev The interface for the main Token Manager contract
//  Only methods required for calling by sibling contracts are required here
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract iLocalContract {

  function updateLocalContract(address _contract, bool _isLocal) virtual external;

  function metaTxSenderIsWorkerOrMinion() internal virtual returns (bool);

  function isLocalContract()
    external
    virtual
    pure
  returns(bool) {
    return true;
  }
}

abstract contract WorkerMetaTransactions is NetworkAgnostic, iLocalContract {
  using SafeMath for uint256;
  bytes32 private constant WORKER_META_TRANSACTION_TYPEHASH = keccak256(
    bytes(
      "WorkerMetaTransaction(bytes32 replayPrevention,address from,bytes functionSignature)"
    )
  );

  // This mapping records all meta-transactions that have been played.
  // It costs more than the nonce method, but this is permissioned, so it's more reliable.
  mapping(address => mapping(bytes32 => bool)) playedTransactions;

  /*
    * Meta transaction structure.
    * No point of including value field here as a user who is doing value transfer has the funds to pay for gas
    *   and should call the desired function directly in that case.
    */
  struct WorkerMetaTransaction {
    bytes32 replayPrevention;
    address from;
    bytes functionSignature;
  }

  function workerExecuteMetaTransaction(
    address userAddress,
    bytes32 replayPrevention,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  )
    public
    payable
  returns (bytes memory) {
    require(metaTxSenderIsWorkerOrMinion(), "Worker Meta-Transaction sent by account other than a worker/minion");
    WorkerMetaTransaction memory metaTx = WorkerMetaTransaction({
      replayPrevention: replayPrevention,
      from: userAddress,
      functionSignature: functionSignature
    });

    require(
      workerVerify(userAddress, metaTx, sigR, sigS, sigV),
      "Signer and signature do not match"
    );

    require(playedTransactions[userAddress][replayPrevention] == false, "REPLAY of a previous transaction");
    playedTransactions[userAddress][replayPrevention] = true;

    emit MetaTransactionExecuted(
      userAddress,
      msg.sender,
      functionSignature
    );

    // Append userAddress and relayer address at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(
      abi.encodePacked(functionSignature, userAddress)
    );
    require(success, "Function call not successful");

    return returnData;
  }

  function hashWorkerMetaTransaction(WorkerMetaTransaction memory metaTx)
    internal
    pure
  returns (bytes32) {
    return
      keccak256(
        abi.encode(
          WORKER_META_TRANSACTION_TYPEHASH,
          metaTx.replayPrevention,
          metaTx.from,
          keccak256(metaTx.functionSignature)
        )
      );
  }

  function workerVerify(
    address signer,
    WorkerMetaTransaction memory metaTx,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) 
    internal
    view
  returns (bool) {
    return
      signer != address(0) && signer ==
      ecrecover(
        toTypedMessageHash(hashWorkerMetaTransaction(metaTx)),
        sigV,
        sigR,
        sigS
      );
  }
}


// @dev allows managers to add new games to the service;
//   allows game managers to add and remove admin accounts
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract GAME_GameAccess is WorkerMetaTransactions, iGAME_Game {
  using SafeMath for uint256;

  event OperatorPrivilegesChanged(uint indexed game, address indexed account, bool isOperator);
  event AdminPrivilegesChanged(uint indexed game, address indexed account, bool isAdmin);

  // Admin control info
  // Two-level privilege system: An Admin level, who can manage accounts & finances,
  //   and an Operator level who can manage game functions
  // Admins have all Operator privileges too. We recomend not using admin
  //   accounts for operations, but admins can be smart contracts, and those
  //   could need both sets of privileges.
  mapping(uint => address[]) public operatorAddressesByGameId;
  mapping(address => uint[]) public gameIdsByOperatorAddress;
  mapping(uint => bool) public workersBannedByGame;

  iGAME_Master public masterContract;
  iGAME_ERC721 public erc721Contract;
  iGAME_ERC20 public erc20Contract;
  mapping(address => bool) public localContracts;


  modifier onlyLocalContract() {
    // Cannot be called using native meta-transactions
    require(localContracts[msg.sender], "sender must be a local contract");
    _;
  }

  modifier onlyGameAdmin(uint _game) {
    require(gameAdmins[_game][_msgSender()], "sender must be a game admin");
    _;
  }

  modifier operatorOrMinion(uint _game) {
    address sender = _msgSender();
    require(
      (!workersBannedByGame[_game] && masterContract.makeFundedCall(sender)) ||
      gameOperators[_game][sender] ||
      gameAdmins[_game][sender],
      "sender must be an admin, operator, or worker");
    _;
  }

  function isValidCaller(address account_, bool isMinion_, uint game_)
    external
    override
    view
  returns(bool isValid) {
    if(isMinion_) {
      isValid = isMinion_ && !workersBannedByGame[game_];
    } else {
      isValid = gameOperators[game_][account_] || gameAdmins[game_][account_];
    }
  }

  modifier adminOrMinion(uint _game) {
    address sender = _msgSender();
    require(
      gameAdmins[_game][sender] ||
      (!workersBannedByGame[_game] && masterContract.makeFundedCall(sender)),
      "sender must be an admin or worker");
    _;
  }

  modifier workerOrMinion() {
    require(masterContract.makeFundedCall(_msgSender()), "must be called by a worker or minion");
    _;
  }

  modifier onlyCOO() {
    require(masterContract.isCOO(_msgSender()), "sender must be the cfo");
    _;
  }

  function isGameAdmin(uint _game, address _admin)
    external
    override
    view
  returns(bool) {
    return gameAdmins[_game][_admin];
  }

  function isOperatorOrMinion(uint _game, address _sender)
    external
    override
  returns(bool) {
    return (!workersBannedByGame[_game] && masterContract.makeFundedCall(_sender)) ||
      gameOperators[_game][_sender] ||
      gameAdmins[_game][_sender];
  }


  function linkContracts(address _erc721Contract, address _erc20Contract)
    external
    override
    onlyLocalContract
  {
    require(address(erc721Contract) == address(0), "token contract must be blank");
    require(address(erc20Contract) == address(0), "auction contract must be blank");
    erc721Contract = iGAME_ERC721(_erc721Contract);
    erc20Contract = iGAME_ERC20(_erc20Contract);
    localContracts[_erc721Contract] = true;
    localContracts[_erc20Contract] = true;
  }

  function updateLocalContract(address _contract, bool _isLocal)
    external
    override
    onlyLocalContract
  {
    require(_contract != address(masterContract), "can't reset the master contract");
    require(_contract != address(erc721Contract), "can't reset the erc721 contract");
    require(_contract != address(erc20Contract), "can't reset the erc20 contract");
    require(_contract != address(0), "can't be the zero address");
    localContracts[_contract] = _isLocal;
  }

  function metaTxSenderIsWorkerOrMinion()
    internal
    override
  returns (bool) {
    return masterContract.makeFundedCall(msg.sender);
  }
}


// @dev allows managers to add new games to the service;
//   allows game managers to add and remove admin accounts
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract GAME_GameAdmin is GAME_GameAccess {

  event OracleTransaction(bytes32 indexed txHash);

  // A mapping of game #s that are available on the service.
  mapping(uint => uint) public games;
  // Max 2^32 games (4.29 billion)
  uint public constant maxGameId = 2**32;

  mapping(bytes32 => bool) public adminOracleHashes;

  constructor(address _masterAddress)
  {
    address sender = _msgSender();
    masterContract = iGAME_Master(_masterAddress);
    localContracts[_masterAddress] = true;
    gameAdmins[0][sender] = true;
    gameOperators[0][sender] = true;
  }

  function oracleUpdateAdminPrivileges(bytes32 txHash, uint _game, address _account, bool _isAdmin)
    external
    workerOrMinion
  {
    if(adminOracleHashes[txHash]) {
      return;
    }
    adminOracleHashes[txHash] = true;
    emit OracleTransaction(txHash);

    if(gameAdmins[_game][_account] != _isAdmin) {
      gameAdmins[_game][_account] = _isAdmin;
      emit AdminPrivilegesChanged(_game, _account, _isAdmin);
    }
  }

  function workerManageOperatorPrivilieges(uint _game, address _account, bool _isOperator)
    external
    adminOrMinion(_game)
  {
    if(gameOperators[_game][_account] != _isOperator) {
      gameOperators[_game][_account] = _isOperator;
      emit OperatorPrivilegesChanged(_game, _account, _isOperator);
    }
  }

}


// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract GAME_GameData is GAME_GameAdmin {
  using SafeMath for uint256;

  struct SetData {
    uint onSaleDate;
    uint saleEndDate;
    string json;
    uint[] cardTokenCounts;
    uint[] cardPrices;
    uint[] cardLoyaltyPrices;
    uint[] cardMaxSupply;
    bytes32[] metadata;
  }

  // @dev Fired whenever an Operator changes an individual card price
  event CardPriceChanged(uint indexed game, uint indexed set, uint indexed card, uint price, uint loyaltyPrice, uint maxForSale);

  event CardDataUpdated(uint indexed game, uint indexed set, uint indexed card, bytes32[] data);
  event CardJsonUpdated(uint indexed game, uint indexed set, uint indexed card, string json);
  event CardUriUpdated(uint indexed game, uint indexed set, uint indexed card, string uri);

  event GameMetadataUpdated(
    uint indexed game,
    uint cardSetCount,
    uint tradeLockSeconds,
    bool workersBanned
  );
  event SetCreated(uint indexed game, uint set);
  event SetMetadataUpdated(
    uint indexed game,
    uint indexed set,
    uint onSaleDate,
    uint saleEndDate,
    string json,
    bytes32[] metadata
  );

  // Some games don't have the concept of "sets" - using "sets" is optional
  // Some games don't have the concept of "cards" - using "cards" is optional
  // Set0 is created on game creation, with one card. This enables pure-token games to not care about sets or cards
  mapping(uint => SetData) internal setData;
  mapping(uint => bytes32[]) public cardData;

  mapping(uint => uint) public latestTokenIds;
  mapping(uint => uint) public cardSetCounts;
  mapping(uint => uint) public tradeLockSeconds;

  mapping(uint => mapping (uint => bool)) cardSetExists;

  // @dev Get all game data for one given game
  // @param _game - the # of the game
  // @returns game - the game ID of the requested game
  // @returns cardSetCount - the number of card sets
  // @returns tradeLock - the number of seconds which granted cards will be locked to an account
  // @returns balance - the GAME Credits balance
  function getGameData(uint _game)
    external
    view
  returns(uint game,
    uint cardSetCount,
    uint tradeLock,
    uint256 balance,
    bool isWorkersBanned)
  {
    game = games[_game];
    cardSetCount = cardSetCounts[_game];
    tradeLock = tradeLockSeconds[_game];
    balance = erc20Contract.getGameBalance(_game);
    isWorkersBanned = workersBannedByGame[_game];
  }

  // @dev Returns the stored data of the requested set within a game
  // @param _game - the # of the game that the token comes from
  // @param _set - the # of the set within the game that the token comes from
  function getSetData(uint _game, uint _set)
    external
    view
  returns(uint onSaleDate,
    uint saleEndDate,
    string memory json,
    uint cardCount,
    uint[] memory cardTokenCounts,
    uint[] memory cardPrices,
    uint[] memory cardLoyaltyPrices,
    uint[] memory cardMaxSupply,
    bytes32[] memory metadata)
  {
    SetData storage data = setData[_game|(_set<<64)];
    onSaleDate = data.onSaleDate;
    saleEndDate = data.saleEndDate;
    json = data.json;
    cardCount = data.cardTokenCounts.length;
    cardTokenCounts = data.cardTokenCounts;
    cardMaxSupply = data.cardMaxSupply;
    cardPrices = data.cardPrices;
    cardLoyaltyPrices = data.cardLoyaltyPrices;
    metadata = data.metadata;
  }

  // @dev Returns the metadata attached to a single card
  // @param _game - the # of the game that the token comes from
  // @param _set - the # of the set within the game that the token comes from
  // @param _card - the # of the card within the set that the token comes from
  function getCardMetadata(uint _game, uint _set, uint _card)
    external
    view
  returns(uint256 price, uint256 loyaltyPrice, bytes32[] memory metadata) {
    uint[] storage cardPrices = setData[_game|(_set<<64)].cardPrices;
    uint[] storage cardLoyaltyPrices = setData[_game|(_set<<64)].cardLoyaltyPrices;
    price = _card < cardPrices.length ? cardPrices[_card] : 0;
    loyaltyPrice = _card < cardLoyaltyPrices.length ? cardLoyaltyPrices[_card] : 0;
    metadata = cardData[_game|(_set<<64)|(_card<<128)];
  }

  // @dev Returns the metadata attached to a single card
  // @param _game - the # of the game that the token comes from
  // @param _set - the # of the set within the game that the token comes from
  // @param _card - the # of the card within the set that the token comes from
  function getCardPrice(uint _game, uint _set, uint _card)
    external
    override
    view
  returns(uint256) {
    uint[] storage cardPrices = setData[_game|(_set<<64)].cardPrices;
    return _card < cardPrices.length ? cardPrices[_card] : 0;
  }

  // @dev Returns the metadata attached to a single card
  // @param _game - the # of the game that the token comes from
  // @param _set - the # of the set within the game that the token comes from
  // @param _card - the # of the card within the set that the token comes from
  function getCardLoyaltyPrice(uint _game, uint _set, uint _card)
    external
    override
    view
  returns(uint256) {
    uint[] storage cardLoyaltyPrices = setData[_game|(_set<<64)].cardLoyaltyPrices;
    return _card < cardLoyaltyPrices.length ? cardLoyaltyPrices[_card] : 0;
  }

  // @dev Returns the metadata attached to a single card
  // @param _game - the # of the game that the token comes from
  // @param _set - the # of the set within the game that the token comes from
  // @param _card - the # of the card within the set that the token comes from
  function getCardPrices(uint _game, uint _set)
    external
    view
  returns(uint256[] memory) {
    return setData[_game|(_set<<64)].cardPrices;
  }

  // @dev Returns the metadata attached to a single card
  // @param _game - the # of the game that the token comes from
  // @param _set - the # of the set within the game that the token comes from
  // @param _card - the # of the card within the set that the token comes from
  function getCardLoyaltyPrices(uint _game, uint _set)
    external
    view
  returns(uint256[] memory) {
    return setData[_game|(_set<<64)].cardLoyaltyPrices;
  }

  function banWorkersFromMyGame(uint _game, bool _stopUsingWorkers)
    external
    onlyGameAdmin(_game)
  {
    workersBannedByGame[_game] = _stopUsingWorkers;
    emitGameMetadata(_game);
  }

  function addSetToGame(
    uint _game,
    uint _set,
    uint _onSaleDate,
    uint _saleEndDate,
    string memory _json,
    bytes32[] memory _metadata
  )
    external
    operatorOrMinion(_game)
  {
    _addSetToGame(_game, _set, _onSaleDate, _saleEndDate, _json, _metadata);
  }

  function _addSetToGame(
    uint _game,
    uint _set,
    uint _onSaleDate,
    uint _saleEndDate,
    string memory _json,
    bytes32[] memory _metadata
  )
    internal
  {
    require(_set <= maxGameId, "set Id must be below 2**32");
    require(!cardSetExists[_game][_set], "can only add sets that don't exist");
    cardSetExists[_game][_set] = true;
    cardSetCounts[_game] = cardSetCounts[_game].add(1);

    SetData memory data = SetData ({
      onSaleDate: _onSaleDate,
      saleEndDate: _saleEndDate,
      json: _json,
      cardTokenCounts: new uint[](0),
      cardPrices: new uint[](0),
      cardLoyaltyPrices: new uint[](0),
      cardMaxSupply: new uint[](0),
      metadata: _metadata
      });
    setData[_game|(_set<<64)] = data;
    emitGameMetadata(_game);
    emit SetCreated(_game, _set);
    emit SetMetadataUpdated(_game, _set, _onSaleDate, _saleEndDate, _json, _metadata);
  }

  function emitGameMetadata(uint _game)
    internal
  {
    emit GameMetadataUpdated(
      _game,
      cardSetCounts[_game],
      tradeLockSeconds[_game],
      workersBannedByGame[_game]);
  }

  function addOrUpdateCard(
    uint _game,
    uint _set,
    uint _encodedCardData,
    bytes32[] memory _cardMetadata,
    string memory _cardJson
  )
    external
    operatorOrMinion(_game)
  {
    require(cardSetExists[_game][_set], "set must exist");
    uint setId = _game|(_set<<64);
    uint[] storage cardTokenCounts = setData[setId].cardTokenCounts;
    // _cards is encoded:
    // 64 bit cardId
    // 96 bit price
    // 32 bit loyalty price
    // 64 bit maxSupply
    uint cardId = uint256(uint64(_encodedCardData));
    require(cardId <= maxGameId, "card Id must be below 2**32");
    require(cardId <= cardTokenCounts.length, "cards must be added sequentially");
    if(cardId == cardTokenCounts.length) {
      cardTokenCounts.push(0);
    }
    _updateCardPrice(_game, _set, cardId, _encodedCardData, setId);
    if(_cardMetadata.length > 0) {
      _updateCardData(_game, _set, cardId, _cardMetadata);
    }
    if(bytes(_cardJson).length > 0) {
      emit CardJsonUpdated(_game, _set, cardId, _cardJson);
    }
  }

  function updateSetCards(uint _game, uint _set, uint[] memory _encodedCardData, bytes32[] memory _cardMetadata)
    external
    operatorOrMinion(_game)
  {
    _updateSetCards(_game, _set, _encodedCardData, _cardMetadata);
  }

  function _updateSetCards(uint _game, uint _set, uint[] memory _encodedCardData, bytes32[] memory _cardMetadata)
    internal
  {
    require(cardSetExists[_game][_set], "set must exist");
    require(_encodedCardData.length > 0, "must add at least one card");
    uint metadataPerCard = _cardMetadata.length / _encodedCardData.length;
    require(
      _cardMetadata.length == 0 ||
      _encodedCardData.length.mul(metadataPerCard) == _cardMetadata.length, "card metadata must be valid");
    uint setId = _game|(_set<<64);
    uint[] storage cardTokenCounts = setData[setId].cardTokenCounts;
    bytes32[] memory perCardMetadata = new bytes32[](metadataPerCard);
    for(uint i = 0; i < _encodedCardData.length; i++) {
      // _cards is encoded:
      // 64 bit cardId
      // 96 bit price
      // 32 bit loyalty price
      // 64 bit maxSupply
      uint cardId = uint256(uint64(_encodedCardData[i]));
      require(cardId <= maxGameId, "card Id must be below 2**32");
      require(cardId <= cardTokenCounts.length, "cards must be added sequentially");
      if(cardId == cardTokenCounts.length) {
        cardTokenCounts.push(0);
      }
      _updateCardPrice(_game, _set, cardId, _encodedCardData[i], setId);
      if(metadataPerCard > 0) {
        for (uint j = 0; j < metadataPerCard; j++) {
          perCardMetadata[j] = _cardMetadata[i.mul(metadataPerCard).add(j)];
        }
        _updateCardData(_game, _set, cardId, perCardMetadata);
      }
    }
  }

  function updateCardUri(uint _game, uint _set, uint _card, string calldata _uri)
    external
    operatorOrMinion(_game)
  {
    // Don't save the uri; it's unreadable on chain
    emit CardUriUpdated(_game, _set, _card, _uri);
  }

  function updateCardJson(uint _game, uint _set, uint _card, string calldata _json)
    external
    operatorOrMinion(_game)
  {
    // Don't save the json; it's unreadable on chain
    emit CardJsonUpdated(_game, _set, _card, _json);
  }

  function updateSetSaleDates(uint _game, uint _set, uint _onSaleDate, uint _saleEndDate)
    external
    operatorOrMinion(_game)
  {
    require(cardSetExists[_game][_set], "set must exist");
    uint setId = _game|(_set<<64);

    setData[setId].onSaleDate = _onSaleDate;
    setData[setId].saleEndDate = _saleEndDate;
    emit SetMetadataUpdated(
      _game, _set, _onSaleDate, _saleEndDate,
      setData[setId].json, setData[setId].metadata);
  }

  function updateSetMetadata(
    uint _game, uint _set,
    string calldata _json, bytes32[] calldata _metadata
  )
    external
    operatorOrMinion(_game)
  {
    require(cardSetExists[_game][_set], "set must exist");
    uint setId = _game|(_set<<64);

    setData[setId].json = _json;

    bytes32[] storage data = setData[setId].metadata;
    while (data.length < _metadata.length) {
      data.push();
    }
    while (data.length > _metadata.length) {
      data.pop();
    }
    for (uint k = 0; k < _metadata.length; k++) {
      data[k] = _metadata[k];
    }
    emit SetMetadataUpdated(_game, _set, setData[setId].onSaleDate, setData[setId].saleEndDate, _json, _metadata);
  }

  function createTokenFromCard(uint game_, uint set_, uint card_)
    external
    override
    onlyLocalContract
  returns(uint tokenId, uint tradeLockTime) {
    require(cardSetExists[game_][set_], "set must exist");
    uint setId = game_|(set_<<64);
    require(card_ < setData[setId].cardTokenCounts.length, "card must be existing card");
    require(setData[setId].saleEndDate > block.timestamp && setData[setId].onSaleDate < block.timestamp, "card must be on sale");

    uint cardId = setId|(card_<<128);

    // generate the tokenId
    tokenId = ++latestTokenIds[cardId];
    require(tokenId < 2**64, "token ID must be in range");

    // update the supply
    uint supply = ++setData[setId].cardTokenCounts[card_];

    uint cardMaxSupply = setData[setId].cardMaxSupply[card_];
    if(cardMaxSupply > 0) {
      require(supply <= cardMaxSupply, "supply must be below max for card");
    }
    tokenId = cardId|(tokenId<<192);

    tradeLockTime = tradeLockSeconds[game_];
  }
  
  function _updateCardPrice(
    uint game,
    uint set,
    uint card,
    uint encodedCardData,
    uint setId
  )
    internal
  {
    uint price = uint256(uint96(encodedCardData>>64));
    uint loyaltyPrice = uint256(uint32(encodedCardData>>160));
    uint maxSupply = uint256(encodedCardData>>192);
    if(loyaltyPrice == 0) {
      loyaltyPrice = price.div(10000000000000000);
    }
    uint[] storage cardPrices = setData[setId].cardPrices;
    uint[] storage cardLoyaltyPrices = setData[setId].cardLoyaltyPrices;
    uint[] storage cardMaxSupply = setData[setId].cardMaxSupply;
    while(cardPrices.length <= card) {
      cardPrices.push(0);
    }
    while(cardLoyaltyPrices.length <= card) {
      cardLoyaltyPrices.push(0);
    }
    while(cardMaxSupply.length <= card) {
      cardMaxSupply.push(0);
    }

    if (cardPrices[card] != price ||
      cardMaxSupply[card] != maxSupply ||
      cardLoyaltyPrices[card] != loyaltyPrice) {
      cardPrices[card] = price;
      cardLoyaltyPrices[card] = loyaltyPrice;
      cardMaxSupply[card] = maxSupply;
      emit CardPriceChanged(game, set, card, price, loyaltyPrice, maxSupply);
    }
  }

  function _updateCardData(
    uint _game, uint _set, uint _card, bytes32[] memory _cardData)
    internal
  {
    bytes32[] storage data = cardData[_game|(_set<<64)|(_card<<128)];

    while (data.length < _cardData.length) {
      data.push();
    }
    while (data.length > _cardData.length) {
      data.pop();
    }
    for (uint k = 0; k < _cardData.length; k++) {
      data[k] = _cardData[k];
    }
    emit CardDataUpdated(_game, _set, _card, _cardData);
  }

  function burnToken(uint _tokenId)
    external
    override
    onlyLocalContract
  {
    // reduce the supply
    uint setId = uint(uint128(_tokenId));
    uint card = uint(uint64(_tokenId>>128));
    uint supply = setData[setId].cardTokenCounts[card];
    require(supply > 0, "must have supply");
    setData[setId].cardTokenCounts[card] = supply.sub(1);
  }
}


// @title GAME Credits Data
// @dev GAME_Game contract for managing all game, set, and token data
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
contract GAME_Game is GAME_GameData {

  string constant public CONTRACT_ERC712_VERSION = "1";
  string constant public CONTRACT_ERC712_NAME = "GAME Credits Sidechain GameData Contract";

  // @dev Constructor creates a reference to the master contract
  // @param masterContract_ - address of the master contract
  constructor(address masterContract_)
    GAME_GameAdmin(masterContract_)
    NetworkAgnostic(CONTRACT_ERC712_NAME, CONTRACT_ERC712_VERSION)
  {
    tradeLockSeconds[0] = 604800; // 7 days

    _addSetToGame(0, 0, 0, 2**127, "", new bytes32[](0));
  }
    // the creator of the contract initially owns the Owner and COO addresses (not the CFO)

  // @dev When a user creates a game on mainnet, it's reflected here.
  // @note Other details, such as admin status, are reflected separately
  function oracleAddNewGame(uint _game, uint _tradeLockSeconds)
    external
    workerOrMinion
  {
    require(_game <= maxGameId, "game Id must be below 2**32");
    require(_game > 0, "game Id must be non-zero");

    // If the game doesn't exist, create it.
    if(_game != games[_game]) {
      games[_game] = _game;

      // Add a set 0, with one card (card 0). This ensures generic tokens can be created without messing with
      //  creating sets and cards (some games won't need sets or cards)
      _addSetToGame(_game, 0, 0, 2**127, "", new bytes32[](0));
      _updateSetCards(_game, 0, new uint[](1), new bytes32[](0));

      // set the initial trade lock
      tradeLockSeconds[_game] = _tradeLockSeconds;

      // Add the game as an collectible by adding it as a set and adding the first card in that set.
      uint championId = _game;
      _addSetToGame(0, championId, 0, 2**127, "", new bytes32[](0));
      _updateSetCards(0, championId, new uint[](1), new bytes32[](0));
    }
  }

  function workerUpdateTradeLock(uint _game, uint _tradeLockSeconds)
    external
    adminOrMinion(_game)
  {
    tradeLockSeconds[_game] = _tradeLockSeconds;
  }
}