pragma solidity >=0.6.0 <0.8.0;



interface IERC1155 /* is ERC165 */ {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
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

 contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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


abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}


interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller"s account to `recipient`.
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
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller"s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender"s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller"s
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // "safeIncreaseAllowance" and "safeDecreaseAllowance"
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity"s return data size checnature mechanism, since
        // we"re implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity"s `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly manature contracts go over the 2300 gas limit
     * imposed by `transfer`, manature them unable to receive funds via
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

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


contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot"s contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler"s defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction"s gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by manature the `nonReentrant` function external, and make it call a
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


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity"s `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity"s `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity"s `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity"s `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring "a" not being zero, but the
        // benefit is lost if "b" is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity"s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity"s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn"t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity"s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity"s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library SafeMath96 {

    function add(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add(uint96 a, uint96 b) internal pure returns (uint96) {
        return add(a, b, "SafeMath96: addition overflow");
    }

    function sub(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub(uint96 a, uint96 b) internal pure returns (uint96) {
        return sub(a, b, "SafeMath96: subtraction overflow");
    }

    function fromUint(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function fromUint(uint n) internal pure returns (uint96) {
        return fromUint(n, "SafeMath96: exceeds 96 bits");
    }
}
library SafeMath32 {

    function add(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        return add(a, b, "SafeMath32: addition overflow");
    }

    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub(a, b, "SafeMath32: subtraction overflow");
    }

    function fromUint(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function fromUint(uint n) internal pure returns (uint32) {
        return fromUint(n, "SafeMath32: exceeds 32 bits");
    }
}

library Signing {

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     * Borrowed from: openzeppelin/contracts/cryptography/ECDSA.sol
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
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    function verifySignature(address signatory, bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure {
        require(signatory == recover(hash, v, r, s), "ECDSA: signature does not match");
    }

    function eip712Hash(bytes32 domainSeparator, bytes memory message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, keccak256(message)));
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function checkExpiry(uint256 deadline, uint256 timeNow) internal pure {
        require(timeNow <= deadline, "Signing: signature expired");
    }
}

// ZooKeeper will takes care of the Nature and he is a fair guy...
//
// Note that it"s ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Nature is sufficiently
// distributed and the community can show to govern itself.
contract ZooKeeper is Ownable, ReentrancyGuard, ERC1155Receiver {
    using SafeMath for uint256;
    using SafeMath96 for uint96;
    using SafeMath32 for uint32;

    using SafeBEP20 for IBEP20;

    string public constant version = "1";
    // The name of the contract
    string public constant name = "ZooKeeper";

    // EIP712 niceties
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 public constant DEPOSIT_TYPEHASH = keccak256(
        "Deposit(address user,uint256 pid,uint256 lptAmount,uint256 stAmount,uint256 nonce,uint256 deadline)"
    );
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256(
        "Withdraw(address user,uint256 pid,uint256 lptAmount,uint256 nonce,uint256 deadline)"
    );


    struct UserInfo {
        uint256 wAmount; // Weighted amount = lptAmount + (stAmount * pool.sTokenWeight)
        uint256 stAmount; // How many S tokens the user has provided
        uint256 lptAmount; // How many LP tokens the user has provided
        uint96 pendingNature; // Nature tokens pending to be given to user
        uint96 rewardDebt; // Reward debt (see explanation below)
        uint32 lastWithdrawBlock; // User last withdraw time

        // We do some fancy math here. Basically, any point in time, the amount of Natures
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.wAmount * pool.accNaturePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here"s what happens:
        //   1. The pool"s `accNaturePerShare` (and `lastRewardBlock`) gets updated
        //   2. User receives the pending reward sent to his/her address
        //   3. User"s `wAmount` gets updated
        //   4. User"s `rewardDebt` gets updated
    }

    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract
        uint32 allocPoint; // Allocation points assigned to this pool (for Natures distribution)
        uint32 lastRewardBlock; // Last block number that Natures distribution occurs
        uint32 sTokenWeight; // "Weight" of LP token in SToken, times 1e8
        IBEP20 sToken; // Address of S token contract
        bool natureLock; // if true, withdraw interval, or withdraw fees otherwise, applied on Nature withdrawals
        uint256 accNaturePerShare; // Accumulated Natures per share, times 1e12 (see above)
    }

    // The Nature token contract
    address public erc1155;

    // The natureSpecialist contract (that receives LP token fees)
    address public natureSpecialist;
    // fees on LP token withdrawals, in percents
    uint8 public lpFeePct = 0;

    // The natureRanger address (that receives Nature fees)
    address public natureRanger;
    // fees on Nature withdrawals, in percents (charged if `pool.natureLock` is `false`)
    uint8 public natureFeePct = 0;
    // Withdraw interval, in blocks, takes effect if pool.natureLock is `true`
    uint32 public withdrawInterval;

    // Nature token amount distributed every block of LP token farming
    uint96 public naturePerLptFarmingBlock;
    // Nature token amount distributed every block of S token farming
    uint96 public naturePerStFarmingBlock;
    // The sum of allocation points in all pools
    uint32 public totalAllocPoint;

    // The block when yield and trade farming starts
    uint32 public startBlock;
    // Block when LP token farming ends
    uint32 public lptFarmingEndBlock;
    // Block when S token farming ends
    uint32 public stFarmingEndBlock;

    uint256 public nftId;

    // Info of each pool
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // EIP712 domain
    bytes32 public DOMAIN_SEPARATOR;
    // Mapping from a user address to the nonce for signing/validating signatures
    mapping (address => uint256) public nonces;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 lptAmount,
        uint256 stAmount
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 lptAmount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 lptAmount
    );

    //function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data)  external virtual override returns(bytes4);

    //function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external virtual override returns(bytes4);

    constructor(
        address _erc1155,
        address _natureSpecialist,
        address _natureRanger,
        uint256 _startBlock,
        uint256 _withdrawInterval,
        uint256 _nftId
    ) public {
        
        erc1155 = _nonZeroAddr(_erc1155);
        natureSpecialist = _nonZeroAddr(_natureSpecialist);
        natureRanger = _nonZeroAddr(_natureRanger);
        startBlock = SafeMath32.fromUint(_startBlock);
        withdrawInterval = SafeMath32.fromUint(_withdrawInterval);
        nftId = _nftId;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                Signing.getChainId(),
                address(this)
            )
        );
    }

    function setFarmingParams(
        uint256 _naturePerLptFarmingBlock,
        uint256 _naturePerStFarmingBlock,
        uint256 _lptFarmingEndBlock,
        uint256 _stFarmingEndBlock
    ) external onlyOwner {
        uint32 _startBlock = startBlock;
        require(_lptFarmingEndBlock >= _startBlock, "ZooKeeper:INVALID_lptFarmEndBlock");
        require(_stFarmingEndBlock >= _startBlock, "ZooKeeper:INVALID_stFarmEndBlock");
        _setFarmingParams(
            SafeMath96.fromUint(_naturePerLptFarmingBlock),
            SafeMath96.fromUint(_naturePerStFarmingBlock),
            SafeMath32.fromUint(_lptFarmingEndBlock),
            SafeMath32.fromUint(_stFarmingEndBlock)
        );
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new LP pool. Owner only may call.
    function add(
        uint256 allocPoint,
        uint256 sTokenWeight,
        IBEP20 lpToken,
        IBEP20 sToken,
        bool withUpdate
    ) public onlyOwner {
        require(_isMissingPool(lpToken, sToken), "ZooKeeper::add:POOL_EXISTS");
        uint32 _allocPoint = SafeMath32.fromUint(allocPoint);

        if (withUpdate) massUpdatePools();

        uint32 _curBlock = curBlock();
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: lpToken,
                sToken: sToken,
                allocPoint: SafeMath32.fromUint(_allocPoint),
                sTokenWeight: SafeMath32.fromUint(sTokenWeight),
                lastRewardBlock: _curBlock > startBlock ? _curBlock : startBlock,
                accNaturePerShare: 0,
                natureLock: true
            })
        );
    }

    // Update the given pool"s Nature allocation point. Owner only may call.
    function setAllocation(
        uint256 pid,
        uint256 allocPoint,
        bool withUpdate
    ) public onlyOwner {
        _validatePid(pid);
        if (withUpdate) massUpdatePools();

        uint32 _allocPoint = SafeMath32.fromUint(allocPoint);

        totalAllocPoint = totalAllocPoint.sub(poolInfo[pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[pid].allocPoint = _allocPoint;
    }

    function setSTokenWeight(
        uint256 pid,
        uint256 sTokenWeight,
        bool withUpdate
    ) public onlyOwner {
        _validatePid(pid);
        if (withUpdate) massUpdatePools();

        poolInfo[pid].sTokenWeight = SafeMath32.fromUint(sTokenWeight);
    }

    function setNatureLock(
        uint256 pid,
        bool _natureLock,
        bool withUpdate
    ) public onlyOwner {
        _validatePid(pid);
        if (withUpdate) massUpdatePools();

        poolInfo[pid].natureLock = _natureLock;
    }

    // Return reward multipliers for LP and S tokens over the given _from to _to block.
    function getMultiplier(uint256 from, uint256 to)
        public
        view
        returns (uint256 lpt, uint256 st)
    {
        (uint32 _lpt, uint32 _st) = _getMultiplier(
            SafeMath32.fromUint(from),
            SafeMath32.fromUint(to)
        );
        lpt = uint256(_lpt);
        st = uint256(_st);
    }

    function getNaturePerBlock(uint256 blockNum) public view returns (uint256) {
        return
            (blockNum > stFarmingEndBlock ? 0 : naturePerStFarmingBlock).add(
                blockNum > lptFarmingEndBlock ? 0 : naturePerLptFarmingBlock
            );
    }

    // View function to see pending Natures on frontend.
    function pendingNature(uint256 pid, address _user)
        external
        view
        returns (uint256)
    {
        _validatePid(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];

        uint256 naturePerShare = pool.accNaturePerShare;

        uint32 _curBlock = curBlock();
        uint256 lptSupply = pool.lpToken.balanceOf(address(this));

        if (_curBlock > pool.lastRewardBlock && lptSupply != 0) {
            (uint32 lptFactor, uint32 stFactor) = _getMultiplier(
                pool.lastRewardBlock,
                _curBlock
            );
            uint96 natureReward = _natureReward(
                lptFactor,
                stFactor,
                pool.allocPoint
            );
            if (natureReward != 0) {
                uint256 stSupply = pool.sToken.balanceOf(address(this));
                uint256 wSupply = _weighted(
                    lptSupply,
                    stSupply,
                    pool.sTokenWeight
                );
                naturePerShare = _accShare(naturePerShare, natureReward, wSupply);
            }
        }

        return
            _accPending(
                user.pendingNature,
                user.wAmount,
                user.rewardDebt,
                naturePerShare
            );
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    // Update reward variables of the given pool
    function updatePool(uint256 pid) public {
        _validatePid(pid);
        _updatePool(pid);
    }

    // Deposit lptAmount of LP token and stAmount of S token to mine Nature,
    // (it sends to msg.sender Natures pending by then)
    function deposit(
        uint256 pid,
        uint256 lptAmount,
        uint256 stAmount
    ) public nonReentrant {
        _deposit(msg.sender, pid, lptAmount, stAmount);
    }

    // Deposit on behalf of the `user` (user" signature required)
    // (it sends to the `user` Natures pending by then)
    function depositBySig(
        address user,
        uint256 pid,
        uint256 lptAmount,
        uint256 stAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant {
        Signing.checkExpiry(deadline, block.timestamp);
        uint256 nonce = nonces[user]++;
        bytes32 digest;
        {
            bytes memory message = abi.encode(DEPOSIT_TYPEHASH, user, pid, lptAmount, stAmount, nonce, deadline);
            digest = Signing.eip712Hash(DOMAIN_SEPARATOR, message);
        }
        Signing.verifySignature(user, digest, v, r, s);

        _deposit(user, pid, lptAmount, stAmount);
    }

    function _deposit(
        address _user,
        uint256 pid,
        uint256 lptAmount,
        uint256 stAmount
    ) internal {
        require(lptAmount != 0, "deposit: zero LP token amount");
        _validatePid(pid);

        _updatePool(pid);

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];

        uint256 oldStAmount = user.stAmount;
        uint96 pendingNatureAmount = _accPending(
            user.pendingNature,
            user.wAmount,
            user.rewardDebt,
            pool.accNaturePerShare
        );
        user.lptAmount = user.lptAmount.add(lptAmount);
        user.stAmount = user.stAmount.add(stAmount);
        user.wAmount = _accWeighted(
            user.wAmount,
            lptAmount,
            stAmount,
            pool.sTokenWeight
        );

        uint32 _curBlock = curBlock();
        if (
            _sendNatureToken(
                _user,
                pendingNatureAmount,
                pool.natureLock,
                _curBlock.sub(user.lastWithdrawBlock)
            )
        ) {
            user.lastWithdrawBlock = _curBlock;
            user.pendingNature = 0;
            pool.sToken.safeTransfer(address(1), oldStAmount);
        } else {
            user.pendingNature = pendingNatureAmount;
        }
        user.rewardDebt = _pending(user.wAmount, 0, pool.accNaturePerShare);

        pool.lpToken.safeTransferFrom(_user, address(this), lptAmount);
        if (stAmount != 0)
            pool.sToken.safeTransferFrom(_user, address(this), stAmount);

        emit Deposit(_user, pid, lptAmount, stAmount);
    }

    // Withdraw lptAmount of LP token and all pending Nature tokens
    // (it burns all S tokens of the msg.sender)
    function withdraw(uint256 pid, uint256 lptAmount) public nonReentrant {
        _withdraw(msg.sender, pid, lptAmount);
    }

    // Withdraw on behalf of the `user` (user" signature required)
    // (it burns all S tokens of the user)
    function withdrawBySig(
        address user,
        uint256 pid,
        uint256 lptAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant {
        Signing.checkExpiry(deadline, block.timestamp);
        uint256 nonce = nonces[user]++;
        bytes32 digest;
        {
            bytes memory message = abi.encode(WITHDRAW_TYPEHASH, user, pid, lptAmount, nonce, deadline);
            digest = Signing.eip712Hash(DOMAIN_SEPARATOR, message);
        }
        Signing.verifySignature(user, digest, v, r, s);

        _withdraw(user, pid, lptAmount);
    }

    function _withdraw(address _user, uint256 pid, uint256 lptAmount) internal {
        _validatePid(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];

        uint256 preLptAmount = user.lptAmount;
        require(preLptAmount >= lptAmount, "withdraw: LP amount not enough");

        user.lptAmount = preLptAmount.sub(lptAmount);
        uint256 stAmount = user.stAmount;

        _updatePool(pid);
        uint96 pendingNatureAmount = _accPending(
            user.pendingNature,
            user.wAmount,
            user.rewardDebt,
            pool.accNaturePerShare
        );
        user.wAmount = user.lptAmount;
        user.rewardDebt = _pending(user.wAmount, 0, pool.accNaturePerShare);
        user.stAmount = 0;
        uint32 _curBlock = curBlock();

        if (
            _sendNatureToken(
                _user,
                pendingNatureAmount,
                pool.natureLock,
                _curBlock.sub(user.lastWithdrawBlock)
            )
        ) {
            user.lastWithdrawBlock = _curBlock;
            user.pendingNature = 0;
        } else {
            user.pendingNature = pendingNatureAmount;
        }

        uint256 sentLptAmount = lptAmount == 0
            ? 0
            : _sendLptAndBurnSt(_user, pool, lptAmount, stAmount);
        emit Withdraw(_user, pid, sentLptAmount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    // (it clears all pending Natures and burns all S tokens)
    function emergencyWithdraw(uint256 pid) public {
        _validatePid(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 lptAmount = user.lptAmount;
        user.lptAmount = 0; // serves as "non-reentrant"
        require(lptAmount > 0, "withdraw: zero LP token amount");

        uint32 _curBlock = curBlock();
        uint256 stAmount = user.stAmount;
        user.wAmount = 0;
        user.stAmount = 0;
        user.rewardDebt = 0;
        user.pendingNature = 0;
        user.lastWithdrawBlock = _curBlock;

        uint256 sentLptAmount = _sendLptAndBurnSt(
            msg.sender,
            pool,
            lptAmount,
            stAmount
        );
        emit EmergencyWithdraw(msg.sender, pid, sentLptAmount);
    }

    function setNatureServant(address _natureSpecialist) public onlyOwner {
        natureSpecialist = _nonZeroAddr(_natureSpecialist);
    }

    function setCourtJester(address _natureRanger) public onlyOwner {
        natureRanger = _nonZeroAddr(_natureRanger);
    }

    function setNatureFeePct(uint256 newPercent) public onlyOwner {
        natureFeePct = _validPercent(newPercent);
    }

    function setLpFeePct(uint256 newPercent) public onlyOwner {
        lpFeePct = _validPercent(newPercent);
    }

    function setWithdrawInterval(uint256 _blocks) public onlyOwner {
        withdrawInterval = SafeMath32.fromUint(_blocks);
    }

    function _updatePool(uint256 pid) internal {
        PoolInfo storage pool = poolInfo[pid];
        uint32 lastUpdateBlock = pool.lastRewardBlock;

        uint32 _curBlock = curBlock();
        if (_curBlock <= lastUpdateBlock) return;
        pool.lastRewardBlock = _curBlock;

        (uint32 lptFactor, uint32 stFactor) = _getMultiplier(
            lastUpdateBlock,
            _curBlock
        );
        if (lptFactor == 0 && stFactor == 0) return;

        uint256 lptSupply = pool.lpToken.balanceOf(address(this));
        if (lptSupply == 0) return;

        uint256 stSupply = pool.sToken.balanceOf(address(this));
        uint256 wSupply = _weighted(lptSupply, stSupply, pool.sTokenWeight);

        uint96 natureReward = _natureReward(lptFactor, stFactor, pool.allocPoint);
        pool.accNaturePerShare = _accShare(
            pool.accNaturePerShare,
            natureReward,
            wSupply
        );
    }

    function _sendNatureToken(
        address user,
        uint96 amount,
        bool natureLock,
        uint32 blocksSinceLastWithdraw
    ) internal returns (bool isSent) {
        isSent = true;
        if (amount == 0) return isSent;

        uint256 feeAmount = 0;
        uint256 userAmount = 0;

        if (!natureLock) {
            userAmount = amount;
            if (natureFeePct != 0) {
                feeAmount = uint256(amount).mul(natureFeePct).div(100);
                userAmount = userAmount.sub(feeAmount);

                IERC1155(erc1155).safeTransferFrom(address(this),natureRanger,nftId, feeAmount, "");
            }
        } else if (blocksSinceLastWithdraw > withdrawInterval) {
            userAmount = amount;
        } else {
            return isSent = false;
        }

        uint256 balance = IERC1155(erc1155).balanceOf(address(this),nftId);
        IERC1155(erc1155).safeTransferFrom(address(this),
            user,
            nftId,
            // if balance lacks some tiny Nature amount due to imprecise rounding
            userAmount > balance ? balance : userAmount,""
        );
    }

    function _sendLptAndBurnSt(
        address user,
        PoolInfo storage pool,
        uint256 lptAmount,
        uint256 stAmount
    ) internal returns (uint256) {
        uint256 userLptAmount = lptAmount;

        if (curBlock() < stFarmingEndBlock && lpFeePct != 0) {
            uint256 lptFee = lptAmount.mul(lpFeePct).div(100);
            userLptAmount = userLptAmount.sub(lptFee);

            pool.lpToken.safeTransfer(natureSpecialist, lptFee);
        }

        if (userLptAmount != 0) pool.lpToken.safeTransfer(user, userLptAmount);
        if (stAmount != 0) pool.sToken.safeTransfer(address(1), stAmount);

        return userLptAmount;
    }

    function _safeNatureTransfer(address _to, uint256 _amount) internal {
        uint256 natureBal = IERC1155(erc1155).balanceOf(address(this),nftId);
        // if pool lacks some tiny Nature amount due to imprecise rounding
        IERC1155(erc1155).safeTransferFrom(address(this),_to,nftId, _amount > natureBal ? natureBal : _amount,"");
    }

    

    function _setFarmingParams(
        uint96 _naturePerLptFarmingBlock,
        uint96 _naturePerStFarmingBlock,
        uint32 _lptFarmingEndBlock,
        uint32 _stFarmingEndBlock
    ) internal {
        require(
            _lptFarmingEndBlock >= lptFarmingEndBlock,
            "ZooKeeper::lptFarmingEndBlock"
        );
        require(
            _stFarmingEndBlock >= stFarmingEndBlock,
            "ZooKeeper::stFarmingEndBlock"
        );

        if (lptFarmingEndBlock != _lptFarmingEndBlock)
            lptFarmingEndBlock = _lptFarmingEndBlock;
        if (stFarmingEndBlock != _stFarmingEndBlock)
            stFarmingEndBlock = _stFarmingEndBlock;

        (uint32 lptFactor, uint32 stFactor) = _getMultiplier(
            curBlock(),
            2**32 - 1
        );
        uint256 minBalance = (
            uint256(_naturePerLptFarmingBlock).mul(uint256(stFactor))
        )
            .add(uint256(_naturePerStFarmingBlock).mul(uint256(lptFactor)));
        require(
            IERC1155(erc1155).balanceOf(address(this),nftId) >= minBalance,
            "ZooKeeper::LOW_Nature_BALANCE"
        );

        naturePerLptFarmingBlock = _naturePerLptFarmingBlock;
        naturePerStFarmingBlock = _naturePerStFarmingBlock;
    }

    // Revert if the LP token has been already added.
    function _isMissingPool(IBEP20 lpToken, IBEP20 sToken)
        internal
        view
        returns (bool)
    {
        _revertZeroAddress(address(lpToken));
        _revertZeroAddress(address(lpToken));
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (
                poolInfo[i].lpToken == lpToken || poolInfo[i].sToken == sToken
            ) {
                return false;
            }
        }
        return true;
    }

    function _getMultiplier(uint32 _from, uint32 _to)
        internal
        view
        returns (uint32 lpt, uint32 st)
    {
        uint32 start = _from > startBlock ? _from : startBlock;

        // LP token farming multiplier
        uint32 end = _to > lptFarmingEndBlock ? lptFarmingEndBlock : _to;
        lpt = _from < lptFarmingEndBlock ? end.sub(start) : 0;

        // S token farming multiplier
        end = _to > stFarmingEndBlock ? stFarmingEndBlock : _to;
        st = _from < stFarmingEndBlock ? end.sub(start) : 0;
    }

    function _accPending(
        uint96 prevPending,
        uint256 amount,
        uint96 rewardDebt,
        uint256 accPerShare
    ) internal pure returns (uint96) {
        return
            amount == 0
                ? prevPending
                : prevPending.add(_pending(amount, rewardDebt, accPerShare));
    }

    function _pending(
        uint256 amount,
        uint96 rewardDebt,
        uint256 accPerShare
    ) internal pure returns (uint96) {
        return
            amount == 0
                ? 0
                : SafeMath96.fromUint(
                    amount.mul(accPerShare).div(1e12).sub(uint256(rewardDebt)),
                    "ZooKeeper::pending:overflow"
                );
    }

    function _natureReward(
        uint32 lptFactor,
        uint32 stFactor,
        uint32 allocPoint
    ) internal view returns (uint96) {
        uint32 _totalAllocPoint = totalAllocPoint;
        uint96 lptReward = _reward(
            lptFactor,
            naturePerLptFarmingBlock,
            allocPoint,
            _totalAllocPoint
        );
        if (stFactor == 0) return lptReward;

        uint96 stReward = _reward(
            stFactor,
            naturePerStFarmingBlock,
            allocPoint,
            _totalAllocPoint
        );
        return lptReward.add(stReward);
    }

    function _reward(
        uint32 factor,
        uint96 rewardPerBlock,
        uint32 allocPoint,
        uint32 _totalAllocPoint
    ) internal pure returns (uint96) {
        return
            SafeMath96.fromUint(
                uint256(factor)
                    .mul(uint256(rewardPerBlock))
                    .mul(uint256(allocPoint))
                    .div(uint256(_totalAllocPoint))
            );
    }

    

    function _accShare(
        uint256 prevShare,
        uint96 reward,
        uint256 supply
    ) internal pure returns (uint256) {
        return prevShare.add(uint256(reward).mul(1e12).div(supply));
    }

    function _accWeighted(
        uint256 prevAmount,
        uint256 lptAmount,
        uint256 stAmount,
        uint32 sTokenWeight
    ) internal pure returns (uint256) {
        return prevAmount.add(_weighted(lptAmount, stAmount, sTokenWeight));
    }

    function _weighted(
        uint256 lptAmount,
        uint256 stAmount,
        uint32 sTokenWeight
    ) internal pure returns (uint256) {
        if (stAmount == 0 || sTokenWeight == 0) {
            return lptAmount;
        }
        return lptAmount.add(stAmount.mul(sTokenWeight).div(1e8));
    }

    function _nonZeroAddr(address _address) private pure returns (address) {
        _revertZeroAddress(_address);
        return _address;
    }

    function curBlock() private view returns (uint32) {
        return SafeMath32.fromUint(block.number);
    }

    function _validPercent(uint256 percent) private pure returns (uint8) {
        require(percent <= 100, "ZooKeeper::INVALID_PERCENT");
        return uint8(percent);
    }

    function _revertZeroAddress(address _address) internal pure {
        require(_address != address(0), "ZooKeeper::ZERO_ADDRESS");
    }

    function _validatePid(uint256 pid) private view returns (uint256) {
        require(pid < poolInfo.length, "ZooKeeper::INVALID_POOL_ID");
        return pid;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata 
    ) external override virtual returns (bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata 
    ) external override virtual returns (bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    
}

