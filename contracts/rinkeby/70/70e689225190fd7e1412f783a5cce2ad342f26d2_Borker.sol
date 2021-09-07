/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

pragma solidity ^0.5.0;

// import "./erc1155mint.sol";


contract IERC1155  {
   
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

   
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

   
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

   
    function setApprovalForAll(address _operator, bool _approved) external;

   
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 contract ERC1155MixedFungibleMintable  {
    
    function isNonFungible(uint256 _id) public pure returns(bool) ;
    
    function isFungible(uint256 _id) public pure returns(bool) ;
    function ownerOf(uint256 _id) public view returns (address) ;
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
    function royality (uint256 nft_id) public view returns(uint256 _royalities);
    function _creators(uint256 nft_id) public view returns(address payable);
    // function isApprovedForAll(address owner, address operator) public view returns (bool);
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

 contract Borker  {
//   ERC1155MixedFungibleMintable ercmixed1155;
    IERC1155 ierc1155 ;
    
     event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount

    );
    struct auction {
        address payable tokenOwner;
        uint256 buyPrice;
        bool erc20TokenPayment ;
        uint256 auctionType;
        address currentBidder;
        uint256 currentBid ;
        uint256 startprice ;
    }
    
    address owner;
    uint256 brokerage = 700 ;
    mapping(address => uint256) public brokerageBalance ;
    mapping(uint256 => auction) public auctions;

    mapping(uint256 => bool) public NFTforSale ;
    
    uint256[] erc20TokenPaymentArray;
    
    constructor() public{
      owner=msg.sender;  
    }
    
    modifier Owner() {
        require(owner == msg.sender,"onlyOwner can call this function");
        _;
    }
    
    function addERC20TokenPayment(uint256 f_id) public Owner {
        erc20TokenPaymentArray.push(f_id);
    }
    
    

    function putOnSell(address ercmixed1155mint ,  uint256 _buyPrice , uint256 nfttokenID,bool accpeterc20Token,uint256 _auctionType,uint256 startprice) public {
        
        ERC1155MixedFungibleMintable ercmixed1155 = ERC1155MixedFungibleMintable(ercmixed1155mint);
        
        if (ercmixed1155.ownerOf(nfttokenID)== msg.sender){
        require( ercmixed1155.isApprovedForAll(ercmixed1155.ownerOf(nfttokenID),address(this)),"not approved");
        require(ercmixed1155.isNonFungible(nfttokenID),"Token is not NFT");
        require(NFTforSale[nfttokenID] == false," Token alreay on sale ");
        // address payable lastOwner2 =ercmixed1155.ownerOf(nfttokenID);
        auction memory newAuction = auction(msg.sender,_buyPrice,accpeterc20Token ,_auctionType,address(0),0,startprice);
        auctions[nfttokenID] = newAuction;
        NFTforSale[nfttokenID] = true;
       
        }
        else {
            revert("the sender is not token owner");
        }
        emit OnSale(
        ercmixed1155mint,
        nfttokenID,
        ercmixed1155.ownerOf(nfttokenID),
       _auctionType,
       _buyPrice
    
    );
        
    }
    
     function buyNFT(address ercmixed1155mint ,uint256 nfttokenID, uint256 _ftID) payable public{
        ERC1155MixedFungibleMintable ercmixed1155 = ERC1155MixedFungibleMintable(ercmixed1155mint);
        auction memory _auction = auctions[nfttokenID];
         
         if(NFTforSale[nfttokenID]== true) {
            // require( ercmixed1155.isFungible(_ftID)==true,"this erc20 toekn not avialble ");
            require(_auction.auctionType == 1,"NFT only for bid");
            //  require(ercmixed1155.balanceOf(msg.sender,_ftID) >= _auction.buyPrice,"not enough amount");
            uint256 royality = (ercmixed1155.royality(nfttokenID) * _auction.buyPrice) / 10000;
            uint256 brokerageAmount = (brokerage * _auction.buyPrice) / 10000;
            uint256 sellerfunds =  _auction.currentBid - royality - brokerageAmount;
            
            for (uint256 i = 0; i < erc20TokenPaymentArray.length; i++) {
            if (_auction.erc20TokenPayment == true) {
            require(erc20TokenPaymentArray[i] == _ftID,"token Id not match");
            require(ercmixed1155.isApprovedForAll(msg.sender,address(this)));
             
            //  transferNFT
        
        
            require(ercmixed1155.balanceOf(msg.sender,_ftID)>=_auction.buyPrice,"not enough amount");
            
            
            ercmixed1155.safeTransferFrom(msg.sender,_auction.tokenOwner,_ftID,sellerfunds,"");
            ercmixed1155.safeTransferFrom(msg.sender,ercmixed1155._creators(nfttokenID),_ftID,royality,"");
            ercmixed1155.safeTransferFrom(msg.sender,address(this),_ftID,brokerageAmount,"");

            ercmixed1155.safeTransferFrom(_auction.tokenOwner,msg.sender,nfttokenID,0,"");
            
            }
            else
            {
                require(msg.value >= _auction.buyPrice,"not enough amount");
                if (_auction.erc20TokenPayment == false)
                {
                    brokerageBalance[address(0)] += brokerageAmount;
                }
                else
                {
                    brokerageBalance[ercmixed1155mint] += brokerageAmount;
                }
                _auction.tokenOwner.transfer(sellerfunds);
                ercmixed1155._creators(nfttokenID).transfer(royality);
                ercmixed1155.safeTransferFrom(_auction.tokenOwner,msg.sender,nfttokenID,0,"");
            }
            
             }
         }
         else{
             revert("this nft npot for sale");
         }
    }
    
    


    function bid(address ercmixed1155mint ,uint256 nfttokenID, uint256 amount,uint256 _fid)public {
        ERC1155MixedFungibleMintable ercmixed1155 = ERC1155MixedFungibleMintable(ercmixed1155mint);
        auction memory _auction = auctions[nfttokenID];
        if (_auction.auctionType == 2){
            require( NFTforSale[nfttokenID]== true," nft not for sale ");
            require(ierc1155.isApprovedForAll(msg.sender,address(this))==true,"borker not approved for spending erc20Token");
            require(amount > _auction.startprice,"not enough amount");
            
            ercmixed1155.safeTransferFrom(msg.sender,_auction.currentBidder,_fid,_auction.currentBid,"");
            _auction.currentBidder = msg.sender;
            _auction.currentBid == amount;
    
        }
    }
        


}