/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity 0.8.0;

contract TrxChain {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 deposit_payouts;
        uint256 deposit_amount;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_withdraw;
        bool userStatus;
    }
    
    
     address payable public owner;
    
   
      mapping(address => mapping(uint=>User)) public users;
      
        uint256 public total_users = 1;
        uint256 public total_deposited;
        uint256 public total_withdraw;
        
        uint256[4][] public cycles=[[10e6,100e6,150],[101e6, 200e6, 130],[201e6, 300e6, 120],[301e6, 400e6, 100]];
        
       
      
        constructor(address payable _owner)  {
        owner = _owner;
    
        }
        
      
        
        function deposit(address  _upline, uint _cycle)public payable{
            require(_cycle >= 0 && _cycle <= 3, "Invalid cycle"); 
            require(_upline != address(0),"Upline address is invalid");
            require(msg.sender != address(0), "Sender address is invalid");
            require(cycles[_cycle][0] <= msg.value && cycles[_cycle][1] >= msg.value, "Bad Amount" );
            require(!users[msg.sender][_cycle].userStatus, "User has already deposited in the cycle");
            
            address  upline;
            
            if(users[_upline][_cycle].userStatus == true){
                upline = _upline;
                
            }
            else{
                upline = owner;
                
            }
            
           if(users[msg.sender][_cycle].upline == address(0)){
               users[msg.sender][_cycle].upline = upline;
               users[upline][_cycle].referrals++;
               uint direct_bonus;
               direct_bonus = (msg.value*10)/100;
               if(users[upline][_cycle].referrals <= 10 && upline != owner){
                  payable(upline).transfer(direct_bonus);
                   
               }
               else{
                    payable(owner).transfer(direct_bonus);
               }
           }
          
          
          users[msg.sender][_cycle].deposit_amount = msg.value;
          users[msg.sender][_cycle].deposit_time = uint40(block.timestamp);
          users[msg.sender][_cycle].total_deposits = users[msg.sender][_cycle].total_deposits + msg.value;
          users[msg.sender][_cycle].total_withdraw = 0;
          users[msg.sender][_cycle].payouts = 0;
          users[msg.sender][_cycle].deposit_payouts= 0;
          users[msg.sender][_cycle].referrals = 0;
          users[msg.sender][_cycle].userStatus = true;
          total_users++;
          total_deposited = total_deposited + msg.value;
          
        }
        
          
    function maxPayoutOf(uint256 _amount, uint256 _cycle) view external returns(uint256) {
        return _amount * cycles[_cycle][2]  / 100;
    }

        
     
     function payoutOf(address _addr, uint256 _cycle)view external returns(uint256 payout, uint256 max_payout){
        max_payout = this.maxPayoutOf(users[_addr][_cycle].deposit_amount,_cycle);
        
        if(users[_addr][_cycle].deposit_payouts < max_payout) {
          payout = (users[_addr][_cycle].deposit_amount * ((block.timestamp - users[_addr][_cycle].deposit_time) / 1) / 100) - users[_addr][_cycle].deposit_payouts;
       if(users[_addr][_cycle].deposit_payouts + payout > max_payout) {
          payout = max_payout - users[_addr][_cycle].deposit_payouts;
     }
        }
     }
     
        function withdraw(uint256 _cycle)payable external{
            
            (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender,_cycle);
        require(users[msg.sender][_cycle].userStatus == true, "User Status is not active");    
        require(users[msg.sender][_cycle].payouts < max_payout, "Full payouts");
  
        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender][_cycle].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender][_cycle].payouts;
            }
            payable(msg.sender).transfer(to_payout);
                         
 
            users[msg.sender][_cycle].deposit_payouts += to_payout;
            users[msg.sender][_cycle].payouts += to_payout;
            users[msg.sender][_cycle].total_withdraw += total_withdraw;
            
            
            
        }
        
        if(users[msg.sender][_cycle].deposit_payouts >= max_payout){
            
            users[msg.sender][_cycle].payouts = 0;
            users[msg.sender][_cycle].deposit_amount = 0;
            users[msg.sender][_cycle].deposit_payouts = 0;
            users[msg.sender][_cycle].deposit_time = 0;
            users[msg.sender][_cycle].userStatus = false;
            

        }
            
        }
            
    
}