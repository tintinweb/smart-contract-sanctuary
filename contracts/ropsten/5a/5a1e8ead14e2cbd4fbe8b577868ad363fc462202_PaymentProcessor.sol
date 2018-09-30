pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable {

  string public contactInformation;

  /**
    * @dev Allows the owner to set a string with their contact information.
    * @param info The contact information to attach to the contract.
    */
  function setContactInformation(string info) onlyOwner public {
    contactInformation = info;
  }
}


/** @title Restricted
 *  Exposes onlyMonetha modifier
 */
contract Restricted is Ownable {

    //MonethaAddress set event
    event MonethaAddressSet(
        address _address,
        bool _isMonethaAddress
    );

    mapping (address => bool) public isMonethaAddress;

    /**
     *  Restrict methods in such way, that they can be invoked only by monethaAddress account.
     */
    modifier onlyMonetha() {
        require(isMonethaAddress[msg.sender]);
        _;
    }

    /**
     *  Allows owner to set new monetha address
     */
    function setMonethaAddress(address _address, bool _isMonethaAddress) onlyOwner public {
        isMonethaAddress[_address] = _isMonethaAddress;

        MonethaAddressSet(_address, _isMonethaAddress);
    }
}


/**
 *  @title MonethaGateway
 *
 *  MonethaGateway forward funds from order payment to merchant&#39;s wallet and collects Monetha fee.
 */
contract MonethaGateway is Pausable, Contactable, Destructible, Restricted {

    using SafeMath for uint256;
    
    string constant VERSION = "0.4";

    /**
     *  Fee permille of Monetha fee.
     *  1 permille (‰) = 0.1 percent (%)
     *  15‰ = 1.5%
     */
    uint public constant FEE_PERMILLE = 15;
    
    /**
     *  Address of Monetha Vault for fee collection
     */
    address public monethaVault;

    /**
     *  Account for permissions managing
     */
    address public admin;

    event PaymentProcessedEther(address merchantWallet, uint merchantIncome, uint monethaIncome);
    event PaymentProcessedToken(address tokenAddress, address merchantWallet, uint merchantIncome, uint monethaIncome);

    /**
     *  @param _monethaVault Address of Monetha Vault
     */
    function MonethaGateway(address _monethaVault, address _admin) public {
        require(_monethaVault != 0x0);
        monethaVault = _monethaVault;
        
        setAdmin(_admin);
    }
    
    /**
     *  acceptPayment accept payment from PaymentAcceptor, forwards it to merchant&#39;s wallet
     *      and collects Monetha fee.
     *  @param _merchantWallet address of merchant&#39;s wallet for fund transfer
     *  @param _monethaFee is a fee collected by Monetha
     */
    function acceptPayment(address _merchantWallet, uint _monethaFee) external payable onlyMonetha whenNotPaused {
        require(_merchantWallet != 0x0);
        require(_monethaFee >= 0 && _monethaFee <= FEE_PERMILLE.mul(msg.value).div(1000)); // Monetha fee cannot be greater than 1.5% of payment
        
        uint merchantIncome = msg.value.sub(_monethaFee);

        _merchantWallet.transfer(merchantIncome);
        monethaVault.transfer(_monethaFee);

        PaymentProcessedEther(_merchantWallet, merchantIncome, _monethaFee);
    }

    function acceptTokenPayment(address _merchantWallet, uint _monethaFee, address _tokenAddress, uint _value) external onlyMonetha whenNotPaused {
        require(_merchantWallet != 0x0);

        // Monetha fee cannot be greater than 1.5% of payment
        require(_monethaFee >= 0 && _monethaFee <= FEE_PERMILLE.mul(_value).div(1000));

        uint merchantIncome = _value.sub(_monethaFee);
        
        ERC20(_tokenAddress).transfer(_merchantWallet, merchantIncome);
        ERC20(_tokenAddress).transfer(monethaVault, _monethaFee);
        
        PaymentProcessedToken(_tokenAddress, _merchantWallet, merchantIncome, _monethaFee);
    }

    /**
     *  changeMonethaVault allows owner to change address of Monetha Vault.
     *  @param newVault New address of Monetha Vault
     */
    function changeMonethaVault(address newVault) external onlyOwner whenNotPaused {
        monethaVault = newVault;
    }

    /**
     *  Allows other monetha account or contract to set new monetha address
     */
    function setMonethaAddress(address _address, bool _isMonethaAddress) public {
        require(msg.sender == admin || msg.sender == owner);

        isMonethaAddress[_address] = _isMonethaAddress;

        MonethaAddressSet(_address, _isMonethaAddress);
    }

    /**
     *  setAdmin allows owner to change address of admin.
     *  @param _admin New address of admin
     */
    function setAdmin(address _admin) public onlyOwner {
        require(_admin != 0x0);
        admin = _admin;
    }
}




