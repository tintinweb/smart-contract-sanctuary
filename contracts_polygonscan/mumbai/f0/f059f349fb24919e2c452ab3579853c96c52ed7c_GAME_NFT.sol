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







// @title ERC-721 Non-Fungible Token Standard
// @dev Interface for contracts conforming to ERC-721: Non-Fungible Tokens
// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
//  Note: the ERC-165 identifier for this interface is 0x80ac58cd

interface iERC721 {

  // @notice Count all NFTs assigned to an owner
  // @dev NFTs assigned to the zero address are considered invalid, and this
  //  function throws for queries about the zero address.
  // @param owner_ An address for whom to query the balance
  // @return The number of NFTs owned by `owner_`, possibly zero
  function balanceOf(address owner_) external view returns (uint);

  // @notice Find the owner of an NFT
  // @param tokenId_ The identifier for an NFT
  // @dev NFTs assigned to zero address are considered invalid, and queries
  //  about them do throw.
  // @return The address of the owner of the NFT
  function ownerOf(uint tokenId_) external view returns (address);

  // @notice Transfers the ownership of an NFT from one address to another address
  // @dev Throws unless `msg.sender` is the current owner, an authorized
  //  operator, or the approved address for this NFT. Throws if `from_` is
  //  not the current owner. Throws if `to_` is the zero address. Throws if
  //  `tokenId_` is not a valid NFT. When transfer is complete, this function
  //  checks if `to_` is a smart contract (code size > 0). If so, it calls
  //  `onERC721Received` on `to_` and throws if the return value is not
  //  `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
  // @param from_ The current owner of the NFT
  // @param to_ The new owner
  // @param tokenId_ The NFT to transfer
  // @param data Additional data with no specified format, sent in call to `to_`
  function safeTransferFrom(address from_, address to_, uint tokenId_, bytes calldata data_) external;

  // @notice Transfers the ownership of an NFT from one address to another address
  // @dev This works identically to the other function with an extra data parameter,
  //  except this function just sets data to ""
  // @param from_ The current owner of the NFT
  // @param to_ The new owner
  // @param tokenId_ The NFT to transfer
  function safeTransferFrom(address from_, address to_, uint tokenId_) external;

  // @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  //  TO CONFIRM THAT `to_` IS CAPABLE OF RECEIVING NFTS OR ELSE
  //  THEY MAY BE PERMANENTLY LOST
  // @dev Throws unless `msg.sender` is the current owner, an authorized
  //  operator, or the approved address for this NFT. Throws if `from_` is
  //  not the current owner. Throws if `to_` is the zero address. Throws if
  //  `tokenId_` is not a valid NFT.
  // @param from_ The current owner of the NFT
  // @param to_ The new owner
  // @param tokenId_ The NFT to transfer
  function transferFrom(address from_, address to_, uint tokenId_) external;

  // @notice Set or reaffirm the approved address for an NFT
  // @dev The zero address indicates there is no approved address.
  // @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
  //  operator of the current owner.
  // @param approved_ The new approved NFT controller
  // @param tokenId_ The NFT to approve
  function approve(address approved_, uint tokenId_) external;

  // @notice Enable or disable approval for a third party ("operator") to manage
  //  all your assets.
  // @dev Throws unless `msg.sender` is the current NFT owner.
  // @dev Emits the ApprovalForAll event
  // @param operator_ Address to add to the set of authorized operators.
  // @param approved_ True if the operators is approved, false to revoke approval
  function setApprovalForAll(address operator_, bool approved_) external;

  // @notice Get the approved address for a single NFT
  // @dev Throws if `tokenId_` is not a valid NFT
  // @param tokenId_ The NFT to find the approved address for
  // @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint tokenId_) external view returns (address);

  // @notice Query if an address is an authorized operator for another address
  // @param owner_ The address that owns the NFTs
  // @param operator_ The address that acts on behalf of the owner
  // @return True if `operator_` is an approved operator for `owner_`, false otherwise
  function isApprovedForAll(address owner_, address operator_) external view returns (bool);
}



// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.

