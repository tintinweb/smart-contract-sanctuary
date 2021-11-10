/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract TestController{

    address payable owner;
    
    mapping(uint256 => mapping(string => bool)) _auction_str_bool;
    mapping(uint256 => mapping(string => uint256)) _auction_str_int;
    //mapping(uint256 => mapping(string => uint256)) _auction_startPrice;
    //mapping(uint256 => mapping(string => uint256)) _auction_endPrice;
    //mapping(uint256 => mapping(string => uint256)) _auction_startDate;
    //mapping(uint256 => mapping(string => uint256)) _auction_duration;
     
     uint256 decimalPrecision = (10 ** 18);

    constructor()  {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }

  
    
    function sell(uint256 _tokenId, bool _isAuction, uint256 _startingPrice, uint256 _endingPrice, uint256 _startingDate, uint256 _duration) public payable returns(uint256)  {
        //require(!NFT.is_sale(_tokenId), "active");
        
        _auction_str_int[_tokenId]["auctionStartPrice"] = _startingPrice;
        _auction_str_bool[_tokenId]["isAuction"] = _isAuction;
        
        if(_isAuction){
            //_auction_str_int[_tokenId]["auctionStartPrice"] = _startingPrice;
            _auction_str_int[_tokenId]["auctionEndPrice"] = _endingPrice;
            _auction_str_int[_tokenId]["auctionStartDate"] = _startingDate;
            _auction_str_int[_tokenId]["auctionEndDate"] = _duration;
        }
        
        
        //fundreceiver.transfer(msg.value);
        //emit NFTPurchased(msg.sender, msg.value, cardId);
        return _tokenId;
    }
    
    function getAuctionPrice(uint256 _tokenId) public view returns(uint256 price, uint256 pricepersec, uint256 lapsetime, uint256 timenow){
        uint256 _price = _auction_str_int[_tokenId]["auctionStartPrice"];
        bool _isAuction = _auction_str_bool[_tokenId]["isAuction"];
        uint256 _totalLapseTime;
        uint256 _addedPrice;
        
        if(_isAuction){
            //uint256 _sPrice = _auction_str_int[_tokenId]["auctionStartPrice"];
            uint256 _ePrice = _auction_str_int[_tokenId]["auctionEndPrice"];
            uint256 _sDate= _auction_str_int[_tokenId]["auctionStartDate"];
            uint256 _duration = _auction_str_int[_tokenId]["auctionEndDate"];
            
            //sample
            // s = 1
            // e = 2
            // duration 1 / 24 / 1440 / 86400
            
            uint256 _priceDiff;
            bool isPriceAsc;
            if(_price > _ePrice){
                isPriceAsc = false;
                _priceDiff = _price - _ePrice; 
            } else{
                isPriceAsc = true;
                _priceDiff = _ePrice - _price;
            }
            //price per second
            uint256 _pricerPerSec = (_priceDiff * decimalPrecision) / _duration;
            
            //get total duration
            _totalLapseTime = block.timestamp - _sDate;
            _addedPrice = _pricerPerSec * _totalLapseTime;
            
            if(_totalLapseTime >= _duration){
                _price = _ePrice;
            }else{
                if(isPriceAsc){
                    _price = (_price * decimalPrecision) + _addedPrice;
                }else{
                    _price = (_ePrice  * decimalPrecision) - _addedPrice;
                }
            }
        }
        
        return (_price, _addedPrice, _totalLapseTime, block.timestamp);
    }
    
    function currentTime() public view returns(uint256){
        return block.timestamp;
    }


}