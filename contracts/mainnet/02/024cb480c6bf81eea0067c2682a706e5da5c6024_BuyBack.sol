pragma solidity ^0.4.11;

/**
 * @title Owned contract with safe ownership pass.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn&#39;t happen yet.
 */
contract Owned {
    /**
     * Contract owner address
     */
    address public contractOwner;

    /**
     * Contract owner address
     */
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

    /**
    * @dev Owner check modifier
    */
    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

    /**
     * @dev Destroy contract and scrub a data
     * @notice Only owner can call it
     */
    function destroy() onlyContractOwner {
        suicide(msg.sender);
    }

    /**
     * Prepares ownership pass.
     *
     * Can only be called by current owner.
     *
     * @param _to address of the next owner. 0x0 is not allowed.
     *
     * @return success.
     */
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        if (_to  == 0x0) {
            return false;
        }

        pendingContractOwner = _to;
        return true;
    }

    /**
     * Finalize ownership pass.
     *
     * Can only be called by pending owner.
     *
     * @return success.
     */
    function claimContractOwnership() returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }

        contractOwner = pendingContractOwner;
        delete pendingContractOwner;

        return true;
    }
}


contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

/**
 * @title Generic owned destroyable contract
 */
contract Object is Owned {
    /**
    *  Common result code. Means everything is fine.
    */
    uint constant OK = 1;
    uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }

    function checkOnlyContractOwner() internal constant returns(uint) {
        if (contractOwner == msg.sender) {
            return OK;
        }

        return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
    }
}


/**
 * @title General MultiEventsHistory user.
 *
 */
contract MultiEventsHistoryAdapter {

    /**
    *   @dev It is address of MultiEventsHistory caller assuming we are inside of delegate call.
    */
    function _self() constant internal returns (address) {
        return msg.sender;
    }
}

contract DelayedPaymentsEmitter is MultiEventsHistoryAdapter {
    event Error(bytes32 message);

    function emitError(bytes32 _message) {
        Error(_message);
    }
}

