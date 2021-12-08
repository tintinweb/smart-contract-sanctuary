/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

library Strings {
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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string internal _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string private _tokenBaseURI;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

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
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _tokenBaseURI;
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        _tokenBaseURI = baseURI_;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface Token is IERC20 {
    function burn(address account, uint256 amount) external returns (bool);
}

interface Collection is IERC721 {
    function getTokenClanId(uint256 id) external view returns (uint8);
}

contract Staking is IERC721Receiver, Ownable {
    struct Staker {
        uint256 islApes;
        uint256 genApes;
        uint256[] islApeIDs;
        uint256[] genApeIDs;
        uint256 multiplier;
        uint256 rewarded;
        uint256 recent;
    }

    uint256 public _rate = 5 ether;
    uint256 public _multiplier = 10;
    uint256 public _pack = 2;

    mapping(address => Staker) private _stakingDetails;

    uint256 private _totalStakedIslApes;
    uint256 private _totalStakedGenApes;
    uint256 private _totalStakedRewards;

    address public immutable _APE_ONLY_ISLAND_COLLECTION_CA;
    address public immutable _GENESIS_APE_ONLY_CA;

    address public _APE_ONLY_ISLAND_TOKEN_CA;

    event Staked(address indexed account, uint256 id);

    event Unstaked(address indexed account, uint256 id);

    event Rewarded(address indexed account, uint256 amount);

    event Funded(address indexed account, uint256 amount);

    constructor() {
        _APE_ONLY_ISLAND_TOKEN_CA = 0x3aF3eeC33fE5B1af5cE4E1F3BA32e64Ab78912B2;
        _APE_ONLY_ISLAND_COLLECTION_CA = 0x260428e36989ee6c6829F8a6E361cba99C7a8447;
        _GENESIS_APE_ONLY_CA = 0xf1e0bEcA4eac65F902466881CDfDD0099D91e47b;
    }

    function setTokenAddress(address token) external onlyOwner returns (bool) {
        _APE_ONLY_ISLAND_TOKEN_CA = token;
        return true;
    }

    function stakeWithMultiplier(
        uint256 packs,
        uint256[] calldata islApes,
        uint256[] calldata genApes
    ) external returns (bool) {
        address account = _msgSender();
        uint256 minimum = _pack * packs;

        require(
            _totalStakedRewards > 0,
            "Staking: no staking rewards available"
        );

        require(
            packs > 0,
            "Staking: minimum argument of island apes not valid"
        );

        require(
            IERC721(_APE_ONLY_ISLAND_COLLECTION_CA).balanceOf(account) >=
                minimum,
            "Staking: minimum of island apes for pack size not found"
        );

        uint256 islApesLength = islApes.length;
        uint256 genApesLength = genApes.length;

        require(
            genApesLength <= islApesLength,
            "Staking: genesis ape length must not be larger than island ape length"
        );

        require(
            islApesLength == minimum,
            "Staking: minimum of island apes for pack size not found"
        );

        require(
            _stakingDetails[account].islApes == 0,
            "Staking: account must unstake to stake"
        );

        uint8 packsClan = getClanId(islApes[0]);

        for (uint256 i = 0; i < islApesLength; i++) {
            require(
                IERC721(_APE_ONLY_ISLAND_COLLECTION_CA).ownerOf(islApes[i]) ==
                    account,
                "Staking: account must be the owner of all island ape <ID> inputs"
            );

            require(
                packsClan == getClanId(islApes[i]),
                "Staking: all apes have to be from same clan"
            );

            IERC721(_APE_ONLY_ISLAND_COLLECTION_CA).transferFrom(
                account,
                address(this),
                islApes[i]
            );
            _stakingDetails[account].islApeIDs.push(islApes[i]);
            emit Staked(account, islApes[i]);
        }

        for (uint256 i = 0; i < genApesLength; i++) {
            require(
                IERC721(_GENESIS_APE_ONLY_CA).ownerOf(genApes[i]) == account,
                "Staking: account must be the owner of all genesis ape <ID> inputs"
            );

            IERC721(_GENESIS_APE_ONLY_CA).transferFrom(
                account,
                address(this),
                genApes[i]
            );
            _stakingDetails[account].genApeIDs.push(genApes[i]);
            emit Staked(account, genApes[i]);
        }

        _stakingDetails[account].islApes += islApesLength;
        _stakingDetails[account].genApes += genApesLength;

        _stakingDetails[account].multiplier = _multiplier * genApesLength;
        _stakingDetails[account].recent = block.timestamp;

        _totalStakedIslApes += islApesLength;
        _totalStakedGenApes += genApesLength;

        return true;
    }

    function stake(uint256 packs, uint256[] calldata islApes)
        external
        returns (bool)
    {
        address account = _msgSender();
        uint256 minimum = _pack * packs;

        require(
            _totalStakedRewards > 0,
            "Staking: no staking rewards available"
        );

        require(
            IERC721(_APE_ONLY_ISLAND_COLLECTION_CA).balanceOf(account) >=
                minimum,
            "Staking: minimum of island apes for pack size not found"
        );

        uint256 islApesLength = islApes.length;

        require(
            islApesLength == minimum,
            "Staking: input of island apes and minimum must match"
        );

        require(
            _stakingDetails[account].islApes == 0,
            "Staking: account must unstake to stake"
        );

        uint8 packsClan = getClanId(islApes[0]);

        for (uint256 i = 0; i < islApesLength; i++) {
            require(
                packsClan == getClanId(islApes[i]),
                "Staking: all apes have to be from same clan"
            );

            require(
                IERC721(_APE_ONLY_ISLAND_COLLECTION_CA).ownerOf(islApes[i]) ==
                    account,
                "Staking: account must be the owner of all island ape <ID> inputs"
            );

            IERC721(_APE_ONLY_ISLAND_COLLECTION_CA).safeTransferFrom(
                account,
                address(this),
                islApes[i]
            );
            _stakingDetails[account].islApeIDs.push(islApes[i]);
            emit Staked(account, islApes[i]);
        }

        _stakingDetails[account].islApes += islApesLength;
        _stakingDetails[account].recent = block.timestamp;
        _totalStakedIslApes += islApesLength;
        return true;
    }

    function unstake() external returns (bool) {
        address account = _msgSender();

        require(
            _stakingDetails[account].islApes > 0,
            "Staking: no staked island apes found"
        );

        uint256 islApes = _stakingDetails[account].islApes;
        uint256[] memory islApeIDs = _stakingDetails[account].islApeIDs;

        uint256 genApes = _stakingDetails[account].genApes;
        uint256[] memory genApeIDs = _stakingDetails[account].genApeIDs;

        if (getAccountRewardsAvailable(account) > 0) reward();

        delete _stakingDetails[account].islApes;
        delete _stakingDetails[account].genApes;
        delete _stakingDetails[account].islApeIDs;
        delete _stakingDetails[account].genApeIDs;
        delete _stakingDetails[account].multiplier;

        for (uint256 i = 0; i < islApes; i++) {
            ERC721(_APE_ONLY_ISLAND_COLLECTION_CA).safeTransferFrom(
                address(this),
                account,
                islApeIDs[i]
            );
            emit Unstaked(account, islApeIDs[i]);
        }

        for (uint256 i = 0; i < genApes; i++) {
            ERC721(_GENESIS_APE_ONLY_CA).safeTransferFrom(
                address(this),
                account,
                genApeIDs[i]
            );
            emit Unstaked(account, genApeIDs[i]);
        }

        _totalStakedIslApes -= islApes;
        _totalStakedGenApes -= genApes;
        return true;
    }

    function fund(uint256 amount) external returns (bool) {
        require(amount > 0, "Staking: must be a valid amount");

        address account = _msgSender();

        require(
            IERC20(_APE_ONLY_ISLAND_TOKEN_CA).balanceOf(account) >= amount,
            "Staking: no island tokens found"
        );

        require(
            IERC20(_APE_ONLY_ISLAND_TOKEN_CA).transferFrom(
                account,
                address(this),
                amount
            ),
            "Staking: transfer of staked rewards failed"
        );

        _totalStakedRewards += amount;

        emit Funded(account, amount);
        return true;
    }

    function emergencyUnstake() external returns (bool) {
        address account = _msgSender();

        require(
            _stakingDetails[account].islApes > 0,
            "Staking: no staked island apes found"
        );

        uint256 islApes = _stakingDetails[account].islApes;
        uint256[] memory islApeIDs = _stakingDetails[account].islApeIDs;

        uint256 genApes = _stakingDetails[account].genApes;
        uint256[] memory genApeIDs = _stakingDetails[account].genApeIDs;

        delete _stakingDetails[account].islApes;
        delete _stakingDetails[account].genApes;
        delete _stakingDetails[account].islApeIDs;
        delete _stakingDetails[account].genApeIDs;
        delete _stakingDetails[account].multiplier;

        for (uint256 i = 0; i < islApes; i++) {
            ERC721(_APE_ONLY_ISLAND_COLLECTION_CA).safeTransferFrom(
                address(this),
                account,
                islApeIDs[i]
            );
            emit Unstaked(account, islApeIDs[i]);
        }

        for (uint256 i = 0; i < genApes; i++) {
            ERC721(_GENESIS_APE_ONLY_CA).safeTransferFrom(
                address(this),
                account,
                genApeIDs[i]
            );
            emit Unstaked(account, genApeIDs[i]);
        }

        _totalStakedIslApes -= islApes;
        _totalStakedGenApes -= genApes;
        return true;
    }

    function emergencyWithdraw() external onlyOwner returns (bool) {
        address account = _msgSender();

        require(
            _totalStakedRewards > 0,
            "Staking: no staking rewards available"
        );

        require(
            Token(_APE_ONLY_ISLAND_TOKEN_CA).transfer(
                account,
                _totalStakedRewards
            ),
            "Staking: transfer of staked rewards failed"
        );

        delete _totalStakedRewards;

        return true;
    }

    function setRewardRate(uint256 amount) external onlyOwner returns (bool) {
        _rate = amount;
        return true;
    }

    function setRewardMultiplier(uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        _multiplier = amount;
        return true;
    }

    function setPackSize(uint256 amount) external onlyOwner returns (bool) {
        _rate = amount;
        return true;
    }

    function getRewardRate() external view returns (uint256) {
        //return global reward rate per staked island ape
        return _rate;
    }

    function getGenesisMultiplier() external view returns (uint256) {
        //return global multiplier % from staking genesis apes
        return _multiplier;
    }

    function getPackSize() external view returns (uint256) {
        //return global pack size required to stake
        return _pack;
    }

    function getTotalStakedGenesisApes() external view returns (uint256) {
        //return total staked genesis apes in contract
        return _totalStakedGenApes;
    }

    function getTotalStakedIslandApes() external view returns (uint256) {
        //return total staked island apes in contract
        return _totalStakedIslApes;
    }

    function getTotalStakedRewards() external view returns (uint256) {
        //return total funded rewards in contract
        return _totalStakedRewards;
    }

    function getAccountStakedIslandApes(address account)
        external
        view
        returns (uint256)
    {
        //return amount of island apes staked by account
        return _stakingDetails[account].islApes;
    }

    function getAccountStakedGenesisApes(address account)
        external
        view
        returns (uint256)
    {
        //return amount of genesis apes staked by account
        return _stakingDetails[account].genApes;
    }

    function getAccountStakedIslandApeIDs(address account)
        external
        view
        returns (uint256[] memory)
    {
        //return all island apes by id staked by account
        return _stakingDetails[account].islApeIDs;
    }

    function getAccountStakedGenesisApeIDs(address account)
        external
        view
        returns (uint256[] memory)
    {
        //return all genesis apes by id staked by account
        return _stakingDetails[account].genApeIDs;
    }

    function getAccountReward(address account) external view returns (uint256) {
        //return all rewards earned by account
        return _stakingDetails[account].rewarded;
    }

    function getAccountMultiplier(address account)
        external
        view
        returns (uint256)
    {
        //return reward multiplier by account
        return _stakingDetails[account].multiplier;
    }

    function getAccountRecentActivity(address account)
        external
        view
        returns (uint256)
    {
        //return most recent activity by account
        return _stakingDetails[account].recent;
    }

    function reward() public returns (bool) {
        address account = _msgSender();

        require(_totalStakedRewards > 0, "Staking: no rewards available");

        uint256 rewards = getAccountRewardsAvailable(account);

        require(rewards > 0, "Staking: no rewards earned");

        _stakingDetails[account].rewarded += rewards;
        _stakingDetails[account].recent = block.timestamp;

        require(
            IERC20(_APE_ONLY_ISLAND_TOKEN_CA).transfer(account, rewards),
            "Staking: transfer of rewards failed"
        );

        _totalStakedRewards -= rewards;

        emit Rewarded(account, rewards);
        return true;
    }

    function getAccountRewardsAvailable(address account)
        public
        view
        returns (uint256)
    {
        if (_totalStakedRewards > 0) {
            uint256 start = _stakingDetails[account].recent;
            uint256 duration;

            if (block.timestamp - start >= 86400) {
                duration = (block.timestamp - start) / 86400;
                return getAccountRewardsEstimatedDaily(account) * duration;
            }
        }
        return 0;
    }

    function getAccountRewardsEstimatedDaily(address account)
        public
        view
        returns (uint256)
    {
        uint256 staked = _stakingDetails[account].islApes;
        uint256 multiplier = _stakingDetails[account].multiplier;
        uint256 reward = _rate * staked;

        //return processed reward with multiplier
        return reward + ((reward * multiplier) / 100);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getClanId(uint256 apeId) private view returns (uint8) {
        return Collection(_APE_ONLY_ISLAND_COLLECTION_CA).getTokenClanId(apeId);
    }
}