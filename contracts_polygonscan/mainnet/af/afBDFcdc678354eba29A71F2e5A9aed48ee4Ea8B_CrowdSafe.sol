/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

// SPDX-License-Identifier: MIT
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : [email protected]
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /home/dev4/Hobbies/CrowdSecurity/contracts/CrowdSafe.sol
// flattened :  Friday, 05-Nov-21 04:11:35 UTC
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

contract ERC20Upgradeable is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable
{
    //Upon initalizing the contract, ban the founder from minting tokens
    mapping(address => bool) public founderMintBan;

    /**
     * `modifier founderBanned()` bans the founder from minting new tokens however they
     * deem fit. It is important that a contract that inspires to wipe out dubious contracts
     * is in-and of itself a reliable contract. In this effort, founderBanned mofifier limits
     * the founder's capability. the ERC20Upgradeable.sol requires that any newly minted tokens
     * are not by the founders, but rather by the intended end-users through the intended mechanisms.
     *
     * This technique will protect "Crowd Safe" from the dreaded rug-pull.
     */
    modifier founderBanned() {
        require(
            !founderMintBan[msg.sender],
            "You are a founder and therefore you are banned from functions that result in minting new tokens"
        );
        _;
    }

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
    function __ERC20_init(string memory name_, string memory symbol_)
        internal
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_)
        internal
        initializer
    {
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
        return 0;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
    function _mint(address account, uint256 amount)
        internal
        virtual
        founderBanned
    {
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

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    uint256[49] private __gap;
}

contract CrowdSafe is ERC20Upgradeable, OwnableUpgradeable {
    uint256 public minimumCompensation;
    uint256 public version;
    uint256 private _amountBan;
    uint256 private _reporterCountBan;

    //Scam Variables
    uint256 public highestScamThreatLevel;
    uint256 public highestScamThreatAwareness;
    address public highestScamThreatAddress;
    address[] public reportedScams;
    address[] public scamReporters;

    mapping(address => bool) public scamReporterSet;
    mapping(address => mapping(address => uint256))
        public userContractScamLevel;
    mapping(address => uint256) public scamThreatLevel;
    mapping(address => uint256) public scamThreatAwareness;

    //Safe Variables
    uint256 public highestSafetyLevel;
    uint256 public highestSafetyAwareness;
    address public highestSafetyAddress;
    address[] public reportedSafe;
    address[] public safeReporters;

    mapping(address => bool) public safeReporterSet;
    mapping(address => mapping(address => uint256))
        public userContractSafeLevel;
    mapping(address => uint256) public safeLevel;
    mapping(address => uint256) public safeAwareness;

    function __CrowdSafe_init(uint256 _version) public initializer {
        __Ownable_init();
        __ERC20_init("Crowd Safe", "VERIFIED");

        minimumCompensation = 21000_0_00000000 wei;
        _amountBan = 500000;
        _reporterCountBan = 100;

        version = _version;

        if (!founderMintBan[_msgSender()]) {
            /**
             * Upon constuction of Crowd Safe contract.
             * The only means of collecting VERIFIED tokens is by reporting safe
             * or scam contracts
             */
            uint256 founderReserve = 48690474535 wei; // Matic Value
            // uint256 founderReserve = 23809523; // Ethereum Value
            _mint(msg.sender, founderReserve);

            reportedSafe.push(msg.sender);
            safeReporters.push(msg.sender);
            safeReporterSet[msg.sender] = true;
            userContractSafeLevel[msg.sender][address(this)] = founderReserve;
            safeLevel[address(this)] = founderReserve;
            safeAwareness[address(this)] = 1;
            founderMintBan[msg.sender] = true;
        }
    }

    function ReportScam(address fraudContract)
        public
        payable
        founderBanned
        banSpamBot
    {
        require(fraudContract != address(0));
        require(fraudContract != msg.sender);

        uint256 confidence = (msg.value + minimumCompensation) /
            minimumCompensation;
        _mint(msg.sender, confidence);
        if (!scamReporterSet[msg.sender]) {
            scamReporterSet[msg.sender] = true;
            scamReporters.push(msg.sender);
        }
        if (userContractScamLevel[msg.sender][fraudContract] == 0) {
            if (scamThreatLevel[fraudContract] == 0) {
                reportedScams.push(fraudContract);
            }
            scamThreatAwareness[fraudContract]++;
        }
        scamThreatLevel[fraudContract] += confidence;
        userContractScamLevel[msg.sender][fraudContract] = confidence;
        _ifMaxThreat(fraudContract);
    }

    function ReportSafe(address verifiedContract)
        public
        payable
        founderBanned
        banSpamBot
    {
        require(verifiedContract != address(0));
        require(verifiedContract != msg.sender);

        uint256 confidence = (msg.value + minimumCompensation) /
            minimumCompensation;
        _mint(msg.sender, confidence);
        if (!safeReporterSet[msg.sender]) {
            safeReporterSet[msg.sender] = true;
            safeReporters.push(msg.sender);
        }
        if (userContractSafeLevel[msg.sender][verifiedContract] == 0) {
            if (safeLevel[verifiedContract] == 0) {
                reportedSafe.push(verifiedContract);
            }
            safeAwareness[verifiedContract]++;
        }
        safeLevel[verifiedContract] += confidence;
        userContractSafeLevel[msg.sender][verifiedContract] = confidence;
        _ifMaxSafety(verifiedContract);
    }

    function getReportedScamsLength() public view returns (uint256) {
        return reportedScams.length;
    }

    function getScamReportersLength() public view returns (uint256) {
        return scamReporters.length;
    }

    function getReportedSafeLength() public view returns (uint256) {
        return reportedSafe.length;
    }

    function getSafeReportersLength() public view returns (uint256) {
        return safeReporters.length;
    }

    function _ifMaxThreat(address fraudContract) internal {
        if (scamThreatLevel[fraudContract] > highestScamThreatLevel) {
            highestScamThreatAwareness = scamThreatAwareness[fraudContract];
            highestScamThreatLevel = scamThreatLevel[fraudContract];
            highestScamThreatAddress = fraudContract;
        }
    }

    function _ifMaxSafety(address verifiedContract) internal {
        if (safeLevel[verifiedContract] > highestSafetyLevel) {
            highestSafetyAwareness = safeAwareness[verifiedContract];
            highestSafetyLevel = safeLevel[verifiedContract];
            highestSafetyAddress = verifiedContract;
        }
    }

    function _setMinimumCompensation(uint256 _minimumCompensation) public {
        minimumCompensation = _minimumCompensation;
    }

    function _setAmountBan(uint256 amountBan) public {
        _amountBan = amountBan;
    }

    function _setReporterCountBan(uint256 reporterCountBan) public {
        _reporterCountBan = reporterCountBan;
    }

    modifier banSpamBot() {
        require(
            scamThreatLevel[msg.sender] < _amountBan && //Matic Value
                // scamThreatLevel[msg.sender] < 10 && //Eth Value
                scamThreatAwareness[msg.sender] < _reporterCountBan,
            // scamThreatAwareness[msg.sender] < 5,
            "People's choice has banned this wallet from voting"
        );
        _;
    }

    /**
     * `modifier founderBanned()` bans the founder from minting new tokens however they
     * deem fit. It is important that a contract that inspires to wipe out dubious contracts
     * is in-and of itself a reliable contract. In this effort, founderBanned mofifier limits
     * the founder's capability. the ERC20Upgradeable.sol requires that any newly minted tokens
     * are not by the founders, but rather by the intended end-users through the intended mechanisms.
     *
     * This technique will protect "Crowd Safe" from the dreaded rug-pull.
     */
}