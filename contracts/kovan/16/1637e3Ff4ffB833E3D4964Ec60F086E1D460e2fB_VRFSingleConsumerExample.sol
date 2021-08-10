/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}



pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {

  function requestRandomWords(
    bytes32 keyHash,  // Corresponds to a particular offchain job which uses that key for the proofs
    uint64  subId,   // A data structure for billing
    uint16  minimumRequestConfirmations,
    uint32  callbackGasLimit,
    uint32  numWords  // Desired number of random words
  )
    external
    returns (
      uint256 requestId
    );

  function createSubscription(
    address[] memory consumers // permitted consumers of the subscription
  )
    external
    returns (
      uint64 subId
    );

  function getSubscription(
    uint64 subId
  )
    external
    view
    returns (
      uint96 balance,
      address owner,
      address[] memory consumers
    );

  function requestSubscriptionOwnerTransfer(
    uint64 subId,
    address newOwner
  )
    external;

  function acceptSubscriptionOwnerTransfer(
    uint64 subId
  )
    external;

  function addConsumer(
    uint64 subId,
    address consumer
  )
    external;

  function removeConsumer(
    uint64 subId,
    address consumer
  )
    external;

  function defundSubscription(
    uint64 subId,
    address to,
    uint96 amount
  )
    external;

  function cancelSubscription(
    uint64 subId,
    address to
  )
    external;
}


// File contracts/VRFv2/VRFConsumerBaseV2.sol

pragma solidity ^0.8.0;

abstract contract VRFConsumerBaseV2 {

  error OnlyCoordinatorCanFulfill(address have, address want);
  
  address immutable private vrfCoordinator;

  constructor(
    address _vrfCoordinator
  )
  {
      vrfCoordinator = _vrfCoordinator;
  }

  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  )
    internal virtual;

  function rawFulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  )
    external
  {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}


// File contracts/VRFv2/VRFConsumer_SingleSubscriber.sol

pragma solidity ^0.8.0;



contract VRFSingleConsumerExample is VRFConsumerBaseV2 {

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    struct RequestConfig {
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
        bytes32 keyHash;
    }
    RequestConfig s_requestConfig;
    uint256[] public s_randomWords;
    uint256 s_requestId;

    constructor(
        address vrfCoordinator,
        address link,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords,
        bytes32 keyHash
    )
    VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_requestConfig = RequestConfig({
            subId: 0, // Unset
            callbackGasLimit: callbackGasLimit,
            requestConfirmations: requestConfirmations,
            numWords: numWords,
            keyHash: keyHash
        });
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    )
        internal
        override
    {
        s_randomWords = randomWords;
    }

    function requestRandomWords()
        external
    {
        RequestConfig memory rc = s_requestConfig;
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            rc.keyHash,
            rc.subId,
            rc.requestConfirmations,
            rc.callbackGasLimit,
            rc.numWords);
    }

    // Assumes this contract owns link
    function topUpSubscription(
        uint256 amount
    )
        external
    {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(s_requestConfig.subId));
    }

    function unsubscribe()
        external
    {
        // Returns funds to this address
        COORDINATOR.cancelSubscription(s_requestConfig.subId, address(this));
        s_requestConfig.subId = 0;
    }

    function subscribe()
        external
    {
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s_requestConfig.subId = COORDINATOR.createSubscription(consumers);
    }
}