//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./ISecureVault.sol";
import "./IExchange.sol";
import "./IController.sol";
import "./Initializable.sol";

contract Controller is IController, Initializable {
    event BuyToken(IExchange _exchange, string _token, uint256 _amount);
    event SellToken(IExchange _exchange, string _token, uint256 _amount);

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
        string calldata _token,
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
        string calldata _token,
        uint256 _amount
    ) external override onlyFlashBotCaller {
        emit SellToken(IExchange(_exchange), _token, _amount);
    }

    function getPercentageOfEarning(uint256 _percentage) external override onlyFlashBotCaller returns (uint256) {
        require(balance > 0, "The actual balance is smaller than zero");
        uint256 earnedPercentage = (_percentage * uint256(balance)) / 100;
        vault.withdrawEthToAddress(earnedPercentage, address(flashBotcaller));
        _resetBalance();
        return earnedPercentage;
    }

    function transferEth(uint256 _amount, address _addressToWithdraw) external override onlyFlashBotCaller {
        vault.withdrawEthToAddress(_amount, _addressToWithdraw);
    }

    function transferToken(
        string calldata _token,
        uint256 _amount,
        address _addressToWithdraw
    ) external override onlyFlashBotCaller {
        vault.withdrawTokensToAddress(_token, _amount, _addressToWithdraw);
    }

    function withdraw(uint256 _amount) external override onlyFlashBotCaller {
        vault.withdrawEthToAddress(_amount, flashBotcaller);
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