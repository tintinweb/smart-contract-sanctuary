//SourceUnit: _Release.sol

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
// -
// developed by 4erpakoff



library EnumerableSet {
    struct UintSet {
        uint256[] _values;
        mapping (uint256 => uint256) _indexes;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        if (contains(set, value)) {
            return false;
        }

        set._values.push(value);
        set._indexes[value] = set._values.length;
        return true;
    }


    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            uint256 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            set._values.pop();
            delete set._indexes[value];

            return true;
        } 
        else {
            return false;
        }
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    function values(UintSet storage set) internal view returns (uint256[] memory _vals) {
        return set._values;
    }
}


    /*************************************************************************** */
    /*************************************************************************** */
    /*************************************************************************** */


library Utils {
    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}




    /*************************************************************************** */
    /*************************************************************************** */
    /*************************************************************************** */


    

interface ITRC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in TRC-165
    /// @dev Interface identification is specified in TRC-165. This function
    ///  uses less than 30,000 energy.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

}

interface ITRC721 {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;
    function getApproved(uint256 _tokenId) external view returns (address);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);


    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

/**
 * Interface for verifying ownership during Community Grant.
 */
interface ITRC721TokenReceiver {
    function onTRC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

interface ITRC721Metadata {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    //Returns the URI of the external file corresponding to ‘_tokenId’. External resource files need to include names, descriptions and pictures. 
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}


interface ITRC721Enumerable {
    //Return the total supply of NFT
    function totalSupply() external view returns (uint256);

    //Return the corresponding ‘tokenId’ through ‘_index’
    function tokenByIndex(uint256 _index) external view returns (uint256);

     //Return the ‘tokenId’ corresponding to the index in the NFT list owned by the ‘_owner'
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}



interface ITRC721Burnable{
    function burn(uint256 _tokenId) external;
}


    /*************************************************************************** */
    /*************************************************************************** */
    /*************************************************************************** */


library Errors {
    string constant NOT_OWNER = "Only owner";
    string constant INVALID_TOKEN_ID = "Invalid token id";
    string constant MINTING_DISABLED = "Minting disabled";
    string constant TRANSFER_NOT_APPROVED = "Transfer not approved";
    string constant OPERATION_NOT_APPROVED = "Operations with token not approved";
    string constant ZERO_ADDRESS = "Address can not be 0x0";
    string constant ALL_MINTED = "All tokens are minted";
    string constant NOT_ENOUGH_TRX = "Insufficient funds to purchase";
    string constant WRONG_FROM = "The 'from' address does not own the token";
    string constant MARKET_MINIMUM_PRICE = "Market price cannot be lowet then 'minimumMarketPrice'";
    string constant MARKET_ALREADY_ON_SALE = "The token is already up for sale";
    string constant MARKET_NOT_FOR_SALE = "The token is not for sale";
    // string constant REENTRANCY_LOCKED = 'Reentrancy is locked';
    string constant MARKET_IS_LOCKED = "Market is locked";
    string constant MARKET_DISABLED = "Market is disabled";
    string constant MIGRATION_DISABLED = "Migration is disabled";
    string constant RANDOM_FAIL = "Random generation failed";

    string constant BID_NOT_EXISTS = "Bid does not exist";
    string constant BID_CHEAP = "There is a bid with a higher price";
    string constant BID_OWNER = "Token owner cannot be a bidder";
    string constant NOT_BIDDER = "Only bidder can operate";
    string constant BID_ACCEPT_OWNER = "Only token owner can accepts bid";

    string constant TOKEN_NOT_INITED = "Token contract is not inited";
    string constant MIGRATION_NOT_APPROVED = "Token transfer not approved";
    string constant MIGRATION_PERMISSIONS = "Only tokenOwner or admins can migrate";
}

    /*************************************************************************** */
    /*************************************************************************** */
    /*************************************************************************** */


contract TRC165 is ITRC165 {
    // Supported interfaces
    mapping(bytes4 => bool) internal supportedInterfaces;

    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        return supportedInterfaces[_interfaceID];
    }
}



    /*************************************************************************** */
    /*************************************************************************** */
    /*************************************************************************** */



