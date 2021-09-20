/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0 . 6 . 0 ;

contract Escrow{
  address public payer;
  address payable public payee;
  address public lawyer;
  uint public amount;

  struct DepositStruct {
    address payable receiver;
    address approver;
    uint depositAmount;
  }

  struct DepositData {
    DepositStruct[] deposits;
    bool checkpoint;
  }

  mapping(address => DepositData) internal depositdatas;
  
  constructor(
    address _payer, 
    address payable _payee, 
    uint _amount) 
    public {
    payer = _payer;
    payee = _payee;
    lawyer = msg.sender; 
    amount = _amount;
  }

    receive() payable external {
    }

  function deposit() payable public {
    require(msg.sender == payer, 'Sender must be the payer');
    require(address(this).balance <= amount, 'Cant send more than escrow amount');
  }

  function release() public {
    require(address(this).balance == amount, 'cannot release funds before full amount is sent');
    require(msg.sender == lawyer, 'only lawyer can release funds');
    payee.transfer(amount);
  }
  
  function balanceOf() view public returns(uint) {
    return address(this).balance;
  }

  function depositFor(address payable _receiver, address _approver) payable public {
    require(msg.value <= amount, 'Cant send more than escrow amount');
    require(msg.sender != _approver, 'Approver is a different account than the function caller.');
    require(_receiver != _approver, 'Approver is a different account than the receiver.');
    DepositData storage depositdata = depositdatas[msg.sender];
    depositdata.checkpoint = true;
    depositdata.deposits.push(DepositStruct(_receiver, _approver, msg.value));
  }

  function approve(address _address) public {
    DepositData storage depositdata = depositdatas[_address];
    require(msg.sender == _address, "This account is not a approver");
    for(uint256 i = 0; i < depositdata.deposits.length; i++) {
            depositdata.deposits[i].receiver.transfer(depositdata.deposits[i].depositAmount);
    }
    depositdata.checkpoint = false;
    delete depositdata.deposits;
  }
}