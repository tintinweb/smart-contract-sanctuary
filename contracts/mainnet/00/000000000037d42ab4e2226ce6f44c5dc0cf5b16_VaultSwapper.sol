// File: Address.sol

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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

// File: IERC20.sol

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

// File: Initializable.sol

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

// File: SafeERC20.sol

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

// File: VaultSwapper.sol

interface Vault is IERC20 {
    function decimals() external view returns (uint256);

    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);
}

interface StableSwap {
    function remove_liquidity_one_coin(
        uint256 amount,
        int128 i,
        uint256 min_amount
    ) external;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts)
        external
        view
        returns (uint256);
}

interface Registry {
    function get_pool_from_lp_token(address lp) external view returns (address);

    function get_lp_token(address pool) external view returns (address);

    function get_n_coins(address) external view returns (uint256[2] memory);

    function get_coins(address) external view returns (address[8] memory);
}

interface FactoryRegistry {
    function get_coins(address) external view returns (address[4] memory);

    function get_n_coins(address) external view returns (uint256);
}

contract VaultSwapper is Initializable {
    Registry constant registry =
        Registry(0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5);
    FactoryRegistry constant factory_registry =
        FactoryRegistry(0xB9fC157394Af804a3578134A6585C0dc9cc990d4);

    uint256 private constant MIN_AMOUNT_OUT = 1;
    uint256 private constant MAX_DONATION = 10_000;
    uint256 private constant DEFAULT_DONATION = 30;
    uint256 private constant UNKNOWN_ORIGIN = 0;
    address public owner;

    event Orgin(uint256 origin);

    enum Action {
        Deposit,
        Withdraw,
        Swap
    }

    struct Swap {
        Action action;
        address pool;
        uint128 n;
        uint128 m;
    }

    function initialize(address _owner) public initializer {
        owner = _owner;
    }

    function set_owner(address new_owner) public {
        require(owner == msg.sender);
        require(new_owner != address(0));
        owner = new_owner;
    }

    /*
        @notice Swap with apoval using eip-2612
        @param from_vault The vault tokens should be taken from
        @param to_vault The vault tokens should be deposited to
        @param amount The amount of tokens you whish to use from the from_vault
        @param min_amount_out The minimal amount of tokens you would expect from the to_vault
        @param expiry signature expiry
        @param signature signature
    */
    function metapool_swap_with_signature(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        uint256 expiry,
        bytes calldata signature
    ) public {
        metapool_swap_with_signature(
            from_vault,
            to_vault,
            amount,
            min_amount_out,
            expiry,
            signature,
            DEFAULT_DONATION,
            UNKNOWN_ORIGIN
        );
    }

    function metapool_swap_with_signature(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        uint256 expiry,
        bytes calldata signature,
        uint256 donation,
        uint256 origin
    ) public {
        assert(
            Vault(from_vault).permit(
                msg.sender,
                address(this),
                amount,
                expiry,
                signature
            )
        );
        metapool_swap(
            from_vault,
            to_vault,
            amount,
            min_amount_out,
            donation,
            origin
        );
    }

    /**
        @notice swap tokens from one meta pool vault to an other
        @dev Remove funds from a vault, move one side of 
        the asset from one curve pool to an other and 
        deposit into the new vault.
        @param from_vault The vault tokens should be taken from
        @param to_vault The vault tokens should be deposited to
        @param amount The amount of tokens you whish to use from the from_vault
        @param min_amount_out The minimal amount of tokens you would expect from the to_vault
    */
    function metapool_swap(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out
    ) public {
        metapool_swap(
            from_vault,
            to_vault,
            amount,
            min_amount_out,
            DEFAULT_DONATION,
            UNKNOWN_ORIGIN
        );
    }

    function metapool_swap(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        uint256 donation,
        uint256 origin
    ) public {
        address underlying = Vault(from_vault).token();
        address target = Vault(to_vault).token();

        address underlying_pool = _get_pool_from_lp_token(underlying);
        address target_pool = _get_pool_from_lp_token(target);

        Vault(from_vault).transferFrom(msg.sender, address(this), amount);
        uint256 underlying_amount = Vault(from_vault).withdraw(
            amount,
            address(this)
        );
        StableSwap(underlying_pool).remove_liquidity_one_coin(
            underlying_amount,
            1,
            1
        );

        IERC20 underlying_coin = IERC20(_get_coin(underlying_pool, 1));
        uint256 liquidity_amount = underlying_coin.balanceOf(address(this));

        underlying_coin.approve(target_pool, liquidity_amount);

        StableSwap(target_pool).add_liquidity(
            [0, liquidity_amount],
            MIN_AMOUNT_OUT
        );

        uint256 target_amount = IERC20(target).balanceOf(address(this));
        if (donation != 0) {
            uint256 donating = (target_amount * donation) / MAX_DONATION;
            SafeERC20.safeTransfer(IERC20(target), owner, donating);
            target_amount -= donating;
        }

        approve(target, to_vault, target_amount);

        uint256 out = Vault(to_vault).deposit(target_amount, msg.sender);

        require(out >= min_amount_out, "out too low");
        if (origin != UNKNOWN_ORIGIN) {
            emit Orgin(origin);
        }
    }

    /**
        @notice estimate the amount of tokens out
        @param from_vault The vault tokens should be taken from
        @param to_vault The vault tokens should be deposited to
        @param amount The amount of tokens you whish to use from the from_vault
        @return the amount of token shared expected in the to_vault
     */
    function metapool_estimate_out(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 donation
    ) public view returns (uint256) {
        address underlying = Vault(from_vault).token();
        address target = Vault(to_vault).token();

        address underlying_pool = _get_pool_from_lp_token(underlying);
        address target_pool = _get_pool_from_lp_token(target);

        uint256 pricePerShareFrom = Vault(from_vault).pricePerShare();
        uint256 pricePerShareTo = Vault(to_vault).pricePerShare();

        uint256 amount_out = (pricePerShareFrom * amount) /
            (10**Vault(from_vault).decimals());
        amount_out = StableSwap(underlying_pool).calc_withdraw_one_coin(
            amount_out,
            1
        );
        amount_out = StableSwap(target_pool).calc_token_amount(
            [0, amount_out],
            true
        );
        amount_out -= (amount_out * donation) / MAX_DONATION;
        return
            (amount_out * (10**Vault(to_vault).decimals())) / pricePerShareTo;
    }

    function swap_with_signature(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        Swap[] calldata instructions,
        uint256 expiry,
        bytes calldata signature
    ) public {
        swap_with_signature(
            from_vault,
            to_vault,
            amount,
            min_amount_out,
            instructions,
            expiry,
            signature,
            DEFAULT_DONATION,
            UNKNOWN_ORIGIN
        );
    }

    function swap_with_signature(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        Swap[] calldata instructions,
        uint256 expiry,
        bytes calldata signature,
        uint256 donation,
        uint256 origin
    ) public {
        assert(
            Vault(from_vault).permit(
                msg.sender,
                address(this),
                amount,
                expiry,
                signature
            )
        );
        swap(
            from_vault,
            to_vault,
            amount,
            min_amount_out,
            instructions,
            donation,
            origin
        );
    }

    function swap(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        Swap[] calldata instructions
    ) public {
        swap(
            from_vault,
            to_vault,
            amount,
            min_amount_out,
            instructions,
            DEFAULT_DONATION,
            UNKNOWN_ORIGIN
        );
    }

    function swap(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        Swap[] calldata instructions,
        uint256 donation,
        uint256 origin
    ) public {
        address token = Vault(from_vault).token();
        address target = Vault(to_vault).token();

        Vault(from_vault).transferFrom(msg.sender, address(this), amount);
        amount = Vault(from_vault).withdraw(amount, address(this));

        uint256 n_coins;
        for (uint256 i = 0; i < instructions.length; i++) {
            if (instructions[i].action == Action.Deposit) {
                n_coins = _get_n_coins(instructions[i].pool);
                uint256[] memory list = new uint256[](n_coins);
                list[instructions[i].n] = amount;
                approve(token, instructions[i].pool, amount);

                if (n_coins == 2) {
                    StableSwap(instructions[i].pool).add_liquidity(
                        [list[0], list[1]],
                        1
                    );
                } else if (n_coins == 3) {
                    StableSwap(instructions[i].pool).add_liquidity(
                        [list[0], list[1], list[2]],
                        1
                    );
                } else if (n_coins == 4) {
                    StableSwap(instructions[i].pool).add_liquidity(
                        [list[0], list[1], list[2], list[3]],
                        1
                    );
                }

                token = _get_lp_token_from_pool(instructions[i].pool);
                amount = IERC20(token).balanceOf(address(this));
            } else if (instructions[i].action == Action.Withdraw) {
                token = _get_coin(instructions[i].pool, instructions[i].n);
                amount = remove_liquidity_one_coin(
                    token,
                    instructions[i].pool,
                    amount,
                    instructions[i].n
                );
            } else {
                approve(token, instructions[i].pool, amount);
                token = _get_coin(instructions[i].pool, instructions[i].m);
                amount = _exchange(
                    token,
                    instructions[i].pool,
                    amount,
                    instructions[i].n,
                    instructions[i].m
                );
            }
        }

        require(target == token, "!path");

        if (donation != 0) {
            uint256 donating = (amount * donation) / MAX_DONATION;
            SafeERC20.safeTransfer(IERC20(target), owner, donating);
            amount -= donating;
        }
        approve(target, to_vault, amount);
        uint256 out = Vault(to_vault).deposit(amount, msg.sender);

        require(out >= min_amount_out, "out too low");
        if (origin != UNKNOWN_ORIGIN) {
            emit Orgin(origin);
        }
    }

    function remove_liquidity_one_coin(
        address token,
        address pool,
        uint256 amount,
        uint128 n
    ) internal returns (uint256) {
        uint256 amountBefore = IERC20(token).balanceOf(address(this));
        pool.call(
            abi.encodeWithSignature(
                "remove_liquidity_one_coin(uint256,uint256,uint256)",
                amount,
                uint256(n),
                1
            )
        );
        uint256 newAmount = IERC20(token).balanceOf(address(this));

        if (newAmount > amountBefore) {
            return newAmount;
        }
        pool.call(
            abi.encodeWithSignature(
                "remove_liquidity_one_coin(uint256,int128,uint256)",
                amount,
                int128(n),
                1
            )
        );

        newAmount = IERC20(token).balanceOf(address(this));
        require(newAmount > amountBefore, "!remove");

        return newAmount;
    }

    function estimate_out(
        address from_vault,
        address to_vault,
        uint256 amount,
        Swap[] calldata instructions,
        uint256 donation
    ) public view returns (uint256) {
        uint256 pricePerShareFrom = Vault(from_vault).pricePerShare();
        uint256 pricePerShareTo = Vault(to_vault).pricePerShare();
        amount =
            (amount * pricePerShareFrom) /
            (10**Vault(from_vault).decimals());
        for (uint256 i = 0; i < instructions.length; i++) {
            uint256 n_coins = _get_n_coins(instructions[i].pool);
            if (instructions[i].action == Action.Deposit) {
                n_coins = _get_n_coins(instructions[i].pool);
                uint256[] memory list = new uint256[](n_coins);
                list[instructions[i].n] = amount;

                if (n_coins == 2) {
                    try
                        StableSwap(instructions[i].pool).calc_token_amount(
                            [list[0], list[1]],
                            true
                        )
                    returns (uint256 _amount) {
                        amount = _amount;
                    } catch {
                        amount = StableSwap(instructions[i].pool)
                            .calc_token_amount([list[0], list[1]]);
                    }
                } else if (n_coins == 3) {
                    try
                        StableSwap(instructions[i].pool).calc_token_amount(
                            [list[0], list[1], list[2]],
                            true
                        )
                    returns (uint256 _amount) {
                        amount = _amount;
                    } catch {
                        amount = StableSwap(instructions[i].pool)
                            .calc_token_amount([list[0], list[1], list[2]]);
                    }
                } else if (n_coins == 4) {
                    try
                        StableSwap(instructions[i].pool).calc_token_amount(
                            [list[0], list[1], list[2], list[3]],
                            true
                        )
                    returns (uint256 _amount) {
                        amount = _amount;
                    } catch {
                        amount = StableSwap(instructions[i].pool)
                            .calc_token_amount(
                                [list[0], list[1], list[2], list[3]]
                            );
                    }
                }
            } else if (instructions[i].action == Action.Withdraw) {
                amount = _calc_withdraw_one_coin(
                    instructions[i].pool,
                    amount,
                    instructions[i].n
                );
            } else {
                amount = _calc_exchange(
                    instructions[i].pool,
                    amount,
                    instructions[i].n,
                    instructions[i].m
                );
            }
        }
        amount -= (amount * donation) / MAX_DONATION;
        return (amount * (10**Vault(to_vault).decimals())) / pricePerShareTo;
    }

    function approve(
        address target,
        address to_vault,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(target).allowance(address(this), to_vault);
        if (allowance < amount) {
            if (allowance != 0) {
                SafeERC20.safeApprove(IERC20(target), to_vault, 0);
            }
            SafeERC20.safeApprove(IERC20(target), to_vault, type(uint256).max);
        }
    }

    function _calc_withdraw_one_coin(
        address pool,
        uint256 amount,
        uint128 n
    ) internal view returns (uint256) {
        (bool success, bytes memory returnData) = pool.staticcall(
            abi.encodeWithSignature(
                "calc_withdraw_one_coin(uint256,uint256)",
                amount,
                uint256(n)
            )
        );
        if (success) {
            return abi.decode(returnData, (uint256));
        }
        (success, returnData) = pool.staticcall(
            abi.encodeWithSignature(
                "calc_withdraw_one_coin(uint256,int128)",
                amount,
                int128(n)
            )
        );

        require(success, "!success");

        return abi.decode(returnData, (uint256));
    }

    function _get_coin(address pool, uint256 n)
        internal
        view
        returns (address)
    {
        address token = registry.get_coins(pool)[n];
        if (token != address(0x0)) return token;
        return factory_registry.get_coins(pool)[n];
    }

    function _get_pool_from_lp_token(address lp)
        internal
        view
        returns (address)
    {
        address pool = registry.get_pool_from_lp_token(lp);
        if (pool == address(0x0)) {
            return lp;
        } else {
            return pool;
        }
    }

    function _exchange(
        address token,
        address pool,
        uint256 amount,
        uint128 n,
        uint128 m
    ) internal returns (uint256) {
        uint256 amountBefore = IERC20(token).balanceOf(address(this));

        pool.call(
            abi.encodeWithSignature(
                "exchange(uint256,uint256,uint256,uint256)",
                uint256(n),
                uint256(m),
                amount,
                1
            )
        );

        uint256 newAmount = IERC20(token).balanceOf(address(this));

        if (newAmount > amountBefore) {
            return newAmount;
        }

        pool.call(
            abi.encodeWithSignature(
                "exchange(int128,int128,uint256,uint256)",
                int128(n),
                int128(m),
                amount,
                1
            )
        );

        newAmount = IERC20(token).balanceOf(address(this));
        require(newAmount > amountBefore, "!exchange");
        return newAmount;
    }

    function _calc_exchange(
        address pool,
        uint256 amount,
        uint128 n,
        uint128 m
    ) internal view returns (uint256) {
        (bool success, bytes memory returnData) = pool.staticcall(
            abi.encodeWithSignature(
                "get_dy(uint256,uint256,uint256)",
                uint256(n),
                uint256(m),
                amount
            )
        );
        if (success) {
            return abi.decode(returnData, (uint256));
        }
        (success, returnData) = pool.staticcall(
            abi.encodeWithSignature(
                "get_dy(int128,int128,uint256)",
                int128(n),
                int128(m),
                amount
            )
        );

        require(success, "!success");

        return abi.decode(returnData, (uint256));
    }

    function _get_lp_token_from_pool(address pool)
        internal
        view
        returns (address)
    {
        address token = registry.get_lp_token(pool);
        if (token != address(0x0)) return token;
        return pool;
    }

    function _get_n_coins(address pool) internal view returns (uint256) {
        uint256 num = registry.get_n_coins(pool)[0];
        if (num != 0) return num;
        return factory_registry.get_n_coins(pool);
    }
}