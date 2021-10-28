/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

/**
    
    SHIBA INU Farm Factory
  
    [KEY FEATURES]
    
    1) Choose your Return of Investment with multiple plans.
       Plan 1 : 4% forever, 1,460% APR
       Plan 2 : 6% for 40 days 240% ROI
       Plan 3 : 5.5% for 60 days 330% ROI
       Plan 4 : 5% for 90 days 450% ROI
       
    2) 10% Referral Bonus in total for all 5 Levels
       Level 1 : 5%
       Level 2 : 3%
       Level 3 : 1.5%
       Level 4 : 1%
       Level 5 : 0.5%
       
    3) Launch Event Promotion: There will be an additional of 2% for each plan for 4 days.)
       Plan 1 : 4% + 2% = 6%
       Plan 2 : 6% + 2% = 8%
       Plan 3 : 5.5% + 2% = 7.5%
       Plan 4 : 5% for + 2% = 7%
       (Make sure to withdraw before the end of the promotion period for it to take effect.)
    
    4) The Crypto Factory Coin Lottery will Launch Soon! 
    
    *Shiba Inu will be listed to Robinhood any day now!
    
    Join our group for more updates and promotional events.
    TG: https://t.me/the_crypto_factory 
  
    ┌───────────────────────────────────────────────────────────────────────┐
    │                                                                       |
    │                     The Crypto Factory Finance                        │
    │           Website: https://www.thecryptofactory.finance/#/            │
    │                                                                       │
    └───────────────────────────────────────────────────────────────────────┘                                                                    
    
    Note: This is experimental community project,
    which means this project has high risks as well as high profits.
    Once contract balance drops to zero payments will stops,
    deposit at your own risk. ** the 6% sweetspot **   
    
 **/
 
/** SPDX-License-Identifier: MIT **/
pragma solidity ^0.6.12;

