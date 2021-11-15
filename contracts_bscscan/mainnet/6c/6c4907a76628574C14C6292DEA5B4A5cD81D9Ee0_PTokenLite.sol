// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IPTokenLite.sol';
import './ERC721.sol';

contract PTokenLite is IPTokenLite, ERC721 {

    // PToken name
    string _name;
    // PToken symbol
    string _symbol;
    // associative pool address
    address _pool;
    // total number of PToken ever minted, this number will never decease
    uint256 _totalMinted;
    // total PTokens hold by all traders
    uint256 _totalSupply;

    // tokenId => margin
    mapping (uint256 => int256) _tokenIdMargins;
    // tokenId => (symbolId => Position)
    mapping (uint256 => mapping (uint256 => Position)) _tokenIdPositions;

    // active symbolIds
    uint256[] _activeSymbolIds;
    // symbolId => bool
    mapping (uint256 => bool) _isActiveSymbolId;
    // symbolId => bool
    mapping (uint256 => bool) _isCloseOnly;
    // symbolId => number of position holders
    mapping (uint256 => uint256) _numPositionHolders;

    modifier _pool_() {
        require(msg.sender == _pool, 'PToken: only pool');
        _;
    }

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function pool() public override view returns (address) {
        return _pool;
    }

    function totalMinted() public override view returns (uint256) {
        return _totalMinted;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function setPool(address newPool) public override {
        require(newPool != address(0), 'PToken: setPool to 0 address');
        require(_pool == address(0) || _pool == msg.sender, 'PToken.setPool: not allowed');
        _pool = newPool;
    }

    function getActiveSymbolIds() public override view returns (uint256[] memory) {
        return _activeSymbolIds;
    }

    function isActiveSymbolId(uint256 symbolId) public override view returns (bool) {
        return _isActiveSymbolId[symbolId];
    }

    function getNumPositionHolders(uint256 symbolId) public override view returns (uint256) {
        return _numPositionHolders[symbolId];
    }

    function addSymbolId(uint256 symbolId) public override _pool_ {
        require(!isActiveSymbolId(symbolId), 'PToken: symbolId already active');
        _activeSymbolIds.push(symbolId);
        _isActiveSymbolId[symbolId] = true;
    }

    function removeSymbolId(uint256 symbolId) public override _pool_ {
        require(isActiveSymbolId(symbolId), 'PToken: non-active symbolId');
        require(_numPositionHolders[symbolId] == 0, 'PToken: exists position holders');

        uint256 index;
        uint256 length = _activeSymbolIds.length;

        for (uint256 i = 0; i < length; i++) {
            if (_activeSymbolIds[i] == symbolId) {
                index = i;
                break;
            }
        }

        for (uint256 i = index; i < length - 1; i++) {
            _activeSymbolIds[i] = _activeSymbolIds[i+1];
        }

        _activeSymbolIds.pop();
        _isActiveSymbolId[symbolId] = false;
    }

    function toggleCloseOnly(uint256 symbolId) public override _pool_ {
        require(isActiveSymbolId(symbolId), 'PToken: inactive symbolId');
        _isCloseOnly[symbolId] = !_isCloseOnly[symbolId];
    }

    function exists(address owner) public override view returns (bool) {
        return _exists(owner);
    }

    function getMargin(address owner) public override view returns (int256) {
        return _tokenIdMargins[_ownerTokenId[owner]];
    }

    function updateMargin(address owner, int256 margin) public override _pool_ {
        _tokenIdMargins[_ownerTokenId[owner]] = margin;
        emit UpdateMargin(owner, margin);
    }

    function addMargin(address owner, int256 delta) public override _pool_ {
        int256 margin = _tokenIdMargins[_ownerTokenId[owner]] + delta;
        _tokenIdMargins[_ownerTokenId[owner]] = margin;
        emit UpdateMargin(owner, margin);
    }

    function getPosition(address owner, uint256 symbolId) public override view returns (Position memory) {
        return _tokenIdPositions[_ownerTokenId[owner]][symbolId];
    }

    function updatePosition(address owner, uint256 symbolId, Position memory position) public override _pool_ {
        int256 preVolume = _tokenIdPositions[_ownerTokenId[owner]][symbolId].volume;
        int256 curVolume = position.volume;

        if (preVolume == 0 && curVolume != 0) {
            _numPositionHolders[symbolId]++;
        } else if (preVolume != 0 && curVolume == 0) {
            _numPositionHolders[symbolId]--;
        }

        if (_isCloseOnly[symbolId]) {
            require(
                (preVolume >= 0 && curVolume >= 0 && preVolume >= curVolume) ||
                (preVolume <= 0 && curVolume <= 0 && preVolume <= curVolume),
                'PToken: close only'
            );
        }

        _tokenIdPositions[_ownerTokenId[owner]][symbolId] = position;
        emit UpdatePosition(owner, symbolId, position.volume, position.cost, position.lastCumulativeFundingRate);
    }

    function mint(address owner) public override _pool_ {
        _totalSupply++;
        uint256 tokenId = ++_totalMinted;
        require(!_exists(tokenId), 'PToken.mint: existent tokenId');

        _ownerTokenId[owner] = tokenId;
        _tokenIdOwner[tokenId] = owner;

        emit Transfer(address(0), owner, tokenId);
    }

    function burn(address owner) public override _pool_ {
        uint256 tokenId = _ownerTokenId[owner];

        _totalSupply--;
        delete _ownerTokenId[owner];
        delete _tokenIdOwner[tokenId];
        delete _tokenIdOperator[tokenId];

        delete _tokenIdMargins[tokenId];

        uint256[] memory symbolIds = getActiveSymbolIds();
        for (uint256 i = 0; i < symbolIds.length; i++) {
            if (_tokenIdPositions[tokenId][symbolIds[i]].volume != 0) {
                _numPositionHolders[symbolIds[i]]--;
            }
            delete _tokenIdPositions[tokenId][symbolIds[i]];
        }

        emit Transfer(owner, address(0), tokenId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC721.sol';

interface IPTokenLite is IERC721 {

    struct Position {
        // position volume, long is positive and short is negative
        int256 volume;
        // the cost the establish this position
        int256 cost;
        // the last cumulativeFundingRate since last funding settlement for this position
        // the overflow for this value in intended
        int256 lastCumulativeFundingRate;
    }

    event UpdateMargin(address indexed owner, int256 amount);

    event UpdatePosition(address indexed owner, uint256 indexed symbolId, int256 volume, int256 cost, int256 lastCumulativeFundingRate);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function pool() external view returns (address);

    function totalMinted() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function setPool(address newPool) external;

    function getActiveSymbolIds() external view returns (uint256[] memory);

    function isActiveSymbolId(uint256 symbolId) external view returns (bool);

    function getNumPositionHolders(uint256 symbolId) external view returns (uint256);

    function addSymbolId(uint256 symbolId) external;

    function removeSymbolId(uint256 symbolId) external;

    function toggleCloseOnly(uint256 symbolId) external;

    function exists(address owner) external view returns (bool);

    function getMargin(address owner) external view returns (int256);

    function updateMargin(address owner, int256 margin) external;

    function addMargin(address owner, int256 delta) external;

    function getPosition(address owner, uint256 symbolId) external view returns (Position memory);

    function updatePosition(address owner, uint256 symbolId, Position memory position) external;

    function mint(address owner) external;

    function burn(address owner) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IERC721Receiver.sol';
import '../interface/IERC721.sol';
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

    modifier _existsTokenId_(uint256 tokenId) {
        require(_exists(tokenId), 'ERC721: nonexistent tokenId');
        _;
    }

    modifier _existsOwner_(address owner) {
        require(_exists(owner), 'ERC721: nonexistent owner');
        _;
    }

    constructor () {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) public override view returns (uint256) {
        return _exists(owner) ? 1 : 0;
    }

    function ownerOf(uint256 tokenId) public override view _existsTokenId_(tokenId) returns (address) {
        return _tokenIdOwner[tokenId];
    }

    function getTokenId(address owner) public override view _existsOwner_(owner) returns (uint256) {
        return _ownerTokenId[owner];
    }

    function getApproved(uint256 tokenId) public override view _existsTokenId_(tokenId) returns (address) {
        return _tokenIdOperator[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public override view _existsOwner_(owner) returns (bool) {
        return _ownerOperator[owner][operator];
    }

    function approve(address operator, uint256 tokenId) public override {
        require(msg.sender == ownerOf(tokenId), 'ERC721.approve: caller not owner');
        _tokenIdOperator[tokenId] = operator;
        emit Approval(msg.sender, operator, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(_exists(msg.sender), 'ERC721.setApprovalForAll: nonexistent owner');
        _ownerOperator[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        _validateTransfer(msg.sender, from, to, tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
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
        require(from == ownerOf(tokenId), 'ERC721._validateTransfer: not owned token');
        require(to != address(0) && !_exists(to), 'ERC721._validateTransfer: to address exists or 0');
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract
     * recipients are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Validation check on parameters should be carried out before calling this function.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     *      The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID.
     * @param to target address that will receive the tokens.
     * @param tokenId uint256 ID of the token to be transferred.
     * @param data bytes optional data to send along with the call.
     * @return bool whether the call correctly returned the expected magic value.
     */
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

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `operator` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the 'tokenId' owned by 'owner'
     *
     * Requirements:
     *
     *  - `owner` must exist
     */
    function getTokenId(address owner) external view returns (uint256);

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Gives permission to `operator` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address
     * clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address operator, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
     * - If the caller is not `from`, it must be approved to move this token
     *   by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first
     * that contract recipients are aware of the ERC721 protocol to prevent
     * tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token
     *   by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     *   by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via
     * {IERC721-safeTransferFrom} by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient,
     * the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
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

import '../interface/IERC165.sol';

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public override view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

