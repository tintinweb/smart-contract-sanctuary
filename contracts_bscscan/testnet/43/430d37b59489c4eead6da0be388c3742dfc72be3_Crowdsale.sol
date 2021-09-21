/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

pragma solidity 0.5.11;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

}

/**
 * @title token interface
 */
interface IBBTZToken {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
    function lock(address account, uint256 amount, uint256 time) external;
    function release() external;
    function hardcap() external view returns(uint256);
    function isAdmin(address account) external view returns (bool);
    function isOwner(address account) external view returns (bool);
}

/**
 * @title Exchange interface
 */
 interface IExchange {
     function acceptETH() external payable;
     function finish() external;
     function reserveAddress() external view returns(address payable);
 }

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */
contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by to perform certain actions (e.g. participate in a
 * crowdsale).
 */
contract WhitelistedRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    IBBTZToken private _token;

    modifier onlyAdmin() {
        require(_token.isAdmin(msg.sender), "Caller has no permission");
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "Sender is not whitelisted");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyAdmin {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function addListToWhitelisted(address[] memory accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            addWhitelisted(accounts[i]);
        }
    }

    function removeWhitelisted(address account) public onlyAdmin {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

/**
 * @title EnlistedRole
 * @dev enlisted accounts have been approved to perform certain actions (e.g. participate in a
 * crowdsale).
 */
contract EnlistedRole {
    using Roles for Roles.Role;

    event EnlistedAdded(address indexed account);
    event EnlistedRemoved(address indexed account);

    Roles.Role private _enlisted;

    IBBTZToken private _token;

    modifier onlyAdmin() {
        require(_token.isAdmin(msg.sender));
        _;
    }

    modifier onlyEnlisted() {
        require(isEnlisted(msg.sender), "Sender is not Enlisted");
        _;
    }

    function isEnlisted(address account) public view returns (bool) {
        return _enlisted.has(account);
    }

    function addEnlisted(address account) public onlyAdmin {
        _enlisted.add(account);
        emit EnlistedAdded(account);
    }

    function addListToEnlisted(address[] memory accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            addEnlisted(accounts[i]);
        }
    }

    function removeEnlisted(address account) public onlyAdmin {
        _enlisted.remove(account);
        emit EnlistedRemoved(account);
    }
}

/**
 * @title Crowdsale contract
 */
