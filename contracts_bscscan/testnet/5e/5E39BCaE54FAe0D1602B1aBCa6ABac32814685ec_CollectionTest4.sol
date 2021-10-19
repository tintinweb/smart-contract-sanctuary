/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
  address private owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  function getOwner() public view returns (address) {
    return owner;
  }

}

interface IERC165 {
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

interface IERC1155TokenReceiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC1155 {
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event URI(string _amount, uint256 indexed _id);

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { codehash := extcodehash(account) }
    return (codehash != 0x0 && codehash != accountHash);
  }

}

abstract contract ERC1155 is IERC165 {
  using Address for address;


  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;

  mapping (address => uint256[]) private ownershipOfs;

  // Events
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event URI(string _uri, uint256 indexed _id);

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount >= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, _data);
  }

  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
  }

  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    // Update balances
    balances[_from][_id] = balances[_from][_id] - _amount; // Subtract amount
    balances[_to][_id] = balances[_to][_id] + _amount;     // Add amount

    // update ownership
    ownershipOfs[_to].push(_id);

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]] - _amounts[i];
      balances[_to][_ids[i]] = balances[_to][_ids[i]] + _amounts[i];

      // update ownership
        ownershipOfs[_to].push(_ids[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  function setApprovalForAll(address _operator, bool _approved)
    external
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function isApprovedForAll(address _owner, address _operator)
    public view virtual returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }

  function balanceOf(address _owner, uint256 _id)
    public view returns (uint256)
  {
    return balances[_owner][_id];
  }

  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }

  bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

  bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

  function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
    if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
        _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
      return true;
    }
    return false;
  }

  function ownershipOf(address _address) external view returns (uint256[] memory) {
    uint256[] memory IDs = new uint256[](ownershipOfs[_address].length);
    uint counter;
    for(uint i=0; i<ownershipOfs[_address].length; i++) {
        if ( balanceOf( _address, ownershipOfs[_address][i] ) > 0 ) {
            IDs[counter] = ownershipOfs[_address][i];
            counter++;
        }
    }
    return IDs;
  }
  
  function appendOwnership(address _address, uint256 _id) internal {
      ownershipOfs[_address].push(_id);
  }

}

abstract contract ERC1155MintBurn is ERC1155 {

  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id] + _amount;

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, _data);
  }

  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]] + _amounts[i];
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, _data);
  }

  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    //Substract _amount
    balances[_from][_id] = balances[_from][_id] - _amount;

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nBurn = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]] - _amounts[i];
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }

}

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, ERC1155MintBurn, Ownable {

  address proxyRegistryAddress;
  uint256 private _currentTokenID = 0;
  mapping (uint256 => address) public creators;
  mapping (uint256 => uint256) public tokenSupply;
  mapping (uint256 => string) public URIs;
  mapping (address => bool) public minters;

  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  /**
   * @dev Require msg.sender to be the creator of the token id
   */
  modifier creatorOnly(uint256 _id) {
    require(creators[_id] == msg.sender, "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
    _;
  }

  /**
   * @dev Require msg.sender to own more than 0 of the token id
   */
  modifier ownersOnly(uint256 _id) {
    require(balances[msg.sender][_id] > 0, "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress
  ) public {
    name = _name;
    symbol = _symbol;
    proxyRegistryAddress = _proxyRegistryAddress;
    minters[msg.sender] = true;
  }

  function uri(
    uint256 _id
  ) public view returns (string memory) {
    require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
    return URIs[_id];
  }


  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }

  function create(
    address _to,
    address _creator,
    uint256 _id,
    uint256 _initialSupply,
    string calldata _uri,
    bytes calldata _data
  ) external returns (uint256) {
    require(minters[msg.sender], "Minter role is required.");

    creators[_id] = _creator;
    URIs[_id] = _uri;
    
    ERC1155.appendOwnership(_to, _id);

    _mint(_to, _id, _initialSupply, _data);
    tokenSupply[_id] = _initialSupply;
    return _id;
  }

  function batchCreate(
    address[] calldata _tos,
    address[] calldata _creators,
    uint256[] calldata _ids,
    uint256[] calldata _initialSupplys,
    string[] calldata _uris,
    bytes calldata _data
  ) external {
    require(minters[msg.sender], "Minter role is required.");
    require(_tos.length == _ids.length, "Invalid array length.");
    for(uint i=0; i<_tos.length; i++) {
        creators[_ids[i]] = _creators[i];
        URIs[_ids[i]] = _uris[i];
        
        ERC1155.appendOwnership(_tos[i], _ids[i]);

        _mint(_tos[i], _ids[i], _initialSupplys[i], _data);
        tokenSupply[_ids[i]] = _initialSupplys[i];
    }

  }


  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) public {
    require(minters[msg.sender], "Minter role is required.");
    _mint(_to, _id, _quantity, _data);
    tokenSupply[_id] = tokenSupply[_id] + _quantity;
  }

  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities,
    bytes memory _data
  ) public {
    require(minters[msg.sender], "Minter role is required.");
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 _id = _ids[i];
      uint256 quantity = _quantities[i];
      tokenSupply[_id] = tokenSupply[_id] + quantity;
    }
    _batchMint(_to, _ids, _quantities, _data);
  }

  function setCreator(
    address _to,
    uint256[] memory _ids
  ) public {
    require(_to != address(0), "ERC1155Tradable#setCreator: INVALID_ADDRESS.");
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 id = _ids[i];
      _setCreator(_to, id);
    }
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view override returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
  {
      creators[_id] = _to;
  }

  function _exists(
    uint256 _id
  ) internal view returns (bool) {
    return creators[_id] != address(0);
  }



  function setMinterRole(address _address, bool _permission) external onlyOwner {
    minters[_address] = _permission;
  }

  function setBatchURI(uint256[] calldata _ids, string calldata _uri) external {
    require(minters[msg.sender], "Minter role is required.");
    for(uint i=0; i<_ids.length; i++) {
        URIs[_ids[i]] = _uri;
    }
  }

  function setURI(uint256 _id, string calldata _uri) external {
    require(minters[msg.sender], "Minter role is required.");
    URIs[_id] = _uri;
  }
  

}

contract CollectionTest4 is ERC1155Tradable {

  constructor(address _proxyRegistryAddress)
  ERC1155Tradable(
    "Testing on BSC",
    "CT",
    _proxyRegistryAddress
  ) public {

  }

  function contractURI() public view returns (string memory) {
    return "https://metadata.tahu.digital/c/ethereum/mainnet/collection-1";
  }
  
}