// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {IFERC1155V1} from "./IFERC1155V1.sol";
import {IERC1155MetadataURI} from "./IERC1155MetadataURI.sol";
import {ERC2981Base} from "./ERC2981Base.sol";
import {ERC2981PerTokenRoyalties} from './ERC2981PerTokenRoyalties.sol';
import {MintERC1155Order, MintERC1155BatchOrder} from "../shared/libraries/LibOrders.sol"; 

/// @dev Funrise ERC1155-compliant contract.
/// @dev Based on code by OpenZeppelin.
/// @author Nypox
contract FERC1155V1 is Context, ERC165, IFERC1155V1, IERC1155MetadataURI, ERC2981PerTokenRoyalties, AccessControl {
    using Address for address;

//  Child chain manager proxy
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

//  Only minter is allowed to mint
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

//  EIP-1155: Multi Token Standard
    bytes4 private constant _INTERFACE_ERC1155 = 0xd9b67a26;

//  EIP-1155: Multi Token Standard. Metadata Extension
    bytes4 private constant _INTERFACE_ERC1155_METADATA_URI = 0x0e89341c; // bytes4(keccak256('uri(uint256)')) == 0x0e89341c

//  Contract-level metadata
    bytes4 private constant _INTERFACE_CONTRACT_URI = 0xe8a3d485; // bytes4(keccak256('contractURI()')) == 0xe8a3d485

//  Token name
    string public name;
    
//  Token symbol
    string public symbol;

//  Contract-level metadata
    string public contractURI;

//  Shared token URI prefix
    string private _baseTokenURI;

//  Token ID => account => balance
    mapping(uint256 => mapping(address => uint256)) private _balances;

//  Account => operator => approval
    mapping(address => mapping(address => bool)) private _operatorApprovals;

//  Token ID => token URI
    mapping(uint256 => string) private _tokenURIs;

//  Token ID => token URI is permanent
    mapping(uint256 => bool) public isPermanentURI;

//  Token ID => creator
    mapping (uint256 => address) private _creators;

//  Token ID => token supply
    mapping (uint256 => uint256) public tokenSupply;

    constructor(
        address minter,
        address childChainManager,
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI,
        string memory contractURI_
    ) {
        name = name_;
        symbol = symbol_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE, minter);
        grantRole(DEPOSITOR_ROLE, childChainManager);

        setBaseTokenURI(baseTokenURI);
        setContractURI(contractURI_);
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {

        _baseTokenURI = baseTokenURI;
    }

    function setContractURI(string memory contractURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {

        contractURI = contractURI_;
    }

/// @dev Sets token URI for token `id`.
/// @dev The creator must own the full supply of the token.
    function setTokenURI(
        uint256 id,
        string calldata newUri,
        bool freeze
    ) public override creatorOrMinterOnly(id) creatorIsFullTokenOwner(id) onlyImpermanentURI(id) {

        if (freeze) {
            require(
                bytes(newUri).length > 0,
                "invalid uri"
            );
            isPermanentURI[id] = true;
        }

        _tokenURIs[id] = newUri;
        emit URI(uri(id), id);
    }

/// @dev EIP-1155: Multi Token Standard. Metadata Extension.
/// @dev {IERC1155MetadataURI}.
    function uri(uint256 id) public view virtual override returns (string memory) {
 
        return string(abi.encodePacked(_baseTokenURI, _tokenURIs[id]));
    }

/// @dev Returns the amount of tokens of token type `id` owned by `account`.
/// @dev `account` cannot be the zero address.
    function balanceOf(address account, uint256 id)
        public
        view
        override
        returns (uint256) {

        require(account != address(0), "balance query for the zero address");
        return _balances[id][account];
    }

/// @dev Returns the creator of `id` token.
    function creatorOf(uint256 id) public view returns (address) {
      return _creators[id];
    }

/// @dev Batched version of {balanceOf}.
/// @dev `accounts` and `ids` must have the same length.
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        override
        returns (uint256[] memory) {

        require(accounts.length == ids.length, "accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

/// @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`.
/// @dev `operator` cannot be the caller if not minter.
/// @dev Emits a {ApprovalForAll} event.
    function setApprovalForAll(address operator, bool approved)
        public
        override {

        address caller = _msgSender();

        if (caller == operator) {
            revert("setting approval status for self");
        }
        _operatorApprovals[caller][operator] = approved;
        emit ApprovalForAll(caller, operator, approved);
    }

/// @dev Returns true if `operator` is approved to transfer `account`'s tokens.
    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool) {

        return _operatorApprovals[account][operator];
    } 

/// @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
/// @dev `to` cannot be the zero address.
/// @dev If the caller is not `from`, it must be have been approved to spend `from`'s tokens via {setApprovalForAll}.
/// @dev `from` must have a balance of tokens of type `id` of at least `amount`.
/// @dev If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received}.
/// @dev Emits a {TransferSingle} event.
    function safeTransferFrom(
        address from,
        address to, 
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {

        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "caller is not owner nor approved"
        );

        require(to != address(0), "transfer to the zero address");

        address operator = _msgSender();

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

/// @dev Batched version of {safeTransferFrom}.
/// @dev Emits a {TransferBatch} event.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {

        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "transfer caller is not owner nor approved"
        );

        require(ids.length == amounts.length, "ids and amounts length mismatch");
        require(to != address(0), "transfer to the zero address");

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

/// @dev Mints `order.amount` tokens of token type `order.id` to `order.to`.
/// @dev Enables approval for contract owner to transfer tokens if `approve` is true.
/// @dev Only contract owner is allowed to call this function.
/// @dev Emits a {TransferSingle} event.
/// @dev Emits a {URI} event.
    function mint(
        MintERC1155Order calldata order,
        bool approve,
        bool freezeTokenURI,
        bytes memory data
    ) external override onlyRole(MINTER_ROLE) {

        require(_creators[order.id] == address(0), "token is already minted");
        require(order.to != address(0), "mint to the zero address");
        require(order.amount > 0, "zero supply");
        require(bytes(order.uri).length > 0, "invalid uri");

        address minter = _msgSender();

        _balances[order.id][order.to] += order.amount;
        _creators[order.id] = order.to;
        tokenSupply[order.id] = order.amount;
        _tokenURIs[order.id] = order.uri;

        if (freezeTokenURI) {
            isPermanentURI[order.id] = true;
        }

        emit TransferSingle(minter, address(0), order.to, order.id, order.amount);

        _doSafeTransferAcceptanceCheck(minter, address(0), order.to, order.id, order.amount, data);

        if (order.royalty.amount > 0) {
            _setTokenRoyalty(order.id, order.royalty.recipient, order.royalty.amount);
        }

        emit URI(uri(order.id), order.id);

        if (approve) {
            _operatorApprovals[order.to][minter] = true;
            emit ApprovalForAll(order.to, minter, true);
        }
    }

/// @dev Batched version of {mint}.
/// @dev Emits a {TransferBatch} event.
/// @dev Emits {URI} events.
    function mintBatch(
        MintERC1155BatchOrder calldata order,
        bool approve,
        bool freezeTokenURI,
        bytes memory data
    ) external override onlyRole(MINTER_ROLE) {

        require(order.ids.length == order.uris.length, "ids and uris length mismatch");

        address minter = _msgSender();

        _mintBatch(
            order.to,
            order.ids,
            order.amounts,
            data
        );

        for (uint256 i = 0; i < order.ids.length; i++) {
            uint256 id = order.ids[i];

            require(bytes(order.uris[i]).length > 0, "invalid uri");

            _tokenURIs[id] = order.uris[i];

            if (freezeTokenURI) {
                isPermanentURI[id] = true;
            }

            emit URI(uri(id), id);

            if (approve) {
                _operatorApprovals[order.to][minter] = true;
                emit ApprovalForAll(order.to, minter, true);
            }

            if (order.royalty.amount > 0) {
                _setTokenRoyalty(id, order.royalty.recipient, order.royalty.amount);
            }
        }
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "mint to the zero address");
        require(ids.length == amounts.length, "ids and amounts length mismatch");

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            require(_creators[id] == address(0), "token is already minted");
            require(amounts[i] > 0, "zero supply");

            _balances[id][to] += amounts[i];
            _creators[id] = to;
            tokenSupply[id] = amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

/// @dev Burns `value` tokens of token `id` from `account`.
/// @dev Burned token cannot be re-minted
/// @dev Emits a {TransferSingle} event.
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public override {

        require(account != address(0), "burn from the zero address");
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "caller is not owner nor approved"
        );

        uint256 fromBalance = _balances[id][account];
        require(fromBalance >= amount, "burn amount exceeds balance");
        unchecked {
            _balances[id][account] = fromBalance - amount;
        }

        emit TransferSingle(_msgSender(), account, address(0), id, amount);
    }

/// @dev Batched version of {burn}.
/// @dev Emits a {TransferBatch} event.
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public override {

        require(account != address(0), "burn from the zero address");
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "caller is not owner nor approved"
        );
        require(ids.length == amounts.length, "ids and amounts length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][account];
            require(fromBalance >= amount, "burn amount exceeds balance");
            unchecked {
                _balances[id][account] = fromBalance - amount;
            }
        }

        emit TransferBatch(_msgSender(), account, address(0), ids, amounts);
    }

/// @dev Called when tokens are deposited on root chain.
/// @param user user address for whom deposit is being done.
/// @param depositData abi encoded ids array and amounts array.
    function deposit(
        address user,
        bytes calldata depositData
    ) external override onlyRole(DEPOSITOR_ROLE) {
        (
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data
        ) = abi.decode(depositData, (uint256[], uint256[], bytes));

        require(
            user != address(0),
            "invalid deposit user"
        );

        _mintBatch(user, ids, amounts, data);
    }

/// @dev Called when user wants to batch withdraw tokens to root chain.
    function withdrawBatch(
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external override {
        burnBatch(_msgSender(), ids, amounts);
    }

/// @dev {IERC165}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC165, IERC165, ERC2981Base, AccessControl)
        returns (bool) {

        return
            interfaceId == _INTERFACE_ERC1155 || 
            interfaceId == _INTERFACE_ERC1155_METADATA_URI ||
            interfaceId == _INTERFACE_CONTRACT_URI || 
            super.supportsInterface(interfaceId);
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
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
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
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

    modifier onlyImpermanentURI(uint256 id) {

        require(
            !isPermanentURI[id],
            "uri is frozen"
        );
        _;
    }

    modifier creatorIsFullTokenOwner(uint256 id) {

        require(
            balanceOf(_creators[id], id) == tokenSupply[id],
            "creator is not full owner"
        );
        _;
    } 

    modifier creatorOrMinterOnly(uint256 id) {

        address caller = _msgSender();

        require(
            _creators[id] == caller || hasRole(MINTER_ROLE, caller),
            "not allowed"
        );
        _;
    } 
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
        assembly { size := extcodesize(account) }
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
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

import "../../utils/introspection/IERC165.sol";

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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
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

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {MintERC1155Order, MintERC1155BatchOrder} from "../shared/libraries/LibOrders.sol"; 

/// @dev Required interface of Funrise ERC1155-compliant contract.
/// @dev Based on code by OpenZeppelin.
/// @author Nypox
interface IFERC1155V1 is IERC165 {

/// @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

/// @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all transfers.
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

/// @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to `approved`.
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

/// @dev Emitted when the URI for token type `id` changes to `value`
    event URI(string value, uint256 indexed id);

/// @dev Returns the amount of tokens of token type `id` owned by `account`.
/// @dev `account` cannot be the zero address.
    function balanceOf(address account, uint256 id) external view returns (uint256);

/// @dev Batched version of {balanceOf}.
/// @dev `accounts` and `ids` must have the same length.
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

/// @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`.
/// @dev `operator` cannot be the caller.
    function setApprovalForAll(address operator, bool approved) external;

/// @dev Returns true if `operator` is approved to transfer `account`'s tokens.
    function isApprovedForAll(address account, address operator) external view returns (bool);

/// @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
/// @dev `to` cannot be the zero address.
/// @dev If the caller is not `from`, it must be have been approved to spend `from`'s tokens via {setApprovalForAll}.
/// @dev `from` must have a balance of tokens of type `id` of at least `amount`.
/// @dev If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received}.
/// @dev Emits a {TransferSingle} event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

/// @dev Batched version of {safeTransferFrom}.
/// @dev Emits a {TransferBatch} event.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

/// @dev Returns the creator of `id` token.
    function creatorOf(uint256 id) external view returns (address);

/// @dev Mints `order.amount` tokens of token type `order.id` to `order.to`.
/// @dev Enables approval for minter to transfer tokens if `approve` is true.
/// @dev Only minter is allowed to call this function.
/// @dev Emits a {TransferSingle} event.
/// @dev Emits a {URI} event.
    function mint(
        MintERC1155Order calldata order,
        bool approve,
        bool freezeTokenURI,
        bytes memory data
    ) external;

/// @dev Batched version of {mint}.
/// @dev Emits a {TransferBatch} event.
/// @dev Emits {URI} events.
    function mintBatch(
        MintERC1155BatchOrder calldata order,
        bool approve,
        bool freezeTokenURI,
        bytes memory data
    ) external;

/// @dev Burns `value` tokens of token `id` from `account`.
/// @dev Burned token cannot be re-minted
/// @dev Emits a {TransferSingle} event.
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

/// @dev Batched version of {burn}.
/// @dev Emits a {TransferBatch} event.
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

/// @dev Sets token URI for token `id`.
/// @dev The creator must own the full supply of the token.
    function setTokenURI(
        uint256 id,
        string calldata newUri,
        bool freeze
    ) external;

/// @notice Called when tokens are deposited on root chain.
/// @param user user address for whom deposit is being done.
/// @param depositData abi encoded ids array and amounts array.
    function deposit(
        address user,
        bytes calldata depositData
    ) external;

// /// @notice Called when user wants to withdraw single token to root chain.
//     function withdrawSingle(
//         uint256 id,
//         uint256 amount
//     ) external;

/// @notice Called when user wants to batch withdraw tokens to root chain.
    function withdrawBatch(
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-1155: Multi Token Standard, optional metadata extension.
interface IERC1155MetadataURI {

/// @notice A distinct Uniform Resource Identifier (URI) for a given token.
    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import {IERC2981Royalties} from './IERC2981Royalties.sol';

/// @dev Adds ERC2981 support to ERC721 and ERC1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import {ERC2981Base} from './ERC2981Base.sol';

/// @dev Adds ERC2981 support to ERC721 and ERC1155
abstract contract ERC2981PerTokenRoyalties is ERC2981Base {
    
    mapping(uint256 => RoyaltyInfo) internal _royalties;

/// @dev Sets token royalties
/// @param tokenId the token id fir which we register the royalties
/// @param recipient recipient of the royalties
/// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 tokenId,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties[tokenId];
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {ERC2981Base} from "../../tokens/ERC2981Base.sol";
import {
    LibAppStorage,
    AppStorage,
    AssetStandard,
    AssetVersion
} from "../../marketplace/libraries/LibAppStorage.sol";

// Mint / Off-chain fixed price listing

struct MintERC721Order {
    address token;
    address to;
    uint256 id;
    string uri;
    ERC2981Base.RoyaltyInfo royalty;
}

struct MintERC721BatchOrder {
    address token;
    address to;
    uint256[] ids;
    string[] uris;
    ERC2981Base.RoyaltyInfo royalty;
}

struct MintERC1155Order {
    address token;
    address to;
    uint256 id;
    uint256 amount;
    string uri;
    ERC2981Base.RoyaltyInfo royalty;
}

struct MintERC1155BatchOrder {
    address token;
    address to;
    uint256[] ids;
    uint256[] amounts;
    string[] uris;
    ERC2981Base.RoyaltyInfo royalty;
}

struct RedeemERC721Order {
    address token;
    address paymentToken;
    address targetToken;
    address from;
    address to;
    uint256 id;
    uint256 price;
}

struct RedeemERC721BundleOrder {
    address[] tokens;
    address paymentToken;
    address targetToken;
    address from;
    address to;
    uint256[] ids;
    uint256[] prices;
}

struct RedeemERC1155Order {
    address token;
    address paymentToken;
    address targetToken;
    address from;
    address to;
    uint256 id;
    uint256 amount;
    uint256 price;
}

struct RedeemERC1155BundleOrder {
    address[] tokens;
    address paymentToken;
    address targetToken;
    address from;
    address to;
    uint256[] ids;
    uint256[] amounts;
    uint256[] prices;
}

// FixedPrice

struct FixedPriceListOrder {
    address owner;                          // owner of assets, seller
    address paymentToken;                   // this token is transferred from a buyer
    address targetToken;                    // this token is transferred to a seller
    uint256 bundleId;                       // target bundle (edit bundle if exists)
    address[] tokens;                       // asset tokens
    uint256[] ids;                          // asset token IDs
    uint256[] amounts;                      // asset token amounts
    uint256[] prices;                       // asset prices
    string[] uris;                          // asset token URIs (lazy mint only)
    AssetStandard[] standards;              // asset type
    ERC2981Base.RoyaltyInfo[] royalties;    // ERC2981 royalties (lazy mint only)
    bool minted;                            // assets existence (lazy mint if false)
}

struct FixedPriceUnlistOrder {
    address owner;
    uint256 bundleId;          
}

struct FixedPriceRedeemOrder {
    address buyer;                          // payer and buyer
    uint256 bundleId;                       // target bundle
    uint256[] amounts;                      // asset token amounts
}

// Auction

struct AuctionListOrder {
    address owner;                          // bundle owner
    address paymentToken;                   // this token is transferred from a bidder
    address targetToken;                    // this token is transferred to the seller
    uint256 bundleId;                       // target bundle (edit bundle if exists)
    address[] tokens;                       // NFT contract addresses
    uint256[] ids;                          // token IDs
    uint256[] amounts;                      // token amounts
    uint256[] startingPrices;               // bids below cumulative starting price are rejectd
    uint256 reservePrice;                   // do not auto sell if final highest bid is below this value
    uint64 duration;                        // auction dutation in seconds
    string[] uris;                          // asset token URIs (lazy mint / virtual only)
    AssetStandard[] standards;              // asset type
    ERC2981Base.RoyaltyInfo[] royalties;    // ERC2981 royalties (lazy mint / virtual only)
    bool minted;                            // assets existence (lazy mint if false)
    bool deferred;                          // virtual if true (lazy mint if true)
}

struct AuctionBidOrder {
    address bidder;                         // bid maker
    uint256 bundleId;                       // target bundle
    uint256 value;                          // total bid value
}

struct AuctionSetOwnerOrder {
    address owner;                          // bundle owner
    address targetToken;                    // this token is transferred to the seller
    uint256 bundleId;                       // target bundle
    string[] uris;                          // asset token URIs
    ERC2981Base.RoyaltyInfo royalty;        // ERC2981 royalty
}

struct AuctionResolveOrder {
    uint256 bundleId;                       // target bundle
    bool accept;                            // accept the highest bid or close the auction and return assets
}

/// @title Order structures.
/// @author Nypox
library LibOrders {

    function hashMintOrderId(
        address token,
        uint256 id
    ) internal view returns (bytes32) {
        
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    token,
                    id,
                    block.chainid
                )
            )
        );
    }

    function hashMintOrderIds(
        address token,
        uint256[] memory ids
    ) internal view returns (bytes32) {
        
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    token,
                    ids,
                    block.chainid
                )
            )
        );
    }

    function hashMintERC721Order(
        MintERC721Order calldata order
    ) internal view returns (bytes32) {
        
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.to,
                    order.id,
                    order.uri,
                    order.royalty.recipient,
                    order.royalty.amount,
                    block.chainid
                )
            )
        );
    }

    function hashMintERC721BatchOrder(
        MintERC721BatchOrder calldata order
    ) internal view returns (bytes32) {

        bytes memory uris;
        for (uint i = 0; i < order.uris.length; i++) {
            uris = abi.encodePacked(uris, order.uris[i]);
        }
        
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.to,
                    order.ids,
                    uris,
                    order.royalty.recipient,
                    order.royalty.amount,
                    block.chainid
                )
            )
        );
    }

    function hashMintERC1155Order(
        MintERC1155Order calldata order
    ) internal view returns (bytes32) {
        
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.to,
                    order.id,
                    order.amount,
                    order.uri,
                    order.royalty.recipient,
                    order.royalty.amount,
                    block.chainid
                )
            )
        );
    }

    function hashMintERC1155BatchOrder(
        MintERC1155BatchOrder calldata order
    ) internal view returns (bytes32) {
        
        bytes memory uris;
        for (uint i = 0; i < order.uris.length; i++) {
            uris = abi.encodePacked(uris, order.uris[i]);
        }

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.to,
                    order.ids,
                    order.amounts,
                    uris,
                    order.royalty.recipient,
                    order.royalty.amount,
                    block.chainid
                )
            )
        );
    }

    function hashRedeemERC721Order(
        RedeemERC721Order calldata order
    ) internal view returns (bytes32) {

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.from,
                    order.id,
                    order.paymentToken,
                    order.targetToken,
                    order.price,
                    block.chainid
                )
            )
        );
    }

    function hashRedeemERC721BundleOrder(
        RedeemERC721BundleOrder calldata order
    ) internal view returns (bytes32) {

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.tokens,
                    order.from,
                    order.ids,
                    order.paymentToken,
                    order.targetToken,
                    order.prices,
                    block.chainid
                )
            )
        );
    }

    function hashRedeemERC1155Order(
        RedeemERC1155Order calldata order
    ) internal view returns (bytes32) {

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.from,
                    order.id,
                    order.paymentToken,
                    order.targetToken,
                    order.amount,
                    order.price,
                    block.chainid
                )
            )
        );
    }

    function hashRedeemERC1155BundleOrder(
        RedeemERC1155BundleOrder memory order
    ) internal view returns (bytes32) {

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.tokens,
                    order.from,
                    order.ids,
                    order.paymentToken,
                    order.targetToken,
                    order.amounts,
                    order.prices,
                    block.chainid
                )
            )
        );
    }

    function hashAuctionSetOwnerOrder(
        AuctionSetOwnerOrder memory order
    ) internal view returns (bytes32) {

        bytes memory uris;
        for (uint i = 0; i < order.uris.length; i++) {
            uris = abi.encodePacked(uris, order.uris[i]);
        }

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.owner,
                    order.targetToken,
                    order.bundleId,
                    uris,
                    order.royalty.recipient,
                    order.royalty.amount,
                    block.chainid
                )
            )
        );
    }

    function hashAuctionResolveOrder(
        AuctionResolveOrder memory order
    ) internal view returns (bytes32) {

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.bundleId,
                    block.chainid
                )
            )
        );
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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibCommon} from "../../shared/libraries/LibCommon.sol";
import {ERC2981Base} from "../../tokens/ERC2981Base.sol";

