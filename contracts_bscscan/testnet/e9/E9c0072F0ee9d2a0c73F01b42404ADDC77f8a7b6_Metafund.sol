/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

contract Metafund {
    // Declare state variables of the contract
    address public _owner;
    address public _manager;
    address payable[] private _investors;

    mapping(address => uint256) public _balances;
    mapping(address => uint256) public _indexOfInvestor;

    event Invest(address from, uint256 value);
    event Withdraw(address to, uint256 value);
    event Transfer(address from,address to, uint256 value);

    constructor() {
        _manager = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == _manager, "only manager");
        _;
    }

    // Investor join into fund
    function invest() public payable {
        require(msg.value > 0, "require investment");
        _balances[msg.sender] += msg.value;

        if (_indexOfInvestor[msg.sender] == 0) {
            _investors.push(payable(msg.sender));
            _indexOfInvestor[msg.sender] = _investors.length;
        }

        emit Invest(msg.sender, msg.value);
    }

    // Left this fund (ether unit)
    function withdraw() public {
        uint amount = _balances[msg.sender];
        require(amount > 0 , "Balance insufficient");
        _balances[msg.sender] = 0;
        
        remove(_indexOfInvestor[msg.sender] - 1);
        delete _indexOfInvestor[msg.sender];

       (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to withdraw");

        emit Withdraw(msg.sender, amount);
    }

    // Close this fund : Refund all investor
    function close() public restricted {
        require(address(this).balance > 0, "Balance insufficient");
        for (uint i = 0; i<_investors.length; i++) {
            address payable addr = _investors[i];
            uint amount = _balances[addr];

            if (amount > 0) {
                _balances[addr] = 0;

                (bool sent, ) = addr.call{value: amount}("");
                require(sent, "Failed to withdraw");

                delete _indexOfInvestor[addr];
                emit Transfer(address(this),addr, amount);
            }
        }
        _investors = new address payable[](0);
    }

    // List investors
    function listInvestor() public view returns(address payable[] memory) {
        return _investors;
    }

    // Get balance in contract (ether uint)
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Move the last element to the deleted spot.
    // Remove the last element.
    function remove(uint256 index) private {
        require(index < _investors.length);
        _investors[index] = _investors[_investors.length-1];
        _investors.pop();
    }

}