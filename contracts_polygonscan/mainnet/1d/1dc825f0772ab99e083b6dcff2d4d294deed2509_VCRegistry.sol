/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

//license MIT
pragma solidity >=0.7.0 <0.8.0;
contract Context {

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}
contract Ownable is Context {
 string public ownerName="STAMPING";
 address private _owner; //Public key of owner by smart contract
 address[] private masters; //Master Role for create, remove, revoke and active news DID
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }
 function owner() external view returns (address) {
    return _owner;
  }
 modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
 function _existMasters(address _senderTx) internal  view returns (bool) {
      bool _isMaster=false;
      for(uint8 i=0;i<masters.length; i++) {
             if(masters[i]==_senderTx) {
                _isMaster=true;
                 break;
             }
        }
      return _isMaster;
  }  
 function isMaster(address DID) external  view returns (bool) {
    return (_existMasters(DID));
  }
 modifier onlyMaster() {
    address  _senderTx = _msgSender();
    require(_owner == _senderTx || _existMasters(_senderTx), "Masterable: caller is not the owner or master");
    
    _;
  }
 function addMaster(address DID)  external  onlyMaster returns (bool) {
      require(!_existMasters(DID),"DID already exists with master role");
      masters.push(DID);
      return true;
  }  
 function removeMaster(address DID) external  onlyMaster returns (bool) {
      bool _isMaster=false;
      uint _index;
      for(uint i=0;i<masters.length; i++) {
             if(masters[i]==DID) {
                 _isMaster=true;
                 _index=i;
                 break;
             }
        }
      if (_isMaster==true) {    
        delete masters[_index];
        return true;
      } else {
        return false;  
      }
  } 
 function getMasterList() external view returns (address[] memory){
		return masters;
}
 function renounceOwnership() external onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
 function transferOwnership(address newOwner) external onlyOwner {
    _transferOwnership(newOwner);
  }
 function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");

    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract VCRegistry is  Context, Ownable {
    
    struct CredentialMetadata {
        address subjectDID;
        uint iat;
        bool status;
        int8 statuscode;
        address creator;
        uint count;
    }
     struct CredentialDataMetadata {
         string data;
         string url;
     }
    event CredentialRegistered(bytes32 indexed credentialHash, address by, address id, uint iat);
    event CredentialRevoked(bytes32 indexed credentialHash, address by, uint date);

  mapping (bytes32 => CredentialMetadata) public  credentialhashs;
  mapping (bytes32 => mapping (address => CredentialMetadata)) public credentials;
  mapping (bytes32 => CredentialDataMetadata) public  credentialdata;
  uint private _count;
  constructor() {
    _count=0;
  }

  function _register(bytes32 credentialHash,  address subjectDID, uint countHashs)  internal returns(bool) {
    CredentialMetadata storage credential = credentialhashs[credentialHash];
    require(credential.subjectDID==address(0),"Credential already exists");

    //credential.issuerDID = issuerDID;
    credential.count = countHashs;
    credential.subjectDID = subjectDID;
    credential.iat = block.timestamp;
    //credential.exp = exp;
    //credential.purpose = purpose;
    credential.status = true;
    credential.statuscode = 0; //"CREATED";
    //credential.url = url;
    //credential.data = data;
    credentials[credentialHash][_msgSender()] = credential;
    credentialhashs[credentialHash] = credential;
    _count++;
    emit CredentialRegistered(credentialHash, _msgSender(), subjectDID, credential.iat);
    return true;

   }

  function register(bytes32 credentialHash,  address subjectDID, uint count)  onlyMaster external returns(bool) {
    return _register(credentialHash, subjectDID, count);
  }
  function registerData(bytes32 credentialHash, address subjectDID, string calldata data, string calldata url, uint count)  onlyMaster external returns(bool) {
    _register(credentialHash,  subjectDID, count);
    CredentialDataMetadata  storage credentialData = credentialdata[credentialHash];
    credentialData.data= data;
    credentialData.url= url;
    credentialdata[credentialHash] = credentialData;
    return  true;
  }
  
  function registerMySelf(bytes32 credentialHash, address subjectDID, string calldata data, string calldata url, uint countHash)   external returns(bool) {
    _register(credentialHash,  subjectDID,  countHash);
    CredentialDataMetadata  storage credentialData = credentialdata[credentialHash];
    credentialData.data= data;
    credentialData.url= url;
    credentialdata[credentialHash] = credentialData;
    return true;
  }
  
  function revoke(bytes32 credentialHash)  onlyOwner external returns(bool) {
    CredentialMetadata storage credential = credentialhashs[credentialHash];

    require(credential.subjectDID!=address(0), "credential hash doesn't exist");
    require(credential.status, "Credential is already revoked");  
    credential.status = false;  
    credential.statuscode = 1;// "REVOKED";
    credentials[credentialHash][credential.creator] = credential;
    credentialhashs[credentialHash] = credential;
    _count--;
    emit CredentialRevoked(credentialHash, _msgSender(), block.timestamp);
    return true;
  }
  function active(bytes32 credentialHash)  onlyOwner external returns(bool) {
    CredentialMetadata storage credential = credentialhashs[credentialHash];

    require(credential.subjectDID!=address(0), "credential hash doesn't exist");
    require(!credential.status, "Credential not is revoked");  
     
    credential.status = true;   
    credential.statuscode = 2;// "ACTIVATED";
    credentials[credentialHash][credential.creator] = credential;
    credentialhashs[credentialHash] = credential;
    _count++;
    emit CredentialRegistered(credentialHash, _msgSender(),credential.subjectDID, block.timestamp);
    return true;
  }
  function verify(bytes32 credentialHash, address issuer)  external view returns(bool isValidm, int8 statuscode){
    CredentialMetadata memory credential = credentials[credentialHash][issuer];
    require(credential.subjectDID!=address(0),"Credential hash doesn't exist");
    return (credential.status, credential.statuscode);
  }
  function count() public view returns (uint){
		return _count;
	}
}