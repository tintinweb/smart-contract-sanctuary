//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./common/BlackList.sol";

/**
 * @title Configurable
 * @dev Configurable varriables of the contract
 **/
contract Configurable {
    uint256 public constant cap = 1_000_000_000 * 10**18;
}

contract SIPToken is
    Initializable,
    ContextUpgradeable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    BlackList,
    Configurable
{
    uint256 private _feeCharged;
    uint256 private _dirtyFunds;
    address private _miningAddr;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Max transfer amount rate in basis points. Eg: 50 - 0.5% of total supply (default the anti whale feature is turned off - set to 10000.)
    uint16 public maxTransferAmountRate;

    // Addresses that excluded from transfer fee
    mapping(address => bool) private _excludedFromTransferFee;

    // events to track onchain-offchain relationships
    event __issue(bytes32 offchain);

    // called when hacker's balance is burnt
    event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);

    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;

    Tokenomic private tokenomic;

    struct Tokenomic {
        uint256 _birthday;
        mapping(address => uint256) _allocate;
        mapping(address => uint256) _lock;
        mapping(address => uint256) _firstUnlock;
        mapping(address => uint256) _unlockRate;
        mapping(address => bool) _isWeekly;
        mapping(address => uint256) _transferred;
    }

    function initialize(
        address strategicPartner,
        address privateSale,
        address preIdo,
        address ido,
        address team,
        address advisory,
        address marketing,
        address mining,
        address play2Earn,
        address reserve,
        address liquidity
    ) public initializer {
        __ERC20_init("Space SIP", "SIP");
        __Ownable_init();
        __Pausable_init();

        setTokenomic(
            strategicPartner,
            privateSale,
            preIdo,
            ido,
            team,
            advisory,
            marketing,
            mining,
            play2Earn,
            reserve,
            liquidity
        );
        maxTransferAmountRate = 10000; // 100%

        _mint(strategicPartner, tokenomic._allocate[strategicPartner]);
        _mint(privateSale, tokenomic._allocate[privateSale]);
        _mint(preIdo, tokenomic._allocate[preIdo]);
        _mint(ido, tokenomic._allocate[ido]);
        _mint(team, tokenomic._allocate[team]);
        _mint(advisory, tokenomic._allocate[advisory]);
        _mint(marketing, tokenomic._allocate[marketing]);
        _mint(mining, tokenomic._allocate[mining]);
        _mint(play2Earn, tokenomic._allocate[play2Earn]);
        _mint(reserve, tokenomic._allocate[reserve]);
        _mint(liquidity, tokenomic._allocate[liquidity]);

        _excludedFromAntiWhale[_msgSender()] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;

        excludedFromAntiWhale(
            strategicPartner,
            privateSale,
            preIdo,
            ido,
            team,
            advisory,
            marketing,
            mining,
            play2Earn,
            reserve,
            liquidity
        );

        excludeFromTransferFee(
            strategicPartner,
            privateSale,
            preIdo,
            ido,
            team,
            advisory,
            marketing,
            mining,
            play2Earn,
            reserve,
            liquidity
        );
    }

    function setTokenomic(
        address strategicPartner,
        address privateSale,
        address preIdo,
        address ido,
        address team,
        address advisory,
        address marketing,
        address mining,
        address play2Earn,
        address reserve,
        address liquidity
    ) private {
        tokenomic._birthday = block.timestamp;
        tokenomic._lock[strategicPartner] = tokenomic._birthday + 30 days * 6;
        tokenomic._lock[team] = tokenomic._birthday + 30 days * 12;
        tokenomic._lock[play2Earn] = tokenomic._birthday + 30 days * 1;
        tokenomic._lock[reserve] = tokenomic._birthday + 30 days * 1;
        tokenomic._lock[privateSale] = tokenomic._birthday;
        tokenomic._lock[preIdo] = tokenomic._birthday;
        tokenomic._lock[ido] = tokenomic._birthday;
        tokenomic._lock[advisory] = tokenomic._birthday;
        tokenomic._lock[marketing] = tokenomic._birthday;
        tokenomic._lock[liquidity] = tokenomic._birthday;
        tokenomic._lock[mining] = tokenomic._birthday;

        tokenomic._firstUnlock[privateSale] = 800;
        tokenomic._firstUnlock[preIdo] = 1800;
        tokenomic._firstUnlock[ido] = 3000;
        tokenomic._firstUnlock[advisory] = 833;
        tokenomic._firstUnlock[liquidity] = 1900;

        tokenomic._isWeekly[ido] = true;

        tokenomic._unlockRate[strategicPartner] = 833;
        tokenomic._unlockRate[privateSale] = 767;
        tokenomic._unlockRate[preIdo] = 1640;
        tokenomic._unlockRate[ido] = 1000;
        tokenomic._unlockRate[team] = 833;
        tokenomic._unlockRate[advisory] = 764;
        tokenomic._unlockRate[marketing] = 208;
        tokenomic._unlockRate[mining] = 167;
        tokenomic._unlockRate[play2Earn] = 169;
        tokenomic._unlockRate[reserve] = 169;
        tokenomic._unlockRate[liquidity] = 2025;

        tokenomic._allocate[strategicPartner] = 20_000_000 * 10**18;
        tokenomic._allocate[privateSale] = 100_000_000 * 10**18;
        tokenomic._allocate[preIdo] = 20_000_000 * 10**18;
        tokenomic._allocate[ido] = 10_000_000 * 10**18;
        tokenomic._allocate[team] = 150_000_000 * 10**18;
        tokenomic._allocate[advisory] = 10_000_000 * 10**18;
        tokenomic._allocate[marketing] = 60_000_000 * 10**18;
        tokenomic._allocate[mining] = 150_000_000 * 10**18;
        tokenomic._allocate[play2Earn] = 350_000_000 * 10**18;
        tokenomic._allocate[reserve] = 90_000_000 * 10**18;
        tokenomic._allocate[liquidity] = 40_000_000 * 10**18;
    }

    function excludedFromAntiWhale(
        address strategicPartner,
        address privateSale,
        address preIdo,
        address ido,
        address team,
        address advisory,
        address marketing,
        address mining,
        address play2Earn,
        address reserve,
        address liquidity
    ) private {
        _excludedFromAntiWhale[strategicPartner] = true;
        _excludedFromAntiWhale[privateSale] = true;
        _excludedFromAntiWhale[preIdo] = true;
        _excludedFromAntiWhale[ido] = true;
        _excludedFromAntiWhale[team] = true;
        _excludedFromAntiWhale[advisory] = true;
        _excludedFromAntiWhale[marketing] = true;
        _excludedFromAntiWhale[mining] = true;
        _excludedFromAntiWhale[play2Earn] = true;
        _excludedFromAntiWhale[reserve] = true;
        _excludedFromAntiWhale[liquidity] = true;
    }

    function excludeFromTransferFee(
        address strategicPartner,
        address privateSale,
        address preIdo,
        address ido,
        address team,
        address advisory,
        address marketing,
        address mining,
        address play2Earn,
        address reserve,
        address liquidity
    ) private {
        _excludedFromTransferFee[strategicPartner] = true;
        _excludedFromTransferFee[privateSale] = true;
        _excludedFromTransferFee[preIdo] = true;
        _excludedFromTransferFee[ido] = true;
        _excludedFromTransferFee[team] = true;
        _excludedFromTransferFee[advisory] = true;
        _excludedFromTransferFee[marketing] = true;
        _excludedFromTransferFee[mining] = true;
        _excludedFromTransferFee[play2Earn] = true;
        _excludedFromTransferFee[reserve] = true;
        _excludedFromTransferFee[liquidity] = true;
    }

    /**
     * @dev function to mint SIP token that was hacked by hacker and send it to reward pool
     */
    function issueBlackFunds(bytes32 offchain) external virtual onlyOwner {
        require(_dirtyFunds > 0, "SIP:EDF"); // empty dirty funds
        _mint(_miningAddr, _dirtyFunds);
        _dirtyFunds = 0;
        emit __issue(offchain);
    }

    /**
     * @dev function to burn SIP of hacker
     * @param _blackListedUser the account whose SIP will be burnt
     */
    function destroyBlackFunds(address _blackListedUser) external virtual onlyOwner {
        require(isBlackListed[_blackListedUser], "SIP:IB"); // in blacklist
        uint256 funds = balanceOf(_blackListedUser);
        _burn(_blackListedUser, funds);
        _dirtyFunds += funds;
        emit DestroyedBlackFunds(_blackListedUser, funds);
    }

    function mint(address _to) external virtual onlyOwner {
        require(totalSupply() + _feeCharged <= cap, "SIP:EC"); // exceed cap
        _mint(_to, _feeCharged);
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external virtual onlyOwner whenPaused {
        _unpause();
    }

    function transfer(address _to, uint256 _value) public virtual override whenNotPaused returns (bool) {
        require(!isBlackListed[_msgSender()]);
        _transfer(_msgSender(), _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual override whenNotPaused returns (bool) {
        require(!isBlackListed[_from]);

        uint256 currentAllowance = allowance(_from, _msgSender());
        require(currentAllowance >= _value, "ERC20:EA"); // exceed allowance
        unchecked {
            _approve(_from, _msgSender(), currentAllowance - _value);
        }

        _transfer(_from, _to, _value);
        return true;
    }

    /// @dev overrides transfer function to meet tokenomics of SIP
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override antiWhale(sender, recipient, amount) {
        require(amount > 0, "SIP:AO"); // amount is 0

        if (tokenomic._lock[sender] > 0) {
            require(block.timestamp > tokenomic._lock[sender], "SIP:TL"); // tokenomic locked
        }

        if (tokenomic._unlockRate[sender] > 0) {
            uint256 allow = (tokenomic._firstUnlock[sender] * tokenomic._allocate[sender]) / 10000;
            uint256 baseTime = tokenomic._lock[sender];
            uint256 period = 0;
            if (tokenomic._isWeekly[sender]) {
                period = (block.timestamp - baseTime) / 7 days;
            } else {
                period = (block.timestamp - baseTime) / 30 days;
            }
            if (period == 0) period = 1;
            allow += (tokenomic._allocate[sender] * period * tokenomic._unlockRate[sender]) / 10000;
            allow -= tokenomic._transferred[sender];
            require(amount <= allow, "SIP:OV"); // over vesting
            tokenomic._transferred[sender] += amount;
        }

        if (recipient == BURN_ADDRESS) {
            // Burn all the amount
            super._burn(sender, amount);
            _feeCharged += amount;
        } else if (_excludedFromTransferFee[sender] || _excludedFromTransferFee[recipient]) {
            // Transfer all the amount
            super._transfer(sender, recipient, amount);
        } else {
            // 1.8% of every transfer burnt
            uint256 burnAmount = (amount * 18) / 1000;
            // 98.2% of transfer sent to recipient
            uint256 sendAmount = amount - burnAmount;
            _feeCharged += burnAmount;
            super._burn(sender, burnAmount);
            super._transfer(sender, recipient, sendAmount);
        }
    }

    /**
     * @dev debug function to get the tokenomic information.
     */
    function getTokenomic(address addr)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        return (
            tokenomic._allocate[addr],
            tokenomic._lock[addr],
            tokenomic._firstUnlock[addr],
            tokenomic._unlockRate[addr],
            tokenomic._isWeekly[addr],
            tokenomic._transferred[addr]
        );
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOwner {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Returns the address is excluded from transfer fee or not.
     */
    function isExcludedFromTransferFee(address _account) public view returns (bool) {
        return _excludedFromTransferFee[_account];
    }

    /**
     * @dev Exclude or include an address from transfer fee.
     * Can only be called by the current operator.
     */
    function setExcludedFromTransferFee(address _account, bool _excluded) external onlyOwner {
        _excludedFromTransferFee[_account] = _excluded;
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return (totalSupply() * maxTransferAmountRate) / 10000;
    }

    /**
     * @dev Function to set maxTransferAmountRate
     */
    function setMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOwner {
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    function version() external pure virtual returns (uint16) {
        return 1;
    }

    /**
    Exludes sender to send more than a certain amount of tokens given settings, if the
    sender is not whitelisted!
     */
    modifier antiWhale(
        address sender,
        address recipient,
        uint256 amount
    ) {
        if (_excludedFromAntiWhale[sender] == false) {
            require(amount <= maxTransferAmount(), "SIP:EM"); // exceed maximum amount
        }
        _;
    }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BlackList is OwnableUpgradeable {
    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded SIP) ///////
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    mapping(address => bool) public isBlackListed;

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
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