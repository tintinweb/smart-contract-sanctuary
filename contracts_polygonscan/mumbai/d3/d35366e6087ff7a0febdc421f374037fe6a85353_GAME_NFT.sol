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







// @title ERC-721 Non-Fungible Token Standard
// @dev Interface for contracts conforming to ERC-721: Non-Fungible Tokens
// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
//  Note: the ERC-165 identifier for this interface is 0x80ac58cd
interface iERC721 {

  // @notice Count all NFTs assigned to an owner
  // @dev NFTs assigned to the zero address are considered invalid, and this
  //  function throws for queries about the zero address.
  // @param _owner An address for whom to query the balance
  // @return The number of NFTs owned by `_owner`, possibly zero
  function balanceOf(address _owner) external view returns (uint);

  // @notice Find the owner of an NFT
  // @param _tokenId The identifier for an NFT
  // @dev NFTs assigned to zero address are considered invalid, and queries
  //  about them do throw.
  // @return The address of the owner of the NFT
  function ownerOf(uint _tokenId) external view returns (address);

  // @notice Transfers the ownership of an NFT from one address to another address
  // @dev Throws unless `msg.sender` is the current owner, an authorized
  //  operator, or the approved address for this NFT. Throws if `_from` is
  //  not the current owner. Throws if `_to` is the zero address. Throws if
  //  `_tokenId` is not a valid NFT. When transfer is complete, this function
  //  checks if `_to` is a smart contract (code size > 0). If so, it calls
  //  `onERC721Received` on `_to` and throws if the return value is not
  //  `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
  // @param _from The current owner of the NFT
  // @param _to The new owner
  // @param _tokenId The NFT to transfer
  // @param data Additional data with no specified format, sent in call to `_to`
  function safeTransferFrom(address _from, address _to, uint _tokenId, bytes calldata _data) external;

  // @notice Transfers the ownership of an NFT from one address to another address
  // @dev This works identically to the other function with an extra data parameter,
  //  except this function just sets data to ""
  // @param _from The current owner of the NFT
  // @param _to The new owner
  // @param _tokenId The NFT to transfer
  function safeTransferFrom(address _from, address _to, uint _tokenId) external;

  // @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  //  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
  //  THEY MAY BE PERMANENTLY LOST
  // @dev Throws unless `msg.sender` is the current owner, an authorized
  //  operator, or the approved address for this NFT. Throws if `_from` is
  //  not the current owner. Throws if `_to` is the zero address. Throws if
  //  `_tokenId` is not a valid NFT.
  // @param _from The current owner of the NFT
  // @param _to The new owner
  // @param _tokenId The NFT to transfer
  function transferFrom(address _from, address _to, uint _tokenId) external;

  // @notice Set or reaffirm the approved address for an NFT
  // @dev The zero address indicates there is no approved address.
  // @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
  //  operator of the current owner.
  // @param _approved The new approved NFT controller
  // @param _tokenId The NFT to approve
  function approve(address _approved, uint _tokenId) external;

  // @notice Enable or disable approval for a third party ("operator") to manage
  //  all your assets.
  // @dev Throws unless `msg.sender` is the current NFT owner.
  // @dev Emits the ApprovalForAll event
  // @param _operator Address to add to the set of authorized operators.
  // @param _approved True if the operators is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved) external;

  // @notice Get the approved address for a single NFT
  // @dev Throws if `_tokenId` is not a valid NFT
  // @param _tokenId The NFT to find the approved address for
  // @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint _tokenId) external view returns (address);

