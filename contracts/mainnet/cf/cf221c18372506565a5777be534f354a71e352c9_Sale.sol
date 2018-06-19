pragma solidity ^0.4.24;

contract Sale {
    address private owner80 = 0xf2b9DA535e8B8eF8aab29956823df7237f1863A3;
    address private owner20 = 0x29FD9956553b9Ce92e658662b2F73d95CF90A969;
    uint256 private ether80;
    uint256 private ether20;

    function Sale() public {

    }
    
    function() external payable {
        ether20 = (msg.value)/5;
        ether80 = (msg.value)-ether20;
        owner80.transfer(ether80);
        owner20.transfer(ether20);
    }
}