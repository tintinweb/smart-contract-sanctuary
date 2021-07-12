/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.7.0;
// SPDX-License-Identifier: UNLICENSED




/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface iERC20 {
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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// @title GAME_MasterAccess
// @dev The contract module that allows a contract to be controlled
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract GAME_MasterAccess is WorkerMetaTransactions, iGAME_Master {
  using SafeMath for uint256;

  // This facet controls access control for the dAPP There are three roles managed here, and this is
  // the recommended usage of each role:
  //
  //     - The Owner: The Owner can reassign other roles and change the addresses of our dependent smart
  //         contracts. It should be initialy set to the address that created the smart contract that
  //         implements this. (set this in the contract constructor).
  //     - The CFO: The CFO can withdraw funds from the contracts, but cannot assign roles, or perform
  //         any operational tasks.
  //     - The COO: The COO can perform operational tasks, but cannot withdraw funds, and cannot
  //         assign roles. (set this in the contract constructor).
  //
  // Different addresses should be set for each role, to maximize security here. Each role is independent
  // and has no overlap overlap in their access abilities. In particular, while the Owner can assign any
  // address to any role, the Owner address itself doesn't have the ability to act in those roles. This
  // restriction is intentional, to minimize the use of addresses.

  event OwnershipTransferred(address previousOwner, address newOwner);

  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public owner;
  address public cfoAddress;
  address public cooAddress;
  address public recoveryAddress;
  iGAME_Game public gameContract;
  iGAME_ERC20 public erc20Contract;
  iGAME_ERC721 public erc721Contract;
  mapping(address => bool) public localContracts;
  iLocalContract[] public activeLocalContracts;


  // @dev The GAME_MasterAccess constructor sets the original `owner` of the contract to the sender
  //  account.
  constructor()
  {
    address sender = _msgSender();
    cooAddress = sender;
    owner = sender;
  }

  // @dev Access modifier for Owner-only functionality
  modifier onlyOwner() {
    require(_msgSender() == owner, "must be owner");
    _;
  }

  // @dev Access modifier for CFO-only functionality
  modifier onlyCFO() {
    require(_msgSender() == cfoAddress, "must be cfo");
    _;
  }

  // @dev Access modifier for COO-only functionality
  modifier onlyCOO() {
    require(_msgSender() == cooAddress, "must be coo");
    _;
  }

  // @dev Access modifier for Server-only functionality
  modifier onlyRecovery() {
    require(_msgSender() == recoveryAddress, "must be recovery");
    _;
  }

  modifier onlyLocalContract() {
    // Cannot be called using native meta-transactions
    require(localContracts[msg.sender], "must be local");
    _;
  }

  function isOwner(address owner_)
    external
    override
    view
  returns(bool) {
    return owner_ != address(0) && owner_ == owner;
  }

  function isCFO(address cfo_)
    external
    override
    view
  returns(bool) {
    return cfo_ != address(0) && cfo_ == cfoAddress;
  }

  function isCOO(address coo_)
    external
    override
    view
  returns(bool) {
    return coo_ != address(0) && coo_ == cooAddress;
  }

  // @dev Assigns a new address to act as the Owner. Only available to the current owner account.
  // @param newOwner_ The address of the new Owner
  function setOwner(address newOwner_)
    external
    onlyRecovery
  {
    require(newOwner_ != address(0), "0 address");
    require(newOwner_ != cooAddress, "coo");
    require(newOwner_ != cfoAddress, "cfo");
    require(newOwner_ != recoveryAddress, "recovery");

    emit OwnershipTransferred(owner, newOwner_);
    owner = newOwner_;
  }

  // @dev Assigns a new address to act as the CFO. Only available to the current Owner.
  // @param newCFO_ The address of the new CFO
  function setCFO(address newCFO_)
    external
    onlyOwner
  {
    require(newCFO_ != address(0), "address(0)");
    require(newCFO_ != owner, "owner");
    require(newCFO_ != cooAddress, "coo");
    require(newCFO_ != recoveryAddress, "recovery");

    cfoAddress = newCFO_;
  }

  // @dev Assigns a new address to act as the COO. Only available to the current Owner.
  // @param newCOO_ The address of the new COO
  function setCOO(address newCOO_)
    external
    onlyOwner
  {
    require(newCOO_ != address(0), "address(0)");
    require(newCOO_ != owner, "owner");
    require(newCOO_ != cfoAddress, "cfo");
    require(newCOO_ != recoveryAddress, "recovery");

    cooAddress = newCOO_;
  }

  // @dev Assigns a new address to act as the Recovery address. Only available to the current Owner.
  // @param newRecovery_ The address of the new Recovery account
  function setRecovery(address newRecovery_)
    external
    onlyOwner
  {
    require(newRecovery_ != address(0), "address(0)");
    require(newRecovery_ != owner, "owner");
    require(newRecovery_ != cfoAddress, "cfo");
    require(newRecovery_ != cooAddress, "coo");

    recoveryAddress = newRecovery_;
  }
}




// @title Minion Manager
// @dev Contract for managing minions for other contracts in the GAME ecosystem
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract iMinionManager {

  function isMinion(address account_) virtual external view returns(bool);
  function isWorker(address account_) virtual external view returns(bool);
  function isWorkerOrMinion(address account_) virtual external view returns(bool);

  function getMinionGroup(bytes32 groupId_) virtual external view returns(address[] memory);
  function addMinionGroup(bytes32 groupId_, address[] calldata minionList_) virtual external;
  function removeMinionGroup(bytes32 groupId_) virtual external;

  function assignWorker(address worker_, bool isWorker_) virtual external returns(bool);

  function isMinionManager()
    external
    pure
  returns(bool) {
    return true;
  }
}

// @title GAME Credits Master Minions
// @dev GAME_Master contract for managing minion and worker funds
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract GAME_MasterMinions is GAME_MasterAccess {

  iMinionManager public minionManager;

  event GasRefillLevels(uint gasRefillLevel, uint gasGrantAmount);
  event MinionManagerAssigned(address minionManager);

  event MinionsAdded(address indexed minionManager, bytes32 indexed groupId, address[] minions);
  event MinionsRemoved(address indexed minionManager, bytes32 indexed groupId, address[] minions);

  event WorkerAssignment(address indexed minionManager, address worker, bool isWorker);

  // Gas Grant Amount
  uint public gasGrantAmount;

  // Gas Refill Level
  uint public gasRefillLevel;

  constructor()
  {
    uint refillLevel = 10**17;
    uint grantAmount = refillLevel * 2;
    setGasRefillLevels(refillLevel, grantAmount);
  }

  modifier onlyWorker() {
    require(minionManager.isWorker(_msgSender()), "is worker");
    _;
  }

  modifier onlyWorkerOrMinion() {
    address sender = _msgSender();
    bool accountIsWorker = minionManager.isWorkerOrMinion(sender);
    if(accountIsWorker && gasGrantAmount > 0 && sender.balance < gasRefillLevel) {
      // if yes, check for funding, and deliver if necessary and possible.
      address(uint160(sender)).transfer(gasGrantAmount);
    }
    require(accountIsWorker, "worker or minion");
    _;
  }

  function isMinion(address account_)
    external
    view
  returns(bool) {
    return minionManager.isMinion(account_);
  }

  function isWorker(address account_)
    external
    override
    view
  returns(bool) {
    return minionManager.isWorker(account_);
  }

  function isWorkerOrMinion(address account_)
    external
    override
    view
  returns(bool) {
    return minionManager.isWorkerOrMinion(account_);
  }


  function setGasRefillLevels(uint gasRefillLevel_, uint gasGrantAmount_)
    public
    onlyCOO
  {
    require(gasGrantAmount_ >= gasRefillLevel_, "grant < refill level");
    gasGrantAmount = gasGrantAmount_;
    gasRefillLevel = gasRefillLevel_;
    emit GasRefillLevels(gasRefillLevel_, gasGrantAmount_);
  }

  function withdrawGas(uint amount)
    external
    onlyCFO
  {
    address payable sender = _msgSender();
    sender.transfer(amount);
  }


  function makeFundedCall(address account_)
    external
    override
    onlyLocalContract
  returns(bool accountIsWorker) {
    return _makeFundedCall(account_);
  }

  function _makeFundedCall(address account_)
    internal
  returns(bool accountIsWorker) {
    accountIsWorker = minionManager.isWorkerOrMinion(account_);
    if(accountIsWorker && gasGrantAmount > 0 && account_.balance < gasRefillLevel) {
      // if yes, check for funding, and deliver if necessary and possible.
      address(uint160(account_)).transfer(gasGrantAmount);
    }
  }

  function metaTxSenderIsWorkerOrMinion()
    internal
    override
  returns (bool) {
    return _makeFundedCall(msg.sender);
  }

  function setMinionManager(iMinionManager minionManager_)
    external
    onlyCOO
  {
    require(minionManager_.isMinionManager(), "is iMinionManager");
    minionManager = minionManager_;
    emit MinionManagerAssigned(address(minionManager_));
  }

  function assignWorker(address worker_, bool isWorker_)
    external
    onlyCOO
  {
    address[] memory addressList = new address[](1);
    addressList[0] = worker_;
    if(minionManager.assignWorker(worker_, isWorker_)) {
      if(isWorker_) {
        _initializeFunds(addressList);
      }
      emit WorkerAssignment(address(minionManager), worker_, isWorker_);
    }
  }

  function getMinionGroup(bytes32 groupId_)
    external
    view
  returns(address[] memory minionList)
  {
    return minionManager.getMinionGroup(groupId_);
  }

  function addMinionGroup(bytes32 groupId_, address[] calldata minionList_)
    external
    onlyWorker
  {
    minionManager.addMinionGroup(groupId_, minionList_);
    emit MinionsAdded(address(minionManager), groupId_, minionList_);
    _initializeFunds(minionList_);
  }


  function removeMinionGroup(bytes32 groupId_)
    external
    onlyWorker
  {
    address[] memory minionList = minionManager.getMinionGroup(groupId_);

    minionManager.removeMinionGroup(groupId_);
    emit MinionsRemoved(address(minionManager), groupId_, minionList);
  }

  // Funding Methods
  // ===============

  function _initializeFunds(address[] memory accountList_)
    internal
  {
    for(uint i = 0; i < accountList_.length; i++) {
      if(gasGrantAmount > 0) {
        address(uint160(accountList_[i])).transfer(gasGrantAmount);
      }
    }
  }
}


// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract GAME_GameTokens is GAME_MasterMinions {
  using SafeMath for uint256;

  mapping(bytes32 => bool) public buyCollectibleOracleHashes;
  mapping(uint => mapping(uint => bool)) public collectibleIsOnSale;

  event TokenCreated(uint indexed game, uint indexed tokenId, bytes32 purchaseId, uint tradeLock);
  
  event TokenJsonUpdated(uint indexed game, uint indexed tokenId, string tokenJson);
  event TokenFeePoints(uint tokenFeePoints);

  uint public buyTokenFeePoints;

  // The purchaseId mapping allows game operators to refer back to objects granted by a specific purchase
  // uint is the game, bytes32 is the purchaseId (recommend the hash of the Apple/Google/Steam receipt)
  // uint[] is the array of token Ids granted by this purchase.
  mapping(uint => mapping(bytes32 => uint[])) public purchaseIdtoTokenIds;

  modifier tokenIsForGame(uint game_, uint tokenId_) {
    require(uint256(uint64(tokenId_)) == game_, "token for game");
    _;
  }

  modifier operatorOrMinion(uint game_) {
    address sender = _msgSender();
    require(gameContract.isValidCaller(
        sender, 
        _makeFundedCall(sender), 
        game_
      ),
      "admin, operator, or worker");
    _;
  }

  constructor() {
    uint feePoints = 2000;
    buyTokenFeePoints = feePoints;
    emit TokenFeePoints(feePoints);
  }

  function updateTokenFeePoints(uint feePoints_)
    external
    onlyCOO
  {
    require(feePoints_ <= 10000);
    buyTokenFeePoints = feePoints_;
    emit TokenFeePoints(feePoints_);
  }

  function parseTokenId(uint tokenId_)
    public
    pure
  returns(uint game, uint set, uint card, uint token) {
    game = (uint256(uint64(tokenId_)));
    set = (uint256(uint64(tokenId_>>64)));
    card = (uint256(uint64(tokenId_>>128)));
    token = (uint256(tokenId_>>192));
  }

  // @dev Can be called by any user, to buy a token from a game with a cryptocurrency.
  // @notice If you want to add specialized metadate, use transferAndCall to your own
  //   smart contract that has Operator privileges
  // @param game_ - the # of the game that the token comes from
  // @param set_ - the # of the set within the game that the token comes from
  // @param card_ - the # of the card to grant a token copy of
  // @param price_ - the list price, in tokens, of that token (must be non-zero)
  function buyToken(uint game_, uint set_, uint card_, uint price_)
    external
  returns(uint tokenId_) {
    require(gameContract.getCardPrice(game_, set_, card_) == price_, "paid == list price");
    require(price_ > 0, "price > 0");
    require(price_ < 10**40, "price overflow");
    address sender = _msgSender();
    address seller = game_ == 0 ? (set_ == 0 ? address(erc20Contract) : address(set_)) : address(game_);
    bytes32 inGameAccount = erc721Contract.getOrCreateInGameAccount(game_, sender);
    erc20Contract.transferByContract(
      sender,
      seller,
      price_
    );
    if(seller != address(erc20Contract)) {
      uint fee = price_.mul(buyTokenFeePoints).div(10000);
      erc20Contract.transferByContract(
        seller,
        address(erc20Contract),
        fee
      );

    }
    tokenId_ = _grantToken(inGameAccount, game_, set_, card_, bytes32(uint(-1)));
  }

  // @dev Can be called by any user, to buy a token from a game with a cryptocurrency.
  // @notice If you want to add specialized metadate, use transferAndCall to your own
  //   smart contract that has Operator privileges
  // @param game_ - the # of the game that the token comes from
  // @param set_ - the # of the set within the game that the token comes from
  // @param card_ - the # of the card to grant a token copy of
  // @param price_ - the list price, in tokens, of that token (must be non-zero)
  function buyTokenWithLoyalty(uint game_, uint set_, uint card_, uint loyaltyPrice_)
    external
  returns(uint tokenId_) {
    address sender = _msgSender();
    require(gameContract.getCardLoyaltyPrice(game_, set_, card_) == loyaltyPrice_, "price == list price");
    require(loyaltyPrice_ > 0, "price > 0");
    bytes32 inGameAccount = erc721Contract.getOrCreateInGameAccount(game_, sender);
    erc20Contract.thirdPartySpendLoyaltyPoints(game_ == 0 ? set_ : game_, sender, loyaltyPrice_);

    tokenId_ = _grantToken(inGameAccount, game_, set_, card_, bytes32(uint(-1)));
  }

  function _grantToken(bytes32 inGameAccount, uint game_, uint set_, uint card_, bytes32 purchaseId_)
    internal
  returns(uint tokenId_) {
    uint fixedXp;
    (tokenId_, fixedXp) = _createToken(inGameAccount, game_, set_, card_, purchaseId_);

    if(game_ == 0) {
      require(collectibleIsOnSale[set_][card_], "collectible must be on sale");
      _buyCollectible(tokenId_, fixedXp, 0, block.timestamp);
    }
  }

  function _buyCollectible(uint tokenId_, uint fixedXp_, uint xpPerHour_, uint creationTime_) 
    internal
  {
    uint xp;
    if(fixedXp_ == 0) {
      // 1-9 = common xp 1=1; 9=256+
      // 10-14 = uncommon 10=512+ 14=8192+
      // 15-17 = rare 15=16384+ 17=65536+
      // 18-19 = epic 18=131072+ 19=262144+
      // 20+ = legendary 20=524288+

      uint token = uint256(tokenId_>>192);
      uint rand = uint(keccak256(abi.encode(tokenId_, block.timestamp)));
      uint randUint16 = uint(uint16(rand));// hash the tokenId and now
      uint randUint16b = uint(uint16(rand>>16));
      uint maxBonus = 30;
      if(token < maxBonus) {
        randUint16 = randUint16.div(maxBonus.sub(token));
      }
      if(randUint16 < 656) { // 1% chance of legendary (12% for the first, 6% for the 8th)
        xp = 524288 + randUint16b.mul(8);
        xpPerHour_ = 16;
      } else if (randUint16 < 2623) { // 3% chance of epic (38% for first, 19% for the 8th)
        xp = 131072 + randUint16b.mul(4);
        xpPerHour_ = 8;
      } else if (randUint16 < 9177) { // 10% chance of rare (50% for first, 75% for 8th)
        xp = 16384 + randUint16b;
        xpPerHour_ = 4;
      } else if (randUint16 < 25561) { // 25% chance of uncommon (0% for first 8)
        xp = 512 + randUint16b.div(8);
        xpPerHour_ = 2;
      } else { // 63% chance of common
        xp = 1 + randUint16b.div(256);
        xpPerHour_ = 1;
      }
    } else {
      xp = fixedXp_;
    }

    erc721Contract.generateCollectible(tokenId_, xp, xpPerHour_, creationTime_);
  }

  function workerBuyCollectible(
    bytes32 purchaseId_,
    address purchaser_,
    uint partnerId_,
    uint card_,
    uint xp_,
    uint xpPerHour_,
    uint creationTime_,
    uint loyaltySpend_,
    bool isOraclePurchase_
  )
    external
    onlyWorkerOrMinion()
  {
    if(isOraclePurchase_) {
      require(purchaseId_ != bytes32(0), "hash can't be zero");
      if(buyCollectibleOracleHashes[purchaseId_]) {
        return;
      }
      buyCollectibleOracleHashes[purchaseId_] = true;
      purchaseId_ = bytes32(uint(-1));
    }
    _workerBuyCollectible(
      purchaseId_,
      purchaser_,
      partnerId_,
      card_,
      xp_,
      xpPerHour_,
      creationTime_
    );

    // take loyalty payment if necessary
    if(loyaltySpend_ > 0) {
      erc20Contract.thirdPartySpendLoyaltyPoints(partnerId_, purchaser_, loyaltySpend_);
    }
  }

  function _workerBuyCollectible(
    bytes32 purchaseId_,
    address purchaser_,
    uint partnerId_,
    uint card_,
    uint xp_,
    uint xpPerHour_,
    uint creationTime_
  )
    internal
  {
    bytes32 inGameAccount = erc721Contract.getOrCreateInGameAccount(0, purchaser_);
    // Create the token, and transfer it to the user
    (uint tokenId, uint fixedXp) = _createToken(inGameAccount, 0, partnerId_, card_, purchaseId_);

    // if there's a fixed XP, we need to ensure it matches
    if(fixedXp > 0) {
      require(xp_ == fixedXp, "xp == fixed XP");
      require(xpPerHour_ == 0, "XP per hour == 0");
    }

    // store collectible based on token ID
    require(collectibleIsOnSale[partnerId_][card_], "collectible must be on sale");
    _buyCollectible(tokenId, xp_, xpPerHour_, creationTime_);

  }

  function updateCollectibleSaleStatus(uint game_, uint card_, bool isOnSale_)
    external
    override
    onlyLocalContract
  {
    collectibleIsOnSale[game_][card_] = isOnSale_;
  }

  function updateTokenJson(uint game_, uint tokenId_, string calldata tokenJson_)
    external
    operatorOrMinion(game_)
    tokenIsForGame(game_, tokenId_)
  {
    emit TokenJsonUpdated(game_, tokenId_, tokenJson_);
  }

  function revokeTokensByPurchaseId(uint game_, bytes32 purchaseId_)
    external
    operatorOrMinion(game_)
  returns(uint[] memory _tokenIds) {
    uint[] storage tokensToRevoke = purchaseIdtoTokenIds[game_][purchaseId_];
    require(tokensToRevoke.length > 0, "revok 1+ tokens");
    _tokenIds = new uint[](tokensToRevoke.length);
    bool isOneRevoked;
    for (uint i = 0; i < tokensToRevoke.length; i++) {
      uint tokenId = tokensToRevoke[i];
      if(erc721Contract.revokeToken(game_, tokenId, purchaseId_)) {
        _tokenIds[i] = tokenId;
        isOneRevoked = true;
      }
    }
    require(isOneRevoked, "revoked at least one");
  }

  function revokeOffChainPurchasedToken(uint game_, uint tokenId_)
    external
    operatorOrMinion(game_)
    tokenIsForGame(game_, tokenId_)
  returns (uint tokenId) {
    if(erc721Contract.revokeToken(game_, tokenId_, bytes32(0))) {
      tokenId = tokenId_;
    }
  }

  // @dev Gets the list of tokenIds created by a given transaction
  // @param game_ - the # of the game that the token comes from
  // @param purchaseId_ - the Id of the purchase that created this token (for real money purchase ONLY)
  //   Pass the hash of the Apple/Google/Steam receipt, or similar
  function getTokenIdsFromPurchaseId(uint game_, bytes32 purchaseId_)
    external
    view
  returns (uint[] memory tokenIds) {
    return purchaseIdtoTokenIds[game_][purchaseId_];
  }

  // @dev Grants a group of tokens from a group of base cards, using the cards' metadata (if any)
  // @param recipient_ - the account who will own this token on creation
  // @param game_ - the # of the game that the token comes from
  // @param set_ - the # of the set within the game that the token comes from
  // @param cards_ - the array of card #s of the card within the set to grant
  // @param purchaseId_ - the Id of the purchase that created this token (for real money purchase ONLY)
  //   Pass the hash of the Apple/Google/Steam receipt, or similar
  function grantTokensFromCards(
    bytes32 recipient_, uint game_, uint set_, uint[] calldata cards_,
    bytes32 purchaseId_)
    external
    operatorOrMinion(game_)
  returns(uint[] memory _tokenIds) {
    _tokenIds = new uint[](cards_.length);
    for (uint i = 0; i < cards_.length; i++) {
      _tokenIds[i] = _grantToken(recipient_, game_, set_, cards_[i], purchaseId_);
    }
  }


  // @dev Internal function to perform the token creation
  // @param recipient_ - the account who will own this token on creation
  // @param game_ - the # of the game that the token comes from
  // @param set_ - the # of the set within the game that the token comes from
  // @param card_ - the # of the card within the set that the token comes from
  // @param purchaseId_ - the Id of the purchase that created this token (for real money purchase ONLY)
  //   Pass the hash of the Apple/Google/Steam receipt, or similar
  // @param _tokenData - any metadata you want to store as part of the token transaction
  function _createToken(
    bytes32 recipient_,
    uint game_,
    uint set_,
    uint card_,
    bytes32 purchaseId_
  )
    internal
  returns (uint tokenId_, uint _fixedXp) {
    uint tradeLockTime;
    (tokenId_, tradeLockTime, _fixedXp) = gameContract.createTokenFromCard(game_, set_, card_);

    // Lock the card from transfers if it was bought off-chain
    // Supports management actions for reverting fraudulent off-chain purchases
    if (purchaseId_ != bytes32(uint(-1))) {
      tradeLockTime = block.timestamp.add(tradeLockTime);
      if(purchaseId_ != bytes32(0)) {
        purchaseIdtoTokenIds[game_][purchaseId_].push(tokenId_);
      }
    } else {
      tradeLockTime = 0;
    }

    emit TokenCreated(game_, tokenId_, purchaseId_, tradeLockTime);

    // Assign ownership, and also emit the Transfer event as per ERC721 draft
    erc721Contract.transferNewToken(
      recipient_,
      tokenId_,
      tradeLockTime);
  }
}

