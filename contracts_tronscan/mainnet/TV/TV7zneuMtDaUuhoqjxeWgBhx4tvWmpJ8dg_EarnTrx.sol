//SourceUnit: earntrx.sol

///////////////////////
///////////
//// EarnTRX.net
//////////
//////////////////////

pragma solidity ^0.5.0;


contract EarnTrx{
    
    uint256 count=1;
    address payable public owner;
                     
    struct User {
        uint256 userId;
        address payable sponserAddress;
		address payable userAddress;
	}
	
    mapping(address => User) public users;
	
    constructor(address payable _owner) public {
	    owner = _owner;
         
		User memory _ownerdata = User({
            userId:count,
            sponserAddress:address(0),
            userAddress:owner

		});

		users[_owner] = _ownerdata;
	    
	}
     
    
    function register(address payable _sponser) public payable {

	  if(users[_sponser].userId==0)
	   {
	     revert("No Sponser");
	   }
	   
	   if(users[msg.sender].userId!=0)
	   {
	     revert("Address exists");
	   }
	   
	   if(msg.value != 600 trx)
	   {
	     revert("Join by paying 600 TRX");
	   }
		
		count++;

		User memory user = User({
            userId:count,
            sponserAddress:users[_sponser].userAddress,
            userAddress:msg.sender
			
		});
		
		users[msg.sender] = user;
	    
	    address payable upline;
	    address payable start=msg.sender;
	   
		for(uint8 i=0; i < 5; i++){
            if(users[start].sponserAddress==address(0))
             {
               break;
             }
             upline=users[start].sponserAddress;
             if(i==0){
                upline.transfer(200 trx);
             }
              if(i==1){
                upline.transfer(100 trx);
             }
              if(i==2){
                upline.transfer(100 trx);
             }
              if(i==3){
                upline.transfer(50 trx);
             }
              if(i==4){
                upline.transfer(50 trx);
             }
             start=users[start].sponserAddress;
		}

	}

	/*function withdraw() public payable{
        require(msg.sender == owner,"only Owner Can Withdraw Fund");
		uint256 B = address(this).balance;
		owner.transfer(B);
		emit Withdraw(owner, B);
    }*/
	function withdraw(uint256 valuet) public {
		require(msg.sender == owner,"only Owner Can Withdraw Fund");
		uint256 contractBalance = address(this).balance/1e6;
		require(contractBalance >= valuet,"No Value");
		owner.transfer(valuet*1e6);
		emit Withdraw(owner, valuet*1e6);
	}
    
    event Withdraw(
    	address add,
    	uint256 value
    );
    
}