pragma solidity 0.8.10;

import "./Utils.sol";

contract PedersenBase {
    using Utils for uint256;
    using Utils for Utils.Point;

    Utils.Point[M << 1] public gs;
    Utils.Point[M << 1] public hs;
    // have to use storage, not immutable, because solidity doesn't support non-primitive immutable types

    constructor() {
        for (uint256 i = 0; i < M << 1; i++) {
            gs[i] = Utils.mapInto("g", i);
            hs[i] = Utils.mapInto("h", i);
        }
    }
}