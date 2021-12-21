// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRewarder.sol";
import "./libraries/TransferHelper.sol";

contract Rewarder is IRewarder, ReentrancyGuard {
    address public immutable override currency;
    address public immutable pool;
    address public operator;

    event LogRewarderWithdraw(address indexed _rewarder, address _currency, address indexed _to, uint256 _amount);
    event LogTransferOwnerShip(address indexed _rewarder, address indexed _oldOperator, address indexed _newOperator);

    constructor(
        address _operator,
        address _currency,
        address _pool
    ) {
        currency = _currency;
        pool = _pool;
        operator = _operator;
    }

    function onReward(address _to, uint256 _amount) external payable override onlyPOOL returns (uint256) {
        require(_to != address(0), "UnoRe: zero address reward");
        if (currency == address(0)) {
            if (address(this).balance >= _amount) {
                TransferHelper.safeTransferETH(_to, _amount);
                return _amount;
            } else {
                if (address(this).balance > 0) {
                    TransferHelper.safeTransferETH(_to, address(this).balance);
                    return address(this).balance;
                } else {
                    return 0;
                }
            }
        } else {
            if (IERC20(currency).balanceOf(address(this)) >= _amount) {
                TransferHelper.safeTransfer(currency, _to, _amount);
                return _amount;
            } else {
                if (IERC20(currency).balanceOf(address(this)) > 0) {
                    TransferHelper.safeTransfer(currency, _to, IERC20(currency).balanceOf(address(this)));
                    return IERC20(currency).balanceOf(address(this));
                } else {
                    return 0;
                }
            }
        }
    }

    function withdraw(address _to, uint256 _amount) external onlyOperator nonReentrant {
        require(_to != address(0), "UnoRe: zero address reward");
        if (currency == address(0)) {
            if (address(this).balance >= _amount) {
                TransferHelper.safeTransferETH(_to, _amount);
                emit LogRewarderWithdraw(address(this), currency, _to, _amount);
            } else {
                if (address(this).balance > 0) {
                    TransferHelper.safeTransferETH(_to, address(this).balance);
                    emit LogRewarderWithdraw(address(this), currency, _to, address(this).balance);
                }
            }
        } else {
            if (IERC20(currency).balanceOf(address(this)) >= _amount) {
                TransferHelper.safeTransfer(currency, _to, _amount);
                emit LogRewarderWithdraw(address(this), currency, _to, _amount);
            } else {
                if (IERC20(currency).balanceOf(address(this)) > 0) {
                    TransferHelper.safeTransfer(currency, _to, IERC20(currency).balanceOf(address(this)));
                    emit LogRewarderWithdraw(address(this), currency, _to, IERC20(currency).balanceOf(address(this)));
                }
            }
        }
    }

    function transferOwnership(address _to) external onlyOperator nonReentrant {
        require(_to != address(0), "UnoRe: zero address reward");
        address oldOperator = operator;
        operator = _to;
        emit LogTransferOwnerShip(address(this), oldOperator, _to);
    }

    modifier onlyPOOL() {
        require(msg.sender == pool, "Only SSRP or SSIP contract can call this function.");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator call this function.");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "../Rewarder.sol";
import "../interfaces/IRewarderFactory.sol";

contract RewarderFactory is IRewarderFactory {
    constructor() {}

    function newRewarder(
        address _operator,
        address _currency,
        address _pool
    ) external override returns (address) {
        Rewarder _rewarder = new Rewarder(_operator, _currency, _pool);
        address _rewarderAddr = address(_rewarder);

        return _rewarderAddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IRewarder {
    function currency() external view returns (address);

    function onReward(address to, uint256 unoAmount) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRewarderFactory {
    function newRewarder(
        address _operator,
        address _currency,
        address _pool
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}