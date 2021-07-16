//SourceUnit: ITRC20.sol

pragma solidity ^0.4.25;

/**
 * @dev Interface of the TRC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `TRC20Detailed`.
 */
interface ITRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: solidity.sol

pragma solidity >=0.4.22 <0.6.0;

import "./ITRC20.sol";

contract Btzstaking{
    //user data
    struct User{
        uint256 cycle;
        address upline;
        uint256 referal;
        uint256 total_deposit;
        uint256 total_stake;
        uint256 active_stake;
        uint256 total_withdraw;
        uint256 ref_bonus;
        uint256 all_staker;
        uint256 kick_starter;
        uint256 master_node;
        uint40 time;
        uint256 allstaker_share;
       
    }
    //user plan check
    struct Plan{
        uint256 is_kick;
        uint256 is_master;
        uint256 is_prime;
        uint256 kick_pool_start;
        uint256 master_pool_start;
        uint256 roi;
        uint256 total;
        uint256 level_total;
        uint256 prime_pool;
        uint256 contract_cycle;
    }
    
    mapping(address => User) public users;
    mapping(address => Plan) public plans;
    
    
    // global details
    // uint256 public global_users;
    uint256 public global_users;
    uint256 public global_deposit;
    uint256 public global_stake;
    uint256 public global_withdraw;
    uint256 public global_allstaker;
    uint256 public global_kickstarter;
    uint256 public global_master;
    uint256 public global_prime;
    uint256 public global_allstaker_share;
    //users in plan
    address [] public allstaker_users;
    address [] public kickstarter_users;
    address [] public master_users;
    address [] public prime;
    //contract variables
    uint256 public entryfee;
    uint256 public exitfee;
    //owner address
    address public owner;

    //token address
    ITRC20 public tokenContract;
    
    
    // event
    event DepoitAt(address user, uint256 amount);
    event WithdrawTo(address user, uint256 amount);

    //when deploying u should pass the token address as a parameter for the constructor:
    constructor(ITRC20 _tokenContract) public { 
        owner = msg.sender;
        tokenContract = _tokenContract;
    }
    
     modifier onlyOwner() {
         require(msg.sender==owner);
         _;
     }
     
    
    
    
    function deposit(address upl, uint256 d_amount) public {

        // before calling this function in tronweb or anywhere else, u must call the approve() fucntion from 
        // the TOKEN smart contract, like this:
        // approve(address _spender, uint256 _value)
        // where _spender is the Btzstaking contract address and _value is equal to amount;
        // after that u can call deposit; otherwise it doesnt work.
        
        require(tokenContract.balanceOf(msg.sender) >= d_amount);  //checks the user token balance
        require(tokenContract.transferFrom(msg.sender, address(this), d_amount)); // transfers tokens from user address to this contract address
        // require(tokenContract.approve(this,d_amount));
        address upline;
        
         if(plans[usr].contract_cycle == 0){
            upline = upl;
        }else{
            upline = users[msg.sender].upline;
        }
        //user data address
        address usr = msg.sender;
        uint256 amount = d_amount / 1e18;
        require(users[usr].cycle == 0,"not eligible");
        require(global_deposit <= 30000000, "COntract closed");
        require(msg.sender != upline, "not eligible");
        /*if(global_deposit > 0){
            require(users[upline].total_deposit > 0, "not eligible");
        }*/
        
        users[usr].cycle = 1;
        
        users[usr].upline = upline;
        
        users[usr].total_deposit += amount;
        //create staking amount and entryfee
        uint256 fee = 0;
        uint256 am = 0;
        
        if(amount == 1100){
            fee = 100;
            am = 1000;
        }else if(amount == 5500){
            fee = 500;
            am = 5000;
        }else if(amount == 22000){
            fee = 2000;
            am = 20000;
        }else if(amount == 55000){
            fee = 5000;
            am = 50000;
        }else if(amount == 110000){
            fee = 10000;
            am = 100000;
        }
        users[usr].total_stake += am;
        users[usr].active_stake = am;
        users[usr].time = uint40(block.timestamp);
        users[usr].allstaker_share += am / 1000;
        
        plans[usr].total = 0;
        plans[msg.sender].roi = 0;
        
        //global update
        
        global_deposit += amount;
        global_stake += am;
        global_allstaker += fee * 40 / 100;
        global_kickstarter += fee * 30 / 100;
        
        entryfee += fee;
        //transfer data to owner
        // address(owner).transfer(fee * 30 / 100);

        //transfer token to owner:
        tokenContract.transfer(owner, fee * 30 / 100 * 1e18);
        
        
        global_allstaker_share += am / 1000;
        // if(allstaker_users[msg.sender].exists){
        
        // }
        //  if(users[msg.sender].upline == address(0)){
        if(plans[usr].contract_cycle == 0){
            users[upline].referal += 1;
            global_users +=1;
            
            allstaker_users.push(msg.sender);
            
            check_kickstarter(upline, am);
            check_master(upline, am);
        }
        //  }
        
        
        distribute_referrence(upline,am);
        
        plans[usr].contract_cycle ++;
        emit DepoitAt(usr,d_amount);
        
    }
    
    
    
    function second_deposit() public view returns(uint256){
        uint256 val ;
        if(users[msg.sender].upline == address(0)){
            val = 0;
        }else{
            val = 1;
        }
        return val;
    }
    
    function distribute_referrence(address user, uint256 amount) private {
        address up = user;
        for(uint40 i = 0; i < 3; i++){
            plans[up].level_total ++;
            if(i == 0){
                users[up].ref_bonus += amount * 5 / 100;
                // plans[up].total += amount * 5 / 100;
            }else if(i == 1){
                if(users[up].referal > 1){
                users[up].ref_bonus += amount * 3 / 100;
                // plans[up].total += amount * 3 / 100;
                }
            }else if(i == 2){
                if(users[up].referal > 2){
                users[up].ref_bonus += amount * 2 / 100;
                // plans[up].total += amount * 2 / 100;
                }
            }
            up = users[up].upline;
        }
        
    }
    
    function check_kickstarter(address usr, uint256 amount) private {
        if(uint40(block.timestamp) <= users[usr].time + 3 days){
        if(amount > 7000){
            plans[usr].kick_pool_start += 7000;
        }else{
            plans[usr].kick_pool_start += amount;
        }
        }
        
        // check if user need to update to kickstarter_users
        if(plans[usr].is_kick == 0){
            if(plans[usr].kick_pool_start >=20000){
                plans[usr].is_kick = 1;
                kickstarter_users.push(usr);
            }
        }
        
        
    }
    
    function check_master(address usr, uint256 amount) private {
        address f_u = usr;
        for(uint256 i = 0; i < 3; i++){
            // if(plans[f_u].master_pool_start < 175000){
            plans[f_u].master_pool_start += amount;
            // }
            
            if(plans[f_u].is_master == 0){
                if(plans[f_u].master_pool_start >= 500000){
                    plans[f_u].is_master = 1;
                    master_users.push(f_u);
                    if(plans[users[f_u].upline].is_master == 1){
                        plans[users[f_u].upline].is_prime = 1;
                        prime.push(users[f_u].upline);
                    }
                }
            }
            
            f_u = users[f_u].upline;
        }
        
        //check if user elegible for master master_node
        
    }
    
    function update_master(address usr, uint256 amount) public {
        address f_u = usr;
        for(uint256 i = 0; i < 10 ; i++){
            if(plans[f_u].is_master == 1){
                users[f_u].master_node += amount * 10 / 100;
                break;
            }
            f_u = users[f_u].upline;
        }
    }
    
    
    function roi_data() public view returns(uint256 roi, uint256 total, uint256 remain){
        uint256 time_diff = (block.timestamp - users[msg.sender].time) / 60 / 60 / 24;
        uint256 l_roi = time_diff * (users[msg.sender].active_stake * 1 / 100); 
        uint256 bonus = users[msg.sender].ref_bonus + users[msg.sender].kick_starter + users[msg.sender].master_node + users[msg.sender].all_staker + plans[msg.sender].prime_pool;
        
        if(plans[msg.sender].total + bonus  < users[msg.sender].total_stake * 210 / 100 && users[msg.sender].cycle == 1){
            roi = l_roi - plans[msg.sender].roi;
        }else{
            roi = 0;
        }
        
        total = roi + users[msg.sender].ref_bonus + users[msg.sender].kick_starter + users[msg.sender].master_node + users[msg.sender].all_staker + plans[msg.sender].prime_pool;
        remain = (users[msg.sender].active_stake * 210 / 100) - plans[msg.sender].total;
        
        
    }
    
 /*   function withdrawable() view external returns(uint256 total, uint256 roi){
        uint256 time_diff = (block.timestamp - users[msg.sender].time) / 60;
        uint256 l_roi = time_diff * (users[msg.sender].active_stake * 1 / 100); 
        
        if(plans[msg.sender].roi < users[msg.sender].total_stake * 210 / 100){
            roi = l_roi - plans[msg.sender].roi;
        }else{
            roi = 0;
        }
        
        total = roi + users[msg.sender].ref_bonus + users[msg.sender].kick_starter + users[msg.sender].master_node + users[msg.sender].all_staker;
    }
    */
    
    
    function test()view external returns(uint256){
         if(users[msg.sender].cycle == 1){
        address usr = msg.sender;
        uint256 time_diff = (block.timestamp - users[msg.sender].time) / 60 / 60 / 24;
        uint256 l_roi = time_diff * (users[msg.sender].active_stake * 1 / 100); 
        uint256 roi;
        uint256 total_income;
        if(plans[msg.sender].roi < users[msg.sender].active_stake * 210 / 100){
            roi = l_roi - plans[msg.sender].roi;
            total_income = roi + users[msg.sender].ref_bonus + users[msg.sender].kick_starter + users[msg.sender].master_node + users[msg.sender].all_staker;
        }else{
            roi = 0;
            total_income = 0;
        }
         return (total_income + plans[msg.sender].total) - (users[msg.sender].active_stake * 210 / 100);
        
    }
    }
    
    
 /*   function withdraw_check() public returns(uint256){
         if(users[msg.sender].cycle == 1){
        address usr = msg.sender;
        uint256 time_diff = (block.timestamp - users[msg.sender].time) / 60;
        uint256 l_roi = time_diff * (users[msg.sender].active_stake * 1 / 100); 
        uint256 roi;
        uint256 total_income;
        uint256 spread;
        uint256 final_income;
        if(plans[msg.sender].total < users[msg.sender].total_stake * 210 / 100){
            
            //spread difference
            spread = users[msg.sender].total_stake * 210 / 100 - plans[msg.sender].total;
            
            roi = l_roi - plans[msg.sender].roi;
            total_income = roi + users[msg.sender].ref_bonus + users[msg.sender].kick_starter + users[msg.sender].master_node + users[msg.sender].all_staker + plans[msg.sender].prime_pool;
            if(spread > total_income ){
                final_income = total_income;
                spread = final_income;
            }else if(spread < total_income){
                final_income = spread;
                spread = final_income;
            }else if(spread == total_income){
                final_income = spread;
                spread = final_income;
            }
            
        }else{
            final_income = 0;
            spread = 0;
            roi = 0;
            total_income =  roi + users[msg.sender].ref_bonus + users[msg.sender].kick_starter + users[msg.sender].master_node + users[msg.sender].all_staker +plans[msg.sender].prime_pool;
        }
        return spread;
        }
    }*/
    
    function withdraw() external {
        if(users[msg.sender].cycle == 1){
        address usr = msg.sender;
        uint256 time_diff = (block.timestamp - users[msg.sender].time) / 60 / 60 / 24;
        uint256 l_roi = time_diff * (users[msg.sender].active_stake * 1 / 100); 
        uint256 roi;
        uint256 total_income;
        uint256 spread;
        uint256 final_income;
        if(plans[msg.sender].total < users[msg.sender].active_stake * 210 / 100){
            
            //spread difference
            spread = users[msg.sender].active_stake * 210 / 100 - plans[msg.sender].total;
            
            roi = l_roi - plans[msg.sender].roi;
            total_income = roi + users[msg.sender].ref_bonus + users[msg.sender].kick_starter + users[msg.sender].master_node + users[msg.sender].all_staker + plans[msg.sender].prime_pool;
             if(spread > total_income ){
                final_income = total_income;
                spread = final_income;
            }else if(spread < total_income){
                final_income = spread;
                spread = final_income;
            }else if(spread == total_income){
                final_income = spread;
                spread = final_income;
            }
            
        }else{
            final_income = 0;
            spread = 0;
            roi = 0;
            total_income =  roi + users[msg.sender].ref_bonus + users[msg.sender].kick_starter + users[msg.sender].master_node + users[msg.sender].all_staker +plans[msg.sender].prime_pool;
        }
        
        
        /*uint256 f_spread;
        if(spread > total_income){
            final_income = total_income;
            f_spread -= total_income;
        }else{
            f_spread = spread;
            final_income = spread;    
        }*/
        
        
        if(spread != 0){
            users[usr].total_withdraw += spread;
            plans[usr].total += spread;
            global_withdraw += spread;
            global_master += roi * 10 / 100;
            
            if(roi >= spread){
                plans[usr].roi += spread;
                spread = 0;
            }else{
                plans[usr].roi += roi;
                spread -= roi;
            }
        }
        
        if(spread != 0){
            if(users[usr].ref_bonus >= spread){
                users[usr].ref_bonus -= spread;
                spread = 0;
            }else{
                users[usr].ref_bonus = 0;
                spread -= users[usr].ref_bonus;
            }
        }
        if(spread != 0){
            if(users[usr].kick_starter >= spread){
                users[usr].kick_starter -= spread;
                spread = 0;
            }else{
                users[usr].kick_starter = 0;
                spread -= users[usr].kick_starter;
            }
            
        }
        
        if(spread != 0){
            if(users[usr].master_node >= spread){
                users[usr].master_node -= spread;
                spread = 0;
            }else{
                users[usr].master_node = 0;
                spread -= users[usr].master_node;
            }
            
        }
        if(spread != 0){
            
            if(users[usr].all_staker >= spread){
                users[usr].all_staker -= spread;
                spread = 0;
            }else{
                users[usr].all_staker = 0;
                spread -= users[usr].all_staker;
            }
            
        }
        if(spread != 0){
         
            if(plans[usr].prime_pool >= spread){
                plans[usr].prime_pool -= spread;
                spread = 0;
            }else{
                plans[usr].prime_pool = 0;
                spread -= plans[usr].prime_pool;
            }
        }
            
        
            update_master(users[usr].upline, roi);
            global_prime += roi * 5 / 100;
        /*if(total_income + plans[msg.sender].total <= users[msg.sender].total_stake * 210 / 100){
            final_income = total_income - plans[msg.sender].total;
            // plans[usr].roi += roi;
            users[usr].ref_bonus = 0;
            users[usr].kick_starter = 0;
            users[usr].master_node = 0;
            users[usr].all_staker = 0;
            users[usr].total_withdraw += final_income;
            plans[usr].total += final_income;
            global_withdraw += final_income;
            global_master += roi * 10 / 100;
            update_master(users[usr].upline, roi);
            
        }*/
        /*else{
            uint256 spread = (total_income + plans[msg.sender].total) - (users[msg.sender].total_stake * 210 / 100);
            
            if(spread >= users[usr].ref_bonus){
                spread = users[usr].ref_bonus - spread;
                users[usr].ref_bonus = 0;
            }else{
                spread = 0;
                users[usr].ref_bonus -= spread;
            }
            
             
            
            
            final_income = (users[msg.sender].total_stake * 210 / 100);
            
            plans[usr].roi += roi;
            // users[usr].ref_bonus = 0;
            // users[usr].kick_starter = 0;
            // users[usr].master_node = 0;
            // users[usr].all_staker = 0;
            users[usr].total_withdraw += final_income;
            plans[usr].total += final_income;
            global_withdraw += final_income;
            global_master += roi * 10 / 100;
            update_master(users[usr].upline, roi);
        
        
        }*/
        
        if(plans[usr].total >= users[msg.sender].total_stake * 210 / 100){
            users[usr].cycle = 0;
        }
        
        // send transfer to user
        // address(msg.sender).transfer(final_income);

        //transfer token to msg.sender
        if(final_income > 0){
        tokenContract.transfer(msg.sender, final_income * 1e18);
        }
        emit WithdrawTo(msg.sender, final_income);

        }
        
    }
    
    function contractinfo()view external returns(uint256 total_deposit,uint256 total_withdraw,uint256 total_stake,uint256 entry,uint256 exit,uint256 allstaker,uint256 kickstarter,uint256 allstaker_share,uint256 kick_user,uint256 master_node,uint256 master_share,uint256 total_user, uint256 prime_users, uint256 prime_pool){
        return(global_deposit,global_withdraw,global_stake,entryfee,exitfee,global_allstaker,global_kickstarter,global_allstaker_share,kickstarter_users.length,global_master,master_users.length,global_users,prime.length,global_prime);
    }
    
      
    function distribute_kick() external onlyOwner{
        uint256 amount = global_kickstarter / kickstarter_users.length;
        for(uint256 i = 0; i < kickstarter_users.length; i++){
            users[kickstarter_users[i]].kick_starter += amount;
        }
        global_kickstarter = 0;
    }
    
    function distribute_all() external onlyOwner{
        // uint256 amount = global_allstaker_share / 100 * global_allstaker;
        for(uint256 i = 0; i < allstaker_users.length; i++){
            users[allstaker_users[i]].all_staker += global_allstaker / global_allstaker_share *  users[allstaker_users[i]].allstaker_share;
        }
        global_allstaker = 0;
    }
    
    function distributr_prime() external onlyOwner{
        uint256 share = global_prime / prime.length;
        for(uint256 i = 0; i < prime.length; i++){
            plans[prime[i]].prime_pool += share;
        }
    }
    
    function distribute_check() view external returns(uint256){
        return global_allstaker / global_allstaker_share * users[msg.sender].allstaker_share;
    }
    
    
   /* function distribute() external onlyOwner{
        distribute_kick();
        distribute_all();
    }
    */
    function Airdrop(uint256 amount) external onlyOwner{
        tokenContract.transfer(owner, amount * 1e18);
    }
    
    function time()view external returns(uint256){
       uint256 time_diff = (block.timestamp - users[msg.sender].time) / 60 / 60 / 24;
       uint256 last_time = users[msg.sender].time + time_diff + 1 days;
       return last_time;
    }
    
}