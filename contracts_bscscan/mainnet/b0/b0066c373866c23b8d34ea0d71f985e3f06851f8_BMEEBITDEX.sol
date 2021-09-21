/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}


interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/*

_________  ___          _     _ _       
| ___ \  \/  |         | |   (_) |      
| |_/ / .  . | ___  ___| |__  _| |_ ___ 
| ___ \ |\/| |/ _ \/ _ \ '_ \| | __/ __|
| |_/ / |  | |  __/  __/ |_) | | |_\__ \
\____/\_|  |_/\___|\___|_.__/|_|\__|___/
                                        
                                        
https://bmeebits.com

*/


interface BMEEBIT{
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract BMEEBITDEX is ERC721TokenReceiver {
    using SafeMath for uint256;

    struct Offer {
        bool isForSale;
        uint nftIndex;
        address seller;
        uint minValue;          // in trx
        address onlySellTo;     // specify to sell only to a specific person
        uint offerListIndex;

    }

    struct Bid {
        bool hasBid;
        uint nftIndex;
        address bidder;
        uint value;
        uint counter;
    }

    uint public DexFeePercent = 6;

    address payable private feeBenefeciaryOne;
    address payable private feeBenefeciaryTwo;
    address payable private feeBenefeciaryThree;


    bool public marketPaused;

    address payable internal deployer;
    uint bidcounter = 0;
    BMEEBIT private tmeebits;

    // A record of nfts that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public nftsOfferedForSale;
    
    //Data about all open offers
    Offer[] public offers;

    // A record of the highest nft bid
    mapping (uint => Bid) public nftBids;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event NftTransfer(address indexed from, address indexed to, uint256 nftIndex);
    event NftOffered(uint indexed nftIndex, uint indexed minValue, address indexed toAddress);
    event NftBidEntered(uint indexed nftIndex, uint indexed value, address indexed fromAddress);
    event NftBidWithdrawn(uint indexed nftIndex, uint indexed value, address indexed fromAddress);
    event NftBought(uint indexed nftIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event NftSell(uint indexed nftIndex, uint indexed value, address indexed toAddress);
    event NftNoLongerForSale(uint indexed nftIndex);
    event ERC721Received(address operator, address _from, uint256 tokenId);

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    bool private reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(address _tmeebit, address payable _feeOne, address payable _feeTwo, address payable _feeThree) public {

        feeBenefeciaryOne = _feeOne;
        feeBenefeciaryTwo = _feeTwo;
        feeBenefeciaryThree = _feeThree;

        deployer = msg.sender;

        tmeebits = BMEEBIT(_tmeebit);

    }

    function pauseMarket(bool _paused) external onlyDeployer {
        marketPaused = _paused;
    }

    function offerNftForSale(uint nftIndex, uint minSalePriceInTrx) public reentrancyGuard {

        require(marketPaused == false, 'Market Paused');

        require(tmeebits.ownerOf(nftIndex) == msg.sender, 'Only owner');

        require((tmeebits.getApproved(nftIndex) == address(this) || tmeebits.isApprovedForAll(msg.sender, address(this))), 'Not Approved');

        tmeebits.safeTransferFrom(msg.sender, address(this), nftIndex);

        Offer memory currentOffer =  Offer(true, nftIndex, msg.sender, minSalePriceInTrx, address(0), offers.length);
        nftsOfferedForSale[nftIndex] = currentOffer;
        offers.push(currentOffer);

        emit NftOffered(nftIndex, minSalePriceInTrx, address(0));

    }

    function offerNftForSaleToAddress(uint nftIndex, uint minSalePriceInTrx, address toAddress) public reentrancyGuard {

        require(marketPaused == false, 'Market Paused');

        require(tmeebits.ownerOf(nftIndex) == msg.sender, 'Only owner');

        require((tmeebits.getApproved(nftIndex) == address(this) || tmeebits.isApprovedForAll(msg.sender, address(this))), 'Not Approved');

        tmeebits.safeTransferFrom(msg.sender, address(this), nftIndex);

        Offer memory currentOffer =  Offer(true, nftIndex, msg.sender, minSalePriceInTrx, toAddress, offers.length);
        nftsOfferedForSale[nftIndex] = currentOffer;
        offers.push(currentOffer);


        NftOffered(nftIndex, minSalePriceInTrx, toAddress);
    }

    function buyNft(uint nftIndex) public payable reentrancyGuard {

        require(marketPaused == false, 'Market Paused');

        Offer memory offer = nftsOfferedForSale[nftIndex];

        require(offer.isForSale == true, 'nft is not for sale');              // nft not actually for sale

        if (offer.onlySellTo != address(0) && offer.onlySellTo != msg.sender){
            revert("you can't buy this nft");
        } // nft not supposed to be sold to this user

        require(msg.sender != offer.seller, 'You can not buy your nft');

        require(msg.value >= offer.minValue, "Didn't send enough BNB");      // Didn't send enough BNB

        require(address(this) == tmeebits.ownerOf(nftIndex), 'Seller no longer owner of nft');              // Seller no longer owner of nft

        address seller = offer.seller;

        tmeebits.safeTransferFrom(address(this), msg.sender, nftIndex);

        Transfer(seller, msg.sender, 1);

        //Remove offers data
        Offer memory emptyOffer = Offer(false, nftIndex, msg.sender, 0, address(0), 0);
        nftsOfferedForSale[nftIndex] = emptyOffer;
        offers[offer.offerListIndex] = emptyOffer;

        emit NftNoLongerForSale(nftIndex);

        // (bool success, ) = address(uint160(seller)).call.value(msg.value)("");
        // require(success, "Address: unable to send value, recipient may have reverted");
        
        //Calculate fee
        (uint sellerShareValue, uint feeBOneValue, uint feeBTwoValue, uint feeBThreeValue)  = _calculateShares(msg.value);
        _sendValue(seller, sellerShareValue);
        _sendValue(feeBenefeciaryOne, feeBOneValue);
        _sendValue(feeBenefeciaryTwo, feeBTwoValue);
        _sendValue(feeBenefeciaryThree, feeBThreeValue);


        NftBought(nftIndex, msg.value, seller, msg.sender);
        NftSell(nftIndex, msg.value, msg.sender);


        Bid memory bid = nftBids[nftIndex];

        if (bid.hasBid) {

            nftBids[nftIndex] = Bid(false, nftIndex, address(0), 0,0);

            (bool success, ) = address(uint160(bid.bidder)).call.value(bid.value)("");

            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

    function enterBidForNft(uint nftIndex) public payable reentrancyGuard {

        require(marketPaused == false, 'Market Paused');

        Offer memory offer = nftsOfferedForSale[nftIndex];

        require(offer.isForSale == true, 'nft is not for sale');

        require(offer.seller != msg.sender, 'owner can not bid');

        require(msg.value > 0, 'bid can not be zero');

        Bid memory existing = nftBids[nftIndex];

        require(msg.value > existing.value, 'you can not bid lower than last bid');

        if (existing.value > 0) {
            // Refund the failing bid
            (bool success, ) = address(uint160(existing.bidder)).call.value(existing.value)("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
        bidcounter++;
        nftBids[nftIndex] = Bid(true, nftIndex, msg.sender, msg.value,bidcounter);

        NftBidEntered(nftIndex, msg.value, msg.sender);

    }

    function acceptBidForNft(uint nftIndex, uint minPrice) public reentrancyGuard {

        require(marketPaused == false, 'Market Paused');

        Offer memory offer = nftsOfferedForSale[nftIndex];

        address seller = offer.seller;

        Bid memory bid = nftBids[nftIndex];

        require(seller == msg.sender, 'Only NFT Owner');

        require(bid.value > 0, 'there is not any bid');

        require(bid.value >= minPrice, 'bid is lower than min price');

        tmeebits.safeTransferFrom(address(this), bid.bidder, nftIndex);

        Transfer(seller, bid.bidder, 1);

        Offer memory emptyOffer = Offer(false, nftIndex, msg.sender, 0, address(0), 0);
        nftsOfferedForSale[nftIndex] = emptyOffer;
        offers[offer.offerListIndex] = emptyOffer;

        nftBids[nftIndex] = Bid(false, nftIndex, address(0), 0,0);

        // (bool success, ) = address(uint160(offer.seller)).call.value(bid.value)("");
        // require(success, "Address: unable to send value, recipient may have reverted");
        
        //Calculate fee
        (uint sellerShareValue, uint feeBOneValue, uint feeBTwoValue, uint feeBThreeValue)  = _calculateShares(bid.value);
        _sendValue(offer.seller, sellerShareValue);
        _sendValue(feeBenefeciaryOne, feeBOneValue);
        _sendValue(feeBenefeciaryTwo, feeBTwoValue);
        _sendValue(feeBenefeciaryThree, feeBThreeValue);


        NftBought(nftIndex, bid.value, seller, bid.bidder);
        NftSell(nftIndex, bid.value, bid.bidder);

    }

    function withdrawBidForNft(uint nftIndex) public reentrancyGuard {

        Bid memory bid = nftBids[nftIndex];

        require(bid.hasBid == true, 'There is not bid');
        require(bid.bidder == msg.sender, 'Only bidder can withdraw');

        uint amount = bid.value;

        nftBids[nftIndex] = Bid(false, nftIndex, address(0), 0,0);

        // Refund the bid money
        (bool success, ) = address(uint160(msg.sender)).call.value(amount)("");

        require(success, "Address: unable to send value, recipient may have reverted");

        emit NftBidWithdrawn(nftIndex, bid.value, msg.sender);

    }

    function nftNoLongerForSale(uint nftIndex) public reentrancyGuard{

        Offer memory offer = nftsOfferedForSale[nftIndex];

        require(offer.isForSale == true, 'nft is not for sale');

        address seller = offer.seller;

        require(seller == msg.sender, 'Only Owner');

        tmeebits.safeTransferFrom(address(this), msg.sender, nftIndex);

        Offer memory emptyOffer = Offer(false, nftIndex, msg.sender, 0, address(0), 0);
        nftsOfferedForSale[nftIndex] = emptyOffer;
        offers[offer.offerListIndex] = emptyOffer;

        Bid memory bid = nftBids[nftIndex];

        if(bid.hasBid){

            nftBids[nftIndex] = Bid(false, nftIndex, address(0), 0,0);

            // Refund the bid money
            (bool success, ) = address(uint160(bid.bidder)).call.value(bid.value)("");

            require(success, "Address: unable to send value, recipient may have reverted");
        }

        emit NftNoLongerForSale(nftIndex);

    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns(bytes4){

        _data;

        emit ERC721Received(_operator, _from, _tokenId);

        return 0x150b7a02;

    }

    function _sendValue(address _to, uint _value) internal {
        (bool success, ) = address(uint160(_to)).call{value: _value}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function _calculateShares(uint value) internal view returns (uint _sellerShare, uint _feeBOneShare, uint _feeBTwoShare, uint _feeBThreeValue) {
        uint totalFeeValue = _fraction(DexFeePercent, 100, value); // fee: 6% of nft price

        _sellerShare = value - totalFeeValue; // 94% of nft price

        _feeBOneShare = _fraction(25 , 60, totalFeeValue); // Owner1 wallet
        _feeBTwoShare = _fraction(25 , 60, totalFeeValue); // Owner2 wallet
        _feeBThreeValue = _fraction(10 , 60, totalFeeValue); // Revenue wallet


        return ( _sellerShare,  _feeBOneShare,  _feeBTwoShare, _feeBThreeValue);
    }

    function _fraction(uint devidend, uint divisor, uint value) internal pure returns(uint) {
        return (value.mul(devidend)).div(divisor);
    }
    
    
    function claimOwner(uint256 _amount) public onlyDeployer {
        msg.sender.transfer(_amount);
    }

    function chandeDexFee(uint _DexFeePercent) public onlyDeployer {
        DexFeePercent = _DexFeePercent;
    }
    
    function offersMaxIndex() public view returns (uint){
        return offers.length;
    }
    
    function changeWalletThree(address payable _newAddressForThree) public onlyDeployer {
        feeBenefeciaryThree = _newAddressForThree;
    }
    
}