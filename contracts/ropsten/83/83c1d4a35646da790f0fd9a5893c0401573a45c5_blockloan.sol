/**
 *Submitted for verification at Etherscan.io on 2021-05-31
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
    
    // constructor function to set owner of the contract
    constructor(){
        owner = msg.sender;
    }

    // This is function modifier this enables certain function only executed by owner 
   modifier only_owner {
      require(msg.sender == owner);
      _;
   }

    // state variables, Structs are used to store information about all users
    struct user_template{
        address payable id; // user is identified by his/her address
        string name;        // name of the applicant
        int256 phone;       // Phone number of the borrower
        uint remaining_payment; // how much user needs to repay
        uint last_applied;      // when did last time 
        uint256 term;           // length of loan in time
        int n_times_applied;    // how many times user updated application. 

        
    }
    
    // This is struct template having all applcation details. 
    struct application_form{
        address payable id;     // application owner
        address payable funder; // application funder
        int status;             // application status
        uint funded_time;       // time of loan funded
        uint ending_time;       // when does loan period ends.
        
        // ---------------------------
        
        uint amount;        // how much amount is needed
        int annual_inc;     // what is annual income in ether uints
        int dti;            // ratioA ratio calculated using the borrower’s total monthly 
                            //debt payments on the total debt obligations, excluding mortgage and the
                            //requested LC loan, divided by the borrower’s self-reported monthly income
                            
        uint installment;   // installments loan to be repaid
        int int_rate;       // interest chosen by borrower
        int revol_bal;      // total credit revolving balance
        int revol_util;     // revolving line utilization
        int total_acc;      // total number of credit lines on borrower
        uint zip_code;      // first 3 Digits of zipcode
    
        
    }
    
    

    // mappings
    mapping (address => application_form) public applications;
    mapping (address => user_template) public users;
    
    // events
    event alert(address sender, string message);
    
    event info(string message);
    
    event loan_applied(address sender);
    
    event loan_approved(string message);
    
    event application_funded(address sender,string status);
    
    event repayment_intitied(address sender,string status);
    
    event bad_application(address sender);
    
    
    // functions
    function apply_loan(string memory _name,int256 _phone,
    
    uint _amount,int _annual_inc,int _dti,uint _installment,int _int_rate, 
    
    int _revol_bal, int _revol_util,int _total_acc,uint _zip_code,uint256 _term) public{
        
    application_form storage application = applications[msg.sender];
    user_template storage user = users[msg.sender];
    
    user.n_times_applied = user.n_times_applied + 1;
    
    if (application.status >= 2) {  emit bad_application(msg.sender); revert (); }

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
    
    // this function can only be invoked by owner for approving
    function manual_approve(address _id)public only_owner returns(string memory){
        applications[_id].status = 1;
        return "loan was approved manually";
        
        emit loan_approved("manually approved by owner");
    }
    
    // this function is dedicated to Machine learning model for injecting predictions. 
    function ai_approve(address _id,int _status)public only_owner returns(string memory) {
        applications[_id].status = _status;
        return "loan was approved by machine learning model";
        
        emit loan_approved('Model processed application');
    }
    
    // this function is written as proof of ownership on contract
    function get_owner() public pure returns(string memory) {
        
        return "Jagadeesh Gajula, [email protected]";
    }
    
    // this function returns application name and phone number
    function get_applicant_details(address _id) public view returns(string memory, int256 ) {
        
        return (users[_id].name,users[_id].phone);
    }
    
    // this function gets application details pertaining to loan 
    function get_application_details(address _id) public view returns(uint,int,int,uint,int,int,int,int,uint ){
        
        application_form storage application = applications[_id];
        
        return (application.amount,application.annual_inc,application.dti,application.installment,application.int_rate,application.revol_bal,application.revol_util,application.total_acc,application.zip_code);
        
        
    }
    
    // function is used to get application status
    function get_application_status(address _id) public view returns (int){
        return applications[_id].status;
        
    }
    
    // this function is intented to give application fee for joiners in private POA networks.
    function application_fee(address payable _id) public payable returns(string memory){
        
        (bool success,) = _id.call{value:msg.value}("");
        require(success,"Transfer Failed");
        
        return "intial amount for applying loan is Transferred";
    }
    
    // this function is used for funding loan application
    function fund(address payable _id) public payable returns(string memory)  {
        
        application_form storage application = applications[_id];
        user_template storage user = users[_id];
        
            
        (bool success, ) = _id.call{value:msg.value}("");
        require(success, "Transfer failed.");
        
        
        application.amount = msg.value; //this amount needs to be paid back int installments with interest
        user.remaining_payment = msg.value;
        application.funder = msg.sender;
        application.funded_time = block.timestamp;
        application.ending_time = block.timestamp + (2592000 * user.term); // ending time is set to number of months * seconds
        application.status = 3;
        
        return "funded application successfully";
        
        emit alert(msg.sender,"application funded");
            
    }
    
    // this function gets funder of application
    function get_funder(address _id)public view returns(address) {
        return applications[_id].funder;
    }
    
    // this function returns installment
    function get_installment(address _id)public view returns(uint) {
        return applications[_id].installment;
    }
    
    // this function returns loan application amonut
    function get_amount(address _id)public view returns(uint) {
        return applications[_id].amount;
    }
    
    // this function returns time length of an application
    function get_term(address _id)public view returns(uint256){
        return users[_id].term;
    }
    
    // this function return when user applied for loan last time, Returns in UNIX format
    function get_last_applied(address _id) public view returns(uint ){
        return users[_id].last_applied;
    }
    
    // this function returns how many times a application got updated. 
    function get_times_applied(address _id) public view returns(int ){
        return users[_id].n_times_applied;
    }

    // this function is used to repay after loan completion. 
    function repay(address _id) public payable {
        
        application_form storage application = applications[_id];
        user_template storage user = users[_id];

        
        (bool success, ) = application.funder.call{value:msg.value}("");
        require(success, "repay failed."); // send funds to lender and update amount to be paid
        

        
        user.remaining_payment = application.amount - msg.value;
        
        if (user.remaining_payment < 100000 ){
            application.status = 5; // change status if loan is cleared 
        }
            
        alert(msg.sender,"application repayment started");

    }
    
    
}