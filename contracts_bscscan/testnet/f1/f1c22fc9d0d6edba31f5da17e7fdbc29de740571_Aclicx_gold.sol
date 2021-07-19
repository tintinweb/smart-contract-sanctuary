/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity 0.4.25;
contract Aclicx_gold {
    using SafeMath for uint256;
     IBEP20 public token;
     
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
        uint256 j_time;
        uint256 dividends;
        uint256 match_bonus;
        uint256 last_payout;
        uint256 gi_bonus;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }

    address public owner;
    uint256[] public GI_PERCENT = [100, 50, 50,50, 50,50, 50,50, 50,50, 50,50, 50,50, 50,50, 50,100];
    uint256 public invested;
    uint256 public gi_bonus;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 public withdrawFee;
    uint256 public releaseTime = 1598104800;//1598104800
    uint8[] public ref_bonuses; // 1 => 1%
    uint256 aclicx_rate = 5; // 5$

    Tarif[] public tarifs;
    mapping(address => Player) public players;
    mapping(address => bool) public whiteListed;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(IBEP20 tokenAdd) public {
        owner = msg.sender;
        token = tokenAdd;
        whiteListed[owner] = true;

        //days , total return percentage//min invest
        tarifs.push(Tarif(400, 200,100));  //0.5% for 400 days  = 200%
        tarifs.push(Tarif(400, 240,500)); //0.6% for 400 days  = 240%
        tarifs.push(Tarif(400, 280,1000)); //0.7% for 400 days  = 280%
        tarifs.push(Tarif(400, 333, 25000)); //0.83% for 400 days  = 333%
        tarifs.push(Tarif(400, 400, 5000)); //1% for 400 days  = 400%
    

        ref_bonuses.push(50);
        ref_bonuses.push(40);
        ref_bonuses.push(30);
        ref_bonuses.push(20);
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

    function _setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0)) {//first time entry
            if(players[_upline].deposits.length == 0) {//no deposite from my upline
                _upline = owner;
            }
            players[_addr].upline = _upline;
            for(uint8 i = 0; i < GI_PERCENT.length; i++) {
                players[_upline].structure[i]++;
                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }

    function deposit(uint8 _tarif, address _upline, uint256 token_quantity) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found"); // ??
       uint256 token_value_in_USD = token_quantity.mul(aclicx_rate);
        require(token_value_in_USD >= tarifs[_tarif].min_inv, "Less Then the min investment");
        require(now >= releaseTime, "not open yet");
        Player storage player = players[msg.sender];

        _setUpline(msg.sender, _upline);
        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: token_value_in_USD,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

       

        player.total_invested += token_value_in_USD;
        player.j_time =  uint256(block.timestamp);
        invested += token_value_in_USD;

        _refPayout(msg.sender, token_value_in_USD);

      //  owner.transfer(token_value_in_USD.mul(10).div(100));
        emit NewDeposit(msg.sender, token_value_in_USD, _tarif);
    }

    function withdraw() payable external {
       

        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0 || player.gi_bonus > 0, "Zero amount");


        uint256 amount = player.dividends + player.match_bonus + gi_bonus;

       

        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        

        _send_gi(msg.sender,player.dividends);
       // msg.sender.transfer(amount);
         token.transfer(msg.sender,amount);

        emit Withdraw(msg.sender, amount);
    }


    function _send_gi(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < GI_PERCENT.length; i++) {
            if(up == address(0)) break;

           if(players[up].structure[i] >players[up].structure[i]+1)
           {
               if(players[up].j_time + 200 days < uint256(block.timestamp))
               {
                    uint256 bonus = _amount * ref_bonuses[i] / 1000;

                    players[up].gi_bonus += bonus;
                    players[up].gi_bonus += bonus;

                    gi_bonus += bonus;
                    up = players[up].upline;
               }
                
           }
            
        }
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
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_bonus, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

      structure = new uint256[](GI_PERCENT.length);

        for(uint8 i = 0; i < GI_PERCENT.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }

    

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn,uint256 _match_bonus) {
        return (invested, withdrawn,match_bonus);
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
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}