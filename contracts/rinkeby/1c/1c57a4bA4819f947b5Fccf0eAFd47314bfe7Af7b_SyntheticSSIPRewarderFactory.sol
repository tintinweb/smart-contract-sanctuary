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
import "./interfaces/ISyntheticSSIPRewarder.sol";
import "./libraries/TransferHelper.sol";

contract SyntheticSSIPRewarder is ISyntheticSSIPRewarder {
    address public immutable SSIP;
    address public immutable override currency;

    constructor(address _SSIP, address _currency) {
        currency = _currency;
        SSIP = _SSIP;
    }

    receive() external payable {}

    function onReward(address _to, uint256 _amount) external payable override onlySSIP returns (uint256) {
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

    modifier onlySSIP() {
        require(msg.sender == SSIP, "Only SSIP can call this function.");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "../SyntheticSSIPRewarder.sol";

contract SyntheticSSIPRewarderFactory {
    address public owner;
    address public lastNewRewarder;
    address[] public rewarderList;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UnoRe: Forbidden");
        _;
    }

    function newSyntheticRewarder(address _ssip, address _currency) external onlyOwner returns (address) {
        SyntheticSSIPRewarder _rewarder = new SyntheticSSIPRewarder(_ssip, _currency);
        address _rewarderAddr = address(_rewarder);
        lastNewRewarder = _rewarderAddr;
        rewarderList.push(_rewarderAddr);

        return _rewarderAddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface ISyntheticSSIPRewarder {
    function currency() external view returns (address);

    function onReward(address _to, uint256 _amount) external payable returns (uint256);
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