/**
 *Submitted for verification at polygonscan.com on 2021-10-29
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/tunnel/FxBaseChildTunnel.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]



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
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}


// File @chainlink/contracts/src/v0.8/[email protected]
contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}


// File @chainlink/contracts/src/v0.8/[email protected]
/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}


// File @openzeppelin/contracts/utils/[email protected]


/**
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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/interfaces/IEgg.sol
struct EggInfo {
    uint256 Maturity;
    uint256 Bonus; //set at minting, based on parents rarity, and on if parents were from original 8181 number between 0 -> 10000
    uint256 EventID;
    bool Hatched; //maybe just burn them when they are hatched? So this in not needed?
}

struct Trait {
    string traitName;
    uint256 rarity;
}

interface IEgg {
    function setCrowMetaData(uint256 _tokenID, uint32[8] memory _metaData)
        external;

    function setCrowRNG(uint256 _tokenID, uint256 _rng) external;

    function setCrowParents(uint256 _tokenID, uint256[2] memory _parents)
        external;

    function setEggBonus(uint256 _tokenID, uint256 _bonus) external;

    function traitInfo(uint8 _traitID, uint32 _traitIndex)
        external
        view
        returns (Trait memory);

    function getCrowMetaData(uint256 _tokenID)
        external
        view
        returns (uint32[8] memory);

    function crowRNG(uint256 _tokenID) external view returns (uint256);

    function eventTraitStartingIndex(uint256 _eventID, uint8 _traitID)
        external
        view
        returns (uint32);

    function getParents(uint256 _tokenID)
        external
        view
        returns (uint256[2] memory);

    function eggInfo(uint256 _eggID) external view returns (EggInfo memory);

    function eventTraitSum() external view returns (uint256);

    function getRarity(uint8 traitID, uint32 traitIndex)
        external
        view
        returns (uint256);

    function getName(uint8 traitID, uint32 traitIndex)
        external
        view
        returns (string memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function burnEgg(uint256 _eggID) external;

    function mintEgg(uint256 _eggID) external;

    function ownerOf(uint256 _eggID) external returns (address);

    function hatch(uint256 _eggID) external;
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}


// File contracts/EggCarton.sol










/**
 * @title Adds Breeding functionality to Crazy Crows Chess Club
 * @author crispymangoes
 * @notice Interacts with breeder contract on mainnet using Polygon State Transfer
 * @notice all crow meta data stored on polygon
 * @dev uses Chainlink VRF to randomly assign crow traits
 * @dev Chainlink Keepers compatible
 */
