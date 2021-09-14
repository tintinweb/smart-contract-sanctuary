/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

interface IBEP20 {

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function transferFromController(address sender, address recipient, uint256 amount) external returns(bool);
    event TokenTransfer(address indexed from, address indexed to, uint256 value);
    event TokenApproval(address indexed owner, address indexed spender, uint256 value);
}

interface IBEP721 {
    event NFTTransfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event NFTApproval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event NFTApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    function balanceOf(address _owner) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns(bool);
    //function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    //function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    //function approve(address _approved, uint256 _tokenId) external payable;
    
    function CreateCard(address _owner) external returns(uint256);
    function ActivateCard(address _owner, uint256 _cardId) external returns(uint256);
    function TransferCard(uint256 _cardId, address _fromowner, address _newowner) external returns(uint256);
    function getOwnerNFTCount(address _owner) external view returns(uint256);
    function getOwnerNFTIDs(address _owner) external view returns(uint256[] memory);
    function ViewCardInfo(uint _cardId) external view  returns(uint, address, uint, uint, bool, bool);
    function ForSaleCard(address _owner, uint256 _cardId) external returns(bool);
    function IsForSale(uint256 _cardId) external view returns(bool);
}

contract MainController{

    IBEP20 Token;
    IBEP721 NFT;

    bool public is_preselling;
    address payable owner;

    constructor(IBEP20 _tokenAddress, IBEP721 _nftAddress)  {
        Token = _tokenAddress;
        NFT = _nftAddress;
        owner = payable(msg.sender);
        is_preselling = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }
    
    function buytoken(address _from, uint256 _amount) public payable returns(bool)  {
        require(is_preselling, "pre selling is done.");
        Token.transferFrom(_from, msg.sender, _amount);
        return true;
    }
    
    function transfertoken(address _to, uint256 _amount) public returns(bool)  {
        Token.transferFrom(msg.sender, _to, _amount);
        return true;
    }

    function transfercard(uint256 _cardId, address _to) public returns(uint256)  {
        return NFT.TransferCard(_cardId, msg.sender, _to);
    }

    function activatecard(uint256 _cardId) public  returns(uint256)  {
        return NFT.ActivateCard(msg.sender, _cardId);
    }
    
    function forsalecard(uint256 _cardId) public returns(bool)  {
        return NFT.ForSaleCard(msg.sender, _cardId);
    }
    
    
    function buycard(uint256 _cardId, uint256 _amount) public payable returns(uint256)  {
        //check if buyer has enough balance
        require(getTokenbalance(msg.sender) >= _amount, "not enough balance");
        
        //check if card is for is_sale
        require(NFT.IsForSale(_cardId), "item not for sale");
        
        //get owner address
        address seller = getNFTOwnerAddress(_cardId);
        
        //transfer token payment
        Token.transferFromController(msg.sender, seller, _amount);
        
        //transfer nft item
        return NFT.TransferCard(_cardId, seller, msg.sender);
        
    }

    function preselling() public payable returns(uint256)  {
        require(is_preselling, "pre selling is done.");
        return NFT.CreateCard(msg.sender);
    }
    
    function getTokenbalance(address _address) public view returns(uint256){
        return Token.balanceOf(_address);
    }
    
    function getNFTCardInfo(uint256 _cardId) public view returns(uint cardId, address card_owner, uint access_count, uint replication_limit, bool is_activated, bool is_sale)  {
        return NFT.ViewCardInfo(_cardId);
    }
    
    function getNFTOwnerCardIds(address _owner) public view returns(uint256[] memory)  {
        return NFT.getOwnerNFTIDs(_owner);
    }
    
    function getNFTOwnerAddress(uint256 _cardId) public view returns(address)  {
        return NFT.ownerOf(_cardId);
    }

    function getbalance()  public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function TransferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function SetPreSellingStatus() public onlyOwner {
        if(is_preselling){
            is_preselling = false;
        }else{
            is_preselling = true;
        }
    }
    
}