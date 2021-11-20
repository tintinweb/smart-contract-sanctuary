// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Validator.sol";

contract AllValidator is IERC721Validator {
    function meetsCriteria(address, uint256)
        external
        pure
        override
        returns (bool)
    {
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Validator {
    function meetsCriteria(address tokenAddress, uint256 tokenId)
        external
        pure
        returns (bool);
}