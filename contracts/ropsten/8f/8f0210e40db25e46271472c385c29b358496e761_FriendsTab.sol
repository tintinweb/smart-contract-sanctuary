/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FriendsTab {

    struct Member {
        mapping(address => uint) owed;
        uint balance;
        string name;
        bool active;
    }

    mapping(address => Member) members;

    address public admin;
    uint public withdrawalFee;
    uint public withdrawalFeeBalance;
    
    event MemberCreation(address indexed newMemberAddress, string name);
    event NewApplication(address indexed addr, string name);
    event Admission(address indexed admitteeAddress, string admitteeName);
    event Expulsion(address indexed expulseeAddress, string expulseeName);
    event NewPaymentObligation(address indexed debtor, address creditor, uint amount);
    event UpdatedPaymentObligation(address indexed debtor, address creditor, uint amount);
    event FulfilledPaymentObligation(address indexed debtor, address creditor, uint amount);
    event WithdrawalFeeAdjustment (uint newFee);
    event WithdrawalFeePayout(address indexed initiator, uint amount);
    
    // ADMINISTRATIVE FUNCTIONS------------------------------------------------------------------------------------------------------

    constructor() {
        admin = msg.sender;
        members[msg.sender].name = "Utz";
        members[msg.sender].active = true;
        withdrawalFee = 1000;
    }

    // There is a small fee (standard: 1000 wei) imposed for every withdrawal made by a member from their balance.
    // The idea is to implement a sort of savings scheme where after several withdrawals, the friends can buy something for the accumulated fees together.
    function changeWithdrawalFee(uint newFee) external {
        require(msg.sender == admin, "Only admin can change withdrawal fee!");
        withdrawalFee=newFee;
        emit WithdrawalFeeAdjustment(newFee);
    }

    // Pay out all accumulated withdrawal fees to the admin calling this function.
    // The admin is the only one who can initiate this payout (to themselves) currently. To provide auditability, an event is emitted everytime this happens.
    function payOutFees() external {
        require(msg.sender == admin, "Only admin can withdraw fee balance!");
        require(withdrawalFeeBalance > 0, "Balance too low! ");
        payable(msg.sender).transfer(withdrawalFeeBalance);
        emit WithdrawalFeePayout(msg.sender, withdrawalFeeBalance);
    }

    // Creates a new, already activated member.
    // Admins can approve anyway, so this eliminates the admission step.
    function createNewMember(address addr, string memory memberName) external {
        require(msg.sender == admin, "Only admin can create new members!");
        members[addr].name = memberName;
        members[addr].active = true;
        emit MemberCreation(addr, memberName);
    }

    // Apply to the group, pending approval / activation by the admin.
    function applyToGroup(string memory memberName) public {
        members[msg.sender].name = memberName;
        emit NewApplication(msg.sender, memberName);
    }

    // Allow a member which has previously applied to enter the group, by power of the admin.
    function admitToGroup(address addr) external {
        require(msg.sender == admin, "Only admin can admit new members!");
        members[addr].active = true;
        emit Admission(addr, members[addr].name);
    }

    // Admin-only: expels a member (identified by address) from the group, disallowing further contract interaction.
    function expelFromGroup(address addr) external {
        require(msg.sender == admin, "Only admin can expel existing members!");
        emit Expulsion(addr, members[addr].name);
        delete members[addr];
    }
    
    // Have the current admin assign a new admin to manage the contract.
    function assignNewAdmin(address addr) external {
        require(msg.sender == admin, "Only admin can assign a new admin!");
        admin = addr;
    }

    // PAYMENT FUNCTIONS-------------------------------------------------------------------------------------------------------------

    // Creates a payment obligation from a specified address (debtor) to the message sender over a specified amount.
    function createNewPaymentObligation(address debtor, uint amount) external {
        require(members[debtor].active && members[msg.sender].active, "Both debtor and creditor need to be active members!");
        require(msg.sender != debtor, "Cannot create a payment obligation to yourself!");
        members[debtor].owed[msg.sender] = amount;
        emit NewPaymentObligation(debtor, msg.sender, amount);
    }

    // Creditors can change existing payment obligations in case of error or other alternating circumstances.
    function updatePaymentObligation(address debtor, uint newAmount) external {
        require(members[debtor].active && members[msg.sender].active, "Both debtor and creditor (you) need to be active members!");
        require(members[debtor].owed[msg.sender] > 0, "Only existing obligations can be updated!");
        members[debtor].owed[msg.sender] = newAmount;
        emit UpdatedPaymentObligation(debtor, msg.sender, newAmount);
    }
    

    // 
    function fulfillPaymentObligation(address creditor) external {
        require(members[msg.sender].active && members[creditor].active, "Both debtor (you) and creditor need to be active members!");
        require(members[msg.sender].balance >= members[msg.sender].owed[creditor], "Not enough funds available to fulfill payment obligation!");
        require(members[msg.sender].owed[creditor] != 0, "You don't owe anything to the specified creditor!");
        emit FulfilledPaymentObligation(msg.sender, creditor, members[msg.sender].owed[creditor]);
        members[msg.sender].balance -= members[msg.sender].owed[creditor];
        members[creditor].balance += members[msg.sender].owed[creditor];
        members[msg.sender].owed[creditor] = 0;
    }

    // VIEWING FUNCTIONS-------------------------------------------------------------------------------------------------------------

    // View the name behind a member address.
    function whoIs(address addr) external view returns (string memory) {
        require(members[msg.sender].active, "You need to be an active member to look up other members!");
        return members[addr].name;
    }

    // Displays how much the sender owes to a specified address.
    function howMuchDoIOweTo(address creditor) external view returns (uint) {
        require(members[msg.sender].active && members[creditor].active, "Both debtor (you) and creditor need to be active members!");
        return members[msg.sender].owed[creditor];
    }
    
    // Shows the balance of the sender's account.
    function showBalance() external view returns (uint) {
        require(members[msg.sender].active, "You need to be an active member to view your balance!");
        return members[msg.sender].balance;
    }

    // BALANCE RELATED FUNCTIONS-----------------------------------------------------------------------------------------------------

    // Deposits ether into the sender's account.
    function deposit() external payable {
        require(members[msg.sender].active, "You need to be an active member to deposit!");
        members[msg.sender].balance += msg.value;
    }

    // Withdraws specified amount of ether from the sender's account. Subject to withdrawal fee (see above).
    function withdraw(uint amount) external {
        require(members[msg.sender].active, "You need to be an active member to withdraw!");
        require(members[msg.sender].balance >= amount - withdrawalFee, "Not enough funds to withdraw!");
        payable(msg.sender).transfer(amount - withdrawalFee);
        members[msg.sender].balance -= amount;
        withdrawalFeeBalance += withdrawalFee;
    }

    // Withdraws the remaining balance from the sender's account. Subject to withdrawal fee (see above).
    function withdrawAll() external {
        require(members[msg.sender].active, "You need to be an active  member to withdraw!");
        require(members[msg.sender].balance >= withdrawalFee, "Not enough funds to withdraw!");
        payable(msg.sender).transfer(members[msg.sender].balance - withdrawalFee);
        members[msg.sender].balance = 0;
        withdrawalFeeBalance += withdrawalFee;
    }
}