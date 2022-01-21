// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <=0.8.0;

import "./IPool.sol";

interface IERC1155Mintable {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

contract ERC1155Pool is IPool {
    IERC1155Mintable public token;
    address public tube;

    modifier onlyTube() {
        require(msg.sender == tube);
        _;
    }

    constructor(address newTube, IERC1155Mintable newToken) {
        token = newToken;
        tube = newTube;
    }

    function mint(
        address to,
        uint256 id,
        bytes memory data
    ) external override onlyTube {
        token.mint(to, id, 1, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <=0.8.0;

interface IPool {
    function mint(
        address to,
        uint256 id,
        bytes memory data
    ) external;
}