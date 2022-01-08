// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICopyFi.sol';
import './IERC20.sol';
import './SafeMath.sol';
import './Ownable.sol';
import './Context.sol';

contract CopyFi is ICopyFi, Ownable {
    IERC20 public token;
    mapping(address => uint256) deposits;
    mapping(uint256 => address) traders;
    mapping(uint256 => uint256) ratios;
    mapping(uint256 => mapping (address => uint256)) follows;

    uint256 lastProductID = 0;

    using SafeMath for uint256;

    constructor(address simpleUSDCAddress) {
        token = IERC20(simpleUSDCAddress);
    }

    function depositOf(address account)
        external
        override
        view
        returns (uint256)
        {
            return deposits[account];
        }

    function traderOf(uint256 productID)
        external
        override
        view
        returns (address)
        {
            return traders[productID];
        }

    function followOf(address account, uint256 productID)
        external
        override
        view
        returns (uint256)
        {
            return follows[productID][account];
        }

    function deposit(uint256 amount)
        external
        override
        returns (bool)
        {
            require(amount > 0);

            uint256 allowance = token.allowance(_msgSender(), address(this));
            require(allowance >= amount);

            require(token.balanceOf(_msgSender()) >= amount);

            token.transferFrom(_msgSender(), address(this), amount);

            deposits[_msgSender()] = deposits[_msgSender()].add(amount);
            emit Deposit(_msgSender(), amount);
            return true;
        }

    function withdrawn(uint256 amount)
        external
        override
        returns (bool)
        {
            require(deposits[_msgSender()] >= amount);
            token.transfer(_msgSender(), amount);
            deposits[_msgSender()] = deposits[_msgSender()].sub(amount);
            return true;
        }

    function registerTrader()
        external
        override
        returns (uint256)
        {
            lastProductID = lastProductID + 1;
            traders[lastProductID] = _msgSender();
            emit ProductID(lastProductID, _msgSender());
            return lastProductID;
        }

    function signal (uint256 productID, int256 amount)
        external
        override
        returns (bool)
        {
            require(_msgSender() == traders[productID]);

            int256 _amount = amount * int256(ratios[productID]) / 100;

            if (_amount > 0) {
                emit Order(_amount, productID);
            }

            return true;
        }

    function follow(uint256 productID, uint256 ratio)
        external
        override
        returns (bool)
        {
            ratios[productID] = ratios[productID] + ratio - follows[productID][_msgSender()];
            follows[productID][_msgSender()] = ratio;
            emit Follow(_msgSender(), productID, ratio);
            return true;
        }

}