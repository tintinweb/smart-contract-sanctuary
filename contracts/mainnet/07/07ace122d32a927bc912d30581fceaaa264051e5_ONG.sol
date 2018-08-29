pragma solidity ^0.4.24;
contract ONG_Base{
    struct Project{
        address Owner;
        uint256 Id;
        uint256 Tokens;
        bool Enable;
    	}
	struct Member{
        address Owner;
        uint256 Tokens;
        bool Enable;
	}
	address public Oracle;
    address public Owner;
	address[] membersAddresses;
    uint256 constant OwnerProject = 1;
    uint256 public Period =1;
	mapping (uint256=>Project) Projects;
	mapping (address=> Member) Members;
	
	
	modifier IsOracle(){
        require(msg.sender == Oracle );
        _;
	}
    modifier IsOwner(){
        require(msg.sender == Owner);
        _;
    }
}
contract ONG_ProjectFunctions is ONG_Base{
    function Project_RemoveToken (uint256 _ProjectID, uint256 _tokens) public {
        require(Projects[_ProjectID].Owner == msg.sender);
        require(Projects[_ProjectID].Enable);
        require(Projects[_ProjectID].Tokens >= _tokens);
        Projects[_ProjectID].Tokens = Projects[_ProjectID].Tokens  - _tokens;
    }
    function Project_Info(uint256 _ProjectID) public view returns(address _Owner,uint256 _Id,uint256 _Tokens,bool _Enable    )  {
         _Owner= Projects[_ProjectID].Owner;
         _Id= Projects[_ProjectID].Id;
         _Tokens= Projects[_ProjectID].Tokens;
         _Enable= Projects[_ProjectID].Enable;
    }
    function Project_ChangeOwner(uint256 _ProjectID, address _newOwner) public{
        require(Projects[_ProjectID].Owner == msg.sender);
        Projects[_ProjectID].Owner = _newOwner;
    }
    function Project_Enable(uint256 _ProjectID) public  returns(bool) {
        require(Projects[_ProjectID].Owner == msg.sender);
        Projects[_ProjectID].Enable = !Projects[_ProjectID].Enable;
        return (Projects[_ProjectID].Enable);
    }
}
contract ONG_MembersFunctions is ONG_Base{
    function Member_AssingTokensToProject(uint256 _tokens, uint256 _ProjectID) public{
        require(Period ==2);
        require(Members[msg.sender].Tokens>=_tokens);
        require(Members[msg.sender].Enable);
        require(Projects[_ProjectID].Enable);
        require(_ProjectID!=OwnerProject);
        
        Members[msg.sender].Tokens = Members[msg.sender].Tokens + _tokens;
    }
    function Members_info(address _member) public view returns(address _Owner,uint256 _Tokens,bool _Enable){
        _Owner = Members[_member].Owner;
        _Tokens = Members[_member].Tokens;
        _Enable = Members[_member].Enable;
}
}
contract ONG_OwnerFunction is ONG_Base{
    function AddMember(address _member, uint256 _tokens) IsOwner public{
        require(Members[_member].Owner != msg.sender);
        Members[_member].Enable = true;
        Members[_member].Owner = _member;
        Members[_member].Tokens = _tokens;
        membersAddresses.push(_member);
    }
    function AddTokensToMember(address _member, uint256 _tokens) IsOwner public{
        require(Period ==1);
        require(Members[_member].Enable);
        Members[_member].Tokens =Members[_member].Tokens + _tokens;
    }
    function EnableMember(address _member)  IsOwner public returns(bool){
        Members[_member].Enable = !Members[_member].Enable;
        return(Members[_member].Enable);
    }
    function AddProject(uint256 _id, address _ProjectOwner) IsOwner public{
        require(Projects[_id].Id != _id);
        Projects[_id].Id = _id;
        Projects[_id].Owner = _ProjectOwner;
        Projects[_id].Enable = true;
    }
    function ReassingTokens(uint256 _IdProject, uint256 _tokens) IsOwner public{
        require(Period ==3);
        require(Projects[OwnerProject].Tokens>= _tokens);
        Projects[OwnerProject].Tokens = Projects[OwnerProject].Tokens - _tokens;
        Projects[_IdProject].Tokens = Projects[_IdProject].Tokens + _tokens;
    }
}
contract ONG_OracleFunctions is ONG_Base{
    function ToPeriod() IsOracle public{
        Period ++;
        if (Period == 3 ){
            for (uint256 i; i> membersAddresses.length;i++ ){
                if(Members[membersAddresses[i]].Tokens>0){
                    Projects[OwnerProject].Tokens = Projects[OwnerProject].Tokens + Members[membersAddresses[i]].Tokens;
                    Members[membersAddresses[i]].Tokens= 0; 
                }
            }
        }
        if( Period ==4){
            Period = 1;
        }
        
    }
}
contract ONG is ONG_OracleFunctions, ONG_OwnerFunction, ONG_MembersFunctions, ONG_ProjectFunctions  {
  constructor (address _Oracle) public{
      Owner= msg.sender;
      Oracle = _Oracle;
      Projects[OwnerProject].Owner = Owner;
      Projects[OwnerProject].Enable = true;
      Projects[OwnerProject].Id = OwnerProject;
  }
}