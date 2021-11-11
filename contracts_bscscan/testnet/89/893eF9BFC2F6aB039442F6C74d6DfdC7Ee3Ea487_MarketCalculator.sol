/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

contract MarketCalculator {
    using SafeMath for uint256;

    /*
    @params:
    - _amount: aToken or pToken
    - _marketPrice: n aToken per Token or n pToken per Token
    - _decimals: aToken or pToken decimals
    @returns:
    - principleAmount: amount a/p Token <==> principleAmount principleToken
    */
    function principleAmount(
        uint256 _amount, 
        uint256 _marketPrice, 
        uint256 _decimals
    ) public pure returns(uint256) {
        return _amount.mul(_marketPrice).div(10 ** _decimals);
    }

    /*
    @params:
    - _totalFunds: public total funds
    - _mintTokens: public mint tokens
    - _prinDecimals: principle decimals
    - _decimals: pToken decimals
    @returns:
    - marketPrice: buy one token need marketPrice pToken
    */
    function marketPrice(
        uint256 _totalFunds, 
        uint256 _mintTokens, 
        uint256 _prinDecimals, 
        uint256 _decimals
    ) public pure returns (uint256) {
        uint256 _totalFundsOfPToken = _totalFunds.mul(_decimals).div(_prinDecimals);
        uint256 _price = _totalFundsOfPToken.div(_mintTokens);

        return _price;
    }

    /*
    @params:
    - _amount: pToken amount
    - _totalFunds: public total funds
    - _mintTokens: public mint tokens
    - _prinDecimals: principle decimals
    - _decimals: pToken decimals
    @returns:
    - marketValue: marketValue token can _amount pToken exchange
    */
    function marketValue(
        uint256 _amount, 
        uint256 _totalFunds, 
        uint256 _mintTokens, 
        uint256 _prinDecimals, 
        uint256 _decimals
    ) public pure returns (uint256) {
        uint256 _prinAmount = principleAmount(_amount, 10**_prinDecimals, _decimals);
        uint256 _newTotalFunds = _totalFunds.add(_prinAmount);
        uint256 _value = _mintTokens.mul(_prinAmount).div(_newTotalFunds);
        
        return _value;
    }
}