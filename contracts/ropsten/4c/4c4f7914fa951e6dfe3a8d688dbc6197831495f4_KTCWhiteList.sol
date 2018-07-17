contract KTCWhiteList  {
    
    address public owner;
    
    mapping ( address => bool ) public whitelist;
    mapping ( address => bool ) public blacklist;
    
    
    modifier onlyOwner {
		require( msg.sender == owner );
		_;
	}
    
   
    function KTCWhiteList(){
        
        owner = msg.sender;
        
    }
   
   
   function whitelistAddress( address _address ) public onlyOwner{
       
       whitelist[ _address ] = true;
       
       
   }
   
   
   function blacklistAddress( address _address ) public onlyOwner{
       
       blacklist[ _address ] = true;
       
       
   }
   
   
   function dewhitelistAddress( address _address ) public onlyOwner{
       
       whitelist[ _address ] = false;
       
       
   }
   
   
   function deblacklistAddress( address _address ) public onlyOwner{
       
       blacklist[ _address ] = false;
       
       
   }
   
   
   function checkAddress ( address _address ) public returns(bool) {
       
       if ( whitelist [ _address ] == true && blacklist[ _address ] == false ) return true;
       
       return false;
       
   }
   
   
   function changeOwner( address _newowner ) public onlyOwner {
       
       owner = _newowner;
       
   }
   
}