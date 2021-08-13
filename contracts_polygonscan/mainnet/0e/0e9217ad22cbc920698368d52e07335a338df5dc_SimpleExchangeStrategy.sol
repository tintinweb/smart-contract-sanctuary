/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IExchangeStrategy {
    function getFee(address token, uint value) external view returns (uint);

    function calcValue(uint reserveIn, uint reserveOut) external view returns(uint);

    function getAmountOut(
        address exchangeToken,
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external view returns (uint amountOut);

    function getAmountIn(
        address exchangeToken,
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external view returns (uint amountIn);
}


pragma solidity ^0.8.4;
// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathTSP {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}


pragma solidity ^0.8.4;
contract SimpleExchangeStrategy is IExchangeStrategy {
    using SafeMathTSP  for uint;

    struct TokenFee {
        uint value;
        uint fee;
    }

    mapping(address => TokenFee[]) public fees;

    uint public constant FEE_MAX_COUNT = 50;

    function getFee(address token, uint value) external view override returns (uint fee) {
        TokenFee[] memory tokenFees = fees[token];

        require(tokenFees.length > 0, "SES: TOKEN_FEE_NOT_SET");

        uint minValue = type(uint).max;
        uint minValueIndex = 0;
        bool wasChanged = false;
        uint currentValue = 0;

        for (uint i = 0; i < tokenFees.length; i++) {
            if (minValue > tokenFees[i].value) {
                minValue = tokenFees[i].value;
                minValueIndex = i;
            }

            if (value >= tokenFees[i].value && currentValue <= tokenFees[i].value) {
                fee = tokenFees[i].fee;
                currentValue = tokenFees[i].value;

                wasChanged = true;
            }
        }

        return !wasChanged ? tokenFees[minValueIndex].fee : fee;
    }

    function calcValue(uint reserveIn, uint reserveOut) external view override returns (uint) {
        return reserveOut / reserveIn;
    }

    function getFees(address token) external view returns (TokenFee[] memory) {
        return fees[token];
    }

    function setTokenFee(address token, uint value, uint fee) external {
        require(token != address(0), "SES: WRONG_TOKEN_ADDRESS");

        TokenFee[] storage tokenFees = fees[token];

        for (uint i = 0; i < tokenFees.length; i++) {
            if (tokenFees[i].value == value) {
                tokenFees[i].fee = fee;
                return;
            }
        }
        require(tokenFees.length < FEE_MAX_COUNT, "SES: FEE_MAX_COUNT");

        tokenFees.push(TokenFee(value, fee));
    }

    function removeTokenFee(address token, uint value) external {
        require(token != address(0), "SES: WRONG_TOKEN_ADDRESS");

        TokenFee[] storage tokenFees = fees[token];

        bool found = false;

        for (uint i = 0; i < tokenFees.length; i++) {
            if (found || tokenFees[i].value == value) {
                found = true;
                tokenFees[i] = i == tokenFees.length - 1 ? tokenFees[i] : tokenFees[i + 1];
            }
        }

        if (found) {
            tokenFees.pop();
        }
    }

    function getAmountOut(address exchangeToken, uint amountIn, uint reserveIn, uint reserveOut)
    external
    view
    override
    returns (uint amountOut) {
        require(amountIn > 0, "SES: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SES: INSUFFICIENT_LIQUIDITY");

        uint256 value = this.calcValue(reserveIn, reserveOut);

        uint amountInWithFee = amountIn.mul(1000 - this.getFee(exchangeToken, value));
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);

        amountOut = numerator / denominator;
    }

    function getAmountIn(address exchangeToken, uint amountOut, uint reserveIn, uint reserveOut)
    external
    view
    override
    returns (uint amountIn) {
        require(amountOut > 0, "SES: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SES: INSUFFICIENT_LIQUIDITY");

        uint256 value = this.calcValue(reserveIn, reserveOut);
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(1000 - this.getFee(exchangeToken, value));

        amountIn = (numerator / denominator).add(1);
    }
}