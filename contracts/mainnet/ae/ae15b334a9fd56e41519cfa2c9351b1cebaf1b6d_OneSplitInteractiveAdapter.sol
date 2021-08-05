/**
 *Submitted for verification at Etherscan.io on 2020-04-27
*/

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;


interface ERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token contract
 * returns false). Tokens that return no value (and instead revert or throw on failure)
 * are also supported, non-reverting calls are assumed to be successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 value,
        string memory location
    )
        internal
    {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.transfer.selector,
                to,
                value
            ),
            "transfer",
            location
        );
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value,
        string memory location
    )
        internal
    {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.transferFrom.selector,
                from,
                to,
                value
            ),
            "transferFrom",
            location
        );
    }

    function safeApprove(
        ERC20 token,
        address spender,
        uint256 value,
        string memory location
    )
        internal
    {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: wrong approve call"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                value
            ),
            "approve",
            location
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract),
     * relaxing the requirement on the return value: the return value is optional
     * (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     * @param location Location of the call (for debug).
     */
    function callOptionalReturn(
        ERC20 token,
        bytes memory data,
        string memory functionName,
        string memory location
    )
        private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking
        // mechanism, since we're implementing it ourselves.

        // We implement two-steps call as callee is a contract is a responsibility of a caller.
        //  1. The call itself is made, and success asserted
        //  2. The return value is decoded, which in turn checks the size of the returned data.

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(
            success,
            string(
                abi.encodePacked(
                    "SafeERC20: ",
                    functionName,
                    " failed in ",
                    location
                )
            )
        );

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: false returned");
        }
    }
}


struct Action {
    ActionType actionType;
    bytes32 protocolName;
    uint256 adapterIndex;
    address[] tokens;
    uint256[] amounts;
    AmountType[] amountTypes;
    bytes data;
}

enum ActionType { None, Deposit, Withdraw }


enum AmountType { None, Relative, Absolute }


/**
 * @title Protocol adapter interface.
 * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.
 * @author Igor Sobolev <[email protected]>
 */
abstract contract ProtocolAdapter {

    /**
     * @dev MUST return "Asset" or "Debt".
     * SHOULD be implemented by the public constant state variable.
     */
    function adapterType() external pure virtual returns (bytes32);

    /**
     * @dev MUST return token type (default is "ERC20").
     * SHOULD be implemented by the public constant state variable.
     */
    function tokenType() external pure virtual returns (bytes32);

    /**
     * @dev MUST return amount of the given token locked on the protocol by the given account.
     */
    function getBalance(address token, address account) public view virtual returns (uint256);
}


/**
 * @title Adapter for OneSplit exchange.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
contract OneSplitAdapter is ProtocolAdapter {

    bytes32 public constant override adapterType = "Exchange";

    bytes32 public constant override tokenType = "";

    /**
     * @return Amount of Uniswap pool tokens held by the given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address, address) public view override returns (uint256) {
        revert("OSA: no balance!");
    }
}


/**
 * @title Base contract for interactive protocol adapters.
 * @dev deposit() and withdraw() functions MUST be implemented
 * as well as all the functions from ProtocolAdapter interface.
 * @author Igor Sobolev <[email protected]>
 */
abstract contract InteractiveAdapter is ProtocolAdapter {

    uint256 internal constant RELATIVE_AMOUNT_BASE = 1e18;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev The function must deposit assets to the protocol.
     * @return MUST return assets to be sent back to the `msg.sender`.
     */
    function deposit(
        address[] memory tokens,
        uint256[] memory amounts,
        AmountType[] memory amountTypes,
        bytes memory data
    )
        public
        payable
        virtual
        returns (address[] memory);

    /**
     * @dev The function must withdraw assets from the protocol.
     * @return MUST return assets to be sent back to the `msg.sender`.
     */
    function withdraw(
        address[] memory tokens,
        uint256[] memory amounts,
        AmountType[] memory amountTypes,
        bytes memory data
    )
        public
        payable
        virtual
        returns (address[] memory);

    function getAbsoluteAmountDeposit(
        address token,
        uint256 amount,
        AmountType amountType
    )
        internal
        view
        virtual
        returns (uint256)
    {
        if (amountType == AmountType.Relative) {
            require(amount <= RELATIVE_AMOUNT_BASE, "L: wrong relative value!");

            uint256 totalAmount;
            if (token == ETH) {
                totalAmount = address(this).balance;
            } else {
                totalAmount = ERC20(token).balanceOf(address(this));
            }

            if (amount == RELATIVE_AMOUNT_BASE) {
                return totalAmount;
            } else {
                return totalAmount * amount / RELATIVE_AMOUNT_BASE; // TODO overflow check
            }
        } else {
            return amount;
        }
    }

    function getAbsoluteAmountWithdraw(
        address token,
        uint256 amount,
        AmountType amountType
    )
        internal
        view
        virtual
        returns (uint256)
    {
        if (amountType == AmountType.Relative) {
            require(amount <= RELATIVE_AMOUNT_BASE, "L: wrong relative value!");

            if (amount == RELATIVE_AMOUNT_BASE) {
                return getBalance(token, address(this));
            } else {
                return getBalance(token, address(this)) * amount / RELATIVE_AMOUNT_BASE; // TODO overflow check
            }
        } else {
            return amount;
        }
    }
}


