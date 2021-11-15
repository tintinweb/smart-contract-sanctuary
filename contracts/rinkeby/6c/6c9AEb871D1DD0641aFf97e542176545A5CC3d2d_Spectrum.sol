// SPDX-License-Identifier: GPL-v2-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./ITokenUriOracle.sol";

struct BatchData {
    uint16 size; // `1 <= size <= 256`
    address minter;
}

struct MintRequest {
    uint248 batch;
    uint8 sizeMinusOne;
}

contract Spectrum is IERC165, IERC721, IERC721Metadata {
    event BatchMinted(
        address indexed minter,
        uint248 indexed batch,
        uint16 size
    );
    event AdminChanged(address newAdmin);
    event TokenUriOracleChanged(
        ITokenUriOracle indexed oldOracle,
        ITokenUriOracle indexed newOracle
    );
    event BatchFeeChanged(uint256 oldFeeWei, uint256 newFeeWei);
    event FeesCollected(address indexed beneficiary, uint256 amount);

    address public admin;
    ITokenUriOracle public tokenUriOracle;
    uint256 public batchFeeWei;

    mapping(uint248 => BatchData) public batch;
    /// Owners for tokens that have been explicitly transferred. If a token
    /// exists but does not have an owner in this map, then its owner is
    /// `_batchData(_tokenId).minter`.
    mapping(uint256 => address) explicitOwner;
    mapping(uint256 => address) operator;
    mapping(address => mapping(address => bool)) approvedForAll;
    mapping(address => uint256) balance;

    string private constant ERR_NOT_FOUND = "Spectrum: NOT_FOUND";
    string private constant ERR_UNAUTHORIZED = "Spectrum: UNAUTHORIZED";
    string private constant ERR_ALREADY_EXISTS = "Spectrum: ALREADY_EXISTS";
    string private constant ERR_INCORRECT_OWNER = "Spectrum: INCORRECT_OWNER";
    string private constant ERR_INCORRECT_FEE = "Spectrum: INCORRECT_FEE";
    string private constant ERR_UNSAFE_TRANSFER = "Spectrum: UNSAFE_TRANSFER";
    string private constant ERR_ZERO_ADDRESS = "Spectrum: ZERO_ADDRESS";

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert(ERR_UNAUTHORIZED);
        _;
    }

    function setAdmin(address _admin) external onlyAdmin {
        emit AdminChanged(_admin);
        admin = _admin;
    }

    function setTokenUriOracle(ITokenUriOracle _oracle) external onlyAdmin {
        emit TokenUriOracleChanged(tokenUriOracle, _oracle);
        tokenUriOracle = _oracle;
    }

    function setBatchFee(uint256 _batchFeeWei) external onlyAdmin {
        emit BatchFeeChanged(batchFeeWei, _batchFeeWei);
        batchFeeWei = _batchFeeWei;
    }

    function name() external pure override returns (string memory) {
        return "Spectrum";
    }

    function symbol() external pure override returns (string memory) {
        return "SPEC";
    }

    function tokenURI(uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
        _batchData(_tokenId); // ensure exists
        return tokenUriOracle.tokenURI(address(this), _tokenId);
    }

    function mint(MintRequest[] memory _requests) external payable {
        uint256 _totalFee = batchFeeWei * _requests.length;
        if (msg.value != _totalFee) revert(ERR_INCORRECT_FEE);
        uint256 _totalSize = 0;
        for (uint256 _i = 0; _i < _requests.length; _i++) {
            uint248 _batch = _requests[_i].batch;
            uint16 _size = uint16(_requests[_i].sizeMinusOne) + 1;
            _totalSize += _size;
            if (batch[_batch].minter != address(0)) revert(ERR_ALREADY_EXISTS);
            batch[_batch] = BatchData({size: _size, minter: msg.sender});
            emit BatchMinted(msg.sender, _batch, _size);
            uint256 _firstTokenId = uint256(_batch) << 8;
            for (uint256 _j = 0; _j < _size; _j++) {
                emit Transfer(address(0), msg.sender, _firstTokenId | _j);
            }
        }
        balance[msg.sender] += _totalSize;
    }

    function collectFees(address payable _beneficiary) external onlyAdmin {
        uint256 _balance = address(this).balance;
        _beneficiary.transfer(_balance);
        emit FeesCollected(_beneficiary, _balance);
    }

    /// Reads the batch data for the given token. Reverts if the token does not
    /// exist.
    function _batchData(uint256 _tokenId)
        internal
        view
        returns (BatchData memory)
    {
        BatchData memory _batch = batch[uint248(_tokenId >> 8)];
        if (uint8(_tokenId) >= _batch.size) revert(ERR_NOT_FOUND);
        return _batch;
    }

    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        if (_owner == address(0)) revert(ERR_ZERO_ADDRESS);
        return balance[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address _owner = explicitOwner[_tokenId];
        if (_owner != address(0)) return _owner;
        _owner = _batchData(_tokenId).minter;
        if (_owner != address(0)) return _owner;
        revert(ERR_NOT_FOUND);
    }

    function _isApprovedOrOwner(address _who, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        if (operator[_tokenId] == _who) return true;
        address _owner = ownerOf(_tokenId);
        return _owner == _who || approvedForAll[_owner][_who];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override {
        transferFrom(_from, _to, _tokenId);
        _checkOnERC721Received(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        safeTransferFrom(_from, _to, _tokenId, bytes(""));
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        if (_to == address(0)) revert(ERR_ZERO_ADDRESS);
        address _owner = ownerOf(_tokenId);
        if (_owner != _from) revert(ERR_INCORRECT_OWNER);
        if (
            _owner != msg.sender &&
            operator[_tokenId] != msg.sender &&
            !approvedForAll[_owner][msg.sender]
        ) revert(ERR_UNAUTHORIZED);
        explicitOwner[_tokenId] = _to;
        operator[_tokenId] = address(0);
        balance[_from]--;
        balance[_to]++;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override {
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) revert(ERR_UNAUTHORIZED);
        operator[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        approvedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        _batchData(_tokenId); // ensure exists
        return operator[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return approvedForAll[_owner][_operator];
    }

    function supportsInterface(bytes4 _interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            _interfaceId == type(IERC165).interfaceId ||
            _interfaceId == type(IERC721).interfaceId ||
            _interfaceId == type(IERC721Metadata).interfaceId;
    }

    // Adapted from OpenZeppelin ERC-721 implementation, which is released
    // under the MIT License.
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal {
        if (!Address.isContract(_to)) {
            return;
        }
        try
            IERC721Receiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            )
        returns (bytes4 _retval) {
            if (_retval != IERC721Receiver.onERC721Received.selector)
                revert(ERR_UNSAFE_TRANSFER);
        } catch (bytes memory _reason) {
            if (_reason.length == 0) {
                revert(ERR_UNSAFE_TRANSFER);
            } else {
                assembly {
                    revert(add(32, _reason), mload(_reason))
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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

// SPDX-License-Identifier: GPL-v2-only
pragma solidity ^0.8.0;

interface ITokenUriOracle {
    /// Computes the token URI for a given token. It is implementation-defined
    /// whether the token ID need actually exist, or whether there are extra
    /// restrictions on the `_tokenContract`.
    function tokenURI(address _tokenContract, uint256 _tokenId)
        external
        view
        returns (string memory);
}

