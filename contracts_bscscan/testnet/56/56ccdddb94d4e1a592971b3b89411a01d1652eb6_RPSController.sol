/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    //function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    //function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    //function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    
    function Create(address _owner) external returns(uint256);
    function ActivateCard(address _owner, uint256 _cardId) external returns(uint256);
    function TransferCard(uint256 _cardId, address _fromowner, address _newowner) external returns(uint256);
    
    function getOwnerNFTCount(address _owner) external view returns(uint256);
    function getOwnerNFTIDs(address _owner) external view returns(uint256[] memory);
    
    function ViewCardInfo(uint _cardId) external view  returns (uint, address, uint, uint, bool);
}

contract RPSController{
    
    IBEP20 RACToken;
    IERC721 RACNFT;
    
    bool is_preselling;
    address payable owner;
    
    constructor(IBEP20 _tokenAddress, IERC721 _nftAddress)  {
        RACToken = _tokenAddress;
        RACNFT = _nftAddress;
        owner = payable(msg.sender);
        is_preselling = true;
    }
    
    modifier onlyOwner () {
       require(msg.sender == owner, "This can only be called by the contract owner!");
       _;
     }
    
    function checkbalance(address _address) public view returns(uint256){
        return RACToken.balanceOf(_address);
    }
    
    function transfer(address _to, uint256 _amount) public returns (bool)  {
        RACToken.transferFrom(msg.sender, _to, _amount);
        //require(amt != 0 , "deposit amount cannot be zero");
        //tokenContract.transfer(address(this),amt);
        return true;
    }
    
    function transfercard(uint256 _cardId, address _to) public payable returns (uint256)  {
        return RACNFT.TransferCard(_cardId, msg.sender, _to);
    }
    
    function activatecard(uint256 _cardId) public payable returns (uint256)  {
        return RACNFT.ActivateCard(msg.sender, _cardId);
    }
    function getCardInfo(uint256 _cardId) public view returns (uint, address, uint, uint, bool)  {
        return RACNFT.ViewCardInfo(_cardId);
    }
    function getOwnerCardIds(address _owner) public view returns (uint256[] memory)  {
        return RACNFT.getOwnerNFTIDs(_owner);
    }
    
    function preselling() public payable returns (uint256)  {
        require(is_preselling, "pre selling is done.");
        //RACToken.transferFrom(msg.sender, _to, _amount);
        return RACNFT.Create(msg.sender);
    }
    
    function getbalance() onlyOwner public {
        owner.transfer(address(this).balance);
    
    }
}