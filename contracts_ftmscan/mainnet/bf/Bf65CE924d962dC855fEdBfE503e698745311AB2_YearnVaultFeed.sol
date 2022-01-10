// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./interfaces/IChainlinkFeed.sol";
import "./interfaces/IYearnVaultToken.sol";
import "./ERC20/IERC20.sol";

contract YearnVaultFeed is IChainlinkFeed {
    IYearnVaultToken public vaultToken;
    IChainlinkFeed public underlyingFeed;

    constructor(IYearnVaultToken _vaultToken, IChainlinkFeed _underlyingFeed) {
        vaultToken = _vaultToken;
        underlyingFeed = _underlyingFeed;
    }

    function decimals() public view returns (uint8) {
        return underlyingFeed.decimals();
    }

    function latestAnswer() external view returns (int256 answer) {
        uint256 underlyingLatestAnswer = uint256(underlyingFeed.latestAnswer());
        uint256 pricePerShare = vaultToken.pricePerShare();
        answer = int256(underlyingLatestAnswer * pricePerShare / 10**(vaultToken.decimals()));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IChainlinkFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IYearnVaultToken {
    function decimals() external view returns (uint256);
    function pricePerShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}