/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Description:
// This is a naive implementation (and just a stupid idea altogether) of a shared wallet where users can:
// 1. Deposit funds in the contract and have their balances tracked. DONE
// 2. A user should not be able to withdraw from their wallet until at least 2 blocks have passed since the wallet
// was initially created (not yet implemented). DONE
// 3. Withdraw funds up to the amount that they have deposited. DONE
// 4. The owner of the contract should also have the ability to emergency withdraw all of the funds. DONE

// There are a number of bugs and security vulnerabilities.


// TODO:
// 1. Please remedy as many bugs/exploits as you can.

// 2. Implement the 2 block withdrawal time limit outlined in #2 above ^.

// 3. Deploy the contract to the Polygon Mumbai Testnet and send your recruiter the contract address.

contract SharedWallet {

    address public _owner;
    mapping(address => uint) public _walletBalances;
    mapping(address => uint) public _blockNumbers;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier blockTimeCheck(){
        require(_blockNumbers[msg.sender]+2 < block.number );
        _;
    }

    modifier checkOverdraft(uint amount){
        require(_walletBalances[msg.sender]>=amount);
        _;
    }

    constructor () {
        _owner = msg.sender;
    }

    receive() external payable {
    }

    function deposit() public payable {
        if(_blockNumbers[msg.sender]==0){
            _blockNumbers[msg.sender] = block.number;
        }
        payable(address(this)).transfer(msg.value);
        _walletBalances[msg.sender] += msg.value;
    }

    function withdraw(uint amount)  checkOverdraft(amount) blockTimeCheck() public payable  {
        payable(msg.sender).transfer(amount);
        _walletBalances[msg.sender] -= amount;
    }

    function emergencyWithdrawAllFunds() isOwner() public {
        require(msg.sender == _owner);
        payable(msg.sender).transfer(address(this).balance);
    }
}