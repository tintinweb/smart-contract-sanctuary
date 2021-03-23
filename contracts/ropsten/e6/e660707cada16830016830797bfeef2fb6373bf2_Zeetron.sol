/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity ^0.5.14;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Zeetron {
    using SafeMath for uint256;

    struct Deposit {
        uint256 id;
        uint256 amount;
        uint256 referralBonus;
        address preReferrer;
        uint256 preRefId;
        address referral;
        uint256 refId;
        uint256 count;
        uint256 cycle;
	    bool closed;
    }

    struct User {
        uint256 totalBonus;
        uint256 withdrawAmount;
        uint256 totalInvestment;
        Deposit[] deposits;

    }
    
    mapping (address => User) private users;
    address private previousReferrer;
    uint256 private previousReferrerId;
    address payable public owner;
    
    uint256 public lastUserId = 0;

    constructor() public payable {
        owner = msg.sender;
        User storage user = users[msg.sender];
        user.deposits.push(Deposit({
            id: 0,
            amount: 0,
            referralBonus: 0,
            preReferrer: address(0),
            preRefId: 0,
            referral: address(0),
            refId: 0,
            count: 0,
            cycle: 0,
            closed: false
        }));
        previousReferrer = owner;
        previousReferrerId = 0;
        users[msg.sender].totalBonus = 0;
    }
    
    function deposit (address referrer, uint256 id) public payable {
        require(msg.value == 0.0001 ether, "Investment cost is 1000 trx");
        lastUserId++;
        User storage user = users[msg.sender];
        user.deposits.push(Deposit({
            id: lastUserId,
            amount: msg.value, 
            referralBonus: 0,
            preReferrer: previousReferrer,
            preRefId: previousReferrerId,
            referral: referrer,
            refId: id,
            count: 0,
            cycle: 0,
            closed: false
        }));
        user.totalInvestment += msg.value;
        if(referrer != owner && referrer != address(0)) {
            users[referrer].deposits[id].referralBonus = users[referrer].deposits[id].referralBonus.add(msg.value.mul(20).div(100));
            users[referrer].totalBonus = users[referrer].totalBonus.add(msg.value.mul(20).div(100));
        }
        payForReferrer(previousReferrer,msg.value,previousReferrerId);
        previousReferrer = msg.sender;
        previousReferrerId = users[msg.sender].deposits.length-1;
    }

    function payForReferrer(address referral, uint256 amount, uint256 depositId) private {
        for(uint i = 0;i < lastUserId;i++) {
            if(!users[referral].deposits[depositId].closed && referral != owner){
                if(users[referral].deposits[depositId].count < 4) {
                    users[referral].deposits[depositId].count = users[referral].deposits[depositId].count+1;
                } 
                else {
                    users[referral].deposits[depositId].count = 1;                    
                    users[referral].totalBonus = users[referral].totalBonus.add(amount.mul(50).div(100));
                    users[referral].deposits[depositId].referralBonus = users[referral].deposits[depositId].referralBonus.add(amount.mul(50).div(100));
                    users[referral].deposits[depositId].cycle += 1;
                    if(users[referral].deposits[depositId].referral != owner && users[referral].deposits[depositId].referral != address(0)) {
                        address refer = users[referral].deposits[depositId].referral;
                        users[refer].deposits[depositId].referralBonus = users[refer].deposits[depositId].referralBonus.add(amount.mul(125).div(1000));
                        users[refer].totalBonus = users[refer].totalBonus.add(amount.mul(125).div(1000));
                    }
                    if(users[referral].deposits[depositId].cycle == 4 ) {
                        users[referral].deposits[depositId].closed = true;
                        users[referral].deposits[depositId].count = 0;
                    }
                } 
            }
            address temp = referral;
            referral = users[referral].deposits[depositId].preReferrer;
            depositId = users[temp].deposits[depositId].preRefId;
        }
    }
    
    function sendToOwner(uint256 amount) public payable returns (uint256) {
        require(msg.sender == owner,"access denied its only for owner");
        msg.sender.transfer(amount);
    }

    function getBalance () public view returns (uint256) {
        return address(this).balance;
    }

    function payout(address payable recipient,uint256 amount) public payable returns(bool) {
        require(users[recipient].totalBonus >= amount,"insufficient amount");
        owner.transfer(amount.mul(5).div(100));
        recipient.transfer(amount.sub(amount.mul(5).div(100)));
        users[recipient].totalBonus = users[recipient].totalBonus.sub(amount);
        users[recipient].withdrawAmount = users[recipient].withdrawAmount.add(amount);
    }
    
    function userDetails() public view returns(uint256, uint256, uint256) {
        User storage user = users[msg.sender];
        return (user.totalBonus, user.withdrawAmount, user.totalInvestment );
    } 
    
    function depositAtIndex(uint index) public view returns (uint256, uint256, uint256, address, uint256, address, uint256, uint256, uint256, bool) {
         User storage user = users[msg.sender];
         require(index < user.deposits.length, "Deposit Not Available");
         Deposit storage dep = user.deposits[index];
         return (dep.id, dep.amount, dep.referralBonus, dep.preReferrer, dep.preRefId, dep.referral, dep.refId, dep.count, dep.cycle, dep.closed);
    }  
}