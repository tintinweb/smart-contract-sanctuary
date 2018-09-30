pragma solidity^0.4.25;
contract Action
{event Log(string  eventMessage);
      constructor () public {
	      
	      emit Log("Contract deployed successfully");
	    }
    
    
      function getMessage() public constant returns (string dataHash)
      {
          return("welcome");
      }
	   
	   
}