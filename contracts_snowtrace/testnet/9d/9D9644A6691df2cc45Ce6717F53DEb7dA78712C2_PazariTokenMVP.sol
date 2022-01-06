/**
 * @title PazariTokenMVP - Version: 0.1.0
 *
 * @dev Modification of the standard ERC1155 token contract for use
 * on the Pazari digital marketplace. These are one-time-payment
 * tokens, and are used for ownership verification after a file
 * has been purchased.
 *
 * Because these are 1155 tokens, creators can mint fungible and
 * non-fungible tokens, depending upon the item they wish to sell.
 * However, they are not transferrable to anyone who isn't an
 * owner of the contract. These tokens are pseudo-NFTs.
 *
 * All tokenHolders are tracked inside of each tokenID's TokenProps,
 * which makes airdrops much easier to accommodate.
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Dependencies/IERC1155.sol";
import "../Dependencies/IERC1155Receiver.sol";
import "../Dependencies/IERC1155MetadataURI.sol";
import "../Dependencies/Address.sol";
import "../Dependencies/Context.sol";
import "../Dependencies/ERC165.sol";
import "../Dependencies/Ownable.sol";
import "../Marketplace/Marketplace.sol";
import "./IPazariTokenMVP.sol";

contract PazariTokenMVP is Context, ERC165, IERC1155MetadataURI {
  using Address for address;

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) private _balances;

  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Restricts access to sensitive functions to only the owner(s) of this contract
  // This is specified during deployment, and more owners can be added later
  mapping(address => bool) private isOwner;

  // Returns tokenOwner index value for an address and a tokenID
  // token owner's address => tokenID => tokenOwner[] index value
  // Used by burn() and burnBatch() to avoid looping over tokenOwner[] arrays
  mapping(address => mapping(uint256 => uint256)) public tokenOwnerIndex;

  // Public array of all TokenProps structs created
  // Newest tokenID is tokenIDs.length
  TokenProps[] public tokenIDs;

  /**
   * @dev Struct to track token properties.
   *
   * note I decided to include tokenID here since tokenID - 1 is needed for tokenIDs[],
   * which may get confusing. We can use the tokenID property to double-check that we
   * are accessing the correct token's properties. It also looks and feels more intuitive
   * as well for a struct that tells us everything we need to know about a tokenID.
   */
  struct TokenProps {
    uint256 tokenID; // ID of token
    string uri; // IPFS URI where public metadata is located
    uint256 totalSupply; // Circulating/minted supply;
    uint256 supplyCap; // Max supply of tokens that can exist;
    bool isMintable; // Token can be minted;
    address[] tokenHolders; // All holders of this token, if fungible
  }

  /**
   * @param _contractOwners Array of all operators that do not require approval to handle
   * transferFrom() operations. Default is the Pazari Marketplace contract, but more operators
   * can be passed in. Operators are mostly responsible for minting new tokens.
   */
  constructor(address[] memory _contractOwners) {
    super;
    for (uint256 i = 0; i < _contractOwners.length; i++) {
      _operatorApprovals[_msgSender()][_contractOwners[i]] = true;
      isOwner[_contractOwners[i]] = true;

      emit ApprovalForAll(_msgSender(), _contractOwners[i], true);
    }
  }

  /**
   * @dev Checks if _tokenID is mintable or not:
   * True = Standard Edition, can be minted -- supplyCap == 0 (DEFAULT)
   * False = Limited Edition, cannot be minted -- supplyCap >= totalSupply
   */
  modifier isMintable(uint256 _tokenID) {
    require(tokenIDs[_tokenID - 1].isMintable, "Minting disabled");
    _;
  }

  /**
   * @dev Restricts access to the owner(s) of the contract
   */
  modifier onlyOwners() {
    require(isOwner[msg.sender], "Only contract owners permitted");
    _;
  }

  /**
   * @dev Adds a new owner address, only owners can call
   */
  function addOwner(address _newOwner) external onlyOwners {
    _operatorApprovals[msg.sender][_newOwner] = true;
    isOwner[_newOwner] = true;

    emit ApprovalForAll(msg.sender, _newOwner, true);
  }

  /**
   * @dev Overloaded version of ownsToken(), checks multiple tokenIDs against a single address and
   * returns an array of bools indicating ownership for each _tokenID[i].
   *
   * @param _tokenIDs Array of tokenIDs to check ownership of
   * @param _owner Wallet address being checked
   *
   * This function is intended for use on sellers' websites in the future, when they can copy some
   * boilerplate code from us to use for creating a "Connect Wallet" button that will check for
   * token ownership across a range of _tokenIDs for whoever connects their wallet.
   */

  function ownsToken(uint256[] memory _tokenIDs, address _owner) public view returns (bool[] memory) {
    bool[] memory hasToken = new bool[](_tokenIDs.length);
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      uint256 tokenID = _tokenIDs[i];
      if (balanceOf(_owner, tokenID) != 0) {
        hasToken[i] = true;
      } else {
        hasToken[i] = false;
      }
    }
    return hasToken;
  }

  /**
   * @dev Creates a new Pazari Token
   *
   * @param _newURI URL that points to item's public metadata
   * @param _isMintable Can tokens be minted? DEFAULT: True
   * @param _amount Amount of tokens to create
   * @param _supplyCap Maximum supply cap. DEFAULT: 0 (infinite supply)
   */
  function createNewToken(
    string memory _newURI,
    uint256 _amount,
    uint256 _supplyCap,
    bool _isMintable
  ) external onlyOwners {
    // If _amount == 0, then supply is infinite
    if (_amount == 0) {
      _amount = type(uint256).max;
    }
    // If _supplyCap > 0, then require _amount <= _supplyCap
    if (_supplyCap > 0) {
      require(_amount <= _supplyCap, "Amount exceeds supply cap");
    }
    // If _supplyCap == 0, then set _supplyCap to max value
    else {
      _supplyCap = type(uint256).max;
    }

    _createToken(_newURI, _isMintable, _amount, _supplyCap);
  }

  function _createToken(
    string memory _newURI,
    bool _isMintable,
    uint256 _amount,
    uint256 _supplyCap
  ) internal {
    address[] memory tokenHolders;
    TokenProps memory newToken = TokenProps(
      tokenIDs.length + 1,
      _newURI,
      _amount,
      _supplyCap,
      _isMintable,
      tokenHolders
    );
    tokenIDs.push(newToken);

    require(_mint(_msgSender(), newToken.tokenID, _amount, ""), "Minting failed");
  }

  /**
   * @dev Use this function for producing either ERC721-style collections of many unique tokens or for
   * uploading a whole collection of works with varying token amounts.
   *
   * See createNewToken() for description of parameters.
   */
  function batchCreateTokens(
    string[] memory _newURIs,
    bool[] calldata _isMintable,
    uint256[] calldata _amounts,
    uint256[] calldata _supplyCaps
  ) external onlyOwners returns (bool) {
    // Check that all arrays are same length
    require(
      _newURIs.length == _isMintable.length &&
        _isMintable.length == _amounts.length &&
        _amounts.length == _supplyCaps.length,
      "Data fields must have same length"
    );

    // Iterate through input arrays, create new token on each iteration
    for (uint256 i = 0; i <= _newURIs.length; i++) {
      string memory newURI = _newURIs[i];
      bool isMintable_ = _isMintable[i];
      uint256 amount = _amounts[i];
      uint256 supplyCap = _supplyCaps[i];

      _createToken(newURI, isMintable_, amount, supplyCap);
    }
    return true;
  }

  /**
   * @dev Mints more copies of a created token.
   *
   * If seller provided isMintable == false, then this function will revert
   */
  function mint(
    address _mintTo,
    uint256 _tokenID,
    uint256 _amount,
    string memory,
    bytes memory
  ) external onlyOwners isMintable(_tokenID) returns (bool) {
    TokenProps memory tokenProperties = tokenIDs[_tokenID - 1];
    require(tokenProperties.totalSupply > 0, "Token does not exist");
    if (tokenProperties.supplyCap != 0) {
      // Check that new amount does not exceed the supply cap
      require(tokenProperties.totalSupply + _amount <= tokenProperties.supplyCap, "Amount exceeds cap");
    }
    _mint(_mintTo, _tokenID, _amount, "");
    return true;
  }

  /**
   * @dev Overloaded version of airdropTokens() that can airdrop multiple tokenIDs to each _recipients[j]
   * @param _tokenIDs Token being airdropped
   * @param _amounts Amount of tokens
   * @param _recipients Array of all airdrop recipients
   * @return Success bool
   */
  function airdropTokens(
    uint256[] memory _tokenIDs,
    uint256[] memory _amounts,
    address[] memory _recipients
  ) external onlyOwners returns (bool) {
    require(_amounts.length == _tokenIDs.length, "Amounts and tokenIDs must be same length");
    uint256 i; // TokenID and amount counter
    uint256 j; // Recipients counter
    // Iterate through each tokenID:
    for (i = 0; i < _tokenIDs.length; i++) {
      require(balanceOf(_msgSender(), _tokenIDs[i]) >= _recipients.length, "Not enough tokens for airdrop");
      // Iterate through recipients, transfer tokenID if recipient != address(0)
      for (j = 0; j < _recipients.length; j++) {
        if (_recipients[j] == address(0)) continue;
        // Skip address(0)
        else _safeTransferFrom(_msgSender(), _recipients[j], _tokenIDs[i], _amounts[i], "");
      }
    }
    return true;
  }

  /**
   * @dev This overloaded version will send _tokenToDrop to every valid address in the tokenHolders
   * array found at tokenIDs[_tokenToCheck]. This is much simpler to call, but cannot be given an
   * arbitrary array of recipients for the airdrop.
   */

  function airdropTokens(
    uint256 _tokenToDrop,
    uint256 _tokenToCheck,
    uint256 _amount
  ) external onlyOwners returns (bool) {
    address[] memory tokenHolders = tokenIDs[_tokenToCheck - 1].tokenHolders;
    require(balanceOf(_msgSender(), _tokenToDrop) >= tokenHolders.length * _amount, "Insufficient tokens");

    for (uint256 i = 0; i < tokenHolders.length; i++) {
      if (tokenHolders[i] == address(0)) continue;
      else _safeTransferFrom(_msgSender(), tokenHolders[i], _tokenToDrop, _amount, "");
    }
    return true;
  }

  /**
   * -----------------------------------
   *     ERC1155 STANDARD FUNCTIONS
   * -----------------------------------
   */

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev This implementation returns the URI stored for any _tokenID,
   * overwrites ERC1155's uri() function while maintaining compatibility
   * with OpenSea's standards.
   */
  function uri(uint256 _tokenID) public view virtual override returns (string memory) {
    return tokenIDs[_tokenID - 1].uri;
  }

  /**
   * @dev External function that updates URI
   *
   * Only the contract owner(s) may update content URI
   */
  function setURI(string memory _newURI, uint256 _tokenID) external onlyOwners {
    _setURI(_newURI, _tokenID);
  }

  /**
   * @dev Internal function that updates URI;
   */
  function _setURI(string memory _newURI, uint256 _tokenID) internal virtual {
    tokenIDs[_tokenID - 1].uri = _newURI;
  }

  /**
   * @dev See {IERC1155-balanceOf}.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
    require(account != address(0), "ERC1155: balance query for the zero address");
    return _balances[id][account];
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    override
    returns (uint256[] memory)
  {
    require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(_msgSender() != operator, "ERC1155: setting approval status for self");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */
  function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[account][operator];
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override {
    require(isOwner[from], "PazariToken: Caller is not an owner");
    _safeTransferFrom(from, to, id, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override {
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      "ERC1155: transfer caller is not creator nor approved"
    );
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
    _balances[id][from] = fromBalance - amount;
    _balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
      _balances[id][from] = fromBalance - amount;
      _balances[id][to] += amount;
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  /**
   * @dev Burns copies of a token from a token owner's address.
   *
   * This can be called by anyone, and if they burn all of their tokens then
   * their address in tokenOwners[tokenID] will be set to address(0). However,
   * their tokenOwnerIndex[] value will not be deleted, as it will be used to
   * put them back on the list of tokenOwners if they receive another token.
   */
  function burn(uint256 _tokenID, uint256 _amount) external returns (bool) {
    _burn(msg.sender, _tokenID, _amount);
    if (balanceOf(msg.sender, _tokenID) == 0) {
      tokenIDs[_tokenID - 1].tokenHolders[tokenOwnerIndex[msg.sender][_tokenID]] = address(0);
    }
    return true;
  }

  /**
   * @dev Burns a batch of tokens from the caller's address.
   *
   * This can be called by anyone, and if they burn all of their tokens then
   * their address in tokenOwners[tokenID] will be set to address(0). However,
   * their tokenOwnerIndex[] value will not be deleted, as it will be used to
   * put them back on the list of tokenOwners if they receive another token.
   */
  function burnBatch(uint256[] calldata _tokenIDs, uint256[] calldata _amounts) external returns (bool) {
    _burnBatch(msg.sender, _tokenIDs, _amounts);
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      if (balanceOf(msg.sender, _tokenIDs[i]) == 0) {
        tokenIDs[_tokenIDs[i] - 1].tokenHolders[tokenOwnerIndex[msg.sender][_tokenIDs[i]]] = address(0);
      }
    }
    return true;
  }

  /**
   * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual returns (bool) {
    require(account != address(0), "ERC1155: mint to the zero address");

    address operator = _msgSender();

    //_beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

    _balances[id][account] += amount;
    emit TransferSingle(operator, address(0), account, id, amount);

    _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    return true;
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual returns (bool) {
    require(to != address(0), "ERC1155: mint to the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    return true;
  }

  /**
   * @dev Destroys `amount` tokens of token type `id` from `account`
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens of token type `id`.
   */
  function _burn(
    address account,
    uint256 id,
    uint256 amount
  ) internal virtual returns (bool) {
    require(account != address(0), "ERC1155: burn from the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

    uint256 accountBalance = _balances[id][account];
    require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
    _balances[id][account] = accountBalance - amount;

    emit TransferSingle(operator, account, address(0), id, amount);
    return true;
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   */
  function _burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual returns (bool) {
    require(account != address(0), "ERC1155: burn from the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 accountBalance = _balances[id][account];
      require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
      _balances[id][account] = accountBalance - amount;
    }

    emit TransferBatch(operator, account, address(0), ids, amounts);
    return true;
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning, as well as batched variants.
   *
   * The same hook is called on both single and batched variants. For single
   * transfers, the length of the `id` and `amount` arrays will be 1.
   *
   * Calling conditions (for each `id` and `amount` pair):
   *
   * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * of token type `id` will be  transferred to `to`.
   * - When `from` is zero, `amount` tokens of token type `id` will be minted
   * for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
   * will be burned.
   * - `from` and `to` are never both zero.
   * - `ids` and `amounts` have the same, non-zero length.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address,
    address,
    address to,
    uint256[] memory ids,
    uint256[] memory,
    bytes memory
  ) internal virtual {
    bool[] memory tempBools = ownsToken(ids, to);
    // If recipient does not own a token, then add their address to tokenHolders
    for (uint256 i = 0; i < ids.length; i++) {
      if (tempBools[i]) {
        tokenIDs[ids[i] - 1].tokenHolders.push(to);
      }
    }
  }

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        if (response != IERC1155Receiver(to).onERC1155Received.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
        bytes4 response
      ) {
        if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  /**
   * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
   * transfers.
   */
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

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
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory);

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
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

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
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
  /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);

  /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
  /**
   * @dev Returns the URI for token type `id`.
   *
   * If the `\{id\}` substring is present in the URI, it must be replaced by
   * clients with the actual token type ID.
   */
  function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain`call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
  /*
   * Commented out this function since it doesn't make sense to include it.
   * Renouncing ownership will completely remove a creator's ability to
   * interact with their token contract, which becomes an attack vector
   * that could have serious consequences for our creators.
   */
  /*
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    */

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Dependencies/Counters.sol";
import "../Dependencies/IERC20Metadata.sol";
import "../Dependencies/ERC1155Holder.sol";
import "../Dependencies/IERC1155.sol";
import "../Dependencies/Context.sol";
import "../PaymentRouter/IPaymentRouter.sol";

contract Marketplace is ERC1155Holder, Context {
  using Counters for Counters.Counter;

  // Counter for items with forSale == false
  Counters.Counter private itemsSoldOut;

  // Struct for market items being sold;
  struct MarketItem {
    uint256 itemID;
    address tokenContract;
    uint256 tokenID;
    uint256 amount;
    address owner;
    uint256 price;
    address paymentContract;
    bool isPush;
    bytes32 routeID;
    bool routeMutable;
    bool forSale;
    uint256 itemLimit;
  }

  // Array of all MarketItems ever created
  MarketItem[] public marketItems;

  // Maps a seller's address to an array of all itemIDs they have created
  // seller's address => itemIDs
  mapping(address => uint256[]) public sellersMarketItems;

  // Maps a contract's address and a token's ID to its corresponding itemId
  // tokenContract address + tokenID => itemID
  mapping(address => mapping(uint256 => uint256)) public tokenMap;

  // Address of PaymentRouter contract
  IPaymentRouter public immutable paymentRouter;

  // Fires when a new MarketItem is created;
  event MarketItemCreated(
    uint256 indexed itemID,
    address indexed nftContract,
    uint256 indexed tokenID,
    address seller,
    uint256 price,
    uint256 amount,
    address paymentToken
  );

  // Fires when a MarketItem is sold;
  event MarketItemSold(uint256 indexed itemID, uint256 amount, address owner);

  // Fires when a creator restocks MarketItems that are sold out
  event ItemRestocked(uint256 indexed itemID, uint256 amount);

  // Fires when a MarketItem's last token is bought
  event ItemSoldOut(uint256 indexed itemID);

  // Fires when forSale is toggled on or off for an itemID
  event ForSaleToggled(uint256 itemID, bool forSale);

  // Fires when a creator pulls a MarketItem's stock from the Marketplace
  event StockPulled(uint256 itemID, uint256 amount);

  // Fires when market item details are modified
  event MarketItemChanged(
    uint256 itemID,
    uint256 price,
    address paymentContract,
    bool isPush,
    bytes32 routeID,
    uint256 itemLimit
  );

  // Restricts access to the seller of the item
  modifier onlyOwner(uint256 _itemID) {
    require(_itemID < marketItems.length, "Item does not exist");
    require(marketItems[_itemID].owner == _msgSender(), "Unauthorized: Only seller");
    _;
  }

  constructor(address _paymentRouter) {
    //Connect to payment router contract
    paymentRouter = IPaymentRouter(_paymentRouter);
  }

  /**
   * @notice Creates a MarketItem struct and assigns it an itemID
   *
   * @param _tokenContract Token contract address of the item being sold
   * @param _ownerAddress Owner's address that can access modifyMarketItem() (MVP: msg.sender)
   * @param _tokenID The token contract ID of the item being sold
   * @param _amount The amount of items available for purchase (MVP: 0)
   * @param _price The price--in payment tokens--of the item being sold
   * @param _paymentContract Contract address of token accepted for payment (MVP: stablecoin)
   * @param _isPush Tells PaymentRouter to use push or pull function for this item (MVP: true)
   * @param _forSale Sets whether item is immediately up for sale (MVP: true)
   * @param _routeID The routeID of the payment route assigned to this item
   * @param _itemLimit How many items a buyer can own, 0 == no limit (MVP: 1)
   * @param _routeMutable Assigns mutability to the routeID, keep false for most items (MVP: false)
   * @return itemID ItemID of the market item
   *
   * @dev Front-end must call IERC1155.setApprovalForAll(marketAddress, true) for any ERC1155 token
   * that is NOT a Pazari1155 contract. Pazari1155 will have auto-approval for Marketplace.
   */

  function createMarketItem(
    address _tokenContract,
    address _ownerAddress,
    uint256 _tokenID,
    uint256 _amount,
    uint256 _price,
    address _paymentContract,
    bool _isPush,
    bool _forSale,
    bytes32 _routeID,
    uint256 _itemLimit,
    bool _routeMutable
  ) external returns (uint256 itemID) {
    /* ========== CHECKS ========== */
    require(tokenMap[_tokenContract][_tokenID] == 0, "Item already exists");
    require(_paymentContract != address(0), "Invalid payment token contract address");
    (, , bool isActive) = paymentRouter.paymentRouteID(_routeID);
    require(isActive, "Payment route inactive");

    // If _amount == 0, then move entire token balance to Marketplace
    if (_amount == 0) {
      _amount = IERC1155(_tokenContract).balanceOf(_msgSender(), _tokenID);
    }

    /* ========== EFFECTS ========== */

    // Store MarketItem data
    itemID = _createMarketItem(
      _tokenContract,
      _ownerAddress,
      _tokenID,
      _amount,
      _price,
      _paymentContract,
      _isPush,
      _forSale,
      _routeID,
      _itemLimit,
      _routeMutable
    );

    /* ========== INTERACTIONS ========== */

    // Transfer tokens from seller to Marketplace
    IERC1155(_tokenContract).safeTransferFrom(_msgSender(), address(this), _tokenID, _amount, "");

    // Check that Marketplace's internal balance matches the token's balanceOf() value
    MarketItem memory item = marketItems[itemID - 1];
    assert(IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) == item.amount);
  }

  /**
   * @dev Private function that updates internal variables and storage for a new MarketItem
   */
  function _createMarketItem(
    address _tokenContract,
    address _ownerAddress,
    uint256 _tokenID,
    uint256 _amount,
    uint256 _price,
    address _paymentContract,
    bool _isPush,
    bool _forSale,
    bytes32 _routeID,
    uint256 _itemLimit,
    bool _routeMutable
  ) private returns (uint256 itemID) {
    // If itemLimit == 0, then there is no itemLimit, use type(uint256).max to make itemLimit infinite
    if (_itemLimit == 0) {
      _itemLimit = type(uint256).max;
    }
    // If price == 0, then the item is free and only one copy can be owned
    if (_price == 0) {
      _itemLimit = 1;
    }

    // Add + 1 so itemID 0 will never exist and can be used for checks
    itemID = marketItems.length + 1;

    // Store new MarketItem in local variable
    MarketItem memory item = MarketItem(
      itemID,
      _tokenContract,
      _tokenID,
      _amount,
      _ownerAddress,
      _price,
      _paymentContract,
      _isPush,
      _routeID,
      _routeMutable,
      _forSale,
      _itemLimit
    );

    // Pushes MarketItem to marketItems[]
    marketItems.push(item);

    // Push itemID to sellersMarketItems mapping array
    // _msgSender == sellerAddress
    sellersMarketItems[_ownerAddress].push(itemID);

    // Assign itemID to tokenMap mapping
    tokenMap[_tokenContract][_tokenID] = itemID;

    // Emits MarketItemCreated event
    // _msgSender == sellerAddress
    emit MarketItemCreated(
      itemID,
      _tokenContract,
      _tokenID,
      _ownerAddress,
      _price,
      _amount,
      _paymentContract
    );
  }

  /**
   * @notice Purchases an _amount of market item itemID
   *
   * @param _itemID Market ID of item being bought
   * @param _amount Amount of item itemID being purchased (MVP: 1)
   * @return bool Success boolean
   *
   * @dev Providing _amount == 0 will purchase the item's full itemLimit.
   */
  function buyMarketItem(uint256 _itemID, uint256 _amount) external returns (bool) {
    // Pull data from itemID's MarketItem struct
    MarketItem memory item = marketItems[_itemID - 1];
    // If _amount == 0, then purchase the itemLimit - balanceOf(buyer)
    // This simplifies logic for purchasing itemLimit on front-end
    if (_amount == 0) {
      _amount = item.itemLimit - IERC1155(item.tokenContract).balanceOf(msg.sender, item.tokenID);
    }
    // Define total cost of purchase
    uint256 totalCost = item.price * _amount;

    /* ========== CHECKS ========== */

    require(_itemID <= marketItems.length, "Item does not exist");
    require(item.forSale, "Item not for sale");
    require(item.amount > 0, "Item sold out");
    require(_msgSender() != item.owner, "Can't buy your own item");
    require(
      IERC1155(item.tokenContract).balanceOf(_msgSender(), item.tokenID) + _amount <= item.itemLimit,
      "Purchase exceeds item limit"
    );

    /* ========== EFFECTS ========== */

    // If buy order exceeds all available stock, then:
    if (item.amount <= _amount) {
      itemsSoldOut.increment(); // Increment counter variable for items sold out
      _amount = item.amount; // Set _amount to the item's remaining inventory
      marketItems[_itemID - 1].forSale = false; // Take item off the market
      emit ItemSoldOut(item.itemID); // Emit itemSoldOut event
    }

    // Adjust Marketplace's inventory
    marketItems[_itemID - 1].amount -= _amount;
    // Emit MarketItemSold
    emit MarketItemSold(item.itemID, _amount, _msgSender());

    /* ========== INTERACTIONS ========== */
    IERC20(item.paymentContract).approve(address(this), totalCost);

    // Pull payment tokens from msg.sender to Marketplace
    IERC20(item.paymentContract).transferFrom(_msgSender(), address(this), totalCost);

    // Approve payment tokens for transfer to PaymentRouter
    IERC20(item.paymentContract).approve(address(paymentRouter), totalCost);

    // Send ERC20 tokens through PaymentRouter, isPush determines which function is used
    // note PaymentRouter functions make external calls to ERC20 contracts, thus they are interactions
    item.isPush
      ? paymentRouter.pushTokens(item.routeID, item.paymentContract, address(this), totalCost) // Pushes tokens to recipients
      : paymentRouter.holdTokens(item.routeID, item.paymentContract, address(this), totalCost); // Holds tokens for pull collection

    // Call market item's token contract and transfer token from Marketplace to buyer
    IERC1155(item.tokenContract).safeTransferFrom(address(this), _msgSender(), item.tokenID, _amount, "");

    //assert(IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) == item.amount);
    return true;
  }

  /**
   * @notice Transfers more stock to a MarketItem, requires minting more tokens first and setting
   * approval for Marketplace
   *
   * @param _itemID MarketItem ID
   * @param _amount Amount of tokens being restocked
   */
  function restockItem(uint256 _itemID, uint256 _amount) external onlyOwner(_itemID) {
    /* ========== CHECKS ========== */
    require(marketItems.length < _itemID, "MarketItem does not exist");
    MarketItem memory item = marketItems[_itemID];

    /* ========== EFFECTS ========== */
    marketItems[_itemID].amount += _amount;
    emit ItemRestocked(_itemID, _amount);

    /* ========== INTERACTIONS ========== */
    IERC1155(item.tokenContract).safeTransferFrom(item.owner, address(this), item.tokenID, _amount, "");

    assert(IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) == item.amount);
  }

  /**
   * @notice Removes _amount of item tokens for _itemID and transfers back to seller's wallet
   *
   * @param _itemID MarketItem's ID
   * @param _amount Amount of tokens being pulled from Marketplace, 0 == pull all tokens
   */
  function pullStock(uint256 _itemID, uint256 _amount) external onlyOwner(_itemID) {
    /* ========== CHECKS ========== */
    // itemID will always be <= marketItems.length, but cannot be > marketItems.length
    require(_itemID <= marketItems.length, "MarketItem does not exist");
    // Store initial values
    MarketItem memory item = marketItems[_itemID];
    require(item.amount >= _amount, "Not enough inventory to pull");

    // Pulls all remaining tokens if _amount == 0
    if (_amount == 0) {
      _amount = item.amount;
    }

    /* ========== EFFECTS ========== */
    marketItems[_itemID].amount -= _amount;

    /* ========== INTERACTIONS ========== */
    IERC1155(item.tokenContract).safeTransferFrom(address(this), _msgSender(), item.tokenID, _amount, "");

    emit StockPulled(_itemID, _amount);

    // Assert internal balances updated correctly, item.amount was initial amount
    assert(marketItems[_itemID].amount < item.amount);
  }

  /**
   * @notice Function that allows item creator to change price, accepted payment
   * token, whether token uses push or pull routes, and payment route.
   *
   * @param _itemID Market item ID
   * @param _price Market price in stablecoins (_price == 0 => _itemLimit = 1)
   * @param _paymentContract Contract address of token accepted for payment
   * @param _isPush Tells PaymentRouter to use push or pull function
   * @param _routeID Payment route ID, only mutable if routeMutable == true
   * @param _itemLimit Buyer's purchase limit for item (_itemLimit == 0 => no limit)
   * @return Sucess boolean
   *
   * @dev What cannot be modified:
   * - Token contract address
   * - Token contract token ID
   * - Seller of market item
   * - RouteID mutability
   * - Item's forSale status
   *
   * @dev If _itemLimit and price are set to 0, then price stays at 0 but _itemLimit is set to 1.
   */
  function modifyMarketItem(
    uint256 _itemID,
    uint256 _price,
    address _paymentContract,
    bool _isPush,
    bytes32 _routeID,
    uint256 _itemLimit
  ) external onlyOwner(_itemID) returns (bool) {
    MarketItem memory oldItem = marketItems[_itemID];

    // If the payment route is not mutable then set the input equal to the old routeID
    if (!oldItem.routeMutable || _routeID == 0) {
      _routeID = oldItem.routeID;
    }
    // If itemLimit == 0, then there is no itemLimit, use type(uint256).max to make itemLimit infinite
    if (_itemLimit == 0) {
      _itemLimit = type(uint256).max;
    }

    marketItems[_itemID] = MarketItem(
      _itemID,
      oldItem.tokenContract,
      oldItem.tokenID,
      oldItem.amount,
      oldItem.owner,
      _price,
      _paymentContract,
      _isPush,
      _routeID,
      oldItem.routeMutable,
      oldItem.forSale,
      _itemLimit
    );

    emit MarketItemChanged(_itemID, _price, _paymentContract, _isPush, _routeID, _itemLimit);
    return true;
  }

  /**
   * @notice Toggles whether an item is for sale or not
   *
   * @dev Use this function to activate/deactivate items for sale on market. Only items that are
   * forSale will be returned by getInStockItems().
   *
   * @param _itemID Marketplace ID of item for sale
   */
  function toggleForSale(uint256 _itemID) external onlyOwner(_itemID) {
    if (marketItems[_itemID].forSale) {
      itemsSoldOut.increment();
      marketItems[_itemID].forSale = false;
    } else {
      itemsSoldOut.decrement();
      marketItems[_itemID].forSale = true;
    }

    // Event added
    emit ForSaleToggled(_itemID, marketItems[_itemID].forSale);
  }

  // DELETE BEFORE PRODUCTION, USED FOR MIGRATION TESTING ONLY
  /**
   * @notice Helper functions to retrieve the last and next created itemIDs
   *
   * note These are mostly for testing purposes. I'm using them to dynamically store the value of each
   * itemID in testing. I don't know any way to store a function's return value in migration tests, so
   * I just made helper functions to assist with this. These are useless for production.
   *
   */
  function getLastItemID() public view returns (uint256 itemID) {
    itemID = marketItems.length;
  }

  // DELETE BEFORE PRODUCTION, USED FOR MIGRATION TESTING ONLY
  function getNextItemID() public view returns (uint256 itemID) {
    itemID = marketItems.length + 1;
  }

  /**
   * @notice Returns an array of all items for sale on marketplace
   */
  function getItemsForSale() public view returns (MarketItem[] memory) {
    // Fetch total item count, both sold and unsold
    uint256 itemCount = marketItems.length;
    // Calculate total unsold items
    uint256 unsoldItemCount = itemCount - itemsSoldOut.current();

    // Create empty array of all unsold MarketItem structs with fixed length unsoldItemCount
    MarketItem[] memory items = new MarketItem[](unsoldItemCount);

    uint256 i; // itemID counter for ALL market items, starts at 1
    uint256 j; // items[] index counter for forSale market items, starts at 0

    // Loop that populates the items[] array
    for (i = 1; j < unsoldItemCount || i <= itemCount; i++) {
      if (marketItems[i - 1].forSale) {
        MarketItem memory unsoldItem = marketItems[i - 1];
        items[j] = unsoldItem; // Assign unsoldItem to items[j]
        j++; // Increment j
      }
    }
    // Return the array of unsold items
    return (items);
  }

  /**
   * @notice Getter function for all itemIDs with forSale.
   */
  function getItemIDsForSale() public view returns (uint256[] memory itemIDs) {
    uint256 itemCount = marketItems.length;
    uint256 unsoldItemCount = itemCount - itemsSoldOut.current();
    itemIDs = new uint256[](unsoldItemCount);

    uint256 i; // itemID counter for ALL market items, starts at 1
    uint256 j; // itemIDs[] index counter for forSale market items, starts at 0

    for (i = 0; j < unsoldItemCount || i < itemCount; i++) {
      if (marketItems[i].forSale) {
        itemIDs[j] = i; // Assign unsoldItem to items[j]
        j++; // Increment j
      }
    }
  }

  /**
   * @notice Returns an array of MarketItem structs given an arbitrary array of _itemIDs.
   */
  function getMarketItems(uint256[] memory _itemIDs) public view returns (MarketItem[] memory marketItems_) {
    marketItems_ = new MarketItem[](_itemIDs.length);
    for (uint256 i = 0; i < _itemIDs.length; i++) {
      marketItems_[i] = marketItems[_itemIDs[i]];
    }
  }

  /**
   * @notice Checks if an address owns a tokenID from a token contract
   *
   * @param _owner The token owner being checked
   * @param _tokenContract The contract address of the token being checked
   * @param _tokenID The token ID being checked
   */
  function ownsToken(
    address _owner,
    address _tokenContract,
    uint256 _tokenID
  ) public view returns (bool hasToken) {
    if (IERC1155(_tokenContract).balanceOf(_owner, _tokenID) != 0) {
      hasToken = true;
    } else hasToken = false;
  }
}

/**
 * @dev Interface for interacting with any PazariTokenMVP contract.
 *
 * Inherits from IERC1155MetadataURI, therefore all IERC1155 function
 * calls will work on a Pazari token. The IPazariTokenMVP interface
 * accesses the Pazari-specific functions of a Pazari token.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Dependencies/IERC1155MetadataURI.sol";

interface IPazariTokenMVP is IERC1155MetadataURI {
  /**
   * @dev Struct to track token properties.
   */
  struct TokenProps {
    string uri; // IPFS URI where public metadata is located
    uint256 totalSupply; // Total circulating supply of token;
    uint256 supplyCap; // Total supply of tokens that can exist (if isMintable == true, supplyCap == 0);
    bool isMintable; // Mintability: Token can be minted;
  }

  /**
   * @dev Accesses the tokenIDs[] array
   *
   * note _index = tokenID - 1
   */
  function tokenIDs(uint256 _index) external view returns (TokenProps memory);

  /**
   * @dev Returns an array of all holders of a _tokenID
   */
  function tokenOwners(uint256 _tokenID) external view returns (address[] memory);

  /**
   * @dev Returns an _owner's index value in a tokenOwners[_tokenID] array.
   *
   * note Use this to know where inside a tokenOwners[_tokenID] array an _owner is.
   */
  function tokenOwnerIndex(address _owner, uint256 _tokenID) external view returns (uint256 index);

  /**
   * @dev Checks if _owner(s) own _tokenID(s). Three overloaded functions can take in any
   * number of tokenIDs and owner addresses that addresses three cases:
   *
   * Case 1: Caller needs to know if _owner holds _tokenID
   * Case 2: Caller needs to know if _owner holds any _tokenIDs
   * Case 3: Caller needs to know which _owners hold which _tokenIDs
   *
   * note The only reason to consider using these functions instead of balanceOf() is so the
   * front-end can receive a boolean as a response and not need to write additional logic
   * to compare numbers and make decisions. Just call ownsToken() and you'll know right away
   * if the address owns that token or not. Use these for token ownership gateways. If
   * calling balanceOf() from the front-end isn't too inconvenient, then we can remove these
   * getter functions entirely, or move them to an external utility contract.
   */
  //function ownsToken(uint256 _tokenID, address _owner) external view returns (bool);

  function ownsToken(uint256[] memory _tokenIDs, address _owner)
    external
    view
    returns (bool[] memory hasToken);

  //function ownsToken(uint256[] memory _tokenIDs, address[] memory _owners) external view returns (bool[][] memory hasTokens);

  /**
   * Performs an airdrop for three different cases:
   *
   * Case 1: An arbitrary list of _recipients will be transferred _amount of _tokenID
   * Case 2: An arbitrary list of _recipients will be transferred _amount of each _tokenIDs[i]
   * Case 3: _amount of _tokenToDrop will be transferred to all _recipients who own _tokenToCheck
   *
   * I chose to use Case 2, since it seems to be the most flexible, and I only have room for 1 function
   */
  //function airdropTokens(uint256 _tokenID, uint256 _amount, address[] memory _recipients) external returns (bool);

  function airdropTokens(
    uint256[] memory _tokenIDs,
    uint256[] memory _amounts,
    address[] memory _recipients
  ) external returns (bool);

  //function airdropTokens(uint256 _tokenToDrop, uint256 _tokenToCheck, uint256 _amount) external returns (bool);

  /**
   * @dev Creates a new Pazari Token
   *
   * @param _newURI URL that points to item's public metadata
   * @param _isMintable Can tokens be minted? DEFAULT: True
   * @param _amount Amount of tokens to create
   * @param _supplyCap Maximum supply cap. DEFAULT: 0 (infinite supply)
   */
  function createNewToken(
    string memory _newURI,
    uint256 _amount,
    uint256 _supplyCap,
    bool _isMintable
  ) external;

  /**
   * @dev Use this function for producing either ERC721-style collections of many unique tokens or for
   * uploading a whole collection of works with varying token amounts.
   *
   * See createNewToken() for description of parameters.
   */
  function batchCreateTokens(
    string[] memory _newURIs,
    bool[] calldata _isMintable,
    uint256[] calldata _amounts,
    uint256[] calldata _supplyCaps
  ) external returns (bool);

  /**
   * @dev Mints more copies of an existing token (NOT NEEDED FOR MVP)
   *
   * If the token creator provided isMintable == false for createNewToken(), then
   * this function will revert. This function is only for "standard edition" type
   * of files, and only for sellers who minted a few tokens.
   */
  function mint(
    address _mintTo,
    uint256 _tokenID,
    uint256 _amount,
    string memory,
    bytes memory
  ) external returns (bool);

  /**
   * @dev Updates token's URI, only contract owners may call
   */
  function setURI(string memory _newURI, uint256 _tokenID) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    unchecked {
      counter._value += 1;
    }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, "Counter: decrement overflow");
    unchecked {
      counter._value = value - 1;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPaymentRouter {
  // Fires when a new payment route is created
  event RouteCreated(address indexed creator, bytes32 routeID, address[] recipients, uint16[] commissions);

  // Fires when a route creator changes route tax
  event RouteTaxChanged(bytes32 routeID, uint16 newTax);

  // Fires when tokens are deposited into a payment route for holding
  event TokensHeld(bytes32 routeID, address tokenAddress, uint256 amount);

  // Fires when tokens are collected from holding by a recipient
  event TokensCollected(address indexed recipient, address tokenAddress, uint256 amount);

  // Fires when route is actived or deactivated
  event RouteToggled(bytes32 indexed routeID, bool isActive, uint256 timestamp);

  // Fires when a route has processed a push-transfer operation
  event TransferReceipt(
    address indexed sender,
    bytes32 routeID,
    address tokenContract,
    uint256 amount,
    uint256 tax,
    uint256 timeStamp
  );

  // Fires when a push-transfer operation fails
  event TransferFailed(
    address indexed sender,
    bytes32 routeID,
    uint256 payment,
    uint256 timestamp,
    address recipient
  );

  /**
   * @notice Returns the properties of a PaymentRoute struct for _routeID
   */
  function paymentRouteID(bytes32 _routeID)
    external
    view
    returns (
      address,
      uint16,
      bool
    );

  /**
   * @notice Returns a balance of tokens/stablecoins ready for collection
   *
   * @param _recipientAddress Address of recipient who can collect tokens
   * @param _tokenContract Contract address of tokens/stablecoins to be collected
   */
  function tokenBalanceToCollect(address _recipientAddress, address _tokenContract)
    external
    view
    returns (uint256);

  /**
   * @notice Returns an array of all routeIDs created by an address
   * @param _creatorAddress Address of route creator
   */
  function creatorRoutes(address _creatorAddress) external view returns (bytes32[] memory);

  /**
   * @notice External function to transfer tokens from msg.sender to all recipients[].
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being transferred
   * @param _senderAddress Wallet address of token sender
   * @param _amount Amount of tokens being routed
   */
  function pushTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external returns (bool);

  /**
   * @notice External function that deposits and sorts tokens for collection, tokens are
   * divided up by each recipient's commission rate
   *
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being deposited for collection
   * @param _senderAddress Address of token sender
   * @param _amount Amount of tokens held in escrow by payment route
   * @return success boolean
   */
  function holdTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external returns (bool);

  /**
   * @notice Collects all earnings stored in PaymentRouter
   *
   * @param _tokenAddress Contract address of payment token to be collected
   * @return success boolean
   */
  function pullTokens(address _tokenAddress) external returns (bool);

  /**
   * @notice Opens a new payment route
   *
   * @param _recipients Array of all recipient addresses for this payment route
   * @param _commissions Array of all recipients' commissions--in percentages with two decimals
   * @return routeID Hash of the created PaymentRoute
   */
  function openPaymentRoute(
    address[] memory _recipients,
    uint16[] memory _commissions,
    uint16 _routeTax
  ) external returns (bytes32 routeID);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
  }
}