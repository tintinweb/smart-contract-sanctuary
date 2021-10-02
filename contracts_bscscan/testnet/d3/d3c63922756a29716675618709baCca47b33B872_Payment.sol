pragma solidity ^0.8.0;

import './IERC20.sol';

contract Payment {
  uint public nextPlanId;
  struct Plan {
    address merchant;
    address token;
    uint amount;
    uint frequency;
  }
  struct Subscription {
    address subscriber;
    uint start;
    uint nextPayment;
  }
  mapping(uint => Plan) public plans;
  mapping(address => mapping(uint => Subscription)) public subscriptions;

  event PlanCreated(
    address merchant,
    uint planId,
    uint date
  );
  event SubscriptionCreated(
    address subscriber,
    uint planId,
    uint date
  );
  event SubscriptionCancelled(
    address subscriber,
    uint planId,
    uint date
  );
  event PaymentSent(
    address from,
    address to,
    uint amount,
    uint planId,
    uint date
  );
  address developer;

    constructor(address _developer) {
         developer = _developer;
    }
    modifier onlyDev(){
        require(msg.sender == developer, "Owner required");
        _;
    }
  function createPlan(address token, uint amount, uint frequency) onlyDev() external {
    require(token != address(0), 'address cannot be null address');
    require(amount > 0, 'amount needs to be > 0');
    require(frequency > 0, 'frequency needs to be > 0');
    plans[nextPlanId] = Plan(
      msg.sender, 
      token,
      amount, 
      frequency // Time in seconds -- 2592000 = 30 days
    );
    nextPlanId++;
  }

  function subscribe(uint planId) external {
    IERC20 token = IERC20(plans[planId].token);
    Plan storage plan = plans[planId];
    require(plan.merchant != address(0), 'this plan does not exist');

    token.transferFrom(msg.sender, plan.merchant, plan.amount);  
    emit PaymentSent(
      msg.sender, 
      plan.merchant, 
      plan.amount, 
      planId, 
      block.timestamp
    );

    subscriptions[msg.sender][planId] = Subscription(
      msg.sender, 
      block.timestamp, 
      block.timestamp + plan.frequency
    );
    emit SubscriptionCreated(msg.sender, planId, block.timestamp);
  }

  function cancel(uint planId) external {
    Subscription storage subscription = subscriptions[msg.sender][planId];
    require(
      subscription.subscriber != address(0), 
      'this subscription does not exist'
    );
    delete subscriptions[msg.sender][planId]; 
    emit SubscriptionCancelled(msg.sender, planId, block.timestamp);
  }
  function checkSubscription(uint planId, address user) view external returns (bool subscribed) {
      Subscription storage subscription = subscriptions[user][planId];
      if(block.timestamp > subscription.nextPayment){
        subscribed = false;
      } else {
          subscribed = true;
      }
      return subscribed;
  }
  
  function pay(address subscriber, uint planId) external {
    Subscription storage subscription = subscriptions[subscriber][planId];
    Plan storage plan = plans[planId];
    IERC20 token = IERC20(plan.token);
    require(
      subscription.subscriber != address(0), 
      'this subscription does not exist'
    );
    require(
      block.timestamp > subscription.nextPayment,
      'not due yet'
    );

    token.transferFrom(subscriber, plan.merchant, plan.amount);  
    emit PaymentSent(
      subscriber,
      plan.merchant, 
      plan.amount, 
      planId, 
      block.timestamp
    );
    //subscription.nextPayment = subscription.nextPayment + plan.frequency;
    //Next payment is started as soon as sub is paid for.
    subscription.nextPayment = block.timestamp + plan.frequency;
  }
}