contract EggCarton is
    FxBaseChildTunnel,
    VRFConsumerBase,
    Ownable,
    ERC721Holder,
    KeeperCompatibleInterface
{
    struct Message {
        bool done;
        bool rngSet;
    }

    //constants for Root message decoding
    bytes32 public constant MAKE_EGG = keccak256("MAKE_EGG");
    bytes32 public constant FIND_TRAITS = keccak256("FIND_TRAITS");

    //values for chainlink vrf
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(bytes32 => uint256) public requestIDtoTokenID;

    //multipliers used to assign different egg bonuses
    uint256 public constant maxMaturity = 1000000; //max maturity an egg can get
    uint256 public constant minMaturity = 500000; //min required maturity to hatch an egg
    uint256 public maturityMultiplier = 20000; //if an egg is max maturity then this is the times bonus they get for rare traits
    uint256 public bonusMultipler = 20000; //changes how fast an egg matures
    uint256 public baseMultiplier = 10000; //used as the base for multipliers
    uint256 public gen0Bonus = 500; //5% bonus based of a 10k max bonus
    uint256 public bonusDifficulty = 8; //makes it more difficult to be assigned a high bonus

    //variables handling egg interaction, and logic
    IEgg Egg;
    mapping(uint256 => bool) public eggOrigin; //used to track which egg carton an egg came from, in the event the egg carton is upgraded
    mapping(uint256 => Message) public messages;
    mapping(uint256 => address) public eggsToDispense;
    //FIFO for egg breeding
    uint256 public headEgg;
    uint256 public tailEgg;
    mapping(uint256 => uint256) public eggFIFO;
    //FIFO for mad house breeding
    uint256 public headMH;
    uint256 public tailMH;
    mapping(uint256 => uint256) public MHFIFO;

    constructor(address _fxChild, address egg)
        FxBaseChildTunnel(_fxChild)
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0,
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1
        )
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 100000000000000; // 0.0001 LINK
        Egg = IEgg(egg);
    }

    /****************** External onlyOwner Functions ******************/
    /**
     * @notice used to adjust egg bonus multipliers
     * @dev all multipliers should be based off _baseMultiplier
     * @dev _gen0Bonus is based off _baseMultiplier
     * @dev _bonusDifficulty can be lowered as more generic crows are minted
     */
    function setParameters(
        uint256 _maturityMultiplier,
        uint256 _bonusMultiplier,
        uint256 _baseMultiplier,
        uint256 _gen0Bonus,
        uint256 _bonusDifficulty
    ) external onlyOwner {
        require(
            _maturityMultiplier / _baseMultiplier > 0,
            "Incorrect Parameters"
        );
        require(_bonusMultiplier / _baseMultiplier > 0, "Incorrect Parameters");
        maturityMultiplier = _maturityMultiplier;
        bonusMultipler = _bonusMultiplier;
        baseMultiplier = _baseMultiplier;
        gen0Bonus = _gen0Bonus;
        bonusDifficulty = _bonusDifficulty;
    }

    /**
     * @notice This contract will not be holding ANY user funds
     * this function is only here to move LINK out of the contract(if switching to new egg carton)
     * or if a user accidentally sends tokens directly to this contract, so that they can be returned
     */
    function adminWithdraw(address _token, uint256 _amount) external onlyOwner {
        uint256 amount = _amount;
        if (amount == 0) {
            amount = IERC20(_token).balanceOf(address(this));
        }
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, amount);
    }

    /****************** External State Changing Functions ******************/
    /**
     * @notice once an egg is of minimum maturity it can be hatched
     * @notice onced hatched, a random number is assigned to it
     * @notice once a random number is assigned, sendHatchedEggToMainnet can be called
     * @dev random number comes from Chainlink VRF
     * @dev caller needs to own egg
     * @param eggID the token id of the egg caller owns and want to hatch
     */
    function hatchEgg(uint256 eggID) external {
        require(eggOrigin[eggID], "Egg must originate from this Egg Carton");
        //first make sure caller owns egg
        require(Egg.ownerOf(eggID) == msg.sender, "Caller does not own egg");

        //make sure egg rarity multiplier is greater than 1
        require(
            Egg.eggInfo(eggID).Maturity >= minMaturity,
            "Egg is not mature enough"
        );

        //call Chainlink VRF
        requestIDtoTokenID[_getRandomNumber()] = eggID;

        Egg.hatch(eggID); //checks to see if egg is already hatched
    }

    /**
     * @notice randomly assigns traits, burns egg, and sends message to Breeder
     * @dev egg must be hatched, caller must own egg, and egg must have come from this breeder
     * @param eggID the token id of the egg caller wants to convert into a mainnet crow
     */
    function sendHatchedEggToMainnet(uint256 eggID) external {
        require(eggOrigin[eggID], "Egg must originate from this Egg Carton");
        //make sure caller owns the egg
        require(Egg.ownerOf(eggID) == msg.sender, "Caller does not own egg");
        //make sure egg was hatched
        require(
            Egg.eggInfo(eggID).Hatched,
            "Egg is not hatched yet, call hatchEgg"
        );
        //make sure chainlink has set the random number for this egg
        require(messages[eggID].rngSet, "Random number is not set yet");

        uint32[8] memory newCrow = calculateEggBreedingTraits(
            eggID,
            Egg.crowRNG(eggID)
        );
        Egg.setCrowMetaData(eggID, newCrow);
        //Send egg to the EggCarton
        Egg.safeTransferFrom(msg.sender, address(this), eggID);
        //burn the egg
        Egg.burnEgg(eggID);

        //send message to root
        _sendMessageToRoot(abi.encode(msg.sender, eggID));
    }

    /**
     * @notice can be called by anyone
     * @dev maintenance function for egg carton
     * @dev Chainlink Keepers compatible
     * @param performData not used can be 0x
     */
    function performUpkeep(bytes calldata performData) external override {
        if (messages[headMH].rngSet) {//if headMH is zero, then messages[headMH].rngSet will NEVER be true
            findTraits();
        }
        if (headEgg != 0) {
            sendEggToCaller();
        }
    }

    /****************** External State Reading Functions ******************/
    /**
     * @notice indicates whether performUpkeep function should be called
     * @dev Chainlink Keepers compatible
     * @param checkData not used can be 0x
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (messages[headMH].rngSet || headEgg != 0);//if headMH is zero, then messages[headMH].rngSet will NEVER be true
    }

    /****************** Public State Changing Functions ******************/
    /**
     * @notice callable by anyone
     * @notice if there is a token id in the MH FIFO buffer, then it's traits will be set
     * @dev reverts if nothing is in the MH FIFO buffer
     * return 0 or 1, 0 means their is no need to call this again, 1 means call again ASAP
     */
    function findTraits() public returns (uint256) {
        uint256 tokenID = headMH;
        require(tokenID != 0, "Nothing to do");
        require(messages[tokenID].rngSet, "RNG not set");
        require(
            !messages[tokenID].done,
            "Traits already calculated for tokenID"
        );
        uint256[2] memory parents = Egg.getParents(tokenID);
        require(parents[0] > 0 || parents[1] > 0, "Parents are not set");

        uint32[8] memory metaData = findRarest(parents[0], parents[1]);
        Egg.setCrowMetaData(tokenID, metaData);

        uint32[8] memory newCrow = calculateMadHouseTraits(
            tokenID,
            Egg.crowRNG(tokenID)
        );
        Egg.setCrowMetaData(tokenID, newCrow);
        messages[tokenID].done = true;
        headMH = MHFIFO[headMH];
        if (headMH == 0) {
            //nothing else to do
            return 0;
        } else {
            //have more traits to calculate
            return 1;
        }
    }

    /**
     * @notice callable by anyone
     * @notice if there is a token id in the Egg FIFO buffer, then it's bonus will be set, and the egg will be sent to reciever
     * @dev reverts if nothing is in the Egg FIFO buffer
     * return 0 or 1, 0 means their is no need to call this again, 1 means call again ASAP
     */
    function sendEggToCaller() public returns (uint256) {
        uint256 baby = headEgg;
        require(baby != 0, "Nothing to do");
        require(eggsToDispense[baby] != address(0), "Forbidden");
        uint256[2] memory parents = Egg.getParents(baby);
        uint256 bonus = findEggBonus(parents[0], parents[1]);
        Egg.setEggBonus(baby, bonus);

        Egg.safeTransferFrom(address(this), eggsToDispense[baby], baby);
        eggsToDispense[baby] = address(0);
        headEgg = eggFIFO[headEgg];
        if (headEgg == 0) {
            //nothing else to do so wait the task specified amount of time
            return 0;
        } else {
            //have more traits to calculate so tell it to wait 1 second before making this callable again
            return 1;
        }
    }

    /****************** Public State Reading Functions ******************/
    /**
     * @notice determines egg bonus using parents rarities, and gen0 status
     * return 0 -> baseMultiplier
     */
    function findEggBonus(uint256 _mom, uint256 _dad)
        public
        view
        returns (uint256 bonus)
    {
        uint256 momSum = 0;
        uint256 dadSum = 0;
        uint32[8] memory mom = Egg.getCrowMetaData(_mom);
        uint32[8] memory dad = Egg.getCrowMetaData(_dad);
        bonus = 0;
        for (uint8 i = 0; i < 8; i++) {
            momSum += Egg.getRarity(i, mom[i]);
            dadSum += Egg.getRarity(i, dad[i]);
        }
        uint256 avgRarity = (momSum + dadSum) / 16;
        if (avgRarity <= (Egg.eventTraitSum() / bonusDifficulty)) {
            bonus =
                (baseMultiplier *
                    ((Egg.eventTraitSum() / bonusDifficulty) - avgRarity)) /
                (Egg.eventTraitSum() / bonusDifficulty);
        } else {
            bonus = 0;
        }

        //Apply gen 0 bonuses
        if (_mom < 8181) {
            bonus += gen0Bonus;
        }
        if (_dad < 8181) {
            bonus += gen0Bonus;
        }
        //cap it at baseMultiplier
        if (bonus > baseMultiplier) {
            bonus = baseMultiplier;
        }
    }

    /**
     * @notice randomly determines 6 remaining traits
     * return array of 8 traits
     */
    function calculateMadHouseTraits(uint256 tokenID, uint256 randomNumber)
        public
        view
        returns (uint32[8] memory newCrow)
    {
        //uses the eggs rarity multiplier, and random seed to calculate the traits
        //if crowMetaData[tokenID][0-7] != 0 then don't touch it because the trait is already set
        uint256[] memory expandedRandomness = expand(randomNumber, 8);
        uint256 sum;
        //Set the initial traits
        newCrow = Egg.getCrowMetaData(tokenID);
        for (uint8 i = 0; i < 8; i++) {
            if (newCrow[i] == 0) {
                //means this trait is not set
                sum = 0;
                uint256 rng = expandedRandomness[i] % Egg.eventTraitSum();
                for (
                    uint32 j = Egg.eventTraitStartingIndex(0, i);
                    j < Egg.eventTraitStartingIndex(1, i);
                    j++
                ) {
                    sum += uint256(Egg.getRarity(i, j));
                    if (rng <= sum) {
                        newCrow[i] = j;
                        break;
                    }
                }
            }
        }
    }

    /**
     * @notice randomly determines 8 traits
     * return array of 8 traits
     */
    function calculateEggBreedingTraits(uint256 tokenID, uint256 randomNumber)
        public
        view
        returns (uint32[8] memory newCrow)
    {
        //uses the eggs rarity multiplier, and random seed to calculate the traits

        uint256 maturity = Egg.eggInfo(tokenID).Maturity;
        if (maturity > maxMaturity) {
            maturity = maxMaturity;
        }
        uint256 amountToDiminishBy;

        uint256[] memory expandedRandomness = expand(randomNumber, 16);
        uint256 sum;
        uint256 startingMaturity = maturity;
        //Set the initial traits
        newCrow = Egg.getCrowMetaData(tokenID);
        for (uint8 i = 0; i < 8; i++) {
            if (newCrow[i] == 0) {
                //means this trait is not set
                maturity = startingMaturity;
                amountToDiminishBy =
                    (maturity - minMaturity) /
                    (Egg.eventTraitStartingIndex(1, i) -
                        Egg.eventTraitStartingIndex(0, i));
                sum = 0;
                uint256 rng = expandedRandomness[i] % Egg.eventTraitSum();
                for (
                    uint32 j = Egg.eventTraitStartingIndex(0, i);
                    j < Egg.eventTraitStartingIndex(1, i);
                    j++
                ) {
                    sum +=
                        (maturityMultiplier *
                            maturity *
                            uint256(Egg.getRarity(i, j))) /
                        (maxMaturity * baseMultiplier);
                    maturity -= amountToDiminishBy;
                    if (rng <= sum) {
                        newCrow[i] = j;
                        break;
                    }
                }
            }
        }

        //check if egg was in a special event and if it was then re run trait setting script
        if (Egg.eggInfo(tokenID).EventID != 0) {
            uint256 eventID = Egg.eggInfo(tokenID).EventID;
            for (uint8 i = 0; i < 8; i++) {
                maturity = startingMaturity;
                amountToDiminishBy =
                    (maturity - minMaturity) /
                    (Egg.eventTraitStartingIndex(eventID + 1, i) -
                        Egg.eventTraitStartingIndex(eventID, i));
                sum = 0;
                uint256 rng = expandedRandomness[i + 8] % Egg.eventTraitSum();
                for (
                    uint32 j = Egg.eventTraitStartingIndex(eventID, i);
                    j < Egg.eventTraitStartingIndex(eventID + 1, i) - 1;
                    j++
                ) {
                    //don't check the last address bc if it is in that, then the traits should not change
                    sum +=
                        (maturityMultiplier *
                            maturity *
                            uint256(Egg.getRarity(i, j))) /
                        (maxMaturity * baseMultiplier);
                    maturity -= amountToDiminishBy;
                    if (rng <= sum) {
                        newCrow[i] = j;
                        break;
                    }
                }
            }
        }
    }

    /**
     * @notice useful to view human readable trait data
     * return array of 8 traits(strings)
     */
    function viewMetaData(uint256 tokenID)
        public
        view
        returns (string[8] memory data)
    {
        uint32[8] memory crow = Egg.getCrowMetaData(tokenID);
        for (uint8 i = 0; i < 8; i++) {
            data[i] = Egg.getName(i, crow[i]);
        }
    }

    /**
     * @notice useful to view human readable rarest traits selected
     * return array of 8 strings, two populated strings are the two rarest traits
     */
    function viewRarest(uint256 mom, uint256 dad)
        public
        view
        returns (string[8] memory data)
    {
        uint32[8] memory crow = findRarest(mom, dad);
        for (uint8 i = 0; i < 8; i++) {
            data[i] = Egg.getName(i, crow[i]);
        }
    }

    /**
     * @notice useful to see what two traits would be passed on to the child
     * return array of 8 numbers. Two will be non zero, which represent the two traits passed on
     */
    function findRarest(uint256 _mom, uint256 _dad)
        public
        view
        returns (uint32[8] memory metaData)
    {
        //run algo to find parents rarest traits
        uint8 momRarest = 0;
        uint8 mom2ndRarest = 0;
        uint8 dadRarest = 0;
        uint8 dad2ndRarest = 0;

        uint32[8] memory mom = Egg.getCrowMetaData(_mom);
        uint32[8] memory dad = Egg.getCrowMetaData(_dad);

        //set the rarest and 2ndRarest for mom and dad
        if (Egg.getRarity(0, mom[0]) < Egg.getRarity(1, mom[1])) {
            momRarest = 0;
            mom2ndRarest = 1;
        } else {
            momRarest = 1;
            mom2ndRarest = 0;
        }
        if (Egg.getRarity(0, dad[0]) < Egg.getRarity(1, dad[1])) {
            dadRarest = 0;
            dad2ndRarest = 1;
        } else {
            dadRarest = 1;
            dad2ndRarest = 0;
        }

        for (uint8 i = 2; i < 8; i++) {
            //check to see if the current trait is rarer than the moms rarest trait
            if (
                Egg.getRarity(i, mom[i]) <
                Egg.getRarity(momRarest, mom[momRarest])
            ) {
                mom2ndRarest = momRarest; //set 2nd rarest equal to old rarest trait
                momRarest = i; //set new rarest trait
            } else {
                //check if the current traits is rarer than the second rarest and replace it if it is
                if (
                    Egg.getRarity(i, mom[i]) <
                    Egg.getRarity(mom2ndRarest, mom[mom2ndRarest])
                ) {
                    mom2ndRarest = i;
                }
            }
            //check to see if the current trait is rarer than the dads rarest trait
            if (
                Egg.getRarity(i, dad[i]) <
                Egg.getRarity(dadRarest, dad[dadRarest])
            ) {
                dad2ndRarest = dadRarest; //set 2nd rarest equal to old rarest trait
                dadRarest = i; //set new rarest trait
            } else {
                //check if the current traits is rarer than the second rarest and replace it if it is
                if (
                    Egg.getRarity(i, dad[i]) <
                    Egg.getRarity(dad2ndRarest, dad[dad2ndRarest])
                ) {
                    dad2ndRarest = i;
                }
            }
        }

        if (dadRarest == momRarest) {
            //if the Trait IDs are the same
            //then use whichever rarer one is rarer, and use the other ones backup
            if (
                Egg.getRarity(dadRarest, dad[dadRarest]) <
                Egg.getRarity(momRarest, mom[momRarest])
            ) {
                metaData[dadRarest] = dad[dadRarest]; //use the dads rarest
                if (dadRarest == mom2ndRarest) {
                    metaData[dad2ndRarest] = dad[dad2ndRarest]; //use dads second rarest
                } else {
                    metaData[mom2ndRarest] = mom[mom2ndRarest]; //use the moms seconds rarest
                }
            } else {
                metaData[momRarest] = mom[momRarest]; //use moms rarest
                if (momRarest == dad2ndRarest) {
                    metaData[mom2ndRarest] = mom[mom2ndRarest]; //use the moms seconds rarest
                } else {
                    metaData[dad2ndRarest] = dad[dad2ndRarest]; //use dads second rarest
                }
            }
        } else {
            //use rarest from both parents
            metaData[dadRarest] = dad[dadRarest]; //use the dads rarest
            metaData[momRarest] = mom[momRarest]; //use moms rarest
        }
    }

    /****************** Public Pure Functions ******************/
    /**
     * @dev used to take 1 random number and generate n more
     * @param randomValue the value to base other random numbers off of
     * @param n the number of random numbers you want to generate
     */
    function expand(uint256 randomValue, uint256 n)
        public
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    /****************** Internal State Changing Functions ******************/
    /**
     * @dev takes messages from Root, and calls appropriate internal function
     * @param sender address of the mainnet contract that sent the message, must be the Breeder
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            message,
            (bytes32, bytes)
        );

        if (syncType == MAKE_EGG) {
            _makeEgg(syncData);
        } else if (syncType == FIND_TRAITS) {
            _findTraits(syncData);
        } else {
            revert("FxERC721ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    /// @dev mints an egg, adds it to eggFIFO, and sets parents
    function _makeEgg(bytes memory message) internal {
        (address caller, uint256 baby, uint256 mom, uint256 dad) = abi.decode(
            message,
            (address, uint256, uint256, uint256)
        );

        Egg.mintEgg(baby);
        eggOrigin[baby] = true;
        eggsToDispense[baby] = caller;

        if (headEgg == 0) {
            headEgg = baby;
        }
        if (tailEgg != 0) {
            eggFIFO[tailEgg] = baby;
        }
        tailEgg = baby;

        uint256[2] memory parents;
        parents[0] = mom;
        parents[1] = dad;
        Egg.setCrowParents(baby, parents);
    }

    /// @dev sets parents, adds id to MHFIFO and requets a random number for that id
    function _findTraits(bytes memory message) internal {
        (uint256 tID, uint256 mom, uint256 dad) = abi.decode(
            message,
            (uint256, uint256, uint256)
        );
        uint256[2] memory parents;
        parents[0] = mom;
        parents[1] = dad;
        Egg.setCrowParents(tID, parents);

        if (headMH == 0) {
            headMH = tID;
        }
        if (tailMH != 0) {
            MHFIFO[tailMH] = tID;
        }
        tailMH = tID;

        requestIDtoTokenID[_getRandomNumber()] = tID;
    }

    /// @dev function to get a random number from Chainlink VRF
    function _getRandomNumber() internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * @dev fulfillment function called by VRF coordinator
     * @dev sets the ids random number, and its message.rngSet variable to true
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 tokenId = requestIDtoTokenID[requestId];
        Egg.setCrowRNG(tokenId, randomness); //save the random number for the crow
        messages[tokenId].rngSet = true;
    }
}