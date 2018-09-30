pragma solidity ^0.4.25;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
        return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


/**
 * @title Currency exchange rate contract
 */
contract CurrencyExchangeRate is Ownable {

    struct Currency {
        uint256 exRateToEther; // Exchange rate: currency to Ether
        uint8 exRateDecimals;  // Exchange rate decimals
    }

    Currency[] public currencies;

    event CurrencyExchangeRateAdded(
        address indexed setter, uint256 index, uint256 rate, uint256 decimals
    );

    event CurrencyExchangeRateSet(
        address indexed setter, uint256 index, uint256 rate, uint256 decimals
    );

    constructor() public {
        // Add Ether to index 0
        currencies.push(
            Currency ({
                exRateToEther: 1,
                exRateDecimals: 0
            })
        );
        // Add USD to index 1
        currencies.push(
            Currency ({
                exRateToEther: 30000,
                exRateDecimals: 2
            })
        );
    }

    function addCurrencyExchangeRate(
        uint256 _exRateToEther, 
        uint8 _exRateDecimals
    ) external onlyOwner {
        emit CurrencyExchangeRateAdded(
            msg.sender, currencies.length, _exRateToEther, _exRateDecimals);
        currencies.push(
            Currency ({
                exRateToEther: _exRateToEther,
                exRateDecimals: _exRateDecimals
            })
        );
    }

    function setCurrencyExchangeRate(
        uint256 _currencyIndex,
        uint256 _exRateToEther, 
        uint8 _exRateDecimals
    ) external onlyOwner {
        emit CurrencyExchangeRateSet(
            msg.sender, _currencyIndex, _exRateToEther, _exRateDecimals);
        currencies[_currencyIndex].exRateToEther = _exRateToEther;
        currencies[_currencyIndex].exRateDecimals = _exRateDecimals;
    }
}


/**
 * @title KYC contract interface
 */
contract KYC {
    
    /**
     * Get KYC expiration timestamp in second.
     *
     * @param _who Account address
     * @return KYC expiration timestamp in second
     */
    function expireOf(address _who) external view returns (uint256);

    /**
     * Get KYC level.
     * Level is ranging from 0 (lowest, no KYC) to 255 (highest, toughest).
     *
     * @param _who Account address
     * @return KYC level
     */
    function kycLevelOf(address _who) external view returns (uint8);

    /**
     * Get encoded nationalities (country list).
     * The uint256 is represented by 256 bits (0 or 1).
     * Every bit can represent a country.
     * For each listed country, set the corresponding bit to 1.
     * To do so, up to 256 countries can be encoded in an uint256 variable.
     * Further, if country blacklist of an ICO was encoded by the same way,
     * it is able to use bitwise AND to check whether the investor can invest
     * the ICO by the crowdsale.
     *
     * @param _who Account address
     * @return Encoded nationalities
     */
    function nationalitiesOf(address _who) external view returns (uint256);

    /**
     * Set KYC status to specific account address.
     *
     * @param _who Account address
     * @param _expiresAt Expire timestamp in seconds
     * @param _level KYC level
     * @param _nationalities Encoded nationalities
     */
    function setKYC(
        address _who, uint256 _expiresAt, uint8 _level, uint256 _nationalities) 
        external;

    event KYCSet (
        address indexed _setter,
        address indexed _who,
        uint256 _expiresAt,
        uint8 _level,
        uint256 _nationalities
    );
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract EtherVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    address public wallet;
    State public state;

    event Closed(address indexed commissionWallet, uint256 commission);
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    constructor(address _wallet) public {
        require(
            _wallet != address(0),
            "Failed to create Ether vault due to wallet address is 0x0."
        );
        wallet = _wallet;
        state = State.Active;
    }

    function deposit() public onlyOwner payable {
        require(
            state == State.Active,
            "Failed to deposit Ether due to state is not Active."
        );
    }

    function close(address _commissionWallet, uint256 _commission) public onlyOwner {
        require(
            state == State.Active,
            "Failed to close due to state is not Active."
        );
        state = State.Closed;
        emit Closed(_commissionWallet, _commission);
        _commissionWallet.transfer(address(this).balance.mul(_commission).div(100));
        wallet.transfer(address(this).balance);
    }

    function enableRefunds() public onlyOwner {
        require(
            state == State.Active,
            "Failed to enable refunds due to state is not Active."
        );
        emit RefundsEnabled();
        state = State.Refunding;        
    }

    function refund(address investor, uint256 depositedValue) public onlyOwner {
        require(
            state == State.Refunding,
            "Failed to refund due to state is not Refunding."
        );
        emit Refunded(investor, depositedValue);
        investor.transfer(depositedValue);        
    }
}



