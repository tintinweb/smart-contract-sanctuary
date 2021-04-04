pragma solidity ^0.7.4;
// "SPDX-License-Identifier: MIT"

import "./ICollateralizationPrimary.sol";
import "SafeMath.sol";
import "./DSMath.sol";

/*
BW-1 - Initial distribution pool
This contract has no fees.

Description
+ Fn1:
    Name: buyBlackAndWhite. 
    Creates request to buy B&W tokens from Collateralization contract. 
    Contains restriction on minimum purchase amount of tokens. By default 1000 B + 1000 W. 
    Uses Get Black&White function(Fn2) to calculate price and amount. 
    Receives Ethereum and user address to send Black and white tokens as parameters.
+ Fn2: 
    Name: changeGovernanceAddress
    Update Gouvernance address. 
    Same as collateralization contract Fn3.
+ Fn3:
    Name: getBWprice
    Get Black&White tokens price. 
    Function calculates and sends as result Black & White tokes price according to data from the Collateralization contract. 
    So it will be one price to buy Black & White tokens together. 
    Furture functionality: Also price should take in account that some amount of tokens we will buy from the secondary pool. 
    It is from 0 to 50% of the requested amount and secondary pool commission will be paid for this amount. 
    How we understand wich amount will be bought from the secondary pool: 
    for the first 10_000_000 Black and same amount of White tokens there is no no buy from the secondary pool operation. 
    After this amount of tokens bought from the Initial distribution pool we should buy according to SPIPBB table below 
    up to 50% of the amount from the secondary pool but taking no more than 1% of secondary pool liquidity. 
Future functionality: Fn4. Extra Buyback. Function gives the ability to buy back Black or White tokens separately with much higher commission than in the secondary pool. Function exists only for cases when Market makers withdraw all ethereum from the secondary pool. Function has limits of tokens to buyback in one operation. 1% bought black and white tokens from the pool. tokens by default. It is calculated by deviation from the proportion of 50/50 B&W tokens in the pool. So this limit should mean that proportion cannot be changed more than. Default commission is 10%
Future functionality: Fn5. Function to set external buyback commissions. Callable only from gouvernance address.
Future functionality: Fn7. Sell a disproportionate amount. Wrapper for collateralisation contract Fn10. If a collateralisation contract contains more tokens of one type after external buyback operation it can sell this disproportionate amount of tokens without buying a second token. Disproportionate amount is the amount of tokens to reduce to get a 50/50 proportion in a collateralisation contract. 
Fn8. A function to receive fees from the secondary pool and recalculate price of B&W tokens. Fees are distributed between B&W tokens according to the current proportion of its price. Fees can be received from any address. This math should include total tokens supply, not only available tokens in collateralisation contracts.
+ Fn9.
    Name: buylimitsUpdate
    Update minimal limits for buyBlackAndWhiteFunction. 
    Callable only from governance contract.
+ Fn10. 
    Name: buyback
    Function to buy back Black and white tokens together.
*/
contract PrimaryPool is DSMath {
    using SafeMath for uint256;

    address public _collateralizationAddress;
    address public _governanceAddress;

    ICollateralizationPrimary _collateralization;

    //Minimum amount of both tokens to buy
    uint256 public _minBlackAndWhiteBuy;
    //Price for 2 tokens
    uint256 public _blackAndWhitePrice;
    // Total supply for both tokens
    uint256 internal constant MAX_TOKENS = 2e9 * 1e18;

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
            "COLLATERIZATION ADDRESS SHOULD BE NOT NULL"
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
            "CALLER SHOULD BE GOVERNANCE"
        );
        _;
    }

    function buylimitsUpdate(uint256 minLimit) public onlyGovernance {
        _minBlackAndWhiteBuy = minLimit;
    }

    function buy(uint256 payment) public payable {
        uint256 blackAndWhitePrice = getBWprice();
    
        //Calculate token amount to send and perform check
        uint256 tokensAmount = wdiv(payment, blackAndWhitePrice);
        require(tokensAmount >= _minBlackAndWhiteBuy);
        uint256 oneTokenAmount = tokensAmount.div(2);

        //Perform actions
        _collateralization.buy(msg.sender, oneTokenAmount, payment);
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
        uint256 whiteSupply = _collateralization.getWhiteSupply();
        uint256 blackSupply = _collateralization.getBlackSupply();
        uint256 curSupply = whiteSupply.add(blackSupply);
        uint256 soldSupply = MAX_TOKENS.sub(curSupply);

        /*
            Calculate token price. If current collateralization is less than default price use default price.
            If token collateralization is higher than default price difine new price from collateralization.
        */
        uint256 defaultTokensPrice = _blackAndWhitePrice;
        if (soldSupply == 0) {
            return defaultTokensPrice;
        }

        uint256 newPrice = wdiv(collateral, soldSupply);
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

        uint256 blackAndWhitePrice = getBWprice();
        uint256 collateralAmount = wmul(tokensAmount.mul(2), blackAndWhitePrice);
        require(
            _collateralizationAddress.balance >= collateralAmount,
            "Not enoght collateral on the conrtact"
        );

        //Perform actions
        _collateralization.buyBack(destination, tokensAmount, collateralAmount);
        emit BuyBack(tokensAmount, blackAndWhitePrice);
    }
}