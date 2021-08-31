/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
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
        return msg.data;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    /**
     * @dev Sets the values for {name}, {symbol} and {desimals}.
     *
     * This function must only be called once during initizliation.
     */
    function _initializeErc20(string calldata name_, string calldata symbol_, uint8 decimals_) internal {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
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
    ) external virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
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

/**
 * @dev Struct that holds info related to vesting balance of a particular user/address.
 */
struct User {
    /**
     * @dev The amount of vesting tokens that becomes available for swap to original tokens
     * in 1:1 proportion at TGE (Token Generation Event) moment.
     */
    uint256 tgeAmount;
    
    /**
     * @dev The amount of vesting tokens that already became available for swap to original
     * tokens in 1:1 proportion during main vesting phase (vesting ticks).
     */
    uint256 unlockedTickAmount;
    
    /**
     * @dev The last vesting tick number at which the {unlockedTickAmount} state was updated.
     */
    uint256 lastUpdateTick;
}

/**
 * @dev Struct that holds info about the vesting schedule.
 * 
 * Vesting time line:
 * 
 *             TGE                            start                    end
 * -------------|-------------------------------|--+--+--+--+--+--+--+--|------------
 *                        cliff duration                 duration
 * 
 * where every {+} is a tick timestamp and {+--+} is a tick period.
 */
struct Vesting {
    /**
     * @dev The period of vesting tick in seconds. The minimal acceptable/valid value is 60 seconds.
     */
    uint256 tickPeriod;
    
    /**
     * @dev The percentage of original tokens to be unlocked at Token Generation Event (TGE) moment
     * in basis points. The max acceptable/valid value is 10000 basis points which is equal to 100%.
     */
    uint16 tgePercentage;

    /**
     * @dev The timestamp in which the Token Generation Event (TGE) occurs.
     */
    uint256 tgeTimestamp;
    
    /**
     * @dev The vesting cliff duration in seconds.
     */
    uint256 cliffDuration;

    /**
     * @dev The total vesting ticks duration in seconds.
     */
    uint256 duration;
}

/**
 * @dev Collection of functions related to the {Vesting} type.
 */
library VestingLib {
    event InitializeVesting(Vesting vesting);
    event SetTgeTimestamp(uint256 tgeTimestamp);
    
    modifier onlyBeforeTge(Vesting storage _self) {
        require(_self.tgeTimestamp == 0 || block.timestamp < _self.tgeTimestamp, "TGE already occured");
        _;
    }
    
    /**
     * @dev Initializes the vesting schedule. This function must be called only once.
     * The {Vesting.tgeTimestamp} can be changed later via {setTgeTimestamp} function.
     */
    function initialize(Vesting storage _self, Vesting calldata _data) internal onlyBeforeTge(_self) {
        require(_data.tickPeriod >= 60, "tick period too small");
        require(_data.tgePercentage <= 10000, "TGE percentage exceeds 100%");
        require(_data.duration >= 60, "duration too small");
        
        _self.tickPeriod = _data.tickPeriod;
        _self.tgePercentage = _data.tgePercentage;
        _self.tgeTimestamp = _data.tgeTimestamp;
        _self.cliffDuration = _data.cliffDuration;
        _self.duration = _data.duration;
        
        emit InitializeVesting(_data);
    }
    
    /**
     * @dev Sets {Vesting.tgeTimestamp} but only if old {Vesting.tgeTimestamp} is not set
     * or did not pass yet.
     */
    function setTgeTimestamp(Vesting storage _self, uint256 _tgeTimestamp) internal onlyBeforeTge(_self) {
        _self.tgeTimestamp = _tgeTimestamp;
        
        emit SetTgeTimestamp(_tgeTimestamp);
    }
    
    /**
     * @dev Returns current vesing tick number by current {block.timestamp}. Ticks numeration starts
     * from 1. If function returned 0 it means that not a single tick has passed yet.
     */
    function currentTick(Vesting storage _self) internal view returns (uint256) {
        if (_self.tgeTimestamp == 0) return 0; // vesting is not yet fully initialized
        
        uint256 startTickTimestamp = _self.tgeTimestamp + _self.cliffDuration;
        uint256 endTickTimestamp = startTickTimestamp + _self.duration;
        
        if (block.timestamp < startTickTimestamp) return 0;
            
        if (block.timestamp >= endTickTimestamp) {
            return lastTick(_self);
        }
        
        return (block.timestamp - startTickTimestamp) / _self.tickPeriod;
    }
    
    /**
     * @dev Returns last vesting tick number (wich equals to total amount of ticks).
     */
    function lastTick(Vesting storage _self) internal view returns (uint256) {
        if (_self.tgeTimestamp == 0) return 0; // vesting is not yet fully initialized
        
        uint256 tick = _self.duration / _self.tickPeriod;

        if (_self.duration % _self.tickPeriod != 0) {
            ++tick;
        }
            
        return tick;
    }
}

