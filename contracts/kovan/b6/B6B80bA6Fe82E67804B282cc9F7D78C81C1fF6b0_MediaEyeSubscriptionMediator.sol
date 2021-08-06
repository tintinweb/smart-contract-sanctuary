pragma solidity ^0.8.0;

import './interfaces/IAMB.sol';
import './interfaces/IMediaEyeSubscription.sol';

contract MediaEyeSubscriptionMediator {

  address public bridge;
  address public mediatorOnOtherSide;
  address public mediaEyeSubscription;
  address public admin;
  uint256 public gasLimit;

  modifier adminOnly() {
    require(
      msg.sender == admin,
      "GovernanceSenderMediator::adminOnly: can only be called by admin"
    );
    _;
  }

  modifier onlyBridge {
      require(
          msg.sender == bridge,
          "GovernanceReceiverMediator::executeTransaction: Call must come from bridge"
      );
      require(
          IAMB(bridge).messageSender() == mediatorOnOtherSide,
          "GovernanceReceiverMediator::queueTransaction: Call must come from mediator"
      );
      _;
    }
  
  modifier onlySubscription {
      require(
          msg.sender == mediaEyeSubscription,
          "GovernanceReceiverMediator::executeTransaction: Call must come from media eye subscription"
      );
      _;
    }
  
  constructor() {
    admin = msg.sender;
  }

  function init(
    address _bridge,
    address _mediatorOnOtherSide,
    address _mediaEyeSubscription,
    uint256 _gasLimit
  ) public {
    bridge = _bridge;
    mediatorOnOtherSide = _mediatorOnOtherSide;
    mediaEyeSubscription = _mediaEyeSubscription;
    gasLimit = _gasLimit;
  }

  function setMediaEyeSubscription(address _mediaEyeSubscription) public adminOnly {
    mediaEyeSubscription = _mediaEyeSubscription;
  }

  function setMediatorContractOnOtherSide(address _mediatorOnOtherSide)
    public
    adminOnly
  {
    mediatorOnOtherSide = _mediatorOnOtherSide;
  }

  function setBridgeContract(address _bridge) public adminOnly {
    bridge = _bridge;
  }

  function setGasLimit(uint256 _newGasLimit) public adminOnly {
    gasLimit = _newGasLimit;
  }

  function subscribeLevelOneByBridge(address account, uint256 startTimestamp, uint256 endTimestamp) external onlyBridge {
    IMediaEyeSubscription(mediaEyeSubscription).subscribeLevelOneByBridge(account, startTimestamp, endTimestamp);
  }

  function subscribeLevelOne(address account, uint256 startTimestamp, uint256 endTimestamp) external onlySubscription {
    bytes4 methodSelector = this.subscribeLevelOneRelay.selector;
    bytes memory data = abi.encodeWithSelector(methodSelector, account, startTimestamp, endTimestamp);
    IAMB(bridge).requireToPassMessage(
      mediatorOnOtherSide,
      data,
      gasLimit
    );
  }

  function subscribeLevelOneRelay(address account, uint256 startTimestamp, uint256 endTimestamp) external onlyBridge {
    bytes4 methodSelector = this.subscribeLevelOneByBridge.selector;
    bytes memory data = abi.encodeWithSelector(methodSelector, account, startTimestamp, endTimestamp);
    IAMB(bridge).requireToPassMessage(
      mediatorOnOtherSide,
      data,
      gasLimit
    );
  }
}

pragma solidity ^0.8.0;

interface IAMB {
    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function failedMessageDataHash(bytes32 _messageId)
        external
        view
        returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId)
        external
        view
        returns (address);

    function failedMessageSender(bytes32 _messageId)
        external
        view
        returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToConfirmMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IMediaEyeSubscription {
    function subscribeLevelOneByBridge(address account, uint256 startTimestamp, uint256 endTimestamp) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}