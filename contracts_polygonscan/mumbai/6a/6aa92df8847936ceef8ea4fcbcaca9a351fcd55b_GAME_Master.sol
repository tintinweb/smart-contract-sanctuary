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

  function getCardPrice(uint _game, uint _set, uint _card) virtual external view returns(uint256);
  function getCardLoyaltyPrice(uint _game, uint _set, uint _card) virtual external view returns(uint256);
  function isGameAdmin(uint _game, address _admin) virtual external view returns(bool);
  function linkContracts(address _erc721Contract, address _erc20Contract) virtual external;
  function isOperatorOrMinion(uint _game, address _sender) virtual external returns(bool);
  function isValidCaller(address account_, bool isMinion_, uint game_) virtual external view returns(bool isValid);
  function burnToken(uint _tokenId) virtual external;
  function createTokenFromCard(uint game_, uint set_, uint card_) virtual external returns(uint tokenId, uint tradeLockTime);
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
    require(_msgSender() == owner, "sender must be owner");
    _;
  }

  // @dev Access modifier for CFO-only functionality
  modifier onlyCFO() {
    require(_msgSender() == cfoAddress, "sender must be cfo");
    _;
  }

  // @dev Access modifier for COO-only functionality
  modifier onlyCOO() {
    require(_msgSender() == cooAddress, "sender must be coo");
    _;
  }

  // @dev Access modifier for Server-only functionality
  modifier onlyRecovery() {
    require(_msgSender() == recoveryAddress, "sender must be recovery");
    _;
  }

  modifier onlyLocalContract() {
    // Cannot be called using native meta-transactions
    require(localContracts[msg.sender], "sender must be a local contract");
    _;
  }

  function isOwner(address _owner)
    external
    override
    view
  returns(bool) {
    return _owner != address(0) && _owner == owner;
  }

  function isCFO(address _cfo)
    external
    override
    view
  returns(bool) {
    return _cfo != address(0) && _cfo == cfoAddress;
  }

  function isCOO(address _coo)
    external
    override
    view
  returns(bool) {
    return _coo != address(0) && _coo == cooAddress;
  }

  // @dev Assigns a new address to act as the Owner. Only available to the current owner account.
  // @param _newOwner The address of the new Owner
  function setOwner(address _newOwner)
    external
    onlyRecovery
  {
    require(_newOwner != address(0), "owner can't be 0 address");
    require(_newOwner != cooAddress, "owner can't be cooAddress");
    require(_newOwner != cfoAddress, "owner can't be cfo ");
    require(_newOwner != recoveryAddress, "owner can't be recovery");

    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  // @dev Assigns a new address to act as the CFO. Only available to the current Owner.
  // @param _newCFO The address of the new CFO
  function setCFO(address _newCFO)
    external
    onlyOwner
  {
    require(_newCFO != address(0), "cfo can't be address(0)");
    require(_newCFO != owner, "cfo can't be owner ");
    require(_newCFO != cooAddress, "cfo can't be coo ");
    require(_newCFO != recoveryAddress, "cfo can't be recovery ");

    cfoAddress = _newCFO;
  }

  // @dev Assigns a new address to act as the COO. Only available to the current Owner.
  // @param _newCOO The address of the new COO
  function setCOO(address _newCOO)
    external
    onlyOwner
  {
    require(_newCOO != address(0), "coo can't be address(0)");
    require(_newCOO != owner, "coo can't be owner ");
    require(_newCOO != cfoAddress, "coo can't be cfo ");
    require(_newCOO != recoveryAddress, "coo can't be recovery ");

    cooAddress = _newCOO;
  }

  // @dev Assigns a new address to act as the Recovery address. Only available to the current Owner.
  // @param _newRecovery The address of the new Recovery account
  function setRecovery(address _newRecovery)
    external
    onlyOwner
  {
    require(_newRecovery != address(0), "recovery can't be address(0)");
    require(_newRecovery != owner, "recovery can't be owner ");
    require(_newRecovery != cfoAddress, "recovery can't be cfo ");
    require(_newRecovery != cooAddress, "recovery can't be coo ");

    recoveryAddress = _newRecovery;
  }
}