// @title GAME Credits Master
// @dev GAME_Master contract for managing ERC-20 and ERC-721 integration with the GAME ecosystem
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
contract GAME_Master is GAME_GameTokens {

  string constant public CONTRACT_ERC712_VERSION = "1";
  string constant public CONTRACT_ERC712_NAME = "GAME Credits Sidechain Master Contract";

  constructor()
    NetworkAgnostic(CONTRACT_ERC712_NAME, CONTRACT_ERC712_VERSION)
  {

  }

  function linkContracts(address gameContract_, address erc20Contract_, address erc721Contract_)
    external
    onlyOwner
  {
    require (address(gameContract) == address(0), "game == address(0)");
    require (address(erc20Contract) == address(0), "erc20 == address(0)");
    require (address(erc721Contract) == address(0), "erc721 == address(0)");
    _updateLocalContract(gameContract_, true);
    _updateLocalContract(erc721Contract_, true);
    _updateLocalContract(erc20Contract_, true);
    gameContract = iGAME_Game(gameContract_);
    erc20Contract = iGAME_ERC20(erc20Contract_);
    erc721Contract = iGAME_ERC721(erc721Contract_);
    gameContract.linkContracts(erc721Contract_, erc20Contract_);
    erc20Contract.linkContracts(gameContract_, erc721Contract_);
    erc721Contract.linkContracts(gameContract_, erc20Contract_);
  }

  // @dev Cancels an auction.
  //  Only the manager may do this, and NFTs are returned to
  //  the seller. This should only be used in emergencies.
  // @param tokenId_ - Id of the NFT on auction to cancel.
  function cancelAuctionByManager(uint tokenId_)
    external
    onlyCOO
  {
    erc20Contract.cancelAuctionByManager(tokenId_);
  }

  // @dev Transfers gained GAME from the contract to the CFO
  // @notice Does NOT transfer tokens from the erc20contract itself; that holds
  //    the staking balances
  function transferGAMEtoCFO()
    external
    onlyCFO
  {
    uint balance = iERC20(address(erc20Contract)).balanceOf(address(this));
    erc20Contract.transferByContract(
      address(this),
      cfoAddress,
      balance);
    balance = iERC20(address(erc20Contract)).balanceOf(address(erc721Contract));
    erc20Contract.transferByContract(
      address(erc721Contract),
      cfoAddress,
      balance);
  }

  function getActiveLocalContracts()
    external
    view
  returns(address[] memory) {
    address[] memory returnAddresses = new address[](activeLocalContracts.length);
    for(uint i = 0; i < activeLocalContracts.length; i++) {
      returnAddresses[i] = address(activeLocalContracts[i]);
    }
    return returnAddresses;
  }

  function updateLocalContract(address contract_, bool isLocal_)
    external
    override
    onlyOwner
  {
    _updateLocalContract(contract_, isLocal_);
  }

  function _updateLocalContract(address contract_, bool isLocal_)
    internal
  {
    require(contract_ != address(this), "this");
    require(contract_ != address(erc721Contract), "erc721");
    require(contract_ != address(erc20Contract), "erc20");
    require(contract_ != address(gameContract), "amecontract");
    require(contract_ != address(0), "address(0)");
    require(localContracts[contract_] != isLocal_, "already local");
    iLocalContract localContract = iLocalContract(contract_);
    require(localContract.isLocalContract(), "isLocalContract()");
    localContracts[contract_] = isLocal_;

    if(isLocal_) {
      for (uint i = 0; i < activeLocalContracts.length; i++) {
        activeLocalContracts[i].updateLocalContract(contract_, isLocal_);
        localContract.updateLocalContract(address(activeLocalContracts[i]), isLocal_);
      }
      activeLocalContracts.push(localContract);
    } else {
      for (uint i = 0; i < activeLocalContracts.length - 1; i++) {
        if(activeLocalContracts[i] == localContract) {
          activeLocalContracts[i] = activeLocalContracts[activeLocalContracts.length - 1];
        }
        activeLocalContracts[i].updateLocalContract(contract_, isLocal_);
        localContract.updateLocalContract(address(activeLocalContracts[i]), isLocal_);
      }
      activeLocalContracts.pop();
    }
  }

  // Fallback function is required to receive Matic gas
  receive() external payable {
      // React to receiving ether
  }

  // Fallback function is required to receive Matic gas
  fallback() external payable {
      // React to receiving ether
  }
}