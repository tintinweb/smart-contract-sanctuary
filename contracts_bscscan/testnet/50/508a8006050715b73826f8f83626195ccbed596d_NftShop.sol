// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./MultiManager.sol";
import "./IMarket.sol";
import "./LibMarket.sol";
import "./ERC20.sol";

contract NftShop is INftShop, ERC721URIStorage, Multimanager{
    using SafeMath for uint256;  
    using Counters for Counters.Counter;
    
    uint256 private _percentPlatformX1000;
    address private _addressAdmin;
    address private _addressDev;
    
    mapping(uint256 => LibMarket.InfoProduct) public infoProduct;
    mapping(address => bool) private editor;
    
    mapping(address => uint256) private sellersBalancesRedeem; //private
    mapping(address => LibMarket.BuyedNft[]) private nftBuyed;
    
    IERC20 private _token; 
    Counters.Counter private infoProductID;
    Counters.Counter private _tokenIds; 
    
    // CONSTRUCTOR //
    constructor(IERC20 tokenPayment,uint256 percentPlatformX1000, address addressAdmin, address addressDev) ERC721("ArtNft", "ART"){ 
        _percentPlatformX1000 = percentPlatformX1000;
        _addressDev = addressDev;
        _addressAdmin = addressAdmin;
        addEditor(msg.sender);
        _token = tokenPayment;
    }
    
    // ADD NEW EDITOR OR BUYER //
    function addEditor(address newEditorAddress) public onlyManager{ 
        require(!editor[newEditorAddress], "Editor present"); 
        editor[newEditorAddress] = true;
        emit AddEditor(newEditorAddress);
    }
    
    function removeEditor(address editorAddress) public onlyManager{ 
        require(editor[editorAddress], "Editor not present"); 
        editor[editorAddress] = false;
        emit RemoveEditor(editorAddress);
    }
    
    // CHECK FUNCTIONS //
    function isBuyerEditor(address AddressBuyEdit) public view returns(bool,bool){ 
        //return (buyer[AddressBuyEdit],editor[AddressBuyEdit]);
        return(true, editor[AddressBuyEdit]);
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
    function buyNft(uint256 _infoProductId) external { // mod payment
        ////////////////////////////////////////
        // CHECK //
        require((!infoProduct[_infoProductId].isSelled), "Just Selled!");
        require((infoProduct[_infoProductId].infoProductID != 0) , "not present"); 
        //require(buyer[msg.sender], "not BUYER"); 
        
        ////////////////////////////////////////
        // PRODUCT INFO //
        uint256 _perfectAmount = infoProduct[_infoProductId].priceProduct; // prezzo preso dalla variabile
        address _ownerNft = infoProduct[_infoProductId].sellerAddress; // indirizzo titolare del bene da vendere
        string memory _tokenUri = infoProduct[_infoProductId].tokenUri; // token
        
        ////////////////////////////////////////
        // CHECK PAYMENT //
        address from = msg.sender;
        _token.allowance(from,  address(this));
        require(_token.transferFrom(from, address(this), _perfectAmount), "Error during staking");
        
        ////////////////////////////////////////
        // SIGN PRODUTC IS SELLED //
        infoProduct[_infoProductId].isSelled = true;
        
        ////////////////////////////////////////
        // SETTING MAPPING PAYMENTS //
        uint256 rate = uint256(100000).sub(_percentPlatformX1000);
        uint256 payment = _perfectAmount.mul(rate).div(uint256(100000));
        uint256 paymentAdmin = (_perfectAmount.sub(payment)).div(2);
        uint256 paymentDev = _perfectAmount.sub(payment).sub(paymentAdmin);
        
        sellersBalancesRedeem[_ownerNft] += payment;
        sellersBalancesRedeem[_addressAdmin] += paymentAdmin;
        sellersBalancesRedeem[_addressDev] += paymentDev;
                
        LibMarket.BuyedNft memory nBuy;
        nBuy.ProductID = _infoProductId;
        nBuy.tokenUri = _tokenUri;
        nftBuyed[from].push(nBuy);
        
        emit OperaBuyed(
            _infoProductId,
            _ownerNft,
            from,
            _perfectAmount,
            _tokenUri
        );
    }
    
    function thisBalance() private view returns (uint256){
        return _token.balanceOf(address(this));
    }

    // PAY TOKEN FROM CONTRACT TO OWNER //
    function paymentRedeem() public {
        uint256 redeemBalance = sellersBalancesRedeem[msg.sender];
        require(redeemBalance > 0);
        
        if(thisBalance() < redeemBalance) redeemBalance = thisBalance();
        
        sellersBalancesRedeem[msg.sender] = 0; 
        _token.transfer(msg.sender, redeemBalance);
    }


    function paymentFromManager(uint256 amount) public onlyManager {
         require(thisBalance() >= amount); 
         _token.transfer(msg.sender, amount);
    }

    // ADD NEW PRODUCT IN SALE //
    function addNewOpera(uint256 price, address sellerAddress, string memory title, string memory tokenUri ) public onlyEditor{
        //require(LibMarket.isPublished(infoProductID, price, sellerAddress, tokenUri), "Just Published");
        
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

        emit AddNewOpera( sellerAddress, price, title, tokenUri, newInfoProductID);
    }

    // MODIFY PRODUCT IN SALE //
    function modifyOperaPrice(uint256 operaId, uint256 newprice) public onlyEditor check(operaId){ 
        infoProduct[operaId].priceProduct = newprice; // mod price on mapping
        
        emit ChangePrice(msg.sender, newprice,operaId, infoProduct[operaId].description, infoProduct[operaId].tokenUri);
    }
 
    // REMOVE PRODUCT IN SALE //
    function removeOpera(uint256 operaId ) public onlyEditor check(operaId){
        delete infoProduct[operaId]; // lo elimina dalla maps
        emit RemoveOpera(msg.sender, operaId, infoProduct[operaId].description, infoProduct[operaId].tokenUri);
    }
    
    function infoProduct_(uint256 _infoProductId)public view returns(LibMarket.InfoProduct memory){
        return infoProduct[_infoProductId];
    }
    
    // CHANGE TOKEN address
    function changeToken(ERC20 tokenPayment)public onlyManager returns(bool){
        _token=tokenPayment;
        return true;
    }
    
    modifier check(uint256 operaId){
        require(infoProduct[operaId].infoProductID != 0 , "Product not present"); 
        require(infoProduct[operaId].sellerAddress == msg.sender, "not seller opera");
        require(!infoProduct[operaId].isSelled, "Product is Selled");
        _;
    }
    
    modifier onlyEditor() { 
        require(editor[msg.sender], "this is not editor");
        _;
    }
}