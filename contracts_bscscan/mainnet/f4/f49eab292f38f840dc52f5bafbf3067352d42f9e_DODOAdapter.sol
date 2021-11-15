// SPDX-License-Identifier: MIT

pragma solidity > 0.6.9;

import "../interfaces/ISwapAdapter.sol";

interface IDODOSwap {
    function sellBase(address to) external;
    function sellQuote(address to) external;
}

contract DODOAdapter is ISwapAdapter {
    function sellBase(address to, address pool, bytes memory) external override {
        IDODOSwap(pool).sellBase(to);
    }

    function sellQuote(address to, address pool, bytes memory) external override {
        IDODOSwap(pool).sellQuote(to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ISwapAdapter {

    function sellBase(address to, address pool, bytes memory data) external;

    function sellQuote(address to, address pool, bytes memory data) external;
}

