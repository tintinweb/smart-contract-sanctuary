pragma solidity ^0.4.21;

// File: contracts/ISimpleCrowdsale.sol

interface ISimpleCrowdsale {
    function getSoftCap() external view returns(uint256);
    function isContributorInLists(address contributorAddress) external view returns(bool);
    function processReservationFundContribution(
        address contributor,
        uint256 tokenAmount,
        uint256 tokenBonusAmount
    ) external payable;
}

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract.
    */
    function Ownable(address _owner) public {
        owner = _owner == address(0) ? msg.sender : _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
    * @dev confirm ownership by a new owner
    */
    function confirmOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

// File: contracts/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

// File: contracts/fund/ICrowdsaleFund.sol

/**
 * @title ICrowdsaleFund
 * @dev Fund methods used by crowdsale contract
 */
interface ICrowdsaleFund {
    /**
    * @dev Function accepts user`s contributed ether and logs contribution
    * @param contributor Contributor wallet address.
    */
    function processContribution(address contributor) external payable;
    /**
    * @dev Function is called on the end of successful crowdsale
    */
    function onCrowdsaleEnd() external;
    /**
    * @dev Function is called if crowdsale failed to reach soft cap
    */
    function enableCrowdsaleRefund() external;
}

// File: contracts/fund/ICrowdsaleReservationFund.sol

/**
 * @title ICrowdsaleReservationFund
 * @dev ReservationFund methods used by crowdsale contract
 */
interface ICrowdsaleReservationFund {
    /**
     * @dev Check if contributor has transactions
     */
    function canCompleteContribution(address contributor) external returns(bool);
    /**
     * @dev Complete contribution
     * @param contributor Contributor`s address
     */
    function completeContribution(address contributor) external;
    /**
     * @dev Function accepts user`s contributed ether and amount of tokens to issue
     * @param contributor Contributor wallet address.
     * @param _tokensToIssue Token amount to issue
     * @param _bonusTokensToIssue Bonus token amount to issue
     */
    function processContribution(address contributor, uint256 _tokensToIssue, uint256 _bonusTokensToIssue) external payable;

    /**
     * @dev Function returns current user`s contributed ether amount
     */
    function contributionsOf(address contributor) external returns(uint256);

    /**
     * @dev Function is called on the end of successful crowdsale
     */
    function onCrowdsaleEnd() external;
}

// File: contracts/token/IERC20Token.sol

/**
 * @title IERC20Token - ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value)  public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success);
    function approve(address _spender, uint256 _value)  public returns (bool success);
    function allowance(address _owner, address _spender)  public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
    /**
    * @dev constructor
    */
    function SafeMath() public {
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/token/LockedTokens.sol

/**
 * @title LockedTokens
 * @dev Lock tokens for certain period of time
 */
contract LockedTokens is SafeMath {
    struct Tokens {
        uint256 amount;
        uint256 lockEndTime;
        bool released;
    }

    event TokensUnlocked(address _to, uint256 _value);

    IERC20Token public token;
    address public crowdsaleAddress;
    mapping(address => Tokens[]) public walletTokens;

    /**
     * @dev LockedTokens constructor
     * @param _token ERC20 compatible token contract
     * @param _crowdsaleAddress Crowdsale contract address
     */
    function LockedTokens(IERC20Token _token, address _crowdsaleAddress) public {
        token = _token;
        crowdsaleAddress = _crowdsaleAddress;
    }

    /**
     * @dev Functions locks tokens
     * @param _to Wallet address to transfer tokens after _lockEndTime
     * @param _amount Amount of tokens to lock
     * @param _lockEndTime End of lock period
     */
    function addTokens(address _to, uint256 _amount, uint256 _lockEndTime) external {
        require(msg.sender == crowdsaleAddress);
        walletTokens[_to].push(Tokens({amount: _amount, lockEndTime: _lockEndTime, released: false}));
    }

    /**
     * @dev Called by owner of locked tokens to release them
     */
    function releaseTokens() public {
        require(walletTokens[msg.sender].length > 0);

        for(uint256 i = 0; i < walletTokens[msg.sender].length; i++) {
            if(!walletTokens[msg.sender][i].released && now >= walletTokens[msg.sender][i].lockEndTime) {
                walletTokens[msg.sender][i].released = true;
                token.transfer(msg.sender, walletTokens[msg.sender][i].amount);
                TokensUnlocked(msg.sender, walletTokens[msg.sender][i].amount);
            }
        }
    }
}

// File: contracts/ownership/MultiOwnable.sol

/**
 * @title MultiOwnable
 * @dev The MultiOwnable contract has owners addresses and provides basic authorization control
 * functions, this simplifies the implementation of "users permissions".
 */
contract MultiOwnable {
    address public manager; // address used to set owners
    address[] public owners;
    mapping(address => bool) public ownerByAddress;

    event SetOwners(address[] owners);

    modifier onlyOwner() {
        require(ownerByAddress[msg.sender] == true);
        _;
    }

    /**
     * @dev MultiOwnable constructor sets the manager
     */
    function MultiOwnable() public {
        manager = msg.sender;
    }

    /**
     * @dev Function to set owners addresses
     */
    function setOwners(address[] _owners) public {
        require(msg.sender == manager);
        _setOwners(_owners);

    }

    function _setOwners(address[] _owners) internal {
        for(uint256 i = 0; i < owners.length; i++) {
            ownerByAddress[owners[i]] = false;
        }


        for(uint256 j = 0; j < _owners.length; j++) {
            ownerByAddress[_owners[j]] = true;
        }
        owners = _owners;
        SetOwners(_owners);
    }

    function getOwners() public constant returns (address[]) {
        return owners;
    }
}

// File: contracts/token/ERC20Token.sol

/**
 * @title ERC20Token - ERC20 base implementation
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Token is IERC20Token, SafeMath {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
      return allowed[_owner][_spender];
    }
}

// File: contracts/token/ITokenEventListener.sol

/**
 * @title ITokenEventListener
 * @dev Interface which should be implemented by token listener
 */
interface ITokenEventListener {
    /**
     * @dev Function is called after token transfer/transferFrom
     * @param _from Sender address
     * @param _to Receiver address
     * @param _value Amount of tokens
     */
    function onTokenTransfer(address _from, address _to, uint256 _value) external;
}

// File: contracts/token/ManagedToken.sol

/**
 * @title ManagedToken
 * @dev ERC20 compatible token with issue and destroy facilities
 * @dev All transfers can be monitored by token event listener
 */
contract ManagedToken is ERC20Token, MultiOwnable {
    bool public allowTransfers = false;
    bool public issuanceFinished = false;

    ITokenEventListener public eventListener;

    event AllowTransfersChanged(bool _newState);
    event Issue(address indexed _to, uint256 _value);
    event Destroy(address indexed _from, uint256 _value);
    event IssuanceFinished();

    modifier transfersAllowed() {
        require(allowTransfers);
        _;
    }

    modifier canIssue() {
        require(!issuanceFinished);
        _;
    }

    /**
     * @dev ManagedToken constructor
     * @param _listener Token listener(address can be 0x0)
     * @param _owners Owners list
     */
    function ManagedToken(address _listener, address[] _owners) public {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        }
        _setOwners(_owners);
    }

    /**
     * @dev Enable/disable token transfers. Can be called only by owners
     * @param _allowTransfers True - allow False - disable
     */
    function setAllowTransfers(bool _allowTransfers) external onlyOwner {
        allowTransfers = _allowTransfers;
        AllowTransfersChanged(_allowTransfers);
    }

    /**
     * @dev Set/remove token event listener
     * @param _listener Listener address (Contract must implement ITokenEventListener interface)
     */
    function setListener(address _listener) public onlyOwner {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        } else {
            delete eventListener;
        }
    }

    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transfer(_to, _value);
        if(hasListener() && success) {
            eventListener.onTokenTransfer(msg.sender, _to, _value);
        }
        return success;
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transferFrom(_from, _to, _value);
        if(hasListener() && success) {
            eventListener.onTokenTransfer(_from, _to, _value);
        }
        return success;
    }

    function hasListener() internal view returns(bool) {
        if(eventListener == address(0)) {
            return false;
        }
        return true;
    }

    /**
     * @dev Issue tokens to specified wallet
     * @param _to Wallet address
     * @param _value Amount of tokens
     */
    function issue(address _to, uint256 _value) external onlyOwner canIssue {
        totalSupply = safeAdd(totalSupply, _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Issue(_to, _value);
        Transfer(address(0), _to, _value);
    }

    /**
     * @dev Destroy tokens on specified address (Called by owner or token holder)
     * @dev Fund contract address must be in the list of owners to burn token during refund
     * @param _from Wallet address
     * @param _value Amount of tokens to destroy
     */
    function destroy(address _from, uint256 _value) external {
        require(ownerByAddress[msg.sender] || msg.sender == _from);
        require(balances[_from] >= _value);
        totalSupply = safeSub(totalSupply, _value);
        balances[_from] = safeSub(balances[_from], _value);
        Transfer(_from, address(0), _value);
        Destroy(_from, _value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From OpenZeppelin StandardToken.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From OpenZeppelin StandardToken.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Finish token issuance
     * @return True if success
     */
    function finishIssuance() public onlyOwner returns (bool) {
        issuanceFinished = true;
        IssuanceFinished();
        return true;
    }
}

// File: contracts/token/TransferLimitedToken.sol

/**
 * @title TransferLimitedToken
 * @dev Token with ability to limit transfers within wallets included in limitedWallets list for certain period of time
 */
contract TransferLimitedToken is ManagedToken {
    uint256 public constant LIMIT_TRANSFERS_PERIOD = 365 days;

    mapping(address => bool) public limitedWallets;
    uint256 public limitEndDate;
    address public limitedWalletsManager;
    bool public isLimitEnabled;

    modifier onlyManager() {
        require(msg.sender == limitedWalletsManager);
        _;
    }

    /**
     * @dev Check if transfer between addresses is available
     * @param _from From address
     * @param _to To address
     */
    modifier canTransfer(address _from, address _to)  {
        require(now >= limitEndDate || !isLimitEnabled || (!limitedWallets[_from] && !limitedWallets[_to]));
        _;
    }

    /**
     * @dev TransferLimitedToken constructor
     * @param _limitStartDate Limit start date
     * @param _listener Token listener(address can be 0x0)
     * @param _owners Owners list
     * @param _limitedWalletsManager Address used to add/del wallets from limitedWallets
     */
    function TransferLimitedToken(
        uint256 _limitStartDate,
        address _listener,
        address[] _owners,
        address _limitedWalletsManager
    ) public ManagedToken(_listener, _owners)
    {
        limitEndDate = _limitStartDate + LIMIT_TRANSFERS_PERIOD;
        isLimitEnabled = true;
        limitedWalletsManager = _limitedWalletsManager;
    }

    /**
     * @dev Add address to limitedWallets
     * @dev Can be called only by manager
     */
    function addLimitedWalletAddress(address _wallet) public {
        require(msg.sender == limitedWalletsManager || ownerByAddress[msg.sender]);
        limitedWallets[_wallet] = true;
    }

    /**
     * @dev Del address from limitedWallets
     * @dev Can be called only by manager
     */
    function delLimitedWalletAddress(address _wallet) public onlyManager {
        limitedWallets[_wallet] = false;
    }

    /**
     * @dev Disable transfer limit manually. Can be called only by manager
     */
    function disableLimit() public onlyManager {
        isLimitEnabled = false;
    }

    function transfer(address _to, uint256 _value) public canTransfer(msg.sender, _to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfer(_from, _to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public canTransfer(msg.sender, _spender) returns (bool) {
        return super.approve(_spender,_value);
    }
}

// File: contracts/Crowdsale.sol

contract TheAbyssDAICO is Ownable, SafeMath, Pausable, ISimpleCrowdsale {
    enum AdditionalBonusState {
        Unavailable,
        Active,
        Applied
    }

    uint256 public constant ADDITIONAL_BONUS_NUM = 3;
    uint256 public constant ADDITIONAL_BONUS_DENOM = 100;

    uint256 public constant ETHER_MIN_CONTRIB = 0.2 ether;
    uint256 public constant ETHER_MAX_CONTRIB = 20 ether;

    uint256 public constant ETHER_MIN_CONTRIB_PRIVATE = 100 ether;
    uint256 public constant ETHER_MAX_CONTRIB_PRIVATE = 3000 ether;

    uint256 public constant ETHER_MIN_CONTRIB_USA = 0.2 ether;
    uint256 public constant ETHER_MAX_CONTRIB_USA = 20 ether;

    uint256 public constant SALE_START_TIME = 1523887200; // 16.04.2018 14:00:00 UTC
    uint256 public constant SALE_END_TIME = 1526479200; // 16.05.2018 14:00:00 UTC

    uint256 public constant BONUS_WINDOW_1_END_TIME = SALE_START_TIME + 2 days;
    uint256 public constant BONUS_WINDOW_2_END_TIME = SALE_START_TIME + 7 days;
    uint256 public constant BONUS_WINDOW_3_END_TIME = SALE_START_TIME + 14 days;
    uint256 public constant BONUS_WINDOW_4_END_TIME = SALE_START_TIME + 21 days;

    uint256 public constant MAX_CONTRIB_CHECK_END_TIME = SALE_START_TIME + 1 days;

    uint256 public constant BNB_TOKEN_PRICE_NUM = 169;
    uint256 public constant BNB_TOKEN_PRICE_DENOM = 1;

    uint256 public tokenPriceNum = 0;
    uint256 public tokenPriceDenom = 0;
    
    TransferLimitedToken public token;
    ICrowdsaleFund public fund;
    ICrowdsaleReservationFund public reservationFund;
    LockedTokens public lockedTokens;

    mapping(address => bool) public whiteList;
    mapping(address => bool) public privilegedList;
    mapping(address => AdditionalBonusState) public additionalBonusOwnerState;
    mapping(address => uint256) public userTotalContributed;

    address public bnbTokenWallet;
    address public referralTokenWallet;
    address public foundationTokenWallet;
    address public advisorsTokenWallet;
    address public companyTokenWallet;
    address public reserveTokenWallet;
    address public bountyTokenWallet;

    uint256 public totalEtherContributed = 0;
    uint256 public rawTokenSupply = 0;

    // BNB
    IERC20Token public bnbToken;
    uint256 public BNB_HARD_CAP = 300000 ether; // 300K BNB
    uint256 public BNB_MIN_CONTRIB = 1000 ether; // 1K BNB
    mapping(address => uint256) public bnbContributions;
    uint256 public totalBNBContributed = 0;

    uint256 public hardCap = 0; // World hard cap will be set right before Token Sale
    uint256 public softCap = 0; // World soft cap will be set right before Token Sale

    bool public bnbRefundEnabled = false;

    event LogContribution(address contributor, uint256 amountWei, uint256 tokenAmount, uint256 tokenBonus, bool additionalBonusApplied, uint256 timestamp);
    event ReservationFundContribution(address contributor, uint256 amountWei, uint256 tokensToIssue, uint256 bonusTokensToIssue, uint256 timestamp);
    event LogBNBContribution(address contributor, uint256 amountBNB, uint256 tokenAmount, uint256 tokenBonus, bool additionalBonusApplied, uint256 timestamp);

    modifier checkContribution() {
        require(isValidContribution());
        _;
    }

    modifier checkBNBContribution() {
        require(isValidBNBContribution());
        _;
    }

    modifier checkCap() {
        require(validateCap());
        _;
    }

    modifier checkTime() {
        require(now >= SALE_START_TIME && now <= SALE_END_TIME);
        _;
    }

    function TheAbyssDAICO(
        address bnbTokenAddress,
        address tokenAddress,
        address fundAddress,
        address reservationFundAddress,
        address _bnbTokenWallet,
        address _referralTokenWallet,
        address _foundationTokenWallet,
        address _advisorsTokenWallet,
        address _companyTokenWallet,
        address _reserveTokenWallet,
        address _bountyTokenWallet,
        address _owner
    ) public
        Ownable(_owner)
    {
        require(tokenAddress != address(0));

        bnbToken = IERC20Token(bnbTokenAddress);
        token = TransferLimitedToken(tokenAddress);
        fund = ICrowdsaleFund(fundAddress);
        reservationFund = ICrowdsaleReservationFund(reservationFundAddress);

        bnbTokenWallet = _bnbTokenWallet;
        referralTokenWallet = _referralTokenWallet;
        foundationTokenWallet = _foundationTokenWallet;
        advisorsTokenWallet = _advisorsTokenWallet;
        companyTokenWallet = _companyTokenWallet;
        reserveTokenWallet = _reserveTokenWallet;
        bountyTokenWallet = _bountyTokenWallet;
    }

    /**
     * @dev check if address can contribute
     */
    function isContributorInLists(address contributor) external view returns(bool) {
        return whiteList[contributor] || privilegedList[contributor] || token.limitedWallets(contributor);
    }

    /**
     * @dev check contribution amount and time
     */
    function isValidContribution() internal view returns(bool) {
        uint256 currentUserContribution = safeAdd(msg.value, userTotalContributed[msg.sender]);
        if(whiteList[msg.sender] && msg.value >= ETHER_MIN_CONTRIB) {
            if(now <= MAX_CONTRIB_CHECK_END_TIME && currentUserContribution > ETHER_MAX_CONTRIB ) {
                    return false;
            }
            return true;

        }
        if(privilegedList[msg.sender] && msg.value >= ETHER_MIN_CONTRIB_PRIVATE) {
            if(now <= MAX_CONTRIB_CHECK_END_TIME && currentUserContribution > ETHER_MAX_CONTRIB_PRIVATE ) {
                    return false;
            }
            return true;
        }

        if(token.limitedWallets(msg.sender) && msg.value >= ETHER_MIN_CONTRIB_USA) {
            if(now <= MAX_CONTRIB_CHECK_END_TIME && currentUserContribution > ETHER_MAX_CONTRIB_USA) {
                    return false;
            }
            return true;
        }

        return false;
    }

    /**
     * @dev Check hard cap overflow
     */
    function validateCap() internal view returns(bool){
        if(msg.value <= safeSub(hardCap, totalEtherContributed)) {
            return true;
        }
        return false;
    }

    /**
     * @dev Set token price once before start of crowdsale
     */
    function setTokenPrice(uint256 _tokenPriceNum, uint256 _tokenPriceDenom) public onlyOwner {
        require(tokenPriceNum == 0 && tokenPriceDenom == 0);
        require(_tokenPriceNum > 0 && _tokenPriceDenom > 0);
        tokenPriceNum = _tokenPriceNum;
        tokenPriceDenom = _tokenPriceDenom;
    }

    /**
     * @dev Set hard cap.
     * @param _hardCap - Hard cap value
     */
    function setHardCap(uint256 _hardCap) public onlyOwner {
        require(hardCap == 0);
        hardCap = _hardCap;
    }

    /**
     * @dev Set soft cap.
     * @param _softCap - Soft cap value
     */
    function setSoftCap(uint256 _softCap) public onlyOwner {
        require(softCap == 0);
        softCap = _softCap;
    }

    /**
     * @dev Get soft cap amount
     **/
    function getSoftCap() external view returns(uint256) {
        return softCap;
    }

    /**
     * @dev Check bnb contribution time, amount and hard cap overflow
     */
    function isValidBNBContribution() internal view returns(bool) {
        if(token.limitedWallets(msg.sender)) {
            return false;
        }
        if(!whiteList[msg.sender] && !privilegedList[msg.sender]) {
            return false;
        }
        uint256 amount = bnbToken.allowance(msg.sender, address(this));
        if(amount < BNB_MIN_CONTRIB || safeAdd(totalBNBContributed, amount) > BNB_HARD_CAP) {
            return false;
        }
        return true;

    }

    /**
     * @dev Calc bonus amount by contribution time
     */
    function getBonus() internal constant returns (uint256, uint256) {
        uint256 numerator = 0;
        uint256 denominator = 100;

        if(now < BONUS_WINDOW_1_END_TIME) {
            numerator = 25;
        } else if(now < BONUS_WINDOW_2_END_TIME) {
            numerator = 15;
        } else if(now < BONUS_WINDOW_3_END_TIME) {
            numerator = 10;
        } else if(now < BONUS_WINDOW_4_END_TIME) {
            numerator = 5;
        } else {
            numerator = 0;
        }

        return (numerator, denominator);
    }

    function addToLists(
        address _wallet,
        bool isInWhiteList,
        bool isInPrivilegedList,
        bool isInLimitedList,
        bool hasAdditionalBonus
    ) public onlyOwner {
        if(isInWhiteList) {
            whiteList[_wallet] = true;
        }
        if(isInPrivilegedList) {
            privilegedList[_wallet] = true;
        }
        if(isInLimitedList) {
            token.addLimitedWalletAddress(_wallet);
        }
        if(hasAdditionalBonus) {
            additionalBonusOwnerState[_wallet] = AdditionalBonusState.Active;
        }
        if(reservationFund.canCompleteContribution(_wallet)) {
            reservationFund.completeContribution(_wallet);
        }
    }

    /**
     * @dev Add wallet to whitelist. For contract owner only.
     */
    function addToWhiteList(address _wallet) public onlyOwner {
        whiteList[_wallet] = true;
    }

    /**
     * @dev Add wallet to additional bonus members. For contract owner only.
     */
    function addAdditionalBonusMember(address _wallet) public onlyOwner {
        additionalBonusOwnerState[_wallet] = AdditionalBonusState.Active;
    }

    /**
     * @dev Add wallet to privileged list. For contract owner only.
     */
    function addToPrivilegedList(address _wallet) public onlyOwner {
        privilegedList[_wallet] = true;
    }

    /**
     * @dev Set LockedTokens contract address
     */
    function setLockedTokens(address lockedTokensAddress) public onlyOwner {
        lockedTokens = LockedTokens(lockedTokensAddress);
    }

    /**
     * @dev Fallback function to receive ether contributions
     */
    function () payable public whenNotPaused {
        if(whiteList[msg.sender] || privilegedList[msg.sender] || token.limitedWallets(msg.sender)) {
            processContribution(msg.sender, msg.value);
        } else {
            processReservationContribution(msg.sender, msg.value);
        }
    }

    function processReservationContribution(address contributor, uint256 amount) private checkTime checkCap {
        require(amount >= ETHER_MIN_CONTRIB);

        if(now <= MAX_CONTRIB_CHECK_END_TIME) {
            uint256 currentUserContribution = safeAdd(amount, reservationFund.contributionsOf(contributor));
            require(currentUserContribution <= ETHER_MAX_CONTRIB);
        }
        uint256 bonusNum = 0;
        uint256 bonusDenom = 100;
        (bonusNum, bonusDenom) = getBonus();
        uint256 tokenBonusAmount = 0;
        uint256 tokenAmount = safeDiv(safeMul(amount, tokenPriceNum), tokenPriceDenom);

        if(bonusNum > 0) {
            tokenBonusAmount = safeDiv(safeMul(tokenAmount, bonusNum), bonusDenom);
        }

        reservationFund.processContribution.value(amount)(
            contributor,
            tokenAmount,
            tokenBonusAmount
        );
        ReservationFundContribution(contributor, amount, tokenAmount, tokenBonusAmount, now);
    }

    /**
     * @dev Process BNB token contribution
     * Transfer all amount of tokens approved by sender. Calc bonuses and issue tokens to contributor.
     */
    function processBNBContribution() public whenNotPaused checkTime checkBNBContribution {
        bool additionalBonusApplied = false;
        uint256 bonusNum = 0;
        uint256 bonusDenom = 100;
        (bonusNum, bonusDenom) = getBonus();
        uint256 amountBNB = bnbToken.allowance(msg.sender, address(this));
        bnbToken.transferFrom(msg.sender, address(this), amountBNB);
        bnbContributions[msg.sender] = safeAdd(bnbContributions[msg.sender], amountBNB);

        uint256 tokenBonusAmount = 0;
        uint256 tokenAmount = safeDiv(safeMul(amountBNB, BNB_TOKEN_PRICE_NUM), BNB_TOKEN_PRICE_DENOM);
        rawTokenSupply = safeAdd(rawTokenSupply, tokenAmount);
        if(bonusNum > 0) {
            tokenBonusAmount = safeDiv(safeMul(tokenAmount, bonusNum), bonusDenom);
        }

        if(additionalBonusOwnerState[msg.sender] ==  AdditionalBonusState.Active) {
            additionalBonusOwnerState[msg.sender] = AdditionalBonusState.Applied;
            uint256 additionalBonus = safeDiv(safeMul(tokenAmount, ADDITIONAL_BONUS_NUM), ADDITIONAL_BONUS_DENOM);
            tokenBonusAmount = safeAdd(tokenBonusAmount, additionalBonus);
            additionalBonusApplied = true;
        }

        uint256 tokenTotalAmount = safeAdd(tokenAmount, tokenBonusAmount);
        token.issue(msg.sender, tokenTotalAmount);
        totalBNBContributed = safeAdd(totalBNBContributed, amountBNB);

        LogBNBContribution(msg.sender, amountBNB, tokenAmount, tokenBonusAmount, additionalBonusApplied, now);
    }

    /**
     * @dev Process ether contribution. Calc bonuses and issue tokens to contributor.
     */
    function processContribution(address contributor, uint256 amount) private checkTime checkContribution checkCap {
        bool additionalBonusApplied = false;
        uint256 bonusNum = 0;
        uint256 bonusDenom = 100;
        (bonusNum, bonusDenom) = getBonus();
        uint256 tokenBonusAmount = 0;

        uint256 tokenAmount = safeDiv(safeMul(amount, tokenPriceNum), tokenPriceDenom);
        rawTokenSupply = safeAdd(rawTokenSupply, tokenAmount);

        if(bonusNum > 0) {
            tokenBonusAmount = safeDiv(safeMul(tokenAmount, bonusNum), bonusDenom);
        }

        if(additionalBonusOwnerState[contributor] ==  AdditionalBonusState.Active) {
            additionalBonusOwnerState[contributor] = AdditionalBonusState.Applied;
            uint256 additionalBonus = safeDiv(safeMul(tokenAmount, ADDITIONAL_BONUS_NUM), ADDITIONAL_BONUS_DENOM);
            tokenBonusAmount = safeAdd(tokenBonusAmount, additionalBonus);
            additionalBonusApplied = true;
        }

        processPayment(contributor, amount, tokenAmount, tokenBonusAmount, additionalBonusApplied);
    }

    /**
     * @dev Process ether contribution before KYC. Calc bonuses and tokens to issue after KYC.
     */
    function processReservationFundContribution(
        address contributor,
        uint256 tokenAmount,
        uint256 tokenBonusAmount
    ) external payable checkCap {
        require(msg.sender == address(reservationFund));
        require(msg.value > 0);

        processPayment(contributor, msg.value, tokenAmount, tokenBonusAmount, false);
    }

    function processPayment(address contributor, uint256 etherAmount, uint256 tokenAmount, uint256 tokenBonusAmount, bool additionalBonusApplied) internal {
        uint256 tokenTotalAmount = safeAdd(tokenAmount, tokenBonusAmount);

        token.issue(contributor, tokenTotalAmount);
        fund.processContribution.value(etherAmount)(contributor);
        totalEtherContributed = safeAdd(totalEtherContributed, etherAmount);
        userTotalContributed[contributor] = safeAdd(userTotalContributed[contributor], etherAmount);
        LogContribution(contributor, etherAmount, tokenAmount, tokenBonusAmount, additionalBonusApplied, now);
    }

    /**
     * @dev Finalize crowdsale if we reached hard cap or current time > SALE_END_TIME
     */
    function finalizeCrowdsale() public onlyOwner {
        if(
            (totalEtherContributed >= safeSub(hardCap, 20 ether) && totalBNBContributed >= safeSub(BNB_HARD_CAP, 10000 ether)) ||
            (now >= SALE_END_TIME && totalEtherContributed >= softCap)
        ) {
            fund.onCrowdsaleEnd();
            reservationFund.onCrowdsaleEnd();
            // BNB transfer
            bnbToken.transfer(bnbTokenWallet, bnbToken.balanceOf(address(this)));

            // Referral
            uint256 referralTokenAmount = safeDiv(rawTokenSupply, 10);
            token.issue(referralTokenWallet, referralTokenAmount);

            // Foundation
            uint256 foundationTokenAmount = safeDiv(token.totalSupply(), 2); // 20%
            lockedTokens.addTokens(foundationTokenWallet, foundationTokenAmount, now + 365 days);

            uint256 suppliedTokenAmount = token.totalSupply();

            // Reserve
            uint256 reservedTokenAmount = safeDiv(safeMul(suppliedTokenAmount, 3), 10); // 18%
            token.issue(address(lockedTokens), reservedTokenAmount);
            lockedTokens.addTokens(reserveTokenWallet, reservedTokenAmount, now + 183 days);

            // Advisors
            uint256 advisorsTokenAmount = safeDiv(suppliedTokenAmount, 10); // 6%
            token.issue(advisorsTokenWallet, advisorsTokenAmount);

            // Company
            uint256 companyTokenAmount = safeDiv(suppliedTokenAmount, 4); // 15%
            token.issue(address(lockedTokens), companyTokenAmount);
            lockedTokens.addTokens(companyTokenWallet, companyTokenAmount, now + 730 days);

            // Bounty
            uint256 bountyTokenAmount = safeDiv(suppliedTokenAmount, 60); // 1%
            token.issue(bountyTokenWallet, bountyTokenAmount);

            token.setAllowTransfers(true);

        } else if(now >= SALE_END_TIME) {
            // Enable fund`s crowdsale refund if soft cap is not reached
            fund.enableCrowdsaleRefund();
            reservationFund.onCrowdsaleEnd();
            bnbRefundEnabled = true;
        }
        token.finishIssuance();
    }

    /**
     * @dev Function is called by contributor to refund BNB token payments if crowdsale failed to reach soft cap
     */
    function refundBNBContributor() public {
        require(bnbRefundEnabled);
        require(bnbContributions[msg.sender] > 0);
        uint256 amount = bnbContributions[msg.sender];
        bnbContributions[msg.sender] = 0;
        bnbToken.transfer(msg.sender, amount);
        token.destroy(msg.sender, token.balanceOf(msg.sender));
    }
}