/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity ^0.4.25;

 contract newstart {
     
       struct User {
        
       address referer;
       uint Kamal;
       
       
       }
      
      
      address public owner;
     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
      mapping(address => User) public users;
      mapping(address => uint256) public token;
      
      
   
    constructor()public{
        owner = msg.sender;
        
        }
        
         modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
        function balanceOf(address _owner) constant returns (uint256 balance) {}
        function tokenTransfer(address _token) public view{
            
            
        }
        
        
        	function contractBalance() constant returns (uint256 balance) {
		return this.balance;
	}
       function addUser( address referer) public payable {
       
       address sender = msg.sender;
       
       
       uint Kamalbal = msg.value*8/100000000000000;
       
        uint value = msg.value*35/100;
      owner.transfer(value);
       require(referer != msg.sender);
      
      require(msg.value >= 100 finney);
      require(msg.value <= 200 finney);
      uint referervalue2 = msg.value*60/100;
      referer.transfer(referervalue2);
       User memory newUser;
       
       newUser.referer = referer;
       newUser.Kamal = Kamalbal;
        users[sender] = newUser;
       }
        
       
    
     
 }