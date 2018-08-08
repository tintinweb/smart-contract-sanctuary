pragma solidity ^0.4.18;

contract TittyBase {

    event Transfer(address indexed from, address indexed to);
    event Creation(address indexed from, uint256 tittyId, uint256 wpId);
    event AddAccessory(uint256 tittyId, uint256 accessoryId);

    struct Accessory {

        uint256 id;
        string name;
        uint256 price;
        bool isActive;

    }

    struct Titty {

        uint256 id;
        string name;
        string gender;
        uint256 originalPrice;
        uint256 salePrice;
        uint256[] accessories;
        bool forSale;
    }

    //Storage
    Titty[] Titties;
    Accessory[] Accessories;
    mapping (uint256 => address) public tittyIndexToOwner;
    mapping (address => uint256) public ownerTittiesCount;
    mapping (uint256 => address) public tittyApproveIndex;

    function _transfer(address _from, address _to, uint256 _tittyId) internal {

        ownerTittiesCount[_to]++;

        tittyIndexToOwner[_tittyId] = _to;
        if (_from != address(0)) {
            ownerTittiesCount[_from]--;
            delete tittyApproveIndex[_tittyId];
        }

        Transfer(_from, _to);

    }

    function _changeTittyPrice (uint256 _newPrice, uint256 _tittyId) internal {

        require(tittyIndexToOwner[_tittyId] == msg.sender);
        Titty storage _titty = Titties[_tittyId];
        _titty.salePrice = _newPrice;

        Titties[_tittyId] = _titty;
    }

    function _setTittyForSale (bool _forSale, uint256 _tittyId) internal {

        require(tittyIndexToOwner[_tittyId] == msg.sender);
        Titty storage _titty = Titties[_tittyId];
        _titty.forSale = _forSale;

        Titties[_tittyId] = _titty;
    }

    function _changeName (string _name, uint256 _tittyId) internal {

        require(tittyIndexToOwner[_tittyId] == msg.sender);
        Titty storage _titty = Titties[_tittyId];
        _titty.name = _name;

        Titties[_tittyId] = _titty;
    }

    function addAccessory (uint256 _id, string _name, uint256 _price, uint256 tittyId ) internal returns (uint) {

        Accessory memory _accessory = Accessory({

            id: _id,
            name: _name,
            price: _price,
            isActive: true

        });

        Titty storage titty = Titties[tittyId];
        uint256 newAccessoryId = Accessories.push(_accessory) - 1;
        titty.accessories.push(newAccessoryId);
        AddAccessory(tittyId, newAccessoryId);

        return newAccessoryId;

    }

    function totalAccessories(uint256 _tittyId) public view returns (uint256) {

        Titty storage titty = Titties[_tittyId];
        return titty.accessories.length;

    }

    function getAccessory(uint256 _tittyId, uint256 _aId) public view returns (uint256 id, string name,  uint256 price, bool active) {

        Titty storage titty = Titties[_tittyId];
        uint256 accId = titty.accessories[_aId];
        Accessory storage accessory = Accessories[accId];
        id = accessory.id;
        name = accessory.name;
        price = accessory.price;
        active = accessory.isActive;

    }

    function createTitty (uint256 _id, string _gender, uint256 _price, address _owner, string _name) internal returns (uint) {
        
        Titty memory _titty = Titty({
            id: _id,
            name: _name,
            gender: _gender,
            originalPrice: _price,
            salePrice: _price,
            accessories: new uint256[](0),
            forSale: false
        });

        uint256 newTittyId = Titties.push(_titty) - 1;

        Creation(
            _owner,
            newTittyId,
            _id
        );

        _transfer(0, _owner, newTittyId);
        return newTittyId;
    }

    

}


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9df9f8e9f8ddfce5f4f2f0e7f8f3b3fef2">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}








