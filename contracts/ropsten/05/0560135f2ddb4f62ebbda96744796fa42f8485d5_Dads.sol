/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity ^0.8.0;

contract Dads {
    bool public publicSaleStarted = false;
    uint256 public constant PRICE = 0.07 ether;
    
    function togglePublicSaleStarted() external {
        publicSaleStarted = !publicSaleStarted;
    }
    
    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started");
        _;
    }
    
    function mint(uint256 amountOfDads) external payable whenPublicSaleStarted {
        require(PRICE * amountOfDads == msg.value, "ETH amount is incorrect");
    }
}