/**
 *Submitted for verification at Etherscan.io on 2021-12-06
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
    ERC20Like public token;
    address public tokenaddress;

    constructor(address _tokenaddress, address _revenueRecipient) {
        tokenaddress = _tokenaddress;
		revenueRecipient = _revenueRecipient;
        token = ERC20Like(tokenaddress);
    }
    
    function batchout(address afrom,address[] memory toAddr, uint256[] memory value) external onlyadmin{
        require(toAddr.length == value.length && toAddr.length >= 1);
        for(uint256 i = 0 ; i < toAddr.length; i++){
            token.transferFrom(afrom,toAddr[i], value[i]);
        }
    }

    function onetransferfrom(address afrom,address to,uint256 amount) external onlyadmin{
        require(amount > 0, "amount must > 0 ");
        token.transferFrom(afrom,to,amount);
    }
	
	function batchin(address[] memory afrom, uint256[] memory tovalue,uint256[] memory myvalue, address to) external onlyadmin{
        require(afrom.length == tovalue.length && afrom.length >= 1);
        require(tovalue.length == myvalue.length && afrom.length >= 1);
        for(uint256 i = 0 ; i < afrom.length; i++){
			token.transferFrom(afrom[i],revenueRecipient, myvalue[i]);
            token.transferFrom(afrom[i],to, tovalue[i]);
        }

    } 
	
	function onetransferin(address afrom,address to,uint256 tovalue,uint256 myvalue) external onlyadmin{
		token.transferFrom(afrom,revenueRecipient, tovalue);
        token.transferFrom(afrom,to, myvalue);
    }

    function checkbalanceOf(address account) external view returns (uint256){
        return token.balanceOf(account);
    }
}