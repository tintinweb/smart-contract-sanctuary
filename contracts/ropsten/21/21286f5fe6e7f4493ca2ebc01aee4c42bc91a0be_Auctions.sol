pragma solidity ^0.4.24;
pragma experimental "v0.5.0";
//pragma experimental ABIEncoderV2;

library AuctionLib {
    struct Bod {
        uint64 inEuro;
        string biederNaam;
    }
}

contract Veiling {

    string veilingObject;

    AuctionLib.Bod[] public biedingen;
    bool public loopt;
    address owner;

    modifier whenAuctionIsActive() {
        require(loopt == true, "Veiling is gesloten");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    event NieuwBodGeaccepteerd(uint64 bodInEuro, string biederNaam);
    event BodGeselecteerd(uint64 bodInEuro, string biederNaam);

    constructor(string memory _veilingObject) public {
        // enforce bound on veilingObject size
        requireBoundedStringSize(_veilingObject, 255);

        veilingObject = _veilingObject;
        loopt = true;
        owner = msg.sender;
    }

    function bied(uint64 bodInEuro, string memory biederNaam) public whenAuctionIsActive onlyOwner {
        // enforce bound on biederNaam size
        requireBoundedStringSize(biederNaam, 255);

        AuctionLib.Bod memory bod = AuctionLib.Bod({inEuro: bodInEuro, biederNaam: biederNaam});
        biedingen.push(bod);

        emit NieuwBodGeaccepteerd(bodInEuro, biederNaam);
    }

    // Record the "selecting" of a bod as a winner. The selection is just an emitted event, which will be logged.
    // Will only emit a select event (thus marking the bod as selected) if such a bod exists.
    function selecteerBod(uint64 bodInEuro, string memory biederNaam) public onlyOwner {
        AuctionLib.Bod memory bod;

        for (uint i = biedingen.length-1; i --> 0;) {
            bod = biedingen[i];

            // do cheapest comparison first (integers)
            if (bod.inEuro == bodInEuro && stringEquals(bod.biederNaam, biederNaam)) {
                // emit event of selecting this bod
                emit BodGeselecteerd(bod.inEuro, bod.biederNaam);
                // done
                return;
            }
        }
    }

//    function allBids() external view returns (AuctionLib.Bod[]) {
//        return biedingen;
//    }

    // Helper function to compare two given strings. Based on the assumption that if their hashes are equals,
    // then so are their values. In other words, a collision is considered sufficiently unlikely.
    function stringEquals(string memory one, string memory two) internal pure returns (bool) {
        bytes memory bytes_one = bytes(one);
        bytes memory bytes_two = bytes(two);

        if (bytes_one.length != bytes_two.length) {
            // if length doesn&#39;t match, don&#39;t even have to hash
            return false;
        }

        return keccak256(bytes_one) == keccak256(bytes_two);
    }

    // Helper function to bound the size of accepted string values, useful for keeping gas costs bounded
    function requireBoundedStringSize(string memory value, uint bound) internal pure {
        require((bytes(value)).length <= bound);
    }

}

contract Auctions {

    address owner;

    mapping(string => Veiling) auctions;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    event AuctionStarted(string auctionObject);
    event AuctionEnded(string auctionObject);

    constructor() public {
        owner = msg.sender;
    }

    function recordAuctionStart(string memory auctionObject) public onlyOwner {
        requireBoundedStringSize(auctionObject, 255);
        auctions[auctionObject] = new Veiling(auctionObject);

        emit AuctionStarted(auctionObject);
    }

    function recordAuctionEnded(string memory auctionObject) public onlyOwner {
        delete auctions[auctionObject];

        emit AuctionEnded(auctionObject);
    }

    function submitBid(string memory auctionObject, uint64 bodInEuro, string memory biederNaam) public onlyOwner {
        Veiling auction = auctions[auctionObject];
        auction.bied(bodInEuro, biederNaam);
    }

    function selectWinningBid(string memory auctionObject, uint64 bodInEuro, string memory biederNaam) public onlyOwner {
        Veiling auction = auctions[auctionObject];
        auction.selecteerBod(bodInEuro, biederNaam);
    }

//    function bidsOfAuction(string memory auctionObject) public view returns (AuctionLib.Bod[]) {
//        return auctions[auctionObject].allBids();
//    }

    // Helper function to bound the size of accepted string values, useful for keeping gas costs bounded
    function requireBoundedStringSize(string memory value, uint bound) internal pure {
        require((bytes(value)).length <= bound);
    }
}