contract DelayedPayments is Object {
   
    uint constant DELAYED_PAYMENTS_SCOPE = 52000;
    uint constant DELAYED_PAYMENTS_INVALID_INVOCATION = DELAYED_PAYMENTS_SCOPE + 17;

    /// @dev `Payment` is a public structure that describes the details of
    ///  each payment making it easy to track the movement of funds
    ///  transparently
    struct Payment {
        address spender;        // Who is sending the funds
        uint earliestPayTime;   // The earliest a payment can be made (Unix Time)
        bool canceled;         // If True then the payment has been canceled
        bool paid;              // If True then the payment has been paid
        address recipient;      // Who is receiving the funds
        uint amount;            // The amount of wei sent in the payment
        uint securityGuardDelay;// The seconds `securityGuard` can delay payment
    }

    Payment[] public authorizedPayments;

    address public securityGuard;
    uint public absoluteMinTimeLock;
    uint public timeLock;
    uint public maxSecurityGuardDelay;

    // Should use interface of the emitter, but address of events history.
    address public eventsHistory;

    /// @dev The white list of approved addresses allowed to set up && receive
    ///  payments from this vault
    mapping (address => bool) public allowedSpenders;

    /// @dev The address assigned the role of `securityGuard` is the only
    ///  addresses that can call a function with this modifier
    modifier onlySecurityGuard { if (msg.sender != securityGuard) throw; _; }

    // @dev Events to make the payment movements easy to find on the blockchain
    event PaymentAuthorized(uint indexed idPayment, address indexed recipient, uint amount);
    event PaymentExecuted(uint indexed idPayment, address indexed recipient, uint amount);
    event PaymentCanceled(uint indexed idPayment);
    event EtherReceived(address indexed from, uint amount);
    event SpenderAuthorization(address indexed spender, bool authorized);

/////////
// Constructor
/////////

    /// @notice The Constructor creates the Vault on the blockchain
    /// @param _absoluteMinTimeLock The minimum number of seconds `timelock` can
    ///  be set to, if set to 0 the `owner` can remove the `timeLock` completely
    /// @param _timeLock Initial number of seconds that payments are delayed
    ///  after they are authorized (a security precaution)
    /// @param _maxSecurityGuardDelay The maximum number of seconds in total
    ///   that `securityGuard` can delay a payment so that the owner can cancel
    ///   the payment if needed
    function DelayedPayments(
        uint _absoluteMinTimeLock,
        uint _timeLock,
        uint _maxSecurityGuardDelay) 
    {
        absoluteMinTimeLock = _absoluteMinTimeLock;
        timeLock = _timeLock;
        securityGuard = msg.sender;
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }

    /**
     * Emits Error event with specified error message.
     *
     * Should only be used if no state changes happened.
     *
     * @param _errorCode code of an error
     * @param _message error message.
     */
    function _error(uint _errorCode, bytes32 _message) internal returns(uint) {
        DelayedPaymentsEmitter(eventsHistory).emitError(_message);
        return _errorCode;
    }

    /**
     * Sets EventsHstory contract address.
     *
     * Can be set only once, and only by contract owner.
     *
     * @param _eventsHistory MultiEventsHistory contract address.
     *
     * @return success.
     */
    function setupEventsHistory(address _eventsHistory) returns(uint errorCode) {
        errorCode = checkOnlyContractOwner();
        if (errorCode != OK) {
            return errorCode;
        }
        if (eventsHistory != 0x0 && eventsHistory != _eventsHistory) {
            return DELAYED_PAYMENTS_INVALID_INVOCATION;
        }
        eventsHistory = _eventsHistory;
        return OK;
    }

/////////
// Helper functions
/////////

    /// @notice States the total number of authorized payments in this contract
    /// @return The number of payments ever authorized even if they were canceled
    function numberOfAuthorizedPayments() constant returns (uint) {
        return authorizedPayments.length;
    }

//////
// Receive Ether
//////

    /// @notice Called anytime ether is sent to the contract && creates an event
    /// to more easily track the incoming transactions
    function receiveEther() payable {
        EtherReceived(msg.sender, msg.value);
    }

    /// @notice The fall back function is called whenever ether is sent to this
    ///  contract
    function () payable {
        receiveEther();
    }

////////
// Spender Interface
////////

    /// @notice only `allowedSpenders[]` Creates a new `Payment`
    /// @param _recipient Destination of the payment
    /// @param _amount Amount to be paid in wei
    /// @param _paymentDelay Number of seconds the payment is to be delayed, if
    ///  this value is below `timeLock` then the `timeLock` determines the delay
    /// @return The Payment ID number for the new authorized payment
    function authorizePayment(
        address _recipient,
        uint _amount,
        uint _paymentDelay
    ) returns(uint) {

        // Fail if you arent on the `allowedSpenders` white list
        if (!allowedSpenders[msg.sender]) throw;
        uint idPayment = authorizedPayments.length;       // Unique Payment ID
        authorizedPayments.length++;

        // The following lines fill out the payment struct
        Payment p = authorizedPayments[idPayment];
        p.spender = msg.sender;

        // Overflow protection
        if (_paymentDelay > 10**18) throw;

        // Determines the earliest the recipient can receive payment (Unix time)
        p.earliestPayTime = _paymentDelay >= timeLock ?
                                now + _paymentDelay :
                                now + timeLock;
        p.recipient = _recipient;
        p.amount = _amount;
        PaymentAuthorized(idPayment, p.recipient, p.amount);
        return idPayment;
    }

    /// @notice only `allowedSpenders[]` The recipient of a payment calls this
    ///  function to send themselves the ether after the `earliestPayTime` has
    ///  expired
    /// @param _idPayment The payment ID to be executed
    function collectAuthorizedPayment(uint _idPayment) {

        // Check that the `_idPayment` has been added to the payments struct
        if (_idPayment >= authorizedPayments.length) return;

        Payment p = authorizedPayments[_idPayment];

        // Checking for reasons not to execute the payment
        if (msg.sender != p.recipient) return;
        if (now < p.earliestPayTime) return;
        if (p.canceled) return;
        if (p.paid) return;
        if (this.balance < p.amount) return;

        p.paid = true; // Set the payment to being paid
        if (!p.recipient.send(p.amount)) {  // Make the payment
            return;
        }
        PaymentExecuted(_idPayment, p.recipient, p.amount);
     }

/////////
// SecurityGuard Interface
/////////

    /// @notice `onlySecurityGuard` Delays a payment for a set number of seconds
    /// @param _idPayment ID of the payment to be delayed
    /// @param _delay The number of seconds to delay the payment
    function delayPayment(uint _idPayment, uint _delay) onlySecurityGuard {
        if (_idPayment >= authorizedPayments.length) throw;

        // Overflow test
        if (_delay > 10**18) throw;

        Payment p = authorizedPayments[_idPayment];

        if ((p.securityGuardDelay + _delay > maxSecurityGuardDelay) ||
            (p.paid) ||
            (p.canceled))
            throw;

        p.securityGuardDelay += _delay;
        p.earliestPayTime += _delay;
    }

////////
// Owner Interface
///////

    /// @notice `onlyOwner` Cancel a payment all together
    /// @param _idPayment ID of the payment to be canceled.
    function cancelPayment(uint _idPayment) onlyContractOwner {
        if (_idPayment >= authorizedPayments.length) throw;

        Payment p = authorizedPayments[_idPayment];


        if (p.canceled) throw;
        if (p.paid) throw;

        p.canceled = true;
        PaymentCanceled(_idPayment);
    }

    /// @notice `onlyOwner` Adds a spender to the `allowedSpenders[]` white list
    /// @param _spender The address of the contract being authorized/unauthorized
    /// @param _authorize `true` if authorizing and `false` if unauthorizing
    function authorizeSpender(address _spender, bool _authorize) onlyContractOwner {
        allowedSpenders[_spender] = _authorize;
        SpenderAuthorization(_spender, _authorize);
    }

    /// @notice `onlyOwner` Sets the address of `securityGuard`
    /// @param _newSecurityGuard Address of the new security guard
    function setSecurityGuard(address _newSecurityGuard) onlyContractOwner {
        securityGuard = _newSecurityGuard;
    }

    /// @notice `onlyOwner` Changes `timeLock`; the new `timeLock` cannot be
    ///  lower than `absoluteMinTimeLock`
    /// @param _newTimeLock Sets the new minimum default `timeLock` in seconds;
    ///  pending payments maintain their `earliestPayTime`
    function setTimelock(uint _newTimeLock) onlyContractOwner {
        if (_newTimeLock < absoluteMinTimeLock) throw;
        timeLock = _newTimeLock;
    }

    /// @notice `onlyOwner` Changes the maximum number of seconds
    /// `securityGuard` can delay a payment
    /// @param _maxSecurityGuardDelay The new maximum delay in seconds that
    ///  `securityGuard` can delay the payment&#39;s execution in total
    function setMaxSecurityGuardDelay(uint _maxSecurityGuardDelay) onlyContractOwner {
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }
}


