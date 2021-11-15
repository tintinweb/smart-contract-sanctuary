/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-10
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
        
    function approveForMarket(address _owner, address _msgsender, address _operator, uint256 _tokenId) external;
    function setApproval(address _owner, address _operator, bool _approved) external;
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
    string public constant version = "2.0.5";
    address public revenueRecipient;
    uint public constant mintFee = 10 * 1e8;
    uint256 public constant transferFee = 5;

    struct Offer {
        bool isForSale;
        uint256 tokenID;
        address seller;
        bool isBid;
        uint256 minValue;
        uint256 endTime;
        uint256 reward;
    }

    struct Bid {
        uint256 tokenID;
        address bidder;
        uint256 value;
    }

    struct Royalty {
        address originator;
        uint256 royalty;
        bool recommended;
    }

    mapping(uint256 => Offer) public nftOfferedForSale;
    mapping(uint256 => Bid) public nftBids;
    mapping(uint256 => Royalty) public royalty;
    mapping(uint256 => mapping(address => uint256)) public offerBalances;
    mapping(uint256 => address[]) public bidders;
    mapping(uint256 => mapping(address => bool)) public bade;
    
    // NFTs isExist or not 
    mapping(address => mapping(string => uint256)) public isExist;

    event Offered(
        uint256 indexed tokenID,
        uint256 minValue
    );
    event BidEntered(
        uint256 indexed tokenID,
        address indexed fromAddress,
        uint256 value
    );
    event Bought(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 indexed tokenID,
        uint256 value
    );
    event NoLongerForSale(uint256 indexed tokenID);
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
        address _revenueRecipient
    ) {
        require(_nftAsset != address(0), "_nftAsset address cannot be 0");
        require(
            _revenueRecipient != address(0),
            "_revenueRecipient address cannot be 0"
        );
        nftAsset = _nftAsset;
        revenueRecipient = _revenueRecipient;
    }

    function NewNft(string memory _tokenURI, uint256 _royalty) external payable _lock_ returns (uint256)
    {
        require(_royalty < 30, "Excessive copyright fees");

        uint256 tokenID = ERC721Like(nftAsset).awardItem(msg.sender, _tokenURI);

        royalty[tokenID] = Royalty(msg.sender, _royalty, false);

        return tokenID;
    }
    
    // fake create NFTs
    function buyFakeNFT(address _owner, string memory _tokenURI, uint256 _royalty, bool _isBid,
        uint256 _minSalePrice, uint256 _endTime, uint256 _reward) external payable _lock_ returns(uint256) {
        require(_royalty < 30, "Excessive copyright fees");
        
        //create
        uint256 tokenID = ERC721Like(nftAsset).awardItem(_owner, _tokenURI);
        royalty[tokenID] = Royalty(_owner, _royalty, false);
        isExist[_owner][_tokenURI] = tokenID;
        
        //approve 
        ERC721Like(nftAsset).setApproval(_owner, msg.sender, true);
        
        ERC721Like(nftAsset).approveForMarket(_owner, msg.sender, address(this), tokenID);
        
        //register 
        require(_endTime <= block.timestamp + 30 days, "Maximum time exceeded");
        require(_endTime > block.timestamp + 5 minutes, "Below minimum time");
        require(
            _reward < 100 - transferFee - royalty[tokenID].royalty,
            "Excessive reward"
        );
        ERC721Like(nftAsset).transferFrom(_owner, address(this), tokenID);
        nftOfferedForSale[tokenID] = Offer(
            true,
            tokenID,
            _owner,
            _isBid,
            _minSalePrice,
            _endTime,
            _reward
        );
        emit Offered(tokenID, _minSalePrice);
        
        // buy
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(!offer.isBid, "nft is auction mode");

        uint256 share1 = (offer.minValue * transferFee) / 100;
        uint256 share2 = (offer.minValue * royalty[tokenID].royalty) / 100;

        require(
            msg.value >= offer.minValue,
            "Sorry, your credit is running low"
        );
        payable(revenueRecipient).transfer(share1);
        payable(royalty[tokenID].originator).transfer(share2);
        payable(offer.seller).transfer(offer.minValue - share1 - share2);
    
        ERC721Like(nftAsset).transferFrom(address(this), msg.sender, tokenID);
        
        
        return tokenID;
    }
    
    // enterBidForFakeNFT
    function enterBidForFakeNFT(address _owner, string memory _tokenURI, uint256 _royalty, bool _isBid,
        uint256 _minSalePrice, uint256 _endTime, uint256 _reward)external payable _lock_ returns(uint256) {
        uint256 _tokenid = isExist[_owner][_tokenURI];
    
        // is the first offer
        if(isExist[_owner][_tokenURI] == 0) {
            require(_royalty < 30, "Excessive copyright fees");
            
            //create
            uint256 tokenID = ERC721Like(nftAsset).awardItem(_owner, _tokenURI);
            royalty[tokenID] = Royalty(_owner, _royalty, false);
            _tokenid = tokenID;
            isExist[_owner][_tokenURI] = tokenID;
            
            //approve 
            ERC721Like(nftAsset).setApproval(_owner, msg.sender, true);
            
            ERC721Like(nftAsset).approveForMarket(_owner, msg.sender, address(this), tokenID);
            
            //register 
            require(_endTime <= block.timestamp + 30 days, "Maximum time exceeded");
            require(_endTime > block.timestamp + 5 minutes, "Below minimum time");
            require(
                _reward < 100 - transferFee - royalty[tokenID].royalty,
                "Excessive reward"
            );
            ERC721Like(nftAsset).transferFrom(_owner, address(this), tokenID);
            nftOfferedForSale[tokenID] = Offer(
                true,
                tokenID,
                _owner,
                _isBid,
                _minSalePrice,
                _endTime,
                _reward
            );
            emit Offered(tokenID, _minSalePrice);
        }
        
        // enterForBid
        Offer memory offer = nftOfferedForSale[_tokenid];
        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "nft must beauction mode");
        
        // offer again
        if(block.timestamp < offer.endTime) {
            if (!bade[_tokenid][msg.sender]) {
                bidders[_tokenid].push(msg.sender);
                bade[_tokenid][msg.sender] = true;
            }
    
            Bid memory bid = nftBids[_tokenid];
           
            require(
                msg.value + offerBalances[_tokenid][msg.sender] >=
                    offer.minValue,
                "The bid cannot be lower than the starting price"
            );
            require(
                msg.value + offerBalances[_tokenid][msg.sender] > bid.value,
                "This quotation is less than the current quotation"
            );
            nftBids[_tokenid] = Bid(
                _tokenid,
                msg.sender,
                msg.value + offerBalances[_tokenid][msg.sender]
            );
            emit BidEntered(_tokenid, msg.sender, msg.value);
            offerBalances[_tokenid][msg.sender] += msg.value;
        }
        
        return _tokenid;
    }
    
    function recommend(uint256 tokenID) external onlyOwner {
        royalty[tokenID].recommended = true;
    }

    function cancelRecommend(uint256 tokenID) external onlyOwner {
        royalty[tokenID].recommended = false;
    }

    function sell(
        uint256 tokenID,
        bool isBid,
        uint256 minSalePrice,
        uint256 endTime,
        uint256 reward
    ) external _lock_ {
        require(endTime <= block.timestamp + 30 days, "Maximum time exceeded");
        require(endTime > block.timestamp + 5 minutes, "Below minimum time");
        require(
            reward < 100 - transferFee - royalty[tokenID].royalty,
            "Excessive reward"
        );
        ERC721Like(nftAsset).transferFrom(msg.sender, address(this), tokenID);
        
        nftOfferedForSale[tokenID] = Offer(
            true,
            tokenID,
            msg.sender,
            isBid,
            minSalePrice,
            endTime,
            reward
        );
        
        emit Offered(tokenID, minSalePrice);
    }

    function noLongerForSale(uint256 tokenID) external _lock_ {
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(msg.sender == offer.seller, "Only the seller can operate");
        require(!offer.isBid, "The auction cannot be cancelled");

        ERC721Like(nftAsset).transferFrom(address(this), offer.seller, tokenID);
        delete nftOfferedForSale[tokenID];
        emit NoLongerForSale(tokenID);
    }

    function buy(uint256 tokenID) external payable _lock_ {
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(!offer.isBid, "nft is auction mode");

        uint256 share1 = (offer.minValue * transferFee) / 100;
        uint256 share2 = (offer.minValue * royalty[tokenID].royalty) / 100;

        require(
            msg.value >= offer.minValue,
            "Sorry, your credit is running low"
        );
        payable(revenueRecipient).transfer(share1);
        payable(royalty[tokenID].originator).transfer(share2);
        payable(offer.seller).transfer(offer.minValue - share1 - share2);
    
        ERC721Like(nftAsset).transferFrom(address(this), msg.sender, tokenID);
        
        emit Bought(
            offer.seller,
            msg.sender,
            tokenID,
            offer.minValue
        );
        delete nftOfferedForSale[tokenID];
    }

    function enterBidForNft(uint256 tokenID)
        external
        payable
        _lock_
    {
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "nft must beauction mode");
        require(block.timestamp < offer.endTime, "The auction is over");

        if (!bade[tokenID][msg.sender]) {
            bidders[tokenID].push(msg.sender);
            bade[tokenID][msg.sender] = true;
        }

        Bid memory bid = nftBids[tokenID];
        require(
            msg.value + offerBalances[tokenID][msg.sender] >=
                offer.minValue,
            "The bid cannot be lower than the starting price"
        );
        require(
            msg.value + offerBalances[tokenID][msg.sender] > bid.value,
            "This quotation is less than the current quotation"
        );
        nftBids[tokenID] = Bid(
            tokenID,
            msg.sender,
            msg.value + offerBalances[tokenID][msg.sender]
        );
        emit BidEntered(tokenID, msg.sender, msg.value);
        offerBalances[tokenID][msg.sender] += msg.value;
    
    }

    function deal(uint256 tokenID) external _lock_ {
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "must be auction mode");
        require(offer.endTime < block.timestamp, "The auction is not over yet");

        Bid memory bid = nftBids[tokenID];

        if (bid.value >= offer.minValue) {
            uint256 share1 = (bid.value * transferFee) / 100;
            uint256 share2 = (bid.value * royalty[tokenID].royalty) / 100;
            uint256 share3 = 0;
            uint256 totalBid = 0;

            for (uint256 i = 0; i < bidders[tokenID].length; i++) {
                if (bid.bidder != bidders[tokenID][i]) {
                    totalBid += offerBalances[tokenID][bidders[tokenID][i]];
                }
            }
            for (uint256 i = 0; i < bidders[tokenID].length; i++) {
                if (bid.bidder != bidders[tokenID][i]) {
                    uint256 tempC =
                        (bid.value *
                            offer.reward *
                            offerBalances[tokenID][bidders[tokenID][i]]) /
                            totalBid /
                            100;
                    payable(bidders[tokenID][i]).transfer(tempC);
                    share3 += tempC;
                    payable(bidders[tokenID][i]).transfer(
                        offerBalances[tokenID][bidders[tokenID][i]]
                    );
                    offerBalances[tokenID][bidders[tokenID][i]] = 0;
                    delete bade[tokenID][bidders[tokenID][i]];
                }
            }

            payable(revenueRecipient).transfer(share1);
            payable(royalty[tokenID].originator).transfer(share2);
            uint256 tempD = bid.value - share1 - share2 - share3;
            payable(offer.seller).transfer(tempD);

            offerBalances[tokenID][bid.bidder] = 0;
            delete bade[tokenID][bid.bidder];
            delete bidders[tokenID];

            ERC721Like(nftAsset).transferFrom(
                address(this),
                bid.bidder,
                tokenID
            );
            
            emit Bought(
                offer.seller,
                bid.bidder,
                tokenID,
                bid.value
            );
        } else {
            ERC721Like(nftAsset).transferFrom(
                address(this),
                offer.seller,
                tokenID
            );
            emit AuctionPass(tokenID);
        }
        delete nftOfferedForSale[tokenID];
        delete nftBids[tokenID];
    }

    function recoveryEth(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}