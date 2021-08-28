/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

pragma solidity 0.8.6;

interface UserInterface {
    function isRegistered(address user) external view returns (bool registered );
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor ()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
     
    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SchemaManager is Ownable{
     UserInterface public userContract;
     uint256 public schemaid;
     mapping(uint => schemaStruct) public schemalist;
     mapping(address => schemaStruct[]) public issuerschemas;
     
    struct schemaStruct {
        uint256 schemaid;
        string name;
        string[] attributes;
        string attributehash;
        uint createdOn;
        address createdBy;
    }
    
    constructor(UserInterface userregiaddr){
        userContract = userregiaddr;
    }
      
    function createSchema(string memory _name, string[] memory _attributes, string memory _attrHash ) public { 
         bool registered =  userContract.isRegistered(msg.sender);
         require(registered ,"Not registered");
         require(!noDuplicates(_attrHash),"Duplicate schema");
         schemalist[schemaid] = schemaStruct(schemaid, _name, _attributes,_attrHash, block.timestamp,address(msg.sender) );
         issuerschemas[msg.sender].push(schemaStruct(schemaid, _name, _attributes,_attrHash, block.timestamp,address(msg.sender) ));
         schemaid++;
   }
   
   function noDuplicates(string memory _attrHash) public  returns (bool){
       bool exists = false;
        for (uint i = 0; i < schemaid; i++) {
             if(keccak256(abi.encodePacked((schemalist[i].attributehash))) == keccak256(abi.encodePacked((_attrHash)))){
             exists=true;
             break;
             }
        }
        return exists;
    }
   
   function getissuserschema(address user) public view returns(uint[] memory ids, string[] memory names, uint[] memory createdOn){
        uint[] memory ids = new uint[](issuerschemas[user].length);
        uint[] memory createdOn = new uint[](issuerschemas[user].length);
        string[] memory names = new string[](issuerschemas[user].length);
        for(uint i=0 ;i < issuerschemas[user].length;i++){
            ids[i] = issuerschemas[user][i].schemaid;
            names[i] = issuerschemas[user][i].name;
            createdOn[i] = issuerschemas[user][i].createdOn;
        }
        return (ids,names,createdOn);   
   }
   
   function getSchemaName(uint _schemaid) public view returns(string memory name) {
      return schemalist[_schemaid].name;
  }
   
  function getissueraddress(uint _schemaid) public view returns(address issueraddress) {
      return schemalist[_schemaid].createdBy;
  }
   
   function getAttributes(uint id)external view returns(string[] memory attributes){
        string[] memory att = new string[](schemalist[id].attributes.length);
        for(uint i=0 ;i<schemalist[id].attributes.length;i++){
            att[i] = schemalist[id].attributes[i];
        }
        return att;
   }
    
    function updateuserContract(UserInterface userregiaddr)public onlyOwner {
        userContract = userregiaddr;    
   }   
}