enum AssetStandard {
    ERC721,
    ERC1155
}

enum AssetVersion {
    None,                                // standard-compliant external contract
    V1                                   // Funrise mintable contract V1
}

enum BundleState {
    Idle,                                // not on sale, default
    OnSale,                              // on sale, minted
    Pending                              // on sale, not minted
}

enum ListingType {
    Offchain,                            // not listed / listed off-chain
    FixedPrice,                          // fixed price listing
    Auction,                             // auction listing
    VirtualAuction                       // virtual auction listing
}

// Represents ERC721 / ERC1155 token
struct Asset {
    uint256 bundleId;                    // current bundle
    uint256 amount;                      // amount of token
    uint256 price;                       // fixed price / starting price
    string uri;                          // token URI
    AssetStandard standard;    
    AssetVersion version;    
    ERC2981Base.RoyaltyInfo royalty;
}

// Represents a bid on a {Bundle}
struct Bid {
    address bidder;                 // payer and bundle recipient
    uint256 value;                  // bid value
    // uint64 timestamp;               // block time
    bool active;                    // bid is active: payment token is locked
}

// Represents a set of {Asset}s
struct Bundle {
    address owner;                       // owner of assets, seller
    address paymentToken;                // this token is transferred from a buyer
    address targetToken;                 // this token is transferred to a seller
    address[] tokens;                    // asset tokens
    uint256[] ids;                       // asset token IDs
    uint256 reservePrice;                // do not accept the highest bid if its value is below this price
    uint64 listingTime;                  // listing block time
    uint64 duration;                     // auction duration
    Bid bid;                             // current bid
    BundleState state;
    ListingType listingType;
}

