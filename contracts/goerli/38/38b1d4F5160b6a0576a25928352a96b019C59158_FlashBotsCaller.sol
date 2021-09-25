//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./interfaces/ISecureVault.sol";
import "./interfaces/IFlashBotsCaller.sol";
import "./interfaces/IController.sol";
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
import "./IExchange.sol";

interface IController {
    function buy(
        address _exchange,
        address _token,
        uint256 _amount
    ) external;

    function sell(
        address _exchange,
        address _token,
        uint256 _amount
    ) external;

    function getPercentageOfEarning(uint256 _percentage) external returns (uint256);

    function transferEth(uint256 _amount, address payable _addressToWithdraw) external;

    function transferToken(
        address _token,
        uint256 _amount,
        address _addressToWithdraw
    ) external;

    function getBalance() external returns (int256);

    function withdraw(uint256 _amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IFlashBotsCaller {
    struct FlashBotCallData {
        address payable contractAddress;
        bytes payload;
    }

    /**
     *
     * Pay to the minner after to execute contract or raw tx
     * Requirements:
     *
     * - `_ethAmountToCoinbase` amount in wei that you want to pay the miner
     *
     */
    function payToMiner(uint256 _ethAmountToCoinbase) external payable;

    /**
     *
     * Pay to the minner only if the execution generate profit
     * Requirements:
     *
     * - `_ethAmountToCoinbase` amount in wei that you want to pay the miner
     *
     */
    function payToMinerIfHaveRevenue(uint256 _ethAmountToCoinbase) external;

    /**
     *
     * Pay to the miner only if the execution generate a specific percentage of profit
     * Requirements:
     *
     * - `_ethPercentageToCoinbase` percentage of earning that will pay to the miner
     *
     */
    function payPercentageToMinerIfHaveRevenue(uint256 _ethPercentageToCoinbase) external;

    /**
     *
     * Execute particular function from the contract
     * If want to send eth to the contract, will take from the IVault
     * IMPORTAT : All the found left in the contract after the execution will send to the IVAULT (seted in the constructor)
     * Requirements:
     *
     * - `_ethPercentageToCoinbase` percentage of earning that will pay to the miner
     *
     */
    function execute(FlashBotCallData[] memory _data) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface ISecureVault {
    function withdrawEth(uint256 _amount) external;

    function withdrawEthToAddress(uint256 _amount, address payable _addressToWithdraw) external;

    function withdrawTokensToAddress(
        address _token,
        uint256 _amount,
        address _addressToWithdraw
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IExchange {
    function calculatePrice(address _token, uint256 _amount) external returns (uint256);

    function buy(
        address _token,
        uint256 _amount,
        address _addressToSendTokens
    ) external payable;

    function sell(
        address _token,
        uint256 _amount,
        address payable _addressToSendEther
    ) external returns (uint256);
}

{
  "optimizer": {
    "enabled": false,
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
  }
}