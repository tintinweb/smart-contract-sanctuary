pragma solidity ^0.8.0;


contract CyblocAccessControl {

  address payable public owner;
  address public operator;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyOperator() {
    require(msg.sender == operator);
    _;
  }

  function setOwner(address payable _newOwner) external onlyOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
  }

  function setOperator(address _newOperator) external onlyOwner {
    operator = _newOperator;
  }

  function withdrawBalance() external onlyOwner {
    owner.transfer(address(this).balance);
  }

}

pragma solidity ^0.8.0;


import "./erc721/CyblocERC721.sol";


// solium-disable-next-line no-empty-blocks
contract CyblocCore is CyblocERC721 {
  struct Cybloc {
    uint256 genes;
    uint256 bornAt;
  }

  Cybloc[] Cyblocs;

  event CyblocSpawned(uint256 indexed _CyblocId, address indexed _owner, uint256 _genes);

  // function CyblocCore() public {
  //   Cyblocs.push(Cybloc(0, now)); // The void Cybloc
  //   _spawnCybloc(0, msg.sender); // Will be Puff
  //   _spawnCybloc(0, msg.sender); // Will be Kotaro
  //   _spawnCybloc(0, msg.sender); // Will be Ginger
  //   _spawnCybloc(0, msg.sender); // Will be Stella
  // }

  function getCybloc(
    uint256 _CyblocId
  )
    external
    view
    mustBeValidToken(_CyblocId)
    returns (uint256 /* _genes */, uint256 /* _bornAt */)
  {
    Cybloc storage _Cybloc = Cyblocs[_CyblocId];
    return (_Cybloc.genes, _Cybloc.bornAt);
  }

  function spawnCybloc(
    uint256 _genes,
    address _owner
  )
    external
    onlySpawner
    whenSpawningAllowed(_genes, _owner)
    returns (uint256)
  {
    return _spawnCybloc(_genes, _owner);
  }

  function _spawnCybloc(uint256 _genes, address _owner) private returns (uint) {
    Cybloc memory _Cybloc = Cybloc({
                            genes: _genes, 
                            bornAt: uint256(block.timestamp)});

    Cyblocs.push(_Cybloc);
    uint256 newCyblocId = Cyblocs.length - 1;
    _mint(_owner, newCyblocId);
    emit CyblocSpawned(newCyblocId, _owner, _genes);

    return newCyblocId;
  }
 
}

pragma solidity ^0.8.0;


import "./CyblocManager.sol";


contract CyblocDependency {

  address public whitelistSetterAddress;

  CyblocSpawningManager public spawningManager;
  CyblocRetirementManager public retirementManager;
  CyblocMarketplaceManager public marketplaceManager;
  CyblocGeneManager public geneManager;

  mapping (address => bool) public whitelistedSpawner;
  mapping (address => bool) public whitelistedByeSayer;
  mapping (address => bool) public whitelistedMarketplace;
  mapping (address => bool) public whitelistedGeneScientist;

  constructor() public {
    whitelistSetterAddress = msg.sender;
  }

  modifier onlyWhitelistSetter() {
    require(msg.sender == whitelistSetterAddress);
    _;
  }

  modifier whenSpawningAllowed(uint256 _genes, address _owner) {
    require(
      address(spawningManager) == address(0) ||
        spawningManager.isSpawningAllowed(_genes, _owner)
    );
    _;
  }

  modifier whenRebirthAllowed(uint256 _CyblocId, uint256 _genes) {
    require(
      address(spawningManager) == address(0) ||
        spawningManager.isRebirthAllowed(_CyblocId, _genes)
    );
    _;
  }

  modifier whenRetirementAllowed(uint256 _CyblocId, bool _rip) {
    require(
      address(retirementManager) == address(0) ||
        retirementManager.isRetirementAllowed(_CyblocId, _rip)
    );
    _;
  }

  modifier whenTransferAllowed(address _from, address _to, uint256 _CyblocId) {
    require(
      address(marketplaceManager) == address(0) ||
        marketplaceManager.isTransferAllowed(_from, _to, _CyblocId)
    );
    _;
  }

  modifier whenEvolvementAllowed(uint256 _CyblocId, uint256 _newGenes) {
    require(
      address(geneManager) == address(0) ||
        geneManager.isEvolvementAllowed(_CyblocId, _newGenes)
    );
    _;
  }

  modifier onlySpawner() {
    require(whitelistedSpawner[msg.sender]);
    _;
  }

  modifier onlyByeSayer() {
    require(whitelistedByeSayer[msg.sender]);
    _;
  }

  modifier onlyMarketplace() {
    require(whitelistedMarketplace[msg.sender]);
    _;
  }

  modifier onlyGeneScientist() {
    require(whitelistedGeneScientist[msg.sender]);
    _;
  }

  /*
   * @dev Setting the whitelist setter address to `address(0)` would be a irreversible process.
   *  This is to lock changes to Cybloc's contracts after their development is done.
   */
  function setWhitelistSetter(address _newSetter) external onlyWhitelistSetter {
    whitelistSetterAddress = _newSetter;
  }

  function setSpawningManager(address _manager) external onlyWhitelistSetter {
    spawningManager = CyblocSpawningManager(_manager);
  }

  function setRetirementManager(address _manager) external onlyWhitelistSetter {
    retirementManager = CyblocRetirementManager(_manager);
  }

  function setMarketplaceManager(address _manager) external onlyWhitelistSetter {
    marketplaceManager = CyblocMarketplaceManager(_manager);
  }

  function setGeneManager(address _manager) external onlyWhitelistSetter {
    geneManager = CyblocGeneManager(_manager);
  }

  function setSpawner(address _spawner, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedSpawner[_spawner] != _whitelisted);
    whitelistedSpawner[_spawner] = _whitelisted;
  }

  function setByeSayer(address _byeSayer, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedByeSayer[_byeSayer] != _whitelisted);
    whitelistedByeSayer[_byeSayer] = _whitelisted;
  }

  function setMarketplace(address _marketplace, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedMarketplace[_marketplace] != _whitelisted);
    whitelistedMarketplace[_marketplace] = _whitelisted;
  }

  function setGeneScientist(address _geneScientist, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedGeneScientist[_geneScientist] != _whitelisted);
    whitelistedGeneScientist[_geneScientist] = _whitelisted;
  }
}

