// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "./Globals.sol";
import "./interfaces/IPrices.sol";
import "./pools/USDoPool.sol";

contract OrionStablecoin is ERC20, AccessControlEnumerable, Ownable {
    IPrices private _prices;

    address public pricesAddress;
    address public creatorAddress;
    address public timelockAddress; // Governance timelock address
    address public controllerAddress; // Controller contract to dynamically adjust system parameters automatically

    uint256 public constant genesisSupply = 2000000 * G_PRECISION; // 2M USDo (only for testing, genesis supply will be 5k on Mainnet). This is to help with establishing the Uniswap pools, as they need liquidity

    uint256 public globalCollateralRatio; // 8 decimals of precision, e.g. 92410214 = 0.92410214
    uint256 public redemptionFee; // 8 decimals of precision, divide by 100000000 in calculations for fee
    uint256 public mintingFee; // 8 decimals of precision, divide by 100000000 in calculations for fee
    uint256 public USDoStep; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refreshCooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public priceTarget; // The price of USDo at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public priceBand; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio

    bool public collateralRatioPaused = false;

    uint256 public lastCallTime; // Last time the refreshCollateralRatio function was called


    event USDoBurned(address indexed from, uint256 amount, address account);
    event USDoMinted(address indexed to, uint256 amount, address account);
    event CollateralRatioRefreshed(uint256 globalCollateralRatio, address account);
    //    event PoolAdded(address pool_address);            check event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    //    event PoolRemoved(address pool_address);          check event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RedemptionFeeSet(uint256 fee, address account);
    event MintingFeeSet(uint256 fee, address account);
    event USDoStepSet(uint256 step, address account);
    event PriceTargetSet(uint256 price, address account);
    event RefreshCooldownSet(uint256 cooldown, address account);
    event ORSAddressSet(address ORS, address account);
    event TimelockSet(address timelock, address account);
    event ControllerSet(address controller, address account);
    event PriceBandSet(uint256 price, address account);
    event PricesSet(address pricess, address account);
    event CollateralRatioToggled(bool ratio, address account);


    constructor(
        string memory name_,
        string memory symbol_,
        address creatorAddress_,
        address timelockAddress_,
        address pricesAddress_
    ) ERC20(name_, symbol_) {
        require(
            creatorAddress_ != address(0) || timelockAddress_ != address(0) || pricesAddress_ != address(0),
            "USDo: Zero address detected"
        );

        _mint(creatorAddress_, genesisSupply);

        creatorAddress = creatorAddress_;
        timelockAddress = timelockAddress_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // todo ??? this role have full access

        _setupRole(COLLATERAL_RATIO_PAUSER, creatorAddress_);
        _setupRole(COLLATERAL_RATIO_PAUSER, timelockAddress_); //  todo ??? this role not upgrade after change timelock address

        _setRoleAdmin(POOL_ROLE, ADMIN_USDO_ROLE);
        _setRoleAdmin(ADMIN_USDO_ROLE, ADMIN_USDO_ROLE);

        _setupRole(ADMIN_USDO_ROLE, msg.sender);
        _setupRole(ADMIN_USDO_ROLE, timelockAddress_);

        _prices = IPrices(pricesAddress_);
        pricesAddress = pricesAddress_;

        USDoStep = 250000; // 8 decimals of precision, equal to 0.25%
        globalCollateralRatio = 100000000; // USDo system starts off fully collateralized (8 decimals of precision)
        refreshCooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        priceTarget = 100000000; // Collateral ratio will adjust according to the $1 price target at genesis
        priceBand = 500000; // Collateral ratio will not adjust if between $0.995 and $1.005 at genesis
    }

    function decimals() public view virtual override returns (uint8) {
        return uint8(G_DECIMALS);
    }

    // This is needed to avoid costly repeat calls to different getter functions
    // It is cheaper gas-wise to just dump everything and only use some of the info
    function USDo_info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            _prices.getUSDoPrice(), // USDo_price()
            _prices.getORSPrice(), // ORS_price()
            totalSupply(), // totalSupply()
            globalCollateralRatio, // globalCollateralRatio
            globalCollateralValue(), // globalCollateralValue()
            mintingFee, // mintingFee
            redemptionFee // redemptionFee()
        );
    }

    // Iterate through all USDo pools and calculate all value of collateral in all pools globally
    function globalCollateralValue() public view returns (uint256) {
        uint256 totalCollateralValue = 0;

        for (uint256 i = 0; i < getRoleMemberCount(POOL_ROLE); i++) {
            totalCollateralValue = totalCollateralValue + USDoPool(getRoleMember(POOL_ROLE, i)).collateralDollarBalance();
        }
        return totalCollateralValue;
    }

    // There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.

    function refreshCollateralRatio() public {
        require(collateralRatioPaused == false, "USDo: Collateral Ratio has been paused");

        uint256 USDoPrice = _prices.getUSDoPrice();

        require(block.timestamp - lastCallTime >= refreshCooldown, "USDo: Must wait for the refresh cooldown since last refresh");

        // Step increments are 0.25% (upon genesis, changable by setUSDoStep())

        if (USDoPrice > priceTarget + priceBand) { //decrease collateral ratio
            if(globalCollateralRatio <= USDoStep){ //if within a step of 0, go to 0
                globalCollateralRatio = 0;
            } else {
                globalCollateralRatio = globalCollateralRatio - USDoStep;
            }
        } else if (USDoPrice < priceTarget - priceBand) { //increase collateral ratio
            if(globalCollateralRatio + USDoStep >= 100000000){
                globalCollateralRatio = 100000000; // cap collateral ratio at 1.00000000
            } else {
                globalCollateralRatio = globalCollateralRatio + USDoStep;
            }
        }

        lastCallTime = block.timestamp; // Set the time of the last expansion

        emit CollateralRatioRefreshed(globalCollateralRatio, msg.sender);
    }

    // Used by pools when user redeems
    function poolBurn(address account_, uint256 amount_) public onlyRole(POOL_ROLE) {
        super._burn(account_, amount_);
        emit USDoBurned(account_, amount_, msg.sender);
    }

    // This function is what other frax pools will call to mint new USDo
    function poolMint(address account_, uint256 amount_) public onlyRole(POOL_ROLE) {
        super._mint(account_, amount_);
        emit USDoMinted(account_, amount_, msg.sender);
    }

    // Adds collateral addresses supported, such as tether and busd, must be ERC20
    function addPool(address poolAddress_) external {
        require(poolAddress_ != address(0), "USDo: Pool address is zero");
        require(!hasRole(POOL_ROLE, poolAddress_), "USDo: Pool already exists");

        grantRole(POOL_ROLE, poolAddress_);
    }

    // Remove a pool
    function removePool(address poolAddress_) external {
        require(hasRole(POOL_ROLE, poolAddress_), "USDo: Address is not pool");

        revokeRole(POOL_ROLE, poolAddress_);
    }

    function setRedemptionFee(uint256 redemptionFee_) public onlyRole(ADMIN_USDO_ROLE) {
        redemptionFee = redemptionFee_;

        emit RedemptionFeeSet(redemptionFee_, msg.sender);
    }

    function setMintingFee(uint256 mintingFee_) public onlyRole(ADMIN_USDO_ROLE) {
        mintingFee = mintingFee_;

        emit MintingFeeSet(mintingFee_, msg.sender);
    }

    function setUSDoStep(uint256 USDoStep_) public onlyRole(ADMIN_USDO_ROLE) {
        USDoStep = USDoStep_;

        emit USDoStepSet(USDoStep_, msg.sender);
    }

    function setPriceTarget(uint256 priceTarget_) public onlyRole(ADMIN_USDO_ROLE) {
        priceTarget = priceTarget_;

        emit PriceTargetSet(priceTarget_, msg.sender);
    }

    function setRefreshCooldown(uint256 refreshCooldown_) public onlyRole(ADMIN_USDO_ROLE) {
        refreshCooldown = refreshCooldown_;

        emit RefreshCooldownSet(refreshCooldown_, msg.sender);
    }

    function setPrices(address pricesAddress_) public onlyRole(ADMIN_USDO_ROLE) {
        require(pricesAddress_ != address(0), "USDo: Zero address detected");

        _prices = IPrices(pricesAddress_);
        pricesAddress = pricesAddress_;

        emit PricesSet(pricesAddress_, msg.sender);
    }

    function setTimelock(address timelockAddress_) external {
        require(timelockAddress_ != address(0), "USDo: Zero address detected");

        grantRole(ADMIN_USDO_ROLE, timelockAddress_);
        if (hasRole(ADMIN_USDO_ROLE, timelockAddress)) revokeRole(ADMIN_USDO_ROLE, timelockAddress);
        timelockAddress = timelockAddress_;

        emit TimelockSet(timelockAddress, msg.sender);
    }

    function setController(address controllerAddress_) external {
        require(controllerAddress_ != address(0), "USDo: Zero address detected");

        grantRole(ADMIN_USDO_ROLE, controllerAddress_);
        if (hasRole(ADMIN_USDO_ROLE, controllerAddress)) revokeRole(ADMIN_USDO_ROLE, controllerAddress);
        controllerAddress = controllerAddress_;

        emit ControllerSet(controllerAddress, msg.sender);
    }

    function setPriceBand(uint256 priceBand_) external onlyRole(ADMIN_USDO_ROLE) {
        priceBand = priceBand_;

        emit PriceBandSet(priceBand_, msg.sender);
    }

    function toggleCollateralRatio() public onlyRole(COLLATERAL_RATIO_PAUSER) {
        collateralRatioPaused = !collateralRatioPaused;

        emit CollateralRatioToggled(collateralRatioPaused, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

uint256 constant G_DECIMALS = 8;
uint256 constant G_PRECISION = 10 ** G_DECIMALS;

bytes32 constant COLLATERAL_RATIO_PAUSER = keccak256("COLLATERAL_RATIO_PAUSER");
bytes32 constant POOL_ROLE = keccak256("POOL_ROLE");
bytes32 constant ADMIN_USDO_ROLE = keccak256("ADMIN_USDO_ROLE"); // onlyByOwnerGovernanceOrController for Orion Stablecoin

bytes32 constant MINT_PAUSER = keccak256("MINT_PAUSER");
bytes32 constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
bytes32 constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
bytes32 constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
bytes32 constant COLLATERAL_PRICE_PAUSER = keccak256("COLLATERAL_PRICE_PAUSER");

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPrices {
    function decimals() external pure returns (uint256);

    function getORNPrice() external view returns (uint256);

    function getORSPrice() external view returns (uint256);

    function getUSDoPrice() external view returns (uint256);

    function getChainlinkPrice(address chainlinkAggregatorAddress_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../Globals.sol";
import "../interfaces/IPrices.sol";
import "./USDoPoolLibrary.sol";
import "../OrionShares.sol";
import "../OrionStablecoin.sol";

contract USDoPool is AccessControl, Ownable {
    uint256 private constant COLLATERAL_RATIO_PRECISION = G_PRECISION;
    uint256 private constant COLLATERAL_RATIO_MAX = G_PRECISION;

    address private _collateralAddress;
    address private _USDoAddress;
    address private _ORSAddress;
    address private _pricesAddress;
    ERC20 private _collateralToken;
    OrionStablecoin private _USDo;
    OrionShares private _ORS;
    IPrices private _prices;

    address private _timelockAddress;
    address private _chainlinkPairAddress;

    uint256 private _collateralPrecision;

    uint256 public mintingFee;
    uint256 public redemptionFee;
    uint256 public buybackFee;
    uint256 public recollatFee;

    mapping (address => uint256) public redeemORSBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolORS;
    mapping (address => uint256) public lastRedeemed;

    uint256 public poolCeiling = 0;        // Pool_ceiling is the total units of collateral that a pool contract can hold
    uint256 public pausedPrice = 0;        // Stores price of the collateral, if price is paused
    uint256 public bonusRate = 750000;     // Bonus rate on ORS minted during recollateralizeUDSo(); G_DECIMALS of precision, set to 0.75% on genesis
    uint256 public redemptionDelay = 1;    // Number of blocks to wait before being able to collectRedemption()
    
    // AccessControl state variables
    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public recollateralizePaused = false;
    bool public buyBackPaused = false;
    bool public collateralPricePaused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == _timelockAddress || msg.sender == owner(), "USDoPool: Caller is not owner or timelock");
        _;
    }

    modifier notRedeemPaused() {
        require(redeemPaused == false, "USDoPool: Redeeming is paused");
        _;
    }

    modifier notMintPaused() {
        require(mintPaused == false, "USDoPool: Minting is paused");
        _;
    }

    /* ========== EVENTS ========== */

    event PoolParametersSet(uint256 newCeiling, uint256 newBonusRate, uint256 newRedemptionDelay, uint256 newMintFee, uint256 newRedeemFee, uint256 newBuybackFee, uint256 newRecollatFee);
    event TimelockSet(address new_timelock);
    event MintingToggled(bool toggled);
    event RedeemingToggled(bool toggled);
    event RecollateralizeToggled(bool toggled);
    event BuybackToggled(bool toggled);
    event CollateralPriceToggled(bool toggled, uint256 price);
 
    /* ========== CONSTRUCTOR ========== */
    
    constructor(
        address USDoAddress_,
        address ORSAddress_,
        address collateralAddress_,
        address timelockAddress_,
        address pricesAddress_,
        address chainlinkPairAddress_,
        uint256 poolCeiling_
    ) {
        require(
            (USDoAddress_ != address(0))
            && (ORSAddress_ != address(0))
            && (collateralAddress_ != address(0))
            && (timelockAddress_ != address(0))
            && (pricesAddress_ != address(0))
            && (chainlinkPairAddress_ != address(0))
        , "USDoPool: Zero address detected");
        _USDo = OrionStablecoin(USDoAddress_);
        _ORS = OrionShares(ORSAddress_);
        _USDoAddress = USDoAddress_;
        _ORSAddress = ORSAddress_;
        _collateralAddress = collateralAddress_;
        _timelockAddress = timelockAddress_;
        _collateralToken = ERC20(collateralAddress_);
        poolCeiling = poolCeiling_;

        _prices = IPrices(pricesAddress_);
        _pricesAddress = pricesAddress_;

        _chainlinkPairAddress = chainlinkPairAddress_;

        _collateralPrecision = 10 ** _collateralToken.decimals();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());   // todo shadow change roles
        grantRole(MINT_PAUSER, timelockAddress_);
        grantRole(REDEEM_PAUSER, timelockAddress_);
        grantRole(RECOLLATERALIZE_PAUSER, timelockAddress_);
        grantRole(BUYBACK_PAUSER, timelockAddress_);
        grantRole(COLLATERAL_PRICE_PAUSER, timelockAddress_);
    }

    // Returns dollar value of collateral held in this USDo pool
    function collateralDollarBalance() public view returns (uint256) {
        if(collateralPricePaused == true){
            return (_collateralBalance() - unclaimedPoolCollateral) * pausedPrice / G_PRECISION;
        } else {
            return (_collateralBalance() - unclaimedPoolCollateral) * _collateralPrice() / G_PRECISION;
        }
    }

    // Returns the value of excess collateral held in this USDo pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollateralDV() public view returns (uint256) {
        uint256 totalSupply = _USDo.totalSupply();
        uint256 globalCollateralRatio = _USDo.globalCollateralRatio();
        uint256 globalCollateralValue = _USDo.globalCollateralValue();

        if (globalCollateralRatio > COLLATERAL_RATIO_PRECISION) globalCollateralRatio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 requiredCollateralDollarValue = totalSupply * globalCollateralRatio / COLLATERAL_RATIO_PRECISION; // Calculates collateral needed to back each 1 USDo with $1 of collateral at current collat ratio

        return globalCollateralValue > requiredCollateralDollarValue ? globalCollateralValue - requiredCollateralDollarValue : 0;
    }

    function setCollateralPair(address chainlinkPairAddress_) external onlyByOwnerOrGovernance {
        require(chainlinkPairAddress_ != address(0), "USDoPool: Chainlink pair address is zero");
        _chainlinkPairAddress = chainlinkPairAddress_;
    }

    function setPricesAddress(address pricesAddress_) external onlyByOwnerOrGovernance {
        require(pricesAddress_ != address(0), "USDoPool: Prices address pair address is zero");
        _pricesAddress = pricesAddress_;
        _prices = IPrices(pricesAddress_);
    }

    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1USDo(uint256 collateralAmountCollDec_, uint256 USDoOutMin_) external notMintPaused {
        uint256 collateralAmount = collateralAmountCollDec_ * G_PRECISION / _collateralPrecision;

        require(_USDo.globalCollateralRatio() >= COLLATERAL_RATIO_MAX, "USDoPool: Collateral ratio must be >= 1");
        require(_collateralBalance() - unclaimedPoolCollateral + collateralAmount <= poolCeiling, "USDoPool: Ceiling reached");
        
        (uint256 USDoAmount) = USDoPoolLibrary.calcMint1t1USDo(
            _collateralPrice(),
            collateralAmount
        ); //1 USDo for each $1 worth of collateral

        USDoAmount = _calcFee(USDoAmount, mintingFee);
        require(USDoOutMin_ <= USDoAmount, "USDoPool: Slippage limit reached");

        uint256 collateralAmountCollDec = collateralAmount * _collateralPrecision / G_PRECISION;

        SafeERC20.safeTransferFrom(_collateralToken, msg.sender, address(this), collateralAmountCollDec);
        _USDo.poolMint(msg.sender, USDoAmount);
    }

    // 0% collateral-backed
    function mintAlgorithmicUSDo(uint256 ORSAmount_, uint256 USDoOutMin_) external notMintPaused {
        uint256 ORSPrice = _prices.getORSPrice();
        require(_USDo.globalCollateralRatio() == 0, "USDoPool: Collateral ratio must be 0");
        
        (uint256 USDoAmount) = USDoPoolLibrary.calcMintAlgorithmicUSDo(
            ORSPrice, // X ORS / 1 USD
            ORSAmount_
        );

        USDoAmount = _calcFee(USDoAmount, mintingFee);
        require(USDoOutMin_ <= USDoAmount, "USDoPool: Slippage limit reached");

        _ORS.poolBurn(msg.sender, ORSAmount_);
        _USDo.poolMint(msg.sender, USDoAmount);
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalUSDo(uint256 collateralAmountCollDec_, uint256 ORSAmount_, uint256 USDoOutMin_) external notMintPaused {
        uint256 ORSPrice = _prices.getORSPrice();
        uint256 globalCollateralRatio = _USDo.globalCollateralRatio();
        uint256 collateralAmount = collateralAmountCollDec_ * G_PRECISION / _collateralPrecision;

        require(
            globalCollateralRatio < COLLATERAL_RATIO_MAX && globalCollateralRatio > 0,
            "USDoPool: Collateral ratio needs to be between .00000001 and .99999999"
        );
        require(
            _collateralBalance() - unclaimedPoolCollateral + collateralAmount <= poolCeiling,
            "USDoPool: Pool ceiling reached, no more USDo can be minted with this collateral"
        );

        (uint256 mintAmount, uint256 ORSNeeded) = USDoPoolLibrary.calcMintFractionalUSDo(
            ORSPrice,
            _collateralPrice(),
            collateralAmount,
            globalCollateralRatio
        );

        mintAmount = _calcFee(mintAmount, mintingFee);

        require(USDoOutMin_ <= mintAmount, "USDoPool: Slippage limit reached");
        require(ORSNeeded <= ORSAmount_, "USDoPool: Not enough ORS inputted");

        uint256 collateralAmountCollDec = collateralAmount * _collateralPrecision / G_PRECISION;

        _ORS.poolBurn(msg.sender, ORSNeeded);
        SafeERC20.safeTransferFrom(_collateralToken, msg.sender, address(this), collateralAmountCollDec);
        _USDo.poolMint(msg.sender, mintAmount);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1USDo(uint256 USDoAmount_, uint256 CollateralOutMinCollDec_) external notRedeemPaused {
        require(_USDo.globalCollateralRatio() == COLLATERAL_RATIO_MAX, "USDoPool: Collateral ratio must be == 1");

        (uint256 collateralNeeded) = USDoPoolLibrary.calcRedeem1t1USDo(
            _collateralPrice(),
            USDoAmount_
        );

        collateralNeeded = _calcFee(collateralNeeded, redemptionFee);

        require(collateralNeeded <= _collateralBalance() - unclaimedPoolCollateral, "USDoPool: Not enough collateral in pool");
        require(CollateralOutMinCollDec_ <= collateralNeeded * _collateralPrecision / G_PRECISION, "USDoPool: Slippage limit reached");

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender] + collateralNeeded;
        unclaimedPoolCollateral = unclaimedPoolCollateral + collateralNeeded;
        lastRedeemed[msg.sender] = block.number;

        _USDo.poolBurn(msg.sender, USDoAmount_);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem USDo for collateral and ORS. > 0% and < 100% collateral-backed
    function redeemFractionalUSDo(uint256 USDoAmount_, uint256 ORSOutMin_, uint256 CollateralOutMinCollDec_) external notRedeemPaused {
        uint256 ORSPrice = _prices.getORSPrice();
        uint256 globalCollateralRatio = _USDo.globalCollateralRatio();

        require(globalCollateralRatio < COLLATERAL_RATIO_MAX && globalCollateralRatio > 0, "USDoPool: Collateral ratio needs to be between .00000001 and .99999999");

        uint256 USDoAmount = _calcFee(USDoAmount_, redemptionFee);

        uint256 ORSDollarValue = USDoAmount - (USDoAmount * globalCollateralRatio / G_PRECISION);
        uint256 ORSAmount = ORSDollarValue * G_PRECISION / ORSPrice;

        uint256 collateralDollarValue = USDoAmount * globalCollateralRatio / G_PRECISION;
        uint256 collateralAmount = collateralDollarValue * G_PRECISION / _collateralPrice();


        require(collateralAmount <= _collateralBalance() - unclaimedPoolCollateral, "USDoPool: Not enough collateral in pool");
        require(CollateralOutMinCollDec_ <= collateralAmount * _collateralPrecision / G_PRECISION, "USDoPool: Slippage limit reached (collateral)");
        require(ORSOutMin_ <= ORSAmount, "USDoPool: Slippage limit reached (ORS)");

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender] + collateralAmount;
        unclaimedPoolCollateral = unclaimedPoolCollateral + collateralAmount;

        redeemORSBalances[msg.sender] = redeemORSBalances[msg.sender] + ORSAmount;
        unclaimedPoolORS = unclaimedPoolORS + ORSAmount;

        lastRedeemed[msg.sender] = block.number;

        _USDo.poolBurn(msg.sender, USDoAmount);
        _ORS.poolMint(address(this), ORSAmount);
    }

    // Redeem USDo for ORS. 0% collateral-backed
    function redeemAlgorithmicUSDo(uint256 USDoAmount_, uint256 ORSOutMin_) external notRedeemPaused {
        uint256 ORSPrice = _prices.getORSPrice();
        uint256 globalCollateralRatio = _USDo.globalCollateralRatio();

        require(globalCollateralRatio == 0, "USDoPool: Collateral ratio must be 0");

        uint256 ORSDollarValue = _calcFee(USDoAmount_, redemptionFee);
        uint256 ORSAmount = ORSDollarValue * G_PRECISION / ORSPrice;

        redeemORSBalances[msg.sender] = redeemORSBalances[msg.sender] + ORSAmount;
        unclaimedPoolORS = unclaimedPoolORS + ORSAmount;
        
        lastRedeemed[msg.sender] = block.number;
        
        require(ORSOutMin_ <= ORSAmount, "USDoPool: Slippage limit reached");

        _USDo.poolBurn(msg.sender, USDoAmount_);
        _ORS.poolMint(address(this), ORSAmount);
    }

    // After a redemption happens, transfer the newly minted ORS and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out USDo/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external {
        require((lastRedeemed[msg.sender] + redemptionDelay) <= block.number, "USDoPool: Must wait for redemptionDelay blocks before collecting redemption");
        bool sendORS = false;
        bool sendCollateral = false;
        uint256 ORSAmount = 0;
        uint256 CollateralAmount = 0;

        if(redeemORSBalances[msg.sender] > 0){
            ORSAmount = redeemORSBalances[msg.sender];
            redeemORSBalances[msg.sender] = 0;
            unclaimedPoolORS = unclaimedPoolORS - ORSAmount;

            sendORS = true;
        }
        
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral - CollateralAmount;

            sendCollateral = true;
        }

        if (sendORS) SafeERC20.safeTransfer(_ORS, msg.sender, ORSAmount);
        if (sendCollateral) SafeERC20.safeTransfer(_collateralToken, msg.sender, CollateralAmount * _collateralPrecision / G_PRECISION);
    }


