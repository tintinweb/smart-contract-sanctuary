//SourceUnit: TVL_MainContract.sol

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

interface TokenContract {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address owner, address spender) external  view returns (uint256 remaining);
    function transfer(address recipient, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external  returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool success);
    function mintByStaking(uint256 tokens) external returns (bool success);
}

contract TotalValueLocked_Staking{
    using SafeMath for uint256;
    address public tokenContractAddress;	
    struct Plan {
        uint256 life_days;
        uint256 percentage;
    }

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

    address public owner;
	
    uint256 public invested; 
    uint256 public withdrawn;
    uint256 public direct_bonus;
    uint256 public match_bonus;
    uint8[] public ref_bonuses;

    Plan[] public plans;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 plan);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    
    constructor(address _tokenContractAddress) public {
        tokenContractAddress = _tokenContractAddress;
        owner = msg.sender;

        plans.push(Plan(90, 106));
        plans.push(Plan(180, 137));
        plans.push(Plan(360, 200));
        
        ref_bonuses.push(50);
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
            Plan storage plan = plans[dep.plan];

            uint256 time_end = dep.time + plan.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * plan.percentage / plan.life_days / 8640000;
            }
        }
    }

    function _refPayout(address _customerAddress, address _referredBy, uint256 _amount) private {
        uint256 bonus = _amount.mul(5).div(100);
        if(_referredBy != address(0) && _referredBy != _customerAddress && players[_referredBy].deposits.length != 0){
            players[_referredBy].match_bonus += bonus;
            players[_referredBy].total_match_bonus += bonus;
            match_bonus += bonus;
            players[_customerAddress].direct_bonus += bonus;

            emit MatchPayout(_referredBy, _customerAddress, bonus);
        }
    }

    function deposit(uint8 _plan, address _upline, uint256 value) public returns(bool success) {
        require(plans[_plan].life_days > 0, "Plan not found");
        require(value >= 1e6, "Zero amount");
        Player storage player = players[msg.sender];
        address self = address(this);
        TokenContract tokencontract = TokenContract(tokenContractAddress);

        player.deposits.push(Deposit({
            plan: _plan,
            amount: value,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        player.total_invested += value;
        invested += value;

        _refPayout(msg.sender, _upline, value);
        tokencontract.transferFrom(msg.sender,self,value);
        if(_plan==0){
            tokencontract.mintByStaking(value.mul(6).div(100));
        }
        else if(_plan==1){
            tokencontract.mintByStaking(value.mul(37).div(100));
        }
        else if(_plan==2){
            tokencontract.mintByStaking(value);
        }
        emit NewDeposit(msg.sender, value, _plan);
        return true;
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

        TokenContract tokencontract = TokenContract(tokenContractAddress);
        tokencontract.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Plan storage plan = plans[dep.plan];

            uint256 time_end = dep.time + plan.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * plan.percentage / plan.life_days / 8640000;
            }
        }

        return value;
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 withdrawable_bonus, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[1] memory structure) {
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
          _endTimes[i] = dep.time + plan.life_days * 86400;
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
            Plan storage plan = plans[dep.plan];

            uint256 time_end = dep.time + plan.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                values[i] = dep.amount * (to - from) * plan.percentage / plan.life_days / 8640000;
            }
        }

        return values;
    }
}