/**
 * @title ICO Rocket Fuel contract for FirstMile/LastMile service.
 */
contract IcoRocketFuel is Ownable {
    using SafeMath for uint256;

    // Crowdsale current state
    enum States {Ready, Active, Paused, Refunding, Closed}
    States public state = States.Ready;

    // Token for crowdsale (Token contract).
    // Replace 0x0 by deployed ERC20 token address.
    ERC20 public token = ERC20(0x0e27b0ca1f890d37737dd5cde9de22431255f524);

    // Crowdsale owner (ICO team).
    // Replace 0x0 by wallet address of ICO team.
    address public crowdsaleOwner = 0xf75589cac3b23f24de65fe5a3cd07966728071a3;

    // When crowdsale is closed, commissions will transfer to this wallet.
    // Replace 0x0 by commission wallet address of platform.
    address public commissionWallet = 0xf75589cac3b23f24de65fe5a3cd07966728071a3;

    // Base exchange rate (1 invested currency = N tokens) and its decimals.
    // Ex. to present base exchange rate = 0.01 (= 1 / (10^2))
    //     baseExRate = 1; baseExRateDecimals = 2 
    //     (1 / (10^2)) equal to (baseExRate / (10^baseExRateDecimals))
    uint256 public baseExRate = 20;    
    uint8 public baseExRateDecimals = 0;

    // External exchange rate contract and currency index.
    // Use exRate.currencies(currency) to get tuple.
    // tuple = (Exchange rate to Ether, Exchange rate decimal)
    // Replace 0x0 by address of deployed CurrencyExchangeRate contract.
    CurrencyExchangeRate public exRate = CurrencyExchangeRate(0x44802e3d6fb67bd8ee7b24033ee04b1290692fd9);
    // Supported currency
    // 0: Ether
    // 1: USD
    uint256 public currency = 1;

    // Total raised in specified currency.
    uint256 public raised = 0;
    // Hard cap in specified currency.
    uint256 public cap = 25000000 * (10**18);
    // Soft cap in specified currency.
    uint256 public goal = 0;
    // Minimum investment in specified currency.
    uint256 public minInvest = 50000 * (10**18);
    
    // Crowdsale closing time in second.
    uint256 public closingTime = 1548979200;
    // Whether allow early closure
    bool public earlyClosure = true;

    // Commission percentage. Set to 10 means 10% 
    uint8 public commission = 10;

    // When KYC is required, check KYC result with this contract.
    // The value is initiated by constructor.
    // The value is not allowed to change after contract deployment.
    // Replace 0x0 by address of deployed KYC contract.
    KYC public kyc = KYC(0x8df3064451f840285993e2a4cfc0ec56b267d288);

    // Get encoded country blacklist.
    // The uint256 is represented by 256 bits (0 or 1).
    // Every bit can represent a country.
    // For the country listed in the blacklist, set the corresponding bit to 1.
    // To do so, up to 256 countries can be encoded in an uint256 variable.
    // Further, if nationalities of an investor were encoded by the same way,
    // it is able to use bitwise AND to check whether the investor can invest
    // the ICO by the crowdsale.
    // Keypasco: Natural persons from Singapore and United States cannot invest.
    uint256 public countryBlacklist = 27606985387965724171868518586879082855975017189942647717541493312847872;

    // Get required KYC level of the crowdsale.
    // KYC level = 0 (default): Crowdsale does not require KYC.
    // KYC level > 0: Crowdsale requires centain level of KYC.
    // KYC level ranges from 0 (no KYC) to 255 (toughest).
    uint8 public kycLevel = 100;

    // Whether legal person can skip country check.
    // True: can skip; False: cannot skip.  
    bool public legalPersonSkipsCountryCheck = true;

    // Use deposits[buyer] to get deposited Wei for buying the token.
    // The buyer is the buyer address.
    mapping(address => uint256) public deposits;
    // Ether vault entrusts invested Wei.
    EtherVault public vault;
    
    // Investment in specified currency.
    // Use invests[buyer] to get current investments.
    mapping(address => uint256) public invests;
    // Token units can be claimed by buyer.
    // Use tokenUnits[buyer] to get current bought token units.
    mapping(address => uint256) public tokenUnits;
    // Total token units for performing the deal.
    // Sum of all buyers&#39; bought token units will equal to this value.
    uint256 public totalTokenUnits = 0;

    // Bonus tiers which will be initiated in constructor.
    struct BonusTier {
        uint256 investSize; // Invest in specified currency
        uint256 bonus;      // Bonus in percentage
    }
    // Bonus levels initiated by constructor.
    BonusTier[] public bonusTiers;

    event StateSet(
        address indexed setter, 
        States oldState, 
        States newState
    );

    event CrowdsaleStarted(
        address indexed icoTeam
    );

    event TokenBought(
        address indexed buyer, 
        uint256 valueWei, 
        uint256 valueCurrency
    );

    event TokensRefunded(
        address indexed beneficiary,
        uint256 valueTokenUnit
    );

    event Finalized(
        address indexed icoTeam
    );

    event SurplusTokensRefunded(
        address indexed beneficiary,
        uint256 valueTokenUnit
    );

    event CrowdsaleStopped(
        address indexed owner
    );

    event TokenClaimed(
        address indexed beneficiary,
        uint256 valueTokenUnit
    );

    event RefundClaimed(
        address indexed beneficiary,
        uint256 valueWei
    );

    modifier onlyCrowdsaleOwner() {
        require(
            msg.sender == crowdsaleOwner,
            "Failed to call function due to permission denied."
        );
        _;
    }

    modifier inState(States _state) {
        require(
            state == _state,
            "Failed to call function due to crowdsale is not in right state."
        );
        _;
    }

    constructor() public {
        // Must push higher bonus first.
        bonusTiers.push(
            BonusTier({
                investSize: 400000 * (10**18),
                bonus: 50
            })
        );
        bonusTiers.push(
            BonusTier({
                investSize: 200000 * (10**18),
                bonus: 40
            })
        );
        bonusTiers.push(
            BonusTier({
                investSize: 100000 * (10**18),
                bonus: 30
            })
        );
        bonusTiers.push(
            BonusTier({
                investSize: 50000 * (10**18),
                bonus: 20
            })
        );
    }

    function setAddress(
        address _token,
        address _crowdsaleOwner,
        address _commissionWallet,
        address _exRate,
        address _kyc
    ) external onlyOwner inState(States.Ready){
        token = ERC20(_token);
        crowdsaleOwner = _crowdsaleOwner;
        commissionWallet = _commissionWallet;
        exRate = CurrencyExchangeRate(_exRate);
        kyc = KYC(_kyc);
    }

    function setSpecialOffer(
        uint256 _currency,
        uint256 _cap,
        uint256 _goal,
        uint256 _minInvest,
        uint256 _closingTime
    ) external onlyOwner inState(States.Ready) {
        currency = _currency;
        cap = _cap;
        goal = _goal;
        minInvest = _minInvest;
        closingTime = _closingTime;
    }

    function setInvestRestriction(
        uint256 _countryBlacklist,
        uint8 _kycLevel,
        bool _legalPersonSkipsCountryCheck
    ) external onlyOwner inState(States.Ready) {
        countryBlacklist = _countryBlacklist;
        kycLevel = _kycLevel;
        legalPersonSkipsCountryCheck = _legalPersonSkipsCountryCheck;
    }

    function setState(uint256 _state) external onlyOwner {
        require(
            uint256(state) < uint256(States.Refunding),
            "Failed to set state due to crowdsale was finalized."
        );
        require(
            // Only allow switch state between Active and Paused.
            uint256(States.Active) == _state || uint256(States.Paused) == _state,
            "Failed to set state due to invalid index."
        );
        emit StateSet(msg.sender, state, States(_state));
        state = States(_state);
    }

    /**
     * Get bonus in token units.
     * @param _investSize Total investment size in specified currency
     * @param _tokenUnits Token units for the investment (without bonus)
     * @return Bonus in token units
     */
    function _getBonus(uint256 _investSize, uint256 _tokenUnits) 
        private view returns (uint256) 
    {
        for (uint256 _i = 0; _i < bonusTiers.length; _i++) {
            if (_investSize >= bonusTiers[_i].investSize) {
                return _tokenUnits.mul(bonusTiers[_i].bonus).div(100);
            }
        }
        return 0;
    }

    /**
     * Start crowdsale.
     */
    function startCrowdsale()
        external
        onlyCrowdsaleOwner
        inState(States.Ready)
    {
        emit CrowdsaleStarted(msg.sender);
        vault = new EtherVault(msg.sender);
        state = States.Active;
    }

    /**
     * Buy token.
     */
    function buyToken()
        external
        inState(States.Active)
        payable
    {
        // KYC level = 0 means no KYC can invest.
        // KYC level > 0 means certain level of KYC is required.
        if (kycLevel > 0) {
            require(
                // solium-disable-next-line security/no-block-members
                block.timestamp < kyc.expireOf(msg.sender),
                "Failed to buy token due to KYC was expired."
            );
        }

        require(
            kycLevel <= kyc.kycLevelOf(msg.sender),
            "Failed to buy token due to require higher KYC level."
        );

        require(
            countryBlacklist & kyc.nationalitiesOf(msg.sender) == 0 || (
                kyc.kycLevelOf(msg.sender) >= 200 && legalPersonSkipsCountryCheck
            ),
            "Failed to buy token due to country investment restriction."
        );

        // Get exchange rate of specified currency.
        (uint256 _exRate, uint8 _exRateDecimals) = exRate.currencies(currency);

        // Convert from Ether to base currency.
        uint256 _investSize = (msg.value)
            .mul(_exRate).div(10**uint256(_exRateDecimals));

        require(
            _investSize >= minInvest,
            "Failed to buy token due to less than minimum investment."
        );

        require(
            raised.add(_investSize) <= cap,
            "Failed to buy token due to exceed cap."
        );

        require(
            // solium-disable-next-line security/no-block-members
            block.timestamp < closingTime,
            "Failed to buy token due to crowdsale is closed."
        );

        // Update total invested in specified currency.
        invests[msg.sender] = invests[msg.sender].add(_investSize);
        // Update total invested wei.
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        // Update total raised in specified currency.    
        raised = raised.add(_investSize);

        // Log previous token units.
        uint256 _previousTokenUnits = tokenUnits[msg.sender];

        // Calculate token units by base exchange rate.
        uint256 _tokenUnits = invests[msg.sender]
            .mul(baseExRate)
            .div(10**uint256(baseExRateDecimals));

        // Calculate bought token units (take bonus into account).
        uint256 _tokenUnitsWithBonus = _tokenUnits.add(
            _getBonus(invests[msg.sender], _tokenUnits));

        // Update total bought token units.
        tokenUnits[msg.sender] = _tokenUnitsWithBonus;

        // Update total token units to be issued.
        totalTokenUnits = totalTokenUnits
            .sub(_previousTokenUnits)
            .add(_tokenUnitsWithBonus);

        emit TokenBought(msg.sender, msg.value, _investSize);

        // Entrust wei to vault.
        vault.deposit.value(msg.value)();
    }

    /**
     * Refund token units to wallet address of crowdsale owner.
     */
    function _refundTokens()
        private
        inState(States.Refunding)
    {
        uint256 _value = token.balanceOf(address(this));
        emit TokensRefunded(crowdsaleOwner, _value);
        if (_value > 0) {         
            // Refund all tokens for crowdsale to refund wallet.
            token.transfer(crowdsaleOwner, _value);
        }
    }

    /**
     * Finalize this crowdsale.
     */
    function finalize()
        external
        inState(States.Active)        
        onlyCrowdsaleOwner
    {
        require(
            // solium-disable-next-line security/no-block-members                
            earlyClosure || block.timestamp >= closingTime,                   
            "Failed to finalize due to crowdsale is opening."
        );

        emit Finalized(msg.sender);

        if (raised >= goal && token.balanceOf(address(this)) >= totalTokenUnits) {
            // Set state to Closed whiling preventing reentry.
            state = States.Closed;

            // Refund surplus tokens.
            uint256 _balance = token.balanceOf(address(this));
            uint256 _surplus = _balance.sub(totalTokenUnits);
            emit SurplusTokensRefunded(crowdsaleOwner, _surplus);
            if (_surplus > 0) {
                // Refund surplus tokens to refund wallet.
                token.transfer(crowdsaleOwner, _surplus);
            }
            // Close vault, and transfer commission and raised ether.
            vault.close(commissionWallet, commission);
        } else {
            state = States.Refunding;
            _refundTokens();
            vault.enableRefunds();
        }
    }

    /**
     * Stop this crowdsale.
     * Only stop suspecious projects.
     */
    function stopCrowdsale()  
        external
        onlyOwner
        inState(States.Paused)
    {
        emit CrowdsaleStopped(msg.sender);
        state = States.Refunding;
        _refundTokens();
        vault.enableRefunds();
    }

    /**
     * Investors claim bought token units.
     */
    function claimToken()
        external 
        inState(States.Closed)
    {
        require(
            tokenUnits[msg.sender] > 0,
            "Failed to claim token due to token unit is 0."
        );
        uint256 _value = tokenUnits[msg.sender];
        tokenUnits[msg.sender] = 0;
        emit TokenClaimed(msg.sender, _value);
        token.transfer(msg.sender, _value);
    }

    /**
     * Investors claim invested Ether refunds.
     */
    function claimRefund()
        external
        inState(States.Refunding)
    {
        require(
            deposits[msg.sender] > 0,
            "Failed to claim refund due to deposit is 0."
        );

        uint256 _value = deposits[msg.sender];
        deposits[msg.sender] = 0;
        emit RefundClaimed(msg.sender, _value);
        vault.refund(msg.sender, _value);
    }
}