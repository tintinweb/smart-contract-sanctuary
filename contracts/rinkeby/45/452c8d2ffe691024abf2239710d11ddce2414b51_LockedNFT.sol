/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// File: remixbackup/FNFT/contracts/libraries/Clones.sol



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

// File: remixbackup/FNFT/contracts/interfaces/ILockedNFT.sol

pragma solidity ^0.8.0;

interface ILockedNFT {
    function ownerTradingFee() external returns (uint);

    function curator() external returns (address);
}

// File: remixbackup/FNFT/contracts/interfaces/INFTStoreHouse.sol

pragma solidity ^0.8.0;

interface INFTStoreHouse {
    function emitStartAuctionEvent(address _user, uint _price) external;

    function emitAuctionEndEvent(address _user, uint _price) external;
    
    function emitRedeemWithAllSupplyEvent(address _user) external;
    
    function emitDirectBuyoutEvent(address _approver, address _buyer, uint _price) external;
}

// File: remixbackup/FNFT/contracts/interfaces/IERC20.sol



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

// File: remixbackup/FNFT/contracts/libraries/ReentrancyGuard.sol



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

// File: remixbackup/FNFT/contracts/libraries/Address.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/contracts/token/ERC721/IERC721ReceiverUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol



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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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


// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol



pragma solidity ^0.8.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol



pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
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
    uint256[50] private __gap;
}


// File: remixbackup/FNFT/contracts/LockedNFT.sol

pragma solidity ^0.8.0;