contract ShibaFarmFactory {
    BEP20 token;
    uint256[] public REFERRAL_PERCENTS = [50, 30, 15, 10, 5]; /* referral levels 5%, 3%, 1.5%, 1%, 0.5% */
    uint256 public constant PERCENT_STEP = 5;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public addEventPercentage = 0;
    uint256 public totalInvested;
    uint256 public totalRefBonus;
    
    address inu = 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D; /* shiba inu token address */
    address payable public developerWallet;
    address payable public developerWallet1;
    address payable public developerWallet2;
    address payable public marketingWallet;
    address payable public partnerWallet1;
    address payable public partnerWallet2;
    address payable public partnerWallet3;
    address payable public partnerWallet4;
    address payable public partnerWallet5;
    
    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);
    
    using SafeMath for uint256;
    Plan[] internal plans;
    mapping(address => User) internal users;
    bool public initialized;
    
    struct Plan {
        uint256 time;
        uint256 percent;
    }

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256[5] levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
    }
    
    function initializeOpenFactory() public {
      require(msg.sender == developerWallet, "Only admin");
      initialized = true;
    }

    function invest(address referrer, uint8 plan, uint256 _amount) public {
        require(initialized, "Contract noy yet started.");
        require(plan < 4, "Invalid plan");

        token.transferFrom(msg.sender, address(this), _amount);
        uint256 fee = buy(_amount);
        emit FeePayed(msg.sender, fee);

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }
        
        user.deposits.push(Deposit(plan, _amount, block.timestamp));
        totalInvested = totalInvested.add(_amount);
        emit NewDeposit(msg.sender, plan, _amount);
    }

    function withdraw() public {
        require(initialized, "Contract noy yet started.");
        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = token.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            user.bonus = totalAmount.sub(contractBalance);
            user.totalBonus = user.totalBonus.add(user.bonus);
            totalAmount = contractBalance;
        }
        
        user.checkpoint = block.timestamp;
        user.withdrawn = user.withdrawn.add(totalAmount);
        uint256 profitAmount = sell(totalAmount);
        emit Withdrawn(msg.sender, profitAmount);
    }

    function getContractBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getPlanInfo(uint8 plan) public view returns (uint256 time, uint256 percent)
    {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getUserDividends(address userAddress) public view returns (uint256)
    {
        User storage user = users[userAddress];
        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
            if (user.checkpoint < finish) {
                uint256 share = user.deposits[i].amount;
                uint256 percent = plans[user.deposits[i].plan].percent;
                // Add percentage from addEventPercentage if > 0 else use original percentage rate.
                uint256 finalPercentage = addEventPercentage != 0 ? percent.add(addEventPercentage) : percent; 
                share = share.mul(finalPercentage).div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint? user.deposits[i].start : user.checkpoint;
                uint256 to = finish < block.timestamp ? finish : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                }
            }
        }

        return totalAmount;
    }
    
    function getUserTotalWithdrawn(address userAddress) public view returns (uint256)
    {
        return users[userAddress].withdrawn;
    }

    function getUserCheckpoint(address userAddress) public view returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress) public view returns (uint256[5] memory referrals)
    {
        return (users[userAddress].levels);
    }

    function getUserTotalReferrals(address userAddress) public view returns (uint256)
    {
        return users[userAddress].levels[0] + users[userAddress].levels[1] + users[userAddress].levels[2] + users[userAddress].levels[3] + users[userAddress].levels[4];
    }

    function getUserReferralBonus(address userAddress) public view returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress) public view returns (uint256)
    {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress) public view returns (uint256)
    {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress) public view returns (uint256)
    {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }
    
    function getUserPlanTotalAmount(address userAddress, uint8 plan) public view returns (uint256 totalAmount)
    {
        User storage user = users[userAddress];
        uint256 amount = 0;
        for( uint256 i = 0; i < user.deposits.length; i++){
            if(user.deposits[i].plan == plan){
                uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));                
                uint256 from = user.deposits[i].start > user.checkpoint? user.deposits[i].start: user.checkpoint;
                uint256 to = finish < block.timestamp ? finish : block.timestamp;
                if (from < to) {
                    amount = user.deposits[i].amount;
                }
            }
        }
        
        totalAmount = amount;
    }
    
    function setEventRate(uint256 value) external {
        require(msg.sender == developerWallet || msg.sender == developerWallet1 || msg.sender == developerWallet2);
        require(value < 50);/* 50 = 5% max promotion */
        addEventPercentage = value;
    }
       
    function sell(uint256 amount) internal returns(uint256){
        require(initialized);
        uint256 total = SafeMath.div(SafeMath.mul(amount,5),100);
		uint256 spread = SafeMath.div(total,5);
        uint256 market = SafeMath.div(spread,4);
        uint256 finalProfit = SafeMath.sub(amount,total);
	    token.transfer(developerWallet, spread);
        token.transfer(developerWallet1, spread);
        token.transfer(developerWallet2, spread);
        token.transfer(marketingWallet, market);
        token.transfer(partnerWallet3, market);
        token.transfer(partnerWallet4, market);
        token.transfer(partnerWallet5, market);
	    token.transfer(msg.sender, finalProfit);
	    return finalProfit;
    }
    
    function buy(uint256 amount) internal returns(uint256){
        require(initialized);
        uint256 total = SafeMath.div(SafeMath.mul(amount,5),100);
		uint256 market = SafeMath.div(SafeMath.mul(amount,2),100);
		uint256 spread = SafeMath.div(total,3);
		uint256 partner = SafeMath.div(market,2);
		uint256 marketing = SafeMath.div(partner,2);
	    token.transfer(developerWallet, spread);
        token.transfer(developerWallet1, spread);
        token.transfer(developerWallet2, spread);
        token.transfer(partnerWallet1, partner);
        token.transfer(partnerWallet2, marketing);
        token.transfer(marketingWallet, marketing);
	    return spread;
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns ( uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish)
    {
        User storage user = users[userAddress];
        plan = user.deposits[index].plan;
        percent = plans[plan].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
    }

    function getSiteInfo() public view returns (uint256 _totalInvested, uint256 _totalBonus)
    {
        return (totalInvested, totalRefBonus);
    }

    function getUserInfo(address userAddress) public view returns (uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals)
    {
        return (getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
  
    constructor() public {
        token = BEP20(inu);
        developerWallet = msg.sender;
        developerWallet1 = 0x2364c9465B434C07eE91e6B99310BCC75060669b; 
        developerWallet2 = 0x2981147dDC035F437f5EC60c08438A263Ca7e2eD;
        marketingWallet = 0x0FC31497113A7827FB18bE351436464d4F15306D;
        partnerWallet1 = 0x9b97F10E328F8c40470eCF8EF95547076FAa1879;
        partnerWallet2 = 0x30283d32479567fB21cB32889Ffd115B2428B262;
        partnerWallet3 = 0x0177A4e72Fd366F9b406A8C9E510378dA9A50f69;
        partnerWallet4 = 0x9e01B67B83AA360076dE9803FD68Abd07F95B07f;
        partnerWallet5 = 0x810575c22bC4b96D16a81d06cada9Ff368872b15;
    
        
        plans.push(Plan(10000, 40)); /** Plan 1 : 4% forever, 1,460% APR **/
        plans.push(Plan(40, 60)); /** Plan 2 : 6% for 40 days 240% ROI **/
        plans.push(Plan(60, 55)); /** Plan 3 : 5.5% for 60 days 330% ROI **/
        plans.push(Plan(90, 5)); /** Plan 4 : 5% for 90 days 450% ROI **/
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

interface BEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value );
}