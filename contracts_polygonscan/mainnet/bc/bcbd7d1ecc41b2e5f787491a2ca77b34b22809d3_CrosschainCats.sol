/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.5.15;

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

/* ERC165.sol *****************************************************************/

/// @title ERC-165 Standard Interface Detection
/// @dev Reference https://eips.ethereum.org/EIPS/eip-165
interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/* ERC721.sol *****************************************************************/

/// @title ERC-721 Non-Fungible Token Standard
/// @dev Reference https://eips.ethereum.org/EIPS/eip-721
interface IERC721 /* is ERC165 */ {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
interface IERC721Metadata /* is ERC721 */ {
    function name() external pure returns (string memory _name);
    function symbol() external pure returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
interface IERC721Enumerable /* is ERC721 */ {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

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

        //(bool success, ) = recipient.call{value: amount}("");
        (bool success, ) = recipient.call.value(amount)("");
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

        //(bool success, bytes memory returndata) = target.call{value: value}(data);
        (bool success, bytes memory returndata) = target.call.value(value)(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



/* AccessControl.sol **********************************************************/

contract AccessControl {
    using SafeERC20 for IERC20;

    address payable public ceo;

    constructor() internal {
        ceo = msg.sender;
    }

    /// @dev Only allowed by executive officer
    modifier onlyCEO() {
        require(msg.sender == ceo);
        _;
    }

    /// @notice Reassign the executive officer role
    /// @param ceo_ new officer address
    function setCEO(address payable ceo_)
        external
        onlyCEO
    {
        require(ceo_ != address(0));
        ceo = ceo_;
    }

    /// @notice Collect funds from this contract
    function withdraw()
        external
        onlyCEO
    {
        ceo.transfer(address(this).balance);
    }

    /// @notice Collect token from this contract
    function withdrawToken(IERC20 token)
        external
        onlyCEO
    {
        token.safeTransfer(ceo, token.balanceOf(ceo));
    }
}



/* SupportsInterface.sol ******************************************************/

/// @title A reusable contract to comply with ERC-165
contract SupportsInterface is IERC165 {
    /// @dev Every interface that we support, do not set 0xffffffff to true
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() internal {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return supportedInterfaces[interfaceID] && (interfaceID != 0xffffffff);
    }
}

/* CrosschainCatsNFT.sol ******************************************************************/

/// @title ERC-721
/// @dev This implementation assumes:
///  - A fixed supply of NFTs, cannot mint or burn
///  - ids are numbered sequentially starting at 1.
///  - This contract does not externally call its own functions
contract CrosschainCatsNFT is AccessControl, IERC165, IERC721, IERC721Metadata, IERC721Enumerable, SupportsInterface {
    /// @dev The authorized address for each NFT
    mapping (uint256 => address) internal tokenApprovals;

    /// @dev The authorized operators for each address
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    address initial;

    string internal _baseURI;
    string internal _contractURI;

    /// @dev Only allowed by executive officer
    modifier onlyCEO() {
        require(msg.sender == ceo);
        _;
    }

    /// @dev Guarantees msg.sender is the owner of _tokenId
    /// @param _tokenId The token to validate belongs to msg.sender
    modifier onlyOwnerOf(uint256 _tokenId) {
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        // assert(msg.sender != address(this))
        require(msg.sender == owner);
        _;
    }

    modifier mustBeOwnedByThisContract(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= TOTAL_SUPPLY);
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        require(owner == address(0) || owner == address(this));
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        // assert(msg.sender != address(this))
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        require(msg.sender == owner || operatorApprovals[owner][msg.sender]);
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        // assert(msg.sender != address(this))
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        if (owner == address(0)) {
            owner = initial;
        }
        require(msg.sender == owner ||
          msg.sender == tokenApprovals[_tokenId] ||
          operatorApprovals[owner][msg.sender]);
        _;
    }

    modifier mustBeValidToken(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= TOTAL_SUPPLY);
        _;
    }

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _tokensOfOwnerWithSubstitutions[_owner].length;
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return _owner The address of the owner of the NFT
    function ownerOf(uint256 _tokenId)
        external
        view
       
