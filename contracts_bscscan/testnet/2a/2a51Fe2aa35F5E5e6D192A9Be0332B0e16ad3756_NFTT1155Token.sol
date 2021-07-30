// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC1155.sol';
import './Pausable.sol';
import './Counters.sol';
import "./Strings.sol";
import './SafeMath.sol';

// NFTTToken base on ERC1155 with Governance
contract NFTT1155Token is ERC1155, Pausable {
  using SafeMath for uint256;
  using Strings for uint256;

  using Counters for Counters.Counter;

  address private governance;
  address private pendingGovernance;
  mapping(address => bool) private minters;

  bytes32 public constant NFT_TREE_TYPE = keccak256("NFT_TREE_TYPE");
  bytes32 public constant NFT_ITEM_TYPE = keccak256("NFT_ITEM_TYPE");

  // Auto increase token id
  Counters.Counter private _tokenIdTracker;

  struct TokenMetadata {
    string uri; // token resource uri
    string name;
    string symbol;
    uint256 createdAt;
    uint256 totalSupply;
    uint256 cap; // max total supply of token
    bytes32 tokenType; // NFT Tree or NFT Item
  }

  // Mapping from token symbol to token ID
  mapping(string => uint256) private tokenSymbolMaping;

  // Mapping from token ID to token metadata
  mapping(uint256 => TokenMetadata) private tokenMetadatas;

  constructor(string memory uri_) Pausable() ERC1155(uri_) {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(msg.sender == governance, 'NFTT1155Token: !governance');
    _;
  }

  function setGovernance(address governance_) external virtual onlyGovernance {
    pendingGovernance = governance_;
  }

  function claimGovernance() external virtual {
    require(msg.sender == pendingGovernance, 'NFTT1155Token: !pendingGovernance');
    governance = pendingGovernance;
    delete pendingGovernance;
  }

  function addMinter(address minter_) external virtual onlyGovernance {
    minters[minter_] = true;
  }

  function removeMinter(address minter_) external virtual onlyGovernance {
    minters[minter_] = false;
  }

  /**
   * @dev Pauses all token transfers. See {Pausable-_pause}.
   *
   * Requirements:
   * - the caller must be the governance.
   */
  function pause() external virtual onlyGovernance {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers. See {Pausable-_unpause}.
   *
   * Requirements:
   * - the caller must be the governance.
   */
  function unpause() external virtual onlyGovernance {
    _unpause();
  }

  function getLastestTokenId() external view virtual returns (uint256) {
    return _tokenIdTracker.current();
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`.
   */
  function setBaseURI(string memory baseURI_) external virtual onlyGovernance {
    _setURI(baseURI_);

    emit ChangeBaseURI(baseURI_);
  }

  /**
   * @dev Return base uri of all token.
   */
  function baseURI() external view virtual returns (string memory) {
    return super.uri(0);
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * This implementation returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function uri(uint256 id_) public view virtual override returns (string memory) {
    require(exists(id_), 'NFTT1155Token: URI query for nonexistent token');

    string memory _tokenURI = tokenMetadatas[id_].uri;
    string memory _baseURI = super.uri(id_);

    // If there is no base URI, return the token URI.
    if (bytes(_baseURI).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(_baseURI, _tokenURI));
    }

    return string(abi.encodePacked(_baseURI, id_.toString()));
  }

  /**
   * @dev Sets `tokenURI` for `tokenId`.
   */
  function setTokenURI(uint256 id_, string memory tokenURI_) external virtual onlyGovernance {
    require(exists(id_), 'NFTT1155Token: URI set of nonexistent token');
    tokenMetadatas[id_].uri = tokenURI_;

    emit ChangeTokenURI(id_, tokenURI_);
  }

  /**
   * @dev Get token matadata of token id
   */
  function getTokenMetadata(uint256 id_) external view virtual returns (TokenMetadata memory) {
    require(exists(id_), 'NFTT1155Token: Metadata query for nonexistent token');
    return tokenMetadatas[id_];
  }

  /**
   * @dev Total amount of tokens in with a given id.
   */
  function totalSupply(uint256 id_) external view virtual returns (uint256) {
    return tokenMetadatas[id_].totalSupply;
  }

  /**
   * @dev Indicates weither any token exist with a given id, or not.
   */
  function exists(uint256 id_) public view virtual returns (bool) {
    return tokenMetadatas[id_].cap > 0;
  }

  /**
   * @dev Return token id mapping to symbol. Return 0 if token symbol is not exitst.
   */
  function getTokenIdFromSymbol(string memory symbol_) external view virtual returns (uint256) {
    return tokenSymbolMaping[symbol_];
  }

  /**
   * @dev See {ERC1155-_beforeTokenTransfer}.
   *
   * Requirements:
   * - minted tokens must not cause the total supply to go over the cap.
   */
  function _beforeTokenTransfer(
    address operator_,
    address from_,
    address to_,
    uint256[] memory ids_,
    uint256[] memory amounts_,
    bytes memory data_
  ) internal virtual override {
    super._beforeTokenTransfer(operator_, from_, to_, ids_, amounts_, data_);

    require(!paused(), 'NFTT1155Token: token transfer while paused');

    if (from_ == address(0)) {
      // When minting tokens
      require(
        tokenMetadatas[ids_[0]].totalSupply.add(amounts_[0]) <= tokenMetadatas[ids_[0]].cap,
        'NFTT1155Token: cap exceeded'
      );
    }
  }

  /**
   * @dev Creates `amount` new token for `to`. See {ERC1155-_mint}.
   *
   * Requirements:
   * - the caller must have the governance or minter.
   */
  function mint(
    address to_,
    string memory uri_,
    string memory name_,
    string memory symbol_,
    uint256 amount_,
    uint256 cap_,
    bytes32 tokenType_
  ) external virtual {
    require(msg.sender == governance || minters[msg.sender], 'NFTT1155Token: !governance, !minter');
    require(tokenType_ == NFT_TREE_TYPE || tokenType_ == NFT_ITEM_TYPE, 'NFTT1155Token: !tokenType');
    require(tokenSymbolMaping[symbol_] == 0, 'NFTT1155Token: !symbol');
    require(cap_ > 0, 'NFTT1155Token: !cap');

    _tokenIdTracker.increment();
    uint256 id = _tokenIdTracker.current();

    tokenSymbolMaping[symbol_] = id;
    tokenMetadatas[id] = TokenMetadata({
      uri: uri_,
      name: name_,
      symbol: symbol_,
      createdAt: block.timestamp,
      totalSupply: amount_,
      cap: cap_,
      tokenType: tokenType_
    });

    _mint(to_, id, amount_, '');

    emit AddNewToken(id);
  }

  /**
   * @dev Creates `amount` existed token for `to`. See {ERC1155-_mint}.
   *
   * Requirements:
   * - the caller must have the governance or minter.
   */
  function mintId(
    address to_,
    uint256 id_,
    uint256 amount_
  ) external virtual {
    require(msg.sender == governance || minters[msg.sender], 'NFTT1155Token: !governance, !minter');
    require(exists(id_), 'NFTT1155Token: token id is not exists');

    _mint(to_, id_, amount_, '');
    tokenMetadatas[id_].totalSupply += amount_;
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   */
  function burn(uint256 id_, uint256 amount_) external virtual {
    _burn(msg.sender, id_, amount_);
    tokenMetadatas[id_].totalSupply -= amount_;
  }

  event AddNewToken(uint256 tokenId_);
  event ChangeTokenURI(uint256 tokenId_, string newURI_);
  event ChangeBaseURI(string newBaseURI_);
}