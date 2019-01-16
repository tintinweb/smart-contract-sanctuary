pragma solidity 0.4.25;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an ownTer address, and provides basic authorization control
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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Destructible.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/modifier/HasManager.sol

contract HasManager is Ownable {

    // allow managers to whitelist and confirm contributions by manager accounts
    // (managers can be set and altered by owner, multiple manager accounts are possible
    mapping (address => bool) public isManager;

    event ChangedManager(address indexed manager, bool active);

    /**
     * @dev Set / alter manager / whitelister "account". This can be done from owner only
     * @param manager address address of the manager to create/alter
     * @param active bool flag that shows if the manager account is active
     */
    function setManager(address manager, bool active) public onlyOwner {
        isManager[manager] = active;
        emit ChangedManager(manager, active);
    }

    modifier managerRole() {
        require(isManager[msg.sender], "sender is not a manager");
        _;
    }

}

// File: contracts/modifier/HasBank.sol

contract HasBank is Ownable {

    // banks can submit new payments
    mapping (address => bool) public isBank;

    event ChangedBank(address indexed bank, bool active);

    /**
     * @dev Set / alter bank / whitelister "account". This can be done from owner only
     * @param bank address address of the bank to create/alter
     * @param active bool flag that shows if the bank account is active
     */
    function setBank(address bank, bool active) public onlyOwner {
        isBank[bank] = active;
        emit ChangedBank(bank, active);
    }

    modifier bankRole() {
        require(isBank[msg.sender], "sender is not a bank");
        _;
    }
}

// File: contracts\ico\TokenGateCrowdsale.sol

