// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMediaEyeSubRecieverMed {
    function subscribeFromHomeRelay(
        address account,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool tier
    ) external;
}

interface IMediaEyeSubscription {
    function subscribeByBridge(
        address account,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool tier
    ) external;

    // function testCounter(
    //     address account,
    //     uint256 startTimestamp,
    //     uint256 endTimestamp
    // ) external;
}

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
        bytes memory _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToConfirmMessage(
        address _contract,
        bytes memory _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToGetInformation(
        bytes32 _requestSelector,
        bytes memory _data
    ) external returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

contract MediaEyeHomeMediator {
    address public bridge;
    address public xdaiMediator;
    address public mediaEyeSubscription;
    address public admin;
    uint256 public gasLimit;
    uint256 public sendCounter;
    uint256 public receiveCounter;

    modifier adminOnly() {
        require(
            msg.sender == admin,
            "GovernanceSenderMediator::adminOnly: can only be called by admin"
        );
        _;
    }

    modifier onlyBridgeReceive() {
        require(
            msg.sender == bridge,
            "GovernanceReceiverMediator::executeTransaction: Call must come from bridge"
        );
        // require(
        //     IAMB(bridge).messageSender() == xdaiMediator,
        //     "GovernanceReceiverMediator::queueTransaction: Call must come from mediator"
        // );
        _;
    }

    modifier onlySubscription() {
        require(
            msg.sender == mediaEyeSubscription,
            "GovernanceReceiverMediator::executeTransaction: Call must come from media eye subscription"
        );
        _;
    }

    constructor(address _admin) {
        admin = _admin;
    }

    function init(
        address _bridge,
        address _xdaiMediator,
        address _mediaEyeSubscription
    ) public {
        bridge = _bridge;
        xdaiMediator = _xdaiMediator;
        mediaEyeSubscription = _mediaEyeSubscription;
        gasLimit = IAMB(bridge).maxGasPerTx() - 1;
    }

    function setMediaEyeSubscription(address _mediaEyeSubscription)
        public
        adminOnly
    {
        mediaEyeSubscription = _mediaEyeSubscription;
    }

    function setXdaiContract(address _xdaiContract) public adminOnly {
        xdaiMediator = _xdaiContract;
    }

    function setBridgeContract(address _bridge) public adminOnly {
        bridge = _bridge;
    }

    function setGasLimit(uint256 _gasLimit) public adminOnly {
        gasLimit = _gasLimit;
    }

    function subscribeByMediator(
        address account,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool tier
    ) external onlySubscription {
        bytes4 methodSelector = IMediaEyeSubRecieverMed(address(0))
            .subscribeFromHomeRelay
            .selector;
        // bytes4 methodSelector = IMediaEyeSubscription(address(0)).testCounter.selector;
        bytes memory data = abi.encodeWithSelector(
            methodSelector,
            account,
            startTimestamp,
            endTimestamp,
            tier
        );
        IAMB(bridge).requireToPassMessage(xdaiMediator, data, gasLimit);
        sendCounter++;
    }

    function subscribeByBridge(
        address account,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool tier
    ) external onlyBridgeReceive {
        IMediaEyeSubscription(mediaEyeSubscription).subscribeByBridge(
            account,
            startTimestamp,
            endTimestamp,
            tier
        );
        receiveCounter++;
    }
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