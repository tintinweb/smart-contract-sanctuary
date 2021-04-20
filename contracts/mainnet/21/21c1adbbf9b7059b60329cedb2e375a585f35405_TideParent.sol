/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

/*
  The shared configuration for tidal and riptide sibling tokens
  riptide.finance

  @nightg0at
  SPDX-License-Identifier: MIT
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/introspection/IERC165.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol



pragma solidity >=0.6.2 <0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: @openzeppelin/contracts/introspection/IERC1820Registry.sol



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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Whitelist.sol

/*
  Exemption whitelists and convenience methods for Tidal's punitive mechanisms

  @nightg0at
*/


pragma solidity 0.6.12;

contract Whitelist is Ownable {

  // protectors can be ERC20, ERC777 or ERC1155 tokens
  // ERC115 tokens have a different balanceOf() method, so we use the ERC1820 registry to identify the ERC1155 interface
  IERC1820Registry private erc1820Registry; // 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
  bytes4 private constant ERC1155_INTERFACE_ID = 0xd9b67a26;

  // used to identify if an address is likely to be a uniswap pair
  address private constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

  // tokens that offer the holder some kind of protection
  struct TokenAttributes {
    bool active;
    uint256 proportion; // proportion of incoming tokens used as burn amount (typically 1 or 0.5)
    uint256 floor; // the lowest the balance can be after a wipeout event
  }

  struct TokenID {
    address addr;
    uint256 id; // for IERC1155 tokens else 0
  }

  // addresses that have some kind of protection as if they are holding protective tokens
  struct AddressAttributes {
    bool active;
    uint256 proportion;
    uint256 floor;
  }

  // addresses that do not incur punitive burns or wipeouts as senders or receivers
  struct WhitelistAttributes {
    bool active;
    bool sendBurn;
    bool receiveBurn;
    bool sendWipeout;
    bool receiveWipeout;
  }

  uint256 public defaultProportion = 1e18;
  uint256 public defaultFloor = 0;

  constructor(
    IERC1820Registry _erc1820Registry
  ) public {
    erc1820Registry = _erc1820Registry;
    
    // premine our starting protectors. Surfboards and trident NFTs
    addProtector(0xf90AeeF57Ae8Bc85FE8d40a3f4a45042F4258c67, 0, 5e17, 0); // surfboard, 0.5x, 0 floor
    addProtector(0xd07dc4262BCDbf85190C01c996b4C06a461d2430, 78947, 1e18, 2496e14); // bronze trident , 1x, 0.2496 floor
    addProtector(0xd07dc4262BCDbf85190C01c996b4C06a461d2430, 78955, 1e18, 42e16); // silver trident, 1x, 0.42 floor
    addProtector(0xd07dc4262BCDbf85190C01c996b4C06a461d2430, 78963, 1e18, 69e16); // gold trident, 1x, 0.69 floor

  }

  mapping (address => AddressAttributes) public protectedAddress;
  TokenID[] public protectors;
  mapping (address => mapping (uint256 => TokenAttributes)) public protectorAttributes;
  mapping (address => WhitelistAttributes) public whitelist;
  

  function addProtector(address _token, uint256 _id, uint256 _proportion, uint256 _floor) public onlyOwner {
    uint256 id = isERC1155(_token) ? _id : 0;
    require(protectorAttributes[_token][id].active == false, "WIPEOUT::addProtector: Token already active");
    editProtector(_token, true, id, _proportion, _floor);
    protectors.push(TokenID(_token, id));
  }

  function editProtector(address _token, bool _active, uint256 _id, uint256 _proportion, uint256 _floor) public onlyOwner {
    protectorAttributes[_token][_id] = TokenAttributes(_active, _proportion, _floor);
  }

  function protectorLength() external view returns (uint256) {
    return protectors.length;
  }

  function getProtectorAttributes(address _addr, uint256 _id) external view returns (bool, uint256, uint256) {
    return (
      protectorAttributes[_addr][_id].active,
      protectorAttributes[_addr][_id].proportion,
      protectorAttributes[_addr][_id].floor
    );
  }


  function isERC1155(address _token) private view returns (bool) {
    return erc1820Registry.implementsERC165Interface(_token, ERC1155_INTERFACE_ID);
  }

  function hasProtector(address _addr, address _protector, uint256 _id) public view returns (bool) {
    bool has = false;
    if (isERC1155(_protector)) {
      if (IERC1155(_protector).balanceOf(_addr, _id) > 0) {
        has = true;
      }
    } else {
      if (IERC20(_protector).balanceOf(_addr) > 0) {
        has = true;
      }
    }
    return has;
  }

  function cumulativeProtectionOf(address _addr) external view returns (uint256, uint256) {
    uint256 proportion = defaultProportion;
    uint256 floor = defaultFloor;
    for (uint256 i=0; i<protectors.length; i++) {
      address protector = protectors[i].addr;
      uint256 id = protectors[i].id;
      if (hasProtector(_addr, protector, id)) {
        if (proportion > protectorAttributes[protector][id].proportion) {
          proportion = protectorAttributes[protector][id].proportion;
        }
        if (floor < protectorAttributes[protector][id].floor) {
          floor = protectorAttributes[protector][id].floor;
        }
      }
    }
    return (proportion, floor);
  }

  function setProtectedAddress(address _addr, bool _active, uint256 _proportion, uint256 _floor) public onlyOwner {
    require(_addr != address(0), "WIPEOUT::setProtector: zero address");
    protectedAddress[_addr] = AddressAttributes(_active, _proportion, _floor);
  }

  function getProtectedAddress(address _addr) external view returns (bool, uint256, uint256) {
    return (
      protectedAddress[_addr].active,
      protectedAddress[_addr].proportion,
      protectedAddress[_addr].floor
    );
  }

  function setWhitelist(
    address _whitelisted,
    bool _active,
    bool _sendBurn,
    bool _receiveBurn,
    bool _sendWipeout,
    bool _receiveWipeout
  ) public onlyOwner {
    require(_whitelisted != address(0), "WIPEOUT::setWhitelist: zero address");
    whitelist[_whitelisted] = WhitelistAttributes(_active, _sendBurn, _receiveBurn, _sendWipeout, _receiveWipeout);
  }

  function getWhitelist(address _addr) external view returns (bool, bool, bool, bool, bool) {
    return (
      whitelist[_addr].active,
      whitelist[_addr].sendBurn,
      whitelist[_addr].receiveBurn,
      whitelist[_addr].sendWipeout,
      whitelist[_addr].receiveWipeout
    );
  }

  // checks if the address is a deployed contract and if so,
  // checks if the factory() method is present and returns the uniswap factory address.
  // returns true if it is.
  // This is easy to spoof but the gains are low enough for this to be ok.
  function isUniswapTokenPair(address _addr) public view returns (bool) {
    uint32 size;
    assembly {
      size := extcodesize(_addr)
    }
    if (size == 0) {
      return false;
    } else {
      try IUniswapV2Pair(_addr).factory() returns (address _factory) {
        return _factory == UNISWAP_FACTORY ? true : false;
      } catch {
        return false;
      }
    }
  }

  function isUniswapTokenPairWith(address _pair, address _token) public view returns (bool) {
    return (IUniswapV2Pair(_pair).token0() == _token || IUniswapV2Pair(_pair).token1() == _token);
  }

  function willBurn(address _sender, address _recipient) public view returns (bool) {
    // returns true if everything is false
    return !(whitelist[_sender].sendBurn || whitelist[_recipient].receiveBurn);
  }

  function willWipeout(address _sender, address _recipient) public view returns (bool) {
    bool whitelisted = whitelist[_sender].sendWipeout || isUniswapTokenPair(_sender);
    whitelisted = whitelisted || whitelist[_recipient].receiveWipeout;
    // returns true if everything is false
    return !whitelisted;
  }

}