pragma solidity ^0.8.0;


interface CyblocSpawningManager {
	function isSpawningAllowed(uint256 _genes, address _owner) external returns (bool);
  function isRebirthAllowed(uint256 _CyblocId, uint256 _genes) external returns (bool);
}

interface CyblocRetirementManager {
  function isRetirementAllowed(uint256 _CyblocId, bool _rip) external returns (bool);
}

interface CyblocMarketplaceManager {
  function isTransferAllowed(address _from, address _to, uint256 _CyblocId) external returns (bool);
}

interface CyblocGeneManager {
  function isEvolvementAllowed(uint256 _CyblocId, uint256 _newGenes) external returns (bool);
}

pragma solidity ^0.8.0;


import "./CyblocERC721BaseEnumerable.sol";
import "./CyblocERC721Metadata.sol";


// solium-disable-next-line no-empty-blocks
contract CyblocERC721 is CyblocERC721BaseEnumerable, CyblocERC721Metadata {
}

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

import "../../erc/erc165/ERC165.sol";
import "../../erc/erc721/IERC721Base.sol";
import "../../erc/erc721/IERC721Enumerable.sol";
import "../../erc/erc721/IERC721TokenReceiver.sol";
import "../dependency/CyBlocDependency.sol";
import "../lifecycle/CyBlocPausable.sol";