interface iERC721Receiver {
  // @notice Handle the receipt of an NFT
  // @dev The ERC721 smart contract calls this function on the recipient
  //  after a `transfer`. This function MAY throw to revert and reject the
  //  transfer. This function MUST use 50,000 gas or less. Return of other
  //  than the magic value MUST result in the transaction being reverted.
  //  Note: the contract address is always the message sender.
  // @param operator_ The address which called `safeTransferFrom` function
  // @param from_ The address which previously owned the token
  // @param tokenId_ The NFT identifier which is being transferred
  // @param data_ Additional data with no specified format
  // @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  //    unless throwing
  function onERC721Received(address operator_, address from_, uint256 tokenId_, bytes calldata data_) external returns(bytes4);
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

abstract contract GAME_NFT_PlayerAccounts is iGAME_ERC721, WorkerMetaTransactions {
  using SafeMath for uint256;

  event AccountLinked(uint indexed game, bytes32 indexed inGameAccount, address indexed cryptoAccount);

  // Link crypto to player acct
  // Each link is PER GAME.
  // These are private because getters and setters must be used.
  mapping (uint => mapping(bytes32 => address)) public gameToCrypto;
  mapping (uint => mapping(address => bytes32)) public cryptoToGame;
  mapping (uint => mapping(bytes32 => address)) public approvedCryptoAccounts;

  mapping (address => uint[]) public gamesLinkedToCrypto;
  mapping (uint => mapping(address => uint)) public gamesLinkedToCryptoPointers;

  modifier isOwnerOf(uint game_, bytes32 inGameAccount_)
  {
    address sender = _msgSender();
    require(
      bytes32(uint(sender)) == inGameAccount_ ||
      cryptoToGame[game_][sender] == inGameAccount_,
      "sender owns this account");
    _;
  }

  function getLinkedGames(address cryptoAccount_)
    external
    view
  returns (uint[] memory) {
    return gamesLinkedToCrypto[cryptoAccount_];
  }

  function getCryptoAccount(uint game_, bytes32 inGameAccount_)
    public
    override
    view
  returns(address cryptoAccount) {
    cryptoAccount = gameToCrypto[game_][inGameAccount_];
  }

  function getValidCryptoAccount(uint game_, bytes32 inGameAccount_)
    public
    override
    view
  returns(address cryptoAccount) {
    cryptoAccount = gameToCrypto[game_][inGameAccount_];
    require(cryptoAccount != address(0), "crypto account must be linked (non-zero)");
  }

  function getInGameAccount(uint game_, address cryptoAccount_)
    public
    override
    view
  returns(bytes32 inGameAccount) {
    inGameAccount = cryptoToGame[game_][cryptoAccount_];
  }

  function getValidInGameAccount(uint game_, address cryptoAccount_)
    public
    override
    view
  returns(bytes32 inGameAccount) {
    inGameAccount = cryptoToGame[game_][cryptoAccount_];
    require(inGameAccount != bytes32(0), "in game account must be linked (set to non-zero)");
  }

  function _getOrCreateInGameAccount(uint game_, address cryptoAccount_)
    internal
  returns(bytes32 inGameAccount) {
    require(cryptoAccount_ != address(0), "account must be valid");
    inGameAccount = cryptoToGame[game_][cryptoAccount_];
    if(inGameAccount == bytes32(0)) {
      inGameAccount = bytes32(uint(cryptoAccount_))<<96;
      _linkCryptoAccount(game_, cryptoAccount_, inGameAccount);
    }
  }

  function _linkCryptoAccount(uint game_, address cryptoAccount_, bytes32 inGameAccount_)
    internal
  {
    delete approvedCryptoAccounts[game_][inGameAccount_];
    cryptoToGame[game_][cryptoAccount_] = inGameAccount_;
    gameToCrypto[game_][inGameAccount_] = cryptoAccount_;
    uint pointer = gamesLinkedToCrypto[cryptoAccount_].length;
    gamesLinkedToCrypto[cryptoAccount_].push(game_);
    gamesLinkedToCryptoPointers[game_][cryptoAccount_] = pointer;
    emit AccountLinked(game_, inGameAccount_, cryptoAccount_);
  }

}


// @title ERC721 Imlpementation
// @dev Utility contract that manages ownership, ERC-721 (draft) compliant.
// @dev Ref: https://github.com/ethereum/EIPs/issues/721
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.

abstract contract GAME_NFT_ERC721 is iERC721, GAME_NFT_PlayerAccounts {
  using SafeMath for uint256;

  // @dev This emits when ownership of any NFT changes by any mechanism.
  //  This event emits when NFTs are created (`from` == 0) and destroyed
  //  (`to` == 0). The approved address for that NFT (if any) is reset to none.
  event InGameTransfer(uint indexed game, bytes32 indexed from, bytes32 indexed to, uint tokenId);

  // @dev This emits when ownership of any NFT changes by any mechanism.
  //  This event emits when NFTs are created (`from` == 0) and destroyed
  //  (`to` == 0). The approved address for that NFT (if any) is reset to none.
  event Transfer(address indexed from_, address indexed to_, uint indexed tokenId_);

  // @dev This emits when the approved address for an NFT is changed or
  //  reaffirmed. The zero address indicates there is no approved address.
  //  When a Transfer event emits, this also indicates that the approved
  //  address for that NFT (if any) is reset to none.
  event Approval(address indexed owner_, address indexed approved_, uint tokenId_);

  // @dev This emits when an operator is enabled or disabled for an owner.
  //  The operator can manage all NFTs of the owner.
  event ApprovalForAll(address indexed owner_, address indexed operator_, bool approved_);

  // @dev A mapping from token Ids to the address that owns them.
  //  All non-retired tokens have some valid owner address.
  mapping (uint => bytes32) public indexToOwner;

  // @dev A mapping from TokenIds to an address that has been approved to call
  //  transferFrom(). Each token can only have one approved address for transfer
  //  at any time. A zero value means no approval is outstanding.
  mapping (uint => address) public indexToApproved;

  // @dev The authorized operators for each address. Operators can approve or transfer
  //  ANY token owned by the address
  mapping (address => mapping (address => bool)) private _operatorsOfAddress;

  // Two mappings for the "ones" (Accounts) to the "many (Tokens).
  mapping(uint => mapping (bytes32 => uint[])) internal tokenKeys;
  mapping(uint => mapping (bytes32 => mapping(uint => uint))) internal tokenKeyPointers;

  // A mapping to determine whether cards are trade-locked (required for some purchases)
  mapping(uint => uint) public indexToTradableTime;

  // @notice Name and symbol of the non fungible token, as defined in ERC721.
  string internal constant NAME = "GAME Credits ERC721";
  string internal constant SYMBOL = "GAME";
  bytes4 private constant ON_ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

  constructor() {  }

  // "cryptoOwner" here is the owner of the crypto account, not the in-game account
  // If there's no linked crypto acocunt, canTransfer must throw.
  modifier canTransfer(uint tokenId_, address cryptoFrom_) {
    address sender = _msgSender();
    address cryptoOwner = getValidCryptoAccount(uint256(uint64(tokenId_)), indexToOwner[tokenId_]);
    require(cryptoOwner == cryptoFrom_, "owner must be from address");
    require(
      cryptoOwner == sender ||
      sender == indexToApproved[tokenId_] ||
      _operatorsOfAddress[cryptoOwner][sender],
      "must be legal to transfer"
    );
    _;
  }

  // @dev Tokens are valid if they're not owned by the zero address
  modifier isValidToken(uint tokenId_) {
    require(indexToOwner[tokenId_] != bytes32(0),"token Id is not valid");
    _;
  }

  // @dev This gets all the tokens owned by an IN GAME ADDRESS (across all sets and cards)
  // @notice Returns a list of all tokenIds assigned to an in-game address address.
  // @notice Returns a dynamic array, which is only supported for web3 calls, and
  //  not contract-to-contract calls.
  // @param inGameAccount_ The owner whose Tokens we are interested in.
  function tokenIdsOfInGameAccount(uint game_, bytes32 inGameAccount_)
    external
    view
  returns(uint[] memory)
  {
    require(inGameAccount_ != bytes32(0), "Can't get tokens of address(0)");
    return tokenKeys[game_][inGameAccount_];
  }

  // @dev Not a standard method of ERC-721 enumerable; this gets all the tokens owned by an address
  //   (across all sets and games)
  // @notice Returns a list of all tokenIds assigned to a crypto address.
  // @notice Returns a dynamic array, which is only supported for web3 calls, and
  //  not contract-to-contract calls.
  // @param game_ The game Id we're interested in
  // @param cryptoAccount_ The owner whose Tokens we are interested in.
  function tokenIdsOfOwner(uint game_, address cryptoAccount_)
    external
    view
  returns(uint[] memory)
  {
    bytes32 inGameAccount = getValidInGameAccount(game_, cryptoAccount_);
    return tokenKeys[game_][inGameAccount];
  }

  // ****** ERC721 Metadata *****//
  // @notice We don't implement the ERC721 Metadata interface here - there's
  //  no on-chain metadata links
  // @notice Name of the token, as defined in ERC721 Metadata
  function name()
    external
    pure
  returns(string memory) {
    return NAME;
  }

  // @notice Symbol of the token, as defined in ERC721 Metadata
  function symbol()
    external
    pure
  returns(string memory) {
    return SYMBOL;
  }

  // @notice Find the in-game owner of an NFT
  // @param tokenId_ The identifier for an NFT
  // @return The in-game owner (bytes32) of the owner of the NFT
  function inGameOwnerOf(uint tokenId_)
    external
    override
    view
  returns (bytes32 owner_) {
    owner_ = indexToOwner[tokenId_];
  }

  // @notice Find the owner of an NFT
  // @param tokenId_ The identifier for an NFT
  // @dev This will THROW if the token owner hasn't linked an Ethereum account to
  //    their in-game account
  // @return The address of the owner of the NFT
  function ownerOf(uint tokenId_)
    external
    override
    view
  returns (address owner_) {
    uint game = uint256(uint64(tokenId_));
    owner_ = getValidCryptoAccount(game, indexToOwner[tokenId_]);
  }

  // @notice Get the approved address for a single NFT
  // @dev Throws if `tokenId_` is not a valid NFT
  // @param tokenId_ The NFT to find the approved address for
  // @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint tokenId_)
    external
    override
    view
    isValidToken(tokenId_)
  returns(address) {
    return indexToApproved[tokenId_];
  }

  // @notice Query if an address is an authorized operator for another address
  // @param owner_ The address that owns the NFTs
  // @param operator_ The address that acts on behalf of the owner
  // @return True if `operator_` is an approved operator for `owner_`, false otherwise
  function isApprovedForAll(address owner_, address operator_)
    external
    override
    view
  returns(bool) {
    return _operatorsOfAddress[owner_][operator_];
  }

  // @notice Returns the number of Tokens owned by a specific in-game address.
  // @param owner_ The owner address to check.
  // @dev Required for ERC-721 compliance
  function balanceOfInGameAccount(uint game_, bytes32 inGameAccount_)
    external
    view
  returns(uint count) {
    return tokenKeys[game_][inGameAccount_].length;
  }

  // @notice Returns the number of Tokens owned by a specific in-game address.
  // @param owner_ The owner address to check.
  // @dev Required for ERC-721 compliance
  function balanceOfGame(uint game_, address cryptoAccount_)
    external
    view
  returns(uint count) {
    return tokenKeys[game_][getValidInGameAccount(game_, cryptoAccount_)].length;
  }

  // @notice Returns the number of Tokens owned by a specific address across all games
  // @param owner_ The owner address to check.
  // @dev Required for ERC-721 compliance
  function balanceOf(address cryptoAccount_)
    external
    override
    view
  returns(uint count) {
    uint[] storage gamesLinked = gamesLinkedToCrypto[cryptoAccount_];
    for (uint i = 0; i < gamesLinked.length; i++) {
      uint game_ = gamesLinked[i];
      count += tokenKeys[game_][getValidInGameAccount(game_, cryptoAccount_)].length;
    }
  }

  // @notice Returns the number of Tokens owned by a specific address across all games
  // @param owner_ The owner address to check.
  // @dev Required for ERC-721 compliance
  function balanceByGameOf(address cryptoAccount_)
    external
    view
  returns(uint[] memory games, uint[] memory balances) {
    games = gamesLinkedToCrypto[cryptoAccount_];
    balances = new uint256[](games.length);
    for (uint i = 0; i < games.length; i++) {
      uint game_ = games[i];
      balances[i] = tokenKeys[game_][getValidInGameAccount(game_, cryptoAccount_)].length;
    }
  }

  // @notice Grant another address the right to transfer a specific token via
  //  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
  // @param to_ The address to be granted transfer approval. Pass address(0) to
  //  clear all approvals.
  // @param tokenId_ The Id of the token that can be transferred if this call succeeds.
  // @dev Required for ERC-721 compliance.
  function approve(address approved_, uint tokenId_)
    external
    override
  {
    address sender = _msgSender();
    address cryptoOwner = getValidCryptoAccount(uint256(uint64(tokenId_)), indexToOwner[tokenId_]);
    require(approved_ != cryptoOwner, "can't approve the owner");
    require(cryptoOwner == sender || _operatorsOfAddress[cryptoOwner][sender], "must be able to approve");

    // Register the approval (replacing any previous approval).
    indexToApproved[tokenId_] = approved_;

    // Emit approval event.
    emit Approval(cryptoOwner, approved_, tokenId_);
  }

  // @notice Enable or disable approval for a third party ("operator") to manage
  //  all your asset.
  // @dev Emits the ApprovalForAll event
  // @param operator_ Address to add to the set of authorized operators.
  // @param approved_ True if the operators is approved, false to revoke approval
  function setApprovalForAll(address operator_, bool approved_)
    external
    override
  {
    address sender = _msgSender();
    require(operator_ != sender, "can't operate yourself");
    _operatorsOfAddress[sender][operator_] = approved_;
    emit ApprovalForAll(sender, operator_, approved_);
  }

  // @notice Transfers the ownership of an NFT from one address to another address
  // @dev Throws unless sender is the current owner, an authorized
  //  operator, or the approved address for this NFT. Throws if `from_` is
  //  not the current owner. Throws if `to_` is the zero address. Throws if
  //  `tokenId_` is not a valid NFT. When transfer is complete, this function
  //  checks if `to_` is a smart contract (code size > 0). If so, it calls
  //  `onERC721Received` on `to_` and throws if the return value is not
  //  `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
  // @param from_ The current owner of the NFT
  // @param to_ The new owner
  // @param tokenId_ The NFT to transfer
  // @param data Additional data with no specified format, sent in call to `to_`
  function safeTransferFrom(address from_, address to_, uint tokenId_, bytes calldata data_)
    external
    override
  {
    _safeTransferFrom(from_, to_, tokenId_, data_);
  }

  // @notice Transfers the ownership of an NFT from one address to another address
  // @dev This works identically to the other function with an extra data parameter,
  //  except this function just sets data to ""
  // @param from_ The current owner of the NFT
  // @param to_ The new owner
  // @param tokenId_ The NFT to transfer
  function safeTransferFrom(address from_, address to_, uint tokenId_)
    external
    override
  {
    _safeTransferFrom(from_, to_, tokenId_, "");
  }

  // @notice Transfers a token from the sender to another address. If transferring
  //  to a smart contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
  //  this contract specifically) or your token may be lost forever. Seriously.
  // @param from_ The address that owns the token to be transfered.
  // @param to_ The address that should take ownership of the token. Can be any address,
  //  including the caller.
  // @param tokenId_ The Id of the token to be transferred.
  function transferFrom(address from_, address to_, uint tokenId_)
    external
    override
    canTransfer(tokenId_, from_)
  {
    // Disallow transfers to this contract to prevent accidental misuse.
    // The contract should never own any Tokens.
    require(to_ != address(this), "never transfer to this contract");

    // Reassign ownership (also clears pending approvals and emits Transfer event).
    _externalTransfer(to_, tokenId_);
  }

  // @dev Actually perform the safeTransferFrom
  function _safeTransferFrom(address from_, address to_, uint tokenId_, bytes memory data_)
    private
    canTransfer(tokenId_, from_)
  {
    _externalTransfer(to_, tokenId_);

    // Do the callback after everything is done to avoid reentrancy attack
    uint codeSize;
    // solium-disable-next-line security/no-inline-assembly
    assembly { codeSize := extcodesize(to_) }
    if (codeSize == 0) {
      return;
    }
    bytes4 result = iERC721Receiver(to_).onERC721Received(_msgSender(), from_, tokenId_, data_);
    //emit ReceivedResult(result, ON_ERC721_RECEIVED);
    require(result == ON_ERC721_RECEIVED, "response must match erc721 receiver");
  }

  //event ReceivedResult(bytes4 result, bytes4 expected);

  function _externalTransfer(address to_, uint tokenId_)
    internal
    isValidToken(tokenId_)
  {
    // Safety check to prevent against an unexpected 0x0 default.
    require(to_ != address(0), "can't transfer to zero address");
    bytes32 inGameTo = _getOrCreateInGameAccount(uint256(uint64(tokenId_)), to_);
    _uncheckedTransfer(inGameTo, tokenId_, true);
  }

  // @dev Assigns ownership of a specific token to an in-game address.
  function _internalTransfer(bytes32 inGameTo_, uint tokenId_, bool shouldCheckTransferTime_)
    internal
    isValidToken(tokenId_)
  {
    _uncheckedTransfer(inGameTo_, tokenId_, shouldCheckTransferTime_);
  }

  // @dev Assigns ownership of a specific token to an in-game address.
  function _uncheckedTransfer(bytes32 inGameTo_, uint tokenId_, bool shouldCheckTransferTime_)
    internal
  {
    bytes32 inGameFrom = indexToOwner[tokenId_];
    uint game = uint256(uint64(tokenId_));
    // When creating new tokens from_ is 0x0, but we can't account that address.
    if (inGameFrom != bytes32(0)) {
      // Can't transfer between non-zero addresses if the card is trade-locked
      require(
        !shouldCheckTransferTime_ || inGameTo_ == bytes32(0) || block.timestamp >= indexToTradableTime[tokenId_],
        "token must be legal to trade at this time"
      );

      // clear any previously approved ownership exchange
      delete indexToApproved[tokenId_];

      if (inGameFrom != inGameTo_) {
        // we have to delete this key from the list in the old ONE, if it changes owners
        uint rowToDelete = tokenKeyPointers[game][inGameFrom][tokenId_];
        uint lastKeyPosition = tokenKeys[game][inGameFrom].length.sub(1);
        uint keyToMove = tokenKeys[game][inGameFrom][lastKeyPosition];
        tokenKeys[game][inGameFrom][rowToDelete] = keyToMove;
        tokenKeyPointers[game][inGameFrom][keyToMove] = rowToDelete;
        tokenKeys[game][inGameFrom].pop();
      }
    }

    // Point the token to the right owner:
    indexToOwner[tokenId_] = inGameTo_;

    if (inGameTo_ != bytes32(0) && inGameFrom != inGameTo_) {
      // Set the token to be owned by the new owner, unless the new owner is 0 (deleted)
      tokenKeyPointers[game][inGameTo_][tokenId_] = tokenKeys[game][inGameTo_].length;
      tokenKeys[game][inGameTo_].push(tokenId_);
    }

    address from = getCryptoAccount(game, inGameFrom);
    address to = getCryptoAccount(game, inGameTo_);

    // Emit the transfer event.
    emit Transfer(from, to, tokenId_);
    emit InGameTransfer(game, inGameFrom, inGameTo_, tokenId_);
  }
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


// @dev allows managers to add new games to the service;
//   allows game managers to add and remove admin accounts
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.

abstract contract GAME_NFT_AccountMgmt is GAME_NFT_ERC721 {
  using SafeMath for uint256;

  event AccountApproved(
    uint indexed game,
    bytes32 indexed inGameAccount,
    address indexed cryptoAccount
  );
  event AccountUnlinked(
    uint indexed game,
    bytes32 indexed inGameAccount,
    address indexed cryptoAccount
  );
  event AccountMerged(
    uint indexed game,
    bytes32 indexed fromInGameAccount,
    bytes32 indexed toInGameAccount,
    address cryptoAccount
  );

  iGAME_Master public masterContract;
  iGAME_Game public gameContract;
  iGAME_ERC20 public erc20Contract;
  mapping(address => bool) public localContracts;

  modifier onlyLocalContract() {
    // Cannot be called using native meta-transactions
    require(localContracts[msg.sender], "Sender must be a local contract");
    _;
  }

  modifier workerOrMinion() {
    require(masterContract.makeFundedCall(_msgSender()), "must be called by a worker or minion");
    _;
  }

  modifier operatorOrMinion(uint game_) {
    require(gameContract.isOperatorOrMinion(game_, _msgSender()), "must be called by an operator or worker");
    _;
  }

  function updateLocalContract(address contract_, bool isLocal_)
    external
    override
    onlyLocalContract
  {
    require(contract_ != address(masterContract), "can't reset the master contract");
    require(contract_ != address(erc20Contract), "can't reset the erc20 contract");
    require(contract_ != address(0), "can't be the zero address");
    localContracts[contract_] = isLocal_;
  }

  function linkContracts(address gameContract_, address erc20Contract_)
    external
    override
    onlyLocalContract
  {
    require(address(gameContract) == address(0), "data contract must be blank");
    require(address(erc20Contract) == address(0), "auction contract must be blank");
    gameContract = iGAME_Game(gameContract_);
    erc20Contract = iGAME_ERC20(erc20Contract_);
  }

  // @notice You can link client account A to Crypto account Z even
  // @notice call this with account(0) to un-link
  // @param game_ - the # of the game which holds this account
  // @param inGameAccount_ - the in-game account Id controlled by the game
  // @param cryptoAccount_ - the Ethereum account Id of the user
  function approveCryptoAccount(uint game_, bytes32 inGameAccount_, address cryptoAccount_)
    external
    operatorOrMinion(game_)
  {
    require(gameToCrypto[game_][inGameAccount_] == address(0), "client must not already be linked");
    approvedCryptoAccounts[game_][inGameAccount_] = cryptoAccount_;
    emit AccountApproved(game_, inGameAccount_, cryptoAccount_);
  }

  // @dev Links the account you send this from to your in-game account
  //   IF your crypto account already has tokens, will merge your account into the new acct
  // @param game_ - the # of the game which holds this account
  // @param inGameAccount_ - the in-game account Id controlled by the game
  function linkCryptoAccountToGame(uint game_, bytes32 inGameAccount_)
    external
  {
    address sender = _msgSender();
    require(
      address(uint(inGameAccount_)>>96) == sender ||
      approvedCryptoAccounts[game_][inGameAccount_] == sender,
      "sender must be authorized or same account");
    require(
      gameToCrypto[game_][inGameAccount_] == address(0),
      "in-game account must not already be linked");
    if (cryptoToGame[game_][sender] == bytes32(0)) {
      _linkCryptoAccount(game_, sender, inGameAccount_);
    } else {
      _mergeInGameAccounts(game_, sender, inGameAccount_);
    }
  }

  // @dev This (a) transfers any items in your current in-game account to the listed in-game account
  //   and then (b) switches the linkage to that account. It REQUIRES that the in-game account to merge has
  //   Approved
  // @param game_ - the # of the game which holds this account
  // @param mergeInto_ - the in-game account Id to transfer assets into
  function _mergeInGameAccounts(uint game_, address cryptoAccount_, bytes32 mergeInto_)
    internal
  {
    require(
      approvedCryptoAccounts[game_][mergeInto_] == cryptoAccount_,
      "sender must be authorized by client");
    require(gameToCrypto[game_][mergeInto_] == address(0), "client must not already be linked");
    bytes32 from_ = getValidInGameAccount(game_, cryptoAccount_);

    // Transfer all tokens owned by account from_ to account to_
    uint[] storage transferred = tokenKeys[game_][from_];
    while(transferred.length > 0) {
      _internalTransfer(mergeInto_, transferred[0], false);
    }

    // un-link the current account
    _unlinkCryptoAccount(game_, cryptoAccount_, from_);

    // link the new account
    _linkCryptoAccount(game_, cryptoAccount_, mergeInto_);

    // Emit the merge event
    emit AccountMerged(game_, from_, mergeInto_, cryptoAccount_);
  }

  // @dev This transfers a number of tokens from your account to another account that you've approved
  //   It does not merge ownership of the two accounts, but can be used to merge large accounts in stages
  //   where merging a single account would be too costly as a single transaction
  // @param game_ - the # of the game which holds this account
  // @param mergeInto_ - the in-game account Id to transfer assets into
  function partialMergeTokens(uint game_, bytes32 mergeInto_, uint numberToMerge_)
    external
  returns (uint[] memory) {
    address sender = _msgSender();
    require(approvedCryptoAccounts[game_][mergeInto_] == sender, "sender must be authorized by client");
    require(gameToCrypto[game_][mergeInto_] == address(0), "client must not already be linked");
    bytes32 from_ = getValidInGameAccount(game_, sender);

    // Transfer all tokens owned by account from_ to account to_
    uint[] storage owned = tokenKeys[game_][from_];

    require(numberToMerge_ <= owned.length, "early out if you try to transfer too many");
    uint[] memory transferred = new uint[](numberToMerge_);
    for (uint i = 0; i < numberToMerge_; i++) {
      uint toTransfer = owned[0];
      transferred[i] = toTransfer;
      _internalTransfer(mergeInto_, toTransfer, false);
      // The token at owned[0] will continually change, because transfer alters the storage array
    }
    return transferred;
  }

  // @dev Gets the user's inGameAccount or creates a new one it if it isn't yet set.
  // @notice This requires CAREFUL management when players can create accounts, and the game's set up
  //   to also use a 3rd-party account. If a player uses this function first, the player will need to:
  //     (a) create a new in-game accout
  //     (b) Have the service call approveCryptoAccount to approve their current crypto account
  //     (c) Call linkCryptoAccountToGame to link your crypto to your in-game acct
  //          Calling this will merge anything from your current acct into the new acct
  // @param game_ - the # of the game which holds this account
  // @param cryptoAccount_ - the Ethereum account Id of the user
  // @returns the user's linked account. If one isn't set, links the account first.
  function getOrCreateInGameAccount(uint game_, address cryptoAccount_)
    external
    override
    onlyLocalContract
  returns(bytes32 inGameAccount) {
    return _getOrCreateInGameAccount(game_, cryptoAccount_);
  }

  // @dev removes ownership of a game account (you can re-establish ownership via a game)
  // @param game_ - the # of the game which holds this account
  function unlinkCryptoAccount(uint game_)
    external
  returns(bytes32 inGameAccount) {
    address sender = _msgSender();
    inGameAccount = cryptoToGame[game_][sender];
    // require(inGameAccount != sender, "can't un-merge an automatically created account");
    require(inGameAccount != bytes32(0), "can't un-merge a null account");

    _unlinkCryptoAccount(game_, sender, inGameAccount);
  }

  function _unlinkCryptoAccount(uint game_, address cryptoAccount_, bytes32 inGameAccount_)
    internal
  {
    require(cryptoToGame[game_][cryptoAccount_] == inGameAccount_, "account must be linked");
    delete gameToCrypto[game_][inGameAccount_];
    delete cryptoToGame[game_][cryptoAccount_];

    // Remove pointer and game list entry;
    uint pointer = gamesLinkedToCryptoPointers[game_][cryptoAccount_];
    uint[] storage gamesLink = gamesLinkedToCrypto[cryptoAccount_];
    uint newLength = gamesLink.length.sub(1);
    uint otherGame = gamesLink[newLength];
    gamesLinkedToCryptoPointers[otherGame][cryptoAccount_] = pointer;
    gamesLink[pointer] = otherGame;
    delete gamesLinkedToCryptoPointers[game_][cryptoAccount_];
    gamesLink.pop();
    emit AccountUnlinked(game_, inGameAccount_, cryptoAccount_);
  }

  function metaTxSenderIsWorkerOrMinion()
    internal
    override
  returns (bool) {
    return masterContract.makeFundedCall(msg.sender);
  }
}


// @title GAME Credits Collectible Data
// @dev GAME_Game contract for managing all collectible data
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.

abstract contract GAME_NFT_Collectibles is GAME_NFT_AccountMgmt {
  using SafeMath for uint256;

// May need to be a localcontract, or part of another contract
// Emits an collectibledata event
  event CollectibleDataUpdated(uint indexed tokenId, uint xp, uint xpPerHour, uint creationTime);
  event CollectibleReset(uint indexed tokenId, uint prevXp, uint prevXpPerHour, uint prevBirthTime);
  event CollectibleXpAdded(uint indexed tokenId, uint xpAdded, uint newXp);
  event CollectibleMerged(uint indexed tokenId, uint indexed mergedTokenId, uint xpGain);

  // collectible data is: creationTime, xp, xpPerHour, ??
  // we use binary addition

  mapping(uint => uint) public collectibleData;

  // xp per level: 100 for L1; 2x for each higher level

  function getCurrentLevel(uint tokenId_)
    public
    view
  returns(uint level) {
    level = _calculateCollectibleLevel(getCurrentXP(tokenId_));
  }

  function getCurrentXP(uint tokenId_)
    public
    view
  returns(uint xp) {
    (uint storedXp, uint xpPerHour, uint creationTime) = parseCollectibleData(collectibleData[tokenId_]);
    xp = storedXp + (block.timestamp.sub(creationTime)).div(3600).mul(xpPerHour);
  }

  function encodeCollectibleData(uint xp_, uint xpPerHour_, uint creationTime_)
    public
    pure
  returns(uint encodedData) {
    // Encoded as creationTime (32 bits, merges (96 bits), xp (128 bits))
    require(uint(uint128(xp_)) == xp_, "no xp overflow");
    require(uint(uint96(xpPerHour_)) == xpPerHour_, "no xpPerHour overflow");
    require(uint(uint32(creationTime_)) == creationTime_, "no creationTime overflow");
    encodedData = creationTime_|(xpPerHour_<<32)|(xp_<<128);
  }

  function parseCollectibleData(uint collectibleData_)
    public
    pure
  returns(uint xp, uint xpPerHour, uint creationTime) {
    xp = uint(collectibleData_>>128);
    xpPerHour = uint(uint96(collectibleData_>>32));
    creationTime = uint(uint32(collectibleData_));
  }

  function getCollectibleData(uint tokenId_)
    public
    view
  returns(uint xp, uint xpPerHour, uint creationTime) {
    return parseCollectibleData(collectibleData[tokenId_]);
  }

  // @dev creates an collectible, saving its initial xp, timestamp, etc.
  function generateCollectible(uint tokenId_, uint xp_, uint xpPerHour_, uint creationTime_)
    external
    override
    onlyLocalContract
  {
    require(collectibleData[tokenId_] == 0, "must not be an collectible here");
    require(xp_ > 0, "must have at least 1 base xp");
    require(creationTime_ > 0, "must have a creationTime");
    _storeCollectibleData(tokenId_, xp_, xpPerHour_, creationTime_);
  }

  function workerAddXpToCollectible(uint tokenId_, uint xpToAdd_)
    external
    workerOrMinion
  {
    (uint currentXp, uint xpPerHour, uint creationTime) = getCollectibleData(tokenId_);
    require(currentXp > 0, "collectible must exist & already have some XP");
    require(xpToAdd_ > 0, "must add at least 1 xp");
    uint newXp = currentXp.add(xpToAdd_);
    emit CollectibleXpAdded(tokenId_, xpToAdd_, newXp);
    _storeCollectibleData(tokenId_, newXp, xpPerHour, creationTime);
  }

  function workerResetCollectible(uint tokenId_, uint newXp_, uint newXpPerHour_, uint newBirthTime_)
    external
    workerOrMinion
  {
    (uint currentXp, uint xpPerHour, uint creationTime) = getCollectibleData(tokenId_);
    require(currentXp > 0, "collectible must exist & already have some XP");
    require(newXp_ > 0, "must have at least 1 base xp");
    require(newBirthTime_ > 0, "must have a creationTime");
    emit CollectibleReset(tokenId_, currentXp, xpPerHour, creationTime);
    _storeCollectibleData(tokenId_, newXp_, newXpPerHour_, newBirthTime_);
  }

  // Merges collectibles if they're all owned by the same user
  // Keeps the oldest collectible; combines xpPerHour and XP of the rest
  // Respects tradelock - you can merge into a tradelocked collectible, but you can't merge away one
  function workerMergeCollectibles(uint[] calldata collectibles_)
    external
    workerOrMinion
  {
    require(collectibles_.length > 1, "must be at least 2 collectibles to merge");
    uint tokenId = collectibles_[0];
    (uint xp, uint xpPerHour, uint creationTime) = getCollectibleData(tokenId);
    uint champion1 = uint256(uint64(tokenId>>64));
    uint card1 = uint256(uint64(tokenId>>128));
    // merges all the collectibles into the first one (sort in ascending numeric order)
    // for each collectible in the group, get the xp and combine it
    // add together each collectible's xpPerHour
    uint newXp = xp;
    for(uint i = 1; i < collectibles_.length; i++) {
      for (uint j = 0; j < i; j++) {
        require(collectibles_[i] != collectibles_[j], "collectible IDs must all be different");
      }
      require(uint256(uint64(collectibles_[i]>>64)) == champion1, "champion ID must match");
      require(uint256(uint64(collectibles_[i]>>128)) == card1, "card ID must match");

      require(indexToOwner[tokenId] == indexToOwner[collectibles_[i]], "must be owned by the same user");
      (uint i_Xp, uint i_XpPerHour, uint i_creationTime) = getCollectibleData(collectibles_[i]);
      newXp = newXp.add(i_Xp);
      xpPerHour = xpPerHour.add(i_XpPerHour);
      if(i_creationTime < creationTime) {
        _burn(tokenId, true); // transfer away the previous collectible
        creationTime = i_creationTime; // update the tracked creationTime
        emit CollectibleMerged(collectibles_[i], tokenId, xp);
        tokenId = collectibles_[i]; // update the tracked collectible Id
      } else {
        _burn(collectibles_[i], true); // transfer away this collectible
        collectibleData[tokenId] = 0; // clear this collectible's data
        emit CollectibleMerged(tokenId, collectibles_[i], i_Xp);
      }
    }
    _storeCollectibleData(tokenId, newXp, xpPerHour, creationTime);
  }

  function _calculateCollectibleLevel(uint xp_)
    internal
    pure
  returns(uint level) {
    uint xp = xp_;
    while(xp > 0) {
      level++;
      xp = xp.div(2);
    }
  }

  function _storeCollectibleData(uint tokenId_, uint xp_, uint xpPerHour_, uint creationTime_)
    internal
  {
    collectibleData[tokenId_] = encodeCollectibleData(xp_, xpPerHour_, creationTime_);
    emit CollectibleDataUpdated(tokenId_, xp_, xpPerHour_, creationTime_);
  }

  // @dev Assigns ownership of a specific token to an in-game address.
  function _burn(uint tokenId_, bool shouldCheckTransferTime_)
    internal
    isValidToken(tokenId_)
  {
    // reduce the supply
    gameContract.burnToken(tokenId_);
    _uncheckedTransfer(bytes32(0), tokenId_, shouldCheckTransferTime_);
  }
}

// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.

contract GAME_NFT is GAME_NFT_Collectibles {

  string constant public CONTRACT_ERC712_VERSION = "1";
  string constant public CONTRACT_ERC712_NAME = "GAME Credits Sidechain ERC721 Contract";

  // @dev Fired whenever an Operator revokes a token that was purchased with off-chain currency
  event TokenRevoked(uint indexed game, uint tokenId, bytes32 indexed currentOwner, bytes32 indexed purchaseId);

  // @dev Constructor creates a reference to the NFT ownership contract
  //  and verifies the manager cut is in the valid range.
  // @param masterContract_ - address of the master contract
  //  between 0-10,000.
  constructor(address masterContract_)
    NetworkAgnostic(CONTRACT_ERC712_NAME, CONTRACT_ERC712_VERSION)
  {
    masterContract = iGAME_Master(masterContract_);
    localContracts[masterContract_] = true;
  }

  function transferNewToken(bytes32 recipient_, uint tokenId_, uint tradeLockTime_)
    external
    override
    onlyLocalContract
  {
    indexToTradableTime[tokenId_] = tradeLockTime_;
    _uncheckedTransfer(recipient_, tokenId_, false);
  }

  function auctionTransfer(address from_, address to_, uint tokenId_)
    external
    override
    onlyLocalContract
  {
    address cryptoOwner = getCryptoAccount(uint256(uint64(tokenId_)), indexToOwner[tokenId_]);
    require(cryptoOwner == from_, "owner must be from address");

    _externalTransfer(to_, tokenId_);
  }

  function revokeToken(uint game_, uint tokenId_, bytes32 purchaseId_)
    external
    override
    onlyLocalContract
  returns (bool _isRevoked) {
    bytes32 _currentOwner = indexToOwner[tokenId_];
    if(block.timestamp < indexToTradableTime[tokenId_] && _currentOwner != bytes32(0)) {
      _internalTransfer(bytes32(0), tokenId_, false);
      _isRevoked = true;
      emit TokenRevoked(game_, tokenId_, _currentOwner, purchaseId_);
    }
  }
}