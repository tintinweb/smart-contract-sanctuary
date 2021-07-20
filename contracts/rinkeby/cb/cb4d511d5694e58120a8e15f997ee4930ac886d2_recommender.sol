/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity ^0.4.17 ~ 0.4.24;




// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract RTInterface{
    function set_recommender(address rt)public;
    function be_recommender()public payable;
    function get_recommender(address user)public view returns(address);
    function get_qualifications(address user)public view returns(bool);
    function get_parameter(uint p1, uint p2)public view returns(uint);
}



contract recommender is RTInterface{
    using SafeMath for uint; 
    
    
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    
    address owner;
    
    
    mapping(uint=>mapping(uint=>uint))public rule_info;
    mapping(address=>mapping(uint=>uint))public rt_info;
    // 1.LV1_no  2.LV2_no  3.LV3_no  
    
    mapping(address=>address)public my_recommender;
    mapping(address => bool)public qualifications;
   
    


    
    constructor()public {
        owner = msg.sender;
        rule_info[1][1] = 5*10**16;
    }
    
    
    
    function be_recommender()public payable{
       require(msg.value >= rule_info[1][1]);
       require(qualifications[msg.sender] == false);
       owner.transfer(msg.value);
       qualifications[msg.sender] = true;
    }
    

    
    
   
    
    function set_recommender(address rt)public {
        require(qualifications[msg.sender] == true); 
        require(my_recommender[msg.sender] == address(0x0));
        require(msg.sender != rt);
  
        my_recommender[msg.sender]=rt;
        set_rt_numbrt(msg.sender);
    }
    
    
    
    function set_rt_numbrt(address user)private{
        address rt = user;
        for(uint i=1; i<=3; i++){
            rt = my_recommender[rt];
            rt_info[rt][i] = rt_info[rt][i].add(1);
        }
    }

    
    
    
    function get_recommender(address user)public view returns(address){
        return my_recommender[user];
    }
    
    
    function get_qualifications(address user)public view returns(bool){
        return qualifications[user];
    }
    
    
    
    
    
    //------------------ctrl_parameter----------------------------
    
    
    function set_parameter(uint p1, uint p2, uint p3)public onlyOwner{
        rule_info[p1][p2] = p3;
    }
    
    
    function get_parameter(uint p1, uint p2)public view returns(uint){
        return rule_info[p1][p2];
    }
   
    
    
    
    
    
}