contract Owned {
    address public contractOwner;

    constructor() { 
        contractOwner = payable(msg.sender); 
    }

    function _transferOwnership(address newOwner) public virtual onlyContractOwner {
        require(newOwner != address(0), Errors.ZERO_ADDRESS);
        contractOwner = newOwner;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, Errors.NOT_OWNER);
        _;
    }
}


contract AccessController is Owned {
    mapping(address => bool) public admins;
    mapping(address => bool) public tokenClaimers;

    constructor() {
        admins[msg.sender] = true;
        tokenClaimers[msg.sender] = true;
    }

    function _transferOwnership(address newOwner) public override(Owned) {
        super._transferOwnership(newOwner);
    }


    function _setAdmin(address _user, bool _isAdmin) external onlyContractOwner {
        admins[_user] = _isAdmin;
        require( admins[contractOwner], 'Only owner' );
    }

    function _setTokenClaimer(address _user, bool _isTokenCalimer) external onlyContractOwner {
        tokenClaimers[_user] = _isTokenCalimer;
        require( tokenClaimers[contractOwner], 'Only owner' );
    }


    modifier onlyAdmin() {
        require(admins[msg.sender], 'Only admin can operate');
        _;
    }

    modifier onlyTokenClaimer() {
        require(tokenClaimers[msg.sender], 'Only Token Claimer can operate');
        _;
    }
}

    /*************************************************************************** */
    /*************************************************************************** */
    /*************************************************************************** */
    /*************************************************************************** */




contract TRC721Metadata is AccessController, ITRC721Metadata {
    string private tokenName;
    string private tokenSymbol;
    string private uri = '';


    constructor(string memory _name, string memory _symbol) {
        tokenName = _name;
        tokenSymbol = _symbol;
    }


    function name() external view override returns (string memory) {
        return tokenName;
    }

    function symbol() external view override returns (string memory) {
        return tokenSymbol;
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(uri, Utils.uintToString(_tokenId)));
    }

    function _setTokenURI(string memory _uri) external onlyAdmin {
        uri = _uri;
    }
}

    /*************************************************************************** */
    /*************************************************************************** */
    /*************************************************************************** */


contract FeeController is AccessController {
    address public feeReciever;

    uint256 private devFeeNom = 1;
    uint256 private devFeeDenom = 100;

    constructor() {
        feeReciever = msg.sender;
    }

    function _setFeeReciever(address _reciever) external onlyAdmin {
        feeReciever = _reciever;
    }

    function getFee() external view returns(uint256 nominator, uint256 denominator) {
        return (devFeeNom, devFeeDenom);
    }

    function _setFee(uint256 newNom, uint256 newDenom) external onlyAdmin {
        devFeeNom = newNom;
        devFeeDenom = newDenom;
    }

    function calculateAndSendFee(uint256 _value) internal returns (uint256 remainingValue) {
        uint256 fee = _value * devFeeNom / devFeeDenom;
        if (fee > 0 && feeReciever != address(this))
            payable(feeReciever).transfer(fee);

        return _value - fee;
    } 
}



contract MarketController is AccessController {
    uint256 public minimumMarketPrice = 5000000000;
    uint256 public minimumBidPrice =    1500000000;

    bool public isMarketEnabled = false;
    bool internal isMarketLocked = false;


    function _setMinimumMarketPrice(uint256 newPrice) external onlyAdmin marketLock {
        // require(newPrice <= minimumMarketPrice, "The minimum price cannot be increased");
        require(newPrice > 0, "Price must be greater than zero");
        minimumMarketPrice = newPrice;
    }


    function _setMinimumBidPrice(uint256 newPrice) external onlyAdmin marketLock {
        // require(newPrice <= minimumMarketPrice, "The minimum price cannot be increased");
        require(newPrice > 0, "Price must be greater than zero");
        minimumBidPrice = newPrice;
    }



    function _enableMarket() external onlyAdmin {
        if (!isMarketEnabled) {
            isMarketEnabled = true;
            emit MarketEnabled();
        }
    }

    function _disableMarket() external onlyAdmin {
        if (isMarketEnabled) {
            isMarketEnabled = false;
            emit MarketDisabled();
        }
    }


    modifier marketLock {
        if (isMarketLocked) {
            require(!isMarketLocked, Errors.MARKET_IS_LOCKED);
        }
        isMarketLocked = true;
        _;
        isMarketLocked = false;
    }

    modifier marketEnabled {
        require(isMarketEnabled, Errors.MARKET_DISABLED);
        _;
    }



    event MarketEnabled();
    event MarketDisabled();
}



