// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./AccessControl.sol";

contract Auctioneer is AccessControl {
    uint256 public minBid;
    uint256 public aDay;
    uint256 public NFTsold;

    bytes32 public constant CEO = keccak256("CEO");
    bytes32 public constant CTO = keccak256("CTO");
    bytes32 public constant CFO = keccak256("CFO");
    address internal constant _safe = 0xd8806d66E24b702e0A56fb972b75D24CAd656821;
    ERC721 public _racers;  // = ERC721(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // IERC20 public WETH;

    struct logBid {
        address bidder;
        uint256 id;
        uint256 bid;
        uint256 timestamp;
    }

    struct auction {
        bool began;
        bool ended;
        address highestBidder;
        uint256 highestBid;
        uint256 totalBids;
        uint256 timeEnded;
        uint256 timeStarted;
        mapping(uint256 => logBid) logBids;
    }

    mapping(uint256 => auction) public Auctions;
    mapping(uint256 => uint256) public RacerSold;
    event getBid(uint256 id, address bidder, uint256 bid, uint256 time);
    // event wethTransfer(address sender, address rec, uint256 amount);

    constructor(){

        _setupRole(DEFAULT_ADMIN_ROLE, _safe);
        _setupRole(CEO, address(0x47c06B50C2a6D28Ce3B130384b19a8929f414030));
        _setupRole(CFO, _safe);
        _setupRole(CTO, msg.sender);

        minBid = 10000000;
        // WETH = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
        _racers = ERC721(0x95F0a20C1c78eBeCf67753bd9488DfdbDDc6150A);
        aDay = 86400;
        NFTsold = 0;
    }

    modifier validate() {
        require(
            hasRole(CEO, msg.sender) ||
                hasRole(CFO, msg.sender) ||
                hasRole(CTO, msg.sender),
            "AccessControl: Address does not have valid Rights"
        );
        _;
    }

    function auctionStart(uint256 id) external payable returns(bool) {
        auction storage inst = Auctions[id];
        uint256 amount = msg.value;

        require(!exists(id), "Racer already has a driver");
        require(!inst.began, "Auction already started");
        require(!inst.ended, "Auction already ended");
        require(amount >= minBid, "Amount should be greater than minimum bid");
               
        RacerSold[NFTsold++] = id;
        inst.began = true;
        inst.highestBid = amount;
        inst.highestBidder = msg.sender;
        inst.timeStarted = block.timestamp;
        inst.timeEnded = block.timestamp + aDay;
        inst.logBids[inst.totalBids++] = logBid({
            bidder: inst.highestBidder,
            bid: inst.highestBid,
            timestamp: block.timestamp,
            id: id
        });
        return true;
    }

    function Bid(uint256 id) external payable returns(bool) {
        
        uint256 amount = msg.value;
        auction storage inst = Auctions[id];

        require(inst.began, "Auction not started");
        require(!inst.ended, "Auction Finished");
        require(
            amount > inst.highestBid,
            "The bid amount should higher than current bid"
        );
        payable(inst.highestBidder).transfer(inst.highestBid);

        inst.highestBidder = msg.sender;
        inst.highestBid = amount;
        inst.logBids[inst.totalBids++] = logBid({
            bidder: inst.highestBidder,
            bid: inst.highestBid,
            timestamp: block.timestamp,
            id: id
        });
        return true;
    }


    function auctionEnd(uint256 id) external payable returns(bool) {
        auction storage inst = Auctions[id];
        require(inst.began, "Auction not yet started started");
        require(!inst.ended, "Auction already Finished!");
        require(block.timestamp >= inst.timeEnded, "Auction Time Not yet finished");
        
        payable(_safe).transfer(inst.highestBid);
        // WETH.transfer(_safe, inst.highestBid);
        inst.ended = true;
        return true;
    }

    function exists(uint256 id) public view returns(bool){
        try _racers.ownerOf(id) returns(address){
            return true;
        }
        catch(bytes memory){
            return false;
        }
    }

    function driver(uint256 id) public view returns(address) {
        return _racers.ownerOf(id);
    }

    function highestBid(uint256 id) public view returns(uint256) {
        return Auctions[id].highestBid;
    }

    function highestBidder(uint256 id) public view returns(address) {
        return Auctions[id].highestBidder;
    }

    function timeEnded(uint256 id) public view returns(uint256) {
        return Auctions[id].timeEnded;
    }

    function setBid(uint256 _val) public validate{
        minBid = _val;
    }
    
    function setTimer(uint256 _val) public validate{
        aDay = _val;
    }

    function setRacers(address _r) public validate{
        _racers = ERC721(_r);
    }
}