contract LockedNFT is ERC20Upgradeable, ERC721HolderUpgradeable, ILockedNFT, ReentrancyGuard {
    using Address for address;

    address public constant eth = address(0);

    IERC721 public lockedNFTContract;
    uint public tokenID;
    uint public ownerBuyoutFee;
    uint public votePercentageThreshold;
    address public override curator;
    uint public portionOfSupplyNeededToStartPrivateBuyout;
    uint public override ownerTradingFee;
    address public currency;
    
    // Votable by FNFT owners
    uint public reservePriceTotal;
    uint public auctionLengthTotal;
    uint public bidIncrementTotal;
    
    uint public lastClaimFeeTimeStamp;
    uint public reservePriceVotedTokenCount;
    uint public auctionLengthVotedTokenCount;
    uint public bidIncrementVotedTokenCount;
    
    mapping(address => uint) public userReservePrice;
    mapping(address => uint) public userAuctionLength;
    mapping(address => uint) public userBidIncrement;
    
    IGlobalGovernanceSettings public globalGovernanceSettings;
    State public currentState;
    
    enum State { normal, auctioning, auctionEnd, redeemed, directlySold }
    
    address public highestBidder;
    uint public highestBidPrice;
    uint public auctionEndTime;
    
    uint public totalSupplyWhenAuctionEnd;
    
    bool public allowDirectBuyout;
    bool public directBuyoutEnabled;

    mapping(address => uint) public userAddressToPrice;
    mapping(address => uint) public userAddressToIndexPlus1;
    address[] public usersMakeBuyoutOffer;

    event UserUpdateReservePrice(address indexed user, uint oldValue, uint newValue, uint tokenCount);
    event UserUpdateAuctionLength(address indexed user, uint oldValue, uint newValue, uint tokenCount);
    event UserUpdateBidIncrement(address indexed user, uint oldValue, uint newValue, uint tokenCount);
    event StartAutcion(address indexed user, uint price);
    event Bid(address indexed user, uint price);
    event RedeemWithAllSupply(address indexed user);
    event AuctionEnd(address indexed user, uint price);
    event ClaimMoney(address indexed user, uint money);
    event MakeBuyoutOffer(address indexed user, uint price);
    event RemoveBuyoutOffer(address indexed user);
    event AcceptBuyoutOffer(address indexed approver, address buyer, uint price);

    function initialize(
        address _globalGovernanceSettings,
        string memory _name,
        string memory _symbol,
        uint _initialSupply,
        uint _reservePrice,
        address _currency,
        address _lockedNFTContract,
        uint _tokenID,
        // uint _ownerBuyoutFee,
        uint _votePercentageThreshold,
        address _previousNFTOwner,
        uint _portionOfSupplyNeededToStartPrivateBuyout,
        bool _allowDirectBuyout
    ) initializer public {
        globalGovernanceSettings = IGlobalGovernanceSettings(_globalGovernanceSettings);

        // require(_ownerBuyoutFee <= globalGovernanceSettings.originalOwnerBuyoutFeeUpperBound(), "Too high owner fee");
        require((_votePercentageThreshold >= globalGovernanceSettings.minVotePercentageThreshold()) && (_votePercentageThreshold <= globalGovernanceSettings.maxVotePercentageThreshold()), "Vote percentage threshold too high or too low");
        require(globalGovernanceSettings.currencyToAcceptableForTrading(_currency) == true, "The currency is not accepted now");
        require(_reservePrice > 0, "Reserve price must be positive");
        require(_portionOfSupplyNeededToStartPrivateBuyout <= 10000);

        __ERC20_init(_name, _symbol);
        __ERC721Holder_init();

        lockedNFTContract = IERC721(_lockedNFTContract);
        tokenID = _tokenID;
        // ownerBuyoutFee = _ownerBuyoutFee;
        votePercentageThreshold = _votePercentageThreshold;
        curator = _previousNFTOwner;
        portionOfSupplyNeededToStartPrivateBuyout = _portionOfSupplyNeededToStartPrivateBuyout;
        currency = _currency;

        _mint(curator, _initialSupply * 1 ether);

        userReservePrice[curator] = _reservePrice;
        reservePriceTotal = _initialSupply * 1 ether * _reservePrice;
        reservePriceVotedTokenCount = _initialSupply * 1 ether;

        allowDirectBuyout = _allowDirectBuyout;
        
        lastClaimFeeTimeStamp = block.timestamp;
        currentState = State.normal;
    }
    
    function setOwnerTradingFee(uint _ownerTradingFee) public {
        require(_ownerTradingFee <= globalGovernanceSettings.originalOwnerTradingFeeUpperBound(), "Too high owner fee");
        ownerTradingFee = _ownerTradingFee;
    }
    
    function setOwnerBuyoutFee(uint _ownerBuyoutFee) public {
        require(_ownerBuyoutFee <= globalGovernanceSettings.originalOwnerBuyoutFeeUpperBound(), "Too high owner fee");
        ownerBuyoutFee = _ownerBuyoutFee;
    }
    
    function reservePriceForAllSupply() public view returns (uint) {
        if (reservePriceVotedTokenCount == 0) return 0;
        return reservePriceTotal * totalSupply() / reservePriceVotedTokenCount / 1 ether;
    }
    
    function auctionLength() public view returns (uint) {
        if (auctionLengthVotedTokenCount == 0) return 0;
        return auctionLengthTotal / (auctionLengthVotedTokenCount);
    }
    
    function bidIncrement() public view returns (uint) {
        if (bidIncrementVotedTokenCount == 0) return 0;
        return bidIncrementTotal / (bidIncrementVotedTokenCount);
    }
    
    function delegateCurator(address _delegate) public {
        require(msg.sender == curator);
        curator = _delegate;
    }
    
    function toggleDirectBuyoutEnabled() public {
        require(allowDirectBuyout);
        require(balanceOf(msg.sender) * 2 >= totalSupply(), "You don't have right to do so");
        directBuyoutEnabled = !directBuyoutEnabled;
    }
    
    function _claimFees() internal {
        uint governanceFee = globalGovernanceSettings.governanceFee() * totalSupply() * (block.timestamp - lastClaimFeeTimeStamp) / 315360000000;
        uint originalownerBuyoutFee = ownerBuyoutFee * totalSupply() * (block.timestamp - lastClaimFeeTimeStamp) / 315360000000;
        lastClaimFeeTimeStamp = block.timestamp;
        _mint(curator, originalownerBuyoutFee);
        _mint(globalGovernanceSettings.feeClaimer(), governanceFee);
    }
    
    function updateChoice(uint _reservePrice, uint _auctionLength, uint _bidIncrement) public {
        _updateDesiredReservePrice(_reservePrice);
        _updateDesiredAuctionLength(_auctionLength);
        _updateDesiredBidIncrement(_bidIncrement);
    }
    
    function _updateDesiredReservePrice(uint _reservePrice) internal {
        uint lowerBound = reservePriceTotal * globalGovernanceSettings.reservePriceLowerLimitPercentage() / reservePriceVotedTokenCount / 10000;
        uint upperBound = reservePriceTotal * globalGovernanceSettings.reservePriceUpperLimitPercentage() / reservePriceVotedTokenCount / 10000;
        require(((_reservePrice >= lowerBound) && (_reservePrice <= upperBound)) || (_reservePrice == 0), "Reserve price too high or too low");
        require(currentState == State.normal, "Current state must not be in auction");
        uint oldChoice = userReservePrice[msg.sender];
        uint weight = balanceOf(msg.sender);
        if ((oldChoice == 0) && (_reservePrice != 0)) {
            userReservePrice[msg.sender] = _reservePrice;
            reservePriceTotal = reservePriceTotal + weight * _reservePrice;
            reservePriceVotedTokenCount = reservePriceVotedTokenCount + weight;
        } else if ((oldChoice != 0) && (_reservePrice == 0)) {
            userReservePrice[msg.sender] = _reservePrice;
            reservePriceTotal = reservePriceTotal - weight * oldChoice;
            reservePriceVotedTokenCount = reservePriceVotedTokenCount - weight;
        } else {
            userReservePrice[msg.sender] = _reservePrice;
            reservePriceTotal = reservePriceTotal - weight * oldChoice + weight * _reservePrice;
        }
        emit UserUpdateReservePrice(msg.sender, oldChoice, _reservePrice, weight);
    }
    
    function _updateDesiredAuctionLength(uint _auctionLength) internal {
        require(((_auctionLength >= globalGovernanceSettings.minAuctionLength()) && (_auctionLength <= globalGovernanceSettings.maxAuctionLength())) || (_auctionLength == 0), "Auction length too high or too low");
        require(currentState == State.normal, "Current state must not be in auction");
        uint oldChoice = userAuctionLength[msg.sender];
        uint weight = balanceOf(msg.sender);
        if ((oldChoice == 0) && (_auctionLength != 0)) {
            userAuctionLength[msg.sender] = _auctionLength;
            auctionLengthTotal = auctionLengthTotal + weight * _auctionLength;
            auctionLengthVotedTokenCount = auctionLengthVotedTokenCount + weight;
        } else if ((oldChoice != 0) && (_auctionLength == 0)) {
            userAuctionLength[msg.sender] = _auctionLength;
            auctionLengthTotal = auctionLengthTotal - weight * oldChoice;
            auctionLengthVotedTokenCount = auctionLengthVotedTokenCount - weight;
        } else {
            userAuctionLength[msg.sender] = _auctionLength;
            auctionLengthTotal = auctionLengthTotal - weight * oldChoice + weight * _auctionLength;
        }
        emit UserUpdateAuctionLength(msg.sender, oldChoice, _auctionLength, weight);
    }
    
    function _updateDesiredBidIncrement(uint _bidIncrement) internal {
        require(((_bidIncrement >= globalGovernanceSettings.minBidIncrement()) && (_bidIncrement <= globalGovernanceSettings.maxBidIncrement())) || (_bidIncrement == 0), "Bid increment too high or too low");
        require(currentState == State.normal, "Current state must not be in auction");
        uint oldChoice = userBidIncrement[msg.sender];
        uint weight = balanceOf(msg.sender);
        if ((oldChoice == 0) && (_bidIncrement != 0)) {
            userBidIncrement[msg.sender] = _bidIncrement;
            bidIncrementTotal = bidIncrementTotal + weight * _bidIncrement;
            bidIncrementVotedTokenCount = bidIncrementVotedTokenCount + weight;
        } else if ((oldChoice != 0) && (_bidIncrement == 0)) {
            userBidIncrement[msg.sender] = _bidIncrement;
            bidIncrementTotal = bidIncrementTotal - weight * oldChoice;
            bidIncrementVotedTokenCount = bidIncrementVotedTokenCount - weight;
        } else {
            userBidIncrement[msg.sender] = _bidIncrement;
            bidIncrementTotal = bidIncrementTotal - weight * oldChoice + weight * _bidIncrement;
        }
        emit UserUpdateAuctionLength(msg.sender, oldChoice, _bidIncrement, weight);
    }
    
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        if ((_from != address(0)) && (_to != address(0)) && (currentState == State.normal)) {
            if (userReservePrice[_from] != userReservePrice[_to]) {
                if (userReservePrice[_from] == 0) {
                    reservePriceVotedTokenCount = reservePriceVotedTokenCount + _amount;
                    reservePriceTotal = reservePriceTotal + _amount * userReservePrice[_to];
                } else if (userReservePrice[_to] == 0) {
                    reservePriceVotedTokenCount = reservePriceVotedTokenCount - _amount;
                    reservePriceTotal = reservePriceTotal - _amount * userReservePrice[_from];
                } else {
                    reservePriceTotal = reservePriceTotal - _amount * userReservePrice[_from] + _amount * userReservePrice[_to];
                }
            }

            if (userAuctionLength[_from] != userAuctionLength[_to]) {
                if (userAuctionLength[_from] == 0) {
                    auctionLengthVotedTokenCount = auctionLengthVotedTokenCount + _amount;
                    auctionLengthTotal = auctionLengthTotal + _amount * userAuctionLength[_to];
                } else if (userAuctionLength[_to] == 0) {
                    auctionLengthVotedTokenCount = auctionLengthVotedTokenCount - _amount;
                    auctionLengthTotal = auctionLengthTotal - _amount * userAuctionLength[_from];
                } else {
                    auctionLengthTotal = auctionLengthTotal - _amount * userAuctionLength[_from] + _amount * userAuctionLength[_to];
                }
            }

            if (userBidIncrement[_from] != userBidIncrement[_to]) {
                if (userBidIncrement[_from] == 0) {
                    bidIncrementVotedTokenCount = bidIncrementVotedTokenCount + _amount;
                    bidIncrementTotal = bidIncrementTotal + _amount * userBidIncrement[_to];
                } else if (userBidIncrement[_to] == 0) {
                    bidIncrementVotedTokenCount = bidIncrementVotedTokenCount - _amount;
                    bidIncrementTotal = bidIncrementTotal - _amount * userBidIncrement[_from];
                } else {
                    bidIncrementTotal = bidIncrementTotal - _amount * userBidIncrement[_from] + _amount * userBidIncrement[_to];
                }
            }
        }
    }

    // Input: price for all fnft supply
    function startAuction(uint _price) public payable nonReentrant {
        require(currentState == State.normal, "Current state must not be in auction");
        require((auctionLengthVotedTokenCount != 0) && (bidIncrementVotedTokenCount != 0), "Nobody has voted for auction length and bid increment");
        require(balanceOf(msg.sender) >= totalSupply() * portionOfSupplyNeededToStartPrivateBuyout / 10000);
        require(_price >= reservePriceForAllSupply(), "Price lower than reserve price for all supply");
        require(reservePriceVotedTokenCount * 10000 / totalSupply() >= votePercentageThreshold, "Not enough FNFT holders accept buyout");
        if (currency == eth) {
            require(msg.value == _price, "Please send exact amount of ETH you specified to start an auction");
        } else {
            require(IERC20(currency).transferFrom(msg.sender, address(this), _price), "No enough tokens");
        }
        
        auctionEndTime = block.timestamp + auctionLength();
        currentState = State.auctioning;
        highestBidder = msg.sender;
        highestBidPrice = _price;
        
        emit StartAutcion(msg.sender, _price);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse()).emitStartAuctionEvent(msg.sender, _price);
    }
    
    function bid(uint _price) public payable nonReentrant {
        require(currentState == State.auctioning, "Current state not be in auction");
        require(balanceOf(msg.sender) >= totalSupply() * portionOfSupplyNeededToStartPrivateBuyout / 10000);
        require(_price >= highestBidPrice * bidIncrement() / 10000 + highestBidPrice, "Price too low");
        require(block.timestamp < auctionEndTime, "Auction ended");
        
        if (block.timestamp + 15 minutes >= auctionEndTime) {
            auctionEndTime = auctionEndTime + 15 minutes;
        }
        
        if (currency == eth) {
            require(msg.value == _price, "Please send exact amount of ETH you specified to bid");
            payable(highestBidder).transfer(highestBidPrice);
        } else {
            require(IERC20(currency).transfer(highestBidder, highestBidPrice), "No enough tokens");
            require(IERC20(currency).transferFrom(msg.sender, address(this), _price), "No enough tokens");
        }
        
        highestBidder = msg.sender;
        highestBidPrice = _price;
        
        emit Bid(msg.sender, _price);
    }
    
    function revertToNFT() public {
        require(currentState == State.normal, "Current state must not be in auction");
        require(balanceOf(msg.sender) == totalSupply(), "You dont own all FNFT tokens");
        lockedNFTContract.safeTransferFrom(address(this), msg.sender, tokenID);
        _burn(msg.sender, balanceOf(msg.sender));
        currentState = State.redeemed;
        highestBidder = msg.sender;
        
        emit RedeemWithAllSupply(msg.sender);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse()).emitRedeemWithAllSupplyEvent(msg.sender);
    }
    
    function endAuction() public nonReentrant {
        require(currentState == State.auctioning, "Auction is not on-going");
        require(block.timestamp > auctionEndTime, "Auction is still on-going");

        currentState = State.auctionEnd;
        _claimFees();
        
        lockedNFTContract.safeTransferFrom(address(this), highestBidder, tokenID);
        
        if ((currency == eth) && (address(this).balance > highestBidPrice)) {
            payable(highestBidder).transfer(address(this).balance - highestBidPrice);
        } else if ((currency != eth) && (IERC20(currency).balanceOf(address(this)) > highestBidPrice)) {
            IERC20(currency).transfer(highestBidder, IERC20(currency).balanceOf(address(this)) - highestBidPrice);
        }
        
        totalSupplyWhenAuctionEnd = totalSupply();
        uint governanceFee = highestBidPrice * balanceOf(globalGovernanceSettings.feeClaimer()) / totalSupplyWhenAuctionEnd;
        _burn(globalGovernanceSettings.feeClaimer(), balanceOf(globalGovernanceSettings.feeClaimer()));
        
        if (currency == eth) {
            payable(globalGovernanceSettings.feeClaimer()).transfer(governanceFee);
        } else {
            IERC20(currency).transfer(globalGovernanceSettings.feeClaimer(), governanceFee);
        }
        
        emit ClaimMoney(globalGovernanceSettings.feeClaimer(), governanceFee);
        emit AuctionEnd(highestBidder, highestBidPrice);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse()).emitAuctionEndEvent(highestBidder, highestBidPrice);
    }

    function makeBuyoutOffer(uint _price) public payable nonReentrant {
        require(currentState == State.normal, "The NFT has been sold or auction is on-going");
        require(directBuyoutEnabled && allowDirectBuyout, "Direct buyout is not allowed");
        // require(balanceOf(msg.sender) >= totalSupply() * portionOfSupplyNeededToStartPrivateBuyout / 10000);
        // require(_price >= reservePriceForAllSupply(), "Price lower than reserve price for all supply");
        require(_price > 0);
        // require(reservePriceVotedTokenCount * 10000 / totalSupply() >= votePercentageThreshold, "Not enough FNFT holders accept buyout");
        if (currency == eth) {
            require(msg.value == _price, "Please send exact amount of ETH you specified to start an auction");
            if (userAddressToPrice[msg.sender] > 0) {
                payable(msg.sender).transfer(_price);
            }
        } else {
            require(IERC20(currency).transferFrom(msg.sender, address(this), _price), "No enough tokens");
            if (userAddressToPrice[msg.sender] > 0) {
                IERC20(currency).transfer(msg.sender, _price);
            }
        }
        userAddressToPrice[msg.sender] = _price;
        
        if (userAddressToIndexPlus1[msg.sender] == 0) {
            userAddressToIndexPlus1[msg.sender] = usersMakeBuyoutOffer.length + 1;
            usersMakeBuyoutOffer.push(msg.sender);
        }

        emit MakeBuyoutOffer(msg.sender, _price);
    }

    function removeBuyoutOffer() public nonReentrant {
        require(userAddressToIndexPlus1[msg.sender] > 0);
        uint price = userAddressToPrice[msg.sender];
        userAddressToPrice[msg.sender] = 0;

        if (currency == eth) {
            payable(msg.sender).transfer(price);
        } else {
            IERC20(currency).transfer(msg.sender, price);
        }
        
        address latestBuyer = usersMakeBuyoutOffer[usersMakeBuyoutOffer.length - 1];
        userAddressToIndexPlus1[latestBuyer] = userAddressToIndexPlus1[msg.sender];
        usersMakeBuyoutOffer[userAddressToIndexPlus1[msg.sender] - 1] = latestBuyer;
        
        userAddressToIndexPlus1[msg.sender] = 0;
        usersMakeBuyoutOffer.pop();

        emit RemoveBuyoutOffer(msg.sender);
    }

    function getBuyoutOfferCount() public view returns (uint) {
        return usersMakeBuyoutOffer.length;
    }

    function getBuyoutOfferList(uint _start, uint _length) public view returns (address[] memory, uint[] memory) {
        uint maxLength = (_start + _length > usersMakeBuyoutOffer.length) ? (usersMakeBuyoutOffer.length - _start) : _length;
        address[] memory addressList = new address[](maxLength);
        uint[] memory priceList = new uint[](maxLength);
        for (uint i = 0; i < maxLength; i++) {
            addressList[i] = usersMakeBuyoutOffer[_start + i];
            priceList[i] = userAddressToPrice[usersMakeBuyoutOffer[_start + i]];
        }
        return (addressList, priceList);
    }
    
    function acceptBuyoutOffer(address buyerAddress) public nonReentrant {
        require(currentState == State.normal, "The NFT has been sold");
        require(directBuyoutEnabled && allowDirectBuyout, "Direct buyout is not allowed");
        require(balanceOf(msg.sender) * 2 >= totalSupply(), "You don't have right to accept buyout ofer");
        // require(userAddressToPrice[buyerAddress] >= reservePriceForAllSupply(), "Price lower than reserve price for all supply");
        currentState = State.directlySold;
        _claimFees();
        highestBidder = buyerAddress;
        highestBidPrice = userAddressToPrice[buyerAddress];

        lockedNFTContract.safeTransferFrom(address(this), buyerAddress, tokenID);
        
        if ((currency == eth) && (address(this).balance > highestBidPrice)) {
            payable(highestBidder).transfer(address(this).balance - highestBidPrice);
        } else if ((currency != eth) && (IERC20(currency).balanceOf(address(this)) > highestBidPrice)) {
            IERC20(currency).transfer(highestBidder, IERC20(currency).balanceOf(address(this)) - highestBidPrice);
        }
        
        totalSupplyWhenAuctionEnd = totalSupply();
        uint governanceFee = highestBidPrice * balanceOf(globalGovernanceSettings.feeClaimer()) / totalSupplyWhenAuctionEnd;
        _burn(globalGovernanceSettings.feeClaimer(), balanceOf(globalGovernanceSettings.feeClaimer()));
        
        if (currency == eth) {
            payable(globalGovernanceSettings.feeClaimer()).transfer(governanceFee);
        } else {
            IERC20(currency).transfer(globalGovernanceSettings.feeClaimer(), governanceFee);
        }
        
        emit ClaimMoney(globalGovernanceSettings.feeClaimer(), governanceFee);
        emit AcceptBuyoutOffer(msg.sender, highestBidder, highestBidPrice);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse()).emitDirectBuyoutEvent(msg.sender, highestBidder, highestBidPrice);
    }

    function claimMoneyAfterAuctionEnd() public nonReentrant returns (uint) {
        require((currentState == State.auctionEnd) || (currentState == State.directlySold), "Auction has not ended");
        require(balanceOf(msg.sender) > 0, "You dont have any token");
        uint fee = highestBidPrice * balanceOf(msg.sender) / totalSupplyWhenAuctionEnd;
        _burn(msg.sender, balanceOf(msg.sender));
        
        if (currency == eth) {
            payable(msg.sender).transfer(fee);
        } else {
            IERC20(currency).transfer(msg.sender, fee);
        }

        emit ClaimMoney(msg.sender, fee);
        return fee;
    }

    /*
    function getReceivedERC20Tokens(address[] memory _tokenAddresses) public {
        require((msg.sender == highestBidder) && ((currentState == State.auctionEnd) || (cucrrentState == State.redeemed) || (currentState == State.directlySold)), "You have no right");
        for (uint i = 0; i < _tokenAddresses.length; i++) {
            if (_tokenAddresses[i] != currency) {
                IERC20(_tokenAddresses[i]).transfer(msg.sender, IERC20(_tokenAddresses[i]).balanceOf(address(this)));
            }
        }
    }

    function getReceivedNFTs(address[] memory _tokenAddresses, uint[] memory _tokenIds) public {
        require((msg.sender == highestBidder) && ((currentState == State.auctionEnd) || (currentState == State.redeemed) || (currentState == State.directlySold)), "You have no right");
        for (uint i = 0; i < _tokenAddresses.length; i++) {
            IERC721(_tokenAddresses[i]).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
        }
    }

    function getReceivedETH() public {
        require((msg.sender == highestBidder) && ((currentState == State.auctionEnd) || (currentState == State.redeemed) || (currentState == State.directlySold)), "You have no right");
        require(currency != eth, "You are not allowed to claim ETH when the currency for trading is ETH");
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
    */
}

