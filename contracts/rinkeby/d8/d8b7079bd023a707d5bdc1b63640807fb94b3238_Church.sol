/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity 0.4.24;

contract Church{
    
    /// allow direct transfers to Contract    
    function () public payable {
    }
    
    address public priest;
    address[] public donators;
    
    constructor () public {
        priest = msg.sender; }
    
    /// regiester real donators 
    function gatherDonation() public payable {
        require(msg.value >= .001 ether);
        donators.push(msg.sender); }
    
    /// only priest has restricted access
    modifier St() {
        require(msg.sender == priest);
        _;
    }
    
    function getDonator() public view returns (address[]) {
        return donators;
    }
}