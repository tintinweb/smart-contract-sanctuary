pragma solidity 0.4.24;

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
        bytes _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToConfirmMessage(
        address _contract,
        bytes _data,
        uint256 _gas
    ) external returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

pragma solidity 0.4.24;

contract AMBMessageContract {
    string public message;

    constructor() public {}

    function sendMessage(
        string _message,
        address _bridgeContract,
        address _contractOnOtherSide,
        uint256 _gasLimit
    ) external {
        bytes4 methodSelector = this.recieveMessage.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _message);
        IAMB(_bridgeContract).requireToPassMessage(
            _contractOnOtherSide,
            data,
            _gasLimit
        );
    }

    function recieveMessage(string _message) external {
        message = _message;
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