/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.6.1;

contract Whitelist {
    
    address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }


    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function add(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function remove(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}





contract RoleBasedAcl {
  address creator;
  
  mapping(address => mapping(string => mapping(string => bool))) roles;
  mapping(address => mapping(string => bool)) roles2;
  
  constructor() public{
    creator = msg.sender;
  }
  
  modifier onlyFromOwner(){
      require(creator == msg.sender);
      _;
  }
  
  function adminRole (address entity, string memory role) public onlyFromOwner {
    roles2[entity][role] = true;
  }
  
  function assignRole (address entity, string memory topic, string memory role) public hasRole('superadmin') {
    roles[entity][topic][role] = true;
  }

  
  function unassignRole (address entity, string memory topic, string memory role) public hasRole('superadmin') {
    roles[entity][topic][role] = false;
  }

  
  function isAssignedRole (address entity, string memory topic, string memory role)public view returns (bool) {
    return roles[entity][topic][role];
  }

  
  modifier hasRole(string memory role) {
    require(roles2[msg.sender][role],"only admin can run this");
    _;
}
}



contract Tufa is RoleBasedAcl,Whitelist {
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