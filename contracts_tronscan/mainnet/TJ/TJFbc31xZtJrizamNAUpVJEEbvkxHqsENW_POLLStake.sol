//SourceUnit: PollFi.sol

pragma solidity >=0.4.20;
import "./TRC20Basic.sol";


contract POLLStake {
    address public owner;
    address  a;

    
    TRC20 public token;
    
    uint8 decimals;
    uint8 TRC20decimals;
    
    struct User{
        bool referred;
        address referred_by;
        uint256 total_invested_amount;
        uint256 referal_profit;
    }
    
    struct Referal_levels{
        uint256 level_1;
    }

    struct Panel_1{
        uint256 invested_amount;
        uint256 profit;
        uint256 profit_withdrawn;
        uint256 start_time;
        uint256 exp_time;
        bool time_started;
        uint256 remaining_inv_prof;
    }


    mapping(address => Panel_1) public panel_1;

    mapping(address => User) public user_info;
    mapping(address => Referal_levels) public refer_info;
    uint public totalcontractamount;



    constructor() public {
        owner = msg.sender;
        a = msg.sender;
        
        TRC20decimals = 8; //  Decimal places of TRC20 token
        token = TRC20(0x413D615BD0BE91C77CBACECC1DC7F53EE347586E2A);
    }

    function getContractTRC20Balance() public view returns (uint256){
       return token.balanceOf(address(this));
    }


    

function invest_panel1(uint256 t_value) public {
        require(t_value >= 100 * (10 ** 8), 'Please Enter Amount no less than 100');
        require(t_value <= 1000000 * (10 ** 8), 'Please Enter Amount no more than 1000000');

        
        if( panel_1[msg.sender].time_started == false){
            panel_1[msg.sender].start_time = now;
            panel_1[msg.sender].time_started = true;
            panel_1[msg.sender].exp_time = now + 90 days; //90*24*60*60  = 90 days
        }
            // // Approve to contract for taking tokens in
            // token.approve(address(this), t_value); // doesn't work external

            // transfer the tokens from user to contract
            token.transferFrom(msg.sender, address(this), t_value);

            // assign token amount to bot accout
            panel_1[msg.sender].invested_amount += t_value;
            user_info[msg.sender].total_invested_amount += t_value; 
            
            referral_system(t_value);
            
            //neg
        if(panel1_days() <= 90){ //90
            panel_1[msg.sender].profit += ((t_value*7*(90 - panel1_days()))/(1000)); // 90 - panel_days()
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

        if( (panel1_days()%7 +1) ==  1){
                // Day_1 = 0.046 : 0.25
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(0.25*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if((panel1_days()%7 +1) ==  2){
                // Day_2 = 0.045 : 0.25
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(0.25*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if((panel1_days()%7 +1) ==  3){
                //Day_3 = 0.045 : 0.25
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(0.25*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }

        }           
        if((panel1_days()%7 +1) ==  4){
                // Day_4 = 0.045 : 0.25
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(0.25*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if((panel1_days()%7 +1) ==  5){
                // Day_5 = 0.045 : 0.25
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(0.25*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if((panel1_days()%7 +1) ==  6){
                // Day_6 = 0.045 : 0.25
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(0.25*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if((panel1_days()%7 +1) ==  7){
                // Day_7 = 0.045 : 0.25
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(0.25*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }

            // if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 45 * 1 days
            //     local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(90*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 20*24*60*60
            //     return local_profit;
            // }else{
            //     return 0;
            // }
        }
        if(now > panel_1[msg.sender].exp_time){
            return panel_1[msg.sender].profit;
        }
    }

    function panel1_days() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return ((now - panel_1[msg.sender].start_time)/(1 days)); // change to 24*60*60   1 days
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
        token.transfer(msg.sender, (amount - ((5*amount)/100)));
        token.transfer(a, ((5*amount)/100));
    }

    function is_valid_time_p1() public view returns(bool){
        if(panel_1[msg.sender].time_started == true){
        return (now > l_l1())&&(now < u_l1());    
        }
        else {
            return true;
        }
    }

    function l_l1() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return (1 days)*panel1_days() + panel_1[msg.sender].start_time;     // 24*60*60 1 days
        }else{
            return now;
        }
        
    }
    function u_l1() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return ((1 days)*panel1_days() + panel_1[msg.sender].start_time + 10 hours);    // 1 days  , 8 hours
        }else {
            return now + (10 hours);  // 8*60*60  8 hours
        }
    }

    function reset_panel_1() private{
        panel_1[msg.sender].remaining_inv_prof = panel_1[msg.sender].profit + panel_1[msg.sender].invested_amount;

        panel_1[msg.sender].invested_amount = 0;
        panel_1[msg.sender].profit = 0;
        panel_1[msg.sender].profit_withdrawn = 0;
        panel_1[msg.sender].start_time = 0;
        panel_1[msg.sender].exp_time = 0;
        panel_1[msg.sender].time_started = false;
    }  

    function withdraw_all_p1() public payable{

        token.transfer(msg.sender, panel_1[msg.sender].remaining_inv_prof);
        panel_1[msg.sender].remaining_inv_prof = 0;

    }


    




 //------------------- Referal System ------------------------

    function refer(address ref_add) public {
        require(user_info[msg.sender].referred == false, ' Already referred ');
        require(ref_add != msg.sender, ' You cannot refer yourself ');
        
        user_info[msg.sender].referred_by = ref_add;
        user_info[msg.sender].referred = true;        
        
        address level1 = user_info[msg.sender].referred_by;
        
        if( (level1 != msg.sender) && (level1 != address(0)) ){
            refer_info[level1].level_1 += 1;
        }

        
    }

    function referral_system(uint256 amount) private {
        address level1 = user_info[msg.sender].referred_by;

        if( (level1 != msg.sender) && (level1 != address(0)) ){
            user_info[level1].referal_profit += (amount*1)/(100);
        }

    }

    function referal_withdraw() public {    
        uint256 pending = user_info[msg.sender].referal_profit;
        user_info[msg.sender].referal_profit = 0;
        
        token.transfer(msg.sender, pending);
    }  



}

 


//SourceUnit: TRC20Basic.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.20;

interface TRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TRC20Basic is TRC20 {

    string public constant name = "TRC20Basic";
    string public constant symbol = "POLL";
    uint8 public constant decimals = 8;  

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_ = 10000000*10**uint256(decimals);

    using SafeMath for uint256;

   constructor() public {  
    balances[msg.sender] = totalSupply_;
    }  

    function totalSupply() public view returns (uint256) {
    return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function burn (uint256 value) public returns (bool){
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        totalSupply_ -= value;
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool){
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] -= _value;
        totalSupply_ -= _value;
        
        return true;
    }
}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}