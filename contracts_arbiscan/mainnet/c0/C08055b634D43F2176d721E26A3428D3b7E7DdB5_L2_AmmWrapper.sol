// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";

interface ISwap {
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);
}

interface IL2_Bridge {
    function send(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline
    ) external;
}

contract L2_AmmWrapper {

    IL2_Bridge public immutable bridge;
    IERC20 public immutable l2CanonicalToken;
    bool public immutable l2CanonicalTokenIsEth;
    IERC20 public immutable hToken;
    ISwap public immutable exchangeAddress;

    /// @notice When l2CanonicalTokenIsEth is true, l2CanonicalToken should be set to the WETH address
    constructor(
        IL2_Bridge _bridge,
        IERC20 _l2CanonicalToken,
        bool _l2CanonicalTokenIsEth,
        IERC20 _hToken,
        ISwap _exchangeAddress
    )
        public
    {
        bridge = _bridge;
        l2CanonicalToken = _l2CanonicalToken;
        l2CanonicalTokenIsEth = _l2CanonicalTokenIsEth;
        hToken = _hToken;
        exchangeAddress = _exchangeAddress;
    }

    receive() external payable {}

    /// @notice amount is the amount the user wants to send plus the Bonder fee
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    )
        public
        payable
    {
        require(amount >= bonderFee, "L2_AMM_W: Bonder fee cannot exceed amount");

        if (l2CanonicalTokenIsEth) {
            require(msg.value == amount, "L2_AMM_W: Value does not match amount");
            IWETH(address(l2CanonicalToken)).deposit{value: amount}();
        } else {
            require(l2CanonicalToken.transferFrom(msg.sender, address(this), amount), "L2_AMM_W: TransferFrom failed");
        }

        require(l2CanonicalToken.approve(address(exchangeAddress), amount), "L2_AMM_W: Approve failed");
        uint256 swapAmount = exchangeAddress.swap(
            0,
            1,
            amount,
            amountOutMin,
            deadline
        );

        bridge.send(chainId, recipient, swapAmount, bonderFee, destinationAmountOutMin, destinationDeadline);
    }

    function attemptSwap(
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline
    )
        external
    {
        require(hToken.transferFrom(msg.sender, address(this), amount), "L2_AMM_W: TransferFrom failed");
        require(hToken.approve(address(exchangeAddress), amount), "L2_AMM_W: Approve failed");

        uint256 amountOut = 0;
        try exchangeAddress.swap(
            1,
            0,
            amount,
            amountOutMin,
            deadline
        ) returns (uint256 _amountOut) {
            amountOut = _amountOut;
        } catch {}

        if (amountOut == 0) {
            // Transfer hToken to recipient if swap fails
            require(hToken.transfer(recipient, amount), "L2_AMM_W: Transfer failed");
            return;
        }

        if (l2CanonicalTokenIsEth) {
            IWETH(address(l2CanonicalToken)).withdraw(amountOut);
            (bool success, ) = recipient.call{value: amountOut}(new bytes(0));
            require(success, 'L2_AMM_W: ETH transfer failed');
        } else {
            require(l2CanonicalToken.transfer(recipient, amountOut), "L2_AMM_W: Transfer failed");
        }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <=0.7.6;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}