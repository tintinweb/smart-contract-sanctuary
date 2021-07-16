//SourceUnit: tronfreedomroi.sol

pragma solidity ^0.4.25;

contract ExtremeFreedom {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint private minDepositSize = 100E6;
    uint public devCommission = 10;
    uint public commissionDivisor = 100;
    uint256[] public REFERRAL_PERCENTS = [300,500,100,100];
    uint256 constant public PERCENTS_DIVIDER = 10000;
    
    uint256 public TIME_STEP=24 hours;
    uint256 public MAX_LIMIT=15;
    uint256 public MAX_LIMIT_REF=20;
    uint256 DevEarnings;
    address owner;
    address  public tronfreedom;
    uint public TRX_FOR_ONE_USD=1;
    address marketingaddress;
    
    struct Player {
        uint trxDeposit;
        uint dollorDeposit;
        uint reinvested;
        uint interestProfit;
        address affFrom;
        uint256 downlineInvestment;
        uint instantEarning;
         Deposit[] deposits;
    }
    
    struct TotalEarnings
    {
        uint dividendEarning;
        uint affRewards;
        uint payoutSum;
        uint referralEarnings;
        mapping(uint256=>uint256) referrals; 
        mapping(uint256=>uint256) referralEarningsL; 
    }
    
     struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
        uint256 amountintrx;
        uint256 checkpoint;
        bool status;
        bool isReinvest;
    }

    mapping(address => Player) public players;
    mapping(address=>TotalEarnings) public totalEarningsplayer;
    
    event Newbie(address indexed user, address indexed _referrer, uint _time);  
    event NewDeposit(address indexed user, uint256 amount, uint _time);  
    event Reinvest(address indexed user, uint256 amount, uint _time);  
    event Withdrawn(address indexed user, uint256 amount, uint _time);  
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount, uint _time);
    
  
    constructor(address _ownerAddr,address _pricesetter,address _marketingaddress) public {
        owner = _ownerAddr;
        tronfreedom=_pricesetter;
        marketingaddress=_marketingaddress;
        players[owner].affFrom=_ownerAddr;
    }

  
   function referralIncomeDist(address userAddress,uint256 _amount,bool isNew) private {
        Player storage player = players[userAddress];
        if (player.affFrom != address(0)) {

            address upline = player.affFrom;
            uint8 i = 0;
            for (i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    totalEarningsplayer[upline].affRewards = totalEarningsplayer[upline].affRewards.add(amount);
                    if(isNew){
                    totalEarningsplayer[upline].referrals[i]++;
                    }
                    totalEarningsplayer[upline].referralEarningsL[i]=totalEarningsplayer[upline].referralEarningsL[i].add(amount);
                    emit RefBonus(upline, msg.sender, i, amount,block.timestamp);
                    upline = players[upline].affFrom;
                } else break;
            }
           
        }
    }



    function () external payable {}

    function deposit(address _affAddr) public payable {
    
        uint256 amountinusd=changeAmountTRXtoUSD(msg.value);
        require(amountinusd>=50, "not minimum amount");
        
        uint depositAmount = msg.value;
        Player storage player = players[msg.sender];

        
        if (player.affFrom == address(0)) {
            totalPlayers++;
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
              player.affFrom = _affAddr;
            }
            else{
               
              player.affFrom = owner;
           }
           emit Newbie(msg.sender, player.affFrom, block.timestamp);
           
           referralIncomeDist(msg.sender,amountinusd,true);
        }
        else
        {
           referralIncomeDist(msg.sender,amountinusd,false);
        }
       
                player.dollorDeposit = player.dollorDeposit.add(amountinusd);
        player.trxDeposit = player.trxDeposit.add(depositAmount);   
        player.instantEarning= player.instantEarning.add(amountinusd.mul(20).div(100));
        
        players[players[msg.sender].affFrom].downlineInvestment=players[players[msg.sender].affFrom].downlineInvestment.add(amountinusd);
        players[msg.sender].deposits.push(Deposit(amountinusd, 0, now,depositAmount,now,true,false));
        owner.transfer(msg.value.mul(5).div(100));
        marketingaddress.transfer(msg.value.mul(5).div(100));
        emit NewDeposit(msg.sender, depositAmount, block.timestamp); 
       
       DevEarnings = DevEarnings.add(depositAmount.mul(devCommission).div(commissionDivisor));
       
    }
    
    //1 for referral, 2 for roi,3 for instantearnings
    function reinvest(uint256 _reinvestType) public
    {
        require(_reinvestType==1 || _reinvestType==2 || _reinvestType==3,"Invalid param");
        Player storage player = players[msg.sender];
        uint256 depositAmount=0;
        if(_reinvestType==1)
        {
            require(totalEarningsplayer[msg.sender].affRewards>=50,"Insufficient amount");
            depositAmount=totalEarningsplayer[msg.sender].affRewards;
            
            totalEarningsplayer[msg.sender].affRewards=0;
        }
        else if(_reinvestType==2)
        {
            collect(msg.sender);
            require(players[msg.sender].interestProfit>=50,"Insufficient amount");
            depositAmount=players[msg.sender].interestProfit;
            player.interestProfit=0;
        }
        else if(_reinvestType==3)
        {
            require(player.instantEarning>=50,"Insufficient amount");
            depositAmount=player.instantEarning;
            player.instantEarning=0;
        }
       uint256 trxamount=changeAmountUSDtoTRX(depositAmount).div(100);
        player.trxDeposit = player.trxDeposit.add(trxamount); 
        player.dollorDeposit=player.dollorDeposit.add(depositAmount);
         player.reinvested=player.reinvested.add(depositAmount);
        players[players[msg.sender].affFrom].downlineInvestment=players[players[msg.sender].affFrom].downlineInvestment.add(player.dollorDeposit);
        players[msg.sender].deposits.push(Deposit(depositAmount, 0, now,trxamount,now,true,true));
     
        
         player.instantEarning= player.instantEarning.add(depositAmount.mul(20).div(100));
         referralIncomeDist(msg.sender,depositAmount,false);
        owner.transfer(trxamount.mul(5).div(100));
        marketingaddress.transfer(trxamount.mul(5).div(100));
        emit Reinvest(msg.sender, depositAmount, block.timestamp); 
       
       DevEarnings = DevEarnings.add(depositAmount.mul(devCommission).div(commissionDivisor));
        
    }

    function withdraw() public {
        
        collect(msg.sender);
      
        require(players[msg.sender].interestProfit > 0);
        transferPayout(msg.sender, players[msg.sender].interestProfit);
        
       
        
        
    }
    
  
     
     function withdrawinstantEarning() public
    {
        require(players[msg.sender].instantEarning>0,"Dont have any earnings");
        msg.sender.transfer(changeAmountUSDtoTRX(players[msg.sender].instantEarning).div(100));
        totalEarningsplayer[msg.sender].payoutSum=totalEarningsplayer[msg.sender].payoutSum.add(players[msg.sender].instantEarning);
        emit Withdrawn(msg.sender, players[msg.sender].instantEarning, block.timestamp);
        players[msg.sender].instantEarning=0;
    }
    
    function withdrawOnlyReferral() public
    {
        require(totalEarningsplayer[msg.sender].affRewards>0,"Dont have any earnings");
        msg.sender.transfer(changeAmountUSDtoTRX(totalEarningsplayer[msg.sender].affRewards).div(100));
        totalEarningsplayer[msg.sender].referralEarnings=totalEarningsplayer[msg.sender].referralEarnings.add(totalEarningsplayer[msg.sender].affRewards);
        totalEarningsplayer[msg.sender].payoutSum=totalEarningsplayer[msg.sender].payoutSum.add(totalEarningsplayer[msg.sender].affRewards);
        emit Withdrawn(msg.sender, totalEarningsplayer[msg.sender].affRewards, block.timestamp);
            totalEarningsplayer[msg.sender].affRewards=0;
        
    }

    function getUserPercentRate(address userAddress) public view returns(uint256){
     
        if(players[userAddress].downlineInvestment>=players[userAddress].dollorDeposit.mul(3))
        {
            return 500;       
        }
        else 
        {
            return 100;
        }
    }
       
    function collect(address _addr) internal {
        Player storage player = players[_addr];
        uint256 ROIPercentage= getUserPercentRate(msg.sender);
        uint256 totalAmount;
        uint256 dividends;
        uint256 maxlimit=15;
        if(ROIPercentage>100)
        {
            maxlimit=20;
        }
        for (uint256 i = 0; i < player.deposits.length; i++) {

            if (player.deposits[i].status && player.deposits[i].withdrawn < player.deposits[i].amount.mul(maxlimit).div(10) && 
            (ROIPercentage==500 || (ROIPercentage==100 && now>player.deposits[i].checkpoint.add(TIME_STEP.mul(150)))))
            {

                if (player.deposits[i].start > player.deposits[i].checkpoint) {

                    dividends = (player.deposits[i].amount.mul(ROIPercentage).div(PERCENTS_DIVIDER))
                        .mul(now.sub(player.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (player.deposits[i].amount.mul(ROIPercentage).div(PERCENTS_DIVIDER))
                        .mul(now.sub(player.deposits[i].checkpoint))
                        .div(TIME_STEP);
                }

                if (player.deposits[i].withdrawn.add(dividends) > player.deposits[i].amount.mul(maxlimit).div(10)) {
                    dividends = (player.deposits[i].amount.mul(maxlimit).div(10)).sub(player.deposits[i].withdrawn);
                    player.deposits[i].status=false;
                }

                player.deposits[i].withdrawn = player.deposits[i].withdrawn.add(dividends); /// changing of storage data
                player.deposits[i].checkpoint=now;
                
                totalAmount = totalAmount.add(dividends);

            }
        }
        player.interestProfit = player.interestProfit.add(totalAmount);
            
            }
    
    
    
    function transferPayout(address _receiver, uint _amount) internal {
        uint contractBalance = changeAmountUSDtoTRX(_amount).div(100);
        require (address(this).balance>=contractBalance,"contract balance is low");
        
            totalPayout = totalPayout.add(_amount);
            
            Player storage player = players[_receiver];
            totalEarningsplayer[_receiver].payoutSum = totalEarningsplayer[_receiver].payoutSum.add(_amount);
          
            totalEarningsplayer[_receiver].dividendEarning=totalEarningsplayer[_receiver].dividendEarning.add(player.interestProfit);
            player.interestProfit = 0;
                
            uint trxToSend=changeAmountUSDtoTRX(_amount).div(100);
            msg.sender.transfer(trxToSend);
            
            emit Withdrawn(msg.sender, _amount, block.timestamp);
         
        
    }
    
    function getProfit(address _addr) public view returns (uint) {
    Player storage player = players[_addr];
        uint256 ROIPercentage= getUserPercentRate(msg.sender);
        uint256 totalAmount;
        uint256 dividends;
        uint256 maxlimit=20;
        if(ROIPercentage==100){
        maxlimit=15;
        }
        for (uint256 i = 0; i < player.deposits.length; i++) {

            if (player.deposits[i].status && player.deposits[i].withdrawn < player.deposits[i].amount.mul(maxlimit).div(10)) {

                if (player.deposits[i].start > player.deposits[i].checkpoint) {

                    dividends = (player.deposits[i].amount.mul(1 trx).mul(ROIPercentage).div(PERCENTS_DIVIDER))
                        .mul(now.sub(player.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (player.deposits[i].amount.mul(1 trx).mul(ROIPercentage).div(PERCENTS_DIVIDER))
                        .mul(now.sub(player.deposits[i].checkpoint))
                        .div(TIME_STEP);
                }

                 if(player.deposits[i].withdrawn.mul(1 trx).add(dividends) > player.deposits[i].amount.mul(1 trx).mul(maxlimit).div(10)) {
                    dividends = (player.deposits[i].amount.mul(1 trx).mul(maxlimit).div(10)).sub(player.deposits[i].withdrawn.mul(1 trx));
                    
                }

                totalAmount = totalAmount.add(dividends);

            }
        }
        return player.interestProfit.add(totalAmount);
            
           
    }
    
    
     function getReferralIncome(address userAddress) public view returns(uint256[] referrals,uint256[] referralEarnings){
        uint256[] memory _referrals = new uint256[](REFERRAL_PERCENTS.length);
        uint256[] memory _referralearnings = new uint256[](REFERRAL_PERCENTS.length);
         for(uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
             _referrals[i]=totalEarningsplayer[userAddress].referrals[i];
             _referralearnings[i]=totalEarningsplayer[userAddress].referralEarningsL[i];
         }
        return (_referrals,_referralearnings);
    }  
    
    function getUserTotalDeposits(address userAddress) public view returns(uint256 _amountinusd,uint256 _amountintrx) {
        Player storage player = players[userAddress];

        uint256 amount;
        uint256 amountinusd;

        for (uint256 i = 0; i < player.deposits.length; i++) {
            if (player.deposits[i].withdrawn < player.deposits[i].amount.mul(2)) {

            amount = amount.add(player.deposits[i].amount);
            amountinusd=amountinusd.add(player.deposits[i].amountintrx);
            }
        }

        return (amount,amountinusd);
    }
    
    
    function investmentsInfo(address _addr) view external returns(uint256[] memory amounts, bool[] memory status, uint256[] memory startTimes, uint256[] memory totalWithdraws,bool[] _isReinvests) {
        Player storage player = players[_addr];

        uint256[] memory _amounts = new uint256[](player.deposits.length);
        bool[] memory _status = new bool[](player.deposits.length);
        uint256[] memory _startTimes = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);
         bool[] memory _isReinvest = new bool[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          Deposit storage dep = player.deposits[i];
        
          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.withdrawn;
          _startTimes[i] = dep.start;
          _status[i] = dep.status;
          _isReinvest[i]=dep.isReinvest;
        }

        return (
          _amounts,
          _status,
          _startTimes,
          _totalWithdraws,
          _isReinvest
        );
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
      function exchangeratefortrx(uint amountperusd) public {
        require(msg.sender==tronfreedom,"Invalid address");
        TRX_FOR_ONE_USD=amountperusd;
    }
    
    function changeAmountUSDtoTRX(uint256 amount) public view returns(uint256){ //return amount in trx
        return (amount*1 trx*TRX_FOR_ONE_USD).div(100);
    }
    
      function changeAmountTRXtoUSD(uint256 amount) public view returns(uint256){   //return amount in usd
        return amount.mul(100).div(TRX_FOR_ONE_USD).div(PERCENTS_DIVIDER);
    }
  
    
    
    
}


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}