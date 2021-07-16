//SourceUnit: TronStaking.sol

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

contract TronStaking is Ownable{

    uint256 overall_invested;
    struct User{
        bool referred;
        address referred_by;
        uint256 total_invested_amount;
        uint256 profit_remaining;
        uint256 referal_profit;
    }
    
    struct Referal_levels{
        uint256 level_1;
        uint256 level_2;
        uint256 level_3;
        uint256 level_4;
        uint256 level_5;
        uint256 level_6;
        uint256 level_7;
        uint256 level_8;
    }

    struct Panel_1{
        uint256 invested_amount;
        uint256 profit;
        uint256 profit_withdrawn;
        uint256 start_time;
        uint256 exp_time;
        bool time_started;
    }

    struct Panel_2{
        uint256 invested_amount;
        uint256 profit;
        uint256 profit_withdrawn;
        uint256 start_time;
        uint256 exp_time;
        bool time_started;
    }
    
    struct Panel_3{
        uint256 invested_amount;
        uint256 profit;
        uint256 profit_withdrawn;
        uint256 start_time;
        uint256 exp_time;
        bool time_started;
    }

    struct Panel_4{
        uint256 invested_amount;
        uint256 profit;
        uint256 profit_withdrawn;
        uint256 start_time;
        uint256 exp_time;
        bool time_started;
    }


    mapping(address => Panel_1) public panel_1;
    mapping(address => Panel_2) public panel_2;
    mapping(address => Panel_3) public panel_3;
    mapping(address => Panel_4) public panel_4;

    mapping(address => User) public user_info;
    mapping(address => Referal_levels) public refer_info;

    mapping(uint8 => address) public top_10_investors;

    function top_10() public{
        for(uint8 i=0; i<10; i++){
            if(top_10_investors[i] == msg.sender){
                for(uint8 j=i ; j<11;j++){
                    top_10_investors[j] = top_10_investors[j+1];
                }
            }
        }
        for(uint8 i=0;i<10;i++){
            if(user_info[top_10_investors[i]].total_invested_amount < user_info[msg.sender].total_invested_amount){

                for(uint8 j = 10;j > i;j--){
                    top_10_investors[j] = top_10_investors[j-1];
                }
                top_10_investors[i] = msg.sender;
                return;
            }
        }
    }

    // -------------------- PANEL 1 -------------------------------  
    // 6% : 30days

    function invest_panel1() public payable {
        
        require(msg.value>=50, 'Please Enter Amount no less than 50');
        
        if(panel_1[msg.sender].time_started == false){
            panel_1[msg.sender].start_time = now;
            panel_1[msg.sender].time_started = true;
            panel_1[msg.sender].exp_time = now + 30 days; //30*24*60*60
        }

            panel_1[msg.sender].invested_amount += msg.value;
            user_info[msg.sender].total_invested_amount += msg.value; 
            overall_invested = overall_invested + msg.value;
            referral_system(msg.value);
            top_10();
            //neg
            if(panel1_days() <= 30){
                panel_1[msg.sender].profit += ((msg.value*(6)*(30 - panel1_days()))/(100)); //prof * 30
            }
    }

    function is_plan_completed_p1() public view returns(bool){
        if(panel_1[msg.sender].exp_time != 0){
            if(now >= panel_1[msg.sender].exp_time){
                return true;
            }
            if(now < panel_1[msg.sender].exp_time){
                return false;
            }
        }else{
            return false;
        }
    }
    function plan_completed_p1() public  returns(bool){
        if( panel_1[msg.sender].exp_time != 0){
            if(now >= panel_1[msg.sender].exp_time){
                reset_panel_1();
                return true;
            }
            if(now < panel_1[msg.sender].exp_time){
                return false;
            }
        }
    }

    function current_profit_p1() public view returns(uint256){
        uint256 local_profit ;
        if(now <= panel_1[msg.sender].exp_time){
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(30*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 30*1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(30*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 30* 1 days
                return local_profit;
            }else{
                return 0;
            }

        }
        if(now > panel_1[msg.sender].exp_time){
            return panel_1[msg.sender].profit;
        }
    }
    
    function panel1_days() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return ((now - panel_1[msg.sender].start_time)/(1 days)); //change to 24*60*60
        }
        else {
            return 0;
        }
    }
    
    function withdraw_profit_panel1(uint256 amount) public payable {
        uint256 current_profit = current_profit_p1();
        require(amount <= current_profit, ' Amount sould be less than profit');
        panel_1[msg.sender].profit_withdrawn = panel_1[msg.sender].profit_withdrawn + amount;
        //neg
        panel_1[msg.sender].profit = panel_1[msg.sender].profit - amount;
        msg.sender.transfer(amount);
    }

    function is_valid_time() public view returns(bool){
        if(panel_1[msg.sender].time_started == true){
        return (now > l_l1())&&(now < u_l1());    
        }
        else{
            return true;
        }
    }    
    
    function l_l1() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return (1 days)*panel1_days() + panel_1[msg.sender].start_time;     // 24*60*60  = 1 days
        }else{
            return now;
        } 
    }    
    
    function u_l1() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return ((1 days)*panel1_days() + panel_1[msg.sender].start_time + 8 hours);    
        }else {
            return now + (8 hours);  // 8*60*60  8 hours
        }
    }
    
    function reset_panel_1() private{
        user_info[msg.sender].profit_remaining += panel_1[msg.sender].profit;

        panel_1[msg.sender].invested_amount = 0;
        panel_1[msg.sender].profit = 0;
        panel_1[msg.sender].profit_withdrawn = 0;
        panel_1[msg.sender].start_time = 0;
        panel_1[msg.sender].exp_time = 0;
        panel_1[msg.sender].time_started = false;
    }

    
    // --------------------------------- PANEL 2 ----------------------
    // 8% : 20days
    
    function invest_panel2() public payable {
        // 50,000,000 = 50 trx
        require(msg.value>=50, 'Please Enter Amount no less than 50');
        
        if(panel_2[msg.sender].time_started == false){
            panel_2[msg.sender].start_time = now;
            panel_2[msg.sender].time_started = true;
            panel_2[msg.sender].exp_time = now + 20 days; //20*24*60*60  = 20 days
        }
        
            panel_2[msg.sender].invested_amount += msg.value;
            user_info[msg.sender].total_invested_amount += msg.value; 
            overall_invested = overall_invested + msg.value;
            referral_system(msg.value);
            top_10();
            //neg
            if(panel2_days() <= 20){ //20
                panel_2[msg.sender].profit += ((msg.value*(8)*(20 - panel2_days()))/(100)); // 20 - panel_days()
            }

    }

    function is_plan_completed_p2() public view returns(bool){
        if(panel_2[msg.sender].exp_time != 0){
            if(now >= panel_2[msg.sender].exp_time){
                return true;
            }
        if(now < panel_2[msg.sender].exp_time){
            return false;
            }
        }else{
            return false;
        }
    }
    function plan_completed_p2() public  returns(bool){
        if( panel_2[msg.sender].exp_time != 0){
        if(now >= panel_2[msg.sender].exp_time){
            reset_panel_2();
            return true;
        }
        if(now < panel_2[msg.sender].exp_time){
            return false;
            }
        }

    }

    function current_profit_p2() public view returns(uint256){
        uint256 local_profit ;
        if(now <= panel_2[msg.sender].exp_time){
            if((((panel_2[msg.sender].profit + panel_2[msg.sender].profit_withdrawn)*(now-panel_2[msg.sender].start_time))/(20*(1 days))) > panel_2[msg.sender].profit_withdrawn){  // 20 * 1 days
                local_profit = (((panel_2[msg.sender].profit + panel_2[msg.sender].profit_withdrawn)*(now-panel_2[msg.sender].start_time))/(20*(1 days))) - panel_2[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }

        }
        if(now > panel_2[msg.sender].exp_time){
            return panel_2[msg.sender].profit;
        }
    }

    function panel2_days() public view returns(uint256){
        if(panel_2[msg.sender].time_started == true){
            return ((now - panel_2[msg.sender].start_time)/(1 days)); // change to 24*60*60   1 days
        }
        else {
            return 0;
        }
    }
    
    function withdraw_profit_panel2(uint256 amount) public payable {
        uint256 current_profit = current_profit_p2();
        require(amount <= current_profit, ' Amount sould be less than profit');
        panel_2[msg.sender].profit_withdrawn = panel_2[msg.sender].profit_withdrawn + amount;
        //neg
        panel_2[msg.sender].profit = panel_2[msg.sender].profit - amount;
        msg.sender.transfer(amount);
    }

    function is_valid_time_p2() public view returns(bool){
        if(panel_2[msg.sender].time_started == true){
        return (now > l_l2())&&(now < u_l2());    
        }
        else {
            return true;
        }
    }

    function l_l2() public view returns(uint256){
        if(panel_2[msg.sender].time_started == true){
            return (1 days)*panel2_days() + panel_2[msg.sender].start_time;     // 24*60*60 1 days
        }else{
            return now;
        }
        
    }
    function u_l2() public view returns(uint256){
        if(panel_2[msg.sender].time_started == true){
            return ((1 days)*panel2_days() + panel_2[msg.sender].start_time + 8 hours);    // 1 days  , 8 hours
        }else {
            return now + (8 hours);  // 8*60*60  8 hours
        }
    }

    function reset_panel_2() private{
        user_info[msg.sender].profit_remaining += panel_2[msg.sender].profit;

        panel_2[msg.sender].invested_amount = 0;
        panel_2[msg.sender].profit = 0;
        panel_2[msg.sender].profit_withdrawn = 0;
        panel_2[msg.sender].start_time = 0;
        panel_2[msg.sender].exp_time = 0;
        panel_2[msg.sender].time_started = false;
    }  



    // --------------------------------- PANEL 3 ---------------------------

    // 10% : 10 days

    function invest_panel3() public payable {
        
        require(msg.value>=50, 'Please Enter Amount no less than 50');
        
        if(panel_3[msg.sender].time_started == false){
            panel_3[msg.sender].start_time = now;
            panel_3[msg.sender].time_started = true;
            panel_3[msg.sender].exp_time = now + 10 days; //10*24*60*60  = 10 days
        }
        
            panel_3[msg.sender].invested_amount += msg.value;
            user_info[msg.sender].total_invested_amount += msg.value; 
            overall_invested = overall_invested + msg.value;
            referral_system(msg.value);
            top_10();
            //neg
            if(panel3_days() <= 10){ //10
                panel_3[msg.sender].profit += ((msg.value*(10)*(10 - panel3_days()))/(100)); // 10 - panel_days()
            }

    }

    function is_plan_completed_p3() public view returns(bool){
        if(panel_3[msg.sender].exp_time != 0){
            if(now >= panel_3[msg.sender].exp_time){
                return true;
            }
        if(now < panel_3[msg.sender].exp_time){
            return false;
            }
        }else{
            return false;
        }
    }
    function plan_completed_p3() public  returns(bool){
        if( panel_3[msg.sender].exp_time != 0){
        if(now >= panel_3[msg.sender].exp_time){
            reset_panel_3();
            return true;
        }
        if(now < panel_3[msg.sender].exp_time){
            return false;
            }
        }

    }

    function current_profit_p3() public view returns(uint256){
        uint256 local_profit ;
        if(now <= panel_3[msg.sender].exp_time){
            if((((panel_3[msg.sender].profit + panel_3[msg.sender].profit_withdrawn)*(now-panel_3[msg.sender].start_time))/(10*(1 days))) > panel_3[msg.sender].profit_withdrawn){  // 10 * 1 days
                local_profit = (((panel_3[msg.sender].profit + panel_3[msg.sender].profit_withdrawn)*(now-panel_3[msg.sender].start_time))/(10*(1 days))) - panel_3[msg.sender].profit_withdrawn; // 10*24*60*60
                return local_profit;
            }else{
                return 0;
            }

        }
        if(now > panel_3[msg.sender].exp_time){
            return panel_3[msg.sender].profit;
        }
    }
    
    function panel3_days() public view returns(uint256){
        if(panel_3[msg.sender].time_started == true){
            return ((now - panel_3[msg.sender].start_time)/(1 days)); // change to 24*60*60   1 days
        }
        else {
            return 0;
        }
    }
    
    function withdraw_profit_panel3(uint256 amount) public payable {
        uint256 current_profit = current_profit_p3();
        require(amount <= current_profit, ' Amount sould be less than profit');
        panel_3[msg.sender].profit_withdrawn = panel_3[msg.sender].profit_withdrawn + amount;
        //neg
        panel_3[msg.sender].profit = panel_3[msg.sender].profit - amount;
        msg.sender.transfer(amount);
    }
    
    function is_valid_time_p3() public view returns(bool){
        if(panel_3[msg.sender].time_started == true){
        return (now > l_l3())&&(now < u_l3());    
        }
        else {
            return true;
        }
    }
    function l_l3() public view returns(uint256){
        if(panel_3[msg.sender].time_started == true){
            return (1 days)*panel3_days() + panel_3[msg.sender].start_time;     // 24*60*60 1 days
        }else{
            return now;
        }  
    } 
    function u_l3() public view returns(uint256){
        if(panel_3[msg.sender].time_started == true){
            return ((1 days)*panel3_days() + panel_3[msg.sender].start_time + 8 hours);    // 1 days  , 8 hours
        }else {
            return now + (8 hours);  // 8*60*60  8 hours
        }
    }

    function reset_panel_3() private{
        user_info[msg.sender].profit_remaining += panel_3[msg.sender].profit;

        panel_3[msg.sender].invested_amount = 0;
        panel_3[msg.sender].profit = 0;
        panel_3[msg.sender].profit_withdrawn = 0;
        panel_3[msg.sender].start_time = 0;
        panel_3[msg.sender].exp_time = 0;
        panel_3[msg.sender].time_started = false;
    }

    // ---------------------------------------------------------------------------------------------------------------


    // -------------------------------------------- PANEL - 4 -------------------------------------------------------
    
    // 12% : 5 days

    function invest_panel4() public payable {
        
        require(msg.value>=50, 'Please Enter Amount no less than 50');
        
        if(panel_4[msg.sender].time_started == false){
            panel_4[msg.sender].start_time = now;
            panel_4[msg.sender].time_started = true;
            panel_4[msg.sender].exp_time = now + 5 days; //5*24*60*60  = 5 days
        }
        
            panel_4[msg.sender].invested_amount += msg.value;
            user_info[msg.sender].total_invested_amount += msg.value; 
            overall_invested = overall_invested + msg.value;
            referral_system(msg.value);
            top_10();
            //neg
            if(panel4_days() <= 5){ //5
                panel_4[msg.sender].profit += ((msg.value*(12)*(5 - panel4_days()))/(100)); // 5 - panel_days()
            }

    }
    
    function is_plan_completed_p4() public view returns(bool){
        if(panel_4[msg.sender].exp_time != 0){
            if(now >= panel_4[msg.sender].exp_time){
                return true;
            }
        if(now < panel_4[msg.sender].exp_time){
            return false;
            }
        }else{
            return false;
        }
    }
    function plan_completed_p4() public  returns(bool){
        if( panel_4[msg.sender].exp_time != 0){
        if(now >= panel_4[msg.sender].exp_time){
            reset_panel_4();
            return true;
        }
        if(now < panel_4[msg.sender].exp_time){
            return false;
            }
        }

    }

    function current_profit_p4() public view returns(uint256){
        uint256 local_profit ;
        if(now <= panel_4[msg.sender].exp_time){
            if((((panel_4[msg.sender].profit + panel_4[msg.sender].profit_withdrawn)*(now-panel_4[msg.sender].start_time))/(5*(1 days))) > panel_4[msg.sender].profit_withdrawn){  // 5 * 1 days
                local_profit = (((panel_4[msg.sender].profit + panel_4[msg.sender].profit_withdrawn)*(now-panel_4[msg.sender].start_time))/(5*(1 days))) - panel_4[msg.sender].profit_withdrawn; // 5*24*60*60
                return local_profit;
            }else{
                return 0;
            }

        }
        if(now > panel_4[msg.sender].exp_time){
            return panel_4[msg.sender].profit;
        }
    }

    function panel4_days() public view returns(uint256){
        if(panel_4[msg.sender].time_started == true){
            return ((now - panel_4[msg.sender].start_time)/(1 days)); // change to 24*60*60   1 days
        }
        else {
            return 0;
        }
    }

    function withdraw_profit_panel4(uint256 amount) public payable {
        uint256 current_profit = current_profit_p4();
        require(amount <= current_profit, ' Amount sould be less than profit');
        panel_4[msg.sender].profit_withdrawn = panel_4[msg.sender].profit_withdrawn + amount;
        //neg
        panel_4[msg.sender].profit = panel_4[msg.sender].profit - amount;
        msg.sender.transfer(amount);
    }

    function is_valid_time_p4() public view returns(bool){
        if(panel_4[msg.sender].time_started == true){
        return (now > l_l4())&&(now < u_l4());    
        }
        else {
            return true;
        }
    }
    function l_l4() public view returns(uint256){
        if(panel_4[msg.sender].time_started == true){
            return (1 days)*panel4_days() + panel_4[msg.sender].start_time;     // 24*60*60 1 days
        }else{
            return now;
        }
        
    }    
    function u_l4() public view returns(uint256){
        if(panel_4[msg.sender].time_started == true){
            return ((1 days)*panel4_days() + panel_4[msg.sender].start_time + 8 hours);    // 1 days  , 8 hours
        }else {
            return now + (8 hours);  // 8*60*60  8 hours
        }
    }

    function reset_panel_4() private{
        user_info[msg.sender].profit_remaining += panel_4[msg.sender].profit;

        panel_4[msg.sender].invested_amount = 0;
        panel_4[msg.sender].profit = 0;
        panel_4[msg.sender].profit_withdrawn = 0;
        panel_4[msg.sender].start_time = 0;
        panel_4[msg.sender].exp_time = 0;
        panel_4[msg.sender].time_started = false;
    }


// ------------- withdraw remaining profit ---------------------
    function withdraw_rem_profit(uint256 amt) public payable{
        require(amt <= user_info[msg.sender].profit_remaining, ' Withdraw amount should be less than remaining profit ');
        user_info[msg.sender].profit_remaining = user_info[msg.sender].profit_remaining - amt;
        msg.sender.transfer(amt); 
    }



 //------------------- Referal System ------------------------

    function refer(address ref_add) public {
        require(user_info[msg.sender].referred == false, ' Already referred ');
        require(ref_add != msg.sender, ' You cannot refer yourself ');
        
        user_info[msg.sender].referred_by = ref_add;
        user_info[msg.sender].referred = true;        
        
        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;
        address level3 = user_info[level2].referred_by;
        address level4 = user_info[level3].referred_by;
        address level5 = user_info[level4].referred_by;
        address level6 = user_info[level5].referred_by;
        address level7 = user_info[level6].referred_by;
        address level8 = user_info[level7].referred_by;
        
        if( (level1 != msg.sender) && (level1 != address(0)) ){
            refer_info[level1].level_1 += 1;
        }
        if( (level2 != msg.sender) && (level2 != address(0)) ){
            refer_info[level2].level_2 += 1;
        }
        if( (level3 != msg.sender) && (level3 != address(0)) ){
            refer_info[level3].level_3 += 1;
        }
        if( (level4 != msg.sender) && (level4 != address(0)) ){
            refer_info[level4].level_4 += 1;
        }
        if( (level5 != msg.sender) && (level5 != address(0)) ){
            refer_info[level5].level_5 += 1;
        }
        if( (level6 != msg.sender) && (level6 != address(0)) ){
            refer_info[level6].level_6 += 1;
        }
        if( (level7 != msg.sender) && (level7!= address(0)) ){
            refer_info[level7].level_7 += 1;
        }
        if( (level8 != msg.sender) && (level8 != address(0)) ){
            refer_info[level8].level_8 += 1;
        }
        
    }

    function referral_system(uint256 amount) private {
        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;
        address level3 = user_info[level2].referred_by;
        address level4 = user_info[level3].referred_by;
        address level5 = user_info[level4].referred_by;
        address level6 = user_info[level5].referred_by;
        address level7 = user_info[level6].referred_by;
        address level8 = user_info[level7].referred_by;

        if( (level1 != msg.sender) && (level1 != address(0)) ){
            user_info[level1].referal_profit += (amount*5)/(100);
        }
        if( (level2 != msg.sender) && (level2 != address(0)) ){
            user_info[level2].referal_profit += (amount*3)/(100);
        }
        if( (level3 != msg.sender) && (level3 != address(0)) ){
            user_info[level3].referal_profit += (amount*(1))/(100);
        }
        if( (level4 != msg.sender) && (level4 != address(0)) ){
            user_info[level4].referal_profit += (amount*1)/(100);
        }
        if( (level5 != msg.sender) && (level5 != address(0)) ){
            user_info[level5].referal_profit += (amount*1)/(100);
        }
        if( (level6 != msg.sender) && (level6 != address(0)) ){
            user_info[level6].referal_profit += (amount*1)/(100);
        }
        if( (level7 != msg.sender) && (level7 != address(0)) ){
            user_info[level7].referal_profit += (amount*1)/(100);
        }
        if( (level8 != msg.sender) && (level8 != address(0)) ){
            user_info[level8].referal_profit += (amount*1)/(100);
        }
    }

    function referal_withdraw(uint256 amount) public {
        require( user_info[msg.sender].referal_profit >= amount, 'Withdraw must be less than Profit');
        user_info[msg.sender].referal_profit = user_info[msg.sender].referal_profit - amount;
        msg.sender.transfer(amount);
    }  

    function over_inv() public view returns(uint256){
        return overall_invested;
    }

    function SendTRXFromContract(address payable _address, uint256 _amount) public payable onlyOwner returns (bool){
        require(_address != address(0), "error for transfer from the zero address");
        _address.transfer(_amount);
        return true;
    }
   
    function SendTRXToContract() public payable returns (bool){
        return true;
    }

}