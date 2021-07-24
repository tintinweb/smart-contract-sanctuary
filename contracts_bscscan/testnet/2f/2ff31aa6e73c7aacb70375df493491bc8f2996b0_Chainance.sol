/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

//- Algorithm and Coding by Tanay AYITMAZ
//- twitter:@tanayayitmaz
//- www.chainance.net

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

//- SafeMath Library
library SafeMath {  
    //- Mode Try
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    
    //- Mode Standart
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SM: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SM: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory SafeMathError) internal pure returns (uint256) {
        require(b <= a, SafeMathError);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SM: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SM: division by zero");
    }
    function div(uint256 a, uint256 b, string memory SafeMathError) internal pure returns (uint256) {
        require(b > 0, SafeMathError);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SM: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory SafeMathError) internal pure returns (uint256) {
        require(b != 0, SafeMathError);
        return a % b;
    }
}

//- Context Library
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

//- Ownable Library
abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private  _lockTime;    

    event owner_transferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit owner_transferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function contract_owner_renounce() public virtual onlyOwner {
        emit owner_transferred(_owner, address(0));
        _owner = address(0);
    }

    function contract_owner_transfer(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit owner_transferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    //- Contract Lock Function's
    function contract_unlock_time() public view returns (uint256) {
        return _lockTime;
    }
    
    function contract_lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = time;
        emit owner_transferred(_owner, address(0));
    }
    
    function contract_unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock.");
        require(block.timestamp > _lockTime , "This Contract is locked.");
        emit owner_transferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

library SearchChainanceAccount {
   function indexOf( uint[] storage self, uint256 value ) public view returns (uint256) {
      for (uint i = 0; i < self.length; i++) 
        if (self[i] == value) return i;
      return type(uint).max;
   }
}

