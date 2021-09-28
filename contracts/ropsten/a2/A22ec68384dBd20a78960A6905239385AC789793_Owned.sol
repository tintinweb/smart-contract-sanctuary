/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20Like {
    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

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
    address public abcToken;
    string public constant version = "2.0.2";
    address public revenueRecipient;
    uint256 public constant mintFee = 10 * 1e8;
    uint256 public constant transferFee = 5;

    struct Offer {
        bool isForSale;
        uint256 tokenID;
        address seller;
        bool isBid;
        uint256 minValue;
        uint256 endTime;
        address paymentToken;
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

    event Offered(
        uint256 indexed tokenID,
        uint256 minValue,
        address paymentToken
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
        uint256 value,
        address paymentToken
    );
    event NoLongerForSale(uint256 indexed tokenID);
    event AuctionPass(uint256 indexed tokenID);

    constructor(
        address _nftAsset,
        address _abcToken,
        address _revenueRecipient
    ) {
        nftAsset = _nftAsset;
        abcToken = _abcToken;
        revenueRecipient = _revenueRecipient;
    }

    function NewNft(string memory _tokenURI, uint256 _royalty)
        external
        returns (uint256)
    {
        require(_royalty < 30, "Excessive copyright fees");

        ERC20Like(abcToken).transferFrom(msg.sender, address(this), mintFee);
        ERC20Like(abcToken).transfer(revenueRecipient, mintFee);

        uint256 tokenID = ERC721Like(nftAsset).awardItem(msg.sender, _tokenURI);

        royalty[tokenID] = Royalty(msg.sender, _royalty, false);

        return tokenID;
    }

    function recommend(uint256 tokenID) external onlyOwner {
        royalty[tokenID].recommended = true;
    }

    function cancelRecommend(uint256 tokenID) external onlyOwner {
        royalty[tokenID].recommended = false;
    }

    /// @notice 挂单出售nft资产
    /// @param tokenID tokenID
    /// @param isBid 拍卖模式标记
    /// @param minSalePrice 起拍价 或 一口价
    /// @param endTime 拍卖模式，出价终止时间
    /// @param paymentToken 用于支付代币的种类
    /// @param reward 拍卖模式，用于奖励拍卖参与者的分成比率
    function sell(
        uint256 tokenID,
        bool isBid,
        uint256 minSalePrice,
        uint256 endTime,
        address paymentToken,
        uint256 reward
    ) external {
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
            paymentToken,
            reward
        );
        emit Offered(tokenID, minSalePrice, paymentToken);
    }

    function noLongerForSale(uint256 tokenID) external {
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(msg.sender == offer.seller, "Only the seller can operate");
        require(!offer.isBid, "The auction cannot be cancelled");

        ERC721Like(nftAsset).transferFrom(address(this), offer.seller, tokenID);
        delete nftOfferedForSale[tokenID];
        emit NoLongerForSale(tokenID);
    }

    function buy(uint256 tokenID) external payable {
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(!offer.isBid, "nft is auction mode");

        uint256 share1 = (offer.minValue * transferFee) / 100; // 平台分润数额
        uint256 share2 = (offer.minValue * royalty[tokenID].royalty) / 100; // 艺术家分润数额

        if (offer.paymentToken != address(0)) {
            ERC20Like(offer.paymentToken).transferFrom(
                msg.sender,
                address(this),
                offer.minValue
            );

            ERC20Like(offer.paymentToken).transfer(revenueRecipient, share1);
            ERC20Like(offer.paymentToken).transfer(
                royalty[tokenID].originator,
                share2
            );
            ERC20Like(offer.paymentToken).transfer(
                offer.seller,
                offer.minValue - share1 - share2
            );
        } else {
            require(
                msg.value >= offer.minValue,
                "Sorry, your credit is running low"
            );
            payable(revenueRecipient).transfer(share1); // 平台分润
            payable(royalty[tokenID].originator).transfer(share2); // 艺术家分润版税
            payable(offer.seller).transfer(offer.minValue - share1 - share2); // 销售者分润
        }
        ERC721Like(nftAsset).transferFrom(address(this), msg.sender, tokenID);
        emit Bought(
            offer.seller,
            msg.sender,
            tokenID,
            offer.minValue,
            offer.paymentToken
        );
        delete nftOfferedForSale[tokenID];
    }

    function enterBidForNft(uint256 tokenID, uint256 amount) public payable {
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "nft must beauction mode");
        require(block.timestamp < offer.endTime, "The auction is over");

        if (!bade[tokenID][msg.sender]) {
            bidders[tokenID].push(msg.sender);
            bade[tokenID][msg.sender] = true;
        }

        Bid memory bid = nftBids[tokenID];
        if (offer.paymentToken != address(0)) {
            require(
                amount + offerBalances[tokenID][msg.sender] >= offer.minValue,
                "The bid cannot be lower than the starting price"
            );
            require(
                amount + offerBalances[tokenID][msg.sender] > bid.value,
                "This quotation is less than the current quotation"
            );
            ERC20Like(offer.paymentToken).transferFrom(
                msg.sender,
                address(this),
                amount
            );
            nftBids[tokenID] = Bid(tokenID, msg.sender, amount);
            emit BidEntered(tokenID, msg.sender, amount);
        } else {
            require(
                msg.value + offerBalances[tokenID][msg.sender] >=
                    offer.minValue,
                "The bid cannot be lower than the starting price"
            );
            require(
                msg.value + offerBalances[tokenID][msg.sender] > bid.value,
                "This quotation is less than the current quotation"
            );
            nftBids[tokenID] = Bid(tokenID, msg.sender, msg.value);
            emit BidEntered(tokenID, msg.sender, msg.value);
        }
        // 累加出价者本次拍卖的金额
        offerBalances[tokenID][msg.sender] += amount;
    }

    // 拍卖结束后，交易双方完成提现处理。通常由买家调用本方法
    function deal(uint256 tokenID) external {
        Offer memory offer = nftOfferedForSale[tokenID];
        require(offer.isForSale, "nft not actually for sale");
        require(offer.isBid, "must be auction mode");
        require(offer.endTime < block.timestamp, "The auction is not over yet");

        Bid memory bid = nftBids[tokenID];

        if (bid.value >= offer.minValue) {
            // bid.value > 0 即可，上面代码保证了出价必须高于 offer.minValue
            uint256 share1 = (bid.value * transferFee) / 100; // 平台分润
            uint256 share2 = (offer.minValue * royalty[tokenID].royalty) / 100; // 艺术家分润
            uint256 share3 = 0; // 拍卖参与者分润
            uint256 totalBid = 0;

            // 汇总未成功拍卖参与者报价的总和
            for (uint256 i = 0; i < bidders[tokenID].length - 1; i++) {
                totalBid += offerBalances[tokenID][bidders[tokenID][i]];
            }

            if (offer.paymentToken != address(0)) {
                for (uint256 i = 0; i < bidders[tokenID].length - 1; i++) {
                    uint256 tempC =
                        (((bid.value * offer.reward) / 100) *
                            offerBalances[tokenID][bidders[tokenID][i]]) /
                            totalBid;
                    // 给拍卖参与者分润
                    ERC20Like(offer.paymentToken).transfer(
                        bidders[tokenID][i],
                        tempC
                    );
                    share3 += tempC;
                    // 给拍卖参与者退款
                    ERC20Like(offer.paymentToken).transfer(
                        bidders[tokenID][i],
                        offerBalances[tokenID][bidders[tokenID][i]]
                    );
                    // 清空可退款余额
                    offerBalances[tokenID][bidders[tokenID][i]] = 0;
                    // 清除已经竞拍标记
                    delete bade[tokenID][bidders[tokenID][i]];
                }

                ERC20Like(offer.paymentToken).transfer(
                    revenueRecipient,
                    share1
                );
                ERC20Like(offer.paymentToken).transfer(
                    royalty[tokenID].originator,
                    share2
                );
                ERC20Like(offer.paymentToken).transfer(
                    offer.seller,
                    bid.value - share1 - share2 - share3
                );
            } else {
                for (uint256 i = 0; i < bidders[tokenID].length - 1; i++) {
                    uint256 tempC =
                        (((bid.value * offer.reward) / 100) *
                            offerBalances[tokenID][bidders[tokenID][i]]) /
                            totalBid;
                    // 给拍卖参与者分润
                    payable(bidders[tokenID][i]).transfer(tempC);
                    share3 += tempC;
                    // 给拍卖参与者退款
                    payable(bidders[tokenID][i]).transfer(
                        offerBalances[tokenID][bidders[tokenID][i]]
                    );
                    // 清空可退款余额
                    offerBalances[tokenID][bidders[tokenID][i]] = 0;
                    // 清除已经竞拍标记
                    delete bade[tokenID][bidders[tokenID][i]];
                }

                payable(revenueRecipient).transfer(share1);
                payable(royalty[tokenID].originator).transfer(share2);
                uint256 tempD = bid.value - share1 - share2 - share3;
                payable(offer.seller).transfer(tempD);
            }
            // 清空中标者可退款余额
            offerBalances[tokenID][bid.bidder] = 0;
            // 清除中标者已经拍卖标记
            delete bade[tokenID][bid.bidder];
            // 清除本次拍卖所有拍卖参与者的钱包地址信息
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
                bid.value,
                offer.paymentToken
            );
        } else {
            // 没人出价，导致流拍
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