contract TokenGateCrowdsale is Ownable, Pausable, HasManager, HasBank, Destructible {

    using SafeMath for uint256;

    event InvestorAdded(address indexed wallet);
    event InvestorRemoved(address indexed wallet);
    event PaymentEvent(bytes32 indexed paymentId, PaymentStatus status);
    event ExchangeRateEvent(uint _timestamp, uint256 _rateBTC, uint256 _rateETH);
    
    enum PaymentStatus { Verified, Cancelled, ErrorInvestorNotFound, ErrorNotTheSameInvestor,
        ErrorExceedsKycLimit, ErrorBelowMinInvest, ErrorNotStarted, ErrorHasEnded }

    uint8 constant public CURRENCY_TYPE_CHF = 0;
    uint8 constant public CURRENCY_TYPE_BTC = 1;
    uint8 constant public CURRENCY_TYPE_ETH = 2;
    
    uint256 constant ZERO = uint256(0);

    struct Payment {
        bytes32 refId;
        uint timestamp;
        uint256 amount;
        uint256 tokenAmount;
        uint8 currencyType;
        PaymentStatus status;
    }

    struct InvestorData {
        uint256 kycLimit;
        uint256 bonus;
    }
    
    // refId => wallet mapping
    // refId: bitcoin addr, eth addr or bank ref id from which payment is expected
    // wallet is the address where generated tokens will be sent
    mapping(bytes32 => address) public investors;

    // wallet => InvestorData in tokens mapping
    mapping(address => InvestorData) public investorData;
    
    // paymentId => Payment mapping
    mapping(bytes32 => Payment) public payments;

    // how many tokens are received per unit currency (BTC and ETH)
    struct ExchangeRate {
        uint timestamp;
        uint256[2] rate;
    }
    
    ExchangeRate[] public exchangeRates;

    bool public finalized = false;

    uint public creationTime = now;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public pendingTime;
    
    ERC20 public token;
    
    // rate CHF is fixed at the beginning of ICO for its duration
    uint256 public rateCHF;
    
    // minimal allowed investment expressed in tokens
    uint256 public minInvestment;

    // keeping track of how much special tokens are allocated
    uint256 public teamTokensSum;
    uint256 public founderTokensSum;
    uint256 public privateSaleTokensSum;
    uint256 public referralTokensSum;
    
    uint8 public constant decimals = 18;
    uint256 public constant oneToken = (10 ** uint256(decimals));

    address public tokenHolder;
    
    /**
     * @param _startTime start time of the ICO
     * @param _endTime end time of the ICO
     * @param _pendingTime pending time after the ICO end
     * @param _managerAddress address of the manager account
     * @param _bankAddress address of the bank account
     * @param _token ERC20 token which is being controlled
     * @param _tokenHolder addr which holds all tokens
     */
    constructor (
        uint256 _startTime,
        uint256 _endTime,
        uint256 _pendingTime,
        address _managerAddress,
        address _bankAddress,
        ERC20 _token,
        address _tokenHolder)
    public
    Pausable()
    {
        require(_token != address(0), "token can not be 0x");
        require(_bankAddress != address(0), "bank address cannot be 0x");
        require(_managerAddress != address(0), "manager address cannot be 0x");
        require(_endTime > _startTime, "endTime must be bigger than startTme");
        require(_pendingTime > 0, "pendingTime must be > 0");
 
        setManager(_managerAddress, true);
        setBank(_bankAddress, true);

        token = _token;
        startTime = _startTime;
        endTime = _endTime;
        pendingTime = _pendingTime;
        tokenHolder = _tokenHolder;
        
        // *****************************
        // adjustable parameters per ICO
        // *****************************
        
        // rateCHF: how many tokens 1 CHF is worth
        // 1 CHF = 0.5 tokens
        rateCHF = oneToken.div(2);
        
        // minCHF - minimal investment in CHF
        uint256 minCHF = 1000;
        // convert to tokens, because it&#39;s easier to work with it
        minInvestment = minCHF.mul(rateCHF);
    }
    
    /**
     * @dev calcs how many seconds are in days
     * @param _days days to converts to seconds
     */
    function daysToSeconds(uint _days) internal pure returns (uint) {
        return _days.mul(24 hours);
    }

    /**
     * @dev gets investor key in hash map based on refId and currency type
     * @param _refId one of investor accounts (btc, eth or bank)
     * @param _currencyType type of the account, 0 - chf, 1 - btc, 2 - eth
     */
    function getInvestorKey(bytes32 _refId, uint8 _currencyType) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_refId, _currencyType));
    }
    
    // Note on return values of functions: it always returns true at the end of the function, so it is
    // possible to detect whether the function completed successfully when calling it over the web3. 
    // In case function fails, the return value will either be &#39;0x&#39; (for require routines without error message)
    // or in form &#39;0x<func signature><encoded error message as string>. In case the function succeeds,
    // it will return "0x00...001" to web3 (equivalent of true)
    
    //
    // Investors
    //
    
    /**
     * @dev registers a new investor or updates existing one (e.g. kyc limit or new account)
     * @param _refIds an array of "mappings" where "mapping" array index == currency type and value is the refId
     * e.g. it expects at position 0 CHF account, 1 - BTC account and 2 - ETH account
     * pass the empty string if the user does not have the corresponding account
     * @param _wallet - wallet address of the investor which gets tokens
     * @param _kycLimit - max allowed investment amount in CHF*oneToken, 0 means unlimited
     * @param _bonus - bonus in percent 0-100
     */
    function addInvestor(bytes32[3][] _refIds, address _wallet, uint256 _kycLimit, uint256 _bonus)
    public managerRole whenNotFinalized whenNotPaused returns (bool) {
        require(now < endTime, "crowdsale is already finished");
        require(_refIds.length > 0, "refs must be a non-empty array");
        require(_wallet != address(0), "wallet must have non-zero address");
        require(_bonus >= 0, "bonus must be greater than or equals to zero");
        require(_bonus <= 100, "bonus must be less than or equals to hundred");

        for (uint i = 0; i < _refIds.length; i++) {
            bytes32[3] memory ref = _refIds[i];
            for (uint j = 0; j < ref.length; j++) {
                // ignore unset values, they are treated as if the user does not have the corresponding account
                if (ref[j] == bytes32(0)) continue;

                bytes32 index = getInvestorKey(ref[j], uint8(j));

                address _curAddress = investors[index];
                require(_curAddress == address(0) || _curAddress == _wallet,
                    "refId already registered with a different wallet");

                investors[index] = _wallet;
            }
        }
        
        // both kycLimit and exchange rate are multiplied by oneToken in order to keep the
        // precision. That&#39;s why it&#39;s necessary to divide by oneToken.
        uint256 kycLimitInTokens = _kycLimit.mul(rateCHF).div(oneToken);

        investorData[_wallet].kycLimit = kycLimitInTokens;
        investorData[_wallet].bonus = _bonus;

        emit InvestorAdded(_wallet);
        
        return true;
    }
 
    /**
     * @dev returns investor wallet by account and account type
     * @param _refId - account
     * @param _currencyType - 0 - CHF account, 1 - BTC account and 2 - ETH account
     */
    function getInvestor(bytes32 _refId, uint8 _currencyType) public view returns (address) {
        return investors[getInvestorKey(_refId, _currencyType)];
    }

    /**
     * @dev returns kyc limit for an investor
     * @param _refId - account
     * @param _currencyType - 0 - CHF account, 1 - BTC account and 2 - ETH account
     */
    function getInvestorKycLimit(bytes32 _refId, uint8 _currencyType) public view returns (uint256) {
        address wallet = investors[getInvestorKey(_refId, _currencyType)];
        return investorData[wallet].kycLimit;
    }

    /**
     * @dev returns kyc limit for an investor
     * @param _refId - account
     * @param _currencyType - 0 - CHF account, 1 - BTC account and 2 - ETH account
     */
    function getBonus(bytes32 _refId, uint8 _currencyType) public view returns (uint256) {
        address wallet = investors[getInvestorKey(_refId, _currencyType)];
        return investorData[wallet].bonus;
    }
    
    //
    // Exchange rate
    //
    
    /**
     * @dev provides a new exchange rate
     * @param _timestamp - time of the exchange rate
     * @param _rateBTC - how much token is worth in BTC multiplied by token decimals
     * @param _rateETH - how much token is worth in ETH multiplied by token decimals
     */
    function provideExchangeRate(
        uint256 _timestamp,
        uint256 _rateBTC,
        uint256 _rateETH) 
    public managerRole whenNotFinalized whenNotPaused whenNotFinalized returns (bool) {
        require(exchangeRates.length == 0 || exchangeRates[exchangeRates.length - 1].timestamp < _timestamp,
            "ts must be greater than the latest ts");
        require(_rateBTC > 0 && _rateETH > 0, "exchange rates must be positive");

        // btc/chf and eth/chf rates are converted to btc/token and eth/token rates
        uint256 rateBtcToken = _rateBTC.mul(rateCHF).div(oneToken);
        uint256 rateEthToken = _rateETH.mul(rateCHF).div(oneToken);
        ExchangeRate memory rate = ExchangeRate(_timestamp, [rateBtcToken, rateEthToken]);
        exchangeRates.push(rate);
        
        emit ExchangeRateEvent(_timestamp, rateBtcToken, rateEthToken);
        
        return true;
    }

    /**
     * @return currently valid exchange rate 
     */
    function getCurrentExchangeRate() public view 
    returns (uint ts, uint256[3] rate) {
        if (exchangeRates.length == 0) return (now, [rateCHF, ZERO, ZERO]);
        ExchangeRate memory er = exchangeRates[exchangeRates.length - 1];
        return (now, [rateCHF, er.rate[CURRENCY_TYPE_BTC - 1], er.rate[CURRENCY_TYPE_ETH - 1]]);
    }

    /**
     * @return exchange rate valid at a certain time
     * @param _timestamp time to return exchange rate for
     */
    function getExchangeRateAtTime(uint _timestamp) public view
    returns (uint ts, uint256[3] rate) {
        if (exchangeRates.length == 0) return (_timestamp, [rateCHF, ZERO, ZERO]);
        for (uint j = 0; j <= exchangeRates.length - 1; j++) {
            uint i = exchangeRates.length - j - 1;
            if (_timestamp >= exchangeRates[i].timestamp) {
                ExchangeRate memory er = exchangeRates[i];
                return (_timestamp, [rateCHF, er.rate[CURRENCY_TYPE_BTC - 1], er.rate[CURRENCY_TYPE_ETH - 1]]);
            }
        }
        return (_timestamp, [rateCHF, ZERO, ZERO]);
    }
    
    /**
     * @return exchange rate array length
     */
    function getExchangeRatesLength() public view returns (uint) {
        return exchangeRates.length;
    }

    //
    // Payments
    //

    // @param _force - set to true to avoid KYC and Limit checks
    function allocateTokens(Payment storage _payment, address _investor, bool _force) internal {
        (, uint256[3] memory er) = getExchangeRateAtTime(_payment.timestamp);
        require(er[_payment.currencyType] > 0, "exchange rate must be positive");
        // both amount and exchange rate are multiplied by oneToken in order to keep the
        // precision. That&#39;s why it&#39;s necessary to divide by oneToken.
        _payment.tokenAmount = _payment.amount.mul(er[_payment.currencyType]).div(oneToken);
        
        // now we know how many tokens is going to be allocated and can check the minInvest and KYC limit
        if (!_force && _payment.tokenAmount < minInvestment) {
            _payment.status = PaymentStatus.ErrorBelowMinInvest;
            _payment.tokenAmount = 0;
        } else if (!_force && investorData[_investor].kycLimit > 0 &&
            investorData[_investor].kycLimit < token.balanceOf(_investor).add(_payment.tokenAmount)) {
            _payment.status = PaymentStatus.ErrorExceedsKycLimit;
            _payment.tokenAmount = 0;
        } else {
            if (investorData[_investor].bonus > 0) {
                uint256 bonus = investorData[_investor].bonus;
                _payment.tokenAmount = _payment.tokenAmount.add(bonus.mul(_payment.tokenAmount).div(100));
            }
            token.transferFrom(tokenHolder, _investor, _payment.tokenAmount);
        }
    }

    /**
     * @dev submit a new payment
     * @param _paymentId unique id for this payment
     * @param _refIds - for Ethereum, this is one sender address. In Bitcoin, there can be several transaction
     * inputs associated with different addresses of the sender. Each address must be registered in smart contract,
     * only one refId will be saved as Payment.
     * @param _timestamp timestamp of the payment
     * @param _amount payment amount multimplied by decimals
     * @param _currencyType 0 - chf, 1 - btc, 2 - eth
     */
    function submitPayment(
        bytes32 _paymentId,
        bytes32[] _refIds,
        uint256 _timestamp,
        uint256 _amount,
        uint8 _currencyType
    ) public bankRole whenNotFinalized whenNotPaused whenNotFinalized returns (bool) {
        require(_timestamp <= now, "payment cannot be in the future");
        require(_amount > 0, "payment amount must be positive");
        require(payments[_paymentId].timestamp == 0, "payment already registered");
        require(_refIds.length > 0, "refIds must not be empty");

        PaymentStatus status = PaymentStatus.Verified;

        if (_timestamp < startTime) {
            status = PaymentStatus.ErrorNotStarted;
        } else if (_timestamp > endTime) {
            status = PaymentStatus.ErrorHasEnded;
        }

        payments[_paymentId] = Payment(
            _refIds[0],
            _timestamp,
            _amount,
            0,
            _currencyType,
            status);

        Payment storage payment = payments[_paymentId];

        bytes32 index = getInvestorKey(_refIds[0], _currencyType);
        address investor = investors[index];
        for (uint8 i = 1; i < _refIds.length; i++) {
            index = getInvestorKey(_refIds[i], _currencyType);
            
            if (investor != investors[index]) {
                // don&#39;t reset the existing error if set
                if (payment.status == PaymentStatus.Verified) {
                    payment.status = PaymentStatus.ErrorNotTheSameInvestor;
                }
            }
        }

        if (investor == address(0)) {
            // don&#39;t reset the existing error if set
            if (payment.status == PaymentStatus.Verified) {
                payment.status = PaymentStatus.ErrorInvestorNotFound;
            }
        } else if (payment.status == PaymentStatus.Verified) {
            allocateTokens(payment, investor, false);
        }
        
        emit PaymentEvent(_paymentId, payment.status);
        
        return true;
    }

    function setPaymentStatus(bytes32 _paymentId, PaymentStatus status)
    public managerRole whenNotFinalized whenNotPaused returns (bool) {
        Payment storage payment = payments[_paymentId];
        require(status != PaymentStatus.Cancelled, "payment cancellation not supported");
        require(payment.status != PaymentStatus.Verified, "already verified, cannot change");
        require(payment.timestamp > 0, "payment not found");
        require(payment.status != status, "status already set");

        payment.status = status;
        
        address investor = investors[getInvestorKey(payment.refId, payment.currencyType)];
        require(investor != address(0), "investor not found by payment refid");

        if (status == PaymentStatus.Verified) {
            allocateTokens(payment, investor, true);
        }

        emit PaymentEvent(_paymentId, payment.status);
        
        return true;
    }
    
    //
    // Finalize
    //

    /**
     * @dev finalize crowdsale
     */
    function finalize() public onlyOwner {
        require(now > endTime + pendingTime, "pending time is not elapsed yet");
        finalized = true;
    }

    modifier whenNotFinalized() {
        require(!finalized, "is already finalized");
        _;
    }
    
    function setEndTime(uint256 _endTime) public onlyOwner whenNotFinalized {
        require(_endTime > startTime, "endTime must be bigger than startTme");
        endTime = _endTime;
    }
}