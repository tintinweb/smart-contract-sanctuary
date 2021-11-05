// SPDX-License-Identifier: Apache-2.0
// 2021 (C) SUPER HOW Contracts: superhow.ART Auction engine v1.0

pragma solidity 0.8.4;

import "./Whales.sol";
import "./Shrimps.sol";
import "./IERC20.sol";


contract Weighting {
    
    address payable internal _weightingBeneficiary;
    address internal _highestWhaleBidder;
    address internal _winnerContract;
    address internal _shrimpsContractAddress;
    address internal _whalesContractAddress;
    uint internal _highestWhaleBid;
    uint internal _highestShrimpBid;
    uint internal _whaleBidTime;
    uint internal _shrimpBidTime;
    uint internal _auctionEndTime;  
    uint internal _paintingMinimalPricing;
    uint internal _weightingWinner;
    uint internal _weightingWinnerMidAuction;
    bool internal _whaleWinnerCheck;
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    receive() external payable {}
    fallback() external payable {}

    modifier onlyOwner() {
        require(msg.sender == _weightingBeneficiary, "Only the owner can use this function");
        _;
    }
    
    modifier afterAuction() {
        require(block.timestamp >= _auctionEndTime, "Auction time is incorrect");
        _;
    }
    
    modifier beforeAuction() {
        require(block.timestamp < _auctionEndTime, "Auction time is incorrect");
        _;
    }
    modifier onlyShrimpsOrWhales() {
        require(msg.sender == _whalesContractAddress || msg.sender == _shrimpsContractAddress, "Not shrimps or whales contract calling");
        _;
    }
    
   
    constructor(
        address payable weightingBeneficiary,
        uint paintingMinimalPricing,
        uint auctionEndTime
    )
    {
        _weightingBeneficiary = weightingBeneficiary;
        _paintingMinimalPricing = paintingMinimalPricing;
        _auctionEndTime = auctionEndTime;
        
        _weightingWinner = 0;
        _weightingWinnerMidAuction = 0;
        _whaleWinnerCheck = false;
    }
   
    function returnWhaleFunds(Whales whalesContract) 
        public
        payable
        onlyOwner()
        afterAuction()
    {
        whalesContract._returnWhaleFunds();
    }
    
    function returnShrimpFunds(Shrimps shrimpContract) 
        public
        payable
        onlyOwner()
        afterAuction()
    {
        shrimpContract._returnShrimpFunds();
    }
    
    function determineWinner(Whales whalesContract, Shrimps shrimpContract)
        public
        onlyOwner()
        afterAuction()
        returns(uint)
    {
        _highestWhaleBid = whalesContract.getHighestBid();
        _highestShrimpBid = shrimpContract.getTotalBid();
        
        _whaleBidTime = whalesContract.getWhaleLastBidTime();
        _shrimpBidTime = shrimpContract.getShrimpLastBidTime();
    
        if(_highestShrimpBid < _paintingMinimalPricing && _highestWhaleBid < _paintingMinimalPricing){
            _weightingWinner = 3;
            return(_weightingWinner);
        }else{
            if(_highestWhaleBid > _highestShrimpBid){
                _weightingWinner = 1;
                _winnerContract = address(whalesContract);
            }else if (_highestWhaleBid < _highestShrimpBid){
                _weightingWinner = 2;
                _winnerContract = address(shrimpContract);
            }else{
                if(_whaleBidTime < _shrimpBidTime){
                    _weightingWinner = 1;
                    _winnerContract = address(whalesContract);
                }else{
                    _weightingWinner = 2;
                    _winnerContract = address(shrimpContract);
                }
            }
        }

        return(_weightingWinner);
    }
    
    function determineWinnerMidAuction(Whales whalesContract, Shrimps shrimpContract)
        public
        returns(uint, uint)
    {
        uint _highestWinnerBidMidAuction;
        _highestWhaleBid = whalesContract.getHighestBid();
        _highestShrimpBid = shrimpContract.getTotalBid();
        
        _whaleBidTime = whalesContract.getWhaleLastBidTime();
        _shrimpBidTime = shrimpContract.getShrimpLastBidTime();
        
        if(_highestWhaleBid > _highestShrimpBid){
            _weightingWinnerMidAuction = 1;
            _highestWinnerBidMidAuction = _highestWhaleBid;
        }else if (_highestWhaleBid < _highestShrimpBid){
            _weightingWinnerMidAuction = 2;
            _highestWinnerBidMidAuction = _highestShrimpBid;
        }else{
            if(_whaleBidTime < _shrimpBidTime){
                _weightingWinnerMidAuction = 1;
                _highestWinnerBidMidAuction = _highestWhaleBid;
            }else{
                _weightingWinnerMidAuction = 2;
                _highestWinnerBidMidAuction = _highestShrimpBid;
            }
        }
        return(_weightingWinnerMidAuction, _highestWinnerBidMidAuction);
    }
    
    function weightingTransfer(address recipient, uint256 amount)
        public 
        onlyOwner()
        afterAuction()
        returns (bool) 
    {
        _weightingTransfer(msg.sender, recipient, amount);
        return true;
    }
    
    function _weightingTransfer(address sender, address recipient, uint256 amount) 
        internal
        virtual 
    {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        uint256 senderBalance = address(this).balance;
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        payable(recipient).transfer(amount);
    }
    
    function weightingWithdrawERC20ContractTokens(IERC20 tokenAddress, address recipient)
        public
        onlyOwner()
        returns(bool)
    {
        require(msg.sender != address(0), "Sender is address zero");
        require(recipient != address(0), "Receiver is address zero");
        tokenAddress.approve(address(this), tokenAddress.balanceOf(address(this)));
        if(!tokenAddress.transferFrom(address(this), recipient, tokenAddress.balanceOf(address(this)))){
            return false;
        }
        return true;
    }
    
    function setAuctionEndTime() 
        external
        onlyShrimpsOrWhales()
    {
        _auctionEndTime = block.timestamp + 15 minutes;
    }
    
    function setPaintingMinimalPricing(uint newPrice) 
        public
        onlyOwner()
    {
        _paintingMinimalPricing = newPrice;
    }
    
    function setAuctionEndTimeManual(uint256 newtime) 
        public
        onlyOwner()
    {
        _auctionEndTime = newtime;
    }

    function confirmWhaleWinner()
        public
        afterAuction()
    {
        require(msg.sender == _highestWhaleBidder, "False winner interaction");
        _whaleWinnerCheck = true;
    }
    
    function setWhalesContract(address whalesContractAddress) 
        public
        onlyOwner()
    {
        _whalesContractAddress = whalesContractAddress;
    }
    
    function setShrimpsContract(address shrimpsContractAddress) 
        public
        onlyOwner()
    {
        _shrimpsContractAddress = shrimpsContractAddress;
    }

    function _passWinner()
        external
        view
        afterAuction()
        returns(uint)
    {
        return (_weightingWinner);
    }
    
    function getWhaleData(Whales whalesContract)
        public
        onlyOwner()
        returns (address, uint)
    {
        _highestWhaleBidder = whalesContract.getHighestBidder();
        _highestWhaleBid = whalesContract.getHighestBid();
        return (_highestWhaleBidder, _highestWhaleBid);
    }
    
    function getShrimpData(Shrimps shrimpContract)
        public
        onlyOwner()
        returns (uint)
    {
        _highestShrimpBid = shrimpContract.getTotalBid();
        return (_highestShrimpBid);
    }
    
    function getBeneficiary() 
        public
        view
        returns (address)
    {
        return _weightingBeneficiary;
    }
    
    function getHighestWhaleBidder() 
        public
        view
        returns (address) 
    {
        return _highestWhaleBidder;
    }
    
    function getWinnerContract() 
        public
        view
        returns (address)
    {
        return _winnerContract;
    }
    
    function getHighestWhaleBid() 
        public
        view
        returns (uint) 
    {
        return _highestWhaleBid;
    }
    
    function getHighestShrimpBid() 
        public
        view
        returns (uint) 
    {
        return _highestShrimpBid;
    }
    
    function getAuctionEndTime() 
        public
        view
        returns (uint) 
    {
        return _auctionEndTime;
    }
    
    function whaleWinnerContractInteraction() 
        public
        afterAuction()
        view
        returns (bool) 
    {
        return _whaleWinnerCheck;
    }
 
    function getWeightingContractAddress() 
        public
        view
        returns (address) 
    {
        return address(this);
    }
    
    function getShrimpsContractAddress() 
        public
        view
        returns (address) 
    {
        return _shrimpsContractAddress;
    }
    
    function getWhalesContractAddress() 
        public
        view
        returns (address) 
    {
        return _whalesContractAddress;
    }
    
}