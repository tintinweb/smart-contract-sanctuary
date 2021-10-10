/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IBEP20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function transferFromController(address sender, address recipient, uint256 amount) external returns(bool);
    function transferFromMain(address recipient, uint256 amount) external returns(bool); 
}

interface IBEP721 {
    function balanceOf(address _owner) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function ReplicateCard(address _owner, uint256 _cardId) external returns(uint256);
    function ActivateCard(address _owner, uint256 _cardId) external returns(uint256);
    function CreateCard(address _owner) external returns(uint256);
    function TransferCard(uint256 _cardId, address _fromowner, address _newowner) external returns(uint256);
    function ForSaleCard(address _owner, uint256 _cardId) external returns(bool);
    function CancelForSaleCard(address _owner, uint256 _cardId) external returns(bool);
    function IsForSale(uint256 _cardId) external view returns(bool);
    function IsActivated(uint256 _cardId) external view returns(bool);
    function getOwnerNFTCount(address _owner) external view returns(uint256);
    function getOwnerNFTIDs(address _owner) external view returns(uint256[] memory);
    function totalSupply() external view returns(uint256);
}

interface IStorage{
    function setIntStrUint(uint256 _keyId, string memory _name, uint256 _value) external;
    function setIntStrBool(uint256 _keyId, string memory _name, bool _value) external;
    function getIntStrUint(uint256 _keyId, string memory _keyName) external view returns(uint256);
    function getIntStrBool(uint256 _keyId, string memory _keyName) external view returns(bool);
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
    IStorage Storage;

    bool public is_preselling;
    address payable owner;
    address payable fundreceiver;
    address payable commreceiver;
    uint8 accessLimit;
    uint8 accessRange;
    uint8 replication;
    uint256 private xSalt;
    
    constructor(IBEP20 _tokenAddress, IBEP721 _nftAddress, IStorage _storageAddress)  {
        Token = _tokenAddress;
        NFT = _nftAddress;
        Storage = _storageAddress;
        
        owner = payable(msg.sender);
        fundreceiver = owner;
        commreceiver = owner;
        is_preselling = true;
        accessRange = 11; //random 0-10 + 10 = max 20;
        accessLimit = 20;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }
    
    

    
    function exchangepoints(uint256 _amount, bytes32 _xData) public returns(bool)  {
        bytes32 digest = keccak256(abi.encodePacked(_amount, msg.sender, xSalt));
        require(digest == _xData, "invalid request");
        Token.transferFromMain(msg.sender, _amount);
        emit TokenClaimed(msg.sender, _amount);
        return true;
    }
    
    
    function buycard(bytes32 xData) public payable returns(uint256)  {
        require(msg.value > 0, "invalid amount");
        bytes32 digest = keccak256(abi.encodePacked(msg.value, msg.sender, xSalt));
        require(digest == xData, "invalid request");
        //pre-selling
        require(is_preselling, "pre selling is done");
        
        uint256 _cardId = NFT.CreateCard(msg.sender);
        Storage.setIntStrUint(_cardId, 'origin', 0);
        fundreceiver.transfer(msg.value);
        emit NFTPurchased(msg.sender, msg.value, _cardId);
        return _cardId;
    }
    
    function activatecard(uint256 _cardId) public returns(bool) {
        address _owner = msg.sender;
        NFT.ActivateCard(_owner, _cardId);
        //set card properties
        uint _accessLimit = accessLimit - random(accessRange, _cardId);
        //save data
        Storage.setIntStrUint(_cardId, 'access_count', _accessLimit);
        //Storage.setIntStrUint(_cardId, 'replication_count', _accessLimit);
        emit NFTActivateCard(_owner, _cardId);
        return true;
    }
    
    function random(uint8 rndLimit, uint256 salt) view internal returns(uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.difficulty, msg.sender, salt))) % rndLimit;
        return randomnumber;
    }
    
    function transfercard(uint256 _cardId, address _to) public returns(uint256)  {
        NFT.TransferCard(_cardId, msg.sender, _to);
        emit NFTTransfer(msg.sender, _to, _cardId);
        return _cardId;
    }
    
    
    
    
    function transfertoken(address _to, uint256 _amount) public returns(bool)  {
        Token.transferFrom(msg.sender, _to, _amount);
        return true;
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
    

    function replicatecard(uint256 _cardId) public returns(uint256)  {
        require(Storage.getIntStrBool(_cardId, 'replicated') == false, "already replicated");
        uint256 newCardId = NFT.CreateCard(msg.sender);
        Storage.setIntStrBool(_cardId, 'replicated', true);
        Storage.setIntStrUint(_cardId, 'origin', _cardId);
        emit NFTReplicateCard(msg.sender, _cardId, newCardId);
        return newCardId;
    }

    function buymarketplace(uint256 _cardId, uint256 _amount, bytes32 _xData) public payable returns(uint256)  {
        bytes32 digest = keccak256(abi.encodePacked(_amount, msg.sender, xSalt));
        require(digest == _xData, "invalid request");
        
        //check if buyer has enough balance
        require(getTokenbalance(msg.sender) >= _amount, "not enough balance");

        //check if card is for is_sale
        require(NFT.IsForSale(_cardId), "item not for sale");

        //get owner address
        address seller = getNFTOwnerAddress(_cardId);
        NFT.TransferCard(_cardId, seller, msg.sender);
        //get 5% com
        uint256 _salecom = (_amount * 5) / 100;
        //seller receive amount
        _amount = _amount  - _salecom;
        //transfer token payment
        Token.transferFromController(msg.sender, commreceiver, _salecom);
        Token.transferFromController(msg.sender, seller, _amount);

        //transfer nft item
        return _cardId;
    }

    

    function getTokenbalance(address _address) public view returns(uint256){
        return Token.balanceOf(_address);
    }

    function getNFTOwnerCount(address _address) public view returns(uint256){
        return NFT.getOwnerNFTCount(_address);
    }

    function getNFTCardInfo(uint256 _cardId) public view returns(uint cardId, address card_owner, uint access_count, bool is_replicated, uint256 origin, bool is_activated, bool is_sale)  {
        
        return(_cardId, NFT.ownerOf(_cardId), getAccessCount(_cardId), isReplicated(_cardId), getOrigin(_cardId), isActivated(_cardId), isForSale(_cardId));
    }

    function isActivated(uint256 _cardId) public view returns(bool)  {
        return NFT.IsActivated(_cardId);
    }
    
    function isForSale(uint256 _cardId) public view returns(bool)  {
        return NFT.IsForSale(_cardId);
    }
    
    function getAccessCount(uint256 _cardId) public view returns(uint256)  {
        return Storage.getIntStrUint(_cardId, 'access_count');
    }
    
    function isReplicated(uint256 _cardId) public view returns(bool)  {
        return Storage.getIntStrBool(_cardId, 'replicated');
    }
    
    function getOrigin(uint256 _cardId) public view returns(uint256)  {
        return Storage.getIntStrUint(_cardId, 'origin');
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
        selfdestruct(owner);
    }

    function TransferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function SetSalt(uint256 _hash) public onlyOwner {
        xSalt = _hash;
    }
    
    function SetfundReceiver(address payable _address) public onlyOwner {
        fundreceiver = _address;
    }
    
    function SetcommReceiver(address payable _address) public onlyOwner {
        commreceiver = _address;
    }

    function SetPreSellingStatus() public onlyOwner {
        if (is_preselling) {
            is_preselling = false;
        } else {
            is_preselling = true;
        }
    }

}