contract TittyOwnership is TittyBase, ERC721 {

    string public name = "CryptoTittes";
    string public symbol = "CT";

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function _isOwner(address _user, uint256 _tittyId) internal view returns (bool) {
        return tittyIndexToOwner[_tittyId] == _user;
    }

    function _approve(uint256 _tittyId, address _approved) internal {
         tittyApproveIndex[_tittyId] = _approved; 
    }

    function _approveFor(address _user, uint256 _tittyId) internal view returns (bool) {
         return tittyApproveIndex[_tittyId] == _user; 
    }

    function totalSupply() public view returns (uint256 total) {
        return Titties.length - 1;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerTittiesCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = tittyIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    function approve(address _to, uint256 _tokenId) public {
        require(_isOwner(msg.sender, _tokenId));
        _approve(_tokenId, _to);
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_approveFor(msg.sender, _tokenId));
        require(_isOwner(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
        

    }
    function transfer(address _to, uint256 _tokenId) public {
        require(_to != address(0));
        require(_isOwner(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }



}

contract TittyPurchase is TittyOwnership {

    address private wallet;
    address private boat;

    function TittyPurchase(address _wallet, address _boat) public {
        wallet = _wallet;
        boat = _boat;

        createTitty(0, "unissex", 1000000000, address(0), "genesis");
    }

    function purchaseNew(uint256 _id, string _name, string _gender, uint256 _price) public payable {

        if (msg.value == 0 && msg.value != _price)
            revert();

        uint256 boatFee = calculateBoatFee(msg.value);
        createTitty(_id, _gender, _price, msg.sender, _name);
        wallet.transfer(msg.value - boatFee);
        boat.transfer(boatFee);

    }

    function purchaseExistent(uint256 _tittyId) public payable {

        Titty storage titty = Titties[_tittyId];
        uint256 fee = calculateFee(titty.salePrice);
        if (msg.value == 0 && msg.value != titty.salePrice)
            revert();
        
        uint256 val = msg.value - fee;
        address owner = tittyIndexToOwner[_tittyId];
        _approve(_tittyId, msg.sender);
        transferFrom(owner, msg.sender, _tittyId);
        owner.transfer(val);
        wallet.transfer(fee);

    }

    function purchaseAccessory(uint256 _tittyId, uint256 _accId, string _name, uint256 _price) public payable {

        if (msg.value == 0 && msg.value != _price)
            revert();

        wallet.transfer(msg.value);
        addAccessory(_accId, _name, _price,  _tittyId);
        
        
    }

    function getAmountOfTitties() public view returns(uint) {
        return Titties.length;
    }

    function getLatestId() public view returns (uint) {
        return Titties.length - 1;
    }

    function getTittyByWpId(address _owner, uint256 _wpId) public view returns (bool own, uint256 tittyId) {
        
        for (uint256 i = 1; i<=totalSupply(); i++) {
            Titty storage titty = Titties[i];
            bool isOwner = _isOwner(_owner, i);
            if (titty.id == _wpId && isOwner) {
                return (true, i);
            }
        }
        
        return (false, 0);
    }

    function belongsTo(address _account, uint256 _tittyId) public view returns (bool) {
        return _isOwner(_account, _tittyId);
    }

    function changePrice(uint256 _price, uint256 _tittyId) public {
        _changeTittyPrice(_price, _tittyId);
    }

    function changeName(string _name, uint256 _tittyId) public {
        _changeName(_name, _tittyId);
    }

    function makeItSellable(uint256 _tittyId) public {
        _setTittyForSale(true, _tittyId);
    }

    function calculateFee (uint256 _price) internal pure returns(uint) {
        return (_price * 10)/100;
    }

    function calculateBoatFee (uint256 _price) internal pure returns(uint) {
        return (_price * 25)/100;
    }

    function() external {}

    function getATitty(uint256 _tittyId)
        public 
        view 
        returns (
        uint256 id,
        string name,
        string gender,
        uint256 originalPrice,
        uint256 salePrice,
        bool forSale
        ) {

            Titty storage titty = Titties[_tittyId];
            id = titty.id;
            name = titty.name;
            gender = titty.gender;
            originalPrice = titty.originalPrice;
            salePrice = titty.salePrice;
            forSale = titty.forSale;
        }

}

contract CTAuction {

    struct Auction {
        // Parameters of the auction. Times are either
        // absolute unix timestamps (seconds since 1970-01-01)
        // or time periods in seconds.
        uint auctionEnd;

        // Current state of the auction.
        address highestBidder;
        uint highestBid;

        //Minumin Bid Set by the beneficiary
        uint minimumBid;

        // Set to true at the end, disallows any change
        bool ended;

        //Titty being Auctioned
        uint titty;

        //Beneficiary
        address beneficiary;

        //buynow price
        uint buyNowPrice;
    }

    Auction[] Auctions;

    address public owner; 
    address public ctWallet; 
    address public tittyContractAddress;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // CriptoTitty Contract
    TittyPurchase public tittyContract;

    // Events that will be fired on changes.
    event HighestBidIncreased(uint auction, address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event BuyNow(address buyer, uint amount);
    event AuctionCancel(uint auction);
    event NewAuctionCreated(uint auctionId, uint titty);
    event DidNotFinishYet(uint time, uint auctionTime);
    event NotTheContractOwner(address owner, address sender);

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    function CTAuction(
        address _tittyPurchaseAddress,
        address _wallet
    ) public 
    {   
        tittyContractAddress = _tittyPurchaseAddress;
        tittyContract = TittyPurchase(_tittyPurchaseAddress);
        ctWallet = _wallet;
        owner = msg.sender; 
    }

    function createAuction(uint _biddingTime, uint _titty, uint _minimumBid, uint _buyNowPrice) public {

        address ownerAddress = tittyContract.ownerOf(_titty);
        require(msg.sender == ownerAddress);

        Auction memory auction = Auction({
            auctionEnd: now + _biddingTime,
            titty: _titty,
            beneficiary: msg.sender,
            highestBidder: 0,
            highestBid: 0,
            ended: false,
            minimumBid: _minimumBid,
            buyNowPrice: _buyNowPrice
        });

        uint auctionId = Auctions.push(auction) - 1;
        NewAuctionCreated(auctionId, _titty);
    }

    function getTittyOwner(uint _titty) public view returns (address) {
        address ownerAddress = tittyContract.ownerOf(_titty);
        return ownerAddress;
    } 

    /// Bid on an auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid(uint _auction) public payable {

        Auction memory auction = Auctions[_auction];

        // Revert the call if the bidding
        // period is over.
        require(now <= auction.auctionEnd);

        // Revert the call value is less than the minimumBid.
        require(msg.value >= auction.minimumBid);

        // If the bid is not higher, send the
        // money back.
        require(msg.value > auction.highestBid);

        if (auction.highestBid != 0) {
            // Sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // It is always safer to let the recipients
            // withdraw their money themselves.
            pendingReturns[auction.highestBidder] += auction.highestBid;
        }
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        Auctions[_auction] = auction;
        HighestBidIncreased(_auction, msg.sender, msg.value);
    }

    function buyNow(uint _auction) public payable {

        Auction memory auction = Auctions[_auction];

        require(now >= auction.auctionEnd); // auction has ended
        require(!auction.ended); // this function has already been called

        //Require that the value sent is the buyNowPrice Set by the Owner/Benneficary
        require(msg.value == auction.buyNowPrice);

        //Require that there are no bids
        require(auction.highestBid == 0);

        // End Auction
        auction.ended = true;
        Auctions[_auction] = auction;
        BuyNow(msg.sender, msg.value);

        // Send the Funds
        tittyContract.transferFrom(auction.beneficiary, msg.sender, auction.titty);
        uint fee = calculateFee(msg.value);
        ctWallet.transfer(fee);
        auction.beneficiary.transfer(msg.value-fee);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0);
        // It is important to set this to zero because the recipient
        // can call this function again as part of the receiving call
        // before `send` returns.
        pendingReturns[msg.sender] = 0;

        if (!msg.sender.send(amount)) {
            // No need to call throw here, just reset the amount owing
            pendingReturns[msg.sender] = amount;
            return false;
        }
        
        return true;
    }

    function auctionCancel(uint _auction) public {

        Auction memory auction = Auctions[_auction];

        //has to be the beneficiary
        require(msg.sender == auction.beneficiary);

        //Auction Ended
        require(now >= auction.auctionEnd);

        //has no maxbid 
        require(auction.highestBid == 0);

        auction.ended = true;
        Auctions[_auction] = auction;
        AuctionCancel(_auction);

    }

    /// End the auction and send the highest bid
    /// to the beneficiary and 10% to CT.
    function auctionEnd(uint _auction) public {

        // Just cryptotitties CEO can end the auction
        require (owner == msg.sender);

        Auction memory auction = Auctions[_auction];

        require (now >= auction.auctionEnd); // auction has ended
        require(!auction.ended); // this function has already been called

        // End Auction
        auction.ended = true;
        Auctions[_auction] = auction;
        AuctionEnded(auction.highestBidder, auction.highestBid);
        if (auction.highestBid != 0) {
            // Send the Funds
            tittyContract.transferFrom(auction.beneficiary, auction.highestBidder, auction.titty);
            uint fee = calculateFee(auction.highestBid);
            ctWallet.transfer(fee);
            auction.beneficiary.transfer(auction.highestBid-fee);
        }

    }

    function getAuctionInfo(uint _auction) public view returns (uint end, address beneficiary, uint maxBid, address maxBidder) {

        Auction storage auction = Auctions[_auction];

        end = auction.auctionEnd;
        beneficiary = auction.beneficiary;
        maxBid = auction.highestBid;
        maxBidder = auction.highestBidder;
    }

    function calculateFee (uint256 _price) internal pure returns(uint) {
        return (_price * 10)/100;
    }
}