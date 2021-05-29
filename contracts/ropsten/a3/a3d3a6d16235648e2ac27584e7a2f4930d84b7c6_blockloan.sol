/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;

contract blockloan{
    
    // application status: 
    // 0: applied 
    // 1: approved
    // 2: rejected 
    // 3: funded 
    // 4: repayment 
    // 5: cleared 
    // 6: re-applied
    
    address payable owner;
    
    constructor(){
        owner = msg.sender;
    }


   modifier only_owner {
      require(msg.sender == owner);
      _;
   }

    // state variables 
    struct user_template{
        address payable id;
        string name;
        int256 phone;
        uint remaining_payment;
        uint last_applied;
        uint256 term;
        int n_times_applied;

        
    }
    
    struct application_form{
        address payable id;
        address payable funder;
        int status;
        uint funded_time;
        uint ending_time;
        
        // ---------------------------
        
        uint amount;
        int annual_inc;
        int dti;
        uint installment;
        int int_rate;
        int revol_bal;
        int revol_util;
        int total_acc;
        uint zip_code;

        
    }
    
    

    // mappings
    mapping (address => application_form) public applications;
    mapping (address => user_template) public users;
    
    
    
    // functions
    function apply_loan(string memory _name,int256 _phone,
    
    uint _amount,int _annual_inc,int _dti,uint _installment,int _int_rate, 
    
    int _revol_bal, int _revol_util,int _total_acc,uint _zip_code,uint256 _term) public{
        
    application_form storage application = applications[msg.sender];
    user_template storage user = users[msg.sender];
    
    user.n_times_applied = user.n_times_applied + 1;
    
    if (application.status >= 2) { revert (); }

     user.name = _name;
     user.phone = _phone;
     user.id = msg.sender;
     application.id = msg.sender;
     user.term = _term;
     
     
     application.amount = _amount;
     application.annual_inc = _annual_inc;
     application.dti = _dti;
     application.installment = _installment;
     application.int_rate = _int_rate;
     application.revol_bal = _revol_bal;
     application.revol_util = _revol_util;
     application.total_acc = _total_acc;
     application.zip_code = _zip_code;
     
     
     application.status = 0;
     user.last_applied = block.timestamp;
     

     
    }
    
    
    function manual_approve(address _id)public only_owner returns(string memory){
        applications[_id].status = 1;
        return "loan was approved manually";
    }
    
    function ai_approve(address _id,int _status)public only_owner returns(string memory) {
        applications[_id].status = _status;
        return "loan was approved by machine learning model";
    }
    
    
    function get_owner() public pure returns(string memory) {
        
        return "Jagadeesh Gajula, [email protected]";
    }
    
    function get_applicant_details(address _id) public view returns(string memory, int256 ) {
        
        return (users[_id].name,users[_id].phone);
    }
    
    function get_application_details(address _id) public view returns(uint,int,int,uint,int,int,int,int,uint ){
        
        application_form storage application = applications[_id];
        
        return (application.amount,application.annual_inc,application.dti,application.installment,application.int_rate,application.revol_bal,application.revol_util,application.total_acc,application.zip_code);
        
        
    }
    
    function get_application_status(address _id) public view returns (int){
        
        
        return applications[_id].status;
        
    }
    
    function application_fee(address payable _id) public payable returns(string memory){
        
        (bool success,) = _id.call{value:msg.value}("");
        require(success,"Transfer Failed");
        
        return "intial amount for applying loan is Transferred";
    }
    
    
    function fund(address payable _id) public payable returns(string memory)  {
        
        application_form storage application = applications[_id];
        user_template storage user = users[_id];
        
            
        (bool success, ) = _id.call{value:msg.value}("");
        require(success, "Transfer failed.");
        
        
        application.amount = msg.value; //this amount needs to be paid back int installments with interest
        user.remaining_payment = msg.value;
        application.funder = msg.sender;
        application.funded_time = block.timestamp;
        application.ending_time = block.timestamp + (2592000 * user.term);
        application.status = 3;
        
        return "funded application successfully";
            
    }
    
    function get_funder(address _id)public view returns(address) {
        return applications[_id].funder;
    }
    
    function get_installment(address _id)public view returns(uint) {
        return applications[_id].installment;
    }
    
    function get_amount(address _id)public view returns(uint) {
        return applications[_id].amount;
    }
    
    function get_term(address _id)public view returns(uint256){
        return users[_id].term;
    }
    
    function get_last_applied(address _id) public view returns(uint ){
        return users[_id].last_applied;
    }
    
    function get_times_applied(address _id) public view returns(int ){
        return users[_id].n_times_applied;
    }

    function repay(address _id) public payable {
        
        application_form storage application = applications[_id];
        user_template storage user = users[_id];

        
        (bool success, ) = application.funder.call{value:msg.value}("");
        require(success, "repay failed.");
        

        
        user.remaining_payment = application.amount - msg.value;
        
        if (user.remaining_payment < 100000 ){
            application.status = 5;
        }
            

    }
    
    
}