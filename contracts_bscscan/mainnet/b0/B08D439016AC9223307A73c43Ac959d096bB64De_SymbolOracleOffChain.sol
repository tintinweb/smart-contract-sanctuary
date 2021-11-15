// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IOracleWithUpdate.sol';

contract SymbolOracleOffChain is IOracleWithUpdate {

    string  public symbol;
    address public immutable signatory;
    uint256 public immutable delayAllowance;

    uint256 public timestamp;
    uint256 public price;

    constructor (string memory symbol_, address signatory_, uint256 delayAllowance_) {
        symbol = symbol_;
        signatory = signatory_;
        delayAllowance = delayAllowance_;
    }

    function getPrice() external override view returns (uint256) {
        require(block.timestamp - timestamp <= delayAllowance, 'price expired');
        return price;
    }

    // update oracle price using off chain signed price
    // the signature must be verified in order for the price to be updated
    function updatePrice(uint256 timestamp_, uint256 price_, uint8 v_, bytes32 r_, bytes32 s_) external override {
        uint256 lastTimestamp = timestamp;
        if (timestamp_ > lastTimestamp) {
            if (v_ == 27 || v_ == 28) {
                bytes32 message = keccak256(abi.encodePacked(symbol, timestamp_, price_));
                bytes32 hash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', message));
                address signer = ecrecover(hash, v_, r_, s_);
                if (signer == signatory) {
                    timestamp = timestamp_;
                    price = price_;
                }
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOracleWithUpdate {

    function getPrice() external returns (uint256);

    function updatePrice(uint256 timestamp, uint256 price, uint8 v, bytes32 r, bytes32 s) external;

}

