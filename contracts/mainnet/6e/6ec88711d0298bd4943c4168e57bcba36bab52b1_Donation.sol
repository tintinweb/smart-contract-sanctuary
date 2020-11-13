// Sources flattened with buidler v1.4.7 https://buidler.dev

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v3.2.0

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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


// File contracts/Donationburn.sol

pragma solidity ^0.6.0;


contract Donation {
    IERC20 public Token;
    uint256 public start;
    uint256 public finish;
    address payable public ad1;
    address payable public ad2;
    address payable public ad3;
    address payable public ad4;

    constructor(
        IERC20 Tokent,
        address payable a1,
        address payable a2,
        address payable a3,
        address payable a4
    ) public {
        Token = Tokent;
        start = now;
        finish = now + 100 days;
        ad1 = a1;
        ad2 = a2;
        ad3 = a3;
        ad4 = a4;
    }

    receive() external payable {
        Token.transfer(
            msg.sender,
            (msg.value * 10 * (finish - start)) /
                ((finish - start) - (now - start))
        );
    }

    uint256 public bal;

    function donate() public {
        bal = address(this).balance;
        _transfer(ad1, bal / 4);
        _transfer(ad2, bal / 4);
        _transfer(ad3, bal / 4);
        _transfer(ad4, bal / 4);
    }

    function _transfer(address payable to, uint256 amount) internal {
      (bool success,) = to.call{value: amount}("");
      require(success, "Donation: Error transferring ether.");
    }
}