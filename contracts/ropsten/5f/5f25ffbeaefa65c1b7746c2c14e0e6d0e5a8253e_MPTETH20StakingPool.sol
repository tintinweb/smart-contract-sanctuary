/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

//"SPDX-License-Identifier: MIT"

pragma solidity ^0.7.5;

interface IDepositContract {
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}

contract MPTETH20StakingPool {
    mapping(address => uint) public balances;
    mapping(bytes => bool) public pubkeysUsed;
    IDepositContract public depositContract = IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
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
        end = block.timestamp + 7 days;
    }
    
    function invest() external payable {
        require(block.timestamp < end, 'too late');
        if(balances[msg.sender] == 0) {
            emit NewInvestor(msg.sender);   
        }
        uint fee = msg.value * 1 / 100;
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
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    )
        external
    {
        require(finalized == true, 'too early');
        require(msg.sender == admin, 'only admin');
        require(address(this).balance >= 32 ether);
        require(pubkeysUsed[pubkey] == false, 'this pubkey was already used');
        depositContract.deposit{value: 32 ether}(
            pubkey, 
            withdrawal_credentials, 
            signature, 
            deposit_data_root
        );
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