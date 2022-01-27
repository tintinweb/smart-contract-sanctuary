/**
   $BLUSHO is unique community driven marketing platform for crypto projects. Crypto projects
   can create project wallets. Everybody can send $BLUSHO tokens to these wallets. The projects
   are ranked by their current token balance within the blusho ecosystem. Project wallets
   are taxed regularly and funds send to the burn wallet.

   Each trade (buy/sell) transaction incurs a developer fee to fund the development and marketing
   of the ecosystem. Wallet to Wallet transfers don't incur a fee. These are your tokens!

    Total Supply: 100.000.000 (100 Million / Constant)
    Buy/Sell Transaction Limit: 1% of Total Supply (Adjustable, min 1% of Circulating Supply)
    Developer Tax: 5% (Adjustable 0-10%)
    Project Tax: 10% (Constant)
    Project Tax Schedule: 1 Week (Min 1 Day, Max 30 Days)

   blusho.finance
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//import "./IERC20.sol";

/// @custom:security-contact [email protected]
contract BlushoToken is IERC20Metadata, Ownable {
    enum Env {
        test,
        development,
        testnet,
        mainnet
    }

    Env private _env;

    /** IERC20 attributes **/

    /**
     * @dev Balances mapping
     */
    mapping(address => uint256) private _balances;

    /**
     * @dev Allowances mapping
     */
    mapping(address => mapping(address => uint256)) private _allowances;

    /** IERC20 attributes end **/

    /** Token Metadata **/

    /**
     * @dev Token name
     */
    string internal _name = "blusho.finance";

    /**
     * @dev Token symbol
     */
    string internal constant SYMBOL = "BLUSHO";

    /**
     * @dev Set the decimals to 18 (Default)
     */
    uint8 internal constant DECIMALS = 18;

    /**
     * @dev Set the total supply when deploying the contract to
     * 100.000.000 (100 millon)
     */
    uint256 internal constant TOTAL_SUPPLY = 100 * 10**6 * 10**DECIMALS;

    /**
     * @dev The burn wallet address.
     * Nobody can get the private key to this wallet
     * Tokens sent to this address will reduce the circulating supply
     */
    address internal constant burnAddress =
        0x000000000000000000000000000000000000dEaD;

    /** Token Metadata End **/

    /** Presale Attributes **/

    /**
     * @dev Start in Presale
     */
    bool internal _isInPresale;

    /** Presale Attributes End */

    /** Tokenomics Attributes **/

    /**
     * @dev Maximum Trade Tax
     */
    uint256 internal constant MAX_DEVELOPER_TAX = 10;

    /**
     * @dev The percentage of each trade transaction that will be sent to
     * the developerWallet for Marketing and Development
     * The default value is 5%.
     *
     * NOTE: set the value to 0 to disable.
     * Can't be set higher than MAX_DEVELOPER_TAX
     */
    uint256 internal _taxDeveloper = 5;

    /**
     * @dev The wallet address that receives the taxDeveloper
     * The default value is the deployer wallet
     */
    address internal _taxDeveloperWallet;

    /**
     * @dev A mapping of DEX wallets that are subject to the tax
     * Transfers between regular wallets should not be taxed
     * Includes the Pancakeswap wallets by default
     *
     */
    mapping(address => bool) internal _exchangeWallets;

    address internal constant PCS_TESTNET_ADDRESS =
        0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address internal constant PCS_V1_ADDRESS =
        0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    address internal constant PCS_V2_ADDRESS =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;

    /** Tokenomics Attributes End **/

    /** Trading Rule Attributes **/

    /**
     * @dev Set the maximum transaction value allowed in a transfer.
     *
     * The default value is 1% of the total supply and it can't be set lower.
     * than 1% of the circulating supply (TOTAL_SUPPLY - BURN BALANCE)
     */
    uint256 internal _transactionLimit = TOTAL_SUPPLY / 100;

    uint256 internal constant MIN_TRANSACTION_LIMIT_FACTOR = 100;

    /**
     * @dev A mapping of Unlimited wallets that are not subject to the tax
     * and max transaction rules
     * Includes the Owner wallet by default
     *
     */
    mapping(address => bool) internal _unlimitedWallets;

    /**
     * @dev A mapping of Blacklisted wallets that are not allowed to transfer
     * any tokens
     *
     */
    mapping(address => bool) internal _blacklistedWallets;

    /** Trading Rule Attributes End **/

    /** Project Wallets Attributes
     * Project wallets are wallets that no one has the key to. Everyone can create a project wallet.
     * And everyone can send tokens to the wallet. The balance will be used in different frontends to
     * create a ranking mechanism for the linked projects. There is a regular tax to incentivize new projects.
     * The tax will be sent to the burn address. To save gas this is only done on token transfers to the
     * individual project wallets. In the meantime a balance of transferred tokens per projectTaxCycle
     * is kept to calculate the correct balance on the fly.
     **/

    struct ProjectWallet {
        bool exists;
        string name; //the project name
        uint256 lastTransferToBurnAddressProjectTaxCycle; //At each transfer to a project wallet
    }

    /**
     * @dev Mapping of Project Wallets to the project wallet.
     * Project wallets will be created in consecutive order starting with
     * address(1001)
     */
    mapping(address => ProjectWallet) internal _projectWallets;

    /**
     * @dev Mapping of Project Owners to the Project Wallets.
     */
    mapping(address => address) internal _projectWalletsOwners;

    /**
     * @dev Currently transfering taxes.
     */
    mapping(address => bool) internal _projectWalletsInTransfer;

    /**
     * @dev The current number of project wallets.
     * Starting with 8000 to create unique wallet addresses
     */
    uint256 internal constant PROJECT_WALLETS_INDEX_BASE = 1000;
    uint256 internal _projectWalletsIndex = PROJECT_WALLETS_INDEX_BASE;

    /**
     * @dev The percentage of each projects wallet, that will be sent to the burn
     * wallet each cycle
     */
    uint256 internal constant taxProjects = 10;

    /**
     * @dev Minimum and Maximum Project Schedule
     * The projects can't be taxed more than once a day and at least every 30 days
     */
    uint256 internal constant MIN_PROJECT_SCHEDULE = 60 * 60 * 24;
    uint256 internal constant MAX_PROJECT_SCHEDULE = 60 * 60 * 24 * 30;

    /**
     * @dev The time in seconds between each project taxation event
     * The default value is 1 week.
     */
    uint256 internal _taxProjectsSchedule = 60 * 60 * 24 * 7; //Seconds between project taxation

    /**
     * @dev The timestamp of the last project taxation event
     * The default value is the contract deployment timestamp.
     */
    uint256 internal _lastProjectsTaxTimestamp;

    /**
     * @dev The current project tax cycle
     */
    uint256 internal _projectsTaxCycle = 0;

    /**
     * @dev Track the total balance of all project wallets
     */
    uint256 internal _totalProjectWalletsBalance = 0;

    /**
     * @dev Balance of unburned tokens
     * Increment with each tax cycle
     * Deduct any tokens actually sent to the burn address
     */
    uint256 internal _pendingProjectTaxesToBeBurned;

    /** Project Wallets Attributes End **/

    /**
     * @dev Custom events
     */
    event Burn(address indexed from, uint256 value);
    event ProjectWalletCreate(address projectWalletAddress, string projectName);
    event ProjectTaxCycle(uint256 taxCycle);
    event ProjectTaxTransfer(address indexed from, uint256 value);

    /**
     * @dev Token constructor
     * Mint the totalSupply
     * Add contract and deployer to _unlimitedWallets
     * Set developer wallet to deployer wallet
     * Set initial last projects tax timestamp
     */
    constructor(Env env) {
        _env = env;

        //Add all tokens to the deployer wallet
        _balances[_msgSender()] += TOTAL_SUPPLY;

        //Set the developer Wallet to the contract owner
        _taxDeveloperWallet = _msgSender();

        // Add pancakeswap exchange addresses
        if (env == Env.mainnet) {
            _exchangeWallets[PCS_V2_ADDRESS] = true; //V2
            _exchangeWallets[PCS_V1_ADDRESS] = true; //V1
        } else {
            _exchangeWallets[PCS_TESTNET_ADDRESS] = true; //Testnet
        }

        // Add owner address to unlimited wallets
        _unlimitedWallets[_msgSender()] = true; //Owner

        //Set initial timestamp as last project tax to prevent immediate taxation
        _lastProjectsTaxTimestamp = block.timestamp;

        //Start in Presale Mode
        if (env == Env.mainnet || env == Env.testnet) {
            _isInPresale = true;
        }

        emit Transfer(address(0), _msgSender(), TOTAL_SUPPLY);
    }

    /** IERC20 methods **/

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
        return SYMBOL;
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
        return DECIMALS;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return TOTAL_SUPPLY;
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
        return _balanceOf(account);
    }

    function _balanceOf(address account)
        internal
        view
        virtual
        returns (uint256)
    {
        //The balance of the burn address needs to be adjusted by the due tokens in project wallets which have not been burned yet
        if (account == burnAddress) {
            return _balanceOfBurnAddress();
        }

        //The balance of a project wallets needs to be adjusted by the due tokens which have not been burned yet
        if (_isProjectWallet(account)) {
            return _balanceOfProjectWallet(account);
        }

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
        require(sender != burnAddress, "ERC20: transfer from the burn address");
        require(
            !_isProjectWallet(sender),
            "ERC20: transfer from a project wallet"
        );
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            !_isBlacklistedWallet(sender),
            "BlushoToken: transfer from blacklisted wallet"
        );
        require(
            !_isBlacklistedWallet(recipient),
            "BlushoToken: transfer to blacklisted wallet"
        );

        uint256 sentAmount = amount;
        uint256 receivedAmount = amount;
        uint256 developerTaxAmount = 0;
        if (
            _isInPresale ||
            _isUnlimitedWallet(sender) ||
            _isUnlimitedWallet(recipient)
        ) {
            //do nothing if one of the participants is an unlimited address
        }
        //if it is an exchange transaction
        else if (_isExchangeWallet(sender) || _isExchangeWallet(recipient)) {
            developerTaxAmount = (sentAmount * _taxDeveloper) / 100;
            receivedAmount = sentAmount - developerTaxAmount;
            if (receivedAmount > _transactionLimit) {
                revert("Transfer amount exceeds the maxTxAmount.");
            }
        }
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= sentAmount,
            "ERC20: transfer amount exceeds balance"
        );

        if (_isProjectWallet(recipient)) {
            //Transfer outstanding project wallet tokens to burn wallet
            _transferOutstandingProjectTax(recipient);
            //Adjust totalProjectsWalletBalance
            _totalProjectWalletsBalance += receivedAmount;
        }

        unchecked {
            _balances[sender] = senderBalance - sentAmount;
        }
        _balances[recipient] += receivedAmount;

        emit Transfer(sender, recipient, sentAmount);
        if (developerTaxAmount > 0) {
            _balances[_taxDeveloperWallet] += developerTaxAmount;
            emit Transfer(sender, _taxDeveloperWallet, developerTaxAmount);
        } else if (recipient == burnAddress) {
            emit Burn(sender, sentAmount);
        }

        //Trigger project wallet tax if due and in mainnet
        if (_env == Env.mainnet && _shouldTriggerProjectWalletTax()) {
            _triggerProjectWalletTax();
        }
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

    /** IERC20 methods End **/

    /** Name change method **/

    /**
     * @dev Method for changing the contract name
     */
    function changeContractName(string memory newName) external onlyOwner {
        _name = newName;
    }

    /** Name change method End **/

    /** Trading Rules Methods **/

    /**
     * @dev Getter for unlimited wallets
     */
    function isUnlimitedWallet(address wallet) external view returns (bool) {
        return _isUnlimitedWallet(wallet);
    }

    /**
     * @dev Internal Getter for unlimited wallets
     */
    function _isUnlimitedWallet(address wallet) internal view returns (bool) {
        return _unlimitedWallets[wallet];
    }

    /**
     * @dev Method for adding unlimited wallet address
     */
    function addUnlimitedWallet(address wallet) external onlyOwner {
        require(
            !_unlimitedWallets[wallet],
            "BlushoToken: Wallet is already an unlimited wallet"
        );
        require(
            !_blacklistedWallets[wallet],
            "BlushoToken: Wallet is a blacklisted wallet"
        );

        _unlimitedWallets[wallet] = true;
    }

    /**
     * @dev Method for removing unlimited wallet address
     */
    function removeUnlimitedWallet(address wallet) external onlyOwner {
        require(
            _unlimitedWallets[wallet],
            "BlushoToken: Wallet is not an unlimited wallet"
        );

        _unlimitedWallets[wallet] = false;
    }

    /**
     * @dev Getter for blacklisted wallets
     */
    function isBlacklistedWallet(address wallet) external view returns (bool) {
        return _isBlacklistedWallet(wallet);
    }

    /**
     * @dev Internal Getter for blacklisted wallets
     */
    function _isBlacklistedWallet(address wallet) internal view returns (bool) {
        return _blacklistedWallets[wallet];
    }

    /**
     * @dev Method for adding blacklisted wallet address
     */
    function addBlacklistedWallet(address wallet) external onlyOwner {
        require(
            !_blacklistedWallets[wallet],
            "BlushoToken: Wallet is already an blacklisted wallet"
        );
        require(
            !_exchangeWallets[wallet],
            "BlushoToken: Wallet is an exchange wallet"
        );
        require(
            !_unlimitedWallets[wallet],
            "BlushoToken: Wallet is an unlimited wallet"
        );
        require(wallet != owner(), "BlushoToken: Wallet is owner wallet");

        _blacklistedWallets[wallet] = true;
    }

    /**
     * @dev Method for removing blacklisted wallet address
     */
    function removeBlacklistedWallet(address wallet) external onlyOwner {
        require(
            _blacklistedWallets[wallet],
            "BlushoToken: Wallet is not a blacklisted wallet"
        );

        _blacklistedWallets[wallet] = false;
    }

    /**
     * @dev Setter for transaction limit
     * Enforces the MAX_TRADE_TAX constant
     */
    function setTransactionLimit(uint256 transactionLimit) external onlyOwner {
        require(
            transactionLimit >=
                _circulatingSupply() / MIN_TRANSACTION_LIMIT_FACTOR,
            "BlushoToken: cannot set transaction limit below 1% of Circulating Supply"
        );
        _transactionLimit = transactionLimit;
    }

    /** Trading Rules Methods End **/

    /** Presale Methods **/

    /**
     * @dev Setter for developer tax
     * Enforces the MAX_TRADE_TAX constant
     */
    function finalizePresale() external onlyOwner {
        require(_isInPresale == true, "BlushoToken: not in presale mode");

        _isInPresale = false;
    }

    /** Presale Methods End **/

    /** Tokenomics Methods **/

    /**
     * @dev Getter for developer tax
     */
    function taxDeveloper() external view returns (uint256) {
        return _taxDeveloper;
    }

    /**
     * @dev Setter for developer tax
     * Enforces the MAX_TRADE_TAX constant
     */
    function setTaxDeveloper(uint256 tax) external onlyOwner {
        require(
            tax <= MAX_DEVELOPER_TAX,
            "BlushoToken: cannot set total tax higher than MAX_DEVELOPER_TAX"
        );
        _taxDeveloper = tax;
    }

    /**
     * @dev Getter for developer tax wallet
     */
    function taxDeveloperWallet() external view returns (address) {
        return _taxDeveloperWallet;
    }

    /**
     * @dev Setter for developer tax wallet address
     */
    function setTaxDeveloperWallet(address wallet) external onlyOwner {
        require(
            wallet != address(0),
            "BlushoToken: Cannot set to null address"
        );
        require(
            wallet != burnAddress,
            "BlushoToken: Cannot set to burn wallet"
        );
        require(
            wallet != address(this),
            "BlushoToken: Cannot set to contract address"
        );
        _taxDeveloperWallet = wallet;
    }

    /**
     * @dev Getter for taxable wallets
     */
    function isExchangeWallet(address wallet) external view returns (bool) {
        return _isExchangeWallet(wallet);
    }

    /**
     * @dev Internal Getter for taxable wallets
     */
    function _isExchangeWallet(address wallet) internal view returns (bool) {
        return _exchangeWallets[wallet];
    }

    /**
     * @dev Method for adding taxable wallet address
     */
    function addExchangeWallet(address wallet) external onlyOwner {
        require(
            !_exchangeWallets[wallet],
            "BlushoToken: Wallet is already an exchange wallet"
        );
        require(wallet != address(0), "BlushoToken: Cannot add null address");
        require(wallet != burnAddress, "BlushoToken: Cannot add burn wallet");
        require(
            wallet != address(this),
            "BlushoToken: Cannot add contract address"
        );

        _exchangeWallets[wallet] = true;
    }

    /**
     * @dev Method for removing taxable wallet address
     */
    function removeExchangeWallet(address wallet) external onlyOwner {
        require(
            _exchangeWallets[wallet],
            "BlushoToken: Wallet is not an exchange wallet"
        );

        _exchangeWallets[wallet] = false;
    }

    /** Tokenomics Methods End **/

    /** Project Wallets Methods **/

    /**
     * @dev Getter for project tax schedule (in seconds)
     */
    function taxProjectsSchedule() public view returns (uint256) {
        return _taxProjectsSchedule;
    }

    /**
     * @dev Setter for project tax schedule
     * Enforces MIN_PROJECT_SCHEDULE
     */
    function setTaxProjectsSchedule(uint256 schedule) public onlyOwner {
        require(
            schedule >= MIN_PROJECT_SCHEDULE,
            "BlushoToken: cannot set project tax schedule lower than MIN_PROJECT_SCHEDULE"
        );
        require(
            schedule <= MAX_PROJECT_SCHEDULE,
            "BlushoToken: cannot set project tax schedule higher than MAX_PROJECT_SCHEDULE"
        );
        _taxProjectsSchedule = schedule;
    }

    /**
     * @dev Getter for last Project tax timestamp
     */
    function lastProjectsTaxTimestamp() external view returns (uint256) {
        return _lastProjectsTaxTimestamp;
    }

    /**
     * @dev Getter for current taxCycle
     */
    function projectsTaxCycle() external view returns (uint256) {
        return _projectsTaxCycle;
    }

    /**
     * @dev Getter for current projectWalletsIndex
     */
    function projectWalletsIndex() external view returns (uint256) {
        return _projectWalletsIndex;
    }

    /**
     * @dev Getter for total balance of project wallets
     */
    function totalProjectWalletsBalance() external view returns (uint256) {
        return _totalProjectWalletsBalance;
    }

    /**
     * @dev Getter for total balance of project wallets
     */
    function pendingProjectTaxesToBeBurned() external view returns (uint256) {
        return _pendingProjectTaxesToBeBurned;
    }

    /**
     * @dev Helper method to generate address for projectwalletindex
     */
    function _addressForProjectWalletIndex(uint256 walletIndex)
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(walletIndex)));
    }

    /**
     * @dev External Getter for addressForProjectWalletIndex
     */
    function addressForProjectWalletIndex(uint256 projectWalletIndex)
        external
        pure
        returns (address)
    {
        return _addressForProjectWalletIndex(projectWalletIndex);
    }

    /**
     * @dev Method to add Project wallets
     * Generates random wallet adress and assigns the caller as the owner
     * Each owner can only have on project wallet
     */
    function addProjectWallet(string memory projectName) public {
        require(
            _projectWalletsOwners[_msgSender()] == address(0),
            "Caller already has a project wallet assigned"
        );

        //Increment wallet index
        _projectWalletsIndex += 1;

        //Generate project wallet address
        address projectWalletAddress = _addressForProjectWalletIndex(
            _projectWalletsIndex
        );

        //Create project wallet struct
        _projectWallets[projectWalletAddress] = ProjectWallet(
            true,
            projectName,
            _projectsTaxCycle
        );
        _projectWalletsOwners[_msgSender()] = projectWalletAddress;

        emit ProjectWalletCreate(projectWalletAddress, projectName);
    }

    /**
     * @dev Method to transfer Project wallets ownership
     */
    function transferOwnershipToProjectWallet(address newOwner) public {
        require(
            _projectWalletsOwners[_msgSender()] != address(0),
            "Caller does not have a project wallet assigned"
        );
        require(
            _projectWalletsOwners[newOwner] == address(0),
            "New Owner already has a project wallet assigned"
        );

        address projectWalletAddress = _projectWalletsOwners[_msgSender()];
        //Transfer ownership to newOwner
        _projectWalletsOwners[newOwner] = projectWalletAddress;
        //Renounce ownership for caller
        _projectWalletsOwners[_msgSender()] = address(0);
    }

    /**
     * @dev Get Project wallet address for caller
     */
    function getProjectWalletAddress(address wallet)
        external
        view
        returns (address)
    {
        require(
            _projectWalletsOwners[wallet] != address(0),
            "Caller does not have a project wallet assigned"
        );

        return _projectWalletsOwners[wallet];
    }

    /**
     * @dev Get Project wallet data for owner
     */
    function getProjectWallet(address wallet)
        external
        view
        returns (ProjectWallet memory)
    {
        require(
            _projectWalletsOwners[wallet] != address(0),
            "Caller does not have a project wallet assigned"
        );

        return _projectWallets[_projectWalletsOwners[wallet]];
    }

    /**
     * @dev Get Project wallet data for owner
     */
    function _shouldTriggerProjectWalletTax() internal view returns (bool) {
        if (_env != Env.mainnet) {
            return true;
        }
        return
            (_lastProjectsTaxTimestamp + _taxProjectsSchedule) <=
            block.timestamp;
    }

    /**
     * @dev Internal Method to trigger project wallet tax
     * Taxes all project wallets
     */
    function _triggerProjectWalletTax() internal {
        require(
            _shouldTriggerProjectWalletTax(),
            "Cannot trigger before schedule"
        );

        //Check if there were any transfers to project wallets since the last taxProjectCycle
        if (_totalProjectWalletsBalance > 0) {
            //Increase temporary _pendingProjectTaxesToBeBurned by the tax. Current real balance for all wallets is totalProjectsWalletsBalance - _pendingProjectTaxesToBeBurned
            _pendingProjectTaxesToBeBurned +=
                ((_totalProjectWalletsBalance -
                    _pendingProjectTaxesToBeBurned) * taxProjects) /
                100;
        }

        //Increase the _projectsTaxCycle
        _projectsTaxCycle += 1;
        emit ProjectTaxCycle(_projectsTaxCycle);
    }

    /**
     * @dev External Method to trigger project wallet tax
     * Taxes all project wallets
     */
    function triggerProjectWalletTax() external {
        _triggerProjectWalletTax();
    }

    /**
     * @dev Method to manually transfer outstanding taxes to burn
     */
    function transferOutstandingProjectTaxes(
        uint256 startWallet,
        uint256 numWallets
    ) external {
        uint256 numProjectWallets = _projectWalletsIndex -
            PROJECT_WALLETS_INDEX_BASE;

        require(
            startWallet < numProjectWallets,
            "Start Wallet is higher than the number of project wallets"
        );

        uint256 endWallet = startWallet + numWallets;
        if (endWallet > numProjectWallets) {
            endWallet = numProjectWallets;
        }

        //Iterate through project wallets
        for (
            uint256 currentWallet = startWallet;
            currentWallet <= endWallet;
            currentWallet++
        ) {
            address projectWalletAddress = _addressForProjectWalletIndex(
                PROJECT_WALLETS_INDEX_BASE + currentWallet
            );
            //Check if is currently in Transfer and skip
            if (!_projectWalletsInTransfer[projectWalletAddress]) {
                _transferOutstandingProjectTax(projectWalletAddress);
            }
        }
    }

    /**
     * @dev Calculate the balance of a project wallet
     */
    function _calculateProjectWalletBalance(
        uint256 baseBalance,
        uint256 startCycle,
        uint256 endCycle
    ) internal pure returns (uint256) {
        uint256 balance = baseBalance;
        for (
            uint256 taxProjectCycle = startCycle;
            taxProjectCycle < endCycle;
            taxProjectCycle++
        ) {
            balance = balance - ((balance * taxProjects) / 100);
        }
        return balance;
    }

    function calculateProjectWalletBalance(
        uint256 baseBalance,
        uint256 startCycle,
        uint256 endCycle
    ) external pure returns (uint256) {
        return
            _calculateProjectWalletBalance(baseBalance, startCycle, endCycle);
    }

    /**
     * @dev Method to calculate project wallet balance for pending transfers to the burn wallet
     */
    function _balanceOfProjectWallet(address account)
        internal
        view
        virtual
        returns (uint256)
    {
        ProjectWallet memory projectWallet = _projectWallets[account];

        //Check if wallet balance had a transfer / burn since the last project tax cycle
        if (
            projectWallet.lastTransferToBurnAddressProjectTaxCycle <
            _projectsTaxCycle
        ) {
            return
                _calculateProjectWalletBalance(
                    _balances[account],
                    projectWallet.lastTransferToBurnAddressProjectTaxCycle,
                    _projectsTaxCycle
                );
        }

        return _balances[account];
    }

    function _isProjectWallet(address wallet) internal view returns (bool) {
        return _projectWallets[wallet].exists;
    }

    function _transferOutstandingProjectTax(address projectWalletAddress)
        internal
    {
        ProjectWallet memory projectWallet = _projectWallets[
            projectWalletAddress
        ];

        //Check if the last transfer was in the last tax cycle and not currently transfering taxes
        if (
            projectWallet.lastTransferToBurnAddressProjectTaxCycle <
            _projectsTaxCycle
        ) {
            //This has to be a require, as any transfer has to fail if project wallet is currently in tax transfer (should rarely happen)
            require(
                !_projectWalletsInTransfer[projectWalletAddress],
                "Currently transfering taxes"
            );
            //Project wallet is currently transfering taxes
            _projectWalletsInTransfer[projectWalletAddress] = true;

            uint256 balance = _balances[projectWalletAddress];
            if (balance > 0) {
                //Get the adjusted project wallet before this transfer
                uint256 adjustedProjectWalletBalance = _calculateProjectWalletBalance(
                        balance,
                        projectWallet.lastTransferToBurnAddressProjectTaxCycle,
                        _projectsTaxCycle
                    );
                //Calculate the difference to get the taxAmount to Burn
                uint256 taxAmountToBurn = balance -
                    adjustedProjectWalletBalance;
                //Check and catch rounding errors. Could happen if this is the last project
                if (taxAmountToBurn > _pendingProjectTaxesToBeBurned) {
                    taxAmountToBurn = _pendingProjectTaxesToBeBurned;
                }
                //Deduct the taxAmount from the projectWallet
                _balances[projectWalletAddress] -= taxAmountToBurn;
                //Add the taxAmount to the burnWallet
                _balances[burnAddress] += taxAmountToBurn;
                //Decrease the temporary _pendingProjectTaxesToBeBurned by the taxAmount as it has actually been burned now
                _pendingProjectTaxesToBeBurned -= taxAmountToBurn;
                //Decrease the total projects wallets balance by the taxAmount as it has actually been burned now
                _totalProjectWalletsBalance -= taxAmountToBurn;

                emit ProjectTaxTransfer(projectWalletAddress, taxAmountToBurn);
                emit Transfer(
                    projectWalletAddress,
                    burnAddress,
                    taxAmountToBurn
                );
            }
            //Update the project wallets taxProjectsCycle
            _projectWallets[projectWalletAddress]
                .lastTransferToBurnAddressProjectTaxCycle = _projectsTaxCycle;

            _projectWalletsInTransfer[projectWalletAddress] = false;
        }
    }

    /**
     * @dev Method to calculate project wallet balance for pending transfers to the burn wallet
     */
    function _balanceOfBurnAddress() internal view virtual returns (uint256) {
        return _balances[burnAddress] + _pendingProjectTaxesToBeBurned;
    }

    /**
     * @dev Method to calculate project wallet balance for pending transfers to the burn wallet
     */
    function _circulatingSupply() internal view virtual returns (uint256) {
        return TOTAL_SUPPLY - _balanceOf(burnAddress);
    }

    /**
     * @dev Method to calculate project wallet balance for pending transfers to the burn wallet
     */
    function circulatingSupply() external view virtual returns (uint256) {
        return _circulatingSupply();
    }

    /** Project Wallets Methods End **/
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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