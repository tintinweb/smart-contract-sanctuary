/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.7.0;
// SPDX-License-Identifier: UNLICENSED












// @title iGAME_ERC721
// @dev The interface for the main Token Manager contract
//  Only methods required for calling by sibling contracts are required here
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.

abstract contract iGAME_ERC721 {

  function auctionTransfer(address from_, address to_, uint tokenId_) virtual external;

  function inGameOwnerOf(uint tokenId_) virtual external view returns (bytes32 owner_);

  function revokeToken(uint game_, uint tokenId_, bytes32 purchaseId_)
    virtual external returns (bool _isRevoked);

  function transferNewToken(bytes32 recipient_, uint tokenId_, uint tradeLockTime_)
    virtual external;

  function getCryptoAccount(uint game_, bytes32 inGameAccount_)
    virtual public view returns(address cryptoAccount);

  function getValidCryptoAccount(uint game_, bytes32 inGameAccount_)
    virtual public view returns(address cryptoAccount);

  function getInGameAccount(uint game_, address cryptoAccount_)
    virtual public view returns(bytes32 inGameAccount);

  function getValidInGameAccount(uint game_, address cryptoAccount_)
    virtual public view returns(bytes32 inGameAccount);

  function getOrCreateInGameAccount(uint game_, address cryptoAccount_)
    virtual external returns(bytes32 inGameAccount);

  function linkContracts(address gameContract_, address erc20Contract_) virtual external;

  function generateCollectible(uint tokenId_, uint xp_, uint xpPerHour_, uint creationTime_) virtual external;
}



// @title iGAME_ERC20
// @dev The interface for the Auction & ERC-20 contract
//  Only methods required for calling by sibling contracts are required here
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.

abstract contract iGAME_ERC20 {

  function cancelAuctionByManager(uint tokenId_) virtual external;

  function transferByContract(address from_, address to_, uint256 value_) virtual external;

  function linkContracts(address gameContract_, address erc721Contract_) virtual external;

  function getGameBalance(uint game_) virtual public view returns(uint balance);

  function getLoyaltyPointsGranted(uint game_, address account_) virtual public view returns(uint currentPoints);

  function getLoyaltyPointSpends(uint game_, address account_) virtual public view returns(uint currentPoints);

  function getLoyaltyPointsTotal(uint game_, address account_) virtual public view returns(uint currentPoints);

  function thirdPartySpendLoyaltyPoints(uint game_, address account_, uint pointsToSpend_) virtual external;
}



// @title iGAME_Master
// @dev The interface for the Master contract
//  Only methods required for calling by sibling contracts are required here
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.

