pragma solidity ^0.6.0;

abstract contract Cat {
    struct Ilk {
        address flip;  // Liquidator
        uint256 chop;  // Liquidation Penalty   [ray]
        uint256 lump;  // Liquidation Quantity  [wad]
    }

    mapping (bytes32 => Ilk) public ilks;
}
