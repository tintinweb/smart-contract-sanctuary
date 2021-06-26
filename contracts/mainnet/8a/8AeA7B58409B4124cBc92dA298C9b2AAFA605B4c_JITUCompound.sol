// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Core of JITU (Just-In-Time-Underwriter)
 * @author KeeperDAO
 * @notice This contract allows whitelisted keepers to add buffer to compound positions that 
 * are slightly above water, so that in the case they go underwater the keepers can
 * preempt a liquidation.
 */
contract JITUCore is Ownable {
    /** State */
    IERC721 public immutable nft;
    LiquidityPoolLike public liquidityPool;
    mapping (address=>bool) keeperWhitelist;
    mapping (address=>bool) underwriterWhitelist;

    /** Events */
    event KeeperWhitelistUpdated(address indexed _keeper, bool _updatedValue);
    event UnderwriterWhitelistUpdated(address indexed _underwriter, bool _updatedValue);
    event LiquidityPoolUpdated(address indexed _oldValue, address indexed _newValue);

    /**
     * @notice initialize the contract state
     */
    constructor (LiquidityPoolLike _liquidityPool, IERC721 _nft) {
        liquidityPool = _liquidityPool;
        nft = _nft;
    }

    /** Modifiers */
    /**
     * @notice reverts if the caller is not a whitelisted keeper
     */
    modifier onlyWhitelistedKeeper() {
        require(
            keeperWhitelist[msg.sender], 
            "JITU: caller is not a whitelisted keeper"
        );
        _;
    }

    /**
     * @notice reverts if the caller is not a whitelisted underwriter
     */
    modifier onlyWhitelistedUnderwriter() {
        require(
            underwriterWhitelist[msg.sender], 
            "JITU: caller is not a whitelisted underwriter"
        );
        _;
    } 

    /**
     * @notice reverts if the caller is not the vault owner
     */
    modifier onlyVaultOwner(address _vault) {
        require(
            nft.ownerOf(uint256(uint160(_vault))) == msg.sender,
            "JITU: not the owner"
        );
        _;
    }

    /**
     * @notice reverts if the wallet is invalid
     */
    modifier valid(address _vault) {
        require(
            nft.ownerOf(uint256(uint160(_vault))) != address(0),
            "JITU: invalid vault address"
        );
        _;
    }

    /** External Functions */

    /**
     * @notice this contract can accept ethereum transfers
     */
    receive() external payable {}

    /**
     * @notice whitelist the given keeper, add to the keeper
     *         whitelist.
     * @param _keeper the address of the keeper
     */
    function updateKeeperWhitelist(address _keeper, bool _val) external onlyOwner {
        keeperWhitelist[_keeper] = _val;
        emit KeeperWhitelistUpdated(_keeper, _val);
    }

    /**
     * @notice update the liquidity provider.
     * @param _liquidityPool the address of the liquidityPool
     */
    function updateLiquidityPool(LiquidityPoolLike _liquidityPool) external onlyOwner {
        require(_liquidityPool != LiquidityPoolLike(address(0)), "JITU: liquidity pool cannot be 0x0");
        emit LiquidityPoolUpdated(address(liquidityPool), address(_liquidityPool));
        liquidityPool = _liquidityPool;
    }

    /**
     * @notice whitelist the given underwriter, add to the underwriter
     *         whitelist.
     * @param _underwriter the address of the underwriter
     */
    function updateUnderwriterWhitelist(address _underwriter, bool _val) external onlyOwner {
        underwriterWhitelist[_underwriter] = _val;
        emit UnderwriterWhitelistUpdated(_underwriter, _val);
    }
}

interface LiquidityPoolLike {
    function adapterBorrow(address _token, uint256 _amount, bytes calldata _data) external;
    function adapterRepay(address _adapter, address _token, uint256 _amount) external payable;
    function borrower() external view returns (address);
}

