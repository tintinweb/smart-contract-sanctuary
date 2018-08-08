pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Beneficiary is Ownable {

    address public beneficiary;

    constructor() public {
        beneficiary = msg.sender;
    }

    function setBeneficiary(address _beneficiary) onlyOwner public {
        beneficiary = _beneficiary;
    }

    function withdrawal(uint256 amount) public onlyOwner {
        if (amount > address(this).balance) {
            revert();
        }

        beneficiary.transfer(amount);
    }

    function withdrawalAll() public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }
}

contract MCPSale is Beneficiary {

    mapping(address => uint256) public balances;
    mapping(uint256 => address) public approved;
    mapping(int32 => mapping(int32 => uint256)) public zone;
    mapping(uint256 => Coordinates) public zone_reverse;
    mapping(uint16 => Region) public regions;
    mapping(uint16 => RegionBid) public region_bids;

    bool public constant implementsERC721 = true;

    uint256 constant MINIMAL_RAISE = 0.5 ether;
    uint256 constant AUCTION_DURATION = 7 * 24 * 60 * 60; // 7 Days

    bool public SaleActive = true;

    struct MapLand {
        uint8 resources;
        uint16 region;
        uint256 buyPrice;
        address owner;
    }

    struct Coordinates {
        int32 x;
        int32 y;
    }

    struct RegionBid {
        address currentBuyer;
        uint256 bid;
        uint256 activeTill;
    }

    struct Region {
        address owner;
        uint8 tax;
        uint256 startPrice;
        string regionName;
        bool onSale;
        bool allowSaleLands;
        bool created;
    }


    uint256 public basePrice = 0.01 ether;
    uint256 public minMargin = 0.001944 ether;
    uint32 public divider = 8;
    uint8 public defaultRegionTax = 10;

    MapLand[] public tokens;

    address public mapMaster;

    modifier isTokenOwner(uint256 _tokenId) {
        if (tokens[_tokenId].owner != msg.sender) {

            if (msg.value > 0) {
                msg.sender.transfer(msg.value);
            }

            return;

        }

        _;
    }

    modifier onlyRegionOwner(uint16 _regionId) {
        if (regions[_regionId].owner != msg.sender) {

            if (msg.value > 0) {
                msg.sender.transfer(msg.value);
            }

            return;

        }

        _;
    }

    modifier isNotNullAddress(address _address) {
        require(address(0) != _address);
        _;
    }

    modifier isApproved(uint256 _tokenId, address _to) {
        require(approved[_tokenId] == _to);
        _;
    }

    modifier onlyMapMaster() {
        require(mapMaster == msg.sender);
        _;
    }

    modifier onlyOnActiveSale() {
        require(SaleActive);
        _;
    }

    modifier canMakeBid(uint16 regionId) {
        if ((region_bids[regionId].activeTill != 0 && region_bids[regionId].activeTill < now)
        || regions[regionId].owner != address(0) || !regions[regionId].onSale
        ) {
            if (msg.value > 0) {
                msg.sender.transfer(msg.value);
            }
            return;
        }

        _;
    }

    constructor() public {
        mapMaster = msg.sender;
        tokens.length++;
        //reserve 0 token - no binding, no sale
        MapLand storage reserve = tokens[tokens.length - 1];
        reserve.owner = msg.sender;
    }

    function setMapMaster(address _mapMaster) public onlyOwner {
        mapMaster = _mapMaster;
    }

    function setMinMargin(uint256 _amount) public onlyOwner {
        minMargin = _amount;
    }

    function setBasePrice(uint256 _amount) public onlyOwner {
        basePrice = _amount;
    }

    function setRegionTax(uint16 regionId, uint8 tax) public onlyRegionOwner(regionId) onlyOnActiveSale {
        require(tax <= 100 && tax >= 0);
        regions[regionId].tax = tax;

        emit TaxUpdate(regionId, regions[regionId].tax);
    }

    function setRegionName(uint16 regionId, string regionName) public onlyOwner {
        regions[regionId].regionName = regionName;
        emit ChangeRegionName(regionId, regionName);
    }

    function setRegionOnSale(uint16 regionId) public onlyMapMaster {
        regions[regionId].onSale = true;

        emit RegionOnSale(regionId);
    }

    function setAllowSellLands(uint16 regionId) public onlyMapMaster {
        regions[regionId].allowSaleLands = true;

        emit RegionAllowSaleLands(regionId);
    }

    function setRegionPrice(uint16 regionId, uint256 price) public onlyOwner {
        if(regions[regionId].owner == address(0) && !regions[regionId].onSale) {
            regions[regionId].startPrice = price;
            emit UpdateRegionPrice(regionId, price);
        }
    }

    function addRegion(uint16 _regionId, uint256 _startPrice, string _regionName) public onlyMapMaster onlyOnActiveSale {

        if (regions[_regionId].created) {
            return;
        }

        Region storage newRegion = regions[_regionId];
        newRegion.startPrice = _startPrice;
        newRegion.tax = defaultRegionTax;
        newRegion.owner = address(0);
        newRegion.regionName = _regionName;
        newRegion.created = true;

        emit AddRegion(_regionId);
    }

    function regionExists(uint16 _regionId) public view returns (bool) {
        return regions[_regionId].created;
    }

    function makeBid(uint16 regionId) payable public
    onlyOnActiveSale
    canMakeBid(regionId) {

        uint256 minimal_bid;

        if (region_bids[regionId].currentBuyer != address(0)) {//If have bid already
            minimal_bid = region_bids[regionId].bid + MINIMAL_RAISE;
        } else {
            minimal_bid = regions[regionId].startPrice;
        }

        if (minimal_bid > msg.value) {

            if (msg.value > 0) {
                msg.sender.transfer(msg.value);
            }

            return;
        }

        RegionBid storage bid = region_bids[regionId];

        if (bid.currentBuyer != address(0)) {
            //Return funds to old buyer
            bid.currentBuyer.transfer(bid.bid);
        } else {
            emit AuctionStarts(regionId);
        }

        // Auction will be active for 7 days if no one make a new bid
        bid.activeTill = now + AUCTION_DURATION;


        bid.currentBuyer = msg.sender;
        bid.bid = msg.value;

        emit RegionNewBid(regionId, msg.sender, msg.value, region_bids[regionId].activeTill);
    }

    function completeRegionAuction(uint16 regionId) public onlyMapMaster {
        if (region_bids[regionId].currentBuyer == address(0)) {
            return;
        }

        if (region_bids[regionId].activeTill > now || region_bids[regionId].activeTill == 0) {
            return;
        }

        transferRegion(regionId, region_bids[regionId].currentBuyer);
    }

    function takeRegion(uint16 regionId) public {
        require(regions[regionId].owner == address(0));
        require(region_bids[regionId].currentBuyer == msg.sender);
        require(region_bids[regionId].activeTill < now);

        transferRegion(regionId, region_bids[regionId].currentBuyer);
    }

    function transferRegion(uint16 regionId, address newOwner) internal {
        regions[regionId].owner = newOwner;
        regions[regionId].onSale = false;

        emit RegionSold(regionId, regions[regionId].owner);
    }

    // returns next minimal bid or final bid on auctions that already end
    function getRegionPrice(uint16 regionId) public view returns (uint256 next_bid) {
        if(regions[regionId].owner != address(0)) {
            return region_bids[regionId].bid;
        }

        if (region_bids[regionId].currentBuyer != address(0)) {//If have bid already
            next_bid = region_bids[regionId].bid + MINIMAL_RAISE;
        } else {
            next_bid = regions[regionId].startPrice;
        }
    }

    function _activateZoneLand(int32 x, int32 y, uint8 region, uint8 resources) internal {
        tokens.length++;
        MapLand storage tmp = tokens[tokens.length - 1];

        tmp.region = region;
        tmp.resources = resources;
        tmp.buyPrice = 0;
        zone[x][y] = tokens.length - 1;
        zone_reverse[tokens.length - 1] = Coordinates(x, y);

        emit ActivateMap(x, y, tokens.length - 1);
    }

    function activateZone(int32[] x, int32[] y, uint8[] region, uint8[] resources) public onlyMapMaster {
        for (uint index = 0; index < x.length; index++) {
            _activateZoneLand(x[index], y[index], region[index], resources[index]);
        }
    }

    function buyLand(int32 x, int32 y) payable public onlyOnActiveSale {
        MapLand storage token = tokens[zone[x][y]];
        if (zone[x][y] == 0 || token.buyPrice > 0 || token.owner != address(0)
        || !regions[token.region].allowSaleLands) {

            if (msg.value > 0) {
                msg.sender.transfer(msg.value);
            }

            return;
        }

        uint256 buyPrice = getLandPrice(x, y);

        if (buyPrice == 0) {

            if (msg.value > 0) {
                msg.sender.transfer(msg.value);
            }

            return;
        }

        uint256[49] memory payouts;
        address[49] memory addresses;
        uint8 tokenBought;


        if (buyPrice > msg.value) {

            if (msg.value > 0) {
                msg.sender.transfer(msg.value);
            }

            return;
        } else if (buyPrice < msg.value) {
            msg.sender.transfer(msg.value - buyPrice);
        }

        (payouts, addresses, tokenBought) = getPayouts(x, y);


        token.owner = msg.sender;
        token.buyPrice = buyPrice;
        balances[msg.sender]++;

        doPayouts(payouts, addresses, buyPrice);

        uint256 tax = getRegionTax(token.region);

        if (regions[token.region].owner != address(0) && tax > 100) {
            uint256 taxValue = ((basePrice * (tax - 100) + ((tokenBought ** 2) * minMargin * (tax - 100))) / 100);
            regions[token.region].owner.transfer(taxValue);
            emit RegionPayout(regions[token.region].owner, taxValue);
        }

        emit Transfer(address(0), msg.sender, zone[x][y]);

    }

    function doPayouts(uint256[49] payouts, address[49] addresses, uint256 fullValue) internal returns (uint256){
        for (uint8 i = 0; i < addresses.length; i++) {
            if (addresses[i] == address(0)) {
                continue;
            }
            addresses[i].transfer(payouts[i]);
            emit Payout(addresses[i], payouts[i]);
            fullValue -= payouts[i];
        }


        return fullValue;
    }

    function getPayouts(int32 x, int32 y) public view returns (uint256[49] payouts, address[49] addresses, uint8 tokenBought) {

        for (int32 xi = x - 3; xi <= x + 3; xi++) {
            for (int32 yi = y - 3; yi <= y + 3; yi++) {
                if (x == xi && y == yi) {
                    continue;
                }
                MapLand memory token = tokens[zone[xi][yi]];

                if (token.buyPrice > 0) {
                    payouts[tokenBought] = (token.buyPrice / divider);
                    addresses[tokenBought] = (token.owner);
                    tokenBought++;

                }
            }
        }


        return (payouts, addresses, tokenBought);
    }

    function getLandPrice(int32 x, int32 y) public view returns (uint256 price){

        if (zone[x][y] == 0) {
            return;
        }

        MapLand memory token = tokens[zone[x][y]];

        int256[2] memory start;
        start[0] = x - 3;
        start[1] = y - 3;
        uint256[2] memory counters = [uint256(0), 0];
        for (int32 xi = x - 3; xi <= x + 3; xi++) {
            for (int32 yi = y - 3; yi <= y + 3; yi++) {
                if (x == xi && y == yi) {
                    continue;
                }

                if (tokens[zone[xi][yi]].buyPrice > 0) {
                    counters[1] += tokens[zone[xi][yi]].buyPrice;
                    counters[0]++;
                }
            }
        }

        uint16 regionId = token.region;

        uint8 taxValue = getRegionTax(regionId);

        if (counters[0] == 0) {
            price = ((basePrice * taxValue) / 100);
        } else {
            price = ((basePrice * taxValue) / 100) + (uint(counters[1]) / divider) + (((counters[0] ** 2) * minMargin * taxValue) / 100);
        }
    }


    function getRegionTax(uint16 regionId) internal view returns (uint8) {
        if (regions[regionId].owner != address(0)) {
            return (100 + regions[regionId].tax);
        }
        return (100 + defaultRegionTax);
    }

    function approve(address _to, uint256 _tokenId) public isTokenOwner(_tokenId) isNotNullAddress(_to) {
        approved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function setRegionOwner(uint16 regionId, address owner, uint256 viewPrice) public onlyOwner {
        require(regions[regionId].owner == address(0) && !regions[regionId].onSale);

        regions[regionId].owner = owner;

        RegionBid storage bid = region_bids[regionId];
        bid.activeTill = now;
        bid.currentBuyer = owner;
        bid.bid = viewPrice;

        emit RegionSold(regionId, owner);

    }

    function transfer(address _to, uint256 _tokenId) public isTokenOwner(_tokenId) isNotNullAddress(_to) isApproved(_tokenId, _to) {
        tokens[_tokenId].owner = _to;

        balances[msg.sender]--;
        balances[_to]++;

        emit Transfer(msg.sender, _to, _tokenId);
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public isTokenOwner(_tokenId) isApproved(_tokenId, _to) {
        tokens[_tokenId].owner = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = tokens[_tokenId].owner;
    }

    function totalSupply() public view returns (uint256) {
        return tokens.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = balances[_owner];
    }

    function setSaleEnd() public onlyOwner {
        SaleActive = false;
        emit EndSale(true);
    }

    function isActive() public view returns (bool) {
        return SaleActive;
    }


    // Events
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

    event RegionAllowSaleLands(uint16 regionId);
    event ActivateMap(int256 x, int256 y, uint256 tokenId);
    event AddRegion(uint16 indexed regionId);
    event UpdateRegionPrice(uint16 indexed regionId, uint256 price);
    event ChangeRegionName(uint16 indexed regionId, string regionName);
    event TaxUpdate(uint16 indexed regionId, uint8 tax);
    event RegionOnSale(uint16 indexed regionId);
    event RegionNewBid(uint16 indexed regionId, address buyer, uint256 value, uint256 activeTill);
    event AuctionStarts(uint16 indexed regionId);
    event RegionSold(uint16 indexed regionId, address owner);
    event Payout(address indexed to, uint256 value);
    event RegionPayout(address indexed to, uint256 value);
    event EndSale(bool isEnded);
}