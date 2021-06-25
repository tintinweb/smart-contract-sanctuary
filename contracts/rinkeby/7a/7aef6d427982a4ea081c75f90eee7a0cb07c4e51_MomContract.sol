/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity ^0.5.0;


contract MomContract {
    
   
  string public name;
  uint public age;
  address[] public contracts;

  constructor(
    string memory _momsName,
    uint _momsAge
  ) 
    public
  {
      
    name = _momsName;
    age = _momsAge;
  }


 function createDaugher(string memory _daughtersName, uint _daughtersAge)
    public
    returns(address newContract)
  {
    DaughterContract c = new DaughterContract(_daughtersName, _daughtersAge);
    contracts.push(address(c));
    return address(c);
  }


//   function allowDaughterToDate() public {
//     daughter.permissionToDate();
//   }

//   function allowSonToDate() public {
//     son.permissionToDate();
//   }

  function getAge() public view returns (uint) {
    return age;
  }
}

 contract DaughterContract {

   string public name;
  uint public age;
  
  constructor(
    string memory _daughtersName,
    uint _daughtersAge
  ) 
    public
  {
     name = _daughtersName;
     age = _daughtersAge;
  }

 function getFlavor()
    public
    view
    returns (string memory flavor)
  {
    return name;
  } 


}