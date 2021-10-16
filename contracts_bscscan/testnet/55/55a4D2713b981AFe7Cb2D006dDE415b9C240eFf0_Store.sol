// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";


contract Store is ERC721{
    
    struct StoreData{
        string Name;
        string Category;
        string Description;
        address Owner;
        uint256 CreatedOn;
        uint256 NumberOfBuyers;
    }
    
    struct ProductData{
        bool StillBuyable;
        string NameOfProduct;
        string ImageUrl;
        string Description;
        uint256 Price;
        uint256 CreatedOn;
        uint256 ShopID;
    }
    
    mapping(address => address) NFTAddress;
    mapping(address => uint256) AmountGained;
    mapping(address => uint256) AmountToPayBack;
    mapping(uint256 => string[]) BuyersList;
    mapping(address => uint256[]) Cart;
    mapping(address => uint256) StoreIdStructure;
    mapping(uint256 => StoreData) Stores;
    mapping(uint256 => ProductData) Products;
    mapping(address => bool) AlreadyHasStore;
    mapping(address => uint256) StoreIdOfUser;
    mapping(uint256 => bool) AlreadyAProduct;
    uint256[] AllStores; 
    uint256[] AllProducts;
    
    constructor() ERC721("SHOP","SHP"){
        
    }
    
    
    receive() external payable{
        
    }
    
    function CreateStore(string memory Name,  string memory Category, string memory Description) public returns(bool) {
        require(!AlreadyHasStore[msg.sender],"You Already Have a store");
        uint256 storeid = AllStores.length + 1;
        Stores[storeid].Name = Name;
        Stores[storeid].Category = Category;
        Stores[storeid].Description = Description;
        Stores[storeid].Owner = msg.sender;
        Stores[storeid].CreatedOn = block.timestamp;
        AllStores.push(1);
        StoreIdStructure[msg.sender] = storeid;
        AlreadyHasStore[msg.sender] = true;
        StoreIdOfUser[msg.sender] = storeid;
        _safeMint(msg.sender,storeid);
         
        return(true);
        
    }
    
    function StoreGasSaver(string memory Name, string memory ImageUrl, string memory Description,uint256 Price,uint256 ShopID) internal view returns(ProductData memory){
        ProductData memory Info;
        Info.NameOfProduct = Name;
        Info.ImageUrl = ImageUrl;
        Info.Description = Description;
        Info.Price = Price;
        Info.CreatedOn = block.timestamp;
        Info.ShopID = ShopID;
        return(Info);
        
        
    }
    
    
    
    function AddProduct(string memory Name, string memory ImageUrl, string memory Description,uint256 Price) public returns(bool){
        require(Price > 0,"Too low");
        require(AlreadyHasStore[msg.sender],"No store found");
        uint256 storeidofuser = StoreIdStructure[msg.sender];
        ProductData memory ProductInfo = StoreGasSaver(Name,ImageUrl,Description,Price,storeidofuser);
        uint256 productIfOf = AllProducts.length + 1;
        Products[productIfOf] = ProductInfo;
        AllProducts.push(1);
        Products[productIfOf].StillBuyable = true;
        return(true);
        
    }
    
    function UpdatePriceOfProuduct(uint256 ProductId,uint256 NewPrice) public returns(bool){
        uint256 StoreId = Products[ProductId].ShopID;
        address OwnerOfShop = Stores[StoreId].Owner;
        require(msg.sender == OwnerOfShop,"Not the seller of product");
        Products[ProductId].Price = NewPrice;
        return(true);
        
    }
    
    function ChangeBuyableSettings(uint256 ProductId,bool BuyableOrNot) public returns(bool){
        uint256 StoreId = Products[ProductId].ShopID;
        address OwnerOfShop = Stores[StoreId].Owner;
        require(msg.sender == OwnerOfShop,"Not the seller of product");
        Products[ProductId].StillBuyable = BuyableOrNot;
        return(true);
    }
    
    function TakeRecievedMoney() public {
        uint256 AmountToPay = AmountGained[msg.sender];
        require(AmountToPay > 0,"Not Revinue Found");
        AmountGained[msg.sender] = 0;
        payable(msg.sender).transfer(AmountToPay);
    }
    
    function ViewBuyersList(uint256 ProductId) public view returns(string[] memory){
        address owner = Stores[Products[ProductId].ShopID].Owner;
        require(owner == msg.sender,"Not the owner");
        return(BuyersList[ProductId]);
    }
    
    function transferOwnershipOf(address From,address To) internal {
        uint256 ShopID = StoreIdOfUser[From];
        require(!AlreadyHasStore[To],"Reciever already has a store");
        require(ShopID != 0,"Error While Transfering Nft : No Nft Found");
        Stores[ShopID].Owner = To;
        StoreIdOfUser[From] = 0;
        AlreadyHasStore[From] = false;
        uint256 Total = AmountGained[From];
        AmountGained[From] = 0;
        AmountGained[To] = Total;
        AlreadyHasStore[To] = true;
        
    }
    
    function _transfer(address from,address to, uint256 tokenid) internal override{
        transferOwnershipOf(from,to);
        super._transfer(from,to,tokenid);
    }
    
    // Buyer functions
    
    function BuyProduct(uint256 ProductId, string memory YourHomeAddress) public payable returns(bool){
        uint256 Storeid = Products[ProductId].ShopID;
        uint256 Price = Products[ProductId].Price;
        require(Price > 0,"No Product Found");
        require(Products[ProductId].StillBuyable,"Product Not Buyable");
        address OwnerOfShop = Stores[Storeid].Owner;
        AmountGained[OwnerOfShop] += Price;
        require(msg.value >= Price,"Amount recived is lower than product price");
        if(msg.value > Price){
        AmountToPayBack[msg.sender] = msg.value - Price;
        }
        BuyersList[ProductId].push(YourHomeAddress);
        Cart[msg.sender].push(ProductId);
        return(true);
    }
    
    function WithDrawExtraDepositedMoney() public {
        
        uint256 AmountToPay = AmountToPayBack[msg.sender];
        AmountToPayBack[msg.sender] = 0;
        payable(msg.sender).transfer(AmountToPay);
        
    }
    function ViewCart(address account) public view returns(uint256[] memory){
        return(Cart[account]);
    }
    
    function ViewProduct(uint256 ProductId) public view returns(ProductData memory){
        return(Products[ProductId]);
    }
    
    function ViewStore(uint256 StoreId) public view returns(StoreData memory){
        return(Stores[StoreId]);
    }
    
    function ViewStoreOf(address account) public view returns(uint256){
        return(StoreIdOfUser[account]);
    }
    
    
    
    
}