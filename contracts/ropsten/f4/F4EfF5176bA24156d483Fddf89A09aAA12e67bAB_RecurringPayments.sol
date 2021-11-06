/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Recurring Payments & Subscriptions on Ethereum
/// @author Jonathan Becker <[email protected]>
/// @notice This is an implementation of recurring payments & subscriptions
///         on ethereum which utilizes an application of ERC20's approval
///         as well as a timelocked proxy of ERC20's transferFrom() to safely
///         handle recurring payments that can be cancelled any time
/// @dev Unlimited approval is not required. We only require an approval of
///      > ( subscriptionCost * 2 ) ERC20 tokens
/// @custom:experimental This is an experimental contract, and is still a PoC
///                      https://jbecker.dev/research/ethereum-recurring-payments/

contract ERC20Interface {
  function approve(address spender, uint256 value) public virtual returns (bool) {}
  function transfer(address to, uint256 value) public virtual returns (bool) {}
  function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {}
  function name() public view virtual returns (string memory) {}
  function symbol() public view virtual returns (string memory) {}
  function decimals() public view virtual returns (uint256) {}
  function totalSupply() public view virtual returns (uint256) {}
  function balanceOf(address account) public view virtual returns (uint256) {}
  function allowance(address owner, address spender) public view virtual returns (uint256) {}
}

