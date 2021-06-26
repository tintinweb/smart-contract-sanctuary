/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl_1year{
    uint256 start_time;
    string timestart_record;
    address payable account_address;
    string m = "It's time to Destroy";
    string s = "not yet";
    
    struct Cust{
        address payable customer;
        uint256 balance;
    }
    
    mapping(address=>Cust) address_Cust;
    
    constructor(string memory what_time_is_now, address payable hodl_account){
        start_time = block.timestamp;
        timestart_record = what_time_is_now;
        account_address = hodl_account;
    }
    
    function Timeelapsed() public view returns (uint256){
        uint256 t = block.timestamp - start_time;
        return t;
    }
    
    function ContractStartTime() public view returns (string memory){
        return timestart_record;
    }
    
    //function CheckBalance() public view returns (uint256){
    //    return address.balance;
    //}
    
    function CHeckisTimeToDestroy() public view returns (string memory){
        uint256 ti = block.timestamp - start_time;
        
        if(ti >= uint256(60)){
            //string storage m = "Destroy Done";
            return m;
        }else{
            //string storage s = "not yet";
           return s;
        }
        
    }    
    
        
    function TimeToDestroy() external{
        uint256 ti = block.timestamp - start_time;
        
        
        if(ti >= uint256(365*24*60*60)){
           selfdestruct(payable(account_address));
            //string storage m = "Destroy Done";
            //return m;
        }else{
            //string storage s = "not yet";
           // return s;
        }
        
    }
    
    fallback() external payable{
    }
    
    receive() external payable{
    }
    

}