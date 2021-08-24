/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// File: contracts/TokenDetArrayLib.sol

pragma solidity ^0.5.17;

// librray for TokenDets
library TokenDetArrayLib {
    // Using for array of strcutres for storing mintable address and token id
    using TokenDetArrayLib for TokenDets;

    struct TokenDet {
        address NFTAddress;
        uint256 tokenID;
    }

    // custom type array TokenDets
    struct TokenDets {
        TokenDet[] array;
    }

    function addTokenDet(
        TokenDets storage self,
        address _mintableaddress,
        uint256 _tokenID
    ) public {
        if (!self.exists(_mintableaddress, _tokenID)) {
            self.array.push(TokenDet(_mintableaddress, _tokenID));
        }
    }

    function getIndexByTokenDet(
        TokenDets storage self,
        address _mintableaddress,
        uint256 _tokenID
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool tokenExists = false;
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _mintableaddress &&
                self.array[i].tokenID == _tokenID
            ) {
                index = i;
                tokenExists = true;
                break;
            }
        }
        return (index, tokenExists);
    }

    function removeTokenDet(
        TokenDets storage self,
        address _mintableaddress,
        uint256 _tokenID
    ) internal returns (bool) {
        (uint256 i, bool tokenExists) = self.getIndexByTokenDet(
            _mintableaddress,
            _tokenID
        );
        if (tokenExists == true) {
            self.array[i] = self.array[self.array.length - 1];
            self.array.pop();
            return true;
        }
        return false;
    }

    function exists(
        TokenDets storage self,
        address _mintableaddress,
        uint256 _tokenID
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _mintableaddress &&
                self.array[i].tokenID == _tokenID
            ) {
                return true;
            }
        }
        return false;
    }
}

// File: contracts/Ownable.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/ERC20Addresses.sol

pragma solidity ^0.5.17;

// library for erc20address array 
library ERC20Addresses {
    using ERC20Addresses for erc20Addresses;

    struct erc20Addresses {
        address[] array;
    }

    function addERC20Tokens(erc20Addresses storage self, address erc20address)
        external
    {
        self.array.push(erc20address);
    }

    function getIndexByERC20Token(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool exists;

        for (uint256 i = 0; i < self.array.length; i++) {
            if (self.array[i] == _ercTokenAddress) {
                index = i;
                exists = true;

                break;
            }
        }
        return (index, exists);
    }

    function removeERC20Token(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal {
       for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _ercTokenAddress 
            ) {
                delete self.array[i];
            }
        }
    }
    function exists(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _ercTokenAddress 
            ) {
                return true;
            }
        }
        return false;
    }
}

// File: contracts/Storage.sol

pragma solidity ^0.5.17 ;
// pragma experimental ABIEncoderV2;



contract Storage is Ownable{
    using TokenDetArrayLib for TokenDetArrayLib.TokenDets;
    using ERC20Addresses for ERC20Addresses.erc20Addresses;
    // address owner;
    uint16 public brokerage;
    mapping(address => mapping(uint256 => bool)) tokenOpenForSale;
    mapping(address => TokenDetArrayLib.TokenDets) tokensForSalePerUser;
    TokenDetArrayLib.TokenDets fixedPriceTokens;
    TokenDetArrayLib.TokenDets auctionTokens;

    //auction type :
    // 1 : only direct buy
    // 2 : only bid
    // 3 : both buy and bid

    struct auction {
        address payable lastOwner;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionType;
        uint256 startingPrice;
        uint256 buyPrice;
        bool buyer;
        uint256 startingTime;
        uint256 closingTime;
        address erc20Token;
    }

    mapping(address => mapping(uint256 => auction)) public auctions;

    
    TokenDetArrayLib.TokenDets tokensForSale;
    ERC20Addresses.erc20Addresses erc20TokensArray;
    
     function getErc20Tokens()
        public
        view
        returns (ERC20Addresses.erc20Addresses memory)
    {
        return erc20TokensArray;
    }

    function getTokensForSale()
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return tokensForSale.array;
    }

    function getFixedPriceTokensForSale()
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return fixedPriceTokens.array;
    }

    function getAuctionTokensForSale()
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return auctionTokens.array;
    }

    function getTokensForSalePerUser(address _user)
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return tokensForSalePerUser[_user].array;
    }

    function setBrokerage(uint16 _brokerage) public onlyOwner {
        brokerage = _brokerage;
    }

}

