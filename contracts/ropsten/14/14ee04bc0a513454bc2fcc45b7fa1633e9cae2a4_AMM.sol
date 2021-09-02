pragma solidity ^0.8.0;

import "IERC20.sol";

contract AMM {
    mapping(address => bool) public supportedCurrencies;
    address[] public currencies;

    constructor(uint256[] memory amounts, address[] memory _currencies) public {
        uint256 n = _currencies.length;
        require(n == amounts.length, "Invalid length!");

        for (uint256 i = 0; i < n; i++) {
            supportedCurrencies[_currencies[i]] = true;

            IERC20(_currencies[i]).transferFrom(
                msg.sender,
                address(this),
                amounts[i]
            );
        }
        currencies = _currencies;
    }

    modifier onlySupportedCurrency(address currencyAddress) {
        require(supportedCurrencies[currencyAddress], "Unsupported currency!");
        _;
    }

    function getBalance(address currencyAddress) public view returns (uint256) {
        return IERC20(currencyAddress).balanceOf(address(this));
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return ((a + b) - 1) / b;
    }

    function getQuote(
        uint256 amountFrom,
        address currencyFrom,
        address currencyTo
    )
        public
        view
        onlySupportedCurrency(currencyFrom)
        onlySupportedCurrency(currencyTo)
        returns (uint256, uint256)
    {
        uint256 const = getBalance(currencyFrom) * getBalance(currencyTo); // 30000
        require(const > 0, "This liquidity pool is dry!");

        uint256 newBalanceFrom = getBalance(currencyFrom) + amountFrom; // 110
        uint256 newBalanceTo = ceilDiv(const, newBalanceFrom); // 273
        newBalanceFrom = ceilDiv(const, newBalanceTo); // 110

        require(newBalanceFrom * newBalanceTo >= const);

        amountFrom = newBalanceFrom - getBalance(currencyFrom);
        uint256 amountTo = getBalance(currencyTo) - newBalanceTo;

        return (amountFrom, amountTo);
    }

    function addLiquidityShare(
        uint256 poolShareNumerator,
        uint256 poolShareDenominator
    ) public {
        uint256 n = currencies.length;

        for (uint256 i = 0; i < n; i++) {
            uint256 calculatedAmount = (getBalance(currencies[i]) *
                poolShareNumerator) / poolShareDenominator;

            IERC20(currencies[i]).transferFrom(
                msg.sender,
                address(this),
                calculatedAmount
            );
        }
    }

    // The amounts for remaining currencies are computed automatically
    function addLiquidity(uint256 exampleAmount, address exampleCurrency)
        public
        onlySupportedCurrency(exampleCurrency)
    {
        uint256 poolShareNumerator = exampleAmount;
        uint256 poolShareDenominator = getBalance(exampleCurrency);
        addLiquidityShare(poolShareNumerator, poolShareDenominator);
    }

    function swap(
        uint256 amountFrom,
        address currencyFrom,
        address currencyTo
    ) public {
        uint256 amountTo;
        (amountFrom, amountTo) = getQuote(amountFrom, currencyFrom, currencyTo);

        IERC20(currencyFrom).transferFrom(
            msg.sender,
            address(this),
            amountFrom
        );

        IERC20(currencyTo).transfer(msg.sender, amountTo);
    }
}