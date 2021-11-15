pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CreatorFund {
    mapping(address => uint256) public funds;

    IERC20 public paymentToken;

    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
    }

    function fundOf(address _creator) external view returns (uint256) {
        return funds[_creator];
    }

    function receiveFund(address _creator, uint256 _amount)
        external
        returns (bool)
    {
        bool transferred =
            paymentToken.transferFrom(msg.sender, address(this), _amount);
        if (transferred) {
            funds[_creator] += _amount;
        }
        return transferred;
    }

    function useFund(
        address _creator,
        address _to,
        uint256 _amount
    ) external returns (bool) {
        // Verifying balance of this creator fund should also be done in the front-end side to prevent spamming gas fee of astropenWallet.
        require(funds[_creator] >= _amount, "Fund is not enough");

        bool transferred = paymentToken.transfer(_to, _amount);
        if (transferred) {
            funds[_creator] -= _amount;
        }
        return transferred;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

