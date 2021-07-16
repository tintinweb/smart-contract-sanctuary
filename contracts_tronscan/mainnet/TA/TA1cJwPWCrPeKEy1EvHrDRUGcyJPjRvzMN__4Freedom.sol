//SourceUnit: 4FREEDOM.sol


/***
 *    ██╗  ██╗███████╗██████╗ ███████╗███████╗██████╗  ██████╗ ███╗   ███╗                                          
 *    ██║  ██║██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗██╔═══██╗████╗ ████║                                          
 *    ███████║█████╗  ██████╔╝█████╗  █████╗  ██║  ██║██║   ██║██╔████╔██║                                          
 *    ╚════██║██╔══╝  ██╔══██╗██╔══╝  ██╔══╝  ██║  ██║██║   ██║██║╚██╔╝██║                                          
 *         ██║██║     ██║  ██║███████╗███████╗██████╔╝╚██████╔╝██║ ╚═╝ ██║                                          
 *         ╚═╝╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝  ╚═════╝ ╚═╝     ╚═╝                                          
 *                                                                                                                                                           
 *                                                                                                                  
 *    ██ ███    ██ ██    ██ ██ ███████ ██████  ████████ ███████     ██    ██      ██████   █████  ███    ██  █████  
 *    ██ ████   ██ ██    ██ ██ ██      ██   ██    ██    ██           ██  ██      ██       ██   ██ ████   ██ ██   ██ 
 *    ██ ██ ██  ██ ██    ██ ██ █████   ██████     ██    █████         ████       ██   ███ ███████ ██ ██  ██ ███████ 
 *    ██ ██  ██ ██  ██  ██  ██ ██      ██   ██    ██    ██             ██        ██    ██ ██   ██ ██  ██ ██ ██   ██ 
 *    ██ ██   ████   ████   ██ ███████ ██   ██    ██    ███████        ██         ██████  ██   ██ ██   ████ ██   ██ 
 *                                                                                                                  
 * 
 *
 *     	4Freedom es un Contrato inteligente desarrollado por la Comunidad de TronFreedom, 
 *     	tiene condiciones que le permiten ser 100% Eterno, Rentable y Autosostenible. 
 *		
 *     	Únete a nuestra comunidad de Emprendedores y Aprende a Ganar Dinero de Manera Rápida, Fácil y Confiable.
 *      
 *     	Solicita más Información por nuestros Canales de Atención.
 *     	-Telegram: https://t.me/tronfreedom
 *     	-Facebook: https://www.facebook.com/clubtronfreedom/
 *      
 *      ****************
 *      * TRONFREEDOM  *
 *      ****************
 *
 * 		4Freedom is a smart Contract developed by the TronFreedom Community,
 * 		It has conditions that allow it to be 100% Eternal, Profitable and Self-sustaining.
 *
 * 		Join our community of Entrepreneurs and Learn to Earn Money in a Fast, Easy and Reliable Way.
 *
 * 		Request more information through our Service Channels.
 * 		-Telegram: https://t.me/tronfreedom
 * 		-Facebook: https://www.facebook.com/clubtronfreedom/
 *
 *
 */

pragma solidity ^0.4.25;

