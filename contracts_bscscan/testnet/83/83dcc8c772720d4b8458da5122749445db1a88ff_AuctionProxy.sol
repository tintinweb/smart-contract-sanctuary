/**
 *Submitted for verification at BscScan.com on 2021-09-24
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
        address nftAddress;
        uint256 tokenId;
        address payable holder;
        address payCoinAddress;
        uint256 startPrice;
        uint256 miniIncreasePrice;
        uint256 maxPrice;   //一口价，达到这个价格则直接成交
        uint256 dealPrice;  //成交价格
        uint    expireDate;
        address payable bidAddress;
        uint256 bidValue;   
        string  bidFrom;
        uint    status;     //0-上架中 1-已完成
    }

    //拍卖映射列表
    mapping (address => mapping (uint256 => Auction)) public auctions;
    
    event NewAuction(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        string _from
    );
    
    event Bid(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        address indexed _bidAddress,
        uint256 _value,
        string _from
    );
    
    event AuctionSold(
        address indexed _nftAddress,
        uint256 indexed _tokenId
    );
    
    event AuctionOverdue(
        address indexed _nftAddress,  
        uint256 indexed _tokenId
    );
    
    event AgreeOutSaleAuctionBid(
        address indexed _nftAddress,  
        uint256 indexed _tokenId
    );
    
    event RefuseOutSaleAuctionBid(
        address indexed _nftAddress,  
        uint256 indexed _tokenId
    );
    
    event CancelAuction(
        address indexed _nftAddress,  
        uint256 indexed _tokenId
    );

    constructor(uint _fee) public{
        fee = _fee;
    }
    
    function modifyFee(uint _fee) public onlyOwner returns(bool){
        fee = _fee;
        return true;
    }

    
    function createAuction (address nftAddress,uint256 tokenId,address payCoinAddress, uint256 startPrice, uint256 miniIncreasePrice, uint256 maxPrice,uint expireDate,string memory createFrom)  public payable returns(bool){
        //对变量处理
        require(startPrice >= 0);
        require(miniIncreasePrice > 0);
        require(maxPrice >= startPrice);
        require(expireDate >= 7 * 24 * 60 * 60 && expireDate <= 30 * 24 * 60 * 60);

        address holder = ERC721Interface(nftAddress).ownerOf(tokenId); 
        address payable nftHolder = address(uint160(holder));

        uint blockExpireDate = now + expireDate * 1 seconds;
        
        //接收nft
        ERC721Interface(nftAddress).transferFrom(holder,address(this),tokenId);
      
        Auction storage auction = auctions[nftAddress][tokenId];
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
        
        auction.auctionId = auctionId;
        auction.nftAddress = nftAddress;
        auction.tokenId = tokenId;
        auction.holder = nftHolder;
        auction.payCoinAddress = payCoinAddress;
        auction.startPrice = startPrice;
        auction.miniIncreasePrice = miniIncreasePrice;
        auction.maxPrice = maxPrice;
        auction.dealPrice = 0;
        auction.expireDate = blockExpireDate;
        auction.bidAddress = address(0);
        auction.bidValue = 0;
        auction.bidFrom = "";
        auction.status = 0;

        emit NewAuction(nftAddress,tokenId,createFrom);

        return true;
    }

    function bid(address nftAddress,uint256 tokenId,uint256 value,string memory bidFrom) public payable returns (bool){
        Auction memory auction = auctions[nftAddress][tokenId];
        
        require(auction.nftAddress != address(0));
        
        if(auction.payCoinAddress == address(0)){
            require(msg.value == value);
        }
        
        emit Bid(nftAddress,tokenId,msg.sender,value,bidFrom);
        
        if(auction.status == 0){
            return bidForOnSalePriceAuction(nftAddress,tokenId,value,bidFrom);
        }
        else {
            return bidForOutSalePriceAuction(nftAddress,tokenId,value,bidFrom);
        }
    }
    
    function bidForOutSalePriceAuction(address nftAddress,uint256 tokenId,uint256 value,string memory bidFrom)  internal returns(bool){
        Auction storage auction = auctions[nftAddress][tokenId];
        
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
        auction.bidFrom = bidFrom;
        //售出后拍卖品如果7天后未成交，则退回
        auction.expireDate = now + 7 days;
        
        return true;
    }

    function bidForOnSalePriceAuction(address nftAddress,uint256 tokenId,uint256 value,string memory bidFrom) internal returns(bool) {
        Auction storage auction = auctions[nftAddress][tokenId];
        
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
        auction.bidFrom = bidFrom;

        
        if(auction.expireDate - now <= 30 minutes){
            auction.expireDate = now + 30 minutes;
        }
        
        //期望价成交
        if(value >= auction.maxPrice){
            return _sold(auction.nftAddress,auction.tokenId);
        }
        
        return true;
    }
    
    function acceptPrice(address nftAddress,uint256 tokenId)  public returns(bool){
        Auction memory auction = auctions[nftAddress][tokenId];
        require(msg.sender == auction.holder);
        require(auction.bidValue != 0);
        require(auction.status == 0);
        
        return _sold(nftAddress,tokenId);
    }
    
    function cancelAuction(address nftAddress,uint256 tokenId)  public returns(bool){
        
        Auction storage auction = auctions[nftAddress][tokenId];
        require(msg.sender == auction.holder);
        
        if(auction.bidAddress != address(0)){
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
            auction.bidFrom = "";
        }
        
        emit CancelAuction(nftAddress,tokenId);
        
        //退回nft
        ERC721Interface(auction.nftAddress).transferFrom(address(this),auction.holder,auction.tokenId);
        
        auction.status = 1;
        auction.expireDate = 0;
        auction.startPrice = 0;
        auction.miniIncreasePrice = 0;
        auction.maxPrice = 0;
        
        return true;
    }
    
    function agreeOutSaleAuctionBid(address nftAddress,uint256 tokenId) public returns(bool){
        
        address holder = ERC721Interface(nftAddress).ownerOf(tokenId);
        require (msg.sender == holder);
        
        emit AgreeOutSaleAuctionBid(nftAddress,tokenId);

        return handleOutSaleAuction(nftAddress,tokenId,1);
    }
    
    function refuseOutSaleAuctionBid(address nftAddress,uint256 tokenId) public returns(bool){
        address holder = ERC721Interface(nftAddress).ownerOf(tokenId);
        require (msg.sender == holder || msg.sender == owner);
        
        emit RefuseOutSaleAuctionBid(nftAddress,tokenId);

        return handleOutSaleAuction(nftAddress,tokenId,0);
    }

    
    function handleOutSaleAuction(address nftAddress,uint256 tokenId,uint agree) internal returns(bool){
      
        Auction storage auction = auctions[nftAddress][tokenId];
        require(auction.status == 1);
        
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
            auction.bidFrom = "";
        }
        else if(agree == 1 && auction.bidAddress != address(0)){
            
            //转移nft以及根据手续费分发
            ERC721Interface(auction.nftAddress).transferFrom(msg.sender,auction.bidAddress,auction.tokenId);

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
            auction.bidFrom = "";
        }

        return true;
    }
    
    function sold (address nftAddress,uint256 tokenId) public payable onlyOwner returns (bool) {
        return _sold(nftAddress,tokenId);
    }

    function _sold (address nftAddress,uint256 tokenId) internal returns (bool) {
        Auction storage auction = auctions[nftAddress][tokenId];
        
        //退回
        if(auction.bidAddress == address(0)){
            //退回nft
            ERC721Interface(auction.nftAddress).transferFrom(address(this),auction.holder,auction.tokenId);
            emit AuctionOverdue(auction.nftAddress,auction.tokenId);
        }else{
            //转移nft以及根据手续费分发
            ERC721Interface(auction.nftAddress).transferFrom(address(this),auction.bidAddress,auction.tokenId);

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
            emit AuctionSold(auction.nftAddress,auction.tokenId);
        }

        //改变拍卖状态
        auction.status = 1;
        auction.dealPrice = auction.bidValue;
        auction.bidValue = 0;
        auction.bidAddress = address(0);
        auction.bidFrom = "";
        auction.expireDate = 0;
        auction.startPrice = 0;
        auction.miniIncreasePrice = 0;
        auction.maxPrice = 0;

        return true;
    }
}