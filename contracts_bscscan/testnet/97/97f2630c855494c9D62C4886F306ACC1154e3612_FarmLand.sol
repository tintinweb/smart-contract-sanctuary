// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IAGold.sol";

contract APapyrus is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    struct FeePair {
        uint256 fee;
        address receiver;
    }

    bool public saleEnabled_;
    uint256 public price;
    address public collateral;

    mapping(uint256 => FeePair) public feeMap;

    function initialize() public initializer {
        __ERC20_init("AoE-Papyrus", "aPapyrus");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        setup();
    }

    function setup() public onlyOwner {
        saleEnabled_ = false;
        price = 100;
        //AGold
        collateral = address(0x5B5214c6110a2B538C2541998b243ec1CC517E24);
        _mint(msg.sender, 1 * 10**decimals());

        //1-Play2Earn
        feeMap[1].receiver = 0x67B5194D5e11a451BD3690C0D60dCBB0eA8D7F74;
        feeMap[1].fee = 50;
        //2-Liquidity
        feeMap[2].receiver = 0x7c528612f1E49A653552450c532a6Ef428a7278c;
        feeMap[2].fee = 47;
        //3-Developers
        feeMap[3].receiver = 0x7dF4a3cEaB37A5c0Fbc82DA090D76E1Cc88Ddd34;
        feeMap[3].fee = 0;
        //4-Marketing
        feeMap[4].receiver = 0x90aaa026541A9d78D67077362996F1BAF2eef29B;
        feeMap[4].fee = 0;
        //5-GameEcosys
        feeMap[5].receiver = 0x7dF4a3cEaB37A5c0Fbc82DA090D76E1Cc88Ddd34;
        feeMap[5].fee = 1;
        //6-Burn
        feeMap[6].receiver = address(0xdEaD);
        feeMap[6].fee = 1;
    }
    function getImplementation() public virtual returns (address) {
        return super._getImplementation();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function saleEnabled(bool status) public onlyOwner {
        saleEnabled_ = status;
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setCollateral(address collateralAddress) public onlyOwner {
        collateral = collateralAddress;
    }

    function getCollateral() public view returns (address) {
        return collateral;
    }

    function setPlay2Earn(address addr, uint256 fee) public onlyOwner {
        feeMap[1].receiver = addr;
        feeMap[1].fee = fee;
    }

    function getPlay2Earn() public view virtual returns (address, uint256) {
        return (feeMap[1].receiver, feeMap[1].fee);
    }

    function setLiquidityFee(address addr, uint256 fee) public onlyOwner {
        feeMap[2].receiver = addr;
        feeMap[2].fee = fee;
    }

    function setMarketingFee(address addr, uint256 fee) public onlyOwner {
        feeMap[4].receiver = addr;
        feeMap[4].fee = fee;
    }

    function setDevelopersFee(address addr, uint256 fee) public onlyOwner {
        feeMap[3].receiver = addr;
        feeMap[3].fee = fee;
    }

    function setGameEcosysFee(address addr, uint256 fee) public onlyOwner {
        feeMap[5].receiver = addr;
        feeMap[5].fee = fee;
    }

    function setBurnFee(address addr, uint256 fee) public onlyOwner {
        feeMap[6].receiver = addr;
        feeMap[6].fee = fee;
    }

    function Buy(address buyer, uint256 amount) public {
        uint256 totalBuy = amount.mul(price);
        IAGold collateralToken = IAGold(collateral);
        uint256 senderBalance = collateralToken.balanceOf(buyer);
        uint256 allowance = collateralToken.allowance(buyer, address(this));

        require(saleEnabled_, "Sales disabled");
        require(senderBalance >= totalBuy, "Insuficient collateral");
        require(allowance >= totalBuy, "Insuficient collateral allowance");

        collateralToken.transferFrom(
            buyer,
            feeMap[1].receiver,
            (totalBuy.mul(feeMap[1].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[2].receiver,
            (totalBuy.mul(feeMap[2].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[3].receiver,
            (totalBuy.mul(feeMap[3].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[4].receiver,
            (totalBuy.mul(feeMap[4].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[5].receiver,
            (totalBuy.mul(feeMap[5].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[6].receiver,
            (totalBuy.mul(feeMap[6].fee)).div(100)
        );

        _mint(buyer, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        //unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
        //}
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        //unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
        //}
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        //unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
        //}
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        //unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
        //}
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        //unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
        //}
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        //unchecked {
        require(b <= a, errorMessage);
        return a - b;
        //}
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        //unchecked {
        require(b > 0, errorMessage);
        return a / b;
        //}
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        //unchecked {
        require(b > 0, errorMessage);
        return a % b;
        //}
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract IAGold {
    function approve(address spender, uint256 amount)
        external
        virtual
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    function allowance(address owner, address spender)
        external
        view
        virtual
        returns (uint256);

    function balanceOf(address account) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./IApeBuilding.sol";
import "./IApes.sol";
import "./IAGold.sol";
import "./IAPapyrus.sol";

contract FarmLand is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    //Contract Addresses
    bool public landEnabled;
    address public buildingsContract;
    address public apeContract;
    address public aGoldContract;
    address public aPapyrusContract;

    //Owner address => BuildingTypeNum => BuildingIDs stacked
    mapping(address => mapping(uint256 => uint256[]))
        public buildingOwnerByTypeBuildings;
    //BuildingID => Owner Address
    mapping(uint256 => address) public buildingOwnerAddress;
    //BuildingID => Slot[] => ApeID
    mapping(uint256 => uint256[3]) public buildingSlotApe;
    //BuildingID => Count(*) Apes
    mapping(uint256 => uint256) public buildingApeCounter;
    //BuildingTypeNum => BaseReward
    mapping(uint256 => uint256) public buildingTypeBaseRewards;

    //Owner address => ApeTypeNum => IDs stacked
    mapping(address => mapping(uint256 => uint256[]))
        public apesOwnerByTypeApes;
    //ApeID => Owner Address
    mapping(uint256 => address) public apeOwnerAddress;
    //ApeID => BuildingID
    mapping(uint256 => uint256) public apeBuildingMap;
    //ApeID Farming init timestamp
    mapping(uint256 => uint256) public apeFarmingInitTimestamp;
    //ApeID Stack init timestamp
    mapping(uint256 => uint256) public apeStackInitTimestamp;
    //ApeTypeNum => BaseReward
    mapping(uint256 => uint256) public apeTypeBaseRewards;

    //Methods
    function initialize() public initializer {
        __ERC1155_init(
            "https://static.apesofempires.com/nfts/json/FarmLand.json"
        );
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        landEnabled = false;

        //BSCTestValues
        aGoldContract = address(0x729c41AE0e73DA7807d438ea9784A12D2c4A57A4);
        apeContract = address(0x0f79C606e7061da01B5c47b3958f83E948567240);
        buildingsContract = address(0xCD907E18B8758ce33814F71D8860B01539504D9c);
        aPapyrusContract = address(0xF8690fbFF7070D3901e01Dc1aa9f3733b2FaAC7F);

        mint(_msgSender(), 0, 1, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // custom setters
    function setLandEnabled(bool val) public onlyOwner {
        landEnabled = val;
    }

    function setBuildingsContract(address val) public onlyOwner {
        buildingsContract = val;
    }

    function setApeContract(address val) public onlyOwner {
        apeContract = val;
    }

    function setAPapyrusAddr(address aval) public onlyOwner {
        aPapyrusContract = aval;
    }

    function setAGoldAddr(address val) public onlyOwner {
        aGoldContract = val;
    }

    function setApesBaseRewards(
        uint256 normalReward,
        uint256 farmerReward,
        uint256 warriorReward
    ) public onlyOwner {
        apeTypeBaseRewards[1] = normalReward;
        apeTypeBaseRewards[2] = farmerReward;
        apeTypeBaseRewards[3] = warriorReward;
    }

    //TEST settters
    function setTimeStamps(
        bool manualDays,
        uint256 apeNftId,
        uint256 startFarmingAgo,
        uint256 startStakeAgo
    ) public onlyOwner {
        if (manualDays) {
            apeFarmingInitTimestamp[apeNftId] = (block.timestamp -
                (startFarmingAgo * 3600 * 24));
            apeStackInitTimestamp[apeNftId] = (block.timestamp -
                (startStakeAgo * 3600 * 24));
        } else {
            apeFarmingInitTimestamp[apeNftId] = (block.timestamp -
                startFarmingAgo);
            apeStackInitTimestamp[apeNftId] = (block.timestamp - startStakeAgo);
        }
    }

    function stackBuilding(
        uint256 buildingNftID
    ) public {
        address sender = address(msg.sender);
        IApeBuilding apeBuilding = IApeBuilding(buildingsContract);
        require(
            apeBuilding.ownerOf(buildingNftID) == sender,
            "Ownership failed"
        );
        require(
            buildingOwnerAddress[buildingNftID] == address(0x000),
            "Already stacked"
        );
        buildingOwnerAddress[buildingNftID] = sender;
        buildingOwnerByTypeBuildings[sender][apeBuilding.getTypeIDByNftID(buildingNftID)].push(buildingNftID);
        apeBuilding.transferFrom(sender, address(this), buildingNftID);
    }

    //NEW: Only stake an ApeId to a BuildingId in a SlotPosition (0 - 2)
    function stackApe(
        uint256 apeNftId,
        uint256 buildingId,
        uint256 slot
    ) public {
        address sender = address(msg.sender);
        IApes apesInstance = IApes(apeContract);
        require(
            apesInstance.ownerOf(apeNftId) == sender,
            "You're not the owner of this ape"
        );
        require(
            apeOwnerAddress[apeNftId] == address(0x000),
            "Ape already Stacked"
        );
        IApeBuilding aBuildInstance = IApeBuilding(buildingsContract);
        require(
            buildingOwnerAddress[buildingId] == sender,
            "Building isn't staked"
        );
        require(buildingApeCounter[buildingId] < 4, "Building is full");
        require(
            apesInstance.typeOfApeById(apeNftId) ==
                aBuildInstance.getTypeIDByNftID(buildingId),
            "Ape on building error"
        );
        require(slot < 3, "Invalid slot");
        apeOwnerAddress[apeNftId] = sender;
        buildingApeCounter[buildingId]++;
        apeBuildingMap[apeNftId] = buildingId;
        buildingSlotApe[buildingId][slot] = apeNftId;
        apeFarmingInitTimestamp[apeNftId] = block.timestamp;
        apeStackInitTimestamp[apeNftId] = block.timestamp;
        apesInstance.transferFrom(sender, address(this), apeNftId);
    }

    //NEW: Only un-stake an ApeId to a BuildingId in a SlotPosition (0 - 2) (Claim called)
    function unstackApe(
        uint256 apeNftId,
        uint256 buildingNftId,
        uint256 slot
    ) public returns (uint256 rewardsEarned) {
        uint256 rewards = claim(apeNftId, buildingNftId);
        address sender = address(msg.sender);
        IApes apesInstance = IApes(apeContract);
        require(
            apeOwnerAddress[apeNftId] == sender,
            "APE not staked or owner failed"
        );
        require(
            apeBuildingMap[apeNftId] == buildingNftId,
            "APE on Building error"
        );
        require(slot < 3, "Invalid slot");
        apeOwnerAddress[apeNftId] = address(0x000);
        buildingApeCounter[buildingNftId]--;
        apeBuildingMap[apeNftId] = 0;
        buildingSlotApe[buildingNftId][slot] = 0;
        apesInstance.setDeltaStack(
            apeNftId,
            block.timestamp - apeStackInitTimestamp[apeNftId]
        );
        apeStackInitTimestamp[apeNftId] = 0;

        apeFarmingInitTimestamp[apeNftId] = 0;
        apesInstance.transferFrom(address(this), sender, apeNftId);
        return rewards;
    }

    //NEW: Claim rewards from an ApeId stack in a BuildingId
    function claim(uint256 apeNftId, uint256 buildingId)
        public
        returns (uint256 rewardsEarned)
    {
        IAGold aGoldInstance = IAGold(aGoldContract);
        IApes apesInstance = IApes(apeContract);

        require(apeOwnerAddress[apeNftId] == _msgSender(), "Ape owner failed");
        require(apeBuildingMap[apeNftId] == buildingId, "Ape isnt stacked");
        require(
            apeFarmingInitTimestamp[apeNftId] != 0,
            "Nothing to claim, timestamp 0"
        );
        uint256 rewards = ((block.timestamp - apeFarmingInitTimestamp[apeNftId]) / 3600) *
                            (apeTypeBaseRewards[apesInstance.getTypeIdByNftId(apeNftId)] / 24);
        apeFarmingInitTimestamp[apeNftId] = block.timestamp;
        if (rewards > 0) {
            aGoldInstance.transfer(_msgSender(), rewards);
            return rewards;
        } else {
            return 0;
        }
    }
    //NEW: Claim all rewards from a BuildingId
    function claimBuildingRewards(
        uint256 buildingId,
        uint256 apeid1,
        uint256 apeid2,
        uint256 apeid3
    ) public returns (uint256 rewardsEarned) {
        require(apeid1 + apeid2 + apeid3 > 0, "Nothing to claim");
        if (apeid1 != 0) return claim(buildingId, apeid1);
        if (apeid2 != 0) return claim(buildingId, apeid2);
        if (apeid3 != 0) return claim(buildingId, apeid3);
        return 0;
    }

    function unStackBuilding(
        uint256 buildingNftId
    ) public {
        address sender = address(msg.sender);
        require(buildingOwnerAddress[buildingNftId] == sender, "Building owner failed");
        require(buildingApeCounter[buildingNftId] == 0, "Unstack Apes first");
        IApeBuilding apeBuilding = IApeBuilding(buildingsContract);
        buildingOwnerAddress[buildingNftId] = address(0x000);
        buildingOwnerByTypeBuildings[sender][apeBuilding.getTypeIDByNftID(buildingNftId)].pop();
        apeBuilding.transferFrom(address(this), sender, buildingNftId);
    }

    // function getStackedApesIdsByType(
    //     address owner, uint256 genericType
    // ) public view returns (uint256[] memory)
    // {
    //     return apesOwnerByTypeApes[owner][genericType];
    // }

    function getStackedBuildingsIdsByType(address owner, uint256 genericType)
        public
        view
        returns (uint256[] memory)
    {
        return buildingOwnerByTypeBuildings[owner][genericType];
    }

    function currentFarmAccumulatorByApe(uint256 apeId)
        public
        view
        returns (uint256)
    {
        address owner = apeOwnerAddress[apeId];
        uint256 currentTimestamp = block.timestamp;
        IApes apesInstance = IApes(apeContract);
        uint256 genericType = apesInstance.getTypeIdByNftId(apeId);
        uint256 totalRewards = 0;
        if (buildingOwnerByTypeBuildings[owner][genericType].length <= 0) {
            totalRewards = 0;
        } else {
            uint256 apeDelta = currentTimestamp -
                apeFarmingInitTimestamp[apeId];
            totalRewards += apeDelta * apeTypeBaseRewards[genericType];
        }
        // adjust rewards
        totalRewards = totalRewards / 86400;

        return totalRewards;
    }

    function evolve(
        uint256 nftID,
        string memory newURI
    ) public {
        IAPapyrus aPapyrus = IAPapyrus(aPapyrusContract);
        require(
            aPapyrus.balanceOf(address(msg.sender)) >= 1,
            "aPapyrus failed"
        );
        require(
            aPapyrus.allowance(address(msg.sender), address(this)) >= 1,
            "allowance failed"
        );
        IApes apeInstance = IApes(apeContract);
        require(
            address(msg.sender) == apeInstance.ownerOf(nftID),
            "ownership failed"
        );
        uint256 currLevel = apeInstance.getLevel(nftID);
        require(
            currLevel != 0 && currLevel != 3,
            "Baby and Warrriors cant evolve"
        );

        if (address(msg.sender) != this.owner()) {
            require(
                (block.timestamp - apeFarmingInitTimestamp[nftID - 1]) >=
                    1209600,
                "farming period below 14 days"
            );
        }

        if (currLevel == 1) {
            aPapyrus.transferFrom(
                address(msg.sender),
                address(aPapyrusContract),
                1
            );
            apeInstance.setLevel(nftID, 2);
            apeInstance.setDeltaStack(nftID, 0);
            apeInstance.setURI(nftID,newURI);
        }
        if (currLevel == 2) {
            aPapyrus.transferFrom(
                address(msg.sender),
                address(aPapyrusContract),
                1
            );
            apeInstance.setLevel(nftID, 3);
            apeInstance.setDeltaStack(nftID, 0);
            apeInstance.setURI(nftID,newURI);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
pragma solidity ^0.8.4;
interface IApeBuilding {
  function Buy ( string memory buildingName, address buyer ) external;
  function approve ( address to, uint256 tokenId ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function builtAtBlock ( uint256 ) external view returns ( uint256 );
  function collaterals ( string memory ) external view returns ( address );
  function feeMap ( uint256 ) external view returns ( uint256 fee, address receiver );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function getPlay2Earn (  ) external view returns ( address, uint256 );
  function initialize (  ) external;
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function name (  ) external view returns ( string memory);
  function owner (  ) external view returns ( address );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function pause (  ) external;
  function paused (  ) external view returns ( bool );
  function renounceOwnership (  ) external;
  function safeMint ( address to ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory _data ) external;
  function saleEnabled ( string memory buildingName, bool status ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setBuildingProps ( uint256 typeID, string memory buildingName, uint256 rewardRate, uint256 slots, address collateral, uint256 price, bool isOnSale, string memory fullURI ) external;
  function setBuiltBlock ( uint256 blockNumber, uint256 buildingID ) external;
  function setBurnFee ( address addr, uint256 fee ) external;
  function setCollateral ( string memory bName, address collateralAddress ) external;
  function setDevelopersFee ( address addr, uint256 fee ) external;
  function setGameEcosysFee ( address addr, uint256 fee ) external;
  function setLiquidityFee ( address addr, uint256 fee ) external;
  function setMarketingFee ( address addr, uint256 fee ) external;
  function setPlay2Earn ( address addr, uint256 fee ) external;
  function setPrice ( string memory buildingName, uint256 price_ ) external;
  function setTokenURI ( string memory fullURI, uint256 tokenId ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function tokenByIndex ( uint256 index ) external view returns ( uint256 );
  function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
  function tokenURI ( uint256 tokenId ) external view returns ( string memory);
  function totalSupply (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferOwnership ( address newOwner ) external;
  function unpause (  ) external;
  function upgradeTo ( address newImplementation ) external;
  function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
  function typeOfBuildingByNFTId (uint256 u) external returns(string memory);
  function bProps (string memory p) external returns(uint256 typeID, string memory buildingName, uint256 rewardRate, uint256 slots, address collateral, uint256 price, bool saleEnabled, string memory fullURI);
  function getTypeIDByNftID(uint256 nftId) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IApes {
  function aBananaAddr (  ) external view returns ( address );
  function aGoldAddr (  ) external view returns ( address );
  function aPapyrusAddr (  ) external view returns ( address );
  function aStoneAddr (  ) external view returns ( address );
  function aStrawAddr (  ) external view returns ( address );
  function aWoodAddr (  ) external view returns ( address );
  function apes ( uint256 ) external view returns ( uint256 idx, uint256 id, uint8 level, uint256 age, string memory edition, uint256 bornAt, bool onSale, uint256 price );
  function approve ( address to, uint256 tokenId ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function bnbAddr (  ) external view returns ( address );
  function buy ( uint256 _tokenId ) external;
  function devWallet (  ) external view returns ( address );
  function evolvePrice (  ) external view returns ( uint256 );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function getOwned (  ) external view returns ( uint256[] memory );
  function grow ( uint256 _tokenIdx ) external;
  function growPrice (  ) external view returns ( uint256 );
  function initialize (  ) external;
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function liquidityWallet (  ) external view returns ( address );
  function listToSell ( uint256 _idx, uint256 _price ) external;
  function manualMint ( string memory _name, string memory _tokenURI, uint256 _level, uint256 _age, string memory _edition, address _owner ) external;
  function marketingWallet (  ) external view returns ( address );
  function migrate ( uint256 _tokenId ) external;
  function mintPrice (  ) external view returns ( uint256 );
  function mintWithFee ( string memory _name, string memory _tokenURI ) external;
  function name (  ) external view returns ( string memory );
  function owner (  ) external view returns ( address );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function pancakeAddr (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function rewardsWallet (  ) external view returns ( address );
  function safeMint ( address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory _data ) external;
  function setABananaAddr ( address ba ) external;
  function setAGoldAddr ( address aa ) external;
  function setAPapyrusAddr ( address pa ) external;
  function setAStoneAddr ( address sa ) external;
  function setAStrawAddr ( address sa ) external;
  function setAWoodAddr ( address wa ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setBNBAddr ( address ba ) external;
  function setDevWallet ( address dw ) external;
  function setEvolvePrice ( uint256 ep ) external;
  function setGrowPrice ( uint256 gp ) external;
  function setLiquidityWallet ( address lw ) external;
  function setMarketingWallet ( address mw ) external;
  function setMintPrice ( uint256 mp ) external;
  function setPancakeAddr ( address pa ) external;
  function setRewardsWallet ( address rw ) external;
  function setWAGoldAddr ( address waa ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function tokenByIndex ( uint256 index ) external view returns ( uint256 );
  function tokenIdToName ( uint256 ) external view returns ( string memory );
  function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
  function tokenURI ( uint256 tokenId ) external view returns ( string memory );
  function totalSupply (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferOwnership ( address newOwner ) external;
  function upgradeTo ( address newImplementation ) external;
  function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
  function wAGoldAddr (  ) external view returns ( address );
  function withdrawFromSell ( uint256 _idx ) external;
  function getTypeIdByNftId (uint256 u) external view returns(uint256);
  function getLevel (uint256 nftID) external view returns(uint256);
  function setLevel (uint nftID, uint lvl) external;
  function setDeltaStack (uint nftID, uint delta) external;
  function deltaStack(uint nftID) external returns (uint256);
  function typeOfApeById (uint256 nftID) external view returns(uint256);
  function setURI(uint256 apeNftId, string memory newURI) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface IAPapyrus {
  function Buy ( address buyer, uint256 amount ) external;
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function collateral (  ) external view returns ( address );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function feeMap ( uint256 ) external view returns ( uint256 fee, address receiver );
  function getCollateral (  ) external view returns ( address );
  function getImplementation (  ) external returns ( address );
  function getPlay2Earn (  ) external view returns ( address, uint256 );
  function getPrice (  ) external view returns ( uint256 );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function initialize (  ) external;
  function mint ( address to, uint256 amount ) external;
  function name (  ) external view returns ( string memory );
  function owner (  ) external view returns ( address );
  function pause (  ) external;
  function paused (  ) external view returns ( bool );
  function price (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function saleEnabled ( bool status ) external;
  function saleEnabled_ (  ) external view returns ( bool );
  function setBurnFee ( address addr, uint256 fee ) external;
  function setCollateral ( address collateralAddress ) external;
  function setDevelopersFee ( address addr, uint256 fee ) external;
  function setGameEcosysFee ( address addr, uint256 fee ) external;
  function setLiquidityFee ( address addr, uint256 fee ) external;
  function setMarketingFee ( address addr, uint256 fee ) external;
  function setPlay2Earn ( address addr, uint256 fee ) external;
  function setPrice ( uint256 price_ ) external;
  function setup (  ) external;
  function symbol (  ) external view returns ( string memory );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function unpause (  ) external;
  function upgradeTo ( address newImplementation ) external;
  function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./IApeBuilding.sol";
import "./IApes.sol";
import "./IAGold.sol";

contract ApesLandBSC is
  Initializable,
  ERC1155Upgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  bool public landEnabled_;
  address payable public GnosisSafeVault;
  address public buildingsContract;
  address public apeContract;
  uint256 public specialBlock;
  address public aGoldAddress;

  /* NOTE
    It maps buildings types to its corresponding apes types:
    1 = ApeHouse = NormalApe
    2 = FarmHouse = FarmApe
    3 = BarracksHouse = WarriorApe
    We call this type "genericType"
  */
  // User address => BuildingType => IDs stacked
  mapping(address => mapping(uint256 => uint256[])) public addressToBuildingsType;
  // Building Id => Owner Address
  mapping(uint256 => address) buildsAtAddress;
  // User address => Ape Type => IDs stacked
  mapping(address => mapping(uint256 => uint256[])) public addressToApesType;
  // Ape Id => Owner Address
  mapping(uint256 => address) public apesAtAddress;
  // buildingType => BaseReward
  mapping(uint256 => uint256) public buildingTypeBaseRewards;
  // buildingType => BaseReward, it use the info that a building type only stack one type of ape
  mapping(uint256 => uint256) public apeTypeBaseRewards;
  // ape Id => tiemstamp when it start farming
  mapping(uint256 => uint256) public apeStartFarmingTimestamp;
  //Special Rewards Claim (NFTID - Amount)
  mapping(uint256 => uint256) public NftIDClaimed;
  //Special Reward Blocks
  uint256 public specialStartBlockTime;
  uint256 public specialEndBlockTime;
  uint256 public rewardFactor;
  event SpecialRewardClaimed(uint256 nftID, uint256 amount);
  struct Enemy {
    uint256 typeNum;
    uint256 bait;
    uint256 reward;
    uint256 winningProb;
  }
  mapping(uint256 => Enemy) public enemies_;
  mapping(uint256 => uint256) public winsByNftId;
  mapping(uint256 => uint256) public totalFightsByNftId;
  event FightFinished(address player, uint256 figtherNftID, bool result, uint256 amount);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() public initializer {
    __ERC1155_init(
        "https://storageapi.fleek.co/877cda1b-4b59-49b8-bdc3-d65ac313f1b6-bucket/NFTs/ApesLand.json"
    );
    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();
    landEnabled_ = true;
    GnosisSafeVault = payable(address(0xfc50B6714482D5cc03cf2d720Dc0b8AE7FC53b2e)); //
    specialBlock = 10949308; //BSC Block at 23:59:59 UTC 15th SET 2021
    aGoldAddress = address(0x5B5214c6110a2B538C2541998b243ec1CC517E24);
    apeContract = address(0xB262AF33e33999777D17e8F6fae333069409aC71);
    buildingsContract = address(0x2aE364c7C33143c3426d1AeCd7b0EAfc8F39F989);
    specialStartBlockTime = 1631750400;
    specialEndBlockTime = 1632441600;
    rewardFactor = 3;
  }
  function setSpecialReward(uint256 startBlockTime, uint256 endBlockTime, uint256 rewFactor) public onlyOwner{
    specialStartBlockTime = startBlockTime;
    specialEndBlockTime = endBlockTime;
    rewardFactor = rewFactor;
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyOwner {
    _mint(account, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  // custom setters
  function setLandEnabled(bool val) public onlyOwner {
    landEnabled_ = val;
  }

  function setGnosisSafeVault(address val) public onlyOwner {
    GnosisSafeVault = payable(address(val));
  }
  function setBuildingsContract(address val) public onlyOwner {
    buildingsContract = val;
  }
  function setApeContract(address val) public onlyOwner {
    apeContract = val;
  }
  function setSpecialBlock(uint256 blockNumber) public onlyOwner {
    specialBlock = blockNumber;
  }
  function setAGoldAddr(address val) public onlyOwner {
    aGoldAddress = val;
  }
  function setBuildingsBaseRewards(uint256 houseReward, uint256 farmReward, uint256 barrackReward) public onlyOwner {
    buildingTypeBaseRewards[1] = houseReward;
    buildingTypeBaseRewards[2] = farmReward;
    buildingTypeBaseRewards[3] = barrackReward;
  }
  function setApesBaseRewards(uint256 normalReward, uint256 farmerReward, uint256 warriorReward) public onlyOwner {
    apeTypeBaseRewards[1] = normalReward;
    apeTypeBaseRewards[2] = farmerReward;
    apeTypeBaseRewards[3] = warriorReward;
  }
  
  // contract logic
  function stackBuilding(uint256 buildingNftID) public {
    address sender = address(msg.sender);
    IApeBuilding apeBuilding = IApeBuilding(buildingsContract);
    require(apeBuilding.ownerOf(buildingNftID) == sender, "You're not the owner of this building");
    require(buildsAtAddress[buildingNftID] == address(0x000), "Building already Stacked");
    // if there are buildings with apes of this kind at stack, make a claim without un-stacking
    uint256 genericType = apeBuilding.getTypeIDByNftID(buildingNftID);
    // TODO: Revisar creo que no debería hacer esto dado que cuando va haciendo el claim lo haría 2 veces
    // if (addressToBuildingsType[sender][genericType].length > 0 && addressToApesType[sender][genericType].length > 0) {
    //   claimRewardsWithoutUnStack(genericType, sender);
    // }
    buildsAtAddress[buildingNftID] = sender;
    addressToBuildingsType[sender][genericType].push(buildingNftID);
    apeBuilding.transferFrom(sender, address(this), buildingNftID);
  }
  function stackApe(uint256 apeNftId) public {
    address sender = address(msg.sender);
    IApes apesInstance = IApes(apeContract);
    require(apesInstance.ownerOf(apeNftId) == sender, "You're not the owner of this ape");
    require(apesAtAddress[apeNftId] == address(0x000), "Ape already Stacked");
    uint256 genericType = apesInstance.getTypeIdByNftId(apeNftId);
    uint256 apesByType = addressToApesType[sender][genericType].length;
    uint256 maxSlots = addressToBuildingsType[sender][genericType].length * 3;
    uint256 freeSlots = maxSlots - apesByType;
    require(freeSlots > 0, "Not free slots");

    addressToApesType[sender][apesInstance.getTypeIdByNftId(apeNftId)].push(apeNftId);
    apesAtAddress[apeNftId] = sender;
    apesInstance.transferFrom(sender, address(this), apeNftId);
    // claimRewards(); => Ya no se hace dado que solo se puede hacer cuando no generó nada
    apeStartFarmingTimestamp[apeNftId] = block.timestamp;
  }
  function unStackBuilding(uint256 genericType) public {
    address sender = address(msg.sender);
    require(addressToApesType[sender][genericType].length == 0, "make claim instead");
    IApeBuilding apeBuilding = IApeBuilding(buildingsContract);
    require(addressToBuildingsType[sender][genericType].length > 0, "not stacked of this type");
    uint256 nftId = addressToBuildingsType[sender][genericType][addressToBuildingsType[sender][genericType].length - 1];
    require(buildsAtAddress[nftId] == sender, "not the stacker");
    // Como va a sacar un edificio tiene que haber al menos 3 slots libres
    uint256 apesByType = addressToApesType[sender][genericType].length;
    uint256 maxSlots = addressToBuildingsType[sender][genericType].length * 3;
    uint256 freeSlots = maxSlots - apesByType;
    require(freeSlots >= 3, "still apes on building");
    addressToBuildingsType[sender][genericType].pop();
    buildsAtAddress[nftId] = address(0x000);
    apeBuilding.transferFrom(address(this), sender, nftId);
  }
  function unStackApes(uint256 genericType) public {
    address sender = address(msg.sender);
    require(addressToBuildingsType[sender][genericType].length == 0, "make claim instead");
    IApes apesInstance = IApes(apeContract);
    require(addressToApesType[sender][genericType].length > 0, "not apes of this type");
    uint256 nftId = addressToApesType[sender][genericType][addressToApesType[sender][genericType].length];
    addressToApesType[sender][genericType].pop();
    require(apesAtAddress[nftId] == sender, "not the stacker");
    apesAtAddress[nftId] = address(0x000); 
    apesInstance.transferFrom(address(this), sender, nftId);
  }
  function adminUnStackApe(uint256 genericType, address owner, uint nftIdCheck) public onlyOwner {
    uint256 nftId = addressToApesType[owner][genericType][addressToApesType[owner][genericType].length - 1];
    require(nftId == nftIdCheck, "Ape NFT Id not match");
    addressToApesType[owner][genericType].pop();
    apesAtAddress[nftId] = address(0x000); 
  }
  /*
    With each claim call it withdraw all the profits collected by the last ape of beeing stack and un-stack it.
    If that ape was the only one in a building, also claim and un-stack the gold collected by the building.
  */
  function claimRewards(uint256 genericType) public {
    address sender = address(msg.sender);
    require(addressToApesType[sender][genericType].length > 0, "no apes of this type");
    IAGold aGold = IAGold(aGoldAddress);
    IApes apesInstance = IApes(apeContract);
    uint256 totalApesByType = addressToApesType[sender][genericType].length;
    uint256 nftId = addressToApesType[sender][genericType][totalApesByType - 1];
    uint256 calculatedDelta = (block.timestamp - apeStartFarmingTimestamp[nftId]);
    uint256 totalRewards = calculatedDelta * apeTypeBaseRewards[genericType];

    apesInstance.setDeltaStack(nftId, calculatedDelta);
    apesInstance.transferFrom(address(this), sender, nftId);
    apesAtAddress[nftId] = address(0x000);
    
    addressToApesType[sender][genericType].pop();
    // adjust rewards
    totalRewards = totalRewards / 86400;
    // transfer the rewards
    aGold.transfer(sender, totalRewards);
  }
  function claimRewardsWithoutUnStack(uint256 genericType, address sender) private {
    uint256 currentTimestamp = block.timestamp;
    require(addressToBuildingsType[sender][genericType].length > 0, "no buildings of this type");
    require(addressToApesType[sender][genericType].length > 0, "no apes of this type");
    IAGold aGold = IAGold(aGoldAddress);
    uint256 totalApesByType = addressToApesType[sender][genericType].length;
    // Add ape profits
    uint256 totalRewards = 0;
    uint256 apeDelta = currentTimestamp - apeStartFarmingTimestamp[addressToApesType[sender][genericType][totalApesByType - 1]];
    totalRewards += apeDelta * apeTypeBaseRewards[genericType];
    // Add building profits
    if (((totalApesByType - 1) % 3) == 0) {
      uint256 buildingDelta = currentTimestamp - apeStartFarmingTimestamp[addressToApesType[sender][genericType][totalApesByType - 1]];
      totalRewards += buildingDelta * buildingTypeBaseRewards[genericType];
    }
    // adjust rewards
    totalRewards = totalRewards / 86400;
    // transfer the rewards
    aGold.transfer(sender, totalRewards);
  }
  function getStackedApesIdsByType(address owner, uint256 genericType) public view returns(uint256[] memory) {
    return addressToApesType[owner][genericType];
  }
  function getStackedBuildingsIdsByType(address owner,uint256 genericType) public view returns(uint256[] memory) {
    return addressToBuildingsType[owner][genericType];
  }
  function currentFarmAccumulatorByApe(uint256 apeId) public view returns(uint256) {
    address owner = apesAtAddress[apeId];
    uint256 currentTimestamp = block.timestamp;
    IApes apesInstance = IApes(apeContract);
    uint256 genericType = apesInstance.getTypeIdByNftId(apeId);
    uint256 totalRewards = 0;
    if (addressToBuildingsType[owner][genericType].length <= 0) {
      totalRewards = 0;
    } else {
      uint256 apeDelta = currentTimestamp - apeStartFarmingTimestamp[apeId];
      totalRewards += apeDelta * apeTypeBaseRewards[genericType];
    }
     // adjust rewards
    totalRewards = totalRewards / 86400;

    return totalRewards;
  }
  function getApeAge(uint256 apeNftId) internal view returns (uint256){
    IApes apeInstance = IApes(apeContract);
    (
  	  uint256 idx,
	    uint256 id,
	    uint8 level,
	    uint256 age,
	    string memory edition,
	    uint256 bornAt,
	    bool onSale,
	    uint256 price
    ) = apeInstance.apes(apeNftId - 1);
    return bornAt;
  }

  function claimSpecialRewards(uint256 apeNftID) public returns (uint256){
    IApes apeInstance = IApes(apeContract);
    bool isOwner = apeInstance.ownerOf(apeNftID) == address(msg.sender);
    require(NftIDClaimed[apeNftID] < 1, "This APE has already claimed its reward");
    require(isOwner, "You aren't the owner of this APE"); 
    require(apeInstance.getTypeIdByNftId(apeNftID) > 0, "Baby Ape doesn't generate rewards");
    IAGold aGoldInstance = IAGold(aGoldAddress);
    uint256 apeAge = getApeAge(apeNftID);
    if(apeAge <= specialStartBlockTime)
    {
      uint256 totalRewards = (specialEndBlockTime - specialStartBlockTime) / 3600 * rewardFactor; //Delta Hours
      aGoldInstance.transfer(address(msg.sender), totalRewards);
      NftIDClaimed[apeNftID] = 1;
      emit SpecialRewardClaimed(apeNftID, totalRewards);
      return totalRewards;
    }
    else
    {
      uint256 totalRewards = (specialEndBlockTime - apeAge) / 3600 * rewardFactor;
      aGoldInstance.transfer(address(msg.sender), totalRewards);
      NftIDClaimed[apeNftID] = 1;
      emit SpecialRewardClaimed(apeNftID, totalRewards);
      return totalRewards;
    }
  }
  function calculateSpecialRewards(uint256 apeNftID) public view returns (uint256) {
    IApes apeInstance = IApes(apeContract);
    if (apeInstance.getTypeIdByNftId(apeNftID) == 0 || NftIDClaimed[apeNftID] >= 1) {
      return 0;
    }
    uint256 apeAge = getApeAge(apeNftID);
    if (apeAge <= specialStartBlockTime) {
      uint256 totalRewards = (specialEndBlockTime - specialStartBlockTime) / 3600 * rewardFactor;
      return totalRewards;
    } else {
      uint256 totalRewards = (specialEndBlockTime - apeAge) / 3600 * rewardFactor;
      return totalRewards;
    }
  }

  //FIGHT Section
  function createEnemy(uint256 typeNum,uint256 bait,uint256 reward,uint256 winningProv) public onlyOwner{
    Enemy memory _toCreate = Enemy(typeNum, bait, reward, winningProv);
    enemies_[typeNum] = _toCreate;
  }
  function fightAgainst(uint256 apeNftID, uint256 enemy) public returns (bool) {
    address sender = address(msg.sender);
    IApes apeInstance = IApes(apeContract);
    bool isOwner = apeInstance.ownerOf(apeNftID) == sender;
    bool isWarrior = apeInstance.getTypeIdByNftId(apeNftID) == 3;
    require(isOwner, "This APE doesn't belong to you");
    require(isWarrior, "Only Warrior APEs can fight");
    IAGold aGoldInstance = IAGold(aGoldAddress);
    require(aGoldInstance.balanceOf(sender) >= enemies_[enemy].bait, "Insufficient aGold to fight");
    require(aGoldInstance.allowance(sender, address(this)) >= enemies_[enemy].reward, "Insufficient allowance");

    bool won = fight(enemies_[enemy].winningProb);
    if(won){
      aGoldInstance.transfer(sender, (enemies_[enemy].reward));
      winsByNftId[apeNftID] += 1;
      totalFightsByNftId[apeNftID] += 1;
      emit FightFinished(sender, apeNftID, true, (enemies_[enemy].reward));
      return true;
    }
    else
    {
      aGoldInstance.transferFrom(sender, address(this), enemies_[enemy].bait);
      totalFightsByNftId[apeNftID] += 1;
      emit FightFinished(sender, apeNftID, false, (enemies_[enemy].bait));
      return false;
    }
  }
  function fight(uint percent) private view returns(bool) {
    uint256 spinResult = (block.gaslimit + block.timestamp) % 10; //Random 1 digit between 0-9
    uint256 adjPercent = (percent / 10) - 1;
    if (spinResult >= 0 && spinResult <= adjPercent) {
      return true;
    } 
    else 
    {
      return false;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSetUpgradeable.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMapUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSetUpgradeable.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
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
library EnumerableSetUpgradeable {
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IAGold.sol";
import "./IOldApe.sol";
import "./IApesLandV2.sol";

contract Apes is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC721_init("AoE-Apes", "aApe");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        setup();
    }

    uint256 public mintPrice;
    uint256 public growPrice;
    uint256 public evolvePrice;
    address public bnbAddr;
    address public aGoldAddr;
    address public wAGoldAddr;
    address public aBananaAddr;
    address public aPapyrusAddr;
    address public aStrawAddr;
    address public aStoneAddr;
    address public aWoodAddr;
    address public pancakeAddr;
    address public liquidityWallet;
    address public devWallet;
    address public marketingWallet;
    address public rewardsWallet;
    // Enums
    enum Level {
        Baby,
        TeenNormal,
        TeenFarmer,
        TeenWarrior,
        AdultNormal,
        AdultFarmer,
        AdultWarrior
    }
    // Structs
    struct Ape {
        uint256 idx;
        uint256 id;
        Level level;
        uint256 age; // stone, iron, future, etc
        string edition; //normal, christmas, etc
        uint256 bornAt;
        bool onSale;
        uint256 price;
    }
    Ape[] public apes;
    // Maps
    mapping(uint256 => string) public tokenIdToName;
    // Events
    event NftBought(address _seller, address _buyer, uint256 _price);
    mapping(uint256 => uint256) public typeOfApeById;
    address oldApes;
    address apesLandAddr;
    mapping(uint256 => uint256) public deltaStack;
    //FarmLand Address
    address public farmLandAddress;
    //ApeID => Won battles
    mapping(uint256 => uint256) public winsByNftId;
    //ApeID => Total Fights
    mapping(uint256 => uint256) public totalFightsByNftId;

    //Safe Zone --
    function setup() public onlyOwner {
        mintPrice = 1000;
        growPrice = 10;
        evolvePrice = 10000;
        aGoldAddr = address(0x729c41AE0e73DA7807d438ea9784A12D2c4A57A4);
        wAGoldAddr = address(0xC88517d800835801bcFfd2FC387a6b682Af641d0);
        aBananaAddr = address(0x20A7fE705cD18C35d4Da123BbEC812Ab73813E98);
        aPapyrusAddr = address(0xde7116afDc8a6f97c04E73decFdEf4b64EC2aa04);
        aStrawAddr = address(0x5D4Fc7EdD249Dd4C3a55d807954205e659Ff4394);
        aStoneAddr = address(0xf191cf06f18EA2E841f135cf2dCfc2612F1716F7);
        aWoodAddr = address(0x879a439926591f89AE0a4AcdA2B099Bcb95c25AF);
        liquidityWallet = address(0x7c528612f1E49A653552450c532a6Ef428a7278c);
        devWallet = address(0x7dF4a3cEaB37A5c0Fbc82DA090D76E1Cc88Ddd34);
        marketingWallet = address(0x90aaa026541A9d78D67077362996F1BAF2eef29B);
        rewardsWallet = address(0x67B5194D5e11a451BD3690C0D60dCBB0eA8D7F74);
        oldApes = address(0xCa00FDc5a1Fe300C703c9351B0d36cBFE0c1A2d4);
        farmLandAddress = address(0x000);
    }

    function setupTest() public onlyOwner {
        mintPrice = 1000;
        growPrice = 10;
        evolvePrice = 10000;
        aGoldAddr = address(0x729c41AE0e73DA7807d438ea9784A12D2c4A57A4);
        wAGoldAddr = address(0xC88517d800835801bcFfd2FC387a6b682Af641d0);
        aBananaAddr = address(0x1d1c01b72790965695ddE66DD8D6012E5296b995);
        aPapyrusAddr = address(0xF8690fbFF7070D3901e01Dc1aa9f3733b2FaAC7F);
        aStrawAddr = address(0x5D4Fc7EdD249Dd4C3a55d807954205e659Ff4394);
        aStoneAddr = address(0x1d58447c03F8d4c5857ED69cF3dB244E37DB8A67);
        aWoodAddr = address(0x2f1Ca363a4E79D9caa8c4a79a38eA002A94eB46D);
        liquidityWallet = address(_msgSender());
        devWallet = address(_msgSender());
        marketingWallet = address(_msgSender());
        rewardsWallet = address(_msgSender());
        oldApes = address(0xCa00FDc5a1Fe300C703c9351B0d36cBFE0c1A2d4);
        farmLandAddress = address(0x0bee23BB9f65D952db2d0198E21AD3fBD4B1014A);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Setters
    function setMintPrice(uint256 mp) public onlyOwner {
        mintPrice = mp;
    }

    function setGrowPrice(uint256 gp) public onlyOwner {
        growPrice = gp;
    }

    function setEvolvePrice(uint256 ep) public onlyOwner {
        evolvePrice = ep;
    }

    function setBNBAddr(address ba) public onlyOwner {
        bnbAddr = ba;
    }

    function setAGoldAddr(address aa) public onlyOwner {
        aGoldAddr = aa;
    }

    function setWAGoldAddr(address waa) public onlyOwner {
        wAGoldAddr = waa;
    }

    function setABananaAddr(address ba) public onlyOwner {
        aBananaAddr = ba;
    }

    function setAPapyrusAddr(address pa) public onlyOwner {
        aPapyrusAddr = pa;
    }

    function setAStrawAddr(address sa) public onlyOwner {
        aStrawAddr = sa;
    }

    function setAStoneAddr(address sa) public onlyOwner {
        aStoneAddr = sa;
    }

    function setAWoodAddr(address wa) public onlyOwner {
        aWoodAddr = wa;
    }

    function setPancakeAddr(address pa) public onlyOwner {
        pancakeAddr = pa;
    }

    function setLiquidityWallet(address lw) public onlyOwner {
        liquidityWallet = lw;
    }

    function setDevWallet(address dw) public onlyOwner {
        devWallet = dw;
    }

    function setMarketingWallet(address mw) public onlyOwner {
        marketingWallet = mw;
    }

    function setRewardsWallet(address rw) public onlyOwner {
        rewardsWallet = rw;
    }

    // Contract Logic
    function getRandomLevel(uint256 seed) private pure returns (Level) {
        // uint256 spinResult = SafeMath.mod(seed, 10);
        uint256 spinResult = seed % 10;
        if (spinResult == 9) {
            return Level.TeenWarrior;
        } else if (spinResult == 8 || spinResult == 7 || spinResult == 6) {
            return Level.TeenFarmer;
        } else {
            return Level.TeenNormal;
        }
    }

    function intToLevel(uint256 num) private pure returns (Level) {
        if (num == 1) {
            return Level.TeenNormal;
        } else if (num == 2) {
            return Level.TeenFarmer;
        } else if (num == 3) {
            return Level.TeenWarrior;
        } else if (num == 4) {
            return Level.AdultNormal;
        } else if (num == 5) {
            return Level.AdultFarmer;
        } else if (num == 6) {
            return Level.AdultWarrior;
        } else {
            return Level.Baby;
        }
    }

    function manualMint(
        string memory _name,
        string memory _tokenURI,
        uint256 _level,
        uint256 _age,
        string memory _edition,
        address _owner
    ) public {
        require(address(msg.sender) == devWallet, "no dev wallet");
        uint256 idx = apes.length;
        uint256 id = idx + 1;
        Level level = intToLevel(_level);
        Ape memory _toCreate = Ape(
            idx,
            id,
            level,
            _age,
            _edition,
            block.timestamp,
            false,
            0
        );
        apes.push(_toCreate);
        tokenIdToName[id] = _name;
        _mint(_owner, id);
        _setTokenURI(id, _tokenURI);
        typeOfApeById[id] = _level;
    }
    function setURI(uint256 apeNftId, string memory newURI) public {
        require((_msgSender() == this.owner()) || (_msgSender() == farmLandAddress),
                "setURI: Owner failed");
        _setTokenURI(apeNftId, newURI);
    }
    function mintWithFee(string memory _name, string memory _tokenURI) public {
        address deadWallet = 0x000000000000000000000000000000000000dEaD;
        IAGold aGold = IAGold(wAGoldAddr);

        address senderAddr = address(msg.sender);
        address apesAddr = address(this);
        uint256 senderBalance = aGold.balanceOf(senderAddr);
        uint256 allowance = aGold.allowance(senderAddr, apesAddr);
        require(senderBalance >= mintPrice, "not enough balance");
        require(allowance >= mintPrice, "not enough allowance");

        uint256 half = mintPrice / 2;
        uint256 otherHalf = mintPrice - half;
        uint256 onePercent = mintPrice / 100;
        uint256 restOtherHalf = otherHalf - onePercent;
        // // send one percent to burn
        aGold.transferFrom(senderAddr, deadWallet, onePercent);
        // // send 49% to rewards wallet
        aGold.transferFrom(senderAddr, rewardsWallet, restOtherHalf);
        // // send 50% to liquidity
        aGold.transferFrom(senderAddr, liquidityWallet, half);

        // Metadatos
        uint256 idx = apes.length;
        uint256 id = idx + 1;
        Ape memory _toCreate = Ape(
            idx,
            id,
            Level.Baby,
            0,
            "normal",
            block.timestamp,
            false,
            0
        );
        tokenIdToName[id] = _name;
        apes.push(_toCreate);
        _mint(msg.sender, id);
        _setTokenURI(id, _tokenURI);
        typeOfApeById[id] = 0;
    }

    function grow(uint256 _tokenIdx) public {
        address deadWallet = address(
            0x000000000000000000000000000000000000dEaD
        );
        IAGold aBanana = IAGold(aBananaAddr);
        address apesAddr = address(this);
        address senderAddr = address(msg.sender);
        uint256 tokenId = _tokenIdx + 1;
        uint256 senderBalance = aBanana.balanceOf(senderAddr);
        uint256 allowance = aBanana.allowance(senderAddr, apesAddr);

        require(senderAddr == ownerOf(tokenId), "not owner");
        require(senderBalance >= growPrice, "not enough balance");
        require(allowance >= growPrice, "not enough allowance");

        Ape memory current = apes[_tokenIdx];
        require(current.level == Level.Baby, "not a baby");

        current.level = getRandomLevel(block.timestamp);
        apes[_tokenIdx] = current;

        aBanana.transferFrom(senderAddr, deadWallet, growPrice);
        typeOfApeById[tokenId] = uint256(current.level);
    }

    function getOwned() public view returns (uint256[] memory) {
        uint256 cantOwned = balanceOf(msg.sender);
        uint256[] memory result = new uint256[](cantOwned);
        for (uint256 index = 0; index < cantOwned; index++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, index);
            result[index] = tokenId;
        }
        return result;
    }

    function listToSell(uint256 _idx, uint256 _price) public {
        Ape memory current = apes[_idx];
        address blockChainOwner = ownerOf(current.id);
        require(msg.sender == blockChainOwner, "not owner");
        require(_price > 0, "price is zero");

        current.onSale = true;
        current.price = _price;
        apes[_idx] = current;
    }

    function withdrawFromSell(uint256 _idx) public {
        Ape memory current = apes[_idx];
        address blockChainOwner = ownerOf(current.id);
        require(msg.sender == blockChainOwner, "not owner");
        require(current.onSale == true, "not on sale");

        current.onSale = false;
        current.price = 0;
        apes[_idx] = current;
    }

    function buy(uint256 _tokenId) public {
        IAGold aGold = IAGold(wAGoldAddr);
        address buyerAddr = address(msg.sender);
        address apesAddr = address(this);
        uint256 buyerBalance = aGold.balanceOf(buyerAddr);
        uint256 allowance = aGold.allowance(buyerAddr, apesAddr);
        uint256 _idx = _tokenId - 1;
        Ape memory current = apes[_idx];
        uint256 price = current.price;
        require(current.onSale == true, "not on sale");
        require(buyerBalance >= price, "not enough balance");
        require(allowance >= price, "not enough allowance");
        address initialOwner = ownerOf(_tokenId);

        // remove it from sales list
        current.onSale = false;
        current.price = 0;
        apes[_idx] = current;

        _transfer(initialOwner, buyerAddr, _tokenId);

        aGold.transferFrom(buyerAddr, initialOwner, price);
    }

    function migrate(uint256 _tokenId) public {}

    function setTypeOfApeById(uint256 id, uint256 typeId) public onlyOwner {
        typeOfApeById[id] = typeId;
    }

    function getTypeIdByNftId(uint256 tokenId) public view returns (uint256) {
        uint256 idx = tokenId - 1;
        Ape memory current = apes[idx];

        return uint256(current.level);
    }

    function setApeUriByNftId(uint256 nftID, string memory jsonURL)
        public
        onlyOwner
    {
        _setTokenURI(nftID - 1, jsonURL);
    }

    function setApesLandAddress(address add) public onlyOwner {
        apesLandAddr = add;
    }
    function setFarmLandAddress(address add) public onlyOwner {
        farmLandAddress = add;
    }
    function setLevel(uint256 nftID, uint256 lvl) public {
        require(
                address(msg.sender) == this.owner() ||
                msg.sender == apesLandAddr ||
                msg.sender == farmLandAddress,
            "Owner required"
        );
        apes[nftID - 1].level = Level(lvl);
        typeOfApeById[nftID] = lvl;
    }

    function getLevel(uint256 nftID) public view returns (uint256) {
        return uint256(apes[nftID - 1].level);
    }

    function setDeltaStack(uint256 nftID, uint256 delta) public {
        require(
                    address(msg.sender) == this.owner() ||
                    msg.sender == apesLandAddr ||
                    msg.sender == farmLandAddress,
            "Owner required"
        );
        deltaStack[nftID] = delta;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal initializer {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract IOldApe {
    function monkeys(uint256 idx)
        external
        virtual
        returns (
            uint256,
            uint256,
            uint8,
            uint256,
            string memory,
            uint256,
            bool,
            uint256,
            address
        );

    function tokenIdToName(uint256 id) external virtual returns (string memory);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual;

    function tokenURI(uint256 tokenId) external virtual returns (string memory);

    function ownerOf(uint256 tokenId) external virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
interface IApesLandV2 {
  function GnosisSafeVault (  ) external view returns ( address );
  function NftIDClaimed ( uint256 ) external view returns ( uint256 );
  function aGoldAddress (  ) external view returns ( address );
  function addressToApesType ( address, uint256, uint256 ) external view returns ( uint256 );
  function addressToBuildingsType ( address, uint256, uint256 ) external view returns ( uint256 );
  function adminUnStackApe ( uint256 genericType, address owner ) external;
  function apeContract (  ) external view returns ( address );
  function apeStartFarmingTimestamp ( uint256 ) external view returns ( uint256 );
  function apeTypeBaseRewards ( uint256 ) external view returns ( uint256 );
  function apesAtAddress ( uint256 ) external view returns ( address );
  function balanceOf ( address account, uint256 id ) external view returns ( uint256 );
  function balanceOfBatch ( address[] memory accounts, uint256[] memory ids ) external view returns ( uint256[] memory );
  function buildingTypeBaseRewards ( uint256 ) external view returns ( uint256 );
  function buildingsContract (  ) external view returns ( address );
  function calculateSpecialRewards ( uint256 apeNftID ) external view returns ( uint256 );
  function claimRewards ( uint256 genericType ) external;
  function claimSpecialRewards ( uint256 apeNftID ) external returns ( uint256 );
  function createEnemy ( uint256 typeNum, uint256 bait, uint256 reward, uint256 winningProv ) external;
  function currentFarmAccumulatorByApe ( uint256 apeId ) external view returns ( uint256 );
  function enemies_ ( uint256 ) external view returns ( uint256 typeNum, uint256 bait, uint256 reward, uint256 winningProb );
  function fightAgainst ( uint256 apeNftID, uint256 enemy ) external returns ( bool );
  function getStackedApesIdsByType ( address owner, uint256 genericType ) external view returns ( uint256[] memory );
  function getStackedBuildingsIdsByType ( address owner, uint256 genericType ) external view returns ( uint256[] memory );
  function initialize (  ) external;
  function isApprovedForAll ( address account, address operator ) external view returns ( bool );
  function landEnabled_ (  ) external view returns ( bool );
  function mint ( address account, uint256 id, uint256 amount, bytes memory data ) external;
  function mintBatch ( address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) external;
  function owner (  ) external view returns ( address );
  function pause (  ) external;
  function paused (  ) external view returns ( bool );
  function renounceOwnership (  ) external;
  function rewardFactor (  ) external view returns ( uint256 );
  function safeBatchTransferFrom ( address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory  data ) external;
  function safeTransferFrom ( address from, address to, uint256 id, uint256 amount, bytes memory  data ) external;
  function setAGoldAddr ( address val ) external;
  function setApeContract ( address val ) external;
  function setApesBaseRewards ( uint256 normalReward, uint256 farmerReward, uint256 warriorReward ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setBuildingsBaseRewards ( uint256 houseReward, uint256 farmReward, uint256 barrackReward ) external;
  function setBuildingsContract ( address val ) external;
  function setGnosisSafeVault ( address val ) external;
  function setLandEnabled ( bool val ) external;
  function setSpecialBlock ( uint256 blockNumber ) external;
  function setSpecialReward ( uint256 startBlockTime, uint256 endBlockTime, uint256 rewFactor ) external;
  function setURI ( string memory newuri ) external;
  function setupTest (  ) external;
  function specialBlock (  ) external view returns ( uint256 );
  function specialEndBlockTime (  ) external view returns ( uint256 );
  function specialStartBlockTime (  ) external view returns ( uint256 );
  function stackApe ( uint256 apeNftId ) external;
  function stackBuilding ( uint256 buildingNftID ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function totalFightsByNftId ( uint256 ) external view returns ( uint256 );
  function transferOwnership ( address newOwner ) external;
  function unStackApes ( uint256 genericType ) external;
  function unStackBuilding ( uint256 genericType ) external;
  function unpause (  ) external;
  function upgradeTo ( address newImplementation ) external;
  function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
  function uri ( uint256 ) external view returns ( string memory );
  function winsByNftId ( uint256 ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";

contract AWood is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    struct FeePair {
        uint256 fee;
        address receiver;
    }

    bool public saleEnabled_;
    uint256 public price;
    address public collateral;

    mapping(uint256 => FeePair) public feeMap;

    function initialize() public initializer {
        __ERC20_init("AoE-Wood", "aWood");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        setup();
    }

    function setup() public onlyOwner {
        saleEnabled_ = false;
        price = 2;
        //AGold
        collateral = address(0x5B5214c6110a2B538C2541998b243ec1CC517E24);
        _mint(msg.sender, 1 * 10**decimals());

        //1-Play2Earn
        feeMap[1].receiver = 0x67B5194D5e11a451BD3690C0D60dCBB0eA8D7F74;
        feeMap[1].fee = 50;
        //2-Liquidity
        feeMap[2].receiver = 0x7c528612f1E49A653552450c532a6Ef428a7278c;
        feeMap[2].fee = 47;
        //3-Developers
        feeMap[3].receiver = 0x7dF4a3cEaB37A5c0Fbc82DA090D76E1Cc88Ddd34;
        feeMap[3].fee = 0;
        //4-Marketing
        feeMap[4].receiver = 0x90aaa026541A9d78D67077362996F1BAF2eef29B;
        feeMap[4].fee = 0;
        //5-GameEcosys
        feeMap[5].receiver = 0x7dF4a3cEaB37A5c0Fbc82DA090D76E1Cc88Ddd34;
        feeMap[5].fee = 1;
        //6-Burn
        feeMap[6].receiver = address(0xdEaD);
        feeMap[6].fee = 1;
    }

    function getImplementation() public virtual returns (address) {
        return super._getImplementation();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    //New

    function saleEnabled(bool status) public onlyOwner {
        saleEnabled_ = status;
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setCollateral(address collateralAddress) public onlyOwner {
        collateral = collateralAddress;
    }

    function getCollateral() public view returns (address) {
        return collateral;
    }

    function setPlay2Earn(address addr, uint256 fee) public onlyOwner {
        feeMap[1].receiver = addr;
        feeMap[1].fee = fee;
    }

    function getPlay2Earn() public view virtual returns (address, uint256) {
        return (feeMap[1].receiver, feeMap[1].fee);
    }

    function setLiquidityFee(address addr, uint256 fee) public onlyOwner {
        feeMap[2].receiver = addr;
        feeMap[2].fee = fee;
    }

    function setMarketingFee(address addr, uint256 fee) public onlyOwner {
        feeMap[4].receiver = addr;
        feeMap[4].fee = fee;
    }

    function setDevelopersFee(address addr, uint256 fee) public onlyOwner {
        feeMap[3].receiver = addr;
        feeMap[3].fee = fee;
    }

    function setGameEcosysFee(address addr, uint256 fee) public onlyOwner {
        feeMap[5].receiver = addr;
        feeMap[5].fee = fee;
    }

    function setBurnFee(address addr, uint256 fee) public onlyOwner {
        feeMap[6].receiver = addr;
        feeMap[6].fee = fee;
    }

    function Buy(address buyer, uint256 amount) public {
        uint256 totalBuy = amount.mul(price);
        IERC20 collateralToken = IERC20(collateral);
        uint256 senderBalance = collateralToken.balanceOf(buyer);
        uint256 allowance = collateralToken.allowance(buyer, address(this));

        require(saleEnabled_, "Sales disabled");
        require(senderBalance >= totalBuy, "Insuficient collateral");
        require(allowance >= totalBuy, "Insuficient collateral allowance");

        collateralToken.transferFrom(
            buyer,
            feeMap[1].receiver,
            (totalBuy.mul(feeMap[1].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[2].receiver,
            (totalBuy.mul(feeMap[2].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[3].receiver,
            (totalBuy.mul(feeMap[3].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[4].receiver,
            (totalBuy.mul(feeMap[4].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[5].receiver,
            (totalBuy.mul(feeMap[5].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[6].receiver,
            (totalBuy.mul(feeMap[6].fee)).div(100)
        );

        _mint(buyer, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract IERC20 {
    function approve(address spender, uint256 amount)
        external
        virtual
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    function allowance(address owner, address spender)
        external
        view
        virtual
        returns (uint256);

    function balanceOf(address account) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";

contract AStraw is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    struct FeePair {
        uint256 fee;
        address receiver;
    }

    bool public saleEnabled_;
    uint256 public price;
    address public collateral;

    mapping(uint256 => FeePair) public feeMap;

    function initialize() public initializer {
        __ERC20_init("AoE-Straw", "aStraw");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        setup();
    }

    function setup() public onlyOwner {
        saleEnabled_ = false;
        price = 1;
        //AGold
        collateral = address(0x5B5214c6110a2B538C2541998b243ec1CC517E24);
        _mint(msg.sender, 1 * 10**decimals());

        //1-Play2Earn
        feeMap[1].receiver = 0x67B5194D5e11a451BD3690C0D60dCBB0eA8D7F74;
        feeMap[1].fee = 50;
        //2-Liquidity
        feeMap[2].receiver = 0x7c528612f1E49A653552450c532a6Ef428a7278c;
        feeMap[2].fee = 47;
        //3-Developers
        feeMap[3].receiver = 0x7dF4a3cEaB37A5c0Fbc82DA090D76E1Cc88Ddd34;
        feeMap[3].fee = 0;
        //4-Marketing
        feeMap[4].receiver = 0x90aaa026541A9d78D67077362996F1BAF2eef29B;
        feeMap[4].fee = 0;
        //5-GameEcosys
        feeMap[5].receiver = 0x7dF4a3cEaB37A5c0Fbc82DA090D76E1Cc88Ddd34;
        feeMap[5].fee = 1;
        //6-Burn
        feeMap[6].receiver = address(0xdEaD);
        feeMap[6].fee = 1;
    }

    function getImplementation() public virtual returns (address) {
        return super._getImplementation();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    //New

    function saleEnabled(bool status) public onlyOwner {
        saleEnabled_ = status;
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setCollateral(address collateralAddress) public onlyOwner {
        collateral = collateralAddress;
    }

    function getCollateral() public view returns (address) {
        return collateral;
    }

    function setPlay2Earn(address addr, uint256 fee) public onlyOwner {
        feeMap[1].receiver = addr;
        feeMap[1].fee = fee;
    }

    function getPlay2Earn() public view virtual returns (address, uint256) {
        return (feeMap[1].receiver, feeMap[1].fee);
    }

    function setLiquidityFee(address addr, uint256 fee) public onlyOwner {
        feeMap[2].receiver = addr;
        feeMap[2].fee = fee;
    }

    function setMarketingFee(address addr, uint256 fee) public onlyOwner {
        feeMap[4].receiver = addr;
        feeMap[4].fee = fee;
    }

    function setDevelopersFee(address addr, uint256 fee) public onlyOwner {
        feeMap[3].receiver = addr;
        feeMap[3].fee = fee;
    }

    function setGameEcosysFee(address addr, uint256 fee) public onlyOwner {
        feeMap[5].receiver = addr;
        feeMap[5].fee = fee;
    }

    function setBurnFee(address addr, uint256 fee) public onlyOwner {
        feeMap[6].receiver = addr;
        feeMap[6].fee = fee;
    }

    function Buy(address buyer, uint256 amount) public {
        uint256 totalBuy = amount.mul(price);
        IERC20 collateralToken = IERC20(collateral);
        uint256 senderBalance = collateralToken.balanceOf(buyer);
        uint256 allowance = collateralToken.allowance(buyer, address(this));

        require(saleEnabled_, "Sales disabled");
        require(senderBalance >= totalBuy, "Insuficient collateral");
        require(allowance >= totalBuy, "Insuficient collateral allowance");

        collateralToken.transferFrom(
            buyer,
            feeMap[1].receiver,
            (totalBuy.mul(feeMap[1].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[2].receiver,
            (totalBuy.mul(feeMap[2].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[3].receiver,
            (totalBuy.mul(feeMap[3].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[4].receiver,
            (totalBuy.mul(feeMap[4].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[5].receiver,
            (totalBuy.mul(feeMap[5].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[6].receiver,
            (totalBuy.mul(feeMap[6].fee)).div(100)
        );

        _mint(buyer, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";

contract AStone is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    struct FeePair {
        uint256 fee;
        address receiver;
    }

    bool public saleEnabled_;
    uint256 public price;
    address public collateral;

    mapping(uint256 => FeePair) public feeMap;

    function initialize() public initializer {
        __ERC20_init("AoE-Stone", "aStone");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        setup();
    }
    function setup() public onlyOwner {
        saleEnabled_ = false;
        price = 3;
        //AGold
        collateral = address(0x5B5214c6110a2B538C2541998b243ec1CC517E24);
        _mint(msg.sender, 1 * 10**decimals());

        //1-Play2Earn
        feeMap[1].receiver = 0x67B5194D5e11a451BD3690C0D60dCBB0eA8D7F74;
        feeMap[1].fee = 50;
        //2-Liquidity
        feeMap[2].receiver = 0x7c528612f1E49A653552450c532a6Ef428a7278c;
        feeMap[2].fee = 47;
        //3-Developers
        feeMap[3].receiver = 0x7dF4a3cEaB37A5c0Fbc82DA090D76E1Cc88Ddd34;
        feeMap[3].fee = 0;
        //4-Marketing
        feeMap[4].receiver = 0x90aaa026541A9d78D67077362996F1BAF2eef29B;
        feeMap[4].fee = 0;
        //5-GameEcosys
        feeMap[5].receiver = 0x7dF4a3cEaB37A5c0Fbc82DA090D76E1Cc88Ddd34;
        feeMap[5].fee = 1;
        //6-Burn
        feeMap[6].receiver = address(0xdEaD);
        feeMap[6].fee = 1;
    }
    function getImplementation() public virtual returns (address) {
        return super._getImplementation();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    //New

    function saleEnabled(bool status) public onlyOwner {
        saleEnabled_ = status;
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setCollateral(address collateralAddress) public onlyOwner {
        collateral = collateralAddress;
    }

    function getCollateral() public view returns (address) {
        return collateral;
    }

    function setPlay2Earn(address addr, uint256 fee) public onlyOwner {
        feeMap[1].receiver = addr;
        feeMap[1].fee = fee;
    }

    function getPlay2Earn() public view virtual returns (address, uint256) {
        return (feeMap[1].receiver, feeMap[1].fee);
    }

    function setLiquidityFee(address addr, uint256 fee) public onlyOwner {
        feeMap[2].receiver = addr;
        feeMap[2].fee = fee;
    }

    function setMarketingFee(address addr, uint256 fee) public onlyOwner {
        feeMap[4].receiver = addr;
        feeMap[4].fee = fee;
    }

    function setDevelopersFee(address addr, uint256 fee) public onlyOwner {
        feeMap[3].receiver = addr;
        feeMap[3].fee = fee;
    }

    function setGameEcosysFee(address addr, uint256 fee) public onlyOwner {
        feeMap[5].receiver = addr;
        feeMap[5].fee = fee;
    }

    function setBurnFee(address addr, uint256 fee) public onlyOwner {
        feeMap[6].receiver = addr;
        feeMap[6].fee = fee;
    }

    function Buy(address buyer, uint256 amount) public {
        uint256 totalBuy = amount.mul(price);
        IERC20 collateralToken = IERC20(collateral);
        uint256 senderBalance = collateralToken.balanceOf(buyer);
        uint256 allowance = collateralToken.allowance(buyer, address(this));

        require(saleEnabled_, "Sales disabled");
        require(senderBalance >= totalBuy, "Insuficient collateral");
        require(allowance >= totalBuy, "Insuficient collateral allowance");

        collateralToken.transferFrom(
            buyer,
            feeMap[1].receiver,
            (totalBuy.mul(feeMap[1].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[2].receiver,
            (totalBuy.mul(feeMap[2].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[3].receiver,
            (totalBuy.mul(feeMap[3].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[4].receiver,
            (totalBuy.mul(feeMap[4].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[5].receiver,
            (totalBuy.mul(feeMap[5].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[6].receiver,
            (totalBuy.mul(feeMap[6].fee)).div(100)
        );

        _mint(buyer, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";

contract ApeBuilding is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    struct FeePair {
        uint256 fee;
        address receiver;
    }

    mapping(uint256 => FeePair) public feeMap;

    struct BuildingProps {
        uint256 typeID;
        string buildingName;
        uint256 rewardRate;
        uint256 slots;
        address collateral;
        uint256 price;
        bool saleEnabled;
        string fullURI;
    }

    mapping(string => BuildingProps) public bProps;
    mapping(uint256 => string) public typeOfBuildingByNFTId;
    mapping(string => address) public collaterals;
    mapping(uint256 => uint256) public builtAtBlock;
    mapping(address => mapping(string => uint256)) public balancesbyTypeMap;
    bool public applyTaxes;
    event BuyBuilding(address buyer, address feeReceiver, uint256 price, uint256 nftId);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC721_init("AoE-Building", "aBuilding");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        setup();
    }

    function setup() public onlyOwner {
        applyTaxes = true;

        collaterals["wAoE"] = address(
            0x5B5214c6110a2B538C2541998b243ec1CC517E24
        );
        collaterals["aWood"] = address(
            0x879a439926591f89AE0a4AcdA2B099Bcb95c25AF
        );
        collaterals["aStone"] = address(
            0xf191cf06f18EA2E841f135cf2dCfc2612F1716F7
        );
        collaterals["aStraw"] = address(
            0x5D4Fc7EdD249Dd4C3a55d807954205e659Ff4394
        );

        //ApeHouse - Settings
        BuildingProps memory apeHouse;
        apeHouse.typeID = 1;
        apeHouse.buildingName = "ApeHouse";
        apeHouse.collateral = collaterals["aStraw"];
        apeHouse.price = 75;
        apeHouse.slots = 3;
        apeHouse.saleEnabled = false;
        apeHouse
            .fullURI = "https://storageapi.fleek.co/877cda1b-4b59-49b8-bdc3-d65ac313f1b6-bucket/NFTs/ApeHouse.json";
        bProps["ApeHouse"] = apeHouse;

        //ApeFarm - Settings
        BuildingProps memory apeFarm;
        apeFarm.typeID = 2;
        apeFarm.buildingName = "ApeFarm";
        apeFarm.collateral = collaterals["aWood"];
        apeFarm.price = 150;
        apeFarm.slots = 3;
        apeFarm.saleEnabled = false;
        apeFarm
            .fullURI = "https://storageapi.fleek.co/877cda1b-4b59-49b8-bdc3-d65ac313f1b6-bucket/NFTs/ApeFarm.json";
        bProps["ApeFarm"] = apeFarm;

        //ApeBarracks - Settings
        BuildingProps memory apeBarracks;
        apeBarracks.typeID = 3;
        apeBarracks.buildingName = "ApeBarracks";
        apeBarracks.collateral = collaterals["aStone"];
        apeBarracks.price = 300;
        apeBarracks.slots = 3;
        apeBarracks.saleEnabled = false;
        apeFarm
            .fullURI = "https://storageapi.fleek.co/877cda1b-4b59-49b8-bdc3-d65ac313f1b6-bucket/NFTs/ApeBarracks.json";
        bProps["ApeBarracks"] = apeBarracks;

        //1-Play2Earn
        feeMap[1].receiver = 0x67B5194D5e11a451BD3690C0D60dCBB0eA8D7F74;
        feeMap[1].fee = 50;
        //2-Liquidity
        feeMap[2].receiver = 0x7c528612f1E49A653552450c532a6Ef428a7278c;
        feeMap[2].fee = 47;
        //3-Developers
        feeMap[3].receiver = 0x7dF4a3cEaB37A5c0Fbc82DA090D76E1Cc88Ddd34;
        feeMap[3].fee = 0;
        //4-Marketing
        feeMap[4].receiver = 0x90aaa026541A9d78D67077362996F1BAF2eef29B;
        feeMap[4].fee = 0;
        //5-GameEcosys
        feeMap[5].receiver = 0x67B5194D5e11a451BD3690C0D60dCBB0eA8D7F74;
        feeMap[5].fee = 1;
        //6-Burn
        feeMap[6].receiver = address(0xdEaD);
        feeMap[6].fee = 1;

    }

    function setBuildingProps(
        uint256 typeID,
        string memory buildingName,
        uint256 rewardRate,
        uint256 slots,
        address collateral,
        uint256 price,
        bool isOnSale,
        string memory fullURI
    ) public onlyOwner {
        BuildingProps memory building;
        building.typeID = typeID;
        building.rewardRate = rewardRate;
        building.buildingName = buildingName;
        building.collateral = collateral;
        building.price = price;
        building.slots = slots;
        building.saleEnabled = isOnSale;
        building.fullURI = fullURI;
        bProps[buildingName] = building;
    }

    function transferFrom(address from,address to,uint256 tokenId) public override (ERC721Upgradeable) {
        balancesbyTypeMap[from][typeOfBuildingByNFTId[tokenId]] -= 1;
        balancesbyTypeMap[to][typeOfBuildingByNFTId[tokenId]] += 1;
        super.transferFrom(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // function Mint(address to, string memory buildingName) internal {
    //     uint256 currentNFTId = _tokenIdCounter.current();
    //     balancesbyTypeMap[to][buildingName]++;
    //     builtAtBlock[currentNFTId] = block.number;
    //     typeOfBuildingByNFTId[currentNFTId] = buildingName;
    //     _setTokenURI(currentNFTId, bProps[buildingName].fullURI);
    //     _mint(to, currentNFTId);
    //     _tokenIdCounter.increment();
    // }

    function setBuiltBlock(uint256 blockNumber, uint256 buildingID)
        public
        onlyOwner
    {
        builtAtBlock[buildingID] = blockNumber;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //Our methods
    function saleEnabled(string memory buildingName, bool status)
        public
        onlyOwner
    {
        bProps[buildingName].saleEnabled = status;
    }

    function setPrice(string memory buildingName, uint256 price_)
        public
        onlyOwner
    {
        bProps[buildingName].price = price_;
    }

    function setCollateral(
        string memory buildingName,
        address collateralAddress
    ) public onlyOwner {
        bProps[buildingName].collateral = collateralAddress;
    }

    function setPlay2Earn(address addr, uint256 fee) public onlyOwner {
        feeMap[1].receiver = addr;
        feeMap[1].fee = fee;
    }

    function getPlay2Earn() public view virtual returns (address, uint256) {
        return (feeMap[1].receiver, feeMap[1].fee);
    }

    function setLiquidityFee(address addr, uint256 fee) public onlyOwner {
        feeMap[2].receiver = addr;
        feeMap[2].fee = fee;
    }

    function setMarketingFee(address addr, uint256 fee) public onlyOwner {
        feeMap[4].receiver = addr;
        feeMap[4].fee = fee;
    }

    function setDevelopersFee(address addr, uint256 fee) public onlyOwner {
        feeMap[3].receiver = addr;
        feeMap[3].fee = fee;
    }

    function setGameEcosysFee(address addr, uint256 fee) public onlyOwner {
        feeMap[5].receiver = addr;
        feeMap[5].fee = fee;
    }

    function setBurnFee(address addr, uint256 fee) public onlyOwner {
        feeMap[6].receiver = addr;
        feeMap[6].fee = fee;
    }

    function balanceOf(string memory buildingTypeName, address own)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            own != address(0),
            "ERC721: balance query for the zero address"
        );
        uint256 value = balancesbyTypeMap[own][buildingTypeName];
        return value;
    }
    function getTypeIDByNftID(uint256 nftID) public view returns (uint256 typeID) {
        return bProps[typeOfBuildingByNFTId[nftID]].typeID;
    }
    function Buy(string memory buildingName) public {
        address buyer = address(msg.sender);
        uint256 price = bProps[buildingName].price;
        IERC20 collateralToken = IERC20(bProps[buildingName].collateral);
        uint256 senderBalance = collateralToken.balanceOf(buyer);
        uint256 allowance = collateralToken.allowance(buyer, address(this));

        require(bProps[buildingName].saleEnabled, "Sales of are disabled");
        require(senderBalance >= price, "Insuficient collateral");
        require(allowance >= price, "Insuficient collateral allowance");
        
        collateralToken.transferFrom(buyer, feeMap[1].receiver, price); 
        //Mint
        uint256 currentNFTId = _tokenIdCounter.current();
        balancesbyTypeMap[buyer][buildingName]++;
        builtAtBlock[currentNFTId] = block.number;
        typeOfBuildingByNFTId[currentNFTId] = buildingName;
        _mint(buyer, currentNFTId);
        _setTokenURI(currentNFTId, bProps[buildingName].fullURI);
        emit BuyBuilding(buyer, feeMap[1].receiver, price, _tokenIdCounter.current());
        _tokenIdCounter.increment();

    // if(applyTaxes){
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[1].receiver,
    //         (price.mul(feeMap[1].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[2].receiver,
    //         (price.mul(feeMap[2].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[3].receiver,
    //         (price.mul(feeMap[3].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[4].receiver,
    //         (price.mul(feeMap[4].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[5].receiver,
    //         (price.mul(feeMap[5].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[6].receiver,
    //         (price.mul(feeMap[6].fee)).div(100)
    //     );
    //     Mint(buyer, buildingName);
    // }
    // else
    // {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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