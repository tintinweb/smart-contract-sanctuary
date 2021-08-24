/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-09

🚀 Welcome to CryptoMint Cloud - the most innovative and benevolent DeFi invetment platform in the Universe! 🚀
We're helping you to become a crypto whale while donating to Eligible Crypto-Charities around the world, with 1st-of-
its-kind on-chain mechanisms to automatically donate at least 1% of every transaction to the charity of your choice.
At the end of every week, on-chain voting decides where 2% of each investment will go to a new charity.
So, how big of a #CharityWhale are you trying to be? 

We're hyper-focused on helping the crypto universe to become safer, easier to understand, more trustworthy, and more 
profitable. We're connecting with top influencers on the major platforms to engage in the dialogues that help us to 
understand the needs of investors, how we can better serve the community, be an informational resource, reinforce best 
practices, and see which charities are perceived to be  the most helpful in accomplishing the most important humanitarian
efforts on earth.

As long-time #cryptovestors and #cryptothusiasts, we've noticed that flash bots, front-runner bots, and high-frequency 
trading bots have been stealing more and more value away from average long-term and day-trading investors by using python 
and solidity scripts in the same ways hedge funds in the traditional financial worlds have been known to take from the 
middle class and make the rich richer.
In our efforts to safeguard your funds and help each investor to become a charitable crypto whale, we have implemented 
a variety of anti-bot and anti-frontrunning tokenomics that help you to safely invest, while supporting
your favorite charity, thanks to the automatic and flexible burn, liquidity provisioning, and donations to the charity 
address of your choice. Every week, we will rely on a community vote in our Telegram group chat to guide this rocketship 
on our moon mission to be the most charitable coin in the universe! Reach via Twitter for pre-sale and airdrop updates!

Rather than typical ROI yield farms, we use defi Arbitrage Bots to ensure that your dividends can keep on multiplying.
We've implemented a profit sharing ratio of 70% given to the Investors and 30% for the marketing, development and referrals.
Our charity wallet: 0x0321724ab40936659CeF5a861bB2DEc71B919599

* Presale starts Thursday, August 12th at 12am UTC on DxSale with FAIRLAUNCH two weeks later. Stay tuned!
 
SPDX-License-Identifier: MIT
*/

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;


