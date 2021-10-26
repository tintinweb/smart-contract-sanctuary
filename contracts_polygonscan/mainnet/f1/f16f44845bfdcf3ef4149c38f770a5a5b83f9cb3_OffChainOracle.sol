/**
 *Submitted for verification at polygonscan.com on 2021-10-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract OffChainOracle {

    string  public symbol;
    address public signer;
    uint256 public delayAllowance;

    uint256 public timestamp;
    uint256 public price;

    address public owner;

    constructor (string memory symbol_, address signer_, uint256 delayAllowance_) {
        owner = msg.sender;
        symbol = symbol_;
        signer = signer_;
        delayAllowance = delayAllowance_;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner, 'only owner');
        owner = newOwner;
    }

    function setSigner(address newSigner) external {
        require(msg.sender == owner, 'only owner');
        signer = newSigner;
    }

    function setDelayAllowance(uint256 newDelayAllowance) external {
        require(msg.sender == owner, 'only owner');
        delayAllowance = newDelayAllowance;
    }

    function getPrice() external view returns (uint256) {
        require(block.timestamp - timestamp < delayAllowance, 'price expired');
        return price;
    }

    // update oracle price using off chain signed price
    // the signature must be verified in order for the price to be updated
    function updatePrice(uint256 timestamp_, uint256 price_, uint8 v_, bytes32 r_, bytes32 s_) external {
        uint256 lastTimestamp = timestamp;
        if (timestamp_ > lastTimestamp) {
            if (v_ == 27 || v_ == 28) {
                bytes32 message = keccak256(abi.encodePacked(symbol, timestamp_, price_));
                bytes32 hash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', message));
                address signatory = ecrecover(hash, v_, r_, s_);
                if (signatory == signer) {
                    timestamp = timestamp_;
                    price = price_;
                }
            }
        }
    }

}