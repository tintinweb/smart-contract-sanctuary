// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAsko {
  function mint(address account, uint256 amount) external;
  function burn(address account, uint256 amount) external;
}

interface IXdaiMediator {
  function relayUnlock(address account, uint256 amount) external;
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

contract AskoMintMediator {
    address public bridge;
    address public xdaiMediator;
    address public asko;
    address public admin;
    uint256 public gasLimit;

    uint256 public relayTest;

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "can only be called by admin"
        );
        _;
    }

    modifier onlyBridge() {
        require(
            msg.sender == bridge,
            "Call must come from bridge"
        );
        _;
    }

    constructor(address _admin) {
        admin = _admin;
    }

    function init(
        address _bridge,
        address _xdaiMediator,
        address _asko
    ) public onlyAdmin {
        bridge = _bridge;
        xdaiMediator = _xdaiMediator;
        asko = _asko;
        gasLimit = IAMB(bridge).maxGasPerTx() - 1;
    }

    function setAskoLocker(address _asko)
        public
        onlyAdmin
    {
        asko = _asko;
    }

    function setXdaiContract(address _xdaiContract) public onlyAdmin {
        xdaiMediator = _xdaiContract;
    }

    function setBridgeContract(address _bridge) public onlyAdmin {
        bridge = _bridge;
    }

    function setGasLimit(uint256 _gasLimit) public onlyAdmin {
        gasLimit = _gasLimit;
    }

    function burnAndUnlock(
        uint256 amount
    ) external {
        IAsko(asko).burn(msg.sender, amount);
        bytes4 methodSelector = IXdaiMediator(address(0))
            .relayUnlock
            .selector;
        bytes memory data = abi.encodeWithSelector(
            methodSelector,
            msg.sender,
            amount
        );
        IAMB(bridge).requireToPassMessage(xdaiMediator, data, gasLimit);
    }

    function mintByBridge(
        address account,
        uint256 amount
    ) external onlyBridge {
        IAsko(asko).mint(
            account,
            amount
        );
    }

    function relay(uint256 count) external onlyBridge{
        relayTest = count;
    }
}