/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity ^0.6.1;

contract RoleBasedAcl {
  address creator;
  
  mapping(address => mapping(string => mapping(string => bool))) roles;
  mapping(address => mapping(string => bool)) roles2;

  constructor() public{
    creator = msg.sender;
  }
  
  
  function assignRole (address entity, string memory topic, string memory role) public {
    roles[entity][topic][role] = true;
  }

  
  function unassignRole (address entity, string memory topic, string memory role) public {
    roles[entity][topic][role] = false;
  }

  
  function isAssignedRole (address entity, string memory topic, string memory role)public view returns (bool) {
    return roles[entity][topic][role];
  }

  
}

contract Token is RoleBasedAcl {
mapping(address => uint256) public authentications;
    mapping (uint256 => address) public randumNumber;
  
    
    address esp32add;
    address prover;
    uint256 private nonce;
    //uint256 abc;
    
    event generatedToken(address,uint256);
    event verified(address,uint256,bool);
    
    constructor(uint256 valueOfNonce) public {
        nonce = valueOfNonce;
    }
     function generateToken(address _esp32add) public{ //returns (uint256) {

        //esp32add = _esp32add;
        prover = _esp32add;
        nonce++;   
        uint256 abc = uint256( uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty,nonce))));
       
        //return (abc);
        authentications[_esp32add] = abc;
        randumNumber[abc] = _esp32add;
        emit generatedToken(prover,abc);
    }
        
    function verification(uint256 value) public {
        address userAdd = randumNumber[value];
        uint256 number = authentications[userAdd];
        
        if(value == number){
            emit verified(userAdd,number,true);
        }
    }
}