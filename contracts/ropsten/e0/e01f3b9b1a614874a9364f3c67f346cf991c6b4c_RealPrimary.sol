/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity >=0.7.0 <0.8.0;

contract RealPrimary {
    
    uint n;
    
    NewReal[] public newReals;
    
    mapping(uint => uint) public  realListFromIdToArray; 
   
   constructor(){
        n = 0;
    }
    
    event Event(
       address  owner,
       bytes16 photo,
       uint indexed id,
       uint256 value,
       address contractAddress
    );
    
   function setReal(address payable _owner_1, uint256  _value_1, uint _id, bytes16 _md5_hash_picture) public {
       
      newReals.push( new NewReal(_owner_1, _value_1, _id, _md5_hash_picture));
      
      realListFromIdToArray[_id] = n;
      
      n = n +1;
       emit Event(
        newReals[realListFromIdToArray[_id]].getOwner(),
        newReals[realListFromIdToArray[_id]].getMd5HashPicture(),
        newReals[realListFromIdToArray[_id]].getId(),
        newReals[realListFromIdToArray[_id]].getValue(),
        newReals[realListFromIdToArray[_id]].getThisContractAddress()
   );
   }
   
    function buy(uint _id) payable public  {
      
      
      require(newReals[realListFromIdToArray[_id]].getValue() == msg.value, 'The price is not equal the acual price');
      
      require(newReals[realListFromIdToArray[_id]].getAvailable() == true, 'The property is sold');

      newReals[realListFromIdToArray[_id]].getOwner().transfer(msg.value);
        
      newReals[realListFromIdToArray[_id]].setUnavailable(msg.sender);
      
       emit Event(
        newReals[realListFromIdToArray[_id]].getOwner(),
        newReals[realListFromIdToArray[_id]].getMd5HashPicture(),
        newReals[realListFromIdToArray[_id]].getId(),
        newReals[realListFromIdToArray[_id]].getValue(),
        newReals[realListFromIdToArray[_id]].getThisContractAddress()
   );
      
     
    }
    
    function getN() public view returns (uint) {
       
        return n;
    }
    
    
    function getAnyContractAddress(uint _id) public view returns (address) {
    
    return  newReals[realListFromIdToArray[_id]].getThisContractAddress();

   }
   
   function getAvailablilityForAnyContract(uint _id) public view returns (bool) {
    
    return newReals[realListFromIdToArray[_id]].getAvailable();

   }
   
   function getValueForAnyContract(uint _id) public view returns (uint256) {
    
    return newReals[realListFromIdToArray[_id]].getValue();

   }
   
   function getOwnerForAnyContract(uint _id) public view returns (address) {
    
    return newReals[realListFromIdToArray[_id]].getOwner();

   }
   
  
}

contract NewReal{
    
   address payable owner;
   uint256  value;
   uint id;
   bytes16 md5_hash_picture;
   bool available;
   
   constructor(address payable _owner, uint256 _value, uint _id, bytes16   _md5_hash_picture){
    id = _id;
    owner = _owner;
    value = _value;
    md5_hash_picture = _md5_hash_picture;
    available = true;
   
   }
   
   function getOwner()   public view  returns (address payable) {
    
    return owner;
   
   }
    function getValue()  public view returns (uint256) {
    
    return value;
   }
   
   function getId()  public view returns (uint) {
    
    return id;
   }
   
   function getMd5HashPicture()  public view returns (bytes16) {
    
    return md5_hash_picture;
   }
   
    function getAvailable() public view returns (bool) {
    
    return available;
   }
   
   function getThisContractAddress() public view returns (address) {
    
    return address(this);
   }
   
   function setUnavailable(address payable newOwner) public {
    
    owner = newOwner;
    available = false;
    
   }
   
}