// File: remixbackup/FNFT/contracts/interfaces/IERC165.sol



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

// File: remixbackup/FNFT/contracts/interfaces/IERC721.sol



pragma solidity ^0.8.0;


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

// File: remixbackup/FNFT/contracts/interfaces/IGlobalGovernanceSettings.sol

pragma solidity ^0.8.0;

interface IGlobalGovernanceSettings {
    function minAuctionLength() external returns (uint);

    function maxAuctionLength() external returns (uint);

    function auctionLengthLowerBound() external returns (uint);

    function auctionLengthUpperBound() external returns (uint);

    function governanceFee() external returns (uint);

    function governenceFeeUpperBound() external returns (uint);

    function tradingFee() external returns (uint);

    function tradingFeeUpperBound() external returns (uint);

    function feeClaimer() external returns (address payable);

    function originalOwnerBuyoutFeeUpperBound() external returns (uint);

    function originalOwnerTradingFeeUpperBound() external returns (uint);

    function minBidIncrement() external returns (uint);

    function maxBidIncrement() external returns (uint);

    function bidIncrementLowerBound() external returns (uint);

    function bidIncrementUpperBound() external returns (uint);

    function minVotePercentageThreshold() external returns (uint);

    function maxVotePercentageThreshold() external returns (uint);

