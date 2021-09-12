// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "../interfaces/IAMMCore.sol";
import "../types/TokenData.sol";

/// @title AMMRouter
/// @author devtooligan.eth
/// @notice Simple Automated Market Maker - Router contract. An excercise for the Yield mentorship program
/// @dev Uses AMMCore
contract AMMRouter {
    IAMMCore public core;
    address public owner;

    constructor(IAMMCore _core) {
        owner = msg.sender;
        core = _core;
    }

    // @notice Use this function to add liquidity in the correct ratio, receive LP tokens
    // @param wadX The amount of tokenX to add
    // @param wadY The amount of tokenY to add
    function mint(uint256 wadX, uint256 wadY) external {
        require(wadX > 0 && wadY > 0, "Invalid amounts");
        TokenData memory x = core.getX();
        TokenData memory y = core.getY();
        require(x.reserve > 0 && y.reserve > 0, "Not initialized");
        require((x.reserve / y.reserve) * 1e18 == (wadX / wadY) * 1e18, "Invalid amounts");

        x.token.transferFrom(msg.sender, address(core), wadX);
        y.token.transferFrom(msg.sender, address(core), wadY);
        core.mintLP(msg.sender);
    }

    // @notice Use this function to remove liquidity and get back tokens
    // @param wad The amount of LP tokens to burn
    function burn(uint256 wad) external {
        require(wad > 0, "Invalid amount");
        require(core.balanceOf(msg.sender) >= wad, "Insufficent balance");
        core.burnLP(msg.sender, wad);
    }

    // @notice Use this function to sell an exact amount of tokenX for the going rate of tokenY
    // @param wad The amount of tokenX to sell
    function sellX(uint256 wad) external {
        require(wad > 0, "Invalid amount");
        TokenData memory x = core.getX();
        x.token.transferFrom(msg.sender, address(core), wad);
        core.swapX(msg.sender);
    }

    // @notice Use this function to sell an exact amount of tokenY for the going rate of tokenX
    // @param wad The amount of tokenY to sell
    function sellY(uint256 wad) external {
        require(wad > 0, "Invalid amount");
        TokenData memory y = core.getY();
        y.token.transferFrom(msg.sender, address(core), wad);
        core.swapY(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "../types/TokenData.sol";

/**
 * @dev Interface for AMMCore
 */
interface IAMMCore is IERC20 {
    function getX() external view returns (TokenData memory);

    function getY() external view returns (TokenData memory);

    event Initialized(uint256 k);
    event Minted(address indexed guy, uint256 k);
    event Burned(address indexed guy, uint256 wad, uint256 xTokensToSend, uint256 yTokensToSend);
    event Swapped(address indexed guy, address indexed tokenIn, uint256 amountX, uint256 amountY);

    //@notice Initializes liquidity pools and k
    // @notice Use this function to initialize k and add liquidity
    // @dev Can only be used once
    // @param wadX The amount of tokenX to add
    // @param wadY The amount of tokenY to add
    function init(uint256 wadX, uint256 wadY) external;

    //@notice Initializes liquidity pools / k ratio
    //@param admin - who will get the initial lp's
    //@dev This should be called by the router contract
    function mintLP(address guy) external;

    //@notice Used to burn Lp's and get out original tokens
    //@param admin - who will get the initial lp's
    //@dev This should be called by the router contract
    function burnLP(address guy, uint256 wad) external;

    //@notice Used to sell a fixed amount of tokenX for a computed amount of Y
    //@notice This assumes the transfer in of tokenX has already occurred
    //@param address - The address of the seller / where to send the Y tokens
    //@dev This should be called by the router contract
    function swapX(address guy) external;

    //@notice Used to sell a fixed amount of tokenY for a computed amount of X
    //@notice This assumes the transfer in of tokenY has already occurred
    //@param address - The address of the seller / where to send the X tokens
    //@dev This should be called by the router contract
    function swapY(address guy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

struct TokenData {
    IERC20 token;
    uint256 reserve;
}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000
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