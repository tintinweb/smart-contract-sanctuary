/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CDNote {
    
    constructor () {
    noteNumber = 1; //CD NOTE #
    DAO = msg.sender;
    fee = 5;// 10,000 = 100% 
    contractAddress = payable(address(this)); //Makes this contract payable
    blocksPerDay = 1;//5760 blocks per day
    timeLockMin = 2; // Days
    timeLockMax = 730; //Days
    loanTimeLimit = 2; //Days
    rateMax = 2000; //Days 
    maxBorrow = 2; // borrow have CD
    earlyBorrowWithdrawlFee = 50; // 10,000 = 100%
    minDeposit = 10000000000000; // 10,000 gwei min deposi
}
    address public DAO; //Dao contract address to make governance calls 
    address payable public contractAddress; // THIS addres
    uint256 public noteNumber; //Number for notes 
    uint256 public fee; //CD creation fee % of deposit 10000 = 100%
    uint256 public earlyBorrowWithdrawlFee; //fee for early withdrawl or borrow of funds % of deposit 10000 = 100%
    uint256 public timeLockMin; //Min time days to lock funds for a matured CD Note
    uint256 public timeLockMax; //Max time days to lock funds for a matured CD Note
    uint256 public rateMax; //Max % rate earned on Max time locked investment 10000 = 100%
    uint256 public blocksPerDay; //5760 blocks per day used for timelock calc for determination of maturity block
    uint256 public maxBorrow; //sets max amount that can be borrowed against cd (1/2 initial #) of Eth Balance
    uint256 public loanTimeLimit; //set days to pay back loan against CD and expires CD if blocks go past due block
    uint256 public minDeposit;// sets a min Deposit ammount 10,000 gwei initial amount 
    uint256 public contractEarn; //how much the contract has earned off fees and liquidation
    bool public godSwitch; // protocol shutdown

//sets control limis on functions to only the DAO address    
modifier onlyDAO() {
    require(msg.sender == DAO, "Caller is not DAO Contract");
    _;
}
//Changes blocks per day should only be changed if major network change makes less or more blocks in a day
function changeBlkPerDay(uint256 _blocksPerDay) onlyDAO public {
    blocksPerDay = _blocksPerDay;
}
//Changes the fee for creating a CD
function changeFee(uint256 _fee) onlyDAO public {
    require(_fee <= 10000, '10,000 is 100%');
    fee = _fee;
}
//Changes the fee for early withdrawl and and borrowing 
function changeEarlyWithdrawlFee(uint256 _earlyBorrowWithdrawlFee) onlyDAO public {
    require(_earlyBorrowWithdrawlFee <= 10000, '10,000 is 100%');
    earlyBorrowWithdrawlFee = _earlyBorrowWithdrawlFee;
}
//Changes DOA Address
function changeOwner(address _DAO) onlyDAO public {
    DAO = _DAO;
}
//Changes Max % interest rate 
function changeRateMax(uint256 _rateMax) onlyDAO public {
    require(_rateMax <= 10000, '10,000 is 100%');
    rateMax = _rateMax;
}
//Changes Max Days of Time Lock
function changeTimeLockMax(uint256 _timeLockMax) onlyDAO public {
    require(_timeLockMax > timeLockMin);
    timeLockMax = _timeLockMax;
}
//Changes Min Days of Time Lock
function changeTimeLockMin(uint256 _timeLockMin) onlyDAO public {
    require(_timeLockMin < timeLockMax);
    timeLockMin = _timeLockMin;
}
// Calls Contract Balance
function contractBalance () view public returns(uint256){
return(address(this).balance);
}
// Calls Current Block
function currentBlock () view public returns(uint256){
return(block.number);
}
// Shuts off Protocol
function setGodSwitchON() onlyDAO public {
    godSwitch = true;
}
// Turns on Protocol 
function setGodSwitchOFF() onlyDAO public {
    godSwitch = false;
}

// all info for a created CD
struct depositNote   {
    uint256 noteNumber; //Note Number
    address accountAddress; //Account Address
    uint256 rate; //CD Rate
    uint256 fee; //CD Fee
    uint256 earlyBorrowWithdrawlFee; //Fee for early Withdraw
    uint256 block; //Deposit Block
    uint256 timeLock; //Number of Blocks the Deposit is locked up;
    uint256 ethBalance; //Balance of Eth in CD
    uint256 maturedValue; //Earned total value after timelock
    uint256 loanPay;
    uint256 loanBlockDue;
    bool valid; // Cd cleared, loaned, or expired on loan
    bool liquidated;
}

//mapping of the created CD based off note number
mapping (uint256 => depositNote) public cd;
//mapping of address to CD note number 1 cd per address
mapping (address => uint256) public cdTracker;

//events within the protocol 
event newCD (depositNote indexed);
event earlyWithdrawlCD (depositNote indexed);
event maturedCD (depositNote indexed);
event loanedCD (depositNote indexed);
event borrowCD (depositNote indexed);
event payLoan (depositNote indexed);
event liquidateCD (depositNote indexed, address indexed);
event transferAddress(depositNote indexed, address indexed);
event fundsAdd(depositNote indexed);

//Deposit of Eth and ceation of CD note , calculates all fees and interest rate for the life of cd 
function depositEth(uint256 _days) payable public {
    require (cdTracker[msg.sender] == 0, "Already Have Valid CD Note Use Another Address");
    uint256 _fee = calcFee(msg.value,fee);
    uint256 _earlyBorrowWithdrawlFee = calcFee(msg.value,earlyBorrowWithdrawlFee);
    require(msg.value >= minDeposit, "Min deposit not met");
    uint256 depositValue = msg.value - _fee;
    uint256 depositRate = rateCalc(_days);
    uint256 maturedValue = (((depositValue)*(depositRate))/10000) + depositValue;
    uint256 depositTimelock = _days * blocksPerDay;
    cd[noteNumber] = depositNote(noteNumber,msg.sender,depositRate,_fee,_earlyBorrowWithdrawlFee,block.number,depositTimelock,depositValue,maturedValue,0,0, true,false);
    cdTracker[msg.sender] = noteNumber;
    emit newCD (cd[noteNumber]);
    noteNumber = noteNumber +1;
    contractEarn = contractEarn + _fee;
} 

//function to withdrawl matured CD Note @ end of timeLock
function withdrawlCD (uint256 _noteNumber ) payable public {
    require(godSwitch == false, "protocol shutdown");
    require(cd[_noteNumber].valid == true,  "Not a valid cd, loaned or cleared");
    require(cd[_noteNumber].accountAddress==msg.sender, "Not Note Owner");
    address _accountAddress = cd[_noteNumber].accountAddress;
    address payable _ethreceiver = payable(_accountAddress);
    uint256 cdMature = cd[_noteNumber].block + cd[_noteNumber].timeLock;
    require (cdMature <= block.number, "cd not matured");
    _ethreceiver.transfer(cd[_noteNumber].maturedValue);
    emit maturedCD(cd[_noteNumber]);
    cd[_noteNumber].valid = false;
    cd[_noteNumber].ethBalance = 0;
    cd[_noteNumber].maturedValue = 0;
    cdTracker[cd[_noteNumber].accountAddress] = 0;
}
//function to withdrawl the balance in the cd and not take cd to maturity
function earlyWithdrawl (uint256 _noteNumber) payable public {
    require(godSwitch == false, "protocol shutdown");
    uint256 cdMature = cd[_noteNumber].block + cd[_noteNumber].timeLock;
    require (cdMature >= block.number, "use withdrawl CD");
    require(cd[_noteNumber].valid == true, "Not a valid cd, loaned or cleared");
    require(cd[_noteNumber].accountAddress==msg.sender, "Not Note Owner");
    address _accountAddress = cd[_noteNumber].accountAddress;
    address payable _ethreceiver = payable(_accountAddress);
    uint256 _value = cd[_noteNumber].ethBalance;
    _value = _value - cd[_noteNumber].earlyBorrowWithdrawlFee;
    _ethreceiver.transfer(_value);
    cd[_noteNumber].valid = false;
    cd[_noteNumber].ethBalance = 0;
    cd[_noteNumber].maturedValue = 0;
    cdTracker[cd[_noteNumber].accountAddress] = 0;
    cd[_noteNumber].liquidated = true;
    emit earlyWithdrawlCD(cd[_noteNumber]);
    contractEarn = contractEarn + cd[_noteNumber].earlyBorrowWithdrawlFee;
} 
//funtion to borrow from the cd with the ability to repay and still have cd mature if paid in certain time period
function borrowWithdrawl(uint256 _noteNumber, uint256 _value) payable public {
    require(godSwitch == false, "protocol shutdown");
    require(cd[_noteNumber].valid == true,  "Not a valid cd, loaned or cleared");
    require(cd[_noteNumber].accountAddress== msg.sender, "Not Note Owner");
    require((cd[_noteNumber].ethBalance - cd[_noteNumber].earlyBorrowWithdrawlFee )/ maxBorrow >= _value, "Over Borrow Limit");
    address _accountAddress = cd[_noteNumber].accountAddress;
    address payable _ethreceiver = payable(_accountAddress);
    cd[_noteNumber].ethBalance = cd[_noteNumber].ethBalance - cd[_noteNumber].earlyBorrowWithdrawlFee - _value;
    cd[_noteNumber].loanBlockDue = block.number + (loanTimeLimit * blocksPerDay);
    cd[_noteNumber].loanPay = _value; 
    _ethreceiver.transfer(_value);
    cd[_noteNumber].valid = false;
    emit borrowCD(cd[_noteNumber]);
    contractEarn = contractEarn + cd[_noteNumber].earlyBorrowWithdrawlFee;
}
//function ot pay back loan and revalidate cd
function payLoanCD(uint256 _noteNumber)payable public{
    require(godSwitch == false, "protocol shutdown");
    require(cd[_noteNumber].valid == false, "CD has no loan");
    require(cd[_noteNumber].accountAddress==msg.sender, "Not Note Owner");
    require(cd[_noteNumber].loanBlockDue >= block.number, "Block Time Limit is Expired");
    require(msg.value >= cd[_noteNumber].loanPay, "More Value required" );
    cd[_noteNumber].ethBalance = cd[_noteNumber].ethBalance + cd[_noteNumber].loanPay;
    cd[_noteNumber].loanPay = 0;
    cd[_noteNumber].loanBlockDue = 0;
    cd[_noteNumber].valid = true;
    emit payLoan(cd[_noteNumber]);
}
//function to liquidate invalid notes and overdue loans 
function liquidCD(uint256 _noteNumber)public {
    require(godSwitch == false, "protocol shutdown");
    require(cd[_noteNumber].valid == false , "CD not loaned");
    require(cd[_noteNumber].loanBlockDue <= block.number||cd[_noteNumber].timeLock <= block.number, "CD Matured while under Loan");
    require(cd[_noteNumber].accountAddress != 0x0000000000000000000000000000000000000000, 'Not a valid CD');
    cd[_noteNumber].valid = false;
    cd[_noteNumber].liquidated = true;
    cdTracker[cd[_noteNumber].accountAddress] = 0;
    emit liquidateCD(cd[_noteNumber], msg.sender);
    cd[_noteNumber].loanPay = 0;
    cd[_noteNumber].loanBlockDue = 0;
    cd[_noteNumber].ethBalance = 0;
    cd[_noteNumber].maturedValue = 0;
    contractEarn = contractEarn + (cd[_noteNumber].ethBalance - cd[_noteNumber].loanPay) ;
}
//fuction of fee calculation for protocol to earn for service
function calcFee(uint256 _value, uint256 _fee) pure public returns(uint256){
    uint256 feeCalc = _value * _fee / 10000 ; 
    return(feeCalc);
}
//function of interest rate based of days locked and max rate
function rateCalc(uint256 _days) view public returns(uint256){
    require(godSwitch == false, "protocol shutdown");
    require(timeLockMin <=_days, "Not enough days");
    require(timeLockMax >=_days, "too many days");
    uint256 slope = (rateMax)/timeLockMax;
    uint256 calcRate = _days * slope;
    return(calcRate);
}

//transfer cd to another account
function transferCD(uint256 _noteNumber, address _newAddress) public {
    require(godSwitch == false, "protocol shutdown");
    require(cd[_noteNumber].accountAddress==msg.sender, "Not Note Owner");
    require(cd[_noteNumber].loanBlockDue < block.number, "Block Time Limit is Expired");
    require(cd[_noteNumber].valid == true,  "Not a valid cd, loaned or cleared");
    emit transferAddress(cd[noteNumber],_newAddress);
    cdTracker[cd[_noteNumber].accountAddress] = 0;
    cd[_noteNumber].accountAddress = _newAddress;
    cdTracker[_newAddress] = _noteNumber;
}
//can send more money to cd at any time during maturing stage but can not be removed early without fee and doesnt earn interst (Form of savings with timelock)
function addFunds(uint256 _noteNumber)payable  public{
    require(godSwitch == false, "protocol shutdown");
    require(cd[_noteNumber].accountAddress==msg.sender, "Not Note Owner");
    require(cd[_noteNumber].loanBlockDue < block.number, "Block Time Limit is Expired");
    require(cd[_noteNumber].valid == true,  "Not a valid cd, loaned or cleared");
    cd[_noteNumber].ethBalance = cd[_noteNumber].ethBalance + msg.value;
    cd[_noteNumber].maturedValue = cd[_noteNumber].maturedValue + msg.value; 
    emit fundsAdd(cd[_noteNumber]);
    
    
}
}