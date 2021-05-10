pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./MultiManager.sol";


contract NftShop is ERC721URIStorage, Multimanager{
    ////////////////////////////////////////
    // NFT VARIABLES //  
    using SafeMath for uint256;  
    using Counters for Counters.Counter;
    Counters.Counter private infoProductID;
    Counters.Counter public _tokenIds; 
    int private _percentPlatformX1000; 
    address private _addressA;
    address private _addressB;
    
    mapping(uint256 => InfoProduct) public infoProduct;
    InfoProduct[] public infoProductArray;
    mapping(address => bool) private editor;
    mapping(address => bool) private buyer; 
    
    mapping(address => uint256) private sellersBalancesRedeem; 
    mapping(address => BuyedNft[]) private nftBuyed;


    ///////////////////////////////////////// -
    // EVENTS //
    event AddNewOpera(
        address indexed sellerAddress, 
        uint256 price, 
        string title, 
        string tokenUri, 
        uint256 newInfoProductID
    );
    
    event ChangePrice(
        address indexed sellerAddress, 
        uint256 newPrice, 
        uint256 ProductID,
        string title,
        string tokenUri
    );
    
    event RemoveOpera(
        address indexed sellerAddress, 
        uint256 ProductID,
        string title,
        string tokenUri
    );

    event OperaBuyed(
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 amount,
        string tokenUri
    );
    
    ///////////////////////////////////////// -
    // STRUCTS //
    struct InfoProduct {
        uint256 infoProductID;
        address sellerAddress;
        uint256 priceProduct;
        string description;
        string tokenUri;
        bool isSelled;
    }

    struct BuyedNft {
        uint256 ProductID;
        string tokenUri;
    }
    
    
    //////////////////////////////////////// -                              
    // CONSTRUCTOR //  
    constructor(int percentPlatformX1000, address addressA, address addressB) ERC721("Ricevo e Spedisco", "RES") {   // Token Address TEST MyToken: 0x2553f6e3a3bc41546ab3dc87c2dcd619bc90c76a
        _percentPlatformX1000 = percentPlatformX1000;
        _addressB = addressB;
        _addressA = addressA;
        
    }


    //////////////////////////////////////// -
    // ADD NEW EDITOR OR BUYER //
    function addEditor(address newEditorAddress) public onlyManager{ // Funzione per aggiungere editors
        require(!editor[newEditorAddress], "Editor Present"); 
        
        editor[newEditorAddress] = true;
    }
    
    
    function addBuyer(address newBuyerAddress) public onlyManager{ // Funzione per aggiungere buyers
        require(!buyer[newBuyerAddress], "Buyer Present"); 
        
        buyer[newBuyerAddress] = true;
    }
    
    
    //////////////////////////////////////// -
    // CHECK FUNCTIONS //
    function isBuyer(address BuyerAddress) public view returns(bool){ 
        
        return buyer[BuyerAddress];
    }
    
     function isEditor(address EditorAddress) public view returns(bool){ 
        
        return editor[EditorAddress];
    }
    

    //////////////////////////////////////// 
    // ADD NEW NFT //
    function addNFT(address owner, string memory tokenURI)
        public onlyManager
        returns (uint256, address)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(owner, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return (newItemId, owner);
    }


    ////////////////////////////////////////
    // BUY NFT //
    
    // BUY NFT NEW SYSTEM //
    function buyNftFromBuyer(uint256 _infoProductId) public payable{
        ////////////////////////////////////////
        // CHECK //
        require((!infoProduct[_infoProductId].isSelled), "This Product is Just Selled!");
        require((infoProduct[_infoProductId].infoProductID != 0) , "Product not present"); 
        require(buyer[msg.sender], "User not BUYER"); 
        
        ////////////////////////////////////////
        // PRODUCT INFO //
        uint256 _perfectAmount = infoProduct[_infoProductId].priceProduct; // prezzo preso dalla variabile
        address _ownerNft = infoProduct[_infoProductId].sellerAddress; // indirizzo titolare del bene da vendere
        string memory _tokenUri = infoProduct[_infoProductId].tokenUri; // token
        
        ////////////////////////////////////////
        // CHECK PAYMENT //
        require((msg.value >= _perfectAmount ), 'Payment not correct'); //Payment in ETH 
        if(msg.value < _perfectAmount){ // change check
            revert();
        }
        address from = msg.sender;
        uint256 paymentReceved = msg.value;
        
        ////////////////////////////////////////
        // SIGN PRODUTC IS SELLED //
        infoProduct[_infoProductId].isSelled = true; // modifico se il pezzo è stato venduto
        
        for(uint i = 0; i < infoProductArray.length; i++) // mod selled at array
        {
            if(infoProductArray[i].infoProductID == _infoProductId)
            {
                infoProductArray[i].isSelled = true;
                return;
            }
        }
        
        ////////////////////////////////////////
        // SETTING MAPPING PAYMENTS //
        uint256 payment = paymentReceved / uint256(100000) * (uint256(100000)  - uint256(_percentPlatformX1000));
        uint256 paymentA = (paymentReceved / uint256(100000) * uint256(_percentPlatformX1000))/2;
        uint256 paymentB = paymentReceved - payment - paymentA;
        
        sellersBalancesRedeem[_ownerNft] += payment;
        sellersBalancesRedeem[_addressA] += paymentA;
        sellersBalancesRedeem[_addressB] += paymentB;
        
        ////////////////////////////////////////
        // SETTING MAPPING NFT //
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        
        BuyedNft memory nBuy;
        nBuy.ProductID = newItemId;
        nBuy.tokenUri = _tokenUri;
        nftBuyed[from].push(nBuy);
        
        emit OperaBuyed(
            newItemId,
            _ownerNft,
            from,
            paymentReceved,
            _tokenUri
        );
        
    }
    
    
    // function buynftOLDSYSTEM(uint256 _infoProductId) public payable {
    //     // Attenzione mettere il controllo di balance ETH. Se non ci sono ETH la transazione NON deve avvenire
        
    //     require((!infoProduct[_infoProductId].isSelled), "This Product is Just Selled!");
    //     require((infoProduct[_infoProductId].infoProductID != 0) , "Product not present"); 
        
        
    //     ////////////////////////////////////////
    //     // PRODUCT INFO //
    //     uint256 _perfectAmount = infoProduct[_infoProductId].priceProduct; // prezzo preso dalla variabile
    //     address payable _ownerNft = payable(infoProduct[_infoProductId].sellerAddress); // indirizzo titolare del bene da vendere
    //     string memory _tokenUri = infoProduct[_infoProductId].tokenUri; // token


    //     ////////////////////////////////////////
    //     // CHECK PAYMENT //
    //     require((msg.value >= _perfectAmount ), 'Payment not correct'); //Payment in ETH 
    //     if(msg.value < _perfectAmount){ // change check
    //         revert();
    //     }
    //     address from = msg.sender;
    //     uint256 paymentReceved = msg.value;
                
         
    //     ////////////////////////////////////////
    //     // SIGN PRODUTC IS SELLED //
    //     infoProduct[_infoProductId].isSelled = true; // modifico se il pezzo è stato venduto
        
    //     for(uint i = 0; i < infoProductArray.length; i++) // mod selled at array
    //     {
    //         if(infoProductArray[i].infoProductID == _infoProductId)
    //         {
    //             infoProductArray[i].isSelled = true;
    //             return;
    //         }
    //     }


    //     ////////////////////////////////////////
    //     // PAY PRODUCT AT SELLER IN ETH//
    //     uint256 payment = paymentReceved / uint256(100000) * (uint256(100000)  - uint256(_percentPlatformX1000));
    //     _ownerNft.transfer(payment);
        
        
    //     ////////////////////////////////////////
    //     // PAY NFT //
    //     _tokenIds.increment();

    //     uint256 newItemId = _tokenIds.current();
    //     _mint(from, newItemId);
    //     _setTokenURI(newItemId, _tokenUri);
    // }


    ////////////////////////////////////////
    // PAY ETH FROM CONTRACT BY MANAGER //
    function paymentManager(address receverPayment, uint256 amount) public onlyManager returns(bool){
        uint256 balance = address(this).balance;
        if(balance<amount){
            return false;
        }
        require(balance>amount, "Amount is over the contract balance");
        address payable recever = payable(receverPayment);
        recever.transfer(amount);
        return true;
    }


    ////////////////////////////////////////
    // ADD GAS //    
    function addGas() public payable {
         require((msg.value >= .1 ether ), 'Payment not correct'); //Payment in ETH
    }


    //////////////////////////////////////// -
    // ADD NEW PRODUCT IN SALE //
    function addNewOpera(uint256 price, address sellerAddress, string memory title, string memory tokenUri ) public {
        
        require(editor[msg.sender], "User not EDITOR"); 
        //require(sellerAddress == msg.sender, "Uer not same seller"); // rimosso per esigenze di piattaforma
        
        infoProductID.increment();

        uint256 newInfoProductID = infoProductID.current();

        InfoProduct memory newProduct;
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


    //////////////////////////////////////// -
    // MODIFY PRODUCT IN SALE //
    function modifyOperaPrice(uint256 operaId, uint256 newprice) public { 
        require(editor[msg.sender], "User is not Editor");
        // require(infoProduct[operaId].sellerAddress == msg.sender, "User is not Owner"); // rimosso per esigenze di piattaforma
        
        require(infoProduct[operaId].infoProductID != 0 , "Product not present"); 
        require(infoProduct[operaId].isSelled, "Product is Selled, is not possible change price");
        
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
 
    // function modifyOperaOwnerAddress(uint256 operaId, address newownerNft) public onlyManager{ 
    //     require(infoProduct[operaId].infoProductID != 0 , "Product not present"); 
    //     infoProduct[operaId].sellerAddress = newownerNft; // mod price on mapping
        
    //     for(uint i = 0; i < infoProductArray.length; i++) // mod price on array view
    //     {
    //         if(infoProductArray[i].infoProductID == operaId)
    //         {
    //             infoProductArray[i].sellerAddress = newownerNft;
    //             return;
    //         }
    //     }
    // }

    // function modifyOperaDescription(uint256 operaId, string memory description) public onlyManager{ 
    //     require(infoProduct[operaId].infoProductID != 0 , "Product not present"); 
    //     infoProduct[operaId].description = description; // mod price on mapping
        
    //     for(uint i = 0; i < infoProductArray.length; i++) // mod price on array view
    //     {
    //         if(infoProductArray[i].infoProductID == operaId)
    //         {
    //             infoProductArray[i].description = description;
    //             return;
    //         }
    //     }
    // }

    // function modifyOperaTokenUri(uint256 operaId, string memory tokenUri) public onlyManager{ 
    //     require(infoProduct[operaId].infoProductID != 0 , "Product not present"); 
    //     infoProduct[operaId].tokenUri = tokenUri; // mod price on mapping
        
    //     for(uint i = 0; i < infoProductArray.length; i++) // mod price on array view
    //     {
    //         if(infoProductArray[i].infoProductID == operaId)
    //         {
    //             infoProductArray[i].tokenUri = tokenUri;
    //             return;
    //         }
    //     }
    // }

    // function modifyOperaIsSelled(uint256 operaId, bool isSelled) public onlyManager{ 
    //     require(infoProduct[operaId].infoProductID != 0 , "Product not present"); 
    //     infoProduct[operaId].isSelled = isSelled; // mod price on mapping
        
    //     for(uint i = 0; i < infoProductArray.length; i++) // mod price on array view
    //     {
    //         if(infoProductArray[i].infoProductID == operaId)
    //         {
    //             infoProductArray[i].isSelled = isSelled;
    //             return;
    //         }
    //     }
    // }
    

    // function modifyOperaAll(uint256 operaId, uint256 newprice, address newownerNft, string memory description, bool isSelled) public onlyManager{ 
    //     require(infoProduct[operaId].infoProductID != 0 , "Product not present"); 
    //     infoProduct[operaId].description = description; // mod mapping
    //     infoProduct[operaId].sellerAddress = newownerNft;
    //     infoProduct[operaId].priceProduct = newprice;
    //     infoProduct[operaId].isSelled = isSelled;

    //     for(uint i = 0; i < infoProductArray.length; i++) // mod price on array view
    //     {
    //         if(infoProductArray[i].infoProductID == operaId)
    //         {
    //             infoProductArray[i].description = description;
    //             infoProductArray[i].sellerAddress = newownerNft;
    //             infoProductArray[i].priceProduct = newprice;
    //             infoProductArray[i].isSelled = isSelled;
    //             return;
    //         }
    //     }
    // }


    //////////////////////////////////////// - 
    // REMOVE PRODUCT IN SALE //
    function removeOpera(uint256 operaId ) public {
        require(editor[msg.sender], "User is not Editor");
        // require(infoProduct[operaId].sellerAddress == msg.sender, "User is not Owner"); // rimosso per esigenze di piattaforma
       
        require(infoProduct[operaId].infoProductID != 0 , "Product not present"); 

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



    ////////////////////////////////////////
    // GET OPERAS LIST //
    function getListProducts() public view returns (InfoProduct[] memory){
        return infoProductArray;
    }
}