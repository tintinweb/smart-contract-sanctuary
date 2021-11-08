// SPDX-License-Identifier: Apache-2.0
// 2021 (C) SUPER HOW Contracts: superhow.ART Auction governance v1.0 

pragma solidity 0.8.4;

import "./Weighting.sol";
import "./IERC20.sol";
import "./IERC1155.sol";


interface IERC1155extended is IERC1155 {
    
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

}

contract Governance {
    
    uint256 internal _idNFT = 0;
    address internal _governanceBeneficiary;
    address internal _whaleAddress;
    address internal _shrimpAddress;
    address internal _erc1155ContractAddress;
    uint internal _winner;
    uint internal _userAmount;
    uint internal _shrimpTransferAmount;
    uint internal _governanceAuctionEndTime;
    uint internal _totalGovernance;
    uint internal _firstDistributionCount;
    uint internal _lastDistributionCount;
    bool internal _distributedAllNFT;
    IERC1155extended internal _erc1155ContractInstance;


    modifier onlyGovernanceOwner() {
        require(msg.sender == _governanceBeneficiary, "Only the owner can use this function");
        _;
    }
    
    modifier afterGovernanceAuction() {
        require(block.timestamp >= _governanceAuctionEndTime, "Auction time is incorrect");
        _; 
    }
    
    modifier distributedAllNFT() {
        require(false == _distributedAllNFT, "NFT's have been distributed to all users");
        _;
    }
   
    constructor(
        address governanceBeneficiary
        ){
        _governanceBeneficiary = governanceBeneficiary;
        _firstDistributionCount = 0;
        _lastDistributionCount = 100;
        _distributedAllNFT = false;
    }
    
    function distributeNFTToWinner(Weighting weightingContract, Whales whalesContract, Shrimps shrimpsContract)
        public
        distributedAllNFT()
        onlyGovernanceOwner()
    {
        _governanceAuctionEndTime = weightingContract.getAuctionEndTime();
        _winner = weightingContract._passWinner();
        require(_winner != 0, "Winner has not been anounced yet or auction has failed to raise funds");
        require(_winner != 3, "Minumum has not been reached for the sale of the painting");
        if(_winner == 1){
            _distributeToWhale(whalesContract);
        }else if (_winner == 2){
            _distributeToShrimps(shrimpsContract);
        }
    }
    
    function _distributeToShrimps(Shrimps shrimpsContract)
        internal
        afterGovernanceAuction()
    {       
            _totalGovernance = shrimpsContract.getTotalBid() / 1e17 wei;
            require(_totalGovernance > 0, "Shrimp bid amount was 0 or less");
            if(_firstDistributionCount == 0){
                _erc1155ContractInstance.mint(_governanceBeneficiary, _idNFT, _totalGovernance, "");
            }
            _userAmount = shrimpsContract.getTotalAmountOfShrimps();
            if (_lastDistributionCount > shrimpsContract.getTotalAmountOfShrimps()) {
                _lastDistributionCount = shrimpsContract.getTotalAmountOfShrimps();
            }
            for (uint j = _firstDistributionCount; j < _lastDistributionCount; j++) {
                _shrimpAddress = shrimpsContract.getShrimpAddress(j);
                _shrimpTransferAmount = shrimpsContract.getShrimpBid(_shrimpAddress);
                require(_shrimpTransferAmount > 0, "Shrimp bid amount must be higher than 0");
                _shrimpTransferAmount = _shrimpTransferAmount / 1e17 wei;
                _erc1155ContractInstance.safeTransferFrom(_governanceBeneficiary, _shrimpAddress, _idNFT, _shrimpTransferAmount, "");
            }
            _firstDistributionCount = _lastDistributionCount;
            _lastDistributionCount += 100;
            if (_firstDistributionCount >= shrimpsContract.getTotalAmountOfShrimps()) {
                _distributedAllNFT = true;
            }
    }
    
    function _distributeToWhale(Whales whalesContract)
        internal
        afterGovernanceAuction()
    {
            _userAmount = 1;
            _totalGovernance = 1;
            _whaleAddress = whalesContract.getHighestBidder();
            _erc1155ContractInstance.mint(_whaleAddress, _idNFT, _userAmount, "");
            
            // _erc1155ContractInstance.safeTransferFrom(_governanceBeneficiary, _whaleAddress, 0, _userAmount, "");
            _distributedAllNFT = true;
    }
    
    function governanceTransfer(address recipient, uint256 amount)
        public 
        onlyGovernanceOwner()
        afterGovernanceAuction()
        returns (bool) 
    {
        _governanceTransfer(msg.sender, recipient, amount);
        return true;
    }
    
    function _governanceTransfer(address sender, address recipient, uint256 amount) 
        internal
        virtual 
    {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        uint256 senderBalance = address(this).balance;
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        payable(recipient).transfer(amount);
    }
    
    function setERC1155contract(address erc1155ContractAddress) 
        public
        onlyGovernanceOwner()
    {
        _erc1155ContractAddress = erc1155ContractAddress;
        // creates erc1155 interface with set ERC1155 address
        _erc1155ContractInstance = IERC1155extended(erc1155ContractAddress);
    }
    
    function setIdNFT(uint256 idNFT) 
        public
        onlyGovernanceOwner()
    {
        _idNFT = idNFT;
    }
    
    function governanceWithdrawERC20ContractTokens(IERC20 tokenAddress, address recipient)
        public
        onlyGovernanceOwner()
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
    
    function getOwnedGovernanceAmount(address userAddress) 
        public
        view
        afterGovernanceAuction()
        returns (uint)
    {
        require(userAddress != address(0), "User address is zero");
        require(_totalGovernance != 0, "Governance has yet to be distributed");
        uint ownedGovernanceAmount = _erc1155ContractInstance.balanceOf(userAddress, _idNFT);
        return ownedGovernanceAmount;
    }
    function getERC1155contract() 
        public
        view
        returns (address)
    {
        return _erc1155ContractAddress;
    }
    
    function getIdNFT() 
        public
        view
        returns (uint256)
    {
        return _idNFT;
    }
    
    
    function getTotalGovernanceAmount() 
        public
        view
        afterGovernanceAuction()
        returns (uint)
    {
        require(_totalGovernance != 0, "Governance has yet to be distributed");
        return _totalGovernance;
    }

    function getGovernanceBeneficiary() 
        public
        view
        returns (address)
    {
        return _governanceBeneficiary;
    }
    
}