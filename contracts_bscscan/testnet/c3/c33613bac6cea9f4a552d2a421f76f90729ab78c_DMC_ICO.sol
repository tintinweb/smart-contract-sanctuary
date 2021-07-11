/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-04
*/

pragma solidity 0.4.25;

contract DMC_ICO {
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
        uint256 dividends;
        uint256 match_bonus;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        uint256 bnb_invested;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }

   
    address public owner;
    address public stakingAddress;//?

    uint256 public invested;
    uint256 public token_order_recieved;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 public withdrawFee;
    uint256 public releaseTime = 1598104800;//1598104800

    uint8[] public ref_bonuses; 

    Tarif[] public tarifs;
    mapping(address => Player) public players;
    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(IBEP20 tokenAdd) public {
        owner = msg.sender;
        withdrawFee = 0;

        token = tokenAdd;

        //days , total return percentage//min invest
        tarifs.push(Tarif(180, 36,170000000000000)); //0.05 usd = 0.00017 BNB
        tarifs.push(Tarif(270, 72,170000000000000));
        tarifs.push(Tarif(360, 120,170000000000000)); 

        ref_bonuses.push(10);
        ref_bonuses.push(40);
        ref_bonuses.push(20);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(2);
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

            

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0)) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr].upline = _upline;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                players[_upline].structure[i]++;
                _upline = players[_upline].upline;
                
            }
        }
    }

    function deposit(uint8 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found"); // ??
        require(msg.value >= tarifs[_tarif].min_inv, "Less Then the min investment");
        require(now >= releaseTime, "not open yet");
        Player storage player = players[msg.sender];

        

        _setUpline(msg.sender, _upline);

      
        if(token_order_recieved < 2500000 * 10**8 )
        {
            //phase 1
            //token _rate  = 170000000000000   i.e 0.03 usd or 0.000095
            uint256 token_rate = 95000000000000;
            uint256 token_to_be_staked = msg.value.div(token_rate);
        }
        else if (token_order_recieved < 5000000 * 10**8)
        {
            //phase 2
            //token _rate  = 260000000000000   i.e 0.04 usd or 0.00013
             token_rate = 130000000000000;
             token_to_be_staked = msg.value.div(token_rate);

        }
         else if (token_order_recieved < 30000000 * 10**8)
        {
            //phase 3
            //token _rate  = 350000000000000   i.e 0.05 usd or 0.00016
             token_rate = 160000000000000;
             token_to_be_staked = msg.value.div(token_rate);

        }
          else if (token_order_recieved < 30000000 * 10**8)
        {
            //phase 4
            //token _rate  = 260000000000000   i.e 0.06 usd or 0.00019
             token_rate = 190000000000000;
             token_to_be_staked = msg.value.div(token_rate);

        }

        token_to_be_staked = token_to_be_staked * 100000000;

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: token_to_be_staked,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        token_order_recieved +=  token_to_be_staked;
        player.total_invested += token_to_be_staked;
        player.bnb_invested +=  msg.value;
        invested += msg.value;

        _refPayout(msg.sender, token_to_be_staked);

      

        emit NewDeposit(msg.sender, msg.value, _tarif);
    }

    function withdraw() payable external {
        
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0  || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus;

        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;


        token.transfer(msg.sender,amount);
       

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

    function ForLiquidity(uint256 amount) public{
        require(msg.sender==owner,'Permission denied');
        msg.sender.transfer(amount);
    }


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_bonus, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus,uint256[] memory structure) {
        Player storage player = players[_addr];

         uint256[] memory _structure = new uint256[](ref_bonuses.length);

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            _structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            _structure
        );
    }

  
    

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, withdrawn, match_bonus);
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