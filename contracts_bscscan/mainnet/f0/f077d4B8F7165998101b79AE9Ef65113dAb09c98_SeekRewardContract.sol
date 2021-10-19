/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity 0.8.9;


// SPDX-License-Identifier:MIT



interface IBEP20 {
    
    function balanceOf(address account) external view returns (uint256);


    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


}



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
        priceFeed = AggregatorV3Interface(0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941);
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
	IBEP20 public token;
    address payable public owner1;
    address payable public owner2;
	uint256 constant public INVEST_MIN_AMOUNT = 50e18;
	uint256 constant public BASE_PERCENT = 10;
	uint256[] public REFERRAL_PERCENTS = [100, 50];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 [15] public REF=[6,6,6,6,6,6,6,6,6,6,8,8,8,8,8];
    bool public Distribution;
    uint256 public investLimitMax=100000e18;

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

	constructor(address payable _owner1,address payable _owner2,address _token)  {
	    owner1=_owner1;
	    owner2=_owner2;
	    token=IBEP20(_token);
	}
	
	
	function getUsdt(uint256 _value)view public returns(uint256){
     return(uint256(getLatestPrice()).mul(_value)).div(1e18);   
    }
    
    function getbnb(uint256 _value)view public returns(uint256){
        return(_value.mul(1e18).div(uint256(getLatestPrice())));
    }

	function _deposit(address referrer) public payable {
		require(msg.value >= getUsdt(INVEST_MIN_AMOUNT),"under limit");
		require(msg.value<=getUsdt(investLimitMax),"upper limit");
		User storage user = users[msg.sender];

		if (user.upline == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.upline = referrer;

		}
		else if(referrer != msg.sender){
		    user.upline=owner1;

		}
		
	users[user.upline].referrals=users[user.upline].referrals.add(1);

		if (user.upline != address(0)) {

			address payable upline = payable(user.upline);
			for (uint256 i = 0; i < 2; i++) {
			    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				if (upline != address(0)&& isActive(upline)) {
				    if(upline==owner1||upline==owner2){
				        upline.transfer(amount);
				        emit RefBonus(upline, msg.sender, i, amount);
				    }
				    else{
					users[upline].bonus = users[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
				    }
				
				    
				} 
				else{
					owner1.transfer(amount.div(2));
					owner2.transfer(amount.div(2));
					emit RefBonus(owner1, msg.sender, i, amount);
				} 
				
				upline = payable(users[upline].upline);
			}

		}

		if (user.deposits.length == 0) {
			totalUsers = totalUsers.add(1);

			emit Newbie(msg.sender);
		}
    	user.checkpoint=block.timestamp;
		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		if(Distribution){
		token.transferFrom(owner1,msg.sender,getbnb(msg.value).mul(100));
		}
		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {
		User storage user = users[msg.sender];

        address payable  userAddress=   payable(msg.sender);
		uint256 totalAmount;
		uint256 dividends;
		uint256 _bonues=getBonuses(userAddress);
		uint256 flag=_bonues.add(user.remaining);
        uint256 flag2;
         user.remaining=0;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(210)).div(100)) {

				if (block.timestamp > user.deposits[i].start) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} 
				
						user.deposits[i].start = block.timestamp;
					
				if(flag>0){

				    if (user.deposits[i].withdrawn.add(dividends).add(flag) < (user.deposits[i].amount.mul(210)).div(100)){
				
				dividends=dividends.add(flag);
				flag=0;
				}
				else if(!(user.deposits[i].withdrawn.add(dividends) > (user.deposits[i].amount.mul(210)).div(100))){
				    
				     flag2=((user.deposits[i].amount.mul(210)).div(100)).sub(user.deposits[i].withdrawn.add(dividends));
				     
				   flag=flag.sub(flag2);
				   
				

                    dividends=dividends.add(flag2);
				}
				
				               
				
				}
				if (user.deposits[i].withdrawn.add(dividends) > (user.deposits[i].amount.mul(210)).div(100)) {
					dividends = ((user.deposits[i].amount.mul(210)).div(100)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

			user.bonus = 0;
			user.matchBonus=0;
			user.remaining= flag;
	
		
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
        
       user.checkpoint=block.timestamp;
       
      _matchBonus(userAddress,totalAmount.mul(6).div(100));
       
       owner1.transfer(totalAmount.mul(2).div(100));
       
       owner2.transfer(totalAmount.mul(2).div(100));
       
		userAddress.transfer(totalAmount.mul(90).div(100));

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
        for (uint i = 0; i < 15; i++) { // For matching bonus
        
        
        uint256 amount=_amount.mul(REF[i]).div(100);   
        
            // if (up == address(0)) {
            //  users[owner1].matchBonus=users[owner1].matchBonus.add(amount);   
            // }
            
            
            if (users[up].referrals >= i+1&& isActive(up)) {
                
                    users[up].matchBonus = users[up].matchBonus.add(amount);
                    
                }
                    
            
                else if (i>=11) {
                    if(users[up].referrals >= 10 && isActive(up)){
                        
                    users[up].matchBonus = users[up].matchBonus.add(amount);
                    
                    }

                }
                else{
                        owner1.transfer(amount.div(2));
                        owner2.transfer(amount.div(2));
                    }
                
                    
                up = users[up].upline;
            
            
        }
            
        }
    


	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}


	function payoutOf(address userAddress) public view returns (uint256,uint256 ) {
		User storage user = users[userAddress];
		uint256 totalAmount;
		uint256 dividends;
		uint256 _remaining;
		uint256 _bonues=getBonuses(userAddress);
		uint256 flag=_bonues.add(user.remaining);

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(210)).div(100)) {

				if (block.timestamp > user.deposits[i].start) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} 
					
				if(flag>0){
				    
				    if (user.deposits[i].withdrawn.add(dividends).add(flag) < (user.deposits[i].amount.mul(210)).div(100)){
				
				dividends=dividends.add(flag);
				
				_remaining=flag;
				
				flag=0;
				}
				else if(!(user.deposits[i].withdrawn.add(dividends) > (user.deposits[i].amount.mul(210)).div(100))){
				    
				    uint256 flag2=((user.deposits[i].amount.mul(210)).div(100)).sub(user.deposits[i].withdrawn.add(dividends));
				    
                      flag=(flag).sub(flag2);
                      
				
                    dividends=dividends.add(flag2);
                    _remaining=flag2;
				}
				
				}

				if (user.deposits[i].withdrawn.add(dividends) > (user.deposits[i].amount.mul(210)).div(100)) {
				    

					dividends = ((user.deposits[i].amount.mul(210)).div(100)).sub(user.deposits[i].withdrawn);
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
			if (user.deposits[user.deposits.length-1].withdrawn < (user.deposits[user.deposits.length-1].amount.mul(210)).div(100)) {
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
	
	function changeOwner1(address payable Addr)public returns(bool){
	    require(msg.sender==owner1," you are not owner1");
	    owner1=Addr;
	    return true;
	}
	
		function changeOwner2(address payable Addr)public returns(bool){
	    require(msg.sender==owner2," you are not owner1");
	    owner2=Addr;
	    return true;
	}
	
	function changeDistribution(bool value)public returns(bool){
	    require(msg.sender==owner1," you are not owner1");
	    Distribution=value;
	    return true;
	}
	
	function changeInvestLimitMax(uint256 value)public returns(bool){
	    require(msg.sender==owner1," you are not owner1");
	    investLimitMax=value;
	    return true;
	}
	

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			amount = amount.add(user.deposits[i].amount);
		    
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
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