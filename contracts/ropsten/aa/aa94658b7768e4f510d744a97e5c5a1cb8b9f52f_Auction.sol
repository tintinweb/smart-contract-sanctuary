pragma solidity ^0.5.0;

contract Auction {
    
    enum State { Open, Closed }
    
    struct Bid {
        address bidder;
        bytes32 hash;
        uint256 timestamp;
        bool verified;
    }
    
    // Events
    event CalculatedHash(bytes32 hash);
    event Debug(bytes hash);

    // Modifiers
    modifier onlyOwner(address _owner) {
        require(owner == _owner);
        _;
    }
    
    // State variables
    address public owner;
    string public isin;
    uint256 public biddingDeadline;
    uint256 public verificationDeadline;
    uint8 public numberOfBids;
    uint8 public stake;
    Bid[] public bids;
    
    // Functions
    constructor(string memory _isin, uint256 _biddingDeadline, uint256 _verificationDeadline, uint8 _stake) public {
        owner = msg.sender;
        isin = _isin;
        biddingDeadline = _biddingDeadline;
        verificationDeadline = _verificationDeadline;
        stake = _stake;
    }
    
    function bid(bytes32 _hash) public payable {
        require(msg.value == stake);
        for (uint i=0; i<bids.length; i++) {
            if (bids[i].bidder == msg.sender) {
                revert();
            }
        }
        bids.push(Bid(msg.sender, _hash, now, false));
    }
    
    function isInVerificationPhase() public view returns (bool) {
        return now >= biddingDeadline && now < verificationDeadline;
    }
    
    
    function verifyBid(string memory _bid, uint256 _nonce) public {
        //if (!isInVerificationPhase()) {
        //    revert();
        //}
        bytes memory abiEncodedPacked  = abi.encodePacked(_bid, _nonce);
        emit Debug(abiEncodedPacked);

        bytes32 hash = keccak256(abi.encodePacked(_bid, _nonce));
        emit CalculatedHash(hash);
        for (uint i=0; i<bids.length; i++) {
            if (bids[i].bidder == msg.sender) {
                bids[i].verified = bids[i].hash == hash;
            }
        }
    }
}