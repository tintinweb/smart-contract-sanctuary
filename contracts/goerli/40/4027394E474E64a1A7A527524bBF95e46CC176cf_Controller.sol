//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./interfaces/ISecureVault.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/IController.sol";
import "./Initializable.sol";

contract Controller is IController, Initializable {
    event BuyToken(IExchange exchange, address token, uint256 amount);
    event SellToken(IExchange exchange, address token, uint256 amount, uint256 selPrice);

    address public flashBotcaller;
    ISecureVault public vault;
    int256 public balance;

    modifier onlyFlashBotCaller() {
        require(msg.sender == flashBotcaller, "Only the Flash Bot caller can execute this function");
        _;
    }

    function initialize(ISecureVault _vault, address _flashBotCaller) public initializer {
        vault = _vault;
        flashBotcaller = _flashBotCaller;
    }

    function buy(
        address _exchange,
        address _token,
        uint256 _amount
    ) external override onlyFlashBotCaller {
        uint256 priceOfTokens = IExchange(_exchange).calculatePrice(_token, _amount);
        balance = -int256(priceOfTokens);
        vault.withdrawEth(priceOfTokens);

        IExchange(_exchange).buy{value: priceOfTokens}(_token, _amount, address(vault));
        emit BuyToken(IExchange(_exchange), _token, _amount);
    }

    function sell(
        address _exchange,
        address _token,
        uint256 _amount
    ) external override onlyFlashBotCaller {
        vault.withdrawTokensToAddress(_token, _amount, _exchange);
        uint256 sellPrice = IExchange(_exchange).sell(_token, _amount, payable(address(vault)));
        balance += int256(sellPrice);
        emit SellToken(IExchange(_exchange), _token, _amount, sellPrice);
    }

    function getPercentageOfEarning(uint256 _percentage) external override onlyFlashBotCaller returns (uint256) {
        require(balance > 0, "The actual balance is smaller than zero");
        uint256 earnedPercentage = (_percentage * uint256(balance)) / 100;
        vault.withdrawEthToAddress(earnedPercentage, payable(flashBotcaller));
        _resetBalance();
        return earnedPercentage;
    }

    function transferEth(uint256 _amount, address payable _addressToWithdraw) external override onlyFlashBotCaller {
        vault.withdrawEthToAddress(_amount, _addressToWithdraw);
    }

    function transferToken(
        address _token,
        uint256 _amount,
        address _addressToWithdraw
    ) external override onlyFlashBotCaller {
        vault.withdrawTokensToAddress(_token, _amount, _addressToWithdraw);
    }

    function withdraw(uint256 _amount) external override onlyFlashBotCaller {
        vault.withdrawEthToAddress(_amount, payable(flashBotcaller));
    }

    function getBalance() external override onlyFlashBotCaller returns (int256) {
        int256 balanceToReturn = balance;
        _resetBalance();
        return balanceToReturn;
    }

    function _resetBalance() private {
        balance = 0;
    }

    receive() external payable {}
    //transfer(uint256, address)
    //transfer(uint256, string, address)
    //withdraw(uint256)
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

