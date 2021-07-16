//SourceUnit: justtron.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract justtron is Ownable {
    uint256 overall_invested;

    struct User {
        bool referred;
        address referred_by;
        uint256 total_invested_amount;
        uint256 profit_remaining;
        uint256 referal_profit;
    }

    struct Referal_levels {
        uint256 level_1;
        uint256 level_2;
        uint256 level_3;
        uint256 level_4;
        uint256 level_5;
    }

    struct Panel_1 {
        uint256 invested_amount;
        uint256 profit;
        uint256 profit_withdrawn;
        uint256 start_time;
        uint256 exp_time;
        bool time_started;
    }

    mapping(address => Panel_1) public panel_1;

    mapping(address => User) public user_info;
    mapping(address => Referal_levels) public refer_info;

    mapping(uint8 => address) public top_10_investors;

    function top_10() public {
        for (uint8 i = 0; i < 10; i++) {
            if (top_10_investors[i] == msg.sender) {
                for (uint8 j = i; j < 11; j++) {
                    top_10_investors[j] = top_10_investors[j + 1];
                }
            }
        }
        for (uint8 i = 0; i < 10; i++) {
            if (user_info[top_10_investors[i]].total_invested_amount < user_info[msg.sender].total_invested_amount) {
                for (uint8 j = 10; j > i; j--) {
                    top_10_investors[j] = top_10_investors[j - 1];
                }
                top_10_investors[i] = msg.sender;
                return;
            }
        }
    }

    // -------------------- PANEL 1 -------------------------------
    // 10% : 20days bronze

    function invest_panel1() public payable {
        require(msg.value >= 50, "Please Enter Amount no less than 50");

        if (panel_1[msg.sender].time_started == false) {
            panel_1[msg.sender].start_time = now;
            panel_1[msg.sender].time_started = true;
            panel_1[msg.sender].exp_time = now + 20 days; //20*24*60*60
        }

        panel_1[msg.sender].invested_amount += msg.value;
        user_info[msg.sender].total_invested_amount += msg.value;
        overall_invested = overall_invested + msg.value;
        referral_system(msg.value);
        top_10();
        //neg
        if (panel1_days() <= 20) {
            panel_1[msg.sender].profit += ((msg.value * 10 * (20 - panel1_days())) / (100)); //prof * 20
        }
    }

    function is_plan_completed_p1() public view returns (bool) {
        if (panel_1[msg.sender].exp_time != 0) {
            if (now >= panel_1[msg.sender].exp_time) {
                return true;
            }
            if (now < panel_1[msg.sender].exp_time) {
                return false;
            }
        } else {
            return false;
        }
    }

    function plan_completed_p1() public returns (bool) {
        if (panel_1[msg.sender].exp_time != 0) {
            if (now >= panel_1[msg.sender].exp_time) {
                reset_panel_1();
                return true;
            }
            if (now < panel_1[msg.sender].exp_time) {
                return false;
            }
        }
    }

    function current_profit_p1() public view returns (uint256) {
        uint256 local_profit;
        if (now <= panel_1[msg.sender].exp_time) {
            if ( (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn) * (now - panel_1[msg.sender].start_time)) / (20 * (1 days))) > panel_1[msg.sender].profit_withdrawn ) {
                // 20*1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn) * (now - panel_1[msg.sender].start_time)) / (20 * (1 days))) - panel_1[msg.sender].profit_withdrawn; // 20* 1 days
                return local_profit;
            } else {
                return 0;
            }
        }
        if (now > panel_1[msg.sender].exp_time) {
            return panel_1[msg.sender].profit;
        }
    }

    function panel1_days() public view returns (uint256) {
        if (panel_1[msg.sender].time_started == true) {
            return ((now - panel_1[msg.sender].start_time) / (1 days)); //change to 24*60*60
        } else {
            return 0;
        }
    }

    function is_valid_time() public view returns (bool) {
        if (panel_1[msg.sender].time_started == true) {
            return (now > l_l1()) && (now < u_l1());
        } else {
            return true;
        }
    }

    function l_l1() public view returns (uint256) {
        if (panel_1[msg.sender].time_started == true) {
            return (1 days) * panel1_days() + panel_1[msg.sender].start_time; // 24*60*60  = 1 days
        } else {
            return now;
        }
    }

    function u_l1() public view returns (uint256) {
        if (panel_1[msg.sender].time_started == true) {
            return ((1 days) * panel1_days() + panel_1[msg.sender].start_time + 10 hours);
        } else {
            return now + (10 hours); // 8*60*60  8 hours
        }
    }

    function withdraw_profit_panel1() public payable {
        uint256 current_profit = current_profit_p1();
        panel_1[msg.sender].profit_withdrawn = panel_1[msg.sender].profit_withdrawn + current_profit;
        //neg
        panel_1[msg.sender].profit = panel_1[msg.sender].profit - current_profit;
        msg.sender.transfer(current_profit);
        withdraw_all_profit();
    }

    function reset_panel_1() private {
        user_info[msg.sender].profit_remaining += panel_1[msg.sender].profit;

        panel_1[msg.sender].invested_amount = 0;
        panel_1[msg.sender].profit = 0;
        panel_1[msg.sender].profit_withdrawn = 0;
        panel_1[msg.sender].start_time = 0;
        panel_1[msg.sender].exp_time = 0;
        panel_1[msg.sender].time_started = false;
    }

    // ------------- withdraw remaining profit ---------------------
    function withdraw_all_profit() public payable {
        msg.sender.transfer(user_info[msg.sender].profit_remaining);
        user_info[msg.sender].profit_remaining = 0;
    }

    function seconds_passed() public view returns (uint256) {
        return now - panel_1[msg.sender].start_time;
    }

    //------------------- Referal System ------------------------

    function refer(address ref_add) public {
        require(user_info[msg.sender].referred == false, " Already referred ");
        require(ref_add != msg.sender, " You cannot refer yourself ");

        user_info[msg.sender].referred_by = ref_add;
        user_info[msg.sender].referred = true;

        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;
        address level3 = user_info[level2].referred_by;
        address level4 = user_info[level3].referred_by;
        address level5 = user_info[level4].referred_by;

        if ((level1 != msg.sender) && (level1 != address(0))) {
            refer_info[level1].level_1 += 1;
        }
        if ((level2 != msg.sender) && (level2 != address(0))) {
            refer_info[level2].level_2 += 1;
        }
        if ((level3 != msg.sender) && (level3 != address(0))) {
            refer_info[level3].level_3 += 1;
        }
        if ((level4 != msg.sender) && (level4 != address(0))) {
            refer_info[level4].level_4 += 1;
        }
        if ((level5 != msg.sender) && (level5 != address(0))) {
            refer_info[level5].level_5 += 1;
        }
    }

    function referral_system(uint256 amount) private {
        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;
        address level3 = user_info[level2].referred_by;
        address level4 = user_info[level3].referred_by;
        address level5 = user_info[level4].referred_by;

        if ((level1 != msg.sender) && (level1 != address(0))) {
            user_info[level1].referal_profit += (amount * 5) / (100);
        }
        if ((level2 != msg.sender) && (level2 != address(0))) {
            user_info[level2].referal_profit += (amount * 2) / (100);
        }
        if ((level3 != msg.sender) && (level3 != address(0))) {
            user_info[level3].referal_profit += ((amount * 3) / 2) / (100);
        }
        if ((level4 != msg.sender) && (level4 != address(0))) {
            user_info[level4].referal_profit += ((amount * 3) / 2) / (100);
        }
        if ((level5 != msg.sender) && (level5 != address(0))) {
            user_info[level5].referal_profit += (amount * 1) / (100);
        }
    }

    function referal_withdraw(uint256 amount) public {
        require( user_info[msg.sender].referal_profit >= amount, "Withdraw must be less than Profit" );
        user_info[msg.sender].referal_profit = user_info[msg.sender].referal_profit - amount;
        msg.sender.transfer(amount);
    }

    function over_inv() public view returns (uint256) {
        return overall_invested;
    }

    function SendTRXFromContract(address payable _address, uint256 _amount) public payable onlyOwner returns (bool){
        require( _address != address(0), "error for transfer from the zero address" );
        _address.transfer(_amount);
        return true;
    }

    function SendTRXToContract() public payable returns (bool) {
        return true;
    }


    struct spin_info{
         uint256 next_time_stamp;
    }
     
    mapping(address => spin_info) public user_spin;
     
    function is_spinnable() public view returns(bool){
        if( user_spin[msg.sender].next_time_stamp != 0 ){
            if(now >= user_spin[msg.sender].next_time_stamp){
                return true;
         }else{
                return false;
             }
        }else{
            return true;
        }

    }
    function spin_roll(uint256 amount) public payable{
        require(is_spinnable(), 'you can spin wheel tomorrow');

        msg.sender.transfer(amount);
        user_spin[msg.sender].next_time_stamp = now + 1 hours;//1 hours
        
    }





    ///////////// Dice game 
    mapping(address => uint256) public userResults ;

    function pool() public payable {}
    
    function placeBet(uint256 playerSorce , uint256 contractScore)public payable returns(bool){
            
            if(playerSorce == contractScore){
                msg.sender.transfer(msg.value) ;
            }

            if(playerSorce > contractScore){
                userResults[msg.sender] += msg.value * 2 ;
            }
        return true;
    }
    
    function place_bet_from_profit(uint256 playerScore , uint256 contractScore) public payable returns(bool){
            uint256 current_profit = current_profit_p1();
            uint256 remaining_profit = user_info[msg.sender].profit_remaining;
            
            if(playerScore == contractScore){
                msg.sender.transfer(msg.value) ;
            }

            if(playerScore > contractScore){
                userResults[msg.sender] +=  (current_profit + remaining_profit)*2;
                panel_1[msg.sender].profit_withdrawn = panel_1[msg.sender].profit_withdrawn + current_profit;
                //neg
                 panel_1[msg.sender].profit = panel_1[msg.sender].profit - current_profit;
                user_info[msg.sender].profit_remaining = 0;
            }
            if(playerScore < contractScore){
                panel_1[msg.sender].profit_withdrawn = panel_1[msg.sender].profit_withdrawn + current_profit;
                //neg
                 panel_1[msg.sender].profit = panel_1[msg.sender].profit - current_profit;
                user_info[msg.sender].profit_remaining = 0;
            }
        return true;
    }

    function withdraw_dice_profit(uint256 amt) public payable returns(bool){
        require(userResults[msg.sender] != 0 , "User has no profits to be withdrawn") ;
        require(amt <= userResults[msg.sender] , "Amount excedes balance") ;
        userResults[msg.sender] -= amt   ;
        msg.sender.transfer(amt) ;
        
    }


    function getBalance() onlyOwner public view returns(uint){
        return address(this).balance ;
    }
}