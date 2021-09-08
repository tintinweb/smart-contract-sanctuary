// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IOracleWithUpdate.sol';

contract SymbolOracleOffChain is IOracleWithUpdate {

    string  public symbol;
    address public immutable signatory;
    //uint256 public immutable delayAllowance;

    uint256 public timestamp;
    uint256 public price;

    constructor (string memory symbol_, address signatory_) {
        symbol = symbol_;
        signatory = signatory_;
        //delayAllowance = delayAllowance_;
    }

    function getPrice() external override view returns (uint256) {
        //require(block.timestamp - timestamp <= delayAllowance, 'price expired');
        return price;
    }

    // update oracle price using off chain signed price
    // the signature must be verified in order for the price to be updated
    function updatePrice(uint256 timestamp_, uint256 price_, uint8 v_, bytes32 r_, bytes32 s_) external override {
        require(msg.sender == signatory, 'only signatory');
        uint256 lastTimestamp = timestamp;
        if (timestamp_ > lastTimestamp) {
            timestamp = timestamp_;
            price = price_;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOracleWithUpdate {

    function getPrice() external returns (uint256);

    function updatePrice(uint256 timestamp, uint256 price, uint8 v, bytes32 r, bytes32 s) external;

}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}