contract CyblocERC721BaseEnumerable is ERC165, IERC721Base, IERC721Enumerable, CyblocDependency, CyblocPausable {
  using SafeMath for uint256;

  // @dev Total amount of tokens.
  uint256 private _totalTokens;

  // @dev Mapping from token index to ID.
  mapping (uint256 => uint256) private _overallTokenId;

  // @dev Mapping from token ID to index.
  mapping (uint256 => uint256) private _overallTokenIndex;

  // @dev Mapping from token ID to owner.
  mapping (uint256 => address) private _tokenOwner;

  // @dev For a given owner and a given operator, store whether
  //  the operator is allowed to manage tokens on behalf of the owner.
  mapping (address => mapping (address => bool)) private _tokenOperator;

  // @dev Mapping from token ID to approved address.
  mapping (uint256 => address) private _tokenApproval;

  // @dev Mapping from owner to list of owned token IDs.
  mapping (address => uint256[]) private _ownedTokens;

  // @dev Mapping from token ID to index in the owned token list.
  mapping (uint256 => uint256) private _ownedTokenIndex;

  constructor() public {
    supportedInterfaces[0x6466353c] = true; // ERC-721 Base
    supportedInterfaces[0x780e9d63] = true; // ERC-721 Enumerable
  }

  // solium-disable function-order

  modifier mustBeValidToken(uint256 _tokenId) {
    require(_tokenOwner[_tokenId] != address(0));
    _;
  }

  function _isTokenOwner(address _ownerToCheck, uint256 _tokenId) private view returns (bool) {
    return _tokenOwner[_tokenId] == _ownerToCheck;
  }

  function _isTokenOperator(address _operatorToCheck, uint256 _tokenId) private view returns (bool) {
    return whitelistedMarketplace[_operatorToCheck] ||
      _tokenOperator[_tokenOwner[_tokenId]][_operatorToCheck];
  }

  function _isApproved(address _approvedToCheck, uint256 _tokenId) private view returns (bool) {
    return _tokenApproval[_tokenId] == _approvedToCheck;
  }

  modifier onlyTokenOwner(uint256 _tokenId) {
    require(_isTokenOwner(msg.sender, _tokenId));
    _;
  }

  modifier onlyTokenOwnerOrOperator(uint256 _tokenId) {
    require(_isTokenOwner(msg.sender, _tokenId) || _isTokenOperator(msg.sender, _tokenId));
    _;
  }

  modifier onlyTokenAuthorized(uint256 _tokenId) {
    require(
      // solium-disable operator-whitespace
      _isTokenOwner(msg.sender, _tokenId) ||
        _isTokenOperator(msg.sender, _tokenId) ||
        _isApproved(msg.sender, _tokenId)
      // solium-enable operator-whitespace
    );
    _;
  }

  // ERC-721 Base

  function balanceOf(address _owner) override external view returns (uint256) {
    require(_owner != address(0));
    return _ownedTokens[_owner].length;
  }

  function _balanceOf(address _owner) private view returns (uint256) {
    require(_owner != address(0));
    return _ownedTokens[_owner].length;
  }

  function ownerOf(uint256 _tokenId) override external view mustBeValidToken(_tokenId) returns (address) {
    return _tokenOwner[_tokenId];
  }

  function _addTokenTo(address _to, uint256 _tokenId) private {
    require(_to != address(0));

    _tokenOwner[_tokenId] = _to;

    uint256 length = _ownedTokens[_to].length;
    _ownedTokens[_to].push(_tokenId);
    _ownedTokenIndex[_tokenId] = length;
  }

  function _mint(address _to, uint256 _tokenId) internal {
    require(_tokenOwner[_tokenId] == address(0));

    _addTokenTo(_to, _tokenId);

    _overallTokenId[_totalTokens] = _tokenId;
    _overallTokenIndex[_tokenId] = _totalTokens;
    _totalTokens = _totalTokens.add(1);

    emit Transfer(address(0), _to, _tokenId);
  }

  function _removeTokenFrom(address _from, uint256 _tokenId) private {
    require(_from != address(0));

    uint256 _tokenIndex = _ownedTokenIndex[_tokenId];
    uint256 _lastTokenIndex = _balanceOf(_from) - 1;
    uint256 _lastTokenId = _ownedTokens[_from][_lastTokenIndex];

    _tokenOwner[_tokenId] = address(0);

    // Insert the last token into the position previously occupied by the removed token.
    _ownedTokens[_from][_tokenIndex] = _lastTokenId;
    _ownedTokenIndex[_lastTokenId] = _tokenIndex;

    // Resize the array.
    delete _ownedTokens[_from][_lastTokenIndex];
    //_ownedTokens[_from].length--;

    // Remove the array if no more tokens are owned to prevent pollution.
    if (_ownedTokens[_from].length == 0) {
      delete _ownedTokens[_from];
    }

    // Update the index of the removed token.
    delete _ownedTokenIndex[_tokenId];
  }

  function _burn(uint256 _tokenId) internal {
    address _from = _tokenOwner[_tokenId];

    require(_from != address(0));

    _removeTokenFrom(_from, _tokenId);
    _totalTokens = _totalTokens.sub(1);

    uint256 _tokenIndex = _overallTokenIndex[_tokenId];
    uint256 _lastTokenId = _overallTokenId[_totalTokens];

    delete _overallTokenIndex[_tokenId];
    delete _overallTokenId[_totalTokens];
    _overallTokenId[_tokenIndex] = _lastTokenId;
    _overallTokenIndex[_lastTokenId] = _tokenIndex;

    emit Transfer(_from, address(0), _tokenId);
  }

  function _isContract(address _address) private view returns (bool) {
    uint _size;
    // solium-disable-next-line security/no-inline-assembly
    assembly { _size := extcodesize(_address) }
    return _size > 0;
  }

  function _transferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data,
    bool _check
  )
    internal
    mustBeValidToken(_tokenId)
    onlyTokenAuthorized(_tokenId)
    whenTransferAllowed(_from, _to, _tokenId)
  {
    require(_isTokenOwner(_from, _tokenId));
    require(_to != address(0));
    require(_to != _from);

    _removeTokenFrom(_from, _tokenId);

    delete _tokenApproval[_tokenId];
    emit Approval(_from, address(0), _tokenId);

    _addTokenTo(_to, _tokenId);

    if (_check && _isContract(_to)) {
      IERC721TokenReceiver(_to).onERC721Received{gas: 50000}(_from, _tokenId, _data);
    }

    emit Transfer(_from, _to, _tokenId);
  }

  // solium-disable arg-overflow

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) override external payable {
    _transferFrom(_from, _to, _tokenId, _data, true);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable {
    _transferFrom(_from, _to, _tokenId, "", true);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) override external payable {
    _transferFrom(_from, _to, _tokenId, "", false);
  }

  // solium-enable arg-overflow

  function approve(
    address _approved,
    uint256 _tokenId
  )
    override
    external
    payable
    mustBeValidToken(_tokenId)
    onlyTokenOwnerOrOperator(_tokenId)
    whenNotPaused
  {
    address _owner = _tokenOwner[_tokenId];

    require(_owner != _approved);
    require(_tokenApproval[_tokenId] != _approved);

    _tokenApproval[_tokenId] = _approved;

    emit Approval(_owner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) override external whenNotPaused {
    require(_tokenOperator[msg.sender][_operator] != _approved);
    _tokenOperator[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function getApproved(uint256 _tokenId) override external view mustBeValidToken(_tokenId) returns (address) {
    return _tokenApproval[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) override external view returns (bool) {
    return _tokenOperator[_owner][_operator];
  }

  // ERC-721 Enumerable

  function totalSupply() override external view returns (uint256) {
    return _totalTokens;
  }

  function tokenByIndex(uint256 _index) override external view returns (uint256) {
    require(_index < _totalTokens);
    return _overallTokenId[_index];
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) override external view returns (uint256 _tokenId) {
    require(_owner != address(0));
    require(_index < _ownedTokens[_owner].length);
    return _ownedTokens[_owner][_index];
  }
}

pragma solidity ^0.8.0;


import "../../erc/erc721/IERC721Metadata.sol";
import "./CyblocERC721BaseEnumerable.sol";


contract CyblocERC721Metadata is CyblocERC721BaseEnumerable, IERC721Metadata {
  string public tokenURIPrefix = "https://Axieinfinity.com/erc/721/Cyblocs/";
  string public tokenURISuffix = ".json";

  constructor() public {
    supportedInterfaces[0x5b5e139f] = true; // ERC-721 Metadata
  }

  function name() override external pure returns (string memory) {
    return "Cybloc";
  }

  function symbol() override external pure returns (string memory) {
    return "CYBLOC";
  }

  function setTokenURIAffixes(string memory _prefix, string memory _suffix) external onlyOperator {
    tokenURIPrefix = _prefix;
    tokenURISuffix = _suffix;
  }

  function tokenURI(
    uint256 _tokenId
  )
    override
    external
    view
    mustBeValidToken(_tokenId)
    returns (string memory)
  {
    bytes memory _tokenURIPrefixBytes = bytes(tokenURIPrefix);
    bytes memory _tokenURISuffixBytes = bytes(tokenURISuffix);
    uint256 _tmpTokenId = _tokenId;
    uint256 _length;

    do {
      _length++;
      _tmpTokenId /= 10;
    } while (_tmpTokenId > 0);

    bytes memory _tokenURIBytes = new bytes(_tokenURIPrefixBytes.length + _length + 5);
    uint256 _i = _tokenURIBytes.length - 6;

    _tmpTokenId = _tokenId;

    do {
      _tokenURIBytes[_i--] = bytes1(uint8(48 + _tmpTokenId % 10));
      _tmpTokenId /= 10;
    } while (_tmpTokenId > 0);

    for (_i = 0; _i < _tokenURIPrefixBytes.length; _i++) {
      _tokenURIBytes[_i] = _tokenURIPrefixBytes[_i];
    }

    for (_i = 0; _i < _tokenURISuffixBytes.length; _i++) {
      _tokenURIBytes[_tokenURIBytes.length + _i - 5] = _tokenURISuffixBytes[_i];
    }

    return string(_tokenURIBytes);
  }
}

pragma solidity ^0.8.0;


import "../CyblocAccessControl.sol";


contract CyblocPausable is CyblocAccessControl {

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }

  function pause() external onlyOperator whenNotPaused {
    paused = true;
  }

  function unpause() public onlyOperator whenPaused {
    paused = false;
  }
}

pragma solidity ^0.8.0;


import "./IERC165.sol";


contract ERC165 is IERC165 {
  /// @dev You must not set element 0xffffffff to true
  mapping (bytes4 => bool) internal supportedInterfaces;

  constructor() public {
    supportedInterfaces[0x01ffc9a7] = true; // ERC-165
  }

  function supportsInterface(bytes4 interfaceID) override external view returns (bool) {
    return supportedInterfaces[interfaceID];
  }
}

pragma solidity ^0.8.0;


/// @title ERC-165 Standard Interface Detection
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
interface IERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

pragma solidity ^0.8.0;


/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x6466353c
interface IERC721Base /* is IERC165  */ {
  /// @dev This emits when ownership of any NFT changes by any mechanism.
  ///  This event emits when NFTs are created (`from` == 0) and destroyed
  ///  (`to` == 0). Exception: during contract creation, any number of NFTs
  ///  may be created and assigned without emitting Transfer. At the time of
  ///  any transfer, the approved address for that NFT (if any) is reset to none.
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

  /// @dev This emits when the approved address for an NFT is changed or
  ///  reaffirmed. The zero address indicates there is no approved address.
  ///  When a Transfer event emits, this also indicates that the approved
  ///  address for that NFT (if any) is reset to none.
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  /// @dev This emits when an operator is enabled or disabled for an owner.
  ///  The operator can manage all NFTs of the owner.
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param _owner An address for whom to query the balance
  /// @return The number of NFTs owned by `_owner`, possibly zero
  function balanceOf(address _owner) external view returns (uint256);

  /// @notice Find the owner of an NFT
  /// @param _tokenId The identifier for an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @return The address of the owner of the NFT
  function ownerOf(uint256 _tokenId) external view returns (address);

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
  ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `_to` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  /// @param _data Additional data with no specified format, sent in call to `_to`
  // solium-disable-next-line arg-overflow
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external payable;

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to []
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

  /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

  /// @notice Set or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param _approved The new approved NFT controller
  /// @param _tokenId The NFT to approve
  function approve(address _approved, uint256 _tokenId) external payable;

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all your asset.
  /// @dev Emits the ApprovalForAll event
  /// @param _operator Address to add to the set of authorized operators.
  /// @param _approved True if the operators is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved) external;

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `_tokenId` is not a valid NFT
  /// @param _tokenId The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint256 _tokenId) external view returns (address);

  /// @notice Query if an address is an authorized operator for another address
  /// @param _owner The address that owns the NFTs
  /// @param _operator The address that acts on behalf of the owner
  /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

pragma solidity ^0.8.0;


/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x780e9d63
interface IERC721Enumerable /* is IERC721Base */ {
  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint256);

  /// @notice Enumerate valid NFTs
  /// @dev Throws if `_index` >= `totalSupply()`.
  /// @param _index A counter less than `totalSupply()`
  /// @return The token identifier for the `_index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(uint256 _index) external view returns (uint256);

  /// @notice Enumerate NFTs assigned to an owner
  /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
  ///  `_owner` is the zero address, representing invalid NFTs.
  /// @param _owner An address where we are interested in NFTs owned by them
  /// @param _index A counter less than `balanceOf(_owner)`
  /// @return _tokenId The token identifier for the `_index`th NFT assigned to `_owner`, (sort order not specified)
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

pragma solidity ^0.8.0;


/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f
interface IERC721Metadata /* is IERC721Base */ {
  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external pure returns (string memory _name);

  /// @notice An abbreviated name for NFTs in this contract
  function symbol() external pure returns (string memory _symbol);

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;


/// @dev Note: the ERC-165 identifier for this interface is 0xf0b9e5ba
interface IERC721TokenReceiver {
  /// @notice Handle the receipt of an NFT
  /// @dev The ERC721 smart contract calls this function on the recipient
  ///  after a `transfer`. This function MAY throw to revert and reject the
  ///  transfer. This function MUST use 50,000 gas or less. Return of other
  ///  than the magic value MUST result in the transaction being reverted.
  ///  Note: the contract address is always the message sender.
  /// @param _from The sending address
  /// @param _tokenId The NFT identifier which is being transfered
  /// @param _data Additional data with no specified format
  /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  ///  unless throwing
	function onERC721Received(address _from, uint256 _tokenId, bytes memory _data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

