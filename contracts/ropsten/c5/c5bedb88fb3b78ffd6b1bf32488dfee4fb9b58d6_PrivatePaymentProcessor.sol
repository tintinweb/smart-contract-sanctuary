pragma solidity ^0.4.24;

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/ownership/Contactable.sol

/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable {

  string public contactInformation;

  /**
    * @dev Allows the owner to set a string with their contact information.
    * @param _info The contact information to attach to the contract.
    */
  function setContactInformation(string _info) public onlyOwner {
    contactInformation = _info;
  }
}

// File: contracts/Restricted.sol

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

        emit MonethaAddressSet(_address, _isMonethaAddress);
    }
}

// File: contracts/GenericERC20.sol

/**
* @title GenericERC20 interface
*/
contract GenericERC20 {
    function totalSupply() public view returns (uint256);

    function decimals() public view returns(uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);
        
    // Return type not defined intentionally since not all ERC20 tokens return proper result type
    function transfer(address _to, uint256 _value) public;

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

// File: contracts/IMonethaVoucher.sol

interface IMonethaVoucher {
    /**
    * @dev Total number of vouchers in shared pool
    */
    function totalInSharedPool() external view returns (uint256);

    /**
     * @dev Converts vouchers to equivalent amount of wei.
     * @param _value amount of vouchers (vouchers) to convert to amount of wei
     * @return A uint256 specifying the amount of wei.
     */
    function toWei(uint256 _value) external view returns (uint256);

    /**
     * @dev Converts amount of wei to equivalent amount of vouchers.
     * @param _value amount of wei to convert to vouchers (vouchers)
     * @return A uint256 specifying the amount of vouchers.
     */
    function fromWei(uint256 _value) external view returns (uint256);

    /**
     * @dev Applies discount for address by returning vouchers to shared pool and transferring funds (in wei). May be called only by Monetha.
     * @param _for address to apply discount for
     * @param _vouchers amount of vouchers to return to shared pool
     * @return Actual number of vouchers returned to shared pool and amount of funds (in wei) transferred.
     */
    function applyDiscount(address _for, uint256 _vouchers) external returns (uint256 amountVouchers, uint256 amountWei);

    /**
     * @dev Applies payback by transferring vouchers from the shared pool to the user.
     * The amount of transferred vouchers is equivalent to the amount of Ether in the `_amountWei` parameter.
     * @param _for address to apply payback for
     * @param _amountWei amount of Ether to estimate the amount of vouchers
     * @return The number of vouchers added
     */
    function applyPayback(address _for, uint256 _amountWei) external returns (uint256 amountVouchers);

    /**
     * @dev Function to buy vouchers by transferring equivalent amount in Ether to contract. May be called only by Monetha.
     * After the vouchers are purchased, they can be sold or released to another user. Purchased vouchers are stored in
     * a separate pool and may not be expired.
     * @param _vouchers The amount of vouchers to buy. The caller must also transfer an equivalent amount of Ether.
     */
    function buyVouchers(uint256 _vouchers) external payable;

    /**
     * @dev The function allows Monetha account to sell previously purchased vouchers and get Ether from the sale.
     * The equivalent amount of Ether will be transferred to the caller. May be called only by Monetha.
     * @param _vouchers The amount of vouchers to sell.
     * @return A uint256 specifying the amount of Ether (in wei) transferred to the caller.
     */
    function sellVouchers(uint256 _vouchers) external returns(uint256 weis);

    /**
     * @dev Function allows Monetha account to release the purchased vouchers to any address.
     * The released voucher acquires an expiration property and should be used in Monetha ecosystem within 6 months, otherwise
     * it will be returned to shared pool. May be called only by Monetha.
     * @param _to address to release vouchers to.
     * @param _value the amount of vouchers to release.
     */
    function releasePurchasedTo(address _to, uint256 _value) external returns (bool);

    /**
     * @dev Function to check the amount of vouchers that an owner (Monetha account) allowed to sell or release to some user.
     * @param owner The address which owns the funds.
     * @return A uint256 specifying the amount of vouchers still available for the owner.
     */
    function purchasedBy(address owner) external view returns (uint256);
}

// File: contracts/MonethaGateway.sol

/**
 *  @title MonethaGateway
 *
 *  MonethaGateway forward funds from order payment to merchant&#39;s wallet and collects Monetha fee.
 */
contract MonethaGateway is Pausable, Contactable, Destructible, Restricted {

    using SafeMath for uint256;

    string constant VERSION = "0.6";

    /**
     *  Fee permille of Monetha fee.
     *  1 permille (‰) = 0.1 percent (%)
     *  15‰ = 1.5%
     */
    uint public constant FEE_PERMILLE = 15;


    uint public constant PERMILLE_COEFFICIENT = 1000;

    /**
     *  Address of Monetha Vault for fee collection
     */
    address public monethaVault;

    /**
     *  Account for permissions managing
     */
    address public admin;

    /**
     * Monetha voucher contract
     */
    IMonethaVoucher public monethaVoucher;

    /**
     *  Max. discount permille.
     *  10 permille = 1 %
     */
    uint public MaxDiscountPermille;

    event PaymentProcessedEther(address merchantWallet, uint merchantIncome, uint monethaIncome);
    event PaymentProcessedToken(address tokenAddress, address merchantWallet, uint merchantIncome, uint monethaIncome);
    event MonethaVoucherChanged(
        address indexed previousMonethaVoucher,
        address indexed newMonethaVoucher
    );
    event MaxDiscountPermilleChanged(uint prevPermilleValue, uint newPermilleValue);

    /**
     *  @param _monethaVault Address of Monetha Vault
     */
    constructor(address _monethaVault, address _admin, IMonethaVoucher _monethaVoucher) public {
        require(_monethaVault != 0x0);
        monethaVault = _monethaVault;

        setAdmin(_admin);
        setMonethaVoucher(_monethaVoucher);
        setMaxDiscountPermille(700); // 70%
    }

    /**
     *  acceptPayment accept payment from PaymentAcceptor, forwards it to merchant&#39;s wallet
     *      and collects Monetha fee.
     *  @param _merchantWallet address of merchant&#39;s wallet for fund transfer
     *  @param _monethaFee is a fee collected by Monetha
     */
    function acceptPayment(address _merchantWallet,
        uint _monethaFee,
        address _customerAddress,
        uint _vouchersApply,
        uint _paybackPermille)
    external payable onlyMonetha whenNotPaused returns (uint discountWei){
        require(_merchantWallet != 0x0);
        uint price = msg.value;
        // Monetha fee cannot be greater than 1.5% of payment
        require(_monethaFee >= 0 && _monethaFee <= FEE_PERMILLE.mul(price).div(1000));

        discountWei = 0;
        if (monethaVoucher != address(0) && _vouchersApply > 0) {
            if (MaxDiscountPermille > 0) {
                uint maxDiscountWei = price.mul(MaxDiscountPermille).div(PERMILLE_COEFFICIENT);
                uint maxVouchers = monethaVoucher.fromWei(maxDiscountWei);
                // limit vouchers to apply
                uint vouchersApply = _vouchersApply;
                if (vouchersApply > maxVouchers) {
                    vouchersApply = maxVouchers;
                }

                (, discountWei) = monethaVoucher.applyDiscount(_customerAddress, vouchersApply);
            }

            if (_paybackPermille > 0) {
                uint paybackWei = price.sub(discountWei).mul(_paybackPermille).div(PERMILLE_COEFFICIENT);
                if (paybackWei > 0) {
                    monethaVoucher.applyPayback(_customerAddress, paybackWei);
                }
            }
        }

        uint merchantIncome = price.sub(_monethaFee);

        _merchantWallet.transfer(merchantIncome);
        monethaVault.transfer(_monethaFee);

        emit PaymentProcessedEther(_merchantWallet, merchantIncome, _monethaFee);
    }

    /**
     *  acceptTokenPayment accept token payment from PaymentAcceptor, forwards it to merchant&#39;s wallet
     *      and collects Monetha fee.
     *  @param _merchantWallet address of merchant&#39;s wallet for fund transfer
     *  @param _monethaFee is a fee collected by Monetha
     *  @param _tokenAddress is the token address
     *  @param _value is the order value
     */
    function acceptTokenPayment(
        address _merchantWallet,
        uint _monethaFee,
        address _tokenAddress,
        uint _value
    )
    external onlyMonetha whenNotPaused
    {
        require(_merchantWallet != 0x0);

        // Monetha fee cannot be greater than 1.5% of payment
        require(_monethaFee >= 0 && _monethaFee <= FEE_PERMILLE.mul(_value).div(1000));

        uint merchantIncome = _value.sub(_monethaFee);

        GenericERC20(_tokenAddress).transfer(_merchantWallet, merchantIncome);
        GenericERC20(_tokenAddress).transfer(monethaVault, _monethaFee);

        emit PaymentProcessedToken(_tokenAddress, _merchantWallet, merchantIncome, _monethaFee);
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

        emit MonethaAddressSet(_address, _isMonethaAddress);
    }

    /**
     *  setAdmin allows owner to change address of admin.
     *  @param _admin New address of admin
     */
    function setAdmin(address _admin) public onlyOwner {
        require(_admin != address(0));
        admin = _admin;
    }

    /**
     *  setAdmin allows owner to change address of Monetha voucher contract. If set to 0x0 address, discounts and paybacks are disabled.
     *  @param _monethaVoucher New address of Monetha voucher contract
     */
    function setMonethaVoucher(IMonethaVoucher _monethaVoucher) public onlyOwner {
        if (monethaVoucher != _monethaVoucher) {
            emit MonethaVoucherChanged(monethaVoucher, _monethaVoucher);
            monethaVoucher = _monethaVoucher;
        }
    }

    /**
     *  setMaxDiscountPermille allows Monetha to change max.discount percentage
     *  @param _maxDiscountPermille New value of max.discount (in permille)
     */
    function setMaxDiscountPermille(uint _maxDiscountPermille) public onlyOwner {
        require(_maxDiscountPermille <= PERMILLE_COEFFICIENT);
        emit MaxDiscountPermilleChanged(MaxDiscountPermille, _maxDiscountPermille);
        MaxDiscountPermille = _maxDiscountPermille;
    }
}

// File: contracts/SafeDestructible.sol

/**
 * @title SafeDestructible
 * Base contract that can be destroyed by owner.
 * Can be destructed if there are no funds on contract balance.
 */
contract SafeDestructible is Ownable {
    function destroy() onlyOwner public {
        require(address(this).balance == 0);
        selfdestruct(owner);
    }
}

// File: contracts/MerchantWallet.sol

/**
 *  @title MerchantWallet
 *  Serves as a public Merchant profile with merchant profile info,
 *      payment settings and latest reputation value.
 *  Also MerchantWallet accepts payments for orders.
 */

contract MerchantWallet is Pausable, SafeDestructible, Contactable, Restricted {

    string constant VERSION = "0.5";

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
    constructor(address _merchantAccount, string _merchantId, address _fundAddress) public isEOA(_fundAddress) {
        require(_merchantAccount != 0x0);
        require(bytes(_merchantId).length > 0);

        merchantAccount = _merchantAccount;
        merchantIdHash = keccak256(abi.encodePacked(_merchantId));

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
    )
        external onlyOwner
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
    function withdraw(uint amount) external onlyMerchant {
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
     *  Allows merchant or Monetha to initiate exchange of tokens by withdrawing all tokens to deposit address of the exchange
     */
    function withdrawAllTokensToExchange(address _tokenAddress, address _depositAccount, uint _minAmount) external onlyMerchantOrMonetha whenNotPaused {
        require(_tokenAddress != address(0));
        
        uint balance = GenericERC20(_tokenAddress).balanceOf(address(this));
        
        require(balance >= _minAmount);
        
        GenericERC20(_tokenAddress).transfer(_depositAccount, balance);
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

// File: contracts/PrivatePaymentProcessor.sol

contract PrivatePaymentProcessor is Pausable, Destructible, Contactable, Restricted {

    using SafeMath for uint256;

    string constant VERSION = "0.6";

    /**
      *  Payback permille.
      *  1 permille = 0.1 %
      */
    uint public constant PAYBACK_PERMILLE = 2; // 0.2%

    // Order paid event
    event OrderPaidInEther(
        uint indexed _orderId,
        address indexed _originAddress,
        uint _price,
        uint _monethaFee,
        uint _discount
    );

    event OrderPaidInToken(
        uint indexed _orderId,
        address indexed _originAddress,
        address indexed _tokenAddress,
        uint _price,
        uint _monethaFee
    );

    // Payments have been processed event
    event PaymentsProcessed(
        address indexed _merchantAddress,
        uint _amount,
        uint _fee
    );

    // PaymentRefunding is an event when refunding initialized
    event PaymentRefunding(
        uint indexed _orderId,
        address indexed _clientAddress,
        uint _amount,
        string _refundReason
    );

    // PaymentWithdrawn event is fired when payment is withdrawn
    event PaymentWithdrawn(
        uint indexed _orderId,
        address indexed _clientAddress,
        uint amount
    );

    /// MonethaGateway contract for payment processing
    MonethaGateway public monethaGateway;

    /// Address of MerchantWallet, where merchant reputation and funds are stored
    MerchantWallet public merchantWallet;

    /// Merchant identifier hash, that associates with the acceptor
    bytes32 public merchantIdHash;

    enum WithdrawState {Null, Pending, Withdrawn}

    struct Withdraw {
        WithdrawState state;
        uint amount;
        address clientAddress;
    }

    mapping(uint => Withdraw) public withdrawals;

    /**
     *  Private Payment Processor sets Monetha Gateway and Merchant Wallet.
     *  @param _merchantId Merchant of the acceptor
     *  @param _monethaGateway Address of MonethaGateway contract for payment processing
     *  @param _merchantWallet Address of MerchantWallet, where merchant reputation and funds are stored
     */
    constructor(
        string _merchantId,
        MonethaGateway _monethaGateway,
        MerchantWallet _merchantWallet
    )
    public
    {
        require(bytes(_merchantId).length > 0);

        merchantIdHash = keccak256(abi.encodePacked(_merchantId));

        setMonethaGateway(_monethaGateway);
        setMerchantWallet(_merchantWallet);
    }

    /**
     *  payForOrder is used by order wallet/client to pay for the order
     *  @param _orderId Identifier of the order
     *  @param _originAddress buyer address
     *  @param _monethaFee is fee collected by Monetha
     */
    function payForOrder(
        uint _orderId,
        address _originAddress,
        uint _monethaFee,
        uint _vouchersApply
    )
    external payable whenNotPaused
    {
        require(_orderId > 0);
        require(_originAddress != 0x0);
        require(msg.value > 0);

        address fundAddress;
        fundAddress = merchantWallet.merchantFundAddress();

        uint discountWei = 0;
        if (fundAddress != address(0)) {
            discountWei = monethaGateway.acceptPayment.value(msg.value)(
                fundAddress,
                _monethaFee,
                _originAddress,
                _vouchersApply,
                PAYBACK_PERMILLE);
        } else {
            discountWei = monethaGateway.acceptPayment.value(msg.value)(
                merchantWallet,
                _monethaFee,
                _originAddress,
                _vouchersApply,
                PAYBACK_PERMILLE);
        }

        // log payment event
        emit OrderPaidInEther(_orderId, _originAddress, msg.value, _monethaFee, discountWei);
    }

    /**
     *  payForOrderInTokens is used by order wallet/client to pay for the order
     *  This call requires that token&#39;s approve method has been called prior to this.
     *  @param _orderId Identifier of the order
     *  @param _originAddress buyer address
     *  @param _monethaFee is fee collected by Monetha
     *  @param _tokenAddress is tokens address
     *  @param _orderValue is order amount
     */
    function payForOrderInTokens(
        uint _orderId,
        address _originAddress,
        uint _monethaFee,
        address _tokenAddress,
        uint _orderValue
    )
    external whenNotPaused
    {
        require(_orderId > 0);
        require(_originAddress != 0x0);
        require(_orderValue > 0);
        require(_tokenAddress != address(0));

        address fundAddress;
        fundAddress = merchantWallet.merchantFundAddress();

        GenericERC20(_tokenAddress).transferFrom(msg.sender, address(this), _orderValue);

        GenericERC20(_tokenAddress).transfer(address(monethaGateway), _orderValue);

        if (fundAddress != address(0)) {
            monethaGateway.acceptTokenPayment(fundAddress, _monethaFee, _tokenAddress, _orderValue);
        } else {
            monethaGateway.acceptTokenPayment(merchantWallet, _monethaFee, _tokenAddress, _orderValue);
        }

        // log payment event
        emit OrderPaidInToken(_orderId, _originAddress, _tokenAddress, _orderValue, _monethaFee);
    }

    /**
     *  refundPayment used in case order cannot be processed and funds need to be returned
     *  This function initiate process of funds refunding to the client.
     *  @param _orderId Identifier of the order
     *  @param _clientAddress is an address of client
     *  @param _refundReason Order refund reason
     */
    function refundPayment(
        uint _orderId,
        address _clientAddress,
        string _refundReason
    )
    external payable onlyMonetha whenNotPaused
    {
        require(_orderId > 0);
        require(_clientAddress != 0x0);
        require(msg.value > 0);
        require(WithdrawState.Null == withdrawals[_orderId].state);

        // create withdraw
        withdrawals[_orderId] = Withdraw({
            state : WithdrawState.Pending,
            amount : msg.value,
            clientAddress : _clientAddress
            });

        // log refunding
        emit PaymentRefunding(_orderId, _clientAddress, msg.value, _refundReason);
    }

    /**
     *  refundTokenPayment used in case order cannot be processed and tokens need to be returned
     *  This call requires that token&#39;s approve method has been called prior to this.
     *  This function initiate process of refunding tokens to the client.
     *  @param _orderId Identifier of the order
     *  @param _clientAddress is an address of client
     *  @param _refundReason Order refund reason
     *  @param _tokenAddress is tokens address
     *  @param _orderValue is order amount
     */
    function refundTokenPayment(
        uint _orderId,
        address _clientAddress,
        string _refundReason,
        uint _orderValue,
        address _tokenAddress
    )
    external onlyMonetha whenNotPaused
    {
        require(_orderId > 0);
        require(_clientAddress != 0x0);
        require(_orderValue > 0);
        require(_tokenAddress != address(0));
        require(WithdrawState.Null == withdrawals[_orderId].state);

        GenericERC20(_tokenAddress).transferFrom(msg.sender, address(this), _orderValue);

        // create withdraw
        withdrawals[_orderId] = Withdraw({
            state : WithdrawState.Pending,
            amount : _orderValue,
            clientAddress : _clientAddress
            });

        // log refunding
        emit PaymentRefunding(_orderId, _clientAddress, _orderValue, _refundReason);
    }

    /**
     *  withdrawRefund performs fund transfer to the client&#39;s account.
     *  @param _orderId Identifier of the order
     */
    function withdrawRefund(uint _orderId)
    external whenNotPaused
    {
        Withdraw storage withdraw = withdrawals[_orderId];
        require(WithdrawState.Pending == withdraw.state);

        address clientAddress = withdraw.clientAddress;
        uint amount = withdraw.amount;

        // changing withdraw state before transfer
        withdraw.state = WithdrawState.Withdrawn;

        // transfer fund to clients account
        clientAddress.transfer(amount);

        // log withdrawn
        emit PaymentWithdrawn(_orderId, clientAddress, amount);
    }

    /**
     *  withdrawTokenRefund performs token transfer to the client&#39;s account.
     *  @param _orderId Identifier of the order
     *  @param _tokenAddress token address
     */
    function withdrawTokenRefund(uint _orderId, address _tokenAddress)
    external whenNotPaused
    {
        require(_tokenAddress != address(0));

        Withdraw storage withdraw = withdrawals[_orderId];
        require(WithdrawState.Pending == withdraw.state);

        address clientAddress = withdraw.clientAddress;
        uint amount = withdraw.amount;

        // changing withdraw state before transfer
        withdraw.state = WithdrawState.Withdrawn;

        // transfer fund to clients account
        GenericERC20(_tokenAddress).transfer(clientAddress, amount);

        // log withdrawn
        emit PaymentWithdrawn(_orderId, clientAddress, amount);
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
}