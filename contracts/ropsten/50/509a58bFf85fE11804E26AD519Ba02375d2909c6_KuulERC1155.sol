/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SafeMath {
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      uint256 c = a + b;
      if (c < a) return (false, 0);
      return (true, c);
    }
  }

  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b > a) return (false, 0);
      return (true, a - b);
    }
  }

  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (a == 0) return (true, 0);
      uint256 c = a * b;
      if (c / a != b) return (false, 0);
      return (true, c);
    }
  }

  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a / b);
    }
  }

  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a % b);
    }
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * b;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return a % b;
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b <= a, errorMessage);
      return a - b;
    }
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a / b;
    }
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
  }
}

library Strings {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
    
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }
}

library Counters {
  struct Counter {
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

  function reset(Counter storage counter) internal {
    counter._value = 0;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
        return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly
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

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _setOwner(_msgSender());
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    _setOwner(address(0));
  }

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

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  event ApprovalForAll(address indexed account, address indexed operator, bool approved);

  event URI(string value, uint256 indexed id);

  function balanceOf(address account, uint256 id) external view returns (uint256);

  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory);

  function setApprovalForAll(address operator, bool approved) external;

  function isApprovedForAll(address account, address operator) external view returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

interface IERC1155Receiver is IERC165 {
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4);
}

interface IERC1155MetadataURI is IERC1155 {
  function uri(uint256 id) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {
  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
  using Address for address;

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) private _balances;

  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
  string private _uri;

