// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Bank.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BankFactory is Ownable {
    /*Variables*/
    struct BankTag {
        address bankAddress;
    }

    address public bankAddress;
    BankTag[] private _banks;

    event BankCreated(address newBankAddress, address owner);

    constructor(address _bankAddress) {
        bankAddress = _bankAddress;
    }

    function createBank(
        string memory name,
        uint256 interestRate,
        uint256 originationFee,
        uint256 collateralizationRatio,
        uint256 liquidationPenalty,
        uint256 period,
        address payable oracleAddress
    ) public {
        address clone = Clones.clone(bankAddress);
        Bank(clone).init(
            msg.sender,
            name,
            interestRate,
            originationFee,
            collateralizationRatio,
            liquidationPenalty,
            period,
            owner(),
            oracleAddress
        );
        BankTag memory newBankTag = BankTag(clone);
        _banks.push(newBankTag);
        emit BankCreated(clone, msg.sender);
    }

    function getNumberOfBanks() public view returns (uint256) {
        return _banks.length;
    }

    function getBankAddressAtIndex(uint256 index)
        public
        view
        returns (address)
    {
        BankTag storage bank = _banks[index];
        return bank.bankAddress;
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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

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
pragma solidity ^0.8.0;

interface ITellor {
    /**
     * @dev Helps initialize a dispute by assigning it a disputeId
     * when a miner returns a false on the validate array(in Tellor.ProofOfWork) it sends the
     * invalidated value information to POS voting
     * @param _requestId being disputed
     * @param _timestamp being disputed
     * @param _minerIndex the index of the miner that submitted the value being disputed. Since each official value
     * requires 5 miners to submit a value.
     */
    function beginDispute(
        uint256 _requestId,
        uint256 _timestamp,
        uint256 _minerIndex
    ) external;

    /**
     * @dev Allows token holders to vote
     * @param _disputeId is the dispute id
     * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
     */
    function vote(uint256 _disputeId, bool _supportsDispute) external;

    /**
     * @dev tallies the votes.
     * @param _disputeId is the dispute id
     */
    function tallyVotes(uint256 _disputeId) external;

    /**
     * @dev Allows for a fork to be proposed
     * @param _propNewTellorAddress address for new proposed Tellor
     */
    function proposeFork(address _propNewTellorAddress) external;

    /**
     * @dev Add tip to Request value from oracle
     * @param _requestId being requested to be mined
     * @param _tip amount the requester is willing to pay to be get on queue. Miners
     * mine the onDeckQueryHash, or the api with the highest payout pool
     */
    function addTip(uint256 _requestId, uint256 _tip) external;

    /**
     * @dev This is called by the miner when they submit the PoW solution (proof of work and value)
     * @param _nonce uint submitted by miner
     * @param _requestId the apiId being mined
     * @param _value of api query
     *
     */
    function submitMiningSolution(
        string calldata _nonce,
        uint256 _requestId,
        uint256 _value
    ) external;

    /**
     * @dev This is called by the miner when they submit the PoW solution (proof of work and value)
     * @param _nonce uint submitted by miner
     * @param _requestId is the array of the 5 PSR's being mined
     * @param _value is an array of 5 values
     */
    function submitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestId,
        uint256[5] calldata _value
    ) external;

    /**
     * @dev Allows the current owner to propose transfer control of the contract to a
     * newOwner and the ownership is pending until the new owner calls the claimOwnership
     * function
     * @param _pendingOwner The address to transfer ownership to.
     */
    function proposeOwnership(address payable _pendingOwner) external;

    /**
     * @dev Allows the new owner to claim control of the contract
     */
    function claimOwnership() external;

    /**
     * @dev This function allows miners to deposit their stake.
     */
    function depositStake() external;

    /**
     * @dev This function allows stakers to request to withdraw their stake (no longer stake)
     * once they lock for withdraw(stakes.currentStatus = 2) they are locked for 7 days before they
     * can withdraw the stake
     */
    function requestStakingWithdraw() external;

    /**
     * @dev This function allows users to withdraw their stake after a 7 day waiting period from request
     */
    function withdrawStake() external;

    /**
     * @dev This function approves a _spender an _amount of tokens to use
     * @param _spender address
     * @param _amount amount the spender is being approved for
     * @return true if spender appproved successfully
     */
    function approve(address _spender, uint256 _amount) external returns (bool);

    /**
     * @dev Allows for a transfer of tokens to _to
     * @param _to The address to send tokens to
     * @param _amount The amount of tokens to send
     * @return true if transfer is successful
     */
    function transfer(address _to, uint256 _amount) external returns (bool);

    /**
     * @dev Sends _amount tokens to _to from _from on the condition it
     * is approved by _from
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     * @return True if the transfer was successful
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    /**
     * @dev Allows users to access the token's name
     */
    function name() external pure returns (string memory);

    /**
     * @dev Allows users to access the token's symbol
     */
    function symbol() external pure returns (string memory);

    /**
     * @dev Allows users to access the number of decimals
     */
    function decimals() external pure returns (uint8);

    /**
     * @dev Getter for the current variables that include the 5 requests Id's
     * @return _challenge _requestIds _difficultky _tip the challenge, 5 requestsId, difficulty and tip
     */
    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _challenge,
            uint256[5] memory _requestIds,
            uint256 _difficutly,
            uint256 _tip
        );

    /**
     * @dev Getter for the top tipped 5 requests Id's
     * @return _requestIds the 5 requestsId
     */
    function getTopRequestIDs()
        external
        view
        returns (uint256[5] memory _requestIds);

    /**
     * @dev Getter for the 5 requests Id's next in line to get mined
     * @return idsOnDeck tipsOnDeck  the 5 requestsId
     */
    function getNewVariablesOnDeck()
        external
        view
        returns (uint256[5] memory idsOnDeck, uint256[5] memory tipsOnDeck);

    /**
     * @dev Updates the Tellor address after a proposed fork has
     * passed the vote and day has gone by without a dispute
     * @param _disputeId the disputeId for the proposed fork
     */
    function updateTellor(uint256 _disputeId) external;

    /**
     * @dev Allows disputer to unlock the dispute fee
     * @param _disputeId to unlock fee from
     */
    function unlockDisputeFee(uint256 _disputeId) external;

    /**
     * @param _user address
     * @param _spender address
     * @return Returns the remaining allowance of tokens granted to the _spender from the _user
     */
    function allowance(address _user, address _spender)
        external
        view
        returns (uint256);

    /**
     * @dev This function returns whether or not a given user is allowed to trade a given amount
     * @param _user address
     * @param _amount uint of amount
     * @return true if the user is alloed to trade the amount specified
     */
    function allowedToTrade(address _user, uint256 _amount)
        external
        view
        returns (bool);

    /**
     * @dev Gets balance of owner specified
     * @param _user is the owner address used to look up the balance
     * @return Returns the balance associated with the passed in _user
     */
    function balanceOf(address _user) external view returns (uint256);

    /**
     * @dev Queries the balance of _user at a specific _blockNumber
     * @param _user The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at _blockNumber
     */
    function balanceOfAt(address _user, uint256 _blockNumber)
        external
        view
        returns (uint256);

    /**
     * @dev This function tells you if a given challenge has been completed by a given miner
     * @param _challenge the challenge to search for
     * @param _miner address that you want to know if they solved the challenge
     * @return true if the _miner address provided solved the
     */
    function didMine(bytes32 _challenge, address _miner)
        external
        view
        returns (bool);

    /**
     * @dev Checks if an address voted in a given dispute
     * @param _disputeId to look up
     * @param _address to look up
     * @return bool of whether or not party voted
     */
    function didVote(uint256 _disputeId, address _address)
        external
        view
        returns (bool);

    /**
     * @dev allows Tellor to read data from the addressVars mapping
     * @param _data is the keccak256("variable_name") of the variable that is being accessed.
     * These are examples of how the variables are saved within other functions:
     * addressVars[keccak256("_owner")]
     * addressVars[keccak256("tellorContract")]
     * return address
     */
    function getAddressVars(bytes32 _data) external view returns (address);

    /**
     * @dev Gets all dispute variables
     * @param _disputeId to look up
     * @return bytes32 hash of dispute
     * @return bool executed where true if it has been voted on
     * @return bool disputeVotePassed
     * @return bool isPropFork true if the dispute is a proposed fork
     * @return address of reportedMiner
     * @return address of reportingParty
     * @return address of proposedForkAddress
     *    uint of requestId
     *    uint of timestamp
     *    uint of value
     *    uint of minExecutionDate
     *    uint of numberOfVotes
     *    uint of blocknumber
     *    uint of minerSlot
     *    uint of quorum
     *    uint of fee
     * @return int count of the current tally
     */
    function getAllDisputeVars(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        );

    /**
     * @dev Getter function for variables for the requestId being currently mined(currentRequestId)
     * @return current challenge, curretnRequestId, level of difficulty, api/query string, and granularity(number of decimals requested), total tip for the request
     */
    function getCurrentVariables()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256,
            string memory,
            uint256,
            uint256
        );

    /**
     * @dev Checks if a given hash of miner,requestId has been disputed
     * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId));
     * @return uint disputeId
     */
    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        returns (uint256);

    /**
     * @dev Checks for uint variables in the disputeUintVars mapping based on the disuputeId
     * @param _disputeId is the dispute id;
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the disputeUintVars under the Dispute struct
     * @return uint value for the bytes32 data submitted
     */
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
        external
        view
        returns (uint256);

    /**
     * @dev Gets the a value for the latest timestamp available
     * @return value for timestamp of last proof of work submited
     * @return true if the is a timestamp for the lastNewValue
     */
    function getLastNewValue() external view returns (uint256, bool);

    /**
     * @dev Gets the a value for the latest timestamp available
     * @param _requestId being requested
     * @return value for timestamp of last proof of work submited and if true if it exist or 0 and false if it doesn't
     */
    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool);

    /**
     * @dev Gets blocknumber for mined timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up blocknumber
     * @return uint of the blocknumber which the dispute was mined
     */
    function getMinedBlockNum(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256);

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return the 5 miners' addresses
     */
    function getMinersByRequestIdAndTimestamp(
        uint256 _requestId,
        uint256 _timestamp
    ) external view returns (address[5] memory);

    /**
     * @dev Counts the number of values that have been submited for the request
     * if called for the currentRequest being mined it can tell you how many miners have submitted a value for that
     * request so far
     * @param _requestId the requestId to look up
     * @return uint count of the number of values received for the requestId
     */
    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        returns (uint256);

    /**
     * @dev Getter function for the specified requestQ index
     * @param _index to look up in the requestQ array
     * @return uint of reqeuestId
     */
    function getRequestIdByRequestQIndex(uint256 _index)
        external
        view
        returns (uint256);

    /**
     * @dev Getter function for requestId based on timestamp
     * @param _timestamp to check requestId
     * @return uint of reqeuestId
     */
    function getRequestIdByTimestamp(uint256 _timestamp)
        external
        view
        returns (uint256);

    /**
     * @dev Getter function for requestId based on the queryHash
     * @param _request is the hash(of string api and granularity) to check if a request already exists
     * @return uint requestId
     */
    function getRequestIdByQueryHash(bytes32 _request)
        external
        view
        returns (uint256);

    /**
     * @dev Getter function for the requestQ array
     * @return the requestQ arrray
     */
    function getRequestQ() external view returns (uint256[51] memory);

    /**
     * @dev Allowes access to the uint variables saved in the apiUintVars under the requestDetails struct
     * for the requestId specified
     * @param _requestId to look up
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the apiUintVars under the requestDetails struct
     * @return uint value of the apiUintVars specified in _data for the requestId specified
     */
    function getRequestUintVars(uint256 _requestId, bytes32 _data)
        external
        view
        returns (uint256);

    /**
     * @dev Gets the API struct variables that are not mappings
     * @param _requestId to look up
     * @return string of api to query
     * @return string of symbol of api to query
     * @return bytes32 hash of string
     * @return bytes32 of the granularity(decimal places) requested
     * @return uint of index in requestQ array
     * @return uint of current payout/tip for this requestId
     */
    function getRequestVars(uint256 _requestId)
        external
        view
        returns (
            string memory,
            string memory,
            bytes32,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev This function allows users to retireve all information about a staker
     * @param _staker address of staker inquiring about
     * @return uint current state of staker
     * @return uint startDate of staking
     */
    function getStakerInfo(address _staker)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestampt to look up miners for
     * @return address[5] array of 5 addresses ofminers that mined the requestId
     */
    function getSubmissionsByTimestamp(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256[5] memory);

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _requestID is the requestId to look up
     * @param _index is the value index to look up
     * @return uint timestamp
     */
    function getTimestampbyRequestIDandIndex(uint256 _requestID, uint256 _index)
        external
        view
        returns (uint256);

    /**
     * @dev Getter for the variables saved under the TellorStorageStruct uintVars variable
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the uintVars under the TellorStorageStruct struct
     * This is an example of how data is saved into the mapping within other functions:
     * self.uintVars[keccak256("stakerCount")]
     * @return uint of specified variable
     */
    function getUintVar(bytes32 _data) external view returns (uint256);

    /**
     * @dev Getter function for next requestId on queue/request with highest payout at time the function is called
     * @return onDeck/info on request with highest payout-- RequestId, Totaltips, and API query string
     */
    function getVariablesOnDeck()
        external
        view
        returns (
            uint256,
            uint256,
            string memory
        );

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return bool true if requestId/timestamp is under dispute
     */
    function isInDispute(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (bool);

    /**
     * @dev Retreive value from oracle based on timestamp
     * @param _requestId being requested
     * @param _timestamp to retreive data/value from
     * @return value for timestamp submitted
     */
    function retrieveData(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256);

    /**
     * @dev Getter for the total_supply of oracle tokens
     * @return uint total supply
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BankStorage
 * This contract provides the data structures, variables, and getters for Bank
 */
contract BankStorage {
    /*Variables*/
    string name;

    struct Reserve {
        uint256 collateralBalance;
        uint256 debtBalance;
        uint256 interestRate;
        uint256 originationFee;
        uint256 collateralizationRatio;
        uint256 liquidationPenalty;
        address oracleContract;
        uint256 period;
    }

    struct Token {
        address tokenAddress;
        uint256 price;
        uint256 priceGranularity;
        uint256 tellorRequestId;
        uint256 reserveBalance;
        uint256 lastUpdatedAt;
    }

    struct Vault {
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 createdAt;
    }

    mapping(address => Vault) public vaults;
    Token debt;
    Token collateral;
    Reserve reserve;

    /**
     * @dev Getter function for the bank name
     * @return bank name
     */
    function getName() public view returns (string memory) {
        return name;
    }

    /**
     * @dev Getter function for the current interest rate
     * @return interest rate
     */
    function getInterestRate() public view returns (uint256) {
        return reserve.interestRate;
    }

    /**
     * @dev Getter function for the origination fee
     * @return origination fee
     */
    function getOriginationFee() public view returns (uint256) {
        return reserve.originationFee;
    }

    /**
     * @dev Getter function for the current collateralization ratio
     * @return collateralization ratio
     */
    function getCollateralizationRatio() public view returns (uint256) {
        return reserve.collateralizationRatio;
    }

    /**
     * @dev Getter function for the liquidation penalty
     * @return liquidation penalty
     */
    function getLiquidationPenalty() public view returns (uint256) {
        return reserve.liquidationPenalty;
    }

    /**
     * @dev Getter function for debt token address
     * @return debt token price
     */
    function getDebtTokenAddress() public view returns (address) {
        return debt.tokenAddress;
    }

    /**
     * @dev Getter function for the debt token(reserve) price
     * @return debt token price
     */
    function getDebtTokenPrice() public view returns (uint256) {
        return debt.price;
    }

    /**
     * @dev Getter function for the debt token price granularity
     * @return debt token price granularity
     */
    function getDebtTokenPriceGranularity() public view returns (uint256) {
        return debt.priceGranularity;
    }

    /**
     * @dev Getter function for the debt token last update time
     * @return debt token last update time
     */
    function getDebtTokenLastUpdatedAt() public view returns (uint256) {
        return debt.lastUpdatedAt;
    }

    /**
     * @dev Getter function for debt token address
     * @return debt token price
     */
    function getCollateralTokenAddress() public view returns (address) {
        return collateral.tokenAddress;
    }

    /**
     * @dev Getter function for the collateral token price
     * @return collateral token price
     */
    function getCollateralTokenPrice() public view returns (uint256) {
        return collateral.price;
    }

    /**
     * @dev Getter function for the collateral token price granularity
     * @return collateral token price granularity
     */
    function getCollateralTokenPriceGranularity()
        public
        view
        returns (uint256)
    {
        return collateral.priceGranularity;
    }

    /**
     * @dev Getter function for the collateral token last update time
     * @return collateral token last update time
     */
    function getCollateralTokenLastUpdatedAt() public view returns (uint256) {
        return collateral.lastUpdatedAt;
    }

    /**
     * @dev Getter function for the debt token(reserve) balance
     * @return debt reserve balance
     */
    function getReserveBalance() public view returns (uint256) {
        return reserve.debtBalance;
    }

    /**
     * @dev Getter function for the debt reserve collateral balance
     * @return collateral reserve balance
     */
    function getReserveCollateralBalance() public view returns (uint256) {
        return reserve.collateralBalance;
    }

    /**
     * @dev Getter function for the user's vault collateral amount
     * @return collateral amount
     */
    function getVaultCollateralAmount() public view returns (uint256) {
        return vaults[msg.sender].collateralAmount;
    }

    /**
     * @dev Getter function for the user's vault debt amount
     * @return debt amount
     */
    function getVaultDebtAmount() public view returns (uint256) {
        return vaults[msg.sender].debtAmount;
    }

    /**
     * @dev Getter function for the user's vault debt amount
     *   uses a simple interest formula (i.e. not compound  interest)
     * @return principal debt amount
     */
    function getVaultRepayAmount() public view returns (uint256 principal) {
        principal = vaults[msg.sender].debtAmount;
        uint256 periodsPerYear = 365 days / reserve.period;
        uint256 periodsElapsed = (block.timestamp / reserve.period) -
            (vaults[msg.sender].createdAt / reserve.period);
        principal +=
            ((principal * reserve.interestRate) / 10000 / periodsPerYear) *
            periodsElapsed;
    }

    /**
     * @dev Getter function for the collateralization ratio
     * @return collateralization ratio
     */
    function getVaultCollateralizationRatio(address vaultOwner)
        public
        view
        returns (uint256)
    {
        if (vaults[vaultOwner].debtAmount == 0) {
            return 0;
        } else {
            return
                (((vaults[vaultOwner].collateralAmount * collateral.price) /
                    collateral.priceGranularity) * 10000) /
                ((vaults[vaultOwner].debtAmount * debt.price) /
                    debt.priceGranularity);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BankStorage.sol";
import "./ITellor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Bank
 * This contract allows the owner to deposit reserves(debt token), earn interest and
 * origination fees from users that borrow against their collateral.
 * The oracle for Bank is Tellor.
 */
contract Bank is BankStorage, Initializable {
    using SafeERC20 for IERC20;

    address private _owner;
    address private _bankFactoryOwner;

    /*Events*/
    event ReserveDeposit(uint256 amount);
    event ReserveWithdraw(address token, uint256 amount);
    event VaultDeposit(address owner, uint256 amount);
    event VaultBorrow(address borrower, uint256 amount);
    event VaultRepay(address borrower, uint256 amount);
    event VaultWithdraw(address borrower, uint256 amount);
    event PriceUpdate(address token, uint256 price);
    event Liquidation(address borrower, uint256 debtAmount);

    /*Constructor*/
    constructor(address payable oracleContract) {
        reserve.oracleContract = oracleContract;
    }

    /*Modifiers*/
    modifier onlyOwner() {
        require(_owner == msg.sender, "IS NOT OWNER");
        _;
    }

    /*Functions*/
    /**
     * @dev Returns the owner of the bank
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * NOTE: Override this to add changing the
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    /**
     * @dev This function sets the fundamental parameters for the bank
     *      and assigns the first admin
     */
    function init(
        address creator,
        string memory bankName,
        uint256 interestRate,
        uint256 originationFee,
        uint256 collateralizationRatio,
        uint256 liquidationPenalty,
        uint256 period,
        address bankFactoryOwner,
        address payable oracleContract
    ) public initializer {
        reserve.interestRate = interestRate;
        reserve.originationFee = originationFee;
        reserve.collateralizationRatio = collateralizationRatio;
        reserve.oracleContract = oracleContract;
        reserve.liquidationPenalty = liquidationPenalty;
        reserve.period = period;
        _owner = creator; // Make the creator the first admin
        _bankFactoryOwner = bankFactoryOwner;
        name = bankName;
    }

    /**
     * @dev This function sets the collateral token properties, only callable one time
     */
    function setCollateral(
        address collateralToken,
        uint256 collateralTokenTellorRequestId,
        uint256 collateralTokenPriceGranularity,
        uint256 collateralTokenPrice
    ) public onlyOwner {
        require(collateral.tokenAddress == address(0) && collateralToken != address(0), "!setable");
        collateral.tokenAddress = collateralToken;
        collateral.price = collateralTokenPrice;
        collateral.priceGranularity = collateralTokenPriceGranularity;
        collateral.tellorRequestId = collateralTokenTellorRequestId;
    }

    /**
     * @dev This function sets the debt token properties, only callable one time
     */
    function setDebt(
        address debtToken,
        uint256 debtTokenTellorRequestId,
        uint256 debtTokenPriceGranularity,
        uint256 debtTokenPrice
    ) public onlyOwner {
        require(debt.tokenAddress == address(0) && debtToken != address(0), "!setable");
        debt.tokenAddress = debtToken;
        debt.price = debtTokenPrice;
        debt.priceGranularity = debtTokenPriceGranularity;
        debt.tellorRequestId = debtTokenTellorRequestId;
    }

    /**
     * @dev This function allows the Bank owner to deposit the reserve (debt tokens)
     * @param amount is the amount to deposit
     */
    function reserveDeposit(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount is zero !!");
        reserve.debtBalance += amount;
        IERC20(debt.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        emit ReserveDeposit(amount);
    }

    /**
     * @dev This function allows the Bank owner to withdraw the reserve (debt tokens)
     *      Withdraws incur a 0.5% fee paid to the bankFactoryOwner
     * @param amount is the amount to withdraw
     */
    function reserveWithdraw(uint256 amount) external onlyOwner {
        require(
            IERC20(debt.tokenAddress).balanceOf(address(this)) >= amount,
            "NOT ENOUGH DEBT TOKENS IN RESERVE"
        );
        uint256 feeAmount = amount / 200; // Bank Factory collects 0.5% fee
        reserve.debtBalance -= amount;
        IERC20(debt.tokenAddress).safeTransfer(msg.sender, amount - feeAmount);
        IERC20(debt.tokenAddress).safeTransfer(_bankFactoryOwner, feeAmount);
        emit ReserveWithdraw(debt.tokenAddress, amount);
    }

    /**
  * @dev This function allows the user to withdraw their collateral
         Withdraws incur a 0.5% fee paid to the bankFactoryOwner
  * @param amount is the amount to withdraw
  */
    function reserveWithdrawCollateral(uint256 amount) external onlyOwner {
        require(
            reserve.collateralBalance >= amount,
            "NOT ENOUGH COLLATERAL IN RESERVE"
        );
        uint256 feeAmount = amount / 200; // Bank Factory collects 0.5% fee
        reserve.collateralBalance -= amount;
        emit ReserveWithdraw(collateral.tokenAddress, amount);
        IERC20(collateral.tokenAddress).safeTransfer(
            msg.sender,
            amount - feeAmount
        );
        IERC20(collateral.tokenAddress).safeTransfer(_bankFactoryOwner, feeAmount);
    }

    /**
     * @dev Use this function to get and update the price for the collateral token
     * using the Tellor Oracle.
     */
    function updateCollateralPrice() external onlyOwner {
        bool ifRetrieve;
        (
            ifRetrieve,
            collateral.price,
            collateral.lastUpdatedAt
        ) = getCurrentValue(collateral.tellorRequestId); //,now - 1 hours);
        emit PriceUpdate(collateral.tokenAddress, collateral.price);
    }

    /**
     * @dev Use this function to get and update the price for the debt token
     * using the Tellor Oracle.
     */
    function updateDebtPrice() external onlyOwner {
        bool ifRetrieve;
        (ifRetrieve, debt.price, debt.lastUpdatedAt) = getCurrentValue(
            debt.tellorRequestId
        ); //,now - 1 hours);
        emit PriceUpdate(debt.tokenAddress, debt.price);
    }

    /**
     * @dev Anyone can use this function to liquidate a vault's debt,
     * the bank admins gets the collateral liquidated, liquidated collateral
     * is charged a 10% fee which gets paid to the bankFactoryOwner
     * @param vaultOwner is the user the bank admins wants to liquidate
     */
    function liquidate(address vaultOwner) external onlyOwner {
        // Require undercollateralization
        require(
            getVaultCollateralizationRatio(vaultOwner) <
                reserve.collateralizationRatio * 100,
            "VAULT NOT UNDERCOLLATERALIZED"
        );
        uint256 debtOwned = vaults[vaultOwner].debtAmount +
            ((vaults[vaultOwner].debtAmount *
                100 *
                reserve.liquidationPenalty) /
                100 /
                100);
        uint256 collateralToLiquidate = (debtOwned * debt.price) /
            collateral.price;

        if (collateralToLiquidate > vaults[vaultOwner].collateralAmount) {
            collateralToLiquidate = vaults[vaultOwner].collateralAmount;
        }

        uint256 feeAmount = collateralToLiquidate / 10; // Bank Factory collects 10% fee
        reserve.collateralBalance += collateralToLiquidate - feeAmount;
        vaults[vaultOwner].collateralAmount -= collateralToLiquidate;
        vaults[vaultOwner].debtAmount = 0;
        IERC20(collateral.tokenAddress).safeTransfer(_bankFactoryOwner, feeAmount);
        emit Liquidation(vaultOwner, debtOwned);
    }

    /**
     * @dev Use this function to allow users to deposit collateral to the vault
     * @param amount is the collateral amount
     */
    function vaultDeposit(uint256 amount) external {
        require(amount > 0, "Amount is zero !!");
        vaults[msg.sender].collateralAmount += amount;
        reserve.collateralBalance += amount;
        IERC20(collateral.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        emit VaultDeposit(msg.sender, amount);
    }

    /**
     * @dev Use this function to allow users to borrow against their collateral
     * @param amount to borrow
     */
    function vaultBorrow(uint256 amount) external {
        if (vaults[msg.sender].debtAmount != 0) {
            vaults[msg.sender].debtAmount = getVaultRepayAmount();
        }
        uint256 maxBorrow = ((vaults[msg.sender].collateralAmount *
            collateral.price) /
            debt.price /
            reserve.collateralizationRatio) * 100;
        maxBorrow *= debt.priceGranularity;
        maxBorrow /= collateral.priceGranularity;
        maxBorrow -= vaults[msg.sender].debtAmount;
        vaults[msg.sender].debtAmount +=
            amount +
            ((amount * reserve.originationFee) / 10000);
        require(vaults[msg.sender].debtAmount < maxBorrow, "NOT ENOUGH COLLATERAL");
        require(amount <= IERC20(debt.tokenAddress).balanceOf(address(this)), "NOT ENOUGH RESERVES");
        if (block.timestamp - vaults[msg.sender].createdAt > reserve.period) {
            // Only adjust if more than 1 interest rate period has past
            vaults[msg.sender].createdAt = block.timestamp;
        }
        reserve.debtBalance -= amount;
        IERC20(debt.tokenAddress).safeTransfer(msg.sender, amount);
        emit VaultBorrow(msg.sender, amount);
    }

    /**
     * @dev This function allows users to pay the interest and origination fee to the
     *  vault before being able to withdraw
     * @param amount owed
     */
    function vaultRepay(uint256 amount) external {
        require(amount > 0, "Amount is zero !!");
        vaults[msg.sender].debtAmount = getVaultRepayAmount();
        require(
            amount <= vaults[msg.sender].debtAmount,
            "CANNOT REPAY MORE THAN OWED"
        );
        vaults[msg.sender].debtAmount -= amount;
        reserve.debtBalance += amount;
        uint256 periodsElapsed = (block.timestamp / reserve.period) -
            (vaults[msg.sender].createdAt / reserve.period);
        vaults[msg.sender].createdAt += periodsElapsed * reserve.period;
        IERC20(debt.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        emit VaultRepay(msg.sender, amount);
    }

    /**
     * @dev Allows users to withdraw their collateral from the vault
     * @param amount withdrawn
     */
    function vaultWithdraw(uint256 amount) external {
        require(
            amount <= vaults[msg.sender].collateralAmount,
            "CANNOT WITHDRAW MORE COLLATERAL"
        );

        uint256 maxBorrowAfterWithdraw = (((vaults[msg.sender]
            .collateralAmount - amount) * collateral.price) /
            debt.price /
            reserve.collateralizationRatio) * 100;
        maxBorrowAfterWithdraw *= debt.priceGranularity;
        maxBorrowAfterWithdraw /= collateral.priceGranularity;
        require(
            vaults[msg.sender].debtAmount <= maxBorrowAfterWithdraw,
            "CANNOT UNDERCOLLATERALIZE VAULT"
        );
        vaults[msg.sender].collateralAmount -= amount;
        reserve.collateralBalance -= amount;
        IERC20(collateral.tokenAddress).safeTransfer(msg.sender, amount);
        emit VaultWithdraw(msg.sender, amount);
    }

    function getBankFactoryOwner() public view returns (address) {
        return _bankFactoryOwner;
    }

    function setBankFactoryOwner(address newOwner) external {
        require(_bankFactoryOwner == msg.sender, "IS NOT BANK FACTORY OWNER");
        _bankFactoryOwner = newOwner;
    }

    function getCurrentValue(uint256 _requestId)
        public
        view
        returns (
            bool ifRetrieve,
            uint256 value,
            uint256 _timestampRetrieved
        )
    {
        ITellor oracle = ITellor(reserve.oracleContract);
        uint256 _count = oracle.getNewValueCountbyRequestId(_requestId);
        uint256 _time = oracle.getTimestampbyRequestIDandIndex(
            _requestId,
            _count - 1
        );
        uint256 _value = oracle.retrieveData(_requestId, _time);
        if (_value > 0) return (true, _value, _time);
        return (false, 0, _time);
    }
}