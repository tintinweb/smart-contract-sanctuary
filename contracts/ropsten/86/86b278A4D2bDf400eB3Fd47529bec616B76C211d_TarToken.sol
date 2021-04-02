/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.5.12;

// library for basic math operation + - * / to prevent and protect overflow error 
// (Overflow and Underflow) which can be occurred from unit256 (Unsigned int 256)
 library SafeMath256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if(a==0 || b==0)
        return 0;  
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b>0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
   require( b<= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
  
}

contract Ownable {


// A list of owners which will be saved as a list here, 
// and the values are the owner’s names. 
// This to allow investors / NATEE Token buyers to trace/monitor 
// who executes which functions written in this NATEE smart contract  string [] ownerName;

  string [] ownerName;  
  mapping (address=>bool) owners;
  mapping (address=>uint256) ownerToProfile;
  address owner;

// all events will be saved as log files
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);
  /**
   * @dev Ownable constructor , initializes sender’s account and 
   * set as owner according to default value according to contract
   *
   */

   // this function will be executed during initial load and will keep the smart contract creator (msg.sender) as Owner
   // and also saved in Owners. This smart contract creator/owner is 
   // Mr. Samret Wajanasathian CTO of Seitee Pte Ltd (https://seitee.com.sg , https://natee.io)

   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
    uint256 idx = ownerName.push("SAMRET WAJANASATHIAN");
    ownerToProfile[msg.sender] = idx;

  }

// function to check whether the given address is either Wallet address or Contract Address

  function isContract(address _addr) internal view returns(bool){
     uint256 length;
     assembly{
      length := extcodesize(_addr)
     }
     if(length > 0){
       return true;
    }
    else {
      return false;
    }

  }

// function to check if the executor is the owner? This to ensure that only the person 
// who has right to execute/call the function has the permission to do so.
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

// This function has only one Owner. The ownership can be transferrable and only
//  the current Owner will only be  able to execute this function.
  
  function transferOwnership(address  newOwner, string memory newOwnerName) public onlyOwner{
    require(isContract(newOwner) == false);
    uint256 idx;
    if(ownerToProfile[newOwner] == 0)
    {
    	idx = ownerName.push(newOwnerName);
    	ownerToProfile[newOwner] = idx;
    }


    emit OwnershipTransferred(owner,newOwner);
    owner = newOwner;

  }

// Function to check if the person is listed in a group of Owners and determine
// if the person has the any permissions in this smart contract such as Exec permission.
  
  modifier onlyOwners(){
    require(owners[msg.sender] == true);
    _;
  }

// Function to add Owner into a list. The person who wanted to add a new owner into this list but be an existing
// member of the Owners list. The log will be saved and can be traced / monitor who’s called this function.
  
  function addOwner(address newOwner,string memory newOwnerName) public onlyOwners{
    require(owners[newOwner] == false);
    require(newOwner != msg.sender);
    if(ownerToProfile[newOwner] == 0)
    {
    	uint256 idx = ownerName.push(newOwnerName);
    	ownerToProfile[newOwner] = idx;
    }
    owners[newOwner] = true;
    emit AddOwner(newOwner,newOwnerName);
  }

// Function to remove the Owner from the Owners list. The person who wanted to remove any owner from Owners
// List must be an existing member of the Owners List. The owner cannot evict himself from the Owners
// List by his own, this is to ensure that there is at least one Owner of this NATEE Smart Contract.
// This NATEE Smart Contract will become useless if there is no owner at all.

  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender);  // can't remove your self
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }
// this function is to check of the given address is allowed to call/execute the particular function
// return true if the given address has right to execute the function.
// for transparency purpose, anyone can use this to trace/monitor the behaviors of this NATEE smart contract.

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

// Function to check who’s executed the functions of smart contract. This returns the name of 
// Owner and this give transparency of whose actions on this NATEE Smart Contract. 

  function getOwnerName(address ownerAddr) public view returns(string memory){
  	require(ownerToProfile[ownerAddr] > 0);

  	return ownerName[ownerToProfile[ownerAddr] - 1];
  }
}

// Mandatory basic functions according to ERC20 standard
contract ERC20 {
	   event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

   	   function totalSupply() public view returns (uint256);
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
  

}

contract StandarERC20 is ERC20{
  using SafeMath256 for uint256; 
     
     mapping (address => uint256) balance;
     mapping (address => mapping (address=>uint256)) allowed;


     uint256  totalSupply_; 
     
      event Transfer(address indexed from,address indexed to,uint256 value);
      event Approval(address indexed owner,address indexed spender,uint256 value);


    function totalSupply() public view returns (uint256){
      return totalSupply_;
    }

     function balanceOf(address _walletAddress) public view returns (uint256){
        return balance[_walletAddress]; 
     }


     function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
        }

     function transfer(address _to, uint256 _value) public returns (bool){
        require(_value <= balance[msg.sender]);
        require(_to != address(0));

        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        
        return true;

     }

     function approve(address _spender, uint256 _value)
            public returns (bool){
            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);
            return true;
            }

      function transferFrom(address _from, address _to, uint256 _value)
            public returns (bool){
               require(_value <= balance[_from]);
               require(_value <= allowed[_from][msg.sender]); 
               require(_to != address(0));

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
              emit Transfer(_from, _to, _value);
              return true;
      }


     
}


contract TarToken is StandarERC20, Ownable {
  using SafeMath256 for uint256;
  string public name = "TarToken";
  string public symbol = "TAR"; 
  uint256 public decimals = 18;


  constructor() public {
    totalSupply_ = 0;
    balance[msg.sender] = 0;
  }

  function mint(address _to,uint256 _value) public onlyOwners returns(bool){
      totalSupply_  += _value;
      balance[_to] += _value;
      emit Transfer(address(this),_to,_value);
      return true;
  }

 

}