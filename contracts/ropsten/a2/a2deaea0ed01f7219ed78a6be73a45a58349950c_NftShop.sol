// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./MultiManager.sol";
import "./IMarket.sol";
import "./LibMarket.sol";

contract NftShop is INftShop, ERC721URIStorage, Multimanager{
    using SafeMath for uint256;  
    using Counters for Counters.Counter;
    
    int private _percentPlatformX1000;
    address private _addressA;
    address private _addressB;
    
    mapping(uint256 => LibMarket.InfoProduct) private infoProduct;
    LibMarket.InfoProduct[] public infoProductArray;
    mapping(address => bool) private editor;
    mapping(address => bool) private buyer; 
    
    mapping(address => uint256) private sellersBalancesRedeem;
    mapping(address => LibMarket.BuyedNft[]) private nftBuyed;

    Counters.Counter private infoProductID;
    Counters.Counter private _tokenIds; 
    
    // CONSTRUCTOR //
    constructor(int percentPlatformX1000, address addressA, address addressB) ERC721("InArtNft", "INART"){ 
        _percentPlatformX1000 = percentPlatformX1000;
        _addressB = addressB;
        _addressA = addressA;
        addEditor(msg.sender);
    }

    
    // ADD NEW EDITOR OR BUYER //
    function addEditor(address newEditorAddress) public onlyManager{ 
        require(!editor[newEditorAddress], "EP"); 
        editor[newEditorAddress] = true;
    }
    
    function addBuyer(address newBuyerAddress) public{
        require(!buyer[newBuyerAddress], "BP"); 
        
        buyer[newBuyerAddress] = true;
    }
    
    // CHECK FUNCTIONS //
    function isBuyerEditor(address AddressBuyEdit) public view returns(bool,bool){ 
        
        return (buyer[AddressBuyEdit],editor[AddressBuyEdit]);
    }
    
    function redeemNft(uint256 _infoProductId) public{
        require(nftBuyed[msg.sender].length != 0, "not has ft");
        bool isPresent = false;
        for(uint i = 0; i < nftBuyed[msg.sender].length; i++)
        {
            if(nftBuyed[msg.sender][i].ProductID == _infoProductId)
            {
                _tokenIds.increment();

                uint256 newItemId = _tokenIds.current();
                _mint(msg.sender, newItemId);
                _setTokenURI(newItemId, nftBuyed[msg.sender][i].tokenUri);
                delete nftBuyed[msg.sender][i];
                emit redeemNftEvent(newItemId, _infoProductId, msg.sender);
                
                return;
            }
        }
       require(isPresent, "not has nft");
    }

    // CHECK BUYED NFT //
    function checkOwnerNft(address sender) public view returns(LibMarket.BuyedNft[] memory)
    {
        return nftBuyed[sender];
    }
    
    
    // CHECK BALANCES FOR REDEEM //
    function checkBalances(address sender) public view returns(uint256)
    {
        return sellersBalancesRedeem[sender];
    }
    
    // BUY NFT NEW SYSTEM //
    function buyNft(uint256 _infoProductId) public payable {
        ////////////////////////////////////////
        // CHECK //
        require((!infoProduct[_infoProductId].isSelled), "Just Selled!");
        require((infoProduct[_infoProductId].infoProductID != 0) , "not present"); 
        require(buyer[msg.sender], "not BUYER"); 
        
        ////////////////////////////////////////
        // PRODUCT INFO //
        uint256 _perfectAmount = infoProduct[_infoProductId].priceProduct; // prezzo preso dalla variabile
        address _ownerNft = infoProduct[_infoProductId].sellerAddress; // indirizzo titolare del bene da vendere
        string memory _tokenUri = infoProduct[_infoProductId].tokenUri; // token
        
        ////////////////////////////////////////
        // CHECK PAYMENT //
        require((msg.value >= _perfectAmount ), 'not correct'); //Payment in ETH 
        if(msg.value < _perfectAmount){ // change check
            revert();
        }
        address from = msg.sender;
        uint256 paymentReceved = msg.value;
        
        ////////////////////////////////////////
        // SIGN PRODUTC IS SELLED //
        infoProduct[_infoProductId].isSelled = true;
        
        for(uint i = 0; i < infoProductArray.length; i++) // mod selled at array
        {
            if(infoProductArray[i].infoProductID == _infoProductId)
            {
                infoProductArray[i].isSelled = true;
                continue;
            }
        }
        
        ////////////////////////////////////////
        // SETTING MAPPING PAYMENTS //
        uint256 rate = uint256(100000 - _percentPlatformX1000);
        uint256 payment = paymentReceved * rate / uint256(100000);
        uint256 paymentA = (paymentReceved - payment)/2;
        uint256 paymentB = paymentReceved - payment - paymentA;
        

        sellersBalancesRedeem[_ownerNft] += payment;
        sellersBalancesRedeem[_addressA] += paymentA;
        sellersBalancesRedeem[_addressB] += paymentB;
                
        LibMarket.BuyedNft memory nBuy;
        nBuy.ProductID = _infoProductId;
        nBuy.tokenUri = _tokenUri;
        nftBuyed[from].push(nBuy);
        
        emit OperaBuyed(
            _infoProductId,
            _ownerNft,
            from,
            paymentReceved,
            _tokenUri
        );
    }

    // PAY ETH FROM CONTRACT TO OWNER //
    function paymentRedeem() public {
        uint256 redeemBalance = sellersBalancesRedeem[msg.sender];
        require(redeemBalance > 0, "AmZ");
        
        uint256 balance = address(this).balance;
        if(balance < redeemBalance) redeemBalance = balance;
        
        sellersBalancesRedeem[msg.sender] = 0; 
        address payable recever = payable(msg.sender);
        recever.transfer(redeemBalance);
    }

    function paymentFromManager(uint256 amount) public onlyManager {
         require(address(this).balance >= amount); 
         payable(msg.sender).transfer(amount);
    }

    // ADD NEW PRODUCT IN SALE //
    function addNewOpera(uint256 price, address sellerAddress, string memory title, string memory tokenUri ) public onlyEditor{
        
        //require(editor[msg.sender], "User not EDITOR"); 
        //require(sellerAddress == msg.sender, "Uer not same seller"); // rimosso per esigenze di piattaforma
        require(LibMarket.isPublished(infoProductArray, price, sellerAddress, tokenUri), "Just Published");
        
        infoProductID.increment();
        uint256 newInfoProductID = infoProductID.current();

        LibMarket.InfoProduct memory newProduct;
        newProduct.infoProductID = newInfoProductID;
        newProduct.description = title;
        newProduct.priceProduct = price;
        newProduct.sellerAddress = sellerAddress;
        newProduct.tokenUri = tokenUri;
        newProduct.isSelled = false;

        infoProduct[newInfoProductID] = newProduct; 
        infoProductArray.push(newProduct);

        emit AddNewOpera( sellerAddress, price, title, tokenUri, newInfoProductID);
    }

    // MODIFY PRODUCT IN SALE //
    function modifyOperaPrice(uint256 operaId, uint256 newprice) public onlyEditor{ 
        //require(editor[msg.sender], "User is not Editor");
        // require(infoProduct[operaId].sellerAddress == msg.sender, "User is not Owner"); // rimosso per esigenze di piattaforma
        
        require(infoProduct[operaId].infoProductID != 0 , "Product not present"); 
        require(!infoProduct[operaId].isSelled, "Product is Selled");
        
        infoProduct[operaId].priceProduct = newprice; // mod price on mapping
        
        for(uint i = 0; i < infoProductArray.length; i++) // mod price on array view
        {
            if(infoProductArray[i].infoProductID == operaId)
            {
                infoProductArray[i].priceProduct = newprice;
                continue;
            }
        }
        
        emit ChangePrice(msg.sender, newprice,operaId, infoProduct[operaId].description, infoProduct[operaId].tokenUri);
    }
 
    // REMOVE PRODUCT IN SALE //
    function removeOpera(uint256 operaId ) public onlyEditor{
        //require(editor[msg.sender], "not Editor");
        // require(infoProduct[operaId].sellerAddress == msg.sender, "User is not Owner"); // rimosso per esigenze di piattaforma
       
        require(infoProduct[operaId].infoProductID != 0 , "Product not present"); 
        require(!infoProduct[operaId].isSelled, "Product is Selled");
        delete infoProduct[operaId]; // lo elimina dalla maps
        
        //remove from array
        for(uint i = 0; i < infoProductArray.length; i++)
        {
            if(infoProductArray[i].infoProductID == operaId)
            {
                delete infoProductArray[i];
                continue;
            }
        }
        emit RemoveOpera(msg.sender, operaId, infoProduct[operaId].description, infoProduct[operaId].tokenUri);
    }
    
    modifier onlyEditor() { 
        require(editor[msg.sender], "this is not manager");
        _;
    }
    // GET OPERAS LIST //
    //function getListProducts() public view returns (LibMarket.InfoProduct[] memory){
        //return infoProductArray;
    //}
}