/**
 * @dev OneSplit contract interface.
 * Only the functions required for OneSplitInteractiveAdapter contract are added.
 * The OneSplit contract is available here
 * github.com/CryptoManiacsZone/1split/blob/master/contracts/OneSplit.sol.
 */
interface OneSplit {
    function swap(
        address,
        address,
        uint256,
        uint256,
        uint256[] calldata,
        uint256
    )
        external
        payable;
    function getExpectedReturn(
        address,
        address,
        uint256,
        uint256,
        uint256
    )
        external
        view
        returns (uint256, uint256[] memory);
}


/**
 * @title Interactive adapter for OneSplit exchange.
 * @dev Implementation of InteractiveAdapter abstract contract.
 * @author Igor Sobolev <[email protected]>
 */
contract OneSplitInteractiveAdapter is InteractiveAdapter, OneSplitAdapter {

    using SafeERC20 for ERC20;

    address internal constant ONE_SPLIT = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;

    /**
     * @notice Exchanges tokens using OneSplit contract.
     * @param tokens Array with one element - `fromToken` address.
     * @param amounts Array with one element - token amount to be exchanged.
     * @param amountTypes Array with one element - amount type.
     * @param data Bytes array with ABI-encoded `toToken` address.
     * @return Asset sent back to the msg.sender.
     * @dev Implementation of InteractiveAdapter function.
     */
    function deposit(
        address[] memory tokens,
        uint256[] memory amounts,
        AmountType[] memory amountTypes,
        bytes memory data
    )
        public
        payable
        override
        returns (address[] memory)
    {
        require(tokens.length == 1, "OSIA: should be 1 token/amount/type!");

        uint256 amount = getAbsoluteAmountDeposit(tokens[0], amounts[0], amountTypes[0]);

        address fromToken = tokens[0];
        if (fromToken == ETH) {
            fromToken = address(0);
        } else {
            ERC20(fromToken).safeApprove(ONE_SPLIT, amount, "OSIA!");
        }

        address[] memory tokensToBeWithdrawn;

        address toToken = abi.decode(data, (address));
        if (toToken == ETH) {
            tokensToBeWithdrawn = new address[](0);
            toToken = address(0);
        } else {
            tokensToBeWithdrawn = new address[](1);
            tokensToBeWithdrawn[0] = toToken;
        }

        swap(fromToken, toToken, amount);

        return tokensToBeWithdrawn;
    }

    /**
     * @notice This function is unavailable in Exchange type adapters.
     * @dev Implementation of InteractiveAdapter function.
     */
    function withdraw(
        address[] memory,
        uint256[] memory,
        AmountType[] memory,
        bytes memory
    )
        public
        payable
        override
        returns (address[] memory)
    {
        revert("OSIA: no withdraw!");
    }

    function swap(address fromToken, address toToken, uint256 amount) internal {
        uint256[] memory distribution;

        try OneSplit(ONE_SPLIT).getExpectedReturn(
            fromToken,
            toToken,
            amount,
            uint256(1),
            uint256(0x040df0) // 0x040dfc to enable curve; 0x04fdf0 to enable base exchanges;
        ) returns (uint256, uint256[] memory result) {
            distribution = result;
        } catch Error(string memory reason) {
            revert(reason);
        } catch (bytes memory) {
            revert("OSIA: 1split fail![1]");
        }

        uint256 value = fromToken == address(0) ? amount : 0;
        try OneSplit(ONE_SPLIT).swap.value(value)(
            fromToken,
            toToken,
            amount,
            uint256(1),
            distribution,
            uint256(0x040df0) // 0x040dfc to enable curve; 0x04fdf0 to enable base exchanges;
        ) {} catch Error(string memory reason) {
            revert(reason);
        } catch (bytes memory) {
            revert("OSIA: 1split fail![2]");
        }
    }
}