abstract contract MarketLots is MarketController  {
    using EnumerableSet for EnumerableSet.UintSet;

    struct MarketLot {
        uint256 tokenId;
        bool isForSale;
        address owner;
        uint256 price;
    }
    
    EnumerableSet.UintSet internal tokensOnSale;
    mapping (uint256 => MarketLot) public marketLots;  // tokenId -> Token information


    function buyFromMarket(uint256 _tokenId, address _to) external payable virtual
    {
        _tokenId; _to;
        revert();
    }


    function putOnMarket(uint256 _tokenId, uint256 price) external virtual {
        _tokenId; price;
        revert();
    }

    function changeLotPrice(uint256 _tokenId, uint256 newPrice) external virtual {
        _tokenId; newPrice;
        revert();
    }

    function withdrawFromMarket(uint256 _tokenId) external virtual {
        _tokenId;
        revert();
    }



    function getMarketLotInfo(uint256 _tokenId) external view returns(MarketLot memory) {
        require(marketLots[_tokenId].isForSale, Errors.MARKET_NOT_FOR_SALE);

        return marketLots[_tokenId];
    }

    function getAllTokensOnSale() external view returns(uint256[] memory) {
        return tokensOnSale.values();
    }

    function checkTokenOnSale(uint256 _tokenId) external view returns (bool) {
        return marketLots[_tokenId].isForSale;
    }


    event MarketTrade(uint256 indexed _tokenId, address indexed _from, address indexed _to, address buyer, uint256 _price);

    event TokenOnSale(uint256 indexed _tokenId, address indexed _owner, uint256 _price);
    event TokenNotOnSale(uint256 indexed _tokenId, address indexed _owner);
    event TokenMarketPriceChange(uint256 indexed _tokenId, address indexed _owner, uint256 _oldPrice, uint256 _newPrice);
}




abstract contract MarketBids is MarketController {
    using EnumerableSet for EnumerableSet.UintSet;

    struct MarketBid {
        bool exists;
        uint256 tokenId;
        address bidder;
        uint256 value;
    }

    mapping (uint256 => MarketBid) public marketBids;
    EnumerableSet.UintSet internal tokensBidsSet;



    function placeBid(uint256) external payable virtual {
        revert();
    }

    function withdrawBid(uint256) external virtual {
        revert();
    }

    function acceptBid(uint256) external virtual {
        revert();
    }



    function getAllTokensWithBids() external view returns (uint256[] memory) {
        return tokensBidsSet.values();
    }

    function getBidPrice(uint256 _tokenId) external view returns (uint256) {
        return marketBids[_tokenId].value;
    }

    function checkBidExists(uint256 _tokenId) external view returns (bool) {
        return marketBids[_tokenId].exists;
    }




    function _safeCancelBidWithRefund(uint256 _tokenId) internal {
        if (marketBids[_tokenId].exists) {
            payable(marketBids[_tokenId].bidder).transfer(marketBids[_tokenId].value);
            _deleteBid(_tokenId);
        }
    }

    function _deleteBid(uint256 _tokenId) internal {
        delete marketBids[_tokenId];
        tokensBidsSet.remove(_tokenId);
    }

    function _createNewBid(uint256 _tokenId) internal returns(MarketBid memory) {
        marketBids[_tokenId] = MarketBid(true, _tokenId, msg.sender, msg.value);
        tokensBidsSet.add(_tokenId);
    
        return marketBids[_tokenId];
    }

    modifier bidExists(uint256 _tokenId) {
        require(marketBids[_tokenId].exists && marketBids[_tokenId].value > 0, Errors.BID_NOT_EXISTS);
        _;
    }

    modifier onlyBidder(uint256 _tokenId) {
        require(marketBids[_tokenId].bidder == msg.sender, Errors.NOT_BIDDER);
        _;
    }


    event BidPlaced(uint256 indexed _tokenId, uint256 _value, address indexed _bidder);
    event BidWithdrawed(uint256 indexed _tokenId, uint256 _value, address indexed _bidder);
    event BidAccepted(uint256 indexed _tokenId, uint256 _value, address _from, address _to);
}



