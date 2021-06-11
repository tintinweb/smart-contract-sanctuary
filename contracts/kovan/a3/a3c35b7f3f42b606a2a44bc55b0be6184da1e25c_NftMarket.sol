/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721Like {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function awardItem(address player, string memory _tokenURI)
        external
        returns (uint256);
}

interface USDTLike {
    function transfer(address, uint256) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external;
}

interface MarketLike {
    function royalty(uint256 tokenID) external returns (address);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "you are not the owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract NftMarket is Owned {
    address public nftAsset;
    address public usdToken;
    address public previous_version;
    string public constant version = "2.2.0";
    uint256 public transferFee = 25;
    uint256 public authorFee = 20;
    uint256 public sellerFee = 500;
    uint256 public overflowFee = 300;
    uint256 public bidGrowth = 100;

    struct Offer {
        bool isForSale;
        bool isBid;
        uint256 tokenID;
        address seller;
        uint256 price;
        address paymentToken;
        uint256 endTime;
    }

    struct Bid {
        uint256 tokenID;
        address bidder;
        uint256 value;
    }

    mapping(uint256 => address) public royalty;
    mapping(uint256 => Offer) public nftOffered;
    mapping(uint256 => Bid) public currentBid;
    mapping(uint256 => Bid[]) public nftBids;
    mapping(uint256 => mapping(address => uint256)) public offerBalances;
    mapping(uint256 => address[]) public bidders;
    mapping(uint256 => mapping(address => bool)) public bade;

    event Offered(
        uint256 indexed tokenID,
        address indexed seller,
        uint256 price,
        address paymentToken,
        bool isBid,
        uint256 endTime
    );
    event Bought(
        address indexed seller,
        address indexed buyers,
        uint256 indexed tokenID,
        uint256 price,
        address paymentToken
    );
    event NoLongerForSale(uint256 indexed tokenID);
    event BidEntered(
        uint256 indexed tokenID,
        address indexed fromAddress,
        uint256 value
    );
    event AuctionPass(uint256 indexed tokenID);

