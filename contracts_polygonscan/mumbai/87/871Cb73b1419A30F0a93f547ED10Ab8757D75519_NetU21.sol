// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface TokenInterface {
    // determinamos las funciones que necesitamos del ERC20. Tienen que ser iguales.
    function decimals() external view  returns(uint8);
    function balanceOf(address _address) external view returns(uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function safeTransferFrom(address _address, address _to, uint256 _id, uint256 _value, bytes memory data) external;
}

/// @custom:security-contact [email protected]
contract NetU21 is ERC1155, AccessControl, ERC1155Burnable, ERC1155Supply, ERC1155Holder, Ownable {
    string public constant name = 'NetU21 Token';
    string public constant symbol = 'NETU21';
    uint8 public constant decimals = 8;
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant ADMIN_NFT = keccak256("ADMIN_NFT");
    uint256 public constant COIN = 0;
    
    uint256 internal totalSupplyToken; //for NETU21 Tokens
    uint256 supply;
    mapping(uint => uint256) public totalSupplyYear; //never more than 2.1M per year
    uint public currentYear;

    struct NetU21_NFT{
        uint256 BurnedCount; // Total burnt NFT (default 0)
        uint256 NFTRegistered; // Total NFT count, including burnt NFT (default 0)
        uint256 NFTEquivalentTokens; //Initial value for NetUs of each NFT (default 1)
        address AdminNFT;
        uint DividToCreator; //default 0%
        string UnitsOrIndividuals;  //Units: #amount of this nfts (coin games, assets, etc). Individuals: Just 1 unique item
        uint BasePriceUnit; //price to buy every single NFT
        mapping(uint256 => address) idToOwner; // _NFT[id].idToOwner[_n] = 0x...addresswallet
        mapping(uint256 => uint) SellValue; // _NFT[id].SellValue[_n] = 0.5000000 (value in NETU21)
        mapping(uint256 => uint) RentValue; // _NFT[id].RentValue[_n] = 0.5000000 (value in NETU21)
        mapping(address => uint) NFTBalanceOf; // _NFT[id].NFTBalanceOf[0x...addresswallet] = #amount; (when is Units)
        mapping(uint256 => bool) NFTPublicView; //when the new owner wants to show to the public or not the NFT
        mapping(uint256 => string) NFTStatus; //when the new owner wants to change the status: Own/Rent/Sale/Rented
        mapping(uint256 => address) idToRented; // _NFT[id].idToRented[_n] = 0x...addresswallet
    }

    struct MyUpline{
     address u01;
     address u02;
     address u03;
     address u04;
     address u05;
     address u06;
     address u07;
     address u08;
     address u09;
     address u10;
     address u11;
     address u12;
     address u13;
     address u14;
     address u15;
     address u16;
     address u17;
     address u18;
     address u19;
     address u20;
     address u21;
    }

    mapping(uint256 => NetU21_NFT) internal _NFT;
    uint256 public totalNFTcollections = 0;
    uint256 totalNFTRegistered = 0;
    mapping(uint => uint) public typeNFT;
    mapping(address => uint) public burnedTokens;
    mapping(address => uint) public BalanceOf;
    mapping(address => uint) public tokensApprovedForBurn;

    string public baseURI = "https://netu21.com/token-data-"; //based on URL https://netu21.com/token-data-{id}.json
    uint public tokensPerMATIC = 1 * (10 ** decimals); // token price for MATIC
    uint public discountSalesBack = 3; //Percent Discount in every sale back
    uint public tokensFaucetMint = 2100000; //amount requested in faucet
    uint public percentForPublic = 99; //Percent for Public in every transaction
    uint public percentForUpline = 1; //Percent for upline

    mapping(address => MyUpline) internal usUp;
    address public lastWalletWithoutNetwork;

    TokenInterface TokenContract; // Variable de la interface.

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    //event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    constructor() ERC1155("https://netu21.com/token-data-") {
        totalSupplyToken = 2100000 * (10 ** decimals);

        _mint(msg.sender, COIN, totalSupplyToken, "");
        BalanceOf[msg.sender] = totalSupplyToken;
        BalanceOf[address(this)] = totalSupplyToken;
        currentYear = 2021;
        totalSupplyYear[currentYear] = totalSupplyToken;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(VERIFIER_ROLE, msg.sender);
        _setupRole(ADMIN_NFT, msg.sender);

        TokenContract = TokenInterface(address(this));

        usUp[msg.sender].u01 = msg.sender;
        usUp[msg.sender].u02 = msg.sender;
        usUp[msg.sender].u03 = msg.sender;
        usUp[msg.sender].u04 = msg.sender;
        usUp[msg.sender].u05 = msg.sender;
        usUp[msg.sender].u06 = msg.sender;
        usUp[msg.sender].u07 = msg.sender;
        usUp[msg.sender].u08 = msg.sender;
        usUp[msg.sender].u09 = msg.sender;
        usUp[msg.sender].u10 = msg.sender;
        usUp[msg.sender].u11 = msg.sender;
        usUp[msg.sender].u12 = msg.sender;
        usUp[msg.sender].u13 = msg.sender;
        usUp[msg.sender].u14 = msg.sender;
        usUp[msg.sender].u15 = msg.sender;
        usUp[msg.sender].u16 = msg.sender;
        usUp[msg.sender].u17 = msg.sender;
        usUp[msg.sender].u18 = msg.sender;
        usUp[msg.sender].u19 = msg.sender;
        usUp[msg.sender].u20 = msg.sender;
        usUp[msg.sender].u21 = msg.sender;
    }

    
    function registerNFTCollection(uint256 NFTRegistered, uint256 NFTEquivalentTokens, address AdminNFT, uint _DividToCreator, string memory _UnitsOrIndividuals, uint _BasePriceUnit) public onlyRole(MINTER_ROLE){
        totalNFTcollections++;
        _NFT[totalNFTcollections].BurnedCount = 0;
        _NFT[totalNFTcollections].NFTRegistered = NFTRegistered;
        _NFT[totalNFTcollections].NFTEquivalentTokens = NFTEquivalentTokens;
        _NFT[totalNFTcollections].AdminNFT = AdminNFT;
        _NFT[totalNFTcollections].DividToCreator = _DividToCreator;
        _NFT[totalNFTcollections].UnitsOrIndividuals = _UnitsOrIndividuals;
        _NFT[totalNFTcollections].BasePriceUnit = _BasePriceUnit;
        _mint(AdminNFT, totalNFTcollections, NFTRegistered, "");
    }

    //ok
    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        baseURI = newuri;
        _setURI(newuri);
    }

    //ok
    function uri(uint256 id) public view virtual override returns (string memory) {
        string memory newuri = "";
        require(id <= totalNFTRegistered, "NOT_EXIST");
        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(baseURI).length == 0) {
            newuri = "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            if (id == 0){
                newuri = string(abi.encodePacked(baseURI, "0-0.json"));
            } else {
                newuri = string(abi.encodePacked(baseURI, uint2str(typeNFT[id]), "-", uint2str(id), ".json"));
            }
        }
        return newuri;
    }
    
    //ok
    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        if (id == COIN) {
            _mint(account, id, amount, data);
            totalSupplyYear[currentYear] = totalSupplyYear[currentYear] + amount;
            BalanceOf[account] = BalanceOf[account] + amount;
        }
    }

    function poolMint() public {
        require(BalanceOf[msg.sender] == 0, "ALREADY_BALANCE");
        _mint(msg.sender, COIN, tokensFaucetMint, "");
        totalSupplyYear[currentYear] = totalSupplyYear[currentYear] + tokensFaucetMint;
        BalanceOf[msg.sender] = BalanceOf[msg.sender] + tokensFaucetMint;
        setUpLine(msg.sender, lastWalletWithoutNetwork);
    }
    //ok
    /*
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }*/

    
    //ADMIN TRANSFER NFT BETWEEN USERS BY MINTER 
    //(Pending)
    function transferNFTFrom(address from, address to, uint _Id, uint value, bytes memory data) public onlyRole(MINTER_ROLE){
        safeTransferFrom(from, to, _Id, value, data);
        BalanceOf[from] = BalanceOf[from] - value;
        BalanceOf[to] = BalanceOf[to] + value;
    }
    
    /*---burning process--*/
    //(pending)
    function approveBurn(uint NFTTokensAmount, address holder) public onlyRole(VERIFIER_ROLE){
        tokensApprovedForBurn[holder]+=NFTTokensAmount;
    }

    //OK
    function burnTokens(uint256 _Id) public onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        //only burn NFTs
        _burn(msg.sender, _Id, tokensApprovedForBurn[msg.sender]);
        _NFT[_Id].BurnedCount = _NFT[_Id].BurnedCount + tokensApprovedForBurn[msg.sender];
        _NFT[_Id].NFTBalanceOf[msg.sender] = _NFT[_Id].NFTBalanceOf[msg.sender] - tokensApprovedForBurn[msg.sender];
        return true;
    }
    
    /*-- ADMIN NFT OPERATIONS --*/
    //OK
    function updateNFTTokenEquivalent(uint amount, uint256 _Id) public onlyRole(ADMIN_NFT){
        require(amount > 0, "NO_VALID_AMOUNT");
        _NFT[_Id].NFTEquivalentTokens = amount;
    }
    /*-- ADMIN NETU21 OPERATIONS --*/
    //ok
    function updatePriceTokensPerMATIC(uint amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(amount > 0, "NO_VALID_AMOUNT");
        tokensPerMATIC = amount;
    }
    
    //ok
    function updateDiscountSalesBack(uint amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(amount > 0, "NO_VALID_AMOUNT");
        discountSalesBack = amount;
    }

    function updatePercents(uint percentUpline, uint percentPublic) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(percentUpline > 0, "NO_VALID_PERCENT_UPLINE");
        require(percentPublic > 0, "NO_VALID_PERCENT_PUBLIC");
        uint _tot = percentUpline + percentPublic;

        require(_tot == 100, "NO_VALID_100_PERCENT");
        
        percentForUpline = percentUpline;
        percentForPublic = percentPublic;
    }

    function updateCurrentYear(uint NewYear) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(NewYear == currentYear+1, "NO_VALID_YEAR");
        currentYear = NewYear;
    }
    function updateTokensMintFaucet(uint amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(amount > 0, "NO_VALID_AMOUNT");
        tokensFaucetMint = amount;
    }
    /* -- NFT operations -- */
    //buy NFT on marketplace
    function getNFT(uint256 _Id, uint256 _n, uint amount, uint _action) external payable returns (uint tokenAmount){
        //_action: 0: Buy / 1: Rent
        uint totalTokens = 0;
        bool toMint = false;
        uint basePrice = _NFT[_Id].BasePriceUnit;
        //is for MINT?
        if (_NFT[typeNFT[_n]].idToOwner[_n] == address(0)) {
            toMint = true;
        } else if (keccak256(abi.encodePacked(_NFT[_Id].NFTStatus[_n])) == keccak256(abi.encodePacked("Rent"))) {
            //to rent or sale
            basePrice = _NFT[_Id].RentValue[_n];
        } else if (keccak256(abi.encodePacked(_NFT[_Id].NFTStatus[_n])) == keccak256(abi.encodePacked("Sell"))) {
            basePrice = _NFT[_Id].SellValue[_n];
        }

        if (keccak256(abi.encodePacked(_NFT[_Id].UnitsOrIndividuals)) == keccak256(abi.encodePacked("Units"))){
            //units of this nft
            totalTokens = (amount * _NFT[_Id].NFTEquivalentTokens) * (10 ** decimals);
            require(msg.value >= (basePrice * amount), "ERR_PRICE");
        } else {
            require(amount == 1, "ERR_AMOUNT");
            //only this nft
            totalTokens = amount;
            require(msg.value >= basePrice, "ERR_PRICE");
        }

        
        if (toMint == true){
            //mint  to user
            _mint(msg.sender, _Id, totalTokens, "");
            _addNFToken(msg.sender, _Id, _n, totalTokens);
        } else {
            if ((keccak256(abi.encodePacked(_NFT[_Id].NFTStatus[_n])) == keccak256(abi.encodePacked("Rent"))) && (_action == 1)) {
                //rent to user
                _NFT[_Id].NFTStatus[_n] = "Rented";
                _NFT[_Id].idToRented[_n] = msg.sender;
            } else if ((keccak256(abi.encodePacked(_NFT[_Id].NFTStatus[_n])) == keccak256(abi.encodePacked("Sell"))) && (_action == 0)){
                //sell to user
                safeTransferFrom(_NFT[_Id].idToOwner[_n], msg.sender, _Id, totalTokens, "");
                _addNFToken(msg.sender, _Id, _n, totalTokens);
            }
        }
        //transfer coins
        if (_NFT[_Id].DividToCreator > 0) {
            uint amount_creator = (basePrice / 100) * _NFT[_Id].DividToCreator;
            basePrice = basePrice - amount_creator;
            safeTransferFrom(msg.sender, _NFT[_Id].AdminNFT, COIN, amount_creator, "");
            BalanceOf[msg.sender] = BalanceOf[msg.sender] - amount_creator; 
            BalanceOf[_NFT[_Id].AdminNFT] = BalanceOf[_NFT[_Id].AdminNFT] + amount_creator;
        }
        transfer(_NFT[_Id].idToOwner[_n], basePrice);
        return totalTokens;
    }

    //Only owner of token/NFT collection
    /*
    function sellNFT(address buyer, uint256 _Id, uint256 _n, uint amount, bytes memory data) public onlyRole(ADMIN_NFT){

        require(_NFT[_Id].AdminNFT == msg.sender, "NOT_ADMIN_NFT_COLLECTION");
        require(buyer != address(0), "ZERO_ADDRESS");
        require(buyer != msg.sender, "SAME_ADDRESS_DESTINATION");
        require(_NFT[_Id].idToOwner[_n] == address(0), "NFT_ALREADY_EXISTS"); //in burned NFTs

        uint totalTokens = 0;

        if (keccak256(abi.encodePacked(_NFT[_Id].UnitsOrIndividuals)) == keccak256(abi.encodePacked(("Units")))){
            //units of this nft
            totalTokens = (amount * _NFT[_Id].NFTEquivalentTokens) * (10 ** decimals);
            require(_NFT[_Id].NFTBalanceOf[msg.sender] > amount, "NOT_ENOUGH_UNITS");
        } else {
            //only this nft
            totalTokens = amount;
        }
        

        //buyer: 99 from total aoperation% 
        //MLM dividends: 1%
        //---------------------------aqui voy-------------------------------- 
        
        //uint valdividends = (totalTokens * percentForUpline) / percentForPublic;
        //validate balance
        //uint _tot = totalTokens + valdividends;
        

        //Mint NFT to the user
        _mint(buyer, _Id, amount, "");
        _addNFToken(buyer, _Id, _n, amount);

        //TODO: transfer the coins to MLM
        safeTransferFrom(msg.sender, buyer, COIN, totalTokens, data); //CHANGE FOR ALL THE MLM
        BalanceOf[msg.sender] = BalanceOf[msg.sender] - totalTokens; //CHANGE FOR ALL THE MLM
        BalanceOf[buyer] = BalanceOf[buyer] + totalTokens;//CHANGE FOR ALL THE MLM
        
    }
    */
    function setToMarketNFT(uint256 _Id, uint256 _n, uint _price, string memory _typeMarket) public returns (bool){
        require(_NFT[_Id].idToOwner[_n] == msg.sender, "NOT_OWER");
        //options: Rent/Sale
        if ((keccak256(abi.encodePacked(_typeMarket)) == keccak256(abi.encodePacked("Rent"))) || (keccak256(abi.encodePacked(_typeMarket)) == keccak256(abi.encodePacked("Sell")))) {
            _NFT[_Id].NFTStatus[_n] = _typeMarket;
            _NFT[_Id].RentValue[_n] = _price;
            return true;
        }
        return false;
    }

    function returnToOwnerNFT(uint256 _Id, uint256 _n) public returns (bool) {
        require(_NFT[_Id].idToOwner[_n] == msg.sender, "NOT_OWER");
        if (keccak256(abi.encodePacked(_NFT[_Id].NFTStatus[_n])) == keccak256(abi.encodePacked("Rented"))) {
            _NFT[_Id].NFTStatus[_n] = "Own";
            _NFT[_Id].idToRented[_n] = address(0);
            return true;
        }
        return false;
    }
    
    function addBurnedTokens(address holder, uint _Id) public {
        if (burnTokens(_Id) == true) {
            uint burnedtok = tokensApprovedForBurn[holder];
            burnedTokens[holder]+=burnedtok;
        }
    }

    function _addNFToken(address _to, uint256 _Id, uint256 _n, uint _amount) internal virtual {
        _NFT[_Id].idToOwner[_n] = _to;
        _NFT[_Id].SellValue[_n] = msg.value;
        _NFT[_Id].RentValue[_n] = 0;
        _NFT[_Id].NFTPublicView[_n] = false;
        _NFT[_Id].NFTStatus[_n] = "Own";

        _NFT[_Id].NFTBalanceOf[_to] = _NFT[_Id].NFTBalanceOf[_to] + _amount;
        _NFT[_Id].NFTRegistered = _NFT[_Id].NFTRegistered + _amount;
        typeNFT[_n] = _Id;
        totalNFTRegistered++;
    }

    function ownerOf(uint256 _n) external view returns (address){
        if (keccak256(abi.encodePacked(_NFT[typeNFT[_n]].NFTStatus[_n])) != keccak256(abi.encodePacked("Rented"))) {
            return _NFT[typeNFT[_n]].idToRented[_n];
        } else {
            return _NFT[typeNFT[_n]].idToOwner[_n];
        }
    }
    
    //function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory){
        
    //}
    
    /*-- ERC20 functions --*/
    function totalSupply() external view returns (uint256) {
        return totalSupplyToken;
    }

    function balanceOf(address account) public view returns (uint256) {
        return BalanceOf[account];
    }

    function transfer(address _to, uint256 amount) public returns (bool){
        //only 99%
        uint256 _pay = (amount / 100) * percentForPublic;
        uint256 _div21 = ((amount / 100) * percentForUpline) / 21;
        uint256 _less = _pay;
        
        safeTransferFrom(msg.sender, _to, COIN, _pay, "");
        BalanceOf[_to] += _pay;
        setUpLine(_to, msg.sender);

        if (msg.sender != usUp[_to].u01){
            safeTransferFrom(msg.sender, usUp[_to].u01, COIN, _div21, "");
            BalanceOf[usUp[_to].u01] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u02){
            safeTransferFrom(msg.sender, usUp[_to].u02, COIN, _div21, "");
            BalanceOf[usUp[_to].u02] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u03){
            safeTransferFrom(msg.sender, usUp[_to].u03, COIN, _div21, "");
            BalanceOf[usUp[_to].u03] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u04){
            safeTransferFrom(msg.sender, usUp[_to].u04, COIN, _div21, "");
            BalanceOf[usUp[_to].u04] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u05){
            safeTransferFrom(msg.sender, usUp[_to].u05, COIN, _div21, "");
            BalanceOf[usUp[_to].u05] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u06){
            safeTransferFrom(msg.sender, usUp[_to].u06, COIN, _div21, "");
            BalanceOf[usUp[_to].u06] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u07){
            safeTransferFrom(msg.sender, usUp[_to].u07, COIN, _div21, "");
            BalanceOf[usUp[_to].u07] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u08){
            safeTransferFrom(msg.sender, usUp[_to].u08, COIN, _div21, "");
            BalanceOf[usUp[_to].u08] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u09){
            safeTransferFrom(msg.sender, usUp[_to].u09, COIN, _div21, "");
            BalanceOf[usUp[_to].u09] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u10){
            safeTransferFrom(msg.sender, usUp[_to].u10, COIN, _div21, "");
            BalanceOf[usUp[_to].u10] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u11){
            safeTransferFrom(msg.sender, usUp[_to].u11, COIN, _div21, "");
            BalanceOf[usUp[_to].u11] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u12){
            safeTransferFrom(msg.sender, usUp[_to].u12, COIN, _div21, "");
            BalanceOf[usUp[_to].u12] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u13){
            safeTransferFrom(msg.sender, usUp[_to].u13, COIN, _div21, "");
            BalanceOf[usUp[_to].u13] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u14){
            safeTransferFrom(msg.sender, usUp[_to].u14, COIN, _div21, "");
            BalanceOf[usUp[_to].u14] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u15){
            safeTransferFrom(msg.sender, usUp[_to].u15, COIN, _div21, "");
            BalanceOf[usUp[_to].u15] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u16){
            safeTransferFrom(msg.sender, usUp[_to].u16, COIN, _div21, "");
            BalanceOf[usUp[_to].u16] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u17){
            safeTransferFrom(msg.sender, usUp[_to].u17, COIN, _div21, "");
            BalanceOf[usUp[_to].u17] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u18){
            safeTransferFrom(msg.sender, usUp[_to].u18, COIN, _div21, "");
            BalanceOf[usUp[_to].u18] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u19){
            safeTransferFrom(msg.sender, usUp[_to].u19, COIN, _div21, "");
            BalanceOf[usUp[_to].u19] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u20){
            safeTransferFrom(msg.sender, usUp[_to].u20, COIN, _div21, "");
            BalanceOf[usUp[_to].u20] += _div21;
            _less += _div21;
        }

        if (msg.sender != usUp[_to].u21){
            safeTransferFrom(msg.sender, usUp[_to].u21, COIN, _div21, "");
            BalanceOf[usUp[_to].u21] += _div21;
            _less += _div21;
        }
        BalanceOf[msg.sender] = BalanceOf[msg.sender] - _less;
        return true;
    }

    
    /* SWAP */
    /**
  * @notice Allow users to buy tokens for MATIC
  */
  function buy() external payable returns (uint256 tokenAmount) {
    require(msg.value > 0, "Send an amount to buy some NETU21 tokens");

    uint256 amountToBuy = msg.value * tokensPerMATIC;// * (10 ** decimals);
    // Transfer token to the msg.sender
    (bool sent) = TokenContract.transfer(msg.sender, amountToBuy);
    
    require(sent, "Failed to transfer NETU21 token to user");
    BalanceOf[msg.sender] += amountToBuy;
    BalanceOf[address(this)] -= amountToBuy;

    // emit the event
    emit BuyTokens(msg.sender, msg.value, amountToBuy);

    return amountToBuy;
  }

  /**
  * @notice Allow users to sell tokens for ETH
  */
  /*
  function sell(uint256 tokenAmountToSell) external {
    // Check that the requested amount of tokens to sell is more than 0
    require(tokenAmountToSell > 0, "Specify an amount of NETU21 tokens greater than zero");

    // Check that the user's token balance is enough to do the swap
    //uint256 userBalance = yourToken.balanceOf(msg.sender);
    uint256 userBalance = balanceOf(msg.sender);
    require(userBalance >= tokenAmountToSell, "Your balance is lower than the amount of NETU21 tokens you want to sell");

    // Check that the Vendor's balance is enough to do the swap
    uint256 amountOfETHToTransfer = tokenAmountToSell / tokensPerMATIC;
    uint256 ownerETHBalance = address(this).balance;
    require(ownerETHBalance >= amountOfETHToTransfer, "Vendor has not enough funds to accept the sell request");

    //(bool sent) = yourToken.transferFrom(msg.sender, address(this), tokenAmountToSell);
    bool sent = true;
    TokenContract.safeTransferFrom(msg.sender, address(this), 0, tokenAmountToSell, "");
    require(sent, "Failed to transfer tokens from user to vendor");
    BalanceOf[msg.sender] = BalanceOf[msg.sender] - tokenAmountToSell;
    BalanceOf[address(this)] = BalanceOf[address(this)] + tokenAmountToSell;

    (sent,) = msg.sender.call{value: amountOfETHToTransfer}("");
    require(sent, "Failed to send MATIC to the user");
  }
*/
  /**
  * @notice Allow the owner of the contract to withdraw ETH
  */
  function withdraw() public onlyOwner {
    uint256 ownerBalance = address(this).balance;
    require(ownerBalance > 0, "Owner has not balance to withdraw");

    (bool sent,) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to send user balance back to the owner");
  }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /* -- MLM Functions -- */
    function setUpLine(address new_acc, address father) internal virtual returns (bool) {
        if (usUp[new_acc].u01 == address(0)) {
            usUp[new_acc].u01 = father;
            usUp[new_acc].u02 = usUp[father].u01;
            usUp[new_acc].u03 = usUp[father].u02;
            usUp[new_acc].u04 = usUp[father].u03;
            usUp[new_acc].u05 = usUp[father].u04;
            usUp[new_acc].u06 = usUp[father].u05;
            usUp[new_acc].u07 = usUp[father].u06;
            usUp[new_acc].u08 = usUp[father].u07;
            usUp[new_acc].u09 = usUp[father].u08;
            usUp[new_acc].u10 = usUp[father].u09;
            usUp[new_acc].u11 = usUp[father].u10;
            usUp[new_acc].u12 = usUp[father].u11;
            usUp[new_acc].u13 = usUp[father].u12;
            usUp[new_acc].u14 = usUp[father].u13;
            usUp[new_acc].u15 = usUp[father].u14;
            usUp[new_acc].u16 = usUp[father].u15;
            usUp[new_acc].u17 = usUp[father].u16;
            usUp[new_acc].u18 = usUp[father].u17;
            usUp[new_acc].u19 = usUp[father].u18;
            usUp[new_acc].u20 = usUp[father].u19;
            usUp[new_acc].u21 = usUp[father].u20;
            lastWalletWithoutNetwork = new_acc;
            return true;
        }
        return false;
    }

    
    function getUpLine(address from, uint level) public view returns (address){
        
        if (level == 1){
            return usUp[from].u01;
        }
        if (level == 2){
            return usUp[from].u02;
        }
        if (level == 3){
            return usUp[from].u03;
        }
        if (level == 4){
            return usUp[from].u04;
        }
        if (level == 5){
            return usUp[from].u05;
        }
        if (level == 6){
            return usUp[from].u06;
        }
        if (level == 7){
            return usUp[from].u07;
        }
        if (level == 8){
            return usUp[from].u08;
        }
        if (level == 9){
            return usUp[from].u09;
        }
        if (level == 10){
            return usUp[from].u10;
        }
        if (level == 11){
            return usUp[from].u11;
        }
        if (level == 12){
            return usUp[from].u12;
        }
        if (level == 13){
            return usUp[from].u13;
        }
        if (level == 14){
            return usUp[from].u14;
        }
        if (level == 15){
            return usUp[from].u15;
        }
        if (level == 16){
            return usUp[from].u16;
        }
        if (level == 17){
            return usUp[from].u17;
        }
        if (level == 18){
            return usUp[from].u18;
        }
        if (level == 19){
            return usUp[from].u19;
        }
        if (level == 20){
            return usUp[from].u20;
        }
        if (level == 21){
            return usUp[from].u21;
        }
        return address(0);
    }

    /* -- Util Functions -- */
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bStr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bStr[k] = b1;
            _i /= 10;
        }
        return string(bStr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}