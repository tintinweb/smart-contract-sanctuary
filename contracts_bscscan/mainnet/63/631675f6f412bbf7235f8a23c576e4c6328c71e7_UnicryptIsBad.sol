/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: 0BSD

pragma solidity ^0.8.10;

interface ERC20 {
    function transfer(address to, uint tokens) external;
    function transferFrom(address from, address to, uint tokens) external;
    function balanceOf(address owner) external returns (uint);
}

contract UnicryptIsBad { // can handle rebasing tokens, simple locks, and "warning-with-delay" locks

    mapping(uint => address) public owners;
    mapping(uint => address) public tokens;
    mapping(uint => uint) public amounts;
    mapping(uint => uint) public dates;
    mapping(uint => uint) public delays;
    mapping(address => uint) public totals;
    uint public id;

    function lock(address token, uint amount, uint date, uint delay) public {
        require(amount > 0, "amount must be greater than 0");
        uint balance = ERC20(token).balanceOf(address(this));
        owners[id] = msg.sender;
        tokens[id] = token;
        dates[id] = date;
        delays[id] = delay;
        ERC20(token).transferFrom(msg.sender, address(this), amount);
        amount = ERC20(token).balanceOf(address(this)) - balance;
        emit Lock(token, msg.sender, amount, date, delay, id);
        amounts[id] = amount;
        totals[token] += amount;
        id++;
    }

    function unlock(uint id_) public {
        require(block.timestamp >= dates[id_], "not yet unlockable");
        require(owners[id_] != address(0), "invalid");
        require(msg.sender == owners[id_], "not lock owner");
        if (delays[id_] > 0) { // if lock has a delay
            if (dates[id_] == 0) { // but no date assigned
                uint date = block.timestamp + delays[id_];
                emit Warning(id_, date);
                dates[id_] = date;
            } else { // and date has been assigned
                _unlock(id_);
            }
        } else { // if lock has no delay
            _unlock(id_);
        }
    }

    function _unlock(uint id_) internal {
        totals[tokens[id_]] -= amounts[id_];
        ERC20(tokens[id_]).transfer(owners[id_], amounts[id_]);
        emit Unlock(id_);
        owners[id_] = address(0);
        tokens[id_] = address(0);
        amounts[id_] = 0;
        dates[id_] = 0;
        delays[id_] = 0;
    }

    function skim(address token) public {
        uint extra = ERC20(token).balanceOf(address(this)) - totals[token];
        if (extra > 0)
            ERC20(token).transfer(msg.sender, extra);
    }

    event Lock(address indexed token, address indexed locker, uint amount, uint date, uint delay, uint id);
    event Unlock(uint indexed id);
    event Warning(uint indexed id, uint date);

}