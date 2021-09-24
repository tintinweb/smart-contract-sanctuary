//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./ISecureVault.sol";
import "./IFlashBotsCaller.sol";
import "./IController.sol";
import "./Initializable.sol";

contract FlashBotsCaller is IFlashBotsCaller, Initializable {
    event PayToMiner(uint256 ethAmountToCoinbase);
    event PayToMinerIfHaveRevenue(uint256 ethAmountToCoinbase);
    event PayPercentageToMinerIfHaveRevenue(uint256 ethAmountToCoinbase, uint256 amountToSend);
    event Execute(FlashBotCallData[] data);

    address private immutable owner;
    address private executor;
    IController public controller;
    modifier onlyExecutor() {
        require(msg.sender == executor, "Only the Executor can execute this function");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the Owner can execute this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function initialize(address _executor, IController _controller) public onlyOwner initializer {
        executor = _executor;
        controller = _controller;
    }

    function payToMiner(uint256 _ethAmountToCoinbase) external payable override onlyExecutor {
        emit PayToMiner(_ethAmountToCoinbase);
        controller.withdraw(_ethAmountToCoinbase);
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function payToMinerIfHaveRevenue(uint256 _ethAmountToCoinbase) external override onlyExecutor {
        int256 balance = controller.getBalance();
        require(balance > 0, "The balance is less than zero");
        uint256 newBalance = uint256(balance);
        require(newBalance > _ethAmountToCoinbase, "The transaction earning are not enough to pay the miner");
        emit PayToMinerIfHaveRevenue(_ethAmountToCoinbase);

        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function payPercentageToMinerIfHaveRevenue(uint256 _ethPercentageToCoinbase) external override onlyExecutor {
        int256 balance = controller.getBalance();
        require(balance > 0, "The balance is less than zero");
        uint256 newBalance = uint256(balance);

        uint256 amountToSend = (_ethPercentageToCoinbase * newBalance) / (100);
        emit PayPercentageToMinerIfHaveRevenue(_ethPercentageToCoinbase, amountToSend);

        block.coinbase.transfer(amountToSend);
    }

    function changeController(IController _controller) external onlyOwner {
        controller = _controller;
    }

    function execute(FlashBotCallData[] calldata _data) external override onlyExecutor {
        emit Execute(_data);
        _eachAllContractToCall(_data);
    }

    function _eachAllContractToCall(FlashBotCallData[] calldata _data) private {
        FlashBotCallData memory dataToOperate;
        for (uint256 i = 0; i < _data.length; i++) {
            dataToOperate = _data[i];
            (bool _success, bytes memory _response) = dataToOperate.contractAddress.call(dataToOperate.payload);
            require(_success, "Failed when call the contract");
            _response;
        }
    }

    receive() external payable {}

    fallback() external payable {}
}