abstract contract iGAME_Master {
  function isOwner(address owner_) virtual external view returns (bool);
  function isCFO(address cfo_) virtual external view returns (bool);
  function isCOO(address coo_) virtual external view returns (bool);
  function isWorker(address account_) virtual external view returns (bool);
  function isWorkerOrMinion(address account_) virtual external view returns (bool);
  function makeFundedCall(address account_) virtual external returns (bool);
  function updateCollectibleSaleStatus(uint game_, uint card_, bool isOnSale_) virtual external;

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

  function getCardPrice(uint game_, uint set_, uint card_) virtual external view returns(uint256);
  function getCardLoyaltyPrice(uint game_, uint set_, uint card_) virtual external view returns(uint256);
  function isGameAdmin(uint game_, address admin_) virtual external view returns(bool);
  function linkContracts(address erc721Contract_, address erc20Contract_) virtual external;
  function isOperatorOrMinion(uint game_, address sender_) virtual external returns(bool);
  function isValidCaller(address account_, bool isMinion_, uint game_) virtual external view returns(bool isValid);
  function burnToken(uint tokenId_) virtual external;
  function createTokenFromCard(uint game_, uint set_, uint card_) virtual external returns(uint tokenId, uint tradeLockTime, uint fixedXp);
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
  bytes32 internal workerDomainSeperator;

  constructor(
      string memory name,
      string memory version
  ) {
    domainSeperator = encodeDomainSeperator(name, version);
    workerDomainSeperator = encodeWorkerDomainSeperator(name, version);
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

  function getWorkerDomainSeperator() public view returns (bytes32) {
    return workerDomainSeperator;
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

  // This encodes the domain separator to the root chain, rather than the main chain.
  function encodeWorkerDomainSeperator(string memory name, string memory version) public view returns (bytes32) {
    uint chainId = getChainId();

    // 1 == truffle test; 1 == Ethereum
    // 137 == matic mainnet; 1 == Ethereum
    // 80001 == matic mumbai; 5 == Goerli
    chainId = chainId == 137 || chainId == 1 ? 1 : chainId == 80001 ? 5 : 0;
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

  function updateLocalContract(address contract_, bool isLocal_) virtual external;

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
    address userAddress_,
    bytes32 replayPrevention_,
    bytes memory functionSignature_,
    bytes32 sigR_,
    bytes32 sigS_,
    uint8 sigV_
  )
    public
    payable
  returns (bytes memory) {
    require(metaTxSenderIsWorkerOrMinion(), "Worker Meta-Transaction sent by account other than a worker/minion");
    WorkerMetaTransaction memory metaTx = WorkerMetaTransaction({
      replayPrevention: replayPrevention_,
      from: userAddress_,
      functionSignature: functionSignature_
    });

    require(
      workerVerify(userAddress_, metaTx, sigR_, sigS_, sigV_),
      "Signer and signature do not match"
    );

    require(playedTransactions[userAddress_][replayPrevention_] == false, "REPLAY of a previous transaction");
    playedTransactions[userAddress_][replayPrevention_] = true;

    emit MetaTransactionExecuted(
      userAddress_,
      msg.sender,
      functionSignature_
    );

    // Append userAddress and relayer address at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(
      abi.encodePacked(functionSignature_, userAddress_)
    );
    require(success, "Function call not successful");

    return returnData;
  }

  function hashWorkerMetaTransaction(WorkerMetaTransaction memory metaTx_)
    internal
    pure
  returns (bytes32) {
    return
      keccak256(
        abi.encode(
          WORKER_META_TRANSACTION_TYPEHASH,
          metaTx_.replayPrevention,
          metaTx_.from,
          keccak256(metaTx_.functionSignature)
        )
      );
  }

  function workerVerify(
    address signer_,
    WorkerMetaTransaction memory metaTx_,
    bytes32 sigR_,
    bytes32 sigS_,
    uint8 sigV_
  ) 
    internal
    view
  returns (bool) {
    return
      signer_ != address(0) && signer_ ==
      ecrecover(
        toWorkerTypedMessageHash(hashWorkerMetaTransaction(metaTx_)),
        sigV_,
        sigR_,
        sigS_
      );
  }

  /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
  function toWorkerTypedMessageHash(bytes32 messageHash_)
    internal
    view
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked("\x19\x01", getWorkerDomainSeperator(), messageHash_)
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
    require(localContracts[msg.sender], "local contract");
    _;
  }

  modifier onlyGameAdmin(uint game_) {
    require(gameAdmins[game_][_msgSender()], "game admin");
    _;
  }

  modifier operatorOrMinion(uint game_) {
    address sender = _msgSender();
    require(
      (!workersBannedByGame[game_] && masterContract.makeFundedCall(sender)) ||
      gameOperators[game_][sender] ||
      gameAdmins[game_][sender],
      "admin, operator, or worker");
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

  modifier adminOrMinion(uint game_) {
    address sender = _msgSender();
    require(
      gameAdmins[game_][sender] ||
      (!workersBannedByGame[game_] && masterContract.makeFundedCall(sender)),
      "admin or worker");
    _;
  }

  modifier workerOrMinion() {
    require(masterContract.makeFundedCall(_msgSender()), "worker or minion");
    _;
  }

  modifier onlyCOO() {
    require(masterContract.isCOO(_msgSender()), "cfo");
    _;
  }

  function isGameAdmin(uint game_, address admin_)
    external
    override
    view
  returns(bool) {
    return gameAdmins[game_][admin_];
  }

  function isOperatorOrMinion(uint game_, address sender_)
    external
    override
  returns(bool) {
    return (!workersBannedByGame[game_] && masterContract.makeFundedCall(sender_)) ||
      gameOperators[game_][sender_] ||
      gameAdmins[game_][sender_];
  }


  function linkContracts(address erc721Contract_, address erc20Contract_)
    external
    override
    onlyLocalContract
  {
    require(address(erc721Contract) == address(0), "token contract");
    require(address(erc20Contract) == address(0), "auction contract");
    erc721Contract = iGAME_ERC721(erc721Contract_);
    erc20Contract = iGAME_ERC20(erc20Contract_);
    localContracts[erc721Contract_] = true;
    localContracts[erc20Contract_] = true;
  }

  function updateLocalContract(address contract_, bool isLocal_)
    external
    override
    onlyLocalContract
  {
    require(contract_ != address(masterContract), "master");
    require(contract_ != address(erc721Contract), "erc721");
    require(contract_ != address(erc20Contract), "erc20");
    require(contract_ != address(0), "address(0)");
    localContracts[contract_] = isLocal_;
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

  constructor(address masterAddress_)
  {
    address sender = _msgSender();
    masterContract = iGAME_Master(masterAddress_);
    localContracts[masterAddress_] = true;
    gameAdmins[0][sender] = true;
    gameOperators[0][sender] = true;
  }

  function oracleUpdateAdminPrivileges(bytes32 txHash_, uint game_, address account_, bool isAdmin_)
    external
    workerOrMinion
  {
    if(adminOracleHashes[txHash_]) {
      return;
    }
    adminOracleHashes[txHash_] = true;
    emit OracleTransaction(txHash_);

    if(gameAdmins[game_][account_] != isAdmin_) {
      gameAdmins[game_][account_] = isAdmin_;
      emit AdminPrivilegesChanged(game_, account_, isAdmin_);
    }
  }

  function workerManageOperatorPrivilieges(uint game_, address account_, bool isOperator_)
    external
    adminOrMinion(game_)
  {
    if(gameOperators[game_][account_] != isOperator_) {
      gameOperators[game_][account_] = isOperator_;
      emit OperatorPrivilegesChanged(game_, account_, isOperator_);
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

  event CollectibleSaleDataUpdated(uint indexed set, uint indexed card, bool isForSale, uint fixedXp);

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

  mapping(uint => mapping (uint => uint)) collectibleFixedXp;

  // @dev Get all game data for one given game
  // @param game_ - the # of the game
  // @returns game - the game ID of the requested game
  // @returns cardSetCount - the number of card sets
  // @returns tradeLock - the number of seconds which granted cards will be locked to an account
  // @returns balance - the GAME Credits balance
  function getGameData(uint game_)
    external
    view
  returns(uint game,
    uint cardSetCount,
    uint tradeLock,
    uint256 balance,
    bool isWorkersBanned)
  {
    game = games[game_];
    cardSetCount = cardSetCounts[game_];
    tradeLock = tradeLockSeconds[game_];
    balance = erc20Contract.getGameBalance(game_);
    isWorkersBanned = workersBannedByGame[game_];
  }

  // @dev Returns the stored data of the requested set within a game
  // @param game_ - the # of the game that the token comes from
  // @param set_ - the # of the set within the game that the token comes from
  function getSetData(uint game_, uint set_)
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
    SetData storage data = setData[game_|(set_<<64)];
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
  // @param game_ - the # of the game that the token comes from
  // @param set_ - the # of the set within the game that the token comes from
  // @param card_ - the # of the card within the set that the token comes from
  function getCardMetadata(uint game_, uint set_, uint card_)
    external
    view
  returns(uint256 price, uint256 loyaltyPrice, bytes32[] memory metadata) {
    uint[] storage cardPrices = setData[game_|(set_<<64)].cardPrices;
    uint[] storage cardLoyaltyPrices = setData[game_|(set_<<64)].cardLoyaltyPrices;
    price = card_ < cardPrices.length ? cardPrices[card_] : 0;
    loyaltyPrice = card_ < cardLoyaltyPrices.length ? cardLoyaltyPrices[card_] : 0;
    metadata = cardData[game_|(set_<<64)|(card_<<128)];
  }

  // @dev Returns the metadata attached to a single card
  // @param game_ - the # of the game that the token comes from
  // @param set_ - the # of the set within the game that the token comes from
  // @param card_ - the # of the card within the set that the token comes from
  function getCardPrice(uint game_, uint set_, uint card_)
    external
    override
    view
  returns(uint256) {
    uint[] storage cardPrices = setData[game_|(set_<<64)].cardPrices;
    return card_ < cardPrices.length ? cardPrices[card_] : 0;
  }

  // @dev Returns the metadata attached to a single card
  // @param game_ - the # of the game that the token comes from
  // @param set_ - the # of the set within the game that the token comes from
  // @param card_ - the # of the card within the set that the token comes from
  function getCardLoyaltyPrice(uint game_, uint set_, uint card_)
    external
    override
    view
  returns(uint256) {
    uint[] storage cardLoyaltyPrices = setData[game_|(set_<<64)].cardLoyaltyPrices;
    return card_ < cardLoyaltyPrices.length ? cardLoyaltyPrices[card_] : 0;
  }

  // @dev Returns the metadata attached to a single card
  // @param game_ - the # of the game that the token comes from
  // @param set_ - the # of the set within the game that the token comes from
  // @param card_ - the # of the card within the set that the token comes from
  function getCardPrices(uint game_, uint set_)
    external
    view
  returns(uint256[] memory) {
    return setData[game_|(set_<<64)].cardPrices;
  }

  // @dev Returns the metadata attached to a single card
  // @param game_ - the # of the game that the token comes from
  // @param set_ - the # of the set within the game that the token comes from
  // @param card_ - the # of the card within the set that the token comes from
  function getCardLoyaltyPrices(uint game_, uint set_)
    external
    view
  returns(uint256[] memory) {
    return setData[game_|(set_<<64)].cardLoyaltyPrices;
  }

  function banWorkersFromMyGame(uint game_, bool stopUsingWorkers_)
    external
    onlyGameAdmin(game_)
  {
    workersBannedByGame[game_] = stopUsingWorkers_;
    emitGameMetadata(game_);
  }

  function addSetToGame(
    uint game_,
    uint set_,
    uint onSaleDate_,
    uint saleEndDate_,
    string memory json_,
    bytes32[] memory metadata_
  )
    external
    operatorOrMinion(game_)
  {
    _addSetToGame(game_, set_, onSaleDate_, saleEndDate_, json_, metadata_);
  }

  function _addSetToGame(
    uint game_,
    uint set_,
    uint onSaleDate_,
    uint saleEndDate_,
    string memory json_,
    bytes32[] memory metadata_
  )
    internal
  {
    require(set_ <= maxGameId, "setId < 2**32");
    require(!cardSetExists[game_][set_], "set must not exist");
    cardSetExists[game_][set_] = true;
    cardSetCounts[game_] = cardSetCounts[game_].add(1);

    SetData memory data = SetData ({
      onSaleDate: onSaleDate_,
      saleEndDate: saleEndDate_,
      json: json_,
      cardTokenCounts: new uint[](0),
      cardPrices: new uint[](0),
      cardLoyaltyPrices: new uint[](0),
      cardMaxSupply: new uint[](0),
      metadata: metadata_
      });
    setData[game_|(set_<<64)] = data;
    emitGameMetadata(game_);
    emit SetCreated(game_, set_);
    emit SetMetadataUpdated(game_, set_, onSaleDate_, saleEndDate_, json_, metadata_);
  }

  function emitGameMetadata(uint game_)
    internal
  {
    emit GameMetadataUpdated(
      game_,
      cardSetCounts[game_],
      tradeLockSeconds[game_],
      workersBannedByGame[game_]);
  }

  // @param fixedXp_ - a fixed amount of XP that the card will have. 0 means variable XP
  function addOrUpdateCollectible(
    uint game_,
    uint encodedCardData_,
    uint fixedXp_,
    bool isForSale_,
    bytes32[] memory cardMetadata_,
    string memory cardJson_
  )
    external
    operatorOrMinion(game_)
  {
    _addOrUpdateCard(0, game_, encodedCardData_, cardMetadata_, cardJson_);

    uint cardId = uint256(uint64(encodedCardData_));
    // put in core collectible data here
    masterContract.updateCollectibleSaleStatus(game_, cardId, isForSale_);
    collectibleFixedXp[game_][cardId] = fixedXp_;
    emit CollectibleSaleDataUpdated(game_, cardId, isForSale_, fixedXp_);
  }

  function addOrUpdateCard(
    uint game_,
    uint set_,
    uint encodedCardData_,
    bytes32[] memory cardMetadata_,
    string memory cardJson_
  )
    external
    operatorOrMinion(game_)
  {
    require(game_ > 0, "not for collectibles");
    _addOrUpdateCard(game_, set_, encodedCardData_, cardMetadata_, cardJson_);
  }

  function _addOrUpdateCard(
    uint game_,
    uint set_,
    uint encodedCardData_,
    bytes32[] memory cardMetadata_,
    string memory cardJson_
  )
    internal
  {
    require(cardSetExists[game_][set_], "set must exist");
    uint setId = game_|(set_<<64);
    uint[] storage cardTokenCounts = setData[setId].cardTokenCounts;
    // cards_ is encoded:
    // 64 bit cardId
    // 96 bit price
    // 32 bit loyalty price
    // 64 bit maxSupply
    uint cardId = uint256(uint64(encodedCardData_));
    require(cardId <= maxGameId, "cardId < 2**32");
    require(cardId <= cardTokenCounts.length, "sequential cards");
    if(cardId == cardTokenCounts.length) {
      cardTokenCounts.push(0);
    }
    _updateCardPrice(game_, set_, cardId, encodedCardData_, setId);
    if(cardMetadata_.length > 0) {
      _updateCardData(game_, set_, cardId, cardMetadata_);
    }
    if(bytes(cardJson_).length > 0) {
      emit CardJsonUpdated(game_, set_, cardId, cardJson_);
    }
  }

  function putCollectibleOnSale(uint game_, uint card_, bool isForSale_)
    external
    operatorOrMinion(game_)
  {
    masterContract.updateCollectibleSaleStatus(game_, card_, isForSale_);
    emit CollectibleSaleDataUpdated(game_, card_, isForSale_, collectibleFixedXp[game_][card_]);
  }

  function updateSetCards(uint game_, uint set_, uint[] memory encodedCardData_, bytes32[] memory cardMetadata_)
    external
    operatorOrMinion(game_)
  {
    require(game_ > 0, "not for collectibles");
    _updateSetCards(game_, set_, encodedCardData_, cardMetadata_);
  }

  function _updateSetCards(uint game_, uint set_, uint[] memory encodedCardData_, bytes32[] memory cardMetadata_)
    internal
  {
    require(cardSetExists[game_][set_], "set must exist");
    require(encodedCardData_.length > 0, "must add at least one card");
    uint metadataPerCard = cardMetadata_.length / encodedCardData_.length;
    require(
      cardMetadata_.length == 0 ||
      encodedCardData_.length.mul(metadataPerCard) == cardMetadata_.length, "card metadata must be valid");
    uint setId = game_|(set_<<64);
    uint[] storage cardTokenCounts = setData[setId].cardTokenCounts;
    bytes32[] memory perCardMetadata = new bytes32[](metadataPerCard);
    for(uint i = 0; i < encodedCardData_.length; i++) {
      // cards_ is encoded:
      // 64 bit cardId
      // 96 bit price
      // 32 bit loyalty price
      // 64 bit maxSupply
      uint cardId = uint256(uint64(encodedCardData_[i]));
      require(cardId <= maxGameId, "cardId < 2**32");
      require(cardId <= cardTokenCounts.length, "sequential cards");
      if(cardId == cardTokenCounts.length) {
        cardTokenCounts.push(0);
      }
      _updateCardPrice(game_, set_, cardId, encodedCardData_[i], setId);
      if(metadataPerCard > 0) {
        for (uint j = 0; j < metadataPerCard; j++) {
          perCardMetadata[j] = cardMetadata_[i.mul(metadataPerCard).add(j)];
        }
        _updateCardData(game_, set_, cardId, perCardMetadata);
      }
    }
  }

  function updateCardJson(uint game_, uint set_, uint card_, string calldata json_)
    external
    operatorOrMinion(game_)
  {
    // Don't save the json; it's unreadable on chain
    emit CardJsonUpdated(game_, set_, card_, json_);
  }

  function updateSetSaleDates(uint game_, uint set_, uint onSaleDate_, uint saleEndDate_)
    external
    operatorOrMinion(game_)
  {
    require(cardSetExists[game_][set_], "set must exist");
    uint setId = game_|(set_<<64);

    setData[setId].onSaleDate = onSaleDate_;
    setData[setId].saleEndDate = saleEndDate_;
    emit SetMetadataUpdated(
      game_, set_, onSaleDate_, saleEndDate_,
      setData[setId].json, setData[setId].metadata);
  }

  function updateSetMetadata(
    uint game_, uint set_,
    string calldata json_, bytes32[] calldata metadata_
  )
    external
    operatorOrMinion(game_)
  {
    require(cardSetExists[game_][set_], "set must exist");
    uint setId = game_|(set_<<64);

    setData[setId].json = json_;

    bytes32[] storage data = setData[setId].metadata;
    while (data.length < metadata_.length) {
      data.push();
    }
    while (data.length > metadata_.length) {
      data.pop();
    }
    for (uint k = 0; k < metadata_.length; k++) {
      data[k] = metadata_[k];
    }
    emit SetMetadataUpdated(game_, set_, setData[setId].onSaleDate, setData[setId].saleEndDate, json_, metadata_);
  }

  function createTokenFromCard(uint game_, uint set_, uint card_)
    external
    override
    onlyLocalContract
  returns(uint tokenId, uint tradeLockTime, uint fixedXp) {
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
      require(supply <= cardMaxSupply, "supply < max");
    }
    tokenId = cardId|(tokenId<<192);

    tradeLockTime = tradeLockSeconds[game_];
    fixedXp = game_ == 0 ? collectibleFixedXp[set_][card_] : 0;
  }
  
  function _updateCardPrice(
    uint game_,
    uint set_,
    uint card_,
    uint encodedCardData_,
    uint setId_
  )
    internal
  {
    uint price = uint256(uint96(encodedCardData_>>64));
    uint loyaltyPrice = uint256(uint32(encodedCardData_>>160));
    uint maxSupply = uint256(encodedCardData_>>192);
    if(loyaltyPrice == 0) {
      loyaltyPrice = price.div(10000000000000000);
    }
    uint[] storage cardPrices = setData[setId_].cardPrices;
    uint[] storage cardLoyaltyPrices = setData[setId_].cardLoyaltyPrices;
    uint[] storage cardMaxSupply = setData[setId_].cardMaxSupply;
    while(cardPrices.length <= card_) {
      cardPrices.push(0);
    }
    while(cardLoyaltyPrices.length <= card_) {
      cardLoyaltyPrices.push(0);
    }
    while(cardMaxSupply.length <= card_) {
      cardMaxSupply.push(0);
    }

    if (cardPrices[card_] != price ||
      cardMaxSupply[card_] != maxSupply ||
      cardLoyaltyPrices[card_] != loyaltyPrice) {
      cardPrices[card_] = price;
      cardLoyaltyPrices[card_] = loyaltyPrice;
      cardMaxSupply[card_] = maxSupply;
      emit CardPriceChanged(game_, set_, card_, price, loyaltyPrice, maxSupply);
    }
  }

  function _updateCardData(
    uint game_, uint set_, uint card_, bytes32[] memory cardData_)
    internal
  {
    bytes32[] storage data = cardData[game_|(set_<<64)|(card_<<128)];

    while (data.length < cardData_.length) {
      data.push();
    }
    while (data.length > cardData_.length) {
      data.pop();
    }
    for (uint k = 0; k < cardData_.length; k++) {
      data[k] = cardData_[k];
    }
    emit CardDataUpdated(game_, set_, card_, cardData_);
  }

  function burnToken(uint tokenId_)
    external
    override
    onlyLocalContract
  {
    // reduce the supply
    uint setId = uint(uint128(tokenId_));
    uint card = uint(uint64(tokenId_>>128));
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
  function oracleAddNewGame(uint game_, uint tradeLockSeconds_)
    external
    workerOrMinion
  {
    require(game_ <= maxGameId, "gameId < 2**32");
    require(game_ > 0, "gameId > 0");

    // If the game doesn't exist, create it.
    if(game_ != games[game_]) {
      games[game_] = game_;

      // Add a set 0, with one card (card 0). This ensures generic tokens can be created without messing with
      //  creating sets and cards (some games won't need sets or cards)
      _addSetToGame(game_, 0, 0, 2**127, "", new bytes32[](0));
      _updateSetCards(game_, 0, new uint[](1), new bytes32[](0));

      // set the initial trade lock
      tradeLockSeconds[game_] = tradeLockSeconds_;

      // Add the game as an collectible by adding it as a set.
      uint championId = game_;
      _addSetToGame(0, championId, 0, 2**127, "", new bytes32[](0));
      //_updateSetCards(0, championId, new uint[](1), new bytes32[](0));
    }
  }

  function workerUpdateTradeLock(uint game_, uint tradeLockSeconds_)
    external
    adminOrMinion(game_)
  {
    tradeLockSeconds[game_] = tradeLockSeconds_;
  }
}