// File: contracts/interfaces/ITideToken.sol


pragma solidity 0.6.12;


interface ITideToken is IERC20 {
  function owner() external view returns (address);
  function mint(address _to, uint256 _amount) external;
  function setParent(address _newConfig) external;
  function wipeout(address _recipient, uint256 _amount) external;
}

// File: contracts/TideParent.sol

pragma solidity 0.6.12;

contract TideParent is Whitelist {

  address private _poseidon;
  address[2] public siblings; //0: tidal, 1: riptide

  uint256 private _burnRate = 69e15; //6.9%, 0.069
  uint256 private _transmuteRate = 42e14; //0.42%, 0.0042

  constructor(
    IERC1820Registry _erc1820Registry
  ) public Whitelist(_erc1820Registry) {}

  function setPoseidon(address _newPoseidon) public onlyOwner {
    if (whitelist[_poseidon].active) {
      setWhitelist(_poseidon, false, false, false, false, false);
    }
    if (protectedAddress[_poseidon].active) {
      setProtectedAddress(_poseidon, false, 0, 0);
    }
    setProtectedAddress(_newPoseidon, true, 5e17, 69e16);
    setWhitelist(_newPoseidon, true, true, false, true, false);
    _poseidon = _newPoseidon;
  }

  function setSibling(uint256 _index, address _token) public onlyOwner {
    require(_token != address(0), "TIDEPARENT::setToken: zero address");
    siblings[_index] = _token;
  }

  function setAddresses(address _siblingA, address _siblingB, address _newPoseidon) external onlyOwner {
    setSibling(0, _siblingA);
    setSibling(1, _siblingB);
    setPoseidon(_newPoseidon);
  }

  function setBurnRate(uint256 _newBurnRate) external onlyOwner {
    require(_newBurnRate <= 2e17, "TIDEPARENT:setBurnRate: 20% max");
    _burnRate = _newBurnRate;
  }

  function setTransmuteRate(uint256 _newTransmuteRate) external onlyOwner {
    require(_newTransmuteRate <= 1e17, "TIDEPARENT:setTransmuteRate: 10% max");
    _transmuteRate = _newTransmuteRate;
  }

  function setNewParent(address _newConfig) external onlyOwner {
    ITideToken(siblings[0]).setParent(_newConfig);
    ITideToken(siblings[1]).setParent(_newConfig);
  }

  function poseidon() public view returns (address) {
    return _poseidon;
  }

  function burnRate() public view returns (uint256) {
    return _burnRate;
  }

  function transmuteRate() public view returns (uint256) {
    return _transmuteRate;
  }

  function sibling(address _siblingCandidate) public view returns (address) {
    if (_siblingCandidate == siblings[0]) {
      return siblings[1];
    } else if (_siblingCandidate == siblings[1]) {
      return siblings[0];
    } else {
      return address(0);
    }
  }
}