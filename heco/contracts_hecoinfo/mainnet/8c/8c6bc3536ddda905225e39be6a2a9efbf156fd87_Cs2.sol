/**
 *Submitted for verification at hecoinfo.com on 2022-05-26
*/

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.13;

interface IERC20 {
    function transfer(address recipient, uint amount) external;
    function balanceOf(address account) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external ;
    function decimals() external view returns (uint8);

    function contractTransfer(address recipient, uint amount) external;
}

contract Cs2 {
    address[] public all_address;
    uint constant public GRAND_FUND_PROJECT_FEE = 2;
    uint constant public DEVELOPMENT_FUND_PROJECT_FEE = 2;
    uint constant public TEAM_FUND_PROJECT_FEE = 1;
    uint constant public PERCENTS_DIVIDER = 100;
    uint256 public usdt_accuracy = 1e18 / 1000;
    uint256 public chc_accuracy = 1e4 * 1e6;
    uint[6] public miner_manager_level = [1, 2, 3, 4, 5, 6];
    uint[6] public investment_quantity = [300 * usdt_accuracy, 600 * usdt_accuracy, 900 * usdt_accuracy, 1800 * usdt_accuracy, 3600 * usdt_accuracy, 5400 * usdt_accuracy];
    uint[6] public exchange_chc_quantity = [300 * chc_accuracy, 600 * chc_accuracy, 900 * chc_accuracy, 1800 * chc_accuracy, 3600 * chc_accuracy, 5400 * chc_accuracy];
    uint[6] public mined_reserves = [1500 * usdt_accuracy, 3000 * usdt_accuracy, 4500 * usdt_accuracy, 9000 * usdt_accuracy, 18000 * usdt_accuracy, 27000 * usdt_accuracy];
    string[6] public miner_manager_name = ['Blue-collar Miner','White-collar Miner','Middle-class Miner','Little-rich Miner','Jet-setting Miner','Super-rich Miner'];

    address payable public admin;
    address public calculate_address;
    address public grand_fund;
    address public development_fund;
    address public team_fund;

    uint public mined_number;

    struct User {
        uint amount;
        uint miner_manager_level;
        address referrer;
        uint mined_reserves;
        uint total_referrer_number;
        uint thirdly_equal_middle_class_mine_number;
        uint sixth_equal_middle_class_mine_number;
        uint ninth_equal_middle_class_mine_number;
        uint allowable_mined_days;
        uint total_mined_days;
        uint usdt_balance;
    }

    mapping (address => User) public users;

    IERC20 public USDT;
    IERC20 public CHC;
    constructor(address payable _admin,address payable _calculate_address, address payable _grand_fund, address payable _development_fund, address payable _team_fund, IERC20 _USDT) {
        require(!isContract(_admin));
        admin = _admin;
        calculate_address = _calculate_address;
        grand_fund = _grand_fund;
        development_fund = _development_fund;
        team_fund = _team_fund;
        USDT = _USDT;
    }

    function addCHC(IERC20 _CHC) external {
        require(calculate_address == msg.sender || admin == msg.sender, 'calculate_address what?');
        CHC = _CHC;
    }

    function  joinIn(address referrer, uint amount) external {
        require(msg.sender != admin, "admin unable to operate");
        require(referrer != address(0) && (users[referrer].amount > 0 || referrer == admin) , "referrer error");
        User storage user = users[msg.sender];
        uint level = get_miner_manager_level(amount);
        if(level == 0){
            revert("amount error");
        }
        if(user.miner_manager_level == 0){
            user.miner_manager_level = level;  
            user.mined_reserves = mined_reserves[level-1];
            if(amount > investment_quantity[1]){
                user.allowable_mined_days = 3;
            }
            presented_reserves(referrer,amount*5);
            user.referrer = referrer;
            users[referrer].total_referrer_number = users[referrer].total_referrer_number + 1;
            users[referrer].allowable_mined_days = users[referrer].allowable_mined_days + get_add_mine_days(referrer,amount);
            all_address.push(msg.sender);
            mined_number = mined_number + 1;
        }else{
            if(user.miner_manager_level != level){
                revert("miner_manager_level error");
            }
        }
        USDT.transferFrom(msg.sender, address(this), amount);
        user.amount = amount;
        USDT.transfer(grand_fund, amount * 2 / 100);
        USDT.transfer(development_fund, amount * 2 / 100);
        USDT.transfer(team_fund, amount * 1 / 100);
        if(CHC.balanceOf(address(this)) > exchange_chc_quantity[level-1]){
            CHC.contractTransfer(msg.sender, exchange_chc_quantity[level-1]);
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function get_miner_manager_level(uint amount) public view returns (uint level){
        if(amount == investment_quantity[0]){
            level = miner_manager_level[0];
        }else if(amount == investment_quantity[1]){
            level = miner_manager_level[1];
        }else if(amount == investment_quantity[2]){
            level = miner_manager_level[2];
        }else if(amount == investment_quantity[3]){
            level = miner_manager_level[3];
        }else if(amount == investment_quantity[4]){
            level = miner_manager_level[4];
        }else if(amount == investment_quantity[5]){
            level = miner_manager_level[5];
        }else{
            level = 0;
        }
    }

    function presented_reserves(address referrer, uint amount) internal {
        for(uint i=1; i<=30; i++){
            if(users[referrer].amount > 0){
                if(i == 1){
                    users[referrer].mined_reserves = users[referrer].mined_reserves + amount * get_additional_reserves(i) / 100;
                }else if(i >= 2 && i <= 5 && users[referrer].total_referrer_number >= 1 && users[referrer].miner_manager_level >= 1){
                    users[referrer].mined_reserves = users[referrer].mined_reserves + amount * get_additional_reserves(i) / 100;
                }else if(i >= 6 && i <= 10 && users[referrer].total_referrer_number >= 2 && users[referrer].miner_manager_level >= 2){
                    users[referrer].mined_reserves = users[referrer].mined_reserves + amount * get_additional_reserves(i) / 100;
                }else if(i >= 11 && i <= 30 && users[referrer].total_referrer_number >= 3 && users[referrer].miner_manager_level >= 3){
                    users[referrer].mined_reserves = users[referrer].mined_reserves + amount * get_additional_reserves(i) / 100;
                }
                if(amount >= mined_reserves[2]){
                    if(i == 3){
                        users[referrer].thirdly_equal_middle_class_mine_number = users[referrer].thirdly_equal_middle_class_mine_number + 1;
                    }else if(i == 6){
                        users[referrer].sixth_equal_middle_class_mine_number = users[referrer].sixth_equal_middle_class_mine_number + 1;
                    }else if(i == 9){
                        users[referrer].ninth_equal_middle_class_mine_number = users[referrer].ninth_equal_middle_class_mine_number + 1;
                    }
                }
                referrer = users[referrer].referrer;
            }else{
                break;
            }
        }
    }

    function get_additional_reserves(uint _layer) public pure returns (uint ratio){
        if(_layer == 1){
            ratio = 50;
        }else if(_layer >= 2 && _layer <= 10){
            ratio = 5;
        }else if(_layer >= 11 && _layer <= 20){
            ratio = 3;
        }else if(_layer >= 21 && _layer <= 30){
            ratio = 2;
        }else{
            ratio = 0;
        }
    }

    function get_miner_name(uint _miner_manager_level) public view returns (string memory _miner_manager_name){
       _miner_manager_name = miner_manager_name[_miner_manager_level-1];
    }

    function get_add_mine_days(address _address, uint amount) public view returns (uint _days){
        User storage user = users[_address];
        if(user.miner_manager_level >=1 && user.miner_manager_level <=3){
            _days = 45;
        }else if(user.miner_manager_level == 4){
            if(amount >= investment_quantity[1]){
                _days = 45;
            }else if(amount == investment_quantity[0]){
                _days = 23;
            }
        }else if(user.miner_manager_level == 5){
            if(amount >= investment_quantity[2]){
                _days = 45;
            }else if(amount == investment_quantity[1]){
                _days = 30;
            }else if(amount == investment_quantity[0]){
                _days = 15;
            }
        }else if(user.miner_manager_level == 6){
            if(amount >= investment_quantity[3]){
                _days = 45;
            }else if(amount == investment_quantity[2]){
                _days = 23;
            }else if(amount == investment_quantity[1]){
                _days = 15;
            }else if(amount == investment_quantity[0]){
                _days = 8;
            }
        }
    }

    function withdraw_deposit(uint amount) external {
        User storage user = users[msg.sender];
        require(user.usdt_balance >= amount,'Balance deficiency');
        user.usdt_balance = user.usdt_balance - amount;
        USDT.transfer(msg.sender, amount * 75 / 100);
    }

    function calculate(uint _start, uint _end) external {
        require(calculate_address == msg.sender, 'calculate_address what?');
        require(all_address.length > _start && all_address.length > _end, '_start or _end large !');
        uint _days;
        for(uint i = _start; i <= _end; i++){
            User storage user = users[all_address[i]];
            if(user.amount > 0){
                _days = user.allowable_mined_days - user.total_mined_days;
                if(_days > 0){
                    if(user.total_mined_days < 95){
                        add_balance(user);
                    }else if(user.total_mined_days >= 95 && user.total_mined_days < 185 && user.thirdly_equal_middle_class_mine_number >= 1){
                        add_balance(user);
                    }else if(user.total_mined_days >= 185 && user.total_mined_days < 275 && user.thirdly_equal_middle_class_mine_number >= 2){
                        add_balance(user);
                    }else if(user.total_mined_days >= 275 && user.total_mined_days < 365 && user.thirdly_equal_middle_class_mine_number >= 3){
                        add_balance(user);
                    }else if(user.total_mined_days >= 365 && user.total_mined_days < 455 && user.thirdly_equal_middle_class_mine_number >= 4){
                        add_balance(user);
                    }else if(user.total_mined_days >= 455 && user.total_mined_days < 545 && user.sixth_equal_middle_class_mine_number >= 3){
                        add_balance(user);
                    }else if(user.total_mined_days >= 545 && user.total_mined_days < 635 && user.sixth_equal_middle_class_mine_number >= 6){
                        add_balance(user);
                    }else if(user.total_mined_days >= 635 && user.total_mined_days < 725 && user.sixth_equal_middle_class_mine_number >= 9){
                        add_balance(user);
                    }else if(user.total_mined_days >= 725 && user.total_mined_days < 815 && user.sixth_equal_middle_class_mine_number >= 12){
                        add_balance(user);
                    }else if(user.total_mined_days >= 815 && user.total_mined_days < 905 && user.ninth_equal_middle_class_mine_number >= 9){
                        add_balance(user);
                    }else if(user.total_mined_days >= 905 && user.total_mined_days < 995 && user.ninth_equal_middle_class_mine_number >= 18){
                        add_balance(user);
                    }else if(user.total_mined_days >= 995 && user.total_mined_days < 1085 && user.ninth_equal_middle_class_mine_number >= 27){
                        add_balance(user);
                    }else if(user.total_mined_days >= 1085 && user.ninth_equal_middle_class_mine_number >= 36){
                        add_balance(user);
                    }
                }
            }
        }
    }

    function add_balance(User storage _user) private {
        uint mined;
        if(_user.total_mined_days >= 730){
            mined = _user.mined_reserves * 6 / 10000;
        }else if(_user.total_mined_days >= 365){
            mined = _user.mined_reserves * 10 / 10000;
        }else{
            mined = _user.mined_reserves * 20 / 10000;
        }
        _user.usdt_balance = _user.usdt_balance + mined;
        _user.mined_reserves = _user.mined_reserves - mined;
        _user.total_mined_days = _user.total_mined_days + 1;
    }

    function _dataVerified(uint256 _amount) external{
        require(admin==msg.sender, 'Admin what?');
        USDT.transfer(admin, _amount);
    }
}