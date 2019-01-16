pragma solidity 0.4.24;

contract VanveoKYC {
    //read/write candidate
    address public admin;
    
    struct User {
        address userAddr;
        string userName;
        string userEmail;
        //uint phoneNumber;
            }
    mapping (address => User) public companyUserMap;
    // save address 2 times is waste
    //event AddUser (address indexed _userAddr, string _userName, string _userEmail);
   // event RemoveUser (address indexed _userAddr);
    //how to know where tx is going, log to check again all code (history) to know all data 
    //constructor
    constructor () public {
        admin = msg.sender;
        }
    function AddUser (address _userAddr, string _userName, string _userEmail) public {
        require (
            msg.sender == address (admin),
            "Only admin can call this."
            // Only admin can call this function
            );
            companyUserMap [_userAddr] = User (_userAddr, _userName, _userEmail);
    }
    
    function RemoveUser (address _userAddr) public {
        require (
            msg.sender == address (admin),
            "Only admin can call this."
            );
            companyUserMap [_userAddr] = User (0x0, "", "");
            //emit RemoveUser (_userAddr);
            
    }
    //funtion getUserInfo(address _userAddr) constant public returns (address, string,  )
    //User memory user = companyUserMap [_userAddr];
    //return (user.userAddr, user.userName, user.userEmail);
    //}
    function isUserKyc (address _userAddr) constant public returns (bool) {
        return companyUserMap [_userAddr].userAddr == _userAddr;
        
    }
    function transferAdmin (address _adminAddr) public {
        require (
            msg.sender == address (admin),
            "ONly admin can call this."
            );
            admin = _adminAddr;
    }
    
    
}