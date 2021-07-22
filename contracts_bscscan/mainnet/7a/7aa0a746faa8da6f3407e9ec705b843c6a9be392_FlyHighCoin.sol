// SPDX-License-Identifier: MIT

/*
Name: Fly High Coin
Symbol: $FLYH

MIT License

Copyright (c) 2021 Fly High Coin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ILiquidityPool.sol";


contract FlyHighCoin is IERC20, IERC20Metadata, Context, Ownable {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _supply;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    //Used for rebase authentication
    address private _masterContractAddress;

    //Used to prevent malicious bots.
    uint256 public _maxTransactionLimit;
    mapping(address => bool) public _bannedBots;

    address public _lpAddress;
    ILiquidityPool private _lpContract;


    event RebaseStatus(uint256 rebaseValue, uint256 supply);


    modifier isMasterContract {
        require(msg.sender == _masterContractAddress);
        _;
    }

    modifier isMaxTransLimitExceeded(uint256 amount) {
        require(amount <= _maxTransactionLimit || owner() == msg.sender || _masterContractAddress == msg.sender, "FLYH: Max transaction limit per transfer execeeded.");
        _;
    }

    modifier isBannedBot(address sender) {
        require(_bannedBots[sender] != true, "FLYH: Transaction is currently restricted for the sender.");
        _;
    }


    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 supply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _supply = supply_ * 10**_decimals;

        _balances[msg.sender] = _supply;

        emit Transfer(address(0), msg.sender, _supply);
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

   function totalSupply() external view override returns (uint256) {
       return _supply;
   }

   function balanceOf(address account) external view override returns (uint256) {
       return _balances[account];
    }

    function transfer(address to, uint256 amount)  external override isMaxTransLimitExceeded(amount) isBannedBot(msg.sender) returns (bool) {
        require(msg.sender != address(0), "FLYH: Invalid sender address.");
        require(to != address(0), "FLYH: Invalid receiver address.");
        require(amount <= _balances[msg.sender], "FLYH: Insufficient balance in the sender account.");

        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override isMaxTransLimitExceeded(amount) isBannedBot(from) returns (bool) {
        require(from != address(0), "FLYH: Invalid sender address.");
        require(to != address(0), "FLYH: Invalid receiver address.");
        require(amount <= _balances[from], "FLYH: Insufficient balance in the sender account.");

        uint256 currentAllowance = _allowances[from][msg.sender];

        require(amount <= currentAllowance, "FLYH: Allowance amount exceeded.");
        _allowances[from][msg.sender] -= amount;

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(msg.sender != address(0), "FLYH: Invalid sender address.");
        require(spender != address(0), "FLYH: Invalid spender address.");

        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function setMasterContractAddress(address masterContractAddress) external onlyOwner returns(bool) {
        _masterContractAddress = masterContractAddress;
        return true;
    }

    function setMaxTransactionLimit(uint256 mValue) external isMasterContract returns(bool) {
        _maxTransactionLimit = mValue * 10**_decimals;
        return true;
    }

    function banBotAddress(address account, bool bState) external isMasterContract returns(bool) {
        _bannedBots[account] = bState;
        return true;
    }

    function setLpAddress(address lpAddress) external isMasterContract returns(bool) {
        _lpAddress = lpAddress;
        _lpContract = ILiquidityPool(_lpAddress);
        return true;
    }

    function rebase(address rAddress, uint256 rValue, bool nRebase, bool sRebase, bool lRebase) external isMasterContract returns(bool) {
        uint256 rebaseValue = rValue * 10**_decimals;

        if(nRebase) {
            _balances[rAddress] -= rebaseValue;
            _supply -= rebaseValue;
        }
        else {
            _balances[rAddress] += rebaseValue;
            _supply += rebaseValue;
        }

        if(sRebase) {
            _lpContract.sync();
            emit RebaseStatus(rebaseValue, _supply);
        }

        if(lRebase) {
            emit Transfer(address(0), rAddress, rebaseValue);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _allowances[msg.sender][spender] += addedValue;

        emit Approval(msg.sender, spender, addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subractedValue) external returns (bool) {
         require(subractedValue <= _allowances[msg.sender][spender], "FLYH: Decrease allowance is greater than approved allowance");

        _allowances[msg.sender][spender] -= subractedValue;

        emit Approval(msg.sender, spender, subractedValue);
        return true;
    }

}