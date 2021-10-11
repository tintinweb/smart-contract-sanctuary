/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CDNote {
    
    constructor () {
    noteNumber = 1;
    owner = msg.sender;
    timeLock = 2;//1051200
    rate = 1000; // 10 percent of 10,000
    fee = 1000000000000000; // 1 million gwei
    earlyWithdrawlFee = 1000000000000000; //1 million gwei 
    contractAddress = payable(address(this));
}
    address public owner;
    address payable public contractAddress;
    uint256 public noteNumber;
    uint256 public fee;
    uint256 public earlyWithdrawlFee;
    uint256 public rate; 
    uint256 public timeLock;

modifier onlyOwner() {
    require(msg.sender == owner, "Caller is not owner");
    _;
}

function changeFee(uint256 _fee) onlyOwner public {
    fee = _fee;
}

function changeTimeLock(uint256 _timeLock) onlyOwner public {
    timeLock = _timeLock;
}

function changeEarlyWithdrawlFee(uint256 _earlyWithdrawlfee) onlyOwner public {
    earlyWithdrawlFee = _earlyWithdrawlfee;
}

function changeOwner(address _owner) onlyOwner public {
    owner = _owner;
}

function depositBalance () view public returns(uint256){
return(address(this).balance);
}

function currentBlock () view public returns(uint256){
return(block.number);
}

struct depositNote   {
    uint256 noteNumber; //Note Number
    address accountAddress; //Account Address
    uint256 rate; //CD Rate
    uint256 fee; //CD Fee
    uint256 earlyWithdrawlFee; //Fee for early Withdraw
    uint256 block; //Deposit Block
    uint256 timeLock; //Number of Blocks the Deposit is locked up;
    uint256 ethBalance; //Balance of Eth in CD
    bool state; // false dead true alive 
}

mapping (uint256 => depositNote) public cd;
event newCD (depositNote indexed);
event earlyWithdrawlCD (depositNote indexed, uint256 indexed earlyFee, uint256 indexed totalWithdrawl);
event maturedCD (depositNote indexed, uint256 indexed earned, uint256 indexed totalWithdrawl);

function depositEth () payable public {
    require(msg.value >= fee + earlyWithdrawlFee, "Min deposit not met");
    address _accountAddress = msg.sender;
    uint256 depositValue = msg.value - fee;
    cd[noteNumber] = depositNote(noteNumber,_accountAddress,rate,fee,earlyWithdrawlFee,block.number,timeLock, depositValue, true);
    emit newCD (cd[noteNumber]);
    noteNumber = noteNumber +1;
    
}    

function withdrawlCD (uint256 _noteNumber ) payable public {
    require(cd[_noteNumber].state == true,  "Note has already cleared");
    require(cd[_noteNumber].accountAddress==msg.sender, "Not Note Owner");
    address _accountAddress = cd[_noteNumber].accountAddress;
    address payable _ethreceiver = payable(_accountAddress);
    uint256 _value = cd[_noteNumber].ethBalance;
    uint256 cdMature = cd[_noteNumber].block + cd[_noteNumber].timeLock;
    require (cdMature <= block.number, "cd not matured");
    uint256 _valueEarned = ((_value * 10000)/(cd[_noteNumber].rate)-0/100);
    _value = _value + _valueEarned;
    _ethreceiver.transfer(_value);
    cd[_noteNumber].state = false;
    emit maturedCD(cd[_noteNumber],_valueEarned,_value);
    
}

function earlyWithdrawl (uint256 _noteNumber) payable public {
    require(cd[_noteNumber].state == true, "Note has already cleared");
    require(cd[_noteNumber].accountAddress==msg.sender, "Not Note Owner");
    address _accountAddress = cd[_noteNumber].accountAddress;
    address payable _ethreceiver = payable(_accountAddress);
    uint256 _value = cd[_noteNumber].ethBalance;
    _value = _value - cd[_noteNumber].earlyWithdrawlFee;
    _ethreceiver.transfer(_value);
    cd[_noteNumber].state = false;
    emit maturedCD(cd[_noteNumber],cd[_noteNumber].earlyWithdrawlFee,_value);
    
    
}   
}