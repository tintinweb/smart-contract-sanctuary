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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../interfaces/ERC20.sol";
import { ProtocolAdapter } from "./ProtocolAdapter.sol";

/**
 * @title Adapter for any protocol with ERC20 interface.
 * @dev Implementation of ProtocolAdapter abstract contract.
 * @author Igor Sobolev <[email protected]>
 */
contract ERC20ProtocolAdapter is ProtocolAdapter {
    /**
     * @return Amount of tokens held by the given account.
     * @dev Implementation of ProtocolAdapter abstract contract function.
     */
    function getBalance(address token, address account) public view override returns (int256) {
        return int256(ERC20(token).balanceOf(account));
    }
}

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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Protocol adapter abstract contract.
 * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.
 * @author Igor Sobolev <[email protected]>
 */
abstract contract ProtocolAdapter {
    /**
     * @dev MUST return amount and type of the given token
     * locked on the protocol by the given account.
     */
    function getBalance(address token, address account) public virtual returns (int256);
}

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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import { ProtocolAdapter } from "../adapters/ProtocolAdapter.sol";
import { TokenAmount, AmountType } from "../shared/Structs.sol";
import { ERC20 } from "../interfaces/ERC20.sol";

/**
 * @title Base contract for interactive protocol adapters.
 * @dev deposit() and withdraw() functions MUST be implemented
 * as well as all the functions from ProtocolAdapter abstract contract.
 * @author Igor Sobolev <[email protected]>
 */
abstract contract InteractiveAdapter is ProtocolAdapter {
    uint256 internal constant DELIMITER = 1e18;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev The function must deposit assets to the protocol.
     * @return MUST return assets to be sent back to the `msg.sender`.
     */
    function deposit(TokenAmount[] calldata tokenAmounts, bytes calldata data)
        external
        payable
        virtual
        returns (address[] memory);

    /**
     * @dev The function must withdraw assets from the protocol.
     * @return MUST return assets to be sent back to the `msg.sender`.
     */
    function withdraw(TokenAmount[] calldata tokenAmounts, bytes calldata data)
        external
        payable
        virtual
        returns (address[] memory);

    function getAbsoluteAmountDeposit(TokenAmount calldata tokenAmount)
        internal
        view
        virtual
        returns (uint256)
    {
        address token = tokenAmount.token;
        uint256 amount = tokenAmount.amount;
        AmountType amountType = tokenAmount.amountType;

        require(
            amountType == AmountType.Relative || amountType == AmountType.Absolute,
            "IA: bad amount type"
        );
        if (amountType == AmountType.Relative) {
            require(amount <= DELIMITER, "IA: bad amount");

            uint256 balance;
            if (token == ETH) {
                balance = address(this).balance;
            } else {
                balance = ERC20(token).balanceOf(address(this));
            }

            if (amount == DELIMITER) {
                return balance;
            } else {
                return mul_(balance, amount) / DELIMITER;
            }
        } else {
            return amount;
        }
    }

    function getAbsoluteAmountWithdraw(TokenAmount calldata tokenAmount)
        internal
        virtual
        returns (uint256)
    {
        address token = tokenAmount.token;
        uint256 amount = tokenAmount.amount;
        AmountType amountType = tokenAmount.amountType;

        require(
            amountType == AmountType.Relative || amountType == AmountType.Absolute,
            "IA: bad amount type"
        );
        if (amountType == AmountType.Relative) {
            require(amount <= DELIMITER, "IA: bad amount");

            int256 balanceSigned = getBalance(token, address(this));
            uint256 balance = balanceSigned > 0 ? uint256(balanceSigned) : uint256(-balanceSigned);
            if (amount == DELIMITER) {
                return balance;
            } else {
                return mul_(balance, amount) / DELIMITER;
            }
        } else {
            return amount;
        }
    }

    function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "IA: mul overflow");

        return c;
    }
}

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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../interfaces/ERC20.sol";
import { SafeERC20 } from "../../shared/SafeERC20.sol";
import { TokenAmount, AmountType } from "../../shared/Structs.sol";
import { ERC20ProtocolAdapter } from "../../adapters/ERC20ProtocolAdapter.sol";
import { InteractiveAdapter } from "../InteractiveAdapter.sol";
import { DODO } from "../../interfaces/DODO.sol";
import { DODOLpToken } from "../../interfaces/DODOLpToken.sol";

