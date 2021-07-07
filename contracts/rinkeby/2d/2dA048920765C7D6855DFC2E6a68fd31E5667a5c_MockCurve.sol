// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface ICurve {
    function minSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function minCeiling() external view returns (uint256);

    function maxCeiling() external view returns (uint256);

    function calcCeiling(uint256 _supply) external view returns (uint256);
}

abstract contract Curve is ICurve {
    /* ========== EVENTS ========== */

    event MinSupplyChanged(
        address indexed operator,
        uint256 _old,
        uint256 _new
    );

    event MaxSupplyChanged(
        address indexed operator,
        uint256 _old,
        uint256 _new
    );

    event MinCeilingChanged(
        address indexed operator,
        uint256 _old,
        uint256 _new
    );

    event MaxCeilingChanged(
        address indexed operator,
        uint256 _old,
        uint256 _new
    );

    /* ========== STATE VARIABLES ========== */

    uint256 public override minSupply;
    uint256 public override maxSupply;

    uint256 public override minCeiling;
    uint256 public override maxCeiling;

    /* ========== GOVERNANCE ========== */

    function setMinSupply(uint256 _newMinSupply) public virtual {
        uint256 oldMinSupply = minSupply;
        minSupply = _newMinSupply;
        emit MinSupplyChanged(msg.sender, oldMinSupply, _newMinSupply);
    }

    function setMaxSupply(uint256 _newMaxSupply) public virtual {
        uint256 oldMaxSupply = maxSupply;
        maxSupply = _newMaxSupply;
        emit MaxSupplyChanged(msg.sender, oldMaxSupply, _newMaxSupply);
    }

    function setMinCeiling(uint256 _newMinCeiling) public virtual {
        uint256 oldMinCeiling = _newMinCeiling;
        minCeiling = _newMinCeiling;
        emit MinCeilingChanged(msg.sender, oldMinCeiling, _newMinCeiling);
    }

    function setMaxCeiling(uint256 _newMaxCeiling) public virtual {
        uint256 oldMaxCeiling = _newMaxCeiling;
        maxCeiling = _newMaxCeiling;
        emit MaxCeilingChanged(msg.sender, oldMaxCeiling, _newMaxCeiling);
    }

    function calcCeiling(uint256 _supply)
        external
        view
        virtual
        override
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import {Curve} from '../curve/Curve.sol';

contract MockCurve is Curve {
    uint256 public ceiling;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _ceiling,
        uint256 _minSupply,
        uint256 _maxSupply,
        uint256 _minCeiling,
        uint256 _maxCeiling
    ) {
        ceiling = _ceiling;
        minSupply = _minSupply;
        maxSupply = _maxSupply;
        minCeiling = _minCeiling;
        maxCeiling = _maxCeiling;
    }

    function setCeiling(uint256 _ceiling) public {
        ceiling = _ceiling;
    }

    function calcCeiling(uint256) external view override returns (uint256) {
        return ceiling;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}