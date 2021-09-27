//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./interfaces/ISecureVault.sol";
import "./interfaces/IFlashBotsCaller.sol";
import "./interfaces/IController.sol";
import "./Initializable.sol";

import "./libraries/SafeMath.sol";

contract FlashBotsCaller is IFlashBotsCaller, Initializable {
    using SafeMath for uint256;

    event PayToMiner(uint256 ethAmountToCoinbase);
    event PayToMinerIfHaveRevenue(uint256 ethAmountToCoinbase);
    event PayPercentageToMinerIfHaveRevenue(
        uint256 percentageToPay,
        int256 profitBeforePayCoinBase,
        uint256 amountToPay
    );
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
        _clearControllerBalance();
    }

    function payToMinerIfHaveRevenue(uint256 _ethAmountToCoinbase) external override onlyExecutor {
        int256 balance = controller.getBalance();
        require(balance > 0, "The balance is less than zero");
        uint256 newBalance = uint256(balance);
        require(newBalance > _ethAmountToCoinbase, "The transaction earning are not enough to pay the miner");
        emit PayToMinerIfHaveRevenue(_ethAmountToCoinbase);
        controller.withdraw(_ethAmountToCoinbase);

        block.coinbase.transfer(_ethAmountToCoinbase);
        _clearControllerBalance();
    }

    function payPercentageToMinerIfHaveRevenue(uint256 _ethPercentageToCoinbase) external override onlyExecutor {
        int256 balance = controller.getBalance();
        require(balance > 0, "The actual balance is smaller than zero");
        uint256 amountToSend = _ethPercentageToCoinbase.mul(uint256(balance)).div(100);
        require(amountToSend > 0, "The percentage to pay is smaller than zero");
        emit PayPercentageToMinerIfHaveRevenue(_ethPercentageToCoinbase, balance, amountToSend);
        controller.withdraw(amountToSend);

        block.coinbase.transfer(amountToSend);
        _clearControllerBalance();
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
            (bool _success, ) = dataToOperate.contractAddress.call(dataToOperate.payload);
            require(_success, "Failed when call the contract");
        }
    }

    function _clearControllerBalance() private {
        controller.clearBalance();
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

    function transferEth(uint256 _amount, address payable _addressToWithdraw) external;

    function transferToken(
        address _token,
        uint256 _amount,
        address _addressToWithdraw
    ) external;

    function getBalance() external returns (int256);

    function clearBalance() external;

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