/**
 *Submitted for verification at BscScan.com on 2021-07-21
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

    event CreateChainUpAccountEvent(string UserName, string NameSurname, string Email, string Description, string WebSite, address AccountAddress);
    event CreateChainUpEvent(string Data);

    event LoginChainUpEvent(string Global_UserName);
    event ViewChainUpAccountIdEvent(string UserName, string NameSurname, string Email, string Description, string WebSite, address AccountAddress);
    
    struct ChainUp_Account {
        string  UserName;
        string  NameSurname;
        string  Email;
        string  Description;
        string  WebSite;
        address AccountAddress;
    }
    
    struct ChainUp_ChainData {
        uint256 DataTime;
        string  Data;
        string  DataUserName;
        address DataAccountAddress;
        //mapping(address => ChainUp_Account) Accounts;
    }
    
    //- Struct Array
    ChainUp_Account[]   private ChainUp_Accounts;
    ChainUp_ChainData[] private ChainUp_ChainDatas;

    function systemCount() public view returns(uint256) {
        uint256 RecordCount;
        for ( uint i = 0; i < ChainUp_Accounts.length; i++) 
            RecordCount = ++RecordCount;
        return(RecordCount);
    }
    
    modifier AccountControl {
        if (ChainUp_Accounts.length == 0) { 
            revert("err_code : 0"); //- There are no users.
        } else _;
    }
    
    modifier LoginControl(string memory UserName) {
        string memory _UserName = getAddressToUserName(msg.sender);
        if ( keccak256(abi.encodePacked(_UserName)) == keccak256(abi.encodePacked("")) ) {
            revert("err_code : 2"); //- User not defined, Please Login
        } else _;
    }
    
    modifier CreateAccountConrol(address myaddress, string memory username, string memory email) {
        for ( uint i = 0; i < ChainUp_Accounts.length; i++ ) {
            //- Address Control
            if ( ChainUp_Accounts[i].AccountAddress == myaddress ) revert("err_code : 3");        
            //- UserName Control
            if ( keccak256(abi.encodePacked(ChainUp_Accounts[i].UserName)) == keccak256(abi.encodePacked(username)) ) revert("err_code : 4");
            //- EMail Control
            if ( keccak256(abi.encodePacked(ChainUp_Accounts[i].Email)) == keccak256(abi.encodePacked(email)) ) revert("err_code : 5");
        } _;
    }
    
    //- Login ChainUp
    function LoginChainUp(address _address) public AccountControl view returns(string memory) {
        for ( uint i = 0; i < ChainUp_Accounts.length; i++) 
            if ( ChainUp_Accounts[i].AccountAddress == _address) return(ChainUp_Accounts[i].UserName);
                //emit LoginChainUpEvent(myUserName);
        revert ("err_code : 1"); //- Failed to login.
    }
    
    //- Create New ChainUp Account
    function CreateChainUpAccount(string memory _UserName, string memory _NameSurname, string memory _Email, string memory _Description, string memory _WebSite) public 
        CreateAccountConrol(msg.sender, _UserName, _Email) {
        
        ChainUp_Accounts.push(ChainUp_Account(_UserName, _NameSurname, _Email, _Description, _WebSite, msg.sender));
        emit CreateChainUpAccountEvent(_UserName, _NameSurname, _Email, _Description, _WebSite, msg.sender);
    }
    
    function getAddressToId(address _address) private AccountControl view returns(uint) {
        for ( uint i = 0; i < ChainUp_Accounts.length; i++ )
            if ( ChainUp_Accounts[i].AccountAddress == _address ) return i;
        //return type(uint).max;
        revert("err_code : 0"); 
    }
    
    function getAddressToUserName(address _address) private AccountControl view returns(string memory) {
        for ( uint i = 0; i < ChainUp_Accounts.length; i++ ) 
            if ( ChainUp_Accounts[i].AccountAddress == _address ) return(ChainUp_Accounts[i].UserName);
        revert("err_code : 0");
    }
    
    function ViewChainUpAccount(address _address) public view returns(string memory, string memory, string memory, string memory, string memory, address) {
        uint256 _id = getAddressToId(_address);
        string memory _UserName = ChainUp_Accounts[_id].UserName;
        string memory _NameSurname = ChainUp_Accounts[_id].NameSurname;
        string memory _Email = ChainUp_Accounts[_id].Email;
        string memory _Description = ChainUp_Accounts[_id].Description;
        string memory _WebSite = ChainUp_Accounts[_id].WebSite;
        address _Address = ChainUp_Accounts[_id].AccountAddress;
        return(_UserName, _NameSurname, _Email, _Description, _WebSite, _Address);
        //emit ViewChainUpAccountIdEvent(_UserName, _NameSurname, _Email, _Description, _WebSite, _Address);
    }

    //- Create ChainUp Data
    function CreateChainUp(string memory _Data) public {
        string memory _UserName = getAddressToUserName(msg.sender);
        if ( keccak256(abi.encodePacked(_UserName)) == keccak256(abi.encodePacked("")) ) {
            revert("err_code : 2"); //- User not defined, Please Login
        }
        ChainUp_ChainDatas.push(ChainUp_ChainData(block.timestamp, _Data, _UserName, msg.sender));
        emit CreateChainUpEvent(_Data);
    } 
    

}