/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

// File: contracts\interfaces\IAvnStorage.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IAvnStorage {
  event LogStoragePermissionUpdated(address indexed publisher, bool status);

  function setStoragePermission(address publisher, bool status) external;
  function storeT2TransactionId(uint256 _t2TransactionId) external;
  function storeT2TransactionIdAndRoot(uint256 _t2TransactionId, bytes32 rootHash) external;
  function confirmLeaf(bytes32 leafHash, bytes32[] memory merklePath) external view returns (bool);
}

// File: contracts\interfaces\IAvnFTScalingManager.sol


pragma solidity 0.7.5;

interface IAvnFTScalingManager {
  event LogLifted(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256 amount, uint256 nonce);
  event LogLowered(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256 amount,
    bytes32 leafHash);

  function disableLift(bool _isDisabled) external;
  function lift(address erc20Contract, bytes32 t2PublicKey, uint256 amount) external;
  function lower(bytes calldata encodedLeaf, bytes32[] calldata merklePath) external;
  function confirmT2Transaction(bytes32 leafHash, bytes32[] memory merklePath) external view returns (bool);
  function retire() external;
}

// File: contracts\interfaces\IAvnFTTreasury.sol


pragma solidity 0.7.5;

interface IAvnFTTreasury {
  event LogFTTreasuryPermissionUpdated(address indexed treasurer, bool status);

  function setTreasurerPermission(address treasurer, bool status) external;
  function getTreasurers() external view returns(address[] memory);
  function unlockERC777Tokens(address token, uint256 amount, bytes calldata data) external;
  function unlockERC20Tokens(address token, uint256 amount) external;
}

// File: contracts\interfaces\IERC20.sol


pragma solidity 0.7.5;

// As described in https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function name() external view returns (string memory); // optional method - see eip spec
  function symbol() external view returns (string memory); // optional method - see eip spec
  function decimals() external view returns (uint8); // optional method - see eip spec
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
}

// File: contracts\interfaces\IERC777.sol


pragma solidity 0.7.5;

// As defined in https://eips.ethereum.org/EIPS/eip-777
interface IERC777 {
  event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data,
      bytes operatorData);
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator,address indexed holder);
  event RevokedOperator(address indexed operator, address indexed holder);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function balanceOf(address holder) external view returns (uint256);
  function granularity() external view returns (uint256);
  function defaultOperators() external view returns (address[] memory);
  function isOperatorFor(address operator, address holder) external view returns (bool);
  function authorizeOperator(address operator) external;
  function revokeOperator(address operator) external;
  function send(address to, uint256 amount, bytes calldata data) external;
  function operatorSend(address from, address to, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
  function burn(uint256 amount, bytes calldata data) external;
  function operatorBurn( address from, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
}

// File: contracts\thirdParty\interfaces\IERC1820Registry.sol

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/introspection/IERC1820Registry.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 _interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// File: contracts\thirdParty\SafeMath.sol

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts\Owned.sol


pragma solidity 0.7.5;

contract Owned {

  address public owner = msg.sender;

  event LogOwnershipTransferred(address indexed owner, address indexed newOwner);

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner");
    _;
  }

  function setOwner(address _owner)
    external
    onlyOwner
  {
    require(_owner != address(0), "Owner cannot be zero address");
    emit LogOwnershipTransferred(owner, _owner);
    owner = _owner;
  }
}

// File: ..\contracts\AvnFTScalingManager.sol


pragma solidity 0.7.5;

