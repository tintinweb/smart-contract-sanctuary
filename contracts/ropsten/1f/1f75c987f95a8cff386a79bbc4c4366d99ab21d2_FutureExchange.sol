/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface Token {
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
}

contract FutureExchange { 
    
    struct Escrow {
        bool escrowStatus;
        uint32 setTimeSellerCancel;
        // uint128 totalGasSpentByConsumers;
        uint256 sellerFee;
        uint256 buyerFee;
        bool sellerDispute;
        bool buyerDispute;
    }
    
    address public owner;
    address public feeAddress;
    uint32 public requestCancelMinimumTime;
    uint256 public feesAvailableForWithdraw = 0;
    
    mapping(bytes32 => Escrow) public escrow_map;
    mapping (address => mapping(address => uint256)) public _token;
    
    event Created(bytes32 _tradeHash);
    event SellerCancelDisabled(bytes32 _tradeHash);
    event SellerRequestedCancel(bytes32 _tradeHash);
    event CancelledBySeller(bytes32 _tradeHash);
    event CancelledByBuyer(bytes32 _tradeHash);
    event Released(bytes32 _tradeHash);
    event DisputeResolved(bytes32 _tradeHash);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address feeadd) {
        owner = msg.sender;
        feeAddress = feeadd;
        requestCancelMinimumTime = 7200; // 2hours
    }
    
    // Create Escrow by Seller
    // token need to be approved before transfer
    function createEscrow(uint16 _tradeId, address _seller, address _buyer, uint256 _amount, address _tokenContract, uint256 _sellerFee, uint256 _buyerFee,uint16 _type,uint32 _sellerCancelInSeconds) payable external returns(bool) {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
        require (msg.sender == _seller,"Invalid User..");
        require (_type == 1 || _type == 2, "Invalid Type.. ");
        require(escrow_map[_tradeHash].escrowStatus == false, "Status Checking Failed.. ");
       
        if(_type == 1){
            require(_amount == msg.value && msg.value > 0, "Invalid Amount..");                  
            require(_tokenContract == address(0), "Token address should be zero");
        }
        if(_type == 2){
            Token(_tokenContract).transferFrom(_seller,address(this), _amount);
        }
        
        uint32 _sellerCancelAfter = _sellerCancelInSeconds == 0 ? 1 : uint32(block.timestamp) + _sellerCancelInSeconds;
        escrow_map[_tradeHash].escrowStatus = true;
        escrow_map[_tradeHash].setTimeSellerCancel = _sellerCancelAfter;
        escrow_map[_tradeHash].sellerFee = _sellerFee;
        escrow_map[_tradeHash].buyerFee = _buyerFee;
        emit Created(_tradeHash); 
        return true;
    }
    
    function releseFunds(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount,address _tokenContract, uint16 _type) external returns (bool){
        return _releseFunds(_tradeId,_seller,_buyer,_amount,_tokenContract,_type);
    }
    
    function disableSellerCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount) external returns (bool){
        return _disableSellerCancel(_tradeId,_seller,_buyer,_amount);
    }
    
    function buyerCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount,  address tokenadd, uint256 _type) external returns (bool){
        return _buyerCancel(_tradeId,_seller,_buyer,_amount,tokenadd,_type);
    }
    
    function sellerCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount,  address tokenadd, uint256 _type) external returns (bool) {
        return _sellerCancel(_tradeId,_seller,_buyer,_amount,tokenadd,_type);
    }
    
    function sellerRequestCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount) external returns (bool) {
        return _sellerRequestCancel(_tradeId,_seller,_buyer,_amount);
    }
    
    function consumeDispute(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount, uint16 _type) external returns (bool){
        return  disputeCall(_tradeId,_seller,_buyer,_amount,_type);
    }
    
    //Its only called by Mediator, because of any issues between seller and buyer (vanish)
    //If the sellerDispute or buyerDispute is true for this trade
    function disputeByMediator(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount, uint16 _favour, uint16 _type, address _tokenContract) external  returns(bool) {
         require(msg.sender == feeAddress,"Invalide address");
         bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
         require(escrow_map[_tradeHash].sellerDispute == true || escrow_map[_tradeHash].buyerDispute == true, " Seller or Buyer Doesn't Call Dispute");
         require(escrow_map[_tradeHash].escrowStatus == true, " Status Failed..");
         require(_favour == 1 || _favour == 2,  "Invalid Favour Type");
         
         if(_type == 1){ //ether
             if(_favour == 1){ //seller
                 _seller.transfer(_amount);
             }
             
             else if (_favour == 2){ //buyer
                uint256 totalfee = escrow_map[_tradeHash].sellerFee + escrow_map[_tradeHash].buyerFee;
                
                feesAvailableForWithdraw += totalfee; //Add the the pot for localethereum to withdraw
                _buyer.transfer(_amount - totalfee);
             }
         }
         if(_type == 2) { //token
              if(_favour == 1) { //seller
                 Token(_tokenContract).transfer(_seller,_amount);
             }
             
             else if (_favour == 2){ //buyer
                uint256 totalfee = escrow_map[_tradeHash].sellerFee + escrow_map[_tradeHash].buyerFee;
                _token[address(this)][_tokenContract] += totalfee;
                //Token(_tokenContract).transfer(owner,totalfee);
                Token(_tokenContract).transfer(_buyer,(_amount - totalfee));
             }
         }
         delete escrow_map[_tradeHash];
         emit DisputeResolved(_tradeHash); // Event
         return true;
    }
    
    // Only Owner Functionalities ------------------------------------------------------------------------------------------------------------------------------------
    // Withdraw fees collected by the contract. Only the owner can call this.
    function withdrawFees(address payable _to, uint256 _amount,uint16 _type, address _tokenContract) onlyOwner external {
        if(_type == 1) {
              require(_amount <= feesAvailableForWithdraw); // Also prevents underflow
              feesAvailableForWithdraw -= _amount;
              _to.transfer(_amount);
        } else if(_type == 2){
             require(_amount <= _token[address(this)][_tokenContract]);
             _token[address(this)][_tokenContract] -= _amount;
             Token(_tokenContract).transfer(_to,_amount);
        }
    }

    // Change the owner to a new address. Only the owner can call this.
    function setOwner(address _newOwner) onlyOwner external{
        owner = _newOwner;
    }
    
    // Change the feeAddress to a new feeAddress. Only the owner can call this.
    function setFeeAddress(address _newFeeAddress) onlyOwner external{
        feeAddress = _newFeeAddress;
    }
    
    // Change the requestCancellationMinimumTime. Only the owner can call this.
    function setRequestCancellationMinimumTime(uint32 _newRequestCancelMinimumTime) onlyOwner external{
        requestCancelMinimumTime = _newRequestCancelMinimumTime;
    }
    
    // If ERC20 tokens are sent to this contract, they will be trapped forever.
    // This function is way for us to withdraw them so we can get them back to their rightful owner
    function approveToken(Token _tokenContract, address _spender, uint256 _value) onlyOwner external {
         _tokenContract.approve(_spender, _value);
    }
    
    // Private Functions ------------------------------------------------------------------------------------------------------------------------------------
    // After Confirm Payment Call By Seller 
    function _releseFunds(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount,address _tokenContract, uint16 _type) private returns(bool){
        require(msg.sender == feeAddress, "Invalid User.. ");
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
        require(escrow_map[_tradeHash].escrowStatus == true, "Status Checking Failed.. ");
        
        if(_type == 1 ){ //ether 
           transferMinusFees(_buyer, _amount, _tradeHash);
        }
        
        if (_type == 2) {
            uint256 _totalfee = escrow_map[_tradeHash].sellerFee + escrow_map[_tradeHash].buyerFee;
            _token[address(this)][_tokenContract] += _totalfee;
            uint256 amount = _amount - escrow_map[_tradeHash].sellerFee;
            Token(_tokenContract).transfer(_buyer,amount);
        }
        delete escrow_map[_tradeHash];
        emit Released(_tradeHash);
        return true;
    }  
    
    // After the payment successfull, the buyer clicks mark as paid & _additionalFee is always 0 
    function _disableSellerCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount) private returns(bool){
       bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
       require(escrow_map[_tradeHash].escrowStatus == true, "Status Checking Failed.. ");
       require(escrow_map[_tradeHash].setTimeSellerCancel !=0,  "Seller Cancel time is Differ.. ");
       require(msg.sender == feeAddress, "Invalid User.. ");
       
       escrow_map[_tradeHash].setTimeSellerCancel = 0;
       emit SellerCancelDisabled(_tradeHash); // Event
       return true;
    }
    
    // If the buyer wants to cancel the trade, the escrow send back ether to seller
    function _buyerCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount,address tokenadd, uint256 _type) private returns(bool){
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
        require(escrow_map[_tradeHash].escrowStatus == true && msg.sender == feeAddress);
        require(escrow_map[_tradeHash].setTimeSellerCancel > block.timestamp, "Time  Expired Issue..");
        delete escrow_map[_tradeHash];
         
        if(_type == 1 ) {
           _seller.transfer(_amount);
        }
        if (_type == 2) {
            Token(tokenadd).transfer(_seller,_amount);
        }
        emit CancelledByBuyer(_tradeHash); 
        return true;
    }
    
    // If the seller wants to cancel the trade, the escrow send back ether to seller,
    // Its only called if the buyer missed to pay the amount 
    function _sellerCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount, address tokenadd, uint256 _type) private returns(bool){
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
        require(escrow_map[_tradeHash].escrowStatus == true && msg.sender==feeAddress);
        if(escrow_map[_tradeHash].setTimeSellerCancel <= 1 || escrow_map[_tradeHash].setTimeSellerCancel > block.timestamp) revert();
        delete escrow_map[_tradeHash];
       
        if(_type == 1 ) {
          _seller.transfer(_amount);
        }
        if (_type == 2) {
           Token(tokenadd).transfer(_seller,_amount);
        }
        emit CancelledBySeller(_tradeHash); 
        return true;
    }
    
    // If the seller wants to cancel the request, seller calls.
    // If the sellet set time for cancel = = 1 
    // Its only called if the buyer is unresponsive 
    function _sellerRequestCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount) private returns(bool){
       bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
       require(feeAddress==msg.sender, "Invalid User.. ");
       require(escrow_map[_tradeHash].escrowStatus == true, "Status Checking Failed.. ");
       require (escrow_map[_tradeHash].setTimeSellerCancel == 1,  "Seller Cancel time is Differ.. ");
       escrow_map[_tradeHash].setTimeSellerCancel = uint32(block.timestamp) + requestCancelMinimumTime;

       emit SellerRequestedCancel(_tradeHash); // Event
       return true;
    }
    
    // Call for dispute if the clashes between seller or buyer
    function disputeCall(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount, uint16 disputetype) private returns (bool _status){
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
        require(msg.sender == feeAddress, " Invalid User.. ");
        require(escrow_map[_tradeHash].escrowStatus == true, " Status Failed.. ");
         
        if(disputetype == 1){
           escrow_map[_tradeHash].sellerDispute = true;
           return true;
        } else if(disputetype == 2){
           escrow_map[_tradeHash].buyerDispute = true;
           return true;
        }
    }
    
    // Transfer without Fees 
    function transferMinusFees(address payable _to, uint256 _amount, bytes32 tradehash) private returns(bool){
        uint256 _totalFees = escrow_map[tradehash].sellerFee + escrow_map[tradehash].buyerFee  ;
        feesAvailableForWithdraw += _totalFees; // Add the the pot for localethereum to withdraw
        _to.transfer(_amount - escrow_map[tradehash].sellerFee );
        return true;        
    }
}