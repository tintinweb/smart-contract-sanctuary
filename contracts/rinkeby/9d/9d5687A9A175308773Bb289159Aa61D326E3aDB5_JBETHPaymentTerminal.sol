// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMathUD60x18.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/Address.sol';
import '@paulrberg/contracts/math/PRBMathUD60x18.sol';
import '@paulrberg/contracts/math/PRBMath.sol';

import './libraries/JBCurrencies.sol';
import './libraries/JBOperations.sol';
import './libraries/JBSplitsGroups.sol';
import './libraries/JBFundingCycleMetadataResolver.sol';

import './JBETHPaymentTerminalStore.sol';

// Inheritance
import './interfaces/IJBETHPaymentTerminal.sol';
import './interfaces/IJBTerminal.sol';
import './interfaces/IJBVault.sol';
import './abstract/JBOperatable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
  @notice
  This contract manages all inflows and outflows of funds into the Juicebox ecosystem.

  @dev 
  A project can transfer its funds, along with the power to reconfigure and mint/burn their tokens, from this contract to another allowed terminal contract at any time.

  Inherits from:

  IJBPaymentTerminal - general interface for the methods in this contract that send and receive funds according to the Juicebox protocol's rules.
  JBOperatable - several functions in this contract can only be accessed by a project owner, or an address that has been preconfifigured to be an operator of the project.
  ReentrencyGuard - several function in this contract shouldn't be accessible recursively.