contract RecurringPayments {



  event NewSubscription(
    address Customer,
    address Payee,
    uint256 Allowance,
    address TokenAddress,
    string Name,
    string Description,
    uint256 LastExecutionDate,
    uint256 SubscriptionPeriod
  );
  event SubscriptionCancelled(
    address Customer,
    address Payee
  );
  event SubscriptionPaid(
    address Customer,
    address Payee,
    uint256 PaymentDate,
    uint256 PaymentAmount,
    uint256 NextPaymentDate
  );


  /// @dev Correct mapping is _customer, then _payee. Holds information about
  ///      an addresses subscriptions using the Subscription struct
  mapping(address => mapping(address => Subscription)) public subscriptions;


  /// @notice This is the subscription struct which holds all information on a
  ///         subscription
  /// @dev    TokenAddress must be a conforming ERC20 contract that supports the
  ///         ERC20Interface
  /// @param Customer           : The customer's address 
  /// @param Payee              : The payee's address 
  /// @param Allowance          : Total cost of ERC20 tokens per SubscriptionPeriod
  /// @param TokenAddress       : A conforming ERC20 token contract address
  /// @param Name               : Name of the subscription
  /// @param Description        : A short description of the subscription
  /// @param LastExecutionDate  : The last time this subscription was paid (UNIX)
  /// @param SubscriptionPeriod : UNIX time for subscription period. For example
  ///                             86400 would be 1 day, which means this Subscription
  ///                             would be charged every day
  /// @param IsActive           : A boolean that marks if this subscription is active 
  ///                             or has been cancelled
  struct Subscription {
    address Customer;
    address Payee;
    uint256 Allowance;
    address TokenAddress;
    string Name;
    string Description;
    uint256 LastExecutionDate;
    uint256 SubscriptionPeriod;
    bool IsActive;
    bool Exists;
  }



  constructor() {
  }



  /// @notice Returns the subscription of _customer and _payee
  /// @dev    Will return regardless if found or not. Use getSubscription(_customer, _payee)
  ///         Exists to test if the subscription really exists
  /// @param _customer : The customer's address 
  /// @param _payee    : The payee's address
  /// @return Subscription from mapping subscriptions
  function getSubscription(address _customer, address _payee) public view returns(Subscription memory){
    return subscriptions[_customer][_payee];
  }

  /// @notice Returns time in seconds remaining before this subscription may be executed
  /// @dev    A return of 0 means the subscripion is ready to be executed
  /// @param _customer : The customer's address 
  /// @param _payee    : The payee's address
  /// @return Time in seconds until this subscription comes due
  function subscriptionTimeRemaining(address _customer, address _payee) public view returns(uint256){
    uint256 remaining = getSubscription(_customer, _payee).LastExecutionDate+getSubscription(_customer, _payee).SubscriptionPeriod;
    if(block.timestamp > remaining){
      return 0;
    }
    else {
      return remaining - block.timestamp;
    }
  }

  /// @notice Creates a new subscription. Must be called by the customer. This will automatically
  ///         create the first subscription charge of _subscriptionCost tokens
  /// @dev    Emits an ERC20 {Transfer} event, as well as {NewSubscription} and {SubscriptionPaid}
  ///         Requires at least an ERC20 allowance to this contract of (_subscriptionCost * 2) tokens
  /// @param _payee              : The payee's address
  /// @param _subscriptionCost   : The cost in ERC20 tokens that will be charged every _subscriptionPeriod
  /// @param _token              : The ERC20 compliant token address
  /// @param _name               : Name of the subscription
  /// @param _description        : A short description of the subscription
  /// @param _subscriptionPeriod : UNIX time for subscription period. For example
  ///                              86400 would be 1 day, which means this Subscription
  ///                              would be charged every day
  function createSubscription(
    address _payee,
    uint256 _subscriptionCost, 
    address _token, 
    string memory _name, 
    string memory _description, 
    uint256 _subscriptionPeriod ) public virtual {
    ERC20Interface tokenInterface;
    tokenInterface = ERC20Interface(_token);

    require(getSubscription(msg.sender, _payee).IsActive != true, "0xSUB: Active subscription already exists.");
    require(_subscriptionCost <= tokenInterface.balanceOf(msg.sender), "0xSUB: Insufficient token balance.");
    require(_subscriptionPeriod > 0, "0xSUB: Subscription period must be greater than 0.");

    subscriptions[msg.sender][_payee] = Subscription(
      msg.sender,
      _payee,
      _subscriptionCost,
      _token,
      _name,
      _description,
      block.timestamp,
      _subscriptionPeriod,
      true,
      true
    );
    require((tokenInterface.allowance(msg.sender, address(this)) >= (_subscriptionCost * 2)) && (tokenInterface.allowance(msg.sender, address(this)) <= 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), "0xSUB: Allowance of (_subscriptionCost * 2) required.");
    require(tokenInterface.transferFrom(msg.sender, _payee, _subscriptionCost), "0xSUB: Initial subscription payment failed.");


    emit NewSubscription(msg.sender, _payee, _subscriptionCost, _token, _name, _description, block.timestamp, _subscriptionPeriod);
    emit SubscriptionPaid(msg.sender, _payee, block.timestamp, _subscriptionCost, block.timestamp+_subscriptionPeriod);
  }
  
  /// @notice Cancells a subscription. May be called by either customer or payee
  /// @dev    Emits a {SubscriptionCancelled} event, and disallows execution of future
  ///         subscription charges
  /// @param _customer : The customer's address 
  /// @param _payee    : The payee's address
  function cancelSubscription(
    address _customer,
    address _payee ) public virtual {
    require((getSubscription(_customer, _payee).Customer == msg.sender || getSubscription(_customer, _payee).Payee == msg.sender), "0xSUB: Only subscription parties can cancel a subscription.");
    require(getSubscription(_customer, _payee).IsActive == true, "0xSUB: Subscription already inactive.");

    subscriptions[_customer][_payee].IsActive = false;

    emit SubscriptionCancelled(_customer, _payee);
  }

  /// @notice Executes a subscription payment. Must be called by the _payee
  /// @dev    Emits a {SubscriptionPaid} event. Requires SubscriptionPeriod to have a passed since LastExecutionDate,
  ///         as well as an ERC20 transferFrom to succeed
  /// @param _customer : The customer's address 
  function executePayment(
    address _customer
  ) public virtual {
    require(getSubscription(_customer, msg.sender).Payee == msg.sender, "0xSUB: Only subscription payees may execute a subscription payment.");
    require(getSubscription(_customer, msg.sender).IsActive == true, "0xSUB: Subscription already inactive.");
    require(_subscriptionPaid(_customer, msg.sender) != true, "0xSUB: Subscription already paid for this period.");

    ERC20Interface tokenInterface;
    tokenInterface = ERC20Interface(getSubscription(_customer, msg.sender).TokenAddress);

    subscriptions[_customer][msg.sender].LastExecutionDate = block.timestamp;
    require(tokenInterface.transferFrom(_customer, msg.sender, getSubscription(_customer, msg.sender).Allowance), "0xSUB: Subscription payment failed.");


    emit SubscriptionPaid(_customer, msg.sender, block.timestamp, getSubscription(_customer, msg.sender).Allowance, block.timestamp+getSubscription(_customer, msg.sender).SubscriptionPeriod);
  }



  /// @notice Determines wether or not this subscription has been paid this period
  /// @param _customer : The customer's address 
  /// @param _payee    : The payee's address
  /// @return Returns a boolean true if the subscription has been charged for this period, false if otherwise
  function _subscriptionPaid(address _customer, address _payee) internal view returns(bool){
    uint256 remaining = getSubscription(_customer, _payee).LastExecutionDate+getSubscription(_customer, _payee).SubscriptionPeriod;
    if(block.timestamp > remaining){
      return false;
    }
    else {
      return true;
    }
  }

}