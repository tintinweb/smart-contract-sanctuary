// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @title RockX payment contract
 */
contract Payment is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using Address for address payable;
    using SafeMath for uint256;

    // a mapping to track the payment token we accept
    mapping (address => bool) private _paymentTokens;

    modifier checkPaymentToken(address token) {
        require(_paymentTokens[token], "unsupported payment currency");
        _;
    }

     /**
     * ======================================================================================
     *
     * SYSTEM FUNCTIONS
     *
     * ======================================================================================
     */
    
    /**
     * @notice enable a token to allow payment
     */
    function enablePayment(address token) onlyOwner external {
        require(token!=address(0));
        require(!_paymentTokens[token], "already enabled");

        _paymentTokens[token] = true;

        // log
        emit PaymentEnabled(token);
    }

    /**
     * @notice disable a token to allow payment
     */
    function disablePayment(address token) onlyOwner external {
        require(_paymentTokens[token], "already disabled");

        delete _paymentTokens[token];

        // log
        emit PaymentDisabled(token);
    }

    /**
     * ======================================================================================
     *
     * PAYMENT FUNCTIONS
     *
     * ======================================================================================
     */
    function deposit(uint256 userid, address token, uint256 amount) payable checkPaymentToken(token) external {

        // log
        emit Deposit(msg.sender, userid, token, amount);
    }
    
    /**
     * ======================================================================================
     *
     * VIEW FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */
    event Deposit(address from, uint256 userid, address token, uint256 amount);
    event PaymentEnabled(address token);
    event PaymentDisabled(address token);
}