/**
 *  @title MerchantDealsHistory
 *  Contract stores hash of Deals conditions together with parties reputation for each deal
 *  This history enables to see evolution of trust rating for both parties
 */
contract MerchantDealsHistory is Contactable, Restricted {

    string constant VERSION = "0.3";

    ///  Merchant identifier hash
    bytes32 public merchantIdHash;
    
    //Deal event
    event DealCompleted(
        uint orderId,
        address clientAddress,
        uint32 clientReputation,
        uint32 merchantReputation,
        bool successful,
        uint dealHash
    );

    //Deal cancellation event
    event DealCancelationReason(
        uint orderId,
        address clientAddress,
        uint32 clientReputation,
        uint32 merchantReputation,
        uint dealHash,
        string cancelReason
    );

    //Deal refund event
    event DealRefundReason(
        uint orderId,
        address clientAddress,
        uint32 clientReputation,
        uint32 merchantReputation,
        uint dealHash,
        string refundReason
    );

    /**
     *  @param _merchantId Merchant of the acceptor
     */
    function MerchantDealsHistory(string _merchantId) public {
        require(bytes(_merchantId).length > 0);
        merchantIdHash = keccak256(_merchantId);
    }

    /**
     *  recordDeal creates an event of completed deal
     *  @param _orderId Identifier of deal&#39;s order
     *  @param _clientAddress Address of client&#39;s account
     *  @param _clientReputation Updated reputation of the client
     *  @param _merchantReputation Updated reputation of the merchant
     *  @param _isSuccess Identifies whether deal was successful or not
     *  @param _dealHash Hashcode of the deal, describing the order (used for deal verification)
     */
    function recordDeal(
        uint _orderId,
        address _clientAddress,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        bool _isSuccess,
        uint _dealHash)
        external onlyMonetha
    {
        DealCompleted(
            _orderId,
            _clientAddress,
            _clientReputation,
            _merchantReputation,
            _isSuccess,
            _dealHash
        );
    }

    /**
     *  recordDealCancelReason creates an event of not paid deal that was cancelled 
     *  @param _orderId Identifier of deal&#39;s order
     *  @param _clientAddress Address of client&#39;s account
     *  @param _clientReputation Updated reputation of the client
     *  @param _merchantReputation Updated reputation of the merchant
     *  @param _dealHash Hashcode of the deal, describing the order (used for deal verification)
     *  @param _cancelReason deal cancelation reason (text)
     */
    function recordDealCancelReason(
        uint _orderId,
        address _clientAddress,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash,
        string _cancelReason)
        external onlyMonetha
    {
        DealCancelationReason(
            _orderId,
            _clientAddress,
            _clientReputation,
            _merchantReputation,
            _dealHash,
            _cancelReason
        );
    }

/**
     *  recordDealRefundReason creates an event of not paid deal that was cancelled 
     *  @param _orderId Identifier of deal&#39;s order
     *  @param _clientAddress Address of client&#39;s account
     *  @param _clientReputation Updated reputation of the client
     *  @param _merchantReputation Updated reputation of the merchant
     *  @param _dealHash Hashcode of the deal, describing the order (used for deal verification)
     *  @param _refundReason deal refund reason (text)
     */
    function recordDealRefundReason(
        uint _orderId,
        address _clientAddress,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash,
        string _refundReason)
        external onlyMonetha
    {
        DealRefundReason(
            _orderId,
            _clientAddress,
            _clientReputation,
            _merchantReputation,
            _dealHash,
            _refundReason
        );
    }
}


/**
 * @title SafeDestructible
 * Base contract that can be destroyed by owner.
 * Can be destructed if there are no funds on contract balance.
 */
