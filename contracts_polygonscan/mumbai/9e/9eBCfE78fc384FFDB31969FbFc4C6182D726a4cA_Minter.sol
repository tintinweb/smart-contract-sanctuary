/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Owned {

    address public owner;
    address public nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerNominated(address indexed newOwner);

    constructor(address _owner) {
        require(_owner != address(0),
            "Address cannot be 0");

        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    function nominateNewOwner(address _owner)
    external
    onlyOwner {
        nominatedOwner = _owner;

        emit OwnerNominated(_owner);
    }

    function acceptOwnership()
    external {
        require(msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership");

        emit OwnershipTransferred(owner, nominatedOwner);

        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
            "Only the contract owner may perform this action");
        _;
    }

}



pragma solidity 0.8.7;

contract AccessController is Owned {

  mapping(bytes32 => mapping(address => bool)) public roles;

  event AuthorizationUpdated(bytes32 role, address target, bool authorization);

  constructor(
    bytes32[] memory _roles,
    address[] memory _authAddresses,
    bool[] memory _authorizations,
    address _owner
  ) Owned(_owner) {
    require(_roles.length == _authAddresses.length && _roles.length == _authorizations.length,
      "Input lenghts not matched");

    for(uint i = 0; i < _roles.length; i++) {
      _setAuthorizations(_roles[i], _authAddresses[i], _authorizations[i]);
    }
  }

  function setAuthorizations(
    bytes32[] calldata _roles,
    address[] calldata _authAddresses,
    bool[] calldata _authorizations
  ) external
  onlyOwner {
    require(_roles.length == _authAddresses.length && _roles.length == _authorizations.length,
      "Input lenghts not matched");

    for(uint i = 0; i < _roles.length; i++) {
      _setAuthorizations(_roles[i], _authAddresses[i], _authorizations[i]);
    }
  }

  function _setAuthorizations(
    bytes32 _role,
    address _address,
    bool _authorization
  ) internal {
    roles[_role][_address] = _authorization;

    emit AuthorizationUpdated(_role, _address, _authorization);
  }

  modifier onlyRole(bytes32 _role, address _address) {
    require(roles[_role][_address],
      string(abi.encodePacked("Caller is not ", _role)));
    _;
  }

}



pragma solidity 0.8.7;

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



pragma solidity 0.8.7;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// OpenZeppelin Contracts v4.3.2 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.7;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}



pragma solidity ^0.8.7;

interface ISummoner is IERC721Enumerable {


  /** MUTATIVE **/

  function mint(address _to, uint _tokenId) external;

  function mintWithRespectiveURI(
    address _to,
    uint _tokenId,
    string calldata _uri,
    bool _exclusiveUri
  ) external;

  function burn(uint _tokenId) external;


  /** VIEWER **/

  function tokenURIVersion(uint tokenId) external view returns(string memory);

  function tokenBaseURI(uint uriVersion) external view returns(string memory);

  function tokenTailURI(uint uriVersion) external view returns(string memory);

  function tokenRespectiveURI(uint tokenId) external view returns(string memory uri, bool exclusive);

  function transferLocked(uint tokenId) external view returns(bool);

  function currentTokenURIVersion() external view returns(uint);

}



pragma solidity 0.8.7;

contract Minter is AccessController {

  struct Whitelist {
    uint8 mintCounts;
    bool whitelist;
  }

  ISummoner summoner;

  mapping(address => Whitelist) public whitelists;

  bytes32 constant private MINTER_AUTH_ROLE = "MINTER_AUTH_ROLE";

  uint public buyerPromotionAmount = 1 ether;

  uint8 public maxNumberOfWhitePayment = 2;
  uint64 public totalWhitelistSupply = 0;
  uint64 public totalOrdinarySupply = 0;

  address private dummyCollector;

  event BuyerPromotionAmountUpdated(uint newBuyerPromotionAmount);
  event MaxNumberOfWhitePaymentUpdated(uint8 newMaxWhitePayment);

  constructor(
    ISummoner _summoner,
    address _dummyCollector,
    bytes32[] memory _roles,
    address[] memory _authAddresses,
    bool[] memory _authorizations,
    address _owner
  ) AccessController(_roles, _authAddresses, _authorizations, _owner) {
    summoner = _summoner;
    dummyCollector = _dummyCollector;
  }

  receive() external payable {}

  function setBuyerPromotionAmount(uint _newAmount)
  external
  onlyOwner {
    buyerPromotionAmount = _newAmount;

    emit BuyerPromotionAmountUpdated(_newAmount);
  }

  function setMaxNumberOfWhitePayment(uint8 _newMaxNumberOfWhitePayment)
  external
  onlyOwner {
    maxNumberOfWhitePayment = _newMaxNumberOfWhitePayment;

    emit MaxNumberOfWhitePaymentUpdated(_newMaxNumberOfWhitePayment);
  }

  function setDummyCollector(address _newDummyCollector)
  external
  onlyOwner {
    require(_newDummyCollector != address(0),
      "collector cannot be empty");

    dummyCollector = _newDummyCollector;
  }

  function addWhitelists(address[] calldata _whitelists)
  external
  onlyOwner {
    for(uint i = 0; i < _whitelists.length; i++) {
      if(whitelists[_whitelists[i]].whitelist) {
        continue;
      }

      whitelists[_whitelists[i]] = Whitelist(0, true);
    }
  }

  function disableWhitelists(address[] calldata _toDisables)
  external
  onlyOwner {
    for(uint i = 0; i < _toDisables.length; i++) {
      delete whitelists[_toDisables[i]];
    }
  }

  function whiteMint(address[] calldata _recipients, uint[] calldata _tokenIds)
  external
  onlyRole(MINTER_AUTH_ROLE, msg.sender) {
    require(_recipients.length == _tokenIds.length,
      "Input length not matched");
    require(address(this).balance >= _recipients.length * buyerPromotionAmount,
      "Not enough promotion coins");

    for(uint i = 0; i < _recipients.length; i++) {
      address recipient =
        whitelists[_recipients[i]].whitelist && ++whitelists[_recipients[i]].mintCounts <= maxNumberOfWhitePayment ?
          _recipients[i] : dummyCollector;

      summoner.mint(recipient, _tokenIds[i]);

      _withdraw(payable(recipient), buyerPromotionAmount);

      totalWhitelistSupply++;
    }
  }

  function mint(address[] calldata _recipients, uint[] calldata _tokenIds)
  external
  onlyRole(MINTER_AUTH_ROLE, msg.sender) {
    require(_recipients.length == _tokenIds.length,
      "Input length not matched");
    require(address(this).balance >= _recipients.length * buyerPromotionAmount,
      "Not enough promotion coins");

    for(uint i = 0; i < _recipients.length; i++) {
      summoner.mint(_recipients[i], _tokenIds[i]);

      _withdraw(payable(_recipients[i]), buyerPromotionAmount);

      totalOrdinarySupply++;
    }
  }

  function withdrawAll(address payable _to)
  external
  onlyOwner {
    _withdraw(_to, address(this).balance);
  }

  function totalSupply()
  external view
  returns(uint) {
    return summoner.totalSupply();
  }

  function ownerOf(uint _tokenId)
  external view
  returns(address) {
    return summoner.ownerOf(_tokenId);
  }

  function _withdraw(address payable _to, uint _amount)
  internal {
    (bool sent, ) = _to.call{ value: _amount }("");

    require(sent,
      "Failed to withdraw");
  }

}