//- This is "Chainance Contract"
contract Chainance is Context, Ownable{
    using SafeMath for uint256;

    uint256 public zeroBlock = block.number;

    event CreateAccountEvent(string UserName, string NameSurname, string Birthday, string Email, string Description, string WebSite, address AccountAddress);
    event CreateImageEvent(string Link, string Info, address AccountAddress);
    event CreateDataEvent(string Data, string UserName, string DataImageLink, address AccountAddress);

    //- Struct's
    struct Account {
        uint index;
        uint256 CreateTime;
        string  UserName;
        string  NameSurname;
        string  Birthday;
        string  Email;
        string  Description;
        string  WebSite;
        address Account_Address;
    }
    mapping (address => Account) private AccountStruct;
    address[] private AccountIndex;

    struct Image {
        uint256 index;
        uint256 ImageTime;
        string  ImageLink;
        string  ImageInfo;
        address Image_Address;
    }
    mapping(address => Image) private ImageStruct;
    address[] private ImageIndex;
    
    struct Data {
        uint256 index;
        uint256 DataTime;
        string  Data;
        string  DataImageLink;
        string  DataUserName;
        address Data_Address;
    }
    mapping(address => Data) private DataStruct;
    address[] private DataIndex;
    
    //- Modifier's
    function AccountCount() public view returns(uint256) {
        return AccountIndex.length;
    }
    
    modifier AccountControl {
        if (AccountIndex.length == 0) { 
            revert("err_code : 0"); //- There are no users.
        } else _;
    }
    
    modifier LoginControl(address _address) {
        if ( AccountStruct[_address].Account_Address != _address ) 
            revert ("err_code : 1"); //- Failed to login.
        if ( keccak256(abi.encodePacked(AccountStruct[_address].UserName)) == keccak256(abi.encodePacked("")) ) 
            revert("err_code : 2"); //- User not defined, Please Login
        else _;
    }
    
    //- Create Account Control in Code
    modifier CreateAccountControl(address _address, string memory _username, string memory _namesurname, string memory _email) {
        require(keccak256(abi.encodePacked(_username)) != keccak256(abi.encodePacked("")), "err_code : 7");
        require(keccak256(abi.encodePacked(_namesurname)) != keccak256(abi.encodePacked("")), "err_code : 8");
        require(keccak256(abi.encodePacked(_email)) != keccak256(abi.encodePacked("")), "err_code : 9");
        
        for ( uint i = 0; i < AccountIndex.length; i++ ) {
            //- Address Control
            if ( AccountStruct[AccountIndex[i]].Account_Address == _address  ) revert("err_code : 3");        
            //- UserName Control
            if ( keccak256(abi.encodePacked(AccountStruct[AccountIndex[i]].UserName)) == keccak256(abi.encodePacked(_username)) ) revert("err_code : 4");
            //- EMail Control
            if ( keccak256(abi.encodePacked(AccountStruct[AccountIndex[i]].Email)) == keccak256(abi.encodePacked(_email)) ) revert("err_code : 5");
        } _;
    }
    
    //- Create Account Control Algorithm 
    function CreateAccountController(address _address, string memory _username, string memory _email) public view returns(uint) {
        uint result = 0;
        for ( uint i = 0; i < AccountIndex.length; i++ ) {
            //- Address Control
            if ( AccountStruct[AccountIndex[i]].Account_Address == _address ) result=result+1; 
            //- UserName Control
            if ( keccak256(abi.encodePacked(AccountStruct[AccountIndex[i]].UserName)) == keccak256(abi.encodePacked(_username)) ) result=result+1;
            //- EMail Control
            if ( keccak256(abi.encodePacked(AccountStruct[AccountIndex[i]].Email)) == keccak256(abi.encodePacked(_email)) ) result=result+1;
        }
        return result;
    }
    
    //- Login Chainance
    function Login(address _address) public AccountControl view returns(string memory) {
        if ( AccountStruct[_address].Account_Address == _address ) return(AccountStruct[_address].UserName);
        revert ("err_code : 1"); //- Failed to login.
    }
    
    //- Create New  Account
    function CreateAccount(address _address, string memory _UserName, string memory _NameSurname, string memory _Birthday, string memory _Email, string memory _Description, string memory _WebSite) public 
        CreateAccountControl(_address, _UserName, _NameSurname, _Email) {
        AccountStruct[_address].CreateTime = block.timestamp;
        AccountStruct[_address].UserName = _UserName;
        AccountStruct[_address].NameSurname = _NameSurname;
        AccountStruct[_address].Birthday = _Birthday;
        AccountStruct[_address].Email = _Email;
        AccountStruct[_address].Description = _Description;
        AccountStruct[_address].WebSite = _WebSite;
        AccountStruct[_address].Account_Address = _address;
        AccountStruct[_address].index = AccountIndex.length;
        AccountIndex.push(_address);
        emit CreateAccountEvent(_UserName, _NameSurname, _Birthday, _Email, _Description, _WebSite, msg.sender);
    }
    
    //- Update Account
    function UpdateAccount(address _address, string memory _UserName, string memory _NameSurname, string memory _Birthday, string memory _Email, string memory _Description, string memory _WebSite) public returns(bool) {
        require(AccountStruct[_address].Account_Address == _address, "err_code : 6");
        if ( keccak256(abi.encodePacked(_UserName)) != keccak256(abi.encodePacked("")) ) AccountStruct[_address].UserName = _UserName;    
        if ( keccak256(abi.encodePacked(_NameSurname)) != keccak256(abi.encodePacked("")) ) AccountStruct[_address].NameSurname = _NameSurname;    
        if ( keccak256(abi.encodePacked(_Birthday)) != keccak256(abi.encodePacked("")) ) AccountStruct[_address].Birthday = _Birthday;    
        if ( keccak256(abi.encodePacked(_Email)) != keccak256(abi.encodePacked("")) ) AccountStruct[_address].Email = _Email;    
        if ( keccak256(abi.encodePacked(_Description)) != keccak256(abi.encodePacked("")) ) AccountStruct[_address].Description = _Description;    
        if ( keccak256(abi.encodePacked(_WebSite)) != keccak256(abi.encodePacked("")) ) AccountStruct[_address].WebSite = _WebSite;
        return true;
    }
    
    //- Create New Profile Image's
    function CreateAccountImage(address _address, string memory _Link, string memory _Info) public LoginControl(_address) {
        ImageStruct[_address].ImageTime = block.timestamp;
        ImageStruct[_address].ImageLink = _Link;
        ImageStruct[_address].ImageInfo = _Info;
        ImageStruct[_address].Image_Address = _address;
        ImageStruct[_address].index = ImageIndex.length;
        ImageIndex.push(_address);
        emit CreateImageEvent(_Link, _Info, _address);
    }
    
    //- Update Account Profile Image
    function UpdateAccountImage(address _address, string memory _Link, string memory _Info) public returns(bool) {
        require(AccountStruct[_address].Account_Address == _address, "err_code : 6");
        if ( keccak256(abi.encodePacked(_Link)) != keccak256(abi.encodePacked("")) ) ImageStruct[_address].ImageLink = _Link;    
        if ( keccak256(abi.encodePacked(_Info)) != keccak256(abi.encodePacked("")) ) ImageStruct[_address].ImageInfo = _Info;
        return true;
    }
    
    //- Create  Data
    function CreateData(address _address, string memory _Data, string memory _DataImageLink) public LoginControl(_address) {
        string memory _UserName = AccountStruct[_address].UserName;
        DataStruct[_address].DataTime = block.timestamp;
        DataStruct[_address].Data = _Data;
        DataStruct[_address].DataImageLink = _DataImageLink;
        DataStruct[_address].DataUserName = _UserName;
        DataStruct[_address].Data_Address = _address;
        DataStruct[_address].index = DataIndex.length;
        DataIndex.push(_address);
        emit CreateDataEvent(_Data, _UserName, _DataImageLink, _address);
    } 

    //- Get Account
    function getAccount(address _address) public view returns(uint256, string memory, string memory, string memory, string memory, string memory, string memory) {
        require(AccountStruct[_address].Account_Address == _address, "err_code : 6"); //- No account found at Wallet address.
        
        return(
        AccountStruct[_address].CreateTime,
        AccountStruct[_address].UserName,
        AccountStruct[_address].NameSurname,
        AccountStruct[_address].Birthday,
        AccountStruct[_address].Email,
        AccountStruct[_address].Description,
        AccountStruct[_address].WebSite);
    }
    
    //- Get Profile Image's
    function getAccountImage(address _address) public view returns(uint256, string memory, string memory, address) {
        require(ImageStruct[_address].Image_Address == _address, "err_code : 6");
        
        return(ImageStruct[_address].ImageTime,        
        ImageStruct[_address].ImageLink,
        ImageStruct[_address].ImageInfo,
        ImageStruct[_address].Image_Address);
    }
    
    //- Get Data
    function getData(address _address) public view returns(uint256, string memory, string memory, string memory, address) {
        require(DataStruct[_address].Data_Address == _address, "err_code : 6");
        
        return(DataStruct[_address].DataTime,
        DataStruct[_address].Data,
        DataStruct[_address].DataImageLink,
        DataStruct[_address].DataUserName,
        DataStruct[_address].Data_Address);
    }
}