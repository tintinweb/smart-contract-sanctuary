//SourceUnit: tronspot.sol

pragma solidity ^0.4.25;


contract Tronspot {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize = 100000000; //100trx
    uint private interestRateDivisor = 10000;
    uint public devCommission = 1;
    uint public commissionDivisor = 100;
    address public insuranceContractAddress;
    
    address private feed1;
    address private feed2;
    
    uint256[] public REFERRAL_PERCENTS = [500,300,100,50,50];
    uint256 constant public PERCENTS_DIVIDER = 10000;
    uint256 public pool_balance;
    uint256 public BASE_PRCENT=100;
    uint256 public TIME_STEP=1 days;
    bool public setAddressFlag= false;
    
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    uint256 public pool_cycle;
    uint256 public pool_last_draw = uint256(block.timestamp);
    address public pool_top;
	
	
    address owner;
    struct Player {
        uint trxDeposit;
        uint time;
        uint interestProfit;
        mapping(uint => uint) refferalCount;
        uint affRewards;
        uint payoutSum;
        address affFrom;
        uint unSetteled;
        uint interestUnSetteled;
        uint lastDeposit;
        uint totalInvested;
        uint pool_Bonus;
        uint totalInterestProfit;
    }

    mapping(address => Player) public players;
    
    event Newbie(address indexed user, address indexed _referrer, uint _time);  
	event NewDeposit(address indexed user, uint256 amount, uint _time);  
	event Withdrawn(address indexed user, uint256 amount, uint _time);  
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount, uint _time);
	event PoolPayout(address indexed addr, uint256 amount);
	
    

    constructor(address _marketingAddr,address _adminfee,address _owneraddress) public {

		feed1 = _adminfee;
		feed2 = _marketingAddr;
		owner = _owneraddress;
	
	}
	
     function () external payable {
     }

    function register(address _addr, address _affAddr) private{
        Player storage player = players[_addr];
      
    if(player.affFrom == address(0) && players[_affAddr].trxDeposit > 0 && _affAddr != msg.sender) {	
        
        player.affFrom = _affAddr;
        
		}
     
    }
    
  
  function getReferralIncome(address userAddress) public view returns(uint256[] referrals){
      Player storage player = players[userAddress];
        uint256[] memory _referrals = new uint256[](REFERRAL_PERCENTS.length);
         for(uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
             _referrals[i]=player.refferalCount[i];
         }
        return (_referrals);
    }


    function deposit(address _affAddr) public payable {
        collect(msg.sender);
        require(msg.value >= minDepositSize, "not minimum amount!");

        uint depositAmount = msg.value;

        Player storage player = players[msg.sender];
        bool isNew= false;
        
        if (player.time == 0) {
            isNew=true;
            totalPlayers++;
               player.time = now; 
        
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
                 emit Newbie(msg.sender, _affAddr, now);
              register(msg.sender, _affAddr);
              
            }
            else{
                emit Newbie(msg.sender, owner, now);
              register(msg.sender, owner);
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        player.lastDeposit=depositAmount;
        players[msg.sender].totalInvested = players[msg.sender].totalInvested.add(msg.value);
        
        
        _pollDeposits(msg.sender, depositAmount);
        
         if(pool_last_draw.add(1 days) < block.timestamp) {
            _drawPool();
        }
        
        distributeRef(msg.value, msg.sender,isNew);
        totalInvested = totalInvested.add(depositAmount);
        emit NewDeposit(msg.sender, depositAmount, now); 
        uint feedtrx1 =  depositAmount.mul(devCommission).mul(8).div(commissionDivisor);
        uint feedtrx2 =  depositAmount.mul(devCommission).mul(2).div(commissionDivisor);
        feed1.transfer(feedtrx1);
        feed2.transfer(feedtrx2);
        insuranceContractAddress.transfer(depositAmount.mul(devCommission).mul(3).div(commissionDivisor));
    }

  function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;
        
         if(pool_top == address(0)){
           
         } 
         else{
             players[pool_top].pool_Bonus = players[pool_top].pool_Bonus.add(pool_balance);
             emit PoolPayout(pool_top, pool_balance);
         }
         
          pool_top = address(0);
          pool_balance =0;
          
    }
    


       function _pollDeposits(address _addr, uint256 _amount) private {
        
        pool_balance =  pool_balance.add((_amount).div(100));

        address upline = players[_addr].affFrom;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] = pool_users_refs_deposits_sum[pool_cycle][upline].add(_amount);
        
        if(pool_top == upline){
            
        }
        else if(pool_top == address(0)) {
                pool_top = upline;
        }
        else
        {
            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top]) {
                pool_top = upline;
            }
        }
    }
    
    function withdraw() public {
            collect(msg.sender);
            transferPayout(msg.sender, players[msg.sender].interestProfit);
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        
    	uint256 vel = getContractBalanceRate();
	
        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
            uint collectProfit = (player.trxDeposit.mul(secPassed.mul(vel))).div(TIME_STEP).div(interestRateDivisor);
            player.interestProfit = player.interestProfit.add(collectProfit);
            if (player.interestProfit.add(player.totalInterestProfit) >= player.trxDeposit.mul(210).div(100)){
                player.interestProfit = player.trxDeposit.mul(210).div(100).sub(player.totalInterestProfit);
            }
          
            player.time = player.time.add(secPassed);
        }
    }

    function transferPayout(address _receiver, uint _amount) internal {
        if (_receiver != address(0)) {
            uint subIntAmt=_amount;
            Player storage player = players[_receiver];
            _amount=player.affRewards.add(_amount).add(player.unSetteled);
            _amount=_amount.add(player.pool_Bonus);//pool top amount
             player.pool_Bonus= 0;
            
          uint contractBalance = address(this).balance;
          
            if (contractBalance > 0 && _amount > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
               
                player.totalInterestProfit = player.totalInterestProfit.add(subIntAmt);
                
                if(subIntAmt>contractBalance){
                    player.interestUnSetteled=  player.interestUnSetteled.add(subIntAmt).sub(contractBalance);
                }
                
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = 0;
               
                player.affRewards=0;
                player.unSetteled=_amount.sub(payout);
               
                msg.sender.transfer(payout);
                emit Withdrawn(msg.sender, payout, now);
            }
        }
    }
    
    
      function updatePayout(address _receiver, uint _amount) external {
          
          require(msg.sender == insuranceContractAddress,"Invalid transaction");
          
        if (_amount > 0 && _receiver != address(0)) {
                Player storage player = players[_receiver];
            
                totalPayout = totalPayout.add(_amount);
                
                player.payoutSum = player.payoutSum.add(_amount);
                player.totalInterestProfit = player.totalInterestProfit.add(_amount).sub(player.interestUnSetteled);
              
                player.interestProfit = 0;
                
                 if(_amount <= player.unSetteled){
                   player.unSetteled=player.unSetteled.sub(_amount);
                 }
                if(_amount <= player.interestUnSetteled){
                   player.interestUnSetteled=player.interestUnSetteled.sub(_amount);
                }
                
                uint secPassed = now.sub(player.time);
                
        if (secPassed > 0 && player.time > 0) {
            player.time = player.time.add(secPassed);
        }
             
        }
    }

    function distributeRef(uint256 _trx, address _affFrom,bool isNew) private{
        Player storage player = players[_affFrom];
       if (player.affFrom != address(0)) {

			address upline = player.affFrom;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
				if (upline != address(0)) {
					uint256 amount = _trx.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					
					players[upline].affRewards = players[upline].affRewards.add(amount);
					
					if(isNew == true){
					    	players[upline].refferalCount[i]++;
					}
					
					emit RefBonus(upline, msg.sender, i, amount,now);
					upline = players[upline].affFrom;
				} else break;
			}
		}
    }

    function getProfit(address _addr) external view returns (uint) {
      
      Player storage player = players[_addr];
      require(player.time > 0);
      
      uint secPassed = now.sub(player.time);
      
 	  uint256 vel = getContractBalanceRate();
	
        
      if (secPassed>0){
        uint collectProfit = (player.trxDeposit.mul(secPassed.mul(vel))).div(TIME_STEP).div(interestRateDivisor);
      }
      
      if (collectProfit.add(player.interestProfit).add(player.totalInterestProfit) >= player.trxDeposit.mul(210).div(100)){
               return player.trxDeposit.mul(210).div(100).sub(player.totalInterestProfit).add(player.interestUnSetteled);
            }
        else{
      return collectProfit.add(player.interestProfit).add(player.interestUnSetteled);
        }
    
    }
    
     function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
	
		uint256 contractBalancePercent = contractBalance.div(2000000000000);
		return BASE_PRCENT.add(contractBalancePercent);
		
	}
    
      function userInfoTotals(address _addr) view external returns( uint256 total_deposits, uint256 total_payouts,uint aff_rewards,uint256 pool_Bonus,address pool_topsponser,uint256 unSetteled,uint256 interestUnSetteled) {
        return (players[_addr].trxDeposit,players[_addr].payoutSum,players[_addr].affRewards,players[_addr].pool_Bonus,pool_top,players[_addr].unSetteled,players[_addr].interestUnSetteled);
    }

      function userInfo(address _addr) view external returns(address aff_from,uint256 last_deposit) {
        return (players[_addr].affFrom,players[_addr].lastDeposit);
    }
    
      function contractTotals() view external returns(uint256 total_users) {
        return (totalPlayers);
    }
    
    function setAddress(address _insuranceAddr) public {
            require(setAddressFlag == false, "Insurance address already set");
            require(msg.sender==owner,"only owner can set address");
            	insuranceContractAddress=_insuranceAddr;
        	setAddressFlag=true;
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