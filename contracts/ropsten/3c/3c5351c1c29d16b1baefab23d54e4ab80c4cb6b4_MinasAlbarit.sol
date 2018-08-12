pragma solidity ^0.4.8;

contract MinasAlbarit {
   address public owner;

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

 
   mapping(address=>Minas) public minasparticipantes;
   
   function RegisterMine(string _name, uint _tokensupply, address _contracmine) onlyOwner
   {
	   minasparticipantes[_contracmine] = Minas ({
		   name: _name,
		   tokensupply: _tokensupply,
		   active: true
	   });
   }
   
   function ModifyMine(address _contractcancel, bool _state, string _name, uint _tokensupply) onlyOwner 
   {
	   minasparticipantes[_contractcancel].active = _state;
	   minasparticipantes[_contractcancel].name = _name;
   	   minasparticipantes[_contractcancel].tokensupply = _tokensupply;


   }
 
   
}