/**
 *Submitted for verification at BscScan.com on 2021-09-21
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
    function transferFromMain(address recipient, uint256 amount) external returns(bool); 
}

interface IBEP721 {
    function balanceOf(address _owner) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function CreateCard(address _owner, uint _origin) external returns(uint256);
    function ReplicateCard(address _owner, uint256 _cardId) external returns(uint256);
    function ActivateCard(address _owner, uint256 _cardId) external returns(uint256);
    function TransferCard(uint256 _cardId, address _fromowner, address _newowner) external returns(uint256);
    function ForSaleCard(address _owner, uint256 _cardId) external returns(bool);
    function CancelForSaleCard(address _owner, uint256 _cardId) external returns(bool);
    function getOwnerNFTCount(address _owner) external view returns(uint256);
    function getOwnerNFTIDs(address _owner) external view returns(uint256[] memory);
    function ViewCardInfo(uint _cardId) external view  returns(uint, address, uint, uint, uint, uint, bool, bool);
    function IsForSale(uint256 _cardId) external view returns(bool);
    function totalSupply() external view returns (uint256);
}

contract TestController{

    event NFTTransfer(address indexed _from, address indexed _to, uint256 indexed _cardId);
    event NFTForSale(address indexed _owner, uint256 indexed _cardId);
    event NFTCancelForSale(address indexed _owner, uint256 indexed _cardId);
    event NFTReplicateCard(address indexed _owner, uint256 indexed _cardId, uint256 indexed _newCardId);
    event NFTActivateCard(address indexed _owner, uint256 indexed _cardId);
    event NFTPurchased(address indexed _owner, uint256 _amount, uint256 indexed _caCancelrdId);
    event TokenPurchased(address indexed _owner, uint256 _amount, uint256 _bnb);
    event TokenClaimed(address indexed _owner, uint256 _amount);


    IBEP20 Token;
    IBEP721 NFT;

    bool public is_preselling;
    address payable owner;
    address payable vault;
    address payable commissionAddress;

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

    function buytoken(uint256 _amount) public payable returns(bool)  {
        //pre-selling
        require(is_preselling, "pre selling is done.");
        Token.transferFromMain(msg.sender, _amount);
        vault.transfer(msg.value);
        emit TokenPurchased(msg.sender, _amount, msg.value);
        return true;
    }
    
    function claimtokens(uint256 _amount) public returns(bool)  {
        Token.transferFromMain(msg.sender, _amount);
        emit TokenClaimed(msg.sender, _amount);
        return true;
    }
    
    function buynft() public payable returns(uint256)  {
        //pre-selling
        require(is_preselling, "pre selling is done.");
        uint256 cardId = NFT.CreateCard(msg.sender, 0);
        vault.transfer(msg.value);
        emit NFTPurchased(msg.sender, msg.value, cardId);
        return cardId;
    }

    function transfertoken(address _to, uint256 _amount) public returns(bool)  {
        Token.transferFrom(msg.sender, _to, _amount);
        return true;
    }

    function transfercard(uint256 _cardId, address _to) public returns(uint256)  {
        NFT.TransferCard(_cardId, msg.sender, _to);
        emit NFTTransfer(msg.sender, _to, _cardId);
        return _cardId;
    }

    function activatecard(uint256 _cardId) public returns(uint256)  {
        NFT.ActivateCard(msg.sender, _cardId);
        emit NFTActivateCard(msg.sender, _cardId);
        return _cardId;
    }

    function replicatecard(uint256 _cardId) public returns(uint256)  {
        uint256 newCardId = NFT.ReplicateCard(msg.sender, _cardId);
        emit NFTReplicateCard(msg.sender, _cardId, newCardId);
        return newCardId;
    }

    function forsalecard(uint256 _cardId) public returns(bool)  {
        NFT.ForSaleCard(msg.sender, _cardId);
        emit NFTForSale(msg.sender, _cardId);
        return true;
    }
    
    function cancelforsalecard(uint256 _cardId) public returns(bool)  {
        NFT.CancelForSaleCard(msg.sender, _cardId);
        emit NFTCancelForSale(msg.sender, _cardId);
        return true;
    }


    function buycard(uint256 _cardId, uint256 _amount) public payable returns(uint256)  {
        //check if buyer has enough balance
        require(getTokenbalance(msg.sender) >= _amount, "not enough balance");

        //check if card is for is_sale
        require(NFT.IsForSale(_cardId), "item not for sale");

        //get owner address
        address seller = getNFTOwnerAddress(_cardId);
        
        //get 5% com
        uint256 _salecom = (_amount * 5) / 100;
        //seller receive amount
        _amount = _amount  - _salecom;
        //transfer token payment
        Token.transferFromController(msg.sender, commissionAddress, _salecom);
        Token.transferFromController(msg.sender, seller, _amount);

        //transfer nft item
        return NFT.TransferCard(_cardId, seller, msg.sender);

    }

    

    function getTokenbalance(address _address) public view returns(uint256){
        return Token.balanceOf(_address);
    }

    function getNFTOwnerCount(address _address) public view returns(uint256){
        return NFT.getOwnerNFTCount(_address);
    }

    function getNFTCardInfo(uint256 _cardId) public view returns(uint cardId, address card_owner, uint access_count, uint replication_limit, uint replicated_count, uint origin, bool is_activated, bool is_sale)  {
        return NFT.ViewCardInfo(_cardId);
    }

    function getNFTOwnerCardIds(address _owner) public view returns(uint256[] memory)  {
        return NFT.getOwnerNFTIDs(_owner);
    }

    function getNFTOwnerAddress(uint256 _cardId) public view returns(address)  {
        return NFT.ownerOf(_cardId);
    }
    function totalNFTs() public view returns(uint256)  {
        return NFT.totalSupply();
    }


    function getbalance()  public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function TransferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function SetReceiver(address payable _receiver) public onlyOwner {
        vault = _receiver;
    }

    function SetPreSellingStatus() public onlyOwner {
        if (is_preselling) {
            is_preselling = false;
        } else {
            is_preselling = true;
        }
    }

}