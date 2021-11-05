// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.4;

import "./Weighting.sol";
import "./IERC20.sol";


contract Shrimps {

    address payable internal _shrimpBeneficiary;
    address internal _shrimpWeightingContract;
    uint internal _totalBid;
    uint internal _maximumShrimpBid;
    uint internal _minimumShrimpBid;
    uint internal _shrimpLastBidTime;
    uint internal _shrimpIncrement;
    uint internal _shrimpReturnFee;
    uint internal _firstDistributionCount;
    uint internal _lastDistributionCount;
    address[] internal shrimpAddresses;   
    bool internal _returnedAllFunds;
    bool private constant NOT_ENTERED = false;
    bool private constant ENTERED = true;
    Weighting scon;
    
    mapping(address => uint) internal _shrimpArray;
    mapping(address => bool) internal _shrimpBid;
    mapping(address => bool) internal _userShrimpReentrancy;
    
    receive() external payable {}
    fallback() external payable {}
    
    modifier shrimpMultipleETH(){
      require(msg.value % _shrimpIncrement * 10**18 == 0, "Only 0,1 ETH multiples are accepted"); //0.1 ether
       _;
    }
   
    modifier beforeShrimpAuction(uint _time) {
        require(block.timestamp < _time, "Shrimp auction has ended");
        _;
    }
    
    modifier afterShrimpAuction(uint _time) {
        require(block.timestamp >= _time, "Shrimp auction did not end yet");
        _;
    }
    
    modifier notShrimpOwner() {
        require(msg.sender != _shrimpBeneficiary, "Contract owner can not interract here");
        _;
    }
    
    modifier onlyShrimpOwner(address messageSender) {
        require(_shrimpBeneficiary == messageSender, "Only the owner can use this function");
        _;
    }
    
    modifier isShrimpWeighting() {
        require(address(_shrimpWeightingContract) == msg.sender, "Wrong contract passed. Contract is not Weighting");
        _;
    }
    
    modifier highestBidMaximum() {
        require(msg.value <= _maximumShrimpBid, "Bid must be less than the set maximum bid");
        require((_shrimpArray[msg.sender] + msg.value) <= _maximumShrimpBid, "Bid must be less than the set maximum bid");
        _;
    }
    
    modifier lowestShrimpBidMinimum() {
        require(msg.value >= _minimumShrimpBid/(1 ether), "Minimum bid amount required");
        _;
    }
    
    modifier returnedAllFunds() {
        require(false == _returnedAllFunds, "Funds have been returned to all users");
        _;
    }
    
    modifier nonShrimpReentrant() {
        require(_userShrimpReentrancy[msg.sender] != ENTERED, "ReentrancyGuard: reentrant call");
        _userShrimpReentrancy[msg.sender] = ENTERED;
        _;
        _userShrimpReentrancy[msg.sender] = NOT_ENTERED;
    }

    constructor(
        address payable shrimpBeneficiary,
        uint maximumShrimpBid,
        uint minimumShrimpBid,
        address shrimpWeightingContract
    )
    {
        _shrimpBeneficiary = shrimpBeneficiary;
        _maximumShrimpBid = maximumShrimpBid;
        _minimumShrimpBid = minimumShrimpBid;
        _shrimpWeightingContract = shrimpWeightingContract;
        scon = Weighting(payable(_shrimpWeightingContract));
        _shrimpIncrement = 0.1 ether;
        _shrimpReturnFee = 0.001 ether;
        _firstDistributionCount = 0;
        _lastDistributionCount = 100;
        _returnedAllFunds = false;
    }
    
    function shrimpsBid()
        public
        payable
        beforeShrimpAuction(scon.getAuctionEndTime())
        notShrimpOwner()
        highestBidMaximum()
        lowestShrimpBidMinimum()
        shrimpMultipleETH()
        nonShrimpReentrant()
    {
        _shrimpsBid();
    }
   
    function _shrimpsBid()
        internal
    {
        uint amount = msg.value;
        
        if(amount > 0){
            _shrimpArray[msg.sender] = _shrimpArray[msg.sender] + amount;
            if(_shrimpBid[msg.sender] == false){
                _shrimpBid[msg.sender] = true;
                shrimpAddresses.push(msg.sender);
            }
            _totalBid = _totalBid + amount;
            _shrimpLastBidTime = block.timestamp;
            
            uint timeLeft = scon.getAuctionEndTime() - block.timestamp;
            if(timeLeft <= 15 minutes){
                scon.setAuctionEndTime();
            }
        }
    }

    function _returnShrimpFunds()
        external
        payable
        isShrimpWeighting()
        returnedAllFunds()
        afterShrimpAuction(scon.getAuctionEndTime())
    {
        if (_lastDistributionCount > shrimpAddresses.length) {
            _lastDistributionCount = shrimpAddresses.length;
        }
        for (uint j = _firstDistributionCount; j < _lastDistributionCount; j++) {
            if(_shrimpArray[shrimpAddresses[j]] > 0){
                uint amount = _shrimpArray[shrimpAddresses[j]] - _shrimpReturnFee;
                if(payable(shrimpAddresses[j]).send(amount)){
                    _shrimpArray[shrimpAddresses[j]] = 0;
                }
            }
        }
        _firstDistributionCount = _lastDistributionCount;
        _lastDistributionCount += 100;
        if (_firstDistributionCount >= shrimpAddresses.length) {
            _returnedAllFunds = true;
        }
    }
    
    function transferShrimpOwnership(address payable newShrimpBeneficiary)
        public
        onlyShrimpOwner(msg.sender)
        beforeShrimpAuction(scon.getAuctionEndTime())
    {
        _transferShrimpOwnership(newShrimpBeneficiary);
    }
   
    function _transferShrimpOwnership(address payable newShrimpBeneficiary)
        internal
    {
        require(newShrimpBeneficiary != address(0));
        _shrimpBeneficiary = newShrimpBeneficiary;  
    }
    
    function transferShrimpOwnershipToZero()
        public
        onlyShrimpOwner(msg.sender)
        beforeShrimpAuction(scon.getAuctionEndTime())
    {
        _transferShrimpOwnershipToZero();
    }
   
    function _transferShrimpOwnershipToZero()
        internal
    {
        _shrimpBeneficiary = payable(address(0));  
    }
    
    function shrimpsTransfer(address recipient, uint256 amount)
        public 
        onlyShrimpOwner(msg.sender)
        afterShrimpAuction(scon.getAuctionEndTime())
        returns (bool) 
    {   
        _shrimpsTransfer(msg.sender, recipient, amount);
        return true;
    }
    
    function _shrimpsTransfer(address sender, address recipient, uint256 amount) 
        internal
        virtual 
    {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        uint256 senderBalance = address(this).balance;
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        if(_shrimpBid[recipient] == true){
            _shrimpArray[recipient] = _shrimpArray[recipient] - amount;
            _totalBid = _totalBid - amount;
            if(_shrimpArray[recipient] == 0){
                delete _shrimpArray[recipient];
            }
        }
        payable(recipient).transfer(amount);
    }
    
    function shrimpsWithdrawERC20ContractTokens(IERC20 tokenAddress, address recipient)
        public
        onlyShrimpOwner(msg.sender)
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
    
    function resetShrimpReentrancy(address user) 
        public
        onlyShrimpOwner(msg.sender)
    {
        _userShrimpReentrancy[user] = NOT_ENTERED;
    }

    function getShrimpBeneficiary() 
        public
        view
        returns (address)
    {
        return _shrimpBeneficiary;
    }
    
    function getShrimpAuctionEndTime() 
        public
        view
        returns (uint) 
    {
        return scon.getAuctionEndTime();
    }
    
    function getTotalBid() 
        public
        view
        returns (uint)
    {
        return _totalBid;
    }
    
    function getShrimpReturnFee() 
        public
        view
        returns (uint256) 
    {
        return _shrimpReturnFee;
    }
    
    function getMaximumShrimpBid() 
        public
        view
        returns (uint) 
    {
        return _maximumShrimpBid;
    }
    
    function getMinimumShrimpBid() 
        public
        view
        returns (uint) 
    {
        return _minimumShrimpBid;
    }
    
    function checkIfShrimpExists(address shrimp) 
        public
        view
        returns (bool)
    {
        if(_shrimpBid[shrimp] == true){
            return true;
        }
        return false;
    }
    
    function getShrimpBid(address shrimpAddress) 
        public
        view
        returns (uint) 
    {
        return _shrimpArray[shrimpAddress];
    }
    
    function getShrimpReentrancyStatus(address user) 
        public
        view
        onlyShrimpOwner(msg.sender)
        returns (bool) 
    {
        return _userShrimpReentrancy[user];
    }
    
    function getTotalAmountOfShrimps() 
        public
        view
        returns (uint) 
    {
        return shrimpAddresses.length;
    }
    
    function getShrimpLastBidTime()
        public
        view
        returns (uint)
    {
        return _shrimpLastBidTime;
    }
    
    function getShrimpIncrement() 
        public
        view
        returns (uint) 
    {
        return _shrimpIncrement;
    }
    
    function getShrimpAddress(uint id) 
        public
        view
        returns (address)
    {
        return shrimpAddresses[id];
    }
    
    function getShrimpContractAddress() 
        public
        view
        returns (address)
    {
        return address(this);
    }
    
    function getShrimpContractBalance() 
        public
        view
        returns (uint) 
    {
        return address(this).balance;
    }
    
}