abstract contract MigrationController is AccessController {
    uint16 private totalMapped = 0;
    uint16 private needToMigrate;

    bool private isMigrationsEnabled = false;
    address internal oldTokensReciever;
    ITRC721 public oldTokenContract = ITRC721(address(0));

    mapping(uint16 => uint16) public oldIdToNewId;      // *id in old contract* => *id in new contract*
    mapping(uint16 => bool) internal suppliedNewTokens;   // newTokenId => isSupplied

    uint16 internal oldZeroTokenId = 0;
    

    constructor(uint16 _needToMigrate) {
        // oldTokensReciever = address(this);
        oldTokensReciever = msg.sender;
        needToMigrate = _needToMigrate;
    }


    function migrateToken(uint256 oldTokenId) external virtual returns (bool) {
        oldTokenId;
        revert();
    }


    function _enableMigration() external onlyAdmin {
        require(totalMapped == needToMigrate, "Migration mapping not fullfilled");
        require(address(oldTokenContract) != address(0), 'Token contract not inited');

        if (!isMigrationsEnabled) {
            isMigrationsEnabled = true;
        }
    }

    function _disableMigration() external onlyAdmin {
        if (isMigrationsEnabled) {
            isMigrationsEnabled = false;
        }
    }

    function _setTokenContract(address _tokenContract) external onlyAdmin {
        require( address(oldTokenContract) == address(0), 'Token contract already inited');
        oldTokenContract = ITRC721(_tokenContract);
    }

    // index of array == id in new contract
    function _setMigrationMapping(uint16[] memory _ids) external onlyAdmin {
        require(totalMapped + _ids.length <= needToMigrate);
        require (_ids.length > 0);

        if (oldZeroTokenId == 0) {
            oldZeroTokenId = _ids[0];
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            if ( _ids[i] < 20000 ) // in Russian it is called a "костыль"
                oldIdToNewId[ _ids[i] ] = totalMapped;
            totalMapped++;
        }
    }

    function _setTotalMapped(uint16 total) external onlyAdmin {
        totalMapped = total;
    }


    modifier migrationEnabled {
        require(isMigrationsEnabled, Errors.MIGRATION_DISABLED);
        require(address(oldTokenContract) != address(0), Errors.TOKEN_NOT_INITED);
        _;
    }


    event TokenMigration(uint indexed _oldTokenId, uint indexed _newTokenId, address _by, address _to);
    event TokenMigrationRejected(uint indexed _oldTokenId, uint indexed _newTokenId, address _by, address indexed _to);
}



    /*************************************************************************** */
    /*************************************************************************** */
    /*************************************************************************** */
    /*************************************************************************** */






