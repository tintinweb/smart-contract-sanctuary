/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract PreSale {
    bool public finished;
    uint256 totalBought;
    address public collector;
    
    mapping (address => uint256) bought;
    mapping (address => bool) allowlist;
    
    event Received(address indexed _sender, uint256 _value);
    
    constructor(address _collector) {
        collector = _collector;
    }
    
    function buy() external payable {
        require(!finished, "PreSale#receive: PRESALE_FINISHED");
        require(allowlist[msg.sender], "PreSale#receive: USER_NOT_ALLOWED");
        require(totalBought + msg.value <= 8 ether, "PreSale#receive: PRESALE_EXHAUSTED");
        require(bought[msg.sender] + msg.value <= 0.5 ether, "Presale#receive: CANT_BOUGHT_MORE_THAN_0.5BNB");
        
        totalBought += msg.value;
        bought[msg.sender] += msg.value;
        
        payable(collector).transfer(msg.value);
        emit Received(msg.sender, msg.value);
    }
    
    
    function allowAddresses(address[] calldata _addresses) external {
        require(msg.sender == collector, "PreSale#finish: INVALID_USER");
        
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowlist[_addresses[i]] = true;
        }
    }
    
    function finish()  external {
        require(msg.sender == collector, "PreSale#finish: INVALID_USER");
        finished = true;
    }
}