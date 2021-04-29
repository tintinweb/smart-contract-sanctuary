/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.8.0;

contract Order {
    
    address payable buyer;
    address payable seller;
    address payable platform;
    address payable affiliate;
    uint8 platform_commission; // percent
    
    // constructor
    constructor(address payable _buyer, address payable _seller, address payable _platform, address payable _affiliate, uint8 _platform_commission) payable {
        buyer = _buyer;
        seller = _seller;
        platform = _platform;
        affiliate = _affiliate;
        platform_commission = _platform_commission;
    }
    
    // complete contract
    function acceptSale() external  {
        // allow only the buyer, seller or platform to complete the contract
        require(msg.sender == platform || msg.sender == buyer || msg.sender == seller);
        
        // platform commission
        if (platform_commission != 0) {
            uint256 platform_cut = (address(this).balance * platform_commission) / 100;
            
            // pay platform
            if (platform == affiliate) {
                platform.transfer(platform_cut); 
            }
            
            // pay affiliate & platform
            else {
                platform.transfer((platform_cut * 30 / 100));
                affiliate.transfer((platform_cut * 70 / 100));
            }
        }
        
        // pay remaining balance to the seller
        seller.transfer(address(this).balance);
    }
    
    // cancel contract
    function rejectSale() external {
        
        // allow only the buyer, seller or platform to cancel the contract
        require(msg.sender == platform || msg.sender == buyer || msg.sender == seller);
        
        // refund buyer
        buyer.transfer(address(this).balance);
    }
}