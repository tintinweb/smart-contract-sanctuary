/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
// Developed by CryptoPuff

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

struct MarketLot {
        uint256 tokenId;
        bool isForSale;
        address owner;
        uint256 price;
}

struct MarketBid {
    address seller;
    uint256 tokenId;
    address bidder;
    uint256 price;
}


library EnumerableSetMarket {
    struct MarketLotSet {
        MarketLot[] _values;
        mapping (uint256 => uint256) _indexes;
    }

    function add(MarketLotSet storage set, MarketLot memory value) internal returns (bool) {
        if (contains(set, value.tokenId)) {
            return false;
        }

        set._values.push(value);
        set._indexes[value.tokenId] = set._values.length;
        return true;
    }


    function remove(MarketLotSet storage set, uint256 _tokenId) internal returns (bool) {
        uint256 valueIndex = set._indexes[_tokenId];

        if (valueIndex != 0) { 
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            MarketLot memory lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue.tokenId] = toDeleteIndex + 1; // All indexes are 1-based
            set._values.pop();
            delete set._indexes[_tokenId];

            return true;
        } 
        else {
            return false;
        }
    }

    function contains(MarketLotSet storage set, uint256 _tokenId) internal view returns (bool) {
        return set._indexes[_tokenId] != 0;
    }

    function length(MarketLotSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(MarketLotSet storage set, uint256 index) internal view returns (MarketLot memory) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    function values(MarketLotSet storage set) internal view returns (MarketLot[] memory) {
        return set._values;
    }

    function getTokenLot(MarketLotSet storage set, uint256 tokenId) internal view returns(MarketLot memory) {
        uint256 index = set._indexes[tokenId];
        return set._values[index];
    }

    function setPrice(MarketLotSet storage set, uint256 tokenId, uint256 price) internal {
        uint256 i = set._indexes[tokenId];
        set._values[i].price = price;
    }

    function isForSale(MarketLotSet storage set, uint256 tokenId) internal view returns (bool) {
        uint256 index = set._indexes[tokenId];
        if (index == 0) {
            return false;
        }
        return set._values[index].isForSale;
    }

    function getPrice(MarketLotSet storage set, uint256 tokenId) internal view returns (uint256) {
        uint256 index = set._indexes[tokenId];
        if (index == 0) {
            return 0;
        }
        return set._values[index].price;
    }
}

library Errors {
    string constant NOT_OWNER = 'Only owner';
    string constant INVALID_TOKEN_ID = 'Invalid token id';
    string constant MINTING_DISABLED = 'Minting disabled';
    string constant TRANSFER_NOT_APPROVED = 'Transfer not approved by owner';
    string constant OPERATION_NOT_APPROVED = 'Operations with token not approved';
    string constant ZERO_ADDRESS = 'Address can not be 0x0';
    string constant ALL_MINTED = "All tokens are minted";
    string constant NOT_ENOUGH_TRX = "Insufficient funds to purchase";
    string constant WRONG_FROM = "The 'from' address does not own the token";
    string constant MARKET_MINIMUM_PRICE = "Market price cannot be lowet then 'minimumMarketPrice'";
    string constant MARKET_ALREADY_ON_SALE = 'The token is already up for sale';
    string constant MARKET_NOT_FOR_SALE = 'The token is not for sale';
    string constant REENTRANCY_LOCKED = 'Reentrancy is locked';
    string constant MARKET_IS_LOCKED = 'Market is locked';
    string constant MARKET_DISABLED = 'Market is disabled';
    string constant MARKET_NO_BID_AVAILABLE = 'No bid available for token';
    string constant MARKET_NO_OWN_BUY = 'Cannot buy token from self';
    string constant MARKET_TOO_LOW_BID = 'Cannot bid less than previous bidder';
    string constant MARKET_CANNOT_SET_PRICE_LOWER_THAN_BID = 'Cannot set price lower than bid';
    string constant RANDOM_FAIL = 'Random generation failed';
    string constant NOTHING_ON_SALE = 'There are no tokens on sale';
    string constant INDEX_INCORRECT = 'Incorrect index for array';
}

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
    
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }
}


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


    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
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


