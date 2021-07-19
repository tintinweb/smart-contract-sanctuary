//SourceUnit: accubits.sol

pragma solidity ^0.6.0;

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Accubits {
    using SafeMath for uint256;

    struct Deposit {
        uint256 amount;
        uint256 withdrawAmount;
	    uint256 referralBonus;
        uint256 time;
	    uint256 referralDepositId;
	    address referral;
	    bool active;
        bool closed;
        mapping(uint8 => uint256) referrals_per_level;
    }

    struct User {
        uint256 dividends;
        bool paid;
        uint256 lastPayout;
        uint256 totalInvested;
        uint256 totalWithdrawn;
        Deposit[] deposits;
    }

    uint256 private userClient;
    uint256 private totalDeposits;
    mapping (address => User) private users;
    uint[] public referralBonuses;
    address payable public owner;

    event LogDeposit(address indexed accountAddress, uint256 amount);
    event LogPayoutDividends(address indexed accountAddress, uint256 amount);
    event LogPayoutPayoutReferralBonus(address indexed accountAddress, uint256 amount);

    constructor() public payable {
        owner = msg.sender;
        userClient = 0;
        totalDeposits = 0;
    	referralBonuses.push(10);
    	referralBonuses.push(4);
    	referralBonuses.push(3);
    	referralBonuses.push(2);
    	referralBonuses.push(1);
    	User storage user = users[msg.sender];
        user.deposits.push(Deposit({
            amount: 0,
            withdrawAmount: 0,
            referralBonus: 0,
            time: uint256(block.timestamp),
            referralDepositId: 0,
            referral: address(0),
            active: true,
            closed: false
        }));
    }

    function deposit(address _referral, uint256 _depositId) public payable returns (bool) {
	    require(msg.value >= 500 trx, "500 TRX Minimum Deposit");
        User storage user = users[msg.sender];
        require(!users[_referral].deposits[_depositId].closed, "Deposit closed");
        require(users[_referral].deposits[_depositId].active, "Deposit is not active");
        user.deposits.push(Deposit({
            amount: msg.value,
            withdrawAmount: 0,
            referralBonus: 0,
            time: uint256(block.timestamp),
            referralDepositId: _depositId,
	        referral: _referral,
	        active: true,
            closed: false
        }));
        user.totalInvested += msg.value;
        user.paid = true;
        totalDeposits += msg.value;
	    payForReferrer(_referral, msg.value, _depositId);
        owner.transfer(msg.value);
        emit LogDeposit(msg.sender, msg.value);
        return true;
    }

    function payForReferrer(address referrer, uint256 depositAmt, uint depositId) private {
        for(uint8 i = 0; i < referralBonuses.length; i++) {
           uint256 referralBonus = depositAmt.mul(referralBonuses[i]).div(100);
           if(referrer == owner){
                users[referrer].deposits[0].referralBonus = users[referrer].deposits[0].referralBonus.add(referralBonus);
		        users[referrer].deposits[0].referrals_per_level[i+1]++;
                break;
           }
	       users[referrer].deposits[depositId].referrals_per_level[i+1]++;
           uint256 dividends = calculateDividends(users[referrer].deposits[depositId].amount, users[referrer].deposits[depositId].time, users[referrer].lastPayout);
           if((referralBonus + dividends) > users[referrer].deposits[depositId].amount.mul(2)) {
                users[referrer].deposits[depositId].closed = true;
           } else {
                users[referrer].deposits[depositId].referralBonus = users[referrer].deposits[depositId].referralBonus.add(referralBonus);
           }
           uint tempDepositId = depositId;
           depositId = users[referrer].deposits[depositId].referralDepositId;
	       referrer = users[referrer].deposits[tempDepositId].referral;
           
	    }
    }

    function depositAmount() public view returns (uint256) {
      address addr = msg.sender;
      Deposit[] storage deposits = users[addr].deposits;
      uint256 balance;
      for(uint8 i = 0; i < deposits.length; i++) {
            if(deposits[i].active) {
                balance += deposits[i].amount;
            }
      }
      return balance;
    }

    function calculateDividends(uint256 amount, uint256 depositTime, uint256 lastPayout) internal view returns (uint256) {
       uint256 dividends;
       uint256 end = depositTime + 17280000;
       uint256 from = lastPayout > depositTime ? lastPayout : depositTime;
       uint256 to = uint256(block.timestamp) > end ? end : uint256(block.timestamp);
       uint256 noOfSec = to.sub(from);
       dividends = amount.mul(37).mul(noOfSec).div(1000);
       return dividends.div(86400);
    }

    function getDividends() public view returns (uint256) {
        address payable addr = msg.sender;
        User storage user = users[addr];
        uint256 dividends;
        Deposit[] storage deposits = user.deposits;
        for(uint8 i = 0; i < deposits.length; i++) {
            if(deposits[i].active){
                if(deposits[i].closed) {
                    dividends = dividends.add(deposits[i].amount * 2);
                } else {
                    uint256 referralBonus = deposits[i].referralBonus;
                    uint256 tempDividends = calculateDividends(deposits[i].amount, deposits[i].time, user.lastPayout);
                    if((referralBonus + tempDividends) > deposits[i].amount.mul(2)) {
                        dividends = (addr != owner) ? dividends.add(deposits[i].amount * 2) : referralBonus;
                    } else {
                        dividends = referralBonus + tempDividends;
                    }
                }
            }
        }
        return dividends;
    }

    function setPayoutDividends() public returns (uint256) {
        address payable addr = msg.sender;
        User storage user = users[addr];
        require(user.paid == true, "Last payment pending. Owner has to send token to client.");
        uint256 dividends;
        Deposit[] storage deposits = user.deposits;
        for(uint8 i = 0; i < deposits.length; i++) {
            uint256 iDividends;
            if(deposits[i].active){
                if(deposits[i].closed) {
                    iDividends = deposits[i].amount * 2;
                } else {
                    uint256 referralBonus = deposits[i].referralBonus;
                    uint256 tempDividends = calculateDividends(deposits[i].amount, deposits[i].time, user.lastPayout);
                    if((referralBonus + tempDividends) > deposits[i].amount.mul(2)) {
                        iDividends = deposits[i].amount * 2;
                        deposits[i].closed = true;
                        deposits[i].active = false;
                    } else {
                        iDividends = referralBonus + tempDividends;
                        deposits[i].referralBonus = 0;
                    }
                }
                deposits[i].withdrawAmount = iDividends;
            }
            dividends = dividends.add(iDividends);
        }
        user.lastPayout = uint256(block.timestamp);
        user.dividends = dividends;
        user.paid = false;
        user.totalWithdrawn = user.totalWithdrawn.add(dividends);
        return dividends;
    }

    function PayoutDividends(address payable recipient) public payable returns (bool) {
        User storage user = users[recipient];
        if(!user.paid) {
            recipient.transfer(user.dividends);
            user.paid = true;
            user.dividends = 0;
        }
        return true;
    }
    
    function userDetails() public view returns(uint256, bool, uint256, uint256, uint256, uint) {
        User storage user = users[msg.sender];
	    return (user.dividends, user.paid, user.lastPayout, user.totalInvested, user.totalWithdrawn, user.deposits.length);
    }

     function depositAtIndex(uint index) public view returns (uint256, uint256, uint256, uint256, uint256, address, bool, bool) {
         User storage user = users[msg.sender];
         require(index < user.deposits.length, "Deposit Not Available");
         Deposit storage dep = user.deposits[index];
         return (dep.amount, dep.withdrawAmount, dep.referralBonus, dep.time, dep.referralDepositId, dep.referral, dep.active, dep.closed);
     }

    function getActiveDepositIndexes(address addr) public view returns(int[] memory) {
        User storage user = users[addr];
        Deposit[] storage deposits = user.deposits;
        int[] memory indices = new int[](deposits.length);
        uint8 k;
        for(uint i = 0; i < deposits.length; i++) {
            if(deposits[i].active && !deposits[i].closed){
                indices[k] = int(i); 
            } else {
                indices[k] = -1;
            }
            k++;
        }
        return indices;
    }
}