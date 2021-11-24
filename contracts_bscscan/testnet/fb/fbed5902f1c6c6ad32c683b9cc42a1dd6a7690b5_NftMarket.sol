/**
 *Submitted for verification at BscScan.com on 2021-11-24
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
    function tokenURI(uint256 tokenId) external returns (string memory);
    function ownerOf(uint256 tokenId) external returns (address);
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
    address public revenueRecipient;
    string public constant version = "2.0.5";
    uint public constant mintFee = 10 * 1e8;
    uint256 public constant transferFee = 5;

    // make some changes for donation
    // address originator
    // bool isDonate
    struct Offer {
        bool isForSale;
        uint256 tokenID;
        address originator;
        address seller;
        address organization;
        bool isBid;
        bool isDonated;
        uint256 minValue;
        uint256 endTime;
        uint256 reward;
    }
    
    // transaction
    struct Transaction {
        uint256 tokenID;
        address caller;
        bool isDonated;
        bool isBid;
        address creator;
        address seller;
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
    // txhash 
    mapping(uint256 => Transaction) public txMessage;
    mapping(uint256 => mapping(address => uint256)) public offerBalances;
    mapping(uint256 => address[]) public bidders;
    mapping(uint256 => mapping(address => bool)) public bade;
    
    // NFTs isExist or not 
    mapping(address => mapping(string => uint256)) public isExist;
    // danotion across
    mapping(address => mapping(string => bool)) public isSencond;
    // donated oraganizations are approved or not
    mapping(address => bool) public isApprovedOrg;

    event Offered(
        uint256 indexed tokenID,
        bool indexed isBid,
        bool indexed isDonated,
        uint256 minValue
    );
    event BidEntered(
        uint256 indexed tokenID,
        address fromAddress,
        uint256 value,
        bool indexed isBid,
        bool indexed isDonated
    );
    event Bought(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 indexed tokenID,
        uint256 value
    );
    event NoLongerForSale(uint256 indexed tokenID);
    event AuctionPass(uint256 indexed tokenID);
    event DealTransaction(
        uint256 indexed tokenID,
        bool indexed isDonated,
        address creator,
        address indexed seller
    );

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
        isExist[msg.sender][_tokenURI] = tokenID;

        return tokenID;
    }
    
    // approve the donated oraganizations
    function approveOrganization(address _organization) external _lock_ {
        require(_organization != address(0), "organization is null");
        isApprovedOrg[_organization] = true;
    }
    
    // fake create NFTs (donate the value to the organization; usual transaction)
    function buyNFTWithMultiStep(bool _isDonated, address _creator, string memory _tokenURI, uint256 _royalty, bool _isBid,
        uint256 _minSalePrice, uint256 _endTime, uint256 _reward, address _organization) external payable _lock_ returns(uint256, bool) {
        require(_royalty < 30, "Excessive copyright fees");
        
        uint256 _tokenid = isExist[_creator][_tokenURI];
        address seller = _creator;
        if(isExist[_creator][_tokenURI] == 0) {
            
            //create
            uint256 tokenID = ERC721Like(nftAsset).awardItem(_creator, _tokenURI);
            royalty[tokenID] = Royalty(_creator, _royalty, false);
            isExist[_creator][_tokenURI] = tokenID;
            _tokenid = isExist[_creator][_tokenURI];
            
        } else {
            seller = ERC721Like(nftAsset).ownerOf(_tokenid);
        }
        
        //approve 
        ERC721Like(nftAsset).setApproval(seller, msg.sender, true);
        
        ERC721Like(nftAsset).approveForMarket(seller, msg.sender, address(this), _tokenid);
        
        //register 
        require(_endTime <= block.timestamp + 30 days, "Maximum time exceeded");
        require(_endTime > block.timestamp + 5 minutes, "Below minimum time");
        require(
            _reward < 100 - transferFee - royalty[_tokenid].royalty,
            "Excessive reward"
        );
        ERC721Like(nftAsset).transferFrom(seller, address(this), _tokenid);
        nftOfferedForSale[_tokenid] = Offer(
            true,
            _tokenid,
            _creator,
            seller,
            _organization,
            _isBid,
            _isDonated,
            _minSalePrice,
            _endTime,
            _reward
        );
        emit Offered(_tokenid, _isBid, _isDonated, _minSalePrice);
        
        // buy
        Offer memory offer = nftOfferedForSale[_tokenid];
        require(offer.isForSale, "nft not actually for sale");
        require(!offer.isBid, "nft is auction mode");

        uint256 share1 = (offer.minValue * royalty[_tokenid].royalty) / 100;
        uint256 share2 = (offer.minValue * transferFee) / 100;

        require(
            msg.value >= offer.minValue,
            "Sorry, your credit is running low"
        );
        payable(royalty[_tokenid].originator).transfer(share1);
        
        if(!_isDonated) {
            // No donation
           payable(revenueRecipient).transfer(share2); 
           payable(offer.seller).transfer(offer.minValue - share1 - share2);
        }else {
            // donate
            require(isApprovedOrg[_organization], "the organization is not approved");
            payable(_organization).transfer(offer.minValue - share1);
        }
    
        txMessage[_tokenid] = Transaction(
            _tokenid,
            msg.sender,
            offer.isDonated,
            _isBid,
            royalty[_tokenid].originator,
            offer.seller
        );
        
        ERC721Like(nftAsset).transferFrom(address(this), msg.sender, _tokenid);
        
        emit Bought(
            offer.seller,
            msg.sender,
            _tokenid,
            offer.minValue
        );
        
        emit DealTransaction(
            _tokenid,
            offer.isDonated,
            royalty[_tokenid].originator,
             offer.seller
        );
        delete nftOfferedForSale[_tokenid];
        
        return (_tokenid, txMessage[_tokenid].isDonated);
    }
    
    //the auction
    function enterBidWithMultiStep(bool _isDonated, address _creator, string memory _tokenURI, uint256 _royalty, bool _isBid,
        uint256 _minSalePrice, uint256 _endTime, uint256 _reward, address _organization)external payable _lock_ returns(uint256) {
        uint256 _tokenid = isExist[_creator][_tokenURI];
        address seller = _creator;
    
        // is the first offer
        if(isExist[_creator][_tokenURI] == 0 || !isSencond[_creator][_tokenURI]) {
            require(_royalty < 30, "Excessive copyright fees");
            isSencond[_creator][_tokenURI] = true;
            
            if(isExist[_creator][_tokenURI] == 0) {
                //create
                uint256 tokenID = ERC721Like(nftAsset).awardItem(_creator, _tokenURI);
                royalty[tokenID] = Royalty(_creator, _royalty, false);
                _tokenid = tokenID;
                isExist[_creator][_tokenURI] = tokenID;
            }
            
            if(isExist[_creator][_tokenURI] != 0) {
                seller = ERC721Like(nftAsset).ownerOf(_tokenid);
            }
            
            //approve 
            ERC721Like(nftAsset).setApproval(seller, msg.sender, true);
            
            ERC721Like(nftAsset).approveForMarket(seller, msg.sender, address(this), _tokenid);
            
            //register 
            require(_endTime <= block.timestamp + 30 days, "Maximum time exceeded");
            require(_endTime > block.timestamp + 5 minutes, "Below minimum time");
            require(
                _reward < 100 - transferFee - royalty[_tokenid].royalty,
                "Excessive reward"
            );
            ERC721Like(nftAsset).transferFrom(seller, address(this), _tokenid);
            nftOfferedForSale[_tokenid] = Offer(
                true,
                _tokenid,
                _creator,
                seller,
                _organization,
                _isBid,
                _isDonated,
                _minSalePrice,
                _endTime,
                _reward
            );
            emit Offered(_tokenid, _isBid, _isDonated, _minSalePrice);
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
            emit BidEntered(_tokenid, msg.sender, msg.value, offer.isBid, offer.isDonated);
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
        bool isDonated,
        uint256 minSalePrice,
        uint256 endTime,
        uint256 reward,
        address organization
    ) external _lock_ {
        if(isBid) {
            require(endTime <= block.timestamp + 30 days, "Maximum time exceeded");
            require(endTime > block.timestamp + 5 minutes, "Below minimum time");
        } 
        
        require(
            reward < 100 - transferFee - royalty[tokenID].royalty,
            "Excessive reward"
        );
        ERC721Like(nftAsset).transferFrom(msg.sender, address(this), tokenID);
        
        //sell
        nftOfferedForSale[tokenID] = Offer(
            true,
            tokenID,
            royalty[tokenID].originator,
            msg.sender,
            organization,
            isBid,
            isDonated,
            minSalePrice,
            endTime,
            reward
        );
        
        emit Offered(tokenID, isBid, isDonated, minSalePrice);
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

    function buy(uint256 tokenID) external payable _lock_ returns(bool){
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(!offer.isBid, "nft is auction mode");

        uint256 share1 = (offer.minValue * transferFee) / 100;
        uint256 share2 = (offer.minValue * royalty[tokenID].royalty) / 100;

        require(
            msg.value >= offer.minValue,
            "Sorry, your credit is running low"
        );
        
        payable(royalty[tokenID].originator).transfer(share2);
        if(offer.isDonated) {
            require(offer.organization != address(0), "The donated organization is null");
            require(isApprovedOrg[offer.organization], "the organization is not approved");
            payable(offer.organization).transfer(offer.minValue - share2);
        }else {
            payable(revenueRecipient).transfer(share1);
            payable(offer.seller).transfer(offer.minValue - share1 - share2);
        }
        
        txMessage[tokenID] = Transaction(
            tokenID,
            msg.sender,
            false,
            false,
            royalty[tokenID].originator,
            offer.seller
        );
        ERC721Like(nftAsset).transferFrom(address(this), msg.sender, tokenID);
        
        emit Bought(
            offer.seller,
            msg.sender,
            tokenID,
            offer.minValue
        );
        
        emit DealTransaction(
            tokenID,
            offer.isDonated,
            royalty[tokenID].originator,
            offer.seller
        );
        delete nftOfferedForSale[tokenID];
        return txMessage[tokenID].isDonated;
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
        emit BidEntered(tokenID, msg.sender, msg.value, offer.isBid, offer.isDonated);
        offerBalances[tokenID][msg.sender] += msg.value;
    
    }

    //  deal for donation or not
    function deal(uint256 tokenID) external _lock_ returns(bool) {
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

            uint256 tempD = bid.value - share2 - share3;
            payable(royalty[tokenID].originator).transfer(share2);
            
            if(offer.isDonated) {
                require(offer.organization != address(0), "The donated organization is null");
                require(isApprovedOrg[offer.organization], "the organization is not approved");
                payable(offer.organization).transfer(tempD);
            }else {
                tempD = bid.value - share1 - share2 - share3;
                payable(revenueRecipient).transfer(share1);
                payable(offer.seller).transfer(tempD);
            }

            offerBalances[tokenID][bid.bidder] = 0;
            delete bade[tokenID][bid.bidder];
            delete bidders[tokenID];

            txMessage[tokenID] = Transaction(
                tokenID,
                msg.sender,
                offer.isDonated,
                offer.isBid,
                royalty[tokenID].originator,
                offer.seller
            );
            
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
            
            emit DealTransaction(
                tokenID,
                offer.isDonated,
                royalty[tokenID].originator,
                offer.seller
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
        
        string memory _tokenURI = ERC721Like(nftAsset).tokenURI(tokenID);
        delete nftOfferedForSale[tokenID];
        delete nftBids[tokenID];
        if(isSencond[offer.originator][_tokenURI]) {
            delete isSencond[offer.originator][_tokenURI];
        }
        
        return txMessage[tokenID].isDonated;
    }

    function recoveryEth(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}