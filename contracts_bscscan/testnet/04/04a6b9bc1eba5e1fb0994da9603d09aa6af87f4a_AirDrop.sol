/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

pragma solidity ^0.8.4;

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
    struct airDropUser {
        bool added;
        address useraddress;
        uint256 claimableAmount;
    }
    mapping (address => airDropUser) private users;
    mapping (address => claimedUser) public claimedUsers;
    uint256 public count = 1;
    address public owner;
    IERC20 tokenContract;
    uint256 public decimals;
   
    event AirDropClaimed(address receiver, uint256 time, uint256 value);
    
    constructor (address _tokenContract,uint256 _decimals)  {
        owner = msg.sender;
        tokenContract = IERC20(_tokenContract);
        decimals = _decimals;
    }
    
    function addAddresses(address[] memory _users,uint256[] memory _amount) public {
        require(msg.sender == owner,"Permission Denied");
        for(uint256 i=0;i<_users.length;i++){
            users[address(_users[i])] = airDropUser(true,address(_users[i]),_amount[i] * 10 ** decimals);
            count++;
        }
    }
    
    function checkAddress(address user) external view returns(bool _added,address _useraddress,uint256 _amount){
        _added = users[user].added;
        _useraddress = users[user].useraddress;
        _amount = users[user].claimableAmount;
    }
    
    function claimAirdrop() external {
        require(users[msg.sender].added,"User not allowed to claim airdrop");
        require(!claimedUsers[msg.sender].claimed,"User not allowed to claim airdrop again");
        tokenContract.transferFrom(owner,msg.sender,users[msg.sender].claimableAmount);
        claimedUsers[msg.sender] = claimedUser(true,msg.sender,block.timestamp,users[msg.sender].claimableAmount);
        emit AirDropClaimed(msg.sender,block.timestamp,users[msg.sender].claimableAmount);
    }
    function setAirdropamount(uint256 _amount,address user) external {
        require(msg.sender == owner,"Permission Denied");
        require(users[user].added,"User not found");
        users[user].claimableAmount = _amount * 10 ** decimals;
    }
    function settokenContract(address _tokencontract) external {
        require(msg.sender == owner,"Permission Denied");
        tokenContract = IERC20(_tokencontract);
    }
    function setdecimals(uint256 _decimals) external {
        require(msg.sender == owner,"Permission Denied");
        decimals = _decimals;
    }
}