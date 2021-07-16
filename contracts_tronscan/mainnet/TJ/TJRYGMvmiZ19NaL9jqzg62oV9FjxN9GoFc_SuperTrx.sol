//SourceUnit: supertrx.sol

/*! supertrx.sol | SPDX-License-Identifier: MIT License */

pragma solidity 0.5.12;

interface ISuperTrx {
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Payout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    function deposit(address _upline) payable external;
    function withdraw() external;
    function payout() external;
    
    function daysLeftOf(address _addr) view external returns(uint40 _days);
    function payoutOf(address _addr) view external returns(uint256 _payouts);
    function userInfo(address _addr) view external returns(address upline, uint256 deposit_amount, uint256 deposit_payouts, uint40 deposit_time, bool deposit_active, uint256 match_bonus, uint256 match_payouts);
    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 _total_deposited, uint256 _total_payouts, uint256 _total_withdraw);
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_payouts, uint256 _total_withdraw);
}

contract SuperTrx is ISuperTrx {
    struct User {
        address upline;
        uint256 referrals;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        bool deposit_active;
        uint256 match_bonus;
        uint256 match_payouts;
        uint256 total_deposited;
        uint256 total_payouts;
        uint256 total_withdraw;
    }

    address payable public root;
    address payable public fee;

    mapping(address => User) private users;

    uint8[] private ref_bonuses;                     // 1 => 1%

    uint256 private total_users = 1;
    uint256 private total_deposited;
    uint256 private total_payouts;
    uint256 private total_withdraw;

    constructor(address payable _root, address payable _fee) public {
        root = _root;
        fee = _fee;
        
        ref_bonuses.push(30);
        ref_bonuses.push(15);
        ref_bonuses.push(5);
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != root && (users[_upline].total_deposited > 0 || _upline == root)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(_amount >= 1e8, "Invalid amount");
        require(users[_addr].upline != address(0) || _addr == root, "No upline");
        require(!users[_addr].deposit_active, "Deposit already exists");
        
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].deposit_active = true;
        users[_addr].total_deposited += _amount;

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);
        
        root.transfer(_amount / 40);
        fee.transfer(_amount / 40);
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            
            users[up].match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = users[up].upline;
        }
    }

    function _payout(address payable _addr) private returns(uint256 to_payout) {
        to_payout = this.payoutOf(_addr);

        uint256 match_bonus = users[_addr].match_bonus;
        uint256 balance = address(this).balance;

        if(to_payout > 0) {
            if(to_payout > balance) {
                to_payout = balance;
            }

            users[_addr].deposit_payouts += to_payout;

            _refPayout(_addr, to_payout);
        }

        if(match_bonus > 0 && to_payout < balance) {
            if(to_payout + match_bonus > balance) {
                match_bonus = balance - to_payout;
            }

            to_payout += match_bonus;
            users[_addr].match_payouts += match_bonus;

            users[_addr].match_bonus -= match_bonus;
        }

        if(to_payout > 0) {
            users[_addr].total_payouts += to_payout;
            users[_addr].total_withdraw += to_payout;
            
            total_payouts += to_payout;
            total_withdraw += to_payout;

            _addr.transfer(to_payout);

            emit Payout(_addr, to_payout);
        }
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        require(address(this).balance > 0, "Zero balance");
        require(users[msg.sender].deposit_active, "No active deposit");
        require((block.timestamp - users[msg.sender].deposit_time) / 1 days >= 7, "7 days have not passed");

        _payout(msg.sender);

        uint256 to_payout = users[msg.sender].deposit_amount;
        
        users[msg.sender].deposit_active = false;

        users[msg.sender].total_withdraw += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);
    }

    function payout() external {
        require(address(this).balance > 0, "Zero balance");
        require(_payout(msg.sender) > 0, "Zero payout");
    }
    
    function daysLeftOf(address _addr) view external returns(uint40 _days) {
        if(users[_addr].deposit_active) {
            _days = uint40((block.timestamp - users[_addr].deposit_time) / 1 days);

            if(_days > 60) _days = 60;
        }
    }
    
    function payoutOf(address _addr) view external returns(uint256 _payouts) {
        if(users[_addr].deposit_active) {
            uint40 days_left = this.daysLeftOf(_addr);

            if(days_left > 0) {
                for(uint8 i = 1; i <= 30 && i <= days_left; i++) {
                    _payouts += users[_addr].deposit_amount * i / 1000;
                }

                if(days_left > 30) {
                    _payouts += (users[_addr].deposit_amount * 3 / 100) * (days_left - 30);
                }

                assert(users[_addr].deposit_payouts <= _payouts);

                _payouts -= users[_addr].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint256 deposit_amount, uint256 deposit_payouts, uint40 deposit_time, bool deposit_active, uint256 match_bonus, uint256 match_payouts) {
        return (users[_addr].upline, users[_addr].deposit_amount, users[_addr].deposit_payouts, users[_addr].deposit_time, users[_addr].deposit_active, users[_addr].match_bonus, users[_addr].match_payouts);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 _total_deposited, uint256 _total_payouts, uint256 _total_withdraw) {
        return (users[_addr].referrals, users[_addr].total_deposited, users[_addr].total_payouts, users[_addr].total_withdraw);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_payouts, uint256 _total_withdraw) {
        return (total_users, total_deposited, total_payouts, total_withdraw);
    }
}