contract AvnFTScalingManager is IAvnFTScalingManager, Owned {
  using SafeMath for uint256;

  struct LeafData {
    bytes t2Data;
    bytes abiEncodedT2Data;
  }

  struct T1LowerData {
    address token;
    bytes32 fromT2PublicKey;
    bytes32 toT2PublicKey;
    uint256 amount;
    address t1LowerAddress;
  }

  // Universal address as defined in Registry Contract Address section of https://eips.ethereum.org/EIPS/eip-1820
  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  // keccak256("ERC777Token")
  bytes32 constant internal ERC777_TOKEN_HASH = 0xac7fbab5f54a3ca8194167523c6753bfeb96a445279294b6125b68cce2177054;
  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal ERC777_TOKENS_RECIPIENT_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  bytes32 constant internal T2_BURN_PUBLIC_KEY = 0x000000000000000000000000000000000000000000000000000000000000dead;
  uint256 constant internal LIFT_LIMIT = type(uint128).max;

  IAvnStorage immutable public avnStorage;
  IAvnFTTreasury immutable public avnFTTreasury;

  uint256 public liftNonce;
  bool public liftDisabled;

  mapping (bytes32 => bool) public hasLowered;

  constructor(IAvnStorage _avnStorage, IAvnFTTreasury _avnFTTreasury)
  {
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC777_TOKENS_RECIPIENT_HASH, address(this));
    avnStorage = _avnStorage;
    avnFTTreasury = _avnFTTreasury;
  }

  modifier onlyWhenLiftEnabled() {
    require(!liftDisabled, "Lifting currently disabled");
    _;
  }

  function disableLift(bool _isDisabled)
    onlyOwner
    external
    override
  {
    liftDisabled = _isDisabled;
  }

  function lift(address _erc20Contract, bytes32 _t2PublicKey, uint256 _amount)
    onlyWhenLiftEnabled
    external
    override
  {
    require(_amount > 0, "Cannot lift zero ERC20 tokens");
    require(IERC20(_erc20Contract).balanceOf(address(avnFTTreasury)).add(_amount) <= LIFT_LIMIT, "Exceeds ERC20 lift limit");
    lockERC20TokensInTreasury(_erc20Contract, _amount);
    emit LogLifted(_erc20Contract, msg.sender, _t2PublicKey, _amount, ++liftNonce);
  }

  function lower(bytes calldata _encodedLeaf, bytes32[] calldata _merklePath)
    external
    override
  {
    bytes32 leafHash = keccak256(_encodedLeaf);
    require(avnStorage.confirmLeaf(leafHash, _merklePath), "Leaf or path invalid");
    require(!hasLowered[leafHash], "Already lowered");
    hasLowered[leafHash] = true;

    LeafData memory leafData;
    (leafData.t2Data, leafData.abiEncodedT2Data) = abi.decode(_encodedLeaf, (bytes, bytes));
    T1LowerData memory t1Data;
    (t1Data.token, t1Data.fromT2PublicKey, t1Data.toT2PublicKey, t1Data.amount, t1Data.t1LowerAddress) =
        abi.decode(leafData.abiEncodedT2Data, (address, bytes32, bytes32, uint256, address));
    require(t1Data.toT2PublicKey == T2_BURN_PUBLIC_KEY, "Must have burned to lower");

    if (ERC1820_REGISTRY.getInterfaceImplementer(t1Data.token, ERC777_TOKEN_HASH) == t1Data.token)
      unlockERC777TokensFromTreasury(t1Data.token, t1Data.t1LowerAddress, t1Data.amount, _encodedLeaf);
    else
      unlockERC20TokensFromTreasury(t1Data.token, t1Data.t1LowerAddress, t1Data.amount);

    emit LogLowered(t1Data.token, t1Data.t1LowerAddress, t1Data.fromT2PublicKey, t1Data.amount, leafHash);
  }

  function tokensReceived(address _operator, address _from, address _to, uint256 _amount, bytes calldata _data,
      bytes calldata /* _operatorData */)
    onlyWhenLiftEnabled
    external
  {
    if (_operator == address(this)) return; // This is an ERC20 lift operation - ignore
    if (_operator == address(avnFTTreasury)) return; // These are funds being unlocked by the treasury - ignore
    require(_amount > 0, "Cannot lift zero ERC777 tokens");
    require(_to == address(this), "Tokens must be sent to this contract");
    require(ERC1820_REGISTRY.getInterfaceImplementer(msg.sender, ERC777_TOKEN_HASH) == msg.sender, "Token must be registered");
    require(IERC777(msg.sender).balanceOf(address(avnFTTreasury)).add(_amount) <= LIFT_LIMIT, "Exceeds ERC777 lift limit");

    // this locks the tokens in the treasury
    IERC777(msg.sender).send(address(avnFTTreasury), _amount, _data);
    emit LogLifted(msg.sender, _from, abi.decode(_data, (bytes32)), _amount, ++liftNonce);
  }

  function confirmT2Transaction(bytes32 _leafHash, bytes32[] memory _merklePath)
    external
    view
    override
    returns (bool)
  {
    return avnStorage.confirmLeaf(_leafHash, _merklePath);
  }

  function retire()
    onlyOwner
    external
    override
  {
    selfdestruct(payable(owner));
  }

  function unlockERC777TokensFromTreasury(address _erc777Contract, address _recipient, uint256 _amount, bytes memory _data)
    private
  {
    IAvnFTTreasury(avnFTTreasury).unlockERC777Tokens(_erc777Contract, _amount, _data);
    IERC777(_erc777Contract).send(_recipient, _amount, _data);
  }

  function unlockERC20TokensFromTreasury(address _erc20Contract, address _recipient, uint256 _amount)
    private
  {
    IAvnFTTreasury(avnFTTreasury).unlockERC20Tokens(_erc20Contract, _amount);
    assert(IERC20(_erc20Contract).transfer(_recipient, _amount));
  }

  function lockERC20TokensInTreasury(address _erc20Contract, uint256 _amount)
    private
  {
    IERC20 erc20Contract = IERC20(_erc20Contract);
    assert(erc20Contract.transferFrom(msg.sender, address(this), _amount));
    // locks the tokens in the treasury
    assert(erc20Contract.transfer(address(avnFTTreasury), _amount));
  }
}