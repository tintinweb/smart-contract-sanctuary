/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

// This contract keeps all Ether sent to it with no way
// to get it back.
contract AdoptionAmplifer {

    struct RecordInfo {
        uint256 amount;
        uint256 time;
        bool claimed;
        address user;
    }

    address[] private allAddresses;
    address private owner;
    
    mapping (uint => RecordInfo[]) public records;
    mapping (uint => uint256) public totalETH;
    mapping (uint => uint256) public totalHexAvailable;
    mapping (uint => bool) public checkDay;
    uint256 startDate = 1641495600;
    event Received(address, uint256);

    constructor() {
        owner=msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

     function findDay() public view returns(uint) {

        return (block.timestamp - startDate) / 86400;
    }

    function getBalance() public payable isOwner {
        address payable ownerAddress = payable(msg.sender);
        uint256 balance = address(this).balance;
        require( balance > 0, 'not enough balance');
        ownerAddress.transfer(address(this).balance);
    }

    function getAllAddresses() public view returns (address[] memory a) {

        address[] memory allAddressData = new address[](allAddresses.length);
        for (uint i=0; i < allAddresses.length; i++) {
            allAddressData[i] = allAddresses[i];
        }
        return allAddressData;
    }

    function addRecord (address _sender, uint256 _amount) internal {
        require(_amount > 0, 'Amount must be greater than 0');
        uint day = findDay();
     
        RecordInfo memory myRecord = RecordInfo({amount: _amount, time: block.timestamp, claimed: false, user:_sender});
        records[day].push(myRecord);
        totalETH[day] = totalETH[day] + _amount;
        bool check = false;
        for (uint i=0; i < allAddresses.length; i++) {
            if( allAddresses[i] == _sender ) {
                check = true;
            }
        }
        if(!check) {
            allAddresses.push(_sender);
        }
    }

    function getTransactionRecords(uint day) public view returns (RecordInfo[] memory record) {
        
        return records[day];
    }

    function settleSubmission (address _sender ,uint day) public isOwner {
        RecordInfo[] memory myRecord = records[day];
        for(uint i = 0; i<myRecord.length; i++){
            if(myRecord[i].user == _sender){
                 myRecord[i].claimed = true;
                 records[day][i] = myRecord[i];
            }
        }
    }

    function clearSubmission (address _sender ) public isOwner {
        for (uint i = 0; i < allAddresses.length ; i++){
            if( allAddresses[i] == _sender ) {
                allAddresses[i] = allAddresses[allAddresses.length - 1];
                delete allAddresses[allAddresses.length - 1];
            }
        }
    }

    function getTotalETH (uint day) public view returns (uint256){
       return totalETH[day];
    }

    function setAvailabeHex (uint256 hexAvailabel) public isOwner {
        uint day = findDay();
        bool _findDay = checkDay[day];
        require(!_findDay,'Available hex can not set twice');
        totalHexAvailable[day] = totalHexAvailable[day] + hexAvailabel;
        checkDay[day] = true;
    }

    function getAvailableHex (uint day) public view returns (uint256){
       return totalHexAvailable[day];
    }

    receive() external payable {
        addRecord(msg.sender, msg.value);
    }

    function totalBalance() external view returns(uint) {
     //return address(owner).balance;
     return payable(address(this)).balance;
    }

    function withdraw() public isOwner {
     payable(msg.sender).transfer(this.totalBalance());
    }
   }