// SPDX-License-Identifier: Apache-2.0
// 2021 (C) SUPER HOW Contracts: superhow.ART Whales bidding v1.0

pragma solidity 0.8.4;

import "./Weighting.sol";
import "./IERC20.sol";


contract Whales {
   
    address payable internal _whaleBeneficiary;
    address internal _whaleWeightingContract;
    address internal _whaleHighestBidder;
    uint internal _highestBid;
    uint internal _whaleLastBidTime;
    uint internal _minimumWhaleBid;
    uint internal _whaleIncrement;
    uint internal _whaleReturnFee;
    bool private constant NOT_ENTERED = false;
    bool private constant ENTERED = true;
    Weighting wcon;

    receive() external payable {}
    fallback() external payable {}
   
    mapping(address => uint) internal _pendingReturns;
    mapping(address => bool) internal _userWhaleReentrancy;
    
    modifier whaleMultipleETH(){
       require(msg.value % _whaleIncrement == 0, "Only 1 ETH multiples are accepted"); //1 ether
       _;
    }
   
    modifier beforeWhaleAuction(uint _time) {
        require(block.timestamp < _time, "Whale auction has ended");
        _;
    }
    
    modifier afterWhaleAuction(uint _time) {
        require(block.timestamp >= _time, "Whale auction did not end yet");
        _;
    }
    
    modifier notWhaleOwner() {
        require(msg.sender != _whaleBeneficiary, "Contract owner can not interract here");
        _;
    }
    
    modifier onlyWhaleOwner(address messageSender) {
        require(_whaleBeneficiary == messageSender, "Only the owner can use this function");
        _;
    }
    
    modifier isWhaleWeighting() {
        require(address(_whaleWeightingContract) == msg.sender, "Wrong contract passed. Contract is not Weighting");
        _;
    }
    
    modifier cantBeFutureOwner(address newBeneficiaryW) {
        require(_whaleHighestBidder != newBeneficiaryW, "Can not pass ownership to highest bidder");
        _;
    }
    
    modifier lowestWhaleBidMinimum() {
        require(msg.value >= _minimumWhaleBid/(1 ether), "Minimum bid amount required");
        _;
    }
    
    modifier highestBidRequired() {
        require(msg.value > _highestBid, "Highest bidder amount required");
        _;
    }
    
    modifier sameBidder() {
        require(msg.sender == _whaleHighestBidder, "Only the same bidder can add to amount");
        _;   
    }
    
    modifier nonWhaleReentrant() {
        require(_userWhaleReentrancy[msg.sender] != ENTERED, "ReentrancyGuard: reentrant call");
        _userWhaleReentrancy[msg.sender] = ENTERED;
        _;
        _userWhaleReentrancy[msg.sender] = NOT_ENTERED;
    }

    constructor(
        address payable whaleBeneficiary,
        uint minimumWhaleBid,
        address whaleWeightingContract
    )
    {
        _whaleBeneficiary = whaleBeneficiary;
        _minimumWhaleBid = minimumWhaleBid;
        _whaleWeightingContract = whaleWeightingContract;
        wcon = Weighting(payable(_whaleWeightingContract));
        
        _whaleIncrement = 1 ether;
        _whaleReturnFee = 0.01 ether;
    }
    
    function whalesBid()
        public
        payable
        beforeWhaleAuction(wcon.getAuctionEndTime())
        notWhaleOwner()
        lowestWhaleBidMinimum()
        highestBidRequired()
        whaleMultipleETH()
        nonWhaleReentrant()
    {
        _whalesBid();
    }
   
    function _whalesBid()
        internal
    {
        if (_highestBid != 0) {
            _pendingReturns[_whaleHighestBidder] = _pendingReturns[_whaleHighestBidder] + _highestBid;
            uint amount = _pendingReturns[_whaleHighestBidder];
            if (amount > 0) {
                _pendingReturns[_whaleHighestBidder] = 0;
                if (!payable(_whaleHighestBidder).send(amount)) {
                    _pendingReturns[_whaleHighestBidder] = amount;
                }
            }
        }
        
        _whaleHighestBidder = msg.sender;
        _highestBid = msg.value;
        
        uint timeLeft = wcon.getAuctionEndTime() - block.timestamp;
        if(timeLeft <= 15 minutes){
            wcon.setAuctionEndTime();
        }
        _whaleLastBidTime = block.timestamp;
    }
    
    function addToWhalesBid()
        public
        payable
        beforeWhaleAuction(wcon.getAuctionEndTime())
        notWhaleOwner()
        sameBidder()
        whaleMultipleETH()
        nonWhaleReentrant()
    {
        _addToBid();
    }
    
    function _addToBid()
        internal
    {
        if(msg.value > 0 && _highestBid > 0){
            _highestBid = _highestBid + msg.value;
            _whaleLastBidTime = block.timestamp;
        }
    }

    function _returnWhaleFunds() 
        external
        payable
        isWhaleWeighting()
        afterWhaleAuction(wcon.getAuctionEndTime())
    {
        if (_highestBid > 0) {
            uint amount =  address(this).balance - _whaleReturnFee;
            payable(_whaleHighestBidder).transfer(amount);
        }
    }
    
    function transferWhaleOwnership(address payable newWhaleBeneficiary)
        public
        onlyWhaleOwner(msg.sender)
        beforeWhaleAuction(wcon.getAuctionEndTime())
        cantBeFutureOwner(newWhaleBeneficiary)
    {
        _transferWhaleOwnership(newWhaleBeneficiary);
    }
   
    function _transferWhaleOwnership(address payable newWhaleBeneficiary)
        internal
    {
        require(newWhaleBeneficiary != address(0));
        _whaleBeneficiary = newWhaleBeneficiary;  
    }
    
        
    function transferWhaleOwnershipToZero()
        public
        onlyWhaleOwner(msg.sender)
        beforeWhaleAuction(wcon.getAuctionEndTime())
    {
        _transferWhaleOwnershipToZero();
    }
   
    function _transferWhaleOwnershipToZero()
        internal
    {
        _whaleBeneficiary = payable(address(0));  
    }
    
    function whalesTransfer(address recipient, uint256 amount)
        public 
        onlyWhaleOwner(msg.sender)
        afterWhaleAuction(wcon.getAuctionEndTime())
        returns (bool) 
    {
        _whalesTransfer(msg.sender, recipient, amount);
        return true;
    }
    
    function _whalesTransfer(address sender, address recipient, uint256 amount) 
        internal
        virtual 
    {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        uint256 senderBalance = address(this).balance;
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        
        if(recipient == _whaleHighestBidder){
            _highestBid = _highestBid - amount;
            if(_highestBid == 0){
                _whaleHighestBidder = address(0);
            }
        }
        payable(recipient).transfer(amount);
    }
    
    function whalesWithdrawERC20ContractTokens(IERC20 tokenAddress, address recipient)
        public
        onlyWhaleOwner(msg.sender)
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
    
    function resetWhaleReentrancy(address user) 
        public
        onlyWhaleOwner(msg.sender)
    {
        _userWhaleReentrancy[user] = NOT_ENTERED;
    }
    
    function getPendingReturns(address user) 
        public
        view
        onlyWhaleOwner(msg.sender)
        returns (uint256) 
    {
        return _pendingReturns[user];
    }
    
    function getWhaleReturnFee() 
        public
        view
        returns (uint256) 
    {
        return _whaleReturnFee;
    }
    
    function getWhaleReentrancyStatus(address user) 
        public
        view
        onlyWhaleOwner(msg.sender)
        returns (bool) 
    {
        return _userWhaleReentrancy[user];
    }

    function getWhaleBeneficiary() 
        public
        view
        returns (address) 
    {
        return _whaleBeneficiary;
    }
    
    function getHighestBidder() 
        public
        view
        returns (address) 
    {
        return _whaleHighestBidder;
    }
    
    function getWhaleAuctionEndTime() 
        public
        view
        returns (uint)
    {
        return wcon.getAuctionEndTime();
    }
    
    function getWhaleLastBidTime()
        public
        view
        returns (uint)
    {
        return _whaleLastBidTime;
    }
    
    function getHighestBid() 
        public
        view
        returns (uint) 
    {
        return _highestBid;
    }
    
    function getWhaleIncrement() 
        public
        view
        returns (uint) 
    {
        return _whaleIncrement;
    }
    
    function getMinimumWhaleBid() 
        public
        view
        returns (uint)
    {
        return _minimumWhaleBid;
    }

    function getWhaleContractAddress() 
        public
        view
        returns (address)
    {
        return address(this);
    }
    
    function getWhaleContractBalance() 
        public
        view
        returns (uint) 
    {
        return address(this).balance;
    }
    
}