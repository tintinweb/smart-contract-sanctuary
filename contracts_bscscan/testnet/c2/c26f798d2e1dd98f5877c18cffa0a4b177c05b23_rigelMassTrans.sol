/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC20 {
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract rigelMassTrans {
    
    address public owner;
    uint256 public amount;
    
    mapping(address => bool) public admin;
    
    constructor (uint256 _amt) {
        amount = _amt;
        owner = msg.sender;
        admin[msg.sender] = true;
    }
    
    // Only allow the owner to do specific tasks
    modifier onlyOwner() {
        require(msg.sender == owner,"RGP TOKEN: YOU ARE NOT THE OWNER.");
        _;
    }
   
    
    function addAdmin(address[] memory _admAddr) public onlyOwner{
        for (uint256 i = 0; i < _admAddr.length; i ++) {
            address _admin = _admAddr[i];
            admin[_admin] = true;
        }
    }
    
    function transfer_To_Multi_Wallet(address[] memory _user, address _token) public {
        require(admin[msg.sender] == true, "Caller is not an admin");
        for (uint256 i = 0; i < _user.length; i++) {
            address wallet = _user[i];
            IERC20(_token).transferFrom(owner, wallet, amount);
        }
    }
    
    function setAmount(uint256 _newAmount) public {
        require(admin[msg.sender] == true, "Caller is not an admin");
        amount = _newAmount;
    }
}