struct Market {
    // owner -> token -> token id -> asset id
    mapping(address => mapping(address => mapping(uint256 => Asset))) assets;

    // bundle id -> bundle
    mapping(uint256 => Bundle) bundles;
}

struct MarketConfig {
    mapping(address => bool) signers;                                           // newly minted tokens must have IDs signed by a signer
    mapping(address => bool) resolvers;                                         // resolves listings

    mapping(AssetStandard => mapping(AssetVersion => address)) assetTokens;     // native mitable asset tokens
    mapping(AssetStandard => AssetVersion) defaultTokenVersions;                // default asset token versions
    mapping(address => AssetStandard) assetTokenStandards;                      // asset token standards
    mapping(address => AssetVersion) assetTokenVersions;                        // asset token versions

    mapping(address => uint256[]) comissionSteps;                               // payment token => comission steps
    mapping(address => uint24[]) comissionPercentages;                          // payment token => comission step values
    mapping(address => uint256) minPrices;                                      // minimum asset prices (payment token => minimum price)
    mapping(address => bool) targetTokens;                                      // seller receives these ERC20 tokens (whitelist)
    address comissionReceiver;                                                  // comissions are transfered to this address
    address platformToken;                                                      // FNR ERC20 token

    uint24 maxRoyalty;                                                          // maximum royalty value
    uint256 maxBundleSize;                                                      // maximum number of assets in a bundle