contract TApes is AccessController, 
                  FeeController, 
                  MarketLots,
                  MarketBids,
                  MigrationController,
                  TRC165, 
                  ITRC721, 
                  TRC721Metadata, 
                  ITRC721Enumerable, 
                  ITRC721Burnable 
{
    using EnumerableSet for EnumerableSet.UintSet;


    uint16 public constant totalMinted = 10001;
    uint16 public totalMigrated = 0;
    uint16 public totalBurned = 0;

    // storage
    mapping (uint256 => address) internal tokenToOwner;
    mapping (address => EnumerableSet.UintSet) internal ownerToTokensSet;
    mapping (uint256 => address) internal tokenToApproval;

    mapping (address => mapping (address => bool)) internal ownerToOperators;


    // Equals to `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `ITRC721Receiver(0).onTRC721Received.selector`
    bytes4 internal magicOnTRC721Recieved = 0x150b7a02;


    constructor(string memory _name, string memory _symbol) 
        TRC721Metadata(_name, _symbol)
        MigrationController(totalMinted)
    {
        supportedInterfaces[0x01ffc9a7] = true; // TRC165
        supportedInterfaces[0x80ac58cd] = true; // TRC721
        supportedInterfaces[0x780e9d63] = true; // TRC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // TRC721 Metadata
    }



    /*************************************************************************** */
    //                             Enumerable: 

    uint8 private _tsm = 0;
    function totalSupply() public view override returns(uint256) {
        if (_tsm == 1) {
            return totalMigrated - totalBurned;
        } else if (_tsm == 2) {
            return totalMinted;
        }

        return totalMigrated;
    }

    function _setTotalSupplyMode(uint8 mode) external onlyAdmin {
        _tsm = mode;
    }


    function tokenByIndex(uint256 _index) external pure override returns (uint256) {
        require(_index >= 0 && _index < totalMinted);
        return _index;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view override returns (uint256 _tokenId) {
        require(_index < ownerToTokensSet[_owner].values().length);
        return ownerToTokensSet[_owner].values()[_index];
    }


    /*************************************************************************** */
    //                             TRC-721: 

    function balanceOf(address _owner) external view override returns (uint256) {
        return ownerToTokensSet[_owner].values().length;
    }

    function ownerOf(uint256 _tokenId) external view override returns (address) {
        return tokenToOwner[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) 
        external override payable 
    {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) 
        external payable override
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) external payable override
        transferApproved(_tokenId)
        validTokenId(_tokenId) 
        notZeroAddress(_to)
    {
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override payable
        validTokenId(_tokenId)
        canOperate(_tokenId)
    {
        address tokenOwner = tokenToOwner[_tokenId];
        if (_approved != tokenOwner) {
            tokenToApproval[_tokenId] = _approved;
            emit Approval(tokenOwner, _approved, _tokenId);
        }
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view override validTokenId(_tokenId)
        returns (address) 
    {
        return tokenToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    // Burnable
    function burn(uint256 _tokenId) external override {
        _burn(_tokenId);
    }


    /*************************************************************************** */

    function getUserTokens(address _user) external view returns (uint256[] memory) {
        return ownerToTokensSet[_user].values();
    }


    function migrateToken(uint256 oldTokenId) external override
        migrationEnabled
        returns (bool isMigrated)
    {
        address tokenOwner = oldTokenContract.ownerOf(oldTokenId);
        require(tokenOwner != address(0), Errors.INVALID_TOKEN_ID);

        require(tokenOwner == msg.sender || admins[msg.sender], Errors.MIGRATION_PERMISSIONS);

        bool isApproved = oldTokenContract.isApprovedForAll(tokenOwner, address(this));
        require(isApproved, Errors.MIGRATION_NOT_APPROVED);

        oldTokenContract.transferFrom(tokenOwner, oldTokensReciever, oldTokenId);

        uint16 nt = oldIdToNewId[uint16(oldTokenId)];

        bool result = false;
        if ( !suppliedNewTokens[nt] && (nt > 0 || (nt == 0 && oldZeroTokenId == oldTokenId)))
        {
            totalMigrated++;
            suppliedNewTokens[nt] = true;
            _addToken(tokenOwner, nt);
            emit TokenMigration(oldTokenId, nt, msg.sender, tokenOwner);
            emit Transfer(address(0), tokenOwner, nt); 
            result = true;
        } 
        else {
            emit TokenMigrationRejected(oldTokenId, nt, msg.sender, tokenOwner);
            result = false;
        }

        return result;
    }

    function isBurned(uint256 _tokenId) external view returns(bool) {
        require(_tokenId < totalMinted, Errors.INVALID_TOKEN_ID);
        return suppliedNewTokens[uint16(_tokenId)] && tokenToOwner[_tokenId] == address(0);
    }




    /*************************************************************************** */
    //                             Market:

    function buyFromMarket(uint256 _tokenId, address _to) external payable override
        notZeroAddress(_to) 
        marketEnabled 
        marketLock
    {
        require(marketLots[_tokenId].isForSale, Errors.MARKET_NOT_FOR_SALE);

        uint256 _price = marketLots[_tokenId].price;
        require(msg.value >= _price, Errors.NOT_ENOUGH_TRX);

        _buyFromMarket(_tokenId, _to);
    }


    function _buyFromMarket(uint256 _tokenId, address _to) internal {
        uint256 _price = marketLots[_tokenId].price;

        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }

        uint256 remainingValue = calculateAndSendFee(_price);
        payable(tokenToOwner[_tokenId]).transfer(remainingValue);
        
        MarketBid memory bid = marketBids[_tokenId];
        if (bid.exists && bid.bidder == msg.sender) {
            _withdrawBidWithEvent(_tokenId);
        }

        emit MarketTrade(_tokenId, tokenToOwner[_tokenId], _to, msg.sender, _price);
        _transfer(tokenToOwner[_tokenId], _to, _tokenId);
    }


    function putOnMarket(uint256 _tokenId, uint256 _price) external override
        transferApproved(_tokenId) 
        marketEnabled 
        marketLock 
    {   
        require(!marketLots[_tokenId].isForSale, Errors.MARKET_ALREADY_ON_SALE);

        MarketBid memory mb = marketBids[_tokenId];
        if (mb.exists && _price <= mb.value) {
            _acceptBid(mb);
            return;
        }

        require(_price >= minimumMarketPrice, Errors.MARKET_MINIMUM_PRICE);

        marketLots[_tokenId] = MarketLot(_tokenId, true, tokenToOwner[_tokenId], _price);
        tokensOnSale.add(_tokenId);

        emit TokenOnSale(_tokenId, tokenToOwner[_tokenId], _price);
    }


    function changeLotPrice(uint256 _tokenId, uint256 newPrice) external override 
        transferApproved(_tokenId) 
        marketEnabled 
        marketLock 
    {
        require(marketLots[_tokenId].isForSale, Errors.MARKET_NOT_FOR_SALE);

        MarketBid memory mb = marketBids[_tokenId];
        if (mb.exists && newPrice <= mb.value) {
            _acceptBid(mb);
            return;
        }

        require(newPrice >= minimumMarketPrice, Errors.MARKET_MINIMUM_PRICE);
        emit TokenMarketPriceChange(_tokenId, tokenToOwner[_tokenId], marketLots[_tokenId].price, newPrice);
        marketLots[_tokenId].price = newPrice;
    }


    function withdrawFromMarket(uint256 _tokenId) external override
        transferApproved(_tokenId) 
        marketLock 
    {
        _removeFromMarket(_tokenId);
    }


    function _removeFromMarket(uint256 _tokenId) internal {
        if (marketLots[_tokenId].isForSale) {
            delete marketLots[_tokenId];
            tokensOnSale.remove(_tokenId);

            emit TokenNotOnSale(_tokenId, tokenToOwner[_tokenId]);
        }
    }

    /*************************************************************************** */



    /*************************************************************************** */
    //                             Bids:
    
    function placeBid(uint256 _tokenId) external payable override
        marketEnabled
        validTokenId(_tokenId) 
        marketLock
    {
        require( msg.sender != tokenToOwner[_tokenId], Errors.BID_OWNER );

        require( msg.value >= minimumBidPrice, Errors.MARKET_MINIMUM_PRICE);
        require( msg.value > marketBids[_tokenId].value, Errors.BID_CHEAP);


        MarketLot memory ml = marketLots[_tokenId];
        if (ml.isForSale && msg.value >= ml.price) {
            _buyFromMarket(_tokenId, msg.sender);
            return;
        }

        _safeCancelBidWithRefund(_tokenId);
        _createNewBid(_tokenId);
        emit BidPlaced(_tokenId, msg.value, msg.sender);
    }


    function withdrawBid(uint256 _tokenId) external override
        bidExists(_tokenId)
        onlyBidder(_tokenId) 
        marketLock  
    {
        _withdrawBidWithEvent(_tokenId);
    }

    function _withdrawBidWithEvent(uint256 _tokenId) internal {
        emit BidWithdrawed(_tokenId, marketBids[_tokenId].value, msg.sender); 
        _safeCancelBidWithRefund(_tokenId);
    }


    function acceptBid(uint256 _tokenId) external override 
        marketEnabled 
        bidExists(_tokenId)
        transferApproved(_tokenId)
        marketLock
    {
        // require(tokenOwner == msg.sender, Errors.BID_ACCEPT_OWNER); -- included in transferApproved modifier
        MarketBid memory b = marketBids[_tokenId];

        if (msg.sender == b.bidder) {
            _withdrawBidWithEvent(_tokenId);
            return;
        }

        _acceptBid(b);
    }


    function _acceptBid(MarketBid memory _bid) internal {
        address tokenOwner = tokenToOwner[_bid.tokenId];
        uint256 res = calculateAndSendFee(_bid.value);
        payable(tokenOwner).transfer(res);

        _transfer(tokenOwner, _bid.bidder, _bid.tokenId);

        emit BidAccepted(_bid.tokenId, _bid.value, tokenOwner, _bid.bidder);
        _deleteBid(_bid.tokenId);
    }

    /*************************************************************************** */


    /*************************************************************************** */
    //                             Internal functions:
    

    function _addToken(address _to, uint256 _tokenId) private notZeroAddress(_to) {
        tokenToOwner[_tokenId] = _to;
        ownerToTokensSet[_to].add(_tokenId);
    }
    

    function _removeToken(address _from, uint256 _tokenId) private {
        if (tokenToOwner[_tokenId] != _from)
            return;
        
        if (tokenToApproval[_tokenId] != address(0))
            delete tokenToApproval[_tokenId];
        
        delete tokenToOwner[_tokenId];
        ownerToTokensSet[_from].remove(_tokenId);

        isMarketLocked = true;
        _removeFromMarket(_tokenId);
        isMarketLocked = false;
    }


    function _transfer(address _from, address _to, uint256 _tokenId) private {
        require(tokenToOwner[_tokenId] == _from, Errors.WRONG_FROM);
        _removeToken(_from, _tokenId);
        _addToken(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private 
        transferApproved(_tokenId) 
        validTokenId(_tokenId) 
        notZeroAddress(_to)
    {
        _transfer(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ITRC721TokenReceiver(_to).onTRC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == magicOnTRC721Recieved);
        }
    }

    function _burn(uint256 _tokenId) private 
        transferApproved(_tokenId) 
        validTokenId(_tokenId) 
    {   
        address owner = tokenToOwner[_tokenId];
        _removeToken(owner, _tokenId);
        totalBurned++;
        emit Transfer(owner, address(0), _tokenId);
    }

    /*************************************************************************** */



    /*************************************************************************** */
    //                             Admin functions: 


    function _withdrawTRX(uint256 amount) external onlyTokenClaimer {
        payable(contractOwner).transfer(amount);
    }

    function _setOnTRC721ReceivedString(bytes4 _str) external onlyAdmin {
        magicOnTRC721Recieved = _str;
    }

    // for old contract fuckups fixes
    function _hardMigrateToken(uint16 _tokenId, address _user) external onlyContractOwner {
        require(tokenToOwner[_tokenId] == address(0));
        require(!suppliedNewTokens[_tokenId]);
        require(_tokenId < totalMinted);
        
        _addToken(_user, _tokenId);

        totalMigrated++;
        suppliedNewTokens[_tokenId] = true;
        emit Transfer(address(0), _user, _tokenId); 
    }

    /*************************************************************************** */




    /*************************************************************************** */
    //                             Service:
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }

    /*************************************************************************** */



    /*************************************************************************** */
    //                             Modifiers: 

    modifier validTokenId(uint256 _tokenId) {
        require(tokenToOwner[_tokenId] != address(0), Errors.INVALID_TOKEN_ID);
        require(_tokenId < totalMinted, Errors.INVALID_TOKEN_ID);
        _;
    }

    modifier transferApproved(uint256 _tokenId) {
        address tokenOwner = tokenToOwner[_tokenId];
        require(
            tokenOwner == msg.sender  || 
            tokenToApproval[_tokenId] == msg.sender || 
            (ownerToOperators[tokenOwner][msg.sender] && tokenOwner != address(0)), 
            Errors.TRANSFER_NOT_APPROVED
        );
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = tokenToOwner[_tokenId];
        require(
            tokenOwner == msg.sender || 
            (ownerToOperators[tokenOwner][msg.sender] && tokenOwner != address(0)), 
            Errors.OPERATION_NOT_APPROVED
        );
        _;
    }

    modifier notZeroAddress(address _addr) {
        require(_addr != address(0), Errors.ZERO_ADDRESS);
        _;
    }
}