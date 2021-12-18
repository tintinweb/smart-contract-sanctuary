/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// ----------------------------------------------------------------------------
//
// Owned
//
// ----------------------------------------------------------------------------

contract Owned {

    address public owner;
    address public newOwner;

    address payable public wallet;
    address public newWallet;

    mapping(address => bool) public isAdmin;

    event OwnershipTransferProposed(address indexed _from, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    event WalletChangeProposed(address indexed _from, address indexed _to);
    event WalletChanged(address indexed _from, address indexed _to);

    event AdminChange(address indexed _admin, bool _status);

    modifier onlyOwner { require(msg.sender == owner); _; }
    modifier onlyAdmin { require(isAdmin[msg.sender]); _; }

    constructor() {
        owner = msg.sender;
        wallet = payable(msg.sender);
        isAdmin[owner] = true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        require(_newOwner != address(0x0));
        emit OwnershipTransferProposed(owner, _newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function changeWallet(address _newWallet) public onlyOwner {
        require(_newWallet != wallet);
        require(_newWallet != address(0x0));
        emit WalletChangeProposed(wallet, _newWallet);
        newWallet = _newWallet;

    }

    function confirmWallet() public {
        require(msg.sender == newWallet);
        emit WalletChanged(wallet, newWallet);
        wallet = payable(newWallet);
    }

    function addAdmin(address _a) public onlyOwner {
        require(isAdmin[_a] == false);
        isAdmin[_a] = true;
        emit AdminChange(_a, true);
    }

    function removeAdmin(address _a) public onlyOwner {
        require(isAdmin[_a] == true);
        isAdmin[_a] = false;
        emit AdminChange(_a, false);
    }

}



// ----------------------------------------------------------------------------
//
// OpenZeppelin - ERC1155 from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol"
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// from @openzeppelin/contracts/utils/introspection/IERC165.sol

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// ----------------------------------------------------------------------------
//
// from @openzeppelin/contracts/utils/introspection/ERC165.sol

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// ----------------------------------------------------------------------------
//
// from @openzeppelin/contracts/token/ERC1155/IERC1155.sol

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


// ----------------------------------------------------------------------------
//
// from @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol

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


// ----------------------------------------------------------------------------
//
// from @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol

interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}


// ----------------------------------------------------------------------------
//
// from @openzeppelin/contracts/utils/Address.sol

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


// ----------------------------------------------------------------------------
//
// from @openzeppelin/contracts/utils/Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// ----------------------------------------------------------------------------
//
// from @openzeppelin/contracts/token/ERC1155/ERC1155.sol

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) _balances;

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


// ----------------------------------------------------------------------------
//
// OpenZeppelin - Strings from "@openzeppelin/contracts/utils/Strings.sol"
//
// ----------------------------------------------------------------------------

library Strings {
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
}


// ----------------------------------------------------------------------------
//
// ERC20Interface
//
// ----------------------------------------------------------------------------

abstract contract ERC20Interface {
    function transfer(address _to, uint _value) virtual public returns (bool success);
}


// ----------------------------------------------------------------------------
//
// HashballerDraftPicks
//
// ----------------------------------------------------------------------------

contract HashballerDraftPicks is ERC1155, Owned {

    uint256 public constant TOTAL_SUPPLY = 10000;
    uint256 public nrPicksRedeemed = 0;

    uint256 public lastPickAssigned = 0;
    
    address public draftPickSeller;
    address public hashballersContract;

    mapping(address => uint256[]) public picksOwned;
    
    string public name = "HashballerDraftPicks";

    // Event logging

    event RedeemDraftPicks(address account_, uint256[] indices_, uint256[] numbers_, uint256 nrPicksRedeemed_);

    // Basic functions

    constructor() ERC1155("http://www.resderelictae.com/zNfT598/{id}.json") {
    }

    // Set Hashballers owner address (can be done only once)

    function setDraftPickSeller(address _a) public onlyOwner {
        require(draftPickSeller == address(0));
        draftPickSeller = _a;
        _balances[1][draftPickSeller] = TOTAL_SUPPLY;
    }

    // Set Hashballers contract address (can be done only once)

    function setHashballersContract(address _a) public onlyOwner {
        require(hashballersContract == address(0));
        hashballersContract = _a;
    }

    /* Utility functions */

    function showPicksOwned(address _a) public view returns(uint256[] memory) {
      return picksOwned[_a];
    }

    /* Implement _beforeTokenTransfer */
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        require(ids.length == 1, "Only one id allowed");
        require(ids[0] == 1, "Id must be 1");
        uint256 amount = amounts[0];
        require(amount > 0, "Amount transferred must be strictly positive");
        uint256 initialFromBalance = _balances[1][from];
        require(initialFromBalance >= amount, "Cannot transfer more than you own");
        require(to != draftPickSeller);

        if (from == draftPickSeller) {
          //
          // Primary transfer
          //
          // Because the correspondence between draft picks and Hashballers 
          // is not known beforehand, we simply assign the next available 
          // numbers in increasing order.
          //
          for (uint256 i = 1; i <= amount; i++) {
            picksOwned[to].push(lastPickAssigned + i);
          }
          lastPickAssigned = lastPickAssigned + amount;
        } else if (data.length == 0) {
          //
          // Secondary transfer (without specifying draft picks)
          //
          // If the data field is empty, we just transfer the last picks.
          // This reduces the gas cost and is suitable for a transfer between
          // accounts owned by the same person, or when the correspondence 
          // betwen draft picks and Hashballers is not yet published.
          //
          for (uint256 i = 1; i <= amount; i++) {
            picksOwned[to].push(picksOwned[from][initialFromBalance - i]);
            picksOwned[from].pop();
          }
        } else {
          //
          // Secondary transfer (for specific draft picks)
          //
          // The data field must include the positions of the draft picks that the user 
          // wants to transfer, in strictly *decreasing* order
          //
          // Positions must be between 0 (0x00) and 255 (0xff)
          //
          // For example, 0x1c0a will transfer draft picks at positions 28 and 10
          // (Which obviously assumes that the account has at leat 29 draft picks)
          //
          require(data.length == amount, "All Draft pick positions need to be provided");
          uint256 idx = uint256(uint8(data[0]));
          require(idx < _balances[1][from]);
          //
          // deal with first position
          //
          picksOwned[to].push(picksOwned[from][idx]);
          picksOwned[from][idx] = picksOwned[from][initialFromBalance - 1];
          picksOwned[from].pop();
          //
          // transfer other draft picks - need to check for increasing sequence
          //
          for (uint256 i = 1; i < amount; i++) {
            uint256 idx_next = uint256(uint8(data[i]));
            // make sure indices are strictly decreasing
            require(idx_next < idx, "Indices must be in strictly decreasing order");
            //
            picksOwned[to].push(picksOwned[from][idx_next]);
            picksOwned[from][idx_next] = picksOwned[from][initialFromBalance - 1 - i];
            picksOwned[from].pop();
            idx = idx_next;
          }
        }
    }    

    /* Redeem Pick */

    function redeemDraftPicks(address account, uint256[] memory indices, uint256[] memory picks) external returns (bool success) {
        require(msg.sender == hashballersContract, "Only the Hashballers contract can redeem a draft pick");
        require(account != address(0), "Cannot redeem draft picks held by the 0x0 account");
        require(account != draftPickSeller, "Cannot redeem draft picks held by the draftPickSeller account");
        require(indices.length == picks.length, "The arrays of indices and picks must have the same size");
        uint256 number = indices.length;
        uint256 initialBalance = _balances[1][account];
        require(number <= initialBalance, "Cannot redeem more picks than are owned");

        // Indices must be strictly decreasing!

        //
        // deal with first position
        //
        uint256 idx = indices[0];
        require(picksOwned[account][idx] == picks[0], "Index and pick number must correspond");
        picksOwned[account][idx] = picksOwned[account][initialBalance - 1];
        picksOwned[account].pop();
        //
        // deal with subsequent positions, if any
        //
        for (uint256 i = 1; i < number; i++) {
          uint256 idx_next = indices[i];
          require(idx_next < idx, "Indices must be in strictly decreasing order");
          require(picksOwned[account][idx_next] == picks[idx_next], "Index and pick number must correspond");
          picksOwned[account][idx_next] = picksOwned[account][initialBalance - 1 - i];
          picksOwned[account].pop();
          idx = idx_next;
        }
        //
        // update balances
        //
        _balances[1][account] = _balances[1][account] - number;
        nrPicksRedeemed = nrPicksRedeemed + number;

        emit RedeemDraftPicks(account, indices, picks, nrPicksRedeemed);
        emit TransferSingle(hashballersContract, account, address(0), 1, number);

        return true;
    
    }

    /* Withdraw balance (just in case) */
    
    function withdraw() public onlyOwner {
        wallet.transfer(address(this).balance);
    }

    /* Transfer any accidentally received ERC-20 tokens (just in case) */

    function transferAnyERC20Token(address _token_address, uint _amount) public onlyOwner returns (bool success) {
        return ERC20Interface(_token_address).transfer(owner, _amount);
    }

}