//     When the protocol is recollateralizing, we need to give a discount of FXS to hit the new CR target
//     Thus, if the target collateral ratio is higher than the actual value of collateral, minters get FXS for adding collateral
//     This function simply rewards anyone that sends collateral to a pool with the same amount of FXS + the bonus rate
//     Anyone can call this function to recollateralize the protocol and take the extra FXS value from the bonus rate as an arb opportunity
    function recollateralizeUSDo(uint256 collateralAmountCollDec_, uint256 ORSOutMin_) external {
        require(recollateralizePaused == false, "USDoPool: Recollateralize is paused");
        uint256 collateralAmount = collateralAmountCollDec_ * G_PRECISION / _collateralPrecision;
        uint256 ORSPrice = _prices.getORSPrice();
        uint256 USDoTotalSupply = _USDo.totalSupply();
        uint256 globalCollateralRatio = _USDo.globalCollateralRatio();
        uint256 globalCollateralValue = _USDo.globalCollateralValue();

        (uint256 collateralUnits, uint256 amountToRecollateralize) = USDoPoolLibrary.calcRecollateralizeUSDoInner(
            collateralAmount,
            _collateralPrice(),
            globalCollateralValue,
            USDoTotalSupply,
            globalCollateralRatio
        );

        uint256 ORSPaidBack = amountToRecollateralize * (G_PRECISION + bonusRate - recollatFee) / ORSPrice;
        uint256 collateralUnitsCollDec = collateralUnits * _collateralPrecision / G_PRECISION;

        require(ORSOutMin_ <= ORSPaidBack, "USDoPool: Slippage limit reached");
        SafeERC20.safeTransferFrom(_collateralToken, msg.sender, address(this), collateralUnitsCollDec);
        _ORS.poolMint(msg.sender, ORSPaidBack);
        
    }

    // Function can be called by an FXS holder to have the protocol buy back FXS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackORS(uint256 ORSAmount_, uint256 CollateralOutMinCollDec_) external {
        require(buyBackPaused == false, "USDoPool: Buyback is paused");

        uint256 ORSPrice = _prices.getORSPrice();

        uint256 collateralAmount = USDoPoolLibrary.calcBuyBackORS(
            ORSPrice,
            ORSAmount_,
            _collateralPrice(),
            availableExcessCollateralDV()
        );

        collateralAmount = _calcFee(collateralAmount, buybackFee);
        uint256 collateralAmountCollDec = collateralAmount * _collateralPrecision / G_PRECISION;

        require(CollateralOutMinCollDec_ <= collateralAmountCollDec, "USDoPool: Slippage limit reached");
        // Give the sender their desired collateral and burn the ORS
        _ORS.poolBurn(msg.sender, ORSAmount_);
        SafeERC20.safeTransfer(_collateralToken, msg.sender, collateralAmountCollDec);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function toggleMinting() external onlyRole(MINT_PAUSER) {
        mintPaused = !mintPaused;

        emit MintingToggled(mintPaused);
    }

    function toggleRedeeming() external onlyRole(REDEEM_PAUSER) {
        redeemPaused = !redeemPaused;

        emit RedeemingToggled(redeemPaused);
    }

    function toggleRecollateralize() external onlyRole(RECOLLATERALIZE_PAUSER) {
        recollateralizePaused = !recollateralizePaused;

        emit RecollateralizeToggled(recollateralizePaused);
    }
    
    function toggleBuyBack() external onlyRole(BUYBACK_PAUSER) {
        buyBackPaused = !buyBackPaused;

        emit BuybackToggled(buyBackPaused);
    }

    function toggleCollateralPrice(uint256 pausedPrice_) external onlyRole(COLLATERAL_PRICE_PAUSER) {
        pausedPrice = pausedPrice_;
        collateralPricePaused = pausedPrice_ == 0;

        emit CollateralPriceToggled(collateralPricePaused, pausedPrice);
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(
        uint256 poolCeiling_,
        uint256 bonusRate_,
        uint256 redemptionDelay_,
        uint256 mintingFee_,
        uint256 redemptionFee_,
        uint256 buybackFee_,
        uint256 recollatFee_
    ) external onlyByOwnerOrGovernance {
        poolCeiling = poolCeiling_;
        bonusRate = bonusRate_;
        redemptionDelay = redemptionDelay_;
        mintingFee = mintingFee_;
        redemptionFee = redemptionFee_;
        buybackFee = buybackFee_;
        recollatFee = recollatFee_;

        emit PoolParametersSet(poolCeiling_, bonusRate_, redemptionDelay_, mintingFee_, redemptionFee_, buybackFee_, recollatFee_);
    }

    function setTimelock(address timelockAddress_) external onlyByOwnerOrGovernance {
        _timelockAddress = timelockAddress_;

        emit TimelockSet(timelockAddress_);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _collateralBalance() private view returns (uint256) {
        return _collateralToken.balanceOf(address(this)) * G_PRECISION / _collateralPrecision;
    }

    function _collateralPrice() private view returns (uint256) {
        return _prices.getChainlinkPrice(_chainlinkPairAddress);
    }

    function _calcFee(uint256 amount_, uint256 fee_) private pure returns (uint256) {
        return amount_ * (G_PRECISION - fee_) / G_PRECISION;
    }
}

// SPDX-License-Identifier: MIT

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Globals.sol";

library USDoPoolLibrary {
    // ================ Functions ================

    // all data mast have G_PRECISIONS

    function calcMint1t1USDo(uint256 collateralPrice_, uint256 collateralAmount_) external pure returns (uint256) {
        return collateralAmount_ * collateralPrice_ / G_PRECISION;
    }

    function calcMintAlgorithmicUSDo(uint256 ORSPrice_, uint256 ORSAmount_) external pure returns (uint256) {
        return ORSAmount_ * ORSPrice_ / G_PRECISION;
    }

    // Must be internal because of the struct
    function calcMintFractionalUSDo(
        uint256 ORSPrice_,
        uint256 collateralPrice_,
        uint256 collateralAmount_,
        uint256 collateralRatio_
    ) internal pure returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint USDo. We do this by seeing the minimum mintable USDo based on each amount

        uint256 collateralDollarValue = collateralAmount_ * collateralPrice_ / G_PRECISION;

        uint256 calculatedORSDollarValue = (collateralDollarValue * G_PRECISION / collateralRatio_) - collateralDollarValue;

        uint256 calculatedORSNeeded = calculatedORSDollarValue * G_PRECISION / ORSPrice_;

        return (
            collateralDollarValue + calculatedORSDollarValue,
            calculatedORSNeeded
        );
    }

    function calcRedeem1t1USDo(uint256 collateralPrice_, uint256 USDoAmount_) public pure returns (uint256) {
        return USDoAmount_ * G_PRECISION / collateralPrice_;
    }

    // Must be internal because of the struct
    function calcBuyBackORS(uint256 ORSPrice_, uint256 ORSAmount_, uint256 collateralPrice_, uint256 excessCollateralDollarValue_) internal pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible ORS with the desired collateral
        require(excessCollateralDollarValue_ > 0, "USDoPoolLibrary: No excess collateral to buy back!");

        // Make sure not to take more than is available
        uint256 ORSDollarValue = ORSAmount_ * ORSPrice_ / G_PRECISION;

        require(ORSDollarValue <= excessCollateralDollarValue_, "USDoPoolLibrary: You are trying to buy back more than the excess!");

        // Get the equivalent amount of collateral based on the market value of FXS provided 
        return ORSDollarValue * G_PRECISION / collateralPrice_;
    }


    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(uint256 totalSupply_, uint256 globalCollateralRatio_, uint256 globalCollateralValue_) public pure returns (uint256) {
        uint256 targetCollateralValue = totalSupply_ * globalCollateralRatio_ / G_PRECISION;
        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return targetCollateralValue < globalCollateralValue_ ? 0 : targetCollateralValue - globalCollateralValue_;
    }

    function calcRecollateralizeUSDoInner(
        uint256 collateralAmount_,
        uint256 collateralPrice_,
        uint256 globalCollateralValue_,
        uint256 USDoTotalSupply_,
        uint256 globalCollateralRatio_
    ) public pure returns (uint256, uint256) {
        uint256 collateralValueAttempted = collateralAmount_ * collateralPrice_ / G_PRECISION;
        uint256 effectiveCollateralRatio = globalCollateralValue_ * G_PRECISION / USDoTotalSupply_;
        uint256 recollateralizePossible = ((globalCollateralRatio_ * USDoTotalSupply_) - (effectiveCollateralRatio * USDoTotalSupply_)) / G_PRECISION;
        uint256 amountToRecollateralize = collateralValueAttempted <= recollateralizePossible ? collateralValueAttempted : recollateralizePossible;

        return (amountToRecollateralize * G_PRECISION / collateralPrice_, amountToRecollateralize);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/access/AccessControl.sol';

import "./Globals.sol";
import "./OrionStablecoin.sol";

contract OrionShares is ERC20, AccessControl {
    IERC20 private _ORN;
    OrionStablecoin private _USDo;

    address public ORNAddress;
    address public USDoAddress;

    constructor(string memory name_, string memory symbol_, address ORNAddress_, address USDoAddress_)
    ERC20(name_, symbol_)
    {
        require(ORNAddress_ != address(0), "ORS: Zero ORN address");
        require(USDoAddress_ != address(0), "ORS: Zero USDo address");

        ORNAddress = ORNAddress_;
        USDoAddress = USDoAddress_;

        _ORN = IERC20(ORNAddress_);
        _USDo = OrionStablecoin(USDoAddress_);
    }

    modifier onlyPools() {
        require(_USDo.hasRole(POOL_ROLE, msg.sender));
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return uint8(G_DECIMALS);
    }

    function swapORNtoORS(uint256 amount_) public {
        require(amount_ > 0, "ORS: ORN amount is zero");

        _ORN.transferFrom(msg.sender, address(this), amount_);
        _mint(msg.sender, amount_);
    }

    function swapORStoORN(uint256 amount_) public {
        require(amount_ > 0, "ORS: ORS amount is zero");

        _burn(msg.sender, amount_);
        _ORN.transfer(msg.sender, amount_);
    }

    function poolMint(address account_, uint256 amount_) external onlyPools {
        require(amount_ > 0, "ORS: ORS amount is zero");

        _mint(account_, amount_);
    }

    function poolBurn(address account_, uint256 amount_) external onlyPools {
        require(amount_ > 0, "ORS: ORS amount is zero");

        _burn(account_, amount_);
    }
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

