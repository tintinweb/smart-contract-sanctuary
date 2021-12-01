// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./GenerativeBB.sol";
import "./NonGenerativeBB.sol";

contract BlindBox is NonGenerativeBB {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct Series1 {
        string name;
        string seriesURI;
        string boxName;
        string boxURI;
        uint256 startTime;
        uint256 endTime;
        address collection; 
    }
    struct Series2 {
        uint256 maxBoxes;
        uint256 perBoxNftMint;
        uint256 perBoxPrice;
        address bankAddress;
        uint256 baseCurrency;
        uint256[] allowedCurrencies; 
    }
    /** 
    @dev constructor initializing blindbox
    */
    constructor() payable  {

    }

    /** 
    @dev this function is to start new series of blindbox
    @param isGenerative flag to show either newely started series is of Generative blindbox type or Non-Generative
    @notice only owner of the contract can trigger this function.
    */
    function StartSeries(
        address[] memory addressData, // [collection, bankAddress]
        string[] memory stringsData, // [name, seriesURI, boxName, boxURI]
       uint256[] memory integerData, //[startTime, endTime, maxBoxes, perBoxNftMint, perBoxPrice, baseCurrency]
       uint256[] memory allowedCurrencies,
        bool isGenerative,  address bankAddress, uint256 royalty ) onlyOwner public {
            Series1 memory series = Series1( stringsData[0], stringsData[1], stringsData[2], stringsData[3], integerData[0], integerData[1],addressData[0]);
        if(isGenerative){
            // start generative series
            // generativeSeriesId.increment();
            generativeSeries(addressData[0],  stringsData[0], stringsData[1], stringsData[2], stringsData[3], integerData[0], integerData[1], royalty);
            
            // emit SeriesInputValue(series,generativeSeriesId.current(), isGenerative,  royalty);

        } else {
            nonGenerativeSeriesId.increment();
            // start non-generative series
            nonGenerativeSeries(addressData[0], stringsData[0], stringsData[1], stringsData[2], stringsData[3], integerData[0], integerData[1], royalty);
            emit SeriesInputValue(series,nonGenerativeSeriesId.current(), isGenerative, royalty );
        }
       extraPsrams(integerData, bankAddress, allowedCurrencies, isGenerative);
        
    }
    function extraPsrams(uint256[] memory integerData, //[startTime, endTime, maxBoxes, perBoxNftMint, perBoxPrice, baseCurrency]
         address bankAddress,
        uint256[] memory allowedCurrencies, bool isGenerative) internal {
        if(isGenerative){
      setExtraParamsGen(integerData[5], allowedCurrencies, bankAddress, integerData[4], integerData[2], integerData[3]);  

        } else {
      setExtraParams(integerData[5], allowedCurrencies, bankAddress, integerData[4], integerData[2], integerData[3]);  

        }
        Series2 memory series = Series2(integerData[2], integerData[3], integerData[4], bankAddress, integerData[5], allowedCurrencies );
        emit Series1InputValue(series,nonGenerativeSeriesId.current(), isGenerative );
    }
    // add URIs/attributes in series [handled in respective BBs]

    /** 
    @dev this function is to buy box of any type.
    @param seriesId id of the series of whom box to bought.
    @param isGenerative flag to show either blindbox to be bought is of Generative blindbox type or Non-Generative
    
    */
    function buyBox(uint256 seriesId, bool isGenerative, uint256 currencyType, string memory ownerId) public {
        if(isGenerative){
            // buyGenerativeBox(seriesId, currencyType);
        } else {
            buyNonGenBox(seriesId, currencyType, ownerId);
        }
    }
    function buyBoxPayable(uint256 seriesId, bool isGenerative) payable public {
        if(isGenerative){
            // buyGenBoxPayable(seriesId);
        } else {
            buyNonGenBoxPayable(seriesId);
        }
    }

    /** 
    @dev this function is to open blindbox of any type.
    @param boxId id of the box to be opened.
    @param isGenerative flag to show either blindbox to be opened is of Generative blindbox type or Non-Generative
    
    */
    function openBox(uint256 boxId, bool isGenerative, string memory ownerId) public {
        if(isGenerative){
            openGenBox(boxId);
        } else {
            openNonGenBox(boxId, ownerId);
        }
    }
    fallback() payable external {}
    receive() payable external {}
    event SeriesInputValue(Series1 _series, uint256 seriesId, bool isGenerative, uint256 royalty);
    event Series1InputValue(Series2 _series, uint256 seriesId, bool isGenerative);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IRand {
    function getRandomNumber() external returns (bytes32 requestId);
    function getRandomVal() external view returns (uint256); 

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Proxy/BlindboxStorage.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract Utils is Ownable, BlindboxStorage{
    
    using SafeMath for uint256;
    address internal gasFeeCollector;
    uint256 internal gasFee;
    constructor() {
       

    }
    function init() public {
        MATIC = IERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab); //for eth chain wrapped ethereum 
        USD = IERC20(0x23a91170fA76141Ac09f126e8D56BD9896D1FD5c);
        platform = 0xF0d2D73d09A04036F7587C16518f67cE622129Fd;
        nft = INFT(0x326Cae76A11d85b5c76E9Eb81346eFa5e4ea7593);
        dex = IDEX(0x23c7903A8a61BA72fF239e7856A7D7e3447718B5);
        ALIA = IERC20(0x6275BD7102b14810C7Cfe69507C3916c7885911A);
        ETH = IERC20(0xd93e56Eb481D63b12b364adB8343c4b28623EebF);
        LPAlia=LPInterface(0x27dD65b98DDAcda1fCbdE9A28f7330f3dFAB304F);
        LPWETH=LPInterface(0xd919650860CD93f45c2F23399f841043A299Ce49);
        LPMATIC=LPInterface(0xFbe216d69e6760145D56cc597C559B322A85c397);
       _setOwner(_msgSender());
        
    }
    function calculatePrice(uint256 _price, uint256 base, uint256 currencyType) public view returns(uint256 price) {    
    price = _price; 
    //(uint112 _reserve0, uint112 _reserve1,) =LPBNB.getReserves();  
    (uint112 reserve0, uint112 reserve1,) =LPAlia.getReserves();
    (uint112 reserveWETH0, uint112 reserveWETH1,) =LPWETH.getReserves(); //0x853Ee4b2A13f8a742d64C8F088bE7bA2131f670d 
    (uint112 reserveWMATIC0, uint112 reserveWMATIC1,) =LPMATIC.getReserves(); //0xFbe216d69e6760145D56cc597C559B322A85c397 LPWMATIC
   
    if(currencyType == 0 && base == 1){
        //dollar to alia
        price = SafeMath.div(SafeMath.mul(price,reserve1),SafeMath.mul(reserve0,1000000000000));  
    } else if(currencyType == 1 && base == 0){
        //alia to dollar
        price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(reserve0,1000000000000)),reserve1);
    } else if (currencyType == 0 && base == 2) {
        //weth to alia
        price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(reserveWETH0,1000000000000)),reserveWETH1);
        price = SafeMath.div(SafeMath.mul(price,reserve1),SafeMath.mul(reserve0,1000000000000)); 
    }else if (currencyType == 1 && base == 2) {
        // weth to usdc
      price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(reserveWETH0,1000000000000)),reserveWETH1);    
    } else if (currencyType == 2 && base == 0) {
        //alia to weth
        price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(reserve0,1000000000000)),reserve1);
        price = SafeMath.div(SafeMath.mul(price,reserveWETH1),SafeMath.mul(reserveWETH0,1000000000000));  
    }else if (currencyType ==2 &&  base == 1) { 
        //usdc to weth
      price = SafeMath.div(SafeMath.mul(price,reserveWETH1),SafeMath.mul(reserveWETH0,1000000000000));    
    }   else if (currencyType == 0 && base == 3) {
        //wmatic to alia
        price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(reserveWMATIC1,1000000000000)),reserveWMATIC0);
        price = SafeMath.div(SafeMath.mul(price,reserve1),SafeMath.mul(reserve0,1000000000000));
    } else if (currencyType == 1 && base == 3) {
        // wmatic to usdc
      price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(reserveWMATIC1,1000000000000)),reserveWMATIC0);
    } else if (currencyType == 2 && base == 3) {
        // wmatic to weth
      price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(reserveWMATIC1,1000000000000)),reserveWMATIC0);
      price = SafeMath.div(SafeMath.mul(price,reserveWETH1),SafeMath.mul(reserveWETH0,1000000000000));
    } else if (currencyType == 3 && base == 0) {
        //alia to wmatic
        price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(reserve0,1000000000000)),reserve1);
        price = SafeMath.div(SafeMath.mul(price,reserveWMATIC0),SafeMath.mul(reserveWMATIC1,1000000000000));
    } else if (currencyType ==3 &&  base == 1) {
        //usdc to wmatic
      price = SafeMath.div(SafeMath.mul(price,reserveWMATIC0),SafeMath.mul(reserveWMATIC1,1000000000000));
    } else if (currencyType ==3 &&  base == 2) {
        //weth to wmatic
      price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(reserveWETH0,1000000000000)),reserveWETH1);
      price = SafeMath.div(SafeMath.mul(price,reserveWMATIC0),SafeMath.mul(reserveWMATIC1,1000000000000));
    }
        
  } 
  
    // function setGaseFeeData(address _address, uint256 gasFeeInUSDT ) onlyOwner public  {
    //    gasFeeCollector = _address;
    //    gasFee = gasFeeInUSDT;
    // }
    function setVRF(address _vrf) onlyOwner public {
        vrf = IRand(_vrf);
        emit VRF(address(vrf));
    }

    function getRand() internal returns(uint256) {

        vrf.getRandomNumber();
        uint256 rndm = vrf.getRandomVal();
        return rndm.mod(100); // taking to limit value within range of 0 - 99
    }
    function blindCreateCollection(string memory name_, string memory symbol_) onlyOwner public {
        dex.createCollection(name_, symbol_);
    }

    function transferOwnerShipCollection(address[] memory collections, address newOwner) onlyOwner public {
       for (uint256 index = 0; index < collections.length; index++) {
            dex.transferCollectionOwnership(collections[index], newOwner);
       }
    }

    // event
    event VRF(address indexed vrf);
    
}

