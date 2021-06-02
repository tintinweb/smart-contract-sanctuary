/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/SubscriptionContract.sol

pragma solidity >=0.4.22 <0.9.0;


contract SubscriptionContract {
  address public serviceAddress = msg.sender;
  bool public halted = false;

  struct Subscription {
    bytes id; // bytes concatenation of addresses of owner, subscriber, and token
    bytes uuid;
    address ownerAddress;
    address subscriberAddress;
    address tokenAddress; // subscription denominated token
    uint lastSettlementTime;
    uint value; // subscription value
    uint interval; // subscription interval in seconds

    // non-state variables
    uint ownerSubscriptionIndex;
    uint subscriberSubscriptionIndex;
    uint index;
    bool exists;
  }

  struct Owner {
    bytes[] subscriptionIDs;
    uint index;
    bool exists;
  }

  struct Subscriber {
    bytes[] subscriptionIDs;
    uint index;
    bool exists;
  }

  event SubscriptionAdded(
    bytes id,
    bytes uuid,
    address ownerAddress,
    address subscriberAddress,
    address tokenAddress,
    uint value,
    uint interval
  );

  event SettlementSuccess(
    bytes id,
    bytes uuid,
    address ownerAddress,
    address subscriberAddress,
    address tokenAddress,
    uint value
  );

  event SettlementFailure(
    bytes id,
    bytes uuid,
    address ownerAddress,
    address subscriberAddress,
    address tokenAddress,
    uint value
  );

  event SubscriptionRemoved(
    bytes id,
    bytes uuid,
    address ownerAddress,
    address subscriberAddress,
    address tokenAddress
  );

  mapping (address => Owner) public owners;
  mapping (address => Subscriber) public subscribers;
  mapping (bytes => Subscription) public subscriptions;

  address[] public ownerIndices;
  address[] public subscriberIndices;
  bytes[] public subscriptionIndices;

  modifier restricted() {
    require(
      msg.sender == serviceAddress,
      "This function is restricted to the contract's service address"
    );
    _;
  }

  modifier notHalt() {
    require(
      !halted,
      "This function is not permitted when contract is halted"
    );
    _;
  }

  function halt() public restricted {
    halted = true;
  }

  function unhalt() public restricted {
    halted = false;
  }

  function makeID(
    bytes calldata uuid,
    address subscriberAddress
  ) pure external returns (bytes memory) {
    return abi.encodePacked(uuid, subscriberAddress);
  }

  function addSubscription(
    address ownerAddress,
    address tokenAddress,
    uint value,
    uint interval,
    bytes calldata uuid
  ) public notHalt returns (Subscription memory) {
    address subscriberAddress = msg.sender;
    bytes memory subscriptionID = this.makeID(uuid, subscriberAddress);

    // Assert that subscription does not exist
    require(subscriptions[subscriptionID].exists != true);
    require(value > 0);
    require(interval > 0);
    require(uuid.length > 1);

    IERC20 erc20 = IERC20(tokenAddress);
    require(erc20.transferFrom(subscriberAddress, ownerAddress, value));

    if (owners[ownerAddress].exists == true) {
      owners[ownerAddress].subscriptionIDs.push(subscriptionID);
    } else {
      ownerIndices.push(ownerAddress);
      bytes[] memory emptySubIDs;
      owners[ownerAddress] = Owner({
        exists: true,
        subscriptionIDs: emptySubIDs,
        index: ownerIndices.length - 1
      });
      owners[ownerAddress].subscriptionIDs.push(subscriptionID);
    }

    if (subscribers[subscriberAddress].exists == true) {
      subscribers[subscriberAddress].subscriptionIDs.push(subscriptionID);
    } else {
      subscriberIndices.push(subscriberAddress);
      bytes[] memory emptySubIDs;
      subscribers[subscriberAddress] = Subscriber({
        exists: true,
        subscriptionIDs: emptySubIDs,
        index: subscriberIndices.length - 1
      });
      subscribers[subscriberAddress].subscriptionIDs.push(subscriptionID);
    }

    subscriptionIndices.push(subscriptionID);

    Subscription memory subscription = Subscription({
      id: subscriptionID,
      uuid: uuid,
      ownerAddress: ownerAddress,
      subscriberAddress: subscriberAddress,
      tokenAddress: tokenAddress,
      lastSettlementTime: block.timestamp,
      value: value,
      interval: interval,
      index: subscriptionIndices.length - 1,
      ownerSubscriptionIndex: owners[ownerAddress].subscriptionIDs.length - 1,
      subscriberSubscriptionIndex: subscribers[subscriberAddress].subscriptionIDs.length - 1,
      exists: true
    });

    subscriptions[subscriptionID] = subscription;

    emit SubscriptionAdded(
      subscriptionID,
      uuid,
      ownerAddress,
      subscriberAddress,
      tokenAddress,
      value,
      interval
    );
    return subscription;
  }

  function removeSubscription(bytes calldata subscriptionID) public returns (bool) {
    address subscriberAddress = msg.sender;

    require(subscriptions[subscriptionID].exists);

    Subscription memory deletedSubscription = subscriptions[subscriptionID];

    require(subscriberAddress == deletedSubscription.subscriberAddress);

    if (deletedSubscription.index != subscriptionIndices.length - 1) {
      bytes memory lastSubscriptionID = subscriptionIndices[subscriberIndices.length - 1];
      subscriptionIndices[deletedSubscription.index] = lastSubscriptionID;
      subscriptions[lastSubscriptionID].index = deletedSubscription.index;
    }

    Owner storage owner = owners[deletedSubscription.ownerAddress];

    if (deletedSubscription.ownerSubscriptionIndex != owner.subscriptionIDs.length - 1) {
      bytes memory lastOwnerSubID = owner.subscriptionIDs[owner.subscriptionIDs.length - 1];
      owner.subscriptionIDs[deletedSubscription.ownerSubscriptionIndex] = lastOwnerSubID;
      subscriptions[lastOwnerSubID].ownerSubscriptionIndex = deletedSubscription.ownerSubscriptionIndex;
    }

    Subscriber storage subscriber = subscribers[deletedSubscription.subscriberAddress];

    if (deletedSubscription.subscriberSubscriptionIndex != subscriber.subscriptionIDs.length - 1) {
      bytes memory lastSubscriberSubID = subscriber.subscriptionIDs[subscriber.subscriptionIDs.length - 1];
      subscriber.subscriptionIDs[deletedSubscription.subscriberSubscriptionIndex] = lastSubscriberSubID;
      subscriptions[lastSubscriberSubID].subscriberSubscriptionIndex = deletedSubscription.subscriberSubscriptionIndex;
    }

    delete subscriptions[subscriptionID];
    subscriptionIndices.pop();
    owner.subscriptionIDs.pop();
    subscriber.subscriptionIDs.pop();

    emit SubscriptionRemoved(
      subscriptionID,
      deletedSubscription.uuid,
      deletedSubscription.ownerAddress,
      deletedSubscription.subscriberAddress,
      deletedSubscription.tokenAddress
    );

    return true;
  }

  function internalRemoveSubscription(bytes calldata subscriptionID) internal returns (bool) {
    require(subscriptions[subscriptionID].exists);

    Subscription memory deletedSubscription = subscriptions[subscriptionID];

    if (deletedSubscription.index != subscriptionIndices.length - 1) {
      bytes memory lastSubscriptionID = subscriptionIndices[subscriberIndices.length - 1];
      subscriptionIndices[deletedSubscription.index] = lastSubscriptionID;
      subscriptions[lastSubscriptionID].index = deletedSubscription.index;
    }

    Owner storage owner = owners[deletedSubscription.ownerAddress];

    if (deletedSubscription.ownerSubscriptionIndex != owner.subscriptionIDs.length - 1) {
      bytes memory lastOwnerSubID = owner.subscriptionIDs[owner.subscriptionIDs.length - 1];
      owner.subscriptionIDs[deletedSubscription.ownerSubscriptionIndex] = lastOwnerSubID;
      subscriptions[lastOwnerSubID].ownerSubscriptionIndex = deletedSubscription.ownerSubscriptionIndex;
    }

    Subscriber storage subscriber = subscribers[deletedSubscription.subscriberAddress];

    if (deletedSubscription.subscriberSubscriptionIndex != subscriber.subscriptionIDs.length - 1) {
      bytes memory lastSubscriberSubID = subscriber.subscriptionIDs[subscriber.subscriptionIDs.length - 1];
      subscriber.subscriptionIDs[deletedSubscription.subscriberSubscriptionIndex] = lastSubscriberSubID;
      subscriptions[lastSubscriberSubID].subscriberSubscriptionIndex = deletedSubscription.subscriberSubscriptionIndex;
    }

    delete subscriptions[subscriptionID];
    subscriptionIndices.pop();
    owner.subscriptionIDs.pop();
    subscriber.subscriptionIDs.pop();

    emit SubscriptionRemoved(
      subscriptionID,
      deletedSubscription.uuid,
      deletedSubscription.ownerAddress,
      deletedSubscription.subscriberAddress,
      deletedSubscription.tokenAddress
    );

    return true;
  }

  function settleSubscription(bytes calldata subscriptionID) public returns (bool) {
    Subscription storage subscription = subscriptions[subscriptionID];

    require(subscription.exists);

    uint gap = block.timestamp - subscription.lastSettlementTime;

    uint allowedPayments = gap / subscription.interval;

    if (allowedPayments < 1) {
      return false;
    }

    bool result = false;

    try IERC20(subscription.tokenAddress).transferFrom(subscription.subscriberAddress, subscription.ownerAddress,allowedPayments * subscription.value) returns (bool b) {
      result = b;
    } catch {
      result = false;
    }


    if (result) {
      subscription.lastSettlementTime = subscription.lastSettlementTime + (allowedPayments * subscription.interval);
      emit SettlementSuccess(
        subscriptionID,
        subscription.uuid,
        subscription.ownerAddress,
        subscription.subscriberAddress,
        subscription.tokenAddress,
        allowedPayments * subscription.value
      );
      return true;
    } else {
      internalRemoveSubscription(subscriptionID);
      emit SettlementFailure(
        subscriptionID,
        subscription.uuid,
        subscription.ownerAddress,
        subscription.subscriberAddress,
        subscription.tokenAddress,
        allowedPayments * subscription.value
      );
      return false;
    }
  }

  function settleOwnerSubscriptions(address ownerAddress) public returns (bool) {
    Owner memory owner = owners[ownerAddress];

    require(owner.exists);

    for (uint i = 0; i < owner.subscriptionIDs.length; i++) {
      this.settleSubscription(owner.subscriptionIDs[i]);
    }

    return true;
  }

  function getClaimableAmount(address ownerAddress, address tokenAddress) public view returns (uint) {
    Owner memory owner = owners[ownerAddress];

    require(owner.exists);

    uint answer = 0;

    for (uint i = 0; i < owner.subscriptionIDs.length; i++) {
      Subscription memory subscription = subscriptions[owner.subscriptionIDs[i]];
      if (subscription.tokenAddress == tokenAddress) {
        answer = answer + this.getAmountOwed(owner.subscriptionIDs[i]);
      }
    }

    return answer;
  }

  function getAmountOwed(bytes calldata subscriptionID) public view returns (uint) {
    Subscription memory subscription = subscriptions[subscriptionID];

    require(subscription.exists);

    return ((block.timestamp - subscription.lastSettlementTime) / subscription.interval) * subscription.value;
  }

  function getIDsByOwner(address ownerAddress) public view returns(bytes[] memory) {
    Owner memory owner = owners[ownerAddress];
    require(owner.exists);
    return owner.subscriptionIDs;
  }

  function getIDsBySubscriber(address subscriberAddress) public view returns(bytes[] memory) {
    Subscriber memory subscriber = subscribers[subscriberAddress];
    require(subscriber.exists);
    return subscriber.subscriptionIDs;
  }
}