// SPDX-License-Identifier: BSD-3-Clause
//
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// This contract is copied from https://github.com/compound-finance/compound-protocol

pragma solidity 0.8.6;


contract CTokenStorage {
    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    address public comptroller;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;
}

abstract contract CToken is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);
    function approve(address spender, uint amount) external virtual returns (bool);
    function allowance(address owner, address spender) external virtual view returns (uint);
    function balanceOf(address owner) external virtual view returns (uint);
    function balanceOfUnderlying(address owner) external virtual returns (uint);
    function getAccountSnapshot(address account) external virtual view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external virtual view returns (uint);
    function supplyRatePerBlock() external virtual view returns (uint);
    function totalBorrowsCurrent() external virtual returns (uint);
    function borrowBalanceCurrent(address account) external virtual returns (uint);
    function borrowBalanceStored(address account) external virtual view returns (uint);
    function exchangeRateCurrent() external virtual returns (uint);
    function exchangeRateStored() external virtual view returns (uint);
    function getCash() external virtual view returns (uint);
    function accrueInterest() external virtual returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external virtual returns (uint);
}

abstract contract CErc20 is CToken {
    function underlying() external virtual view returns (address);
    function mint(uint mintAmount) external virtual returns (uint);
    function repayBorrow(uint repayAmount) external virtual returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CToken cTokenCollateral) external virtual returns (uint);
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
}

abstract contract CEther is CToken {
    function mint() external virtual payable;
    function repayBorrow() external virtual payable;
    function repayBorrowBehalf(address borrower) external virtual payable;
    function liquidateBorrow(address borrower, CToken cTokenCollateral) external virtual payable;
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
}

abstract contract PriceOracle {
    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CToken cToken) external virtual view returns (uint);
}

