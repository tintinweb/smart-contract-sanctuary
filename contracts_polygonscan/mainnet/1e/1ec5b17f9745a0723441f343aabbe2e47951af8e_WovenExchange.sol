//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./libraries/LibBytes.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IHopL1Bridge.sol";
import "./interfaces/IHopL2AmmWrapper.sol";

contract WovenExchange {
    using LibBytes for bytes;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MAX_INT_HEX =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    struct CurrencyAmount {
        address target;
        uint256 amount;
    }

    function swapAndSendToBridge(
        bytes calldata swapData,
        bytes calldata sendToBridgeData
    ) public payable {
        address self = address(this);
        // prettier-ignore
        require(
            this.swap.selector == swapData.readBytes4(0) &&
            (
                this.hopSendL1ToL2.selector == sendToBridgeData.readBytes4(0) ||
                this.hopSendL2ToOther.selector == sendToBridgeData.readBytes4(0)
            ),
            "calldata error"
        );

        {
            (bool success, bytes memory ret) = self.delegatecall(swapData);
            require(success, string(ret));
        }
        {
            (bool success, bytes memory ret) = self.call{value: self.balance}(
                sendToBridgeData
            );
            require(success, string(ret));
        }
    }

    function swap(
        CurrencyAmount calldata input,
        CurrencyAmount calldata output,
        address recipient,
        address allowanceTarget,
        address exchange,
        bytes calldata callData
    ) public payable {
        address sender = msg.sender;
        address self = address(this);

        if (input.target != ETH) {
            if (sender != self) {
                IERC20(input.target).transferFrom(sender, self, input.amount);
            }
            IERC20(input.target).approve(allowanceTarget, input.amount);
        }

        (bool success, bytes memory ret) = exchange.call{value: self.balance}(
            callData
        );
        require(success, string(ret));

        if (recipient != self && output.amount > 0) {
            if (self.balance > 0) {
                payable(recipient).transfer(self.balance);
            }
            if (output.target != ETH) {
                uint256 balance = IERC20(output.target).balanceOf(self);
                IERC20(output.target).transfer(recipient, balance);
            }
        }
    }

    function getAmount(CurrencyAmount calldata currency)
        private
        view
        returns (uint256)
    {
        uint256 amount = currency.amount;

        if (currency.target != ETH) {
            if (amount == MAX_INT_HEX) {
                amount = IERC20(currency.target).balanceOf(msg.sender);
            }
        } else {
            if (amount == MAX_INT_HEX) {
                amount = address(this).balance;
            }
        }

        return amount;
    }

    function hopSendL1ToL2(
        address bridge,
        CurrencyAmount calldata currency,
        uint256 destinationChainId,
        address recipient,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) public payable {
        address sender = msg.sender;
        address self = address(this);
        uint256 amount = getAmount(currency);

        if (currency.target != ETH) {
            if (sender != self) {
                IERC20(currency.target).transferFrom(sender, self, amount);
            }
            IERC20(currency.target).approve(bridge, amount);
        }

        IHopL1Bridge(bridge).sendToL2{value: self.balance}(
            destinationChainId,
            recipient,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );
    }

    function hopSendL2ToOther(
        address ammWrapper,
        CurrencyAmount calldata currency,
        uint256 destinationChainId,
        address recipient,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) public payable {
        address sender = msg.sender;
        address self = address(this);
        uint256 amount = getAmount(currency);

        if (currency.target != ETH) {
            if (sender != self) {
                IERC20(currency.target).transferFrom(sender, self, amount);
            }
            IERC20(currency.target).approve(ammWrapper, amount);
        }

        IHopL2AmmWrapper(ammWrapper).swapAndSend{value: self.balance}(
            destinationChainId,
            recipient,
            amount,
            bonderFee,
            amountOutMin,
            deadline,
            destinationAmountOutMin,
            destinationDeadline
        );
    }

    // solhint-disable no-empty-blocks

    receive() external payable virtual {}

    // solhint-enable no-empty-blocks
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibBytes {
    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index)
        internal
        pure
        returns (bytes4 result)
    {
        require(b.length >= index + 4, "InvalidByteOperation");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(
                result,
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }

        return result;
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
    function transfer(address recipient, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function approve(address spender, uint256 amount) external;

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
    ) external;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IHopL1Bridge {
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IHopL2AmmWrapper {
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;
}