contract Crowdsale is ReentrancyGuard, WhitelistedRole, EnlistedRole {
    using SafeMath for uint256;

    // deployer
    address internal _initAddress;

    // The token being sold
    IBBTZToken private _token;

    // Address where funds are collected
    address payable private _wallet;
    address payable private _exchangeAddr;
    address private _bonusAddr;
    address private _teamAddr;
    address private _priceProvider;

    // stats
    uint256 private _weiRaised; // (ETH)
    uint256 private _tokensPurchased; // (Tokens)
    uint256 private _reserved; // (USD)

    // reserve variables
    uint256 private _reserveTrigger = 100000000 * (10**18); // (Tokens)
    uint256 private _reserveLimit = 150000; // (USD)

    // Price of 1 ether in USD Cents
    uint256 private _currentETHPrice;
    uint256 private _decimals;

    // How many token units a buyer gets per 1 USD
    uint256 private _rate;

    // Bonus percent (5% = 500)
    uint256 private _bonusPercent = 500;

    // Minimum amount of wei to invest
    uint256 private _minimum = 0.1 ether; // (ETH)

    // Limit of emission of crowdsale
    uint256 private _hardcap; // (Tokens)

    // ending time
    uint256 private _endTime; // (UNIX)

    // states
    enum Reserving {OFF, ON}
    Reserving private _reserve = Reserving.OFF;

    enum State {Usual, Whitelist, PrivateSale, Closed}
    State public state = State.Usual;

    // events
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokensSent(address indexed sender, address indexed beneficiary, uint256 amount);
    event NewETHPrice(uint256 oldValue, uint256 newValue, uint256 decimals);
    event Payout(address indexed recipient, uint256 weiAmount, uint256 usdAmount);
    event BonusPayed(address indexed beneficiary, uint256 amount);
    event ReserveState(bool isActive);
    event StateChanged(string currentState);

    // time controller
    modifier active() {
        require(
            block.timestamp <= _endTime
            && _tokensPurchased < _hardcap
            && state != State.Closed
            );
        _;
    }

    // token admin checker
    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    /**
     * @dev constructor function, sets address of deployer.
     */
    constructor() public {
        _initAddress = msg.sender;
    }

    /**
     * @dev iniialize start variables.
     * Can be called once only by address who comitted deploy.
     */
    function init(
        uint256 rate,
        uint256 initialETHPrice,
        uint256 decimals,
        address payable wallet,
        address bonusAddr,
        address teamAddr,
        address payable exchange,
        IBBTZToken token,
        uint256 endTime,
        uint256 hardcap
        ) public {

        require(msg.sender == _initAddress);
        require(address(_token) == address(0));

        require(rate != 0, "Rate is 0");
        require(initialETHPrice != 0, "Initial ETH price is 0");
        require(wallet != address(0), "Wallet is the zero address");
        require(bonusAddr != address(0), "BonusAddr is the zero address");
        require(teamAddr != address(0), "TeamAddr is the zero address");
        require(isContract(address(token)), "Token is not a contract");
        require(isContract(exchange), "Exchange is not a contract");
        require(endTime != 0, "EndTime is 0");
        require(hardcap != 0, "HardCap is 0");


        _rate = rate;
        _currentETHPrice = initialETHPrice;
        _decimals = decimals;
        _wallet = wallet;
        _bonusAddr = bonusAddr;
        _teamAddr = teamAddr;
        _exchangeAddr = exchange;
        _token = token;
        _endTime = endTime;
        _hardcap = hardcap;
    }

    /**
     * @dev fallback function
     */
    function() external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev token purchase
     * This function has a non-reentrancy guard
     * Can be called only before end time
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public payable nonReentrant active {
        require(beneficiary != address(0), "New parameter value is the zero address");
        require(msg.value >= _minimum, "Wei amount is less than minimum");

        if (state == State.Whitelist) {
            require(isWhitelisted(beneficiary), "Beneficiary is not whitelisted");
        }

        if (state == State.PrivateSale) {
            require(isEnlisted(beneficiary), "Beneficiary is not enlisted");
        }

        uint256 weiAmount = msg.value;

        uint256 tokens = weiToTokens(weiAmount);

        uint256 bonusAmount = tokens.mul(_bonusPercent).div(10000);

        if (_tokensPurchased.add(tokens).add(bonusAmount) > _hardcap) {
            tokens = (_hardcap.sub(_tokensPurchased)).mul(10000).div(_bonusPercent.add(10000));
            bonusAmount = _hardcap.sub(_tokensPurchased).sub(tokens);
            weiAmount = tokensToWei(tokens);
            _sendETH(msg.sender, msg.value.sub(weiAmount));
        }

        if (bonusAmount > 0) {
            _token.mint(_bonusAddr, bonusAmount);
            emit BonusPayed(beneficiary, bonusAmount);
        }

        if (
            _tokensPurchased <= _reserveTrigger
            && _tokensPurchased.add(tokens) > _reserveTrigger
            && reserved() < _reserveLimit
            ) {
            _reserve = Reserving.ON;
            emit ReserveState(true);
            uint256 unreservedWei = tokensToWei(_reserveTrigger.sub(_tokensPurchased));
            _sendETH(_wallet, unreservedWei);
            refund(weiAmount.sub(unreservedWei));
        } else {
            refund(weiAmount);
        }

        _token.mint(beneficiary, tokens);

        _tokensPurchased = _tokensPurchased.add(tokens);
        _weiRaised = _weiRaised.add(weiAmount);

        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

    }

    /**
     * @dev internal Send tokens function.
     * @param recipient address to send tokens to.
     * @param amount amount of tokens.
     */
    function _sendTokens(address recipient, uint256 amount) internal {
        require(recipient != address(0), "Recipient is the zero address");
        _token.mint(recipient, amount);
        emit TokensSent(msg.sender, recipient, amount);
    }

    /**
     * @dev Send tokens to recipient.
     * Available only to the admin.
     * @param recipient address to send tokens to.
     * @param amount amount of tokens.
     */
    function sendTokens(address recipient, uint256 amount) public onlyAdmin {
        _sendTokens(recipient, amount);
        _tokensPurchased = _tokensPurchased.add(amount);
    }

    /**
     * @dev Send fixed amount of tokens to list of recipients.
     * Available only to the admin.
     * @param recipients addresses to send tokens to.
     * @param amount amount of tokens.
     */
    function sendTokensToList(address[] memory recipients, uint256 amount) public onlyAdmin {
        require(recipients.length > 0);
        for (uint256 i = 0; i < recipients.length; i++) {
            _sendTokens(recipients[i], amount);
        }
        _tokensPurchased = _tokensPurchased.add(amount.mul(recipients.length));
    }

    /**
     * @dev Send tokens to recipient per specified wei amount.
     * Available only to the admin.
     * @param recipient address to send tokens to.
     * @param weiAmount amount of wei.
     */
     function sendTokensPerWei(address recipient, uint256 weiAmount) public onlyAdmin {
         _sendTokens(recipient, weiToTokens(weiAmount));
         _tokensPurchased = _tokensPurchased.add(weiToTokens(weiAmount));
     }

     /**
      * @dev Send fixed amount of tokens per wei to list of recipients.
      * Available only to the admin.
      * @param recipients addresses to send tokens to.
      * @param weiAmount amount of wei.
      */
     function sendTokensPerWeiToList(address[] memory recipients, uint256 weiAmount) public onlyAdmin {
         require(recipients.length > 0);
         for (uint256 i = 0; i < recipients.length; i++) {
             _sendTokens(recipients[i], weiToTokens(weiAmount));
         }
         _tokensPurchased = _tokensPurchased.add(weiToTokens(weiAmount).mul(recipients.length));
     }

    /**
     * @dev internal function to allocate funds.
     */
     function refund(uint256 weiAmount) internal {
         if (_reserve == Reserving.OFF) {
             _sendETH(_wallet, weiAmount);
         } else {
             if (USDToWei(_reserveLimit) >= _reserved) {
                 if (weiToUSD(_reserved.add(weiAmount)) >= _reserveLimit) {

                     uint256 reservedWei = USDToWei(_reserveLimit).sub(_reserved);
                     _sendETH(_exchangeAddr, reservedWei);
                     uint256 unreservedWei = weiAmount.sub(reservedWei);
                     _sendETH(_wallet, unreservedWei);

                     _reserved = USDToWei(_reserveLimit);
                     _reserve = Reserving.OFF;
                     emit ReserveState(false);
                } else {
                     _reserved = _reserved.add(weiAmount);
                     _sendETH(_exchangeAddr, weiAmount);
                }
             } else {
                 _sendETH(_wallet, weiAmount);
                 _reserve = Reserving.OFF;
                 emit ReserveState(false);
             }
         }
     }

     function _sendETH(address payable recipient, uint256 weiAmount) internal {
         require(recipient != address(0));

         if (recipient == _exchangeAddr) {
             IExchange(_exchangeAddr).acceptETH.value(weiAmount)();
         } else {
             recipient.transfer(weiAmount);
         }

         emit Payout(recipient, weiAmount, weiToUSD(weiAmount));
     }

    /**
     * @dev finish crowdsale.
     * Available only to the admin.
     * Can be called only if hardcap is reached or ending time has passed.
     */
    function finishSale() public onlyAdmin {
        require(isEnded());

        _token.mint(IExchange(_exchangeAddr).reserveAddress(), _token.hardcap().sub(_token.totalSupply()));
        _token.lock(_teamAddr, _token.balanceOf(_teamAddr), 31536000);
        _token.release();
        IExchange(_exchangeAddr).finish();

        emit StateChanged("Usual");
        state = State.Usual;
    }

    /**
     * @dev Calculate amount of tokens to recieve for a given amount of wei
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified weiAmount
     */
    function weiToTokens(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(_currentETHPrice).mul(_rate).div(10**_decimals).div(1 ether);
    }

    /**
     * @dev Calculate amount of wei needed to buy given amount of tokens
     * @param tokenAmount amount of tokens
     * @return wei amount that one need to send to buy the specified tokenAmount
     */
    function tokensToWei(uint256 tokenAmount) internal view returns(uint256) {
        return tokenAmount.mul(1 ether).mul(10**_decimals).div(_rate).div(_currentETHPrice);
    }

    /**
     * @dev Calculate amount of USD for a given amount of wei
     * @param weiAmount amount of tokens
     * @return USD amount
     */
    function weiToUSD(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(_currentETHPrice).div(10**_decimals).div(1 ether);
    }

    /**
     * @dev Calculate amount of wei for given amount of USD
     * @param USDAmount amount of USD
     * @return wei amount
     */
    function USDToWei(uint256 USDAmount) internal view returns(uint256) {
        return USDAmount.mul(1 ether).mul(10**_decimals).div(_currentETHPrice);
    }

    /**
     * @dev Calculate amount of USD needed to buy given amount of tokens
     * @param tokenAmount amount of tokens
     * @return USD amount that one need to send to buy the specified tokenAmount
     */
    function tokensToUSD(uint256 tokenAmount) internal view returns(uint256) {
        return weiToUSD(tokensToWei(tokenAmount));
    }

    /**
     * @dev Function to change the rate.
     * Available only to the admin.
     * @param newRate new value.
     */
    function setRate(uint256 newRate) external onlyAdmin {
        require(newRate != 0, "New parameter value is 0");

        _rate = newRate;
    }

    /**
     * @dev Function to change the PriceProvider address.
     * Available only to the admin.
     * @param provider new address.
     */
    function setEthPriceProvider(address provider) external onlyAdmin {
        require(provider != address(0), "New parameter value is the zero address");
        require(isContract(provider));

        _priceProvider = provider;
    }

    /**
     * @dev Function to change the address to receive ether.
     * Available only to the admin.
     * @param newWallet new address.
     */
    function setWallet(address payable newWallet) external onlyAdmin {
        require(newWallet != address(0), "New parameter value is the zero address");

        _wallet = newWallet;
    }

    /**
     * @dev Function to change the BonusAddr address.
     * Available only to the admin.
     * @param newBonusAddr new address.
     */
    function setBonusAddr(address newBonusAddr) external onlyAdmin {
        require(newBonusAddr != address(0), "New parameter value is the zero address");

        _bonusAddr = newBonusAddr;
    }


    /**
     * @dev Function to change the address of team.
     * Available only to the admin.
     * @param newTeamAddr new address.
     */
    function setTeamAddr(address payable newTeamAddr) external onlyAdmin {
        require(newTeamAddr != address(0), "New parameter value is the zero address");

        _teamAddr = newTeamAddr;
    }

    /**
     * @dev Function to change the Exchange address.
     * Available only to the admin.
     * @param newExchange new address.
     */
    function setExchangeAddr(address payable newExchange) external onlyAdmin {
        require(newExchange != address(0), "New parameter value is the zero address");
        require(isContract(newExchange), "Exchange is not a contract");

        _exchangeAddr = newExchange;
    }

    /**
     * @dev Function to change the ETH Price.
     * Available only to the admin and to the PriceProvider.
     * @param newPrice amount of USD Cents for 1 ether.
     */
    function setETHPrice(uint256 newPrice) external {
        require(newPrice != 0, "New parameter value is 0");
        require(msg.sender == _priceProvider || isAdmin(msg.sender), "Sender has no permission");

        emit NewETHPrice(_currentETHPrice, newPrice, _decimals);
        _currentETHPrice = newPrice;
    }

    /**
     * @dev Function to change the USD decimals.
     * Available only to the admin and to the PriceProvider.
     * @param newDecimals amount of numbers after decimal point.
     */
    function setDecimals(uint256 newDecimals) external {
        require(msg.sender == _priceProvider || isAdmin(msg.sender), "Sender has no permission");

        _decimals = newDecimals;
    }

    /**
     * @dev Function to change the end time.
     * Available only to the admin.
     * @param newTime UNIX time of ending of crowdsale.
     */
    function setEndTime(uint256 newTime) external onlyAdmin {
        require(newTime != 0, "New parameter value is 0");

        _endTime = newTime;
    }

    /**
     * @dev Function to change the bonus percent.
     * Available only to the admin.
     * @param newPercent new bonus percent.
     */
    function setBonusPercent(uint256 newPercent) external onlyAdmin {

        _bonusPercent = newPercent;
    }

    /**
     * @dev Function to change the hardcap.
     * Available only to the admin.
     * @param newCap new hardcap value.
     */
    function setHardCap(uint256 newCap) external onlyAdmin {
        require(newCap != 0, "New parameter value is 0");

        _hardcap = newCap;
    }

    /**
     * @dev Function to change the minimum amount (wei).
     * Available only to the admin.
     * @param newMinimum new minimum value (wei).
     */
    function setMinimum(uint256 newMinimum) external onlyAdmin {
        require(newMinimum != 0, "New parameter value is 0");

        _minimum = newMinimum;
    }

    /**
     * @dev Function to change the reserve Limit (USD).
     * Available only to the admin.
     * @param newResLimitUSD new value (USD).
     */
    function setReserveLimit(uint256 newResLimitUSD) external onlyAdmin {
        require(newResLimitUSD != 0, "New parameter value is 0");

        _reserveLimit = newResLimitUSD;
    }

    /**
     * @dev Function to change the reserve trigger value (tokens).
     * Available only to the admin.
     * @param newReserveTrigger new value (tokens).
     */
    function setReserveTrigger(uint256 newReserveTrigger) external onlyAdmin {
        require(newReserveTrigger != 0, "New parameter value is 0");

        _reserveTrigger = newReserveTrigger;
    }

    /**
     * @dev Function to change activate whitelist state.
     * Available only to the admin.
     */
    function switchWhitelist() external onlyAdmin {
        require(state != State.Whitelist);
        emit StateChanged("Whitelist");
        state = State.Whitelist;
    }

    /**
     * @dev Function to change activate private sale state.
     * Available only to the admin.
     */
    function switchPrivateSale() external onlyAdmin {
        require(state != State.PrivateSale);
        emit StateChanged("PrivateSale");
        state = State.PrivateSale;
    }

    /**
     * @dev Function to change activate closed state.
     * Available only to the admin.
     */
    function switchClosed() external onlyAdmin {
        require(state != State.Closed);
        emit StateChanged("Closed");
        state = State.Closed;
    }

    /**
     * @dev Function to change activate usual state.
     * Available only to the admin.
     */
    function switchUsual() external onlyAdmin {
        require(state != State.Usual);
        emit StateChanged("Usual");
        state = State.Usual;
    }

    /**
    * @dev Allows to any owner of the contract withdraw needed ERC20 token from this contract (promo or bounties for example).
    * @param ERC20Token Address of ERC20 token.
    * @param recipient Account to receive tokens.
    */
    function withdrawERC20(address ERC20Token, address recipient) external onlyAdmin {

        uint256 amount = IBBTZToken(ERC20Token).balanceOf(address(this));
        require(amount > 0);
        IBBTZToken(ERC20Token).transfer(recipient, amount);

    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IBBTZToken) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the bonus address where bonuses are collected.
     */
    function bonusAddr() public view returns (address) {
        return _bonusAddr;
    }

    /**
     * @return the address where funds are collected.
     */
    function teamAddr() public view returns (address) {
        return _teamAddr;
    }

    /**
     * @return the address of exchange contract.
     */
    function exchange() public view returns (address payable) {
        return _exchangeAddr;
    }

    /**
     * @return the priceProvider address.
     */
    function priceProvider() public view returns (address) {
        return _priceProvider;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the price of 1 ether in USD Cents.
     */
    function currentETHPrice() public view returns (uint256 price) {
        return(_currentETHPrice);
    }

    /**
     * @return the the number of decimals of ETH Price.
     */
    function currentETHPriceDecimals() public view returns (uint256 decimals) {
        return(_decimals);
    }

    /**
     * @return bonusPercent.
     */
    function bonusPercent() public view returns (uint256) {
        return _bonusPercent;
    }

    /**
     * @return minimum amount of wei to invest.
     */
    function minimum() public view returns (uint256) {
        return _minimum;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return the reserved amount of ETH in USD.
     */
    function reserved() public view returns (uint256) {
        return weiToUSD(_reserved);
    }

    /**
     * @return the reserved limit in USD.
     */
    function reserveLimit() public view returns (uint256) {
        return _reserveLimit;
    }

    /**
     * @return the reserved limit in USD.
     */
    function reserveTrigger() public view returns (uint256) {
        return _reserveTrigger;
    }

    /**
     * @return the hardcap.
     */
    function hardcap() public view returns (uint256) {
        return _hardcap;
    }

    /**
     * @return the ending UNIX time.
     */
    function endTime() public view returns (uint256) {
        return _endTime;
    }

    /**
     * @return the amount of purchased tokens.
     */
    function tokensPurchased() public view returns (uint256) {
        return _tokensPurchased;
    }

    /**
     * @return true if caller is owner.
     */
    function isOwner(address account) internal view returns (bool) {
        return _token.isOwner(account);
    }

    /**
     * @return true if caller is admin.
     */
    function isAdmin(address account) internal view returns (bool) {
        return _token.isAdmin(account);
    }

    /**
     * @return true if the address is a сontract.
     */
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /**
     * @return true if hardcap is reached or endtime has passed.
     */
    function isEnded() public view returns (bool) {
        return (_tokensPurchased >= _hardcap || block.timestamp >= _endTime);
    }

}