contract SafeDestructible is Ownable {
    function destroy() onlyOwner public {
        require(this.balance == 0);
        selfdestruct(owner);
    }
}

/**
 *  @title MerchantWallet
 *  Serves as a public Merchant profile with merchant profile info,
 *      payment settings and latest reputation value.
 *  Also MerchantWallet accepts payments for orders.
 */

contract MerchantWallet is Pausable, SafeDestructible, Contactable, Restricted {

    string constant VERSION = "0.4";

    /// Address of merchant&#39;s account, that can withdraw from wallet
    address public merchantAccount;

    /// Address of merchant&#39;s fund address.
    address public merchantFundAddress;

    /// Unique Merchant identifier hash
    bytes32 public merchantIdHash;

    /// profileMap stores general information about the merchant
    mapping (string=>string) profileMap;

    /// paymentSettingsMap stores payment and order settings for the merchant
    mapping (string=>string) paymentSettingsMap;

    /// compositeReputationMap stores composite reputation, that compraises from several metrics
    mapping (string=>uint32) compositeReputationMap;

    /// number of last digits in compositeReputation for fractional part
    uint8 public constant REPUTATION_DECIMALS = 4;

    /**
     *  Restrict methods in such way, that they can be invoked only by merchant account.
     */
    modifier onlyMerchant() {
        require(msg.sender == merchantAccount);
        _;
    }

    /**
     *  Fund Address should always be Externally Owned Account and not a contract.
     */
    modifier isEOA(address _fundAddress) {
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_fundAddress)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     *  Restrict methods in such way, that they can be invoked only by merchant account or by monethaAddress account.
     */
    modifier onlyMerchantOrMonetha() {
        require(msg.sender == merchantAccount || isMonethaAddress[msg.sender]);
        _;
    }

    /**
     *  @param _merchantAccount Address of merchant&#39;s account, that can withdraw from wallet
     *  @param _merchantId Merchant identifier
     *  @param _fundAddress Merchant&#39;s fund address, where amount will be transferred.
     */
    function MerchantWallet(address _merchantAccount, string _merchantId, address _fundAddress) public isEOA(_fundAddress) {
        require(_merchantAccount != 0x0);
        require(bytes(_merchantId).length > 0);

        merchantAccount = _merchantAccount;
        merchantIdHash = keccak256(_merchantId);

        merchantFundAddress = _fundAddress;
    }

    /**
     *  Accept payment from MonethaGateway
     */
    function () external payable {
    }

    /**
     *  @return profile info by string key
     */
    function profile(string key) external constant returns (string) {
        return profileMap[key];
    }

    /**
     *  @return payment setting by string key
     */
    function paymentSettings(string key) external constant returns (string) {
        return paymentSettingsMap[key];
    }

    /**
     *  @return composite reputation value by string key
     */
    function compositeReputation(string key) external constant returns (uint32) {
        return compositeReputationMap[key];
    }

    /**
     *  Set profile info by string key
     */
    function setProfile(
        string profileKey,
        string profileValue,
        string repKey,
        uint32 repValue
    ) external onlyOwner
    {
        profileMap[profileKey] = profileValue;

        if (bytes(repKey).length != 0) {
            compositeReputationMap[repKey] = repValue;
        }
    }

    /**
     *  Set payment setting by string key
     */
    function setPaymentSettings(string key, string value) external onlyOwner {
        paymentSettingsMap[key] = value;
    }

    /**
     *  Set composite reputation value by string key
     */
    function setCompositeReputation(string key, uint32 value) external onlyMonetha {
        compositeReputationMap[key] = value;
    }

    /**
     *  Allows withdrawal of funds to beneficiary address
     */
    function doWithdrawal(address beneficiary, uint amount) private {
        require(beneficiary != 0x0);
        beneficiary.transfer(amount);
    }

    /**
     *  Allows merchant to withdraw funds to beneficiary address
     */
    function withdrawTo(address beneficiary, uint amount) public onlyMerchant whenNotPaused {
        doWithdrawal(beneficiary, amount);
    }

    /**
     *  Allows merchant to withdraw funds to it&#39;s own account
     */
    function withdraw(uint amount) external {
        withdrawTo(msg.sender, amount);
    }

    /**
     *  Allows merchant or Monetha to initiate exchange of funds by withdrawing funds to deposit address of the exchange
     */
    function withdrawToExchange(address depositAccount, uint amount) external onlyMerchantOrMonetha whenNotPaused {
        doWithdrawal(depositAccount, amount);
    }

    /**
     *  Allows merchant or Monetha to initiate exchange of funds by withdrawing all funds to deposit address of the exchange
     */
    function withdrawAllToExchange(address depositAccount, uint min_amount) external onlyMerchantOrMonetha whenNotPaused {
        require (address(this).balance >= min_amount);
        doWithdrawal(depositAccount, address(this).balance);
    }

    /**
     *  Allows merchant to change it&#39;s account address
     */
    function changeMerchantAccount(address newAccount) external onlyMerchant whenNotPaused {
        merchantAccount = newAccount;
    }

    /**
     *  Allows merchant to change it&#39;s fund address.
     */
    function changeFundAddress(address newFundAddress) external onlyMerchant isEOA(newFundAddress) {
        merchantFundAddress = newFundAddress;
    }
}