/**
 * @dev Struct that holds info related to airdrop for particular recipient.
 */
struct Recipient {
    address addr;
    uint256 amount;
}

/**
 * @dev This is a contract of vesting token. Vesting token represents the right of its holder to get
 * original token (contract collateral) that will be gradually unlocked by vesting schedule. Vesting
 * tokens may be freely transfered by its holders. By transfering some amount of vesting tokens holder
 * transfers the right to get corresponding amount of original tokens in 1:1 proportion.
 */
contract VestingToken is ERC20, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    using VestingLib for Vesting;
    
    /**
     * @dev The only address which is authorized to call {setTgeTimestamp} function.
     */
    address public admin_;
    
    /**
     * @dev The original token that will be gradually unlocked for vesting token holders by vesting
     * schedule.
     */
    IERC20Metadata public originalToken_;
    
    /**
     * @dev Mapping that holds info related to vesting balance of a every user/address.
     */
    mapping(address => User) public users_;
    
    /**
     * @dev The vesting schedule configuration for this contract.
     */
    Vesting public vesting_;
    
    event Airdrop(address indexed caller, address indexed minter, Recipient[] recipients);
    event SwapToOriginal(address indexed caller, uint256 amount);
    
    /**
     * @dev This contract is supposed to be used as logic implementation that will be pointed to by
     * minimal proxy contract. {initialize} function sets all of the initial state for the contract.
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _admin,
        IERC20Metadata _originalToken,
        Vesting calldata _vesting,
        address _minter,
        Recipient[] calldata _recipients) external initializer {
        
        _initializeErc20(_name, _symbol, _originalToken.decimals());
        
        admin_ = _admin;
        originalToken_ = _originalToken;
        
        vesting_.initialize(_vesting);
        
        if (_recipients.length > 0) {
            _airdrop(_minter, _recipients);
        }
    }
    
    modifier onlyAdmin() {
        require(admin_ == _msgSender(), "auth failed");
        _;
    }
    
    /**
     * @dev Sets the Token Generation Event timestamp but only if old value is not set or did not
     * pass yet. Only {admin_} is authorized to call this function.
     */
    function setTgeTimestamp(uint256 _tgeTimestamp) external onlyAdmin {
        vesting_.setTgeTimestamp(_tgeTimestamp);
    }
    
    /**
     * @dev Anyone who's willing to give enough original tokens as a collateral can call this
     * function to mint vesting tokens for specified recipients.
     */
    function airdrop(Recipient[] calldata _recipients) external {
        _airdrop(_msgSender(), _recipients);
    }
    
    /**
     * @dev Returns current state related to vesting balance of a particular user/address.
     * 
     * @param _userAddr The address of user to get state for.
     * 
     * @return timestamp The timestamp of the most recent block in blockchain.
     * @return totalBalance Total balance of vesting tokens of {_userAddr} user.
     * @return unlockedAmount The maximum amount of vesting tokens on {_userAddr} balance that
     * can be swapped to original tokens at the moment.
     * @return lockedAmount The amount of vesting tokens on {_userAddr} balance that cannot
     * be swapped to original tokens yet but will be unlocked for swap in future.
     */
    function vestingBalance(address _userAddr) external view
        returns (
            uint256 timestamp,
            uint256 totalBalance,
            uint256 unlockedAmount,
            uint256 lockedAmount) {

        timestamp = block.timestamp;

        totalBalance = balanceOf(_userAddr);

        unlockedAmount = users_[_userAddr].unlockedTickAmount;
        unlockedAmount += _calcNewUnlockedTickAmount(_userAddr, vesting_.currentTick());
        unlockedAmount += _calcUnlockedTgeAmount(_userAddr);

        lockedAmount = totalBalance - unlockedAmount;
    }
    
    /**
     * @dev By calling this function user/address is able to swap specified amount of vesting tokens
     * to original tokens in 1:1 proportion. Maximum amount to swap is limited by unlocked balance
     * of user/address which is calculated by vesting schedule, total user/address balance and the
     * timestamp of the most recent block in blockchain.
     */
    function swapToOriginal(uint256 _amount) external {
        address msgSender = _msgSender();

        _updateUser(msgSender, vesting_.currentTick());

        _swapToOriginal(msgSender, _amount);
    }
    
    /**
     * @dev Works like {swapToOriginal} function except the amount of tokens to swap will be equal to
     * the entire unlocked balance of user/address.
     */
    function swapToOriginalMax() external {
        address msgSender = _msgSender();

        _updateUser(msgSender, vesting_.currentTick());

        _swapToOriginal(
            msgSender,
            users_[msgSender].unlockedTickAmount + _calcUnlockedTgeAmount(msgSender));
    }
    
    function _swapToOriginal(address _msgSender, uint256 _amount) private {
        User storage user = users_[_msgSender];

        require(_amount > 0, "zero swap amount");

        require(
            _amount <= user.unlockedTickAmount + _calcUnlockedTgeAmount(_msgSender),
            "amount exceeds unlocked balance");

        if (_amount <= user.tgeAmount) {
            user.tgeAmount -= _amount;
        } else {
            user.unlockedTickAmount -= _amount - user.tgeAmount;
            delete user.tgeAmount;
        }

        _burn(_msgSender, _amount);
        originalToken_.safeTransfer(_msgSender, _amount);
        
        emit SwapToOriginal(_msgSender, _amount);
    }
    
    /**
     * @dev This function mints vesting tokens for specified recipients and takes original tokens
     * from {_minter} as a collateral.
     */
    function _airdrop(address _minter, Recipient[] calldata _recipients) private nonReentrant {
        require(_recipients.length > 0, "empty recipient list");

        uint256 totalAmount;

        // mint vesting tokens for specified recipients
        for (uint16 i = 0; i < _recipients.length; ++i) {
            totalAmount += _recipients[i].amount;
            
            _mint(_recipients[i].addr, _recipients[i].amount);
            
            users_[_recipients[i].addr].tgeAmount
                += _recipients[i].amount * vesting_.tgePercentage / 10000;
        }
        
        // get collateral in original tokens for airdrop
        originalToken_.safeTransferFrom(_minter, address(this), totalAmount);
        
        emit Airdrop(_msgSender(), _minter, _recipients);
    }

    /**
     * @dev This function is called before any vesting token transfer (including mint and burn).
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount) internal virtual override {
            
        if (_from == address(0) || _to == address(0)) { // mint or burn
            return;
        }
        
        // transfer from user to user
        _onBeforeUserToUserTransfer(_from, _to, _amount);
    }
    
    /**
     * @dev This function is called before any vesting token transfer from user to another user.
     * 
     * Vesting balance of any user/address consists of following parts:
     * 1) Golden balance - the sum of user's {User.tgeAmount} and {User.unlockedTickAmount}.
     * 2) Gray balance - the rest of user's vesting token balance.
     * 
     * The strategy for transfering vesting balance is following: in the first place only gray
     * balance is transfered and only if all of the gray balance is exhausted then golden balance
     * is also transfered.
     */
    function _onBeforeUserToUserTransfer(address _from, address _to, uint256 _amount) private {
        if (_from == _to) return;
        
        uint256 currentTick = vesting_.currentTick();

        _updateUser(_from, currentTick);
        _updateUser(_to, currentTick);

        User storage userTo = users_[_to];
        User storage userFrom = users_[_from];

        uint256 fromGoldenAmount = userFrom.tgeAmount + userFrom.unlockedTickAmount;
        uint256 fromGrayAmount = balanceOf(_from) - fromGoldenAmount;

        if (_amount > fromGrayAmount) { // golden amount is also transfered
            uint256 transferGoldenAmount = _amount - fromGrayAmount;
        
            if (transferGoldenAmount <= userFrom.tgeAmount) {
                userFrom.tgeAmount -= transferGoldenAmount;
                userTo.tgeAmount += transferGoldenAmount;
            } else {
                uint256 transferUnlockedTickAmount = transferGoldenAmount - userFrom.tgeAmount;
                
                userFrom.unlockedTickAmount -= transferUnlockedTickAmount;
                userTo.unlockedTickAmount += transferUnlockedTickAmount;
                
                userTo.tgeAmount += userFrom.tgeAmount;
                delete userFrom.tgeAmount;
            }
        }
    }

    /**
     * @dev Updates the {_userAddr} user state related to the main vesting phase (vesting ticks).
     */
    function _updateUser(address _userAddr, uint256 _currentTick) private {
        if (_currentTick == 0) return;
        
        User storage user = users_[_userAddr];
        
        if (user.lastUpdateTick == vesting_.lastTick()) return;
        
        user.unlockedTickAmount += _calcNewUnlockedTickAmount(_userAddr, _currentTick);
        user.lastUpdateTick = _currentTick;
    }
    
    /**
     * @dev Returns current amount of vesting tokens that had been unlocked for {_userAddr} user at
     * TGE (Token Generation Event) moment and currently are available for swap to original tokens.
     */
    function _calcUnlockedTgeAmount(address _userAddr) private view returns (uint256) {
        if (vesting_.tgeTimestamp == 0 || block.timestamp < vesting_.tgeTimestamp) {
            return 0;
        }
        
        return users_[_userAddr].tgeAmount;
    }
    
    /**
     * @dev This function is called before vesting token is minted to someone's address. Returns the
     * balance that must be added to the {User.unlockedAmount}.
     */
    function _calcNewUnlockedTickAmountByMintAmount(
        uint256 _ticksMintAmount,
        uint256 _currentTick) private view returns (uint256) {

        if (_currentTick == 0) return 0;

        uint256 result = _ticksMintAmount * _currentTick;
        result /= vesting_.lastTick();

        return result;
    }

    /**
     * @dev Returns the amount of vesting tokens that have been unlocked for swap to original tokens
     * during main vesting phase (vesting ticks) since last update.
     */
    function _calcNewUnlockedTickAmount(
        address _userAddr,
        uint256 _currentTick) private view returns (uint256) {
            
        if (_currentTick == 0) return 0;
        
        User storage user = users_[_userAddr];

        uint256 totalTicksBalance = balanceOf(_userAddr) - user.tgeAmount;
        
        if (totalTicksBalance == 0) return 0;
        
        uint256 result = totalTicksBalance - user.unlockedTickAmount;
        
        if (_currentTick == vesting_.lastTick()) return result;
        
        uint256 ticksPassed = _currentTick - user.lastUpdateTick;

        if (ticksPassed == 0) return 0;
        
        result *= ticksPassed;
        result /= vesting_.lastTick() - user.lastUpdateTick;

        return result;
    }
}