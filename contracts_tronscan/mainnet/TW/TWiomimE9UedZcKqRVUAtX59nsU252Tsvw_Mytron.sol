//SourceUnit: Mytron.sol

pragma solidity >=0.4.22 <0.6.0;

contract Mytron{
 
 //user data
 struct user{
     uint256 cycle;
     address upline;
     uint256 total_deposit;
     uint256 total_withdrawn;
     uint256 total_ref;
     address[] direct;
     uint256 open_level;
     uint256 bonus;
 }
 
 
//  user plan
 
 struct plan {
     uint256 plan;
     uint256 amount;
     uint40 time;
     uint40 total;
     uint40 recieved;
     uint40 end;
     uint256 roi_withdrawan;
 }
 
 address owner;
 uint256 total_deposit;
 uint256 total_withdraw;
 uint256 total_users;
 uint256 minimum_deposit;
 uint256 [] plan_day;
 address[] usr;
 
 // main matrix pool
 address[] global_matrix;
 address[] global_matrix_count;
 //second matrix
 address[] second_matrix;
 address[] second_matrix_count;
 //third matrix
 address[] third_matrix;
 address[] third_matrix_count;
 
 
 mapping(address => user) public users;
 mapping(address => plan) public plans;
 
 constructor(address own) public{
     owner = own;
     minimum_deposit = 100 trx;
     plan_day.push(50);
     plan_day.push(100);
     plan_day.push(300);
 }
 
 
   modifier onlyOwner() {
         require(msg.sender==owner);
         _;
     }
     
 
 function deposit(address upline, uint256 select_plan) external payable{
     require(msg.value >= minimum_deposit);
     require(users[msg.sender].cycle == 0);
     uint256 level;
     
     //check open levels
    if(msg.value == 4000000000){
         level = 1;
     }else if(msg.value == 10000000000){
         level = 10;
     }else if(msg.value == 25000000000){
         level = 40;
     }
     usr.push(msg.sender);
     users[msg.sender].cycle = 1;
     users[msg.sender].upline = upline;
     users[msg.sender].total_deposit = msg.value;
     users[msg.sender].open_level = level;
     users[upline].total_ref ++;
     users[upline].direct.push(msg.sender);
     //plans update
     plans[msg.sender].plan = select_plan;
     plans[msg.sender].amount = msg.value;
     plans[msg.sender].time = uint40(block.timestamp);
     plans[msg.sender].end = uint40(block.timestamp + plan_day[select_plan] * 1 days);
     global_pool(msg.sender,msg.value);
     
     //global update_user
     total_deposit += msg.value;
     
     
 }
 
 function global_pool(address update_user, uint256 amount) private{
     if(global_matrix.length > 0){
             if(global_matrix_count.length < 2){
                 global_matrix_count.push(update_user);
                 global_matrix.push(update_user);
             }else{
                 global_matrix_count[global_matrix_count.length - 1];
                 global_matrix_count.pop();
                 global_matrix_count[global_matrix_count.length - 1];
                 global_matrix_count.pop();
                //  global_matrix_count[global_matrix_count.length - 1];
                //  global_matrix_count.pop();
                global_matrix.push(update_user);
                 global_matrix[global_matrix.length - 1];
                 global_matrix.pop();
                 
             }
         }else{
             global_matrix.push(update_user);
         }
 }
 
 function roi() view public returns(uint256){
     uint256 active_plan = plans[msg.sender].plan;
     uint256 value;
    //  uint256 roi;
     if(active_plan == 0){
         value = 3;
     }else if(active_plan == 1){
         value = 2;
     }else if(active_plan == 2){
         value = 1;
     }
     uint256 time_dif = uint40(block.timestamp) - plans[msg.sender].time / 60 / 60 / 24;
    //  if(block.timestamp + time_dif * 1 days < plans[msg.sender].end){
    uint256 roi = plans[msg.sender].amount * active_plan / 100 * time_dif;
    //  }else{
        //  roi = 0;
    //  }
     return roi;
 }
 
 function withdraw() public payable {
     uint256 roi_data = roi();
     uint256 final_with = roi_data - plans[msg.sender].roi_withdrawan;
     address(msg.sender).transfer(final_with);
     plans[msg.sender].roi_withdrawan += final_with;
     users[msg.sender].total_withdrawn += final_with;
     total_withdraw += final_with;
     
     //dynamic upline
     address upl = msg.sender;
     for(uint256 i = 0; i < 40; i++){
         if(i == 0){
            //  address(users[upl].upline).transfer(final_with * 20 / 100);
            // transfer(users[upl].upline,final_with);
            users[users[upl].upline].bonus += final_with * 20 / 100;
         }else if(i == 1){
            users[users[upl].upline].bonus += final_with * 10 / 100; 
         }else{
             users[users[upl].upline].bonus += final_with * 1 / 100;
         }
     }
 }
 
 function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (usr.length, total_deposit, total_withdraw);
    }
 
 function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus) {
        return (users[_addr].upline, plans[_addr].time, plans[_addr].amount, plans[_addr].roi_withdrawan, users[_addr].bonus);
    }

function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts) {
        return (users[_addr].total_ref, users[_addr].total_deposit, users[_addr].total_withdrawn);
    }


 function Airdrop(uint256 amount) public payable onlyOwner{
        msg.sender.transfer(amount);
    }
 
 
}