contract HIDDENWARRIORS is ITRC721, ITRC165, ITRC721Metadata, ITRC721Enumerable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSetMarket for EnumerableSetMarket.MarketLotSet;

    string internal _name = "HiddenWarriors";
    string internal _symbol = "HWARS";

    uint256 internal totalMinted = 0;

    uint256 public constant MINTING_LIMIT = 10000;

    uint256 public mintingPrice = 1000000000000000000;
    uint256 public minimumMarketPrice = 1000000000000000000;

    uint256 internal devComissionNom = 1;
    uint256 internal devComissionDenom = 100;

    uint256 internal DENOMINATOR_FOR_FREE_HWAR = 500;

    //Service:
    bool internal isReentrancyLock = false;
    bool internal isMarketLocked = false;
    address internal contractOwner;
    address internal addressZero = address(0);
    uint8 constant MAXIMUM_MINT_LIMIT = 20;

    // Equals to `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `ITRC721Receiver(0).onTRC721Received.selector`
    bytes4 internal constant MAGIC_ON_TRC721_RECEIVED = 0x150b7a02;

    // Random
    uint256 internal nonce = 0;
    uint256[MINTING_LIMIT] internal indices;

    // Supported interfaces
    mapping(bytes4 => bool) internal supportedInterfaces;

    // storage
    mapping (uint256 => address) internal tokenToOwner;
    mapping (address => EnumerableSet.UintSet) internal ownerToTokensSet;
    mapping (uint256 => address) internal tokenToApproval;

    mapping (address => mapping (address => bool)) internal ownerToOperators;

    bool public isMintingEnabled = false;
    bool public isMarketEnabled = false;
    
    EnumerableSetMarket.MarketLotSet internal tokensOnSale;
    mapping(uint256 => MarketBid) public tokensBid;

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // TRC165
        supportedInterfaces[0x80ac58cd] = true; // TRC721
        supportedInterfaces[0x780e9d63] = true; // TRC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // TRC721 Metadata

        contractOwner = msg.sender;
    }

    /************************* */
    //                             ITRC721Metadata: 

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) external pure override returns (string memory) {
        return string(abi.encodePacked("https://sudeepojha.com.np/blockchain/api/v1/getjson/", Utils.uintToString(_tokenId)));
    }

    /************************* */
    //                             Enumerable: 

    function totalSupply() public view override returns(uint256) {
        return totalMinted;
    }

    function tokenByIndex(uint256 _index) external pure override returns (uint256) {
        require(_index >= 0 && _index < MINTING_LIMIT);
        return _index + 1;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view override returns (uint256 _tokenId) {
        require(_index < ownerToTokensSet[_owner].values().length, Errors.INDEX_INCORRECT);
        return ownerToTokensSet[_owner].values()[_index];
    }

    function getNotMintedAmount() external view returns(uint256) {
        return MINTING_LIMIT - totalMinted;
    }

    /************************* */
    //                             ITRC165: 
    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        return supportedInterfaces[_interfaceID];
    }


    /************************* */
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


    /************************* */

    function getUserTokens(address _user) external view returns (uint256[] memory) {
        return ownerToTokensSet[_user].values();
    }

    /************************* */
    //                             Mint:
    function mint() external payable reentrancyGuard mintingEnabled returns (uint256[MAXIMUM_MINT_LIMIT] memory) {
        require(msg.value >= mintingPrice, Errors.NOT_ENOUGH_TRX);
        uint256[MAXIMUM_MINT_LIMIT] memory mintedIndexes;
        uint256 amountOfHIDDENWARRIORSToMint = Utils.min(MAXIMUM_MINT_LIMIT, Utils.min(msg.value/mintingPrice, (MINTING_LIMIT - totalMinted)));
        uint256 totalMintPrice = mintingPrice * amountOfHIDDENWARRIORSToMint;
        
        if (msg.value > totalMintPrice) {
            payable(msg.sender).transfer(msg.value - totalMintPrice);
        }

        for (uint hwarIndex = 0; hwarIndex < amountOfHIDDENWARRIORSToMint; hwarIndex++) {
            mintedIndexes[hwarIndex] = _mint(msg.sender);
            if (totalMinted % DENOMINATOR_FOR_FREE_HWAR == 0) {
                payable(msg.sender).transfer(mintingPrice);
            }
        }
        
        return mintedIndexes;
    }

    /************************* */


    /************************* */
    //                             Internal functions:

    function _mint(address _to) internal notZeroAddress(_to) returns (uint256 _mintedTokenId) {
        require(totalMinted < MINTING_LIMIT, Errors.ALL_MINTED);
        uint randomId = _generateRandomId();
        totalMinted++;
        
        _addToken(_to, randomId);

        emit Mint(randomId, msg.sender, _to);
        emit Transfer(addressZero, _to, randomId);

        return randomId;
    }
    function _addToken(address _to, uint256 _tokenId) private notZeroAddress(_to) {
        tokenToOwner[_tokenId] = _to;
        ownerToTokensSet[_to].add(_tokenId);
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        require(tokenToOwner[_tokenId] == _from, Errors.WRONG_FROM);
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
            require(retval == MAGIC_ON_TRC721_RECEIVED);
        }
    }

    /************************* */



    /************************* */
    //                             Admin functions: 

    function _enableMinting() external onlyContractOwner {
        if (!isMintingEnabled) {
            isMintingEnabled = true;
            emit MintingEnabled();
        }
    }

    function _disableMinting() external onlyContractOwner {
        if (isMintingEnabled) {
            isMintingEnabled = false;
            emit MintingDisabled();
        }
    }

    function _setMintingPrice(uint256 newPrice) external onlyContractOwner {
        mintingPrice = newPrice;
    }

    function _setMinimumMarketPrice(uint256 newPrice) external onlyContractOwner marketLock {
        require(newPrice <= minimumMarketPrice, "The minimum price cannot be increased");
        require(newPrice > 0, "Price must be greater than zero");
        minimumMarketPrice = newPrice;
    }

    function claimBNB(uint256 amount) external onlyContractOwner {
        payable(contractOwner).transfer(amount);
    }

    function _setDevComission(uint256 newNom, uint256 newDenom) external onlyContractOwner {
        require(newDenom != 0);
        devComissionNom = newNom;
        devComissionDenom = newDenom;
    }


    function withdraw() external onlyContractOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    /************************* */




    /************************* */
    //                             Service:
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }


    function _generateRandomId() private returns (uint256) {
        uint256 totalSize = MINTING_LIMIT - totalMinted;
        uint256 index = uint256(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint256 value = 0;

        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            indices[index] = totalSize - 1;    // Array position not initialized, so use position
        } else { 
            indices[index] = indices[totalSize - 1];   // Array position holds a value so use that
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value + 1;
    }

    function getDevComission() external view returns(uint256 nominator, uint256 denominator) {
        return (devComissionNom, devComissionDenom);
    }

    /************************* */



    /************************* */
    //                             Modifiers: 

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, Errors.NOT_OWNER);
        _;
    }

    modifier reentrancyGuard {
        if (isReentrancyLock) {
            require(!isReentrancyLock, Errors.REENTRANCY_LOCKED);
        }
        isReentrancyLock = true;
        _;
        isReentrancyLock = false;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(tokenToOwner[_tokenId] != addressZero, Errors.INVALID_TOKEN_ID);
        _;
    }

    modifier mintingEnabled() {
        require(isMintingEnabled, Errors.MINTING_DISABLED);
        _;
    }

    modifier transferApproved(uint256 _tokenId) {
        address tokenOwner = tokenToOwner[_tokenId];
        require(
            tokenOwner == msg.sender  || 
            tokenToApproval[_tokenId] == msg.sender || 
            ((ownerToOperators[tokenOwner][msg.sender] == true) && tokenOwner != addressZero), 
            Errors.TRANSFER_NOT_APPROVED
        );
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = tokenToOwner[_tokenId];
        require(
            tokenOwner == msg.sender || 
            ((ownerToOperators[tokenOwner][msg.sender] == true) && tokenOwner != addressZero), 
            Errors.OPERATION_NOT_APPROVED
        );
        _;
    }

    modifier notZeroAddress(address _addr) {
        require(_addr != addressZero, Errors.ZERO_ADDRESS);
        _;
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

    /************************* */



    /************************* */
    //                             Events: 
    // NFT minted
    event Mint(uint indexed tokenId, address indexed mintedBy, address indexed mintedTo);
     // TRX is deposited into the contract.
    //TRX is withdrawn from the contract.
    event Withdraw(address indexed account, uint amount);

    event TokenOnSale(uint256 indexed _tokenId, address indexed _owner, uint256 _price);
    event TokenNotOnSale(uint256 indexed _tokenId, address indexed _owner);
    event TokenMarketPriceChange(uint256 indexed _tokenId, address indexed _owner, uint256 _oldPrice, uint256 _newPrice);

    event MintingEnabled();
    event MintingDisabled();
}