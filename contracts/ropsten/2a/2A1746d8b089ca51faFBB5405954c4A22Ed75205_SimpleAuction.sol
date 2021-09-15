/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.4.17;
contract SimpleAuction {
    uint public companyregistrationnumber;
    uint public VATregistrationnumber;
    string public technologyband;
    uint public solarmin;
    uint public windmin;
    address public  beneficiary;
    uint public auctionEndtime;
    address public solarhighestBidder;
    address public windhighestBidder;
    uint public solarhighestBid;
    uint public windhighestBid;
    string public auctiontype;
    address public manager;
    mapping(address => uint) public solarpendingReturns;
     mapping(address => uint) public windpendingReturns;
    bool ended;
    uint public solarpower;
    uint public windpower;
    uint public solarpowerstart;
    uint public windpowerstart;
    uint public solarpowerend;
    uint public windpowerend;
    bytes32 solarorwind;
    bytes32 check;
      function SimpleAuction(
   uint _companyregistrationnumber,
   uint _VATregistrationnumber,
   string _technologyband,
        uint _biddingTime,
        address _beneficiary,
        uint _solarmin,
        uint _windmin,
        uint _solarpower,
        uint _windpower,
        uint _solarpowerstart,
        uint _solarpowerend,
         uint _windpowerstart,
        uint _windpowerend,
        string _auctiontype
    ) public {
        companyregistrationnumber=_companyregistrationnumber;
        VATregistrationnumber=_VATregistrationnumber;
        technologyband=_technologyband;
        beneficiary = _beneficiary;
        auctionEndtime = now + _biddingTime;
        solarmin = _solarmin;
        windmin = _windmin;
        solarpower=_solarpower;
        windpower=_windpower;
        solarpowerstart=_solarpowerstart;
        windpowerstart=_windpowerstart;
        solarpowerend=_solarpowerend;
        windpowerend=_windpowerend;
        auctiontype=_auctiontype;
        manager=msg.sender;
    }

    function enteroption(string _solarorwind) public {
        solarorwind=keccak256(_solarorwind);
        
    }

    function bidsolar() public payable {
        require(msg.value>solarmin);
        require(now <= auctionEndtime);
        require(msg.value > solarhighestBid);
        check=keccak256("solar");
        require(check==solarorwind);
        solarhighestBidder = msg.sender;
        solarhighestBid = msg.value;
        
    if (solarhighestBid != 0) {
        solarpendingReturns[solarhighestBidder] += solarhighestBid;
}

        
    }
    
        function bidwind() public payable {
        require(msg.value>windmin);
        require(now <= auctionEndtime);
        require(msg.value > windhighestBid);
        check=keccak256("wind");
        require(check==solarorwind);
        windhighestBidder = msg.sender;
        windhighestBid = msg.value;
        
    if (windhighestBid != 0) {
        windpendingReturns[windhighestBidder] += windhighestBid;
}
    }
    
    function solarwithdraw() public returns (bool) {
        require(ended==true);
        uint solaramount = solarpendingReturns[msg.sender];
        if (solaramount > 0) {
             solarpendingReturns[msg.sender] = 0;
             if (!msg.sender.send(solaramount)) {
                 solarpendingReturns[msg.sender] = solaramount;
                return false;
             }
        }
        return true;
    }
    
     function windwithdraw() public returns (bool) {
        require(ended==true);
        uint windamount = windpendingReturns[msg.sender];
        if (windamount > 0) {
             windpendingReturns[msg.sender] = 0;
             if (!msg.sender.send(windamount)) {
                 windpendingReturns[msg.sender] = windamount;
                return false;
             }
        }
        return true;
    }
        
    function getBalance() external view returns(uint){
        //to get the contract balance
        return address(this).balance;
    }

    function auctionEnd() public {
        require(now >= auctionEndtime);
require(msg.sender==manager);
        require(!ended);
        ended = true;
         beneficiary.transfer(solarhighestBid);
beneficiary.transfer(windhighestBid);
}
}