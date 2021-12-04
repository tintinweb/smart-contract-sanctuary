// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";
import "pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol";

/// Contract for external Solid Group bot protection
abstract contract BPContract { 
    function protect(
        address sender,
        address receiver,
        uint256 amount
    ) external virtual;
}

/// @title RudolphInuTest
/// @notice RudolphInuTest Contract implementing ERC20 standard
/// PancakeRouter should be defined post creation.
/// PancakePair should be defined post launch.
contract RudolphInuTest is ERC20PresetFixedSupply, AccessControl, Ownable {
    /// Fee for liquidity, marketing, development, etc.
    /// Create with 99% tax to combat bots, adjust later with max limited fee amount
    uint16 public operationsFee = 990;
    /// Percentage of operations fee to add to liquidity
    uint256 public feeLiquidityPercentage = 400;
    /// Fee for staking pools, etc.
    uint8 public rewardsFee = 0;

    /// Variables for bot protection contract and states
    BPContract public BP;
    bool public botProtectionEnabled;
    bool public BPDisabledForever = false;

    /// Addresses to receive taxes
    address private _operationsWallet;
    address private _rewardsVault;
    address private _liquidityRecipient;

    mapping(address => bool) _isExcludedFromFee;
    mapping(address => bool) _isExcludedFromMaxTx;

    IPancakeRouter02 public PancakeRouter;
    IPancakePair public PancakePair;

    bool public feesEnabled = true;
    bool public swapEnabled = true;

    uint256 public maxTxAmount = 10000e18;
    uint256 public swapThreshold = 10000e18;
    bool private _swapActive = false;

    /// Events on variable changes
    event BotProtectionEnabledUpdated(bool enabled);
    event BotProtectionPermanentlyDisabled();
    event PancakePairUpdated(address pair);
    event PancakeRouterUpdated(address router);
    event OperationsFeeUpdated(uint8 fee);
    event RewardsFeeUpdated(uint8 fee);
    event OperationsWalletUpdated(address wallet);
    event RewardsVaultUpdated(address vault);
    event FeeLiquidityPercentageUpdated(uint256 percentage);
    event IncludedInFees(address account);
    event ExcludedFromFees(address account);
    event IncludedInMaxTransaction(address account);
    event ExcludedFromMaxTransaction(address account);
    event MaxTransactionUpdated(uint256 maxTxAmount);
    event FeesEnabledUpdated(bool enabled);
    event SwapEnabledUpdated(bool enabled);
    event SwapThresholdUpdated(uint256 threshold);
    event LiquidityRecipientUpdated(address recipient);
    event SwapTokensForNative(uint256 amount);
    event AddLiquidity(uint256 tokenAmount, uint256 nativeAmount);

    /// RudolphInu constructor
    /// @param name The token name
    /// @param symbol The token symbol
    /// @param initialSupply The token final initialSupply to mint
    /// @param owner The address to send minted supply to
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20PresetFixedSupply(name, symbol, initialSupply, owner) {
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner] = true;

        // Define administrator roles that can add/remove from given roles
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        // Add deployer to admin roles
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
    }

    /// CONTRACT FUNDS ///

    /// Receive native funds on contract if required (only owner or router)
    receive() external payable {
        require(
            _msgSender() == owner() || _msgSender() == address(PancakeRouter)
        );
    }

    /// Withdraw any native funds to sender address
    function withdrawNative() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _withdrawNative(_msgSender(), address(this).balance),
            "RudolphInu: Withdraw failed"
        );
    }

    /// Withdraw any ERC20 tokens to sender address
    /// @param _token The address of ERC20 token to withdraw
    /// @param amount The amount of the token to withdraw
    function withdrawToken(address _token, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(_token).transfer(_msgSender(), amount);
    }

    /// PUBLIC VIEWS ///

    /// Check if address is excluded from fees
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /// Check if address is excluded from max transaction
    function isExcludedFromMaxTx(address account) external view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    /// Get total fees (divide by 10 for percentage value)
    function totalFees() external view returns (uint256) {
        if (feesEnabled) {
            return operationsFee + rewardsFee;
        }
        return 0;
    }

    /// ADMINISTRATION ///

    /// Set the bot protection contract address
    function setBPAddress(address _bp) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(BP) == address(0),
            "RudolphInu: BP can only be initialized once"
        );
        BP = BPContract(_bp);
    }

    /// Set bot protection enabled state
    function setBotProtectionEnabled(bool _enabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!BPDisabledForever, "RudolphInu: BP is permanently disabled");
        botProtectionEnabled = _enabled;
        emit BotProtectionEnabledUpdated(_enabled);
    }

    /// Set bot protection disabled forever
    function disableBotProtectionForever()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            !BPDisabledForever,
            "RudolphInu: BP is already permanently disabled"
        );
        BPDisabledForever = true;
        botProtectionEnabled = false;
        emit BotProtectionPermanentlyDisabled();
    }

    /// Set pancake/token pair address
    function setPrimaryPairAddress(address pair)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            pair != address(0),
            "RudolphInu: Cannot set Pair to zero address"
        );
        PancakePair = IPancakePair(pair);
        emit PancakePairUpdated(pair);
    }

    /// Set pancake router address
    function setRouterAddress(address router)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            address(PancakeRouter) == address(0),
            "RudolphInu: Cannot set Router more than once"
        );
        require(
            router != address(0),
            "RudolphInu: Cannot set Router to zero address"
        );
        PancakeRouter = IPancakeRouter02(router);
        _approve(address(this), address(PancakeRouter), ~uint256(0));
        emit PancakeRouterUpdated(router);
    }

    /// Approve pancake router address
    function approveRouterAddress() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(PancakeRouter) != address(0),
            "RudolphInu: router has not been set yet"
        );
        _approve(address(this), address(PancakeRouter), ~uint256(0));
    }

    /// Set address to receive operations funds
    function setOperationsWallet(address wallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            wallet != address(0),
            "RudolphInu: Cannot set Wallet to zero address"
        );
        _operationsWallet = wallet;
        emit OperationsWalletUpdated(wallet);
    }

    /// Set address to receive rewards tokens
    function setRewardsVault(address vault)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            vault != address(0),
            "RudolphInu: Cannot set Vault to zero address"
        );
        _rewardsVault = vault;
        emit RewardsVaultUpdated(vault);
    }

    /// Set liquidity recipient
    function setLiquidityRecipient(address recipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _liquidityRecipient = recipient;
        emit LiquidityRecipientUpdated(recipient);
    }

    /// Set feesEnabled flag
    function setFeesEnabled(bool _enabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        feesEnabled = _enabled;
        emit FeesEnabledUpdated(_enabled);
    }

    /// Include address in fees
    function includeInFee(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _isExcludedFromFee[account] = false;
        emit IncludedInFees(account);
    }

    /// Exclude address from fees
    function excludeFromFee(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFees(account);
    }

    /// Include address in max tx
    function includeInMaxTx(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _isExcludedFromMaxTx[account] = false;
        emit IncludedInMaxTransaction(account);
    }

    /// Exclude address from max tx
    function excludeFromMaxTx(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _isExcludedFromMaxTx[account] = true;
        emit ExcludedFromMaxTransaction(account);
    }

    /// Set max transaction amount
    function setMaxTxAmount(uint256 maxTx)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 percentage = (maxTx * 10e2) / totalSupply();
        require(
            percentage >= 1,
            "RudolphInu: Cannot set max transaction less than 0.1%"
        );
        maxTxAmount = maxTx;
        emit MaxTransactionUpdated(maxTx);
    }

    /// Set max transaction percentage
    /// @param maxTxPercentage Max transaction percentage where 10 = 1%
    function setMaxTxPercentage(uint256 maxTxPercentage)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            maxTxPercentage >= 1,
            "RudolphInu: Cannot set max transaction less than 0.1%"
        );
        uint256 maxTx = (totalSupply() * maxTxPercentage) / 10e2;
        maxTxAmount = maxTx;
        emit MaxTransactionUpdated(maxTx);
    }

    /// Set swap threshold of tokens to swap to native
    function setSwapThreshold(uint256 threshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(threshold > 0, "RudolphInu: Cannot set threshold to zero");
        swapThreshold = threshold;
        emit SwapThresholdUpdated(threshold);
    }

    /// Set swapEnabled flag
    function setSwapEnabled(bool _enabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        swapEnabled = _enabled;
        emit SwapEnabledUpdated(_enabled);
    }

    /// Set operations fee to take on buys/sells
    function setOperationsFee(uint8 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee <= 200, "RudolphInu: max operations fee is 20%");
        operationsFee = fee;
        emit OperationsFeeUpdated(fee);
    }

    /// Set rewards (e.g. staking pool) fees to take on buys/sells
    function setRewardsFee(uint8 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee <= 100, "RudolphInu: max rewards fee is 10%");
        rewardsFee = fee;
        emit RewardsFeeUpdated(fee);
    }

    /// Set percentage of operations fee to add to liquidity
    function setFeeLiquidityPercentage(uint16 percentage)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            percentage <= 1000,
            "RudolphInu: max fee liquidity percentage is 100%"
        );
        feeLiquidityPercentage = percentage;
        emit FeeLiquidityPercentageUpdated(percentage);
    }

    /// TRANSFER AND SWAP ///

    /// @dev Enable swap active flag before function and disable afterwards
    modifier swapSemaphore() {
        _swapActive = true;
        _;
        _swapActive = false;
    }

    /// @dev Check if transfer should limit transaction amount
    modifier canTransfer(
        address sender,
        address receiver,
        uint256 amount
    ) {
        // If buying or selling from primary pair and not excluded, ensure max transaction
        if (
            (sender == address(PancakePair) ||
                receiver == address(PancakePair)) &&
            !(_isExcludedFromMaxTx[sender] || _isExcludedFromMaxTx[receiver])
        ) {
            require(
                amount <= maxTxAmount,
                "RudolphInu: Transfer amount over maxTxAmount"
            );
        }
        _;
    }

    /// @dev Check if transfer should take fee, only take fee on buys/sells
    function _shouldTakeFee(address sender, address receiver)
        internal
        view
        virtual
        returns (bool)
    {
        return
            (sender == address(PancakePair) ||
                receiver == address(PancakePair)) &&
            !(_isExcludedFromFee[sender] || _isExcludedFromFee[receiver]);
    }

    /// @dev Calculate individual and total fee amounts for a given transfer amount
    /// @param amount The transfer amount
    /// @return totalFeeAmount The total fee value to take from transfer amount
    /// @return operationsFeeAmount The operations fee value to take from transfer amount
    /// @return rewardFeeAmount The rewards fee value to take from transfer amount
    function _calculateFees(uint256 amount)
        internal
        view
        returns (
            uint256 totalFeeAmount,
            uint256 operationsFeeAmount,
            uint256 rewardFeeAmount
        )
    {
        operationsFeeAmount = (amount * operationsFee) / 10e2;
        rewardFeeAmount = (amount * rewardsFee) / 10e2;
        totalFeeAmount = rewardFeeAmount + operationsFeeAmount;
    }

    /// @notice Transfer amount, taking taxes (if enabled) for operations and reward pool.
    ///			If enabled and threshold is reached, also swap taxes to native currency and add to liquidity.
    /// @inheritdoc	ERC20
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override canTransfer(sender, recipient, amount) {
        // Use protection contract if bot protection enabled
        if (botProtectionEnabled && !BPDisabledForever) {
            BP.protect(sender, recipient, amount);
        }

        (
            uint256 totalFee,
            uint256 operationsFeeAmount,
            uint256 rewardFeeAmount
        ) = _calculateFees(amount);

        if (sender != address(PancakePair) && !_swapActive && swapEnabled) {
            _swapTokens();
        }

        if (_shouldTakeFee(sender, recipient) && feesEnabled) {
            uint256 transferAmount = amount - totalFee;

            super._transfer(sender, recipient, transferAmount);
            if (operationsFeeAmount > 0) {
                super._transfer(sender, address(this), operationsFeeAmount);
            }
            if (rewardFeeAmount > 0) {
                super._transfer(
                    sender,
                    address(_rewardsVault),
                    rewardFeeAmount
                );
            }
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    /// @dev Calculate amount of a value that should go to liquidity
    /// @param amount The original fee amount
    /// @return The value of fee to add to liquidity
    function _calculateLiquidityPercentage(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return (amount * feeLiquidityPercentage) / 10e2;
    }

    /// @dev Calculate operations fee split amounts for liquidity tokens and total to swap to native
    /// @param amount The operations fee amount
    /// @return tokensForLiquidity The amount of tokens to save to pair with native currency for LP
    /// @return swapAmount The amount of tokens to swap for native currency to split for marketing and to pair for LP
    function _calculateOperationsFeeSplit(uint256 amount)
        internal
        view
        returns (uint256 tokensForLiquidity, uint256 swapAmount)
    {
        // Get token amount from taxes for liquidity
        tokensForLiquidity = _calculateLiquidityPercentage(amount);
        // Get token amount from taxes for operations
        uint256 tokensForOperations = amount - tokensForLiquidity;
        // Halve liquidity tokens for converting to native
        uint256 liquidityTokens = tokensForLiquidity / 2;
        uint256 liquiditySwap = tokensForLiquidity - liquidityTokens;
        // Get total tokens to convert to native token
        swapAmount = tokensForOperations + liquiditySwap;
    }

    /// @dev If swapThreshold reached, swap tokens to native currency, add liquidity, and send to marketing wallet
    function _swapTokens() internal swapSemaphore {
        uint256 contractBalance = IERC20(address(this)).balanceOf(
            address(this)
        );
        uint256 threshold = swapThreshold;
        if (contractBalance > threshold && swapEnabled) {
            if (threshold > maxTxAmount) {
                threshold = maxTxAmount;
            }

            (
                uint256 tokensForLiquidity,
                uint256 swapAmount
            ) = _calculateOperationsFeeSplit(threshold);

            // Perform swap and calculate converted value
            uint256 initialBalance = payable(this).balance;
            if (_swapTokensForNative(swapAmount)) {
                uint256 swapBalance = payable(this).balance;
                uint256 profit = swapBalance - initialBalance;

                // Get native amount from taxes for liquidity/operations
                uint256 nativeForLiquidity = _calculateLiquidityPercentage(
                    profit
                );
                uint256 nativeForOperations = profit - nativeForLiquidity;
                if (nativeForOperations > 0) {
                    _withdrawNative(_operationsWallet, nativeForOperations);
                }
                if (nativeForLiquidity > 0) {
                    _addLiquidity(tokensForLiquidity, nativeForLiquidity);
                }
            }
        }
    }

    /// @dev Withdraw native currency to recipient using call method
    function _withdrawNative(address recipient, uint256 amount)
        internal
        virtual
        returns (bool success)
    {
        (success, ) = payable(recipient).call{value: amount}("");
    }

    /// @dev Swap tokens for native currency (e.g. BNB)
    function _swapTokensForNative(uint256 amount)
        internal
        virtual
        returns (bool)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeRouter.WETH();
        try
            PancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp
            )
        {
            emit SwapTokensForNative(amount);
            return true;
        } catch (bytes memory) {
            return false;
        }
    }

    /// @dev Add liquidity to token from token contract holdings
    function _addLiquidity(uint256 tokenAmount, uint256 nativeAmount)
        private
        returns (bool)
    {
        try
            PancakeRouter.addLiquidityETH{value: nativeAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                _liquidityRecipient,
                block.timestamp
            )
        {
            emit AddLiquidity(tokenAmount, nativeAmount);
            return true;
        } catch (bytes memory) {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/presets/ERC20PresetFixedSupply.sol)
pragma solidity ^0.8.0;

import "../extensions/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}