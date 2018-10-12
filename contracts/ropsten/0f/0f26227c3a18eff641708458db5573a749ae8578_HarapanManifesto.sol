pragma solidity ^0.4.17;

contract HarapanManifesto{
	struct Manifesto {
		string ManifestoCategory;
		string ManifestoAction;
		uint CompletionDate;
		bool Broken;
		bool Completed;
	}
	
	mapping (uint => Manifesto) private manifestos;
	
	address owner;
	mapping(address => bool) public Admins;
	uint manifestoCount;
	uint deletedCount;
	
	constructor(){
		owner = msg.sender;
		manifestoCount = 0;
	}
	
	modifier ownerOnly {
		require(msg.sender == owner);
		_;
	}
	
	modifier adminOrOwnerOnly {
		require(msg.sender == owner || IsAdmin(msg.sender));
		_;
	}
	
	function AddAdmin(address _address) public ownerOnly {
		Admins[_address] = true;
	}
	
	function IsAdmin(address _address) returns (bool) {
		return Admins[_address];
	}
	
	function InitializeManifesto(string manifestoCategory, string manifestoAction, uint CompletionDate, bool Broken, bool Completed) public ownerOnly {
		manifestos[manifestoCount].ManifestoCategory = manifestoCategory;
		manifestos[manifestoCount].ManifestoAction = manifestoAction;
		manifestos[manifestoCount].CompletionDate = CompletionDate;
		manifestos[manifestoCount].Broken = Broken;
		manifestos[manifestoCount].Completed = Completed;
		manifestoCount++;
	}
	
	function InsertManifesto(string manifestoCategory, string manifestoAction) public adminOrOwnerOnly {
		manifestos[manifestoCount].ManifestoCategory = manifestoCategory;
		manifestos[manifestoCount].ManifestoAction = manifestoAction;
		manifestos[manifestoCount].CompletionDate = 0;
		manifestos[manifestoCount].Broken = false;
		manifestos[manifestoCount].Completed = false;
		manifestoCount++;
	}
	
	function GetManifestoByCategory(string category) public view returns (string){
	    
		for(uint i = 0; i < manifestoCount; i++){
			
		}
	}
	
	function GetManifestoById(uint id) public view returns (string manifestoCategory, 
							  string manifestoAction,
							  uint completionDate, 
							  bool broken, 
							  bool completed){
		return(manifestos[id].ManifestoCategory,
			   manifestos[id].ManifestoAction,
			   manifestos[id].CompletionDate,
			   manifestos[id].Broken,
			   manifestos[id].Completed);
	}
	
	function ManifestoCount() public view returns (uint){
		return manifestoCount - 1 ;
	} 
	
	function UpdateManifesto(uint id, bool broken, bool completed) ownerOnly public  returns (bool, bool, uint){
		manifestos[id].Broken = broken;
		manifestos[id].Completed= completed;
		
		if(completed){
			manifestos[id].CompletionDate = now;
		}
		
		return (broken, completed, id);
	}
	
	function DeleteContract() ownerOnly public{
		selfdestruct(owner);
	}
}