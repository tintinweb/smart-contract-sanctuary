/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;


library TokenDetArrayLib{
    // Using for array of strcutres for storing mintable address and token id 
    using TokenDetArrayLib for TokenDets;

    struct  TokenDet {
        address NFTAddress;
        uint256 tokenID;
    }

    // custom type array TokenDets
    struct TokenDets {
        TokenDet[] array;
    }

    /**
     * @notice push an tokenDet to the array
     * @dev if the address already exists, it will not be added again
     * @param self Storage array containing tokenDet type variables
     */
    function addTokenDet(TokenDets storage self,address _mintableaddress,uint256 _tokenID) public {
        if(!self.exists(_mintableaddress, _tokenID)){
            self.array.push(TokenDet(_mintableaddress, _tokenID));
        }
    }

    /**
     * @notice get the tokenDet at a specific index from array
     * @dev revert if the index is out of bounds
     * @param self Storage array containing tokenDet type variables
     */
    function getIndexByTokenDet(TokenDets storage self, address _mintableaddress,uint256 _tokenID) internal view returns(uint256, bool) {
        uint256 index;
        bool exists = false;
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _mintableaddress &&
                self.array[i].tokenID == _tokenID
            ) {
                index =i;
                exists = true;
                break;
            }
        }
        return (index, exists);
    }    

    /**
     * @notice remove an tokenDet from the array
     * @dev finds the tokenDet, swaps it with the last tokenDet, and then deletes it;
     *      returns a boolean whether the tokenDet was found and deleted
     * @param self Storage array containing tokenDet type variables
     */
    function removeTokenDet(TokenDets storage self, address _mintableaddress,uint256 _tokenID) internal returns (bool) {
        
            (uint256 i, bool exists)  = self.getIndexByTokenDet(_mintableaddress,_tokenID);
            if (exists == true) {
                self.array[i] = self.array[self.array.length - 1];
                self.array.pop();
                return true;
            }
        return false;
    }
    
    /**
     * @notice check if an tokenDet exist in the array
     * @param self Storage array containing tokenDet type variables
     */
    function exists(TokenDets storage self, address _mintableaddress,uint256 _tokenID) internal view returns (bool) {
        for (uint i = 0; i < self.array.length; i++) {
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

// Interface of ERC721Receiver
contract IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
}

// Contract for Managing the ERC721 Holding
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

// ERC721 Interface
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

// Broker Contract
contract Broker is ERC721Holder {
    
    using TokenDetArrayLib for TokenDetArrayLib.TokenDets;
  
    // events
    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time
    );
    event Buy(
        address indexed collection,
        uint256 tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        uint256 time
    );
    event Collect(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        address collector,
        uint256 time
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time
    );

    address owner;
    uint16 public brokerage;
    mapping(address => mapping(uint256 => bool)) tokenOpenForSale;
    mapping(address => TokenDetArrayLib.TokenDets) tokensForSalePerUser;
    
    TokenDetArrayLib.TokenDets  fixedPriceTokens;
    TokenDetArrayLib.TokenDets  auctionTokens;
    

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
    }

    mapping(address => mapping(uint256 => auction)) public auctions;

    TokenDetArrayLib.TokenDets  tokensForSale;

    constructor(uint16 _brokerage) public {
        owner = msg.sender;
        brokerage = _brokerage;
    }

    function getTokensForSale() public view returns (TokenDetArrayLib.TokenDet[] memory) {
        return tokensForSale.array;
    }

    function getFixedPriceTokensForSale()
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return fixedPriceTokens.array;
    }

    function getAuctionTokensForSale() public view returns (TokenDetArrayLib.TokenDet[] memory) {
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

    function bid(uint256 tokenID, address _mintableToken) public payable {
        MintableToken Token = MintableToken(_mintableToken);
        require(
            tokenOpenForSale[_mintableToken][tokenID] == true,
            "Token Not For Sale"
        );
        require(
            msg.value > auctions[_mintableToken][tokenID].currentBid,
            "Insufficient Payment"
        );
        require(
            block.timestamp < auctions[_mintableToken][tokenID].closingTime,
            "Auction Time Over!"
        );
        require(
            auctions[_mintableToken][tokenID].auctionType != 1,
            "Auction Not For Bid"
        );

        if (auctions[_mintableToken][tokenID].buyer == true) {
            auctions[_mintableToken][tokenID].highestBidder.transfer(
                auctions[_mintableToken][tokenID].currentBid
            );
        }

        Token.safeTransferFrom(Token.ownerOf(tokenID), address(this), tokenID);
        auctions[_mintableToken][tokenID].currentBid = msg.value;
        auctions[_mintableToken][tokenID].buyer = true;
        auctions[_mintableToken][tokenID].highestBidder = msg.sender;

        // Bid event
        emit Bid(
            _mintableToken,
            tokenID,
            auctions[_mintableToken][tokenID].lastOwner,
            msg.sender,
            msg.value,
            block.timestamp
        );
    }

    function collect(uint256 tokenID, address _mintableToken) public {
        MintableToken Token = MintableToken(_mintableToken);
        // Check expiry time
        require(
            block.timestamp > auctions[_mintableToken][tokenID].closingTime,
            "Auction Not Over!"
        );
        // Get seller of the NFT
        address payable lastOwner2 = auctions[_mintableToken][tokenID]
            .lastOwner;
        
        // Check if this auction had even a single bid
        if (auctions[_mintableToken][tokenID].buyer == true){
            // Get royality and creator of NFT from collection
            uint256 royalities = Token.royalities(tokenID);
            address payable creator = Token.creators(tokenID);

            // auctions[_mintableToken][tokenID].buyPrice = uint256(0);
            // NFT transfer
            Token.safeTransferFrom(
                Token.ownerOf(tokenID),
                auctions[_mintableToken][tokenID].highestBidder,
                tokenID
            );
            // Royality transfer
            creator.transfer(
                (royalities * auctions[_mintableToken][tokenID].currentBid) / 10000
            );
            // Fund transfer after brockerage and royality charges
            lastOwner2.transfer(
                ((10000 - royalities - brokerage) *
                    auctions[_mintableToken][tokenID].currentBid) / 10000
            );

            // Buy event
            emit Buy(
                _mintableToken,
                tokenID,
                lastOwner2,
                auctions[_mintableToken][tokenID].highestBidder,
                auctions[_mintableToken][tokenID].currentBid,
                block.timestamp
            );
        }

        // Disabling the on sale status
        tokenOpenForSale[_mintableToken][tokenID] = false;
        // Collect event
        emit Collect(
            _mintableToken,
            tokenID,
            lastOwner2,
            auctions[_mintableToken][tokenID].highestBidder,
            msg.sender,
            block.timestamp
        );

        // Remove from sale list
        tokensForSale.removeTokenDet(_mintableToken,tokenID);
        // Remove from sale per user list
        tokensForSalePerUser[lastOwner2].removeTokenDet(_mintableToken,tokenID);
        // Remove form auctions list
        auctionTokens.removeTokenDet(_mintableToken,tokenID);
        // Delete the auction details
        delete auctions[_mintableToken][tokenID];
    }

    function buy(uint256 tokenID, address _mintableToken) public payable {
        MintableToken Token = MintableToken(_mintableToken);
        require(
            tokenOpenForSale[_mintableToken][tokenID] == true,
            "Token Not For Sale"
        );
        require(
            msg.value >= auctions[_mintableToken][tokenID].buyPrice,
            "Insufficient Payment"
        );
        require(
            auctions[_mintableToken][tokenID].auctionType != 2,
            "Auction for Bid only!"
        );
        address payable lastOwner2 = auctions[_mintableToken][tokenID]
            .lastOwner;
        uint256 royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);

        tokenOpenForSale[_mintableToken][tokenID] = false;
        auctions[_mintableToken][tokenID].buyer = true;
        auctions[_mintableToken][tokenID].highestBidder = msg.sender;
        auctions[_mintableToken][tokenID].currentBid = auctions[_mintableToken][
            tokenID
        ].buyPrice;

        Token.safeTransferFrom(
            Token.ownerOf(tokenID),
            auctions[_mintableToken][tokenID].highestBidder,
            tokenID
        );
        creator.transfer(
            (royalities * auctions[_mintableToken][tokenID].currentBid) / 10000
        );
        lastOwner2.transfer(
            ((10000 - royalities - brokerage) *
                auctions[_mintableToken][tokenID].currentBid) / 10000
        );

        // Buy event
        emit Buy(
            _mintableToken,
            tokenID,
            lastOwner2,
            msg.sender,
            auctions[_mintableToken][tokenID].buyPrice,
            block.timestamp
        );

       
        tokensForSale.removeTokenDet(_mintableToken,tokenID);

        tokensForSalePerUser[lastOwner2].removeTokenDet(_mintableToken,tokenID);
        
        fixedPriceTokens.removeTokenDet(_mintableToken,tokenID);
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function putOnSale(
        uint256 _tokenID,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _buyPrice,
        uint256 _duration,
        address _mintableToken
    ) public {
        MintableToken Token = MintableToken(_mintableToken);
        require(Token.ownerOf(_tokenID) == msg.sender, "Permission Denied");
        require(
            Token.getApproved(_tokenID) == address(this),
            "Broker Not approved"
        );
        // Allow to put on sale to already on sale NFT \
        // only if it was on auction and have 0 bids and auction is over
        if (tokenOpenForSale[_mintableToken][_tokenID] == true) {
            require(
                auctions[_mintableToken][_tokenID].auctionType == 2 
                &&
                auctions[_mintableToken][_tokenID].buyer == false 
                &&
                block.timestamp > auctions[_mintableToken][_tokenID].closingTime,
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
            block.timestamp + _duration
        );

        auctions[_mintableToken][_tokenID] = newAuction;

        // Store data in all mappings if adding fresh token on sale
        if (tokenOpenForSale[_mintableToken][_tokenID] == false){
            tokenOpenForSale[_mintableToken][_tokenID] = true;
            
            tokensForSale.addTokenDet(_mintableToken, _tokenID);
            tokensForSalePerUser[msg.sender].addTokenDet(_mintableToken, _tokenID);

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
            block.timestamp
        );

    }

    function updatePrice(uint256 tokenID, address _mintableToken, uint256 _newPrice) public {
        MintableToken Token = MintableToken(_mintableToken);
        // Sender will be owner only if no have bidded on auction.
        require(
            Token.ownerOf(tokenID) == msg.sender, 
            "You must be owner and Token should not have any bid"
        );  
        require(
            tokenOpenForSale[_mintableToken][tokenID] == true,
            "Token Must be on sale to change price"
        );
        if (auctions[_mintableToken][tokenID].auctionType == 2){
            require(
                block.timestamp < auctions[_mintableToken][tokenID].closingTime,
                "Auction Time Over!"
            );
        }
        // Trigger event PriceUpdated with Old and new price
        emit PriceUpdated(
            _mintableToken,
            tokenID,
            auctions[_mintableToken][tokenID].lastOwner,
            auctions[_mintableToken][tokenID].auctionType,
            auctions[_mintableToken][tokenID].auctionType == 1 ? auctions[_mintableToken][tokenID].buyPrice : auctions[_mintableToken][tokenID].startingPrice,
            _newPrice,
            block.timestamp
        );
        // Update Price
        if (auctions[_mintableToken][tokenID].auctionType == 1){
            auctions[_mintableToken][tokenID].buyPrice = _newPrice;
        }
        else{
            auctions[_mintableToken][tokenID].startingPrice = _newPrice;
        }
    }
    
    function putSaleOff(uint256 tokenID, address _mintableToken) public {
        MintableToken Token = MintableToken(_mintableToken);
        require(Token.ownerOf(tokenID) == msg.sender, "Permission Denied");
        auctions[_mintableToken][tokenID].buyPrice = uint256(0);
        tokenOpenForSale[_mintableToken][tokenID] = false;

        // OffSale event
        emit OffSale(_mintableToken, tokenID, msg.sender, block.timestamp);

       
        tokensForSale.removeTokenDet(_mintableToken, tokenID);
        
      
        tokensForSalePerUser[msg.sender].removeTokenDet(_mintableToken, tokenID);
        // Remove token from list
        if (auctions[_mintableToken][tokenID].auctionType == 1) {
           
            fixedPriceTokens.removeTokenDet(_mintableToken, tokenID);
        } else if (auctions[_mintableToken][tokenID].auctionType == 2) {
           
            auctionTokens.removeTokenDet(_mintableToken, tokenID);
        }
    }

    function getOnSaleStatus(address _mintableToken, uint256 tokenID)
        public
        view
        returns (bool)
    {
        return tokenOpenForSale[_mintableToken][tokenID];
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function() external payable {
        //call your function here / implement your actions
    }
}