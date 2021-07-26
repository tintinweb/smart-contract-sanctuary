/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7 .6;
contract BUSDLIFE {
    using SafeMath
    for uint256;
     IBEP20 public token;
    uint256 public constant INVEST_MIN_AMOUNT = 10 ether; // 10 BUSD
    uint256 public constant BASE_PERCENT = 100; // 1% per day
    uint256[] public REFERRAL_PERCENTS = [500, 400, 300,300,200,200,100];
    uint256[] public REFERRAL_COND = [100, 500, 1000,5000,10000,50000,100000];
    uint256 public constant MARKETING_FEE = 400;
    uint256 public constant PROJECT_FEE = 400;
    uint256 public constant PERCENTS_DIVIDER = 10000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public LAUNCH_TIME;
    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address payable public marketingAddress;
    address payable public projectAddress;
    uint256 poolAmonut;
    uint40 public pool_last_draw = uint40(block.timestamp);

    address[]   public pool1;
    address[]  public pool2;
    address[]  public pool3;

    struct Deposit {
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address payable referrer;
        uint256 bonus;
        uint256 bonus_avaliable;
        uint256 id;
        uint256 returnedDividends;
        uint256 available;
        uint256 withdrawn;
        uint256 poolbonus;
        mapping(uint8 => uint256) structure;
        mapping(uint8 => uint256) levelBusiness;
        mapping(uint8 => bool) reward_status;
        bool hasUsersBonus;
    }

    mapping(address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);

    modifier beforeStarted() {
        require(block.timestamp >= LAUNCH_TIME, "!beforeStarted");
        _;
    }

    constructor(address payable marketingAddr, address payable projectAddr,IBEP20 tokenAdd) {
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
         token = tokenAdd;
    }

    function invest(address payable referrer, uint256 token_quantity) public payable beforeStarted() {
        require(token_quantity >= INVEST_MIN_AMOUNT, "!INVEST_MIN_AMOUNT");

        token.transferFrom(msg.sender, address(this), token_quantity);
   
        token.transfer(projectAddress,token_quantity.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
        token.transfer(marketingAddress,token_quantity.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
        emit FeePayed(
            msg.sender,
            token_quantity.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER)
        );

        User storage user = users[msg.sender];

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {
            address payable upline = user.referrer;
            for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    
                    uint256 amount =
                        token_quantity.mul(REFERRAL_PERCENTS[i]).div(
                            PERCENTS_DIVIDER
                        );
                    
                    if(users[upline].levelBusiness[i] >=  REFERRAL_COND[i] )
                    {
                        users[upline].bonus = users[upline].bonus.add(amount);
                        users[upline].bonus_avaliable = users[upline].bonus_avaliable.add(amount);
                    }
                   

                    users[upline].structure[i]++;
                    users[upline].levelBusiness[i] += amount;

                   upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            user.id = totalUsers;
            user.hasUsersBonus = true;
            user.returnedDividends = 0;
            user.withdrawn = 0;
            emit Newbie(msg.sender);
        }

        poolAmonut = poolAmonut + token_quantity.div(50);
        
        poolDistribution(msg.sender);
        if(pool_last_draw + 1 days < block.timestamp) {
            draw_pool();
        }

        user.available = user.available.add(token_quantity.mul(2)); // max 200%
        user.deposits.push(Deposit(token_quantity, block.timestamp));

        totalInvested = totalInvested.add(token_quantity);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, token_quantity);
    }

    function poolDistribution(address userAddress) private{
        for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
           address up = users[userAddress].referrer;
            if (up != address(0)) 
            {
                uint256 total_team =  getTotalTeam(up);
                uint256 total_businesss = getTotalBusiness(up);
                uint256 Direct_referral = users[up].structure[0];
                if(Direct_referral >=10 && total_team >=100 && total_businesss >=10000 &&  total_businesss < 100000 )
                {
                    //eligible for the the first 50% of the pool
                    pool1.push(up);

                }
                else if(Direct_referral >=25 && total_team >=1000 && total_businesss >=100000  && total_businesss < 1000000)
                {
                     pool2.push(up);
                }
                else if(Direct_referral >=50 && total_team >=10000 && total_businesss >=1000000)
                {
                    pool3.push(up);
                }
            }
            up =  users[up].referrer;
        }
                

        
    }
    
    function withdraw_ref_pool_income()  public {
          User storage user = users[msg.sender];
          
          uint256 ref_avalibale = user.bonus_avaliable;
          uint256 pool_income = user.poolbonus;
          uint256 total_avail = pool_income.add(ref_avalibale);
          token.transfer(msg.sender,total_avail);
          user.bonus_avaliable = 0;
          user.poolbonus = 0;
   
    }

    function draw_pool() private
    {
        pool_last_draw = uint40(block.timestamp);
        if(poolAmonut > 0)
        {

        
            if(pool1.length > 0)
            {
            uint256 poolsharing =  poolAmonut.div(2);
            uint256 each = poolsharing.div(pool1.length);
                for( uint8 i =0; i < pool1.length; i++)
                {
                    if(!(users[pool1[i]].reward_status[1]))
                    {
                         users[pool1[i]].poolbonus += each;
                         users[pool1[i]].reward_status[1] = true;
                    }
                       
                }
            }

            if(pool2.length > 0)
            {
            uint256 poolsharing =  poolAmonut.mul(25).div(100);
            uint256 each = poolsharing.div(pool1.length);
                for( uint8 i =0; i < pool2.length; i++)
                {
                    if(!(users[pool2[i]].reward_status[1]))
                    {
                      users[pool2[i]].poolbonus += each; 
                      users[pool2[i]].reward_status[1] = true;
                    }
                }
            }
            if(pool3.length > 0)
            {
            uint256 poolsharing =  poolAmonut.mul(25).div(100);
            uint256 each = poolsharing.div(pool1.length);
                for( uint8 i =0; i < pool3.length; i++)
                {
                   if(!(users[pool3[i]].reward_status[1]))
                    {
                        users[pool3[i]].poolbonus += each; 
                        users[pool3[i]].reward_status[1] = true;
                    }
                }
            }
        }

        poolAmonut=0;

    }

    function withdraw() public beforeStarted() {
        require(
            getTimer(msg.sender) < block.timestamp,
            "withdrawal is available only once every 24 hours"
        );

        User storage user = users[msg.sender];

        uint256 userPercentRate = BASE_PERCENT;

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.available > 0) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                            user.deposits[i].amount.mul(userPercentRate).div(
                                PERCENTS_DIVIDER
                            )
                        )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (
                            user.deposits[i].amount.mul(userPercentRate).div(
                                PERCENTS_DIVIDER
                            )
                        )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                totalAmount = totalAmount.add(dividends);
            }
        }

        totalAmount = totalAmount.add(user.returnedDividends);

        if (user.available < totalAmount) {
            totalAmount = user.available;
        }



        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
        
        uint256 for_new_capital = totalAmount.mul(30).div(100);
        
        for(uint8 i=0; i< user.deposits.length; i++)
        {
            uint256 amt_to_reduce = for_new_capital.div(user.deposits.length);
             user.deposits[i].amount =  user.deposits[i].amount.sub(amt_to_reduce);
        }

        //msg.sender.transfer(totalAmount.sub(for_new_capital));
        token.transfer(msg.sender,totalAmount.sub(for_new_capital));
        
        user.available = user.available.sub(totalAmount);
        user.withdrawn = user.withdrawn.add(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }


    function getUserDividends(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 userPercentRate = BASE_PERCENT;

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.available > 0) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                            user.deposits[i].amount.mul(userPercentRate).div(
                                PERCENTS_DIVIDER
                            )
                        )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (
                            user.deposits[i].amount.mul(userPercentRate).div(
                                PERCENTS_DIVIDER
                            )
                        )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function
            }
        }
        totalDividends.add(user.returnedDividends);

        if (totalDividends > user.available) {
            totalDividends = user.available;
        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress)
    public
    view
    returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
    public
    view
    returns(address) {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress)
    public
    view
    returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserAvailable(address userAddress)
    public
    view
    returns(uint256) {
        return getUserDividends(userAddress);
    }

    function getAvailable(address userAddress) public view returns(uint256) {
        return users[userAddress].available;
    }

    function getTotalTeam(address userAddress) public view returns(uint256)
    {
         User storage user = users[userAddress];
         uint256 _structure;
        
          
        for(uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            _structure += user.structure[i];
            
        }
        return _structure;

    }
     function getTotalBusiness(address userAddress) public view returns(uint256)
    {
         User storage user = users[userAddress];
         uint256 _business;
        
          
        for(uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            _business += user.levelBusiness[i];
            
        }
        return _business;

    }
    
    function userInfo(address _addr) view external returns(uint256 poolbonus, uint256 bonus_avaliable, uint256[] memory structure, uint256[] memory levelBusiness) {
        User storage user = users[_addr];

       // uint256 payout = this.payoutOf(_addr);

      structure = new uint256[](REFERRAL_PERCENTS.length);
      levelBusiness = new uint256[](REFERRAL_PERCENTS.length);

        for(uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            structure[i] = user.structure[i];
            levelBusiness[i] = user.levelBusiness[i];
            
        }

        return (
            user.poolbonus,
            user.bonus_avaliable,
            structure,
            levelBusiness
        );
    }

    function getTimer(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint.add(24 hours);
    }

    function getUserDepositInfo(address userAddress, uint256 index)
    public
    view
    returns(uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].start);
    }

    function userHasBonus(address userAddress) public view returns(bool) {
        return users[userAddress].hasUsersBonus;
    }

    function getUserAmountOfDeposits(address userAddress)
    public
    view
    returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
    public
    view
    returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress)
    public
    view
    returns(uint256) {
        User storage user = users[userAddress];

        return user.withdrawn;
    }

    
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}