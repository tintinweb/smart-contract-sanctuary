pragma solidity ^0.8.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title ProxyStorage
 * @dev Store the address of logic contact that the proxy should forward to.
 */
contract ProxyStorage is Ownable {
  address internal _proxyTo;
}

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy is ProxyStorage {

  event ProxyUpdated(address indexed _new, address indexed _old);

  constructor(address _proxyTo) public {
    updateProxyTo(_proxyTo);
  }

  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address) {
    return _proxyTo;
  }

  /**
  * @dev See more at: https://eips.ethereum.org/EIPS/eip-897
  * @return type of proxy - always upgradable
  */
  function proxyType() external pure returns (uint256) {
      // Upgradeable proxy
      return 2;
  }

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  fallback () payable external {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

  function updateProxyTo(address _newProxyTo) public onlyOwner {
    require(_newProxyTo != address(0x0));

    _proxyTo = _newProxyTo;
    emit ProxyUpdated(_newProxyTo, _proxyTo);
  }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        require(c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Since Solidity automatically asserts when dividing by 0,
        // but we only need it to revert.
        require(b > 0);
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Same reason as `div`.
        require(b > 0);
        return a % b;
    }

    function ceilingDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        return add(div(a, b), mod(a, b) > 0 ? 1 : 0);
    }

    function subU64(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require(b <= a);
        return a - b;
    }

    function addU8(uint8 a, uint8 b) internal pure returns (uint8 c) {
        c = a + b;
        require(c >= a);
    }
}

interface IRegistry {
    function getContract(string calldata _name) external view returns (address _address);

    function isTokenMapped(address _token, uint32 _standard, bool _isMainchain) external view returns (bool);

    function updateContract(string calldata _name, address _newAddress) external;

    function mapToken( address _mainchainToken, address _sidechainToken, uint32 _standard) external;

    function clearMapToken(address _mainchainToken, address _sidechainToken) external;

    function getMappedToken(address _token, bool _isMainchain) external view returns ( address _mainchainToken, address _sidechainToken, uint32 _standard);
}

/**
 * @title GatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
contract MainchainGatewayStorage is Ownable {
    event TokenDeposited(
        uint256 indexed _depositId,
        address indexed _owner,
        address indexed _tokenAddress,
        address _sidechainAddress,
        uint32 _standard,
        uint256 _tokenNumber // ERC-20 amount or ERC721 tokenId
    );

    event TokenWithdrew(
        uint256 indexed _withdrawId,
        address indexed _owner,
        address indexed _tokenAddress,
        uint256 _tokenNumber // ERC-20 amount or ERC721 tokenId
    );

    struct DepositEntry {
        address owner;
        address tokenAddress;
        address sidechainAddress;
        uint32 standard;
        uint256 tokenNumber;
    }

    struct WithdrawalEntry {
        address owner;
        address tokenAddress;
        uint256 tokenNumber;
    }

    IRegistry public registry;

    uint256 public depositCount;
    DepositEntry[] public deposits;
    mapping(uint256 => WithdrawalEntry) public withdrawals;

    function updateRegistry(address _registry) external onlyOwner {
        registry = IRegistry(_registry);
    }
}

contract MainchainGatewayProxy is Proxy, MainchainGatewayStorage {
    constructor(address _proxyTo, address _registry) public Proxy(_proxyTo) {
        registry = IRegistry(_registry);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}