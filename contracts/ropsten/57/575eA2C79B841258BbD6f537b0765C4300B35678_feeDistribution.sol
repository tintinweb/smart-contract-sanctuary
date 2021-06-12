/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

contract feeDistribution {
    
    struct Payee {
        uint payeeFees;
        address payeeAddress;
    }
    
    mapping (uint => Payee) payeeList;
    
    mapping (address => bool) payeeAddresses;
    
    uint public payeeCount;
    
    uint feesSum;
    
    address public owner;
    
    modifier isOwner {
        require(msg.sender == owner, "Function can only be called by an owner");
        _;
    }
    
    event PayeeAdded(
        uint fees,
        address payeeAddress
        );
        
    event PayeeModified(
        uint index,
        uint fees,
        address payeeAddress
        );
    
    event DistribtuionComplete (uint distributionTime);
    
    constructor() {
        payeeCount = 0;
        owner = msg.sender;
        feesSum = 0;
    }
    
    receive() external payable {
        distributePayment();
    }
    
    fallback() external payable {
        distributePayment();
    }
    
    function addPayee(uint _fees, address _payeeAddress) public isOwner returns (bool) {
        require(!payeeAddresses[_payeeAddress], "Payee by this address is already in the list");
        Payee memory newPayee = Payee(_fees, _payeeAddress);
        payeeCount = payeeCount + 1;
        payeeList[payeeCount] = newPayee;
        feesSum = feesSum + _fees;
        payeeAddresses[_payeeAddress] = true;
        emit PayeeAdded(_fees, _payeeAddress);
        return true;
    }
    
    function modifyPayeeByIndex(uint _index, uint _newFees,address _newAddress) public isOwner returns (bool) {
        require(payeeList[_index].payeeFees > 0, "Payee with this index doesn't exist");
        feesSum = feesSum - payeeList[_index].payeeFees;
        payeeList[_index].payeeFees = _newFees;
        payeeList[_index].payeeAddress = _newAddress;
        delete payeeAddresses[payeeList[_index].payeeAddress];
        payeeAddresses[_newAddress] = true;
        feesSum = feesSum + _newFees;
        emit PayeeModified(_index, _newFees, _newAddress);
        return true;
    }
    
    function distributePayment() public payable returns (bool) {
        require(payeeCount > 0, "No payees defined for distribution");
        require(msg.value == feesSum * 10**18, "The balance is less than distribution amount");
        for (uint i = 1; i <= payeeCount; i++){
            payable(payeeList[i].payeeAddress).transfer(payeeList[i].payeeFees*10**10);
        }
        emit DistribtuionComplete(block.timestamp);
        return true;
    }
    
    function deletePayeeList() public isOwner returns (bool) {
        require(payeeCount > 0, "No payees defined for distribution");
        for (uint i = 1; i <= payeeCount; i++){
            delete payeeAddresses[payeeList[i].payeeAddress];
            delete payeeList[i];
        }
        payeeCount = 0;
        feesSum = 0;
        return true;
    }
    
    function viewPayeeDetails(uint _index) public view isOwner returns (uint payeeFees, address payeeAddress) {
        require(payeeCount > 0, "No payees defined for distribution");
        require(payeeList[_index].payeeFees > 0, "Payee with this index doesn't exist");
        return (payeeList[_index].payeeFees, payeeList[_index].payeeAddress) ;
    }
    
}