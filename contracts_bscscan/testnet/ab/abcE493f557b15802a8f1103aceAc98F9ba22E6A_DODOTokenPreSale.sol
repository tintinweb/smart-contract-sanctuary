/*

    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity ^0.6.9;

import {InitializableERC20} from "../InitializableERC20.sol";

contract DODOTokenPreSale {
    InitializableERC20 public token;
    address public beneficiary;
    address public alfatokenteam;
    
    uint public amountRaised;
    
    uint public bonus;
    uint public price;    
    uint public minSaleAmount;

    constructor(
        InitializableERC20 _token,
        address _beneficiary,
        address _alfatokenteam
    ) public {
        token = InitializableERC20(_token);
        beneficiary = _beneficiary;
        alfatokenteam = _alfatokenteam;
        bonus = 25;
        price = 1;
        minSaleAmount = 1000000000;
    }

    receive () external payable {
        uint amount = msg.value;
        uint tokenAmount = amount * price;
        if (tokenAmount < minSaleAmount) revert();
        amountRaised += amount;
        token.transfer(msg.sender, tokenAmount * (100 + bonus) / 100);
    }

    function TransferETH(address payable _to, uint _amount) public {
        require(msg.sender == beneficiary || msg.sender == alfatokenteam);
        _to.transfer(_amount);
    }

    function TransferTokens(address _to, uint _amount) public {
        require(msg.sender == beneficiary || msg.sender == alfatokenteam);
        token.transfer(_to, _amount);
    }

    function ChangeBonus(uint _bonus) public {
        require(msg.sender == beneficiary || msg.sender == alfatokenteam);
        bonus = _bonus;
    }
    
    function ChangePrice(uint _price) public {
        require(msg.sender == beneficiary || msg.sender == alfatokenteam);
        price = _price;
    }
    
    function ChangeMinSaleAmount(uint _minSaleAmount) public {
        require(msg.sender == beneficiary || msg.sender == alfatokenteam);
        minSaleAmount = _minSaleAmount;
    }
}