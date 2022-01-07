// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

import "./IEncoding.sol";

contract IdentityEncoder is IEncoding {
    function decode(bytes memory grid)
        external
        pure
        returns (string[][] memory)
    {
        return abi.decode(grid, (string[][]));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

interface IEncoding {
    function decode(bytes memory grid)
        external
        pure
        returns (string[][] memory);
}