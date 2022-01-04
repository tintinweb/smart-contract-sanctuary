/**
 *Submitted for verification at polygonscan.com on 2022-01-03
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


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
        require(set._values.length < index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    function values(UintSet storage set) internal view returns (uint256[] memory _vals) {
        return set._values;
    }
}



library Errors {
    string constant NOT_OWNER = 'Only owner';
    string constant INVALID_TOKEN_ID = 'Invalid token id';
    string constant MINTING_DISABLED = 'Minting disabled';
    string constant MINTING_MAX_MINT_AMOUNT = 'You cannot mint more than 20 NFTs per once';
    string constant MINTING_MIN_MINT_AMOUNT = 'You cannot mint lower than 1 NFT';
    string constant TRANSFER_NOT_APPROVED = 'Transfer not approved by owner';
    string constant OPERATION_NOT_APPROVED = 'Operations with token not approved';
    string constant ZERO_ADDRESS = 'Address can not be 0x0';
    string constant ALL_MINTED = "All tokens are minted";
    string constant EXCEEDS_MAX_SUPPLY = "Exceeds maximum supply. Please try to mint less NFTs.";
    string constant NOT_ENOUGH_MATIC = "Insufficient funds to purchase";
    string constant WRONG_FROM = "The 'from' address does not own the token";
    string constant MARKET_ZERO_PRICE = "Market price cannot be lower than zero";
    string constant MARKET_ALREADY_ON_SALE = 'The token is already up for sale';
    string constant MARKET_NOT_FOR_SALE = 'The token is not for sale';
    string constant REENTRANCY_LOCKED = 'Reentrancy is locked';
    string constant MARKET_IS_LOCKED = 'Market is locked';
    string constant MARKET_DISABLED = 'Market is disabled';
    string constant RANDOM_FAIL = 'Random generation failed';
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
}


interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 energy.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

}

interface IERC721 {
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
interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

interface IERC721Metadata {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    //Returns the URI of the external file corresponding to ‘_tokenId’. External resource files need to include names, descriptions and pictures. 
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}


interface IERC721Enumerable {
    //Return the total supply of NFT
    function totalSupply() external view returns (uint256);

    //Return the corresponding ‘tokenId’ through ‘_index’
    function tokenByIndex(uint256 _index) external view returns (uint256);

     //Return the ‘tokenId’ corresponding to the index in the NFT list owned by the ‘_owner'
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}






contract PolygonApes is IERC721, IERC165, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableSetMarket for EnumerableSetMarket.MarketLotSet;

    string internal _name = "PolygonApes";
    string internal _symbol = "PAPES";
    string private _baseURI;

    uint256 internal totalMinted = 0;

    uint256 public constant MINTING_LIMIT = 10000;

    uint256 public mintingPrice = 0.001 ether;

    // dev comission
    uint256 internal devComissionNom = 4;
    uint256 internal devComissionDenom = 100;

    // devs
    address private dev1 = 0x355caFf4596d8668e98096E9047fB29deA42F1e3;
    address private dev2 = 0x85EbB46D47b3F556df18b8C7443781Ba5ff1D152;
    address private dev3 = 0xe56c571b5b19E21c9e2F2C198d2639d2984C2c48;

    //Service:
    bool internal isReentrancyLock = false;
    bool internal isMarketLocked = false;
    address internal contractOwner;
    address internal addressZero = address(0);

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;


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


    // Market
    struct MarketLot {
        uint256 tokenId;
        bool isForSale;
        address owner;
        uint256 price;
    }
    
    EnumerableSet.UintSet internal tokensOnSale;
    mapping (uint256 => MarketLot) internal marketLots;  // tokenId -> Token information


    constructor(string memory baseURI_) {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata

        contractOwner = msg.sender;

        _setBaseURI(baseURI_);
    }




    /*************************************************************************** */
    //                             IERC721Metadata: 

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, Utils.uintToString(_tokenId), '.json'));
    }

    /*************************************************************************** */
    //                             Enumerable: 

    function totalSupply() public view override returns(uint256) {
        return totalMinted;
    }

    function tokenByIndex(uint256 _index) external pure override returns (uint256) {
        require(_index >= 0 && _index < MINTING_LIMIT);
        return _index;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view override returns (uint256 _tokenId) {
        require(_index < ownerToTokensSet[_owner].values().length);
        return ownerToTokensSet[_owner].values()[_index];
    }

    function getNotMintedAmount() external view returns(uint256) {
        return MINTING_LIMIT - totalMinted;
    }

    /*************************************************************************** */
    //                             IERC165: 
    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        return supportedInterfaces[_interfaceID];
    }


    /*************************************************************************** */
    //                             ERC-721: 

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


    /*************************************************************************** */

    function getUserTokens(address _user) external view returns (uint256[] memory) {
        return ownerToTokensSet[_user].values();
    }

    /*************************************************************************** */
    //                             Mint:


    function getNFTPrice(uint256 amount) public view returns (uint256) {
        require(totalSupply() < MINTING_LIMIT, "Sale has already ended.");

        return amount.mul(mintingPrice);
    }

    function mint(uint256 amount) external payable reentrancyGuard mintingEnabled {

        uint256 nftPrice = getNFTPrice(amount);

        require(msg.value >= nftPrice, Errors.NOT_ENOUGH_MATIC);
        
        
        require(amount >= 1, Errors.MINTING_MIN_MINT_AMOUNT);
        require(amount <= 20, Errors.MINTING_MAX_MINT_AMOUNT);
        require((totalMinted + amount) <= MINTING_LIMIT, Errors.EXCEEDS_MAX_SUPPLY);

        if (msg.value > nftPrice) {
            payable(msg.sender).transfer(msg.value - nftPrice);
        }

        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender);
        }
    }


    function changeBaseURI(string memory baseURI) onlyContractOwner external {
       _setBaseURI(baseURI);
    }


    /*************************************************************************** */
    //                             Market:
    function buyFromMarket(uint256 _tokenId, address _to) external payable
        notZeroAddress(_to) 
        marketEnabled 
        marketLock
    {
        require(marketLots[_tokenId].isForSale, Errors.MARKET_NOT_FOR_SALE);

        uint256 _price = marketLots[_tokenId].price;
        require(msg.value >= marketLots[_tokenId].price, Errors.NOT_ENOUGH_MATIC);

        if (msg.value > marketLots[_tokenId].price) {
            payable(msg.sender).transfer(msg.value - _price);
        }

        uint256 devComission = _price * (devComissionNom ) / devComissionDenom;

        payable(dev1).transfer(devComission / 3);
        payable(dev2).transfer(devComission / 3);
        payable(dev3).transfer(devComission / 3);


        payable(tokenToOwner[_tokenId]).transfer(_price - devComission);
        emit MarketTrade(_tokenId, tokenToOwner[_tokenId], _to, msg.sender, _price);
        
        _transfer(tokenToOwner[_tokenId], _to, _tokenId);
    }


    function putOnMarket(uint256 _tokenId, uint256 price) external canOperate(_tokenId) marketEnabled marketLock {
        require(!marketLots[_tokenId].isForSale, Errors.MARKET_ALREADY_ON_SALE);
        require(price > 0, Errors.MARKET_ZERO_PRICE);

        marketLots[_tokenId] = MarketLot(_tokenId, true, tokenToOwner[_tokenId], price);
        tokensOnSale.add(_tokenId);

        emit TokenOnSale(_tokenId, tokenToOwner[_tokenId], price);
    }

    function changeLotPrice(uint256 _tokenId, uint256 newPrice) external canOperate(_tokenId) marketEnabled marketLock {
        require(marketLots[_tokenId].isForSale, Errors.MARKET_NOT_FOR_SALE);
        require(newPrice > 0, Errors.MARKET_ZERO_PRICE);

        emit TokenMarketPriceChange(_tokenId, tokenToOwner[_tokenId], marketLots[_tokenId].price, newPrice);

        marketLots[_tokenId].price = newPrice;
    }

    function withdrawFromMarket(uint256 _tokenId) external canOperate(_tokenId) marketLock {
        _removeFromMarket(_tokenId);

        emit TokenNotOnSale(_tokenId, tokenToOwner[_tokenId]);
    }


    function _removeFromMarket(uint256 _tokenId) internal {
        if (marketLots[_tokenId].isForSale) {
            delete marketLots[_tokenId];
            tokensOnSale.remove(_tokenId);
        }
    }

    function getMarketLotInfo(uint256 _tokenId) external view returns(MarketLot memory) {
        require(marketLots[_tokenId].isForSale, Errors.MARKET_NOT_FOR_SALE);

        return marketLots[_tokenId];
    }

    function getTokensOnSale() external view returns(uint256[] memory) {
        return tokensOnSale.values();
    }

    /*************************************************************************** */


    /*************************************************************************** */
    //                             Internal functions:

    function _mint(address _to) internal notZeroAddress(_to) returns (uint256 _mintedTokenId) {
        require(totalMinted < MINTING_LIMIT, Errors.ALL_MINTED);
        uint randomId = _tryGenerateRandomId();
        totalMinted++;

        if (randomId == 0) {
            randomId = _tryGenerateRandomId();
            totalMinted++;
        }

        if (randomId != 0) {
            _addToken(_to, randomId);

            emit Mint(randomId, msg.sender, _to);
            emit Transfer(addressZero, _to, randomId);
        }

        return randomId;
    }
    

    function _addToken(address _to, uint256 _tokenId) private notZeroAddress(_to) {
        tokenToOwner[_tokenId] = _to;
        ownerToTokensSet[_to].add(_tokenId);
    }
    

    function _removeToken(address _from, uint256 _tokenId) private {
        if (tokenToOwner[_tokenId] != _from)
            return;
        
        if (tokenToApproval[_tokenId] != addressZero)
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
            bytes4 retval = IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _setBaseURI(string memory baseURI_) private {
        _baseURI = baseURI_;
    }

    /*************************************************************************** */



    /*************************************************************************** */
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

    function _claimMATIC(uint256 amount) external onlyContractOwner {
        payable(contractOwner).transfer(amount);
    }

    function _enableMarket() external onlyContractOwner {
        if (!isMarketEnabled) {
            isMarketEnabled = true;
            emit MarketEnabled();
        }
    }

    function _disableMarket() external onlyContractOwner {
        if (isMarketEnabled) {
            isMarketEnabled = false;
            emit MarketDisabled();
        }
    }

    function withdraw() external onlyContractOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    /*************************************************************************** */




    /*************************************************************************** */
    //                             Service:
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }


    function _tryGenerateRandomId() private returns (uint256) {
        uint256 randId = _generateRandomId();
        
        if (tokenToOwner[randId] == addressZero) {
            return randId;
        } else {
            return 0;
        }
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

    /*************************************************************************** */



    /*************************************************************************** */
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
            (ownerToOperators[tokenOwner][msg.sender] && tokenOwner != addressZero), 
            Errors.TRANSFER_NOT_APPROVED
        );
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = tokenToOwner[_tokenId];
        require(
            tokenOwner == msg.sender || 
            (ownerToOperators[tokenOwner][msg.sender] && tokenOwner != addressZero), 
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


    /*************************************************************************** */



    /*************************************************************************** */
    //                             Events: 

    event MarketTrade(uint256 indexed _tokenId, address indexed _from, address indexed _to, address buyer, uint256 _price);

    // NFT minted
    event Mint(uint indexed tokenId, address indexed mintedBy, address indexed mintedTo);
     // MATIC is deposited into the contract.
    event Deposit(address indexed account, uint amount);
    //MATIC is withdrawn from the contract.
    event Withdraw(address indexed account, uint amount);

    event TokenOnSale(uint256 indexed _tokenId, address indexed _owner, uint256 _price);
    event TokenNotOnSale(uint256 indexed _tokenId, address indexed _owner);
    event TokenMarketPriceChange(uint256 indexed _tokenId, address indexed _owner, uint256 _oldPrice, uint256 _newPrice);

    event MintingEnabled();
    event MintingDisabled();

    event MarketEnabled();
    event MarketDisabled();
}