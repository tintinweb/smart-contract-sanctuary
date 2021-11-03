/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

pragma solidity >=0.4.0 <0.6.0;

contract Auth {
    struct Node {
        address addr;
        int groupId ;
        string objectName ;
        string password;
        
    }
     constructor () public payable{
         
     }
    uint public temp;
    mapping(address => Node) node;
    int[10] groupIdA;
    string [10] objectIdA;
    address [10] objectAddA;
    uint public j=0;
     // check the already existing node function
    function isGroupExist(int _groupId) public view returns (bool) 
    {
        
        for(uint i=0 ; i<10 ; i++)
      
      {
     if (groupIdA[i]==_groupId)
        return true;}
       
     //  else 
       // return false;//}
    
    
    }   
        
        
    function isAddExists(address key) public  returns (bool) {

      
        
        for(uint i=0 ; i<10 ; i++)
      
      {
       if (objectAddA[i]==key)
{
     temp=i;
      return true ; }}
       
      // else 
       // return false;
    
    }  
    function isObjExists(string memory objectId) public view returns (bool) {

        
        for(uint i=0 ; i<10 ; i++)
      {
      
       if (keccak256(abi.encodePacked(objectIdA[i]))==keccak256(abi.encodePacked(objectId)))
       return true ;}
       
     //  else 
       // return false;}
    
        
    }
        
    // if the object is Master check if the group Exist to revert the transaction 

    // node registration function
   
    function register(
       // otype _ott,
       uint cat,
        address _address,
        int _groupId,
        string memory _objectName,
       // string memory  _password ,
        bytes32 message, bytes memory sig,
        address master_pub) public payable returns (bool)
        { // address master_pub;
          // bytes32 message;
         //  bytes memory sig;
           //uint j =0;//
           bool value;
            uint8 v;
       bytes32 r;
       bytes32 s;
       address master;

       (v, r, s) = splitSignature(sig);
      master = ecrecover(message, v, r, s);
     /* if (cat !=0 || cat!=1)
      {
          revert("The object categry should be 0 or 1 ");
      }*/
            if (cat==0){
      if(isGroupExist(_groupId)==true) // check if group Exist 
        revert("Object Group Already Exist");
            
     if( isAddExists(_address)==true)
        revert("Object Address Already Exist");
     if(isObjExists(_objectName)==true)  
        revert("The Object  Already Exist");
            }
        
        
        if (cat==1){ // the follower details must be taken 
        if( isGroupExist(_groupId)==false)
          revert("Object Group Not Exist");
       if(isAddExists(_address)==true)
       revert("Object Address Already Exist");
       if(isObjExists(_objectName)==true)  
        revert(" The Object  Already Exist");
       
        if(master_pub!= master)
       revert("Invalid signtrure");
        
       }
        node[_address].addr =_address;                     
        node[_address].groupId=_groupId;
        node[_address].objectName = _objectName;
      
       groupIdA[j]=_groupId;
       objectAddA[j]= _address;
       objectIdA[j]=_objectName;
        j++;
      return true;
        // the values not equal to 1 or 0 of cat 
            
        } 
    function Enter(address addr,
        int groupId ,
        string memory  objectId ) public {
        
    }
    
    function recoverSigner(address master_pub,bytes32 message, bytes memory sig)
       public
       pure
       returns (bool)
    {
       uint8 v;
       bytes32 r;
       bytes32 s;
       address master;

       (v, r, s) = splitSignature(sig);
      master = ecrecover(message, v, r, s);
      if(master==master_pub)
      return true;
      else 
      return false;
  }

  function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
   {
       require(sig.length == 65);
       
       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
       }

       return (v, r, s);
   }
   
   mapping (address => Node ) public nodeStructs;
   mapping (address => string) message;
   uint x;
   uint y;

  function exchangeMessage(address sender,address receiver ,string memory _message)  public
        {
        // if( isGroupExist(_groupId)==false)
         // revert("Object Group Not Exist");
         // check the existeness of sender and receiver using address
         if( isAddExists(sender)==false)
         revert("sender  Not Exist");
         else 
        
         x=temp;
         if( isAddExists(receiver)==false)
         revert("receiver  Not Exist");
         else
        
         y=temp;
         // check if both belongs to the same Group
         // if(nodeStructs[sender].groupId==nodeStructs[receiver].groupId)  //
          if (groupIdA[x]==groupIdA[y])
         message[receiver] = _message;
         else 
         revert("The objects not belong to the same group");
  }

  function readMessage()public
        returns (string memory) {
    return message[msg.sender];
  }
    

    
    }