/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.4.24;

// File: contracts/upgradable/ProxyStorage.sol

contract ProxyStorage {

  /**
   * Current contract to which we are proxing
   */
  address public currentContract;
  address public proxyOwner;
}

// File: contracts/upgradable/OwnableStorage.sol

contract OwnableStorage {

  address public owner;

  constructor() internal {
    owner = msg.sender;
  }

}

// File: erc821/contracts/AssetRegistryStorage.sol

contract AssetRegistryStorage {

  string internal _name;
  string internal _symbol;
  string internal _description;

  /**
   * Stores the total count of assets managed by this registry
   */
  uint256 internal _count;

  /**
   * Stores an array of assets owned by a given account
   */
  mapping(address => uint256[]) internal _assetsOf;

  /**
   * Stores the current holder of an asset
   */
  mapping(uint256 => address) internal _holderOf;

  /**
   * Stores the index of an asset in the `_assetsOf` array of its holder
   */
  mapping(uint256 => uint256) internal _indexOfAsset;

  /**
   * Stores the data associated with an asset
   */
  mapping(uint256 => string) internal _assetData;

  /**
   * For a given account, for a given operator, store whether that operator is
   * allowed to transfer and modify assets on behalf of them.
   */
  mapping(address => mapping(address => bool)) internal _operators;

  /**
   * Approval array
   */
  mapping(uint256 => address) internal _approval;
}

// File: contracts/sector/ISectorRegistry.sol

contract ISectorRegistry {
  function mint(address to, string metadata) external returns (uint256);
  function ownerOf(uint256 _tokenId) public view returns (address _owner); // from ERC721

  // Events

  event CreateSector(
    address indexed _owner,
    uint256 indexed _sectorId,
    string _data
  );

  event AddSpace(
    uint256 indexed _sectorId,
    uint256 indexed _spaceId
  );

  event RemoveSpace(
    uint256 indexed _sectorId,
    uint256 indexed _spaceId,
    address indexed _destinatary
  );

  event Update(
    uint256 indexed _assetId,
    address indexed _holder,
    address indexed _operator,
    string _data
  );

  event UpdateOperator(
    uint256 indexed _sectorId,
    address indexed _operator
  );

  event UpdateManager(
    address indexed _owner,
    address indexed _operator,
    address indexed _caller,
    bool _approved
  );

  event SetSPACERegistry(
    address indexed _registry
  );

  event SetSectorSpaceBalanceToken(
    address indexed _previousSectorSpaceBalance,
    address indexed _newSectorSpaceBalance
  );
}

// File: contracts/minimeToken/IMinimeToken.sol

interface IMiniMeToken {
////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount) external returns (bool);


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount) external returns (bool);

    /// @param _owner The address that's balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) external view returns (uint256 balance);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
}

// File: contracts/space/SPACEStorage.sol

contract SPACEStorage {
  mapping (address => uint) public latestPing;

  uint256 constant clearLow = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 constant clearHigh = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  uint256 constant factor = 0x100000000000000000000000000000000;

  mapping (address => bool) internal _deprecated_authorizedDeploy;

  mapping (uint256 => address) public updateOperator;

  ISectorRegistry public sectorRegistry;

  mapping (address => bool) public authorizedDeploy;

  mapping(address => mapping(address => bool)) public updateManager;

  // Space balance minime token
  IMiniMeToken public spaceBalance;

  // Registered balance accounts
  mapping(address => bool) public registeredBalance;
}

// File: contracts/Storage.sol

contract Storage is ProxyStorage, OwnableStorage, AssetRegistryStorage, SPACEStorage {
}

// File: contracts/upgradable/Ownable.sol

contract Ownable is Storage {

  event OwnerUpdate(address _prevOwner, address _newOwner);

  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != owner, "Cannot transfer to yourself");
    owner = _newOwner;
  }
}

// File: contracts/upgradable/DelegateProxy.sol

contract DelegateProxy {
  /**
   * @dev Performs a delegatecall and returns whatever the delegatecall returned (entire context execution will return!)
   * @param _dst Destination address to perform the delegatecall
   * @param _calldata Calldata for the delegatecall
   */
  function delegatedFwd(address _dst, bytes _calldata) internal {
    require(isContract(_dst), "The destination address is not a contract");

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
      let size := returndatasize

      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)

      // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
      // if the call returned error data, forward it
      switch result case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

  function isContract(address _target) internal view returns (bool) {
    uint256 size;
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_target) }
    return size > 0;
  }
}

// File: contracts/upgradable/IApplication.sol

contract IApplication {
  function initialize(bytes data) public;
}

// File: contracts/upgradable/Proxy.sol

contract Proxy is Storage, DelegateProxy, Ownable {

  event Upgrade(address indexed newContract, bytes initializedWith);
  event OwnerUpdate(address _prevOwner, address _newOwner);

  constructor() public {
    proxyOwner = msg.sender;
    owner = msg.sender;
  }

  //
  // Dispatch fallback
  //

  function () public payable {
    require(currentContract != 0, "If app code has not been set yet, do not call");
    delegatedFwd(currentContract, msg.data);
  }

  //
  // Ownership
  //

  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner, "Unauthorized user");
    _;
  }

  function transferOwnership(address _newOwner) public onlyProxyOwner {
    require(_newOwner != address(0), "Empty address");
    require(_newOwner != proxyOwner, "Already authorized");
    proxyOwner = _newOwner;
  }

  //
  // Upgrade
  //

  function upgrade(IApplication newContract, bytes data) public onlyProxyOwner {
    currentContract = newContract;
    IApplication(this).initialize(data);

    emit Upgrade(newContract, data);
  }
}

// File: contracts/upgradable/SPACEProxy.sol

contract SPACEProxy is Storage, Proxy {
}