pragma solidity ^0.8.0;


import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../IERC20.sol';
import '../VRF/IRand.sol';
import '../INFT.sol';
import '../IDEX.sol';
import "../LPInterface.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * @title DexStorage
 * @dev Defining dex storage for the proxy contract.
 */
///////////////////////////////////////////////////////////////////////////////////////////////////

contract BlindboxStorage {
 using Counters for Counters.Counter;
    using SafeMath for uint256;

    address a;
    address b;
    address c;

    IRand vrf;
    IERC20 ALIA;
    IERC20 ETH;
    IERC20 USD;
    IERC20 MATIC;
    INFT nft;
    IDEX dex;
    address platform;
    IERC20 internal token;
    
    Counters.Counter internal _boxId;

 Counters.Counter public generativeSeriesId;

    struct Attribute {
        string name;
        string uri;
        uint256 rarity;
    }

    struct GenerativeBox {
        string name;
        string boxURI;
        uint256 series; // to track start end Time
        uint256 countNFTs;
        // uint256[] attributes;
        // uint256 attributesRarity;
        bool isOpened;
    }

    struct GenSeries {
        string name;
        string seriesURI;
        string boxName;
        string boxURI;
        uint256 startTime;
        uint256 endTime;
        uint256 maxBoxes;
        uint256 perBoxNftMint;
        uint256 price; // in ALIA
        Counters.Counter boxId; // to track series's boxId (upto minted so far)
        Counters.Counter attrType; // attribute Type IDs
        Counters.Counter attrId; // attribute's ID
        // attributeType => attributeId => Attribute
        mapping ( uint256 => mapping( uint256 => Attribute)) attributes;
        // attributes combination hash => flag
        mapping ( bytes32 => bool) blackList;
    }

    struct NFT {
        // attrType => attrId
        mapping (uint256 => uint256) attribute;
    }

    // seriesId => Series
    mapping ( uint256 => GenSeries) public genSeries;
   mapping ( uint256 => uint256) public genseriesRoyalty;
    mapping ( uint256 => uint256[]) _allowedCurrenciesGen;
    mapping ( uint256 => address) public bankAddressGen;
    mapping ( uint256 => uint256) public baseCurrencyGen;
    mapping (uint256=>address) public genCollection;
    // boxId => attributeType => attributeId => Attribute
    // mapping( uint256 => mapping ( uint256 => mapping( uint256 => Attribute))) public attributes;
    // boxId => Box
    mapping ( uint256 => GenerativeBox) public boxesGen;
    // attributes combination => flag
    // mapping ( bytes => bool) public blackList;
    // boxId => boxOpener => array of combinations to be minted
    // mapping ( uint256 => mapping ( address => bytes[] )) public nftToMint;
    // boxId => owner
    mapping ( uint256 => address ) public genBoxOwner;
    // boxId => NFT index => attrType => attribute
    mapping (uint256 => mapping( uint256 => mapping (uint256 => uint256))) public nftsToMint;
  

    Counters.Counter public nonGenerativeSeriesId;
    // mapping(address => Counters.Counter) public nonGenerativeSeriesIdByAddress;
    struct URI {
        string name;
        string uri;
        uint256 rarity;
        uint256 copies;
    }

    struct NonGenerativeBox {
        string name;
        string boxURI;
        uint256 series; // to track start end Time
        uint256 countNFTs;
        // uint256[] attributes;
        // uint256 attributesRarity;
        bool isOpened;

    }

    struct NonGenSeries {
        address collection;
        string name;
        string seriesURI;
        string boxName;
        string boxURI;
        uint256 startTime;
        uint256 endTime;
        uint256 maxBoxes;
        uint256 perBoxNftMint;
        uint256 price; 
        Counters.Counter boxId; // to track series's boxId (upto minted so far)
        Counters.Counter attrId; 
        // uriId => URI 
        mapping ( uint256 => URI) uris;
    }

    struct IDs {
        Counters.Counter attrType;
        Counters.Counter attrId;
    }

    struct CopiesData{
        
        uint256 total;
        mapping(uint256 => uint256) nftCopies;
    }
    mapping (uint256 => CopiesData) public _CopiesData;
    
    // seriesId => NonGenSeries
    mapping ( uint256 => NonGenSeries) public nonGenSeries;

   mapping ( uint256 => uint256[]) _allowedCurrencies;
   mapping ( uint256 => address) public bankAddress;
   mapping ( uint256 => uint256) public nonGenseriesRoyalty;
   mapping ( uint256 => uint256) public baseCurrency;
    // boxId => IDs
    // mapping (uint256 => IDs) boxIds;
    // boxId => attributeType => attributeId => Attribute
    // mapping( uint256 => mapping ( uint256 => mapping( uint256 => Attribute))) public attributes;
    // boxId => Box
    mapping ( uint256 => NonGenerativeBox) public boxesNonGen;
    // attributes combination => flag
    // mapping ( bytes => bool) public blackList;
    // boxId => boxOpener => array of combinations to be minted
    // mapping ( uint256 => mapping ( address => bytes[] )) public nftToMint;
    // boxId => owner
    struct ownerData {
        address ownerAddress;
        string id;
    }
    mapping ( uint256 => ownerData ) public nonGenBoxOwner;
    // boxId => NFT index => attrType => attribute
    // mapping (uint256 => mapping( uint256 => mapping (uint256 => uint256))) public nfts;
    mapping(address => mapping(bool => uint256[])) seriesIdsByCollection;
    uint256 deployTime;
    LPInterface LPAlia;
    LPInterface LPWETH;
    LPInterface LPMATIC;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './GenerativeBB.sol';

contract NonGenerativeBB is GenerativeBB {

   using Counters for Counters.Counter;
    using SafeMath for uint256;

    constructor() public {

    }

/** 
    @dev function to add URIs in given series
        @param seriesId - id of the series in whom URIs to be added
        @param name - array of URI names to be added/updated
        @param uri - array of URIs to be added/updated
        @param rarity - array of URI rarity to be added/updated
    @notice
        1. all arrays should be of same length & sequence
        2. only owner of the smartcontract can add/update URIs
        3. you can not update one URI, should provide all to ensure data integrity & rarities
    */
    function setURIs(uint256 seriesId, string[] memory name, string[] memory uri, uint256[] memory rarity, uint256 copies) onlyOwner public {
        // uint256 totalRarity = 0;
        require(abi.encode(nonGenSeries[seriesId].name).length != 0,"Non-GenerativeSeries doesn't exist");
        require(name.length == uri.length && name.length == rarity.length, "URIs length mismatched");
        Counters.Counter storage _attrId = nonGenSeries[seriesId].attrId;
        // _attrId.reset();
        
        uint256 from = _attrId.current() + 1;
        for (uint256 index = 0; index < name.length; index++) {
            // totalRarity = totalRarity + rarity[index];
            // require( totalRarity <= 100, "Rarity sum of URIs can't exceed 100");
            _attrId.increment();
            nonGenSeries[seriesId].uris[_attrId.current()] = URI(name[index], uri[index], rarity[index], copies);
            
        }
        _CopiesData[seriesId].total = _attrId.current();
        // require( totalRarity == 100, "Rarity sum of URIs should be equal to 100");
        emit URIsAdded(seriesId,from, _attrId.current(), uri, name, rarity);
    }
/** 
    @dev function to start new NonGenerative Series
        @param name - name of the series
        @param seriesURI - series metadata tracking URI
        @param boxName - name of the boxes to be created in this series
        @param boxURI - blindbox's URI tracking its metadata
        @param startTime - start time of the series, (from whom its boxes will be available to get bought)
        @param endTime - end time of the series, (after whom its boxes will not be available to get bought)
        
       @notice only owner of smartcontract can trigger this function
    */
    function nonGenerativeSeries(address bCollection,string memory name, string memory seriesURI, string memory boxName, string memory boxURI, uint256 startTime, uint256 endTime, uint256 royalty) onlyOwner internal {
        require(startTime < endTime, "invalid series endTime");
        nonGenSeries[nonGenerativeSeriesId.current()].collection = bCollection;
        seriesIdsByCollection[bCollection][false].push(nonGenerativeSeriesId.current());
        nonGenSeries[nonGenerativeSeriesId.current()].name = name;
        nonGenSeries[nonGenerativeSeriesId.current()].seriesURI = seriesURI;
        nonGenSeries[nonGenerativeSeriesId.current()].boxName = boxName;
        nonGenSeries[nonGenerativeSeriesId.current()].boxURI = boxURI;
        nonGenSeries[nonGenerativeSeriesId.current()].startTime = startTime;
        nonGenSeries[nonGenerativeSeriesId.current()].endTime = endTime;
        nonGenseriesRoyalty[nonGenerativeSeriesId.current()] = royalty;

        emit NewNonGenSeries( nonGenerativeSeriesId.current(), name, startTime, endTime);
    }
    function setExtraParams(uint256 _baseCurrency, uint256[] memory allowedCurrecny, address _bankAddress, uint256 boxPrice, uint256 maxBoxes, uint256 perBoxNftMint) internal {
        baseCurrency[nonGenerativeSeriesId.current()] = _baseCurrency;
        _allowedCurrencies[nonGenerativeSeriesId.current()] = allowedCurrecny;
        bankAddress[nonGenerativeSeriesId.current()] = _bankAddress;
        nonGenSeries[nonGenerativeSeriesId.current()].price = boxPrice;
        nonGenSeries[nonGenerativeSeriesId.current()].maxBoxes = maxBoxes;
        nonGenSeries[nonGenerativeSeriesId.current()].perBoxNftMint = perBoxNftMint;
    }
    function getAllowedCurrencies(uint256 seriesId) public view returns(uint256[] memory) {
        return _allowedCurrencies[seriesId];
    }
    /** 
    @dev utility function to mint NonGenerative BlindBox
        @param seriesId - id of NonGenerative Series whose box to be opened
    @notice given series should not be ended or its max boxes already minted.
    */
    function mintNonGenBox(uint256 seriesId) private {
        require(nonGenSeries[seriesId].startTime <= block.timestamp, "series not started");
        require(nonGenSeries[seriesId].endTime >= block.timestamp, "series ended");
        require(nonGenSeries[seriesId].maxBoxes > nonGenSeries[seriesId].boxId.current(),"max boxes minted of this series");
        nonGenSeries[seriesId].boxId.increment(); // incrementing boxCount minted
        _boxId.increment(); // incrementing to get boxId

        boxesNonGen[_boxId.current()].name = nonGenSeries[seriesId].boxName;
        boxesNonGen[_boxId.current()].boxURI = nonGenSeries[seriesId].boxURI;
        boxesNonGen[_boxId.current()].series = seriesId;
        boxesNonGen[_boxId.current()].countNFTs = nonGenSeries[seriesId].perBoxNftMint;
       
        // uint256[] attributes;    // attributes setting in another mapping per boxId. note: series should've all attributes [Done]
        // uint256 attributesRarity; // rarity should be 100, how to ensure ? 
                                    //from available attrubets fill them in 100 index of array as per their rarity. divide all available rarites into 100
        emit BoxMintNonGen(_boxId.current(), seriesId);

    }
    modifier validateCurrencyType(uint256 seriesId, uint256 currencyType, bool isPayable) {
        bool isValid = false;
        uint256[] storage allowedCurrencies = _allowedCurrencies[seriesId];
        for (uint256 index = 0; index < allowedCurrencies.length; index++) {
            if(allowedCurrencies[index] == currencyType){
                isValid = true;
            }
        }
        require(isValid, "123");
        require((isPayable && currencyType == 3) || currencyType < 3, "126");
        _;
    }
    
/** 
    @dev function to buy NonGenerative BlindBox
        @param seriesId - id of NonGenerative Series whose box to be bought
    @notice given series should not be ended or its max boxes already minted.
    */
    function buyNonGenBox(uint256 seriesId, uint256 currencyType, string memory ownerId) validateCurrencyType(seriesId,currencyType, false) internal {
        require(abi.encodePacked(nonGenSeries[seriesId].name).length > 0,"Series doesn't exist"); 
        require(nonGenSeries[seriesId].maxBoxes > nonGenSeries[seriesId].boxId.current(),"boxes sold out");
        require(nonGenSeries[seriesId].attrId.current() > nonGenSeries[seriesId].boxId.current(),"boxes sold out");
        mintNonGenBox(seriesId);
            token = USD;
        
        uint256 price = calculatePrice(nonGenSeries[seriesId].price , baseCurrency[seriesId], currencyType);
        // uint256 price2 = calculatePrice(gasFee ,0, currencyType);
        
        if(currencyType == 0){
            dex.mintAliaForNonCrypto(price, msg.sender);
            token = ALIA;
        } else if (currencyType == 2) {
            token = ETH;
        }else{
            price = price / 1000000000000;
            // price2 = price2 / 1000000000000;
        }
        // escrow alia
        token.transferFrom(msg.sender, bankAddress[seriesId], price);
        // token.transferFrom(msg.sender, gasFeeCollector, price2);
        // transfer box to buyer
        nonGenBoxOwner[_boxId.current()].ownerAddress = msg.sender;
        nonGenBoxOwner[_boxId.current()].id = ownerId;
        emitBuyBoxNonGen(seriesId, currencyType, price, ownerId);
       
    }
    function timeTester() internal {
    if(deployTime+ 24 hours <= block.timestamp)
    {
      deployTime = block.timestamp;
      vrf.getRandomNumber();
    }
  }
    function buyNonGenBoxPayable(uint256 seriesId) validateCurrencyType(seriesId,3, true)  internal {
        require(abi.encodePacked(nonGenSeries[seriesId].name).length > 0,"Series doesn't exist"); 
        require(nonGenSeries[seriesId].maxBoxes > nonGenSeries[seriesId].boxId.current(),"boxes sold out");
        uint256 before_bal = MATIC.balanceOf(address(this));
        MATIC.deposit{value : msg.value}();
        uint256 after_bal = MATIC.balanceOf(address(this));
        uint256 depositAmount = after_bal - before_bal;
        uint256 price = calculatePrice(nonGenSeries[seriesId].price , baseCurrency[seriesId], 1);
        // uint256 price2 = calculatePrice(gasFee , 0, 1);
        require(price <= depositAmount, "NFT 108");
        chainTransfer(bankAddress[seriesId], 1000, price);
        // chainTransfer(gasFeeCollector, 1000, price2);
        if((depositAmount - price ) > 0) chainTransfer(msg.sender, 1000, (depositAmount - price ));
        mintNonGenBox(seriesId);
        // transfer box to buyer
        nonGenBoxOwner[_boxId.current()].ownerAddress = msg.sender;
        emitBuyBoxNonGen(seriesId, 3, price, "");
      }
    function emitBuyBoxNonGen(uint256 seriesId, uint256 currencyType, uint256 price, string memory ownerId) private{
    emit BuyBoxNonGen(_boxId.current(), seriesId, nonGenSeries[seriesId].price, currencyType, nonGenSeries[seriesId].collection, msg.sender, baseCurrency[seriesId], price, ownerId);
    }
//     function chainTransfer(address _address, uint256 percentage, uint256 price) private {
//       address payable newAddress = payable(_address);
//       uint256 initialBalance;
//       uint256 newBalance;
//       initialBalance = address(this).balance;
//       MATIC.withdraw(SafeMath.div(SafeMath.mul(price,percentage), 1000));
//       newBalance = address(this).balance.sub(initialBalance);
//     //   newAddress.transfer(newBalance);
//     (bool success, ) = newAddress.call{value: newBalance}("");
//     require(success, "Failed to send Ether");
//   }
/** 
    @dev function to open NonGenerative BlindBox
        @param boxId - id of blind box to be opened
    @notice given box should not be already opened.
    */
    function openNonGenBox(uint256 boxId, string memory ownerId) public {
        require(nonGenBoxOwner[boxId].ownerAddress == msg.sender, "Box not owned");
        require(!boxesNonGen[boxId].isOpened, "Box already opened");
        _openNonGenBox(boxId, ownerId);

        emit BoxOpenedNonGen(boxId);
    }
/** 
    @dev utility function to open NonGenerative BlindBox
        @param boxId - id of blind box to be opened
    @notice given box should not be already opened.
    */
    function _openNonGenBox(uint256 boxId, string memory ownerId) private {
        uint256 sId = boxesNonGen[boxId].series;
        address collection = nonGenSeries[sId].collection;
    timeTester();
        // uint256 attrType = nonGenSeries[sId].attrType.current();
        uint256 rand =  vrf.getRandomVal();
        uint256 rand1;
        // uint256[] memory uris = new uint256[](_CopiesData[sId].total);
        uint256 tokenId;
        // uris = getRandURIs(sId, _CopiesData[sId].total);
        for (uint256 j = 0; j < boxesNonGen[boxId].countNFTs; j++) {
          rand1 = uint256(keccak256(abi.encodePacked(block.coinbase, rand, msg.sender, j))).mod(_CopiesData[sId].total); // to keep each iteration further randomize and reducing fee of invoking VRF on each iteration.
          tokenId = dex.mintWithCollection(collection, msg.sender, nonGenSeries[sId].uris[rand1].uri, nonGenseriesRoyalty[sId], ownerId, msg.sender );
          _CopiesData[sId].nftCopies[rand1]++;
          if(_CopiesData[sId].nftCopies[rand1] >= nonGenSeries[sId].uris[rand1].copies){
              URI storage temp = nonGenSeries[sId].uris[rand1];
            nonGenSeries[sId].uris[rand1] = nonGenSeries[sId].uris[_CopiesData[sId].total];
            nonGenSeries[sId].uris[_CopiesData[sId].total] = temp;
            _CopiesData[sId].total--;
            
          }
          emit NonGenNFTMinted(boxId, tokenId, msg.sender, collection, rand1, ownerId);
        }
        boxesNonGen[boxId].isOpened = true;
       
    }
/** 
    @dev utility function to get Random URIs of given series based on URI's rarities.
        @param seriesId - id of nongenerative series
        @param countNFTs - total NFTs to be randomly selected and minted.
    */
    function getRandURIs(uint256 seriesId, uint256 countNFTs) internal view returns(uint256[] memory) {
        uint256[] memory URIs = new uint256[](countNFTs);
        // uint256[] memory uris = new uint256[](100);
        URI memory uri;
        uint256 occurence;
        uint256 i = 0;
        // populate attributes in array as per their rarity
        for (uint256 uriId = 1; uriId <= nonGenSeries[seriesId].attrId.current(); uriId++) {
            uri = nonGenSeries[seriesId].uris[uriId];
            // occurence = getOccurency(attr, attrType);
            occurence = uri.rarity;
            for (uint256 index = 0; index < occurence; index++) {
                URIs[i] = uriId;
                i++;
            }
        }
        // generate rand num through VRF out of 100 (size of array) can increase size or decrase based on attributes quantity
        
        // pic thos uriIds and return
        return URIs;
    }
    
    // events
    event NewNonGenSeries(uint256 indexed seriesId, string name, uint256 startTime, uint256 endTime);
    event BoxMintNonGen(uint256 boxId, uint256 seriesId);
    // event AttributesAdded(uint256 indexed boxId, uint256 indexed attrType, uint256 fromm, uint256 to);
    event URIsAdded(uint256 indexed boxId, uint256 from, uint256 to, string[] uris, string[] name, uint256[] rarity);
    event BuyBoxNonGen(uint256 boxId, uint256 seriesId, uint256 orignalPrice, uint256 currencyType, address collection, address from,uint256 baseCurrency, uint256 calculated, string ownerId);
    event BoxOpenedNonGen(uint256 indexed boxId);
    event NonGenNFTMinted(uint256 indexed boxId, uint256 tokenId, address from, address collection, uint256 uriIndex, string ownerId );
    // event BlackList(uint256 indexed seriesId, bytes32 indexed combHash, bool flag);
    

}

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface LPInterface {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface INFT {
    function mintWithTokenURI(address to, string calldata tokenURI) external returns (uint256);
    function transferFrom(address owner, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
     function withdraw(uint) external;
    function deposit() payable external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IDEX {
   function calculatePrice(uint256 _price, uint256 base, uint256 currencyType, uint256 tokenId, address seller, address nft_a) external view returns(uint256);
  function mintWithCollection(address collection, address to, string memory tokenURI, uint256 royalty, string memory ownerId, address from )external returns(uint256);
  function createCollection(string calldata name_, string calldata symbol_) external;
   function transferCollectionOwnership(address collection, address newOwner) external;
   function mintAliaForNonCrypto(uint256 price,address from) external returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Utils.sol';
/**
@title GenerativeBB 
- this contract of blindbox's type Generative. which deals with all the operations of Generative blinboxes & series
 */
contract GenerativeBB is Utils {
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    constructor()  {

    }


    /** 
    @dev function to add attributes/traits in given series
        @param seriesId - id of the series in whom attributes to be added
        @param attrType - attribute Type id whose variants(attributes) to be updated, pass attrType=0 is want to add new attributeType.
        @param name - array of attributes names to be added/updated
        @param uri - array of attributes URIs to be added/updated
        @param rarity - array of attributes rarity to be added/updated
    @notice
        1. all arrays should be of same length & sequence
        2. only owner of the smartcontract can add/update attributes
        3. you can not update one attribute, should provide all to attributes of given attrType# ensure data integrity & rarities
    */
    function setAttributes(uint256 seriesId, uint256 attrType, string[] memory name, string[] memory uri, uint256[] memory rarity) onlyOwner public {
        uint256 totalRarity = 0;
        if(attrType == 0){
            genSeries[seriesId].attrType.increment(); // should do +=
            attrType = genSeries[seriesId].attrType.current();
        }else {
            require(abi.encodePacked(genSeries[seriesId].attributes[attrType][1].name).length != 0,"attrType doesn't exists, please pass attrType=0 for new attrType");
        }
        require(name.length == uri.length && name.length == rarity.length, "attributes length mismatched");
        Counters.Counter storage _attrId = genSeries[seriesId].attrId; // need to reset so rarity sum calc could be exact to avoid rarity issues
        _attrId.reset(); // reseting attrIds to overwrite
        // delete genSeries[seriesId].attributes[attrType];
        uint256 from = _attrId.current() + 1;
        for (uint256 index = 0; index < name.length; index++) {
            totalRarity = totalRarity + rarity[index];
            require( totalRarity <= 100, "Rarity sum of attributes can't exceed 100");
            _attrId.increment();
            genSeries[seriesId].attributes[attrType][_attrId.current()] = Attribute(name[index], uri[index], rarity[index]);
        }

        require( totalRarity == 100, "Rarity sum of attributes shoud be equal to 100");
        emit AttributesAdded(seriesId, attrType,from, _attrId.current());
    }
/** 
    @dev function to start new Generative Series
        @param name - name of the series
        @param seriesURI - series metadata tracking URI
        @param boxName - name of the boxes to be created in this series
        @param boxURI - blindbox's URI tracking its metadata
        @param startTime - start time of the series, (from whom its boxes will be available to get bought)
        @param endTime - end time of the series, (after whom its boxes will not be available to get bought)

    */
    function generativeSeries(address bCollection, string memory name, string memory seriesURI, string memory boxName, string memory boxURI, uint256 startTime, uint256 endTime, uint256 royalty) onlyOwner internal {
        require(startTime < endTime, "invalid series endTime");
        seriesIdsByCollection[bCollection][true].push(generativeSeriesId.current());
        genCollection[generativeSeriesId.current()] = bCollection;
        genSeries[generativeSeriesId.current()].name = name;
        genSeries[generativeSeriesId.current()].seriesURI = seriesURI;
        genSeries[generativeSeriesId.current()].boxName = boxName;
        genSeries[generativeSeriesId.current()].boxURI = boxURI;
        genSeries[generativeSeriesId.current()].startTime = startTime;
        genSeries[generativeSeriesId.current()].endTime = endTime;

        emit NewGenSeries( generativeSeriesId.current(), name, startTime, endTime);
    }
    function setExtraParamsGen(uint256 _baseCurrency, uint256[] memory allowedCurrecny, address _bankAddress, uint256 boxPrice, uint256 maxBoxes, uint256 perBoxNftMint) internal {
        baseCurrencyGen[generativeSeriesId.current()] = _baseCurrency;
        _allowedCurrenciesGen[generativeSeriesId.current()] = allowedCurrecny;
        bankAddressGen[generativeSeriesId.current()] = _bankAddress;
        genSeries[generativeSeriesId.current()].price = boxPrice;
        genSeries[generativeSeriesId.current()].maxBoxes = maxBoxes;
        genSeries[generativeSeriesId.current()].perBoxNftMint = perBoxNftMint;
    }
    /** 
    @dev utility function to mint Generative BlindBox
        @param seriesId - id of Generative Series whose box to be opened
    @notice given series should not be ended or its max boxes already minted.
    */
    function mintGenBox(uint256 seriesId) private {
        require(genSeries[seriesId].endTime >= block.timestamp, "series ended");
        require(genSeries[seriesId].maxBoxes > genSeries[seriesId].boxId.current(),"max boxes minted of this series");
        genSeries[seriesId].boxId.increment(); // incrementing boxCount minted
        _boxId.increment(); // incrementing to get boxId

        boxesGen[_boxId.current()].name = genSeries[seriesId].boxName;
        boxesGen[_boxId.current()].boxURI = genSeries[seriesId].boxURI;
        boxesGen[_boxId.current()].series = seriesId;
        boxesGen[_boxId.current()].countNFTs = genSeries[seriesId].perBoxNftMint;
       
        // uint256[] attributes;    // attributes setting in another mapping per boxId. note: series should've all attributes [Done]
        // uint256 attributesRarity; // rarity should be 100, how to ensure ? 
                                    //from available attrubets fill them in 100 index of array as per their rarity. divide all available rarites into 100
        emit BoxMintGen(_boxId.current(), seriesId);

    }
     modifier validateCurrencyTypeGen(uint256 seriesId, uint256 currencyType, bool isPayable) {
        bool isValid = false;
        uint256[] storage allowedCurrencies = _allowedCurrenciesGen[seriesId];
        for (uint256 index = 0; index < allowedCurrencies.length; index++) {
            if(allowedCurrencies[index] == currencyType){
                isValid = true;
            }
        }
        require(isValid, "123");
        require((isPayable && currencyType == 1) || currencyType < 1, "126");
        _;
    }
/** 
    @dev function to buy Generative BlindBox
        @param seriesId - id of Generative Series whose box to be bought
    @notice given series should not be ended or its max boxes already minted.
    */
    function buyGenerativeBox(uint256 seriesId, uint256 currencyType) validateCurrencyTypeGen(seriesId, currencyType, false) internal {
        require(abi.encode(genSeries[seriesId].name).length > 0,"Series doesn't exist"); 
        require(genSeries[seriesId].maxBoxes > genSeries[seriesId].boxId.current(),"boxes sold out");
        mintGenBox(seriesId);
       token = USD;
        
        uint256 price = dex.calculatePrice(genSeries[seriesId].price , baseCurrencyGen[seriesId], currencyType, 0, address(this), address(this));
        // if(currencyType == 0){
            price = price / 1000000000000;
        // }
        // escrow alia
        token.transferFrom(msg.sender, bankAddressGen[seriesId], price);
        genBoxOwner[_boxId.current()] = msg.sender;

        emit BuyBoxGen(_boxId.current(), seriesId);
    }
    function buyGenBoxPayable(uint256 seriesId) validateCurrencyTypeGen(seriesId,1, true) internal {
        require(abi.encode(genSeries[seriesId].name).length > 0,"Series doesn't exist"); 
        require(genSeries[seriesId].maxBoxes > genSeries[seriesId].boxId.current(),"boxes sold out");
        uint256 before_bal = MATIC.balanceOf(address(this));
        MATIC.deposit{value : msg.value}();
        uint256 after_bal = MATIC.balanceOf(address(this));
        uint256 depositAmount = after_bal - before_bal;
        uint256 price = dex.calculatePrice(genSeries[seriesId].price , baseCurrencyGen[seriesId], 1, 0, address(this), address(this));
        require(price <= depositAmount, "NFT 108");
        chainTransfer(bankAddressGen[seriesId], 1000, price);
        if(depositAmount - price > 0) chainTransfer(msg.sender, 1000, (depositAmount - price));
        mintGenBox(seriesId);
        // transfer box to buyer
        genBoxOwner[_boxId.current()] = msg.sender;

        emit BuyBoxGen(_boxId.current(), seriesId);
    }
    function chainTransfer(address _address, uint256 percentage, uint256 price) internal {
      address payable newAddress = payable(_address);
      uint256 initialBalance;
      uint256 newBalance;
      initialBalance = address(this).balance;
      MATIC.withdraw(SafeMath.div(SafeMath.mul(price,percentage), 1000));
      newBalance = address(this).balance.sub(initialBalance);
    //   newAddress.transfer(newBalance);
    (bool success, ) = newAddress.call{value: newBalance}("");
    require(success, "Failed to send Ether");
  }
/** 
    @dev function to open Generative BlindBox
        @param boxId - id of blind box to be opened
    @notice given box should not be already opened.
    */
    function openGenBox(uint256 boxId) internal {
        require(genBoxOwner[boxId] == msg.sender, "Box not owned");
        require(!boxesGen[boxId].isOpened, "Box already opened");
        _openGenBox(boxId);

        emit BoxOpenedGen(boxId);

    }
    event Msg(string msg);
    event Value(uint256 value);
    /** 
    @dev utility function to open Generative BlindBox
        @param boxId - id of blind box to be opened
    @notice given box should not be already opened.
    */
    function _openGenBox(uint256 boxId) private {
        uint256 sId = boxesGen[boxId].series;
        uint256 attrType = genSeries[sId].attrType.current();
        
        uint256 rand = getRand(); // should get random number within range of 100
        // NFT[] storage nft = NFT[](boxesGen[boxId].countNFTs);
        uint256 i;
        uint256 j;
        bytes32 combHash;
        uint256 rand1;
        for ( i = 1; i <= boxesGen[boxId].countNFTs; i++) {
            emit Msg("into NFT loop");
            combHash = bytes32(0); // reset combHash for next iteration of possible NFT
            // combHash = keccak256(abi.encode(sId,boxId)); // to keep combHash of each box unique [no needed, as list is per series]
            
            for ( j = 1; j <= attrType; j++){
                // select one random attribute from each attribute type
                // set in mapping against boxId
                emit Msg("into attrType loop");
                rand1 = uint256(keccak256(abi.encodePacked(block.coinbase, rand, msg.sender, i,j))).mod(100); // to keep each iteration further randomize and reducing fee of invoking VRF on each iteration.
                emit Value(rand1);
                nftsToMint[boxId][i][j] = getRandAttr(sId, boxId, j, rand1);
                // nftsToMint[i].attribute[j] = getRandAttr(sId, boxId, j);
                // generate hash of comb decided so far
                combHash = keccak256(abi.encode(combHash, nftsToMint[boxId][i][j])); // TODO: need to test if hash appending work same like hashing with all values at once. [DONE]
            }
                // bytes32 comb = keccak256(abi.encode())
            // check if selected attr comibination is blacklisted
            if( isBlackListed(sId, combHash)){
                // same iteration should run again
                i = i - 1;
                j = j - 1;
                rand = getRand(); // getting new random number to skip blacklisted comb on same iteration.
                // delete nftsToMint[boxId][i]; // deleting blacklisted comb NFT [need to delete each j's entry] TODO: what if left as it is to be replaced in next iteration with same i
            }
        }

        boxesGen[boxId].isOpened = true;
    }

    /** 
    @dev utility function to get Random attribute of given attribute Type based on attributes rarities.
        @param seriesId - id of generative series
        @param boxId - id of blindbox whose
        @param attrType - attribute type whose random attribute to be selected
        @param rand - random number on whose basis random attribute to be selected
    */
    function getRandAttr(uint256 seriesId, uint256 boxId, uint256 attrType, uint256 rand) private returns(uint256) {
        uint256[] memory attrs = new uint256[](100);
        Attribute memory attr;
        uint256 occurence;
        uint256 i = 0;
        // populate attributes in array as per their rarity
        for (uint256 attrId = 1; attrId <= genSeries[seriesId].attrId.current(); attrId++) {
            attr = genSeries[seriesId].attributes[attrType][attrId];
            // occurence = getOccurency(attr, attrType);
            occurence = attr.rarity;
            for (uint256 index = 0; index < occurence; index++) {
                attrs[i] = attrId;
                i++;
                if( i > rand ){
                    break;
                }
            }
        }
        // generate rand num through VRF out of 100 (size of array) can increase size or decrase based on attributes quantity
        // pic that index's attributeId and return
        // emit Attr(attrType, attrs[rand]);
        return attrs[rand];
    }

    /** 
    @dev function to check is given combination of attributes of specific series is blacklisted or not
        @param seriesId series Id whose blacklist to be checked against given combHash
        @param combHash hash of attributes combination which is to be checked
    */
    function isBlackListed(uint256 seriesId, bytes32 combHash) public view returns(bool) {
        return genSeries[seriesId].blackList[combHash];
    }
    /** 
    @dev function to get hash of given attributes combination.
        @param seriesId series Id whose attributes combination
        @param boxId hash of attributes combination which is to be checked
    */
    function getCombHash(uint256 seriesId, uint256 boxId, uint256[] memory attrTypes, uint256[] memory attrIds) public pure returns(bytes32) {
        bytes32 combHash = bytes32(0);
        // for (uint256 i = 0; i < attrTypes.length; i++) {
            for (uint256 j = 0; j < attrIds.length; j++) {
                combHash = keccak256(abi.encode(combHash,attrIds[j]));
            }
            
        // }
        return combHash;
    }
/** 
    @dev function to blacklist given attributes combination.
        @param seriesId series Id whose attributes combination to be blacklisted
        @param combHash hash of attributes combination to be blacklisted
        @param flag flag to blacklist or not.
    */
    function blackListAttribute(uint256 seriesId, bytes32 combHash, bool flag) public onlyOwner {
        genSeries[seriesId].blackList[combHash] = flag;
        emit BlackList(seriesId, combHash, flag);
    }
   /** 
    @dev function to mint NFTs by sumbitting finalized URIs of comibation attributes, randomly calculated at the time of box was opened.
        @param boxId boxId whose randomly calculated NFTs to be minted
        @param uris Generated array of URIs to be minted.
    @notice only owner of the contract can trigger this function
    */
    // function mintGenerativeNFTs(address collection, uint256 boxId, string[] memory uris) public onlyOwner {
    //     require(nftsToMint[boxId][1][1] > 0, "boxId isn't opened");
    //     require(boxesGen[boxId].countNFTs == uris.length, "insufficient URIs to mint");
    //      for (uint256 i = 0; i < uris.length; i++) {
    //         dex.mintWithCollection(collection, genBoxOwner[boxId], uris[i], genseriesRoyalty[boxesGen[boxId].series]);
    //      }
    //      uint256 countNFTs = boxesGen[boxId].countNFTs;
    //      delete boxesGen[boxId]; // deleting box to avoid duplicate NFTs mint
    //      emit NFTsMinted(boxId, genBoxOwner[boxId], countNFTs);
    // }
 /** 
    @dev function to mint NFTs by sumbitting finalized URIs of comibation attributes, randomly calculated at the time of box was opened.
        @param seriesId ID of series whose attributes to be fetched.
        @param attrType attribute Type of which attributes to be fetched.
        @param attrId attribute ID to be fetched.
    */
    function getAttributes(uint256 seriesId, uint256 attrType, uint256 attrId) public view returns(Attribute memory){
        return genSeries[seriesId].attributes[attrType][attrId];
    }
    
    // events
    event NewGenSeries(uint256 indexed seriesId, string name, uint256 startTime, uint256 endTime);
    event BoxMintGen(uint256 boxId, uint256 seriesId);
    event AttributesAdded(uint256 indexed seriesId, uint256 indexed attrType, uint256 from, uint256 to);
    event BuyBoxGen(uint256 boxId, uint256 seriesId);
    event BoxOpenedGen(uint256 indexed boxId);
    event BlackList(uint256 indexed seriesId, bytes32 indexed combHash, bool flag);
    event NFTsMinted(uint256 indexed boxId, address owner, uint256 countNFTs);
    

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}