/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// Part: IERC20

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

// File: MockAdapter.sol

contract MockAdapter {
    mapping(address => uint256) private prices;
    address public WETH;

    constructor(address[] memory _tokens, uint256[] memory _prices) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            prices[_tokens[i]] = _prices[i];
        }
    }

    receive() external payable {}

    function swapETHToUnderlying(address underlying, uint256 underlyingAmount) external payable {
        IERC20(underlying).transfer(msg.sender, (msg.value * 10**18) / prices[underlying]);
    }

    function getTokensPrices(address[] memory _tokens) external view returns (uint256[] memory) {
        uint256[] memory _prices = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            _prices[i] = prices[_tokens[i]];
        }
        return _prices;
    }

    function swapUnderlyingsToETH(uint256[] memory underlyingAmounts, address[] memory underlyings) external virtual {
        uint256 ethAmount = 0;
        for (uint256 i = 0; i < underlyings.length; i++) {
            IERC20(underlyings[i]).transferFrom(msg.sender, address(this), underlyingAmounts[i]);
            ethAmount += (underlyingAmounts[i] * prices[underlyings[i]]) / 10**18;
        }
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "Failed");
    }

    function getEthPrice() external pure returns (uint256) {
        return 2000 * 10**6;
    }

    function getDHVPrice(address _dhvToken) external pure returns (uint256) {
        _dhvToken;
        return 3 * 10**14;
    }

    function getUnderlyingAmount(
        uint256 eth,
        address from,
        address to
    ) external view returns (uint256) {
        from;
        return from == WETH ? (eth * 10**18) / prices[to] : (eth * 10**18) / prices[from];
    }

    function getEthAmountWithSlippage(uint256 _amount, address _tokenToSwap) external view returns (uint256) {
        return (_amount * prices[_tokenToSwap]) / 10**18;
    }

    function mockSetTokenPrice(address _token, uint256 _price) external {
        prices[_token] = _price;
    }
}