    bool private _mutex;
    modifier _lock_() {
        require(!_mutex, "reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    constructor(
        address _nftAsset,
        address _usdToken,
        address _previous_version
    ) {
        nftAsset = _nftAsset;
        usdToken = _usdToken;
        previous_version = _previous_version;
    }

    function createAndSell(
        string memory _tokenURI,
        uint256 _price,
        address _paymentToken,
        bool _isBid,
        uint256 _endTime
    ) external returns (uint256) {
        uint256 tokenID =
            ERC721Like(nftAsset).awardItem(address(this), _tokenURI);

        royalty[tokenID] = msg.sender;

        _sell(tokenID, _price, _paymentToken, _isBid, _endTime);

        return tokenID;
    }

    function sell(
        uint256 _tokenID,
        uint256 _price,
        address _paymentToken,
        bool _isBid,
        uint256 _endTime
    ) external {
        ERC721Like(nftAsset).transferFrom(msg.sender, address(this), _tokenID);

        if (royalty[_tokenID] == address(0)) {
            address temp = MarketLike(previous_version).royalty(_tokenID);
            if (temp != address(0)) {
                royalty[_tokenID] = temp;
            } else {
                royalty[_tokenID] = msg.sender;
            }
        }

        _sell(_tokenID, _price, _paymentToken, _isBid, _endTime);
    }

    function _sell(
        uint256 _tokenID,
        uint256 _price,
        address _paymentToken,
        bool _isBid,
        uint256 _endTime
    ) internal {
        if (_paymentToken != address(0)) {
            nftOffered[_tokenID] = Offer(
                true,
                _isBid,
                _tokenID,
                msg.sender,
                _price,
                usdToken,
                _endTime
            );
        } else {
            nftOffered[_tokenID] = Offer(
                true,
                _isBid,
                _tokenID,
                msg.sender,
                _price,
                _paymentToken,
                _endTime
            );
        }

        emit Offered(
            _tokenID,
            msg.sender,
            _price,
            _paymentToken,
            _isBid,
            _endTime
        );
    }

    function noLongerForSale(uint256 tokenID) external {
        Offer memory offer = nftOffered[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(msg.sender == offer.seller, "Only the seller can operate");
        require(!offer.isBid, "The auction cannot be cancelled");

        ERC721Like(nftAsset).transferFrom(address(this), offer.seller, tokenID);
        delete nftOffered[tokenID];
        emit NoLongerForSale(tokenID);
    }

    function buy(uint256 _tokenID) external payable _lock_ {
        Offer memory offer = nftOffered[_tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(!offer.isBid, "nft is auction mode");
        uint256 share1 = (offer.price * transferFee) / 1000;

        if (offer.paymentToken != address(0)) {
            USDTLike(offer.paymentToken).transferFrom(
                msg.sender,
                address(this),
                offer.price
            );
            USDTLike(offer.paymentToken).transfer(
                offer.seller,
                offer.price - share1
            );
        } else {
            require(
                msg.value >= offer.price,
                "Sorry, your credit is running low"
            );
            payable(offer.seller).transfer(offer.price - share1);
        }

        ERC721Like(nftAsset).transferFrom(address(this), msg.sender, _tokenID);
        emit Bought(
            offer.seller,
            msg.sender,
            _tokenID,
            offer.price,
            offer.paymentToken
        );
        delete nftOffered[_tokenID];
    }

    function enterBid(uint256 tokenID, uint256 amount) external payable _lock_ {
        Offer memory offer = nftOffered[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "nft must beauction mode");
        if (offer.endTime > 0) {
            require(block.timestamp < offer.endTime, "The auction is over");
        }

        if (!bade[tokenID][msg.sender]) {
            bidders[tokenID].push(msg.sender);
            bade[tokenID][msg.sender] = true;
        }

        Bid memory bid = currentBid[tokenID];
        if (offer.paymentToken != address(0)) {
            require(
                amount + offerBalances[tokenID][msg.sender] >= offer.price,
                "The bid cannot be lower than the starting price"
            );
            require(
                amount + offerBalances[tokenID][msg.sender] >
                    (bid.value * (bidGrowth + 1000)) / 1000,
                "This quotation is less than the current quotation"
            );
            USDTLike(offer.paymentToken).transferFrom(
                msg.sender,
                address(this),
                amount
            );
            currentBid[tokenID] = Bid(
                tokenID,
                msg.sender,
                amount + offerBalances[tokenID][msg.sender]
            );
            nftBids[tokenID].push(currentBid[tokenID]);
            emit BidEntered(tokenID, msg.sender, amount);
            offerBalances[tokenID][msg.sender] += amount;
        } else {
            require(
                msg.value + offerBalances[tokenID][msg.sender] >= offer.price,
                "The bid cannot be lower than the starting price"
            );
            require(
                msg.value + offerBalances[tokenID][msg.sender] > bid.value,
                "This quotation is less than the current quotation"
            );
            currentBid[tokenID] = Bid(
                tokenID,
                msg.sender,
                msg.value + offerBalances[tokenID][msg.sender]
            );
            nftBids[tokenID].push(currentBid[tokenID]);
            emit BidEntered(tokenID, msg.sender, msg.value);
            offerBalances[tokenID][msg.sender] += msg.value;
        }
    }

    function deal(uint256 tokenID) external _lock_ {
        Offer memory offer = nftOffered[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "must be auction mode");
        require(offer.endTime != 0, "Open ended auction");
        require(offer.endTime < block.timestamp, "The auction is not over yet");

        Bid memory bid = currentBid[tokenID];
        // Bid memory bid = nftBids[tokenID][nftBids[tokenID].length -1];

        if (bid.value >= offer.price) {
            uint256 share_Contract =
                ((offer.price +
                    ((bid.value - offer.price) * sellerFee) /
                    1000) * transferFee) / 1000;
            uint256 share_Seller =
                ((offer.price +
                    ((bid.value - offer.price) * sellerFee) /
                    1000) * (1000 - transferFee)) / 1000;
            uint256 share_Author = (share_Contract * authorFee) / 1000;

            if (offer.paymentToken != address(0)) {
                USDTLike(offer.paymentToken).transfer(
                    royalty[tokenID],
                    share_Author
                );
                USDTLike(offer.paymentToken).transfer(
                    offer.seller,
                    share_Seller
                );

                for (uint256 i = 0; i < nftBids[tokenID].length - 1; i++) {
                    uint256 share_bidder = 0;
                    if (i == 0) {
                        share_bidder =
                            ((nftBids[tokenID][i].value - offer.price) *
                                overflowFee) /
                            100;
                    } else {
                        share_bidder =
                            ((nftBids[tokenID][i].value -
                                nftBids[tokenID][i - 1].value) * overflowFee) /
                            100;
                    }
                    USDTLike(offer.paymentToken).transfer(
                        nftBids[tokenID][i].bidder,
                        share_bidder
                    );
                }

                for (uint256 i = 0; i < bidders[tokenID].length; i++) {
                    if (bid.bidder != bidders[tokenID][i]) {
                        uint256 offerBalance =
                            offerBalances[tokenID][bidders[tokenID][i]];
                        offerBalances[tokenID][bidders[tokenID][i]] = 0;
                        USDTLike(offer.paymentToken).transfer(
                            bidders[tokenID][i],
                            offerBalance
                        );
                        delete bade[tokenID][bidders[tokenID][i]];
                    }
                }
            } else {
                payable(royalty[tokenID]).transfer(share_Author);
                payable(offer.seller).transfer(share_Seller);
                for (uint256 i = 0; i < nftBids[tokenID].length - 1; i++) {
                    uint256 share_bidder = 0;
                    if (i == 0) {
                        share_bidder =
                            ((nftBids[tokenID][i].value - offer.price) * 30) /
                            100;
                    } else {
                        share_bidder =
                            ((nftBids[tokenID][i].value -
                                nftBids[tokenID][i - 1].value) * 30) /
                            100;
                    }
                    payable(nftBids[tokenID][i].bidder).transfer(share_bidder);
                }

                for (uint256 i = 0; i < bidders[tokenID].length; i++) {
                    if (bid.bidder != bidders[tokenID][i]) {
                        uint256 offerBalance =
                            offerBalances[tokenID][bidders[tokenID][i]];
                        offerBalances[tokenID][bidders[tokenID][i]] = 0;
                        payable(bidders[tokenID][i]).transfer(offerBalance);
                        delete bade[tokenID][bidders[tokenID][i]];
                    }
                }
            }
            offerBalances[tokenID][bid.bidder] = 0;
            delete bade[tokenID][bid.bidder];
            delete bidders[tokenID];
            delete nftBids[tokenID];

            ERC721Like(nftAsset).transferFrom(
                address(this),
                bid.bidder,
                tokenID
            );
            emit Bought(
                offer.seller,
                bid.bidder,
                tokenID,
                bid.value,
                offer.paymentToken
            );
        } else {
            ERC721Like(nftAsset).transferFrom(
                address(this),
                offer.seller,
                tokenID
            );
            emit AuctionPass(tokenID);
        }
        delete nftOffered[tokenID];
        delete currentBid[tokenID];
    }

    function recoveryEth(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    function recoveryUsdt(uint256 amount) external onlyOwner {
        USDTLike(usdToken).transfer(owner, amount);
    }

    function setTransferFee(uint256 _transferFee) external onlyOwner {
        require(_transferFee > 0);
        transferFee = _transferFee;
    }

    function setSellerFee(uint256 _sellerFee) external onlyOwner {
        require(_sellerFee > 0);
        sellerFee = _sellerFee;
    }

    function setAuthorFee(uint256 _authorFee) external onlyOwner {
        require(_authorFee > 0);
        authorFee = _authorFee;
    }

    function setOverflowFee(uint256 _overflowFee) external onlyOwner {
        require(_overflowFee > 0);
        overflowFee = _overflowFee;
    }

    function setBidGrowth(uint256 _bidGrowth) external onlyOwner {
        require(_bidGrowth > 0);
        bidGrowth = _bidGrowth;
    }

    receive() external payable {}
}