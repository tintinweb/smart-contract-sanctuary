/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity 0.6.0;

contract MyContract{
    
    uint uidCout=100;
    
    struct User {
        uint user_id;
        string user_name;
		uint sponser_id;
		uint wallet1;
		uint wallet2;
		uint wallet3;
		uint wallet4;
		uint wallet5;
		uint wallet6;
	}
	
	mapping (uint => User) public alluser;

	
	constructor() public {
	    
	    User memory owner = User({
	    	user_id:uidCout,
		    user_name:'owner',
		    sponser_id:0,
		    wallet1:0,
		    wallet2:0,
		    wallet3:0,
		    wallet4:0,
		    wallet5:0,
		    wallet6:0
		});
		alluser[uidCout] = owner;
	}
	
	
	function register(uint _sponserId,string memory username) public{
	  
	   if(alluser[_sponserId].user_id==0)
	   {
	     revert("No SponserId");
	   }
	   
	   uidCout++;
	
		User memory user = User({
		    user_id:uidCout,
		    user_name:username,
		    sponser_id:alluser[_sponserId].user_id,
		    wallet1:0,
		    wallet2:0,
		    wallet3:0,
		    wallet4:0,
		    wallet5:0,
		    wallet6:0
		});

		alluser[uidCout] = user;

	}
	

    function getref(uint _userid) public view returns (uint[] memory) {
        
       if(alluser[_userid].user_id==0)
	   {
	     revert("No User");
	   }
    
        uint j=0;
        uint start=_userid+1;
        uint length=5;
        uint[] memory array = new uint[](length);
      
        for (uint i = start; i <= uidCout; i++) {
         
            if(alluser[i].sponser_id == _userid)
	        {
	            array[j]=alluser[i].user_id;
	            j++;
	           
	        }
        }
        return  array;
    }
    
     function getUp(uint _userid) public view returns (uint[] memory) {
        
       if(alluser[_userid].user_id==0)
	   {
	     revert("No User");
	   }
	   
	    if(_userid==100)
	   {
	     revert("No upline");
	   }
    
        uint j=0;
        uint start=_userid;
        uint length=5;
        uint[] memory array = new uint[](length);
      
        for (uint i = 0; i <length; i++) {
            
             if(start==100){
                break;
            }
         
            array[j]=alluser[start].sponser_id;
            j++;
            start=alluser[start].sponser_id;
        }
        return  array;
    }
	
}