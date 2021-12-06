/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TimeLockedWallet{
    address public creator;
    address public owner;
    uint256 public unlockDate;
    address public tokenContract;
    uint256 public createdAt;

    modifier onlyOwner {
        require(msg.sender == owner,"Only Owner Error");
        _;
    }

    constructor(
        address creator_,
        address owner_,
        uint256 unlockDate_,
        address tokenContract_
    ){
        creator = creator_;
        owner = owner_;
        unlockDate = unlockDate_;
        tokenContract = tokenContract_;
        createdAt = block.timestamp;
    }

    function withdrawTokens() onlyOwner public {
       require(block.timestamp >= unlockDate,"Unlock Date Error");
       IERC20 token = IERC20(tokenContract);
       uint256 tokenBalance = token.balanceOf(address(this));
       token.transfer(owner, tokenBalance);
       emit WithdrewTokens(tokenContract, msg.sender, tokenBalance);
    }

    function info() public view returns(address, address, uint256, uint256, uint256) {
        IERC20 token = IERC20(tokenContract);
        uint256 tokenBalance = token.balanceOf(address(this));
        return (creator, owner, unlockDate, createdAt,tokenBalance);
    }

    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}

contract TimeLockedWalletFactory{
    mapping(address => address[]) wallets;
    address tokenContract;

    constructor(address _tokenContract){
        tokenContract=_tokenContract;
    }

    function getWallets(address _user) 
        public
        view
        returns(address[] memory)
    {
        return wallets[_user];
    }

    function newTimeLockedWallet(address _owner, uint256 _unlockDate)
      payable
      public
      returns(address wallet)
    {
        wallet = address(new TimeLockedWallet(msg.sender, _owner, _unlockDate,tokenContract));
        wallets[msg.sender].push(wallet);
        if(msg.sender != _owner){
            wallets[_owner].push(wallet);
        }
        emit Created(wallet, msg.sender, _owner, block.timestamp, _unlockDate, msg.value);
    }

    event Created(address wallet, address from, address to, uint256 createdAt, uint256 unlockDate, uint256 amount);
}