contract _4Freedom {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint public totalWithdrawn;
    uint private minDepositSize = 100E6;
    uint public devCommission = 10;
    uint public commissionDivisor = 100;
    uint256[] public REFERRAL_PERCENTS = [1000, 2000, 200,200,200,200,200];
    uint256 constant public PERCENTS_DIVIDER = 10000;
    
    uint256 public TIME_STEP=24 hours;
    uint256 public MAX_LIMIT=20;
    uint256 DevEarnings;
    address owner;
    struct Player {
        uint trxDeposit;
        uint time;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
        uint dividendEarning;
        address affFrom;
        uint referralEarnings;
        mapping(uint256=>uint256) referrals; 
        mapping(uint256=>uint256) referralEarningsL; 
        uint256 downlineInvestment;
        uint256 unsettled;
        
    }

    mapping(address => Player) public players;
    
    event Newbie(address indexed user, address indexed _referrer, uint _time);  
    event NewDeposit(address indexed user, uint256 amount, uint _time);  
    event Withdrawn(address indexed user, uint256 amount, uint _time);  
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount, uint _time);
  
    constructor(address _marketingAddr) public {
        owner = _marketingAddr;
        players[owner].time=block.timestamp;
                
    }

    function referralIncomeDist(address userAddress,uint256 _amount,bool isNew) private {
        Player storage player = players[userAddress];
        if (player.affFrom != address(0)) {

            address upline = player.affFrom;
            uint8 i = 0;
            for (i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    players[upline].affRewards = players[upline].affRewards.add(amount);
                    if(isNew){
                    players[upline].referrals[i]++;
                    }
                    players[upline].referralEarningsL[i]=players[upline].referralEarningsL[i].add(amount);
                    emit RefBonus(upline, msg.sender, i, amount,block.timestamp);
                    upline = players[upline].affFrom;
                } else break;
            }
            for(uint8 j=i;j< REFERRAL_PERCENTS.length;j++){
                 amount = _amount.mul(REFERRAL_PERCENTS[j]).div(PERCENTS_DIVIDER);
                DevEarnings=DevEarnings.add(amount);
            }
        }
    }

    function () external payable {}

    function deposit(address _affAddr) public payable {
    
        collect(msg.sender);
        require(msg.value >= minDepositSize, "not minimum amount!");
        
        uint depositAmount = msg.value;
        Player storage player = players[msg.sender];

        if (player.time == 0) {
           player.time = block.timestamp; 
            totalPlayers++;
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
                 emit Newbie(msg.sender, _affAddr, block.timestamp);
              player.affFrom = _affAddr;
            }
            else{
                emit Newbie(msg.sender, owner, block.timestamp);
              player.affFrom = owner;
           }
           referralIncomeDist(msg.sender,depositAmount,true);
        }
        else
        {
            referralIncomeDist(msg.sender,depositAmount,false);
        }
                
        player.trxDeposit = player.trxDeposit.add(depositAmount);        
        players[players[msg.sender].affFrom].downlineInvestment=players[players[msg.sender].affFrom].downlineInvestment.add(depositAmount);
        totalInvested = totalInvested.add(depositAmount);
        emit NewDeposit(msg.sender, depositAmount, block.timestamp); 
       
       DevEarnings = DevEarnings.add(depositAmount.mul(devCommission).div(commissionDivisor));
       
    }

    function withdraw() public {
        
        collect(msg.sender);
        uint256 ROIPercentage= getUserPercentRate(msg.sender);
        uint256 _amount=0;
        if(ROIPercentage>100)
        {
            require(players[msg.sender].interestProfit.add(players[msg.sender].affRewards).add(players[msg.sender].unsettled) > 0);
             _amount=players[msg.sender].interestProfit.add(players[msg.sender].affRewards.add(players[msg.sender].unsettled));
            transferPayout(msg.sender, _amount,true);
        }
        else{
            require(players[msg.sender].affRewards > 0);
             _amount=players[msg.sender].affRewards;
            transferPayout(msg.sender, _amount,false);
        }
        
        if(msg.sender==owner){
         owner.transfer(DevEarnings);
         players[msg.sender].referralEarnings=players[msg.sender].referralEarnings.add(DevEarnings);
         DevEarnings=0;
        }
    }

    function getUserPercentRate(address userAddress) public view returns(uint256){
        if(players[userAddress].downlineInvestment>=players[userAddress].trxDeposit.mul(10))
        {
            return 2000;
        }
        else if(players[userAddress].downlineInvestment>=players[userAddress].trxDeposit.mul(8))
        {
            return 1000;
        }
        else if(players[userAddress].downlineInvestment>=players[userAddress].trxDeposit.mul(4))
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
        uint secPassed = block.timestamp.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
          uint collectProfit=0;
      
          if (secPassed > 0) {
                collectProfit = (uint(player.trxDeposit).mul(ROIPercentage).div(PERCENTS_DIVIDER))
                    .mul(secPassed)
                    .div(TIME_STEP);
                     if (uint(player.dividendEarning).add(player.interestProfit).add(collectProfit) > uint(player.trxDeposit).mul(MAX_LIMIT).div(10)) {
                    collectProfit = (uint(player.trxDeposit).mul(MAX_LIMIT).div(10)).sub(uint(player.dividendEarning)).sub(player.interestProfit);
                }
            }
           
            player.interestProfit = player.interestProfit.add(collectProfit);
            
            player.time = player.time.add(secPassed);
        }
        
    }
    
    function transferPayout(address _receiver, uint _amount,bool isEligible) internal {

        uint contractBalance = address(this).balance;
        if (contractBalance > 0) {
            uint payout = _amount > contractBalance ? contractBalance : _amount;
            totalPayout = totalPayout.add(payout);
            
            Player storage player = players[_receiver];
            player.payoutSum = player.payoutSum.add(payout);
            player.referralEarnings=player.referralEarnings.add(player.affRewards);
            player.affRewards=0;
            
            if(isEligible){
                player.dividendEarning=player.dividendEarning.add(player.interestProfit);
                player.interestProfit = 0;
                
            }
            player.unsettled=_amount.sub(payout);
            msg.sender.transfer(payout);
            
            emit Withdrawn(msg.sender, payout, block.timestamp);
            totalWithdrawn=totalWithdrawn.add(payout);
            
        }
        
    }
    
    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);
        uint256 ROIPercentage= getUserPercentRate(msg.sender);
      uint secPassed = block.timestamp.sub(player.time);
      uint collectProfit=0;
      
      if (secPassed > 0) {
         
            collectProfit = (uint(player.trxDeposit).mul(ROIPercentage).div(PERCENTS_DIVIDER))
                .mul(secPassed)
                .div(TIME_STEP);
            if (uint(player.dividendEarning).add(player.interestProfit).add(collectProfit) > uint(player.trxDeposit).mul(MAX_LIMIT).div(10)) {
                    collectProfit = (uint(player.trxDeposit).mul(MAX_LIMIT).div(10)).sub(uint(player.dividendEarning)).sub(player.interestProfit);
                }
            
        }
      
      return collectProfit.add(player.interestProfit);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getReferralIncome(address userAddress) public view returns(uint256[] referrals,uint256[] referralEarnings){
      Player storage player = players[userAddress];
        uint256[] memory _referrals = new uint256[](REFERRAL_PERCENTS.length);
        uint256[] memory _referralearnings = new uint256[](REFERRAL_PERCENTS.length);
         for(uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
             _referrals[i]=player.referrals[i];
             _referralearnings[i]=player.referralEarningsL[i];
         }
        return (_referrals,_referralearnings);
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