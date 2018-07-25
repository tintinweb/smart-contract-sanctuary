pragma solidity ^0.4.24;

interface IOracle {

    /**
    * @notice Returns address of oracle currency (0x0 for ETH)
    */
    function getCurrencyAddress() external view returns(address);

    /**
    * @notice Returns symbol of oracle currency (0x0 for ETH)
    */
    function getCurrencySymbol() external view returns(bytes32);

    /**
    * @notice Returns denomination of price
    */
    function getCurrencyDenominated() external view returns(bytes32);

    /**
    * @notice Returns price - should throw if not valid
    */
    function getPrice() external view returns(uint256);

}

contract MockOracle is IOracle {

    address public currency;
    bytes32 public currencySymbol;
    bytes32 public denominatedCurrency;
    uint256 public price;

    constructor(address _currency, bytes32 _currencySymbol, bytes32 _denominatedCurrency, uint256 _price) public {
        currency = _currency;
        currencySymbol = _currencySymbol;
        denominatedCurrency = _denominatedCurrency;
        price = _price;
    }

    function changePrice(uint256 _price) external {
        price = _price;
    }

    /**
    * @notice Returns address of oracle currency (0x0 for ETH)
    */
    function getCurrencyAddress() external view returns(address) {
        return currency;
    }

    /**
    * @notice Returns symbol of oracle currency (0x0 for ETH)
    */
    function getCurrencySymbol() external view returns(bytes32) {
        return currencySymbol;
    }

    /**
    * @notice Returns denomination of price
    */
    function getCurrencyDenominated() external view returns(bytes32) {
        return denominatedCurrency;
    }

    /**
    * @notice Returns price - should throw if not valid
    */
    function getPrice() external view returns(uint256) {
        return price;
    }

}