/**
* @title ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 {
    function totalSupply() public view returns (uint256);
    
    function decimals() public view returns(uint256);

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




/**
 *  @title PaymentProcessor
 *  Each Merchant has one PaymentProcessor that ensure payment and order processing with Trust and Reputation
 *
 *  Payment Processor State Transitions:
 *  Null -(addOrder) -> Created
 *  Created -(securePay) -> Paid
 *  Created -(cancelOrder) -> Cancelled
 *  Paid -(refundPayment) -> Refunding
 *  Paid -(processPayment) -> Finalized
 *  Refunding -(withdrawRefund) -> Refunded
 */


contract PaymentProcessor is Pausable, Destructible, Contactable, Restricted {

    using SafeMath for uint256;

    string constant VERSION = "0.4";

    /**
     *  Fee permille of Monetha fee.
     *  1 permille = 0.1 %
     *  15 permille = 1.5%
     */
    uint public constant FEE_PERMILLE = 15;

    /// MonethaGateway contract for payment processing
    MonethaGateway public monethaGateway;

    /// MerchantDealsHistory contract of acceptor&#39;s merchant
    MerchantDealsHistory public merchantHistory;

    /// Address of MerchantWallet, where merchant reputation and funds are stored
    MerchantWallet public merchantWallet;

    /// Merchant identifier hash, that associates with the acceptor
    bytes32 public merchantIdHash;

    mapping (uint=>Order) public orders;

    enum State {Null, Created, Paid, Finalized, Refunding, Refunded, Cancelled}

    struct Order {
        State state;
        uint price;
        uint fee;
        address paymentAcceptor;
        address originAddress;
        address tokenAddress;
    }

    /**
     *  Asserts current state.
     *  @param _state Expected state
     *  @param _orderId Order Id
     */
    modifier atState(uint _orderId, State _state) {
        require(_state == orders[_orderId].state);
        _;
    }

    /**
     *  Performs a transition after function execution.
     *  @param _state Next state
     *  @param _orderId Order Id
     */
    modifier transition(uint _orderId, State _state) {
        _;
        orders[_orderId].state = _state;
    }

    /**
     *  payment Processor sets Monetha Gateway
     *  @param _merchantId Merchant of the acceptor
     *  @param _merchantHistory Address of MerchantDealsHistory contract of acceptor&#39;s merchant
     *  @param _monethaGateway Address of MonethaGateway contract for payment processing
     *  @param _merchantWallet Address of MerchantWallet, where merchant reputation and funds are stored
     */
    function PaymentProcessor(
        string _merchantId,
        MerchantDealsHistory _merchantHistory,
        MonethaGateway _monethaGateway,
        MerchantWallet _merchantWallet
    ) public
    {
        require(bytes(_merchantId).length > 0);

        merchantIdHash = keccak256(_merchantId);

        setMonethaGateway(_monethaGateway);
        setMerchantWallet(_merchantWallet);
        setMerchantDealsHistory(_merchantHistory);
    }

    /**
     *  Assigns the acceptor to the order (when client initiates order).
     *  @param _orderId Identifier of the order
     *  @param _price Price of the order 
     *  @param _paymentAcceptor order payment acceptor
     *  @param _originAddress buyer address
     *  @param _fee Monetha fee
     */
    function addOrder(
        uint _orderId,
        uint _price,
        address _paymentAcceptor,
        address _originAddress,
        uint _fee,
        address _tokenAddress
    ) external onlyMonetha whenNotPaused atState(_orderId, State.Null)
    {
        require(_orderId > 0);
        require(_price > 0);
        require(_fee >= 0 && _fee <= FEE_PERMILLE.mul(_price).div(1000)); // Monetha fee cannot be greater than 1.5% of price

        orders[_orderId] = Order({
            state: State.Created,
            price: _price,
            fee: _fee,
            paymentAcceptor: _paymentAcceptor,
            originAddress: _originAddress,
            tokenAddress: _tokenAddress
        });
    }

    /**
     *  securePay can be used by client if he wants to securely set client address for refund together with payment.
     *  This function require more gas, then fallback function.
     *  @param _orderId Identifier of the order
     */
    function securePay(uint _orderId)
        external payable whenNotPaused
        atState(_orderId, State.Created) transition(_orderId, State.Paid)
    {
        Order storage order = orders[_orderId];

        require(msg.sender == order.paymentAcceptor);
        require(msg.value == order.price);
    }

    /**
     *  secureTokenPay can be used by client if he wants to securely set client address for token refund together with token payment.
     *  This call requires that token&#39;s approve method has been called prior to this.
     *  @param _orderId Identifier of the order
     */
    function secureTokenPay(uint _orderId)
        external whenNotPaused
        atState(_orderId, State.Created) transition(_orderId, State.Paid)
    {
        Order storage order = orders[_orderId];

        require(order.tokenAddress != address(0));
        
        ERC20(order.tokenAddress).transferFrom(msg.sender, address(this), order.price);
    }

    /**
     *  cancelOrder is used when client doesn&#39;t pay and order need to be cancelled.
     *  @param _orderId Identifier of the order
     *  @param _clientReputation Updated reputation of the client
     *  @param _merchantReputation Updated reputation of the merchant
     *  @param _dealHash Hashcode of the deal, describing the order (used for deal verification)
     *  @param _cancelReason Order cancel reason
     */
    function cancelOrder(
        uint _orderId,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash,
        string _cancelReason
    )
        external onlyMonetha whenNotPaused
        atState(_orderId, State.Created) transition(_orderId, State.Cancelled)
    {
        require(bytes(_cancelReason).length > 0);

        Order storage order = orders[_orderId];

        updateDealConditions(
            _orderId,
            _clientReputation,
            _merchantReputation,
            false,
            _dealHash
        );

        merchantHistory.recordDealCancelReason(
            _orderId,
            order.originAddress,
            _clientReputation,
            _merchantReputation,
            _dealHash,
            _cancelReason
        );
    }

    /**
     *  refundPayment used in case order cannot be processed.
     *  This function initiate process of funds refunding to the client.
     *  @param _orderId Identifier of the order
     *  @param _clientReputation Updated reputation of the client
     *  @param _merchantReputation Updated reputation of the merchant
     *  @param _dealHash Hashcode of the deal, describing the order (used for deal verification)
     *  @param _refundReason Order refund reason, order will be moved to State Cancelled after Client withdraws money
     */
    function refundPayment(
        uint _orderId,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash,
        string _refundReason
    )   
        external onlyMonetha whenNotPaused
        atState(_orderId, State.Paid) transition(_orderId, State.Refunding)
    {
        require(bytes(_refundReason).length > 0);

        Order storage order = orders[_orderId];

        updateDealConditions(
            _orderId,
            _clientReputation,
            _merchantReputation,
            false,
            _dealHash
        );

        merchantHistory.recordDealRefundReason(
            _orderId,
            order.originAddress,
            _clientReputation,
            _merchantReputation,
            _dealHash,
            _refundReason
        );
    }

    /**
     *  withdrawRefund performs fund transfer to the client&#39;s account.
     *  @param _orderId Identifier of the order
     */
    function withdrawRefund(uint _orderId) 
        external whenNotPaused
        atState(_orderId, State.Refunding) transition(_orderId, State.Refunded) 
    {
        Order storage order = orders[_orderId];
        order.originAddress.transfer(order.price);
    }

    /**
     *  withdrawTokenRefund performs token transfer to the client&#39;s account.
     *  @param _orderId Identifier of the order
     */
    function withdrawTokenRefund(uint _orderId)
        external whenNotPaused
        atState(_orderId, State.Refunding) transition(_orderId, State.Refunded)
    {
        require(orders[_orderId].tokenAddress != address(0));
        
        ERC20(orders[_orderId].tokenAddress).transfer(orders[_orderId].originAddress, orders[_orderId].price);
    }

    /**
     *  processPayment transfer funds/tokens to MonethaGateway and completes the order.
     *  @param _orderId Identifier of the order
     *  @param _clientReputation Updated reputation of the client
     *  @param _merchantReputation Updated reputation of the merchant
     *  @param _dealHash Hashcode of the deal, describing the order (used for deal verification)
     */
    function processPayment(
        uint _orderId,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash
    )
        external onlyMonetha whenNotPaused
        atState(_orderId, State.Paid) transition(_orderId, State.Finalized)
    {
        address fundAddress;
        fundAddress = merchantWallet.merchantFundAddress();

        if (fundAddress != address(0) && orders[_orderId].tokenAddress != address(0)) {
            ERC20(orders[_orderId].tokenAddress).transfer(address(monethaGateway), orders[_orderId].price);
            monethaGateway.acceptTokenPayment(fundAddress, orders[_orderId].fee, orders[_orderId].tokenAddress, orders[_orderId].price);
        } else if (fundAddress == address(0) && orders[_orderId].tokenAddress != address(0)) {
            ERC20(orders[_orderId].tokenAddress).transfer(address(monethaGateway), orders[_orderId].price);
            monethaGateway.acceptTokenPayment(merchantWallet, orders[_orderId].fee, orders[_orderId].tokenAddress, orders[_orderId].price);
        } else if (fundAddress != address(0) && orders[_orderId].tokenAddress == address(0)) {
            monethaGateway.acceptPayment.value(orders[_orderId].price)(fundAddress, orders[_orderId].fee);
        } else if (fundAddress == address(0) && orders[_orderId].tokenAddress == address(0)) {
            monethaGateway.acceptPayment.value(orders[_orderId].price)(merchantWallet, orders[_orderId].fee);
        }
        
        updateDealConditions(
            _orderId,
            _clientReputation,
            _merchantReputation,
            true,
            _dealHash
        );
    }

    /**
     *  setMonethaGateway allows owner to change address of MonethaGateway.
     *  @param _newGateway Address of new MonethaGateway contract
     */
    function setMonethaGateway(MonethaGateway _newGateway) public onlyOwner {
        require(address(_newGateway) != 0x0);

        monethaGateway = _newGateway;
    }

    /**
     *  setMerchantWallet allows owner to change address of MerchantWallet.
     *  @param _newWallet Address of new MerchantWallet contract
     */
    function setMerchantWallet(MerchantWallet _newWallet) public onlyOwner {
        require(address(_newWallet) != 0x0);
        require(_newWallet.merchantIdHash() == merchantIdHash);

        merchantWallet = _newWallet;
    }

    /**
     *  setMerchantDealsHistory allows owner to change address of MerchantDealsHistory.
     *  @param _merchantHistory Address of new MerchantDealsHistory contract
     */
    function setMerchantDealsHistory(MerchantDealsHistory _merchantHistory) public onlyOwner {
        require(address(_merchantHistory) != 0x0);
        require(_merchantHistory.merchantIdHash() == merchantIdHash);

        merchantHistory = _merchantHistory;
    }

    /**
     *  updateDealConditions record finalized deal and updates merchant reputation
     *  in future: update Client reputation
     *  @param _orderId Identifier of the order
     *  @param _clientReputation Updated reputation of the client
     *  @param _merchantReputation Updated reputation of the merchant
     *  @param _isSuccess Identifies whether deal was successful or not
     *  @param _dealHash Hashcode of the deal, describing the order (used for deal verification)
     */
    function updateDealConditions(
        uint _orderId,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        bool _isSuccess,
        uint _dealHash
    ) internal
    {
        merchantHistory.recordDeal(
            _orderId,
            orders[_orderId].originAddress,
            _clientReputation,
            _merchantReputation,
            _isSuccess,
            _dealHash
        );

        //update parties Reputation
        merchantWallet.setCompositeReputation("total", _merchantReputation);
    }
}