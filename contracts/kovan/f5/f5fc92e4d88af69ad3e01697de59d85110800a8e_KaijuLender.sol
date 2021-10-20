/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address sender, address recipient, uint256 tokenId) external returns (bool);
    function fusion(uint256 parent1, uint256 parent2) external;
    function walletOfOwner(address owner) external view returns(uint256[] memory);
}

contract KaijuLender {
    
    //1st Sender provides Kaiju, 750 RWASTE and 0.02 ETH fee
    //2nd Sender provides Kaiju n2, gets 0.01 ETH fee for provision
    //Contract makes baby kaiju, returns it to 1st Sender

    
    IERC721 public constant kaiju721 = IERC721(0x0c2E57EFddbA8c768147D1fdF9176a0A6EBd5d83);
    IERC20 public constant rwaste = IERC20(0x5cd2FAc9702D68dde5a94B1af95962bCFb80fC7d);
    
    uint public _parent1;
    address public _parent1acc;
    
    address public dev;
    constructor() {
        dev = msg.sender;
    }
    
    function requestMating(uint tokenId) external payable {
        require(msg.value == 0.02 ether);
        require(_parent1 == 0, "Already Occupied");
        
        kaiju721.transferFrom(msg.sender, address(this), tokenId);
        rwaste.transferFrom(msg.sender, address(this), 750 ether);
        _parent1acc = msg.sender;
        _parent1 = tokenId;
    }
    
    function lendToMate(uint tokenId) external {
        require(tx.origin == msg.sender, "eoa");
        require(_parent1 != 0, "Must have parent 1");
        //Transfer parent 2
        kaiju721.transferFrom(msg.sender, address(this), tokenId);
        
        //Approve to make baby
        rwaste.approve(address(kaiju721), 750 ether);
        
        //Make baby
        kaiju721.fusion(_parent1, tokenId);
        
        //Return Kaijus to owners
        kaiju721.transferFrom(address(this), _parent1acc, _parent1);
        kaiju721.transferFrom(address(this), msg.sender, tokenId);
        
        //Return baby to requester
        kaiju721.transferFrom(address(this), _parent1acc, kaiju721.walletOfOwner(address(this))[0]);
        
        delete _parent1acc;
        delete _parent1;
        
        //Pay lender for mating
        payable(msg.sender).transfer(0.01 ether);
        //Pay dev for making this contract
        payable(dev).transfer(0.01 ether);
    }
    
    function withdrawParent1() external {
        require(msg.sender == _parent1acc, "owner");
        //in memory
        uint parent1 = _parent1;
        //reset storage
        delete _parent1acc;
        delete _parent1;
        //return kaiju and rwaste to parent 1
        kaiju721.transferFrom(address(this), msg.sender, parent1);
        rwaste.transfer(msg.sender, 750 ether);
    }
    
}