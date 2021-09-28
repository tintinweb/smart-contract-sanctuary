// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";
import "./ERC721Holder.sol";

contract WaifuHouse is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Holder,
    Ownable
{
    struct Order {
        uint8 orderType; //0:Fixed Price, 1:Dutch Auction, 2:English Auction
        address seller;
        IERC721 token;
        uint256 tokenId;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startBlock;
        uint256 endBlock;
        uint256 lastBidPrice;
        address lastBidder;
        bool isSold;
    }
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 16;

    uint256 public mintPrice = 66600000 gwei; // 0.0666 ETH

    bool public saleIsActive = false;

    bool public buildingIsActive = false;

    string public baseURI;

    string public provenance;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    address[2] private _shareholders;

    uint256[2] private _shares;

    address private _manager;

    event WaifuBuilt(
        uint256 firstTokenId,
        uint256 secondTokenId,
        uint256 builtWaifuTokenId
    );
    // Mapping from token ID to the amount of claimable eth in gwei
    mapping(uint256 => uint256) private _claimableEth;
    mapping(IERC721 => mapping(uint256 => bytes32[])) public orderIdByToken;
    mapping(address => bytes32[]) public orderIdBySeller;
    mapping(bytes32 => Order) public orderInfo;

    address public feeAddress;
    uint16 public feePercent;

    event MakeOrder(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller
    );
    event CancelOrder(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller
    );
    event Bid(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address bidder,
        uint256 bidPrice
    );
    event Claim(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller,
        address taker,
        uint256 price
    );

    event PaymentReleased(address to, uint256 amount);

    event EthDeposited(uint256 amount);

    event EthClaimed(address to, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxWaifuSupply
    ) ERC721(name, symbol) {
        maxTokenSupply = maxWaifuSupply;

        feeAddress = msg.sender;
        feePercent = 10000;

        _shareholders[0] = 0xd0fFF29a9bB5C3D8AFeB0FBC5c5272614C2300d8;
        _shareholders[1] = 0xeEEb5a14ff494A8D20F90CF12Be73Cd8b1c9A74D;
        _shares[0] = 5000;
        _shares[1] = 5000;
    }

    function setMaxTokenSupply(uint256 maxWaifuSupply) public onlyOwner {
        maxTokenSupply = maxWaifuSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdrawForGiveaway(uint256 amount, address payable to)
        public
        onlyOwner
    {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");

        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 2; i++) {
            uint256 payment = (amount * _shares[i]) / totalShares;
            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    /*
     * Mint reserved NFTs for giveaways, devs, etc.
     */
    function reserveMint(uint256 reservedAmount) public onlyOwner {
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(msg.sender, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
     * Mint reserved NFTs for giveaways, devs, etc.
     */
    function reserveMint(uint256 reservedAmount, address mintAddress)
        public
        onlyOwner
    {
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
     * Pause sale if active, make active if paused.
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
     * Pause building if active, make active if paused.
     */
    function flipBuildingState() public onlyOwner {
        buildingIsActive = !buildingIsActive;
    }

    /*
     * Mint Waifu House NFTs, woo!
     */
    function mintWaifu(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint houses");
        require(
            numberOfTokens <= MAX_MINTS_PER_TXN,
            "You can only mint 16 houses at a time"
        );
        require(
            totalSupply() + numberOfTokens <= maxTokenSupply,
            "Purchase would exceed max available houses"
        );
        require(
            mintPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        }

        // If we haven't set the starting index, set the starting index block.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }
    }

    /*
     * Set the manager address for deposits.
     */
    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }

    /**
     * @dev Throws if called by any account other than the owner or manager.
     */
    modifier onlyOwnerOrManager() {
        require(
            owner() == _msgSender() || _manager == _msgSender(),
            "Caller is not the owner or manager"
        );
        _;
    }

    /*
     * Deposit eth for distribution to token owners.
     */
    function deposit() public payable onlyOwnerOrManager {
        uint256 tokenCount = totalSupply();
        uint256 claimableAmountPerToken = msg.value / tokenCount;

        for (uint256 i = 0; i < tokenCount; i++) {
            // Iterate over all existing tokens (that have not been burnt)
            _claimableEth[tokenByIndex(i)] += claimableAmountPerToken;
        }

        emit EthDeposited(msg.value);
    }

    /*
     * Get the claimable balance of a token ID.
     */
    function claimableBalanceOfTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _claimableEth[tokenId];
    }

    /*
     * Get the total claimable balance for an owner.
     */
    function claimableBalance(address owner) public view returns (uint256) {
        uint256 balance = 0;
        uint256 numTokens = balanceOf(owner);

        for (uint256 i = 0; i < numTokens; i++) {
            balance += claimableBalanceOfTokenId(tokenOfOwnerByIndex(owner, i));
        }

        return balance;
    }

    function claim() public {
        uint256 amount = 0;
        uint256 numTokens = balanceOf(msg.sender);

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            amount += _claimableEth[tokenId];
            // Empty out all the claimed amount so as to protect against re-entrancy attacks.
            _claimableEth[tokenId] = 0;
        }

        require(amount > 0, "There is no amount left to claim");

        emit EthClaimed(msg.sender, amount);

        // We must transfer at the very end to protect against re-entrancy.
        Address.sendValue(payable(msg.sender), amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Set the starting index for the collection.
     */
    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % maxTokenSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (block.number - startingIndexBlock > 255) {
            startingIndex =
                uint256(blockhash(block.number - 1)) %
                maxTokenSupply;
        }
        // Prevent default sequence.
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }

    function buidWaifu(uint256 firstTokenId, uint256 secondTokenId) public {
        require(
            buildingIsActive && !saleIsActive,
            "Either sale is currently active or cooking is inactive"
        );
        require(
            _isApprovedOrOwner(_msgSender(), firstTokenId) &&
                _isApprovedOrOwner(_msgSender(), secondTokenId),
            "Caller is not owner nor approved"
        );

        // burn the 2 tokens
        _burn(firstTokenId);
        _burn(secondTokenId);

        // mint new token
        uint256 builtWaifuTokenId = _tokenIdCounter.current() + 1;
        _safeMint(msg.sender, builtWaifuTokenId);
        _tokenIdCounter.increment();

        // fire event in logs
        emit WaifuBuilt(firstTokenId, secondTokenId, builtWaifuTokenId);
    }

    /**
     * Set the starting index block for the collection. Usually, this will be set after the first sale mint.
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    /*
     * Set provenance once it's calculated.
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // view fx
    function getCurrentPrice(bytes32 _order) public view returns (uint256) {
        Order storage o = orderInfo[_order];
        uint8 orderType = o.orderType;
        if (orderType == 0) {
            return o.startPrice;
        } else if (orderType == 2) {
            uint256 lastBidPrice = o.lastBidPrice;
            return lastBidPrice == 0 ? o.startPrice : lastBidPrice;
        } else {
            uint256 _startPrice = o.startPrice;
            uint256 _startBlock = o.startBlock;
            uint256 tickPerBlock = (_startPrice - o.endPrice) /
                (o.endBlock - _startBlock);
            return _startPrice - ((block.number - _startBlock) * tickPerBlock);
        }
    }

    function tokenOrderLength(IERC721 _token, uint256 _id)
        external
        view
        returns (uint256)
    {
        return orderIdByToken[_token][_id].length;
    }

    function sellerOrderLength(address _seller)
        external
        view
        returns (uint256)
    {
        return orderIdBySeller[_seller].length;
    }

    // make order fx
    //0:Fixed Price, 1:Dutch Auction, 2:English Auction
    function dutchAuction(
        IERC721 _token,
        uint256 _id,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _endBlock
    ) public {
        require(
            _startPrice > _endPrice,
            "End price should be lower than start price"
        );
        _makeOrder(1, _token, _id, _startPrice, _endPrice, _endBlock);
    } //sp != ep

    function englishAuction(
        IERC721 _token,
        uint256 _id,
        uint256 _startPrice,
        uint256 _endBlock
    ) public {
        _makeOrder(2, _token, _id, _startPrice, 0, _endBlock);
    } //ep=0. for gas saving.

    function fixedPrice(
        IERC721 _token,
        uint256 _id,
        uint256 _price,
        uint256 _endBlock
    ) public {
        _makeOrder(0, _token, _id, _price, 0, _endBlock);
    } //ep=0. for gas saving.

    function _makeOrder(
        uint8 _orderType,
        IERC721 _token,
        uint256 _id,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _endBlock
    ) internal {
        require(_endBlock > block.number, "Duration must be more than zero");

        //push
        bytes32 hash = _hash(_token, _id, msg.sender);
        orderInfo[hash] = Order(
            _orderType,
            msg.sender,
            _token,
            _id,
            _startPrice,
            _endPrice,
            block.number,
            _endBlock,
            0,
            address(0),
            false
        );
        orderIdByToken[_token][_id].push(hash);
        orderIdBySeller[msg.sender].push(hash);

        //check if seller has a right to transfer the NFT token. safeTransferFrom.
        _token.safeTransferFrom(msg.sender, address(this), _id);

        emit MakeOrder(_token, _id, hash, msg.sender);
    }

    function _hash(
        IERC721 _token,
        uint256 _id,
        address _seller
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.number, _token, _id, _seller));
    }

    // take order fx
    //you have to pay only ETH for bidding and buying.

    //In this contract, since send function is used instead of transfer or low-level call function,
    //if a participant is a contract, it must have receive payable function.
    //But if it has some code in either receive or fallback fx, they might not be able to receive their ETH.
    //Even though some contracts can't receive their ETH, the transaction won't be failed.

    //Bids must be at least 5% higher than the previous bid.
    //If someone bids in the last 5 minutes of an auction, the auction will automatically extend by 5 minutes.
    function bid(bytes32 _order) external payable {
        Order storage o = orderInfo[_order];
        uint256 endBlock = o.endBlock;
        uint256 lastBidPrice = o.lastBidPrice;
        address lastBidder = o.lastBidder;

        require(o.orderType == 2, "only for English Auction");
        require(endBlock != 0, "Canceled order");
        require(block.number <= endBlock, "It's over");
        require(o.seller != msg.sender, "Can not bid to your order");

        if (lastBidPrice != 0) {
            require(
                msg.value >= lastBidPrice + (lastBidPrice / 20),
                "low price bid"
            ); //5%
        } else {
            require(
                msg.value >= o.startPrice && msg.value > 0,
                "low price bid"
            );
        }

        if (block.number > endBlock - 20) {
            //20blocks = 5 mins in Etherium.
            o.endBlock = endBlock + 20;
        }

        o.lastBidder = msg.sender;
        o.lastBidPrice = msg.value;

        if (lastBidPrice != 0) {
            payable(lastBidder).transfer(lastBidPrice);
        }

        emit Bid(o.token, o.tokenId, _order, msg.sender, msg.value);
    }

    function buyItNow(bytes32 _order) external payable {
        Order storage o = orderInfo[_order];
        uint256 endBlock = o.endBlock;
        require(endBlock != 0, "Canceled order");
        require(endBlock > block.number, "It's over");
        require(o.orderType < 2, "It's a English Auction");
        require(o.isSold == false, "Already sold");

        uint256 currentPrice = getCurrentPrice(_order);
        require(msg.value >= currentPrice, "price error");

        o.isSold = true; //reentrancy proof

        uint256 fee = (currentPrice * feePercent) / 10000;
        payable(o.seller).transfer(currentPrice - fee);
        payable(feeAddress).transfer(fee);
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }

        o.token.safeTransferFrom(address(this), msg.sender, o.tokenId);

        emit Claim(
            o.token,
            o.tokenId,
            _order,
            o.seller,
            msg.sender,
            currentPrice
        );
    }

    //both seller and taker can call this fx in English Auction. Probably the taker(last bidder) might call this fx.
    //In both DA and FP, buyItNow fx include claim fx.
    function claimfx(bytes32 _order) external {
        Order storage o = orderInfo[_order];
        address seller = o.seller;
        address lastBidder = o.lastBidder;
        require(o.isSold == false, "Already sold");

        require(
            seller == msg.sender || lastBidder == msg.sender,
            "Access denied"
        );
        require(o.orderType == 2, "This function is for English Auction");
        require(block.number > o.endBlock, "Not yet");

        IERC721 token = o.token;
        uint256 tokenId = o.tokenId;
        uint256 lastBidPrice = o.lastBidPrice;

        uint256 fee = (lastBidPrice * feePercent) / 10000;

        o.isSold = true;

        payable(seller).transfer(lastBidPrice - fee);
        payable(feeAddress).transfer(fee);
        token.safeTransferFrom(address(this), lastBidder, tokenId);

        emit Claim(token, tokenId, _order, seller, lastBidder, lastBidPrice);
    }

    function cancelOrder(bytes32 _order) external {
        Order storage o = orderInfo[_order];
        require(o.seller == msg.sender, "Access denied");
        require(o.lastBidPrice == 0, "Bidding exist"); //for EA. but even in DA, FP, seller can withdraw his/her token with this fx.
        require(o.isSold == false, "Already sold");

        IERC721 token = o.token;
        uint256 tokenId = o.tokenId;

        o.endBlock = 0; //0 endBlock means the order was canceled.

        token.safeTransferFrom(address(this), msg.sender, tokenId);
        emit CancelOrder(token, tokenId, _order, msg.sender);
    }

    //feeAddress must be either an EOA or a contract must have payable receive fx and doesn't have some codes in that fx.
    //If not, it might be that it won't be receive any fee.
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function updateFeePercent(uint16 _percent) external onlyOwner {
        require(_percent <= 10000, "input value is more than 100%");
        feePercent = _percent;
    }
}