*/
contract JBETHPaymentTerminal is
  IJBETHPaymentTerminal,
  IJBTerminal,
  JBOperatable,
  Ownable,
  ReentrancyGuard
{
  // A library that parses the packed funding cycle metadata into a more friendly format.
  using JBFundingCycleMetadataResolver for JBFundingCycle;

  //*********************************************************************//
  // --------------------- private stored constants -------------------- //
  //*********************************************************************//

  /**
    @notice 
    Fees that are being held to be processed later.

    _projectId The ID of the project for which fees are being held.
  */
  mapping(uint256 => JBFee[]) private _heldFeesOf;

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice
    The Projects contract which mints ERC-721's that represent project ownership and transfers.
  */
  IJBProjects public immutable override projects;

  /** 
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  /** 
    @notice
    The contract that stores splits for each project.
  */
  IJBSplitsStore public immutable override splitsStore;

  /**
    @notice 
    The contract that stores and manages the terminal's data.
  */
  JBETHPaymentTerminalStore public immutable store;

  /** 
    @notice 
    The token that this terminal accepts. 

    @dev
    ETH is represented as address 0x0000000000000000000000000000000000042069.
  */
  address public immutable override token = 0x0000000000000000000000000000000000042069;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The ETH balance that this terminal holds for each project.

    @param _projectId The ID of the project to which the balance belongs.

    @return The ETH balance.
  */
  function ethBalanceOf(uint256 _projectId) external view override returns (uint256) {
    // The store's balance is already in ETH.
    return store.balanceOf(_projectId);
  }

  /** 
    @notice 
    The fees that are currently being held to be processed later for each project.

    @param _projectId The ID of the project for which fees are being held.

    @return An array of fees that are being held.
  */
  function heldFeesOf(uint256 _projectId) external view override returns (JBFee[] memory) {
    return _heldFeesOf[_projectId];
  }

  /** 
    @notice
    An address that serves as this terminal's delegate when making requests to juicebox ecosystem contracts.

    @return The delegate address.
  */
  function delegate() external view override returns (address) {
    // The store is the delegate.
    return address(store);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _operatorStore A contract storing operator assignments.
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _directory A contract storing directories of terminals and controllers for each project.
    @param _splitsStore A contract that stores splits for each project.
    @param _store A contract that stores the terminal's data.
  */
  constructor(
    IJBOperatorStore _operatorStore,
    IJBProjects _projects,
    IJBDirectory _directory,
    IJBSplitsStore _splitsStore,
    JBETHPaymentTerminalStore _store
  ) JBOperatable(_operatorStore) {
    projects = _projects;
    directory = _directory;
    splitsStore = _splitsStore;

    // Claim the store so that it recognizes this terminal as the one that can access it.
    _store.claim();

    store = _store;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice
    Contribute ETH to a project.

    @dev
    The msg.value is the amount of the contribution in wei.

    @param _projectId The ID of the project being paid.
    @param _beneficiary The address to mint tokens for and pass along to the funding cycle's data source and delegate.
    @param _minReturnedTokens The minimum number of tokens expected in return.
    @param _preferClaimedTokens A flag indicating whether the request prefers to issue tokens unstaked rather than staked.
    @param _memo A memo to pass along to the emitted event, and passed along the the funding cycle's data source and delegate.
    @param _delegateMetadata Bytes to send along to the delegate, if one is provided.

    @return The number of the funding cycle that the payment was made during.
  */
  function pay(
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _delegateMetadata
  ) external payable override returns (uint256) {
    return
      _pay(
        msg.value,
        _projectId,
        _beneficiary,
        _minReturnedTokens,
        _preferClaimedTokens,
        _memo,
        _delegateMetadata
      );
  }

  /**
    @notice 
    Distributes payouts for a project according to the constraints of its current funding cycle.

    @dev
    Payouts are sent to the preprogrammed splits. 

    @dev
    Anyone can distribute payouts on a project's behalf.

    @param _projectId The ID of the project having its payouts distributed.
    @param _amount The amount being distributed.
    @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's currency.
    @param _minReturnedWei The minimum number of wei that the amount should be valued at.

    @return The ID of the funding cycle during which the distribution was made.
  */
  function distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedWei,
    string memory _memo
  ) external override nonReentrant returns (uint256) {
    // Record the withdrawal.
    (JBFundingCycle memory _fundingCycle, uint256 _withdrawnAmount) = store.recordWithdrawalFor(
      _projectId,
      _amount,
      _currency,
      _minReturnedWei
    );

    // Get a reference to the project owner, which will receive tokens from paying the platform fee
    // and receive any extra distributable funds not allocated to payout splits.
    address payable _projectOwner = payable(projects.ownerOf(_projectId));

    // Get a reference to the handle of the project paying the fee and sending payouts.
    bytes32 _handle = projects.handleOf(_projectId);

    // Take a fee from the _withdrawnAmount, if needed.
    // The project's owner will be the beneficiary of the resulting minted tokens from platform project.
    // The platform project's ID is 1.
    uint256 _feeAmount = _fundingCycle.fee == 0 || _projectId == 1
      ? 0
      : _takeFeeFrom(
        _fundingCycle,
        _withdrawnAmount,
        _projectOwner,
        string(bytes.concat('Fee from @', _handle))
      );

    // Payout to splits and get a reference to the leftover transfer amount after all mods have been paid.
    // The net transfer amount is the withdrawn amount minus the fee.
    uint256 _leftoverDistributionAmount = _distributeToPayoutSplitsOf(
      _fundingCycle,
      _withdrawnAmount - _feeAmount,
      string(bytes.concat('Payout from @', _handle))
    );

    // Transfer any remaining balance to the project owner.
    if (_leftoverDistributionAmount > 0)
      Address.sendValue(_projectOwner, _leftoverDistributionAmount);

    emit DistributePayouts(
      _fundingCycle.id,
      _projectId,
      _projectOwner,
      _amount,
      _withdrawnAmount,
      _feeAmount,
      _leftoverDistributionAmount,
      _memo,
      msg.sender
    );

    return _fundingCycle.id;
  }

  /**
    @notice 
    Allows a project to send funds from its overflow up to the preconfigured allowance.
    
    @dev 
    Only a project's owner or a designated operator can migrate it.

    @param _projectId The ID of the project to use the allowance of.
    @param _amount The amount of the allowance to use.
    @param _beneficiary The address to send the funds to.

    @return The ID of the funding cycle during which the allowance was use.
  */
  function useAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedWei,
    address payable _beneficiary
  )
    external
    override
    nonReentrant
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.USE_ALLOWANCE)
    returns (uint256)
  {
    // Record the use of the allowance.
    (JBFundingCycle memory _fundingCycle, uint256 _withdrawnAmount) = store.recordUsedAllowanceOf(
      _projectId,
      this,
      _amount,
      _currency,
      _minReturnedWei
    );

    // Get a reference to the project owner, which will receive tokens from paying the platform fee
    // and receive any extra distributable funds not allocated to payout splits.
    address payable _projectOwner = payable(projects.ownerOf(_projectId));

    // Get a reference to the handle of the project paying the fee and sending payouts.
    bytes32 _handle = projects.handleOf(_projectId);

    // Take a fee from the _withdrawnAmount, if needed.
    // The project's owner will be the beneficiary of the resulting minted tokens from platform project.
    // The platform project's ID is 1.
    uint256 _feeAmount = _fundingCycle.fee == 0 || _projectId == 1
      ? 0
      : _takeFeeFrom(
        _fundingCycle,
        _withdrawnAmount,
        _projectOwner,
        string(bytes.concat('Fee from @', _handle))
      );

    // Transfer any remaining balance to the project owner.
    Address.sendValue(_beneficiary, _withdrawnAmount - _feeAmount);

    emit UseAllowance(
      _fundingCycle.id,
      _fundingCycle.configured,
      _projectId,
      _beneficiary,
      _withdrawnAmount,
      _feeAmount,
      _withdrawnAmount - _feeAmount,
      msg.sender
    );

    return _fundingCycle.id;
  }

  /**
    @notice
    Addresses can redeem their tokens to claim the project's overflowed ETH, or to trigger rules determined by the project's current funding cycle's data source.

    @dev
    Only a token's holder or a designated operator can redeem it.

    @param _holder The account to redeem tokens for.
    @param _projectId The ID of the project to which the tokens being redeemed belong.
    @param _tokenCount The number of tokens to redeem.
    @param _minReturnedWei The minimum amount of Wei expected in return.
    @param _beneficiary The address to send the ETH to. Send the address this contract to burn the count.
    @param _memo A memo to pass along to the emitted event.
    @param _delegateMetadata Bytes to send along to the delegate, if one is provided.

    @return claimAmount The amount of ETH that the tokens were redeemed for, in wei.
  */
  function redeemTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _minReturnedWei,
    address payable _beneficiary,
    string memory _memo,
    bytes memory _delegateMetadata
  )
    external
    override
    nonReentrant
    requirePermission(_holder, _projectId, JBOperations.REDEEM)
    returns (uint256 claimAmount)
  {
    // Can't send claimed funds to the zero address.
    require(_beneficiary != address(0), '0x4c: ZERO_ADDRESS');

    // Keep a reference to the funding cycles during which the redemption is being made.
    JBFundingCycle memory _fundingCycle;

    // Record the redemption.
    (_fundingCycle, claimAmount, _memo) = store.recordRedemptionFor(
      _holder,
      _projectId,
      _tokenCount,
      _minReturnedWei,
      _beneficiary,
      _memo,
      _delegateMetadata
    );

    // Send the claimed funds to the beneficiary.
    if (claimAmount > 0) Address.sendValue(_beneficiary, claimAmount);

    emit RedeemTokens(
      _fundingCycle.id,
      _projectId,
      _holder,
      _fundingCycle,
      _beneficiary,
      _tokenCount,
      claimAmount,
      _memo,
      msg.sender
    );
  }

  /**
    @notice
    Allows a project owner to migrate its funds and operations to a new terminal.

    @dev
    Only a project's owner or a designated operator can migrate it.

    @param _projectId The ID of the project being migrated.
    @param _to The terminal contract that will gain the project's funds.
  */
  function migrate(uint256 _projectId, IJBTerminal _to)
    external
    override
    nonReentrant
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.MIGRATE_TERMINAL)
  {
    // The terminal being migrated to must accept the same token as this terminal.
    require(token == _to.token(), '0x4d: INCOMPATIBLE');

    // Record the migration in the store.
    uint256 _balance = store.recordMigration(_projectId);

    if (_balance > 0)
      // Withdraw the balance to transfer to the new terminal;
      _to.addToBalanceOf{value: _balance}(_projectId, '');

    emit Migrate(_projectId, _to, _balance, msg.sender);
  }

  /**
    @notice
    Receives funds belonging to the specified project.

    @param _projectId The ID of the project to which the funds received belong.
    @param _memo A memo to pass along to the emitted event.
  */
  function addToBalanceOf(uint256 _projectId, string memory _memo) external payable override {
    // Amount must be greater than 0.
    require(msg.value > 0, '0x4c: NO_OP');

    // Record the added funds.
    JBFundingCycle memory _fundingCycle = store.recordAddedBalanceFor(_projectId, msg.value);

    // Refund any held fees to make sure the project doesn't pay double for funds going in and out of the protocol.
    _refundHeldFees(_projectId, msg.value, _fundingCycle.fee);

    emit AddToBalance(_projectId, msg.value, _memo, msg.sender);
  }

  /**
    @notice
    Process any fees that are being held for the project.

    @dev
    Only a project owner, an operator, or the contract's owner can process held fees.

    @param _projectId The ID of the project whos held fees should be processed.
  */
  function processFees(uint256 _projectId)
    external
    requirePermissionAllowingOverride(
      projects.ownerOf(_projectId),
      _projectId,
      JBOperations.PROCESS_FEES,
      msg.sender == owner()
    )
    nonReentrant
  {
    // Get a reference to the project's held fees.
    JBFee[] memory _heldFees = _heldFeesOf[_projectId];

    // Process each fee.
    for (uint256 _i = 0; _i < _heldFees.length; _i++)
      _takeFee(_heldFees[_i].amount, _heldFees[_i].beneficiary, _heldFees[_i].memo);

    // Delete the held fee's now that they've been processed.
    delete _heldFeesOf[_projectId];

    emit ProcessFees(_projectId, _heldFees, msg.sender);
  }

  //*********************************************************************//
  // --------------------- private helper functions -------------------- //
  //*********************************************************************//

  /** 
    @notice
    Pays out splits for a project's funding cycle configuration.

    @param _fundingCycle The funding cycle during which the distribution is being made.
    @param _amount The total amount being distributed.
    @param _memo A memo to pass along to the emitted events.

    @return leftoverAmount If the leftover amount if the splits don't add up to 100%.
  */
  function _distributeToPayoutSplitsOf(
    JBFundingCycle memory _fundingCycle,
    uint256 _amount,
    string memory _memo
  ) private returns (uint256 leftoverAmount) {
    // Set the leftover amount to the initial amount.
    leftoverAmount = _amount;

    // Get a reference to the project's payout splits.
    JBSplit[] memory _splits = splitsStore.splitsOf(
      _fundingCycle.projectId,
      _fundingCycle.configured,
      JBSplitsGroups.ETH_PAYOUT
    );

    //Transfer between all splits.
    for (uint256 _i = 0; _i < _splits.length; _i++) {
      // Get a reference to the mod being iterated on.
      JBSplit memory _split = _splits[_i];

      // The amount to send towards mods. Mods percents are out of 10000000.
      uint256 _payoutAmount = PRBMath.mulDiv(_amount, _split.percent, 10000000);

      if (_payoutAmount > 0) {
        // Transfer ETH to the mod.
        // If there's an allocator set, transfer to its `allocate` function.
        if (_split.allocator != IJBSplitAllocator(address(0))) {
          _split.allocator.allocate{value: _payoutAmount}(
            _payoutAmount,
            JBSplitsGroups.ETH_PAYOUT,
            _fundingCycle.projectId,
            _split.projectId,
            _split.beneficiary,
            _split.preferClaimed
          );
          // Otherwise, if a project is specified, make a payment to it.
        } else if (_split.projectId != 0) {
          // Get a reference to the Juicebox terminal being used.
          IJBTerminal _terminal = directory.primaryTerminalOf(_split.projectId, token);

          // The project must have a terminal to send funds to.
          require(_terminal != IJBTerminal(address(0)), '0x4d: BAD_SPLIT');

          // Save gas if this contract is being used as the terminal.
          if (_terminal == this) {
            _pay(
              _payoutAmount,
              _split.projectId,
              _split.beneficiary,
              0,
              _split.preferClaimed,
              _memo,
              bytes('')
            );
          } else {
            _terminal.pay{value: _payoutAmount}(
              _split.projectId,
              _split.beneficiary,
              0,
              _split.preferClaimed,
              _memo,
              bytes('')
            );
          }
        } else {
          // Otherwise, send the funds directly to the beneficiary.
          Address.sendValue(_split.beneficiary, _payoutAmount);
        }

        // Subtract from the amount to be sent to the beneficiary.
        leftoverAmount = leftoverAmount - _payoutAmount;
      }

      emit DistributeToPayoutSplit(
        _fundingCycle.id,
        _fundingCycle.projectId,
        _split,
        _payoutAmount,
        msg.sender
      );
    }
  }

  /** 
    @notice 
    Takes a fee into the platform's project, which has an id of 1.

    @param _fundingCycle The funding cycle during which the fee is being taken. 
    @param _amount The amount to take a fee from.
    @param _beneficiary The address to print the platforms tokens for.
    @param _memo A memo to pass along to the emitted event.

    @return feeAmount The amount of the fee taken.
  */
  function _takeFeeFrom(
    JBFundingCycle memory _fundingCycle,
    uint256 _amount,
    address _beneficiary,
    string memory _memo
  ) private returns (uint256 feeAmount) {
    // The amount of ETH from the _amount to pay as a fee.
    feeAmount = _amount - PRBMath.mulDiv(_amount, 200, _fundingCycle.fee + 200);

    // Nothing to do if there's no fee to take.
    if (feeAmount == 0) return 0;

    _fundingCycle.shouldHoldFees()
      ? _heldFeesOf[_fundingCycle.projectId].push(JBFee(feeAmount, _beneficiary, _memo)) // Take the fee.
      : _takeFee(feeAmount, _beneficiary, _memo);
  }

  /** 
    @notice 
    Take a fee of the specified amount.

    @param _amount The fee amount.
    @param _beneficiary The address to print the platforms tokens for.
    @param _memo A memo to pass along to the emitted event.
  */
  function _takeFee(
    uint256 _amount,
    address _beneficiary,
    string memory _memo
  ) private {
    // Get the terminal for the JuiceboxDAO project.
    IJBTerminal _terminal = directory.primaryTerminalOf(1, token);

    // When processing the admin fee, save gas if the admin is using this contract as its terminal.
    _terminal == this // Use the local pay call.
      ? _pay(_amount, 1, _beneficiary, 0, false, _memo, bytes('')) // Use the external pay call of the correct terminal.
      : _terminal.pay{value: _amount}(1, _beneficiary, 0, false, _memo, bytes(''));
  }

  /**
    @notice
    See the documentation for 'pay'.
  */
  function _pay(
    uint256 _amount,
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string memory _memo,
    bytes memory _delegateMetadata
  ) private returns (uint256) {
    // Cant send tokens to the zero address.
    require(_beneficiary != address(0), '0x4e: ZERO_ADDRESS');

    JBFundingCycle memory _fundingCycle;
    uint256 _weight;
    uint256 _tokenCount;

    // Record the payment.
    (_fundingCycle, _weight, _tokenCount, _memo) = store.recordPaymentFrom(
      msg.sender,
      _amount,
      _projectId,
      (_preferClaimedTokens ? 1 : 0) | uint160(_beneficiary),
      _minReturnedTokens,
      _memo,
      _delegateMetadata
    );

    emit Pay(
      _fundingCycle.id,
      _projectId,
      _beneficiary,
      _fundingCycle,
      _amount,
      _weight,
      _tokenCount,
      _memo,
      msg.sender
    );

    return _fundingCycle.id;
  }

  /** 
    @notice
    Refund fees based on the specified amount.

    @param _projectId The project for which fees are being refunded.
    @param _amount The amount to base the refund on.
    @param _percent The current fee percent to issue a refund based on.
  */
  function _refundHeldFees(
    uint256 _projectId,
    uint256 _amount,
    uint256 _percent
  ) private {
    // The amount of fees that were taken from an original payout to yield the provided amount.
    uint256 _refundAmount = PRBMath.mulDiv(_amount, _percent + 200, 200) - _amount;

    // Get a reference to the project's held fees.
    JBFee[] memory _heldFees = _heldFeesOf[_projectId];

    // Delete the current held fees.
    delete _heldFeesOf[_projectId];

    // Process each fee.
    for (uint256 _i = 0; _i < _heldFees.length; _i++) {
      if (_refundAmount == 0) {
        _heldFeesOf[_projectId].push(_heldFees[_i]);
      } else if (_refundAmount >= _heldFees[_i].amount) {
        _refundAmount = _refundAmount - _heldFees[_i].amount;
      } else {
        _heldFeesOf[_projectId].push(
          JBFee(_heldFees[_i].amount - _refundAmount, _heldFees[_i].beneficiary, _heldFees[_i].memo)
        );
        _refundAmount = 0;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@paulrberg/contracts/math/PRBMathUD60x18.sol';
import '@paulrberg/contracts/math/PRBMath.sol';

import './interfaces/IJBPrices.sol';
import './interfaces/IJBTokenStore.sol';

import './libraries/JBCurrencies.sol';
import './libraries/JBOperations.sol';
import './libraries/JBSplitsGroups.sol';
import './libraries/JBFundingCycleMetadataResolver.sol';

/**
  @notice
  This contract manages all inflows and outflows of funds into the Juicebox ecosystem.

  @dev 
  A project can transfer its funds, along with the power to reconfigure and mint/burn their tokens, from this contract to another allowed terminal contract at any time.

  Inherits from:

  IJBPaymentTerminal - general interface for the methods in this contract that send and receive funds according to the Juicebox protocol's rules.
  JBOperatable - several functions in this contract can only be accessed by a project owner, or an address that has been preconfifigured to be an operator of the project.
  ReentrencyGuard - several function in this contract shouldn't be accessible recursively.
*/
contract JBETHPaymentTerminalStore {
  // A library that parses the packed funding cycle metadata into a more friendly format.
  using JBFundingCycleMetadataResolver for JBFundingCycle;

  // A modifier only allowing the associated payment terminal to access the function.
  modifier onlyAssociatedPaymentTerminal() {
    require(msg.sender == terminal, '0x3a: UNAUTHORIZED');
    _;
  }

  event DelegateDidPay(IJBPayDelegate indexed delegate, JBDidPayData data);

  event DelegateDidRedeem(IJBRedemptionDelegate indexed delegate, JBDidRedeemData data);

  /** 
    @notice
    The Projects contract which mints ERC-721's that represent project ownership and transfers.
  */
  IJBProjects public immutable projects;

  /** 
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable directory;

  /** 
    @notice 
    The contract storing all funding cycle configurations.
  */
  IJBFundingCycleStore public immutable fundingCycleStore;

  /** 
    @notice 
    The contract that manages token minting and burning.
  */
  IJBTokenStore public immutable tokenStore;

  /** 
    @notice 
    The contract that exposes price feeds.
  */
  IJBPrices public immutable prices;

  /** 
    @notice
    The associated payment terminal for which this contract stores data.
  */
  address public terminal;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The amount of ETH that each project has.

    _projectId The ID of the project to get the balance of.
  */
  mapping(uint256 => uint256) public balanceOf;

  /**
    @notice 
    The amount of overflow that a project is allowed to tap into on-demand for the specified project configuration. 

    @dev 
    Decreases as projects use of the allowance.

    _projectId The ID of the project to get the current overflow allowance of.
    _configuration The configuration of the during which the allowance applies.
  */
  mapping(uint256 => mapping(uint256 => uint256)) public usedOverflowAllowanceOf;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice
    Gets the current overflowed amount for a specified project.

    @param _projectId The ID of the project to get overflow for.

    @return The current amount of overflow that project has.
  */
  function currentOverflowOf(uint256 _projectId) external view returns (uint256) {
    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    return _overflowDuring(_fundingCycle);
  }

  /**
    @notice
    The amount of overflowed ETH that can be claimed by the specified number of tokens.

    @dev If the project has an active funding cycle reconfiguration ballot, the project's ballot redemption rate is used.

    @param _projectId The ID of the project to get a claimable amount for.
    @param _tokenCount The number of tokens to make the calculation with. 

    @return The amount of overflowed ETH that can be claimed.
  */
  function claimableOverflowOf(uint256 _projectId, uint256 _tokenCount)
    external
    view
    returns (uint256)
  {
    return _claimableOverflowOf(fundingCycleStore.currentOf(_projectId), _tokenCount);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _prices A contract that exposes price feeds.
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _directory A contract storing directories of terminals and controllers for each project.
    @param _fundingCycleStore A contract storing all funding cycle configurations.
    @param _tokenStore A contract that manages token minting and burning.
  */
  constructor(
    IJBPrices _prices,
    IJBProjects _projects,
    IJBDirectory _directory,
    IJBFundingCycleStore _fundingCycleStore,
    IJBTokenStore _tokenStore
  ) {
    prices = _prices;
    projects = _projects;
    directory = _directory;
    fundingCycleStore = _fundingCycleStore;
    tokenStore = _tokenStore;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice
    Records newly contributed ETH to a project.

    @dev
    Mint's the project's tokens according to values provided by a configured data source. If no data source is configured, mints tokens proportional to the amount of the contribution.

    @dev 
    Only the associated payment terminal can record a payment.

    @param _payer The original address that sent the payment to the terminal.
    @param _amount The amount that is being paid.
    @param _projectId The ID of the project being paid.
    @param _preferClaimedTokensAndBeneficiary Two properties are included in this packed uint256:
      The first bit contains the flag indicating whether the request prefers to issue tokens claimed as ERC-20s.
      The remaining bits contains the address that should receive benefits from the payment.

      This design is necessary two prevent a "Stack too deep" compiler error that comes up if the variables are declared seperately.
    @param _minReturnedTokens The minimum number of tokens expected to be minted in return.
    @param _memo A memo that will be included in the published event.
    @param _delegateMetadata Bytes to send along to the delegate, if one is used.

    @return fundingCycle The project's funding cycle during which payment was made.
    @return weight The weight according to which new token supply was minted.
    @return tokenCount The number of tokens that were minted.
    @return memo A memo that should be passed along to the emitted event.
  */
  function recordPaymentFrom(
    address _payer,
    uint256 _amount,
    uint256 _projectId,
    uint256 _preferClaimedTokensAndBeneficiary,
    uint256 _minReturnedTokens,
    string memory _memo,
    bytes memory _delegateMetadata
  )
    external
    onlyAssociatedPaymentTerminal
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 weight,
      uint256 tokenCount,
      string memory memo
    )
  {
    // Get a reference to the current funding cycle for the project.
    fundingCycle = fundingCycleStore.currentOf(_projectId);

    // The project must have a funding cycle configured.
    require(fundingCycle.number > 0, '0x3a: NOT_FOUND');

    // Must not be paused.
    require(!fundingCycle.payPaused(), '0x3b: PAUSED');

    // Save a reference to the delegate to use.
    IJBPayDelegate _delegate;

    // If the funding cycle has configured a data source, use it to derive a weight and memo.
    if (fundingCycle.useDataSourceForPay()) {
      (weight, memo, _delegate, _delegateMetadata) = fundingCycle.dataSource().payParams(
        JBPayParamsData(
          _payer,
          _amount,
          fundingCycle.weight,
          fundingCycle.reservedRate(),
          address(uint160(_preferClaimedTokensAndBeneficiary >> 1)),
          _memo,
          _delegateMetadata
        )
      );
      // Otherwise use the funding cycle's weight
    } else {
      weight = fundingCycle.weight;
      memo = _memo;
    }

    // Multiply the amount by the weight to determine the amount of tokens to mint.
    uint256 _weightedAmount = PRBMathUD60x18.mul(_amount, weight);

    // Add the amount to the balance of the project if needed.
    if (_amount > 0) balanceOf[_projectId] = balanceOf[_projectId] + _amount;

    if (_weightedAmount > 0)
      tokenCount = directory.controllerOf(_projectId).mintTokensOf(
        _projectId,
        _weightedAmount,
        address(uint160(_preferClaimedTokensAndBeneficiary >> 1)),
        'ETH received',
        (_preferClaimedTokensAndBeneficiary & 1) == 0,
        fundingCycle.reservedRate()
      );

    // The token count for the beneficiary must be greater than or equal to the minimum expected.
    require(tokenCount >= _minReturnedTokens, '0x3c: INADEQUATE');

    // If a delegate was returned by the data source, issue a callback to it.
    if (_delegate != IJBPayDelegate(address(0))) {
      JBDidPayData memory _data = JBDidPayData(
        _payer,
        _projectId,
        _amount,
        weight,
        tokenCount,
        payable(address(uint160(_preferClaimedTokensAndBeneficiary >> 1))),
        memo,
        _delegateMetadata
      );
      _delegate.didPay(_data);
      emit DelegateDidPay(_delegate, _data);
    }
  }

  /**
    @notice
    Records newly withdrawn funds for a project.

    @dev
    Only the associated payment terminal can record a withdrawal.

    @param _projectId The ID of the project that is having funds withdrawn.
    @param _amount The amount being withdrawn. Send as wei (18 decimals).
    @param _currency The expected currency of the `_amount` being tapped. This must match the project's current funding cycle's currency.
    @param _minReturnedWei The minimum number of wei that should be withdrawn.

    @return fundingCycle The funding cycle during which the withdrawal was made.
    @return withdrawnAmount The amount withdrawn.
  */
  function recordWithdrawalFor(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedWei
  )
    external
    onlyAssociatedPaymentTerminal
    returns (JBFundingCycle memory fundingCycle, uint256 withdrawnAmount)
  {
    // Registers the funds as withdrawn and gets the ID of the funding cycle during which this withdrawal is being made.
    fundingCycle = directory.controllerOf(_projectId).signalWithdrawlFrom(_projectId, _amount);

    // Funds cannot be withdrawn if there's no funding cycle.
    require(fundingCycle.id > 0, '0x3d: NOT_FOUND');

    // The funding cycle must not be configured to have withdrawals paused.
    require(!fundingCycle.withdrawalsPaused(), '0x3e: PAUSED');

    // Make sure the currencies match.
    require(_currency == fundingCycle.currency, '0x3f: UNEXPECTED_CURRENCY');

    // Convert the amount to wei.
    withdrawnAmount = PRBMathUD60x18.div(
      _amount,
      prices.priceFor(fundingCycle.currency, JBCurrencies.ETH)
    );

    // The amount being withdrawn must be available.
    require(withdrawnAmount <= balanceOf[_projectId], '0x40: INSUFFICIENT_FUNDS');

    // The amount being withdrawn must be at least as much as was expected.
    require(_minReturnedWei <= withdrawnAmount, '0x41: INADEQUATE');

    // Removed the withdrawn funds from the project's balance.
    balanceOf[_projectId] = balanceOf[_projectId] - withdrawnAmount;
  }

  /** 
    @notice 
    Records newly used allowance funds of a project.

    @param _projectId The ID of the project to use the allowance of.
    @param _terminal The terminal for the allowance.
    @param _amount The amount of the allowance to use.
    @param _currency The currency of the `_amount` value. Must match the funding cycle's currency.
    @param _minReturnedWei The amount of wei that is expected to be withdrawn.

    @return fundingCycle The funding cycle during which the withdrawal is being made.
    @return withdrawnAmount The amount withdrawn.
  */
  function recordUsedAllowanceOf(
    uint256 _projectId,
    IJBTerminal _terminal,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedWei
  )
    external
    onlyAssociatedPaymentTerminal
    returns (JBFundingCycle memory fundingCycle, uint256 withdrawnAmount)
  {
    // Get a reference to the project's current funding cycle.
    fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Make sure the currencies match.
    require(_currency == fundingCycle.currency, '0x42: UNEXPECTED_CURRENCY');

    // Convert the amount to wei.
    withdrawnAmount = PRBMathUD60x18.div(
      _amount,
      prices.priceFor(fundingCycle.currency, JBCurrencies.ETH)
    );

    // There must be sufficient allowance available.
    require(
      withdrawnAmount <=
        directory.controllerOf(_projectId).overflowAllowanceOf(
          _projectId,
          fundingCycle.configured,
          _terminal
        ) -
          usedOverflowAllowanceOf[_projectId][fundingCycle.configured],
      '0x43: NOT_ALLOWED'
    );

    // The amount being withdrawn must be available.
    require(withdrawnAmount <= balanceOf[_projectId], '0x44: INSUFFICIENT_FUNDS');

    // The amount being withdrawn must be at least as much as was expected.
    require(_minReturnedWei <= withdrawnAmount, '0x45: INADEQUATE');

    // Store the decremented value.
    usedOverflowAllowanceOf[_projectId][fundingCycle.configured] =
      usedOverflowAllowanceOf[_projectId][fundingCycle.configured] +
      withdrawnAmount;

    // Update the project's balance.
    balanceOf[_projectId] = balanceOf[_projectId] - withdrawnAmount;
  }

  /**
    @notice
    Records newly redeemed tokens of a project.

    @dev 
    Only the associated payment terminal can record a redemption.

    @param _holder The account that is having its tokens redeemed.
    @param _projectId The ID of the project to which the tokens being redeemed belong.
    @param _tokenCount The number of tokens to redeemed.
    @param _minReturnedWei The minimum amount of wei expected in return.
    @param _beneficiary The address that will benefit from the claimed amount.
    @param _memo A memo to pass along to the emitted event.
    @param _delegateMetadata Bytes to send along to the delegate, if one is used.

    @return fundingCycle The funding cycle during which the redemption was made.
    @return claimAmount The amount of wei claimed.
    @return memo A memo that should be passed along to the emitted event.
  */
  function recordRedemptionFor(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _minReturnedWei,
    address payable _beneficiary,
    string memory _memo,
    bytes memory _delegateMetadata
  )
    external
    onlyAssociatedPaymentTerminal
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 claimAmount,
      string memory memo
    )
  {
    // The holder must have the specified number of the project's tokens.
    require(tokenStore.balanceOf(_holder, _projectId) >= _tokenCount, '0x46: INSUFFICIENT_TOKENS');

    // Get a reference to the project's current funding cycle.
    fundingCycle = fundingCycleStore.currentOf(_projectId);

    // The current funding cycle must not be paused.
    require(!fundingCycle.redeemPaused(), '0x47: PAUSED');

    // Save a reference to the delegate to use.
    IJBRedemptionDelegate _delegate;

    // If the funding cycle has configured a data source, use it to derive a claim amount and memo.
    if (fundingCycle.useDataSourceForRedeem()) {
      (claimAmount, memo, _delegate, _delegateMetadata) = fundingCycle.dataSource().redeemParams(
        JBRedeemParamsData(
          _holder,
          _tokenCount,
          fundingCycle.redemptionRate(),
          fundingCycle.ballotRedemptionRate(),
          _beneficiary,
          _memo,
          _delegateMetadata
        )
      );
    } else {
      claimAmount = _claimableOverflowOf(fundingCycle, _tokenCount);
      memo = _memo;
    }

    // The amount being claimed must be within the project's balance.
    require(claimAmount <= balanceOf[_projectId], '0x48: INSUFFICIENT_FUNDS');

    // The amount being claimed must be at least as much as was expected.
    require(claimAmount >= _minReturnedWei, '0x49: INADEQUATE');

    // Redeem the tokens, which burns them.
    if (_tokenCount > 0)
      directory.controllerOf(_projectId).burnTokensOf(
        _holder,
        _projectId,
        _tokenCount,
        'Redeem for ETH',
        true
      );

    // Remove the redeemed funds from the project's balance.
    if (claimAmount > 0) balanceOf[_projectId] = balanceOf[_projectId] - claimAmount;

    // If a delegate was returned by the data source, issue a callback to it.
    if (_delegate != IJBRedemptionDelegate(address(0))) {
      JBDidRedeemData memory _data = JBDidRedeemData(
        _holder,
        _projectId,
        _tokenCount,
        claimAmount,
        _beneficiary,
        memo,
        _delegateMetadata
      );
      _delegate.didRedeem(_data);
      emit DelegateDidRedeem(_delegate, _data);
    }
  }

  /**
    @notice
    Records newly added funds for the project.

    @dev
    Only the associated payment terminal can record an added balance.

    @param _projectId The ID of the project to which the funds being added belong.
    @param _amount The amount added, in wei.

    @return fundingCycle The current funding cycle for the project.
  */
  function recordAddedBalanceFor(uint256 _projectId, uint256 _amount)
    external
    onlyAssociatedPaymentTerminal
    returns (JBFundingCycle memory fundingCycle)
  {
    // Get a reference to the project's current funding cycle.
    fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Increment the balance.
    balanceOf[_projectId] = balanceOf[_projectId] + _amount;
  }

  /** 
    @notice
    Records the migration of this terminal to another.

    @param _projectId The ID of the project being migrated.

    @return balance The project's current balance.
  */
  function recordMigration(uint256 _projectId)
    external
    onlyAssociatedPaymentTerminal
    returns (uint256 balance)
  {
    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(_projectId);

    // Migration must be allowed
    require(_fundingCycle.terminalMigrationAllowed(), '0x4a: NOT_ALLOWED');

    // Return the current balance.
    balance = balanceOf[_projectId];

    // Set the balance to 0.
    balanceOf[_projectId] = 0;
  }

  /** 
    @notice
    Allows this store to be claimed by an address so that it recognized the address as its terminal.
  */
  function claim() external {
    // This store can only be claimed once.
    require(terminal == address(0), '0x4b: ALREADY_CLAIMED');

    // Set the terminal as the msg.sender.
    terminal = msg.sender;
  }

  //*********************************************************************//
  // --------------------- private helper functions -------------------- //
  //*********************************************************************//

  /**
    @notice
    See docs for `claimableOverflowOf`
  */
  function _claimableOverflowOf(JBFundingCycle memory _fundingCycle, uint256 _tokenCount)
    private
    view
    returns (uint256)
  {
    // Get the amount of current overflow.
    uint256 _currentOverflow = _overflowDuring(_fundingCycle);

    // If there is no overflow, nothing is claimable.
    if (_currentOverflow == 0) return 0;

    // Get the total number of tokens in circulation.
    uint256 _totalSupply = tokenStore.totalSupplyOf(_fundingCycle.projectId);

    // Get the number of reserved tokens the project has.
    uint256 _reservedTokenAmount = directory
      .controllerOf(_fundingCycle.projectId)
      .reservedTokenBalanceOf(_fundingCycle.projectId, _fundingCycle.reservedRate());

    // If there are reserved tokens, add them to the total supply.
    if (_reservedTokenAmount > 0) _totalSupply = _totalSupply + _reservedTokenAmount;

    // If the amount being redeemed is the the total supply, return the rest of the overflow.
    if (_tokenCount == _totalSupply) return _currentOverflow;

    // Use the ballot redemption rate if the queued cycle is pending approval according to the previous funding cycle's ballot.
    uint256 _redemptionRate = fundingCycleStore.currentBallotStateOf(_fundingCycle.projectId) ==
      JBBallotState.Active
      ? _fundingCycle.ballotRedemptionRate()
      : _fundingCycle.redemptionRate();

    // If the redemption rate is 0, nothing is claimable.
    if (_redemptionRate == 0) return 0;

    // Get a reference to the linear proportion.
    uint256 _base = PRBMath.mulDiv(_currentOverflow, _tokenCount, _totalSupply);

    // These conditions are all part of the same curve. Edge conditions are separated because fewer operation are necessary.
    if (_redemptionRate == 10000) return _base;
    return
      PRBMath.mulDiv(
        _base,
        _redemptionRate + PRBMath.mulDiv(_tokenCount, 10000 - _redemptionRate, _totalSupply),
        10000
      );
  }

  /**
    @notice
    Gets the amount that is overflowing when measured from the specified funding cycle.

    @dev
    This amount changes as the price of ETH changes in relation to the funding cycle's currency.

    @param _fundingCycle The ID of the funding cycle to base the overflow on.

    @return overflow The overflow of funds.
  */
  function _overflowDuring(JBFundingCycle memory _fundingCycle) private view returns (uint256) {
    // Get the current balance of the project.
    uint256 _balanceOf = balanceOf[_fundingCycle.projectId];

    // If there's no balance, there's no overflow.
    if (_balanceOf == 0) return 0;

    // Get a reference to the amount still withdrawable during the funding cycle.
    uint256 _targetRemaining = _fundingCycle.target - _fundingCycle.tapped;

    // Convert the _targetRemaining to ETH.
    uint256 _ethTargetRemaining = _targetRemaining == 0
      ? 0 // Get the current price of ETH.
      : PRBMathUD60x18.div(
        _targetRemaining,
        prices.priceFor(_fundingCycle.currency, JBCurrencies.ETH)
      );

    // Overflow is the balance of this project minus the amount that can still be withdrawn.
    return _balanceOf < _ethTargetRemaining ? 0 : _balanceOf - _ethTargetRemaining;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBOperatable.sol';

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.
*/
abstract contract JBOperatable is IJBOperatable {
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    require(
      msg.sender == _account ||
        operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) ||
        operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex),
      'Operatable: UNAUTHORIZED'
    );
    _;
  }

  modifier requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) {
    require(
      _override ||
        msg.sender == _account ||
        operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) ||
        operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex),
      'Operatable: UNAUTHORIZED'
    );
    _;
  }

  /** 
    @notice 
    A contract storing operator assignments.
  */
  IJBOperatorStore public immutable override operatorStore;

  /** 
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBOperatorStore _operatorStore) {
    operatorStore = _operatorStore;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

enum JBBallotState {
  Approved,
  Active,
  Failed,
  Standby
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';
import './IJBTerminal.sol';
import './IJBFundingCycleStore.sol';

interface IJBController {
  function reservedTokenBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function prepForMigrationOf(uint256 _projectId, IJBController _from) external;

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    uint256 _reserveRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function signalWithdrawlFrom(uint256 _projectId, uint256 _amount)
    external
    returns (JBFundingCycle memory);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBTerminal _terminal
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBTerminal.sol';
import './IJBProjects.sol';
import './IJBController.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, IJBController indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBTerminal indexed terminal, address caller);

  event RemoveTerminal(uint256 indexed projectId, IJBTerminal indexed terminal, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBTerminal indexed terminal,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function controllerOf(uint256 _projectId) external view returns (IJBController);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBTerminal);

  function terminalsOf(uint256 _projectId) external view returns (IJBTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBTerminal _terminal) external view returns (bool);

  function isTerminalDelegateOf(uint256 _projectId, address _delegate) external view returns (bool);

  function addTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;

  function removeTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;

  function setControllerOf(uint256 _projectId, IJBController _controller) external;

  function setPrimaryTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBProjects.sol';
import './IJBDirectory.sol';
import './IJBSplitsStore.sol';
import './IJBFundingCycleStore.sol';
import './IJBPayDelegate.sol';
import './IJBTokenStore.sol';
import './IJBPrices.sol';
import './IJBRedemptionDelegate.sol';
import './IJBController.sol';

import './../structs/JBFee.sol';

interface IJBETHPaymentTerminal {
  event AddToBalance(uint256 indexed projectId, uint256 amount, string memo, address caller);
  event Migrate(uint256 indexed projectId, IJBTerminal indexed to, uint256 amount, address caller);
  event DistributePayouts(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    address projectOwner,
    uint256 amount,
    uint256 withdrawnAmount,
    uint256 feeAmount,
    uint256 projectOwnerDistributionAmount,
    string memo,
    address caller
  );

  event UseAllowance(
    uint256 indexed fundingCycleId,
    uint256 indexed configuration,
    uint256 indexed projectId,
    address beneficiary,
    uint256 amount,
    uint256 feeAmount,
    uint256 transferAmount,
    address caller
  );
  event ProcessFees(uint256 indexed projectId, JBFee[] fees, address caller);
  event Pay(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    address indexed beneficiary,
    JBFundingCycle fundingCycle,
    uint256 amount,
    uint256 weight,
    uint256 tokenCount,
    string memo,
    address caller
  );
  event RedeemTokens(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    address indexed holder,
    JBFundingCycle fundingCycle,
    address beneficiary,
    uint256 tokenCount,
    uint256 claimedAmount,
    string memo,
    address caller
  );
  event DistributeToPayoutSplit(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    JBSplit split,
    uint256 amount,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function heldFeesOf(uint256 _projectId) external view returns (JBFee[] memory);

  function distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedWei,
    string memory _memo
  ) external returns (uint256);

  function redeemTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _count,
    uint256 _minReturnedWei,
    address payable _beneficiary,
    string calldata _memo,
    bytes calldata _delegateMetadata
  ) external returns (uint256 claimedAmount);

  function useAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedWei,
    address payable _beneficiary
  ) external returns (uint256 fundingCycleNumber);

  function migrate(uint256 _projectId, IJBTerminal _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot {
  function duration() external view returns (uint256);

  function state(uint256 _fundingCycleId, uint256 _configured)
    external
    view
    returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';

import './IJBPayDelegate.sol';
import './IJBRedemptionDelegate.sol';

import './../structs/JBPayParamsData.sol';
import './../structs/JBRedeemParamsData.sol';

interface IJBFundingCycleDataSource {
  function payParams(JBPayParamsData calldata _param)
    external
    view
    returns (
      uint256 weight,
      string memory memo,
      IJBPayDelegate delegate,
      bytes memory delegateMetadata
    );

  function redeemParams(JBRedeemParamsData calldata _param)
    external
    view
    returns (
      uint256 amount,
      string memory memo,
      IJBRedemptionDelegate delegate,
      bytes memory delegateMetadata
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleBallot.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    uint256 indexed configured,
    JBFundingCycleData data,
    uint256 metadata,
    address caller
  );

  event Tap(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    uint256 amount,
    uint256 newTappedAmount,
    address caller
  );

  event Init(uint256 indexed fundingCycleId, uint256 indexed projectId, uint256 indexed basedOn);

  function latestIdOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _fundingCycleId) external view returns (JBFundingCycle memory);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _fee
  ) external returns (JBFundingCycle memory fundingCycle);

  function tapFrom(uint256 _projectId, uint256 _amount)
    external
    returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(JBOperatorData calldata _operatorData) external;

  function setOperators(JBOperatorData[] calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBDidPayData.sol';

interface IJBPayDelegate {
  function didPay(JBDidPayData calldata _param) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';

interface IJBPrices {
  event AddFeed(uint256 indexed currency, uint256 indexed base, AggregatorV3Interface feed);

  function TARGET_DECIMALS() external returns (uint256);

  function feedFor(uint256 _currency, uint256 _base) external returns (AggregatorV3Interface);

  function priceFor(uint256 _currency, uint256 _base) external view returns (uint256);

  function addFeedFor(
    uint256 _currency,
    uint256 _base,
    AggregatorV3Interface _priceFeed
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBTerminal.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    bytes32 indexed handle,
    string uri,
    address caller
  );

  event SetHandle(uint256 indexed projectId, bytes32 indexed handle, address caller);

  event SetUri(uint256 indexed projectId, string uri, address caller);

  event TransferHandle(
    uint256 indexed projectId,
    address indexed transferAddress,
    bytes32 indexed handle,
    bytes32 newHandle,
    address caller
  );

  event ClaimHandle(
    uint256 indexed projectId,
    address indexed transferAddress,
    bytes32 indexed handle,
    address caller
  );

  event ChallengeHandle(
    bytes32 indexed handle,
    uint256 indexed projectId,
    uint256 challengeExpiry,
    address caller
  );

  event RenewHandle(bytes32 indexed handle, uint256 indexed projectId, address caller);

  function count() external view returns (uint256);

  function uriOf(uint256 _projectId) external view returns (string memory);

  function handleOf(uint256 _projectId) external returns (bytes32 handle);

  function idFor(bytes32 _handle) external returns (uint256 projectId);

  function transferAddressFor(bytes32 _handle) external returns (address receiver);

  function challengeExpiryOf(bytes32 _handle) external returns (uint256);

  function createFor(
    address _owner,
    bytes32 _handle,
    string calldata _uri
  ) external returns (uint256 id);

  function setHandleOf(uint256 _projectId, bytes32 _handle) external;

  function setUriOf(uint256 _projectId, string calldata _uri) external;

  function transferHandleOf(
    uint256 _projectId,
    address _transferAddress,
    bytes32 _newHandle
  ) external returns (bytes32 _handle);

  function claimHandle(
    bytes32 _handle,
    address _for,
    uint256 _projectId
  ) external;

  function challengeHandle(bytes32 _handle) external;

  function renewHandleOf(uint256 _projectId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';

import './../structs/JBDidRedeemData.sol';

interface IJBRedemptionDelegate {
  function didRedeem(JBDidRedeemData calldata _param) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBSplitAllocator {
  event Allocate(
    uint256 indexed projectId,
    uint256 indexed forProjectId,
    address indexed beneficiary,
    uint256 amount,
    address caller
  );

  function allocate(
    uint256 _amount,
    uint256 _group,
    uint256 _projectId,
    uint256 _forProjectId,
    address _beneficiary,
    bool _preferClaimed
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';
import './IJBProjects.sol';
import './IJBDirectory.sol';
import './IJBSplitAllocator.sol';

import './../structs/JBSplit.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    JBSplit[] memory _splits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';
import './IJBVault.sol';

interface IJBTerminal {
  function token() external view returns (address);

  function ethBalanceOf(uint256 _projectId) external view returns (uint256);

  function delegate() external view returns (address);

  function pay(
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _delegateMetadata
  ) external payable returns (uint256 fundingCycleId);

  function addToBalanceOf(uint256 _projectId, string memory _memo) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IJBToken is IERC20 {
  function mint(
    address _account,
    uint256 _amount,
    uint256 _projectId
  ) external;

  function burn(
    address _account,
    uint256 _amount,
    uint256 _projectId
  ) external;

  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBProjects.sol';
import './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool tokensWereClaimed,
    bool preferClaimedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 unclaimedTokenBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(address indexed holder, uint256 indexed projectId, uint256 amount, address caller);

  event ShouldRequireClaim(uint256 indexed projectId, bool indexed flag, address caller);

  event ChangeToken(
    uint256 indexed projectId,
    IJBToken indexed token,
    address indexed owner,
    address caller
  );

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projects() external view returns (IJBProjects);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function requireClaimFor(uint256 _projectId) external view returns (bool);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function changeTokenOf(
    uint256 _projectId,
    IJBToken _token,
    address _newOwner
  ) external;

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function shouldRequireClaimingFor(uint256 _projectId, bool _flag) external;

  function claimFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferTo(
    address _recipient,
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBDirectory.sol';

interface IJBVault {
  event Deposit(uint256 indexed projectId, uint256 amount, address caller);
  event Withdraw(uint256 indexed projectId, uint256 amount, address to, address caller);

  function token() external view returns (address);

  function deposit(uint256 _projectId, uint256 _amount) external payable;

  function withdraw(
    uint256 _projectId,
    uint256 _amount,
    address payable _to
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBCurrencies {
  uint256 public constant ETH = 0;
  uint256 public constant USD = 1;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleStore.sol';
import './../interfaces/IJBFundingCycleDataSource.sol';
import './../structs/JBFundingCycleMetadata.sol';

library JBFundingCycleMetadataResolver {
  function reservedRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    return uint256(uint16(_fundingCycle.metadata >> 8));
  }

  function redemptionRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    return uint256(uint16(_fundingCycle.metadata >> 24));
  }

  function ballotRedemptionRate(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (uint256)
  {
    return uint256(uint16(_fundingCycle.metadata >> 32));
  }

  function payPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 40) & 1) == 0;
  }

  function withdrawalsPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 41) & 1) == 0;
  }

  function redeemPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 42) & 1) == 0;
  }

  function mintPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 43) & 1) == 0;
  }

  function burnPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 44) & 1) == 0;
  }

  function terminalMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 45) & 1) == 0;
  }

  function controllerMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 46) & 1) == 0;
  }

  function shouldHoldFees(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 47) & 1) == 0;
  }

  function useDataSourceForPay(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return (_fundingCycle.metadata >> 48) & 1 == 0;
  }

  function useDataSourceForRedeem(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return (_fundingCycle.metadata >> 49) & 1 == 0;
  }

  function dataSource(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (IJBFundingCycleDataSource)
  {
    return IJBFundingCycleDataSource(address(uint160(_fundingCycle.metadata >> 50)));
  }

  /**
    @notice
    Pack the funding cycle metadata.

    @param _metadata The metadata to validate and pack.

    @return packed The packed uint256 of all metadata params. The first 8 bytes specify the version.
  */
  function packFundingCycleMetadata(JBFundingCycleMetadata memory _metadata)
    internal
    pure
    returns (uint256 packed)
  {
    // version 1 in the first 8 bytes.
    packed = 1;
    // reserved rate in bits 8-15.
    packed |= _metadata.reservedRate << 8;
    // bonding curve in bits 16-23.
    packed |= _metadata.redemptionRate << 16;
    // reconfiguration bonding curve rate in bits 24-31.
    packed |= _metadata.ballotRedemptionRate << 24;
    // pause pay in bit 32.
    packed |= (_metadata.pausePay ? 1 : 0) << 32;
    // pause tap in bit 33.
    packed |= (_metadata.pauseWithdrawals ? 1 : 0) << 33;
    // pause redeem in bit 34.
    packed |= (_metadata.pauseRedeem ? 1 : 0) << 34;
    // pause mint in bit 35.
    packed |= (_metadata.pauseMint ? 1 : 0) << 35;
    // pause mint in bit 36.
    packed |= (_metadata.pauseBurn ? 1 : 0) << 36;
    // allow terminal migration in bit 37.
    packed |= (_metadata.allowTerminalMigration ? 1 : 0) << 37;
    // allow controller migration in bit 38.
    packed |= (_metadata.allowControllerMigration ? 1 : 0) << 38;
    // hold fees in bit 39.
    packed |= (_metadata.holdFees ? 1 : 0) << 39;
    // use pay data source in bit 40.
    packed |= (_metadata.useDataSourceForPay ? 1 : 0) << 40;
    // use redeem data source in bit 41.
    packed |= (_metadata.useDataSourceForRedeem ? 1 : 0) << 41;
    // data source address in bits 42-201.
    packed |= uint160(address(_metadata.dataSource)) << 42;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBOperations {
  uint256 public constant RECONFIGURE = 1;
  uint256 public constant PRINT_PREMINED_TOKENS = 2;
  uint256 public constant REDEEM = 3;
  uint256 public constant MIGRATE_CONTROLLER = 4;
  uint256 public constant MIGRATE_TERMINAL = 5;
  uint256 public constant PROCESS_FEES = 6;
  uint256 public constant SET_HANDLE = 7;
  uint256 public constant SET_URI = 8;
  uint256 public constant CLAIM_HANDLE = 9;
  uint256 public constant RENEW_HANDLE = 10;
  uint256 public constant ISSUE = 11;
  uint256 public constant CHANGE_TOKEN = 12;
  uint256 public constant MINT = 13;
  uint256 public constant BURN = 14;
  uint256 public constant TRANSFER = 15;
  uint256 public constant REQUIRE_CLAIM = 16;
  uint256 public constant SET_CONTROLLER = 17;
  uint256 public constant ADD_TERMINAL = 18;
  uint256 public constant REMOVE_TERMINAL = 19;
  uint256 public constant SET_PRIMARY_TERMINAL = 20;
  uint256 public constant USE_ALLOWANCE = 21;
  uint256 public constant SET_SPLITS = 22;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBSplitsGroups {
  uint256 public constant ETH_PAYOUT = 1;
  uint256 public constant RESERVED_TOKENS = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBDidPayData {
  // The address from which the payment originated.
  address payer;
  // The ID of the project for which the payment was made.
  uint256 projectId;
  // The amount of ETH that was paid.
  uint256 amount;
  // The weight that was used for minting tokens.
  uint256 weight;
  // The number of tokens minted.
  uint256 tokenCount;
  // The address to which the tokens were minted.
  address beneficiary;
  // The memo that is being emitted alongside the payment.
  string memo;
  // Metadata to send to the delegate.
  bytes delegateMetadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBDidRedeemData {
  // The holder of the tokens being redeemed.
  address holder;
  // The project to which the redeemed tokens are associated.
  uint256 projectId;
  // The number of tokens being redeemed.
  uint256 tokenCount;
  // The amount of ETH being claimed.
  uint256 claimAmount;
  // The address to which the ETH will be sent.
  address payable beneficiary;
  // The memo that is being emitted alongside the redemption.
  string memo;
  // Metadata to send to the delegate.
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBFee {
  // The amount of the fee.
  uint256 amount;
  // The address that will receive the tokens that are minted as a result of the fee payment.
  address beneficiary;
  // The memo that should be emitted alongside the fee payment.
  string memo;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

/// @notice The funding cycle structure represents a project stewarded by an address, and accounts for which addresses have helped sustain the project.
struct JBFundingCycle {
  // A unique number that's incremented for each new funding cycle, starting with 1.
  uint256 id;
  // The ID of the project contract that this funding cycle belongs to.
  uint256 projectId;
  // The number of this funding cycle for the project.
  uint256 number;
  // The ID of a previous funding cycle that this one is based on.
  uint256 basedOn;
  // The time when this funding cycle was last configured.
  uint256 configured;
  // A number determining the amount of redistribution shares this funding cycle will issue to each sustainer.
  uint256 weight;
  // The ballot contract to use to determine a subsequent funding cycle's reconfiguration status.
  IJBFundingCycleBallot ballot;
  // The time when this funding cycle will become active.
  uint256 start;
  // The number of seconds until this funding cycle's surplus is redistributed.
  uint256 duration;
  // The amount that this funding cycle is targeting in terms of the currency.
  uint256 target;
  // The currency that the target is measured in.
  uint256 currency;
  // The percentage of each payment to send as a fee to the Juicebox admin.
  uint256 fee;
  // A percentage indicating how much more weight to give a funding cycle compared to its predecessor.
  uint256 discountRate;
  // The amount of available funds that have been tapped by the project in terms of the currency.
  uint256 tapped;
  // A packed list of extra data. The first 8 bytes are reserved for versioning.
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycleData {
  // The target of the funding cycle.
  uint256 target;
  // The currency of the funding cycle. 0 is ETH, 1 is USD.
  uint256 currency;
  // The duration of the funding cycle.
  uint256 duration;
  // The discount rate of the funding cycle.
  uint256 discountRate;
  // The weight of the funding cycle. Send a weight of 1 to set a minimum.
  uint256 weight;
  // The ballot of the funding cycle.
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleDataSource.sol';

struct JBFundingCycleMetadata {
  // The reserved rate of the funding cycle.
  uint256 reservedRate;
  // The redemption rate of the funding cycle.
  uint256 redemptionRate;
  // The redemption rate to use during an active ballot of the funding cycle.
  uint256 ballotRedemptionRate;
  // If the pay functionality should be paused during the funding cycle.
  bool pausePay;
  // If the withdraw functionality should be paused during the funding cycle.
  bool pauseWithdrawals;
  // If the redeem functionality should be paused during the funding cycle.
  bool pauseRedeem;
  // If the mint functionality should be paused during the funding cycle.
  bool pauseMint;
  // If the burn functionality should be paused during the funding cycle.
  bool pauseBurn;
  // If migrating terminals should be allowed during this funding cycle.
  bool allowTerminalMigration;
  // If migrating controllers should be allowed during this funding cycle.
  bool allowControllerMigration;
  // If fees should be held during this funding cycle.
  bool holdFees;
  // If the data source should be used for pay transactions during this funding cycle.
  bool useDataSourceForPay;
  // If the data source should be used for redeem transactions during this funding cycle.
  bool useDataSourceForRedeem;
  // The data source to use during this funding cycle.
  IJBFundingCycleDataSource dataSource;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBOperatorData {
  // The address of the operator.
  address operator;
  // The domain within which the operator is being given permissions.
  uint256 domain;
  // The indexes of the permissions the operator is being given.
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBPayParamsData {
  // The address from which the payment originated.
  address payer;
  // The ETH amount of the payment.
  uint256 amount;
  // The weight of the funding cycle during which the payment is being made.
  uint256 weight;
  // The reserved rate of the funding cycle during which the payment is being made.
  uint256 reservedRate;
  // The proposed beneficiary of the tokens that will be minted as a result of the tokens.
  address beneficiary;
  // The proposed memo that is being emitted alongside the payment.
  string memo;
  // The proposed metadata to send to the delegate.
  bytes delegateMetadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBRedeemParamsData {
  // The holder of the tokens being redeemed.
  address holder;
  // The proposed number of tokens being redeemed.
  uint256 tokenCount;
  // The redemption rate of the funding cycle during which the redemption is being made.
  uint256 redemptionRate;
  // The ballot redemption rate of the funding cycle during which the redemption is being made.
  uint256 ballotRedemptionRate;
  // The proposed beneficiary of the ETH being claimed by making the redemption.
  address beneficiary;
  // The proposed memo that is being emitted alongside the redemption.
  string memo;
  // The proposed metadata to send to the delegate.
  bytes delegateMetadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBSplitAllocator.sol';

struct JBSplit {
  // A flag that only has effect if a projectId is also specified, and that project has issued its tokens.
  // If so, this flag indicates if the tokens that result from making a payment to the project should be delivered staked or unstaked to the beneficiary.
  bool preferClaimed;
  // The percent of the whole group that this split occupies. This number is out of 10000000.
  uint24 percent;
  // Specifies if the split should be unchangeable until the specifies time comes, with the exception of extending the lockedUntil period.
  uint48 lockedUntil;
  // The role the  beneficary depends on whether or not projectId is specified, or whether or not allocator is specified.
  // If allocator is set, the beneficiary will be forwarded to the allocator for it to use.
  // If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it.
  // If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  address payable beneficiary;
  // If an allocator is specified, funds will be sent to the allocator contract along with the projectId, beneficiary, preferClaimed properties.
  IJBSplitAllocator allocator;
  // If an allocator is not set but a projectId is set, funds will be sent to the Juicebox treasury belonging to the project who's ID is specified.
  // Resulting tokens will be routed to the beneficiary with the unstaked token prerence respected.
  uint56 projectId;
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculting the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculting the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explictly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding towards zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}