    function reservePriceLowerLimitPercentage() external returns (uint);

    function reservePriceUpperLimitPercentage() external returns (uint);

    function nftStoreHouse() external returns (address);

    function currencyToAcceptableForTrading(address) external returns (bool);
}

// File: remixbackup/FNFT/contracts/GlobalGovernanceSettings.sol

pragma solidity ^0.8.0;


contract GlobalGovernanceSettings is IGlobalGovernanceSettings {
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926; // 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant eth = address(0);
    
    mapping(address => bool) public override currencyToAcceptableForTrading;
    address[] public currenciesAcceptableForTrading = [weth, dai, usdc, usdt, eth];
    
    uint public override minAuctionLength;
    uint public override maxAuctionLength;
    uint public override immutable auctionLengthLowerBound;
    uint public override immutable auctionLengthUpperBound;
    
    uint public override governanceFee; // In terms of 0.01%
    uint public override immutable governenceFeeUpperBound;
    uint public override tradingFee; // In terms of 0.01%
    uint public override immutable tradingFeeUpperBound;
    address payable public override feeClaimer;
    
    uint public immutable override originalOwnerBuyoutFeeUpperBound;
    uint public immutable override originalOwnerTradingFeeUpperBound;

    uint public override minBidIncrement;
    uint public override maxBidIncrement;
    uint public override immutable bidIncrementLowerBound;
    uint public override immutable bidIncrementUpperBound;
    
    uint public override immutable minVotePercentageThreshold;
    uint public override immutable maxVotePercentageThreshold;
    
    uint public override reservePriceLowerLimitPercentage;
    uint public override reservePriceUpperLimitPercentage;
    
    address public owner;
    
    address public override immutable nftStoreHouse;
    
    event UpdateMinAuctionLength(uint oldValue, uint newValue);
    event UpdateMaxAuctionLength(uint oldValue, uint newValue);
    event UpdateGovernanceFee(uint oldValue, uint newValue);
    event UpdateTradingFee(uint oldValue, uint newValue);
    event UpdateFeeClaimer(address oldValue, address newValue);
    event UpdateMinBidIncrement(uint oldValue, uint newValue);
    event UpdateMaxBidIncrement(uint oldValue, uint newValue);
    event UpdateReservePriceLowerLimitPercentage(uint oldValue, uint newValue);
    event UpdateReservePriceUpperLimitPercentage(uint oldValue, uint newValue);
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _owner) {
        minAuctionLength = 10 minutes;
        maxAuctionLength = 3 days;
        auctionLengthLowerBound = 10 minutes;
        auctionLengthUpperBound = 3 days;
        
        governanceFee = 1000;
        governenceFeeUpperBound = 1000;
        tradingFee = 1000;
        tradingFeeUpperBound = 1000;
        feeClaimer = payable(_owner);
        
        originalOwnerBuyoutFeeUpperBound = 1000;
        originalOwnerTradingFeeUpperBound = 1000;
        
        minBidIncrement = 100;
        maxBidIncrement = 5000;
        bidIncrementLowerBound = 10;
        bidIncrementUpperBound = 10000;
        
        owner = _owner;
        
        minVotePercentageThreshold = 100;
        maxVotePercentageThreshold = 8000;
        reservePriceLowerLimitPercentage = 1000;
        reservePriceUpperLimitPercentage = 100000;
        nftStoreHouse = msg.sender;
        
        currencyToAcceptableForTrading[weth] = true;
        currencyToAcceptableForTrading[dai] = true;
        currencyToAcceptableForTrading[usdc] = true;
        currencyToAcceptableForTrading[usdt] = true;
        currencyToAcceptableForTrading[eth] = true;
    }
    
    function setMinAuctionLength(uint _minAuctionLength) public onlyOwner {
        require(_minAuctionLength >= auctionLengthLowerBound);
        require(_minAuctionLength < maxAuctionLength);
        emit UpdateMinAuctionLength(minAuctionLength, _minAuctionLength);
        minAuctionLength = _minAuctionLength;
    }
    
    function setMaxAuctionLength(uint _maxAuctionLength) public onlyOwner {
        require(_maxAuctionLength <= auctionLengthUpperBound);
        require(_maxAuctionLength > minAuctionLength);
        emit UpdateMaxAuctionLength(maxAuctionLength, _maxAuctionLength);
        maxAuctionLength = _maxAuctionLength;
    }
    
    function setTradingFee(uint _tradingFee) public onlyOwner {
        require(_tradingFee <= tradingFeeUpperBound);
        emit UpdateTradingFee(tradingFee, _tradingFee);
        tradingFee = _tradingFee;
    }
    
    function setGovernanceFee(uint _governanceFee) public onlyOwner {
        require(_governanceFee <= governenceFeeUpperBound);
        emit UpdateGovernanceFee(governanceFee, _governanceFee);
        governanceFee = _governanceFee;
    }
    
    function setFeeClaimer(address _feeClaimer) public onlyOwner {
        emit UpdateFeeClaimer(feeClaimer, _feeClaimer);
        feeClaimer = payable(_feeClaimer);
    }
    
    function setMinBidIncrement(uint _minBidIncrement) public onlyOwner {
        require(_minBidIncrement >= bidIncrementLowerBound);
        require(_minBidIncrement < maxBidIncrement);
        emit UpdateMinBidIncrement(minBidIncrement, _minBidIncrement);
        minBidIncrement = _minBidIncrement;
    }
    
    function setMaxBidIncrement(uint _maxBidIncrement) public onlyOwner {
        require(_maxBidIncrement <= bidIncrementUpperBound);
        require(_maxBidIncrement > minBidIncrement);
        emit UpdateMaxBidIncrement(maxBidIncrement, _maxBidIncrement);
        maxBidIncrement = _maxBidIncrement;
    }
    
    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
    
    function setReservePriceLowerLimitPercentage(uint _reservePriceLowerLimitPercentage) public onlyOwner {
        require(_reservePriceLowerLimitPercentage < reservePriceUpperLimitPercentage);
        emit UpdateReservePriceLowerLimitPercentage(reservePriceLowerLimitPercentage, _reservePriceLowerLimitPercentage);
        reservePriceLowerLimitPercentage = _reservePriceLowerLimitPercentage;
    }
    
    
    function setReservePriceUpperLimitPercentage(uint _reservePriceUpperLimitPercentage) public onlyOwner {
        require(reservePriceLowerLimitPercentage < _reservePriceUpperLimitPercentage);
        emit UpdateReservePriceUpperLimitPercentage(reservePriceUpperLimitPercentage, _reservePriceUpperLimitPercentage);
        reservePriceUpperLimitPercentage = _reservePriceUpperLimitPercentage;
    }
    
    function addAcceptableCurrency(address _currency) public onlyOwner {
        if (!currencyToAcceptableForTrading[_currency]) {
            currencyToAcceptableForTrading[_currency] = true;
            currenciesAcceptableForTrading.push(_currency);
        }
    }
    
    function removeAcceptableCurrency(address _currency) public onlyOwner {
        if (currencyToAcceptableForTrading[_currency]) {
            currencyToAcceptableForTrading[_currency] = false;
            for (uint i = 0; i < currenciesAcceptableForTrading.length; i++) {
                if (currenciesAcceptableForTrading[i] == _currency) {
                    currenciesAcceptableForTrading[i] = currenciesAcceptableForTrading[currenciesAcceptableForTrading.length - 1];
                    break;
                }
            }
            currenciesAcceptableForTrading.pop();
        }
    }
}

