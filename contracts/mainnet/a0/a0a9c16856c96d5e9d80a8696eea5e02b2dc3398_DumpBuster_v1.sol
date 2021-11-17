// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./Context.sol";
import "./IERC20.sol";

contract DumpBuster_v1 is Context, IERC20 {

    mapping (address => uint256) private _balances; // How much money everyone has
    mapping (address => bool) private _exchanges; // A map of exchanges for swapping coins. These addresses are whitelisted from time based transactions.
    mapping (address => mapping (address => uint256)) private _allowances; // For Uniswap. Used to let uniswap make exchanges for you.

    address private _owner; // Who owns the token
    address private _banner; // Who can ban people
    address private _proxy; // Address of the proxy
    address private _tax; // The address of the wallet that project tax funds goes to
    uint256 private _taxAmount; // Amount we tax that goes to _tax wallet, treated as a percentage (10000 = 100%)
    address private _treasury; // Address of our treasury wallet
    uint256 private _sellTaxFactor; // Multiplicative factor by which sell tax differs from buy tax (10000 = 100%, 18000 = 1.8x)


    //mapping (address => uint256) private _lastTransactBlocks; // Keeps track of the last block a user transacted in
    //mapping (address => uint256) private _lastTransactTimes; // Keeps track of the last time a user transacted
    bool private _tradeIsOpen; // Is trading available
    bool private _buyIsOpen; // Is exchange buying available
    bool private _sellIsOpen; // Is exchange selling available
    //uint256 private _launchedBlock; // What block number did we launch on
    uint256 private _blockRestriction; // The number of blocks people need to wait til the second transaction
    uint256 private _timeRestriction; // How long folks need to wait between transactions
    uint256 private _transactRestriction; // Maximum number of tokens a user is allowed to trade in one transaction
    uint256 private _transactRestrictionTime; // How long is the transaction size restriction in effect
    uint256 private _transactRestrictionTimeStart; // What time does the transaction time restriction start
    bool private _transactRestrictionEnabled; // Is the transaction size restriction enabled

    bool private _initialized; // Have we initialzed
    uint256 private _DECIMALS;
    uint256 private _DECIMALFACTOR;
    uint256 private _SUPPLY;
    uint256 private _TotalSupply;
    uint256 private _TENTHOUSANDUNITS;
    string private _NAME;
    string private _SYMBOL; // Our Ticker

    mapping (address => mapping (address => uint256)) private botChecker; // For each coin the last time each wallet transacted.
    mapping (address => mapping (address => bool)) private blacklist; // For each coin which wallets are blacklisted?
    mapping (address => bool) private _partners; // Map of which coins should be allowed to utilize DumpBuster methods

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event Transfer(address recipient, uint256 amount);
    event Approval(address spender, uint256 amount);

    /**
     * Description: Check if a user is the owner. Used by methods that should only be run by the owner wallet.
     **/
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(_msgSender() == _owner, "Caller is not owner");
        _;
    }

    /**
     * Description: Check if a user is the owner or banner. Used by methods that should only be run by the owner or banner wallets.
     **/
    modifier isOwnerOrBanner() {
        require(_msgSender() == _owner || _msgSender() == _banner, "Caller is not owner or banner");
        _;
    }

    /**
     * Description: Used to initialize all variables when contract is launched. Only ever run at launch.
     **/
    function initialize() public {
        require(!_initialized);
        _owner = _msgSender();
    	_tax = 0xefe5bb8529b6bF478EF8c18cd115746F162C9C2d;
    	_banner = _msgSender();
    	_treasury = _msgSender();
        _tradeIsOpen = false;
        _buyIsOpen = true;
        _sellIsOpen = false;
    	_blockRestriction = 2;
        _timeRestriction = 60;
    	_taxAmount = 320;
    	_sellTaxFactor = 18000;
    	_transactRestriction = 250000000;
    	_transactRestrictionTime = 60;
    	_transactRestrictionTimeStart = block.timestamp;

    	_DECIMALS = 9;
    	_DECIMALFACTOR = 10 ** _DECIMALS;
    	_SUPPLY = 100000000000;
    	_TotalSupply = _SUPPLY * _DECIMALFACTOR;
    	_TENTHOUSANDUNITS = 10000;
    	_NAME = "DumpBuster";
    	_SYMBOL = "GTFO";

    	_balances[_msgSender()] = _TotalSupply;

    	_initialized = true;

        emit OwnerSet(address(0), _owner);
    }

    /**
     * Description: Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * Description: Change banner
     * @param newBanner address of new banner
     */
    function changeBanner(address newBanner) public isOwner {
        _banner = newBanner;
    }

    /**
     * Description: Open trading after launch
     */
    function openTrade() public isOwner {
        _tradeIsOpen = true;
    }

    /**
     * Description: Close trading in emergency, even transacts other than buys/sells
     */
    function closeTrade() public isOwner {
        _tradeIsOpen = false;
    }

    /**
     * Description: Open buying on exchanges
     */
    function openBuys() public isOwner {
        _buyIsOpen = true;
    }

    /**
     * Description: Open selling on exchanges
     */
    function openSells() public isOwner {
        _sellIsOpen = true;
    }

    /**
     * Description: Close buying on exchanges
     */
    function closeBuys() public isOwner {
        _buyIsOpen = false;
    }

    /**
     * Description: Close selling on exchanges
     */
    function closeSells() public isOwner {
        _sellIsOpen = false;
    }

    /**
     * Description: Add an exchange LP to the exchange list
     */
    function addExchange(address exchangeToAdd) public isOwner {
        _exchanges[exchangeToAdd] = true;
    }

    /**
     * Description: Remove an exchange LP to the exchange list
     */
    function removeExchange(address exchangeToRemove) public isOwner {
        _exchanges[exchangeToRemove] = false;
    }


    /**
     * Description: Set the address of our own coin up so we can utilize our own DumpBuster Methods. This can only be called once.
     * @param proxyAddress - The address of the proxy.
     */
    function setProxy(address proxyAddress) public isOwner {
        require(_proxy==address(0));
        _proxy = proxyAddress;
    }


    /**
     * Description: Used to white list contract addresses that utilize our methods.
     * @param partnerAddress - The address to add to our whitelist.
     */
    function addPartner(address partnerAddress) public isOwner {
        _partners[partnerAddress] = true;
    }

    /**
     * Description: Used to remove people from the whitelist. Will not delete their data in case they decide to come back.
     * @param partnerAddress - The address of the contract to remove from the whitelist.
     */
    function removePartner(address partnerAddress) public isOwner {
        _partners[partnerAddress] = false;
    }

    /**
     * Description: Allows admin to change the time restriction between transactions during time restriction windows.
     * @param newTime - The time in seconds to block after a transaction
     */
    function updateTimeRestriction(uint256 newTime) public isOwner {
        _timeRestriction = newTime;
    }

    /**
     * Description: Update how many blocks we make people wait to transact more than once during launch window.
     * @param newBlock - Number of blocks we will make people wait.
     */
    function updateBlockRestriction(uint256 newBlock) public isOwner {
        _blockRestriction = newBlock;
    }

    /**
     * Description: Update the wallet address general tax is sent to and change the general tax percentage (10000 = 100%).
     * @param taxAddress - The wallet address.
     * @param taxAmount - The percentage to send in tax to the general tax wallet (10000 = 100%).
     */
    function updateTax(address taxAddress, uint256 taxAmount) public isOwner {
        _tax = taxAddress;
        _taxAmount = taxAmount;
    }

    /**
     * Description: Change the amount of tokens people are able to trade during the time restricted periods.
     * @param transactRestriction - The amount of tokens people can transact during restricted periods.
     */
    function updateTransactRestriction(uint256 transactRestriction) public isOwner {
        _transactRestriction = transactRestriction;
    }

    /**
     * Description: Changes the amount of time the transaction restrictions are in effect and turns on or off transaction restrictions.
     * @param transactRestrictionTime - Amount of time to restrict transactions (number of seconds)
     * @param transactRestrictionEnabled - Should we start restrictions again.
     */
    function updateTransactRestrictionTime(uint256 transactRestrictionTime, bool transactRestrictionEnabled) public isOwner {
        _transactRestrictionTime = transactRestrictionTime;
        _transactRestrictionEnabled = transactRestrictionEnabled;
        _transactRestrictionTimeStart = block.timestamp;
    }

    /**
     * Description: Changes the treasury wallet address.
     * @param treasury - Wallet address of treasury wallet.
     */
    function updateTreasury(address treasury) public isOwner {
        _treasury = treasury;
    }

    /**
     * Description: Return owner address.
     * @return address of owner.
     */
    function getOwner() external view returns (address) {
        return _owner;
    }

    /**
     * Description: Return coin name.
     * @return name of coin.
     */
    function name() public view returns (string memory) {
        return _NAME;
    }

    /**
     * Description: Return ticker symbol.
     * @return Ticker Symbol
     */
    function symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    /**
     * Description: Return how many digits there are to the right of the decimal.
     * @return Number of digits to the right of the decimal.
     */
    function decimals() public view returns (uint256) {
        return _DECIMALS;
    }

    /**
     * Description: Return total number of tokens in circulation.
     * @return Number of tokens in circulation.
     */
    function totalSupply() public override view returns (uint256) {
        return _TotalSupply;
    }

    /**
     * Description: Get the number of tokens in a given wallet.
     * @param account - Address of wallet to check.
     * @return Number of tokens in wallet.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * Description: Lets a wallet transfer funds to another wallet.
     * @param recipient - Address of wallet to send funds to.
     * @param amount - Number of tokens to send to recipient.
     * @return Was transaction successful
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transfer(_msgSender(), recipient, amount);
    }

    /**
     * Description: Lets a third wallet transfer funds from one wallet to another wallet.
     * @param sender - Address of wallet to take funds from.
     * @param recipient - Address of wallet to send funds to.
     * @param amount - Number of tokens to send to recipient.
     * @return Was transaction successful
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount <= _allowances[sender][_msgSender()], "Insufficient allowance");
        bool tranactionWentThrough = _transfer(sender, recipient, amount);

        if (tranactionWentThrough) {
            _allowances[sender][_msgSender()] = _allowances[sender][_msgSender()] - amount;
        }

        return tranactionWentThrough;
    }

    /**
     * Description: Allows a wallet to see how much another wallet has approved a third wallet to spend.
     * @param owner - The wallet address with the funds.
     * @param spender - The wallet approved to spend funds.
     * @return The amount approved for the owner / spender pair.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * Description: Allows a wallet to approve a certain number of funds another wallet can transact with.
     * @param spender - The wallet approved to spend funds.
     * @param amount - The amount being approved to spend.
     * @return Whether the transaction was successful.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function fullScan(address coinId, address accountId, uint256 timeThreshold, uint256 tokenAmount, uint256 totalTokens, uint256 percentageThreshold) public returns (bool isIssue){
        collectTax();

        if (validateTimeBasedTransaction(coinId, accountId, timeThreshold, false)) {
            return true;
        }

        if (validateVolumeBasedTransaction(tokenAmount, totalTokens, percentageThreshold, false)) {
            return true;
        }

        if (validateManipulation(false)) {
            return true;
        }

        return false;
    }

    /**
     * Takes coin id, account id, and time threshold. If the account has traded the coin id since the time threshold we return true.
     **/
    function validateTimeBasedTransaction(address coinId, address accountId, uint256 timeThreshold) public returns (bool isIssue) {
        return validateTimeBasedTransaction(coinId, accountId, timeThreshold, true);
    }

    function validateTimeBasedTransaction(address coinId, address accountId, uint256 timeThreshold, bool collectThreshold) private returns (bool isIssue) {
        if (collectThreshold) {
            collectTax();
        }

        if ((block.timestamp - botChecker[coinId][accountId]) < timeThreshold) {
            return true;
        }
        return false;
    }

    function validateVolumeBasedTransaction(uint256 tokenAmount, uint256 totalTokens, uint256 percentageThreshold, address accountId) public returns (bool isIssue) {
        return validateVolumeBasedTransaction(tokenAmount, totalTokens, percentageThreshold, true);
    }

    function validateVolumeBasedTransaction(uint256 tokenAmount, uint256 totalTokens, uint256 percentageThreshold, bool collectThreshold) private returns (bool isIssue) {
        if (collectThreshold) {
            collectTax();
        }

        if (((tokenAmount * _TENTHOUSANDUNITS) / _TotalSupply) > (percentageThreshold)) {
            return true;
        }
        return false;
    }

    function validateManipulation() public returns (bool isIssue) {
        return validateManipulation(true);
    }

    function validateManipulation(bool collectThreshold) private returns (bool isIssue) {
        if (collectThreshold) {
            collectTax();
        }
    }

    function isOnBlackList(address coinId, address accountId) public view returns (bool isIssue) {
        return blacklist[coinId][accountId] == true;
    }

    function addToBlacklist(address coinId, address accountId) public isOwnerOrBanner {
        blacklist[coinId][accountId] = true;
    }

    function removeFromBlacklist(address coinId, address accountId) public isOwnerOrBanner {
        blacklist[coinId][accountId] = false;
    }

    /**
    * Call this method to log a transacttion which will update our tables.
     **/
    function transact(address coinId, address accountId) public returns (bool isIssue) {
        botChecker[coinId][accountId] = block.timestamp;
    }

    function collectTax() private view returns (bool hadCoin) {
        require (_partners[_msgSender()]);
    }

    /**
     * Description Method to handle transfer of funds from one account to another. Also handles taxes.
     * @param sender - wallet of sender
     * @param recipient - wallet of recipient
     * @param amount - number of tokens to transfer
     * @return Was transaction successful
     */
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(_owner == sender || _tradeIsOpen, "Trading not currently open");

    	// Initializes to 0 - will only happen once - require always succeeds the first time
        //if (_lastTransactBlocks[sender] == 0) {
    	    //_lastTransactBlocks[sender] = _launchedBlock + _blockRestriction + 1;
    	//}
    	//require(_owner == sender || _lastTransactBlocks[sender] - _launchedBlock > _blockRestriction, "Cannot transact twice in first blocks");

    	if (!_exchanges[sender]) {
    	    require(_owner == sender || block.timestamp - botChecker[_proxy][sender] > _timeRestriction, "Cannot transact twice in short period of time");
    	}

    	if (!_exchanges[recipient]) {
    	    require(_owner == sender || block.timestamp - botChecker[_proxy][recipient] > _timeRestriction, "The wallet you are sending funds to cannot transact twice in short period of time");
    	}

    	if (_owner == sender || (_transactRestrictionEnabled && block.timestamp <= _transactRestrictionTimeStart + _transactRestrictionTime)) {
    	    require(_owner == sender || amount < _transactRestriction, "Cannot exceed transaction size limit");
    	}

        require(amount <= _balances[sender], "Insufficient balance");

        require(_owner == sender || !blacklist[_proxy][sender], "Sender Blacklisted");
        require(_owner == sender || !blacklist[_proxy][recipient], "Recipient Blacklisted");

        if (_exchanges[sender]) {
            require(_owner == sender || _buyIsOpen, "Buying not currently open");
        }

        if (_exchanges[recipient]) {
            require(_owner == sender || _sellIsOpen, "Selling not currently open");
        }

    	uint256 amountForTax;
    	uint256 amountForTransfer;

    	amountForTax = amount * _taxAmount / _TENTHOUSANDUNITS;

    	if (_exchanges[recipient] && _sellTaxFactor != _TENTHOUSANDUNITS) {
            amountForTax = amountForTax * _sellTaxFactor / _TENTHOUSANDUNITS;
        }

    	amountForTransfer = amount - amountForTax;

    	_balances[sender] = _balances[sender] - amount;
    	_balances[_tax] = _balances[_tax] + amountForTax;
        _balances[recipient] = _balances[recipient] + amountForTransfer;
        emit Transfer(sender, recipient, amountForTransfer);

    	if (!_exchanges[sender]) {
    	    botChecker[_proxy][sender] = block.timestamp;
    	}

    	if (!_exchanges[recipient]) {
    	    botChecker[_proxy][recipient] = block.timestamp;
    	}

        return true;
    }
}