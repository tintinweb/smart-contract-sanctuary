// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./rebase/Staking.sol";
import "./router/IRouter.sol";

contract TokenRepository {

    address private immutable _owner;

    struct TokenInfo {
        Staking staking;
        IERC20 stakingToken;
        IRouter router;
        address[] swapPath;
    }

    mapping (address => bool) private _isRegisteredToken;
    mapping (address => TokenInfo) private _info;

    constructor() {
        _owner = msg.sender;
    }

    function registerToken(
        address token,
        address staking_,
        address stakingToken_,
        address router_,
        address[] memory swapPath
    ) external onlyOwner {
        TokenInfo memory info;
        info.staking = Staking(staking_);
        info.stakingToken = IERC20(stakingToken_);
        info.router = IRouter(router_);
        info.swapPath = swapPath;
        _info[token] = info;
        _isRegisteredToken[token] = true;
    }

    function isRegisteredToken(address token) external view returns (bool) {
        return _isRegisteredToken[token];
    }

    function getTokenInfo(address token)
        external
        view
        onlyRegisteredToken(token)
        returns (TokenInfo memory)
    {
        return _info[token];
    }

    function staking(address token)
        external
        view
        onlyRegisteredToken(token)
        returns (Staking)
    {
        return _info[token].staking;
    }

    function stakingToken(address token)
        external
        view
        onlyRegisteredToken(token)
        returns (IERC20)
    {
        return _info[token].stakingToken;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not the owner");
        _;
    }

    modifier onlyRegisteredToken(address token) {
        require(_isRegisteredToken[token], "unknown token");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

abstract contract Staking {

    struct Epoch {
        uint length;
        uint number;
        uint endBlock;
        uint distribute;
    }
    Epoch public epoch;

    function stake(uint amount, address recipient) external virtual returns (bool);
    function claim(address recipient) public virtual;
    function rebase() public virtual;
    function unstake(uint amount, bool trigger) external virtual;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IRouter {

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}