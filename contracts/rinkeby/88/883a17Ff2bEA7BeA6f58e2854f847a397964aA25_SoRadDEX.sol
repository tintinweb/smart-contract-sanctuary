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

pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SoRadDEX {
    string public purpose = "Swapping SRTs";
    IERC20 srts;

    constructor(address tokenAddress) public {
        srts = IERC20(tokenAddress);
    }

    uint256 public totalLiquidity;

    mapping(address => uint256) public liquidity;

    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX:init - already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(srts.transferFrom(msg.sender, address(this), tokens));
        return totalLiquidity;
    }

    function price(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public pure returns (uint256) {
        uint256 input_amount_with_fee = input_amount * 997;
        uint256 numerator = input_amount_with_fee * output_reserve;
        uint256 denominator = input_reserve * 1000 + input_amount_with_fee;
        return numerator / denominator;
    }

    function ethToToken() public payable returns (uint256) {
        uint256 token_reserve = srts.balanceOf(address(this));
        uint256 tokens_bought = price(
            msg.value,
            address(this).balance - msg.value,
            token_reserve
        );
        require(srts.transfer(msg.sender, tokens_bought));
        return tokens_bought;
    }

    function tokenToEth(uint256 tokens) public returns (uint256) {
        uint256 token_reserve = srts.balanceOf(address(this));
        uint256 eth_bought = price(
            tokens,
            token_reserve,
            address(this).balance
        );
        payable(msg.sender).transfer(eth_bought);
        require(srts.transferFrom(msg.sender, address(this), tokens));
        return eth_bought;
    }

    function deposit() public payable returns (uint256) {
        uint256 eth_reserve = address(this).balance - msg.value;
        uint256 token_reserve = srts.balanceOf(address(this));
        uint256 token_amount = ((msg.value * token_reserve) / eth_reserve) + 1;
        uint256 liquidity_minted = (msg.value * totalLiquidity) / eth_reserve;
        liquidity[msg.sender] = liquidity[msg.sender] + liquidity_minted;
        totalLiquidity = totalLiquidity + liquidity_minted;
        require(srts.transferFrom(msg.sender, address(this), token_amount));
        return liquidity_minted;
    }

    function withdraw(uint256 liq_amount) public returns (uint256, uint256) {
        uint256 token_reserve = srts.balanceOf(address(this));
        uint256 eth_amount = (liq_amount * address(this).balance) /
            totalLiquidity;
        uint256 token_amount = (liq_amount * token_reserve) / totalLiquidity;
        liquidity[msg.sender] -= liq_amount;
        totalLiquidity -= liq_amount;
        (bool sent, ) = msg.sender.call{value: eth_amount}("");
        require(srts.transfer(msg.sender, token_amount));
        return (eth_amount, token_amount);
    }
}