abstract contract Comptroller {
    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /// @notice A list of all markets
    CToken[] public allMarkets;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    struct Market {
        // Whether or not this market is listed
        bool isListed;

        
        // Multiplier representing the most one can borrow against their collateral in this market.
        // For instance, 0.9 to allow borrowing 90% of collateral value.
        // Must be between 0 and 1, and stored as a mantissa.
        uint collateralFactorMantissa;

        // Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;

        // Whether or not this market receives COMP
        bool isComped;
    }

    /**
     * @notice Official mapping of cTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external virtual returns (uint[] memory);
    function exitMarket(address cToken) external virtual returns (uint);
    function checkMembership(address account, CToken cToken) external virtual view returns (bool);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external virtual view returns (uint, uint);

    function getAssetsIn(address account) external virtual view returns (address[] memory);

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint redeemTokens,
        uint borrowAmount) external virtual view returns (uint, uint, uint);

    function _setPriceOracle(PriceOracle newOracle) external virtual returns (uint);
}

contract SimplePriceOracle is PriceOracle {
    mapping(address => uint) prices;
    uint256 ethPrice;
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    function getUnderlyingPrice(CToken cToken) public override view returns (uint) {
        if (compareStrings(cToken.symbol(), "cETH")) {
            return ethPrice;
        } else {
            return prices[address(CErc20(address(cToken)).underlying())];
        }
    }

    function setUnderlyingPrice(CToken cToken, uint underlyingPriceMantissa) public {
         if (compareStrings(cToken.symbol(), "cETH")) {
            ethPrice = underlyingPriceMantissa;
        } else {
            address asset = address(CErc20(address(cToken)).underlying());
            emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
            prices[asset] = underlyingPriceMantissa;
        }   
    }

    function setDirectPrice(address asset, uint price) public {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./IKCompound.sol";

/**
 * @title JITU Compound interface
 * @author KeeperDAO
 * @notice Interface for the Compound JITU plugin.
 */
interface IJITUCompound {
    /** Following functions can only be called by the owner */

    /** 
     * @notice borrow given amount of tokens from the liquidity pool.
     * @param _cToken the address of the cToken
     * @param _amount the amount of underlying tokens 
     */ 
    function borrow(CToken _cToken, uint256 _amount) external;

    /** 
     * @notice repay given amount back to the LiquidityPool
     *
     * @param _cToken the address of the cToken
     * @param _amount the amount of underlying tokens
     */
    function repay(CToken _cToken, uint256 _amount) external payable;

    /** Following functions can only be called by a whitelisted keeper */

    /** 
     * @notice underwrite the given vault, with the given amount of
     * compound tokens.
     *
     * @param _vault the address of the compound vault
     * @param _cToken the address of the cToken
     * @param _tokens the amount of cToken
     */
    function underwrite(address _vault, CToken _cToken, uint256 _tokens) external;

    /**
     * @notice reclaim the given amount of compound tokens from the given vault 
     *
     * @param _vault the address of the compound vault
     */
    function reclaim(address _vault) external;

    /** Following functions can only be called by the vault owner */

    /**
     * @notice return the provided compound tokens from the given vault,
     * and change the protection status of the vault.
     *
     * @param _vault the address of the compound vault
     */
    function removeProtection(address _vault, bool _permanent) external;

    /**
     * @notice protect the vault when it is close to liquidation.
     *
     * @param _vault the address of the compound vault
     */
    function protect(address _vault) external;

    /**
     * @notice Allows a user to migrate an existing compound position.
     * @dev The user has to approve all the cTokens (he uses as collateral)
     * to his hiding vault contract before calling this function, otherwise 
     * this contract will be reverted.
     * 
     * @param _tokens the amount that needs to be flash lent (should be 
     * greater than the value of the compund position).
     */
    function migrate(
        IKCompound _vault,
        address _account, 
        uint256 _tokens, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) external;

    /** Following function can only be called by a whitelisted keeper */

    /**
     * @notice preempt a liquidation without considering the buffer provided by JITU
     *
     * @param _vault the address of the compound vault
     * @param _cTokenRepaid the address of the compound token that needs to be repaid
     * @param _repayAmount the amount of the token that needs to be repaid
     * @param _cTokenCollateral the compound token that the user would receive for repaying the
     * loan
     *
     * @return seized token amount
     */
    function preempt(
        address _vault, 
        CToken _cTokenRepaid, 
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./Compound.sol";

/**
 * @title KCompound Interface
 * @author KeeperDAO
 * @notice Interface for the KCompound hiding vault plugin.
 */
interface IKCompound {
    /**
     * @notice Calculate the given cToken's balance of this contract.
     *
     * @param _cToken The address of the cToken contract.
     *
     * @return Outstanding balance of the given token.
     */
    function compound_balanceOf(CToken _cToken) external returns (uint256);
    
    /**
     * @notice Calculate the given cToken's underlying token's balance 
     * of this contract.
     * 
     * @param _cToken The address of the cToken contract.
     *
     * @return Outstanding balance of the given token.
     */
    function compound_balanceOfUnderlying(CToken _cToken) external returns (uint256);
    
    /**
     * @notice Calculate the unhealth of this account.
     * @dev    unhealth of an account starts from 0, if a position 
     *         has an unhealth of more than 100 then the position
     *         is liquidatable.
     *
     * @return Unhealth of this account.
     */
    function compound_unhealth() external view returns (uint256);

    /**
     * @notice Checks whether given position is underwritten.
     */
    function compound_isUnderwritten() external view returns (bool);

    /** Following functions can only be called by the owner */

    /** 
     * @notice Deposit funds to the Compound Protocol.
     *
     * @param _cToken The address of the cToken contract.
     * @param _amount The value of partial loan.
     */
    function compound_deposit(CToken _cToken, uint256 _amount) external payable;

    /**
     * @notice Repay funds to the Compound Protocol.
     *
     * @param _cToken The address of the cToken contract.
     * @param _amount The value of partial loan.
     */
    function compound_repay(CToken _cToken, uint256 _amount) external payable;

    /** 
     * @notice Withdraw funds from the Compound Protocol.
     *
     * @param _to The address of the receiver.
     * @param _cToken The address of the cToken contract.
     * @param _amount The amount to be withdrawn.
     */
    function compound_withdraw(address payable _to, CToken _cToken, uint256 _amount) external;

    /**
     * @notice Borrow funds from the Compound Protocol.
     *
     * @param _to The address of the amount receiver.
     * @param _cToken The address of the cToken contract.
     * @param _amount The value of partial loan.
     */
    function compound_borrow(address payable _to, CToken _cToken, uint256 _amount) external;

    /**
     * @notice The user can enter new markets by passing them here.
     */
    function compound_enterMarkets(address[] memory _cTokens) external;

    /** Following functions can only be called by JITU */

    /**
     * @notice Allows a user to migrate an existing compound position.
     * @dev The user has to approve all the cTokens (he owns) to this 
     * contract before calling this function, otherwise this contract will
     * be reverted.
     * @param  _amount The amount that needs to be flash lent (should be 
     *                 greater than the value of the compund position).
     */
    function compound_migrate(
        address account, 
        uint256 _amount, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) external;

    /**
     * @notice Prempt liquidation for positions underwater if the provided 
     *         buffer is not considered on the Compound Protocol.
     *
     * @param _cTokenRepay The cToken for which the loan is being repaid for.
     * @param _repayAmount The amount that should be repaid.
     * @param _cTokenCollateral The collateral cToken address.
     */
    function compound_preempt(
        address _liquidator, 
        CToken _cTokenRepay, 
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) external payable returns (uint256);

    /**
     * @notice Allows JITU to underwrite this contract, by providing cTokens.
     *
     * @param _cToken The address of the cToken.
     * @param _tokens The amount of the cToken tokens.
     */
    function compound_underwrite(CToken _cToken, uint256 _tokens) external payable;

    /**
     * @notice Allows JITU to reclaim the cTokens it provided.
     */
    function compound_reclaim() external; 
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./LibCToken.sol";
import "./IJITUCompound.sol";
import "../JITUCore.sol";

/**
 * @title Compound extension for JITU (Just-In-Time-Underwriter)
 * @author KeeperDAO
 * @notice This contract allows whitelisted keepers to add buffer to compound positions that 
 * are slightly above water, so that in the case they go underwater the keepers can
 * preempt a liquidation.
 */
contract JITUCompound is JITUCore, IJITUCompound {
    using LibCToken for CToken;

    mapping (address=>bool) public unprotected;

    /** Events */
    event Underwritten(
        address indexed _vault,
        address indexed _underwriter, 
        address indexed _token, 
        uint256 _amount
    );
    event Reclaimed(address indexed _vault, address indexed _underwriter);
    event Repaid(address indexed _vault);
    event Preempted(
        address indexed _vault, 
        address indexed _keeper, 
        address _repayToken, 
        uint256 _repayAmount, 
        address _collateralToken,
        uint256 _seizedAmount
    );
    event ProtectionRemoved(address indexed _vault);
    event ProtectionAdded(address indexed _vault);

    /**
     * @notice initialize the contract state
     */
    constructor (LiquidityPoolLike _liquidityPool, IERC721 _nft) JITUCore(_liquidityPool, _nft) {}

    /** External override Functions */

    /**
     * @inheritdoc IJITUCompound
     */
    function borrow(CToken _cToken, uint256 _amount) external override onlyOwner {
        require(_cToken.isListed(), "JITUCompound: unsupported cToken address");
        liquidityPool.adapterBorrow(
                _cToken.underlying(),
                _amount,
                abi.encodeWithSelector(this.borrowCallback.selector, _cToken, _amount)
            );
    }

    /** 
     * @dev this function should only be called by the BorrowerProxy.
     * @dev expects the LiquidityPool contract to transfer ERC20 tokens before
     * calling this function (this is validated during _cToken.mint(...)). 
     * @dev expects the LiqudityPool contract to set msg.value = _amount, (this 
     * is validated during _cToken.mint(...))
     *
     * @param _cToken the address of the cToken
     * @param _amount the amount of underlying tokens
     */
    function borrowCallback(CToken _cToken, uint256 _amount) external payable {
        require(msg.sender == liquidityPool.borrower(), 
            "JITUCompound: unsupported cToken address");
        _deposit(_cToken, _amount);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function repay(CToken _cToken, uint256 _amount) external override payable onlyOwner {
        _cToken.redeemUnderlying(_amount);
        _cToken.approveUnderlying(address(liquidityPool), _amount);
        if (address(_cToken) == address(LibCToken.CETHER)) {
            liquidityPool.adapterRepay{ value: _amount }(address(this), _cToken.underlying(), _amount);
        } else {
            liquidityPool.adapterRepay(address(this), _cToken.underlying(), _amount);
        }
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function underwrite(address _vault, CToken _cToken, uint256 _tokens) 
        external override valid(_vault) onlyWhitelistedUnderwriter {
        require(!unprotected[_vault], "JITUCompound: unprotected vault");
        require(_cToken.isListed(), "JITUCompound: unsupported cToken address");
        require(_cToken.transfer(_vault, _tokens), "JITUCompound: failed to transfer cTokens");
        IKCompound(_vault).compound_underwrite(_cToken, _tokens);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function reclaim(address _vault) external override valid(_vault) 
        onlyWhitelistedUnderwriter {  
        IKCompound(_vault).compound_reclaim();
        emit Reclaimed(_vault, msg.sender);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function removeProtection(address _vault, bool _permanent) external override onlyVaultOwner(_vault) {  
        unprotected[_vault] = _permanent;
        IKCompound(_vault).compound_reclaim();
        emit ProtectionRemoved(_vault);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function protect(address _vault) external override onlyVaultOwner(_vault) {  
        unprotected[_vault] = false;
        emit ProtectionAdded(_vault);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function migrate(
        IKCompound _vault,
        address _account, 
        uint256 _tokens, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) external override onlyVaultOwner(address(_vault)) {
        CToken cToken = CToken(_collateralMarkets[0]);
        require(cToken.isListed(), "JITUCompound: unsupported cToken address"); 
        require(
            cToken.transfer(address(_vault), _tokens), 
            "JITUCompound: failed to transfer cTokens"
        );
        _vault.compound_migrate(_account, _tokens, _collateralMarkets, _debtMarkets);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function preempt(
        address _vault, 
        CToken _cTokenRepaid, 
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) external override payable valid(_vault) onlyWhitelistedKeeper returns (uint256) {
        require(_cTokenRepaid.isListed(), "KCompound: invalid _cTokenRepaid address");
        require(_cTokenCollateral.isListed(), "KCompound: invalid _cTokenCollateral address");
        uint256 seizedAmount = IKCompound(_vault).compound_preempt{ value: msg.value }(
            msg.sender, 
            _cTokenRepaid, 
            _repayAmount, 
            _cTokenCollateral
        );
        emit Preempted(
            address(_vault), 
            msg.sender, 
            address(_cTokenRepaid), 
            _repayAmount, 
            address(_cTokenCollateral),
            seizedAmount
        );
        return seizedAmount;
    }

    /** Internal Functions */
    function _deposit(CToken _cToken, uint256 _amount) internal {
        _cToken.approveUnderlying(address(_cToken), _amount);
        _cToken.mint(_amount);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Compound.sol";

/**
 * @title Library to simplify CToken interaction
 * @author KeeperDAO
 * @dev this library abstracts cERC20 and cEther interactions.
 */
library LibCToken {
    using SafeERC20 for IERC20;

    // Network: MAINNET
    Comptroller constant COMPTROLLER = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    CEther constant CETHER = CEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    // Kovan
    // Comptroller constant COMPTROLLER = Comptroller(0x5eAe89DC1C671724A672ff0630122ee834098657);
    // CEther constant CETHER = CEther(0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72);

    /**
     * @notice checks if the given cToken is listed as a valid market on 
     * comptroller.
     * 
     * @param _cToken cToken address
     */
    function isListed(CToken _cToken) internal view returns (bool listed) {
        (listed, , ) = COMPTROLLER.markets(address(_cToken));
    }

    /**
     * @notice returns the given cToken's underlying token address.
     * 
     * @param _cToken cToken address
     */
    function underlying(CToken _cToken) internal view returns (address) {
        if (address(_cToken) == address(CETHER)) {
            return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        } else {
            return CErc20(address(_cToken)).underlying();
        }
    }

    /**
     * @notice redeems given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function redeemUnderlying(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            require(CETHER.redeemUnderlying(_amount) == 0, "failed to redeem ether");
        } else {
            require(CErc20(address(_cToken)).redeemUnderlying(_amount) == 0, "failed to redeem ERC20");
        }
    }

    /**
     * @notice borrows given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function borrow(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            require(CETHER.borrow(_amount) == 0, "failed to borrow ether");
        } else {
            require(CErc20(address(_cToken)).borrow(_amount) == 0, "failed to borrow ERC20");
        }
    }

    /**
     * @notice deposits given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function mint(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            CETHER.mint{ value: _amount }();
        } else {

            require(CErc20(address(_cToken)).mint(_amount) == 0, "failed to mint cERC20");
        }
    }

    /**
     * @notice repay given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function repayBorrow(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            CETHER.repayBorrow{ value: _amount }();
        } else {
            require(CErc20(address(_cToken)).repayBorrow(_amount) == 0, "failed to mint cERC20");
        }
    }

    /**
     * @notice repay given amount of underlying tokens on behalf of the borrower.
     * 
     * @param _cToken cToken address
     * @param _borrower borrower address
     * @param _amount underlying token amount
     */
    function repayBorrowBehalf(CToken _cToken, address _borrower, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            CETHER.repayBorrowBehalf{ value: _amount }(_borrower);
        } else {
            require(CErc20(address(_cToken)).repayBorrowBehalf(_borrower, _amount) == 0, "failed to mint cERC20");
        }
    }

    /**
     * @notice transfer given amount of underlying tokens to the given address.
     * 
     * @param _cToken cToken address
     * @param _to reciever address
     * @param _amount underlying token amount
     */
    function transferUnderlying(CToken _cToken, address payable _to, uint256 _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            (bool success,) = _to.call{ value: _amount }("");
            require(success, "Transfer Failed");
        } else {
            IERC20(CErc20(address(_cToken)).underlying()).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice approve given amount of underlying tokens to the given address.
     * 
     * @param _cToken cToken address
     * @param _spender spender address
     * @param _amount underlying token amount
     */
    function approveUnderlying(CToken _cToken, address _spender, uint256 _amount) internal {
        if (address(_cToken) != address(CETHER)) {
            IERC20 token = IERC20(CErc20(address(_cToken)).underlying());
            token.safeIncreaseAllowance(_spender, _amount);
        } 
    }

    /**
     * @notice pull approve given amount of underlying tokens to the given address.
     * 
     * @param _cToken cToken address
     * @param _from address from which the funds need to be pulled
     * @param _to address to which the funds are approved to
     * @param _amount underlying token amount
     */
    function pullAndApproveUnderlying(CToken _cToken, address _from, address _to, uint256 _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            require(msg.value == _amount, "failed to mint CETHER");
        } else {
            IERC20 token = IERC20(CErc20(address(_cToken)).underlying());
            token.safeTransferFrom(_from, address(this), _amount);
            token.safeIncreaseAllowance(_to, _amount);
        }
    }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}