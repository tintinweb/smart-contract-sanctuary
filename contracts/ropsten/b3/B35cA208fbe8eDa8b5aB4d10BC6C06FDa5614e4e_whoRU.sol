/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity 0.8.6;

contract whoRU {

    struct client {
        string _name;
        string _email;
    }

      client[] public clients;

  
    mapping(address => string) name;
    mapping(address => string) email;
    mapping (address => bool) membership; 




      function register (string memory _name, string memory _email) public { 

        name[msg.sender] = _name;
        email[msg.sender] = _email;
        membership[msg.sender]= true;
        

        clients.push(client(_name, _email));

    }
    
       function unregister (address _address) public {
        
        if(_address != msg.sender){
            revert();
        }
        
        name[msg.sender] = "";
        email[msg.sender] = "";
        membership[_address]=false;
      
        
    }


    function getInfo(address _address) view public returns (string memory, string memory, bool){
        return (name[_address],  email[_address],  membership[_address]);
    }


  
}