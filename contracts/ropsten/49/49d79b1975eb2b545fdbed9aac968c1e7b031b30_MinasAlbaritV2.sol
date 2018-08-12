pragma solidity ^0.4.8;

contract MinasAlbaritV2 {
   address public owner;
   uint public cardosotoken;
   address minacardoso =0x4c812A48855F3A6Ebcf8e52A6f082cD6DEfF930F;

 function MinasAlbarit()
 {
     owner = msg.sender;
 }

 struct Minas {
	 string name;
	 uint tokensupply;
	 bool active;	 
 }
 
 
 modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

 
   mapping(uint256=>Minas) public minasparticipantes;
   
   function RegisterMine(string _name, uint _tokensupply, uint256 _Id) onlyOwner
   {
	   minasparticipantes[_Id] = Minas ({
		   name: _name,
		   tokensupply: _tokensupply,
		   active: true
	   });
   }
   
   function ModifyMine(uint256 _Id, bool _state, string _name, uint _tokensupply, string  _token) onlyOwner 
   {
	   minasparticipantes[_Id].active = _state;
	   minasparticipantes[_Id].name = _name;
   	   minasparticipantes[_Id].tokensupply = _tokensupply;

   }
   

 
   
}