    mapping(address => uint256) auctionSteps;                                   // payment token => minimal value difference required for overbid
    mapping(address => uint256) minReservePriceTotal;                           // payment token -> value
    uint256 minAuctionDuration;                                                 // in seconds
    uint256 maxAuctionDuration;                                                 // in seconds
    uint64 auctionProlongation;                                                 // duration is increased by this value after each successful bid
    uint64 auctionRelaxationTime;                                               // resolver can resolve an auction after {auction duration + relaxation time}

    bool skipPlatformToken;                                                     // skip platform token for the path {payment token => platform token => target token}
}

struct ExchangeConfig {
    address router;                                                             // swap router
    uint256 maxSwapDelay;                                                       // deadline = block.timestamp + maxDelay
}

struct Accounts {
    mapping(bytes32 => bool) roots;                                             // Merkle roots
    mapping(address => bool) refillBlacklist;                                   // do not refill these accounts
    uint256 refillValue;                                                        // registered accounts are refilled with this amount
}

struct AppStorage {
    Accounts accounts;
    Market market;
    MarketConfig marketConfig;
    ExchangeConfig exchangeConfig;
}

library LibAppStorage {

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {

    modifier onlyDiamondOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier isSender(address _address) {
        require(
            _address == LibCommon.msgSender(),
            "NOT_SENDER"
        );
        _;
    }

    modifier notEqual(address _address1, address _address2) {
        require(
            _address1 != _address2,
            "WRONG_ADDRESS"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {

/// @notice Called with the sale price to determine how much royalty is owed and to whom.
/// @param tokenId - the NFT asset queried for royalty information
/// @param value - the sale price of the NFT asset specified by tokenId
/// @return receiver - address of who should be sent the royalty payment
/// @return royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library LibCommon {

    function msgSender() internal view returns (address sender) {
        return msg.sender;
    }

    function msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }

    function verifyLeaf(bytes32 _leaf, bytes32[] memory _proof, bytes32 _root)
    internal pure returns (bool)
    {
        return MerkleProof.verify(_proof, _root, _leaf);
    }

    function verify(
        bytes32 digest,
        address signer,
        bytes memory signature
    ) internal pure returns (bool) {

        return signer == ECDSA.recover(digest, signature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}