/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// File: FundMe.sol

contract FundMe {

    mapping(address => uint256) public addressToAmountFund;

    function fund() public payable {
        addressToAmountFund[msg.sender] += msg.value;
    }

//    function getVersion() public view returns (uint256){
//        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
//        return priceFeed.version();
//    }

}