/**
 * @title Interactive adapter for DODO (liquidity).
 * @dev Implementation of InteractiveAdapter abstract contract.
 * @author Igor Sobolev <[email protected]>
 */
contract DodoAssetInteractiveAdapter is InteractiveAdapter, ERC20ProtocolAdapter {
    using SafeERC20 for ERC20;

    /**
     * @notice Deposits tokens to the DODO pool.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * token address, token amount to be deposited, and amount type.
     * @param data ABI-encoded additional parameter:
     *     - pool - DODO lp (capital token) address.
     * @return tokensToBeWithdrawn Array with one element - DODO lp (capital token) address.
     * @dev Implementation of InteractiveAdapter function.
     */
    function deposit(TokenAmount[] calldata tokenAmounts, bytes calldata data)
        external
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "DAIA: should be 1 tokenAmount[1]");

        address token = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountDeposit(tokenAmounts[0]);

        address lpToken = abi.decode(data, (address));

        address dodo = DODOLpToken(lpToken)._OWNER_();

        ERC20(token).safeApproveMax(dodo, amount, "DAIA");

        function(uint256) external returns (uint256) dodoDeposit =
            isBaseToken(token, dodo) ? DODO(dodo).depositBase : DODO(dodo).depositQuote;

        // solhint-disable-next-line no-empty-blocks
        try dodoDeposit(amount) returns (uint256) {} catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("DAIA: deposit fail");
        }

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = lpToken;
    }

    /**
     * @notice Withdraws tokens from the DODO pool.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     * DODO lp (capital token) address, amount to be redeemed, and amount type.
     * @return tokensToBeWithdrawn Array with one element - destination token address.
     * @dev Implementation of InteractiveAdapter function.
     */
    function withdraw(TokenAmount[] calldata tokenAmounts, bytes calldata)
        external
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "DAIA: should be 1 tokenAmount[2]");

        address token = tokenAmounts[0].token;
        address toToken = DODOLpToken(token).originToken();
        address dodo = DODOLpToken(token)._OWNER_();

        if (tokenAmounts[0].amount == 1e18 && tokenAmounts[0].amountType == AmountType.Relative) {
            function() external returns (uint256) dodoWithdraw =
                isBaseToken(toToken, dodo)
                    ? DODO(dodo).withdrawAllBase
                    : DODO(dodo).withdrawAllQuote;

            // solhint-disable-next-line no-empty-blocks
            try dodoWithdraw() returns (uint256) {} catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("DAIA: withdraw fail");
            }
        } else {
            uint256 amount = getAbsoluteAmountWithdraw(tokenAmounts[0]);

            (uint256 baseTarget, uint256 quoteTarget) = DODO(dodo).getExpectedTarget();
            function(uint256) external returns (uint256) dodoWithdraw;
            uint256 withdrawAmount;
            if (isBaseToken(toToken, dodo)) {
                dodoWithdraw = DODO(dodo).withdrawBase;
                withdrawAmount = mul_(amount - 1, baseTarget) / DODO(dodo).getTotalBaseCapital();
            } else {
                dodoWithdraw = DODO(dodo).withdrawQuote;
                withdrawAmount = mul_(amount - 1, quoteTarget) / DODO(dodo).getTotalQuoteCapital();
            }

            // solhint-disable-next-line no-empty-blocks
            try dodoWithdraw(withdrawAmount) returns (uint256) {} catch Error(
                string memory reason
            ) {
                revert(reason);
            } catch {
                revert("DAIA: withdraw fail");
            }
        }

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = toToken;
    }

    function isBaseToken(address token, address dodo) internal view returns (bool) {
        return token == DODO(dodo)._BASE_TOKEN_();
    }
}

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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @dev DODO contract interface.
 * Only the functions required for DodoTokenAdapter contract are added.
 * The DODO contract is available here
 * github.com/DODOEX/dodo-smart-contract/blob/master/contracts/dodo.sol.
 */
interface DODO {
    function depositBase(uint256) external returns (uint256);

    function depositQuote(uint256) external returns (uint256);

    function withdrawBase(uint256) external returns (uint256);

    function withdrawQuote(uint256) external returns (uint256);

    function withdrawAllBase() external returns (uint256);

    function withdrawAllQuote() external returns (uint256);

    // solhint-disable func-name-mixedcase
    function _BASE_TOKEN_() external view returns (address);

    function _BASE_CAPITAL_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    // solhint-enable func-name-mixedcase

