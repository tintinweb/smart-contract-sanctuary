// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import  "./ISetToken.sol";
import  "./IBasicIssuanceModule.sol";


interface IIssuance {
    


function issue(ISetToken _setToken, uint256 _quantity, address _to) external ;

function getRequiredComponentUnitsForIssue(
        ISetToken _setToken,
        uint256 _quantity
    ) external returns(address[] memory, uint256[] memory);


}





contract IssueSET {
    
    address public maticAToken = 0x4c07ce6454D5340591f62fD7d3978B6f42Ef953e ;
    address public maticBToken = 0x1687d4BDE380019748605231C956335a473Fd3dc ;
    address public maticsetTokenPABaddress = 0xDB022E4695B067A08106411035efD3b08549E232;
    IBasicIssuanceModule issuance;
    
    address public basicIssuanceModuleAddress ;
   	 
	   ISetToken mySets = ISetToken(maticsetTokenPABaddress);
	   
	   
	 //  IIssuance issuance ;
	   
	   
	   constructor(address _issuance ) public {
	       
	        basicIssuanceModuleAddress = _issuance;
	        issuance = IBasicIssuanceModule(basicIssuanceModuleAddress);
	        
	        
	  }
	   
	 
	  
   

 /////////////////////////////////////////////////////////////////// BASIC ISSUANCE  RELATED FUNCTIONS/////////////////////////////////////////////////////////
	 
	
	function issueSET2 ( ISetToken _setToken , uint256 _quantity, address _to) external {
	   
   
		// Here 1 PAB SET Token Consists of 5000 MTOA Token & 2000 MTOB Underlying Token
	    
     ISetToken mySet = ISetToken(_setToken);
     uint256 quantity = _quantity;
     address to = _to; 
          
		
		
		//your contract needs to first do a transferFrom msg.sender for both tokens to your contract from your wallet,
		//Here msg.sender is my wallet account address "0x3793f758a36c04B51a520a59520e4d845f94F9F2" which holds MTOA and MTOB Tokens
		//oh and you'll also need to approve your contract to transfer tokens from your wallet
		
        IERC20(maticAToken).transferFrom( msg.sender ,address(this) ,7000000000000000000);
          
        IERC20(maticBToken).transferFrom( msg.sender ,address(this) ,7000000000000000000);
		
//then your contract needs to do an approval to the BasicIssuanceModule for those amounts and 
		
		IERC20(maticAToken).approve(address(issuance) ,6000000000000000000);
		IERC20(maticBToken).approve(address(issuance) ,6000000000000000000);
		   
		
		  //then call the issue on the BasicIssuanceModule
          //from your contract with the to address set to msg.sender so that the Set Token is sent to your wallet and not your contract. 
          
          // Here _to address I am passing is msg.sender which is "0x3793f758a36c04B51a520a59520e4d845f94F9F2" which is the actual owner of MTOA and MTOB Tokens(my wallet address)
      
          issuance.issue( mySet , quantity, to); 
                 
 	 }
	 

	
	
	 
	 	 function getRequiredComponentUnitsForIssueData (ISetToken _mySet , uint256 _quantity) external view returns (address[] memory, uint256[] memory) {
	 	     
	 	    
	 	      ISetToken mySet = ISetToken(_mySet);
	 	       uint256 quantity = _quantity;
	 	      
	 	     return issuance.getRequiredComponentUnitsForIssue(mySet , quantity);
	 	 }
	 
	 // here  manager should call issue ,but smart contract is calling the issue functiom
	 
	 
	 
	 
	 
	 
	  /////////////////////////////////////////////////////////////////// SET CONTRACT RELATED FUNCTIONS/////////////////////////////////////////////////////////
	 
	 	function getModules()  external view returns (address[] memory) {
			 
			return mySets.getModules() ;
			 
		 }
		 
		 
		 
		 		 
	  function isPendingModule(address _module) external view returns(bool) {
		  
		  address module = _module ;
		  
		  return  mySets.isPendingModule(module);
	  }
		 
		 
		 
	 
	   function getComponents() external view returns(address[] memory) {
		   
		   return  mySets.getComponents();
	   }
	 
    
}