library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract CryptoMintCloud {
    using SafeMath for uint256;

    uint public startTime;
    uint public total;
    uint public pool;
    uint public rankPool;
    uint public safetyPool;
    uint public sefetyTime;
    uint public rankTime;
    address payable public charity;
    address payable public ad;
    address payable public team;
    address payable public owner;  //Intialize owner variable -s
    address Blockaddress;// intialize address -s
    uint freezebegin;// intialize variable to begin time of block  -s
    uint freezeend;// intialize variable to end time of block   -s
    uint dayTime = 1 days;
    uint increaseTime = 5 hours;

    uint initialTime = dayTime.mul(7);
    uint unit = 18;
    
    uint percentInsuranceReward = 0;
    uint public stakeTime;
    uint[] pcts = [0,0,0];
    // uint stake
    
    //address public owner = msg.sender;
    struct User {
        bool active;
        address referrer;
        uint recommendReward;
        uint investment;
        uint totalWithdraw;
        uint totalReward;
        uint checkpoint;
        uint subNum;
        uint subStake;
        address[] subordinates;
        Investment[] investments;
        blocklist[] blocks;
        whitelist[] whitels;
    }

    struct Investment {
        uint start;
        uint finish;
        uint value;
        uint totalReward;
        uint period;
        uint rate;
        uint typeNum;
        bool isReStake;
        address referrer;
    }

    struct Invest{
        address addr;
        uint value;
        uint reward;
        uint time;
    }
    
    /* struct blocklist  */
    
     struct blocklist{
        address addresss;
        uint freezebegin;
        uint freezeend;
    }
    /* end */
    
    /* struct whitelist  */
    
     struct whitelist{
        address addresss;
        uint freezebegin;
        uint freezeend;
    }
    /* end */
    
    Invest[] public insurances;
    uint public insuranceIndex;
    uint public insuranceRewardIndex;

    uint[] rankPcts = [40,30,20,10];
    mapping(uint => Invest[4]) rankMapArray;
    mapping(uint => mapping(address => uint)) public rankMap;
    mapping(uint => bool) public rankFlag;
    mapping(address => User) public userMap;

    event Stake(address indexed user,address indexed referrer, uint256 amount);
    event Retake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Insurance(address indexed user, uint256 amount);
    event Rank(address indexed user, uint256 amount);
    
    event ShowAddress(whitelist[] whitels);
    address [] public registeredusers; // Storing all user addresses into array  -s
   
     modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
    
    constructor(address payable charity_, address payable ad_, address payable team_,address payable owners,uint256 startTime_, uint256 rankTime_) {
        require(!isContract(charity_), "!charityAddress");
        require(!isContract(ad_), "!adAddress");
        require(!isContract(team_), "!teamAddress");
        charity = charity_;
        ad = ad_;
        team = team_;
        owner = owners;//pass owner address -s
        userMap[team].active = true;
        userMap[owner].referrer = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        // userMap[owner].investment = 2;
        if(startTime_==0) startTime_ = block.timestamp;
        if(rankTime_==0) rankTime_ = block.timestamp;
        startTime = startTime_;
        rankTime = rankTime_;
    }

    function setCharity( address payable _charity) external onlyOwner() {
        charity = _charity;
    }

    /*   Addblockers  onwer will add the address and start time and end time of block address*/
    function addblockers(address blockaddress,uint x, uint y)  public onlyOwner{
         User storage user = userMap[owner];
         user.blocks.push(blocklist({
              addresss: blockaddress,
                    freezebegin: x,
                    freezeend: y
         }));
     }   
     /*  end   */

  /*   displayblockers  will display the list of blockaddress and time start and end*/
    
     function displayblockers()  public view returns(address[] memory baddresss,uint[] memory x,uint[] memory y) {
      blocklist[] memory blocks  = userMap[owner].blocks;
        baddresss = new address [](blocks.length);
        x = new uint[](blocks.length);
        y = new uint[](blocks.length);
        for(uint i=0;i<blocks.length;i++){
            baddresss[i] = blocks[i].addresss;
            x[i] = blocks[i].freezebegin;
            y[i] = blocks[i].freezeend;
        }
       
     } 
     
     /*  end   */
      
    /*   addwhitelists  will add the address and start time and end time of white list address*/
    function addwhitelists(address whiteaddress,uint x, uint y)  public onlyOwner{
         User storage user = userMap[owner];
         user.whitels.push(whitelist({
              addresss: whiteaddress,
                    freezebegin: x,
                    freezeend: y
         }));
     }   
     /*  end   */
     
      /*   displaywhitelists  will display the list of white list addresses and time start and end*/
    
     function displaywhitelists()  public view returns(address[] memory waddresss,uint[] memory x,uint[] memory y) {
      whitelist[] memory whitels  = userMap[owner].whitels;
        waddresss = new address [](whitels.length);
        x = new uint[](whitels.length);
        y = new uint[](whitels.length);
        for(uint i=0;i<whitels.length;i++){
            waddresss[i] = whitels[i].addresss;
            x[i] = whitels[i].freezebegin;
            y[i] = whitels[i].freezeend;
        }
       
     } 
     
     /*  end   */
     
    
    function changeInsurancePercent(uint percentInsurance) public {
        percentInsuranceReward=percentInsurance;
    }
    function changePCTs(uint pct1,uint pct2,uint pct3) public {
        User storage user = userMap[owner];
        if(user.investments.length>0)
        {
            // uint diff = (block.timestamp - user.investments[0].start) / 60 / 60 / 24;
            if (user.investments[0].start <= (block.timestamp - 7 days)) {
            // if(diff>7 days){
                    pcts[0]=pct1;
                    pcts[1]=pct2;
                    pcts[2]=pct3;
            }
        }
        
    } 
    function getRefferalInvestor() public view returns(address referrer,uint amount){
        User storage user = userMap[owner];
        Investment memory investment;
        // uint maxAmount=0;
        // address maxReffer=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        // address maxReffer=0x0000000000000000000000000000000000000000;
        for(uint i=0;i<user.investments.length;i++){
            investment = user.investments[i];
            
            if(userMap[investment.referrer].investment>amount)
            {
                amount=userMap[investment.referrer].investment;
                referrer=investment.referrer;
            }
        }
        // referrer=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        // amount=20;
    } 
    function getPCTs() public view returns(uint[] memory pctsArg){
        return pcts;
    } 
    function getRankIndex() public view returns(uint index){
        (, uint time) = block.timestamp.trySub(rankTime);
        index = time.div(dayTime);
    }

    function getRandom() internal view returns(uint256) {
        bytes32 _blockhash = blockhash(block.number-1);
        uint256 random =  uint256(keccak256(abi.encode(_blockhash,block.timestamp,block.difficulty))).mod(7);
        return random;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getInfo() public view returns(uint,uint,uint,uint,uint,uint,uint){
        return (startTime, total, pool, rankPool, safetyPool, sefetyTime, rankTime);
    }

    function getRanks(uint index) public view returns(address[4] memory addresses, uint[4] memory values,
        uint[4] memory rewards, uint[4] memory times){
        Invest[4] memory invests = rankMapArray[index];
        for(uint i=0;i<invests.length;i++){
            addresses[i] = invests[i].addr;
            values[i] = invests[i].value;
            rewards[i] = invests[i].reward;
            times[i] = invests[i].time;
        }
    }

    function getInsurances(uint length) public view returns(address[] memory addresses, uint[] memory values,
        uint[] memory rewards, uint[] memory times){
        uint index = 0;
        (,uint end) = insuranceIndex.trySub(length);
        length = insuranceIndex.sub(end);
        addresses = new address[](length);
        values = new uint[](length);
        rewards = new uint[](length);
        times = new uint[](length);
        for(uint i=insuranceIndex;i>end;i--){
            addresses[index] = insurances[i-1].addr;
            values[index] = insurances[i-1].value;
            times[index] = insurances[i-1].time;
            rewards[index] = insurances[i-1].reward;
            index++;
        }
    }

    // function to get investments including info. times, starts, values, total rewads, rates, typeNums
    function getInvestments() public onlyOwner view returns(
        uint[] memory times,uint[] memory starts, uint[] memory values, uint[] memory totalRewards,
        uint[] memory rates, uint[] memory typeNums, bool[] memory isReStakes
    ){
        Investment[] memory investments = userMap[msg.sender].investments;
        times = new uint[](investments.length);
        starts = new uint[](investments.length);
        values = new uint[](investments.length);
        totalRewards = new uint[](investments.length);
        rates = new uint[](investments.length);
        typeNums = new uint[](investments.length);
        isReStakes = new bool[](investments.length);
        for (uint i = 0; i < investments.length; i++) {
            times[i] = investments[i].finish;
            starts[i] = investments[i].start;
            values[i] = investments[i].value;
            totalRewards[i] = investments[i].totalReward;
            rates[i] = investments[i].rate;
            typeNums[i] = investments[i].typeNum;
            isReStakes[i] = investments[i].isReStake;
        }
    }

    function getInvestmentsEx() public view returns(uint[] memory periods){
        Investment[] memory investments = userMap[msg.sender].investments;
        periods = new uint[](investments.length);
        for (uint i = 0; i < investments.length; i++) {
            periods[i] = investments[i].period;
        }
    }

    // method to increase PerksCoin Token
    function getIncreasePct() public view returns(uint increasePct){
        (,uint time) = block.timestamp.trySub(startTime);
        increasePct = time.div(increaseTime);
    }

    // bnm 
    function calcReward(uint income, uint rate, uint period) public pure returns(uint reward){
        reward = income.mul(rate).mul(period).div(1000);
    }

    function calcRewardCompound(uint income, uint rate, uint period) public pure returns(uint reward){
        reward = income;
        for(uint i=0;i<18;i++){
            if(period > i)
                reward = reward.mul(rate).div(1000).add(reward);
            else
                reward = reward.mul(0).div(1000).add(reward);
        }
        reward = reward.sub(income);
    }

    function getPeriodAndRate(uint typeNum, uint income) public view returns(uint period, uint rate, uint totalReward){
        if(typeNum==1){
            period = 15;
            rate = getIncreasePct().add(80);
            totalReward = calcReward(income, rate, period);
        }else if(typeNum==2){
            period = 15;
            rate = getRandom().mul(10).add(getIncreasePct()).add(60);
            totalReward = calcReward(income, rate, period);
        }else if(typeNum==3){
            period = 15;
            rate = getIncreasePct().add(76);
            totalReward = calcRewardCompound(income, rate, period);
        }else if(typeNum==4){
            period = getRandom().add(12);
            rate = getIncreasePct().add(76);
            totalReward = calcRewardCompound(income, rate, period);
        }
    }

    // Stake referrer account
    function stake(address referrer, uint typeNum) public payable {
        // address referrer=0x831Bfe565B2e0b61b140dEcD6B3eC5D11bfEB31f;
        // uint typeNum=1;
        require(block.timestamp>=startTime, "Not start");
        stakeTime=block.timestamp;
        uint income = msg.value;
        require(income >= 5 * 10 ** (unit.sub(2)), "Minimum investment 0.05");
        require(income <= 100 * 10 ** unit, "Maximum investment 100");
        require(userMap[msg.sender].investment==0, "Investor already invested!");
        
        
        bindRelationship(referrer);
        whitelist[] memory whitels  = userMap[owner].whitels;
        if(msg.sender!=owner)
        {
            bool flag=false;
            for(uint i=0;i<whitels.length;i++){
                if(whitels[i].addresss==msg.sender)
                {
                    flag=true;
                    break;
                }
                
            }
            require(flag, "Invester should be added in whitelist first!");    
        }
        
        addInvestment(referrer,typeNum, income, false);
        // emit ShowAddress(userMap[owner].whitels);
        emit Stake(msg.sender,referrer, income);
    }
    
    // method to get update amount
    function updateReward(uint amount) private returns(uint){
        uint income = getAmount();
        User storage user = userMap[msg.sender];
        if(amount == 0 || amount > income) amount = income;
        if(amount > pool) amount = pool;
        // require(amount > 0, appendUintToString("Error: ",amount));
        user.totalReward = income.sub(amount);
        user.totalWithdraw = user.totalWithdraw.add(amount);
        user.checkpoint = block.timestamp;
        pool = pool.sub(amount);
        if(sefetyTime == 0 && block.timestamp > startTime.add(dayTime.mul(2)) && pool < 10 * 10 ** unit)
            sefetyTime = block.timestamp.add(dayTime);
        return amount;
    }
    
    //re stake the amount
    function reStake(uint typeNum, uint amount) public {
        amount = updateReward(amount);
        addInvestment(userMap[msg.sender].referrer,typeNum, amount, true);
        emit Retake(msg.sender, amount);
    }
    
    // withdraw amount from wallet
    function withdraw(uint amount) public {
        amount = updateReward(amount);
        if(sefetyTime > 0 && sefetyTime < block.timestamp){
            msg.sender.transfer(amount);
        }else{
            // safetyPool = safetyPool.add(amount.mul(5).div(100));
            msg.sender.transfer(amount.mul(95).div(100));
        }
        emit Withdraw(msg.sender, amount);
    }
    
    // partial withdraw amount from wallet
    function partialWithdraw(uint amount) public {
        amount = updateReward(amount);
        if(sefetyTime > 0 && sefetyTime < block.timestamp){
            msg.sender.transfer(amount);
        }else{
            // safetyPool = safetyPool.add(amount.mul(5).div(100));
            msg.sender.transfer(amount.mul(95).div(100));
        }
        emit Withdraw(msg.sender, amount);
    }
    
    // method to get ammount 
    function getAmount() public view returns(uint amount){
        User memory user = userMap[msg.sender];
        amount = user.totalReward;
        Investment memory investment;
        for(uint i=0;i<user.investments.length;i++){
            investment = user.investments[i];
            if(user.checkpoint > investment.finish) continue;
            if(investment.typeNum > 2) {
                if(block.timestamp < investment.finish) continue;
                amount = amount.add(investment.totalReward);
            }else{
                uint rate = investment.totalReward.div(investment.period.mul(dayTime));
                uint start = investment.start.max(user.checkpoint);
                uint end = investment.finish.min(block.timestamp);
                if(start < end){
                    amount = amount.add(end.sub(start).mul(rate));
                }
            }
        }
    }
    
    //add investment 
    function addInvestment(address areferrer,uint typeNum, uint income, bool isReStake) private{
        User storage user = userMap[msg.sender];

        // && userMap[msg.sender].referrer!=0x0000000000000000000000000000000000000000
        //userMap[msg.sender].referrer!=address(0)
        
        if(areferrer!=owner)
        {
            require(user.referrer!=address(0) , "This is an Invite-only investment club. Refferal Links are required to invest. Please join our Telegram group to get a referrer if you don't have one already.");
        }
        
        
        safetyPool = safetyPool.add(income.mul(5).div(100));
        uint reIncome = income;
        if(isReStake) reIncome = income.mul(102).div(100);
        (uint period, uint rate, uint totalReward) = getPeriodAndRate(typeNum, reIncome);
        uint finish = dayTime.mul(period).add(block.timestamp);
        if (period > 0) {
            address(uint160(charity)).transfer(income.mul(45).div(1000));
            address(uint160(ad)).transfer(income.mul(55).div(1000));
            if(block.timestamp>startTime.add(initialTime)){
                pool = pool.add(income.mul(85).div(100));
                rankPool = rankPool.add(income.mul(5).div(100));
            }else{
                pool = pool.add(income.mul(88).div(100));
                rankPool = rankPool.add(income.mul(2).div(100));
            }

            total = total.add(income);
            user.investment = user.investment.add(income);
            address referrer = user.referrer;
            uint index = getRankIndex();
            for(uint i=0;i<3;i++){
                if(!userMap[referrer].active) break;
                uint reward = income.mul(pcts[i]).div(100);
                userMap[referrer].recommendReward = userMap[referrer].recommendReward.add(reward);
                userMap[referrer].totalReward = userMap[referrer].totalReward.add(reward);
                userMap[referrer].subStake = userMap[referrer].subStake.add(income);
                if(i==0){
                    rankMap[index][referrer] = rankMap[index][referrer].add(income);
                    ranking(referrer, rankMap[index][referrer]);
                }
                referrer = userMap[referrer].referrer;
            }
            if(user.investments.length>0)
            {
                // uint diff = (block.timestamp - user.investments[0].start) / 60 / 60 / 24;
                // if(diff>7 days){
                if (user.investments[0].start <= (block.timestamp - 7 days)) {
                    if(pcts[0] == 0 && pcts[1] == 0 && pcts[2] == 0)
                    {
                        pcts = [5,2,1];       
                    }
                }
                
            }
            user.investments.push(Investment({
                start: block.timestamp,
                finish: finish,
                value: reIncome,
                totalReward: totalReward,
                period: period,
                rate: rate,
                typeNum: typeNum,
                isReStake: isReStake,
                referrer: areferrer
            }));
            if(sefetyTime == 0 || sefetyTime > block.timestamp){
                insurances.push(Invest(msg.sender, income, percentInsuranceReward, block.timestamp));
                insuranceIndex++;
                insuranceRewardIndex = insuranceIndex;
            }
               /* this will help us to push the users address into array */
           
            registeredusers.push(msg.sender);
            /**************s************/
        }
    }
    
       /* this help us to get the registered user address which helps to getuserinvestments by rounding up addressess in loop to find all invested users rewards,invested amount,type,rate -s */
     function getregisteredusers() public view returns (address[] memory) {
      return registeredusers;
     }
    /* end -s */

    function ranking(address addr, uint value) private{
        uint index = getRankIndex();
        Invest storage invest;
        address tempAddr;
        uint tempValue;
        address origAddr = addr;
        for(uint i=0;i<rankMapArray[index].length;i++){
            invest = rankMapArray[index][i];
            if(addr==invest.addr) {
                invest.value = value;
                return;
            }else if(value > invest.value){
                tempAddr = invest.addr;
                tempValue = invest.value;
                invest.addr = addr;
                invest.value = value;
                if(origAddr == tempAddr) return;
                addr = tempAddr;
                value = tempValue;
            }
        }
    }

    function distributeRank(uint index) public{
        require(index >= 0 && index < getRankIndex() && !rankFlag[index], "Error index");
        rankFlag[index] = true;
        Invest[4] storage invests = rankMapArray[index];
        address payable addr;
        uint amount;
        uint distribute = rankPool.mul(15).div(100);
        for(uint i=0;i<invests.length;i++){
            addr = address(uint160(invests[i].addr));
            if(distribute <= 0 || addr==address(0)) break;
            amount = distribute.mul(rankPcts[i]).div(100);
            invests[i].reward = amount;
            invests[i].time = block.timestamp;
            addr.transfer(amount);
            emit Rank(addr, amount);
        }
        rankPool = rankPool.sub(distribute);
    }

    function distributeInsurance(uint length) public{
        require(sefetyTime > 0 && sefetyTime < block.timestamp, "Not end");
        address payable addr;
        uint amount;
        (,uint end) = insuranceRewardIndex.trySub(length);
        for(uint i=insuranceRewardIndex;i>end;i--){
            addr = address(uint160(insurances[i-1].addr));
            amount = insurances[i-1].value.mul(150).div(100);
            if(safetyPool <= 0 || addr==address(0) || amount <=0) break;
            amount = safetyPool.min(amount);
            safetyPool = safetyPool.sub(amount);
            insurances[i-1].reward = amount;
            addr.transfer(amount);
            emit Insurance(addr, amount);
            insuranceRewardIndex = i-1;
        }
    }

    // event test_value(Investment[] indexed value1);
    
    function bindRelationship(address referrer) private {
        // emit test_value(userMap[msg.sender].investments);
        
        if(referrer!=owner)
        {
            require(userMap[referrer].investment!=0, "Minimum investment 0.05 to generate Referreral");
        }
        
        if (userMap[msg.sender].active) return;
        userMap[msg.sender].active = true;
        if (referrer == msg.sender || !userMap[referrer].active) referrer = team;
        
        userMap[msg.sender].referrer = referrer;
        userMap[referrer].subordinates.push(msg.sender);
        for(uint i=0;i<3;i++){
            userMap[referrer].subNum++;
            referrer = userMap[referrer].referrer;
            if(!userMap[referrer].active) return;
        }
    }

    

   

  /* this help us to get the user investments all users you get from getregistered method then make a loop pass that address into this method and make total reward,total invest and subtract this from owner investment and you will get the real information like I shown in passive profit -s */
     
       function getUserInvestments(address userAddress) public view returns(
        uint[] memory times,uint[] memory starts, uint[] memory values, uint[] memory totalRewards,
        uint[] memory rates, uint[] memory typeNums, bool[] memory isReStakes, address[] memory referrer
    ){
        Investment[] memory investments = userMap[userAddress].investments;
        times = new uint[](investments.length);
        starts = new uint[](investments.length);
        values = new uint[](investments.length);
        totalRewards = new uint[](investments.length);
        rates = new uint[](investments.length);
        typeNums = new uint[](investments.length);
        isReStakes = new bool[](investments.length);
        referrer = new address[](investments.length);
        for (uint i = 0; i < investments.length; i++) {
            times[i] = investments[i].finish;
            starts[i] = investments[i].start;
            values[i] = investments[i].value;
            totalRewards[i] = investments[i].totalReward;
            rates[i] = investments[i].rate;
            typeNums[i] = investments[i].typeNum;
            isReStakes[i] = investments[i].isReStake;
            referrer[i] = investments[i].referrer;
        }
    }
      /* end */
     
    
    /* In this method you need to pass owner address to get owner total investment and rewards and subtract that from user total invest and rewads then get real informations -s */
     

    function getOwnerInvestments() public view returns(
        uint[] memory times,uint[] memory starts, uint[] memory values, uint[] memory totalRewards,
        uint[] memory rates, uint[] memory typeNums, bool[] memory isReStakes
    ){
        Investment[] memory investments = userMap[owner].investments;
        times = new uint[](investments.length);
        starts = new uint[](investments.length);
        values = new uint[](investments.length);
        totalRewards = new uint[](investments.length);
        rates = new uint[](investments.length);
        typeNums = new uint[](investments.length);
        isReStakes = new bool[](investments.length);
        for (uint i = 0; i < investments.length; i++) {
            times[i] = investments[i].finish;
            starts[i] = investments[i].start;
            values[i] = investments[i].value;
            totalRewards[i] = investments[i].totalReward;
            rates[i] = investments[i].rate;
            typeNums[i] = investments[i].typeNum;
            isReStakes[i] = investments[i].isReStake;
        }
    }
      /*  end  */
      
      /* Get uset details -s  */
      
       function getUserdetail(address userAddress)  public  view returns(
        bool[] memory active,address[] memory referrer,
        uint[] memory recommendReward,uint[] memory investment, uint[] memory totalWithdraw, uint[] memory totalReward
    ){
        User storage user = userMap[userAddress];
        active = new bool[](user.investments.length);
        referrer = new address[](user.investments.length);
        recommendReward = new uint[](user.investments.length);
        investment = new uint[](user.investments.length);
        totalWithdraw = new uint[](user.investments.length);
        totalReward = new uint[](user.investments.length);
        for (uint i = 0; i < user.investments.length; i++) {
            active[i] = user.active;
            referrer[i] = user.referrer;
            recommendReward[i] = user.recommendReward;
            investment[i] = user.investment;
            totalWithdraw[i] = user.totalWithdraw;
            totalReward[i] = user.totalReward;
        }
    }
     
    /*  end */ 
    
}