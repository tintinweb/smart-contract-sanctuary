pragma solidity ^0.8.4;

import "./token/BEP20/IBEP20.sol";

contract MockApeSwapRouter {

    uint totalStakedAmount = 0;
    address public banana;
    address public mainst;

    // Info of each user.
    struct DepositInfo {
        uint256 amount;
    }

    mapping (address => DepositInfo) public depositInfo;


    modifier validatePool(uint256 _pid) {
        require(_pid == 0, "validatePool: pool exists?");
        _;
    }

    constructor (address _banana, address _mainstreet) {
        banana = _banana;
        mainst = _mainstreet;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ApeRouter: EXPIRED');
        _;
    }

    function getAmountsOut(uint amountIn, address[] memory path)
    public
    view
    returns (uint[] memory amounts)
    {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10000000000000;
        amounts[1] = 1000000000000000000;
        return amounts;
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        IBEP20(banana).transfer(to, 100000000000000000000);
        uint[] memory balance = new uint[](2);
        balance[0] = 10000000000000;
        balance[1] = 100000000000000000000;
        return balance;
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        IBEP20(banana).transferFrom(msg.sender, address(this), amountIn);
        payable(msg.sender).transfer(10000000000000000);
        uint[] memory balance = new uint[](2);
        balance[0] = 10000000000000;
        balance[1] = 1000000000000;
        return balance;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        IBEP20(banana).transferFrom(msg.sender, address(this), 1000000000000000000);
        IBEP20(mainst).transfer(msg.sender, 10000000000000000000);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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