contract Asset {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

contract BuyBackEmitter {
    function emitError(uint errorCode);
    function emitPricesUpdated(uint buyPrice, uint sellPrice);
    function emitActiveChanged(bool isActive);
}


contract BuyBack is Object {

    uint constant ERROR_EXCHANGE_INVALID_PARAMETER = 6000;
    uint constant ERROR_EXCHANGE_INVALID_INVOCATION = 6001;
    uint constant ERROR_EXCHANGE_INVALID_FEE_PERCENT = 6002;
    uint constant ERROR_EXCHANGE_INVALID_PRICE = 6003;
    uint constant ERROR_EXCHANGE_MAINTENANCE_MODE = 6004;
    uint constant ERROR_EXCHANGE_TOO_HIGH_PRICE = 6005;
    uint constant ERROR_EXCHANGE_TOO_LOW_PRICE = 6006;
    uint constant ERROR_EXCHANGE_INSUFFICIENT_BALANCE = 6007;
    uint constant ERROR_EXCHANGE_INSUFFICIENT_ETHER_SUPPLY = 6008;
    uint constant ERROR_EXCHANGE_PAYMENT_FAILED = 6009;
    uint constant ERROR_EXCHANGE_TRANSFER_FAILED = 6010;
    uint constant ERROR_EXCHANGE_FEE_TRANSFER_FAILED = 6011;
    uint constant ERROR_EXCHANGE_DELAYEDPAYMENTS_ACCESS = 6012;

    // Assigned ERC20 token.
    Asset public asset;
    DelayedPayments public delayedPayments;
    //Switch for turn on and off the exchange operations
    bool public isActive;
    // Price in wei at which exchange buys tokens.
    uint public buyPrice = 1;
    // Price in wei at which exchange sells tokens.
    uint public sellPrice = 2570735391000000; // 80% from ETH/USD=311.1950
    uint public minAmount;
    uint public maxAmount;
    // User sold tokens and received wei.
    event Sell(address indexed who, uint token, uint eth);
    // User bought tokens and payed wei.
    event Buy(address indexed who, uint token, uint eth);
    event WithdrawTokens(address indexed recipient, uint amount);
    event WithdrawEth(address indexed recipient, uint amount);
    event PricesUpdated(address indexed self, uint buyPrice, uint sellPrice);
    event ActiveChanged(address indexed self, bool isActive);
    event Error(uint errorCode);

    /**
     * @dev On received ethers
     * @param sender Ether sender
     * @param amount Ether value
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);

    // Should use interface of the emitter, but address of events history.
    BuyBackEmitter public eventsHistory;

    /**
     * Emits Error event with specified error message.
     *
     * Should only be used if no state changes happened.
     *
     * @param error error from Errors library.
     */
    function _error(uint error) internal returns (uint) {
        getEventsHistory().emitError(error);
        return error;
    }

    function _emitPricesUpdated(uint buyPrice, uint sellPrice) internal {
        getEventsHistory().emitPricesUpdated(buyPrice, sellPrice);
    }

    function _emitActiveChanged(bool isActive) internal {
        getEventsHistory().emitActiveChanged(isActive);
    }

    /**
     * Sets EventsHstory contract address.
     *
     * Can be set only once, and only by contract owner.
     *
     * @param _eventsHistory MultiEventsHistory contract address.
     *
     * @return success.
     */
    function setupEventsHistory(address _eventsHistory) onlyContractOwner returns (uint) {
        if (address(eventsHistory) != 0x0) {
            return _error(ERROR_EXCHANGE_INVALID_INVOCATION);
        }

        eventsHistory = BuyBackEmitter(_eventsHistory);
        return OK;
    }

    /**
     * Assigns ERC20 token for exchange.
     *
     * Can be set only once, and only by contract owner.
     *
     * @param _asset ERC20 token address.
     *
     * @return success.
     */
    function init(Asset _asset, DelayedPayments _delayedPayments) onlyContractOwner returns (uint errorCode) {
        if (address(asset) != 0x0 || address(delayedPayments) != 0x0) {
            return _error(ERROR_EXCHANGE_INVALID_INVOCATION);
        }

        asset = _asset;
        delayedPayments = _delayedPayments;
        isActive = true;
        return OK;
    }

    function setActive(bool _active) onlyContractOwner returns (uint) {
        if (isActive != _active) {
            _emitActiveChanged(_active);
        }

        isActive = _active;
        return OK;
    }

    /**
     * Set exchange operation prices.
     * Sell price cannot be less than buy price.
     *
     * Can be set only by contract owner.
     *
     * @param _buyPrice price in wei at which exchange buys tokens.
     * @param _sellPrice price in wei at which exchange sells tokens.
     *
     * @return success.
     */
    function setPrices(uint _buyPrice, uint _sellPrice) onlyContractOwner returns (uint) {
        if (_sellPrice < _buyPrice) {
            return _error(ERROR_EXCHANGE_INVALID_PRICE);
        }

        buyPrice = _buyPrice;
        sellPrice = _sellPrice;
        _emitPricesUpdated(_buyPrice, _sellPrice);

        return OK;
    }

    /**
     * Returns assigned token address balance.
     *
     * @param _address address to get balance.
     *
     * @return token balance.
     */
    function _balanceOf(address _address) constant internal returns (uint) {
        return asset.balanceOf(_address);
    }

    /**
     * Sell tokens for ether at specified price. Tokens are taken from caller
     * though an allowance logic.
     * Amount should be less than or equal to current allowance value.
     * Price should be less than or equal to current exchange buyPrice.
     *
     * @param _amount amount of tokens to sell.
     * @param _price price in wei at which sell will happen.
     *
     * @return success.
     */
    function sell(uint _amount, uint _price) returns (uint) {
        if (!isActive) {
            return _error(ERROR_EXCHANGE_MAINTENANCE_MODE);
        }

        if (_price > buyPrice) {
            return _error(ERROR_EXCHANGE_TOO_HIGH_PRICE);
        }

        if (_balanceOf(msg.sender) < _amount) {
            return _error(ERROR_EXCHANGE_INSUFFICIENT_BALANCE);
        }

        uint total = _mul(_amount, _price);
        if (this.balance < total) {
            return _error(ERROR_EXCHANGE_INSUFFICIENT_ETHER_SUPPLY);
        }

        if (!asset.transferFrom(msg.sender, this, _amount)) {
            return _error(ERROR_EXCHANGE_PAYMENT_FAILED);
        }

        if (!delayedPayments.send(total)) {
            throw;
        }
        if (!delayedPayments.allowedSpenders(this)) {
            throw;
        }
        delayedPayments.authorizePayment(msg.sender,total,1 hours); 
        Sell(msg.sender, _amount, total);

        return OK;
    }

    /**
     * Transfer specified amount of tokens from exchange to specified address.
     *
     * Can be called only by contract owner.
     *
     * @param _recipient address to transfer tokens to.
     * @param _amount amount of tokens to transfer.
     *
     * @return success.
     */
    function withdrawTokens(address _recipient, uint _amount) onlyContractOwner returns (uint) {
        if (_balanceOf(this) < _amount) {
            return _error(ERROR_EXCHANGE_INSUFFICIENT_BALANCE);
        }

        if (!asset.transfer(_recipient, _amount)) {
            return _error(ERROR_EXCHANGE_TRANSFER_FAILED);
        }

        WithdrawTokens(_recipient, _amount);

        return OK;
    }

    /**
     * Transfer all tokens from exchange to specified address.
     *
     * Can be called only by contract owner.
     *
     * @param _recipient address to transfer tokens to.
     *
     * @return success.
     */
    function withdrawAllTokens(address _recipient) onlyContractOwner returns (uint) {
        return withdrawTokens(_recipient, _balanceOf(this));
    }

    /**
     * Transfer specified amount of wei from exchange to specified address.
     *
     * Can be called only by contract owner.
     *
     * @param _recipient address to transfer wei to.
     * @param _amount amount of wei to transfer.
     *
     * @return success.
     */
    function withdrawEth(address _recipient, uint _amount) onlyContractOwner returns (uint) {
        if (this.balance < _amount) {
            return _error(ERROR_EXCHANGE_INSUFFICIENT_ETHER_SUPPLY);
        }

        if (!_recipient.send(_amount)) {
            return _error(ERROR_EXCHANGE_TRANSFER_FAILED);
        }

        WithdrawEth(_recipient, _amount);

        return OK;
    }

    /**
     * Transfer all wei from exchange to specified address.
     *
     * Can be called only by contract owner.
     *
     * @param _recipient address to transfer wei to.
     *
     * @return success.
     */
    function withdrawAllEth(address _recipient) onlyContractOwner() returns (uint) {
        return withdrawEth(_recipient, this.balance);
    }

    /**
     * Transfer all tokens and wei from exchange to specified address.
     *
     * Can be called only by contract owner.
     *
     * @param _recipient address to transfer tokens and wei to.
     *
     * @return success.
     */
    function withdrawAll(address _recipient) onlyContractOwner returns (uint) {
        uint withdrawAllTokensResult = withdrawAllTokens(_recipient);
        if (withdrawAllTokensResult != OK) {
            return withdrawAllTokensResult;
        }

        uint withdrawAllEthResult = withdrawAllEth(_recipient);
        if (withdrawAllEthResult != OK) {
            return withdrawAllEthResult;
        }

        return OK;
    }

    function emitError(uint errorCode) {
        Error(errorCode);
    }

    function emitPricesUpdated(uint buyPrice, uint sellPrice) {
        PricesUpdated(msg.sender, buyPrice, sellPrice);
    }

    function emitActiveChanged(bool isActive) {
        ActiveChanged(msg.sender, isActive);
    }

    function getEventsHistory() constant returns (BuyBackEmitter) {
        return address(eventsHistory) != 0x0 ? eventsHistory : BuyBackEmitter(this);
    }
    /**
     * Overflow-safe multiplication.
     *
     * Throws in case of value overflow.
     *
     * @param _a first operand.
     * @param _b second operand.
     *
     * @return multiplication result.
     */
    function _mul(uint _a, uint _b) internal constant returns (uint) {
        uint result = _a * _b;
        if (_a != 0 && result / _a != _b) {
            throw;
        }
        return result;
    }

    /**
     * Accept all ether to maintain exchange supply.
     */
    function() payable {
        if (msg.value != 0) {
            ReceivedEther(msg.sender, msg.value);
        } else {
            throw;
        }
    }
}