// @title Minion Manager
// @dev Contract for managing minions for other contracts in the GAME ecosystem
// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract iMinionManager {

  function isMinion(address _account) virtual external view returns(bool);
  function isWorker(address _account) virtual external view returns(bool);
  function isWorkerOrMinion(address _account) virtual external view returns(bool);

  function getMinionGroup(bytes32 groupId) virtual external view returns(address[] memory);
  function addMinionGroup(bytes32 groupId, address[] calldata minionList) virtual external;
  function removeMinionGroup(bytes32 groupId) virtual external;

  function assignWorker(address _worker, bool _isWorker) virtual external returns(bool);

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
    require(minionManager.isWorker(_msgSender()), "sender must be a worker");
    _;
  }

  modifier onlyWorkerOrMinion() {
    address sender = _msgSender();
    bool accountIsWorker = minionManager.isWorkerOrMinion(sender);
    if(accountIsWorker && gasGrantAmount > 0 && sender.balance < gasRefillLevel) {
      // if yes, check for funding, and deliver if necessary and possible.
      address(uint160(sender)).transfer(gasGrantAmount);
    }
    require(accountIsWorker, "sender must be a worker or minion");
    _;
  }

  function isMinion(address _account)
    external
    view
  returns(bool) {
    return minionManager.isMinion(_account);
  }

  function isWorker(address _account)
    external
    override
    view
  returns(bool) {
    return minionManager.isWorker(_account);
  }

  function isWorkerOrMinion(address _account)
    external
    override
    view
  returns(bool) {
    return minionManager.isWorkerOrMinion(_account);
  }


  function setGasRefillLevels(uint _gasRefillLevel, uint _gasGrantAmount)
    public
    onlyCOO
  {
    require(_gasGrantAmount >= _gasRefillLevel, "Must grant more gas than the refill level");
    gasGrantAmount = _gasGrantAmount;
    gasRefillLevel = _gasRefillLevel;
    emit GasRefillLevels(_gasRefillLevel, _gasGrantAmount);
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

  function setMinionManager(iMinionManager _minionManager)
    external
    onlyCOO
  {
    require(_minionManager.isMinionManager(), "must implement iMinionManager");
    minionManager = _minionManager;
    emit MinionManagerAssigned(address(_minionManager));
  }

  function assignWorker(address _worker, bool _isWorker)
    external
    onlyCOO
  {
    address[] memory addressList = new address[](1);
    addressList[0] = _worker;
    if(minionManager.assignWorker(_worker, _isWorker)) {
      if(_isWorker) {
        _initializeFunds(addressList);
      }
      emit WorkerAssignment(address(minionManager), _worker, _isWorker);
    }
  }

  function getMinionGroup(bytes32 groupId)
    external
    view
  returns(address[] memory minionList)
  {
    return minionManager.getMinionGroup(groupId);
  }

  function addMinionGroup(bytes32 groupId, address[] calldata minionList)
    external
    onlyWorker
  {
    minionManager.addMinionGroup(groupId, minionList);
    emit MinionsAdded(address(minionManager), groupId, minionList);
    _initializeFunds(minionList);
  }


  function removeMinionGroup(bytes32 groupId)
    external
    onlyWorker
  {
    address[] memory minionList = minionManager.getMinionGroup(groupId);

    minionManager.removeMinionGroup(groupId);
    emit MinionsRemoved(address(minionManager), groupId, minionList);
  }

  // Funding Methods
  // ===============

  function _initializeFunds(address[] memory accountList)
    internal
  {
    for(uint i = 0; i < accountList.length; i++) {
      if(gasGrantAmount > 0) {
        address(uint160(accountList[i])).transfer(gasGrantAmount);
      }
    }
  }
}