// File: contracts/Broker.sol

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract MintableToken {
    // Required methods
    function totalSupply() public view returns (uint256 total);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function approve(address _to, uint256 _tokenId) external;

    function transfer(address _to, uint256 _tokenId) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function royalities(uint256 _tokenId) public view returns (uint256);

    function creators(uint256 _tokenId) public view returns (address payable);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool);
}

contract Broker is ERC721Holder, Storage {

    // events
    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time,
        address ERC20Address
    );
    event Buy(
        address indexed collection,
        uint256 tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event Collect(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        address collector,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        address ERC20Address
    );

    constructor(uint16 _brokerage) public {
        brokerage = _brokerage;
        transferOwnership(msg.sender);
    }

    function addERC20TokenPayment(address _erc20Token) public onlyOwner {
        erc20TokensArray.addERC20Tokens(_erc20Token);
    }

    function removeERC20TokenPayment(address _erc20Token) public onlyOwner {
        require(erc20TokensArray.exists(_erc20Token),"This ERC20token not available in Array");
        erc20TokensArray.removeERC20Token(_erc20Token);
    }

    function bid(
        uint256 tokenID,
        address _mintableToken,
        uint256 amount
    ) public payable {
        MintableToken Token = MintableToken(_mintableToken);

        auction memory _auction = auctions[_mintableToken][tokenID];

        require(
            tokenOpenForSale[_mintableToken][tokenID] == true,
            "Token Not For Sale"
        );
        require(
            block.timestamp < _auction.closingTime,
            "Auction Time Over!"
        );
        require(
            _auction.auctionType != 1,
            "Auction Not For Bid"
        );

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "Insufficient Payment"
            );

            if (_auction.buyer == true) {
                _auction.highestBidder.transfer(
                    _auction.currentBid
                );
                _auction.currentBid = msg.value;
            }
        } else {
            IERC20 erc20Token = IERC20(
                _auction.erc20Token
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount &&
                    amount > _auction.currentBid,
                " The price of bidding is not enough"
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.buyer == true) {

                erc20Token.transferFrom(
                    address(this),
                    _auction.highestBidder,
                    _auction.currentBid
                );
                _auction.currentBid = amount;
            }
        }

        Token.safeTransferFrom(Token.ownerOf(tokenID), address(this), tokenID);
        _auction.buyer = true;
        _auction.highestBidder = msg.sender;

        auctions[_mintableToken][tokenID] = _auction;

        // Bid event
        emit Bid(
            _mintableToken,
            tokenID,
            _auction.lastOwner,
            msg.sender,
            msg.value,
            block.timestamp,
            _auction.erc20Token
        );
    }

    function collect(uint256 tokenID, address _mintableToken) public {
        MintableToken Token = MintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        require(
            block.timestamp > _auction.closingTime,
            "Auction Not Over!"
        );

        address payable lastOwner2 = _auction.lastOwner;
        uint256 royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);

        uint256 royalitiy = (royalities *
            _auction.currentBid) / 10000;

        uint256 lastOwner_funds = ((10000 - royalities - brokerage) *
            _auction.currentBid) / 10000;
        if (_auction.buyer == true) {
            
            if (_auction.erc20Token == address(0)) {
                creator.transfer(royalitiy);
                lastOwner2.transfer(lastOwner_funds);

            } else {
                IERC20 erc20Token = IERC20(
                    _auction.erc20Token
                );
                // transfer royalitiy to creator
                erc20Token.transferFrom(address(this), creator, royalitiy);

                erc20Token.transferFrom(
                    address(this),
                    lastOwner2,
                    lastOwner_funds
                );
            }
            tokenOpenForSale[_mintableToken][tokenID] = false;
            Token.safeTransferFrom(
                Token.ownerOf(tokenID),
                _auction.highestBidder,
                tokenID
            );
            
            // Buy event
            emit Buy(
                _mintableToken,
                tokenID,
                lastOwner2,
                msg.sender,
                _auction.currentBid,
                block.timestamp,
                _auction.erc20Token
            );
        }
        
        // Collect event
        emit Collect(
            _mintableToken,
            tokenID,
            lastOwner2,
            _auction.highestBidder,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.removeTokenDet(_mintableToken, tokenID);

        tokensForSalePerUser[lastOwner2].removeTokenDet(
            _mintableToken,
            tokenID
        );
        auctionTokens.removeTokenDet(_mintableToken, tokenID);
        delete auctions[_mintableToken][tokenID];

    }


    function buy(
        uint256 tokenID,
        address _mintableToken
    ) public payable {
        MintableToken Token = MintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        require(
            tokenOpenForSale[_mintableToken][tokenID] == true,
            "Token Not For Sale"
        );
        require(
            _auction.auctionType != 2,
            "Auction for Bid only!"
        );

        address payable lastOwner2 = _auction
            .lastOwner;
        uint256 royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);
        uint256 royalitiy = (royalities *
            _auction.buyPrice) / 10000;
        uint256 brokerage_this = (brokerage *
            _auction.buyPrice) / 10000;

        uint256 lastOwner_funds = ((10000 - royalities - brokerage) *
            _auction.buyPrice) / 10000;

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value >= _auction.buyPrice,
                "Insufficient Payment"
            );

            creator.transfer(royalitiy);
            lastOwner2.transfer(lastOwner_funds);
        } else {
            IERC20 erc20Token = IERC20(
                _auction.erc20Token
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) >=  _auction.buyPrice,
                "Insufficient spent allowance "
            );
            // transfer royalitiy to creator
            erc20Token.transferFrom(msg.sender, creator, royalitiy);
            // transfer brokerage amount to broker
            erc20Token.transferFrom(msg.sender, address(this), brokerage_this);
            // transfer remaining  amount to lastOwner2
            erc20Token.transferFrom(msg.sender, lastOwner2, lastOwner_funds);
        }

        tokenOpenForSale[_mintableToken][tokenID] = false;
        _auction.buyer = true;
        _auction.highestBidder = msg.sender;
        _auction.currentBid = _auction.buyPrice;

        Token.safeTransferFrom(
            Token.ownerOf(tokenID),
            _auction.highestBidder,
            tokenID
        );

        // Buy event
        emit Buy(
            _mintableToken,
            tokenID,
            lastOwner2,
            msg.sender,
            _auction.buyPrice,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.removeTokenDet(_mintableToken, tokenID);
        tokensForSalePerUser[lastOwner2].removeTokenDet(
            _mintableToken,
            tokenID
        );

        fixedPriceTokens.removeTokenDet(_mintableToken, tokenID);
        delete auctions[_mintableToken][tokenID];
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawERC20(address _erc20Token)
        public
        onlyOwner
    {
        require(
            erc20TokensArray.exists(_erc20Token),
            "this erc20token payment not allowed"
        );
        IERC20 erc20Token = IERC20(_erc20Token);
        erc20Token.transferFrom(
            address(this),
            msg.sender,
            erc20Token.balanceOf(address(this))
        );
    }

    function putOnSale(
        uint256 _tokenID,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _buyPrice,
        uint256 _duration,
        address _mintableToken,
        address _erc20Token
    ) public {
        
        MintableToken Token = MintableToken(_mintableToken);

        require(Token.ownerOf(_tokenID) == msg.sender, "Permission Denied");
        require(
            Token.getApproved(_tokenID) == address(this),
            "Broker Not approved"
        );
        auction memory _auction = auctions[_mintableToken][_tokenID];

        // Allow to put on sale to already on sale NFT \
        // only if it was on auction and have 0 bids and auction is over
        if (tokenOpenForSale[_mintableToken][_tokenID] == true) {
            require(
                _auction.auctionType == 2 &&
                _auction.buyer == false &&
                block.timestamp > _auction.closingTime,
                "This NFT is already on sale."
            );
        }

        // if user want erc20toeken as Payment
        if (_erc20Token != address(0)) {

            require(
                erc20TokensArray.exists(_erc20Token),
                "this erc20token payment not allowed"
            );
        }

        auction memory newAuction = auction(
            msg.sender,
            _startingPrice,
            address(0),
            _auctionType,
            _startingPrice,
            _buyPrice,
            false,
            block.timestamp,
            block.timestamp + _duration,
            _erc20Token
        );
        auctions[_mintableToken][_tokenID] = newAuction;

        // Store data in all mappings if adding fresh token on sale
        if (tokenOpenForSale[_mintableToken][_tokenID] == false) {
            tokenOpenForSale[_mintableToken][_tokenID] = true;

            tokensForSale.addTokenDet(_mintableToken, _tokenID);
            tokensForSalePerUser[msg.sender].addTokenDet(
                _mintableToken,
                _tokenID
            );

            // Add token to fixedPrice on Timed list
            if (_auctionType == 1) {
                fixedPriceTokens.addTokenDet(_mintableToken, _tokenID);
            } else if (_auctionType == 2) {
                auctionTokens.addTokenDet(_mintableToken, _tokenID);
            }
        }

        // OnSale event
        emit OnSale(
            _mintableToken,
            _tokenID,
            msg.sender,
            _auctionType,
            _auctionType == 1 ? _buyPrice : _startingPrice,
            block.timestamp,
            newAuction.erc20Token
        );
    }

    function updatePrice(
        uint256 tokenID,
        address _mintableToken,
        uint256 _newPrice,
        address _erc20Token
    ) public {
        MintableToken Token = MintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];

        // Sender will be owner only if no have bidded on auction.
        require(
            Token.ownerOf(tokenID) == msg.sender,
            "You must be owner and Token should not have any bid"
        );

        require(
            tokenOpenForSale[_mintableToken][tokenID] == true,
            "Token Must be on sale to change price"
        );

        if (_auction.auctionType == 2) {
            require(
                block.timestamp < _auction.closingTime,
                "Auction Time Over!"
            );
        }
        // if user want erc20toeken as Payment
        if (_erc20Token != address(0)) {
            
            require(
                erc20TokensArray.exists(_erc20Token),
                "this erc20token payment not allowed"
            );
        }
        // Trigger event PriceUpdated with Old and new price
        emit PriceUpdated(
            _mintableToken,
            tokenID,
            _auction.lastOwner,
            _auction.auctionType,
            _auction.auctionType == 1
                ? _auction.buyPrice
                : _auction.startingPrice,
            _newPrice,
            block.timestamp,
            _auction.erc20Token

        );
        // Update Price
        if (_auction.auctionType == 1) {
            _auction.buyPrice = _newPrice;
        } else {
            _auction.startingPrice = _newPrice;
        }
        _auction.erc20Token = _erc20Token;
        auctions[_mintableToken][tokenID] = _auction;

    }

    function putSaleOff(uint256 tokenID, address _mintableToken) public {
        MintableToken Token = MintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        require(Token.ownerOf(tokenID) == msg.sender, "Permission Denied");
        _auction.buyPrice = uint256(0);
        tokenOpenForSale[_mintableToken][tokenID] = false;

        // OffSale event
        emit OffSale(_mintableToken, tokenID, msg.sender, block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.removeTokenDet(_mintableToken, tokenID);

        tokensForSalePerUser[msg.sender].removeTokenDet(
            _mintableToken,
            tokenID
        );
        // Remove token from list
        if (_auction.auctionType == 1) {
            fixedPriceTokens.removeTokenDet(_mintableToken, tokenID);
        } else if (_auction.auctionType == 2) {
            auctionTokens.removeTokenDet(_mintableToken, tokenID);
        }
        delete auctions[_mintableToken][tokenID];

    }

    function getOnSaleStatus(address _mintableToken, uint256 tokenID)
        public
        view
        returns (bool)
    {
        return tokenOpenForSale[_mintableToken][tokenID];
    }
}