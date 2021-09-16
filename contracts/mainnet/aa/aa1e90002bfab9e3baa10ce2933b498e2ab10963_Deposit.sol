/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Deposit {

    uint256 private constant ONE_DAY_SEC = 1 days;
    uint256 private constant ALL_PERCENT = 100;
    uint256 private constant ONE_DAY_PERCENT = 2;
    uint256 private constant REFERER_PERCENT = 20;
    uint256 private constant PAYMENT_FOR_WITHDRAW = 0.001 ether;

    struct Payment {
        uint256 value;
        uint256 timestamp;
    }

    struct Member {
        Payment payments;
        address referer;
        uint256 withdrawn;
        uint256 deposit;
        bool active;
    }

    mapping(address => Member) private members;
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MemberWithdrawn(address indexed member, uint256 amount);
    event OwnerWithdrawn(address indexed owner, uint256 amount);
    event MemberDeposit(address indexed member, uint256 amount, bytes data);
    event SendToReferer(address indexed member, uint256 amount);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier isNotMember() {
        require(!members[msg.sender].active, 'You have already made a deposit');
        _;
    }

    modifier isMember() {
        require(members[msg.sender].active, 'You have not made a deposit yet');
        _;
    }

    receive() external payable {
        if (msg.value == PAYMENT_FOR_WITHDRAW) {
            makeWithdraw();
        } else {
            makeDeposit();
        }
    }

    fallback() external payable {
        if (msg.value != PAYMENT_FOR_WITHDRAW) {
            makeDeposit();
        }
    }

    function makeDeposit() private isNotMember {
        if (msg.data.length == 20) {
            address referer = bytesToAddress(bytes(msg.data));
            checkReferer(referer);
        }
        deposit(msg.sender, msg.value);
    }

    function makeWithdraw() private isMember {
        Member storage memberSender = members[msg.sender];
        uint256 reward = calcReward(msg.sender);
        uint256 amount = reward - memberSender.withdrawn;
        if (amount > 0) {
            memberSender.withdrawn += amount;
            emit MemberWithdrawn(msg.sender, amount);
            payable(msg.sender).transfer(amount);
        }
    }

    function checkReferer(address referer) private {
        if (members[referer].active) {
            Member storage memberSender = members[msg.sender];
            memberSender.referer = referer;
            uint256 amount = msg.value * REFERER_PERCENT / ALL_PERCENT;
            fixActiveStatus(msg.sender);
            payable(referer).transfer(amount);
            emit SendToReferer(referer, amount);
        }
    }

    function calcReward(address user) private view returns(uint256 _reward) {
        uint256 endDate = block.timestamp;
        uint256 diff = (endDate - members[user].payments.timestamp) / ONE_DAY_SEC;
        _reward = (members[user].payments.value * ONE_DAY_PERCENT / ALL_PERCENT) * diff;
    }

    function deposit(address sender, uint256 value) private {
        fixActiveStatus(sender);
        Member storage member = members[sender];
        member.deposit += value;
        member.payments = Payment(value, block.timestamp);
        emit MemberDeposit(sender, value, msg.data);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    function fixActiveStatus(address user) private {
        Member storage memberUser = members[user];
        if (!memberUser.active) {
            memberUser.active = true;
        }
    }


    function getMemberMainParams(address user) external view returns(
        address _referer, uint256 _withdrawn, uint256 _deposit, bool _active)
    {
        _referer = members[user].referer;
        _withdrawn = members[user].withdrawn;
        _deposit = members[user].deposit;
        _active = members[user].active;
    }

    function getMemberPayments(address user) external view returns(
        uint256 _amount, uint256 _timestamp)
    {
        if (members[user].active) {
            _amount = members[user].payments.value;
            _timestamp = members[user].payments.timestamp;
        }
    }

    function changeOwner(address newOwner) external isOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;
    }

    function withdraw(uint256 amount) external isOwner {
        require(address(this).balance >= amount, "Not enough funds");
        emit OwnerWithdrawn(owner, amount);

        payable(owner).transfer(amount);
    }

    function getBalance() external view returns(uint256)  {
        return address(this).balance;
    }
}