        mustBeValidToken(_tokenId)
        returns (address _owner)
    {
        _owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Do owner address substitution
        if (_owner == address(0)) {
            _owner = initial;
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable
    {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        payable
       
        mustBeValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Do owner address substitution
        if (owner == address(0)) {
            owner = initial;
        }
        require(owner == _from);
        require(_to != address(0));
        _transfer(_tokenId, _to);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)
        external
        payable
       
        mustBeValidToken(_tokenId)
        canOperate(_tokenId)
    {
        address _owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Do owner address substitution
        if (_owner == address(0)) {
            _owner = initial;
        }
        tokenApprovals[_tokenId] = _approved;
        emit Approval(_owner, _approved, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to
    ///  manage all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId)
        external
        view
       
        mustBeValidToken(_tokenId)
        returns (address)
    {
        return tokenApprovals[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    // COMPLIANCE WITH ERC721Metadata //////////////////////////////////////////

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string memory) {
        return "Crosschain Cats";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string memory) {
        return "CCCATS";
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory str)
    {
        if (_i == 0)
        {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId)
        external
        view
        mustBeValidToken(_tokenId)
        returns (string memory _tokenURI)
    {
        return string(abi.encodePacked(baseURI(), uint2str(_tokenId), ".json"));
    }

    // COMPLIANCE WITH ERC721Enumerable ////////////////////////////////////////

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one
    ///  has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < TOTAL_SUPPLY);
        return _index + 1;
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return _tokenId The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId) {
        require(_owner != address(0));
        require(_index < _tokensOfOwnerWithSubstitutions[_owner].length);
        _tokenId = _tokensOfOwnerWithSubstitutions[_owner][_index];
        // Handle substitutions
        if (_owner == initial) {
            if (_tokenId == 0) {
                _tokenId = _index + 1;
            }
        }
    }

    // INTERNAL INTERFACE //////////////////////////////////////////////////////

    /// @dev Actually do a transfer, does NO precondition checking
    function _transfer(uint256 _tokenId, address _to) internal {
        // Here are the preconditions we are not checking:
        // assert(canTransfer(_tokenId))
        // assert(mustBeValidToken(_tokenId))
        require(_to != address(0));

        // Find the FROM address
        address from = _tokenOwnerWithSubstitutions[_tokenId];
        // Do owner address substitution
        if (from == address(0)) {
            from = initial;
        }

        // Take away from the FROM address
        // The Entriken algorithm for deleting from an indexed, unsorted array
        uint256 indexToDelete = _ownedTokensIndexWithSubstitutions[_tokenId];
        // Do owned tokens substitution
        if (indexToDelete == 0) {
            indexToDelete = _tokenId - 1;
        } else {
            indexToDelete = indexToDelete - 1;
        }
        // We can only shrink an array from its end. If the item we want to
        // delete is in the middle then copy last item to middle and shrink
        // the end.
        if (indexToDelete != _tokensOfOwnerWithSubstitutions[from].length - 1) {
            uint256 lastNft = _tokensOfOwnerWithSubstitutions[from][_tokensOfOwnerWithSubstitutions[from].length - 1];
            // Do tokens of owner substitution
            if (lastNft == 0) {
                // assert(from ==  address(0) || from == address(this));
                lastNft = _tokensOfOwnerWithSubstitutions[from].length; // - 1 + 1
            }
            _tokensOfOwnerWithSubstitutions[from][indexToDelete] = lastNft;
            _ownedTokensIndexWithSubstitutions[lastNft] = indexToDelete + 1;
        }
        // Next line also deletes the contents at the last position of the array (gas refund)
        // solidity 6
        _tokensOfOwnerWithSubstitutions[from].length--;
        //_tokensOfOwnerWithSubstitutions[from].pop();
        // Right now _ownedTokensIndexWithSubstitutions[_tokenId] is invalid, set it below based on the new owner

        // Give to the TO address
        _tokensOfOwnerWithSubstitutions[_to].push(_tokenId);
        _ownedTokensIndexWithSubstitutions[_tokenId] = (_tokensOfOwnerWithSubstitutions[_to].length - 1) + 1;

        // External processing
        _tokenOwnerWithSubstitutions[_tokenId] = _to;
        tokenApprovals[_tokenId] = address(0);
        emit Transfer(from, _to, _tokenId);
    }

    uint256 constant TOTAL_SUPPLY = 25000;

    bytes4 private constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @dev The owner of each NFT
    ///  If value == address(0), NFT is owned by address(this)
    ///  If value != address(0), NFT is owned by value
    ///  assert(This contract never assigns ownership to address(0) or destroys NFTs)
    ///  In other words address(0) in storage means address(this) outside
    mapping (uint256 => address) private _tokenOwnerWithSubstitutions;

    /// @dev The list of NFTs owned by each address
    ///  Nomenclature: arr[key][index] = value
    ///  If key != address(this) or value != 0, then value represents an NFT
    ///  If key == address(this) and value == 0, then index + 1 is the NFT
    ///  assert(0 is not a valid NFT)
    ///  In other words [0, 0, a, 0] is equivalent to [1, 2, a, 4] for address(this)
    mapping (address => uint256[]) private _tokensOfOwnerWithSubstitutions;

    /// @dev (Location + 1) of each NFT in its owner's list
    ///  Nomenclature: arr[nftId] = value
    ///  If value != 0, _tokensOfOwnerWithSubstitutions[owner][value - 1] = nftId
    ///  If value == 0, _tokensOfOwnerWithSubstitutions[owner][nftId - 1] = nftId
    ///  assert(2**256-1 is not a valid NFT)
    ///  In other words mapping {a=>a} is equivalent to {a=>0}
    mapping (uint256 => uint256) private _ownedTokensIndexWithSubstitutions;

    constructor() internal {
        initial = msg.sender;
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
        supportedInterfaces[0x8153916a] = true; // ERC721 + 165 (not needed)
        _tokensOfOwnerWithSubstitutions[initial].length = TOTAL_SUPPLY;
    }

    /// @dev Actually perform the safeTransferFrom
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data)
        private
        mustBeValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Do owner address substitution
        if (owner == address(0)) {
            owner = initial;
        }
        require(owner == _from);
        require(_to != address(0));
        _transfer(_tokenId, _to);

        // Do the callback after everything is done to avoid reentrancy attack
        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
        require(retval == ERC721_RECEIVED);
    }

    /// @notice 10% royalties going to this contract
    function royaltyInfo(uint256, uint256 value)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        royaltyAmount = (value * 1000) / 10000;
    }

        /// @notice helper to set the description
    /// @param baseURI_ the new baseURI
    function _setBaseURI(string memory baseURI_)
        internal
    {
        _baseURI = baseURI_;
    }
 
    /// @notice helper to set the description
    /// @param baseURI_ the new baseURI
    function setBaseURI(string calldata baseURI_)
        external
        onlyCEO
    {
        _baseURI = baseURI_;
    }

    /// @notice helper to set the description
    function baseURI()
        public
        view
        returns (string memory)
    {
        return _baseURI;
    }

    /// @notice Returns the contract URI function. Used on OpenSea to get details
    //          about a contract (owner, royalties etc...)
    function contractURI()
        public
        view
        returns (string memory)
    {
        return _contractURI;
    }

    /// @dev Internal function to set the _contractURI
    /// @param contractURI_ the new contract uri
    function _setContractURI(string memory contractURI_)
        internal
    {
        _contractURI = contractURI_;
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string calldata contractURI_)
        external
        onlyCEO
    {
        _setContractURI(contractURI_);
    }
}

/* CrosschainCats.sol *****************************************************************/

contract CrosschainCats is CrosschainCatsNFT {
    /// @notice constructor
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param baseURI_ The token base URI (metadata) - can be empty ""
    constructor(
            string memory contractURI_,
            string memory baseURI_
        )
        public
    {
        _setBaseURI(baseURI_);
        _setContractURI(contractURI_);
    }
    function() external payable { }
    function receive() external payable { }
}