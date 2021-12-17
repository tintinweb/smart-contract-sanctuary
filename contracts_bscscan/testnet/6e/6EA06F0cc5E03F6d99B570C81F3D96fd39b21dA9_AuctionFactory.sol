// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Create2.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../interfaces/IAuctionFactory.sol';
import '../interfaces/IAuction.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

pragma solidity 0.8.8;

/// @title Auction
/// @notice AuctionFactory creates and manages Auction contracts
contract Auction is IAuction, ReentrancyGuard {
  using SafeERC20 for IERC20;

  constructor() {
    _factory = IAuctionFactory(msg.sender);
    mvl = IERC20(_factory.getMvlAddress());
  }

  uint256 internal _startTimestamp;
  uint256 internal _endTimestamp;
  uint256 internal _mintAmount;
  uint256 internal _floorPrice;
  uint256 internal _auctionId;

  uint256 internal _criteria;

  mapping(bytes12 => Bid) internal _bids;
  mapping(bytes12 => bytes12) internal _nextBids;
  uint256 public totalBid;
  bytes12 constant BASE = '1';

  IERC20 public immutable mvl;

  IAuctionFactory internal _factory;

  modifier underway() {
    if (getAuctionState() != State.ACTIVE) revert AuctionNotInProgress();
    _;
  }

  modifier ended() {
    if (getAuctionState() != State.END) revert AuctionNotEnded();
    _;
  }

  modifier onlyFactory() {
    if (msg.sender != address(_factory)) revert NotAuthorized();
    _;
  }

  modifier owner(bytes12 bid) {
    if (msg.sender != _bids[bid].owner) revert NotBidOwner();
    _;
  }

  /// @notice Initialize function
  function initialize(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice,
    uint256 auctionId
  ) external onlyFactory {
    _startTimestamp = startTimestamp;
    _endTimestamp = endTimestamp;
    _mintAmount = mintAmount;
    _floorPrice = floorPrice;
    _auctionId = auctionId;

    _nextBids[BASE] = BASE;
  }

  /// View Functions ///

  /// @notice This function returns current state of this auction.
  ///  If the criteria is 0, auction is always pending
  /// @return state The state of the auction
  function getAuctionState() public view returns (State state) {
    if (_criteria == 0) {
      return State.PENDING;
    }

    if (block.timestamp < _startTimestamp) {
      state = State.PENDING;
    } else if (block.timestamp > _endTimestamp) {
      state = State.END;
    } else {
      state = State.ACTIVE;
    }
  }

  /// @notice This function returns the information of the this auction
  /// @return startTimestamp Auction start timestamp
  /// @return endTimestamp Auction end timestamp
  /// @return mintAmount Amount to mint
  /// @return floorPrice Basis point of this auction
  /// @return auctionId Currend id of this auction
  /// @return criteria Currend id of this auction
  function getAuctionInformation()
    external
    view
    returns (
      uint256 startTimestamp,
      uint256 endTimestamp,
      uint256 mintAmount,
      uint256 floorPrice,
      uint256 auctionId,
      uint256 criteria
    )
  {
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    mintAmount = _mintAmount;
    floorPrice = _floorPrice;
    auctionId = _auctionId;
    criteria = _criteria;
  }

  /// @notice This function returns the bid amount of the given bid id
  /// @param bid The address of the user
  /// @return bidAmount The price user bids
  function getBiddingPrice(bytes12 bid) external view returns (uint256 bidAmount) {
    bidAmount = _bids[bid].amount;
  }

  function getBidOwner(bytes12 bid) external view returns (address owner_) {
    owner_ = _bids[bid].owner;
  }

  /// @notice This function returns a list of addresses who bid in ascending order of the bid amount
  /// @param k The length of the result
  function getMultiBids(uint256 k) public view returns (Bid[] memory) {
    if (k > totalBid) revert SurpassTotalBidder();
    Bid[] memory bidList = new Bid[](k);
    bytes12 currentId = _nextBids[BASE];
    for (uint256 i = 0; i < k; ++i) {
      bidList[i] = _bids[currentId];
      currentId = _nextBids[currentId];
    }
    return bidList;
  }

  /// @notice This function returns a list of amounts which user bid in ascending order of the bid amount
  /// @param k The length of the list to check
  function getMultiBidAmount(uint256 k) public view returns (uint256[] memory) {
    if (k > totalBid) revert SurpassTotalBidder();
    uint256[] memory bidAmountList = new uint256[](k);
    bytes12 currentId = _nextBids[BASE];
    for (uint256 i = 0; i < k; ++i) {
      bidAmountList[i] = _bids[currentId].amount;
      currentId = _nextBids[currentId];
    }
    return bidAmountList;
  }

  /// @notice This function returns a list of the accounts who are the winner of this auction
  /// The number of the winner depends on the `_mintAmount`
  function getWinBids() external view returns (Bid[] memory) {
    if (totalBid <= _mintAmount) {
      return getMultiBids(totalBid);
    }
    return getMultiBids(_mintAmount);
  }

  /// @notice This function returns a list of the bid amounts of the accounts who are the winner of this auction
  /// The number of the winner depends on the `_mintAmount`
  function getWinBidAmounts() external view returns (uint256[] memory) {
    if (totalBid <= _mintAmount) {
      return getMultiBidAmount(totalBid);
    }
    return getMultiBidAmount(_mintAmount);
  }

  /// User Functions ///

  /// @notice User can bid by executing this function
  /// Each bids are stored as `Bid` struct.
  /// When user call this function, Bid created and stored in linked list-like map
  /// @param amount amount to place
  function placeBid(uint256 amount) external nonReentrant underway {
    bytes12 bid = _generateBidId(amount);

    if (_bids[bid].owner != address(0)) revert AlreadyExist();

    _placeBid(bid, amount);

    mvl.transferFrom(msg.sender, address(this), amount);
  }

  /// @notice users can place differenct bid. Asset transfers.
  /// msg.sender must be a owner of the given bid id
  /// @param bid The id of the bid to update
  /// @param amount The amount to update
  function updateBid(bytes12 bid, uint256 amount) external nonReentrant underway owner(bid) {
    Bid memory beforeBid = _bids[bid];

    if (beforeBid.amount == amount) revert NotSameAmount();

    if (beforeBid.amount < amount) {
      mvl.transferFrom(msg.sender, address(this), amount - beforeBid.amount);
    } else {
      mvl.transfer(msg.sender, beforeBid.amount - amount);
    }

    _updateBid(bid, amount);
  }

  /// @notice User can cancel their bid
  /// msg.sender must be a owner of the given bid id
  /// @param bid The id of the bid to cancel
  function cancelBid(bytes12 bid) external nonReentrant underway owner(bid) {
    Bid memory beforeBid = _bids[bid];

    _removeAccount(bid);

    mvl.transfer(msg.sender, beforeBid.amount);

    emit CancelBid(msg.sender, totalBid);
  }

  /// @notice After the auction ended, user who failed to win the bid can refund their bid amount
  function refundBid(bytes12 bid) external nonReentrant ended owner(bid) {
    if (_isWinningBid(bid) == true) revert WinBidRefundNotAlowed();

    Bid memory beforeBid = _bids[bid];

    _bids[bid].amount = 0;
    _bids[bid].owner = address(0);

    mvl.transfer(msg.sender, beforeBid.amount);

    emit RefundBid(msg.sender, bid, beforeBid.amount);
  }

  /// Admin Functions ///

  /// @notice admin can stop current auction by setting _endTimestamp to block.timestamp
  function emergencyStop() external onlyFactory {
    _endTimestamp = block.timestamp;
  }

  // function refund
  function transferAsset(address bid, uint256 amount) external onlyFactory {
    _transferAsset(bid, amount);
  }

  /// @notice Set criteria for the auction
  function setCriteria(uint256 currentMvlPrice) external onlyFactory {
    _criteria = (_floorPrice * currentMvlPrice) / 1e18;
  }

  /// Internal Functions ///

  function _generateBidId(uint256 salt) internal view returns (bytes12) {
    return bytes12(keccak256(abi.encodePacked(msg.sender, block.timestamp, salt)));
  }

  function _placeBid(bytes12 bid, uint256 amount) internal {
    require(_nextBids[bid] == bytes12(0), 'Already placed');
    bytes12 index = _findIndex(amount);

    Bid storage _bid = _bids[bid];

    _bid.amount = amount;
    _bid.owner = msg.sender;

    _nextBids[bid] = _nextBids[index];
    _nextBids[index] = bid;

    totalBid++;

    emit PlaceBid(msg.sender, bid, amount, totalBid);
  }

  function _updateBid(bytes12 bid, uint256 newBid) internal {
    require(_nextBids[bid] != bytes12(0), 'Not placed bid');
    bytes12 previousAccount = _findPreviousAccount(bid);
    bytes12 nextAccount = _nextBids[bid];
    if (_verifyIndex(previousAccount, newBid, nextAccount)) {
      _bids[bid].amount = newBid;
    } else {
      _removeAccount(bid);
      _placeBid(bid, newBid);
    }

    emit UpdateBid(msg.sender, bid, newBid, totalBid);
  }

  function _removeAccount(bytes12 bid) internal {
    require(_nextBids[bid] != bytes12(0));
    bytes12 previousAccount = _findPreviousAccount(bid);
    _nextBids[previousAccount] = _nextBids[bid];
    _nextBids[bid] = bytes12(0);
    _bids[bid].amount = 0;
    totalBid--;
  }

  function _verifyIndex(
    bytes12 previousAccount,
    uint256 newValue,
    bytes12 nextAccount
  ) internal view returns (bool) {
    return
      (previousAccount == BASE || _bids[previousAccount].amount >= newValue) &&
      (nextAccount == BASE || newValue > _bids[nextAccount].amount);
  }

  function _findIndex(uint256 newValue) internal view returns (bytes12) {
    bytes12 candidateAddress = BASE;
    while (true) {
      if (_verifyIndex(candidateAddress, newValue, _nextBids[candidateAddress]))
        return candidateAddress;
      candidateAddress = _nextBids[candidateAddress];
    }
  }

  function _isPreviousAccount(bytes12 bid, bytes12 previousBid) internal view returns (bool) {
    return _nextBids[previousBid] == bid;
  }

  function _findPreviousAccount(bytes12 bid) internal view returns (bytes12) {
    bytes12 currentId = BASE;
    while (_nextBids[currentId] != BASE) {
      if (_isPreviousAccount(bid, currentId)) return currentId;
      currentId = _nextBids[currentId];
    }
    return bytes12(0);
  }

  function _isWinningBid(bytes12 bid) internal view returns (bool) {
    bytes12 currentId = _nextBids[BASE];
    for (uint256 i = 0; i < _mintAmount; ++i) {
      if (bid == currentId) {
        return true;
      }
      currentId = _nextBids[currentId];
    }
    return false;
  }

  function _transferAsset(address account, uint256 amount) internal {
    mvl.safeTransfer(account, amount);
  }
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Create2.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Auction.sol';
import '../interfaces/IAuctionFactory.sol';
import '../interfaces/IAuction.sol';
import '../interfaces/IMvlPriceOracle.sol';

pragma solidity 0.8.8;

error LengthMismatch();

/// @title AuctionFactory
/// @notice AuctionFactory creates and manages Auction contracts
contract AuctionFactory is IAuctionFactory, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter internal _auctionIds;

  mapping(uint256 => address) auctions;

  IERC20 internal _mvl;
  IMvlPriceOracle internal _mvlOracle;

  constructor(address mvl_) {
    _mvl = IERC20(mvl_);
  }

  function setMvlOracle(address mvlOracle) external onlyOwner {
    _mvlOracle = IMvlPriceOracle(mvlOracle);
  }

  function getMvlOracle() public view returns (address mvlOracle) {
    mvlOracle = address(_mvlOracle);
  }

  function getMvlAddress() public view returns (address mvlAddress) {
    mvlAddress = address(_mvl);
  }

  function getAuctionAddress(uint256 id) public view returns (address auction) {
    auction = auctions[id];
  }

  /// @notice Admin can create auction contract with Create2
  /// @param startTimestamp Auction start timestamp
  /// @param endTimestamp Auction end timestamp
  /// @param mintAmount The number of the winner
  /// @param floorPrice Floor price in USD. It will be used for setting mvl criteria
  function createAuction(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice
  ) external onlyOwner {
    uint256 auctionId = _auctionIds.current();

    if (startTimestamp >= endTimestamp) revert InvalidTimestamps();
    if (block.timestamp >= endTimestamp) revert FinishedAuction();

    bytes32 salt = keccak256(
      abi.encodePacked(startTimestamp, endTimestamp, mintAmount, floorPrice, auctionId)
    );

    address auctionAddress = Create2.deploy(0, salt, type(Auction).creationCode);

    auctions[auctionId] = auctionAddress;

    IAuction(auctionAddress).initialize(
      startTimestamp,
      endTimestamp,
      mintAmount,
      floorPrice,
      auctionId
    );

    _auctionIds.increment();

    emit AuctionCreated(
      auctionAddress,
      auctionId,
      startTimestamp,
      endTimestamp,
      mintAmount,
      floorPrice
    );
  }

  function emergencyStop(uint256 auctionId) external onlyOwner {}

  function transferAuctionAsset(
    uint256 auctionId,
    address account,
    uint256 amount
  ) external onlyOwner {
    return _transferAuctionAsset(auctionId, account, amount);
  }

  function transferAuctionAssetBatch(
    uint256 auctionId,
    address[] memory accounts,
    uint256[] memory amounts
  ) external onlyOwner {
    if (accounts.length != amounts.length) revert LengthMismatch();

    for (uint256 i = 0; i < accounts.length; ++i) {
      _transferAuctionAsset(auctionId, accounts[i], amounts[i]);
    }
  }

  function _transferAuctionAsset(
    uint256 auctionId,
    address account,
    uint256 amount
  ) internal {
    IAuction(auctions[auctionId]).transferAsset(account, amount);
  }

  function setCriteria(uint256 auctionId) external onlyOwner {
    IAuction(auctions[auctionId]).setCriteria(_mvlOracle.getCurrentWeightedAveragePrice());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

error AuctionNotInProgress();
error AuctionNotEnded();
error NotAuthorized();
error NotBidBefore();
error NotSameAmount();
error SurpassTotalBidder();
error NotBidOwner();
error AlreadyExist();
error WinBidRefundNotAlowed();

struct Bid {
  address owner;
  uint256 amount;
}

/// @title AuctionFactory
/// @notice AuctionFactory creates and manages Auction contracts
interface IAuction {
  event PlaceBid(address indexed account, bytes12 bid, uint256 amount, uint256 totalBid);

  event UpdateBid(address indexed account, bytes12 bid, uint256 newBid, uint256 totalBid);

  event CancelBid(address indexed account, uint256 totalBid);

  event RefundBid(address indexed account, bytes12 bid, uint256 amount);

  enum State {
    PENDING,
    ACTIVE,
    END
  }

  function initialize(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice,
    uint256 auctionId
  ) external;

  /// View Functions ///

  function getAuctionState() external view returns (State state);

  function getAuctionInformation()
    external
    view
    returns (
      uint256 startTimestamp,
      uint256 endTimestamp,
      uint256 mintAmount,
      uint256 floorPrice,
      uint256 auctionId,
      uint256 criteria
    );

  function getBiddingPrice(bytes12 bid) external view returns (uint256 bidAmount);

  function getBidOwner(bytes12 bid) external view returns (address owner_);

  function getMultiBids(uint256 k) external view returns (Bid[] memory);

  function getMultiBidAmount(uint256 k) external view returns (uint256[] memory);

  function getWinBids() external view returns (Bid[] memory);

  function getWinBidAmounts() external view returns (uint256[] memory);

  /// User Functions ///

  /// @notice User can bid by executing this function
  function placeBid(uint256 amount) external;

  function updateBid(bytes12 bid, uint256 amount) external;

  function cancelBid(bytes12 bid) external;

  function refundBid(bytes12 bid) external;

  /// Admin Functions ///
  function emergencyStop() external;

  function transferAsset(address account, uint256 amount) external;

  /// @notice Set criteria for the auction
  function setCriteria(uint256 currentMvlPrice) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

error InvalidTimestamps();
error FinishedAuction();

interface IAuctionFactory {
  event AuctionCreated(
    address indexed auctionAddress,
    uint256 auctionId,
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice
  );

  /// @notice Returns mvl token contract address
  function getMvlAddress() external view returns (address mvlAddress);

  /// @notice Return the address of the auction corresponded to the given id
  function getAuctionAddress(uint256 id) external view returns (address auction);

  /// @notice Deploy new auction contract with `Create2`.
  function createAuction(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice
  ) external;

  function emergencyStop(uint256 auctionId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

interface IMvlPriceOracle {
  function getCurrentWeightedAveragePrice() external view returns (uint256 price);

  function getCurrentPrice() external view returns (uint256 currentPrice);

  function setCurrentPrice(uint256 price) external;

  function getMaxCount() external view returns (uint256 maxCount);

  function setMaxCount(uint256 maxCount) external;

  function resetCount() external;
}