// @author GAME Credits (gamecredits.org)
// (c) 2020 GAME Credits All Rights Reserved. This code is not open source.
abstract contract GAME_GameTokens is GAME_MasterMinions {
  using SafeMath for uint256;

  mapping(bytes32 => bool) public buyCollectibleOracleHashes;

  event TokenCreated(uint indexed game, uint indexed tokenId, bytes32 purchaseId, uint tradeLock);
  
  event TokenUriUpdated(uint indexed game, uint indexed tokenId, string tokenUri);
  event TokenJsonUpdated(uint indexed game, uint indexed tokenId, string tokenJson);
  event TokenFeePoints(uint tokenFeePoints);

  uint public buyTokenFeePoints;

  // The purchaseId mapping allows game operators to refer back to objects granted by a specific purchase
  // uint is the game, bytes32 is the purchaseId (recommend the hash of the Apple/Google/Steam receipt)
  // uint[] is the array of token Ids granted by this purchase.
  mapping(uint => mapping(bytes32 => uint[])) public purchaseIdtoTokenIds;

  modifier tokenIsForGame(uint _game, uint _tokenId) {
    require(uint256(uint64(_tokenId)) == _game, "token must be for this game");
    _;
  }

  modifier operatorOrMinion(uint game_) {
    address sender = _msgSender();
    require(gameContract.isValidCaller(
        sender, 
        _makeFundedCall(sender), 
        game_
      ),
      "sender must be an admin, operator, or worker");
    _;
  }

  constructor() {
    uint feePoints = 2000;
    buyTokenFeePoints = feePoints;
    emit TokenFeePoints(feePoints);
  }

  function updateTokenFeePoints(uint feePoints)
    external
    onlyCOO
  {
    require(feePoints <= 10000);
    buyTokenFeePoints = feePoints;
    emit TokenFeePoints(feePoints);
  }

  function parseTokenId(uint _tokenId)
    public
    pure
  returns(uint game, uint set, uint card, uint token) {
    game = (uint256(uint64(_tokenId)));
    set = (uint256(uint64(_tokenId>>64)));
    card = (uint256(uint64(_tokenId>>128)));
    token = (uint256(_tokenId>>192));
  }

  // @dev Can be called by any user, to buy a token from a game with a cryptocurrency.
  // @notice If you want to add specialized metadate, use transferAndCall to your own
  //   smart contract that has Operator privileges
  // @param _game - the # of the game that the token comes from
  // @param _set - the # of the set within the game that the token comes from
  // @param _card - the # of the card to grant a token copy of
  // @param _price - the list price, in tokens, of that token (must be non-zero)
  function buyToken(uint _game, uint _set, uint _card, uint _price)
    external
  returns(uint _tokenId) {
    require(gameContract.getCardPrice(_game, _set, _card) == _price, "paid price must equal list price");
    require(_price > 0, "purchase price must be >0");
    require(_price < 10**40, "price overflow");
    address sender = _msgSender();
    address seller = _game == 0 ? (_set == 0 ? address(erc20Contract) : address(_set)) : address(_game);
    bytes32 inGameAddress = erc721Contract.getOrCreateInGameAccount(_game, sender);
    erc20Contract.transferByContract(
      sender,
      seller,
      _price
    );
    if(seller != address(erc20Contract)) {
      uint fee = _price.mul(buyTokenFeePoints).div(10000);
      erc20Contract.transferByContract(
        seller,
        address(erc20Contract),
        fee
      );

    }
    _tokenId = _createToken(inGameAddress, _game, _set, _card, bytes32(uint(-1)));
  }

  // @dev Can be called by any user, to buy a token from a game with a cryptocurrency.
  // @notice If you want to add specialized metadate, use transferAndCall to your own
  //   smart contract that has Operator privileges
  // @param _game - the # of the game that the token comes from
  // @param _set - the # of the set within the game that the token comes from
  // @param _card - the # of the card to grant a token copy of
  // @param _price - the list price, in tokens, of that token (must be non-zero)
  function buyTokenWithLoyalty(uint _game, uint _set, uint _card, uint _loyaltyPrice)
    external
  returns(uint _tokenId) {
    address sender = _msgSender();
    require(gameContract.getCardLoyaltyPrice(_game, _set, _card) == _loyaltyPrice, "paid price must equal list price");
    require(_loyaltyPrice > 0, "purchase price must be >0");
    bytes32 inGameAddress = erc721Contract.getOrCreateInGameAccount(_game, sender);
    erc20Contract.thirdPartySpendLoyaltyPoints(_game, sender, _loyaltyPrice);
    _tokenId = _createToken(inGameAddress, _game, _set, _card, bytes32(uint(-1)));
  }

  function workerBuyCollectible(
    bytes32 purchaseId,
    address purchaser,
    uint championId,
    uint card,
    uint xp,
    uint xpPerHour,
    uint creationTime,
    uint loyaltySpend,
    bool isOraclePurchase
  )
    external
    onlyWorkerOrMinion()
  {
    bytes32 _purchaseId = purchaseId;
    if(isOraclePurchase) {
      require(_purchaseId != bytes32(0), "Oracle hash can't be zero");
      if(buyCollectibleOracleHashes[_purchaseId]) {
        return;
      }
      buyCollectibleOracleHashes[_purchaseId] = true;
      _purchaseId = bytes32(uint(-1));
    }
    bytes32 inGameAddress = erc721Contract.getOrCreateInGameAccount(0, purchaser);
    // Create the token, and transfer it to the user
    uint tokenId = _createToken(inGameAddress, 0, championId, card, _purchaseId);
    // store collectible based on token ID
    erc721Contract.generateCollectible(tokenId, xp, xpPerHour, creationTime);
    // take loyalty payment if necessary
    if(loyaltySpend > 0) {
      erc20Contract.thirdPartySpendLoyaltyPoints(championId, purchaser, loyaltySpend);
    }
  }

  function updateTokenUri(uint _game, uint _tokenId, string calldata _tokenUri)
    external
    operatorOrMinion(_game)
    tokenIsForGame(_game, _tokenId)
  {
    emit TokenUriUpdated(_game, _tokenId, _tokenUri);
  }

  function updateTokenJson(uint _game, uint _tokenId, string calldata _tokenJson)
    external
    operatorOrMinion(_game)
    tokenIsForGame(_game, _tokenId)
  {
    emit TokenJsonUpdated(_game, _tokenId, _tokenJson);
  }

  function revokeTokensByPurchaseId(uint _game, bytes32 _purchaseId)
    external
    operatorOrMinion(_game)
  returns(uint[] memory _tokenIds) {
    uint[] storage tokensToRevoke = purchaseIdtoTokenIds[_game][_purchaseId];
    require(tokensToRevoke.length > 0, "must be revoking at least one token");
    _tokenIds = new uint[](tokensToRevoke.length);
    bool isOneRevoked;
    for (uint i = 0; i < tokensToRevoke.length; i++) {
      uint tokenId = tokensToRevoke[i];
      if(erc721Contract.revokeToken(_game, tokenId, _purchaseId)) {
        _tokenIds[i] = tokenId;
        isOneRevoked = true;
      }
    }
    require(isOneRevoked, "must have revoked at least one");
  }

  function revokeOffChainPurchasedToken(uint _game, uint _tokenId)
    external
    operatorOrMinion(_game)
    tokenIsForGame(_game, _tokenId)
  returns (uint tokenId) {
    if(erc721Contract.revokeToken(_game, _tokenId, bytes32(0))) {
      tokenId = _tokenId;
    }
  }

  // @dev Gets the list of tokenIds created by a given transaction
  // @param _game - the # of the game that the token comes from
  // @param _purchaseId - the Id of the purchase that created this token (for real money purchase ONLY)
  //   Pass the hash of the Apple/Google/Steam receipt, or similar
  function getTokenIdsFromPurchaseId(uint _game, bytes32 _purchaseId)
    external
    view
  returns (uint[] memory tokenIds) {
    return purchaseIdtoTokenIds[_game][_purchaseId];
  }

  // @dev Grants a group of tokens from a group of base cards, using the cards' metadata (if any)
  // @param _recipient - the account who will own this token on creation
  // @param _game - the # of the game that the token comes from
  // @param _set - the # of the set within the game that the token comes from
  // @param _cards - the array of card #s of the card within the set to grant
  // @param _purchaseId - the Id of the purchase that created this token (for real money purchase ONLY)
  //   Pass the hash of the Apple/Google/Steam receipt, or similar
  function grantTokensFromCards(
    bytes32 _recipient, uint _game, uint _set, uint[] calldata _cards,
    bytes32 _purchaseId)
    external
    operatorOrMinion(_game)
  returns(uint[] memory _tokenIds) {
    _tokenIds = new uint[](_cards.length);
    for (uint i = 0; i < _cards.length; i++) {
      _tokenIds[i] = _createToken(_recipient, _game, _set, _cards[i], _purchaseId);
    }
  }


  // @dev Internal function to perform the token creation
  // @param _recipient - the account who will own this token on creation
  // @param _game - the # of the game that the token comes from
  // @param _set - the # of the set within the game that the token comes from
  // @param _card - the # of the card within the set that the token comes from
  // @param _purchaseId - the Id of the purchase that created this token (for real money purchase ONLY)
  //   Pass the hash of the Apple/Google/Steam receipt, or similar
  // @param _tokenData - any metadata you want to store as part of the token transaction
  function _createToken(
    bytes32 _recipient,
    uint _game,
    uint _set,
    uint _card,
    bytes32 _purchaseId
  )
    internal
  returns (uint _tokenId) {
    uint tradeLockTime;
    (_tokenId, tradeLockTime) = gameContract.createTokenFromCard(_game, _set, _card);

    // Lock the card from transfers if it was bought off-chain
    // Supports management actions for reverting fraudulent off-chain purchases
    if (_purchaseId != bytes32(uint(-1))) {
      tradeLockTime = block.timestamp.add(tradeLockTime);
      if(_purchaseId != bytes32(0)) {
        purchaseIdtoTokenIds[_game][_purchaseId].push(_tokenId);
      }
    } else {
      tradeLockTime = 0;
    }

    emit TokenCreated(_game, _tokenId, _purchaseId, tradeLockTime);

    // Assign ownership, and also emit the Transfer event as per ERC721 draft
    erc721Contract.transferNewToken(
      _recipient,
      _tokenId,
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

  function linkContracts(address _gameContract, address _erc20Contract, address _erc721Contract)
    external
    onlyOwner
  {
    require (address(gameContract) == address(0), "game can't be address(0)");
    require (address(erc20Contract) == address(0), "erc20 can't be address(0)");
    require (address(erc721Contract) == address(0), "erc721 can't be address(0)");
    _updateLocalContract(_gameContract, true);
    _updateLocalContract(_erc721Contract, true);
    _updateLocalContract(_erc20Contract, true);
    gameContract = iGAME_Game(_gameContract);
    erc20Contract = iGAME_ERC20(_erc20Contract);
    erc721Contract = iGAME_ERC721(_erc721Contract);
    gameContract.linkContracts(_erc721Contract, _erc20Contract);
    erc20Contract.linkContracts(_gameContract, _erc721Contract);
    erc721Contract.linkContracts(_gameContract, _erc20Contract);
  }

  // @dev Cancels an auction.
  //  Only the manager may do this, and NFTs are returned to
  //  the seller. This should only be used in emergencies.
  // @param _tokenId - Id of the NFT on auction to cancel.
  function cancelAuctionByManager(uint _tokenId)
    external
    onlyCOO
  {
    erc20Contract.cancelAuctionByManager(_tokenId);
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

  function updateLocalContract(address _contract, bool _isLocal)
    external
    override
    onlyOwner
  {
    _updateLocalContract(_contract, _isLocal);
  }

  function _updateLocalContract(address _contract, bool _isLocal)
    internal
  {
    require(_contract != address(this), "new local can't be this contract");
    require(_contract != address(erc721Contract), "new local can't be erc721");
    require(_contract != address(erc20Contract), "new local can't be erc20");
    require(_contract != address(gameContract), "new local can't be gamecontract");
    require(_contract != address(0), "new local can't be address(0)");
    require(localContracts[_contract] != _isLocal, "new local can't be local already");
    iLocalContract localContract = iLocalContract(_contract);
    require(localContract.isLocalContract(), "new local must implement isLocalContract()");
    localContracts[_contract] = _isLocal;

    if(_isLocal) {
      for (uint i = 0; i < activeLocalContracts.length; i++) {
        activeLocalContracts[i].updateLocalContract(_contract, _isLocal);
        localContract.updateLocalContract(address(activeLocalContracts[i]), _isLocal);
      }
      activeLocalContracts.push(localContract);
    } else {
      for (uint i = 0; i < activeLocalContracts.length - 1; i++) {
        if(activeLocalContracts[i] == localContract) {
          activeLocalContracts[i] = activeLocalContracts[activeLocalContracts.length - 1];
        }
        activeLocalContracts[i].updateLocalContract(_contract, _isLocal);
        localContract.updateLocalContract(address(activeLocalContracts[i]), _isLocal);
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