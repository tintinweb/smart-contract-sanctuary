/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: No license

pragma solidity ^0.8.9;

contract CrowdFunding {

    address public provider;
    uint256 public cap;
    uint256 public thresholdCap;
    uint256 public initialBlock;
    uint256 public timeToMarketBlocks;
    string public offerCode;
    mapping (address => uint256) public nonces;
    mapping (address => mapping (uint256 => uint256)) public orders;

    event OfferCreation (address indexed provider, string indexed offerCode);

    constructor (uint256 _cap,
                 uint256 _thresholdCap,
                 uint256 _timeToMarketBlocks,
                 string memory _offerCode) {
        provider = msg.sender;
        cap = _cap;
        thresholdCap = _thresholdCap;
        initialBlock = block.number;
        timeToMarketBlocks = _timeToMarketBlocks;
        offerCode = _offerCode;
        emit OfferCreation(msg.sender, offerCode);
    }

    function postOrder () external payable {
        require(msg.value + address(this).balance <= cap, 'Demand beyond cap');
        nonces[msg.sender] = nonces[msg.sender] + 1;
        orders[msg.sender][nonces[msg.sender]] = msg.value;
    }

}