// File: remixbackup/FNFT/contracts/libraries/Context.sol



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

// File: remixbackup/FNFT/contracts/libraries/Ownable.sol



pragma solidity ^0.8.0;


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

// File: remixbackup/FNFT/contracts/libraries/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// File: remixbackup/FNFT/contracts/NFTStoreHouse.sol

pragma solidity ^0.8.0;







contract NFTStoreHouse is Ownable, Pausable {
    address public constant eth = address(0);
    
    uint public lockedNFTCount;
    uint public currentNFTIndex = 1;
    mapping(uint => address) public indexToFNFTAddress;
    mapping(address => uint) public fnftAddressToIndex;
    
    address public immutable governanceSettings;
    address public immutable fnftBlueprint;
    
    event LockNFT(address indexed nftContractAddress, uint tokenID, address fnftContractAddress, uint fnftIndex);
    event StartAutcion(address indexed fnftContractAddress, address user, uint price);
    event RedeemWithAllSupply(address indexed fnftContractAddress, address user);
    event AuctionEnd(address indexed fnftContractAddress, address user, uint price);
    event DirectBuyout(address indexed fnftContractAddress, address approver, address buyer, uint price);
    
    constructor() {
        governanceSettings = address(new GlobalGovernanceSettings(msg.sender));
        fnftBlueprint = address(new LockedNFT());
    }
    
    function pause() public onlyOwner {
        super._pause();
    }
    
    function unpause() public onlyOwner {
        super._unpause();
    }
    
    function _lockNFT(
        string memory _name,
        string memory _symbol,
        uint _initialSupply,
        uint _reservePrice,
        address _currency,
        address _lockedNFTContract,
        uint _tokenID,
        uint _votePercentageThreshold,
        uint _portionOfSupplyNeededToStartPrivateBuyout,
        bool _allowDirectBuyout
    ) private whenNotPaused returns (uint) {
        bytes memory implementationCalldata = abi.encodeWithSignature(
            "initialize(address,string,string,uint256,uint256,address,address,uint256,uint256,address,uint256,bool)",
            governanceSettings,
            _name,
            _symbol,
            _initialSupply,
            _reservePrice,
            _currency,
            _lockedNFTContract,
            _tokenID,
            _votePercentageThreshold,
            msg.sender,
            _portionOfSupplyNeededToStartPrivateBuyout,
            _allowDirectBuyout
        );

        address fnftContractAddress = Clones.clone(fnftBlueprint);
        (bool ok,) = fnftContractAddress.call(implementationCalldata);
        require(ok);

        IERC721(_lockedNFTContract).transferFrom(msg.sender, fnftContractAddress, _tokenID);
        indexToFNFTAddress[currentNFTIndex] = fnftContractAddress;
        fnftAddressToIndex[fnftContractAddress] = currentNFTIndex;
        emit LockNFT(_lockedNFTContract, _tokenID, fnftContractAddress, currentNFTIndex);
        
        currentNFTIndex++;
        lockedNFTCount++;
        return currentNFTIndex - 1;
    }
    
    function lockNFTUsingETHForBuyout(
        string memory _name,
        string memory _symbol,
        uint _initialSupply,
        uint _reservePrice,
        address _lockedNFTContract,
        uint _tokenID,
        uint _votePercentageThreshold,
        uint _portionOfSupplyNeededToStartPrivateBuyout,
        bool _allowDirectBuyout
    ) public returns (uint) {
        _lockNFT(
            _name,
            _symbol,
            _initialSupply,
            _reservePrice,
            eth,
            _lockedNFTContract,
            _tokenID,
            _votePercentageThreshold,
            _portionOfSupplyNeededToStartPrivateBuyout,
            _allowDirectBuyout
        );
    }
    
    function lockNFTUsingOtherCurrencyForBuyout(
        string memory _name,
        string memory _symbol,
        uint _initialSupply,
        uint _reservePrice,
        address _currency,
        address _lockedNFTContract,
        uint _tokenID,
        uint _votePercentageThreshold,
        uint _portionOfSupplyNeededToStartPrivateBuyout,
        bool _allowDirectBuyout
    ) public returns (uint) {
        _lockNFT(
            _name,
            _symbol,
            _initialSupply,
            _reservePrice,
            _currency,
            _lockedNFTContract,
            _tokenID,
            _votePercentageThreshold,
            _portionOfSupplyNeededToStartPrivateBuyout,
            _allowDirectBuyout
        );
    }

    function emitStartAuctionEvent(address _user, uint _price) external {
        require(fnftAddressToIndex[msg.sender] >= 1);
        emit StartAutcion(msg.sender, _user, _price);
    }
    
    function emitAuctionEndEvent(address _user, uint _price) external {
        require(fnftAddressToIndex[msg.sender] >= 1);
        emit AuctionEnd(msg.sender, _user, _price);
    }
    
    function emitRedeemWithAllSupplyEvent(address _user) external {
        require(fnftAddressToIndex[msg.sender] >= 1);
        emit RedeemWithAllSupply(msg.sender, _user);
    }
    
    function emitDirectBuyoutEvent(address _approver, address _buyer, uint _price) external {
        require(fnftAddressToIndex[msg.sender] >= 1);
        emit DirectBuyout(msg.sender, _approver, _buyer, _price);
    }
}