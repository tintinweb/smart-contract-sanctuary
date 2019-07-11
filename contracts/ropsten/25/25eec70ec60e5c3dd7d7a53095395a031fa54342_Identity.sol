/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-21
*/

pragma solidity ^0.4.24;

interface ERC725 {
    event DataChanged(string _name, string _postalAddress, string _phone, string _email, string _photoHash);
    event OwnerChanged(address indexed ownerAddress);

    function changeOwner(address _owner) external;
    function setData(string _name, string _postalAddress, string _phone, string _email, bytes32 _photoHash) external;
    function setDocHash(string _certificate, bytes32 _hash) external;
    function getDocHash(uint256 _id) external view returns(uint256 _hashID,string _certificate, bytes32 _hash);
    function getCount() external view returns(uint256 _count);
    function getDataOfIdentity(bool _show) external view returns(string _name, string _postalAddress, string _phone/*, string _email, bytes32 _photoHash*/);

}

library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract Identity is ERC725 {
    
    using SafeMath for uint256;
    
    address public owner;
    
    uint256 count;
    
    string name;
    string postalAddress;
    string phone;
    string email; 
    
     bytes32 photoHash;
    
    struct DocumentandHash{
        uint256 hashID;
        string documentDetail;
        bytes32 docmentHash;
    }
    
    mapping (uint256 => DocumentandHash) DocHash;
    
    constructor(string _name, string _postalAddress, string _phone, string _email, bytes32 _photoHash) public {
        owner = msg.sender;
        
        name = _name;
        postalAddress =_postalAddress;
        phone = _phone;
        email = _email;
        photoHash = _photoHash;
        
        count = 1;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "only-owner-allowed");
        _;
    }
    
    function changeOwner(address _owner) external onlyOwner
    {
        owner = _owner;
        emit OwnerChanged(owner);
    }


    function setData(string _name, string _postalAddress, string _phone, string _email, bytes32 _photoHash) external onlyOwner
    {
        name = _name;
        postalAddress =_postalAddress;
        phone = _phone;
        email = _email;
        photoHash = _photoHash;
    
    }
    
    function setDocHash(string _certificate, bytes32 _hash) external onlyOwner {
        
        DocHash[count].hashID = count;
        DocHash[count].documentDetail = _certificate;
        DocHash[count].docmentHash = _hash;
        
        count = count.add(1);
        
    }

    function getDocHash(uint256 _id) public view returns(uint256 _hashID,string _certificate, bytes32 _hash){
        
        _hashID = DocHash[_id].hashID;
        _certificate = DocHash[_id].documentDetail;
        _hash = DocHash[_id].docmentHash;
    }
    
    function getCount() public view returns(uint256 _count) {
        _count = count.sub(1);
    }
    
    function getDataOfIdentity(bool _show) public view returns(string _name, string _postalAddress, string _phone, string _email, bytes32 _photoHash){
       
       if (_show ==  true)
       {
            _name = name;
            _postalAddress = postalAddress;
            _phone =  phone;
            _email =  email;
            _photoHash = photoHash;
       }
    }

}