/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

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
    uint256 public  _lockTime;    

    event owner_transferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit owner_transferred(address(0), msgSender);
    }

    function owner() private view returns (address) {
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

//- This is "Chainance Contract"
contract Chainance is Context, Ownable{
    using SafeMath for uint256;
    
    event LoginChainUpEvent(string Global_UserName);
    event CreateChainUpAccountEvent(string UserName, string NameSurname, string Email, string Description, string WebSite, address AccountAddress);
    event CreateChainUpEvent(string Data);
    event ViewChainUpAccountIdEvent(string UserName, string NameSurname, string Email, string Description, string WebSite, address AccountAddress);
    
    string private Global_UserName;
    
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
    
    modifier AccountControl {
        if (ChainUp_Accounts.length == 0) { 
            revert("Not Login : Err 1"); 
        } else _;
    }
    
    modifier LoginControl(string memory UserName) {
        if ( keccak256(abi.encodePacked(UserName)) == keccak256(abi.encodePacked("")) ) {
            revert("User Not Defined, Please Login");
        } else 
        _;
    }
    
    ChainUp_Account[]   private ChainUp_Accounts;
    ChainUp_ChainData[] private ChainUp_ChainDatas;

    //- Login ChainUp
    function _LoginChainUp() internal AccountControl {
        for ( uint i =0; i < ChainUp_Accounts.length; i++) {
            if ( ChainUp_Accounts[i].AccountAddress == msg.sender ) {
                Global_UserName = ChainUp_Accounts[i].UserName;
                emit LoginChainUpEvent(Global_UserName);
            } else {
                revert ("Not Login");
            }
        }
    }
    
    //- Create New ChainUp Account
    function CreateChainUpAccount(string memory _UserName, string memory _NameSurname, string memory _Email, string memory _Description, string memory _WebSite) public {
        for ( uint i = 0; i < ChainUp_Accounts.length; i++ ) {
            //- Address Control
            if ( ChainUp_Accounts[i].AccountAddress == msg.sender ) {
                revert("Address Avaible");        
            }
            //- UserName Control
            if ( keccak256(abi.encodePacked(ChainUp_Accounts[i].UserName)) == keccak256(abi.encodePacked(_UserName)) ) {
                revert("UserName Avaible");
            }
            //- EMail Control
            if ( keccak256(abi.encodePacked(ChainUp_Accounts[i].Email)) == keccak256(abi.encodePacked(_Email)) ) {
                revert("EMail Avaible");
            }
        }
        ChainUp_Accounts.push(ChainUp_Account(_UserName, _NameSurname, _Email, _Description, _WebSite, msg.sender));
        emit CreateChainUpAccountEvent(_UserName, _NameSurname, _Email, _Description, _WebSite, msg.sender);
    }
    
    function ViewChainUpAccountId(uint256 _id) public LoginControl(Global_UserName) view returns(string memory, string memory, string memory, string memory, string memory, address) {
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
    function CreateChainUp(string memory _Data) public LoginControl(Global_UserName) {
        ChainUp_ChainDatas.push(ChainUp_ChainData(block.timestamp, _Data, Global_UserName, msg.sender));
        emit CreateChainUpEvent(_Data);
    }    
    

    //- Use External Function's
    function LoginChainUp() external {
        _LoginChainUp();
    }    

}