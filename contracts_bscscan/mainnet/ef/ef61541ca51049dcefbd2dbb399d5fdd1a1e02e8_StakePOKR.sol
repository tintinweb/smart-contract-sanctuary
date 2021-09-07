/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract StakePOKR {
    using SafeMath for uint;

    address payable public owner;
    IBEP20 public POKRtoken;

	address payable internal contract_;
    
    uint public invested;
    uint public burned;
    uint public earnings;
    uint public withdrawn;
    uint public reinvested;
    uint public direct_bonus;
    uint public match_bonus;
    uint public cashBack_bonus;
    
    uint public WithdrawalGap = 86400;
    
    uint public minDeposit = 1000000;
    uint public maxDeposit = 1000000000000000000000;
    
    
    uint public DailyRoi = 57871;        

    uint private stakeDisableTime = 1694275200;
    
    address payable private marketing1 = payable(msg.sender);
    address payable private marketing2 = payable(msg.sender);
    address payable private marketing3 = payable(msg.sender);
    address payable private marketing4 = payable(msg.sender);
    address payable private marketing5 = payable(msg.sender);
    address payable private marketing6 = payable(msg.sender);
    address payable private marketing7 = payable(msg.sender);
    address payable private marketing8 = payable(msg.sender);
    address payable private marketing9 = payable(msg.sender);
    address payable private marketing10 = payable(msg.sender);
    address payable private marketing11 = payable(msg.sender);
    address payable private marketing12 = payable(msg.sender);
    address payable private defaultref = payable(msg.sender);

  

    uint internal lastUid = 1;

    uint[] public match_bonus_;

    

    DataStructs.Plan[] public plans;

    mapping(address => DataStructs.Player) public players;

    mapping(uint => address) public getPlayerbyId;

    event ReferralBonus(address indexed addr, address indexed refBy, uint bonus);
    event NewDeposit(address indexed addr, uint amount);
    event MatchPayout(address indexed addr, address indexed from, uint amount);
    event Withdraw(address indexed addr, uint amount);

   
       constructor(address payable _owner, IBEP20 _token) {
       owner = _owner;
       POKRtoken = _token;
       contract_ = payable(msg.sender);
       
        match_bonus_.push(12); 
        match_bonus_.push(11); 
        match_bonus_.push(10); 
        match_bonus_.push(9); 
        match_bonus_.push(8); 
        match_bonus_.push(7); 
        match_bonus_.push(6); 
        match_bonus_.push(5); 
        match_bonus_.push(4); 
        match_bonus_.push(3); 
  }

    /**
     * Modifiers
     * */
    modifier hasDeposit(address _userId){
        require(players[_userId].deposits.length > 0);
        _;
    }
                                                                                              
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
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

                if(players[up].refscount[0].aff1sum >= 10)
            {    
            players[up].finances[0].available += _bonus;
            players[up].finances[0].total_match_bonus += _bonus;
            players[up].finances[0].total_earnings += _bonus;

            match_bonus += _bonus;
            earnings += _bonus;

            emit MatchPayout(up, _userId, _bonus); 
            }

            up = players[up].refBy;
        }
    }

  function _checkout(address _userId) private hasDeposit(_userId){
        DataStructs.Player storage player = players[_userId];
        if(player.deposits.length == 0) return;
        uint _minuteRate;
       
        uint _myEarnings;

        for(uint i = 0; i < player.deposits.length; i++){
            DataStructs.Deposit storage dep = player.deposits[i];
            uint secPassed = block.timestamp - dep.time;
            if (secPassed > 0) {
                _minuteRate = DailyRoi;
                 
                uint _gross = dep.amount.mul(secPassed).mul(_minuteRate).div(1e12);
                
                uint _max = dep.amount.mul(2);
                uint _releasednet = dep.earnings;
                uint _released = dep.earnings.add(_gross);
                
                if(_released < _max){
                    _myEarnings += _gross;
                    dep.earnings += _gross;
                    dep.time = block.timestamp;
                }
                
           else{
            uint256 collectProfit_net = _max.sub(_releasednet); 
             
             if (collectProfit_net > 0) {
             
             if(collectProfit_net <= _gross)
             {_myEarnings += collectProfit_net; 
             dep.earnings += collectProfit_net;
             dep.time = block.timestamp;
             }
             else{
             _myEarnings += _gross; 
             dep.earnings += _gross;
             dep.time = block.timestamp;}
             }
              else{
              _myEarnings += 0;
              dep.earnings += 0; 
              dep.time = block.timestamp;
              }
            }
                
}
        }
        
        player.finances[0].available += _myEarnings;
        player.finances[0].last_payout = block.timestamp;
        player.finances[0].total_earnings += _myEarnings;
        _matchingPayout(_userId, _myEarnings);
        
 }

       function _Register(address _addr, address _affAddr) private{

        
        address _refBy = _affAddr;

        DataStructs.Player storage player = players[_addr];

        player.refBy = _refBy;

        address _affAddr1 = _refBy;
        address _affAddr2 = players[_affAddr1].refBy;
        address _affAddr3 = players[_affAddr2].refBy;
        address _affAddr4 = players[_affAddr3].refBy;
        address _affAddr5 = players[_affAddr4].refBy;
        address _affAddr6 = players[_affAddr5].refBy;
        address _affAddr7 = players[_affAddr6].refBy;
       

        players[_affAddr1].refscount[0].aff1sum = players[_affAddr1].refscount[0].aff1sum.add(1);
        players[_affAddr2].refscount[0].aff2sum = players[_affAddr2].refscount[0].aff2sum.add(1);
        players[_affAddr3].refscount[0].aff3sum = players[_affAddr3].refscount[0].aff3sum.add(1);
        players[_affAddr4].refscount[0].aff4sum = players[_affAddr4].refscount[0].aff4sum.add(1);
        players[_affAddr5].refscount[0].aff5sum = players[_affAddr5].refscount[0].aff5sum.add(1);
        players[_affAddr6].refscount[0].aff6sum = players[_affAddr6].refscount[0].aff6sum.add(1);
        players[_affAddr7].refscount[0].aff7sum = players[_affAddr7].refscount[0].aff7sum.add(1);
        

        player.playerId = lastUid;
        getPlayerbyId[lastUid] = _addr;

        lastUid++;
    }


    /*
    * Only external call
    */

    receive() external payable{

    }
    
     function directDeposit(address  _refBy, uint _amount) external{ 
        require(block.timestamp <= stakeDisableTime, "Staking is disabled!");
        require(IBEP20(POKRtoken).transferFrom(msg.sender, address(this), _amount),'Failed_Transfer');
        deposit(_amount, payable(msg.sender), _refBy);
    }

    function deposit(uint _amount, address payable _userId, address _refBy) internal {
        IBEP20 _token = IBEP20(POKRtoken);
        IBEP20(POKRtoken).burn(address(this), _token.balanceOf(address(this)));
										  
        require(_amount >= minDeposit && _amount <= maxDeposit);

        DataStructs.Player storage player = players[_userId];

        
            if(player.finances[0].total_invested == 0){
            if(_refBy != address(0) && _refBy != _userId && players[_refBy].finances[0].total_invested > 0){
              _Register(_userId, _refBy);
            }
            else{
              _Register(_userId, defaultref);
            }
            }

        player.deposits.push(DataStructs.Deposit({
            
            amount: _amount,
            earnings: 0,
            time: uint(block.timestamp)
            }));

        player.finances[0].total_invested += _amount;
        invested += _amount;
        burned += _amount;
        
        player.finances[0].max_withdrawal = player.finances[0].total_invested.mul(2); 
        distributeRef(_amount, player.refBy);
        
        _checkout(_userId);


        
        uint marketingfee1 = _amount.mul(3).div(100);
        uint marketingfee2 = _amount.mul(2).div(100);
        uint marketingfee3 = _amount.mul(1).div(100);
       
        
        
        IBEP20(POKRtoken).mint(marketing1, marketingfee1);
        IBEP20(POKRtoken).mint(marketing2, marketingfee1);
        IBEP20(POKRtoken).mint(marketing3, marketingfee2);
        IBEP20(POKRtoken).mint(marketing4, marketingfee2);
        IBEP20(POKRtoken).mint(marketing5, marketingfee3);
        IBEP20(POKRtoken).mint(marketing6, marketingfee3);
        IBEP20(POKRtoken).mint(marketing7, marketingfee3);
        IBEP20(POKRtoken).mint(marketing8, marketingfee3);
        IBEP20(POKRtoken).mint(marketing9, marketingfee3);
        IBEP20(POKRtoken).mint(marketing10, marketingfee3);
        IBEP20(POKRtoken).mint(marketing11, marketingfee3);
        IBEP20(POKRtoken).mint(marketing12, marketingfee3);
        
        emit NewDeposit(_userId, _amount);
        
    }
    
    function distributeRef(uint256 _trx, address _affFrom) private{
 
        uint256 _allaff = (_trx.mul(15)).div(100);

        address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].refBy;
        address _affAddr3 = players[_affAddr2].refBy;
        address _affAddr4 = players[_affAddr3].refBy;
        address _affAddr5 = players[_affAddr4].refBy;
        address _affAddr6 = players[_affAddr5].refBy;
        address _affAddr7 = players[_affAddr6].refBy;
       
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(5)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].finances[0].available += _affRewards;
            players[_affAddr1].finances[0].total_cashback += _affRewards;
            players[_affAddr1].finances[0].total_earnings += _affRewards;

            direct_bonus += _affRewards;
            earnings += _affRewards;
            emit ReferralBonus(msg.sender, _affAddr1, _affRewards);
         }

        if (_affAddr2 != address(0)) {
        
        if(players[_affAddr2].refscount[0].aff1sum >= 2){
        
            _affRewards = (_trx.mul(4)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr2].finances[0].available += _affRewards;
            players[_affAddr2].finances[0].total_cashback += _affRewards;
            players[_affAddr2].finances[0].total_earnings += _affRewards;
            direct_bonus += _affRewards;
            earnings += _affRewards;
            emit ReferralBonus(msg.sender, _affAddr2, _affRewards);
          }
        }

        if (_affAddr3 != address(0)) {
         if(players[_affAddr3].refscount[0].aff1sum >= 3){
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].finances[0].available += _affRewards;
            players[_affAddr3].finances[0].total_cashback += _affRewards;
            players[_affAddr3].finances[0].total_earnings += _affRewards;
            direct_bonus += _affRewards;
            earnings += _affRewards;
            emit ReferralBonus(msg.sender, _affAddr3, _affRewards);
            } 
        }

        if (_affAddr4 != address(0)) {
         if(players[_affAddr4].refscount[0].aff1sum >= 4){
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr4].finances[0].available += _affRewards;
            players[_affAddr4].finances[0].total_cashback += _affRewards;
            players[_affAddr4].finances[0].total_earnings += _affRewards;
            direct_bonus += _affRewards;
            earnings += _affRewards;
            emit ReferralBonus(msg.sender, _affAddr4, _affRewards);
            }
        }

        if (_affAddr5 != address(0)) {
        
         if(players[_affAddr5].refscount[0].aff1sum >= 5){
         
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr5].finances[0].available += _affRewards;
            players[_affAddr5].finances[0].total_cashback += _affRewards;
            players[_affAddr5].finances[0].total_earnings += _affRewards;
            direct_bonus += _affRewards;
            earnings += _affRewards;
            emit ReferralBonus(msg.sender, _affAddr5, _affRewards);
            }
        }

        if (_affAddr6 != address(0)) {
        
         if(players[_affAddr6].refscount[0].aff1sum >= 6){
            _affRewards = (_trx.mul(1)).div(100);
           _allaff = _allaff.sub(_affRewards);
            players[_affAddr6].finances[0].available += _affRewards;
            players[_affAddr6].finances[0].total_cashback += _affRewards;
            players[_affAddr6].finances[0].total_earnings += _affRewards;
            direct_bonus += _affRewards;
            earnings += _affRewards;
            emit ReferralBonus(msg.sender, _affAddr6, _affRewards);
            }
        }

        if (_affAddr7 != address(0)) {
        
         if(players[_affAddr7].refscount[0].aff1sum >= 7){
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr7].finances[0].available += _affRewards;
            players[_affAddr7].finances[0].total_cashback += _affRewards;
            players[_affAddr7].finances[0].total_earnings += _affRewards;
            direct_bonus += _affRewards;
            earnings += _affRewards;
            emit ReferralBonus(msg.sender, _affAddr7, _affRewards);
            }
        }

     if(_allaff > 0 ){
            IBEP20(POKRtoken).mint(owner, _allaff);
        }
    }

        function withdraw() external hasDeposit(msg.sender){
        
        address payable _userId = payable(msg.sender);
        DataStructs.Player storage player = players[_userId];
        uint256 withdrawal_gap = block.timestamp - player.finances[0].withdrawal_time;
        
        require(withdrawal_gap >= WithdrawalGap); 
        uint allowed_withdrawal;
        uint amount;
        _checkout(_userId);

        if(player.finances[0].available <= player.finances[0].total_invested){
        allowed_withdrawal = player.finances[0].available;
        }else{
        allowed_withdrawal = player.finances[0].total_invested;   
        }
        
        uint allowed_gross = player.finances[0].total_withdrawn.add(allowed_withdrawal); 
        
        if(allowed_gross <= player.finances[0].max_withdrawal){
        amount = allowed_withdrawal;
        }else{
        amount = player.finances[0].max_withdrawal.sub(player.finances[0].total_withdrawn);
        }
        
        
        require(amount > 0, "Insufficient Balance!");

       

        player.finances[0].available -= amount;
        player.finances[0].total_withdrawn += amount;
        player.finances[0].withdrawal_time = block.timestamp; 
        withdrawn += amount;

        IBEP20(POKRtoken).mint(_userId, amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function reinvest() external hasDeposit(msg.sender){
        
        address _userId = msg.sender;
        _checkout(_userId);

        DataStructs.Player storage player = players[_userId];
        uint _amountavailable = player.finances[0].available;
        uint _amount = _amountavailable.div(5); // Only 20 percent will be reinvested
        //require(address(this).balance >= _amount);
        require(_amount > 0, "Insufficient Balance!");

        player.finances[0].available -= _amount;
        player.finances[0].total_invested += _amount;
        
        player.finances[0].total_reinvested += _amount;
        player.finances[0].max_withdrawal = player.finances[0].total_invested.mul(2); 
        invested += _amount;
       
        reinvested += _amount;
        
}

  function _getEarnings(address _userId) view external returns(uint) {

        DataStructs.Player storage player = players[_userId];
        if(player.deposits.length == 0) return 0;
        uint _minuteRate;
       
        uint _myEarnings;

        for(uint i = 0; i < player.deposits.length; i++){
            DataStructs.Deposit storage dep = player.deposits[i];
            uint secPassed = block.timestamp - dep.time;
            if (secPassed > 0) {
                _minuteRate = DailyRoi;
                
                uint _gross = dep.amount.mul(secPassed).mul(_minuteRate).div(1e12);
                
                uint _max = dep.amount.mul(2);
                uint _releasednet = dep.earnings;
                uint _released = dep.earnings.add(_gross);
                
                
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
        return player.finances[0].available.add(_myEarnings);
    }
    
    function BurnPOKR(uint _amount) external{ 
        require(IBEP20(POKRtoken).transferFrom(msg.sender, address(this), _amount),'Failed_Transfer');
        IBEP20 _token = IBEP20(POKRtoken);
        IBEP20(POKRtoken).burn(address(this), _token.balanceOf(address(this)));
    }

 

    function userInfo(address _userId) view external returns(uint for_withdraw, uint total_invested, uint total_withdrawn,
        uint total_match_bonus, uint total_cashback, uint withdrawal_time, uint aff1sum, address refby) {
        DataStructs.Player storage player = players[_userId];
        uint _myEarnings = this._getEarnings(_userId).add(player.finances[0].available);

        return (
        _myEarnings,
        player.finances[0].total_invested,
        player.finances[0].total_withdrawn,
        player.finances[0].total_match_bonus, 
        player.finances[0].total_cashback,
        player.finances[0].withdrawal_time,
        player.refscount[0].aff1sum,
        player.refBy);
}
    
    
    function RefInfo(address _userId) view external returns(uint aff1sum, uint aff2sum, uint aff3sum, uint aff4sum, uint aff5sum, uint aff6sum, uint aff7sum) {
        DataStructs.Player storage player = players[_userId];
        return (
        player.refscount[0].aff1sum,
        player.refscount[0].aff2sum,
        player.refscount[0].aff3sum,
        player.refscount[0].aff4sum,
        player.refscount[0].aff5sum,
        player.refscount[0].aff6sum,
        player.refscount[0].aff7sum);
    }

    function contractInfo() view external returns(uint, uint, uint, uint, uint, uint, uint, uint) {
        return (invested, withdrawn, earnings.add(withdrawn), direct_bonus, match_bonus, lastUid, cashBack_bonus, burned);
    }
    
    /**
     * Restrictied functions
     * */

	function setOwner(address payable _owner) external onlyOwner()  returns(bool){
        owner = _owner;
        return true;
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
    
           function updateMarketing9(address payable _address) public {
       require(msg.sender==owner);
       marketing9 = _address;
    }
    
           function updateMarketing10(address payable _address) public {
       require(msg.sender==owner);
       marketing10 = _address;
    }
    
           function updateMarketing11(address payable _address) public {
       require(msg.sender==owner);
       marketing11 = _address;
    }
    
           function updateMarketing12(address payable _address) public {
       require(msg.sender==owner);
       marketing12 = _address;
    }
    
        function updateDefaultref(address payable _address) public {
       require(msg.sender==owner);
       defaultref = _address;
    }
    
       function setDailyRoi(uint256 _DailyRoi) public {
      require(msg.sender==owner);
      DailyRoi = _DailyRoi;
    } 
    
      function setMinDeposit(uint256 _MinDeposit) public {
      require(msg.sender==owner);
      minDeposit = _MinDeposit;
    }     
}

contract StakePOKR_{

    struct Deposit {
        //uint planId;
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
        uint total_cashback; // used for refcommission
        uint total_invested;
        uint last_payout;
        uint total_withdrawn;
        uint total_reinvested;
        uint max_withdrawal;
        uint withdrawal_time;
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
        //uint planId;
        uint amount;
        uint earnings; 
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
}

   
     struct Finances{
        uint available;
        uint total_earnings;
        uint total_direct_bonus;
        uint total_match_bonus;
        uint total_cashback; 
        uint total_invested;
        uint last_payout;
        uint total_withdrawn;
        uint total_reinvested;
        uint withdrawal_time;
        uint max_withdrawal;
    }

    struct Player {
        uint playerId;
        address refBy;
        Finances[1] finances;
        Deposit[] deposits;
        RefsCount[1] refscount;
        
    }
}
interface IBEP20 {

    function balanceOf(address tokenOwner) external pure returns (uint balance);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
    
    function mint(address account, uint256 amount) external;
    
    function burn(address account, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}