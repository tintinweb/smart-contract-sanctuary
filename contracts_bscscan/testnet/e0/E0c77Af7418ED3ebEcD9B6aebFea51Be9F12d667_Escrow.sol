/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/// @title Escrow contract
/// @author Freezy-Ex (https://github.com/FreezyEx)
/// @notice A smart contract that can be used as an escrow

contract Escrow{
    
    // list of moderators
    mapping(address => bool) private moderators;
    
    mapping(address => mapping(uint256 => EscrowStruct)) public buyerDatabase;
    
    address public feeCollector; // Collected taxes will be forwarded here

    enum Status { PENDING, COMPLETED, REFUNDED }
    
    struct EscrowTax {
        uint256 buyerTax;
        uint256 sellerTax;
    }
    
    struct EscrowStruct {
        address buyer;      //the address of the buyer
        address seller;     //the address of the seller
        uint256 amount;     //the price of the order
        uint256 tax_amount; //the amount in BNB of the tax
        Status status;      //the current status of the order
    }
    
    
    EscrowTax public escrowTax = EscrowTax({
        buyerTax: 2,
        sellerTax: 2
    });
    
    modifier onlyModerators() {
       require(moderators[msg.sender],"Address is not moderator");
       _;
    }
    
    event RefundEmitted(address buyer, uint256 id, uint256 amount);
    event ResolvedToSeller(address seller, uint256 id, uint256 amount);
    event DeliveryConfirmed(address seller, uint256 id, uint256 amount);
    
    constructor(address[] memory _moderators, address _feeCollector) {
      for(uint256 i; i< _moderators.length; i++){
          moderators[_moderators[i]] = true;
      }
      
      feeCollector = _feeCollector;
    }
    
    /// @notice Updates taxes for buyer and seller
    /// @dev Total tax must be <= 20%
    function setEscrowTax(uint256 _buyerTax, uint256 _sellerTax) external onlyModerators{
        require(_buyerTax + _sellerTax <= 20, "Total tax must be <= 20");
        escrowTax.buyerTax = _buyerTax;
        escrowTax.sellerTax = _sellerTax;
    }
    
    /// @notice Starts a new escrow service
    /// @param _tx_id The id of the operation
    /// @param sellerAddress The address of the seller
    /// @param price The price of the service in BNB
    function startTrade(uint256 _tx_id, address sellerAddress, uint256 price) external payable{
        require(price > 0 && msg.value == (price * escrowTax.buyerTax / 100));
        require(buyerDatabase[msg.sender][_tx_id].seller == sellerAddress, "There is already a service with this data");
        uint256 _tax_amount = price * escrowTax.buyerTax / 100;
        buyerDatabase[msg.sender][_tx_id] = EscrowStruct(msg.sender, sellerAddress, price, _tax_amount, Status.PENDING);
    }
    
    /// @notice Refunds the buyer. Only moderators or seller can call this
    /// @param buyerAddress The address of the buyer to refund
    /// @param _tx_id The id of the order
    function refundBuyer(address buyerAddress, uint256 _tx_id) external {
        require(msg.sender == buyerDatabase[buyerAddress][_tx_id].seller || moderators[msg.sender], "Only seller or moderator can refund");
        require(buyerDatabase[buyerAddress][_tx_id].status == Status.PENDING);
        require(buyerAddress == buyerDatabase[buyerAddress][_tx_id].buyer);
        uint256 amountToRefund = buyerDatabase[buyerAddress][_tx_id].amount + buyerDatabase[buyerAddress][_tx_id].tax_amount;
        buyerDatabase[buyerAddress][_tx_id].status = Status.REFUNDED;
        payable(buyerAddress).transfer(amountToRefund);
        emit RefundEmitted(buyerAddress, _tx_id, amountToRefund);
    }
    
    /// @notice Resolve the dispute in favor of the seller
    /// @param buyerAddress The address of the buyer of the order
    /// @param _tx_id The id of the order
    function resolveToSeller(address buyerAddress, uint256 _tx_id) external onlyModerators{
        require(buyerDatabase[buyerAddress][_tx_id].status == Status.PENDING);
        uint256 amountToRelease = buyerDatabase[buyerAddress][_tx_id].amount * escrowTax.sellerTax / 100;
        buyerDatabase[buyerAddress][_tx_id].status = Status.COMPLETED;
        address sellerAdd = buyerDatabase[buyerAddress][_tx_id].seller;
        payable(sellerAdd).transfer(amountToRelease);
        emit ResolvedToSeller(sellerAdd, _tx_id, amountToRelease);
    }
    
    /// @notice Confirm the delivery and forward funds to seller
    /// @param buyerAddress The address of the buyer
    /// @param _tx_id The id of the order
    function confirmDelivery(address buyerAddress, uint256 _tx_id) external{
        require(msg.sender == buyerDatabase[buyerAddress][_tx_id].buyer, "Only buyer can confirm delivery");
        require(buyerDatabase[buyerAddress][_tx_id].status == Status.PENDING);
        buyerDatabase[buyerAddress][_tx_id].status = Status.COMPLETED;
        uint256 amountToRelease = buyerDatabase[buyerAddress][_tx_id].amount * escrowTax.sellerTax / 100;
        address sellerAdd = buyerDatabase[buyerAddress][_tx_id].seller;
        payable(sellerAdd).transfer(amountToRelease);
        emit DeliveryConfirmed(sellerAdd, _tx_id, amountToRelease);
    }
    
    /// @notice Collects fees and forward to feeCollector
    function collectFees(uint256 amount) internal{
        require(amount > 0);
        payable(feeCollector).transfer(amount);
    }

}