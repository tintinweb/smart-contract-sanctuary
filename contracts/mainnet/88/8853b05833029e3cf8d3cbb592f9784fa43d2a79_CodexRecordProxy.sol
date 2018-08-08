pragma solidity 0.4.24;

// File: contracts/ERC165/ERC165.sol

/**
 * @dev A standard for detecting smart contract interfaces.
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
contract ERC165 {

  // bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));
  bytes4 constant INTERFACE_ERC165 = 0x01ffc9a7;

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   */
  function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
    return _interfaceID == INTERFACE_ERC165;
  }
}

// File: contracts/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  // bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
  // bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
  // bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
  // bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
  // bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
  // bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
  // bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
  // bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
  // bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;));
  bytes4 constant INTERFACE_ERC721 = 0x80ac58cd;

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool indexed _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);

  // Note: This is not in the official ERC-721 standard so it&#39;s not included in the interface hash
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId) public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId) public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data) public;
}

// File: contracts/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  // bytes4(keccak256(&#39;totalSupply()&#39;)) ^
  // bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
  // bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;));
  bytes4 constant INTERFACE_ERC721_ENUMERABLE = 0x780e9d63;

  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  // bytes4(keccak256(&#39;name()&#39;)) ^
  // bytes4(keccak256(&#39;symbol()&#39;)) ^
  // bytes4(keccak256(&#39;tokenURI(uint256)&#39;));
  bytes4 constant INTERFACE_ERC721_METADATA = 0x5b5e139f;

  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
/* solium-disable-next-line no-empty-blocks */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: contracts/library/ProxyOwnable.sol

/**
 * @title ProxyOwnable
 * @dev Essentially the Ownable contract, renamed for the purposes of separating it from the
 *  DelayedOwnable contract (the owner of the token contract).
 */
contract ProxyOwnable {
  address public proxyOwner;

  event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `proxyOwner` of the contract to the sender
   * account.
   */
  constructor() public {
    proxyOwner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == proxyOwner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferProxyOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));

    emit ProxyOwnershipTransferred(proxyOwner, _newOwner);

    proxyOwner = _newOwner;
  }
}

// File: contracts/CodexRecordProxy.sol

/**
 * @title CodexRecordProxy, a proxy contract for token storage
 * @dev This allows the token owner to optionally upgrade the token in the future
 *  if there are changes needed in the business logic. See the upgradeTo function
 *  for caveats.
 * Based on MIT licensed code from
 *  https://github.com/zeppelinos/labs/tree/master/upgradeability_using_inherited_storage
 */
contract CodexRecordProxy is ProxyOwnable {
  event Upgraded(string version, address indexed implementation);

  string public version;
  address public implementation;

  constructor(address _implementation) public {
    upgradeTo("1", _implementation);
  }

  /**
   * @dev Fallback function. Any transaction sent to this contract that doesn&#39;t match the
   *  upgradeTo signature will fallback to this function, which in turn will use
   *  DELEGATECALL to delegate the transaction data to the implementation.
   */
  function () payable public {
    address _implementation = implementation;

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _implementation, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

  /**
   * @dev Since name is passed into the ERC721 token constructor, it&#39;s not stored in the CodexRecordProxy
   *  contract. Thus, we call into the contract directly to retrieve its value.
   * @return string The name of the token
   */
  function name() external view returns (string) {
    ERC721Metadata tokenMetadata = ERC721Metadata(implementation);

    return tokenMetadata.name();
  }

  /**
   * @dev Since symbol is passed into the ERC721 token constructor, it&#39;s not stored in the CodexRecordProxy
   *  contract. Thus, we call into the contract directly to retrieve its value.
   * @return string The symbol of token
   */
  function symbol() external view returns (string) {
    ERC721Metadata tokenMetadata = ERC721Metadata(implementation);

    return tokenMetadata.symbol();
  }

  /**
   * @dev Upgrades the CodexRecordProxy to point at a new implementation. Only callable by the owner.
   *  Only upgrade the token after extensive testing has been done. The storage is append only.
   *  The new token must inherit from the previous token so the shape of the storage is maintained.
   * @param _version The version of the token
   * @param _implementation The address at which the implementation is available
   */
  function upgradeTo(string _version, address _implementation) public onlyOwner {
    require(
      keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(version)),
      "The version cannot be the same");

    require(
      _implementation != implementation,
      "The implementation cannot be the same");

    require(
      _implementation != address(0),
      "The implementation cannot be the 0 address");

    version = _version;
    implementation = _implementation;

    emit Upgraded(version, implementation);
  }
}