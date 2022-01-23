/**
 * @title FactoryPazariTokenMVP
 *
 * This contract factory produces the PazariTokenMVP contract, which is the
 * primary token contract for Pazari MVP market items.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Tokens/PazariTokenMVP.sol";

contract FactoryPazariTokenMVP {
  /**
   * @notice Clones a new PazariTokenMVP contract
   * @param _contractOwners Array of all addresses that are admins of the new token contract
   *
   * @dev It is very important to include this factory's address in _contractOwners. If not,
   * then the logic in _msgSender() will use msg.sender instead of tx.origin, and the factory
   * will become the originalOwner of the new token contract--thus locking out the contract
   * creator. The alternative is to include the caller's wallet address in _contractOwners.
   * Normally we would set this inside the function, but this contract is right on the edge
   * of its bytecode size limit and can't fit much more logic inside it.
   */
  function newPazariTokenMVP(address[] memory _contractOwners) external returns (address newContract) {
    PazariTokenMVP _newContract = new PazariTokenMVP(_contractOwners);
    newContract = address(_newContract);
  }
}

/**
 * @title PazariTokenMVP - Version: 0.1.0
 *
 * @dev Modification of the standard ERC1155 token contract for use
 * on the Pazari digital marketplace. These are one-time-payment
 * tokens, and are used for ownership verification after a file
 * has been purchased.
 *
 * Pazari uses ERC1155 tokens so it can possess immediate support
 * for ERC1155 NFTs, and the PazariToken is a modified ERC1155
 * with limited transfer capabilities.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Dependencies/IERC1155.sol";
import "../Dependencies/IERC1155Receiver.sol";
import "../Dependencies/IERC1155MetadataURI.sol";
import "../Dependencies/Address.sol";
import "../Dependencies/ERC165.sol";
import "../Dependencies/Ownable.sol";
import "../Marketplace/Marketplace.sol";
import "./IPazariTokenMVP.sol";
import "./Pazari1155.sol";

contract PazariTokenMVP is Pazari1155 {
  using Address for address;

  // Fires when a new token is created through createNewToken()
  event TokenCreated(string URI, uint256 indexed tokenID, uint256 amount);

  // Fires when more tokens are minted from a pre-existing tokenID
  event TokensMinted(address indexed mintTo, uint256 indexed tokenID, uint256 amount);

  // Fires when tokens are transferred via airdropTokens()
  event TokensAirdropped(uint256 indexed tokenID, uint256 amount, uint256 timestamp);

  /**
   * @param _contractOwners Array of all addresses that have operator approval and
   * isAdmin status.
   */
  constructor(address[] memory _contractOwners) Pazari1155(_contractOwners) {}

  /**
   * @notice Returns TokenProps struct, only admins can call
   */
  function getTokenProps(uint256 _tokenID) public view onlyAdmin returns (TokenProps memory) {
    return tokenProps[_tokenID - 1];
  }

  /**
   * Returns tokenHolders array for tokenID, only admins can call
   */
  function getTokenHolders(uint256 _tokenID) public view onlyAdmin returns (address[] memory) {
    return tokenHolders[_tokenID];
  }

  /**
   * @notice Returns tokenHolderIndex value for an address and a tokenID
   * @dev All this does is returns the location of an address inside a tokenID's tokenHolders
   */
  function getTokenHolderIndex(address _tokenHolder, uint256 _tokenID)
    public
    view
    onlyAdmin
    returns (uint256)
  {
    return tokenHolderIndex[_tokenHolder][_tokenID];
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
  ) external onlyAdmin returns (uint256) {
    uint256 tokenID;
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

    tokenID = _createToken(_newURI, _isMintable, _amount, _supplyCap);
    return tokenID;
  }

  function _createToken(
    string memory _newURI,
    bool _isMintable,
    uint256 _amount,
    uint256 _supplyCap
  ) internal returns (uint256 tokenID) {
    // The zeroth tokenHolder is address(0)
    tokenHolderIndex[address(0)][tokenID] = 0;
    tokenHolders[tokenID].push(address(0));

    tokenID = tokenProps.length;
    // Create new TokenProps and push to tokenProps array
    TokenProps memory newToken = TokenProps(tokenProps.length, _newURI, _amount, _supplyCap, _isMintable);
    tokenProps.push(newToken);
    // Grab tokenID from newToken's struct
    tokenID = newToken.tokenID;

    // Mint tokens to _msgSender()
    require(_mint(_msgSender(), tokenID, _amount, ""), "Minting failed");

    emit TokenCreated(_newURI, tokenID, _amount);
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
  ) external onlyAdmin returns (bool) {
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
   * @notice Mints more units of a created token
   *
   * @dev Only available for tokens with isMintable == true
   *
   * @param _mintTo Address tokens were minted to (MVP: msg.sender)
   * @param _tokenID Token ID being minted
   * @param _amount Amount of tokenID to be minted
   * @return Bool Success bool
   *
   * @dev Emits TokensMinted event
   */
  function mint(
    address _mintTo,
    uint256 _tokenID,
    uint256 _amount,
    string memory,
    bytes memory
  ) external onlyAdmin returns (bool) {
    TokenProps memory tokenProperties = tokenProps[_tokenID - 1];
    require(tokenProperties.totalSupply > 0, "Token does not exist");
    require(tokenProps[_tokenID - 1].isMintable, "Minting disabled");
    if (tokenProperties.supplyCap != 0) {
      // Check that new amount does not exceed the supply cap
      require(tokenProperties.totalSupply + _amount <= tokenProperties.supplyCap, "Amount exceeds cap");
    }
    _mint(_mintTo, _tokenID, _amount, "");
    emit TokensMinted(_mintTo, _tokenID, _amount);
    return true;
  }

  /**
   * @dev Performs a multi-token airdrop of each _amounts[i] for each _[i] to each _recipients[j]
   *
   * @param _tokenIDs Tokens being airdropped
   * @param _amounts Amount of each token being sent to each recipient
   * @param _recipients All airdrop recipients
   * @return Success bool
   */
  function airdropTokens(
    uint256[] memory _tokenIDs,
    uint256[] memory _amounts,
    address[] memory _recipients
  ) external onlyAdmin returns (bool) {
    require(_amounts.length == _tokenIDs.length, "Amounts and tokenIds must be same length");
    uint256 i; // TokenID and amount counter
    uint256 j; // Recipients counter
    // Iterate through each tokenID being airdropped:
    for (i = 0; i < _tokenIDs.length; i++) {
      require(balanceOf(_msgSender(), _tokenIDs[i]) >= _recipients.length, "Not enough tokens for airdrop");
      // Iterate through recipients, transfer tokenID if recipient != address(0)
      // See burn() for why some addresses in tokenHolders may be address(0)
      for (j = 0; j < _recipients.length; j++) {
        if (_recipients[j] == address(0)) continue;
        // If found, then skip address(0)
        else _safeTransferFrom(_msgSender(), _recipients[j], _tokenIDs[i], _amounts[i], "");
      }
    }
    return true;
  }

  /**
   * @dev Overridden ERC1155 function, requires that the caller of the function
   * is an owner of the contract.
   *
   * @dev Transfers should only work for isAdmin => isAdmin and for isAdmin => !isAdmin,
   * but not for !isAdmin => !isAdmin. Only admins are allowed to transfer these tokens
   * to non-admins.
   *
   * @dev The logic gives instruction for when recipient is not admin but sender is, which
   * is permitted freely. This is like a store selling an item to someone. What is also
   * implied by this condition is that it is acceptable for recipients to transfer their
   * PazariTokens back to the sender/admin, which would happen during a refund. What is
   * also implied is that it is not acceptable for recipients to transfer their PazariTokens
   * to anyone else. These tokens are attached to downloadable content, and should NOT be
   * transferrable to non-admin addresses to protect the content.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external virtual override {
    // If recipient is not admin, then sender needs to be admin
    if (!isAdmin[to]) {
      require(isAdmin[from], "PazariToken: Only admins may send PazariTokens to non-admins");
    }
    _safeTransferFrom(from, to, id, amount, data);
  }

  /**
   * @dev This implementation returns the URI stored for any _tokenID,
   * overwrites ERC1155's uri() function while maintaining compatibility
   * with OpenSea's standards.
   */
  function uri(uint256 _tokenID) public view virtual override returns (string memory) {
    return tokenProps[_tokenID - 1].uri;
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
import "../Tokens/IPazariTokenMVP.sol";

contract AccessControlMP {
  // Maps admin addresses to bool
  mapping(address => bool) public isAdmin;

  // Maps itemIDs and admin addresses to bool
  mapping(uint256 => mapping(address => bool)) public isItemAdmin;

  // Mapping of all blacklisted addresses that are banned from Pazari Marketplace
  mapping(address => bool) public isBlacklisted;

  // Maps itemID to the address that created it
  mapping(uint256 => address) public itemCreator;

  string private errorMsgCallerNotAdmin;
  string private errorMsgAddressAlreadyAdmin;
  string private errorMsgAddressNotAdmin;

  // Used by noReentrantCalls
  address internal msgSender;
  uint256 private constant notEntered = 1;
  uint256 private constant entered = 2;
  uint256 private status;

  // Fires when Pazari admins are added/removed
  event AdminAdded(address indexed newAdmin, address indexed adminAuthorized, string memo, uint256 timestamp);
  event AdminRemoved(
    address indexed oldAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Fires when item admins are added or removed
  event ItemAdminAdded(
    uint256 indexed itemID,
    address indexed newAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );
  event ItemAdminRemoved(
    uint256 indexed itemID,
    address indexed oldAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Fires when an address is blacklisted/whitelisted from the Pazari Marketplace
  event AddressBlacklisted(
    address blacklistedAddress,
    address indexed adminAddress,
    string memo,
    uint256 timestamp
  );
  event AddressWhitelisted(
    address whitelistedAddress,
    address indexed adminAddress,
    string memo,
    uint256 timestamp
  );

  constructor(address[] memory _adminAddresses) {
    for (uint256 i = 0; i < _adminAddresses.length; i++) {
      isAdmin[_adminAddresses[i]] = true;
    }
    msgSender = address(this);
    status = notEntered;
    errorMsgCallerNotAdmin = "Marketplace: Caller is not admin";
    errorMsgAddressAlreadyAdmin = "Marketplace: Address is already an admin";
    errorMsgAddressNotAdmin = "Marketplace: Address is not an admin";
  }

  /**
   * @notice Returns tx.origin for any Pazari-owned admin contracts, returns msg.sender
   * for everything else. See PaymentRouter for more details.
   */
  function _msgSender() public view returns (address) {
    if (tx.origin != msg.sender && isAdmin[msg.sender]) {
      return tx.origin;
    } else return msg.sender;
  }

  // Adds an address to isAdmin mapping
  // Emits AdminAdded event
  function addAdmin(address _newAddress, string calldata _memo) external onlyAdmin returns (bool) {
    require(!isAdmin[_newAddress], errorMsgAddressAlreadyAdmin);

    isAdmin[_newAddress] = true;

    emit AdminAdded(_newAddress, tx.origin, _memo, block.timestamp);
    return true;
  }

  // Adds an address to isItemAdmin mapping
  // Emits ItemAdminAdded event
  function addItemAdmin(
    uint256 _itemID,
    address _newAddress,
    string calldata _memo
  ) external onlyItemAdmin(_itemID) returns (bool) {
    require(isItemAdmin[_itemID][msg.sender] && isItemAdmin[_itemID][tx.origin], errorMsgCallerNotAdmin);
    require(!isItemAdmin[_itemID][_newAddress], errorMsgAddressAlreadyAdmin);

    isItemAdmin[_itemID][_newAddress] = true;

    emit ItemAdminAdded(_itemID, _newAddress, _msgSender(), _memo, block.timestamp);
    return true;
  }

  // Removes an address from isAdmin mapping
  // Emits AdminRemoved event
  function removeAdmin(address _oldAddress, string calldata _memo) external onlyAdmin returns (bool) {
    require(isAdmin[_oldAddress], errorMsgAddressNotAdmin);

    isAdmin[_oldAddress] = false;

    emit AdminRemoved(_oldAddress, tx.origin, _memo, block.timestamp);
    return true;
  }

  // Removes an address from isItemAdmin mapping
  // Emits ItemAdminRemoved event
  function removeItemAdmin(
    uint256 _itemID,
    address _oldAddress,
    string calldata _memo
  ) external onlyItemAdmin(_itemID) returns (bool) {
    require(isItemAdmin[_itemID][msg.sender] && isItemAdmin[_itemID][tx.origin], errorMsgCallerNotAdmin);
    require(isItemAdmin[_itemID][_oldAddress], errorMsgAddressNotAdmin);
    require(itemCreator[_itemID] == _msgSender(), "Cannot remove item creator");

    isItemAdmin[_itemID][_oldAddress] = false;

    emit ItemAdminRemoved(_itemID, _oldAddress, _msgSender(), _memo, block.timestamp);
    return true;
  }

  /**
   * @notice Toggles isBlacklisted for an address. Can only be called by Pazari
   * Marketplace admins. Other contracts that implement address blacklisting
   * can call this contract's isBlacklisted mapping.
   *
   * @param _userAddress Address of user being black/whitelisted
   * @param _memo Provide contextual info/code for why user was black/whitelisted
   *
   * @dev Emits AddressBlacklisted event when _userAddress is blacklisted
   * @dev Emits AddressWhitelisted event when _userAddress is whitelisted
   */
  function toggleBlacklist(address _userAddress, string calldata _memo) external returns (bool) {
    require(isAdmin[msg.sender] && isAdmin[tx.origin], errorMsgCallerNotAdmin);
    require(!isAdmin[_userAddress], "Cannot blacklist admins");

    if (!isBlacklisted[_userAddress]) {
      isBlacklisted[_userAddress] = true;
      emit AddressBlacklisted(_userAddress, _msgSender(), _memo, block.timestamp);
    } else {
      isBlacklisted[_userAddress] = false;
      emit AddressWhitelisted(_userAddress, _msgSender(), _memo, block.timestamp);
    }

    return true;
  }

  /**
   * @notice Requires that both msg.sender and tx.origin be admins. This restricts all
   * calls to only Pazari-owned admin addresses, including wallets and contracts, and
   * eliminates phishing attacks.
   */
  modifier onlyAdmin() {
    require(isAdmin[msg.sender] && isAdmin[tx.origin], errorMsgCallerNotAdmin);
    _;
  }

  modifier noBlacklist() {
    require(!isBlacklisted[_msgSender()], "Caller cannot be blacklisted");
    _;
  }

  // Restricts access to admins of a MarketItem
  modifier onlyItemAdmin(uint256 _itemID) {
    require(
      itemCreator[_itemID] == _msgSender() || isItemAdmin[_itemID][_msgSender()] || isAdmin[_msgSender()],
      errorMsgCallerNotAdmin
    );
    _;
  }

  /**
   * @notice Provides defense against reentrancy calls
   * @dev msgSender is only used to avoid needless function calls, and
   * isn't part of the reentrancy guard. It is set back to this address
   * after every use to refund some of the gas spent on it.
   */
  modifier noReentrantCalls() {
    require(status == notEntered, "Reentrancy not allowed");
    status = entered; // Lock function
    msgSender = _msgSender(); // Store value of _msgSender()
    _;
    msgSender = address(this); // Reset msgSender
    status = notEntered; // Unlock function
  }
}

contract Marketplace is ERC1155Holder, AccessControlMP {
  using Counters for Counters.Counter;

  // Fires when a new MarketItem is created;
  event MarketItemCreated(
    uint256 indexed itemID,
    address indexed nftContract,
    uint256 tokenID,
    address indexed admin,
    uint256 price,
    uint256 amount,
    address paymentToken
  );

  // Fires when a MarketItem is sold;
  event MarketItemSold(uint256 indexed itemID, uint256 amount, address owner);

  // Fires when a MarketItem's last token is bought
  event ItemSoldOut(uint256 indexed itemID);

  // Fires when a creator restocks MarketItems that are sold out
  event ItemRestocked(uint256 indexed itemID, uint256 amount);

  // Fires when a creator pulls a MarketItem's stock from the Marketplace
  event ItemPulled(uint256 indexed itemID, uint256 amount);

  // Fires when forSale is toggled on or off for an itemID
  event ForSaleToggled(uint256 indexed itemID, bool forSale);

  // Fires when a MarketItem has been deleted
  event MarketItemDeleted(uint256 itemID, address indexed itemAdmin, uint256 timestamp);

  // Fires when market item details are modified
  event MarketItemChanged(
    uint256 indexed itemID,
    uint256 price,
    address paymentContract,
    bool isPush,
    bytes32 routeID,
    uint256 itemLimit
  );

  // Fires when admin recovers lost NFT(s)
  event NFTRecovered(
    address indexed tokenContract,
    uint256 indexed tokenID,
    address recipient,
    address indexed admin,
    string memo,
    uint256 timestamp
  );

  // Maps a seller's address to an array of all itemIDs they have created
  // seller's address => itemIDs
  mapping(address => uint256[]) public sellersMarketItems;

  // Maps a contract's address and a token's ID to its corresponding itemId
  // The purpose of this is to prevent duplicate items for same token
  // tokenContract address + tokenID => itemID
  mapping(address => mapping(uint256 => uint256)) public tokenMap;

  // Struct for market items being sold;
  struct MarketItem {
    uint256 itemID;
    uint256 tokenID;
    uint256 price;
    uint256 amount;
    uint256 itemLimit;
    bytes32 routeID;
    address tokenContract;
    address paymentContract;
    bool isPush;
    bool routeMutable;
    bool forSale;
  }

  // Counter for items with forSale == false
  Counters.Counter private itemsSoldOut;

  // Array of all MarketItems ever created
  MarketItem[] public marketItems;

  // Address of PaymentRouter contract
  IPaymentRouter public immutable iPaymentRouter;

  constructor(address _paymentRouter, address[] memory _admins) AccessControlMP(_admins) {
    //Connect to payment router contract
    iPaymentRouter = IPaymentRouter(_paymentRouter);
  }

  // Checks if an item was deleted or if _itemID is valid
  modifier itemExists(uint256 _itemID) {
    MarketItem memory item = marketItems[_itemID - 1];
    require(item.itemID == _itemID, "Item was deleted");
    require(_itemID <= marketItems.length, "Invalid itemID");
    _;
  }

  /**
   * @notice Creates a MarketItem struct and assigns it an itemID
   *
   * @param _tokenContract Token contract address of the item being sold
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
   */
  function createMarketItem(
    address _tokenContract,
    uint256 _tokenID,
    uint256 _amount,
    uint256 _price,
    address _paymentContract,
    bool _isPush,
    bool _forSale,
    bytes32 _routeID,
    uint256 _itemLimit,
    bool _routeMutable
  ) external noReentrantCalls noBlacklist returns (uint256 itemID) {
    MarketItem memory item = MarketItem({
      itemID: itemID,
      tokenContract: _tokenContract,
      tokenID: _tokenID,
      amount: _amount,
      price: _price,
      paymentContract: _paymentContract,
      isPush: _isPush,
      routeID: _routeID,
      routeMutable: _routeMutable,
      forSale: _forSale,
      itemLimit: _itemLimit
    });
    /* ========== CHECKS ========== */
    require(tokenMap[_tokenContract][_tokenID] == 0, "Item already exists");
    require(_paymentContract != address(0), "Invalid payment token contract address");
    (, , , bool isActive) = iPaymentRouter.paymentRouteID(_routeID);
    require(isActive, "Payment route inactive");

    // If _amount == 0, then move entire token balance to Marketplace
    if (_amount == 0) {
      item.amount = IERC1155(item.tokenContract).balanceOf(msgSender, item.tokenID);
    }

    /* ========== EFFECTS ========== */

    // Store MarketItem data
    itemID = _createMarketItem(item);

    /* ========== INTERACTIONS ========== */

    // Transfer tokens from seller to Marketplace
    IERC1155(_tokenContract).safeTransferFrom(_msgSender(), address(this), item.tokenID, item.amount, "");

    // Check that Marketplace's internal balance matches the token's balanceOf() value
    item = marketItems[itemID - 1];
    require(
      IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) >= item.amount,
      "Market received insufficient tokens"
    );
  }

  /**
   * @notice Lighter overload of createMarketItem
   *
   * @param _tokenContract Token contract address of the item being sold
   * @param _tokenID The token contract ID of the item being sold
   * @param _amount The amount of items available for purchase (MVP: 0)
   * @param _price The price--in payment tokens--of the item being sold
   * @param _paymentContract Contract address of token accepted for payment (MVP: stablecoin)
   * @param _routeID The routeID of the payment route assigned to this item
   * @return itemID ItemID of the market item
   */
  function createMarketItem(
    address _tokenContract,
    uint256 _tokenID,
    uint256 _amount,
    uint256 _price,
    address _paymentContract,
    bytes32 _routeID
  ) external noReentrantCalls noBlacklist returns (uint256 itemID) {
    MarketItem memory item = MarketItem({
      itemID: itemID,
      tokenContract: _tokenContract,
      tokenID: _tokenID,
      amount: _amount,
      price: _price,
      paymentContract: _paymentContract,
      isPush: true,
      routeID: _routeID,
      routeMutable: false,
      forSale: true,
      itemLimit: 1
    });

    /* ========== CHECKS ========== */
    require(tokenMap[_tokenContract][_tokenID] == 0, "Item already exists");
    require(_paymentContract != address(0), "Invalid payment token contract address");
    (, , , bool isActive) = iPaymentRouter.paymentRouteID(_routeID);
    require(isActive, "Payment route inactive");

    // If _amount == 0, then move entire token balance to Marketplace
    if (_amount == 0) {
      item.amount = IERC1155(_tokenContract).balanceOf(_msgSender(), _tokenID);
    }

    /* ========== EFFECTS ========== */

    // Store MarketItem data
    itemID = _createMarketItem(item);

    /* ========== INTERACTIONS ========== */

    // Transfer tokens from seller to Marketplace
    IERC1155(_tokenContract).safeTransferFrom(_msgSender(), address(this), _tokenID, item.amount, "");

    // Check that Marketplace's internal balance matches the token's balanceOf() value
    item = marketItems[itemID - 1];
    require(
      IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) >= item.amount,
      "Market did not receive tokens"
    );
  }

  /**
   * @dev Private function that updates internal variables and storage for a new MarketItem
   */
  function _createMarketItem(MarketItem memory item) private returns (uint256 itemID) {
    // If itemLimit == 0, then there is no itemLimit, use type(uint256).max to make itemLimit infinite
    if (item.itemLimit == 0) {
      item.itemLimit = type(uint256).max;
    }
    // If price == 0, then the item is free and only one copy can be owned
    if (item.price == 0) {
      item.itemLimit = 1;
    }

    // Define itemID
    itemID = marketItems.length + 1;
    // Update local variable's itemID
    item.itemID = itemID;
    // Push local variable to marketItems[]
    marketItems.push(item);

    // Push itemID to sellersMarketItems mapping array
    sellersMarketItems[msgSender].push(item.itemID);

    // Assign itemID to tokenMap mapping
    tokenMap[item.tokenContract][item.tokenID] = itemID;

    // Assign isItemAdmin and itemCreator to msgSender()
    itemCreator[itemID] = msgSender;
    isItemAdmin[itemID][msgSender] = true;

    // Emits MarketItemCreated event
    emit MarketItemCreated(
      itemID,
      item.tokenContract,
      item.tokenID,
      msgSender,
      item.price,
      item.amount,
      item.paymentContract
    );
  }

  /**
   * @dev Purchases an _amount of market item itemID
   *
   * @param _itemID Market ID of item being bought
   * @param _amount Amount of item itemID being purchased (MVP: 1)
   * @return bool Success boolean
   *
   * @dev Emits ItemSoldOut event
   *
   * note Providing _amount == 0 will purchase the item's full itemLimit
   * minus the buyer's existing balance.
   */
  function buyMarketItem(uint256 _itemID, uint256 _amount)
    external
    noReentrantCalls
    noBlacklist
    itemExists(_itemID)
    returns (bool)
  {
    // Pull data from itemID's MarketItem struct
    MarketItem memory item = marketItems[_itemID - 1];
    uint256 itemLimit = item.itemLimit;
    uint256 balance = IERC1155(item.tokenContract).balanceOf(_msgSender(), item.tokenID);
    uint256 initBuyersBalance = IERC1155(item.tokenContract).balanceOf(msgSender, item.tokenID);

    // Define total cost of purchase
    uint256 totalCost = item.price * _amount;

    /* ========== CHECKS ========== */
    require(
      !isItemAdmin[item.itemID][_msgSender()] || itemCreator[item.itemID] != _msgSender(),
      "Can't buy your own item"
    );
    require(item.amount > 0, "Item sold out");
    require(item.forSale, "Item not for sale");
    require(balance < itemLimit, "Buyer already owns the item limit");
    // If _amount == 0, then purchase itemLimit - balance
    // If _amount + balance surpasses itemLimit, then purchase itemLimit - balance
    if (_amount == 0 || _amount + balance > itemLimit) {
      _amount = itemLimit - balance;
    }

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
    require(IERC20(item.paymentContract).approve(address(this), totalCost), "ERC20 approval failure");

    // Pull payment tokens from msg.sender to Marketplace
    require(
      IERC20(item.paymentContract).transferFrom(_msgSender(), address(this), totalCost),
      "ERC20 transfer failure"
    );

    // Approve payment tokens for transfer to PaymentRouter
    require(
      IERC20(item.paymentContract).approve(address(iPaymentRouter), totalCost),
      "ERC20 approval failure"
    );

    // Send ERC20 tokens through PaymentRouter, isPush determines which function is used
    // note PaymentRouter functions make external calls to ERC20 contracts, thus they are interactions
    item.isPush
      ? iPaymentRouter.pushTokens(item.routeID, item.paymentContract, address(this), totalCost) // Pushes tokens to recipients
      : iPaymentRouter.holdTokens(item.routeID, item.paymentContract, address(this), totalCost); // Holds tokens for pull collection

    // Call market item's token contract and transfer token from Marketplace to buyer
    IERC1155(item.tokenContract).safeTransferFrom(address(this), _msgSender(), item.tokenID, _amount, "");

    require( // Buyer should be + _amount
      IERC1155(item.tokenContract).balanceOf(msgSender, item.tokenID) == initBuyersBalance + _amount,
      "Buyer never received token"
    );

    emit MarketItemSold(item.itemID, _amount, msgSender);
    return true;
  }

  /**
   * @dev Transfers more stock to a MarketItem, requires minting more tokens first and setting
   * approval for Marketplace
   *
   * @param _itemID MarketItem ID
   * @param _amount Amount of tokens being restocked
   *
   * @dev Emits ItemRestocked event
   */
  function restockItem(uint256 _itemID, uint256 _amount)
    external
    noReentrantCalls
    noBlacklist
    onlyItemAdmin(_itemID)
    itemExists(_itemID)
    returns (bool)
  {
    MarketItem memory item = marketItems[_itemID - 1];
    uint256 initMarketBalance = IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID);

    /* ========== CHECKS ========== */
    require(
      IERC1155(item.tokenContract).balanceOf(_msgSender(), item.tokenID) >= _amount,
      "Insufficient token balance"
    );

    /* ========== EFFECTS ========== */
    // If item is out of stock
    if (item.amount == 0) {
      itemsSoldOut.decrement();
      item.forSale = true;
    }

    item.amount += _amount;
    marketItems[_itemID - 1] = item; // Update actual market item

    /* ========== INTERACTIONS ========== */
    IERC1155(item.tokenContract).safeTransferFrom(_msgSender(), address(this), item.tokenID, _amount, "");

    // Check that balances updated correctly on both sides
    require( // Marketplace should be + _amount
      IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) == initMarketBalance + _amount,
      "Marketplace never received tokens"
    );

    emit ItemRestocked(_itemID, _amount);
    return true;
  }

  /**
   * @notice Removes _amount of item tokens for _itemID and transfers back to seller's wallet
   *
   * @param _itemID MarketItem's ID
   * @param _amount Amount of tokens being pulled from Marketplace, 0 == pull all tokens
   * @return bool Success bool
   *
   * @dev Emits ItemPulled event
   */
  function pullStock(uint256 _itemID, uint256 _amount)
    external
    noReentrantCalls
    noBlacklist
    onlyItemAdmin(_itemID)
    itemExists(_itemID)
    returns (bool)
  {
    MarketItem memory item = marketItems[_itemID - 1];
    uint256 initMarketBalance = item.amount;

    /* ========== CHECKS ========== */
    // Store initial values
    require(item.amount >= _amount, "Not enough inventory to pull");

    // Pulls all remaining tokens if _amount == 0, sets forSale to false
    if (_amount == 0 || _amount >= item.amount) {
      _amount = item.amount;
      marketItems[_itemID - 1].forSale = false;
      itemsSoldOut.increment();
    }

    /* ========== EFFECTS ========== */
    marketItems[_itemID - 1].amount -= _amount;

    /* ========== INTERACTIONS ========== */
    IERC1155(item.tokenContract).safeTransferFrom(address(this), _msgSender(), item.tokenID, _amount, "");

    // Check that balances updated correctly on both sides
    require( // Marketplace should be - _amount
      IERC1155(item.tokenContract).balanceOf(address(this), item.tokenID) == initMarketBalance - _amount,
      "Marketplace never lost tokens"
    );

    emit ItemPulled(_itemID, _amount);
    return true;
  }

  /**
   * @notice Function that allows item creator to change price, accepted payment
   * token, whether token uses push or pull routes, and payment route.
   *
   * @param _itemID Market item ID
   * @param _price Market price in stablecoins
   * @param _paymentContract Contract address of token accepted for payment (MVP: stablecoin address)
   * @param _isPush Tells PaymentRouter to use push or pull function (MVP: true)
   * @param _routeID Payment route ID, only useful if routeMutable == true (MVP: 0)
   * @param _itemLimit Buyer's purchase limit for item (MVP: 1)
   * @return Sucess boolean
   *
   * @dev Emits MarketItemChanged event
   */
  function modifyMarketItem(
    uint256 _itemID,
    uint256 _price,
    address _paymentContract,
    bool _isPush,
    bytes32 _routeID,
    uint256 _itemLimit,
    bool _forSale
  ) external noReentrantCalls noBlacklist onlyItemAdmin(_itemID) itemExists(_itemID) returns (bool) {
    MarketItem memory oldItem = marketItems[_itemID - 1];
    // routeMutable logic
    if (!oldItem.routeMutable || _routeID == 0) {
      // If the payment route is not mutable, then set the input equal to the old routeID
      _routeID = oldItem.routeID;
    }
    // itemLimit special condition logic
    // If itemLimit == 0, then there is no itemLimit, use type(uint256).max to make itemLimit infinite
    if (_itemLimit == 0) {
      _itemLimit = type(uint256).max;
    }

    // Toggle forSale logic
    if ((oldItem.forSale != _forSale) && (_forSale == false)) {
      itemsSoldOut.increment();
      emit ForSaleToggled(_itemID, _forSale);
    } else if ((oldItem.forSale != _forSale) && (_forSale == true)) {
      require(oldItem.amount > 0, "Restock item before reactivating");
      itemsSoldOut.decrement();
      emit ForSaleToggled(_itemID, _forSale);
    }

    // Modify MarketItem within marketItems array
    marketItems[_itemID - 1] = MarketItem({
      itemID: _itemID,
      tokenContract: oldItem.tokenContract,
      tokenID: oldItem.tokenID,
      amount: oldItem.amount,
      price: _price,
      paymentContract: _paymentContract,
      isPush: _isPush,
      routeID: _routeID,
      routeMutable: oldItem.routeMutable,
      forSale: _forSale,
      itemLimit: _itemLimit
    });

    emit MarketItemChanged(_itemID, _price, _paymentContract, _isPush, _routeID, _itemLimit);
    return true;
  }

  /**
   * @notice Deletes a MarketItem, setting all its properties to default values
   * @dev Does not remove itemID or the entry in marketItems, just sets properties to default
   * and removes tokenMap mappings. This frees up the tokenID to be used in a new MarketItem.
   * @dev Only the itemCreator or a Pazari admin can call this function
   *
   * @dev Emits MarketItemDeleted event
   */
  function deleteMarketItem(uint256 _itemID)
    external
    noReentrantCalls
    noBlacklist
    itemExists(_itemID)
    returns (bool)
  {
    MarketItem memory item = marketItems[_itemID - 1];
    // Caller must either be item's creator or a Pazari admin, no itemAdmins allowed
    require(
      _msgSender() == itemCreator[_itemID] || isAdmin[_msgSender()],
      "Only item creators and Pazari admins"
    );
    // Require item has been completely unstocked and deactivated
    require(!item.forSale, "Deactivate item before deleting");
    require(item.amount == 0, "Pull all stock before deleting");

    // Erase tokenMap mapping, frees up tokenID to be used in a new MarketItem
    delete tokenMap[item.tokenContract][item.tokenID];
    // Set all properties to defaults by deletion
    delete marketItems[_itemID - 1];
    // Erase itemCreator mapping
    delete itemCreator[_itemID];
    // Erase sellersMarketItems entry

    // RETURN
    emit MarketItemDeleted(_itemID, _msgSender(), block.timestamp);
    return true;
  }

  /**
   * @dev Getter function for all itemIDs with forSale. This function should run lighter and faster
   * than getItemsForSale() because it doesn't return structs.
   */
  function getItemIDsForSale() public view returns (uint256[] memory) {
    // Fetch total item count, both sold and unsold
    uint256 itemCount = marketItems.length;
    // Calculate total unsold items
    uint256 unsoldItemCount = itemCount - itemsSoldOut.current();

    // Create empty array of all unsold MarketItem structs with fixed length unsoldItemCount
    uint256[] memory itemIDs = new uint256[](unsoldItemCount);

    uint256 i; // itemID counter for ALL MarketItems
    uint256 j = 0; // itemIDs[] index counter for forSale market items

    for (i = 0; j < unsoldItemCount || i < itemCount; i++) {
      if (marketItems[i].forSale) {
        itemIDs[j] = marketItems[i].itemID; // Assign unsoldItem to items[j]
        j++; // Increment j
      }
    }
    return itemIDs;
  }

  /**
   * @dev Returns an array of MarketItem structs given an arbitrary array of _itemIDs.
   */
  function getMarketItems(uint256[] memory _itemIDs) public view returns (MarketItem[] memory marketItems_) {
    marketItems_ = new MarketItem[](_itemIDs.length);
    for (uint256 i = 0; i < _itemIDs.length; i++) {
      marketItems_[i] = marketItems[_itemIDs[i] - 1];
    }
  }

  /**
   * @notice Checks if an address owns any itemIDs
   *
   * @param _owner The address being checked
   * @param _itemIDs Array of item IDs being checked
   *
   * @dev This function can be used to check for tokens across multiple contracts, and is better than the
   * ownsTokens() function in the PazariTokenMVP contract. This is the only function we will need to call.
   */
  function ownsTokens(address _owner, uint256[] memory _itemIDs)
    public
    view
    returns (bool[] memory hasToken)
  {
    hasToken = new bool[](_itemIDs.length);
    for (uint256 i = 0; i < _itemIDs.length; i++) {
      MarketItem memory item = marketItems[_itemIDs[i] - 1];
      if (IERC1155(item.tokenContract).balanceOf(_owner, item.tokenID) != 0) {
        hasToken[i] = true;
      } else hasToken[i] = false;
    }
  }

  /**
   * @notice Returns an array of MarketItems created by the seller's address
   * @dev Used for displaying seller's items for mini-shops on seller profiles
   * @dev There is no way to remove items from this array, and deleted itemIDs will still show,
   * but will have nonexistent item details.
   */
  function getSellersMarketItems(address _sellerAddress) public view returns (uint256[] memory) {
    return sellersMarketItems[_sellerAddress];
  }

  /**
   * @notice This is in case someone mistakenly sends their ERC1155 NFT to this contract address
   * @dev Requires both tx.origin and msg.sender be admins
   * @param _nftContract Contract address of NFT being recovered
   * @param _tokenID Token ID of NFT
   * @param _amount Amount of NFTs to recover
   * @param _recipient Where the NFTs are going
   * @param _memo Any notes the admin wants to include in the event
   * @return bool Success bool
   *
   * @dev Emits NFTRecovered event
   */
  function recoverNFT(
    address _nftContract,
    uint256 _tokenID,
    uint256 _amount,
    address _recipient,
    string calldata _memo
  ) external noReentrantCalls returns (bool) {
    uint256 itemID = tokenMap[_nftContract][_tokenID];
    uint256 initMarketBalance = IERC1155(_nftContract).balanceOf(address(this), _tokenID);
    uint256 initOwnerBalance = IERC1155(_nftContract).balanceOf(_recipient, _tokenID);
    uint256 marketItemBalance = marketItems[itemID - 1].amount;

    require(initMarketBalance > marketItemBalance, "No tokens available");
    require(isAdmin[tx.origin] && isAdmin[msg.sender], "Please contact Pazari support about your lost NFT");

    // If _amount is greater than the amount of unlisted tokens
    if (_amount > initMarketBalance - marketItemBalance) {
      // Set _amount equal to unlisted tokens
      _amount = initMarketBalance - marketItemBalance;
    }

    // Transfer token(s) to recipient
    IERC1155(_nftContract).safeTransferFrom(address(this), _recipient, _tokenID, _amount, "");

    // Check that recipient's balance was updated correctly
    require( // Recipient final balance should be initial + _amount
      IERC1155(_nftContract).balanceOf(_recipient, _tokenID) == initOwnerBalance + _amount,
      "Recipient never received token(s)"
    );

    emit NFTRecovered(_nftContract, _tokenID, _recipient, msgSender, _memo, block.timestamp);
    return true;
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
  // Fires when a new token is created through createNewToken()
  event TokenCreated(string URI, uint256 indexed tokenID, uint256 amount);

  // Fires when more tokens are minted from a pre-existing tokenID
  event TokensMinted(address indexed mintTo, uint256 indexed tokenID, uint256 amount);

  // Fires when tokens are transferred via airdropTokens()
  event TokensAirdropped(uint256 indexed tokenID, uint256 amount, uint256 timestamp);

  /**
   * @dev Struct to track token properties.
   */
  struct TokenProps {
    string uri; // IPFS URI where public metadata is located
    uint256 totalSupply; // Total circulating supply of token;
    uint256 supplyCap; // Total supply of tokens that can exist (if isMintable == true, supplyCap == 0);
    bool isMintable; // Mintability: Token can be minted;
  }

  //***FUNCTIONS: SETTERS***\\

  /**
   * @dev This implementation returns the URI stored for any _tokenID,
   * overwrites ERC1155's uri() function while maintaining compatibility
   * with OpenSea's standards.
   */
  function uri(uint256 _tokenID) external view override returns (string memory);

  /**
   * @dev Creates a new Pazari Token
   *
   * @param _newURI URL that points to item's public metadata
   * @param _isMintable Can tokens be minted? DEFAULT: True
   * @param _amount Amount of tokens to create
   * @param _supplyCap Maximum supply cap. DEFAULT: 0 (infinite supply)
   * @return uint256 TokenID of new token
   */
  function createNewToken(
    string memory _newURI,
    uint256 _amount,
    uint256 _supplyCap,
    bool _isMintable
  ) external returns (uint256);

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
   * @notice Performs an airdrop for multiple tokens to many recipients
   *
   * @param _tokenIDs Array of all tokenIDs being airdropped
   * @param _amounts Array of all amounts of each tokenID to drop to each recipient
   * @param _recipients Array of all recipients for the airdrop
   *
   * @dev Emits TokenAirdropped event
   */
  function airdropTokens(
    uint256[] memory _tokenIDs,
    uint256[] memory _amounts,
    address[] memory _recipients
  ) external returns (bool);

  /**
   * @dev Burns _amount copies of a _tokenID (NOT NEEDED FOR MVP)
   */
  function burn(uint256 _tokenID, uint256 _amount) external returns (bool);

  /**
   * @dev Burns multiple tokenIDs
   */
  function burnBatch(uint256[] calldata _tokenIDs, uint256[] calldata _amounts) external returns (bool);

  /**
   * @dev Updates token's URI, only contract owners may call
   */
  function setURI(string memory _newURI, uint256 _tokenID) external;

  //***FUNCTIONS: GETTERS***\\

  /**
   * @notice Checks multiple tokenIDs against a single address and returns an array of bools
   * indicating ownership for each tokenID.
   *
   * @param _tokenIDs Array of tokenIDs to check ownership of
   * @param _owner Wallet address being checked
   * @return bool[] Array of mappings where true means the _owner has at least one tokenID
   */
  function ownsToken(uint256[] memory _tokenIDs, address _owner) external view returns (bool[] memory);

  /**
   * @notice Returns TokenProps struct
   *
   * @dev Only available to token contract admins
   */
  function getTokenProps(uint256 tokenID) external view returns (TokenProps memory);

  /**
   * @notice Returns an array of all holders of a _tokenID
   *
   * @dev Only available to token contract admins
   */
  function getTokenHolders(uint256 _tokenID) external view returns (address[] memory);

  /**
   * @notice Returns tokenHolderIndex value for an address and a tokenID
   * @dev All this does is returns the location of an address inside a tokenID's tokenHolders
   */
  function getTokenHolderIndex(address _tokenHolder, uint256 _tokenID) external view returns (uint256);
}

interface IAccessControlPTMVP {
  // Accesses isAdmin mapping
  function isAdmin(address _adminAddress) external view returns (bool);

  /**
   * @notice Returns tx.origin for any Pazari-owned admin contracts, returns msg.sender
   * for everything else. See PaymentRouter for more details.
   */
  function _msgSender() external view returns (address);

  // Adds an address to isAdmin mapping
  function addAdmin(address _newAddress) external returns (bool);

  // Removes an address from isAdmin mapping
  function removeAdmin(address _oldAddress) external returns (bool);
}

/**
 * @title Pazari1155
 *
 * @dev This is the ERC1155 contract that PazariTokens are made from. All ERC1155-native
 * functions are here, as well as Pazari-native functions that are essential.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Dependencies/IERC1155MetadataURI.sol";
import "../Dependencies/Address.sol";
import "../Dependencies/ERC165.sol";
import "../Marketplace/Marketplace.sol";

contract AccessControlPTMVP {
  // Maps admin addresses to bool
  // These are NOT Pazari developer admins, but can include Pazari helpers
  mapping(address => bool) public isAdmin;

  // The address that cloned this contract, never loses admin access
  address internal immutable originalOwner;

  constructor(address[] memory _adminAddresses) {
    for (uint256 i = 0; i < _adminAddresses.length; i++) {
      isAdmin[_adminAddresses[i]] = true;
    }
    originalOwner = _msgSender();
  }

  modifier onlyAdmin() {
    require(isAdmin[_msgSender()], "Caller is not admin");
    _;
  }

  /**
   * @notice Returns tx.origin for any Pazari-owned admin contracts, returns msg.sender
   * for everything else. This only permits Pazari helper contracts to use tx.origin,
   * and all external non-admin contracts and wallets will use msg.sender.
   * @dev This design is vulnerable to phishing attacks if a helper contract that
   * has isAdmin does NOT implement the same _msgSender() logic.
   * @dev _msgSender()'s context is the contract it is being called from, and uses
   * that contract's AccessControl storage for isAdmin. External contracts can use
   * each other's _msgSender() for if they need to use the same AccessControl storage.
   */
  function _msgSender() public view returns (address) {
    if (tx.origin != msg.sender && isAdmin[msg.sender]) {
      return tx.origin;
    } else return msg.sender;
  }

  // Adds an address to isAdmin mapping
  // Requires both tx.origin and msg.sender be admins
  function addAdmin(address _newAddress) external returns (bool) {
    require(isAdmin[msg.sender] && isAdmin[tx.origin], "Caller is not admin");
    require(!isAdmin[_newAddress], "Address is already an admin");
    isAdmin[_newAddress] = true;
    return true;
  }

  // Removes an address from isAdmin mapping
  // Requires both tx.origin and msg.sender be admins
  function removeAdmin(address _oldAddress) external returns (bool) {
    require(isAdmin[msg.sender] && isAdmin[tx.origin], "Caller is not admin");
    require(_oldAddress != originalOwner, "Cannot remove original owner");
    require(isAdmin[_oldAddress], "Address must be an admin");
    isAdmin[_oldAddress] = false;
    return true;
  }
}

