pragma solidity ^0.4.11;

contract DGDb_Auction{
    
    Badge public badge_obj;
    
    address public beneficiary;
    uint public expiry_date;
    
    address public highest_bidder;
    uint public highest_bid;
    mapping(address => uint) pending_returns;
    
    
    function DGDb_Auction(address beneficiary_address, address badge_address, uint duration_in_days){
        beneficiary = beneficiary_address;
        badge_obj = Badge(badge_address);
        expiry_date = now + duration_in_days * 1 days;
    }
    
    // This function is called every time someone sends ether to this contract
    function() payable {
        require(now < (expiry_date));
        require(msg.value > highest_bid);
        
        uint num_badges = badge_obj.balanceOf(this);
        require(num_badges > 0);
        
        if (highest_bidder != 0) {
            pending_returns[highest_bidder] += highest_bid;
        }
        
        highest_bidder = msg.sender;
        highest_bid = msg.value;
    }
    
    // Bidders that have been outbid can call this to retrieve their ETH
    function withdraw_ether() returns (bool) {
        uint amount = pending_returns[msg.sender];
        if (amount > 0) {
            pending_returns[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                pending_returns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    
    // For winner (or creator if no bids) to retrieve badge
    function withdraw_badge() {
        require(now >= (expiry_date));
        
        uint num_badges = badge_obj.balanceOf(this);
        
        if (highest_bid > 0){
            badge_obj.transfer(highest_bidder, num_badges);
        } else {
            badge_obj.transfer(beneficiary, num_badges);
        }
    }
    
    // For auction creator to retrieve ETH 1 day after auction ends
    function end_auction() {
        require(msg.sender == beneficiary);
        require(now > (expiry_date + 1 days));
        selfdestruct(beneficiary);
    }
}

contract Badge{
function Badge();
function approve(address _spender,uint256 _value)returns(bool success);
function setOwner(address _owner)returns(bool success);
function totalSupply()constant returns(uint256 );
function transferFrom(address _from,address _to,uint256 _value)returns(bool success);
function subtractSafely(uint256 a,uint256 b)returns(uint256 );
function mint(address _owner,uint256 _amount)returns(bool success);
function safeToAdd(uint256 a,uint256 b)returns(bool );
function balanceOf(address _owner)constant returns(uint256 balance);
function owner()constant returns(address );
function transfer(address _to,uint256 _value)returns(bool success);
function addSafely(uint256 a,uint256 b)returns(uint256 result);
function locked()constant returns(bool );
function allowance(address _owner,address _spender)constant returns(uint256 remaining);
function safeToSubtract(uint256 a,uint256 b)returns(bool );
}