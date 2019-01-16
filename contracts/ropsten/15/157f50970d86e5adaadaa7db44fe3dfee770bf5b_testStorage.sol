pragma solidity ^0.4.0;

contract testStorage {

    uint public a;
    address public b;
    
    function get_money() public payable{
    }
    
    function get_balance() public view returns(uint){
      return address(this).balance;
      //return this.balance;
    }
    
    
    function set_a (uint a_) public {
        a = a_;
    }
	
	function set(uint a_,address b_) public{
	    a = a_;
	    b = b_;
	}
	
	function get() public view returns(uint,address){
	    return (a,b);
	}
	
	function get_add(uint x) public pure returns(uint){
	    return x+1;
	}
	
}