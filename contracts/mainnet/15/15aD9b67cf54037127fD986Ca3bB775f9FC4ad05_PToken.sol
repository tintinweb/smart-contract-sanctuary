// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../interface/IERC721.sol";
import "../interface/IPToken.sol";
import "./ERC721.sol";
import "../math/UnsignedSafeMath.sol";

/**
 * @title Deri Protocol non-fungible position token implementation
 */
contract PToken is IERC721, IPToken, ERC721 {

    using UnsignedSafeMath for uint256;

    // Pool address this PToken associated with
    address private _pool;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Total ever minted PToken
    uint256 private _totalMinted;

    // Total existent PToken
    uint256 private _totalSupply;

    // Mapping from tokenId to Position
    mapping (uint256 => Position) private _tokenIdPosition;

    modifier _pool_() {
        require(msg.sender == _pool, "PToken: called by non-associative pool, probably the original pool has been migrated");
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection
     */
    constructor (string memory name_, string memory symbol_, address pool_) {
        require(pool_ != address(0), "PToken: construct with 0 address pool");
        _name = name_;
        _symbol = symbol_;
        _pool = pool_;
    }

    /**
     * @dev See {IPToken}.{setPool}
     */
    function setPool(address newPool) public override {
        require(newPool != address(0), "PToken: setPool to 0 address");
        require(msg.sender == _pool, "PToken: setPool caller is not current pool");
        _pool = newPool;
    }

    /**
     * @dev See {IPToken}.{pool}
     */
    function pool() public view override returns (address) {
        return _pool;
    }

    /**
     * @dev See {IPToken}.{name}
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IPToken}.{symbol}
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IPToken}.{totalMinted}
     */
    function totalMinted() public view override returns (uint256) {
        return _totalMinted;
    }

    /**
     * @dev See {IPToken}.{totalSupply}
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IPToken}.{exists}
     */
    function exists(address owner) public view override returns (bool) {
        return _exists(owner);
    }

    /**
     * @dev See {IPToken}.{exists}
     */
    function exists(uint256 tokenId) public view override returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev See {IPToken}.{getPosition}
     */
    function getPosition(address owner) public view override returns (
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    ) {
        require(_exists(owner), "PToken: getPosition for nonexistent owner");
        Position storage p = _tokenIdPosition[_ownerTokenId[owner]];
        return (
            p.volume,
            p.cost,
            p.lastCumuFundingRate,
            p.margin,
            p.lastUpdateTimestamp
        );
    }

    /**
     * @dev See {IPToken}.{getPosition}
     */
    function getPosition(uint256 tokenId) public view override returns (
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    ) {
        require(_exists(tokenId), "PToken: getPosition for nonexistent tokenId");
        Position storage p = _tokenIdPosition[tokenId];
        return (
            p.volume,
            p.cost,
            p.lastCumuFundingRate,
            p.margin,
            p.lastUpdateTimestamp
        );
    }

    /**
     * @dev See {IPToken}.{mint}
     */
    function mint(address owner, uint256 margin) public override _pool_ {
        require(owner != address(0), "PToken: mint to 0 address");
        require(!_exists(owner), "PToken: mint to existent owner");

        _totalMinted = _totalMinted.add(1);
        _totalSupply = _totalSupply.add(1);
        uint256 tokenId = _totalMinted;
        require(!_exists(tokenId), "PToken: mint to existent tokenId");

        _ownerTokenId[owner] = tokenId;
        _tokenIdOwner[tokenId] = owner;
        Position storage p = _tokenIdPosition[tokenId];
        p.margin = margin;

        emit Transfer(address(0), owner, tokenId);
    }

    /**
     * @dev See {IPToken}.{update}
     */
    function update(
        address owner,
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    ) public override _pool_
    {
        require(_exists(owner), "PToken: update to nonexistent owner");
        Position storage p = _tokenIdPosition[_ownerTokenId[owner]];
        p.volume = volume;
        p.cost = cost;
        p.lastCumuFundingRate = lastCumuFundingRate;
        p.margin = margin;
        p.lastUpdateTimestamp = lastUpdateTimestamp;

        emit Update(owner, volume, cost, lastCumuFundingRate, margin, lastUpdateTimestamp);
    }

    /**
     * @dev See {IPToken}.{burn}
     */
    function burn(address owner) public override _pool_ {
        require(_exists(owner), "PToken: burn nonexistent owner");
        uint256 tokenId = _ownerTokenId[owner];
        Position storage p = _tokenIdPosition[tokenId];
        require(p.volume == 0, "PToken: burn non empty token");

        _totalSupply = _totalSupply.sub(1);

        // clear ownership and approvals
        delete _ownerTokenId[owner];
        delete _tokenIdOwner[tokenId];
        delete _tokenIdPosition[tokenId];
        delete _tokenIdOperator[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title Deri Protocol non-fungible position token interface
 */
interface IPToken is IERC721 {

    /**
     * @dev Emitted when `owner`'s position is updated
     */
    event Update(
        address indexed owner,
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    );

    /**
     * @dev Position struct
     */
    struct Position {
        // Position volume, long is positive and short is negative
        int256 volume;
        // Position cost, long position cost is positive, short position cost is negative
        int256 cost;
        // The last cumuFundingRate since last funding settlement for this position
        // The overflow for this value is intended
        int256 lastCumuFundingRate;
        // Margin associated with this position
        uint256 margin;
        // Last timestamp this position updated
        uint256 lastUpdateTimestamp;
    }

    /**
     * @dev Set pool address of position token
     * pool is the only controller of this contract
     * can only be called by current pool
     */
    function setPool(address newPool) external;

    /**
     * @dev Returns address of current pool
     */
    function pool() external view returns (address);

    /**
     * @dev Returns the token collection name
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the total number of ever minted position tokens, including those burned
     */
    function totalMinted() external view returns (uint256);

    /**
     * @dev Returns the total number of existent position tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns if `owner` owns a position token in this contract
     */
    function exists(address owner) external view returns (bool);

    /**
     * @dev Returns if position token of `tokenId` exists
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns the position of owner `owner`
     *
     * `owner` must exist
     */
    function getPosition(address owner) external view returns (
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    );

    /**
     * @dev Returns the position of token `tokenId`
     *
     * `tokenId` must exist
     */
    function getPosition(uint256 tokenId) external view returns (
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    );

    /**
     * @dev Mint a position token for `owner` with intial margin of `margin`
     *
     * Can only be called by pool
     * `owner` cannot be zero address
     * `owner` must not exist before calling
     */
    function mint(address owner, uint256 margin) external;

    /**
     * @dev Update the position token for `owner`
     *
     * Can only be called by pool
     * `owner` must exist
     */
    function update(
        address owner,
        int256 volume,
        int256 cost,
        int256 lastCumuFundingRate,
        uint256 margin,
        uint256 lastUpdateTimestamp
    ) external;

    /**
     * @dev Burn the position token owned of `owner`
     *
     * Can only be called by pool
     * `owner` must exist
     */
    function burn(address owner) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../interface/IERC721.sol";
import "../interface/IERC721Receiver.sol";
import "../utils/Address.sol";
import "./ERC165.sol";

/**
 * @dev ERC721 Non-Fungible Token Implementation
 *
 * Exert uniqueness of owner: one owner can only have one token
 */
contract ERC721 is IERC721, ERC165 {

    using Address for address;

    /*
     * Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
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

    /**
     * @dev See {IERC721}.{balanceOf}
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (_exists(owner)) {
            return 1;
        } else {
            return 0;
        }
    }

    /**
     * @dev See {IERC721}.{ownerOf}
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: ownerOf for nonexistent tokenId");
        return _tokenIdOwner[tokenId];
    }

    /**
     * @dev See {IERC721}.{getApproved}
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: getApproved for nonexistent tokenId");
        return _tokenIdOperator[tokenId];
    }

    /**
     * @dev See {IERC721}.{isApprovedForAll}
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        require(_exists(owner), "ERC721: isApprovedForAll for nonexistent owner");
        return _ownerOperator[owner][operator];
    }

    /**
     * @dev See {IERC721}.{approve}
     */
    function approve(address operator, uint256 tokenId) public override {
        require(msg.sender == ownerOf(tokenId), "ERC721: approve caller is not owner");
        _approve(msg.sender, operator, tokenId);
    }

    /**
     * @dev See {IERC721}.{setApprovalForAll}
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(_exists(msg.sender), "ERC721: setApprovalForAll caller is not existent owner");
        _ownerOperator[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721}.{transferFrom}
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        _validateTransfer(msg.sender, from, to, tokenId);
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721}.{safeTransferFrom}
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721}.{safeTransferFrom}
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public override
    {
        _validateTransfer(msg.sender, from, to, tokenId);
        _safeTransfer(from, to, tokenId, data);
    }


    /**
     * @dev Returns if owner exists.
     */
    function _exists(address owner) internal view returns (bool) {
        return _ownerTokenId[owner] != 0;
    }

    /**
     * @dev Returns if tokenId exists.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenIdOwner[tokenId] != address(0);
    }

    /**
     * @dev Approve `operator` to manage `tokenId`, owned by `owner`
     *
     * Validation check on parameters should be carried out before calling this function.
     */
    function _approve(address owner, address operator, uint256 tokenId) internal {
        _tokenIdOperator[tokenId] = operator;
        emit Approval(owner, operator, tokenId);
    }

    /**
     * @dev Validate transferFrom parameters
     */
    function _validateTransfer(address operator, address from, address to, uint256 tokenId)
        internal view
    {
        require(from == ownerOf(tokenId), "ERC721: transfer not owned token");
        require(to != address(0), "ERC721: transfer to 0 address");
        require(!_exists(to), "ERC721: transfer to already existent owner");
        require(
            operator == from || _tokenIdOperator[tokenId] == operator || _ownerOperator[from][operator],
            "ERC721: transfer caller is not owner nor approved"
        );
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Validation check on parameters should be carried out before calling this function.
     *
     * Emits a {Transfer} event.
     */
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
            "ERC721: transfer to non ERC721Receiver implementer"
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
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Unsigned safe math
 */
library UnsignedSafeMath {

    /**
     * @dev Addition of unsigned integers, counterpart to `+`
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "UnsignedSafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Subtraction of unsigned integers, counterpart to `-`
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "UnsignedSafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Multiplication of unsigned integers, counterpart to `*`
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero,
        // but the benefit is lost if 'b' is also tested
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "UnsignedSafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Division of unsigned integers, counterpart to `/`
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "UnsignedSafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Modulo of unsigned integers, counterpart to `%`
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "UnsignedSafeMath: modulo by zero");
        uint256 c = a % b;
        return c;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../interface/IERC165.sol";

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
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
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