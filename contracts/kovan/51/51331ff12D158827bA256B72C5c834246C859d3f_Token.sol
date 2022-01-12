// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Ownable.sol";
pragma solidity ^0.8.9;

contract Token is IERC20, Ownable {

    string private _name;
    string private _symbol;

    uint8 private _decimals;
    uint8 constant MAX_TAX_FEE_RATE = 6;
    uint8[4] public taxPercentages;
    uint8 public taxFee;
    uint256 public _totalSupply;
    uint256 public whaleAmount;
    uint256 public totalVestings;


    bool public antiWhale;
    bool public _enableTax;

    address[4] public taxAddresses;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(uint256 => VestingDetails) public vestingID;
    mapping(address => uint256[]) receiverIDs;
    mapping(address => bool) public isWhitelistedFromWhaleAmount;

    enum taxAddressType {
        taxAddressNewMovies,
        taxAddressProfit,
        taxAddressDevelopment,
        taxAddressUserCredit
    }

    event whaleAmountUpdated(
        uint256 oldAmount,
        uint256 newAmount,
        uint256 time
    );
    event antiWhaleUpdated(bool status, uint256 time);
    event taxAddressUpdated(address taxAddress, uint256 time, string info);
    event UpdatedWhitelistedAddress(address _address, bool isWhitelisted);
    event TaxTransfer(
        address indexed from,
        address[4] indexed to,
        uint256[4] indexed value
    );

    struct VestingDetails {
        address receiver;
        uint256 amount;
        uint256 release;
        bool expired;
    }

    /**
     * @dev Constructor.
     * @param __name name of the token
     * @param __symbol symbol of the token, 3-4 chars is recommended
     * @param __decimals number of decimal places of one token unit, 18 is widely used
     * @param _taxPercent will be the tax percentage, example: 6%
     * @param __totalSupply total supply of tokens in lowest units (depending on decimals)
     * @param _antiWhale to enable the antiwhale feature on/off, by default value is false.
     * @param _whaleAmount whale amount of tokens in lowest units (depending on decimals)
     * @param owner address that gets 100% of token supply
     * @param _taxAddresses will be the 4 addresses to which the tax fees will be sent in each token transfer when tax is applicable
     * @param _taxPercentages are the ratios of the tax percentage divided between the 4 _taxAddresses for example => [ 10%, 20%, 30%, 40% ]
     */
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint8 _taxPercent,
        uint256 __totalSupply,
        bool _antiWhale,
        uint256 _whaleAmount,
        address owner,
        address[4] memory _taxAddresses,
        uint8[4] memory _taxPercentages
    ) Ownable(owner) {
        require(owner != address(0), "Owner can't be zero address");
        require(
            _taxAddresses[0] != address(0) &&
                _taxAddresses[1] != address(0) &&
                _taxAddresses[2] != address(0) &&
                _taxAddresses[3] != address(0),
            "Tax addresses cannot be zero address"
        );
        require(_taxPercent <= MAX_TAX_FEE_RATE, "Exceeded max tax rate limit");
        require(
            _taxPercentages[0] +
                _taxPercentages[1] +
                _taxPercentages[2] +
                _taxPercentages[3] ==
                100,
            "Total percentages must equal 100"
        );
        require(_whaleAmount < __totalSupply, "Whale amount must be lower than total supply");

        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        _owner = owner;
        whaleAmount = _whaleAmount * 10**__decimals;
        antiWhale = _antiWhale;
        _totalSupply = __totalSupply * 10**__decimals;
        taxFee = _taxPercent;
        _enableTax = true;

        // set tokenOwnerAddress as owner of all tokens and the owner has the control of antiWhale feature if enabled.
        _balances[_owner] = _totalSupply;

        // Mapping tax address
        taxAddresses[uint256(taxAddressType.taxAddressDevelopment)] = _taxAddresses[uint256(taxAddressType.taxAddressDevelopment)];
        taxAddresses[uint256(taxAddressType.taxAddressNewMovies)] = _taxAddresses[uint256(taxAddressType.taxAddressNewMovies)];
        taxAddresses[uint256(taxAddressType.taxAddressProfit)] = _taxAddresses[uint256(taxAddressType.taxAddressProfit)];
        taxAddresses[uint256(taxAddressType.taxAddressUserCredit)] = _taxAddresses[uint256(taxAddressType.taxAddressUserCredit)];

        // Mapping tax percentages
        taxPercentages[uint256(taxAddressType.taxAddressDevelopment)] = _taxPercentages[uint256(taxAddressType.taxAddressDevelopment)];
        taxPercentages[uint256(taxAddressType.taxAddressNewMovies)] = _taxPercentages[uint256(taxAddressType.taxAddressNewMovies)];
        taxPercentages[uint256(taxAddressType.taxAddressProfit)] = _taxPercentages[uint256(taxAddressType.taxAddressProfit)];
        taxPercentages[uint256(taxAddressType.taxAddressUserCredit)] = _taxPercentages[uint256(taxAddressType.taxAddressUserCredit)];

        // Owner and taxAddresses are excluded from transfer tax fees
        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[taxAddresses[uint256(taxAddressType.taxAddressDevelopment)]] = true;
        _isExcludedFromFee[taxAddresses[uint256(taxAddressType.taxAddressNewMovies)]] = true;
        _isExcludedFromFee[taxAddresses[uint256(taxAddressType.taxAddressProfit)]] = true;
        _isExcludedFromFee[taxAddresses[uint256(taxAddressType.taxAddressUserCredit)]] = true;

        // Whitelisted
        isWhitelistedFromWhaleAmount[_owner] = true;
        isWhitelistedFromWhaleAmount[address(this)] = true;
        isWhitelistedFromWhaleAmount[taxAddresses[uint256(taxAddressType.taxAddressDevelopment)]] = true;
        isWhitelistedFromWhaleAmount[taxAddresses[uint256(taxAddressType.taxAddressNewMovies)]] = true;
        isWhitelistedFromWhaleAmount[taxAddresses[uint256(taxAddressType.taxAddressProfit)]] = true;
        isWhitelistedFromWhaleAmount[taxAddresses[uint256(taxAddressType.taxAddressUserCredit)]] = true;

        // Event
        emit Transfer(address(0), _owner, _totalSupply);

    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @return the total supply of tokens
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Allows the owner to change the whale amount per transaction
     * @param _amount The amount of lowest token units to be set as whaleAmount
     * @return _success true (bool) if the flow was successful
     */
    function updateWhaleAmount(uint256 _amount)
        external
        onlyOwner
        returns (bool _success)
    {
        require(antiWhale, "Anti whale is turned off");
        uint256 oldAmount = whaleAmount;
        whaleAmount = _amount;
        emit whaleAmountUpdated(oldAmount, whaleAmount, block.timestamp);
        return true;    
    }

    /**
     * @dev Allows the owner to turn the anti whale feature on/off.
     * @param status disable (false) / enable (enable) bool value
     * @return _success true (bool) if the flow was successful
     */
    function updateAntiWhale(bool status) external onlyOwner returns (bool _success) {
        antiWhale = status;
        emit antiWhaleUpdated(antiWhale, block.timestamp);
        return true;
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * @param spender Address of spender
     * @param value uint amount that spender is approved by msg.sender to spend
     * @return _success bool (true) if flow was successful
     *
     * Approves spender to spend value tokens from msg.sender
     */
    function approve(address spender, uint256 value) public returns (bool _success) {
        _approve(msg.sender, spender, value);
        return true;
    }

        /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * @param owner Address of owner of token who sets allowance for spender to use the owner's tokens
     * @param spender Address of spender whose allowance is being set by msg.sender
     * @param value Value by which spender's allowance is being reduced
     * @return _success bool value => true if flow was successful
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal returns (bool _success) {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
        return true;
    }

        /**
     * @dev See `IERC20.allowance`.
     * @param owner Address of the owner of the tokens
     * @param spender Address of the spender of the owners's tokens
     * @return the amount of token set by owner for spender to spend
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

        /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * @param spender Address of spender whose allowance is being increased by msg.sender
     * @param addedValue Value by which spender's allowance is being increased
     * @return _success bool value => true if flow was successful
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool _success)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @param spender Address of spender whose allowance is being increased by msg.sender
     * @param subtractedValue Value by which spender's allowance is being reduced
     * @return _success bool value => true if flow was successful 
     *   
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool _success)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - subtractedValue
        );
        return true;
    }

    /**
     * @param _address Address of the user
     * @param _isWhitelisted boolean (true or false), whether the address must be enabled/disabled from whitelist
     * @return success Boolean value => true if flow was successful
     * Updates an account's status in the whitelistFromWhaleAmount (enable/disable)
     */
    function updateWhitelistedAddressFromWhale(address _address, bool _isWhitelisted) public onlyOwner
    returns(bool success){
        isWhitelistedFromWhaleAmount[_address] = _isWhitelisted;
        emit UpdatedWhitelistedAddress(_address, _isWhitelisted);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * @param sender Address of sender whose is transferring amount to the recipient
     * @param recipient Address of the receiver of tokens from the sender
     * @param amount Amount of tokens being transferred by sender to the recipient
     * @return _success Boolean value => true if flow was successful
     *
     *Transfers {amount} token from sender to recipient
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool _success) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    /**
     * @dev See `IERC20.transfer`.
     * @param recipient Address of the receiver of tokens from the sender
     * @param amount Amount of tokens being transferred by sender to the recipient
     * @return _success Boolean value true if the flow is successful
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external returns (bool _success) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

        /**
     * @dev Allows the caller to airdrop tokens.
     * @param users Addresses of the users.
     * @param amounts Token values to the corresponding users.
     * @param totalSum Total sum of the tokens to be airdropped to all users.
     * @return _success true (bool) if the flow was successful
     */
    function multiSend(
        address[] memory users,
        uint256[] memory amounts,
        uint256 totalSum
    ) external returns (bool _success) {
        require(users.length == amounts.length, "Length mismatch");
        require(totalSum <= balanceOf(msg.sender), "Not enough balance");

        for (uint256 i = 0; i < users.length; i++) {
            _transfer(msg.sender, users[i], amounts[i]);
        }
        return true;
    }

    /**
     * @param from Address of sender whose is transferring amount to the recipient
     * @param to Address of the receiver of tokens from the sender
     * @param amount Amount of tokens being transferred by sender to the recipient
     * @return _success Boolean value => true if flow was successful
     * Transfers amount from {from} to {to}
     * Checks for antiWhale
     * Checks for tax applicability
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool _success) {
        
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Transfer will be taxed if both sender and receiver are not excluded from fee
        bool isTaxed = _enableTax &&
            (!(_isExcludedFromFee[from] || _isExcludedFromFee[to]));

        // Checking for anti-whale
        if (antiWhale) {
            uint256 tax_amount = 0;
            if (isTaxed) tax_amount = (amount * taxFee) / 10**2;
            require(
                (amount - tax_amount) <= whaleAmount,
                "Transfer amount exceeds max amount"
            );
            //If account is not whitelisted from whale amount, then checking if total balance will be greater than whale amount 
            if(!isWhitelistedFromWhaleAmount[to]){
                require(
                    balanceOf(to) + amount - tax_amount <= whaleAmount,
                    "Recipient amount exceeds max amount"
                );
            }
        }
        unchecked {
            require(balanceOf(from) >= amount, "Amount exceeds balance");
            _balances[from] = _balances[from] - amount;
        }

        // If any account belongs to _isExcludedFromFee account then no tax will be applied
        if (!isTaxed) {
            // No tax
            // SafeMath for addition overflow built-in
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        } else {
            // Calculation of Tax amount
            uint256 tax_amount = (amount * taxFee) / (10**2);

            _transferFee(from, tax_amount);

            // Subtracting tax from transfer amount to receiver
            _balances[to] += amount - tax_amount;
            emit Transfer(from, to, amount - tax_amount);
        }
        return true;
    }

    /**
     * @param tax Amount of tokens to be divided between the 4 tax addresses
     * @return _success Boolean value => true if flow was successful
     * Transfers the tax fee to the tax addresses divided between them in the ratio provided in taxRatios
     */
    function _transferFee(address from, uint256 tax) private returns (bool _success) {
        
        // Calculate Amount
        uint256 taxAmountDevelopment = (tax * taxPercentages[uint256(taxAddressType.taxAddressDevelopment)]) / (100);
        uint256 taxAmountNewMovies = (tax * taxPercentages[uint256(taxAddressType.taxAddressNewMovies)]) / (100);
        uint256 taxAmountProfit = (tax * taxPercentages[uint256(taxAddressType.taxAddressProfit)]) / (100);
        uint256 taxAmountUserCredit = (tax * taxPercentages[uint256(taxAddressType.taxAddressUserCredit)]) / (100);
        uint256 totalDivided = taxAmountDevelopment + taxAmountNewMovies + taxAmountProfit + taxAmountUserCredit;
        taxAmountUserCredit = taxAmountUserCredit + (tax - totalDivided);

        // Transfer Amount
        _balances[taxAddresses[uint256(taxAddressType.taxAddressDevelopment)]] += taxAmountDevelopment;
        _balances[taxAddresses[uint256(taxAddressType.taxAddressNewMovies)]] += taxAmountNewMovies;
        _balances[taxAddresses[uint256(taxAddressType.taxAddressProfit)]] += taxAmountProfit;
        _balances[taxAddresses[uint256(taxAddressType.taxAddressUserCredit)]] += taxAmountUserCredit;

        // Events
        emit Transfer(from, taxAddresses[uint256(taxAddressType.taxAddressDevelopment)], taxAmountDevelopment);
        emit Transfer(from, taxAddresses[uint256(taxAddressType.taxAddressNewMovies)], taxAmountNewMovies);
        emit Transfer(from, taxAddresses[uint256(taxAddressType.taxAddressProfit)], taxAmountProfit);
        emit Transfer(from, taxAddresses[uint256(taxAddressType.taxAddressUserCredit)], taxAmountDevelopment);

        return true;
    }

    /**
     * @param account Address of the account to be checked if its excluded from tax fees
     * @return _success Boolean value => true if flow was successful
     * Checks if account is excluded from tax fee
     */
    function isExcludedFromFee(address account) public view returns (bool _success) {
        return _isExcludedFromFee[account];
    }

        /** 
    * @param applicable Boolean to set the tax applicability as true or false
    * @return _success boolean (true) if flow was successful
    Changes the tax applicability as provided in the input
    */
    function isTaxApplicable(bool applicable)
        external
        onlyOwner
        returns (bool _success)
    {
        if (_enableTax != applicable) {
            _enableTax = applicable;
            return true;
        }
        return false;
    }

    /**
     * @param newAddress Address of the new taxAddress of type {_type}
     * @param _type Tax address type, one of the 4 types : 
        taxAddressNewMovies,
        taxAddressProfit,
        taxAddressDevelopment,
        taxAddressUserCredit
     * @return _success Boolean value => true if flow was successful
     * Changes tax address of type {_type}
     * Includes the previous address in tax fee
     * Excludes the new address from tax fee
     * Exclude old address from whitelist, and includes the new address
     */
    function changeTaxAddress(address newAddress, taxAddressType _type)
        external
        onlyOwner
        returns (bool _success)
    {   
        includeInFee(taxAddresses[uint256(_type)]);
        updateWhitelistedAddressFromWhale(taxAddresses[uint256(_type)], false);
        updateWhitelistedAddressFromWhale(newAddress, true);
        excludeFromFee(newAddress);
        taxAddresses[uint256(_type)] = newAddress;
        
        return true;

    }

    /**
     * @param _taxPercentages The ratios of the division of the tax fees between the 4 tax addresses
     * @return _success Boolean value => true if flow was successful
     * Changes the ratio of tax division between the 4 tax addresses: 
        taxAddressNewMovies,
        taxAddressProfit,
        taxAddressDevelopment,
        taxAddressUserCredit
     */
    function changeTaxPercentages(uint8[4] calldata _taxPercentages)
        external
        onlyOwner
        returns (bool _success)
    {
        require(
            _taxPercentages[0] +
                _taxPercentages[1] +
                _taxPercentages[2] +
                _taxPercentages[3] ==
                100,
            "Total percentages must equal 100"
        );
        taxPercentages[uint256(taxAddressType.taxAddressDevelopment)] = _taxPercentages[uint256(taxAddressType.taxAddressDevelopment)];
        taxPercentages[uint256(taxAddressType.taxAddressNewMovies)] = _taxPercentages[uint256(taxAddressType.taxAddressNewMovies)];
        taxPercentages[uint256(taxAddressType.taxAddressProfit)] = _taxPercentages[uint256(taxAddressType.taxAddressProfit)];
        taxPercentages[uint256(taxAddressType.taxAddressUserCredit)] = _taxPercentages[uint256(taxAddressType.taxAddressUserCredit)];
        return true;
    }

    /**
     * @param _taxFee Tax rate in percentage to be set by owner
     * @return _success Boolean value => true if flow was successful
     * Owner can set the tax rate, maximum upto 6%
     */
    function changeTaxFeePercent(uint8 _taxFee) external onlyOwner returns (bool _success) {
        require(_taxFee <= MAX_TAX_FEE_RATE, "Exceeded max tax rate");
        taxFee = _taxFee;
        return true;
    }

    /**
     * @param account Address of account to be evicted from taxes during each transfer
     * @return _success Boolean value => true if flow was successful
     * Account will be evicted from taxes for each transfer
     */
    function excludeFromFee(address account) public onlyOwner returns (bool _success) {
        _isExcludedFromFee[account] = true;
        return true;
    }

    /**
     * @param account Address of account to be applicable to pay taxes during each transfer
     * @return _success Boolean value => true if flow was successful
     * Account will be applicable to pay taxes for each transfer
     */
    function includeInFee(address account) public onlyOwner returns (bool _success) {
        _isExcludedFromFee[account] = false;
        return true;
    }

    /**
     * @param account Address of account
     * @return Number of tokens owned by the account
     * Returns the balance of tokens of the account
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
    * @param _receiver Address of the receiver of the vesting
    * @param _amount Amount of tokens to be locked up for vesting
    * @param _release Timestamp of the release time
    * @return _success Boolean value true if flow is successful
    * Creates a new vesting
    */
    function createVesting(
        address _receiver,
        uint256 _amount,
        uint256 _release
    ) public returns (bool _success) {
        require(_receiver != address(0), "Zero receiver address");
        require(_amount > 0, "Zero amount");
        require(_release > block.timestamp, "Incorrect release time");

        totalVestings++;
        vestingID[totalVestings] = VestingDetails(
            _receiver,
            _amount,
            _release,
            false
        );
        // Adds the vesting id corresponding to the receiver
        receiverIDs[_receiver].push(totalVestings);
        require(_transfer(msg.sender, address(this), _amount));
        return true;
    }

        /**
    * @param _receivers Arrays of address of receiver of vesting amount
    * @param _amounts Array of amounts corresponding to each vesting
    * @param _releases Array of release timestamps corresponding to each vesting
    * @return _success Boolean value true if flow is successful
    * Creates multiple vesting, calls createVesting for each corresponding entry in {_receivers} {_amounts} {_releases}
    */
    function createMultipleVesting(
        address[] memory _receivers,
        uint256[] memory _amounts,
        uint256[] memory _releases
    ) external returns (bool _success) {
        require(
            _receivers.length == _amounts.length &&
                _amounts.length == _releases.length,
            "Invalid data"
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            bool success = createVesting(
                _receivers[i],
                _amounts[i],
                _releases[i]
            );
            require(success, "Creation of vesting failed");
        }
        return true;
    }

        /**
    * @param id Id of the vesting
    * @return Boolean value true if flow is successful
    * Returns the release timestamp of the the vesting
    */
    function getReleaseTime(uint256 id) public view returns(uint256){
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(!vestingDetail.expired, "ID expired");
        return vestingDetail.release;
    }

    /**
    * @param id Id of the vesting
    * @return _success Boolean value true if flow is successful
    * The receiver of the vesting can claim their vesting if the vesting ID corresponds to their address 
    * and hasn't expired
    */
    function claim(uint256 id) external returns (bool _success) {
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(msg.sender == vestingDetail.receiver, "Caller is not the receiver");
        require(!vestingDetail.expired, "ID expired");
        require(
            block.timestamp >= vestingDetail.release,
            "Release time not reached"
        );
        vestingID[id].expired = true;
        require(_transfer(
            address(this),
            vestingDetail.receiver,
            vestingDetail.amount
        ));
        return true;
    }

    /**
    * @param user Address of receiver of vesting amount
    * @return Array of IDs corresponding to vesting assigned to the user
    * Returns the IDs of the vestings , the user corresponds to
    */
    function getReceiverIDs(address user)
        external
        view
        returns (uint256[] memory)
    {
        return receiverIDs[user];
    }
}