/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Pyramid_scheme {
    uint256 private daily_interest_percentage ;
    string timestart_record;
    string contract_owner_name;
    uint256 start_time;
    address payable contract_owner_address;
  
    struct Cust{
        address payable cust_address;
        uint256 number;
        uint256 deposit_time;
        uint256 balance;
        uint256 interest_gain;
        bool Cust_exist;
    }
    
    mapping(address=>Cust) address_Cust;
    
    event event_addCustomer(address customer);
    event event_Deposit(address customer, uint256 value);
    event event_receive(address Donor,uint256 Value);

    constructor(string memory what_time_is_now, string memory contract_builder_name, address payable contract_builder_address,uint256 set_daily_interest_percentage){
        start_time = block.timestamp;
        timestart_record = what_time_is_now;
        contract_owner_name = contract_builder_name;
        contract_owner_address = contract_builder_address;
        daily_interest_percentage = set_daily_interest_percentage;
    }
    
    address[] all_customer;
    
    modifier isConstractOwner(){
        require(msg.sender == contract_owner_address, "You are not contract owner!");
        _;
    }
    
    
    
    function AddCustomer(address payable customer) public {
        all_customer.push(customer);
        address_Cust[customer].number = all_customer.length;
        address_Cust[customer].Cust_exist = true;
        address_Cust[customer].deposit_time = 0;
        emit event_addCustomer(customer);
    }
    
    function AddBalance(address payable customer, uint256 value) public {
        require(address_Cust[customer].Cust_exist, "You are not our customer.Please add first.");
        address_Cust[customer].balance += value;
        address_Cust[customer].deposit_time = block.timestamp;

    }
    
   // function CheckInterestgain (address payable customer) public returns(uint256){
   //     address_Cust[customer].interest_gain +=  (block.timestamp - address_Cust[customer].deposit_time)*daily_interest_percentage;
   //     return address_Cust[customer].interest_gain;
   // }
    
    
    function CheckBalance (address payable customer) public view returns(uint256){
        require(address_Cust[customer].deposit_time != 0, "no Deposit data!");
        uint interest_gain =  (block.timestamp - address_Cust[customer].deposit_time)*daily_interest_percentage/8640000;
        return address_Cust[customer].balance + interest_gain ;
    }
    
    function Timeelapsed(address payable customer) public view returns (uint256){
        require(address_Cust[customer].deposit_time != 0, "no Deposit data!");
        uint256 t = block.timestamp - address_Cust[customer].deposit_time;
        return t;
    }
    
    function GetallBalance() external view returns(uint256) {
        uint256 sum = 0;
        
        for(uint i=0;i<all_customer.length;i++){
            address temp = all_customer[i];
            uint interest_gain =  (block.timestamp - address_Cust[temp].deposit_time)*daily_interest_percentage/8640000;
            sum += address_Cust[temp].balance + interest_gain;
        }
       
        return sum ;
    }
    
    function TimeToDestroy() external isConstractOwner{
        selfdestruct(payable(contract_owner_address));
    }
    


    fallback() external payable{
    }
    
    receive() external payable{
        emit event_receive(msg.sender,msg.value);
    }
    
}