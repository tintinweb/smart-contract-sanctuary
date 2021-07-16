/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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

interface IDexAdapter {
    function swapETHToUnderlying(address underlying) external payable;

    function swapUndelyingsToETH(uint256[] memory underlyingAmounts, address[] memory underlyings) external;

    function swapTokenToToken(
        uint256 _amountToSwap,
        address _tokenToSwap,
        address _tokenToReceive
    ) external returns (uint256);

    function getUnderlyingAmount(
        uint256 _amount,
        address _tokenToSwap,
        address _tokenToReceive
    ) external view returns (uint256);

    function getPath(address _tokenToSwap, address _tokenToReceive) external view returns (address[] memory);

    function getTokensPrices(address[] memory _tokens) external view returns (uint256[] memory);

    function getEthPrice() external view returns (uint256);

    function getDHVPrice(address _dhvToken) external view returns (uint256);
}

contract MockAdapter is IDexAdapter {
    mapping(address => uint256) private prices;

    constructor(address[] memory _tokens, uint256[] memory _prices) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            prices[_tokens[i]] = _prices[i];
        }
    }

    receive() external payable {}

    function swapUndelyingsToETH(uint256[] memory underlyingAmounts, address[] memory underlyings) external override {
        uint256 ethValue;
        for (uint256 i = 0; i < underlyings.length; i++) {
            ethValue += (underlyingAmounts[i] * prices[underlyings[i]]) / (2000 * 10**6);
            IERC20(underlyings[i]).transferFrom(msg.sender, address(this), underlyingAmounts[i]);
        }
        (bool sent, ) = msg.sender.call{value: ethValue + 10 * 10**18}("");
        require(sent, "ETH transfer failed");
    }

    function swapETHToUnderlying(address underlying) external payable override {
        uint256 underlyingAmount = (msg.value * (2000 * 10**6) ) / prices[underlying];

        IERC20(underlying).transfer(msg.sender, underlyingAmount);
    }

    function swapTokenToToken(
        uint256 _amountToSwap,
        address _tokenToSwap,
        address _tokenToReceive
    ) external override returns (uint256) {
        return 0;
    }

    function getTokensPrices(address[] memory _tokens) external view override returns (uint256[] memory) {
        uint256[] memory _prices = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            _prices[i] = prices[_tokens[i]];
        }
        return _prices;
    }

    function getEthPrice() external pure override returns (uint256) {
        return 2000 * 10**6;
    }

    function getDHVPrice(address _dhvToken) external pure override returns (uint256) {
        _dhvToken;
        return 10**18;
    }

    function getUnderlyingAmount(
        uint256 eth,
        address from,
        address to
    ) external view override returns (uint256) {
        from;
        return (eth * 2000 * 10**6) / prices[to];
    }

    function getPath(address _tokenToSwap, address _tokenToReceive) external view override returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _tokenToSwap;
        path[1] = _tokenToReceive;
    }
}