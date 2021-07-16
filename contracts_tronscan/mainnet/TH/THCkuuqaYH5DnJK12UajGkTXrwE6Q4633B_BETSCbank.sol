//SourceUnit: BETSCbank.sol

pragma solidity 0.5.14;

contract BETSCbank {
    using SafeMath for uint;
    
    /* VARIABLES */
    uint private constant token_id = 1003482;
    uint private constant minimum_deposit = 1000000000; // 1000 BETSC
    uint[5] private percentage_referrals = [400, 200, 100, 50, 10]; // 4% - 2% - 1% - 0.5% - 0.1%
    uint private constant base_percentage = 100; // 1%
    uint private constant max_hold_percentage = 300; // 3%
    uint private constant max_contract_percentage = 2000; // 20%
    uint private constant percentage_divider = 10000;
    uint private constant balance_percentaje_step = 25000000000; // 25,000 BETSC
    uint private constant time_step = 86400; // 1 days
    uint private constant release_time = 1608577200; // 2020/12/21 19:00 UTC
    
    uint public total_investors;
    uint public total_deposited;
    uint public total_withdrawn;
    uint public referral_rewards;
    
    /* DATA STRUCTURES */
    struct Deposit {
        uint32 date;
        uint48 amount;
        uint48 withdrawn;
    }
    struct Investor {
        address upline;
        uint24[5] referrals;
        uint32 checkpoint;
        uint48 referral_bonus;
        uint48 referral_bonus_withdrawn;
        Deposit[] deposit_list;
    }
    mapping(address => Investor) internal investors_list;
    
    /* EVENTS */
    event new_deposit(
        address indexed _address,
        uint amount
    );
    event referral_bonus(
        address indexed upline,
        address indexed referral,
        uint amount,
        uint indexed level
    );
    event withdrawn(
        address indexed investor,
        uint amount
    );
    
    /* PUBLIC FUNCTIONS */
    function invest(address referrer) public payable {
        require(block.timestamp >= release_time);
        require(msg.tokenid == token_id);
        
        uint msgValue = msg.tokenvalue;
        
        require(msgValue >= minimum_deposit);
        
        Investor storage investor = investors_list[msg.sender];
        if(investor.deposit_list.length == 0){
            if(investors_list[referrer].deposit_list.length > 0 && referrer != msg.sender) {
                investor.upline = referrer;
            }
            investor.checkpoint = uint32(block.timestamp);
            total_investors++;
        }
        
        if(investor.upline != address(0)) {
            address upline = investor.upline;
            for(uint i = 0; i < 5; i++) {
                if(upline != address(0)) {
                    uint amount = msgValue.mul(percentage_referrals[i]).div(percentage_divider);
                    investors_list[upline].referral_bonus = uint48(uint(investors_list[upline].referral_bonus).add(amount));
                    referral_rewards = referral_rewards.add(amount);
                    
                    emit referral_bonus(upline, msg.sender, amount, i);
                    if(investor.deposit_list.length == 0){
                        investors_list[upline].referrals[i]++;
                    }
            
                    upline = investors_list[upline].upline;
                } else break;
            }
        }
        
        investor.deposit_list.push(Deposit(uint32(block.timestamp), uint48(msgValue), 0));
        
        total_deposited = total_deposited.add(msgValue);
        emit new_deposit(msg.sender, msgValue);
    }
    
    function withdraw() public {
        require(getContractBalance() > 0, "The contract balance is 0");
        
        Investor storage investor = investors_list[msg.sender];

        uint userPercentRate = getUserPercentRate(msg.sender);
        uint totalAmount;
        uint dividends;
        for(uint i = 0; i < investor.deposit_list.length; i++) {
            if(investor.deposit_list[i].withdrawn < uint(investor.deposit_list[i].amount).div(4).mul(7)) {
                if(investor.deposit_list[i].date > investor.checkpoint) {
                    dividends = (uint(investor.deposit_list[i].amount).mul(userPercentRate).div(percentage_divider))
                        .mul(block.timestamp.sub(investor.deposit_list[i].date)).div(time_step);
                } else {
                    dividends = (uint(investor.deposit_list[i].amount).mul(userPercentRate).div(percentage_divider))
                        .mul(block.timestamp.sub(investor.checkpoint)).div(time_step);
                }

                if(uint(investor.deposit_list[i].withdrawn).add(dividends) > uint(investor.deposit_list[i].amount).div(4).mul(7)) {
                    dividends = (uint(investor.deposit_list[i].amount).div(4).mul(7)).sub(investor.deposit_list[i].withdrawn);
                }

                investor.deposit_list[i].withdrawn = uint48(uint(investor.deposit_list[i].withdrawn).add(dividends));
                totalAmount = totalAmount.add(dividends);
            }
        }
        
        uint referralBonus = investor.referral_bonus;

		if(referralBonus > 0) {
		    totalAmount = totalAmount.add(referralBonus);
		    referral_rewards = referral_rewards.add(referralBonus);
		    
			investor.referral_bonus_withdrawn = uint48(uint(investor.referral_bonus_withdrawn).add(referralBonus));
			investor.referral_bonus = 0;
		}

        require(totalAmount > 0, "User has no dividends");

        uint contractBalance = address(this).tokenBalance(token_id);
        if(contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        investor.checkpoint = uint32(block.timestamp);

        msg.sender.transferToken(totalAmount, token_id);

        total_withdrawn = total_withdrawn.add(totalAmount);
        emit withdrawn(msg.sender, totalAmount);
    }
	
	function getContractBalanceRate() internal view returns (uint) {
        uint contractBalance = address(this).tokenBalance(token_id);
        uint contractBalancePercent = base_percentage.add(contractBalance.div(balance_percentaje_step));

        if (contractBalancePercent < max_contract_percentage) {
            return contractBalancePercent;
        } else {
            return max_contract_percentage;
        }
    }
    
    function getUserPercentRate(address userAddress) public view returns (uint) {
        Investor storage investor = investors_list[userAddress];
        
        uint contractPercent = getContractBalanceRate();
        if (isActive(userAddress)) {
            uint timeMultiplier = ((block.timestamp.sub(investor.checkpoint)).div(7200));
            if (timeMultiplier > max_hold_percentage) {
                timeMultiplier = max_hold_percentage;
            }
            return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }
    
    function getContractBalance() public view returns (uint) {
        return address(this).tokenBalance(token_id);
    }
    
    function getUserBalance(address userAddress) public view returns (uint) {
        return userAddress.tokenBalance(token_id);
    }

    function getUserAvailable(address userAddress) public view returns (uint) {
        Investor storage investor = investors_list[userAddress];

        uint userPercentRate = getUserPercentRate(userAddress);

        uint totalAmount;
        uint dividends;
        for(uint i = 0; i < investor.deposit_list.length; i++) {
            if(investor.deposit_list[i].withdrawn < uint(investor.deposit_list[i].amount).div(4).mul(7)) {
                if(investor.deposit_list[i].date > investor.checkpoint) {
                    dividends = (uint(investor.deposit_list[i].amount).mul(userPercentRate).div(percentage_divider))
                        .mul(block.timestamp.sub(investor.deposit_list[i].date)).div(time_step);
                } else {
                    dividends = (uint(investor.deposit_list[i].amount).mul(userPercentRate).div(percentage_divider))
                        .mul(block.timestamp.sub(investor.checkpoint)).div(time_step);
                }

                if(uint(investor.deposit_list[i].withdrawn).add(dividends) > uint(investor.deposit_list[i].amount).div(4).mul(7)) {
                    dividends = (uint(investor.deposit_list[i].amount).div(4).mul(7)).sub(investor.deposit_list[i].withdrawn);
                }

                totalAmount = totalAmount.add(dividends);
            }
        }

        return totalAmount;
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return investors_list[userAddress].deposit_list.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint) {
        Investor storage investor = investors_list[userAddress];

        uint amount;
        for (uint i = 0; i < investor.deposit_list.length; i++) {
            amount = amount.add(investor.deposit_list[i].amount);
        }
        
        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
        Investor storage investor = investors_list[userAddress];
        
        uint amount;
        for (uint i = 0; i < investor.deposit_list.length; i++) {
            amount = amount.add(investor.deposit_list[i].withdrawn);
        }

        return amount;
    }

    function getUserDeposits(address userAddress, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory) {
        Investor storage investor = investors_list[userAddress];

        uint count = first.sub(last);
        if (count > investor.deposit_list.length) {
            count = investor.deposit_list.length;
        }

        uint[] memory amount = new uint[](count);
        uint[] memory withdrawn_ = new uint[](count);
        uint[] memory date = new uint[](count);

        uint index = 0;
        for (uint i = first; i > last; i--) {
            amount[index] = uint(investor.deposit_list[i-1].amount);
            withdrawn_[index] = uint(investor.deposit_list[i-1].withdrawn);
            date[index] = uint(investor.deposit_list[i-1].date);
            index++;
        }

        return (amount, withdrawn_, date);
    }

    function getSiteStats() public view returns (uint, uint, uint, uint, uint, uint) {
        return (total_deposited, total_investors, total_withdrawn, referral_rewards, address(this).tokenBalance(token_id), getContractBalanceRate());
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);
        uint userReferralsBonus = investors_list[userAddress].referral_bonus;

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn, userReferralsBonus);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint48, uint24[5] memory) {
        Investor storage investor = investors_list[userAddress];

        return (investor.upline, investor.referral_bonus_withdrawn, investor.referrals);
    }
    
    function isActive(address userAddress) public view returns (bool) {
        Investor storage investor = investors_list[userAddress];

        return (investor.deposit_list.length > 0) && investor.deposit_list[investor.deposit_list.length-1].withdrawn < uint(investor.deposit_list[investor.deposit_list.length-1].amount).mul(2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
}