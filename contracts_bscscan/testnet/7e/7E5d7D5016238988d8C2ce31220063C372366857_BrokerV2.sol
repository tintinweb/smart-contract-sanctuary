/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

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
        TokenDet memory _tokenDet
        // address _mintableAddress,
        // uint256 _tokenID
    ) public {
        if (!self.exists(_tokenDet)) {
            self.array.push(_tokenDet);
        }
    }

    function getIndexByTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool tokenExists = false;
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenID == _tokenDet.tokenID 
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
        TokenDet memory _tokenDet
    ) internal returns (bool) {
        (uint256 i, bool tokenExists) = self.getIndexByTokenDet(_tokenDet);
        if (tokenExists == true) {
            self.array[i] = self.array[self.array.length - 1];
            self.array.pop();
            return true;
        }
        return false;
    }

    function exists(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenID == _tokenDet.tokenID
            ) {
                return true;
            }
        }
        return false;
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
contract Ownable {
    address private _owner;

    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        // address msgSender = _msgSender();
        _owner = msg.sender;
        // emit OwnershipTransferred(address(0), msg.sender);
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
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        // emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}



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


interface IERC20 {
    
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract IMintableToken {

    // Required methods
    function ownerOf(uint256 _tokenId) external view returns (address owner);

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

contract Storage is Ownable {
    using TokenDetArrayLib for TokenDetArrayLib.TokenDets;
    using ERC20Addresses for ERC20Addresses.erc20Addresses;
    // address owner;
    // uint16 public brokerage;
    mapping (address=>uint) public brokerage;
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
        returns (address[] memory)
    {
        return erc20TokensArray.array;
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

    function addERC20TokenPayment(address _erc20Token, uint _brokerage) public onlyOwner {
        erc20TokensArray.addERC20Tokens(_erc20Token);
        brokerage[_erc20Token] = _brokerage;
    }

    function updateBrokerage(address _erc20Token, uint _brokerage) public onlyOwner {
        brokerage[_erc20Token] = _brokerage;
    }

}

contract BrokerModifiers is Storage {
    modifier erc20Allowed(address _erc20Token) {
        if (_erc20Token != address(0)) {
            require(
                erc20TokensArray.exists(_erc20Token),
                "ERC20 not allowed"
            );
        }
        _;
    }

    modifier onSaleOnly(uint256 tokenID, address _mintableToken) {
        require(
            tokenOpenForSale[_mintableToken][tokenID] == true,
            "Token Not For Sale"
        );
        _;
    }

    modifier activeAuction(uint256 tokenID, address _mintableToken) {
        require(
            block.timestamp < auctions[_mintableToken][tokenID].closingTime,
            "Auction Time Over!"
        );
        _;
    }

    modifier auctionOnly(uint256 tokenID, address _mintableToken) {
        require(
            auctions[_mintableToken][tokenID].auctionType != 1,
            "Auction Not For Bid"
        );
        _;
    }

    modifier flatSaleOnly(uint256 tokenID, address _mintableToken) {
        require(
            auctions[_mintableToken][tokenID].auctionType != 2,
            "Auction for Bid only!"
        );
        _;
    }

    modifier tokenOwnerOnlly(uint256 tokenID, address _mintableToken) {
        // Sender will be owner only if no have bidded on auction.
        require(
            IMintableToken(_mintableToken).ownerOf(tokenID) == msg.sender,
            "You must be owner and Token should not have any bid"
        );
        _;
    }
}


contract BrokerV2 is ERC721Holder, BrokerModifiers {
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

    mapping(address => uint256) brokerageBalance;

    constructor(uint _brokerage) public {
        brokerage[address(0)] = _brokerage;
        transferOwnership(msg.sender);
    }

    function removeERC20TokenPayment(address _erc20Token)
        public
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        erc20TokensArray.removeERC20Token(_erc20Token);
    }

    function bid(
        uint256 tokenID,
        address _mintableToken,
        uint256 amount
    )
        public
        payable
        onSaleOnly(tokenID, _mintableToken)
        activeAuction(tokenID, _mintableToken)
    {
        IMintableToken Token = IMintableToken(_mintableToken);

        auction memory _auction = auctions[_mintableToken][tokenID];

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "Insufficient bidding amount."
            );

            if (_auction.buyer == true) {
                _auction.highestBidder.transfer(_auction.currentBid);
            }
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "Allowance is less than amount sent for bidding."
            );
            require(
                amount > _auction.currentBid,
                "Insufficient bidding amount."
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.buyer == true) {
                erc20Token.transfer(
                    _auction.highestBidder,
                    _auction.currentBid
                );
            }
        }

        _auction.currentBid = _auction.erc20Token == address(0)
            ? msg.value
            : amount;

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
    // Collect Function are use to collect funds and NFT from Broker
    function collect(uint256 tokenID, address _mintableToken)
        public
    {
        IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(_mintableToken,tokenID);

        require(
            block.timestamp > _auction.closingTime,
            "Auction Not Over!"
        );

        address payable lastOwner2 = _auction.lastOwner;
        uint256 royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);

        uint256 royality = (royalities * _auction.currentBid) / 10000;
        uint256 brokerageAmount = (brokerage[_auction.erc20Token] * _auction.currentBid) / 10000;

        uint256 lastOwner_funds = _auction.currentBid - royality - brokerageAmount;
        
        if (_auction.buyer == true) {
            if (_auction.erc20Token == address(0)) {
                creator.transfer(royality);
                lastOwner2.transfer(lastOwner_funds);
            } else {
                IERC20 erc20Token = IERC20(_auction.erc20Token);
                // transfer royalitiy to creator
                erc20Token.transfer(creator, royality);
                erc20Token.transfer(lastOwner2, lastOwner_funds);
            }
            brokerageBalance[_auction.erc20Token] += brokerageAmount;
            tokenOpenForSale[_mintableToken][tokenID] = false;
            Token.safeTransferFrom(
                Token.ownerOf(tokenID),
                _auction.highestBidder,
                tokenID
            );

            // Buy event
            emit Buy(
                _tokenDet.NFTAddress,
                _tokenDet.tokenID,
                lastOwner2,
                _auction.highestBidder,
                _auction.currentBid,
                block.timestamp,
                _auction.erc20Token
            );
        }

        // Collect event
        emit Collect(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            lastOwner2,
            _auction.highestBidder,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.removeTokenDet(_tokenDet);

        tokensForSalePerUser[lastOwner2].removeTokenDet(_tokenDet);
        auctionTokens.removeTokenDet(_tokenDet);
        delete auctions[_mintableToken][tokenID];
    }

    function buy(uint256 tokenID, address _mintableToken)
        public
        payable
        onSaleOnly(tokenID, _mintableToken)
        flatSaleOnly(tokenID, _mintableToken)
    {
        IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(_mintableToken,tokenID);
        
        address payable lastOwner2 = _auction.lastOwner;
        uint256 royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);
        uint256 royality = (royalities * _auction.buyPrice) / 10000;
        uint256 brokerageAmount = (brokerage[_auction.erc20Token] * _auction.buyPrice) / 10000;

        uint256 lastOwner_funds = _auction.buyPrice - royality - brokerageAmount;

        if (_auction.erc20Token == address(0)) {
            require(msg.value >= _auction.buyPrice, "Insufficient Payment");

            creator.transfer(royality);
            lastOwner2.transfer(lastOwner_funds);


        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >=
                    _auction.buyPrice,
                "Insufficient spent allowance "
            );
            // transfer royalitiy to creator
            erc20Token.transferFrom(msg.sender, creator, royality);
            // transfer brokerage amount to broker
            erc20Token.transferFrom(msg.sender, address(this), brokerageAmount);
            // transfer remaining  amount to lastOwner
            erc20Token.transferFrom(msg.sender, lastOwner2, lastOwner_funds);
        }
        brokerageBalance[_auction.erc20Token] += brokerageAmount;

        tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] = false;
        // _auction.buyer = true;
        // _auction.highestBidder = msg.sender;
        // _auction.currentBid = _auction.buyPrice;

        Token.safeTransferFrom(
            Token.ownerOf(_tokenDet.tokenID),
            // _auction.highestBidder,/
            msg.sender,
            _tokenDet.tokenID
        );

        // Buy event
        emit Buy(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            lastOwner2,
            msg.sender,
            _auction.buyPrice,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.removeTokenDet(_tokenDet);
        tokensForSalePerUser[lastOwner2].removeTokenDet(_tokenDet);

        fixedPriceTokens.removeTokenDet(_tokenDet);
        delete auctions[_tokenDet.NFTAddress][_tokenDet.tokenID];
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(brokerageBalance[address(0)]);
        brokerageBalance[address(0)] = 0;
    }

    function withdrawERC20(address _erc20Token) public onlyOwner {
        require(
            erc20TokensArray.exists(_erc20Token),
            "This erc20token payment not allowed"
        );
        IERC20 erc20Token = IERC20(_erc20Token);
        erc20Token.transfer(msg.sender, brokerageBalance[_erc20Token]);
        brokerageBalance[_erc20Token] = 0;
    }

    function putOnSale(
        uint256 _tokenID,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _buyPrice,
        uint256 _duration,
        address _mintableToken,
        address _erc20Token
    )
        public
        erc20Allowed(_erc20Token)
        tokenOwnerOnlly(_tokenID, _mintableToken)
    {
        IMintableToken Token = IMintableToken(_mintableToken);

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
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(_mintableToken, _tokenID);

        // Store data in all mappings if adding fresh token on sale
        if (tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] == false) {
            tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] = true;

            tokensForSale.addTokenDet(_tokenDet);
            tokensForSalePerUser[msg.sender].addTokenDet(_tokenDet);

            // Add token to fixedPrice on Timed list
            if (_auctionType == 1) {
                fixedPriceTokens.addTokenDet(_tokenDet);
            } else if (_auctionType == 2) {
                auctionTokens.addTokenDet(_tokenDet);
            }
        }

        // OnSale event
        emit OnSale(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            msg.sender,
            _auctionType,
            newAuction.auctionType == 1 ? newAuction.buyPrice : newAuction.startingPrice,
            block.timestamp,
            newAuction.erc20Token
        );
    }

    function updatePrice(
        uint256 tokenID,
        address _mintableToken,
        uint256 _newPrice,
        address _erc20Token
    )
        public
        onSaleOnly(tokenID, _mintableToken)
        erc20Allowed(_erc20Token)
        tokenOwnerOnlly(tokenID, _mintableToken)
    {
        // IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];

        if (_auction.auctionType == 2) {
            require(
                block.timestamp < _auction.closingTime,
                "Auction Time Over!"
            );
        }
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
            _auction.currentBid = _newPrice;
        }
        _auction.erc20Token = _erc20Token;
        auctions[_mintableToken][tokenID] = _auction;
    }

    function putSaleOff(uint256 tokenID, address _mintableToken)
        public
        tokenOwnerOnlly(tokenID, _mintableToken)
    {
        // IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(_mintableToken,tokenID);
        tokenOpenForSale[_mintableToken][tokenID] = false;

        // OffSale event
        emit OffSale(
            _mintableToken,
            tokenID,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.removeTokenDet(_tokenDet);

        tokensForSalePerUser[msg.sender].removeTokenDet(_tokenDet);
        // Remove token from list
        if (_auction.auctionType == 1) {
            fixedPriceTokens.removeTokenDet(_tokenDet);
        } else if (_auction.auctionType == 2) {
            auctionTokens.removeTokenDet(_tokenDet);
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