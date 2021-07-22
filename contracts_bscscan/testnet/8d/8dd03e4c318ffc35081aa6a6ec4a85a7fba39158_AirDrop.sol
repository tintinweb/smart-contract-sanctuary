/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AirDrop {
    struct claimedUser {
        bool claimed;
        address useraddress;
        uint256 claimedtime;
        uint256 claimedamount;
    }
    mapping (address => uint256) private users;
    mapping (address => claimedUser) public claimedUsers;
    uint256 count = 1;
    address public owner;
    IERC20 tokenContract;
    uint256 public airdropAmount;
   
    event AirDropClaimed(address receiver, uint256 time, uint256 value);
    
    constructor (address _tokenContract) public {
        owner = msg.sender;
        tokenContract = IERC20(_tokenContract);
    }
    
    function addAddresses(address[] memory _users) public {
        require(msg.sender == owner,"Permission Denied");
        for(uint256 i=0;i<_users.length;i++){
            if(users[_users[i]] != 0){
                users[_users[i]] = count;
                count++;
            }
        }
    }
    
    function checkAddress(address user) external view returns(bool){
        return users[user] != 0;
    }
    
    function claimAirdrop() external {
        require(users[msg.sender] != 0,"User not allowed to claim airdrop");
        require(!claimedUsers[msg.sender].claimed,"User not allowed to claim airdrop again");
        tokenContract.transfer(msg.sender,airdropAmount);
        claimedUsers[msg.sender] = claimedUser(true,msg.sender,block.timestamp,airdropAmount);
        emit AirDropClaimed(msg.sender,block.timestamp,airdropAmount);
    }
    function setAirdropamount(uint256 _amount,uint256 _decimals) external {
        require(msg.sender == owner,"Permission Denied");
        airdropAmount = _amount * 10 ** _decimals;
    }
    function settokenContract(address _tokencontract) external {
        require(msg.sender == owner,"Permission Denied");
        tokenContract = IERC20(_tokencontract);
    }
}