  // @notice Query if an address is an authorized operator for another address
  // @param _owner The address that owns the NFTs
  // @param _operator The address that acts on behalf of the owner
  // @return True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}



// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface iERC721Receiver {
  // @notice Handle the receipt of an NFT
  // @dev The ERC721 smart contract calls this function on the recipient
  //  after a `transfer`. This function MAY throw to revert and reject the
  //  transfer. This function MUST use 50,000 gas or less. Return of other
  //  than the magic value MUST result in the transaction being reverted.
  //  Note: the contract address is always the message sender.
  // @param _operator The address which called `safeTransferFrom` function
  // @param _from The address which previously owned the token
  // @param _tokenId The NFT identifier which is being transferred
  // @param _data Additional data with no specified format
  // @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  //    unless throwing
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
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
        toWorkerTypedMessageHash(hashWorkerMetaTransaction(metaTx)),
        sigV,
        sigR,
        sigS
      );
  }

  /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
  function toWorkerTypedMessageHash(bytes32 messageHash)
    internal
    view
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked("\x19\x01", getWorkerDomainSeperator(), messageHash)
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

  modifier isOwnerOf(uint _game, bytes32 _inGameAccount)
  {
    address sender = _msgSender();
    require(
      bytes32(uint(sender)) == _inGameAccount ||
      cryptoToGame[_game][sender] == _inGameAccount,
      "sender owns this account");
    _;
  }

  function getLinkedGames(address _cryptoAccount)
    external
    view
  returns (uint[] memory) {
    return gamesLinkedToCrypto[_cryptoAccount];
  }

  function getCryptoAccount(uint _game, bytes32 _inGameAccount)
    public
    override
    view
  returns(address cryptoAccount) {
    cryptoAccount = gameToCrypto[_game][_inGameAccount];
  }

  function getValidCryptoAccount(uint _game, bytes32 _inGameAccount)
    public
    override
    view
  returns(address cryptoAccount) {
    cryptoAccount = gameToCrypto[_game][_inGameAccount];
    require(cryptoAccount != address(0), "crypto account must be linked (non-zero)");
  }

  function getInGameAccount(uint _game, address _cryptoAccount)
    public
    override
    view
  returns(bytes32 inGameAccount) {
    inGameAccount = cryptoToGame[_game][_cryptoAccount];
  }

  function getValidInGameAccount(uint _game, address _cryptoAccount)
    public
    override
    view
  returns(bytes32 inGameAccount) {
    inGameAccount = cryptoToGame[_game][_cryptoAccount];
    require(inGameAccount != bytes32(0), "in game account must be linked (set to non-zero)");
  }

  function _getOrCreateInGameAccount(uint _game, address _cryptoAccount)
    internal
  returns(bytes32 inGameAccount) {
    require(_cryptoAccount != address(0), "account must be valid");
    inGameAccount = cryptoToGame[_game][_cryptoAccount];
    if(inGameAccount == bytes32(0)) {
      inGameAccount = bytes32(uint(_cryptoAccount))<<96;
      _linkCryptoAccount(_game, _cryptoAccount, inGameAccount);
    }
  }

  function _linkCryptoAccount(uint _game, address _cryptoAccount, bytes32 _inGameAccount)
    internal
  {
    delete approvedCryptoAccounts[_game][_inGameAccount];
    cryptoToGame[_game][_cryptoAccount] = _inGameAccount;
    gameToCrypto[_game][_inGameAccount] = _cryptoAccount;
    uint pointer = gamesLinkedToCrypto[_cryptoAccount].length;
    gamesLinkedToCrypto[_cryptoAccount].push(_game);
    gamesLinkedToCryptoPointers[_game][_cryptoAccount] = pointer;
    emit AccountLinked(_game, _inGameAccount, _cryptoAccount);
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
  event Transfer(address indexed _from, address indexed _to, uint indexed _tokenId);

  // @dev This emits when the approved address for an NFT is changed or
  //  reaffirmed. The zero address indicates there is no approved address.
  //  When a Transfer event emits, this also indicates that the approved
  //  address for that NFT (if any) is reset to none.
  event Approval(address indexed _owner, address indexed _approved, uint _tokenId);

  // @dev This emits when an operator is enabled or disabled for an owner.
  //  The operator can manage all NFTs of the owner.
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

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
  modifier canTransfer(uint _tokenId, address _cryptoFrom) {
    address sender = _msgSender();
    address cryptoOwner = getValidCryptoAccount(uint256(uint64(_tokenId)), indexToOwner[_tokenId]);
    require(cryptoOwner == _cryptoFrom, "owner must be from address");
    require(
      cryptoOwner == sender ||
      sender == indexToApproved[_tokenId] ||
      _operatorsOfAddress[cryptoOwner][sender],
      "must be legal to transfer"
    );
    _;
  }

  // @dev Tokens are valid if they're not owned by the zero address
  modifier isValidToken(uint _tokenId) {
    require(indexToOwner[_tokenId] != bytes32(0),"token Id is not valid");
    _;
  }

  // @dev This gets all the tokens owned by an IN GAME ADDRESS (across all sets and cards)
  // @notice Returns a list of all tokenIds assigned to an in-game address address.
  // @notice Returns a dynamic array, which is only supported for web3 calls, and
  //  not contract-to-contract calls.
  // @param _inGameAccount The owner whose Tokens we are interested in.
  function tokenIdsOfInGameAccount(uint _game, bytes32 _inGameAccount)
    external
    view
  returns(uint[] memory)
  {
    require(_inGameAccount != bytes32(0), "Can't get tokens of address(0)");
    return tokenKeys[_game][_inGameAccount];
  }

  // @dev Not a standard method of ERC-721 enumerable; this gets all the tokens owned by an address
  //   (across all sets and games)
  // @notice Returns a list of all tokenIds assigned to a crypto address.
  // @notice Returns a dynamic array, which is only supported for web3 calls, and
  //  not contract-to-contract calls.
  // @param _game The game Id we're interested in
  // @param _cryptoAccount The owner whose Tokens we are interested in.
  function tokenIdsOfOwner(uint _game, address _cryptoAccount)
    external
    view
  returns(uint[] memory)
  {
    bytes32 inGameAccount = getValidInGameAccount(_game, _cryptoAccount);
    return tokenKeys[_game][inGameAccount];
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
  // @param _tokenId The identifier for an NFT
  // @return The in-game owner (bytes32) of the owner of the NFT
  function inGameOwnerOf(uint _tokenId)
    external
    override
    view
  returns (bytes32 _owner) {
    _owner = indexToOwner[_tokenId];
  }

  // @notice Find the owner of an NFT
  // @param _tokenId The identifier for an NFT
  // @dev This will THROW if the token owner hasn't linked an Ethereum account to
  //    their in-game account
  // @return The address of the owner of the NFT
  function ownerOf(uint _tokenId)
    external
    override
    view
  returns (address _owner) {
    uint game = uint256(uint64(_tokenId));
    _owner = getValidCryptoAccount(game, indexToOwner[_tokenId]);
  }

  // @notice Get the approved address for a single NFT
  // @dev Throws if `_tokenId` is not a valid NFT
  // @param _tokenId The NFT to find the approved address for
  // @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint _tokenId)
    external
    override
    view
    isValidToken(_tokenId)
  returns(address) {
    return indexToApproved[_tokenId];
  }

  // @notice Query if an address is an authorized operator for another address
  // @param _owner The address that owns the NFTs
  // @param _operator The address that acts on behalf of the owner
  // @return True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(address _owner, address _operator)
    external
    override
    view
  returns(bool) {
    return _operatorsOfAddress[_owner][_operator];
  }

  // @notice Returns the number of Tokens owned by a specific in-game address.
  // @param _owner The owner address to check.
  // @dev Required for ERC-721 compliance
  function balanceOfInGameAccount(uint _game, bytes32 _inGameAccount)
    external
    view
  returns(uint count) {
    return tokenKeys[_game][_inGameAccount].length;
  }

  // @notice Returns the number of Tokens owned by a specific in-game address.
  // @param _owner The owner address to check.
  // @dev Required for ERC-721 compliance
  function balanceOfGame(uint _game, address _cryptoAccount)
    external
    view
  returns(uint count) {
    return tokenKeys[_game][getValidInGameAccount(_game, _cryptoAccount)].length;
  }

  // @notice Returns the number of Tokens owned by a specific address across all games
  // @param _owner The owner address to check.
  // @dev Required for ERC-721 compliance
  function balanceOf(address _cryptoAccount)
    external
    override
    view
  returns(uint count) {
    uint[] storage gamesLinked = gamesLinkedToCrypto[_cryptoAccount];
    for (uint i = 0; i < gamesLinked.length; i++) {
      uint _game = gamesLinked[i];
      count += tokenKeys[_game][getValidInGameAccount(_game, _cryptoAccount)].length;
    }
  }

  // @notice Returns the number of Tokens owned by a specific address across all games
  // @param _owner The owner address to check.
  // @dev Required for ERC-721 compliance
  function balanceByGameOf(address _cryptoAccount)
    external
    view
  returns(uint[] memory games, uint[] memory balances) {
    games = gamesLinkedToCrypto[_cryptoAccount];
    balances = new uint256[](games.length);
    for (uint i = 0; i < games.length; i++) {
      uint _game = games[i];
      balances[i] = tokenKeys[_game][getValidInGameAccount(_game, _cryptoAccount)].length;
    }
  }

  // @notice Grant another address the right to transfer a specific token via
  //  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
  // @param _to The address to be granted transfer approval. Pass address(0) to
  //  clear all approvals.
  // @param _tokenId The Id of the token that can be transferred if this call succeeds.
  // @dev Required for ERC-721 compliance.
  function approve(address _approved, uint _tokenId)
    external
    override
  {
    address sender = _msgSender();
    address cryptoOwner = getValidCryptoAccount(uint256(uint64(_tokenId)), indexToOwner[_tokenId]);
    require(_approved != cryptoOwner, "can't approve the owner");
    require(cryptoOwner == sender || _operatorsOfAddress[cryptoOwner][sender], "must be able to approve");

    // Register the approval (replacing any previous approval).
    indexToApproved[_tokenId] = _approved;

    // Emit approval event.
    emit Approval(cryptoOwner, _approved, _tokenId);
  }

  // @notice Enable or disable approval for a third party ("operator") to manage
  //  all your asset.
  // @dev Emits the ApprovalForAll event
  // @param _operator Address to add to the set of authorized operators.
  // @param _approved True if the operators is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved)
    external
    override
  {
    address sender = _msgSender();
    require(_operator != sender, "can't operate yourself");
    _operatorsOfAddress[sender][_operator] = _approved;
    emit ApprovalForAll(sender, _operator, _approved);
  }

  // @notice Transfers the ownership of an NFT from one address to another address
  // @dev Throws unless sender is the current owner, an authorized
  //  operator, or the approved address for this NFT. Throws if `_from` is
  //  not the current owner. Throws if `_to` is the zero address. Throws if
  //  `_tokenId` is not a valid NFT. When transfer is complete, this function
  //  checks if `_to` is a smart contract (code size > 0). If so, it calls
  //  `onERC721Received` on `_to` and throws if the return value is not
  //  `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
  // @param _from The current owner of the NFT
  // @param _to The new owner
  // @param _tokenId The NFT to transfer
  // @param data Additional data with no specified format, sent in call to `_to`
  function safeTransferFrom(address _from, address _to, uint _tokenId, bytes calldata data)
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, data);
  }

  // @notice Transfers the ownership of an NFT from one address to another address
  // @dev This works identically to the other function with an extra data parameter,
  //  except this function just sets data to ""
  // @param _from The current owner of the NFT
  // @param _to The new owner
  // @param _tokenId The NFT to transfer
  function safeTransferFrom(address _from, address _to, uint _tokenId)
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  // @notice Transfers a token from the sender to another address. If transferring
  //  to a smart contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
  //  this contract specifically) or your token may be lost forever. Seriously.
  // @param _from The address that owns the token to be transfered.
  // @param _to The address that should take ownership of the token. Can be any address,
  //  including the caller.
  // @param _tokenId The Id of the token to be transferred.
  function transferFrom(address _from, address _to, uint _tokenId)
    external
    override
    canTransfer(_tokenId, _from)
  {
    // Disallow transfers to this contract to prevent accidental misuse.
    // The contract should never own any Tokens.
    require(_to != address(this), "never transfer to this contract");

    // Reassign ownership (also clears pending approvals and emits Transfer event).
    _externalTransfer(_to, _tokenId);
  }

  // @dev Actually perform the safeTransferFrom
  function _safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory data)
    private
    canTransfer(_tokenId, _from)
  {
    _externalTransfer(_to, _tokenId);

    // Do the callback after everything is done to avoid reentrancy attack
    uint codeSize;
    // solium-disable-next-line security/no-inline-assembly
    assembly { codeSize := extcodesize(_to) }
    if (codeSize == 0) {
      return;
    }
    bytes4 result = iERC721Receiver(_to).onERC721Received(_msgSender(), _from, _tokenId, data);
    //emit ReceivedResult(result, ON_ERC721_RECEIVED);
    require(result == ON_ERC721_RECEIVED, "response must match erc721 receiver");
  }

  //event ReceivedResult(bytes4 result, bytes4 expected);

  function _externalTransfer(address _to, uint _tokenId)
    internal
    isValidToken(_tokenId)
  {
    // Safety check to prevent against an unexpected 0x0 default.
    require(_to != address(0), "can't transfer to zero address");
    bytes32 inGameTo = _getOrCreateInGameAccount(uint256(uint64(_tokenId)), _to);
    _uncheckedTransfer(inGameTo, _tokenId, true);
  }

  // @dev Assigns ownership of a specific token to an in-game address.
  function _internalTransfer(bytes32 _inGameTo, uint _tokenId, bool shouldCheckTransferTime)
    internal
    isValidToken(_tokenId)
  {
    _uncheckedTransfer(_inGameTo, _tokenId, shouldCheckTransferTime);
  }

  // @dev Assigns ownership of a specific token to an in-game address.
  function _uncheckedTransfer(bytes32 _inGameTo, uint _tokenId, bool shouldCheckTransferTime)
    internal
  {
    bytes32 inGameFrom = indexToOwner[_tokenId];
    uint game = uint256(uint64(_tokenId));
    // When creating new tokens _from is 0x0, but we can't account that address.
    if (inGameFrom != bytes32(0)) {
      // Can't transfer between non-zero addresses if the card is trade-locked
      require(
        !shouldCheckTransferTime || _inGameTo == bytes32(0) || block.timestamp >= indexToTradableTime[_tokenId],
        "token must be legal to trade at this time"
      );

      // clear any previously approved ownership exchange
      delete indexToApproved[_tokenId];

      if (inGameFrom != _inGameTo) {
        // we have to delete this key from the list in the old ONE, if it changes owners
        uint rowToDelete = tokenKeyPointers[game][inGameFrom][_tokenId];
        uint lastKeyPosition = tokenKeys[game][inGameFrom].length.sub(1);
        uint keyToMove = tokenKeys[game][inGameFrom][lastKeyPosition];
        tokenKeys[game][inGameFrom][rowToDelete] = keyToMove;
        tokenKeyPointers[game][inGameFrom][keyToMove] = rowToDelete;
        tokenKeys[game][inGameFrom].pop();
      }
    }

    // Point the token to the right owner:
    indexToOwner[_tokenId] = _inGameTo;

    if (_inGameTo != bytes32(0) && inGameFrom != _inGameTo) {
      // Set the token to be owned by the new owner, unless the new owner is 0 (deleted)
      tokenKeyPointers[game][_inGameTo][_tokenId] = tokenKeys[game][_inGameTo].length;
      tokenKeys[game][_inGameTo].push(_tokenId);
    }

    address from = getCryptoAccount(game, inGameFrom);
    address to = getCryptoAccount(game, _inGameTo);

    // Emit the transfer event.
    emit Transfer(from, to, _tokenId);
    emit InGameTransfer(game, inGameFrom, _inGameTo, _tokenId);
  }
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

  modifier operatorOrMinion(uint _game) {
    require(gameContract.isOperatorOrMinion(_game, _msgSender()), "must be called by an operator or worker");
    _;
  }

  function updateLocalContract(address _contract, bool _isLocal)
    external
    override
    onlyLocalContract
  {
    require(_contract != address(masterContract), "can't reset the master contract");
    require(_contract != address(erc20Contract), "can't reset the erc20 contract");
    require(_contract != address(0), "can't be the zero address");
    localContracts[_contract] = _isLocal;
  }

  function linkContracts(address _gameContract, address _erc20Contract)
    external
    override
    onlyLocalContract
  {
    require(address(gameContract) == address(0), "data contract must be blank");
    require(address(erc20Contract) == address(0), "auction contract must be blank");
    gameContract = iGAME_Game(_gameContract);
    erc20Contract = iGAME_ERC20(_erc20Contract);
  }

  // @notice You can link client account A to Crypto account Z even
  // @notice call this with account(0) to un-link
  // @param _game - the # of the game which holds this account
  // @param _inGameAccount - the in-game account Id controlled by the game
  // @param _cryptoAccount - the Ethereum account Id of the user
  function approveCryptoAccount(uint _game, bytes32 _inGameAccount, address _cryptoAccount)
    external
    operatorOrMinion(_game)
  {
    require(gameToCrypto[_game][_inGameAccount] == address(0), "client must not already be linked");
    approvedCryptoAccounts[_game][_inGameAccount] = _cryptoAccount;
    emit AccountApproved(_game, _inGameAccount, _cryptoAccount);
  }

  // @dev Links the account you send this from to your in-game account
  //   IF your crypto account already has tokens, will merge your account into the new acct
  // @param _game - the # of the game which holds this account
  // @param _inGameAccount - the in-game account Id controlled by the game
  function linkCryptoAccountToGame(uint _game, bytes32 _inGameAccount)
    external
  {
    address sender = _msgSender();
    require(
      address(uint(_inGameAccount)>>96) == sender ||
      approvedCryptoAccounts[_game][_inGameAccount] == sender,
      "sender must be authorized or same account");
    require(
      gameToCrypto[_game][_inGameAccount] == address(0),
      "in-game account must not already be linked");
    if (cryptoToGame[_game][sender] == bytes32(0)) {
      _linkCryptoAccount(_game, sender, _inGameAccount);
    } else {
      _mergeInGameAccounts(_game, sender, _inGameAccount);
    }
  }

  // @dev This (a) transfers any items in your current in-game account to the listed in-game account
  //   and then (b) switches the linkage to that account. It REQUIRES that the in-game account to merge has
  //   Approved
  // @param _game - the # of the game which holds this account
  // @param _mergeInto - the in-game account Id to transfer assets into
  function _mergeInGameAccounts(uint _game, address _cryptoAccount, bytes32 _mergeInto)
    internal
  {
    require(
      approvedCryptoAccounts[_game][_mergeInto] == _cryptoAccount,
      "sender must be authorized by client");
    require(gameToCrypto[_game][_mergeInto] == address(0), "client must not already be linked");
    bytes32 _from = getValidInGameAccount(_game, _cryptoAccount);

    // Transfer all tokens owned by account _from to account _to
    uint[] storage transferred = tokenKeys[_game][_from];
    while(transferred.length > 0) {
      _internalTransfer(_mergeInto, transferred[0], false);
    }

    // un-link the current account
    _unlinkCryptoAccount(_game, _cryptoAccount, _from);

    // link the new account
    _linkCryptoAccount(_game, _cryptoAccount, _mergeInto);

    // Emit the merge event
    emit AccountMerged(_game, _from, _mergeInto, _cryptoAccount);
  }

  // @dev This transfers a number of tokens from your account to another account that you've approved
  //   It does not merge ownership of the two accounts, but can be used to merge large accounts in stages
  //   where merging a single account would be too costly as a single transaction
  // @param _game - the # of the game which holds this account
  // @param _mergeInto - the in-game account Id to transfer assets into
  function partialMergeTokens(uint _game, bytes32 _mergeInto, uint _numberToMerge)
    external
  returns (uint[] memory) {
    address sender = _msgSender();
    require(approvedCryptoAccounts[_game][_mergeInto] == sender, "sender must be authorized by client");
    require(gameToCrypto[_game][_mergeInto] == address(0), "client must not already be linked");
    bytes32 _from = getValidInGameAccount(_game, sender);

    // Transfer all tokens owned by account _from to account _to
    uint[] storage owned = tokenKeys[_game][_from];

    require(_numberToMerge <= owned.length, "early out if you try to transfer too many");
    uint[] memory transferred = new uint[](_numberToMerge);
    for (uint i = 0; i < _numberToMerge; i++) {
      uint toTransfer = owned[0];
      transferred[i] = toTransfer;
      _internalTransfer(_mergeInto, toTransfer, false);
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
  // @param _game - the # of the game which holds this account
  // @param _cryptoAccount - the Ethereum account Id of the user
  // @returns the user's linked account. If one isn't set, links the account first.
  function getOrCreateInGameAccount(uint _game, address _cryptoAccount)
    external
    override
    onlyLocalContract
  returns(bytes32 inGameAccount) {
    return _getOrCreateInGameAccount(_game, _cryptoAccount);
  }

  // @dev removes ownership of a game account (you can re-establish ownership via a game)
  // @param _game - the # of the game which holds this account
  function unlinkCryptoAccount(uint _game)
    external
  returns(bytes32 inGameAccount) {
    address sender = _msgSender();
    inGameAccount = cryptoToGame[_game][sender];
    // require(inGameAccount != sender, "can't un-merge an automatically created account");
    require(inGameAccount != bytes32(0), "can't un-merge a null account");

    _unlinkCryptoAccount(_game, sender, inGameAccount);
  }

  function _unlinkCryptoAccount(uint _game, address _cryptoAccount, bytes32 _inGameAccount)
    internal
  {
    require(cryptoToGame[_game][_cryptoAccount] == _inGameAccount, "account must be linked");
    delete gameToCrypto[_game][_inGameAccount];
    delete cryptoToGame[_game][_cryptoAccount];

    // Remove pointer and game list entry;
    uint pointer = gamesLinkedToCryptoPointers[_game][_cryptoAccount];
    uint[] storage gamesLink = gamesLinkedToCrypto[_cryptoAccount];
    uint newLength = gamesLink.length.sub(1);
    uint otherGame = gamesLink[newLength];
    gamesLinkedToCryptoPointers[otherGame][_cryptoAccount] = pointer;
    gamesLink[pointer] = otherGame;
    delete gamesLinkedToCryptoPointers[_game][_cryptoAccount];
    gamesLink.pop();
    emit AccountUnlinked(_game, _inGameAccount, _cryptoAccount);
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

  function getCurrentLevel(uint tokenId)
    public
    view
  returns(uint level) {
    level = _calculateCollectibleLevel(getCurrentXP(tokenId));
  }

  function getCurrentXP(uint tokenId)
    public
    view
  returns(uint xp) {
    (uint storedXp, uint xpPerHour, uint creationTime) = parseCollectibleData(collectibleData[tokenId]);
    xp = storedXp + (block.timestamp.sub(creationTime)).div(3600).mul(xpPerHour);
  }

  function encodeCollectibleData(uint xp, uint xpPerHour, uint creationTime)
    public
    pure
  returns(uint encodedData) {
    // Encoded as creationTime (32 bits, merges (96 bits), xp (128 bits))
    require(uint(uint128(xp)) == xp, "no xp overflow");
    require(uint(uint96(xpPerHour)) == xpPerHour, "no xpPerHour overflow");
    require(uint(uint32(creationTime)) == creationTime, "no creationTime overflow");
    encodedData = creationTime|(xpPerHour<<32)|(xp<<128);
  }

  function parseCollectibleData(uint _collectibleData)
    public
    pure
  returns(uint xp, uint xpPerHour, uint creationTime) {
    xp = uint(_collectibleData>>128);
    xpPerHour = uint(uint96(_collectibleData>>32));
    creationTime = uint(uint32(_collectibleData));
  }

  function getCollectibleData(uint tokenId)
    public
    view
  returns(uint xp, uint xpPerHour, uint creationTime) {
    return parseCollectibleData(collectibleData[tokenId]);
  }

  // @dev creates an collectible, saving its initial xp, timestamp, etc.
  function generateCollectible(uint tokenId, uint xp, uint xpPerHour, uint creationTime)
    external
    override
    onlyLocalContract
  {
    require(collectibleData[tokenId] == 0, "must not be an collectible here");
    require(xp > 0, "must have at least 1 base xp");
    require(xpPerHour > 0, "must have at least 1 xpPerHour");
    require(creationTime > 0, "must have a creationTime");
    _storeCollectibleData(tokenId, xp, xpPerHour, creationTime);
  }

  function workerAddXpToCollectible(uint tokenId, uint xpToAdd)
    external
    workerOrMinion
  {
    (uint currentXp, uint xpPerHour, uint creationTime) = getCollectibleData(tokenId);
    require(currentXp > 0, "collectible must exist & already have some XP");
    require(xpToAdd > 0, "must add at least 1 xp");
    uint newXp = currentXp.add(xpToAdd);
    emit CollectibleXpAdded(tokenId, xpToAdd, newXp);
    _storeCollectibleData(tokenId, newXp, xpPerHour, creationTime);
  }

  function workerResetCollectible(uint tokenId, uint newXp, uint newXpPerHour, uint newBirthTime)
    external
    workerOrMinion
  {
    (uint currentXp, uint xpPerHour, uint creationTime) = getCollectibleData(tokenId);
    require(currentXp > 0, "collectible must exist & already have some XP");
    require(newXp > 0, "must have at least 1 base xp");
    require(newXpPerHour > 0, "must have at least 1 xpPerHour");
    require(newBirthTime > 0, "must have a creationTime");
    emit CollectibleReset(tokenId, currentXp, xpPerHour, creationTime);
    _storeCollectibleData(tokenId, newXp, newXpPerHour, newBirthTime);
  }

  // Merges collectibles if they're all owned by the same user
  // Keeps the oldest collectible; combines xpPerHour and XP of the rest
  // Respects tradelock - you can merge into a tradelocked collectible, but you can't merge away one
  function workerMergeCollectibles(uint[] calldata collectibles)
    external
    workerOrMinion
  {
    require(collectibles.length > 1, "must be at least 2 collectibles to merge");
    uint tokenId = collectibles[0];
    (uint xp, uint xpPerHour, uint creationTime) = getCollectibleData(tokenId);
    uint champion1 = uint256(uint64(tokenId>>64));
    uint card1 = uint256(uint64(tokenId>>128));
    // merges all the collectibles into the first one (sort in ascending numeric order)
    // for each collectible in the group, get the xp and combine it
    // add together each collectible's xpPerHour
    uint newXp = xp;
    for(uint i = 1; i < collectibles.length; i++) {
      for (uint j = 0; j < i; j++) {
        require(collectibles[i] != collectibles[j], "collectible IDs must all be different");
      }
      require(uint256(uint64(collectibles[i]>>64)) == champion1, "champion ID must match");
      require(uint256(uint64(collectibles[i]>>128)) == card1, "card ID must match");

      require(indexToOwner[tokenId] == indexToOwner[collectibles[i]], "must be owned by the same user");
      (uint i_Xp, uint i_XpPerHour, uint i_creationTime) = getCollectibleData(collectibles[i]);
      newXp = newXp.add(i_Xp);
      xpPerHour = xpPerHour.add(i_XpPerHour);
      if(i_creationTime < creationTime) {
        _burn(tokenId, true); // transfer away the previous collectible
        creationTime = i_creationTime; // update the tracked creationTime
        emit CollectibleMerged(collectibles[i], tokenId, xp);
        tokenId = collectibles[i]; // update the tracked collectible Id
      } else {
        _burn(collectibles[i], true); // transfer away this collectible
        collectibleData[tokenId] = 0; // clear this collectible's data
        emit CollectibleMerged(tokenId, collectibles[i], i_Xp);
      }
    }
    _storeCollectibleData(tokenId, newXp, xpPerHour, creationTime);
  }

  function _calculateCollectibleLevel(uint _xp)
    internal
    pure
  returns(uint level) {
    uint xp = _xp;
    while(xp > 0) {
      level++;
      xp = xp.div(2);
    }
  }

  function _storeCollectibleData(uint tokenId, uint xp, uint xpPerHour, uint creationTime)
    internal
  {
    collectibleData[tokenId] = encodeCollectibleData(xp, xpPerHour, creationTime);
    emit CollectibleDataUpdated(tokenId, xp, xpPerHour, creationTime);
  }

  // @dev Assigns ownership of a specific token to an in-game address.
  function _burn(uint _tokenId, bool shouldCheckTransferTime)
    internal
    isValidToken(_tokenId)
  {
    // reduce the supply
    gameContract.burnToken(_tokenId);
    _uncheckedTransfer(bytes32(0), _tokenId, shouldCheckTransferTime);
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
  // @param _masterContract - address of the master contract
  //  between 0-10,000.
  constructor(address masterContract_)
    NetworkAgnostic(CONTRACT_ERC712_NAME, CONTRACT_ERC712_VERSION)
  {
    masterContract = iGAME_Master(masterContract_);
    localContracts[masterContract_] = true;
  }

  function transferNewToken(bytes32 _recipient, uint _tokenId, uint _tradeLockTime)
    external
    override
    onlyLocalContract
  {
    indexToTradableTime[_tokenId] = _tradeLockTime;
    _uncheckedTransfer(_recipient, _tokenId, false);
  }

  function auctionTransfer(address _from, address _to, uint _tokenId)
    external
    override
    onlyLocalContract
  {
    address cryptoOwner = getCryptoAccount(uint256(uint64(_tokenId)), indexToOwner[_tokenId]);
    require(cryptoOwner == _from, "owner must be from address");

    _externalTransfer(_to, _tokenId);
  }

  function revokeToken(uint _game, uint _tokenId, bytes32 _purchaseId)
    external
    override
    onlyLocalContract
  returns (bool _isRevoked) {
    bytes32 _currentOwner = indexToOwner[_tokenId];
    if(block.timestamp < indexToTradableTime[_tokenId] && _currentOwner != bytes32(0)) {
      _internalTransfer(bytes32(0), _tokenId, false);
      _isRevoked = true;
      emit TokenRevoked(_game, _tokenId, _currentOwner, _purchaseId);
    }
  }
}