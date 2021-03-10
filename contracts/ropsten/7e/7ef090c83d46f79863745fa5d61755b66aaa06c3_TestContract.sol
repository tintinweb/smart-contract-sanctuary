/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract TestContract {

    uint256 public SALE_START_TIMESTAMP;
    
    constructor (uint256 _SALE_START_TIMESTAMP) public {
        SALE_START_TIMESTAMP = _SALE_START_TIMESTAMP;
    }
    
    function setSALE_START_TIMESTAMP(uint256 _SALE_START_TIMESTAMP) public {
        require(_SALE_START_TIMESTAMP > 0);
        SALE_START_TIMESTAMP = _SALE_START_TIMESTAMP;
    }
    
    function getSALE_START_TIMESTAMP() public view returns (uint256) {
        return SALE_START_TIMESTAMP;
    }
    
    function mintAPixl(uint256 numberOfPixls) public payable {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Not yet opened");
    }
}