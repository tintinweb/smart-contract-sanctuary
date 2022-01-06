// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {Math} from "Math.sol";
import {Ownable} from "Ownable.sol";

import {RegistryAPI, VaultAPI} from "YearnAPI.sol";

/**
 * Adapted from the Yearn BaseRouter for Shapeshift's use case of a router that forward native vault tokens
 * to the caller and does not hold any funds or assets (vault tokens or other ERC20 tokens)
 */
contract ShapeShiftDAORouter is Ownable {
    RegistryAPI public registry;

    // ERC20 Unlimited Approvals (short-circuits VaultAPI.transferFrom)
    uint256 constant UNLIMITED_APPROVAL = type(uint256).max;

    // Sentinel values used to save gas on deposit/withdraw/migrate
    // NOTE: UNLIMITED_APPROVAL == DEPOSIT_EVERYTHING == WITHDRAW_EVERYTHING == MIGRATE_EVERYTHING = MAX_VAULT_ID
    uint256 constant DEPOSIT_EVERYTHING = type(uint256).max;
    uint256 constant WITHDRAW_EVERYTHING = type(uint256).max;
    uint256 constant MIGRATE_EVERYTHING = type(uint256).max;
    uint256 constant MAX_VAULT_ID = type(uint256).max;

    constructor(address yearnRegistry) {
        // Recommended to use `v2.registry.ychad.eth`
        registry = RegistryAPI(yearnRegistry);
    }

    /**
     * @notice Used to update the yearn registry. The choice of registry is SECURITY SENSITIVE, so only the
     * owner can update it.
     * @param yearnRegistry The new registry address.
     */
    function setRegistry(address yearnRegistry) external onlyOwner() {
        address currentYearnGovernanceAddress = registry.governance();
        // In case you want to override the registry instead of re-deploying
        registry = RegistryAPI(yearnRegistry);
        // Make sure there's no change in governance
        // NOTE: Also avoid bricking the router from setting a bad registry
        require(
            currentYearnGovernanceAddress == registry.governance(),
            "invalid registry"
        );
    }

    function numVaults(address token) external view returns (uint256) {
        return registry.numVaults(token);
    }

    function vaults(address token, uint256 deploymentId)
        external
        view
        returns (VaultAPI)
    {
        return registry.vaults(token, deploymentId);
    }

    function latestVault(address token) external view returns (VaultAPI) {
        return registry.latestVault(token);
    }

    /**
     * @notice Gets the balance of an account across all the vaults for a token.
     * @param token Which ERC20 token to pull vault balances for
     * @param account The address of the account to pull the balances for
     * @return The current value, in token base units, of the shares held by the specified
       account across all the vaults for the specified token.
     */
    function totalVaultBalance(address token, address account)
        external
        view
        returns (uint256)
    {
        return this.totalVaultBalance(token, account, 0, MAX_VAULT_ID);
    }

    /**
     * @notice Gets the balance of an account across certain vaults for a token.
     * @param token Which ERC20 token to pull vault balances for
     * @param account The address of the account to pull the balances for
     * @param firstVaultId First vault id to include; 0 to start at the beginning
     * @param lastVaultId Last vault id to include; `MAX_VAULT_ID` to include all vaults
     * @return balance The current value, in token base units, of the shares held by the specified
       account across all the specified vaults for the specified token.
     */
    function totalVaultBalance(
        address token,
        address account,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) external view returns (uint256 balance) {
        require(firstVaultId <= lastVaultId);

        uint256 _lastVaultId = lastVaultId;
        if (_lastVaultId == MAX_VAULT_ID)
            _lastVaultId = registry.numVaults(address(token)) - 1;

        for (uint256 i = firstVaultId; i <= _lastVaultId; i++) {
            VaultAPI vault = registry.vaults(token, i);
            uint256 vaultTokenBalance = (vault.balanceOf(account) *
                vault.pricePerShare()) / 10**vault.decimals();
            balance += vaultTokenBalance;
        }
    }

    /**
     * @notice Returns the combined TVL for all the vaults for a specified token.
     * @return assets The sum of all the assets managed by the vaults for the specified token.
     */
    function totalAssets(address token) external view returns (uint256) {
        return this.totalAssets(token, 0, MAX_VAULT_ID);
    }

    /**
     * @notice Returns the combined TVL for all the specified vaults for a specified token.
     * @param firstVaultId First vault id to include; 0 to start at the beginning
     * @param lastVaultId Last vault id to include; `MAX_VAULT_ID` to include all vaults
     * @return assets The sum of all the assets managed by the vaults for the specified token.
     */
    function totalAssets(
        address token,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) external view returns (uint256 assets) {
        require(firstVaultId <= lastVaultId);

        uint256 _lastVaultId = lastVaultId;
        if (_lastVaultId == MAX_VAULT_ID)
            _lastVaultId = registry.numVaults(address(token)) - 1;

        for (uint256 i = firstVaultId; i <= _lastVaultId; i++) {
            VaultAPI vault = registry.vaults(token, i);
            assets += vault.totalAssets();
        }
    }

    /**
     * @notice Called to deposit the caller's tokens into the most-current vault, crediting the minted shares to recipient.
     * @dev The caller must approve this contract to utilize the specified ERC20 or this call will revert.
     * @param token Address of the ERC20 token being deposited
     * @param recipient Address to receive the issued vault tokens
     * @param amount Amount of tokens to deposit; tokens that cannot be deposited will be refunded. If `DEPOSIT_EVERYTHING`, just deposit everything.
     * @return Total vault shares received by recipient
     */
    function deposit(
        address token,
        address recipient,
        uint256 amount
    ) external returns (uint256) {
        return
            _deposit(
                IERC20(token),
                _msgSender(),
                recipient,
                amount,
                MAX_VAULT_ID
            );
    }

    /**
     * @notice Called to deposit the caller's tokens into a specific vault, crediting the minted shares to recipient.
     * @dev The caller must approve this contract to utilize the specified ERC20 or this call will revert.
     * @param token Address of the ERC20 token being deposited
     * @param recipient Address to receive the issued vault tokens
     * @param amount Amount of tokens to deposit; tokens that cannot be deposited will be refunded. If `DEPOSIT_EVERYTHING`, just deposit everything.
     * @param vaultId Vault id to deposit into; pass `MAX_VAULT_ID` to deposit into the latest vault
     * @return Total vault shares received by recipient
     */
    function deposit(
        address token,
        address recipient,
        uint256 amount,
        uint256 vaultId
    ) external returns (uint256) {
        return
            _deposit(IERC20(token), _msgSender(), recipient, amount, vaultId);
    }

    /**
     * @notice Called to deposit depositor's tokens into a specific vault, crediting the minted shares to recipient.
     * @dev Depositor must approve this contract to utilize the specified ERC20 or this call will revert.
     * @param token Address of the ERC20 token being deposited
     * @param depositor Address to pull deposited funds from. SECURITY SENSITIVE.
     * @param recipient Address to receive the issued vault tokens
     * @param amount Amount of tokens to deposit; tokens that cannot be deposited will be refunded. If `DEPOSIT_EVERYTHING`, just deposit everything.
     * @param vaultId Vault id to deposit into; pass `MAX_VAULT_ID` to deposit into the latest vault
     * @return shares Total vault shares received by recipient
     */
    function _deposit(
        IERC20 token,
        address depositor,
        address recipient,
        uint256 amount,
        uint256 vaultId
    ) internal returns (uint256 shares) {
        bool pullFunds = depositor != address(this);

        VaultAPI vault;
        if (vaultId == MAX_VAULT_ID) {
            vault = registry.latestVault(address(token));
        } else {
            vault = registry.vaults(address(token), vaultId);
        }

        if (token.allowance(address(this), address(vault)) < amount) {
            SafeERC20.safeApprove(token, address(vault), 0); // Avoid issues with some tokens requiring 0
            SafeERC20.safeApprove(token, address(vault), UNLIMITED_APPROVAL); // Vaults are trusted
        }

        if (amount == DEPOSIT_EVERYTHING) amount = token.balanceOf(depositor);

        if (pullFunds) {
            uint256 beforeBal = token.balanceOf(address(this));
            SafeERC20.safeTransferFrom(token, depositor, address(this), amount);

            shares = vault.deposit(amount, recipient);

            uint256 afterWithdrawBal = token.balanceOf(address(this));
            if (afterWithdrawBal > beforeBal)
                SafeERC20.safeTransfer(
                    token,
                    depositor,
                    afterWithdrawBal - beforeBal
                );
        } else {
            shares = vault.deposit(amount, recipient);
        }
    }

    /**
     * @notice Called to redeem the all of the caller's shares from underlying vault(s), with the proceeds distributed to recipient.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from vaults
     * @param recipient Address to receive the withdrawn tokens
     * @return The number of tokens received by recipient.
     */
    function withdraw(address token, address recipient)
        external
        returns (uint256)
    {
        return
            _withdraw(
                IERC20(token),
                _msgSender(),
                recipient,
                WITHDRAW_EVERYTHING,
                0,
                MAX_VAULT_ID
            );
    }

    /**
     * @notice Called to redeem the caller's shares from underlying vault(s), with the proceeds distributed to recipient.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from vaults
     * @param recipient Address to receive the withdrawn tokens
     * @param amount Maximum number of tokens to withdraw from all vaults; actual withdrawal may be less. If `WITHDRAW_EVERYTHING`, just withdraw everything.
     * @return The number of tokens received by recipient.
     */
    function withdraw(
        address token,
        address recipient,
        uint256 amount
    ) external returns (uint256) {
        return
            _withdraw(
                IERC20(token),
                _msgSender(),
                recipient,
                amount,
                0,
                MAX_VAULT_ID
            );
    }

    /**
     * @notice Called to redeem the caller's shares from underlying vault(s), with the proceeds distributed to recipient.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from vaults
     * @param recipient Address to receive the withdrawn tokens
     * @param amount Maximum number of tokens to withdraw from all vaults; actual withdrawal may be less. If `WITHDRAW_EVERYTHING`, just withdraw everything.
     * @param firstVaultId First vault id to pull from; 0 to start at the the beginning
     * @param lastVaultId Last vault id to pull from; `MAX_VAULT_ID` to withdraw from all vaults
     * @return The number of tokens received by recipient.
     */
    function withdraw(
        address token,
        address recipient,
        uint256 amount,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) external returns (uint256) {
        return
            _withdraw(
                IERC20(token),
                _msgSender(),
                recipient,
                amount,
                firstVaultId,
                lastVaultId
            );
    }

    /**
     * @notice Called to redeem withdrawer's shares from underlying vault(s), with the proceeds distributed to recipient.
     * @dev Withdrawer must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from vaults
     * @param withdrawer Address to pull the vault shares from. SECURITY SENSITIVE.
     * @param recipient Address to receive the withdrawn tokens
     * @param amount Maximum number of tokens to withdraw from all vaults; actual withdrawal may be less. If `WITHDRAW_EVERYTHING`, just withdraw everything.
     * @param firstVaultId First vault id to pull from; 0 to start at the the beginning
     * @param lastVaultId Last vault id to pull from; `MAX_VAULT_ID` to withdraw from all vaults
     * @return withdrawn The number of tokens received by recipient.
     */
    function _withdraw(
        IERC20 token,
        address withdrawer,
        address recipient,
        uint256 amount,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) internal returns (uint256 withdrawn) {
        require(firstVaultId <= lastVaultId);

        uint256 _lastVaultId = lastVaultId;
        if (_lastVaultId == MAX_VAULT_ID)
            _lastVaultId = registry.numVaults(address(token)) - 1;

        for (
            uint256 i = firstVaultId;
            withdrawn + 1 < amount && i <= _lastVaultId;
            i++
        ) {
            VaultAPI vault = registry.vaults(address(token), i);

            uint256 availableShares = Math.min(
                vault.balanceOf(withdrawer),
                vault.maxAvailableShares()
            );
            // Restrict by the allowance that `withdrawer` has given to this contract
            availableShares = Math.min(
                availableShares,
                vault.allowance(withdrawer, address(this))
            );
            if (availableShares == 0) continue;

            uint256 maxShares;
            if (amount != WITHDRAW_EVERYTHING) {
                // Compute amount to withdraw fully to satisfy the request
                uint256 estimatedShares = ((amount - withdrawn) *
                    10**vault.decimals()) / vault.pricePerShare();

                // Limit amount to withdraw to the maximum made available to this contract
                // NOTE: Avoid corner case where `estimatedShares` isn't precise enough
                // NOTE: If `0 < estimatedShares < 1` but `availableShares > 1`, this will withdraw more than necessary
                maxShares = Math.min(availableShares, estimatedShares);
            } else {
                maxShares = availableShares;
            }

            uint256 beforeBal = vault.balanceOf(address(this));

            SafeERC20.safeTransferFrom(
                vault,
                withdrawer,
                address(this),
                maxShares
            );

            withdrawn += vault.withdraw(maxShares, recipient);

            uint256 afterWithdrawBal = vault.balanceOf(address(this));
            if (afterWithdrawBal > beforeBal) {
                SafeERC20.safeTransfer(
                    vault,
                    withdrawer,
                    afterWithdrawBal - beforeBal
                );
            }
        }
    }

    /**
     * @notice Called to migrate all of the caller's shares to the latest vault.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to migrate the vaults of
     * @return The number of tokens migrated.
     */
    function migrate(address token) external returns (uint256) {
        return
            _migrate(
                IERC20(token),
                _msgSender(),
                MIGRATE_EVERYTHING,
                0,
                MAX_VAULT_ID
            );
    }

    /**
     * @notice Called to migrate the caller's shares to the latest vault.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to migrate the vaults of
     * @param amount Maximum number of tokens to migrate from all vaults; actual migration may be less. If `MIGRATE_EVERYTHING`, just migrate everything.
     * @return The number of tokens migrated.
     */
    function migrate(address token, uint256 amount) external returns (uint256) {
        return _migrate(IERC20(token), _msgSender(), amount, 0, MAX_VAULT_ID);
    }

    /**
     * @notice Called to migrate the caller's shares to the latest vault.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to migrate the vaults of
     * @param amount Maximum number of tokens to migrate from all vaults; actual migration may be less. If `MIGRATE_EVERYTHING`, just migrate everything.
     * @param firstVaultId First vault id to migrate from; 0 to start at the the beginning
     * @param lastVaultId Last vault id to migrate from; `MAX_VAULT_ID` to migrate from all vaults
     * @return The number of tokens migrated.
     */
    function migrate(
        address token,
        uint256 amount,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) external returns (uint256) {
        return
            _migrate(
                IERC20(token),
                _msgSender(),
                amount,
                firstVaultId,
                lastVaultId
            );
    }

    /**
     * @notice Called to migrate migrator's shares to the latest vault.
     * @dev Migrator must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to migrate the vaults of
     * @param migrator Address to migrate the shares of. SECURITY SENSITIVE.
     * @param amount Maximum number of tokens to migrate from all vaults; actual migration may be less. If `MIGRATE_EVERYTHING`, just migrate everything.
     * @param firstVaultId First vault id to migrate from; 0 to start at the the beginning
     * @param lastVaultId Last vault id to migrate from; `MAX_VAULT_ID` to migrate from all vaults
     * @return migrated The number of tokens migrated.
     */
    function _migrate(
        IERC20 token,
        address migrator,
        uint256 amount,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) internal returns (uint256 migrated) {
        uint256 latestVaultId = registry.numVaults(address(token)) - 1;
        if (amount == 0 || latestVaultId == 0) return 0; // Nothing to migrate, or nowhere to go (not a failure)

        VaultAPI _latestVault = registry.vaults(address(token), latestVaultId);
        uint256 _amount = Math.min(
            amount,
            _latestVault.depositLimit() - _latestVault.totalAssets()
        );

        uint256 beforeWithdrawBal = token.balanceOf(address(this));
        _withdraw(
            token,
            migrator,
            address(this),
            _amount,
            firstVaultId,
            Math.min(lastVaultId, latestVaultId - 1)
        );
        uint256 afterWithdrawBal = token.balanceOf(address(this));
        require(afterWithdrawBal > beforeWithdrawBal, "withdraw failed");

        _deposit(
            token,
            address(this),
            migrator,
            afterWithdrawBal - beforeWithdrawBal,
            latestVaultId
        );
        uint256 afterDepositBal = token.balanceOf(address(this));
        require(afterWithdrawBal > afterDepositBal, "deposit failed");
        migrated = afterWithdrawBal - afterDepositBal;

        if (afterWithdrawBal - beforeWithdrawBal > migrated) {
            SafeERC20.safeTransfer(
                token,
                migrator,
                afterDepositBal - beforeWithdrawBal
            );
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {IERC20} from "IERC20.sol";

interface VaultAPI is IERC20 {
    function decimals() external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);
}

interface RegistryAPI {
    function governance() external view returns (address);

    function latestVault(address token) external view returns (VaultAPI);

    function numVaults(address token) external view returns (uint256);

    function vaults(address token, uint256 deploymentId)
        external
        view
        returns (VaultAPI);
}