abstract contract Pazari1155 is AccessControlPTMVP, ERC165, IERC1155MetadataURI {
  using Address for address;

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) internal _balances;

  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) internal _operatorApprovals;

  // Returns tokenHolder index value for an address and a tokenID
  // token owner's address => tokenID => tokenHolder[index] value
  mapping(address => mapping(uint256 => uint256)) public tokenHolderIndex;

  // Maps tokenIDs to tokenHolders arrays
  mapping(uint256 => address[]) internal tokenHolders;

  // Public array of all TokenProps structs created
  TokenProps[] public tokenProps;

  /**
   * @dev Struct to track token properties.
   */
  struct TokenProps {
    uint256 tokenID; // ID of token
    string uri; // IPFS URI where public metadata is located
    uint256 totalSupply; // Circulating/minted supply;
    uint256 supplyCap; // Max supply of tokens that can exist;
    bool isMintable; // Token can be minted;
  }

  /**
   * @param _contractOwners Array of all operators that do not require approval to handle
   * transferFrom() operations and have isAdmin status. Initially, these addresses will
   * only include the contract creator's wallet address (if using PazariMVP), and the
   * addresses for Marketplace and PazariMVP. If contract creator was not using PazariMVP
   * or any kind of isAdmin contract, then _contractOwners will include the contract's
   * address instead of the user's wallet address. This is intentional for use with
   * multi-sig contracts later.
   */
  constructor(address[] memory _contractOwners) AccessControlPTMVP(_contractOwners) {
    super;
    for (uint256 i = 0; i < _contractOwners.length; i++) {
      _operatorApprovals[_msgSender()][_contractOwners[i]] = true;
    }
  }

  //***FUNCTIONS: ERC1155 MODIFIED & PAZARI***\\

  /**
   * @notice Checks multiple tokenIDs against a single address and returns an array of bools
   * indicating ownership for each tokenID.
   *
   * @param _tokenIDs Array of tokenIDs to check ownership of
   * @param _owner Wallet address being checked
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
   * @dev External function that updates URI
   *
   * Only contract admins may update content URI
   */
  function setURI(string memory _newURI, uint256 _tokenID) external onlyAdmin {
    _setURI(_newURI, _tokenID);
  }

  /**
   * @dev Internal function that updates URI;
   */
  function _setURI(string memory _newURI, uint256 _tokenID) internal {
    tokenProps[_tokenID - 1].uri = _newURI;
  }

  /**
   * @notice Burns copies of a token from a token owner's address.
   *
   * @dev When an address has burned all of their tokens their address in
   * that tokenID's tokenHolders array is set to address(0). However, their
   * tokenHoldersIndex mapping is not removed, and can be used for checks.
   */
  function burn(uint256 _tokenID, uint256 _amount) external returns (bool) {
    _burn(_msgSender(), _tokenID, _amount);
    // After successful burn, if balanceOf == 0 then set tokenHolder address to address(0)
    if (balanceOf(_msgSender(), _tokenID) == 0) {
      tokenHolders[_tokenID][tokenHolderIndex[_msgSender()][_tokenID]] = address(0);
    }
    return true;
  }

  /**
   * @dev Burns a batch of tokens from the caller's address.
   *
   * This can be called by anyone, and if they burn all of their tokens then
   * their address in tokenOwners[tokenID] will be set to address(0). However,
   * their tokenHolderIndex value will not be deleted, as it will be used to
   * put them back on the list of tokenOwners if they receive another token.
   */
  function burnBatch(uint256[] calldata _tokenIDs, uint256[] calldata _amounts) external returns (bool) {
    _burnBatch(_msgSender(), _tokenIDs, _amounts);
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      if (balanceOf(_msgSender(), _tokenIDs[i]) == 0) {
        tokenHolders[_tokenIDs[i]][tokenHolderIndex[_msgSender()][_tokenIDs[i]]] = address(0);
      }
    }
    return true;
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning, as well as batched variants.
   *
   * @dev Pazari's variant checks to see if a recipient owns any tokens already,
   * and if not then their address is added to a tokenHolders array. If they were
   * previously a tokenHolder but burned all their tokens then their address is
   * added back in to the token's tokenHolders array.
   */
  function _beforeTokenTransfer(
    address,
    address,
    address recipient,
    uint256[] memory tokenIDs,
    uint256[] memory,
    bytes memory
  ) internal virtual {
    // Get an array of bools for which tokenIDs recipient owns
    bool[] memory hasTokens = ownsToken(tokenIDs, recipient);
    // Iterate through array
    for (uint256 i = 0; i < tokenIDs.length; i++) {
      if (hasTokens[i] == false) {
        // Run logic if recipient does not own a token
        // If recipient was a tokenHolder before, then put them back in tokenHolders
        if (tokenHolderIndex[recipient][tokenIDs[i]] != 0) {
          tokenHolders[tokenIDs[i]][tokenHolderIndex[recipient][tokenIDs[i]]] = recipient;
        }
        // if not, then push recipient's address to tokenHolders, initialize tokenHolderIndex
        else {
          tokenHolderIndex[recipient][tokenIDs[i]] = tokenHolders[tokenIDs[i]].length;
          tokenHolders[tokenIDs[i]].push(recipient);
        }
      }
    }
  }

  //***FUNCTIONS: ERC1155 UNMODIFIED***\\

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
    // Require caller is an admin
    // If caller is a contract with isAdmin, then user's wallet address is checked
    // If caller is a contract without isAdmin, then contract's address is checked instead
    require(isAdmin[_msgSender()], "PazariToken: Caller is not admin");
    // If recipient is not admin, then sender needs to be admin
    if (!isAdmin[to]) {
      require(isAdmin[from], "PazariToken: Only admins may transfer");
    }

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

