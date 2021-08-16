/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

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

contract Broker is ERC721Holder {
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
    mapping(address => tokenDet[]) public tokensForSalePerUser;
    tokenDet[] public fixedPriceTokens;
    tokenDet[] public auctionTokens;

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

    struct tokenDet {
        address NFTAddress;
        uint256 tokenID;
    }

    mapping(address => mapping(uint256 => auction)) public auctions;

    tokenDet[] public tokensForSale;

    constructor(uint16 _brokerage) public {
        owner = msg.sender;
        brokerage = _brokerage;
    }

    function getTokensForSale() public view returns (tokenDet[] memory) {
        return tokensForSale;
    }

    function getFixedPriceTokensForSale()
        public
        view
        returns (tokenDet[] memory)
    {
        return fixedPriceTokens;
    }

    function getAuctionTokensForSale() public view returns (tokenDet[] memory) {
        return auctionTokens;
    }

    function getTokensForSalePerUser(address _user)
        public
        view
        returns (tokenDet[] memory)
    {
        return tokensForSalePerUser[_user];
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
        require(
            block.timestamp > auctions[_mintableToken][tokenID].closingTime,
            "Auction Not Over!"
        );
        address payable lastOwner2 = auctions[_mintableToken][tokenID]
            .lastOwner;
        if (auctions[_mintableToken][tokenID].buyer = true){
            
            uint256 royalities = Token.royalities(tokenID);
            address payable creator = Token.creators(tokenID);

            auctions[_mintableToken][tokenID].buyPrice = uint256(0);

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
                auctions[_mintableToken][tokenID].currentBid,
                block.timestamp
            );
        }

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

        uint256 index;
        for (uint256 i = 0; i < tokensForSale.length; i++) {
            if (
                tokensForSale[i].NFTAddress == _mintableToken &&
                tokensForSale[i].tokenID == tokenID
            ) {
                index = i;
                break;
            }
        }

        tokensForSale[index] = tokensForSale[tokensForSale.length - 1];
        delete tokensForSale[tokensForSale.length - 1];
        tokensForSale.pop();

        uint256 index2;
        for (uint256 i = 0; i < tokensForSalePerUser[lastOwner2].length; i++) {
            if (
                tokensForSalePerUser[lastOwner2][i].NFTAddress ==
                _mintableToken &&
                tokensForSalePerUser[lastOwner2][i].tokenID == tokenID
            ) {
                index2 = i;
                break;
            }
        }

        tokensForSalePerUser[lastOwner2][index2] = tokensForSalePerUser[
            lastOwner2
        ][tokensForSalePerUser[lastOwner2].length - 1];
        delete tokensForSalePerUser[lastOwner2][
            tokensForSalePerUser[lastOwner2].length - 1
        ];
        tokensForSalePerUser[lastOwner2].pop();

        // Remove from auctionTokens
        uint256 index3;
        for (uint256 i = 0; i < auctionTokens.length; i++) {
            if (
                auctionTokens[i].NFTAddress == _mintableToken &&
                auctionTokens[i].tokenID == tokenID
            ) {
                index3 = i;
                break;
            }
        }

        auctionTokens[index3] = auctionTokens[auctionTokens.length - 1];
        delete auctionTokens[auctionTokens.length - 1];
        auctionTokens.pop();
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

        uint256 index;
        for (uint256 i = 0; i < tokensForSale.length; i++) {
            if (
                tokensForSale[i].NFTAddress == _mintableToken &&
                tokensForSale[i].tokenID == tokenID
            ) {
                index = i;
                break;
            }
        }

        tokensForSale[index] = tokensForSale[tokensForSale.length - 1];
        delete tokensForSale[tokensForSale.length - 1];
        tokensForSale.pop();

        uint256 index2;
        for (uint256 i = 0; i < tokensForSalePerUser[lastOwner2].length; i++) {
            if (
                tokensForSalePerUser[lastOwner2][i].NFTAddress ==
                _mintableToken &&
                tokensForSalePerUser[lastOwner2][i].tokenID == tokenID
            ) {
                index2 = i;
                break;
            }
        }

        tokensForSalePerUser[lastOwner2][index2] = tokensForSalePerUser[
            lastOwner2
        ][tokensForSalePerUser[lastOwner2].length - 1];
        delete tokensForSalePerUser[lastOwner2][
            tokensForSalePerUser[lastOwner2].length - 1
        ];
        tokensForSalePerUser[lastOwner2].pop();

        // Remove from fixedPreiceTones
        uint256 index3;
        for (uint256 i = 0; i < fixedPriceTokens.length; i++) {
            if (
                fixedPriceTokens[i].NFTAddress == _mintableToken &&
                fixedPriceTokens[i].tokenID == tokenID
            ) {
                index3 = i;
                break;
            }
        }

        fixedPriceTokens[index3] = fixedPriceTokens[
            fixedPriceTokens.length - 1
        ];
        delete fixedPriceTokens[fixedPriceTokens.length - 1];
        fixedPriceTokens.pop();
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
            tokenDet memory object = tokenDet(_mintableToken, _tokenID);
            tokensForSale.push(object);
            tokensForSalePerUser[msg.sender].push(object);

            // Add token to fixedPrice on Timed list
            if (_auctionType == 1) {
                fixedPriceTokens.push(object);
            } else if (_auctionType == 2) {
                auctionTokens.push(object);
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

        uint256 index;
        for (uint256 i = 0; i < tokensForSale.length; i++) {
            if (tokensForSale[i].tokenID == tokenID) {
                index = i;
                break;
            }
        }

        tokensForSale[index] = tokensForSale[tokensForSale.length - 1];
        delete tokensForSale[tokensForSale.length - 1];
        tokensForSale.pop();

        uint256 index2;
        for (uint256 i = 0; i < tokensForSalePerUser[msg.sender].length; i++) {
            if (tokensForSalePerUser[msg.sender][i].tokenID == tokenID) {
                index2 = i;
                break;
            }
        }

        tokensForSalePerUser[msg.sender][index2] = tokensForSalePerUser[
            msg.sender
        ][tokensForSalePerUser[msg.sender].length - 1];
        delete tokensForSalePerUser[msg.sender][
            tokensForSalePerUser[msg.sender].length - 1
        ];
        tokensForSalePerUser[msg.sender].pop();

        // Remove token from list
        if (auctions[_mintableToken][tokenID].auctionType == 1) {
            uint256 index3;
            for (uint256 i = 0; i < fixedPriceTokens.length; i++) {
                if (
                    fixedPriceTokens[i].NFTAddress == _mintableToken &&
                    fixedPriceTokens[i].tokenID == tokenID
                ) {
                    index3 = i;
                    break;
                }
            }

            fixedPriceTokens[index3] = fixedPriceTokens[
                fixedPriceTokens.length - 1
            ];
            delete fixedPriceTokens[fixedPriceTokens.length - 1];
            fixedPriceTokens.pop();
        } else if (auctions[_mintableToken][tokenID].auctionType == 2) {
            uint256 index4;
            for (uint256 i = 0; i < auctionTokens.length; i++) {
                if (
                    auctionTokens[i].NFTAddress == _mintableToken &&
                    auctionTokens[i].tokenID == tokenID
                ) {
                    index4 = i;
                    break;
                }
            }

            auctionTokens[index4] = auctionTokens[auctionTokens.length - 1];
            delete auctionTokens[auctionTokens.length - 1];
            auctionTokens.pop();
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