    function getExpectedTarget() external view returns (uint256, uint256);

    function getTotalBaseCapital() external view returns (uint256);

    function getTotalQuoteCapital() external view returns (uint256);
}

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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @dev DODOLpToken contract interface.
 * Only the functions required for DodoTokenAdapter contract are added.
 * The DODOLpToken contract is available here
 * github.com/DODOEX/dodo-smart-contract/blob/master/contracts/impl/DODOLpToken.sol.
 */
interface DODOLpToken {
    // solhint-disable func-name-mixedcase
    function _OWNER_() external view returns (address);

    // solhint-enable func-name-mixedcase
    function originToken() external view returns (address);
}

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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface ERC20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);
}

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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;

import "../interfaces/ERC20.sol";

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
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value),
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
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value),
            "transferFrom",
            location
        );
    }

    function safeApprove(
        ERC20 token,
        address spender,
        uint256 value,
        string memory location
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            string(abi.encodePacked("SafeERC20: bad approve call from ", location))
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value),
            "approve",
            location
        );
    }

    function safeApproveMax(
        ERC20 token,
        address spender,
        uint256 value,
        string memory location
    ) internal {
        uint256 allowance = ERC20(token).allowance(address(this), spender);
        if (allowance < value) {
            if (allowance > 0) {
                safeApprove(token, spender, 0, location);
            }
            safeApprove(token, spender, type(uint256).max, location);
        }
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
    ) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking
        // mechanism, since we're implementing it ourselves.

        // We implement two-steps call as callee is a contract is a responsibility of a caller.
        //  1. The call itself is made, and success asserted
        //  2. The return value is decoded, which in turn checks the size of the returned data.

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(
            success,
            string(abi.encodePacked("SafeERC20: ", functionName, " failed in ", location))
        );

        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                string(
                    abi.encodePacked("SafeERC20: ", functionName, " returned false in ", location)
                )
            );
        }
    }
}

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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

// The struct consists of TokenBalanceMeta structs for
// (base) token and its underlying tokens (if any).
struct FullTokenBalance {
    TokenBalanceMeta base;
    TokenBalanceMeta[] underlying;
}

// The struct consists of TokenBalance struct
// with token address and absolute amount
// and ERC20Metadata struct with ERC20-style metadata.
// NOTE: 0xEeee...EEeE address is used for ETH.
struct TokenBalanceMeta {
    TokenBalance tokenBalance;
    ERC20Metadata erc20metadata;
}

// The struct consists of ERC20-style token metadata.
struct ERC20Metadata {
    string name;
    string symbol;
    uint8 decimals;
}

// The struct consists of protocol adapter's name
// and array of TokenBalance structs
// with token addresses and absolute amounts.
struct AdapterBalance {
    bytes32 protocolAdapterName;
    TokenBalance[] tokenBalances;
}

// The struct consists of token address
// and its absolute amount (may be negative).
// 0xEeee...EEeE is used for Ether
struct TokenBalance {
    address token;
    int256 amount;
}

// The struct consists of token address,
// and price per full share (1e18).
// 0xEeee...EEeE is used for Ether
struct Component {
    address token;
    int256 rate;
}

//=============================== Interactive Adapters Structs ====================================

// The struct consists of name of the protocol adapter,
// action type, array of token amounts,
// and some additional data (depends on the protocol).
struct Action {
    bytes32 protocolAdapterName;
    ActionType actionType;
    TokenAmount[] tokenAmounts;
    bytes data;
}

// The struct consists of token address,
// its amount, and amount type, as well as
// permit type and calldata.
struct Input {
    TokenAmount tokenAmount;
    Permit permit;
}

// The struct consists of
// permit type and calldata.
struct Permit {
    PermitType permitType;
    bytes permitCallData;
}

// The struct consists of token address,
// its amount, and amount type.
// 0xEeee...EEeE is used for Ether
struct TokenAmount {
    address token;
    uint256 amount;
    AmountType amountType;
}

// The struct consists of fee share
// and beneficiary address.
struct Fee {
    uint256 share;
    address beneficiary;
}

// The struct consists of token address
// and its absolute amount.
// 0xEeee...EEeE is used for Ether
struct AbsoluteTokenAmount {
    address token;
    uint256 absoluteAmount;
}

enum ActionType { None, Deposit, Withdraw }

enum AmountType { None, Relative, Absolute }

enum PermitType { None, EIP2612, DAI, Yearn }