// READY FOR PRODUCTION
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Pazari developer functions are not included
 */
interface IPaymentRouter {
  //***EVENTS***\\
  // Fires when a new payment route is created
  event RouteCreated(address indexed creator, bytes32 routeID, address[] recipients, uint16[] commissions);

  // Fires when a route creator changes route tax
  event RouteTaxChanged(bytes32 routeID, uint16 newTax);

  // Fires when a route tax bounds is changed
  event RouteTaxBoundsChanged(uint16 minTax, uint16 maxTax);

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

  // Fires when tokens are deposited into a payment route for holding
  event TokensHeld(bytes32 routeID, address tokenAddress, uint256 amount);

  // Fires when tokens are collected from holding by a recipient
  event TokensCollected(address indexed recipient, address tokenAddress, uint256 amount);

  // Fires when a PaymentRoute's isActive property is toggled on or off
  // isActive == true => Route was reactivated
  // isActive == false => Route was deactivated
  event RouteToggled(bytes32 indexed routeID, bool isActive, uint256 timestamp);

  // Fires when an admin sets a new address for the Pazari treasury
  event TreasurySet(address oldAddress, address newAddress, address adminCaller, uint256 timestamp);

  // Fires when the pazariTreasury address is altered
  event TreasuryChanged(
    address oldAddress,
    address newAddress,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Fires when recipient max values are altered
  event MaxRecipientsChanged(
    uint8 newMaxRecipients,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  //***STRUCT AND ENUM***\\

  // Stores data for each payment route
  struct PaymentRoute {
    address routeCreator; // Address of payment route creator
    address[] recipients; // Recipients in this payment route
    uint16[] commissions; // Commissions for each recipient--in fractions of 10000
    uint16 routeTax; // Tax paid by this route
    TAXTYPE taxType; // Determines if PaymentRoute auto-adjusts to minTax or maxTax
    bool isActive; // Is route currently active?
  }

  // Enum that is used to auto-adjust routeTax if minTax/maxTax are adjusted
  enum TAXTYPE {
    CUSTOM,
    MINTAX,
    MAXTAX
  }

  //***FUNCTIONS: GETTERS***\\

  /**
   * @notice Directly accesses paymentRouteID mapping
   * @dev Returns PaymentRoute properties as a tuple rather than a struct, and may not return the
   * recipients and commissions arrays. Use getPaymentRoute() wherever possible.
   */
  function paymentRouteID(bytes32 _routeID)
    external
    view
    returns (
      address,
      uint16,
      TAXTYPE,
      bool
    );

  /**
   * @notice Calculates the routeID of a payment route.
   *
   * @param _routeCreator Address of payment route's creator
   * @param _recipients Array of all commission recipients
   * @param _commissions Array of all commissions relative to _recipients
   * @return routeID Calculated routeID
   *
   * @dev RouteIDs are calculated by keccak256(_routeCreator, _recipients, _commissions)
   * @dev If a non-Pazari helper contract was used, then _routeCreator will be contract's address
   */
  function getPaymentRouteID(
    address _routeCreator,
    address[] calldata _recipients,
    uint16[] calldata _commissions
  ) external pure returns (bytes32 routeID);

  /**
   * @notice Returns the entire PaymentRoute struct, including arrays
   */
  function getPaymentRoute(bytes32 _routeID) external view returns (PaymentRoute memory paymentRoute);

  /**
   * @notice Returns a balance of tokens/stablecoins ready for collection
   *
   * @param _recipientAddress Address of recipient who can collect tokens
   * @param _tokenContract Contract address of tokens/stablecoins to be collected
   */
  function getPaymentBalance(address _recipientAddress, address _tokenContract)
    external
    view
    returns (uint256 balance);

  /**
   * @notice Returns an array of all routeIDs created by an address
   */
  function getCreatorRoutes(address _creatorAddress) external view returns (bytes32[] memory routeIDs);

  /**
   * @notice Returns minimum and maximum allowable bounds for routeTax
   */
  function getTaxBounds() external view returns (uint256 minTax, uint256 maxTax);

  //***FUNCTIONS: SETTERS***\\

  /**
   * @dev Opens a new payment route
   * @notice Only a Pazari-owned contract or admin can call
   *
   * @param _recipients Array of all recipient addresses for this payment route
   * @param _commissions Array of all recipients' commissions--in fractions of 10000
   * @param _routeTax Platform tax paid by this route: minTax <= _routeTax <= maxTax
   * @return routeID Hash of the created PaymentRoute
   */
  function openPaymentRoute(
    address[] memory _recipients,
    uint16[] memory _commissions,
    uint16 _routeTax
  ) external returns (bytes32 routeID);

  /**
   * @notice Transfers tokens from _senderAddress to all recipients for the PaymentRoute
   * @notice Only a Pazari-owned contract or admin can call
   *
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being transferred
   * @param _senderAddress Wallet address of token sender
   * @param _amount Amount of tokens being routed
   * @return bool Success bool
   *
   * @dev Emits TransferReceipt event
   */
  function pushTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external returns (bool);

  /**
   * @dev Deposits and sorts tokens for collection, tokens are divided up by each
   * recipient's commission rate for that PaymentRoute
   * @notice Only a Pazari-owned contract or admin can call
   *
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being deposited for collection
   * @param _senderAddress Address of token sender
   * @param _amount Amount of tokens held in escrow by payment route
   * @return success Success boolean
   */
  function holdTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external returns (bool);

  /**
   * @dev Collects all earnings stored in PaymentRouter for msg.sender
   *
   * @param _tokenAddress Contract address of payment token to be collected
   * @return success Success bool
   */
  function pullTokens(address _tokenAddress) external returns (bool);

  /**
   * @notice Toggles a payment route with ID _routeID
   *
   * @dev Emits RouteToggled event
   */
  function togglePaymentRoute(bytes32 _routeID) external;

  /**
   * @notice Adjusts the tax applied to a payment route. Minimum is minTax, and
   * maximum is maxTax.
   *
   * @param _routeID PaymentRoute's routeID
   * @param _newTax New tax applied to route, calculated in fractions of 10000
   *
   * @dev Emits RouteTaxChanged event
   *
   * @dev Developers can alter minTax and maxTax, and the changes will be auto-applied
   * to an item the first time it is purchased.
   */
  function adjustRouteTax(bytes32 _routeID, uint16 _newTax) external returns (bool);

  /**
   * @notice This function allows devs to set the minTax and maxTax global variables
   * @notice Only a Pazari admin can call
   *
   * @dev Emits RouteTaxBoundsChanged
   */
  function adjustTaxBounds(uint16 _minTax, uint16 _maxTax) external view;

  /**
   * @notice Sets the treasury's address
   * @notice Only a Pazari admin can call
   *
   * @dev Emits TreasurySet event
   */
  function setTreasuryAddress(address _newTreasuryAddress)
    external
    returns (
      bool success,
      address oldAddress,
      address newAddress
    );

  /**
   * @notice Sets the maximum number of recipients allowed for a PaymentRoute
   * @dev Does not affect pre-existing routes, only new routes
   *
   * @param _newMax Maximum recipient size for new PaymentRoutes
   * @return (bool, uint8) Success bool, new value for maxRecipients
   */
  function setMaxRecipients(uint8 _newMax, string calldata _memo) external returns (bool, uint8);
}

/**
 * @dev Includes all access control functions for Pazari admins and
 * PaymentRoute management. Uses two types of admins: Pazari admins
 * who have isAdmin, and PaymentRoute admins who have isRouteAdmin.
 * All Pazari admins can access functions restricted to route admins,
 * but route admins cannot access functions restricted to Pazari admins.
 */
interface IAccessControlPR {
  /**
   * @notice Returns tx.origin for any Pazari-owned admin contracts, returns msg.sender
   * for everything else. This only permits Pazari helper contracts to return tx.origin,
   * and all external non-admin contracts and wallets will return msg.sender.
   * @dev This can be used to detect if user is being tricked into a phishing attack.
   * If _msgSender() is different from user's wallet address, then there exists an
   * unauthorized contract between the user and the _msgSender() function. However,
   * there is a context when this is intentional, see next dev entry.
   * @dev This can also be used to create multi-sig contracts that own MarketItems
   * on behalf of multiple owners without any one of them having ownership, and
   * without needing to specify who the owner is at item creation. In this context,
   * _msgSender() will return the address of the multi-sig contract instead of any
   * wallet addresses operating the contract. This feature will be essential for
   * collaboration projects.
   * @dev Returns tx.origin if caller is using a contract with isAdmin. PazariMVP
   * and FactoryPazariTokenMVP require isAdmin with other contracts to function.
   * Marketplace must have isAdmin with PaymentRouter to be able to use it, and
   * PazariMVP must have isAdmin with Marketplace to function and will revert if
   * it doesn't.
   */
  function _msgSender() external view returns (address callerAddress);

  //***PAZARI ADMINS***\\
  // Fires when Pazari admins are added/removed
  event AdminAdded(address indexed newAdmin, address indexed adminAuthorized, string memo, uint256 timestamp);
  event AdminRemoved(
    address indexed oldAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Maps Pazari admin addresses to bools
  function isAdmin(address _adminAddress) external view returns (bool success);

  // Adds an address to isAdmin mapping
  function addAdmin(address _addedAddress, string calldata _memo) external returns (bool success);

  // Removes an address from isAdmin mapping
  function removeAdmin(address _removedAddress, string calldata _memo) external returns (bool success);

  //***PAYMENT ROUTE ADMINS (SELLERS)***\\
  // Fires when route admins are added/removed, returns _msgSender() for callerAdmin
  event RouteAdminAdded(
    bytes32 indexed routeID,
    address indexed newAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );
  event RouteAdminRemoved(
    bytes32 indexed routeID,
    address indexed oldAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Returns true if an address is an admin for a routeID
  function isRouteAdmin(bytes32 _routeID, address _adminAddress) external view returns (bool success);

  // Adds an address to isRouteAdmin mapping
  function addRouteAdmin(
    bytes32 _routeID,
    address _newAdmin,
    string memory memo
  ) external returns (bool success);

  // Removes an address from isRouteAdmin mapping
  function removeRouteAdmin(
    bytes32 _routeID,
    address _oldAddress,
    string memory memo
  ) external returns (bool success);
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