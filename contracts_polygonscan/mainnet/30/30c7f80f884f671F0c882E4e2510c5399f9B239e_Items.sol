/**
 *Submitted for verification at polygonscan.com on 2021-08-26
*/

pragma solidity >=0.5.0;


// 
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// 
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
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this;
    // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol
/**
* @dev Contract module which provides a basic access control mechanism, where
* there is an account (an owner) that can be granted exclusive access to
* specific functions.
*
* This module is used through inheritance. It will make available the modifier
* `onlyOwner`, which can be applied to your functions to restrict their use to
* the owner.
*/
abstract contract Ownable is Initializable, Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
  * @dev Initializes the contract setting the deployer as the initial owner.
  */
  function initialize() public virtual initializer {
    _owner = _msgSender();
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
  * @dev Returns the address of the current owner.
  */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  /**
  * @dev Returns true if the caller is the current owner.
  */
  function isOwner() public view returns (bool) {
    return _msgSender() == _owner;
  }

  /**
  * @dev Leaves the contract without owner. It will not be possible to call
  * `onlyOwner` functions anymore. Can only be called by the current owner.
  *
  * NOTE: Renouncing ownership will leave the contract without an owner,
  * thereby removing any functionality that is only available to the owner.
  */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Can only be called by the current owner.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract BasicMetaTransaction {

  event MetaTransactionExecuted(address userAddress, address relayerAddress, bytes functionSignature);

  mapping(address => uint256) private nonces;

  function getChainID() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
  * Main function to be called when user wants to execute meta transaction.
  * The actual function to be called should be passed as param with name functionSignature
  * Here the basic signature recovery is being used. Signature is expected to be generated using
  * personal_sign method.
  * @param userAddress Address of user trying to do meta transaction
  * @param functionSignature Signature of the actual function to be called via meta transaction
  * @param sigR R part of the signature
  * @param sigS S part of the signature
  * @param sigV V part of the signature
  */
  function executeMetaTransaction(address userAddress, bytes memory functionSignature,
    bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns (bytes memory) {

    require(verify(userAddress, nonces[userAddress], getChainID(), functionSignature, sigR, sigS, sigV), "Signer and signature do not match");
    nonces[userAddress] = nonces[userAddress]++;

    // Append userAddress at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

    require(success, "Function call not successful");
    emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);
    return returnData;
  }

  function getNonce(address user) external view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  // Builds a prefixed hash to mimic the behavior of eth_sign.
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function verify(address owner, uint256 nonce, uint256 chainID, bytes memory functionSignature,
    bytes32 sigR, bytes32 sigS, uint8 sigV) public view returns (bool) {

    bytes32 hash = prefixed(keccak256(abi.encodePacked(nonce, this, chainID, functionSignature)));
    address signer = ecrecover(hash, sigV, sigR, sigS);
    require(signer != address(0), "Invalid signature");
    return (owner == signer);
  }

  function msgSender() internal view returns (address sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
      // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      return msg.sender;
    }
  }
}

contract Items is BasicMetaTransaction, Ownable {

  IERC20 MOCA;

  uint256 public totalItems;

  uint256 public AMOUNT_PER_ITEM;
  uint256 public COOLDOWN;
  uint8 public MAX_ITEMS;
  

  mapping(uint256 => Item) public idToItem;
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(uint256 => uint256)) public ownedItems;

  mapping(address => uint256) public lastTimeAdded;

  struct Item {
    uint256 id;
    uint256 chainId;
    address owner;
    address collection;
    uint256 tokenId;
    uint256 timestamp_activated;
  }

  event NewItem(Item item, uint256 blockNumber);

  function initialize(IERC20 _requiredToken, uint256 _cooldown, uint256 _amount, uint8 _max_items) public initializer {
    Ownable.initialize();
    MOCA = IERC20(address(_requiredToken));
    COOLDOWN = _cooldown;
    AMOUNT_PER_ITEM = _amount;
    MAX_ITEMS = _max_items;
  }

  function addItem(Item[] memory _items) public {
    require(lastTimeAdded[msgSender()] + COOLDOWN <= block.timestamp, "ERR_COOLDOWN");
    require(_items.length <= MAX_ITEMS, "ERR_MAX_ITEMS");
    
    for(uint8 i=0; i < _items.length; i++) {
	    require(MOCA.transferFrom(msgSender(), address(this), AMOUNT_PER_ITEM) == true, "Not enough $MOCA");
	    
	    Item memory _item = _items[i];
	    Item storage item = idToItem[totalItems];
    
        item.id = totalItems;
        item.chainId = _item.chainId;
        item.owner = msgSender();
        item.collection = _item.collection;
        item.tokenId = _item.tokenId;
        item.timestamp_activated = block.timestamp;
    
        ownedItems[msgSender()][balanceOf[msgSender()]] = item.id;
        balanceOf[msgSender()]++;
    
        totalItems++;
    
        lastTimeAdded[msgSender()] = block.timestamp;
    
        emit NewItem(item, block.number);
    }
  }
  
  function withdraw() public onlyOwner {
      MOCA.transfer(msgSender(), MOCA.balanceOf(address(this)));
  }

}