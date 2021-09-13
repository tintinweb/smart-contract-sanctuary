/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity ^0.5.10;

interface ERC20Interface {
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function transfer(address _to, uint256 _value) external;
  function approve(address _spender, uint256 _value) external returns (bool);
  function symbol() external view returns (string memory);
}

interface ERC721Interface {
  function transferFrom(address _from, address _to, uint256 _tokenId) external ;
  function ownerOf(uint256 _tokenId) external view returns (address);
  function approve(address _to, uint256 _tokenId) external;
}

contract Ownable {
  address payable public owner;

  constructor () public{
    owner = msg.sender;
  }

  modifier onlyOwner()  {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address payable newOwner) public onlyOwner {

    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract AuctionProxy is Ownable {
    //手续费，以100为单位，10/100
    uint public fee;   
    //合约内的拍卖数量，同时也作为id
    uint public auctionAmount;

    struct Auction {
        uint    auctionId;
        address nftAddess;
        uint256 tokenId;
        address payable holder;
        address payCoinAddress;
        string  payCoin;
        uint256 startPrice;
        uint256 miniIncreasePrice;
        uint256 maxPrice;   //一口价，达到这个价格则直接成交
        uint256 dealPrice;  //成交价格
        uint    expireDate;
        address payable bidAddress;
        uint256 bidValue;   
        uint    status;     //0-上架中 1-已完成
    }

    //拍卖映射列表
    mapping (address => mapping (uint256 => Auction)) public auctions;
    
    event NewAuction(
        address indexed _nftAddess,
        uint256 indexed _tokenId
    );
    
    event Bid(
        address indexed _nftAddess,
        uint256 indexed _tokenId,
        uint256 indexed _value
    );
    
    event AuctionSold(
        address indexed _nftAddess,
        uint256 indexed _tokenId
    );
    
    event AuctionOverdue(
        address indexed _nftAddess,  
        uint256 indexed _tokenId
    );
    
    event HandleOutSaleAuction(
        address indexed _nftAddess,  
        uint256 indexed _tokenId,
        uint indexed _agree
    );

    constructor(uint _fee) public{
        fee = _fee;
    }

    
    function createAuction (address nftAddess,uint256 tokenId,address payCoinAddress,string memory payCoin, uint256 startPrice, uint256 miniIncreasePrice, uint256 maxPrice,uint expireDate)  public payable returns(bool){
        //对变量处理
        require(startPrice >= 0);
        require(miniIncreasePrice>=0);
        require(expireDate >= 7 && expireDate <= 30);

        address holder = ERC721Interface(nftAddess).ownerOf(tokenId); 
        address payable nftHolder = address(uint160(holder));

        uint blockExpireDate = now + expireDate * 1 days;
        
        //接收nft
        ERC721Interface(nftAddess).transferFrom(holder,address(this),tokenId);
      
        Auction storage auction = auctions[nftAddess][tokenId];
        uint auctionId = auction.auctionId;
        if(auctionId == 0){
            auctionAmount ++;
            auctionId = auctionAmount;
        }
        
        //如果拍卖已结束并且有用户在结束后对拍卖对拍卖出价了，则退还出价
        if(auction.status == 1 && auction.bidValue != 0 && auction.bidAddress != address(0)){
            
            if(auction.payCoinAddress == address(0)){
                auction.bidAddress.transfer(auction.bidValue);
            }else{
                ERC20Interface(auction.payCoinAddress).transfer(auction.bidAddress,auction.bidValue);
            }
        }
        
        auction.auctionId = auctionAmount;
        auction.nftAddess = nftAddess;
        auction.tokenId = tokenId;
        auction.holder = nftHolder;
        auction.payCoinAddress = payCoinAddress;
        auction.payCoin = payCoin;
        auction.startPrice = startPrice;
        auction.miniIncreasePrice = miniIncreasePrice;
        auction.maxPrice = maxPrice;
        auction.dealPrice = 0;
        auction.expireDate = blockExpireDate;
        auction.bidAddress = address(0);
        auction.bidValue = 0;
        auction.status = 0;

        emit NewAuction(nftAddess,tokenId);

        return true;
    }

    function bid(address nftAddess,uint256 tokenId,uint256 value) public payable returns (bool){
        Auction memory auction = auctions[nftAddess][tokenId];
        
        require(auction.nftAddess != address(0));
        
        if(auction.payCoinAddress == address(0)){
            require(msg.value == value);
        }
        
        emit Bid(nftAddess,tokenId,value);
        
        if(auction.status == 0){
            return bidForOnSalePriceAuction(nftAddess,tokenId,value);
        }
        else {
            return bidForOutSalePriceAuction(nftAddess,tokenId,value);
        }
    }
    
    function bidForOutSalePriceAuction(address nftAddess,uint256 tokenId,uint256 value)  internal returns(bool){
        Auction storage auction = auctions[nftAddess][tokenId];
        
        //售出后第一次被出价 
        if(auction.bidAddress == address(0)){
            require(value > auction.dealPrice);
        }else{
            require(value > auction.bidValue);
            
            //退回上一个人的bid
            if(auction.payCoinAddress == address(0)){
                //退bnb
                auction.bidAddress.transfer(auction.bidValue);
            }else{
                //退token
                ERC20Interface(auction.payCoinAddress).transfer(auction.bidAddress,auction.bidValue);
            }
        }
        
        if(auction.payCoinAddress != address(0)){
            //接收token
            ERC20Interface(auction.payCoinAddress).transferFrom(msg.sender,address(this),value);
        }
        
        auction.bidAddress = msg.sender;
        auction.bidValue = value;
        //售出后拍卖品如果7天后未成交，则退回
        auction.expireDate = now + 7 days;
        
        return true;
    }

    function bidForOnSalePriceAuction(address nftAddess,uint256 tokenId,uint256 value) internal returns(bool) {
        Auction storage auction = auctions[nftAddess][tokenId];
        
        if(auction.bidAddress == address(0)){
            require(value>=auction.startPrice);
        }else{
            require(value >= auction.bidValue + auction.miniIncreasePrice);
            //退回上一个人的bid
            if(auction.payCoinAddress == address(0)){
                //退bnb
                auction.bidAddress.transfer(auction.bidValue);
            }else{
                //退token
                ERC20Interface(auction.payCoinAddress).transfer(auction.bidAddress,auction.bidValue);
            }
        }
        
        if(auction.payCoinAddress != address(0)){
            //接收token
            ERC20Interface(auction.payCoinAddress).transferFrom(msg.sender,address(this),value);
        }
        
        auction.bidAddress = msg.sender;
        auction.bidValue = value;
        
        if(auction.expireDate - now <= 30 minutes){
            auction.expireDate = now + 30 minutes;
        }
        
        //期望价成交
        if(value >= auction.maxPrice){
            return _sold(auction.nftAddess,auction.tokenId);
        }
        
        return true;
    }
    
    function handleOutSaleAuction(address nftAddess,uint256 tokenId,uint agree) public returns(bool){
        address holder = ERC721Interface(nftAddess).ownerOf(tokenId);
        require (msg.sender == holder || msg.sender == owner);
        
        Auction storage auction = auctions[nftAddess][tokenId];
        require(auction.status == 1);
      
        if(msg.sender == owner){
            require(agree == 0);
        }
        
        emit HandleOutSaleAuction(nftAddess,tokenId,agree);
        
        //退回出价
        if(agree == 0 && auction.bidAddress != address(0)){
             //退回上一个人的bid
            if(auction.payCoinAddress == address(0)){
                //退bnb
                auction.bidAddress.transfer(auction.bidValue);
            }else{
                //退token
                ERC20Interface(auction.payCoinAddress).transfer(auction.bidAddress,auction.bidValue);
            }
            
            auction.bidValue = 0;
            auction.bidAddress = address(0);
        }
        else if(agree == 1 && auction.bidAddress != address(0)){
            
            //转移nft以及根据手续费分发
            ERC721Interface(auction.nftAddess).transferFrom(msg.sender,auction.bidAddress,auction.tokenId);

            uint256 feeValue = auction.bidValue / fee;
            uint256 getValue = auction.bidValue - feeValue;

            if(auction.payCoinAddress == address(0)){
                owner.transfer(feeValue);
                auction.holder.transfer(getValue);
            }else{
                ERC20Interface(auction.payCoinAddress).transfer(owner,feeValue);
                ERC20Interface(auction.payCoinAddress).transfer(auction.holder,getValue);
            }
            
            auction.holder = auction.bidAddress;
            auction.dealPrice = auction.bidValue;
            auction.bidValue = 0;
            auction.bidAddress = address(0);
        }

        return true;
    }
    
    function sold (address nftAddess,uint256 tokenId) public payable onlyOwner returns (bool) {
        return _sold(nftAddess,tokenId);
    }

    function _sold (address nftAddess,uint256 tokenId) internal returns (bool) {
        Auction storage auction = auctions[nftAddess][tokenId];
        
        //退回
        if(auction.bidAddress == address(0)){
            //退回nft
            ERC721Interface(auction.nftAddess).transferFrom(address(this),auction.holder,auction.tokenId);
            emit AuctionOverdue(auction.nftAddess,auction.tokenId);
        }else{
            //转移nft以及根据手续费分发
            ERC721Interface(auction.nftAddess).transferFrom(address(this),auction.bidAddress,auction.tokenId);

            uint256 feeValue = auction.bidValue / fee;
            uint256 getValue = auction.bidValue - feeValue;

            if(auction.payCoinAddress == address(0)){
                owner.transfer(feeValue);
                auction.holder.transfer(getValue);
            }else{
                ERC20Interface(auction.payCoinAddress).transfer(owner,feeValue);
                ERC20Interface(auction.payCoinAddress).transfer(auction.holder,getValue);
            }
            
            auction.holder = auction.bidAddress;
            emit AuctionSold(auction.nftAddess,auction.tokenId);
        }

        //改变拍卖状态
        auction.status = 1;
        auction.dealPrice = auction.bidValue;
        auction.bidValue = 0;
        auction.bidAddress = address(0);
        auction.expireDate = 0;
        auction.startPrice = 0;
        auction.miniIncreasePrice = 0;
        auction.maxPrice = 0;

        return true;
    }
}