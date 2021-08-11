/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity 0.5.17;

contract Ownable {

// A list of owners which will be saved as a list here, 
// and the values are the owner’s names. 


  string [] ownerName;  
  address newOwner; // temp for confirm;
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
   // Mr. Samret Wajanasathian CTO of Shuttle One Pte Ltd (https://www.shuttle.one)

   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
    uint256 idx = ownerName.push("SAMRET WAJANASATHIAN");
    ownerToProfile[msg.sender] = idx;

  }

// // function to check whether the given address is either Wallet address or Contract Address

//   function isContract(address _addr) internal view returns(bool){
//      uint256 length;
//      assembly{
//       length := extcodesize(_addr)
//      }
//      if(length > 0){
//       return true;
//     }
//     else {
//       return false;
//     }

//   }

// function to check if the executor is the owner? This to ensure that only the person 
// who has right to execute/call the function has the permission to do so.
  modifier onlyOwner(){
    require(msg.sender == owner,"SZO/ERROR-not-owner");
    _;
  }

// This function has only one Owner. The ownership can be transferrable and only
//  the current Owner will only be  able to execute this function.
//  Onwer can be Contract address
  function transferOwnership(address  _newOwner, string memory newOwnerName) public onlyOwner{
    
    uint256 idx;
    if(ownerToProfile[_newOwner] == 0)
    {
    	idx = ownerName.push(newOwnerName);
    	ownerToProfile[_newOwner] = idx;
    }


    emit OwnershipTransferred(owner,_newOwner);
    newOwner = _newOwner;

  }
  
  // Function to confirm New Owner can execute
  function newOwnerConfirm() public returns(bool){
        if(newOwner == msg.sender)
        {
            owner = newOwner;
            newOwner = address(0);
            return true;
        }
        return false;
  }

// Function to check if the person is listed in a group of Owners and determine
// if the person has the any permissions in this smart contract such as Exec permission.
  
  modifier onlyOwners(){
    require(owners[msg.sender] == true);
    _;
  }

// Function to add Owner into a list. The person who wanted to add a new owner into this list but be an existing
// member of the Owners list. The log will be saved and can be traced / monitor who’s called this function.
  
  function addOwner(address _newOwner,string memory newOwnerName) public onlyOwners{
    require(owners[_newOwner] == false,"SZO/ERROR-already-owner");
    require(newOwner != msg.sender,"SZO/ERROR-same-owner-add");
    if(ownerToProfile[_newOwner] == 0)
    {
    	uint256 idx = ownerName.push(newOwnerName);
    	ownerToProfile[_newOwner] = idx;
    }
    owners[_newOwner] = true;
    emit AddOwner(_newOwner,newOwnerName);
  }

// Function to remove the Owner from the Owners list. The person who wanted to remove any owner from Owners
// List must be an existing member of the Owners List. The owner cannot evict himself from the Owners
// List by his own, this is to ensure that there is at least one Owner of this ShuttleOne Smart Contract.
// This ShuttleOne Smart Contract will become useless if there is no owner at all.

  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender,"SZO/ERROR-remove-yourself");  // can't remove your self
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }
// this function is to check of the given address is allowed to call/execute the particular function
// return true if the given address has right to execute the function.
// for transparency purpose, anyone can use this to trace/monitor the behaviors of this ShuttleOne smart contract.

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

// Function to check who’s executed the functions of smart contract. This returns the name of 
// Owner and this give transparency of whose actions on this ShuttleOne Smart Contract. 

  function getOwnerName(address ownerAddr) public view returns(string memory){
  	require(ownerToProfile[ownerAddr] > 0,"SZO/ERROR-NOT-OWNER-ADDRESS");
  	return ownerName[ownerToProfile[ownerAddr] - 1];
  }
}


contract SZO {
	     event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

   	   function totalSupply() public view returns (uint256);
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
  
	   function createKYCData(bytes32 _KycData1, bytes32 _kycData2,address  _wallet) public returns(uint256);
}

contract WSZO3ndShare is  Ownable {
     SZO wszoToken;
    
     
     constructor() public {
         wszoToken = SZO(0x5538Ac3ce36e73bB851921f2a804b4657b5307bf); // wszo
      }
       
     function transferAllToShareHolder() public onlyOwners returns(bool){
         
            wszoToken.transfer(0x85B4C6180099557aF2787964c651980382D24361,1020000 ether); //1
            wszoToken.transfer(0x85B4C6180099557aF2787964c651980382D24361,673200 ether); //2
            wszoToken.transfer(0x137b159F631A215513DC511901982025e32404C2,408000 ether); //3
            wszoToken.transfer(0x0D49112c7D5ecC8ae1Aa891C681f1f761f7C9E2b,357000 ether); //4
            wszoToken.transfer(0xa7bADCcA8F2B636dCBbD92A42d53cB175ADB7435,323000 ether); //5
            wszoToken.transfer(0x005BaBb7da64B22B21Bac94e0a829CF519Fa236A,113220 ether); //6
            wszoToken.transfer(0x859e099277B88d51Fa3a6Fe49B7B6eE3DBA66dD8,100300 ether); //7
            wszoToken.transfer(0x10c8c627121D018e23b71EE4a00c01b441f35414,71400 ether); //8
            wszoToken.transfer(0x1b2b1FC2aeDc8194B738fc265407a92a909Acf76,68000 ether); //9
            wszoToken.transfer(0x99d2e820264D7353eC260BcD1351c6BCE964468E,68000 ether); //10
            wszoToken.transfer(0x45A05B3f4f5e2cfA19dE42e37f4B3890Bd9f639B,61880 ether); //11
            wszoToken.transfer(0xA461D372AB2F1D8717630014F9F8Cb1B946FB83f,25500 ether); //12
            wszoToken.transfer(0xFEE4d3C5D98Fa7323f5eB9c0819Fa7E6E9519C64,17000 ether); //13
            wszoToken.transfer(0xa79406e200DAA9a605661E883BC393064133940d,17000 ether); //14
            wszoToken.transfer(0x5703948EDB483599624c74aFde5CDf9c1dbb2AdB,13600 ether); //15
            wszoToken.transfer(0x0A43E3fC2c5778D0A9BAcC4752A10609E3d3cf21,6800 ether); //16
            wszoToken.transfer(0x5c89aAa59E3268d7612F2c8DF59A6864b7db90Aa,3740 ether); //17
            wszoToken.transfer(0x2cda19Ac5F75e9b7b48c0bD7A655be29E579a807,3400 ether); //18
            wszoToken.transfer(0xa4f929a976dD20c03CCAB5D7998F9702332F15D7,3400 ether); //19
            wszoToken.transfer(0x0758c1620924a6787af7755Cd528fcC78B86e2C8,17000 ether); //20

     }
     
      function transferToken(address _to,uint256 _amount,address _token) public onlyOwners returns(bool){
          // Emegency Call just in case have problem
          return SZO(_token).transfer(_to,_amount);
      }


      function transfer(address _to,uint256 _amount) public onlyOwners returns(bool){
          // Emegency Call just in case have problem
          return wszoToken.transfer(_to,_amount);
      }

 
}