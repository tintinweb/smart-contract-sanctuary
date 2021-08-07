// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMediaEyeSubRecieverMed {
    function subscribeLevelOneFromForeignRelay(
        address account,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external;
}

interface IMediaEyeSubscription {
    function subscribeLevelOneByBridge(
        address account,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external;
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

    function requireToGetInformation(bytes32 _requestSelector, bytes memory _data)
        external
        returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

contract MediaEyeForeignMediator {
    address public bridge;
    address public xdaiMediator;
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

    modifier onlyBridgeReceive() {
        require(
            msg.sender == bridge,
            "GovernanceReceiverMediator::executeTransaction: Call must come from bridge"
        );
        require(
            IAMB(bridge).messageSender() == xdaiMediator,
            "GovernanceReceiverMediator::queueTransaction: Call must come from mediator"
        );
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
        address _mediatorOnOtherSide,
        address _xdaiMediator,
        address _mediaEyeSubscription
    ) public {
        bridge = _bridge;
        mediatorOnOtherSide = _mediatorOnOtherSide;
        xdaiMediator = _xdaiMediator;
        mediaEyeSubscription = _mediaEyeSubscription;
        gasLimit = IAMB(bridge).maxGasPerTx();
    }

    function setMediaEyeSubscription(address _mediaEyeSubscription)
        public
        adminOnly
    {
        mediaEyeSubscription = _mediaEyeSubscription;
    }

    function setXdaiContract(address _xdaiContract)
        public
        adminOnly
    {
        xdaiMediator = _xdaiContract;
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

    function setGasLimit() public adminOnly {
        gasLimit = IAMB(bridge).maxGasPerTx();
    }

    function subscribeLevelOne(
        address account,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external onlySubscription {
        bytes4 methodSelector = IMediaEyeSubRecieverMed(address(0))
            .subscribeLevelOneFromForeignRelay
            .selector;
        bytes memory data = abi.encodeWithSelector(
            methodSelector,
            account,
            startTimestamp,
            endTimestamp
        );
        IAMB(bridge).requireToPassMessage(xdaiMediator, data, gasLimit);
    }

    function subscribeLevelOneByBridge(
        address account,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external onlyBridgeReceive {
        IMediaEyeSubscription(mediaEyeSubscription).subscribeLevelOneByBridge(
            account,
            startTimestamp,
            endTimestamp
        );
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