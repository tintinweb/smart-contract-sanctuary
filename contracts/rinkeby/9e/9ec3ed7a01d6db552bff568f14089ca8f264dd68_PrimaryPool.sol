pragma solidity ^0.7.4;
// "SPDX-License-Identifier: MIT"

import "./ICollateralizationPrimary.sol";
import "./SafeMath.sol";
import "./DSMath.sol";

contract PrimaryPool is DSMath {
    using SafeMath for uint256;

    address public _collateralizationAddress;
    address public _governanceAddress;

    ICollateralizationPrimary _collateralization;

    //Minimum amount of both tokens to buy
    uint256 public _minBlackAndWhiteBuy;
    //Price for 2 tokens
    uint256 public _blackAndWhitePrice;

    event Buy(uint256 buyAmount, uint256 price);
    event BuyBack(uint256 tokensAmount, uint256 price);

    constructor(
        address collateralizationAddress,
        address governanceAddress,
        uint256 minBlackAndWhiteBuy,
        uint256 blackAndWhitePrice
    ) {
        require(
            collateralizationAddress != address(0),
            "Collateralization address should be not null"
        );

        _collateralization = ICollateralizationPrimary(collateralizationAddress);
        _collateralizationAddress = collateralizationAddress;

        _governanceAddress = governanceAddress == address(0)
            ? msg.sender
            : governanceAddress;

        _minBlackAndWhiteBuy = minBlackAndWhiteBuy == 0
            ? 1
            : minBlackAndWhiteBuy;
        _blackAndWhitePrice = blackAndWhitePrice == 0
            ? 10_000_000
            : blackAndWhitePrice;
    }

    modifier onlyGovernance() {
        require(
            _governanceAddress == msg.sender,
            "Caller should be governance"
        );
        _;
    }

    function buylimitsUpdate(uint256 minLimit) public onlyGovernance {
        _minBlackAndWhiteBuy = minLimit;
    }

    function buy(uint256 payment) public {
        uint256 blackAndWhitePrice = getBWprice();
    
        //Calculate token amount to send and perform check
        uint256 tokensAmount = wdiv(payment, blackAndWhitePrice.mul(2));
        require(tokensAmount >= _minBlackAndWhiteBuy);

        //Perform actions
        _collateralization.buy(msg.sender, tokensAmount, payment);
        emit Buy(tokensAmount, payment);
    }

    function changeGovernanceAddress(address governanceAddress)
        public
        onlyGovernance
    {
        require(
            governanceAddress != address(0),
            "New governance address is empty"
        );
        _governanceAddress = governanceAddress;
    }

    function getBWprice() public view returns (uint256) {
        // Get data from collateralization contract
        uint256 collateral = _collateralization.getCollateralization();
        uint256 bwtSupply = _collateralization.getBwtSupply();

        /*
            Calculate token price. If current collateralization is less than default price use default price.
            If token collateralization is higher than default price difine new price from collateralization.
        */
        uint256 defaultTokensPrice = _blackAndWhitePrice;
        if (bwtSupply == 0) {
            return defaultTokensPrice;
        }

        uint256 newPrice = wdiv(collateral, bwtSupply.mul(2));
        if (newPrice > defaultTokensPrice) {
            return newPrice;
        }
        return defaultTokensPrice;
    }

    function buyBack(address destination, uint256 tokensAmount) public {
        require(
            destination != address(0),
            "Destination address is empty"
        );

        uint256 bwtPrice = getBWprice().mul(2);
        uint256 collateralAmount = wmul(tokensAmount, bwtPrice);
        require(
            _collateralization.getCollateralization() >= collateralAmount,
            "Not enought collateral on the conrtact"
        );

        //Perform actions
        _collateralization.buyBack(destination, tokensAmount, collateralAmount);
        emit BuyBack(tokensAmount, bwtPrice);
    }
}