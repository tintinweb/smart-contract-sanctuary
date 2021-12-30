// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IDToken.sol';
import './ERC721.sol';
import '../utils/NameVersion.sol';

contract DToken is IDToken, ERC721, NameVersion {

    address public immutable pool;

    string  public name;

    string  public symbol;

    uint256 public totalMinted;

    modifier _onlyPool_() {
        require(msg.sender == pool, 'DToken: only pool');
        _;
    }

    constructor (string memory name_, string memory symbol_, address pool_) NameVersion('DToken', '3.0.1') {
        name = name_;
        symbol = symbol_;
        pool = pool_;
    }

    function exists(address owner) external view returns (bool) {
        return _exists(owner);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // tokenId existence unchecked
    function getOwnerOf(uint256 tokenId) external view returns (address) {
        return _tokenIdOwner[tokenId];
    }

    // owner existence unchecked
    function getTokenIdOf(address owner) external view returns (uint256) {
        return _ownerTokenId[owner];
    }

    function mint(address owner) external _onlyPool_ returns (uint256) {
        require(!_exists(owner), 'DToken.mint: existent owner');

        uint256 tokenId = ++totalMinted;
        _ownerTokenId[owner] = tokenId;
        _tokenIdOwner[tokenId] = owner;

        emit Transfer(address(0), owner, tokenId);
        return tokenId;
    }

    function burn(uint256 tokenId) external _onlyPool_ {
        address owner = _tokenIdOwner[tokenId];
        require(owner != address(0), 'DToken.burn: nonexistent tokenId');

        delete _ownerTokenId[owner];
        delete _tokenIdOwner[tokenId];
        delete _tokenIdOperator[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC721.sol';
import '../utils/INameVersion.sol';

interface IDToken is IERC721, INameVersion {

    function pool() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalMinted() external view returns (uint256);

    function exists(address owner) external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function getTokenIdOf(address owner) external view returns (uint256);

    function mint(address owner) external returns (uint256);

    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC721Receiver.sol';
import './IERC721.sol';
import '../library/Address.sol';
import './ERC165.sol';

/**
 * @dev ERC721 Non-Fungible Token Implementation
 *
 * Exert uniqueness of owner: one owner can only have one token
 */
contract ERC721 is IERC721, ERC165 {

    using Address for address;

    /*
     * Equals to `bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'))`
     * which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
     */
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x081812fc ^ 0xe985e9c5 ^
     *        0x095ea7b3 ^ 0xa22cb465 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    // Mapping from owner address to tokenId
    // tokenId starts from 1, 0 is reserved for nonexistent token
    // One owner can only own one token in this contract
    mapping (address => uint256) _ownerTokenId;

    // Mapping from tokenId to owner
    mapping (uint256 => address) _tokenIdOwner;

    // Mapping from tokenId to approved operator
    mapping (uint256 => address) _tokenIdOperator;

    // Mapping from owner to operator for all approval
    mapping (address => mapping (address => bool)) _ownerOperator;

    constructor () {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _ownerTokenId[owner] != 0 ? 1 : 0;
    }

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        require(
            (owner = _tokenIdOwner[tokenId]) != address(0),
            'ERC721.ownerOf: nonexistent tokenId'
        );
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), 'ERC721.getApproved: nonexistent tokenId');
        return _tokenIdOperator[tokenId];
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        require(_exists(owner), 'ERC721.isApprovedForAll: nonexistent owner');
        return _ownerOperator[owner][operator];
    }

    function approve(address operator, uint256 tokenId) external {
        address owner = msg.sender;
        require(owner == ownerOf(tokenId), 'ERC721.approve: caller not owner');
        _tokenIdOperator[tokenId] = operator;
        emit Approval(owner, operator, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        address owner = msg.sender;
        require(_exists(owner), 'ERC721.setApprovalForAll: nonexistent owner');
        _ownerOperator[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        _validateTransfer(msg.sender, from, to, tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        _validateTransfer(msg.sender, from, to, tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

    //================================================================================

    function _exists(address owner) internal view returns (bool) {
        return _ownerTokenId[owner] != 0;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenIdOwner[tokenId] != address(0);
    }

    function _validateTransfer(address operator, address from, address to, uint256 tokenId) internal view {
        require(
            from == ownerOf(tokenId),
            'ERC721._validateTransfer: not owned token'
        );
        require(
            to != address(0) && !_exists(to),
            'ERC721._validateTransfer: to address _exists or 0'
        );
        require(
            operator == from || _tokenIdOperator[tokenId] == operator || _ownerOperator[from][operator],
            'ERC721._validateTransfer: not owner nor approved'
        );
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        // clear previous ownership and approvals
        delete _ownerTokenId[from];
        delete _tokenIdOperator[tokenId];

        // set up new owner
        _ownerTokenId[to] = tokenId;
        _tokenIdOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            data
        ), 'ERC721: transfer to non ERC721Receiver implementer');
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC165.sol";

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function approve(address operator, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity >=0.8.0 <0.9.0;

import './IERC165.sol';

abstract contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}