//SourceUnit: Certificate.sol

pragma solidity >=0.5.0 < 0.6.0;


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


contract AdminRole {
    using Roles for Roles.Role;
    address public certificateAuthority;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    Roles.Role private _Admins;

    constructor () internal {
        _addAdmin(msg.sender);
        certificateAuthority = msg.sender;
    }
    

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }
    
 
    modifier onlyCertificateAuthority() {
        require(msg.sender == certificateAuthority, "Ownable: caller is not the Certificate Authority");
        _;
    }

 

    function transferOwnership(address newOwner) public onlyCertificateAuthority {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(certificateAuthority, newOwner);
        certificateAuthority = newOwner;
    }
    

    function isAdmin(address account) public view returns (bool) {
        return _Admins.has(account);
    }

    function addAdmin(address account) public onlyCertificateAuthority {
        _addAdmin(account);
    }
    function removeAdmin(address account) public onlyCertificateAuthority {
        _removeAdmin(account);
    }

    function renounceAdmin() public {
        require(msg.sender!=certificateAuthority, "certificateAuthority Cannot Revoke their Admin Role");
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _Admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _Admins.remove(account);
        emit AdminRemoved(account);
    }
}

contract Certificate is AdminRole {
    
    struct User {
        uint256 uid;
        string name;
        string course;
        uint256 date;
        bytes32 key;
        uint256 count;
        string issuedby;
    }
    
    string public certificateAuthorityName;
    uint256 public uid;
    
    mapping (bytes32 => bytes32) public certificate;
    mapping(bytes32 => User) public users;
    
    
    event Issued(string name, uint256 uid, bytes32 key);
    
    constructor (string memory _certificateAuthorityName) payable public {
        
        certificateAuthorityName = _certificateAuthorityName;
        
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    //Issue Certificate by entering uid, name, course and date
    function issueCertificate(uint256 _uid, string memory _name, string memory _course, uint256 _date, string memory _issuedby) public onlyCertificateAuthority returns(bytes32) {
        require(certificate[keccak256(abi.encodePacked(_uid))]==0,"UID already Exists");
        uid++;
        
        
        bytes32 key = keccak256(abi.encodePacked(_uid));
        certificate[key] = keccak256(abi.encodePacked(_uid,_name,_course,_date,_issuedby)); //storage
        
        users[key].uid = _uid;
        users[key].name = _name;
        users[key].course = _course;
        users[key].date = _date;
        users[key].key = key;
        users[key].count = uid;
        users[key].issuedby = _issuedby;
        
        emit Issued(_name,_uid,key); //fire issued event
        return key;
        
    }
    
    function issueCertificateSecAdmin(uint256 _uid, string memory _name, string memory _course, uint256 _date, string memory _issuedby) public onlyAdmin returns(bytes32) {
        require(certificate[keccak256(abi.encodePacked(_uid))]==0,"UID already Exists");
        uid++;
        
        
        bytes32 key = keccak256(abi.encodePacked(_uid));
        certificate[key] = keccak256(abi.encodePacked(_uid,_name,_course,_date,_issuedby)); //storage
        
        users[key].uid = _uid;
        users[key].name = _name;
        users[key].course = _course;
        users[key].date = _date;
        users[key].key = key;
        users[key].count = uid;
        users[key].issuedby = _issuedby;
        
        emit Issued(_name,_uid,key); //fire issued event
        return key;
    }
    
    
    //After the QR code is scanned the array is entered in this function and verified by user
    function verifyCertificateUsingDetails(uint256 _uid, string memory _name, string memory _course, uint256 _date, string memory _issuedby) public view returns (bool) {
        
        if( certificate[keccak256(abi.encodePacked(_uid))] == keccak256(abi.encodePacked(_uid, _name,_course, _date,_issuedby)) ) {
            return true;
        }
            return false;
    }

     function userInfo(bytes32 key) view external returns(uint256 _uuid, string memory _name, string memory _course, uint256 _date, bytes32 _key, uint256 _count, string memory _issuedby) {
        return (    users[key].uid,
                    users[key].name,
                    users[key].course,
                    users[key].date,
                    users[key].key,
                    users[key].count ,
                    users[key].issuedby);
    }





}