  /**
    * @dev See {_setURI}.
    */
  constructor(string memory uri_) {
    _setURI(uri_);
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
    * @dev See {IERC1155MetadataURI-uri}.
    *
    * This implementation returns the same URI for *all* token types. It relies
    * on the token type ID substitution mechanism
    * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
    *
    * Clients calling this function must replace the `\{id\}` substring with the
    * actual token type ID.
    */
  function uri(uint256) public view virtual override returns (string memory) {
    return _uri;
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
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );
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
      "ERC1155: transfer caller is not owner nor approved"
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
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
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
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
      _balances[id][to] += amount;
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  /**
    * @dev Sets a new URI for all token types, by relying on the token type ID
    * substitution mechanism
    * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
    *
    * By this mechanism, any occurrence of the `\{id\}` substring in either the
    * URI or any of the amounts in the JSON file at said URI will be replaced by
    * clients with the token type ID.
    *
    * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
    * interpreted by clients as
    * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
    * for token type ID 0x4cce0.
    *
    * See {uri}.
    *
    * Because these URIs cannot be meaningfully represented by the {URI} event,
    * this function emits no events.
    */
  function _setURI(string memory newuri) internal virtual {
    _uri = newuri;
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
  ) internal virtual {
    require(account != address(0), "ERC1155: mint to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

    _balances[id][account] += amount;
    emit TransferSingle(operator, address(0), account, id, amount);

    _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
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
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
  }

  function _burn(
      address account,
      uint256 id,
      uint256 amount
  ) internal virtual {
    require(account != address(0), "ERC1155: burn from the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

    uint256 accountBalance = _balances[id][account];
    require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
      _balances[id][account] = accountBalance - amount;
    }

    emit TransferSingle(operator, account, address(0), id, amount);
  }

  function _burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    require(account != address(0), "ERC1155: burn from the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 accountBalance = _balances[id][account];
      require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
      unchecked {
        _balances[id][account] = accountBalance - amount;
      }
    }

    emit TransferBatch(operator, account, address(0), ids, amounts);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

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
        if (response != IERC1155Receiver.onERC1155Received.selector) {
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
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
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

abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor () {
      _status = _NOT_ENTERED;
  }

  /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * Calling a `nonReentrant` function from another `nonReentrant`
    * function is not supported. It is possible to prevent this from happening
    * by making the `nonReentrant` function external, and make it call a
    * `private` function that does the actual work.
    */
  modifier nonReentrant() {
      // On the first call to nonReentrant, _notEntered will be true
      require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

      // Any calls to nonReentrant after this point will fail
      _status = _ENTERED;

      _;

      // By storing the original value once again, a refund is triggered (see
      // https://eips.ethereum.org/EIPS/eip-2200)
      _status = _NOT_ENTERED;
  }
}

contract KuulERC1155 is ERC1155, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string public _name;
  string public _symbol;
  string public _baseURI = "ipfs://";
  
  struct NftInfo {
    uint256 tokenId;
    address creator;
    address owner;
    uint256 supply;
    bool tokenType; // 0:common 1: betta
    uint256[] subTokenIds;
    uint256[] subTokenAmounts;
    IERC20 payToken;
    uint256 price;
    uint256 neutralize;
  }

  mapping (uint256 => NftInfo) private _nftInfo;
  mapping(address => bool) public minters;

  constructor() ERC1155(_baseURI) {
    _name = "CML8 Contract";
    _symbol = "CML8";
  }

  modifier onlyMinter() {
    require(_msgSender() == owner() || minters[_msgSender()], "not minter");
    _;
  }

  function setMinters(address _address, bool _allow) public onlyOwner {
    require(_address != address(0), "zero_address");
    minters[_address] = _allow;
  }
  
  function mintSingleCommonNft(
    address initialOwner,
    uint256 supply
  ) external onlyMinter returns (uint256) {
    require(supply > 0, "The supply must over 0");
    _tokenIds.increment();
    uint256 _id = _tokenIds.current();
    _mint(initialOwner, _id, supply, "0x0000");

    _nftInfo[_id].tokenId = _id;
    _nftInfo[_id].supply = supply;
    _nftInfo[_id].creator = _msgSender();
    _nftInfo[_id].owner = initialOwner;
    _nftInfo[_id].tokenType = false;

    return _id;
  }
  
  function mintBatchCommonNft(
    address initialOwner,
    uint256[] memory supplies
  ) external onlyMinter returns (uint256[] memory) {
    uint256[] memory _ids;

    for (uint256 i = 0; i < supplies.length; i++) {
      require(supplies[i] > 0, "The supply must over 0");
      _tokenIds.increment();
      uint256 _id = _tokenIds.current();
      _nftInfo[_id].tokenId = _id;
      _nftInfo[_id].supply = supplies[i];
      _nftInfo[_id].creator = _msgSender();
      _nftInfo[_id].owner = initialOwner;
      _nftInfo[_id].tokenType = false;
      _ids[i] = _id;
    }

    _mintBatch(initialOwner, _ids, supplies, "0x0000");

    return _ids;
  }
  
  function mintBettaNft(
    address buyer,
    uint256[] memory ids,
    uint256[] memory amounts
  ) external onlyMinter returns(uint256) {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    _tokenIds.increment();
    uint256 _id = _tokenIds.current();
    uint256 _neutralize = 0; // The amount after making NFT

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 _tokenId = ids[i];
      require(exist(_tokenId), "Not exist");
      uint256 _tokenAmount = amounts[i];
      address _owner = _nftInfo[_tokenId].owner;
      uint256 _price = _nftInfo[_tokenId].price;
      uint256 _paidPrice = _price.mul(_tokenAmount); // The price will be paid to token owner
      
      _nftInfo[_id].subTokenIds.push(_tokenId);
      _nftInfo[_id].subTokenIds.push(_tokenAmount);
      _neutralize = _neutralize.add(_tokenAmount);
      _burn(_owner, _tokenId, _tokenAmount);

      _nftInfo[_tokenId].payToken.transferFrom(_msgSender(), _owner, _paidPrice);
    }

    _nftInfo[_id].tokenId = _id;
    _nftInfo[_id].supply = 1;
    _nftInfo[_id].creator = _msgSender();
    _nftInfo[_id].owner = buyer;
    _nftInfo[_id].tokenType = true;
    _nftInfo[_id].neutralize = _neutralize;

    _mint(buyer, _id, 1, "0x0000");
    
    return _id;
  }

  function buySingleToken(uint256 id, uint256 amount) public nonReentrant {
    require(exist(id), "Not Exist");
    NftInfo memory _info = _nftInfo[id];
    uint256 _price = _info.price.mul(amount);
    require(balanceOf(_info.owner, id) >= amount, "Balance must over amount");
    if(!_info.tokenType) {
      _info.payToken.transferFrom(_msgSender(), _info.owner, _price);
    } else {
      uint256 _realPrice = _price.mul(9).div(10);
      _info.payToken.transferFrom(_msgSender(), _info.owner, _realPrice);
      for(uint256 i = 0; i < _info.subTokenIds.length; i++) {
        NftInfo memory _subInfo = _nftInfo[_info.subTokenIds[i]];
        uint256 _rate = _info.subTokenAmounts[i].div(_info.neutralize);
        // uint256 _royaltyPrice = _price.div(10).mul(_rate);
        // _info.payToken.transferFrom(_msgSender(), _subInfo.owner, _royaltyPrice);
      }
    }
    _safeTransferFrom(_info.owner, _msgSender(), id, amount, "0x00");
  }

  function setTokenInfo(uint256 id, IERC20 payToken, uint256 price ) public onlyMinter {
    require(exist(id), "Not Exist");
    _nftInfo[id].payToken = payToken;
    _nftInfo[id].price = price;
  }

  function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}
  
  function uri(uint256 id) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(id)));
	}

  function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

  function totalSupply(uint256 id) public view virtual returns (uint256) {
		return _nftInfo[id].supply;
	}

  function exist(uint256 id) public view virtual returns (bool) {
		return _nftInfo[id].tokenId > 0;
	}

  function getNftInfo(uint256 id) public view returns(uint256 price, IERC20 payToken) {
    NftInfo memory _info = _nftInfo[id];
    return (_info.price, _info.payToken);
  }

}