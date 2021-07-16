//SourceUnit: LotteryEffect.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;
import "./SafeMath.sol";
contract LotteryEffect{
    using SafeMath for uint256;
    uint256 constant public PRICE_TICKET = 5 trx;
    address payable public  owner;
    bool public isPaused;
    uint256 private idTicket;
    uint256[] public ticketsSoldCurrently;
    uint256[] public ticketsSold;
    string message;
    
    uint256 public totalRewardPaid;
    
    struct Winers {
        address player;
        uint256 ticket;
        uint256 date;
        uint256 amount;
    }
    
    struct TicketSold{
        address payable player;
        uint256 date;
    }
    
    mapping(uint256=>TicketSold) public tickets;
    
    Winers[] public winers;
    uint256[] public latestWinners;
    address payable public lastwinner;
    
    event BuyTicket(address _player, uint256 _ticket);
    event SelectWinner(address _wine);
    event Winner(address _wine,uint256 _ticket, uint256 _date, uint256 _amount);
    
    
    modifier onlyOwner{
        require(msg.sender==owner,"only owner");
        _;
    }
    modifier playIsPaused{
        require(!isPaused, "play is paused");
        _;
    }
    
    constructor(string memory _msg) public {
        isPaused = false;
        owner=msg.sender;
        idTicket=1;
        message=_msg;
    }
    function getPriceTicket() external pure returns(uint256){
        return PRICE_TICKET;
    }
    
    function buyTicketToAddress(address payable _address) external payable playIsPaused returns(uint256){            
        require(msg.value == PRICE_TICKET,message);
        return ticketHandler(_address);
    }
    
    function buyMultiTicketToAddress(address payable _address,uint256 numberOfTickets) external payable playIsPaused returns(uint256){            
        uint256 check = msg.value.div(numberOfTickets);
        require(check == PRICE_TICKET,message);
        for(uint256 i = 0; i < numberOfTickets;i++ ){
            ticketHandler(_address);
            }
    }
    function buyTicket() public payable playIsPaused returns(uint256){            
        require(msg.value == PRICE_TICKET,message);
        return ticketHandler(msg.sender);
    }
    
    function buyMultiTicket(uint256 numberOfTickets) public payable playIsPaused{            
        uint256 check = msg.value.div(numberOfTickets);
        require(check == PRICE_TICKET, message);
        for(uint256 i = 0; i < numberOfTickets;i++ ){
            ticketHandler(msg.sender);
            }
    }
    
    function selectWinner(uint256 randomSeed) public payable onlyOwner returns(uint256){
        uint256 _amount=getJackpot();
        require(_amount !=0,"empty Jackpot");
        isPaused =true;
        uint256 ramdom = uint256(keccak256(abi.encodePacked(now,randomSeed,msg.sender))) % ticketsSoldCurrently.length;
        uint256 ticketWiner =ticketsSoldCurrently[ramdom];
        address payable _winer =tickets[ticketWiner].player;
        totalRewardPaid=totalRewardPaid.add(_amount.mul(2));
        _winer.transfer(_amount);
        owner.transfer(address(this).balance);
        winers.push(Winers(_winer,ticketWiner,now,_amount));
        lastwinner=_winer;
        latestWinners.push(ticketWiner);
        delete ticketsSoldCurrently;
        emit Winner(_winer,ticketWiner,now,_amount);
        isPaused =false;
        return ticketWiner;
    }
    
    
    function ticketHandler(address payable  _address) internal playIsPaused returns(uint256) {
        ticketsSoldCurrently.push(idTicket);
        ticketsSold.push(idTicket);
        tickets[idTicket]=TicketSold(_address,block.timestamp);
        emit BuyTicket(_address,idTicket);
        uint256 _ticketSold=idTicket;
        idTicket++;
        return _ticketSold;
    }
    
    function getJackpot() public view returns(uint256){
        return (address(this).balance).div(2);
    } 
    function getJackpotRate() public view returns(uint256){
        return (address(this).balance).div(2).div(1e6);
    } 
    
    function getTicketsSold() public view returns(uint256[] memory){
        return ticketsSold;
    }
    function getLastTicketsSold() public view returns(uint256){
        return ticketsSoldCurrently.length;
    } 
    
    function getTicketsSoldCurrently() public view returns(uint256[] memory){
        return ticketsSoldCurrently;
    }
    function getLatestWinners() public view returns(uint256[] memory){
        return latestWinners;
    }
    
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: TronEffect.sol

// SPDX-License-Identifier: MIT
/*

'########:'########:::'#######::'##::: ##::::'########:'########:'########:'########::'######::'########:
... ##..:: ##.... ##:'##.... ##: ###:: ##:::: ##.....:: ##.....:: ##.....:: ##.....::'##... ##:... ##..::
::: ##:::: ##:::: ##: ##:::: ##: ####: ##:::: ##::::::: ##::::::: ##::::::: ##::::::: ##:::..::::: ##::::
::: ##:::: ########:: ##:::: ##: ## ## ##:::: ######::: ######::: ######::: ######::: ##:::::::::: ##::::
::: ##:::: ##.. ##::: ##:::: ##: ##. ####:::: ##...:::: ##...:::: ##...:::: ##...:::: ##:::::::::: ##::::
::: ##:::: ##::. ##:: ##:::: ##: ##:. ###:::: ##::::::: ##::::::: ##::::::: ##::::::: ##::: ##:::: ##::::
::: ##:::: ##:::. ##:. #######:: ##::. ##:::: ########: ##::::::: ##::::::: ########:. ######::::: ##::::
:::..:::::..:::::..:::.......:::..::::..:::::........::..::::::::..::::::::........:::......::::::..:::::


Tron Effect - Smart Contract Verified in TRONSCAN✅

Collective Financing - decentralized global ecosystem

📈Dividends in real time

👥9% Total referral commission. In 3 Levels.
2% Invitation bonus (one-time payment).
4% Direct referral bonus (payment for each investment).
2% 1st Level referral bonus (payment for each investment, unlocked with
a minimum of 10 direct referrals).
1% second-level referral bonus (payment for each investment, unlocked
with a minimum of 50 1st level referrals).

🎁Daily event - Lottery
Try your luck by purchasing a ticket or acquiring an Investment Plan, you could be the winner of 50% of the lottery jackpot.

🐳Daily event - Whales
Get 10% of your investment in bonuses for being "The Whale of The Day"

=============================
🔸Minimum deposit per registration: 100 TRX
🔸Minimum deposit in investment plans: 300 TRX
🔸Minimum Withdrawal: 10 TRX
▫️Transaction Fee 1 ~ 5 TRX

Telegram groups 🗣
@TronEffect <- Main Channel
@TronEffectEs <- Spanish Channel
@TronEffectGLOBAL <- English Channel

. Telegram channel
https://t.me/troneffect

. Telegram groups

a. English - Global
https://t.me/TronEffectGLOBAL
b. Spanish
https://t.me/TronEffectEs

. Terms and Conditions

a. Disclaimer, the corporate team in charge of the development of
Tron Effect is foreign to the operation and longevity of the Smart Contract, since
the moment it enters the Tron blockchain it becomes an autonomous and decentralized system that only fulfills the functions for which it was created. Nonetheless, this system is made so that you can get great profitability of your capital and much more bonuses, but its fullfilment and results depend on the participation of
each member of the community.


b. Tron Effect is a decentralized crowdfunding system, each
user is an important part for the decision making process and influences
directly on the lifespan of the project, we suggest you not to be short-term minded in order to
maintain the health of Tron Effect.

c. Any investment made in Tron Effect generates an investment plan and does not
have any type of refund or withdrawal of capital except for the payment of
dividends.

d. Any bonuses received within the system (referrals, lottery or whales)
will be reflected within the platform, but will only be accrued to the user when they request
request a withdrawal.

What is Tron Effect?

Tron Effect is an Smart Contract that works within the Tron blockchain, it was created under 
crowdfunding in a decentralized ecosystem where decisions are made by each and every one of 
the members within this Smart Contract, the system is autonomous and only fulfills the
functions for which it was created, excluding any type of biased decision that may affect its operation.


Investment plans

1. Diamond plan

Dividends in real time
Generate 3.5% daily ROI, Maximum 216%
Payments for 65 days
Minimum Investment 300 TRX
System deductions 5%

2. Ruby Plan

Dividends in real time
Generate 4% daily ROI, Maximum 152%
Payments for 40 days
Minimum investment 300 TRX
System deductions 5%

3. Emerald Plan

Dividends in real time
General 4.5% daily on your investment, Maximum 121%
Payments for 30 days
Minimum Investment 300 TRX
System deductions 10%


By investing in any of our plans you agree to the terms and conditions of Tron Effect and
You must have between 1 ~ 5 TRX for the transaction fees. Each operation (investment or withdrawal) 
within Tron Effect will award you a gift ticket to the daily event.


Events

Tron Effect has two daily events:

Lottery: Buy as many tickets as you want to participate in this event where you could be the
winner of 50% of the available Jackpot, each operation (investment or withdrawal) within Tron Effect
gives you a gift ticket. Tickets Cost 5 TRX per unit.

Whales: Invest big and become "The Whale of The Day" you will get an additional bonus of
10% ROI and it will be reflected directly in your user panel within Tron Effect.

7 Ways to Generate Income with Tron Effect

1. Get a bonus of 2% of your investment for every guest who signs up for Tron Effect with your
referral link.

2. Generate income in real time with our 3 investment plans (Diamond,
Ruby and emerald)

3. Get a 4% bonus on each investment made by your referrals

4. Get a 2% bonus on each investment made by your
1st level referrals. Unlocked by having 10 direct referrals.

5. Get a 1% bonus on each investment made by your 2nd level referrals. Unlocked by having 50 first level referrals.

6. You can be the winner of 50% of the lottery Jackpot by participating in our
daily event, you can buy as many tickets as you want in order to increase your winning chance.

7. Get a 10% bonus ROI for being "the whale of the day"

*/

pragma solidity ^0.5.8;
import "./LotteryEffect.sol";

contract TronEffect{
    using SafeMath for uint256;    
    LotteryEffect lottery;

    uint256 constant public INVEST_MIN_AMOUNT = 300 trx;
    uint256 constant public REGISTER_FEE = 10 trx;	
	uint256 constant public DIRECT_LEVEL= 0;
	uint256 constant public FIRST_LEVEL= 1;
	uint256 constant public SECOND_LEVEL= 2;    
    uint256 constant public WHALES_REWARD= 100;
    uint256 constant public INVITED_REWARD= 20;
    uint256 constant public SUPPORT_FEE = 30;
	uint256 constant public DEVELOPMENT_FEE = 30;
	uint256 constant public MARKETING_FEE = 40;
	uint256 constant public PROJECT_FEE = 10;
	uint256 constant public PERCENTS_DIVIDER = 1000.0;
	uint256 constant public CONTRACT_BALANCE_STEP = 1 trx;
    uint256 constant public TIME_STEP = 1 days;
    uint256 constant public TIME_PLAN_DIAMOND = 65 days;
    uint256 constant public TIME_PLAN_RUBY =  40 days;
    uint256 constant public TIME_PLAN_EMERALD =  30 days;
    uint256 constant public DAILY_PERCENTAGE_PLAN_DIAMOND = 35;
    uint256 constant public DAILY_PERCENTAGE_PLAN_RUBY = 40;
    uint256 constant public DAILY_PERCENTAGE_PLAN_EMERALD = 45;
    uint256 constant public REINVESTMENT_PERCENTAGE = 950;
    uint256 constant public FIRST_LEVEL_REFERREALS_UNLOCK =10;
    uint256 constant public SECOND_LEVEL_REFERREALS_UNLOCK = 50;
    uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;    
    uint256 public lastUserId = 1;
    uint256[] public REFERRAL_PERCENTS = [40, 20, 10];
    address payable public developmentAddress;    
	address payable public projectAddress;    
    enum planInvest {Diamond, Ruby, Emerald }   

    struct Deposit {
        planInvest planType;
		uint256 amount;
		uint256 initAmount;
		uint256 withdrawn;
		uint256 checkPoint;
		uint256 start;
        bool paid;
	}

	struct Referrer{
	    address referrer;
		mapping(address=>address) directReferrels;
		mapping(address=>address) firstLevelReferrals;
        mapping(address=>address) secondLevelReferrals;
        address[] directReferrerList;
		address[] firstLevelReferralsList;
        address[] secondLevelReferralsList;
        bool isActiveFirstLevel;
        bool isActivesecondLevel;
	}

    struct User {
        address userAddress;		        
        uint256 id;        
		uint256 timeRegister;		
		uint256  bonusUniqueForReferrel;
		uint256  bonus;
        Deposit[] deposits;
        Referrer referrer;
	}
	struct Whale{
	    address user;
	    uint256 amount;
	    uint256 date;	    
	}
	
	Whale public currentWhale;
	Whale  public lastWhale;
	
    mapping (address => User) internal users;
    mapping (address => bool) public BannedUsers;
    mapping(uint256 => address) public idToAddress;

    event NewUser(address indexed user,uint256 userID);
	event NewDeposit(address indexed user, uint256 amount,planInvest _planInvest);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event RefBonusInvited(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount,uint256 _typeFeePayed); //0 register 1 invest	
    event GiftTicket(address indexed user);	
	event CurrentWhale(address indexed user,uint256 bonusAmount, uint256 date);
	event LastWhale(address indexed user,uint256 bonusAmount,uint256 date);
    event UserBan(address indexed user,bool state,uint256 date);
	
    constructor(address payable _developmentAddress,    
    address payable _projectAddress,
    address payable _lottery) public payable {
        require(!isContract(_developmentAddress) &&
        !isContract(_projectAddress));
        lottery=LotteryEffect(_lottery);
        
        developmentAddress =_developmentAddress;
        projectAddress=_projectAddress;
        
        currentWhale.user=_projectAddress;
        currentWhale.amount=0;
        currentWhale.date=block.timestamp;
        
        dummyRegistration(projectAddress);
    }

    modifier onlyUser(){
        require(isUserExists(msg.sender),"user not exists");
        _;
    }

    modifier onlyProject(){
            require(msg.sender ==projectAddress,"only project Address");
        _;
    }
    modifier isBanned{
            require(!BannedUsers[msg.sender],"have been banned, contact technical support");
        _;
    }
    
    
    
    
    function withdraw() public isBanned onlyUser  payable{
        User storage user = users[msg.sender];
		
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {		    
            if(user.deposits[i].paid)
                continue;
            uint256 interesRate;
            uint256 timePlan;
            (interesRate, timePlan) = getInterestRateForPlan(user.deposits[i].planType);

            uint256 MaxWithdrawn = interestCalculator(user.deposits[i].amount,interesRate)
					.mul(timePlan).div(TIME_STEP);

			if ( user.deposits[i].withdrawn < MaxWithdrawn ){

				if (block.timestamp.sub(user.deposits[i].start) > timePlan
                && user.deposits[i].withdrawn == 0) {
					dividends = MaxWithdrawn;
				}
                else{
					dividends = interestCalculator(user.deposits[i].amount,interesRate)
						.mul(block.timestamp.sub(user.deposits[i].checkPoint))
						.div(TIME_STEP);
				}
                if(user.deposits[i].withdrawn.add(dividends) > MaxWithdrawn )
                {
                    dividends = MaxWithdrawn - user.deposits[i].withdrawn;
                }
                
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				if(user.deposits[i].planType !=planInvest.Emerald)
				totalAmount = totalAmount.add(dividends.mul(REINVESTMENT_PERCENTAGE).div(PERCENTS_DIVIDER));
				else
				totalAmount = totalAmount.add(dividends.mul(REINVESTMENT_PERCENTAGE.sub(50)).div(PERCENTS_DIVIDER));
				user.deposits[i].checkPoint = block.timestamp;
                if(user.deposits[i].withdrawn >= MaxWithdrawn)
                user.deposits[i].paid=true;
			}
            else{
                if(!user.deposits[i].paid)
                user.deposits[i].paid=true;
            }
		}

		uint256 referralBonus = getUserBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}

		uint256 invitedBonus = getInviteBonus(msg.sender);
		if(invitedBonus >0){
		    totalAmount = totalAmount.add(invitedBonus);
		    user.bonusUniqueForReferrel=0;
		}

		require(totalAmount > 5, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}                  
		uint256 priceTicket =lottery.getPriceTicket();
        if( address(this).balance > priceTicket ){         	
    	lottery.buyTicketToAddress.value(priceTicket)(msg.sender);
        emit GiftTicket(msg.sender);
        }
		msg.sender.transfer(totalAmount);
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);	
    }

    function invest(uint128 _typePlan) public isBanned onlyUser payable{
        require(msg.value >= INVEST_MIN_AMOUNT ,"minimum invest is 300 trx" );
        require(_typePlan < 3,"type plan invalid, Diamond = 0, Ruby = 1, Emerald =2");
        developmentAddress.transfer(msg.value.mul(DEVELOPMENT_FEE
        .add(MARKETING_FEE)
        .add(SUPPORT_FEE))
        .div(PERCENTS_DIVIDER));
        
        projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
        
        
        uint256 totalFee=msg.value.mul(MARKETING_FEE
        .add(PROJECT_FEE)
        .add(SUPPORT_FEE)
        .add(DEVELOPMENT_FEE))
        .div(PERCENTS_DIVIDER);
        emit FeePayed(msg.sender, totalFee,1);

        User storage _user = users[msg.sender];
        
        planInvest plan;
        if(_typePlan == uint(planInvest.Diamond))
        plan= planInvest.Diamond;
        if(_typePlan == uint(planInvest.Ruby))
        plan= planInvest.Ruby;
        if(_typePlan == uint(planInvest.Emerald))
        plan= planInvest.Emerald;

        _user.deposits.push(Deposit(
        plan,
		msg.value,
		msg.value,
		0,
		block.timestamp,
		block.timestamp,
		false
    	));
        
        updateWhale(msg.value);

        uint256 priceTicket =lottery.getPriceTicket();
        if( address(this).balance > priceTicket ){         	
    	lottery.buyTicketToAddress.value(priceTicket)(msg.sender);
        emit GiftTicket(msg.sender);
        }
    	totalInvested = totalInvested.add(msg.value);
    	totalDeposits = totalDeposits.add(1);       
        
        address _referrer = users[msg.sender].referrer.referrer;
	    updateBonus(_referrer,msg.value.sub(totalFee));

    	emit NewDeposit(msg.sender, msg.value,plan);
    }    

    function registration(address _IDreferrer,uint128 _typePlan) public payable returns(uint256 _userID) {
        address _referrer = _IDreferrer;
        require(msg.value>= INVEST_MIN_AMOUNT.div(3),"pay registration  100 TRX");
        if(_referrer==address(0))
        _referrer = projectAddress;        
        require(!isUserExists(msg.sender),"user exists");
        require(isUserExists(_referrer),"referrer not exists");
        require(msg.sender != _referrer,"referrer is equal to new User");       

        
        planInvest plan;
        if(_typePlan == uint(planInvest.Diamond))
        plan= planInvest.Diamond;
        if(_typePlan == uint(planInvest.Ruby))
        plan= planInvest.Ruby;
        if(_typePlan == uint(planInvest.Emerald))
        plan= planInvest.Emerald;


        User storage _user =users[msg.sender];                
        _user.userAddress = msg.sender;
		_user.timeRegister = block.timestamp;
        _user.referrer.referrer = _referrer;
        _user.referrer.isActiveFirstLevel = false;
        _user.referrer.isActivesecondLevel = false;
        idToAddress[lastUserId] = msg.sender;
        _user.id = lastUserId;
        totalUsers++;
        lastUserId++;
        _userID=_user.id;        
        uint256 ticketPrice =lottery.getPriceTicket();
        uint256 amount =msg.value - REGISTER_FEE;
        projectAddress.transfer(REGISTER_FEE);
        emit FeePayed(msg.sender, REGISTER_FEE,0);        

        _user.deposits.push(Deposit(
            plan,
        	amount,
        	amount,
        	0,
        	block.timestamp,
        	block.timestamp,
        	false
        ));

        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);        
        
        updateWhale(msg.value);

        if( address(this).balance > ticketPrice ){  
        lottery.buyTicketToAddress.value(ticketPrice)(msg.sender);                
        emit GiftTicket(msg.sender);
        }
        updateBonusUniqueForReferrel(_referrer, msg.sender, amount);
        updateDirectReferrels(msg.sender,_referrer);
        emit NewUser(msg.sender,_user.id);        
    }
    
    function dummyRegistration(address _address) private {
        address _newUser = _address;
        address _referrer =_address;
        User storage _user =users[_newUser];
        _user.id = lastUserId;
        _user.userAddress = _newUser;
		_user.timeRegister = block.timestamp;
        _user.referrer.referrer = _referrer;
        _user.referrer.isActiveFirstLevel = true;
        _user.referrer.isActivesecondLevel = true;
        idToAddress[lastUserId] = _newUser;
        totalUsers++;
        lastUserId++;
        emit NewUser(msg.sender,_user.id);
    }

    function isUserExists(address _address) public view returns(bool){
        return ( users[_address].userAddress != address(0) );
    }

    function getUserReferrer(address _address) public view returns(address){
        require(isUserExists(_address),"user not exists" );
        return users[_address].referrer.referrer;
    }
    function getUserReferrerFull(address _address) public view returns(address referrer_,uint256 DirectLength,
    uint256 FirstLevelLength,uint256 SecondLevelLength){
        require(isUserExists(_address),"user not exists" );
        referrer_ = users[_address].referrer.referrer;
        DirectLength= users[_address].referrer.directReferrerList.length;
        FirstLevelLength=users[_address].referrer.firstLevelReferralsList.length;
        SecondLevelLength =users[_address].referrer.secondLevelReferralsList.length;
    }

    function getDirectReferrels(address _address) public view returns(address[] memory){
        require(isUserExists(_address),"user not exists" );
        return users[_address].referrer.directReferrerList;
    }

    function getFirstLevelReferrals(address _address) public view returns(address[] memory){
        require(isUserExists(_address),"user not exists" );
        return users[_address].referrer.firstLevelReferralsList;
    }

    function getSecondLevelReferrals(address _address) public view returns(address[] memory){
        require(isUserExists(_address),"user not exists" );
        return users[_address].referrer.secondLevelReferralsList;
    }

    function updateDirectReferrels(address _newReferrer,address _userAddress) internal {
        User storage _user = users[_userAddress];
        _user.referrer.directReferrels[_newReferrer]=_newReferrer;
        _user.referrer.directReferrerList.push(_newReferrer);
        updateFirstLevelReferrals(_newReferrer,_userAddress);
    }

    function updateFirstLevelReferrals(address _newReferrer,address childReferrer) internal{

        address fatherReferrer = users[childReferrer].referrer.referrer;

        User storage _user =users[fatherReferrer] ;

        if(_user.referrer.directReferrels[_newReferrer]!=address(0))
            return;
        
        _user.referrer.firstLevelReferrals[_newReferrer]=_newReferrer;
        _user.referrer.firstLevelReferralsList.push(_newReferrer);
        updateSecondLevelReferrals(_newReferrer, fatherReferrer);
        
    }

    function updateSecondLevelReferrals(address _newReferrer,address sonReferrer) internal {
        address granfather = users[sonReferrer].referrer.referrer;
        User storage _user = users[granfather];

        if(_user.referrer.firstLevelReferrals[_newReferrer] != address(0))
            return;

        _user.referrer.secondLevelReferrals[_newReferrer]=_newReferrer;
        _user.referrer.secondLevelReferralsList.push(_newReferrer);
    }

   function getContractBalance() public view returns (uint256){
		return address(this).balance;
   }    

    function getInviteBonus (address _address) public onlyUser view  returns(uint256) {
        require(isUserExists(_address),"user not exists" );
        return users[_address].bonusUniqueForReferrel;
    }

    function getUserBonus(address _address) public  onlyUser view returns(uint256) {
        require(isUserExists(_address),"user not exists" );
        return users[_address].bonus;
    }

    function getBalaceUser(address _address) public onlyUser view returns(uint256){
        uint256 totalAmount;
		uint256 dividends;
        for (uint256 i = 0; i < users[_address].deposits.length; i++) {
            if(!users[_address].deposits[i].paid)
            dividends = dividends.add(getInterest(_address,i));
        }
        totalAmount=totalAmount.add(dividends);

        uint256 referralBonus = getUserBonus(_address);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
		}

		uint256 invitedBonus = getInviteBonus(_address);
		if(invitedBonus >0){
		    totalAmount = totalAmount.add(invitedBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		return totalAmount;
    }

    function getUserCheckpoint(address _address) public  view returns(uint256) {
		return users[_address].timeRegister.div(TIME_STEP);
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256,planInvest, uint256,bool) {
	    User memory user = users[userAddress];
		return (user.deposits[index].amount,
        user.deposits[index].withdrawn,
        user.deposits[index].planType,
        user.deposits[index].start,
        user.deposits[index].paid);
	}
	

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
    }

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i <  users[userAddress].deposits.length; i++) {
            amount = amount.add( users[userAddress].deposits[i].amount);
		}
		return amount;
	}    

    function getUserTotalCurrentDeposits(address userAddress) public view returns(uint256) {
        uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            if(!users[userAddress].deposits[i].paid)
                amount = amount.add(users[userAddress].deposits[i].amount);		}
		return amount;
	}    

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User memory user = users[userAddress];
		uint256 amount;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}
		return amount;
	}

    function getInterestRateForPlan(planInvest _plan) internal pure returns (uint256 interesRate,uint256 timePlan){
        if(_plan == planInvest.Diamond){
        interesRate = DAILY_PERCENTAGE_PLAN_DIAMOND;
        timePlan = TIME_PLAN_DIAMOND;
        }
        if(_plan == planInvest.Ruby){
        interesRate= DAILY_PERCENTAGE_PLAN_RUBY;
        timePlan = TIME_PLAN_RUBY;
        }
        if(_plan == planInvest.Emerald){
        interesRate= DAILY_PERCENTAGE_PLAN_EMERALD;
        timePlan = TIME_PLAN_EMERALD;
        }
    }
    function getMyUserID(address address_)public view returns(uint256 _ID) {
        _ID=users[address_].id;
    }
    function getInterest(address _address, uint256 index) public view returns(uint256){
            if(users[_address].deposits[index].paid)
                return 0;            
            User memory user = users[_address];
		    uint256 totalAmount;
		    uint256 dividends;
		    uint256 i = index;
		    uint256 interesRate;
            uint256 timePlan;           

            (interesRate, timePlan) = getInterestRateForPlan(user.deposits[i].planType);

            uint256 MaxWithdrawn = interestCalculator(user.deposits[i].amount,interesRate)
					.mul(timePlan).div(TIME_STEP);

			if (user.deposits[i].withdrawn < MaxWithdrawn) {
				if (block.timestamp.sub(user.deposits[i].start) > timePlan
                && user.deposits[i].withdrawn == 0) {
					dividends = MaxWithdrawn;
				}
                else{
					dividends = interestCalculator(user.deposits[i].amount,interesRate)
						.mul(block.timestamp.sub(user.deposits[i].checkPoint))
						.div(TIME_STEP);
				}
                if(user.deposits[i].withdrawn.add(dividends) > MaxWithdrawn )
                {
                    dividends = MaxWithdrawn - user.deposits[i].withdrawn;
                }				
                if(user.deposits[i].planType !=planInvest.Emerald)
				totalAmount = totalAmount.add(dividends.mul(REINVESTMENT_PERCENTAGE).div(PERCENTS_DIVIDER));
				else
				totalAmount = totalAmount.add(dividends.mul(REINVESTMENT_PERCENTAGE.sub(50)).div(PERCENTS_DIVIDER));

				totalAmount = dividends;
            }

		return totalAmount;
    }

    function updateBonus(address _address, uint256 _amount) internal {
        address _user = _address;
        address _referral = msg.sender;
        uint256 amount;
        for(uint256 i = 0; i<3;i++){
            if(_user != address(0) && _user != _referral){
                (_user,_referral,amount) = updateBonusHandler(_user, _amount,i);                                          
                if(amount!=0){
                    if(i!=0)            
                    emit RefBonus(_user, _referral, i,amount);
                    else
                    emit RefBonus(_address, msg.sender,i,amount);
                }
            }
        }
    }
   
    function updateBonusHandler(address _address, uint256 _amount, uint256 _lever) internal returns(address _referrer,address _referral, uint256 _bonus){
        _referrer = users[_address].referrer.referrer;
        _referral = _address;        
        
        uint256 bonus =users[_address].bonus;        
        uint256 newBonus = _amount.mul(REFERRAL_PERCENTS[_lever]).div(PERCENTS_DIVIDER);

        if(!users[_address].referrer.isActiveFirstLevel && users[_address].referrer.directReferrerList.length >= FIRST_LEVEL_REFERREALS_UNLOCK )        
            users[_address].referrer.isActiveFirstLevel=true;   
        if(!users[_address].referrer.isActivesecondLevel && ( users[_address].referrer.firstLevelReferralsList.length >= SECOND_LEVEL_REFERREALS_UNLOCK ))        
            users[_address].referrer.isActivesecondLevel=true;      
                     
        if((_lever == DIRECT_LEVEL) ||
         ( users[_address].referrer.isActiveFirstLevel && _lever == FIRST_LEVEL ) ||
         ( users[_address].referrer.isActivesecondLevel && _lever == SECOND_LEVEL ) )
         {
         users[_address].bonus = bonus.add(newBonus);
         _bonus = newBonus;
         }                 
    }

    function updateBonusUniqueForReferrel(address _address, address _referral, uint256 _amount) internal {        
        uint256 bonus =users[_address].bonusUniqueForReferrel;
        uint256 totalAmount =_amount.mul(INVITED_REWARD).div(PERCENTS_DIVIDER);
        users[_address].bonusUniqueForReferrel = bonus.add(totalAmount);
        emit RefBonusInvited(_address,_referral,totalAmount);
    }

    function interestCalculator(uint256 _amount, uint256 _interestRate)internal pure returns(uint256){
        require(_interestRate < 100,"Interest rate invalid");
        return _amount.mul(_interestRate).div(PERCENTS_DIVIDER);
    }

    function reset() public onlyProject payable{
        for (uint256 i = 2; i <= totalUsers; i++) {
            delete users[idToAddress[i]].deposits;            
        } 
        projectAddress.transfer(address(this).balance);
    }
    
    
    function updateWhale(uint256 _amount) internal {
        if(_amount>currentWhale.amount)
        {
        currentWhale.user=msg.sender;
        currentWhale.amount=_amount;
        currentWhale.date=block.timestamp;
        emit CurrentWhale(msg.sender,_amount,block.timestamp);
        }
    }
    function selectWhale() public onlyProject{
        require(currentWhale.user != projectAddress,"no whales");
        
        lastWhale.user=currentWhale.user;
        lastWhale.amount=currentWhale.amount;
        lastWhale.date=block.timestamp;
        emit LastWhale(currentWhale.user,currentWhale.amount,block.timestamp);
        
        uint256 bonus =users[currentWhale.user].bonus;
        users[currentWhale.user].bonus = bonus.add(lastWhale.amount.mul(WHALES_REWARD).div(PERCENTS_DIVIDER));
        
        currentWhale.user=projectAddress;
        currentWhale.amount=0;
        currentWhale.date=block.timestamp;
        
    
    }
    function banUser(address _user,bool _state) public onlyProject {
        BannedUsers[_user]=_state;
        emit UserBan(_user,_state,block.timestamp);
    }
    
    

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}